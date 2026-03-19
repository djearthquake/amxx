#include <amxmodx>
#include <amxmisc>

#define WITHOUT_PORT 1
#define charsmin -1

new g_iPing, g_iLoss, g_iPingTolerance, g_iPingT, g_iPingAdm, g_iPingDebug;
new bool:g_bEntry[MAX_PLAYERS + 1]
new const StrTreatmentMsg[] = "Your ping or loss is out of bounds!"

public plugin_init()
{
    register_plugin("Ping telepathy", "2026.03.19", "SPiNX")
    g_iPingTolerance = register_cvar("ping_limit", "500");
    g_iPingAdm       = register_cvar("ping_admin", "0");
    g_iPingDebug     = register_cvar("ping_debug", "0");
}

stock Fn_etwork(id)
{
    get_user_ping(id, g_iPing, g_iLoss);
}

public client_putinserver(id)
{
    if (id > 0)
        Fn_etwork(id)

    new name[MAX_NAME_LENGTH], ip[MAX_IP_LENGTH];
    get_user_name(id, name, charsmax(name))
    get_user_ip(id, ip, charsmax(ip), WITHOUT_PORT);

    g_bEntry[id] = (is_user_connected(id) && !is_user_bot(id)) ? true : false;

    if(get_pcvar_num(g_iPingDebug))
        server_print("ping[%i]|loss[%i]|name[%s]|ip[%s]", g_iPing, g_iLoss, name, ip)

    set_task(15.0, "lift_ping_immunity", id);
}

public client_disconnected(id)
{
    g_bEntry[id] = false;
}

public lift_ping_immunity(id)
{
    g_bEntry[id] = false;
}

stock Fn_Outcome(id, iLoss, iPing)
{
    new userid2 = get_user_userid(id);
    server_cmd("kick #%d %s Ping:%i|Loss:%i", userid2, StrTreatmentMsg, iPing, iLoss);
}

public client_infochanged(id)
{
    if(id > 0 && !is_user_bot(id))
    {
        if(!is_user_admin(id) || (is_user_admin(id) && get_pcvar_num(g_iPingAdm) != 0))
            client_command(id);
    }
}

public client_command(id)
{
    if(id > 0 && g_bEntry[id] == false)
    {
        if(!is_user_admin(id) || (is_user_admin(id) && get_pcvar_num(g_iPingAdm) != 0))
        {
            Fn_etwork(id)
            g_iPingT = get_pcvar_num(g_iPingTolerance);

            if(g_iPing > g_iPingT || g_iLoss > floatround(floatsqroot(float(g_iPingT))))
            {
                Fn_Outcome(id, g_iLoss, g_iPing);
                return PLUGIN_HANDLED;
            }
            else if(g_iLoss >= 3)
            {
                if(get_pcvar_num(g_iPingDebug) > charsmin)
                {
                    static szArg[128], szCmd[32], szArg1[32], szName[32];
                    read_args(szArg, charsmax(szArg));
                    read_argv(0, szCmd, charsmax(szCmd));
                    read_argv(1, szArg1, charsmax(szArg1));
                    get_user_name(id, szName, charsmax(szName));
                    log_amx("%s lagged server [%d|%d] with %s %s", szName, g_iPing, g_iLoss, szCmd, szArg1)
                }
                return PLUGIN_HANDLED_MAIN;
            }
        }
    }
    return PLUGIN_CONTINUE;
}
