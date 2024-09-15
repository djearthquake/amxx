#include amxmodx
#include engine
#include fakemeta

new g_touching_jeep[MAX_PLAYERS +1]

public plugin_init()
{
    register_plugin( "Jeep unsticking", "0.0.2", "SPiNX" );
    register_concmd("unstick","@unstick",0,": Unstick from jeep.");
    register_touch("func_vehicle", "player", "@jeep")
}

@unstick(id)
{
    if(is_user_alive(id) && g_touching_jeep[id])
    {
        client_print id, print_chat, "Trying to unstick you!"

        static Float:Origin[3]
        pev(id, pev_origin, Origin)
        Origin[2] += 100.0

        set_pev(id, pev_origin, Origin)
        set_task 1.5, "@untouch", id,_,_, "a", 3
    }
    return PLUGIN_HANDLED
}

@untouch(id)
{
    if(id & id <=MaxClients)
    {
        g_touching_jeep[id] = false
    }
}

@jeep(iCar, iPlayer)
{
    if(is_user_alive(iPlayer) && pev_valid(iCar))
    {
        static iDistance; iDistance = get_entity_distance(iCar, iPlayer)
        g_touching_jeep[iPlayer] =  iDistance ? true : false
    }
}
