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
#define VERSION "1.5"
#define AUTHOR "SPiNX"
#define MAX_PLAYERS         32
#define MAX_NAME_LENGTH     32
#define HLW_KNIFE           0x0019
#define HLW_PIPEWRENCH      18
#define charsmin                  -1

new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new g_Szsatchel_ring

new disarmament[][]=
{
    /*"monster_satchelcharge",*/
    //"monster_satchel",
    "mortar_shell",
    "monster_snark",
    "monster_tripmine",
    "monster_penguin",
    "monster_babycrab",
    "monster_grenade"
}

new g_enable, g_health
new g_SzMonster_class[MAX_NAME_LENGTH];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_SetModel,"FORWARD_SET_MODEL");

    for( new list; list < sizeof disarmament; list++)
        register_touch(disarmament[list], "player", "disarm_")

    g_enable = register_cvar("hl_satchel", "1")
    g_health = register_cvar("hl_satchel_health", "15")
}

public plugin_precache()
{
    g_Szsatchel_ring = precache_model("sprites/zerogxplode.spr")
}

public FORWARD_SET_MODEL(entid, model[])
{
    if(get_pcvar_num(g_enable))
    {
        if(pev_valid(entid) < 2
        || !equal(model,"models/w_satchel.mdl")
        //|| !equal(model,"models/w_rpg.mdl")
        //|| !equal(model,"models/w_argrenade.mdl")
        //|| !equal(model,"models/crossbow_bolt.mdl")
        //|| !equal(model,"models/w_grenade.mdl")
    )
        return FMRES_IGNORED;

        static id;
        id = pev(entid,pev_owner);

        if (id<1 || !is_user_connected(id) || is_user_connecting(id) || !is_user_alive(id) || is_user_bot(id))
            return FMRES_IGNORED;

        new Float:health = get_pcvar_float(g_health)

        set_pev(entid,pev_health,health);
        set_pev(entid,pev_takedamage,DAMAGE_AIM); //aim is bullets, yes is blast
        set_pev(entid,pev_solid,SOLID_TRIGGER);
        set_pev(entid,pev_movetype,MOVETYPE_FLY);
        set_pev(entid,pev_effects,EF_BRIGHTLIGHT); //assure settings are applying while playing
        client_cmd(id,"spk ../../valve/sound/common/launch_deny2.wav")

        emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        ewrite_byte(TE_BEAMRING)
        ewrite_short(entid)  //(start entity)
        ewrite_short(id)  //(end entity)
        ewrite_short(g_Szsatchel_ring)  //(sprite index)
        ewrite_byte(1)   //(starting frame)
        ewrite_byte(4)   //(frame rate in 0.1's)
        ewrite_byte(75)   //(life in 0.1's)
        ewrite_byte(50)   //(line width in 0.1's)
        ewrite_byte(10)   //(noise amplitude in 0.01's)
        ewrite_byte(100)   //(red)
        ewrite_byte(50)   //(green)
        ewrite_byte(75)   //(blue)
        ewrite_byte(100)   //(brightness)
        ewrite_byte(35)   //(scroll speed in 0.1's)
        emessage_end()

        new players[ MAX_PLAYERS ]
        new playercount

        get_players(players,playercount,"h")
        for (new m=0; m<playercount; m++)
        {
            new playerlocation[3]
            if(is_user_connected(players[m]))
            if(is_user_bot(players[m]) ||  !is_user_bot(players[m])) 
            {
                get_user_origin(players[m], playerlocation)
                new resultdance = get_entity_distance(entid, players[m]);
                if (resultdance < 500)
                {
                    if(players[m] != id)
                    {
                        fakedamage(players[m],"Satchel lash",75.0,DMG_ENERGYBEAM)
                        if(!is_user_bot(id))
                            client_cmd id,"spk ../../valve/sound/common/wpn_denyselect.wav"
                    }
                }
            }
        }
    }
    return FMRES_IGNORED;
}

public client_putinserver(id)
    if(is_user_connected(id))
        get_user_name(id,ClientName[id],charsmax(ClientName[]))

stock have_tool(id)
{
    if (get_user_weapon(id) == HLW_KNIFE || get_user_weapon(id) == HLW_CROWBAR || get_user_weapon(id) == HLW_PIPEWRENCH)
        return 1
    else
        return 0
}
public disarm_(entid, id)
{
    new Float:null[3];
    null[0] = -5000000.0;
    null[1] = -5000000.0;
    null[2] = -5000000.0;

    if( get_pcvar_num(g_enable) && is_valid_ent(entid) && have_tool(id))//!pev( entid, pev_owner )
    {

        entity_get_string(entid,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))
        if(containi(g_SzMonster_class, "monster_") > charsmin)
            replace(g_SzMonster_class,charsmax(g_SzMonster_class),"monster_","")

        set_pev(entid,pev_effects,EF_BRIGHTFIELD );

        client_print(0,print_center,"[ %s ]^n^n%s handled a %s.", PLUGIN, ClientName[id], g_SzMonster_class );
        if(equali(g_SzMonster_class,"tripmine"))
        {
            if(get_pcvar_num(g_enable) == 1)
            {
                entity_set_float(entid, EV_FL_dmg, 1.0);
                entity_set_vector(entid,EV_VEC_origin, null);
            }
            else if(get_pcvar_num(g_enable) > 1 && pev(id, pev_button) & IN_DUCK && pev(id, pev_oldbuttons) & IN_DUCK )
            {
                entity_set_float(entid, EV_FL_dmg, 1.0);
                entity_set_vector(entid,EV_VEC_origin, null);
            }

        }
        if(equali(g_SzMonster_class,"satchel"))
        {
            remove_entity(entid);
        }
        else
        {
            set_pev(entid,pev_solid, SOLID_NOT);//teleporter stack fix
            remove_entity(entid);
        }
        client_cmd(id,"spk weapons/debris3.wav");


    }


}

/*
#include <amxmod>
#include <VexdUM>

new g_enable, g_health;

public plugin_init()
{
	register_plugin("Destroyable Satchel Charge", "1.2", "Anggara_nothing")
	g_enable = register_cvar("hl_satchel", "1")
	g_health = register_cvar("hl_satchel_health", "100")
}

public set_model(entid, const model[])
{
	if(!(model[7] == 'w' && model[9] == 's' && model[14] == 'e' && equal(model, "models/w_satchel.mdl")))
		return PLUGIN_CONTINUE;

	if(get_cvarptr_num(g_enable) <= 0)
		return PLUGIN_CONTINUE;

	if(!is_entity(entid))
		return PLUGIN_CONTINUE;

	new id = entity_get_edict(entid, EV_ENT_owner);

	if(!id || !is_user_alive(id))
		return PLUGIN_CONTINUE;

	entity_set_float(entid, EV_FL_health, get_cvarptr_float(g_health));
	entity_set_float(entid, EV_FL_takedamage, DAMAGE_YES);

	return PLUGIN_CONTINUE;
}
*/
