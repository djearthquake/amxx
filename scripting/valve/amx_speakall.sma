/*Make speak commands public.*/
#include amxmodx

public plugin_init()
{
    register_plugin("SPEAK ALL", "0.0.3", "SPiNX");
    register_concmd("amx_speakall","@speakall",0,": Vox speak.");
}

@speakall(id, szArgCmd1[128])
{
    if(is_user_connected(id))
    {
        read_argv(1,szArgCmd1, charsmax(szArgCmd1));

        for(new players; players<=MaxClients; ++players)
        {
            if(is_user_connected(players))
            {
                console_cmd players, "speak ^"%s^"", szArgCmd1
                server_print("%N spoke %s.", id, szArgCmd1)
            }
        }
    }
    return PLUGIN_HANDLED
}
