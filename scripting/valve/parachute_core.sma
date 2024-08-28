/*𝓼𝓹𝓲𝓷𝔁*/
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>

#define PLUGIN "Auto Null Parachute"
#define VERSION "0.2"
#define AUTHOR "SPiNX"
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH              16
new pAutoDeploy, pFallSpeed, pParaModel, g_model, g_para_think;

public plugin_init()
{
   register_plugin(PLUGIN, VERSION, AUTHOR);
   g_para_think = register_forward(FM_PlayerPreThink, "chute_think", true)
   pFallSpeed  = register_cvar("parachute_fallspeed", "100");
   pAutoDeploy = register_cvar("parachute_autorip", "200");
   pParaModel  = register_cvar("parachute_model", "1");
}

public plugin_precache()

   g_model = precache_model("sprites/steam1.spr");


public chute_think(id)
{
    if(is_user_alive(id))
    {
        static Rip_Cord; Rip_Cord = get_pcvar_num(pAutoDeploy);
        static AUTO;

        AUTO = (pev(id,pev_flFallVelocity) >= (get_pcvar_num(pFallSpeed) + Rip_Cord) );
        static Float:fallspeed; fallspeed = get_pcvar_float(pFallSpeed) * -1.0
        static button, oldbutton, flags; button = get_user_button(id), oldbutton = get_user_oldbutton(id), flags = get_entity_flags(id);

        if(flags & FL_ONGROUND)
        {
            if (get_user_gravity(id) == 0.1)
            {
                set_user_gravity(id, 1.0)
            }
        }
        if(button & IN_USE|AUTO)
        {
            static Float:velocity[3]
            entity_get_vector(id, EV_VEC_velocity, velocity)
            set_user_gravity(id, 0.1)
            velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed

            if(get_pcvar_num(pParaModel))
            {
                entity_set_vector(id, EV_VEC_velocity, velocity)
                //emessage_begin( MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
                emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY);
                ewrite_byte(TE_PLAYERATTACHMENT)
                ewrite_byte(id)
                ewrite_coord(-MAX_AUTHID_LENGTH)
                ewrite_short(g_model)
                ewrite_short(MAX_IP_LENGTH) //life
                emessage_end();
            }

        }
        else if (oldbutton & IN_USE)
        {
            set_user_gravity(id, 1.0);
        }
    }
    return PLUGIN_HANDLED_MAIN;
}

public plugin_end()
{
    unregister_forward(FM_PlayerPreThink, g_para_think)
}
