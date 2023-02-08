#include amxmodx
#include engine
#include fakemeta
new bMultiplayer
new bool:bReadble[MAX_PLAYERS + 1];
#define FRICTION_NOT 1.0

public plugin_init()
{
    register_plugin("Friction Bugfix","1.0.0","SPiNX")
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
    bMultiplayer = get_playersnum();
}

public client_PreThink(iPlayer)
{
    if(bReadble[iPlayer] && is_user_alive(iPlayer))
    {
        new Float:get_friction = entity_get_float(iPlayer, EV_FL_friction)
        if(get_friction != FRICTION_NOT)
        {
            bMultiplayer ? client_print(0, print_center, "%n,^nis on ICE!", iPlayer) : client_print(iPlayer, print_center, "Ice!")
            entity_set_float(iPlayer, EV_FL_friction, get_friction + 0.001)
            if(get_friction > 1.0)
            {
                entity_set_float(iPlayer, EV_FL_friction, FRICTION_NOT)
            }
        }
    }
    return PLUGIN_HANDLED;
}

