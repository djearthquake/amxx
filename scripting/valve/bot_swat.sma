#include amxmodx

#define PLUGIN "!Bot Swat"
#define VERSION "0.0.1"

//Command is specfic to bot type.
static const ZERO_BOT_COMMAND[] = {"jk_botti max_bots 0; jk_botti min_bots 0"};

new g_bot_limit, g_humans, ClientAuth[MAX_PLAYERS + 1][MAX_AUTHID_LENGTH];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "SPiNX");
    register_clcmd("amx_purge_bots", "@zero_bots", ADMIN_CFG, "- Remove all bots!");
    g_bot_limit = register_cvar("humans_for_botpurge", "4");
}

public client_authorized(id, const authid[])
{
    static iLimit; iLimit = 0;
    iLimit = get_pcvar_num(g_bot_limit);

    copy(ClientAuth[id], charsmax(ClientAuth[]), authid)

    if(!equal(authid, "BOT"))
    {
        g_humans++
    }
    if(g_humans >= iLimit)
    {
        @zero_bots()
    }
}

@zero_bots()
{
    for(new list = 1 ;list <= MaxClients;++list)
    {
        if(equal(ClientAuth[list], "BOT"))
        {
            server_cmd("kick %n ^"Purging bots.^"",list);
            server_cmd ZERO_BOT_COMMAND
        }
    }
    return PLUGIN_HANDLED
}

public client_disconnected(id)
{
    if(!equal(ClientAuth[id], "BOT"))
    {
        g_humans--
    }

    ClientAuth[id] = ""

    if(!g_humans)
    {
        zero_bots()
    }
}
