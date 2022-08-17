 /*
  * 
  * Thanks to Destroyable Satchel Charge by Anggara_nothing for some code to jump start project.
  * 
  * This is a replacement upgrade with new author and new name as idea was totally different:
  * 
  * 
  *  * DISARM * 
  * 
  * Appreciate the destroyable aspect after being trapped in a teleport once. That's suicide though.
  * 
  * This will let you dismarm and otherwise never pin 'players' anymore who are equipped with a knife.
  * 
  * Satchels can still pin objects.
  * 
  * Earlier on I had some of that nonsense fixed simply by making satchels solid_not.
  * Test it. Send feedback. Even if I am not around, this is easy to maintain.
  * 
  */

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hlsdk_const>

#define PLUGIN "Disarmable Satchel Mine"
#define VERSION "1.3"
#define AUTHOR "SPiNX"
#define HLW_KNIFE           0x0019
#define HLW_PIPEWRENCH      18

new g_enable, g_health;
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_SetModel,"FORWARD_SET_MODEL");


    register_touch("monster_satchelcharge", "player", "disarm_satchel");
    register_touch("monster_snark", "player", "disarm_snark");
    register_touch("monster_tripmine", "player", "disarm_mine");

    register_touch("weapon_egon", "player", "egon");


    g_enable = register_cvar("hl_satchel", "0")
    g_health = register_cvar("hl_satchel_health", "100")
}

public FORWARD_SET_MODEL(entid, model[])
{
    if(!get_pcvar_num(g_enable) || !pev_valid(entid) || !equal(model,"models/w_satchel.mdl"))
        return FMRES_IGNORED;

    static id;
    id = pev(entid,pev_owner);

    if (!id || !is_user_connected(id) || !is_user_alive(id) || is_user_bot(id))
        return FMRES_IGNORED;

    new Float:health = get_pcvar_float(g_health)

    set_pev(entid,pev_health,health);
    set_pev(entid,pev_takedamage,DAMAGE_YES);
    set_pev(entid,pev_solid,SOLID_TRIGGER);

    return FMRES_IGNORED;
}


public egon(ent, id)

{
    client_print(0,print_center,"%n found an Egon!", id);
}


public disarm_satchel(entid, id)

{
    if(/*!pev( entid, pev_owner ) &&*/ (get_user_weapon(id) == HLW_KNIFE && pev(id, pev_button) & IN_DUCK && pev(id, pev_oldbuttons) & IN_DUCK || get_user_weapon(id) == HLW_PIPEWRENCH)
    && is_valid_ent(entid) )

    {
    client_print(0,print_center,"[ %s ]^n^nSatchel disarmed by %n.", PLUGIN, id);
    set_pev(entid,pev_solid, SOLID_NOT);
    remove_entity(entid);
    client_cmd(id,"spk weapons/debris3.wav");
    }
}

public disarm_snark(entid, id)

{
    if(/*!pev( entid, pev_owner ) &&*/ (get_user_weapon(id) == HLW_KNIFE && pev(id, pev_button) & IN_DUCK && pev(id, pev_oldbuttons) & IN_DUCK || get_user_weapon(id) == HLW_PIPEWRENCH)
    && is_valid_ent(entid) )

    {
    client_print(0,print_center,"[ %s ]^n^nSnark smashed by %n.", PLUGIN, id);
    set_pev(entid,pev_solid, SOLID_NOT);
    remove_entity(entid);
    client_cmd(id,"spk weapons/debris3.wav");
    }
}

public disarm_mine(entidm, id)

{

    new Float:null[3];
    null[0] = -5000000.0;
    null[1] = -5000000.0;
    null[2] = -5000000.0;

    if ( get_user_weapon(id) == HLW_KNIFE && pev(id, pev_button) & IN_USE && pev(id, pev_oldbuttons) & IN_USE || get_user_weapon(id) == HLW_PIPEWRENCH )

    if(is_valid_ent(entidm))

        {
            entity_set_float( entidm, EV_FL_dmg, 1.0);
            entity_set_vector( entidm,EV_VEC_origin, null);
            client_cmd(id,"spk weapons/debris3.wav");
            client_print(0,print_center,"[ %s ]^n^nMine dismantled by %n.", PLUGIN, id);
        }

}
