
/*
* Appears unfinished/needs tested ::: Github
*
stock EF_ChangeYaw(const ENTITY)
    return engfunc(EngFunc_ChangeYaw, ENTITY);

stock EF_ChangePitch(const ENTITY)
    return engfunc(EngFunc_ChangePitch, ENTITY)
*
*/

//https://forums.alliedmods.net/showthread.php?t=328807&page=2
//Pitch Yaw Roll (Y Z X)

#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util //dispatch key values
#define MAGIC_NUMBER 0
#define MAX_PLAYERS 32

new iDegree, g_candy;

new g_angles[3]

new g_puff_hp
new g_puff_scale

new ibangbang;


//new const szModel[]  = "sprites/arrow1.spr"
new const szModel[]  = "models/player/gina/Gina.mdl"
new const debris1[]  = "sound/debris/pushbox1.wav"
new const debris2[]  = "sound/debris/pushbox2.wav"
new const debris3[]  = "sound/debris/pushbox3.wav"
new const glass1[]   = "sound/debris/bustglass1.wav"
new const glass2[]   = "sound/debris/bustglass2.wav"

new const battery[]  = "models/w_battery.mdl"
new const medkit[]   = "models/w_medkit.mdl"
new const smallkit[] = "sound/items/smallmedkit1.wav"
new const apache1[]  = "models/apachet.mdl"
new const apache2[]  = "models/apache.mdl"
new const apache3[]  = "models/HVR.mdl"

new const apache_snds[][] ={
"apache/ap_rotor1.wav",
"apache/ap_rotor2.wav",
"apache/ap_rotor3.wav",
"apache/ap_rotor4.wav",
"apache/ap_whine1.wav",
"weapons/mortarhit.wav",
"turret/tu_fire1.wav"
}
new const apache_snds_gen[][] ={
"sound/apache/ap_rotor1.wav",
"sound/apache/ap_rotor2.wav",
"sound/apache/ap_rotor3.wav",
"sound/apache/ap_rotor4.wav",
"sound/apache/ap_whine1.wav",
"sound/weapons/mortarhit.wav",
"sound/turret/tu_fire1.wav"
}
new const smoker_precache[] = "sprites/white.spr"




public plugin_init()
{
    register_concmd(".sprite","clcmd_test",0,".sprite <#> - set toss velocity")
    register_concmd(".monster","clcmd_test2",0,".monster")
    g_candy = register_cvar("free_shit","1")
    ibangbang = register_cvar("free_bang", "100");
    g_angles = { 0.0, 0.0, 0.0 }
    g_puff_hp = register_cvar("smoke_puff_hp", "10")
    g_puff_scale = register_cvar("smoke_puff_scale", "1000")
}



public plugin_precache()
{
    precache_generic(medkit);
    precache_generic(smallkit);

    precache_model(szModel);
    precache_generic(szModel);
    //chopper
    precache_model(apache1)
    precache_generic(apache1)

    precache_model(apache2)
    precache_generic(apache2)

    precache_model(apache3)
    precache_generic(apache3)

    precache_model("models/metalplategibs_green.mdl")
    precache_generic("models/metalplategibs_green.mdl")

    precache_model("models/w_battery.mdl")
    precache_generic("models/w_battery.mdl")


    for(new needed; needed < sizeof apache_snds;needed++)
        precache_sound(apache_snds[needed])

    for(new needed; needed < sizeof apache_snds_gen;needed++)
        precache_generic(apache_snds_gen[needed])

    precache_model("sprites/fexplo.spr")
    precache_generic("sprites/fexplo.spr")

    //env_smoker
    precache_model(smoker_precache);
    precache_generic(smoker_precache);

    precache_model("models/scientist.mdl") //for gina
    precache_generic("models/scientist.mdl") //for gina

    precache_generic("sound/scientist/sci_pain1.wav") //for amxx to load
    precache_generic("sound/scientist/sci_pain2.wav")
    precache_generic("sound/scientist/sci_pain3.wav")
    precache_generic("sound/scientist/sci_pain4.wav")
    precache_generic("sound/scientist/sci_pain5.wav")
    precache_generic("sound/scientist/sci_pain6.wav")
    precache_generic("sound/scientist/sci_pain7.wav")
    precache_generic("sound/scientist/sci_pain8.wav")
    precache_generic("sound/scientist/sci_pain9.wav")
    precache_generic("sound/scientist/sci_pain10.wav")


    precache_generic(battery); //func_pushable
    precache_generic(debris1); //func_pushable
    precache_generic(debris2); //func_pushable
    precache_generic(debris3); //func_pushable

        //breakable ent properties

    precache_generic(glass1);   //func_pushable
    precache_generic(glass2);   //func_pushable
}


