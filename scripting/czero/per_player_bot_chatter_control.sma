#include amxmodx
#include amxmisc
#include fakemeta

#define PLUGIN "Bot Chatter Control"
#define VERSION "0.1"
#define AUTHOR "SPiNX"

enum
{
    CHATTER_ALL = 0,
    CHATTER_RADIO_ONLY,
    CHATTER_OFF
}

new g_PlayerPreference[MAX_PLAYERS + 1];
new bool:g_bIsBot[MAX_PLAYERS + 1]
new g_MsgIdSendAudio, g_MsgIdTextMsg;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say /botchat", "CmdBotChatMenu", 0, "- Opens visual menu to set bot chatter preferences");
    register_clcmd("say_team /botchat", "CmdBotChatMenu", 0, "- Opens visual menu to set bot chatter preferences (Team Chat)");
    register_clcmd("say botchat", "CmdBotChatMenu", 0, "- Opens visual menu to set bot chatter preferences (No Slash)");

    register_clcmd("amx_bothelp", "CmdConsoleHelp", 0, "- Shows console instructions for bot preferences");
    register_clcmd("say /bothelp", "CmdConsoleHelp", 0, "- Shows console instructions for bot preferences via chat");

    g_MsgIdSendAudio = get_user_msgid("SendAudio");
    g_MsgIdTextMsg = get_user_msgid("TextMsg");

    register_message(g_MsgIdSendAudio, "Hook_SendAudio");
    register_message(g_MsgIdTextMsg, "Hook_TextMsg");

    register_forward(FM_Voice_SetClientListening, "Forward_SetClientListening");
}

public client_authorized(id, const authid[])
{
    if (equal(authid, "BOT"))
    {
        g_bIsBot[id] = true
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        if(!g_bIsBot[id])
        {
            g_bIsBot[id] = is_user_bot(id) ? true:false;
        }
        if(!g_bIsBot[id])
        {
            g_PlayerPreference[id] = CHATTER_ALL;
            set_task(5.0, "Task_WelcomeNotice", id);
        }
    }
}

public Task_WelcomeNotice(id)
{
    if (!is_user_connected(id) || g_bIsBot[id])
    {
        return;
    }

    client_print_color(id, print_team_default, "^4[Server]^1 Surrounded by bots? Type ^3/botchat^1 in chat or ^3amx_bothelp^1 in console to mute or adjust their chatter!");
}

public CmdConsoleHelp(id)
{
    console_print(id, "====================================================");
    console_print(id, "             BOT CHATTER CONTROL HELP               ");
    console_print(id, "====================================================");
    console_print(id, " Since this server runs mostly bots, you can change");
    console_print(id, " how much spam you hear from them at any time.");
    console_print(id, "");
    console_print(id, " Chat Commands:");
    console_print(id, "   type '/botchat'  - Opens visual menu to choose preference");
    console_print(id, "");
    console_print(id, " Available Options:");
    console_print(id, "   1. All Bot Chatter     - Hear casual talk and radio tags");
    console_print(id, "   2. Standard Radio Only - Blocks voice chatter, leaves standard callouts");
    console_print(id, "   3. Completely Off      - Pure silence. No text, no sounds, no spam");
    console_print(id, "====================================================");

    return PLUGIN_HANDLED;
}

public CmdBotChatMenu(id)
{
    new menu = menu_create("\rBot Chatter Preference:", "Menu_ChatterHandler");

    menu_additem(menu, g_PlayerPreference[id] == CHATTER_ALL ? "\yAll Bot Chatter [Active]" : "All Bot Chatter", "0");
    menu_additem(menu, g_PlayerPreference[id] == CHATTER_RADIO_ONLY ? "\yStandard Radio Only [Active]" : "Standard Radio Only", "1");
    menu_additem(menu, g_PlayerPreference[id] == CHATTER_OFF ? "\yCompletely Off [Active]" : "Completely Off", "2");

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);

    return PLUGIN_HANDLED;
}

public Menu_ChatterHandler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    g_PlayerPreference[id] = item;

    switch(item)
    {
        case CHATTER_ALL:
        {
            client_print_color(id, print_team_default, "^3[BotChat]^1 You will now hear all bot voice lines and radio.");
        }
        case CHATTER_RADIO_ONLY:
        {
            client_print_color(id, print_team_default, "^3[BotChat]^1 You will only hear standard tactical radio commands.");
        }
        case CHATTER_OFF:
        {
            client_print_color(id, print_team_default, "^3[BotChat]^1 All bot chatter and radio are now muted for you.");
        }
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public Forward_SetClientListening(iReceiver, iSender, bool:bListen)
{
    if (!is_user_connected(iReceiver) || !is_user_connected(iSender))
    {
        return FMRES_IGNORED;
    }

    if (g_bIsBot[iSender])
    {
        // If receiver wants radio only or total silence, sever the link
        if (g_PlayerPreference[iReceiver] == CHATTER_RADIO_ONLY || g_PlayerPreference[iReceiver] == CHATTER_OFF)
        {
            engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
            forward_return(FMV_CELL, false);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

// Blocks radio sound clips (e.g., "Go go go")
public Hook_SendAudio(msg_id, msg_dest, target)
{
    if (msg_dest != MSG_ONE || !is_user_connected(target))
    {
        return PLUGIN_CONTINUE;
    }

    if (g_PlayerPreference[target] == CHATTER_OFF)
    {
        static audio_sample[MAX_RESOURCE_PATH_LENGTH];
        get_msg_arg_string(2, audio_sample, charsmax(audio_sample));

        if (contain(audio_sample, "MRAD_") != FM_NULLENT || contain(audio_sample, "radio") != FM_NULLENT)
        {
            return PLUGIN_HANDLED;
        }
    }
    return PLUGIN_CONTINUE;
}

// Blocks radio chat text strings from printing
public Hook_TextMsg(msg_id, msg_dest, target)
{
    if (msg_dest != MSG_ONE || !is_user_connected(target))
    {
        return PLUGIN_CONTINUE;
    }

    if (g_PlayerPreference[target] == CHATTER_OFF)
    {
        static text_msg[MAX_RESOURCE_PATH_LENGTH];
        get_msg_arg_string(2, text_msg, charsmax(text_msg));

        if (containi(text_msg, "Radio") != FM_NULLENT)
        {
            return PLUGIN_HANDLED;
        }
    }
    return PLUGIN_CONTINUE;
}
