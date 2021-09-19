#include amxmodx
#include amxmisc
#include engine
#include hamsandwich
#include fakemeta

#define alert 911
#define SPEC_PRG "of_spectate.amxx"
//Define your spec plugin pathway!
#define MAX_PLAYERS                32

#define MAX_RESOURCE_PATH_LENGTH   64

#define MAX_MENU_LENGTH            512

#define MAX_NAME_LENGTH            32

#define MAX_AUTHID_LENGTH          64

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1
new g_timer[MAX_PLAYERS + 1]
new g_afk_spec_player/*, afk*/
new const CvarAFKTimeDesc[] = "Seconds before moving AFK player into spectator mode."
new sleepy[MAX_PLAYERS + 1], g_spec
new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
#define ALRT 84641
#define FADE_HOLD (1<<2)

public plugin_init()
{
    register_plugin("Connect Alert System","1.0","SPiNX");
    set_task(1.0, "new_users",alert,"",0,"b");

#if AMXX_VERSION_NUM == 182
g_afk_spec_player = register_cvar("mp_autospec", "75")
#endif
/*
#if AMXX_VERSION_NUM == 190
#if AMXX_VERSION_NUM == 110
    bind_pcvar_num( create_cvar("mp_autospec", "90", FCVAR_NONE, CvarAFKTimeDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 300.0), g_afk_spec_player)
#endif
#endif
*/
    g_spec = get_cvar_pointer("sv_spectate_spawn")
    RegisterHam(Ham_Spawn, "player", "screensaver_stop", 1);
}

public client_putinserver(index)
{

    if(!task_exists(ALRT) && !is_user_bot(index) && !is_user_admin(index))
    {
        //t_user_name(index,ClientName[index],charsmax(ClientName[]))
        set_task(1.5,"the_alert", ALRT) //1.0 stil gets doubles!
    }
    g_timer[index] = 1
}

public the_alert()
{
    client_cmd(0,"spk ^"alert a intruder is here^"")
}

public client_authorized(id)

//if(is_user_connected(id))
{
    get_user_name(id,ClientName[id],charsmax(ClientName[]))
    client_print 0,print_chat,"%s is lurking...", ClientName[id]
    g_timer[id] = 1
    server_print "%s is lurking...", ClientName[id]
}


public new_users()
{
    new players[MAX_PLAYERS], playercount, downloader;
    get_players(players,playercount,"i");


    for (downloader=0; downloader<playercount; ++downloader)
    {

        if(is_user_connecting(players[downloader]))
        {
            new uptime = g_timer[players[downloader]]++
            server_print"%s uptime:%i", ClientName[downloader], uptime

            if(uptime < 5)
            {
                client_print 0,print_chat,"%s is connecting...", ClientName[downloader]
                server_print "%s is connecting...", ClientName[downloader]
            }

            else
            {
                set_hudmessage(255, 255, 255, 0.00, 0.50, .effects= 0 , .holdtime= 5.0)
                show_hudmessage 0, "%s is downloading...", ClientName[downloader]
                //client_print 0,print_chat,"%s is downloading...", ClientName[downloader]
                server_print "%s is downloading...", ClientName[downloader]
            }

        }

        if(is_user_connected(players[downloader]) && !is_user_alive(players[downloader]) && !is_user_bot(players[downloader]))
        {
            new uptime = sleepy[players[downloader]]++

            if (uptime > get_pcvar_num(g_afk_spec_player))
            {
                if(g_spec && callfunc_begin("@go_spec",SPEC_PRG))
                {
                    if(!g_spec)
                        return
                    dllfunc(DLLFunc_ClientPutInServer, players[downloader])
                    log_amx "Sending %n to spec", ClientName[downloader]
                    callfunc_push_int(players[downloader])
                    callfunc_end()
                    sleepy[players[downloader]] = 1
                }
                else
                {
                    set_hudmessage(255, 255, 255, 0.41, 0.00, .effects= 0 , .holdtime= 5.0)
                    show_hudmessage 0, "%s is NO LONGER active...", ClientName[players[downloader]]
                    //client_print 0, print_chat, "%s is NO LONGER active...", ClientName[players[downloader]]
                    screensaver(players[downloader], uptime)
                    //sleepy[players[downloader]] = 1
                }
            }
            else
            {
                set_hudmessage(255, 255, 255, 0.41, 0.00, .effects= 0 , .holdtime= 5.0)
                show_hudmessage 0, "%s is NO LONGER active...", ClientName[players[downloader]]
                client_print players[downloader],print_chat, "AFK time:%i", uptime
                //client_print 0, print_console, "%s is NO LONGER active...", ClientName[players[downloader]]
            }
        }
    }
}

public screensaver_stop(id)
{
    new duration = 1<<12
    new holdTime = 1<<8
    new fadeType = FADE_HOLD
    new blindness = 0
    g_timer[id] = 1
    if (is_user_connected(id))
    {
        message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id); // use the magic #1 for "one client" 
        write_short(duration); // fade lasts this long duration 
        write_short(holdTime); // fade lasts this long hold time 
        write_short(fadeType); // fade type 
        write_byte(0); // fade red 
        write_byte(0); // fade green 
        write_byte(0); // fade blue  
        write_byte(blindness); // fade alpha  
        message_end(); 
    }   
}

public screensaver(id, uptime)
if (is_user_connected(id))
{
    client_print id,print_center, "Screen saver active for:%i seconds", uptime
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id); // use the magic #1 for "one client"  
    write_short(1<<12); // fade lasts this long duration  
    write_short(1<<8); // fade lasts this long hold time  
    write_short(FADE_HOLD); // fade type
    write_byte(0); // fade red  
    write_byte(0); // fade green  
    write_byte(0); // fade blue  
    write_byte(255); // fade alpha   
    message_end();  
}