public clcmd_test(id)
{
    new arg[MAX_PLAYERS]
    read_argv(1,arg,charsmax(arg))
    new Float:velocity[3];
    new Float:fplayerorigin[3];
    new ent = create_entity("env_smoker"); //"env_spritetrain" //node maker later path_corners op4 and cs? only
    //new ent = create_entity("env_spritetrain")

    //make a pushable destroyable exploding treat box

    //new Float:fsizer = random_float(-2.25,2.5) //assorted toybox sizes

    new Float:fsizer = random_float(-2.25,5.5)

    entity_set_float(ent, EV_FL_scale, fsizer);


    set_pev(ent, pev_spawnflags, SF_PUSH_BREAKABLE)
    set_pev(ent, pev_takedamage, DAMAGE_AIM);
    
    set_pev(ent, pev_health, get_pcvar_float(g_puff_hp)); //ctrl how long smoke lasts

    //set_pev(ent, pev_gravity,0.0001)

    //DispatchKeyValue(entity, "KeyName", "Value");
    //_set_kvd(ent, "gibmodel", "models/w_battery.mdl");
    //fm_set_kvd(ent, "classname", "env_smoker");
/*
    new smoke_scale[12]
    formatex(smoke_scale, charsmax(smoke_scale),"^"%i^"", get_pcvar_num(g_puff_scale)) //how big
    server_print"puff scale %s",smoke_scale*/
    fm_set_kvd(ent, "scale" , "10000000");
    
    //fm_set_kvd(ent, "targetname", "smokey");
    fm_set_kvd(ent, "targetname", "magic_arrow")
    fm_set_kvd(ent, "angles", "0 0 0");
    //new boom[4] = formatex(boom, charsmax(boom), "%i", get_pcvar_num(ibangbang))
    //fm_set_kvd(ent, "explodemagnitude", "350");
    //fm_set_kvd(ent, "angles", "270 0 0");
    //new igoodie = get_pcvar_num(g_candy); clamp(igoodie,0,9); //have no idea what drops or pops on cs except mp5, para, awp well awp and 308 used to have universal magic numbers, Hungarian spice however you like. I like chop suey.
    //fm_set_kvd(ent, "spawnobject", "1"); //armor Amxx has a huge handy page some place. 10 makes crossbow on hl yet crashes sven of all apps!! 9 is arrows 2 is medkit 8 weapon_shotgun



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


    entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);

    set_pev(ent,pev_solid, MOVETYPE_PUSH)

    entity_set_model(ent, szModel);
    //entity_set_size(ent, Float:{-3000.0,-3000.0,-3000.0}, Float:{3000.0,3000.0,3000.0});

    //entity_set_size(ent, mins, maxs);

    set_pev( ent, pev_frame, 0.0 )
    set_pev( ent, pev_framerate, 10.0 )

/*
    fm_set_kvd(ent, "rendermode", "3"); // 0 is normal //solid is 4 , 1 is color, 2 texture 3 glow //other than 3 with sprites use negative scales
    fm_set_kvd(ent, "renderamt", "255"); // 255 make illusionary not a blank ///////100 amt mode 3 for transparet no blk backgorund
    fm_set_kvd(ent, "skin", "-16"); //ladder
    fm_set_kvd(ent, "speed", "64")
    fm_set_kvd(ent, "renderfx", "3"); //4 slow wide pulse //16holo 14 glow 10 fast strobe
    fm_set_kvd(ent, "rendercolor", "6 7 255")
    fm_set_kvd(ent, "targetname", "magic_arrow")
    fm_set_kvd(ent, "target", "magic_arrow")
    fm_set_kvd(ent, "scale", "5")
    fm_set_kvd(ent, "friction", "1") //stock is 20
*/

    set_pev( ent, pev_angles, g_angles)

    dllfunc( DLLFunc_Spawn, ent )

    set_task(random_float(10.0,44.0),"ChangeYaw", ent,_,_,"b")

    return PLUGIN_HANDLED;
}

