/*Make speak commands public.*/
#include amxmodx

#define MAX_CMD_LENGTH        128
#define MAX_PLAYERS            32

#if !defined MaxClients
static MaxClients
#endif

new bool:g_Bot[MAX_PLAYERS+1];
static szVersion[MAX_PLAYERS]

public plugin_init()
{
    register_plugin("SPEAK ALL", "0.0.3", "SPiNX");
    register_concmd("amx_speakall","@speakall",0,": Vox speak.");

    #if !defined MaxClients
    MaxClients = get_maxplayers()
    #endif

    get_amxx_verstring(szVersion, charsmax(szVersion))
    server_print szVersion
}

@speakall(id, szArgCmd1[MAX_CMD_LENGTH])
{
    if(is_user_connected(id))
    {
        read_argv(1,szArgCmd1, charsmax(szArgCmd1));

        for(new players; players<=MaxClients; players++)
        {
            if(is_user_connected(players))
            {
                //client_print(0, print_chat, g_Bot[players] ? "We think this is a bot!":"NOT A BOT!")

               if(equal(szVersion, "1.8.2"))
               {
                   if(g_Bot[players])
                    {
                        console_cmd players, "speak ^"%s^"", szArgCmd1
                    }
                    else
                    {
                            console_cmd(0, "kick #%d ^"Should be a bot being kicked!^"", get_user_userid(players) );
                    }
                }
                else
                {
                   if(!g_Bot[players])
                    {
                        console_cmd players, "speak ^"%s^"", szArgCmd1
                        server_print("%N spoke %s.", id, szArgCmd1)
                    }
                }
            }
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
    if(is_user_connected(id))
    {
        g_Bot[id] = is_user_bot(id) ? true : false
        server_print( g_Bot[id] ? "We think this is a bot!":"NOT A BOT!")
    }
}
#endif
