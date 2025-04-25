/*
2021-AUG-26  SPiNX <Point 1>
 Filing bad commands.
 ping_debug -1 disables.
2021-SEPT-20 SPiNX <Point 2>
 Backwards compatibility.
 2025-APR-25 SPiNX <Point 3>
 * Filter bots related to CZ map loading/ round starting stability issues.
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

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

#define ACCESS_LEVEL    "ADMIN_RESERVATION"

new  g_iPing, g_iLoss, g_iPingTolerance, g_iPingT, g_iPingAdm, g_iPingDebug
new bool:g_bEntry[MAX_PLAYERS + 1]
new g_AI, g_Admin;
static ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
static const StrTreatmentMsg[] = "Your ping or loss is out of bounds!";

public plugin_init()
{
    register_plugin("Ping telepathy", "04/2025", "SPiNX")
    g_iPingTolerance = register_cvar("ping_limit", "500");
    g_iPingAdm       = register_cvar("ping_admin", "0");
    g_iPingDebug     = register_cvar("ping_debug", "0");
}

stock Fn_etwork(id) {get_user_ping(id, g_iPing, g_iLoss);return g_iLoss,g_iPing;}

public client_putinserver(id)
{
    static name[MAX_NAME_LENGTH], ip[MAX_IP_LENGTH], reason[128];

    ClearPlayerBit(g_AI, id);
    ClearPlayerBit(g_Admin, id);

    if(is_user_connected(id))
    {
        has_flag(id, ACCESS_LEVEL)  ? SetPlayerBit(g_Admin, id) : ClearPlayerBit(g_Admin, id)

        Fn_etwork(id)
        reason = "Server is busy. Please retry your connection."

        get_user_name(id,name,charsmax(name))
        get_user_ip( id, ip, charsmax( ip ), WITHOUT_PORT );

        g_bEntry[id] = CheckPlayerBit(g_AI, id ) ? false : true

        if(get_pcvar_num(g_iPingDebug))
            server_print "ping[%i]|loss[%i]|name[%s]|ip[%s]",g_iPing,g_iLoss, name, ip

        set_task(15.0,"lift_ping_immunity",id);
    }
}

public client_authorized(id, const authid[])
{
    if(is_user_connecting(id))
    {
        equal(authid, "BOT") ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
    }
}

public client_disconnected(id)
{
    ClearPlayerBit(g_AI, id);
    ClearPlayerBit(g_Admin, id);
    g_bEntry[id] = false;
}

public lift_ping_immunity(id){g_bEntry[id] = false;}

stock Fn_Outcome(id,g_iLoss,g_iPing)
{
    static userid2; userid2 = get_user_userid(id);
    return console_cmd(0, "kick #%d %s Ping:%i|Loss:%i", userid2, StrTreatmentMsg, g_iPing, g_iLoss)
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
        if(!CheckPlayerBit(g_AI, id ) && !CheckPlayerBit(g_Admin, id ) || CheckPlayerBit(g_Admin, id ) && (get_pcvar_num(g_iPingAdm) != 0 ) )
        client_command(id);
    }
}

public client_command(id)
{
    if(!g_bEntry[id] && !CheckPlayerBit(g_AI, id ))
    if(!CheckPlayerBit(g_Admin, id ) || CheckPlayerBit(g_Admin, id ) && (get_pcvar_num(g_iPingAdm) != 0 ) )
    {

        Fn_etwork(id)

        g_iPingT = get_pcvar_num(g_iPingTolerance);

        if(get_pcvar_num(g_iPingDebug))
           server_print "ping[%i]|loss[%i]-->%N",g_iPing,g_iLoss, id

        if(g_iPing > g_iPingT || g_iLoss > (sqroot(g_iPingT)) )
            Fn_Outcome(id,g_iLoss,g_iPing);

        else if(g_iLoss >= 3)
        {

            if(get_pcvar_num(g_iPingDebug) > charsmin)
            {
                static szArg[MAX_USER_INFO_LENGTH];
                static szArgCmd[MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH], szArgCmd1[MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH];

                read_args(szArg, charsmax(szArg));
                read_argv(0,szArgCmd, charsmax(szArgCmd));
                read_argv(1,szArgCmd1, charsmax(szArgCmd1));
                if(is_user_connected(id))
                {
                    log_amx "%s lagged server ping[%i]|loss[%i] with %s %s",ClientName[id],g_iPing,g_iLoss,szArgCmd,szArgCmd1
                }
            }
            return PLUGIN_HANDLED_MAIN; //attempting prevent lag spike.
        }

    }
    return PLUGIN_CONTINUE
}
