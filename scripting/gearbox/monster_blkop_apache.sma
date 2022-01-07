#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util
#define MAX_PLAYERS 32

new g_puff_hp
new g_puff_scale

new const apache_model[][] =
{
    "models/HVR.mdl",
    //grn
    "models/apachet.mdl",
    "models/apache.mdl",
    //blk
    "models/blkop_apache.mdl",
    "models/blkop_apachet.mdl",
    "sprites/lgtning.spr",
    "sprites/fexplo.spr",
    "models/metalplategibs_green.mdl",
    "models/metalplategibs_dark.mdl",
    //waypoint smoke
    "sprites/white.spr"
}

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

public plugin_init()
{
    //waypointing
    g_puff_hp = register_cvar("smoke_puff_hp", "7")
    g_puff_scale = register_cvar("smoke_puff_scale", "500")
    //Apache
    register_concmd(".apache","clcmd_apache",ADMIN_CHAT,".apache - makes apache. Add black to make BlackOps")
    register_concmd(".apache_way","clcmd_apache_waypoint",ADMIN_RCON,".apache_way - makes apache waypoint. Append black to make BlackOps")
}

public plugin_precache()
{
    for(new list; list < sizeof apache_model;list++)
    {
        precache_model(apache_model[list])
        precache_generic(apache_model[list])
    }

    for(new list; list < sizeof apache_snds;list++)
    {
        precache_sound(apache_snds[list])

        //Generic cache of sounds
        new SzReformat_SND_generic[MAX_PLAYERS]
        formatex(SzReformat_SND_generic,charsmax(SzReformat_SND_generic),"sound/%s",apache_snds[list])
        precache_generic(SzReformat_SND_generic)
    }

}

public clcmd_apache_waypoint(id)
{
    new bool:bOps
    if(is_user_alive(id))
    {
        new arg[MAX_PLAYERS]
        read_argv(1,arg,charsmax(arg))
        new way_type[MAX_PLAYERS]

        if(containi(arg,"black") > -1 && !find_ent_by_tname(-1, "blk_apache_way_point"))
        {
            way_type = "blk_apache_way_point"
            bOps = true
        }
        else if(!find_ent_by_tname(-1, "apache_way_point"))
            way_type = "apache_way_point"
        else goto PRINT
        
        new Float:fplayerorigin[3];
        new ent = create_entity("env_smoker");
        new Float:fsizer
        fsizer = g_puff_scale ? get_pcvar_num(g_puff_scale)*1.0 : random_float(-2.25,5.5)
        new SzScale[MAX_PLAYERS]

        float_to_str(fsizer, SzScale, charsmax(SzScale))
        entity_set_float(ent, EV_FL_scale, fsizer);

        set_pev(ent, pev_health, get_pcvar_float(g_puff_hp)); //ctrl how long smoke lasts
        fm_set_kvd(ent, "scale" , SzScale);
        
        fm_set_kvd(ent, "targetname", way_type) 

        entity_get_vector(id, EV_VEC_origin, fplayerorigin);

        fplayerorigin[1] += 50.0
        entity_set_origin(ent, fplayerorigin);


        dllfunc( DLLFunc_Spawn, ent )
    }
    else
    {
        PRINT:
        if(bOps)
            client_print(id, print_center, "Apache waypoint already defined.")
        else
            client_print(id, print_center, "Black Ops Apache waypoint already defined.")
    }

    return PLUGIN_HANDLED;
}

public clcmd_apache(id)
{
    new bool:bOps
    if(is_user_alive(id))
    {
        new arg[MAX_PLAYERS]
        
        read_argv(1,arg,charsmax(arg))
        new plane_type[MAX_PLAYERS]

        if(containi(arg,"black") > -1 && !find_ent(-1, "monster_blkop_apache"))
        {
            plane_type = "monster_blkop_apache"
            bOps = true
        }
        else if(!find_ent(-1, "monster_apache"))
            plane_type = "monster_apache"
        else goto PRINT

        new Float:fplayerorigin[3];

        new apache = create_entity(plane_type);

        entity_get_vector(id, EV_VEC_origin, fplayerorigin);

        fplayerorigin[1] += 50.0 //offside
        fplayerorigin[2] += 100.0 //overhead

        entity_set_origin(apache, fplayerorigin);

        //set_pev(apache, pev_owner, id) //If you want credit for it's work. Rapid Hookgrab makes crashing server an easy task.

        fm_set_kvd(apache, "rendermode", "0"); // 0 is normal //solid is 4 , 1 is color, 2 texture 3 glow //other than 3 with sprites use negative scales 5 is additive
        fm_set_kvd(apache, "renderamt", "150"); // 255 make illusionary not a blank ///////100 amt mode 3 for transparet no blk backgorund
        fm_set_kvd(apache, "speed", "64")
        fm_set_kvd(apache, "renderfx", "14"); //4 slow wide pulse //16holo 14 glow 10 fast strobe
        fm_set_kvd(apache, "rendercolor", "150 25 200")
        if(bOps)
        {
            fm_set_kvd(apache, "targetname", "blk_amx_monster_apache")
            fm_set_kvd(apache, "target", "blk_apache_way_point")
        }
        else
        {
            fm_set_kvd(apache, "targetname", "amx_monster_apache")
            fm_set_kvd(apache, "target", "apache_way_point")
        }

        dllfunc( DLLFunc_Spawn, apache )
        return PLUGIN_HANDLED;
    }
    else
    {
        PRINT:
        if(bOps)
            client_print(id, print_center, "Black Ops Apache is dispatched already!^n^nOne will have to due.")
        else
            client_print(id, print_center, "We already have Apache dispatched!^n^nOne will have to due.")
    }
    return PLUGIN_CONTINUE;
}
