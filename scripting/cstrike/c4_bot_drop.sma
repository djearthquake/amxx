#include amxmodx

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new g_AI, g_cvar_drop;

public plugin_init()
{
    register_plugin("Bot Drop C4","1.0.0","SPiNX")
    register_logevent("logevent_function_p", 3, "2=Spawned_With_The_Bomb");
    g_cvar_drop = register_cvar("bot_drop_c4", "1")
}

public client_authorized(id, const authid[])
{
    if(is_user_connecting(id))
    {
        equal(authid, "BOT") ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
    }
}

stock get_loguser_index()
{
    static loguser[80], name[MAX_NAME_LENGTH];
    read_logargv(0, loguser, charsmax(loguser));
    parse_loguser(loguser, name, charsmax(loguser));
    
    return get_user_index(name);
}

public logevent_function_p()
{
    static id; id = get_loguser_index();
    static iBot; iBot = get_pcvar_num(g_cvar_drop)

    if(iBot)
    {
        if(CheckPlayerBit(g_AI, id) && is_user_alive(id))
        {
            engclient_cmd(id, "drop", "weapon_c4")
        }
    }
}
