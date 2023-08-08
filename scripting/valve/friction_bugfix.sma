#include amxmodx
#include engine
#include fakemeta
new bMultiplayer
new bool:bReadble[MAX_PLAYERS + 1];
#define FRICTION_NOT 1.0
new const szEnt[] = "func_friction"

public plugin_init()
{
    register_plugin("Friction Bugfix","1.0.1","SPiNX")
    if(!has_map_ent_class(szEnt))
    {
        server_print "Map does not have %s..pausing...", szEnt
        pause "a"
    }
}

public client_putinserver(iPlayer)
{
    if(is_user_connected(iPlayer))
    {
        bReadble[iPlayer] = true
        bMultiplayer = get_playersnum();
    }
}

public client_disconnected(iPlayer)
{
    bReadble[iPlayer] = false
}

public client_PreThink(iPlayer)
{
    if(bMultiplayer)
    {
        if(bReadble[iPlayer] && is_user_alive(iPlayer))
        {
            static Float:get_friction; get_friction = entity_get_float(iPlayer, EV_FL_friction)
            if(get_friction != FRICTION_NOT)
            {
                entity_set_float(iPlayer, EV_FL_friction, get_friction + 0.001)
                if(get_friction > 1.0)
                {
                    entity_set_float(iPlayer, EV_FL_friction, FRICTION_NOT)
                }
                /*
                if(!task_exists(iPlayer))
                {
                    set_task(3.0, "@feedback", iPlayer)
                }
                */
            }
        }
    }
    return PLUGIN_HANDLED;
}

@feedback(iPlayer)
{
    if(is_user_connected(iPlayer))
        client_print(0, print_center, "%n,^nis on ICE!", iPlayer)
}
