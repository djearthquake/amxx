#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util
#define MAX_PLAYERS 32

new g_puff_hp
new g_puff_scale

new const apache3[]  = "models/HVR.mdl"
new const apache4[]  = "models/blkop_apache.mdl"
new const apache5[]  = "models/blkop_apachet.mdl"
new const light[]    = "sprites/lgtning.spr"

new const apache_snds[][] =
{
    "apache/ap_rotor1.wav",
    "apache/ap_rotor2.wav",
    "apache/ap_rotor3.wav",
    "apache/ap_rotor4.wav",
    "apache/ap_whine1.wav",
    "weapons/mortarhit.wav",
    "turret/tu_fire1.wav"
}

new const smoker_precache[] = "sprites/white.spr"
public plugin_init()
{
    register_concmd(".sprite_blk_ops","clcmd_way",ADMIN_CHAT,".sprite_blk_ops - waypoint bind")
    register_concmd(".monster_blk_ops","clcmd_monster",ADMIN_RCON,".monster_blk_ops - monster bind")

    g_puff_hp = register_cvar("smoke_puff_hp", "7")
    g_puff_scale = register_cvar("smoke_puff_scale", "500")
}

public plugin_precache()
{
    precache_model(apache3)
    precache_model(apache4)
    precache_model(apache5)

    precache_model(light)
    precache_model("sprites/fexplo.spr")
    precache_model("models/metalplategibs_green.mdl")
    precache_model("models/metalplategibs_dark.mdl")

    for(new needed; needed < sizeof apache_snds;needed++)
    {
        precache_sound(apache_snds[needed])
        //Generic cache of sounds
        new SzReformat_SND_generic[MAX_PLAYERS]
        formatex(SzReformat_SND_generic,charsmax(SzReformat_SND_generic),"sound/%s",apache_snds[needed])
        precache_generic(SzReformat_SND_generic)
    }

    precache_model(smoker_precache);
}

public clcmd_way(id)
{
    if(!find_ent_by_tname(-1, "blk_apache_way_point"))
    {

        new arg[MAX_PLAYERS]
        read_argv(1,arg,charsmax(arg))
        new Float:fplayerorigin[3];
        new ent = create_entity("env_smoker");
        new Float:fsizer
        fsizer = g_puff_scale ? get_pcvar_num(g_puff_scale)*1.0 : random_float(-2.25,5.5)
        new SzScale[MAX_PLAYERS]

        float_to_str(fsizer, SzScale, charsmax(SzScale))
        entity_set_float(ent, EV_FL_scale, fsizer);

        set_pev(ent, pev_health, get_pcvar_float(g_puff_hp)); //ctrl how long smoke lasts
        fm_set_kvd(ent, "scale" , SzScale);
        fm_set_kvd(ent, "targetname", "blk_apache_way_point")

        entity_get_vector(id, EV_VEC_origin, fplayerorigin);

        fplayerorigin[1] += 50.0
        entity_set_origin(ent, fplayerorigin);
        
        set_pev(ent, pev_owner, id)

        dllfunc( DLLFunc_Spawn, ent )
    }
    else
        client_print id, print_center, "We have a waypoint already!"

    return PLUGIN_HANDLED;
}


public clcmd_monster(id)
{
    if(!find_ent(-1, "monster_blkop_apache"))
    {
        new arg[MAX_PLAYERS]
        read_argv(1,arg,charsmax(arg))
        new Float:fplayerorigin[3];
    
        new apache = create_entity("monster_blkop_apache");
    
        entity_get_vector(id, EV_VEC_origin, fplayerorigin);
    
        fplayerorigin[1] += 50.0 //offside
        fplayerorigin[2] += 2000.0 //overhead

        entity_set_origin(apache, fplayerorigin);
    
        set_pev(apache, pev_owner, id)

        fm_set_kvd(apache, "rendermode", "0"); // 0 is normal //solid is 4 , 1 is color, 2 texture 3 glow //other than 3 with sprites use negative scales 5 is additive
        fm_set_kvd(apache, "renderamt", "150"); // 255 make illusionary not a blank ///////100 amt mode 3 for transparet no blk backgorund
        fm_set_kvd(apache, "speed", "64")
        fm_set_kvd(apache, "renderfx", "14"); //4 slow wide pulse //16holo 14 glow 10 fast strobe
        fm_set_kvd(apache, "rendercolor", "150 25 200")
        fm_set_kvd(apache, "targetname", "blk_amx_monster_apache")
        fm_set_kvd(apache, "target", "blk_apache_way_point")

        dllfunc( DLLFunc_Spawn, apache )
        return PLUGIN_HANDLED;
    }
    else
   
        client_print id, print_center, "We already have a blk ops copter dispatched!^n^nOne will have to due."
    return PLUGIN_CONTINUE;
}