public shape_shifter(ent)
{
//Too much work and no play! ...
///0.clientemp:    formatex(g_szFile[0], charsmax(g_szFile), "%s/%s", g_filepath, g_szRequired_Files[0]);
//if something then ? ChangeYaw : hiya!

}


public ChangeYaw(ent) //iDegree
{

    new Float:HALF_A_CIRCLE = 270.0
    new Float:Origin[3]
    new Float:Axis[3]

    if(pev_valid(ent))

    {
   /*     switch(random_num(2,3)){
        case 2: entity_set_string(ent,EV_SZ_classname,"env_spritetrain")
        case 3: entity_set_string(ent,EV_SZ_classname,"func_pushable")
    }
     */
        //entity_set_string(ent,EV_SZ_classname,"env_spritetrain") //func_pushable
        //entity_set_string(ent,EV_SZ_classname,"func_pushable"

        set_pev(ent, pev_owner, 0);
        //entity_set_string(ent,EV_SZ_classname,"func_pushable");
        entity_get_vector(ent,EV_VEC_origin,Origin);
        entity_get_vector(ent,EV_VEC_angles,Axis);

        new const Float:shift = HALF_A_CIRCLE

        new Float:X = Axis[0]
        new Float:Y = Axis[1]
        new Float:Z = Axis[2]

        if(Y <= 0.0)
        {
            Y = (Axis[1] - shift)
            server_print("increasing yaw to %f",  Y-shift);
        }
        else
            Y = (Axis[1] + shift + shift)

        if(X >= 0.0)
        {
            X = (Axis[0] - shift - shift)
            //server_print("decreasing yaw");
        }
        else
            X = (Axis[0] + shift + shift)

            //(Axis[1] ? = Axis[1]+shift : Axis[1]-shift)

        //if(!task_exists(ent))
         //   set_task(random_float(5.0,10.0),ent,"ChangeYaw");

        set_pev( ent, pev_angles, Y) //engfunc(EngFunc_WriteAngle, Y);
        set_pev( ent, pev_angles, X) //engfunc(EngFunc_WriteAngle, Y);


    }

    //else

     //   return MAGIC_NUMBER

    return PLUGIN_CONTINUE;
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
    fm_set_kvd(apache, "gibmodel", "models/w_battery.mdl");

    entity_get_vector(id, EV_VEC_origin, fplayerorigin);

    fplayerorigin[1] += 50.0
    entity_set_origin(apache, fplayerorigin);

    //Set it away from you or make yourself owner momentarily
    set_pev(apache, pev_owner, id)

    VelocityByAim(id,str_to_num(arg),velocity)




    set_pev(apache,pev_solid, MOVETYPE_STEP) //SOLID_TRIGGER) // 1 trigger btw  solid_bsp needs MOVETYPE_PUSH  //3 slidebox fn box!
    entity_set_model(apache, apache1);

    entity_set_size(apache, Float:{-30000.0,-30000.0,-30000.0}, Float:{30000.0,30000.0,30000.0});
    set_pev( apache, pev_frame, 0.0 )
    set_pev( apache, pev_framerate, 10.0 )
    entity_set_float(apache, EV_FL_scale, random_float(0.1,0.5));


    fm_set_kvd(apache, "rendermode", "5"); // 0 is normal //solid is 4 , 1 is color, 2 texture 3 glow //other than 3 with sprites use negative scales 5 is additive
    fm_set_kvd(apache, "renderamt", "150"); // 255 make illusionary not a blank ///////100 amt mode 3 for transparet no blk backgorund
    //fm_set_kvd(apache, "skin", "-16"); //ladder
    fm_set_kvd(apache, "speed", "64")
    fm_set_kvd(apache, "renderfx", "14"); //4 slow wide pulse //16holo 14 glow 10 fast strobe
    fm_set_kvd(apache, "rendercolor", "150 25 200")
    fm_set_kvd(apache, "targetname", "amx_monster")
    fm_set_kvd(apache, "target", "magic_arrow")


    set_pev( apache, pev_angles, g_angles)

    dllfunc( DLLFunc_Spawn, apache )


    return PLUGIN_HANDLED;
}
