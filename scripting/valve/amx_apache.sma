#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util //dispatch key values
#define MAGIC_NUMBER 0
#define MAX_PLAYERS 32

new g_angles[3]

new g_puff_hp
new g_puff_scale

new const apache1[]  = "models/apachet.mdl"
new const apache2[]  = "models/apache.mdl"
new const apache3[]  = "models/HVR.mdl"
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
new const apache_snds_gen[][] =
{
    "sound/apache/ap_rotor1.wav",
    "sound/apache/ap_rotor2.wav",
    "sound/apache/ap_rotor3.wav",
    "sound/apache/ap_rotor4.wav",
    "sound/apache/ap_whine1.wav",
    "sound/weapons/mortarhit.wav",
    "sound/turret/tu_fire1.wav"
}

new const smoker_precache[] = "sprites/white.spr" //and apache https://github.com/ValveSoftware/halflife/blob/master/dlls/apache.cpp

public plugin_init()
{
    register_concmd(".sprite","clcmd_test",ADMIN_CHAT,".sprite <#> - set toss velocity")
    register_concmd(".monster","clcmd_test2",ADMIN_RCON,".monster")

    g_angles = { 0.0, 0.0, 0.0 }
    g_puff_hp = register_cvar("smoke_puff_hp", "200") //20- crash easy just floating
    g_puff_scale = register_cvar("smoke_puff_scale", "10")
}



public plugin_precache()
{

    //precache_model(szModel);

    precache_model(apache1)

    precache_model(apache2)

    precache_model(apache3)

    precache_model(light)

    precache_model("models/metalplategibs_green.mdl")

    for(new needed; needed < sizeof apache_snds;needed++)
        precache_sound(apache_snds[needed])

    for(new needed; needed < sizeof apache_snds_gen;needed++)
        precache_generic(apache_snds_gen[needed])

    precache_model("sprites/fexplo.spr")
    //env_smoker
    precache_model(smoker_precache);
}

public clcmd_test(id)
{
    if(!find_ent_by_tname(-1, "apache_way_point"))
    {

        new arg[MAX_PLAYERS]
        read_argv(1,arg,charsmax(arg))
        new Float:velocity[3];
        new Float:fplayerorigin[3];
        new ent = create_entity("env_smoker");
        new Float:fsizer
        fsizer = g_puff_scale ? get_pcvar_num(g_puff_scale)*1.0 : random_float(-2.25,5.5)
        new SzScale[MAX_PLAYERS]

        float_to_str(fsizer, SzScale, charsmax(SzScale))
        entity_set_float(ent, EV_FL_scale, fsizer);

        set_pev(ent, pev_health, get_pcvar_float(g_puff_hp)); //ctrl how long smoke lasts
        fm_set_kvd(ent, "scale" , SzScale);
        fm_set_kvd(ent, "targetname", "apache_way_point")

        entity_get_vector(id, EV_VEC_origin, fplayerorigin);

        fplayerorigin[1] += 50.0
        entity_set_origin(ent, fplayerorigin);

        //Set it away from you or make yourself owner momentarily
        set_pev(ent, pev_owner, id)

        VelocityByAim(id,str_to_num(arg),velocity)

        new Float:mins[3], Float:maxs[3]

        mins[0] = -150.0
        mins[1] = -150.0
        mins[2] = -250.0

        maxs[0] = 250.0
        maxs[1] = 250.0
        maxs[2] = 120.0

        set_pev( ent, pev_frame, 0.0 )
        set_pev( ent, pev_framerate, 10.0 )


        dllfunc( DLLFunc_Spawn, ent )
    }
    else
        client_print id, print_center, "We have a waypoint already!"

    return PLUGIN_HANDLED;
}


public clcmd_test2(id)
{
    new arg[MAX_PLAYERS]
    read_argv(1,arg,charsmax(arg))
    new Float:velocity[3];
    new Float:fplayerorigin[3];

    new apache = create_entity("monster_apache");

    set_pev(apache, pev_spawnflags, SF_SPRITE_STARTON)

    //DispatchKeyValue(entity, "KeyName", "Value");
    //fm_set_kvd(apache, "gibmodel", "models/w_battery.mdl");

    entity_get_vector(id, EV_VEC_origin, fplayerorigin);

    fplayerorigin[1] += 50.0
    entity_set_origin(apache, fplayerorigin);

    //Set it away from you or make yourself owner momentarily
    set_pev(apache, pev_owner, id)

    VelocityByAim(id,str_to_num(arg),velocity)

    set_pev(apache,pev_solid, MOVETYPE_STEP) //SOLID_TRIGGER) // 1 trigger btw  solid_bsp needs MOVETYPE_PUSH  //3 slidebox fn box!
    entity_set_model(apache, apache1);

    entity_set_size(apache, Float:{-3.0,-3.0,-3.0}, Float:{3.0,3.0,3.0});
    set_pev( apache, pev_frame, 0.0 )
    set_pev( apache, pev_framerate, 10.0 )

    fm_set_kvd(apache, "rendermode", "5"); // 0 is normal //solid is 4 , 1 is color, 2 texture 3 glow //other than 3 with sprites use negative scales 5 is additive
    fm_set_kvd(apache, "renderamt", "150"); // 255 make illusionary not a blank ///////100 amt mode 3 for transparet no blk backgorund
    ///fm_set_kvd(apache, "skin", "-16"); //ladder  later
    fm_set_kvd(apache, "speed", "64")
    fm_set_kvd(apache, "renderfx", "14"); //4 slow wide pulse //16holo 14 glow 10 fast strobe
    fm_set_kvd(apache, "rendercolor", "150 25 200")
    fm_set_kvd(apache, "targetname", "amx_monster_apache")
    fm_set_kvd(apache, "target", "apache_way_point")

    set_pev( apache, pev_angles, g_angles)

    dllfunc( DLLFunc_Spawn, apache )

    return PLUGIN_HANDLED;
}
