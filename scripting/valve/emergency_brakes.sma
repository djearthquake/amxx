#include amxmodx
#include engine_stocks
#include fakemeta

#define IDLE_SPEED 0.1
#define GO_SPEED 1200.0

new cvar_range;
static const CARS[]= "func_vehicle"
static m_speed, g_mod_car[MAX_PLAYERS +1]

const LINUX_DIFF = 5;
const LINUX_OFFSET_WEAPONS = 4;

public plugin_init()
{
    register_plugin( "Auto Braking", "0.0.1", "SPiNX" );

    #if !defined MaxClients
    #define MaxClients get_maxplayers( )
    #endif

    if(!find_ent(MaxClients, CARS))
    {
        pause "d"
    }

    cvar_range = register_cvar("brake_range", "250")
    m_speed = (find_ent_data_info("CFuncVehicle", "m_speed")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF
}

public client_command(id)
{
    static iRange; iRange = get_pcvar_num(cvar_range)
    if(iRange)

    if(is_driving(id))
    {
        is_driving(id) ? set_task(0.1, "@brake_think", id, _,_, "b") : remove_task(id)
    }
}

@brake_think(id)
{
    static iRange; iRange = get_pcvar_num(cvar_range)
    if(iRange)

    if(is_user_alive(id))
    {
        if(is_driving(id))
        {
            for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
            {
                if(is_user_alive(iPlayer))
                {
                    if(iPlayer != id)
                    {
                        if(get_user_team(iPlayer) == get_user_team(id))
                        {
                            static iDistance; iDistance = get_entity_distance(id, iPlayer)

                            if( iDistance < iRange)
                            {
                                set_pdata_float(g_mod_car[id], m_speed, IDLE_SPEED, LINUX_DIFF)
                                client_print( id, print_center, "EMERGENCY BRAKES ENGAGED!^n^n%n was nearly ran down!!", iPlayer)
                            }
                            else
                            {
                                set_pdata_float(g_mod_car[id], m_speed, GO_SPEED, LINUX_DIFF)
                            }
                        }
                    }
                }
            }
        }
    }
}

public pfn_touch(ptr, ptd)
{
    static iCar; iCar = get_pcvar_num(cvar_range)

    if(iCar)
    {
        if(is_user_alive(ptr) && pev_valid(ptd))
        {
            static iPlayer;iPlayer = ptr
            if(is_driving(iPlayer))
            {
                g_mod_car[iPlayer] = ptd
            }
        }
    }
}

stock is_driving(iPlayer)
{
    if(is_user_alive(iPlayer))
    {
        return pev(iPlayer,pev_flags) & FL_ONTRAIN
    }
    return PLUGIN_HANDLED
}
