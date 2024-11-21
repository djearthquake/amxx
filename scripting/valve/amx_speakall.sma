/*Make speak commands public.*/

#include amxmodx

#define MAX_CMD_LENGTH        128
#define MAX_PLAYERS            32

new iBot[MAX_PLAYERS+1];
#if !defined MaxClients
static MaxClients
#endif

public plugin_init()
{
    register_plugin("SPEAK ALL", "0.0.3", "SPiNX");
    register_concmd("amx_speakall","@speakall",0,": Vox speak.");
    #if !defined MaxClients
    MaxClients = get_maxplayers()
    #endif

}

@speakall(id, szArgCmd1[MAX_CMD_LENGTH])
{
    if(is_user_connected(id))
    {
        read_argv(1,szArgCmd1, charsmax(szArgCmd1));

        for(new players; players<=MaxClients; ++players)
        if(is_user_connected(players) && !iBot[players])
        {
            console_cmd players, "speak ^"%s^"", szArgCmd1
            server_print("%N spoke %s.", id, szArgCmd1)
        }
    }
    return PLUGIN_HANDLED
}
#if AMXX_VERSION_NUM != 182
public client_authorized(id, const authid[])
{
    iBot[id] = equal(authid, "BOT") ? true : false
}
#else
public client_putinserver(id)
{
    static authid[4]
    get_user_authid(id, authid, charsmax(authid))
    iBot[id] = equal(authid, "BOT") ? true : false
}
#endif
