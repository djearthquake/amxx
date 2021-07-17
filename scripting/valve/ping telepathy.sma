#include amxmodx
#include amxmisc

new  g_iPing, g_iLoss, g_iPingTolerance, g_iPingT, g_iPingAdm, g_iPingDebug;
new const StrTreatmentMsg[] = "Your ping or loss is out of bounds!"
public plugin_init()
{
    register_plugin("Ping telepathy", "2020", "SPiNX")
    g_iPingTolerance = register_cvar("ping_limit", "500");
    g_iPingAdm       = register_cvar("ping_admin", "0");
    g_iPingDebug     = register_cvar("ping_debug", "0");
}
public client_connectex(id, const name[], const ip[], reason[128])
{
    get_user_ping(id, g_iPing, g_iLoss);
    reason = StrTreatmentMsg
    client_command(id);

    if(get_pcvar_num(g_iPingDebug)){
    server_print("ping[%i]|loss[%i]|name[%s]|ip[%s]",g_iPing,g_iLoss, name, ip);
    }
    g_iPingT = ( get_pcvar_num(g_iPingTolerance)*sqroot(sqroot(g_iPing)) );
    if(g_iPing > g_iPingT || g_iLoss > sqroot(sqroot(g_iPing)) || is_user_bot(id) )
            return PLUGIN_HANDLED_MAIN;
        else
    return PLUGIN_CONTINUE;
}
public client_command(id)
{
    if(is_user_bot(id))return;
    if(!is_user_admin(id) || is_user_admin(id) && (get_pcvar_num(g_iPingAdm)!=0) )
        Fn_etwork(id)
    g_iPingT = get_pcvar_num(g_iPingTolerance);
    if(get_pcvar_num(g_iPingDebug))
    if(!is_user_admin(id) || is_user_admin(id) && (get_pcvar_num(g_iPingAdm)!=0) )
       server_print("ping[%i]|loss[%i]",g_iPing,g_iLoss);
    if(g_iPing > g_iPingT || g_iLoss > sqroot(sqroot(g_iPingT)) )
        Fn_Outcome(id);
}
public client_infochanged(id)
{
    client_command(id);
    return PLUGIN_CONTINUE;
}
stock Fn_etwork(id)
{
    get_user_ping(id, g_iPing, g_iLoss);
    return g_iLoss,g_iPing;
}
stock Fn_Outcome(id)
{
    new userid2 = get_user_userid(id);
    return server_cmd("kick #%d %s", userid2, StrTreatmentMsg);
}
