/*𝓼𝓹𝓲𝓷𝔁*/
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>

#define PLUGIN "Auto Null Parachute"
#define VERSION "0.1"
#define AUTHOR "SPiNX"
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH              16
new pAutoDeploy, pFallSpeed, pParaModel, g_model;

public plugin_init()
{
   register_plugin(PLUGIN, VERSION, AUTHOR);
   pFallSpeed  = register_cvar("parachute_fallspeed", "100");
   pAutoDeploy = register_cvar("parachute_autorip", "200");
   pParaModel  = register_cvar("parachute_model", "1");
}

public plugin_precache()

   g_model = precache_model("sprites/steam1.spr");


public client_PreThink(id)
{
   if (is_user_connecting(id) || !is_user_connected(id) || !is_user_alive(id))

      return;

   else

   {

       new Rip_Cord = get_pcvar_num(pAutoDeploy);

       new AUTO;

       AUTO = (pev(id,pev_flFallVelocity) >= (get_pcvar_num(pFallSpeed) + Rip_Cord) );

       new Float:fallspeed = get_pcvar_float(pFallSpeed) * -1.0
       new button = get_user_button(id), oldbutton = get_user_oldbutton(id), flags = get_entity_flags(id);

       if(flags & FL_ONGROUND)
       {
          if (get_user_gravity(id) == 0.1)

             set_user_gravity(id, 1.0)

          return
       }

       if(button & IN_USE|AUTO)

       {
          new Float:velocity[3]
          entity_get_vector(id, EV_VEC_velocity, velocity)
          set_user_gravity(id, 0.1)
          velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed

          if(get_pcvar_num(pParaModel))
          {
              entity_set_vector(id, EV_VEC_velocity, velocity)
              emessage_begin( MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
              ewrite_byte(TE_PLAYERATTACHMENT)
              ewrite_byte(id)
              ewrite_coord(-MAX_AUTHID_LENGTH)
              ewrite_short(g_model)
              ewrite_short(MAX_IP_LENGTH) //life
              emessage_end();
          }


       }

       else if (oldbutton & IN_USE)
          set_user_gravity(id, 1.0);
    }


}
