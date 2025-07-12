#include amxmodx
#include engine_stocks
#include fakemeta
#include hamsandwich

static const szHostages[][]={"hostage_entity", "monster_scientist"};

new g_cvar, bool:bRescuing;

public plugin_init()
{
    register_plugin("CS2 HOSTAGES", "0.0.3", "SPiNX")
    register_logevent("logevent_hostage_rescued",3,"2=Rescued_A_Hostage");
    g_cvar = register_cvar("cs2_hostages", "1")
}

public logevent_hostage_rescued()
{
    new cvar =  get_pcvar_num(g_cvar);
    if(cvar)
    {
        new id = get_loguser_index();
        if(is_user_alive(id) && !bRescuing)
        {
            bRescuing = true
            hostage_one(id)
        }
    }
}

public hostage_one(id)
{
    new ihostie, Float:Origin[3];

    if(is_user_alive(id))
    {
        new ent = find_ent(MaxClients, "func_hostage_rescue")
        if(ent)
        {
            get_brush_entity_origin(ent, Origin)
        }
        else
        {
            ent = find_ent(MaxClients, "info_hostage_rescue")
            if(ent)
            {
                get_brush_entity_origin(ent, Origin)
            }
            else
            {
                pev(id, pev_origin, Origin);
            }
        }
        for(new gang; gang <sizeof(szHostages);gang++)
        {
            while((ihostie = find_ent(ihostie, szHostages[gang])))
            {
                #define TOGGLE "3"
                ExecuteHam(Ham_Use, ihostie, id, id, TOGGLE, 1.0);
                set_pev(ihostie, pev_origin, Origin);
            }
            if(bRescuing)
            {
                bRescuing = false
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
