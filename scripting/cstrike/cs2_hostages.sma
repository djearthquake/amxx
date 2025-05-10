#include amxmodx
#include engine_stocks
#include fakemeta

static const szHostages[][]={"hostage_entity", "monster_scientist"};

new g_cvar

public plugin_init()
{
    register_plugin("CS2 HOSTAGES", "0.0.1", "SPiNX")
    register_logevent("logevent_hostage_rescued",3,"2=Rescued_A_Hostage");
    g_cvar = register_cvar("cs2_hostages", "1")
}

public logevent_hostage_rescued()
{
    new cvar =  get_pcvar_num(g_cvar);
    if(cvar)
    {
        new id = get_loguser_index();
        if(is_user_connected(id))
        {
            hostage_one(id)
        }
    }
}

stock hostage_one(id)
{
    new ihostie, Float:Origin[3];
    new bool:printed;

    if(is_user_alive(id))
    {
        pev(id, pev_origin, Origin);

        for(new gang; gang <sizeof(szHostages);gang++)
        {
            while((ihostie = find_ent(ihostie, szHostages[gang])))
            {
                set_pev(ihostie, pev_origin, Origin);
            }
            if(!printed)
            {
                printed = true
                client_print 0, print_chat, "%n saved the hostages!", id;
            }

        }

    }

}

stock get_loguser_index()
{
    new log_user[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_PLAYERS];
    read_logargv(0, log_user, charsmax(log_user));

    parse_loguser(log_user, name, charsmax(name));

    return get_user_index(name);
}
