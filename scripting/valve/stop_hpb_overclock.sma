#include amxmodx
#include fakemeta

public plugin_init()
{
    register_plugin("Stop hpb_bot over-clock","1.0",".sρiηX҉.");
    register_event_ex ( "ResetHUD" , "@spawn", RegisterEvent_Single|RegisterEvent_OnlyAlive)
}

@spawn(id)
{
    if(is_user_connected(id))
    {
        set_pev(id, pev_maxspeed, 272.0)

        if(is_user_bot(id))
        {
            set_pev(id, pev_framerate, 15.0)
            set_pev(id, pev_maxspeed, 200.0)
            set_pev(id, pev_movetype, MOVETYPE_WALK)
        }
    }
}
