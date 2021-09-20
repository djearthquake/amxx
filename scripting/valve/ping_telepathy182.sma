/*
2021-AUG-26  SPiNX <Point 1> 
 Filing bad commands.
 ping_debug -1 disables.
2021-SEPT-20 SPiNX <Point 2>
 Backwards compatibility.
*/
#include amxmodx
#include amxmisc
#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32
#define MAX_IP_LENGTH 16
#define WITHOUT_PORT 1


#define MAX_PLAYERS                32

#define MAX_RESOURCE_PATH_LENGTH   64

#define MAX_MENU_LENGTH            512

#define MAX_NAME_LENGTH            32

#define MAX_AUTHID_LENGTH          64

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1

#define client_disconnect client_disconnected

new  g_iPing, g_iLoss, g_iPingTolerance, g_iPingT, g_iPingAdm, g_iPingDebug;
new bool:g_bEntry[MAX_PLAYERS + 1]
new const StrTreatmentMsg[] = "Your ping or loss is out of bounds!"

public plugin_init()
{
    register_plugin("Ping telepathy", "2020.182.2", "SPiNX")
    g_iPingTolerance = register_cvar("ping_limit", "500");
    g_iPingAdm       = register_cvar("ping_admin", "0");
    g_iPingDebug     = register_cvar("ping_debug", "0");
}

stock Fn_etwork(id) {get_user_ping(id, g_iPing, g_iLoss);return g_iLoss,g_iPing;}

public client_putinserver(id)
{
    if (id > 0)
    Fn_etwork(id)

    new name[MAX_NAME_LENGTH], ip[MAX_IP_LENGTH], reason[128];
    reason = "Server is busy. Please retry your connection."
    get_user_name(id,name,charsmax(name))
    get_user_ip( id, ip, charsmax( ip ), WITHOUT_PORT );

    if(is_user_connected(id) && !is_user_bot(id))
        g_bEntry[id] = true;
    else
        g_bEntry[id] = false;

    if(get_pcvar_num(g_iPingDebug))
        server_print "ping[%i]|loss[%i]|name[%s]|ip[%s]",g_iPing,g_iLoss, name, ip

    set_task(15.0,"lift_ping_immunity",id);
}
public client_disconnected(id)

    g_bEntry[id] = false;

public lift_ping_immunity(id){g_bEntry[id] = false;}

stock Fn_Outcome(id,g_iLoss,g_iPing)
{
    new userid2 = get_user_userid(id);
    return server_cmd("kick #%d %s Ping:%i|Loss:%i", userid2, StrTreatmentMsg, g_iPing, g_iLoss)
}
public client_infochanged(id)
    if(!is_user_bot(id) && id > 0 || !is_user_admin(id) || is_user_admin(id) && (get_pcvar_num(g_iPingAdm) != 0 ) )
        client_command(id);

public client_command(id)
{
    if(g_bEntry[id] == false && id > 0)
    if(!is_user_admin(id) || is_user_admin(id) && (get_pcvar_num(g_iPingAdm) != 0 ) )
    {

        Fn_etwork(id)

        g_iPingT = get_pcvar_num(g_iPingTolerance);

        if(get_pcvar_num(g_iPingDebug))

           server_print "ping[%i]|loss[%i]",g_iPing,g_iLoss

        if(g_iPing > g_iPingT || g_iLoss > (sqroot(g_iPingT)) )
            Fn_Outcome(id,g_iLoss,g_iPing);

        else if(g_iLoss >= 3)
        {

            if(get_pcvar_num(g_iPingDebug) > charsmin)
            {
                new szArg[MAX_USER_INFO_LENGTH];
                new szArgCmd[MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH], szArgCmd1[MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH];

                read_args(szArg, charsmax(szArg));
                read_argv(0,szArgCmd, charsmax(szArgCmd));
                read_argv(1,szArgCmd1, charsmax(szArgCmd1));
                if(is_user_connected(id))
                {
                    new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
                    get_user_name(id,ClientName[id],charsmax(ClientName[]))
                    log_amx "%s lagged server ping[%i]|loss[%i] with %s %s",ClientName[id],g_iPing,g_iLoss,szArgCmd,szArgCmd1
                }
            }
            return PLUGIN_HANDLED_MAIN; //attempting prevent lag spike.
        }

    }
    return PLUGIN_CONTINUE
}
