#include amxmodx
#include engine_stocks
#include fakemeta
#include hamsandwich

static const szHostages[][]={"hostage_entity", "monster_scientist"};

new g_cvar, bool:bRescuing, bool:bGetarea, Float:g_origin[3];

public plugin_init()
{
    register_plugin("CS2 HOSTAGES", "0.0.4", "SPiNX")
    register_logevent("logevent_hostage_rescued",3,"2=Rescued_A_Hostage");
    g_cvar = register_cvar("cs2_hostages", "1")

    static rescue_area; rescue_area=0;
    rescue_area  = find_ent(MaxClients, "func_hostage_rescue")
    
    if(rescue_area)
    {
        get_brush_entity_origin(rescue_area, g_origin)
        bGetarea = true
    }
    else
    {
        rescue_area  = find_ent(MaxClients, "info_hostage_rescue")
    }
    if(rescue_area)
    {
        get_brush_entity_origin(rescue_area, g_origin)
        bGetarea = true
    }
    if(!bGetarea)
    {
        RegisterHam(Ham_Spawn, "player", "@spawn", 1)
    }
}

@spawn(id)
{
    if(!bGetarea)
    if(is_user_alive(id) && get_user_team(id) ==2)
    {
        bGetarea = true
        pev(id, pev_origin, g_origin)
    }
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
            @hostage_one(id)
        }
    }
}

@hostage_one(id)
{
    new ihostie;

    if(is_user_alive(id))
    {
        for(new gang; gang <sizeof(szHostages);gang++)
        {
            while((ihostie = find_ent(ihostie, szHostages[gang])))
            {
                #define TOGGLE "3"
                set_pev(ihostie, pev_origin, g_origin);
                ExecuteHam(Ham_Use, ihostie, id, id, TOGGLE, 1.0);
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
