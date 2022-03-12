#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#define MAX_PLAYERS     32
#define PERMISSION ADMIN_ALL //ADMIN_CHAT

#define FRICTION_NOT    1.0
#define FRICTION_MUD    1.8
#define FRICTION_ICE    0.3
#define charsmin        -1

new g_puff_hp
new g_puff_scale
new bool:bSpec_Apache_Owner_lock[MAX_PLAYERS], bool:bApache_Owner_lock[MAX_PLAYERS]

new const grunt_sounds[][]=
{
    "weapons/saw_fire1.wav",
    "weapons/saw_fire2.wav",
    "weapons/saw_fire3.wav",
    "fgrunt/medic.wav",
    "fgrunt/death1.wav",
    "fgrunt/death2.wav",
    "fgrunt/death3.wav",
    "fgrunt/death4.wav",
    "fgrunt/death5.wav",
    "fgrunt/death6.wav",
    "fgrunt/pain1.wav",
    "fgrunt/pain2.wav",
    "fgrunt/pain3.wav",
    "fgrunt/pain4.wav",
    "fgrunt/pain5.wav",
    "fgrunt/pain6.wav",
    "fgrunt/gr_pain6.wav",
    "fgrunt/gr_pain1.wav",
    "fgrunt/gr_pain2.wav",
    "fgrunt/gr_pain3.wav",
    "fgrunt/gr_pain4.wav",
    "fgrunt/gr_pain6.wav",
    "fgrunt/gr_pain6.wav",
    "hgrunt/affirmative!.wav",
    "hgrunt/affirmative.wav",
    "hgrunt/alert!.wav",
    "hgrunt/alert.wav",
    "hgrunt/got.wav",
    "hgrunt/go!.wav",
    "hgrunt/go.wav",
    "hgrunt/gr_alert1.wav",
    "hgrunt/gr_die1.wav",
    "hgrunt/gr_die2.wav",
    "hgrunt/gr_die3.wav",
    "hgrunt/grenade!.wav",
    "hgrunt/gr_idle1.wav",
    "hgrunt/gr_idle2.wav",
    "hgrunt/gr_idle3.wav",
    "hgrunt/gr_loadtalk.wav",
    "hgrunt/gr_mgun1.wav",
    "hgrunt/gr_mgun2.wav",
    "hgrunt/gr_mgun3.wav",
    "hgrunt/gr_pain1.wav",
    "hgrunt/gr_pain2.wav",
    "hgrunt/gr_pain3.wav",
    "hgrunt/gr_pain4.wav",
    "hgrunt/gr_pain5.wav",
    "hgrunt/gr_reload1.wav",
    "hgrunt/gr_step1.wav",
    "hgrunt/gr_step2.wav",
    "hgrunt/gr_step3.wav",
    "hgrunt/gr_step4.wav",
    "zombie/claw_miss2.wav",
    "zombie/claw_miss1.wav"

}

new const apache_model[][] =
{
    //osprey
    "models/hgrunt.mdl",
    "sprites/rope.spr",
    "models/osprey.mdl",
    "models/osprey_tailgibs.mdl",
    "models/osprey_bodygibs.mdl",
    "models/osprey_enginegibs.mdl",
    "models/crashed_osprey.mdl",
    "models/blkop_osprey.mdl",
    "models/blkop_ospreyt.mdl",
    "models/blkop_dead_osprey.mdl",
    "models/blkop_dead_osprey.mdl",
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
    "hgrunt/gr_mgun1.wav",
    "ambience/osprey_rotors.wav",
    "misc/osprey_takeoff.wav",
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
    is_running("gearbox") || is_running("sven") ?
    register_plugin("OP4 Apache", "1.0", ".sρiηX҉.") : register_plugin("Apache(not_loaded)", "Incompatible-mod", ".sρiηX҉.")
    //Sven Copters (and all monsters) are always enticed to attack humans and follow them. Op4 they are stationary yet attack until waypoint puff of smoke is made.
    //Can own copter and attack does no damage. Bind view to see from their perspective and fly off when in limp mod from bumping objects.

    //Sensors
    register_touch("monster_apache", "*", "@Apache_Sensor")
    register_touch("monster_blkop_apache", "*", "@Apache_Sensor")
    register_touch("monster_apache", "worldspawn", "@Apache_World")
    register_touch("monster_blkop_apache", "worldspawn", "@Apache_World")
    register_touch("monster_osprey", "*", "@Apache_Sensor")
    register_touch("monster_osprey", "worldspawn", "@Apache_World")

    //waypointing
    g_puff_hp = register_cvar("smoke_puff_hp", "200") //HP is how long puff lasts. Dev Comment: Too short of time/HP may contribute to instability with OP4. 
    g_puff_scale = register_cvar("smoke_puff_scale", "100") //How big is the cloud of smoke. Dev Comment: Have fun. Makes mod more realistic.

    //Apache
    register_concmd(".apache_buy","clcmd_apache_buy",PERMISSION,".apache_buy - Befriend the apache")
    register_concmd(".apache","clcmd_apache",PERMISSION,".apache - makes apache. Add black to make BlackOps")
    register_concmd(".apache_way","clcmd_apache_waypoint",PERMISSION,".apache_way - makes apache waypoint. Append black to make BlackOps")
    register_concmd(".apache_view","clcmd_apache_view",PERMISSION,".apache_view - Look from Apache pilot seat. Reset your view.")

    RegisterHam(Ham_Killed, "player", "client_disconnected", 1) //copter crashing just from owner respawning

    register_dictionary("common.txt")
}


//WHAT IF APACHE TOUCHES SOMETHING?
@Apache_Sensor(Apache, Sensor) //standard apache crashing with both monsters merged into 1 fcn.
{
    if(pev_valid(Apache) == 2)
    {
        new SzMonster_class[MAX_PLAYERS], SzSensor_class[MAX_PLAYERS]
        entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))

        if(pev_valid(Sensor) && containi(SzMonster_class, "apache") != charsmin || containi(SzMonster_class, "osprey") != charsmin)
        {
            entity_get_string(Sensor,EV_SZ_classname,SzSensor_class,charsmax(SzSensor_class))
            //client_print 0, print_center, "%s is next to^n^n%s",SzMonster_class, SzSensor_class //use HUD overflowing on chats
    
            
            if(equali(SzSensor_class,"func_breakable") || equali(SzSensor_class,"Hook_rope") || containi(SzSensor_class,"monster") > charsmin && containi(SzSensor_class,"apache") == charsmin/*copters touch explode otherwise*/)
            {
                ///@Apache_World(Apache)
                //ExecuteHam(Ham_TakeDamage,Apache,Sensor,Apache,50.0,DMG_CRUSH|DMG_ALWAYSGIB)
                ExecuteHam(Ham_TakeDamage,Sensor,Apache,Sensor,5.0,DMG_SLASH|DMG_ALWAYSGIB)
            }
            else if(equali(SzSensor_class,"func_pushable"))
            {
                set_pev(Sensor, pev_movetype, MOVETYPE_BOUNCE)
            }
            else if(equali(SzSensor_class,"player"))
            {
                new Player = Sensor
                @Apache_Player(Apache, Player)
            }
            else if(containi(SzSensor_class,"apache") > charsmin && pev_valid(Sensor) == 2)
            {
                //still crashed when colliding in air. {Pick one with whatever hp then make that one drop etc?
                entity_set_int(Apache, EV_INT_solid, SOLID_NOT)
                entity_set_float(Apache, EV_FL_friction, FRICTION_ICE)
                set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE)
                set_task(random_num(1,5)*1.5,"@return_body",Apache)

                entity_set_int(Sensor, EV_INT_solid, SOLID_NOT)
                entity_set_float(Sensor, EV_FL_friction, FRICTION_ICE)
                set_pev(Sensor, pev_movetype, MOVETYPE_BOUNCE)
                set_task(random_num(1,5)*1.5,"@return_body",Sensor)
            }
            else
            {
                client_print 0, print_center, "%s is next to^n^n%s",SzMonster_class, SzSensor_class
                if(entity_intersects(Apache, Sensor))
                //if(entity_intersects(Apache, *))
                    set_task(random_num(1,3)*1.5,"@return_body",Apache)

            }
        }
    }
}
//PUT PROPERTIES BACK TO STOCK
@return_body(Apache)
{
    new SzMonster_class[MAX_PLAYERS]
    pev_valid(Apache) ? entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class)) : client_print( 0, print_console, "Craft hit some ripples...")

    if( containi(SzMonster_class, "apache") != charsmin || containi(SzMonster_class, "osprey") != charsmin && pev_valid(Apache) == 2 )
    {
        ///if(pev(Apache, pev_owner) > 0 && is_user_alive(pev(Apache, pev_owner)) || pev(Apache, pev_owner) > 32 && is_valid_ent(Apache))
        {
            //client_print 0, print_console, "Changing physics!"
            new SzMonster_class[MAX_PLAYERS]
            entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
            set_pev(Apache, pev_movetype, MOVETYPE_FLY)
            entity_set_int(Apache, EV_INT_solid, SOLID_BBOX)
    
            ///entity_set_float(Apache, EV_FL_friction, FRICTION_NOT)
    
            client_print 0, print_center, "%s back on course", SzMonster_class
        }
    }
}
//When copter runs into a player
@Apache_Player(Apache, Player)
if( is_user_alive(Player) && pev_valid(Apache) == 2 )
{
    new SzMonster_class[MAX_PLAYERS]
    entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
    //if( containi(SzMonster_class, "apache") != charsmin && pev_valid(Apache) == 2 )
    if( containi(SzMonster_class, "apache") != charsmin && pev_valid(Apache) == 2 && is_user_alive(Player) )
    //if(is_user_connected(Player) && pev_valid(Apache) == 2)
    {
        new SzMonster_class[MAX_PLAYERS]
        entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
        client_print 0, print_center, "%s is on %n", SzMonster_class, Player
        set_pev(Apache, pev_movetype, MOVETYPE_BOUNCEMISSILE) //very good for human to personally unstick copter from worldspawn if it has a patch to glide down
        //set_pev(Apache, pev_movetype,MOVETYPE_FOLLOW) //freezes it/catches it
        //set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE) 
    }
    //set_task(2.0,"@return_body",Apache)
}
//When copter hits worldspawn ents
@Apache_World(Apache)
{
    ///client_print 0, print_console, "Apache is on world"
    new SzMonster_class[MAX_PLAYERS]
    entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
    if( containi(SzMonster_class, "apache") != charsmin || containi(SzMonster_class, "osprey") != charsmin && pev_valid(Apache) == 2 )
    {
        new SzMonster_class[MAX_PLAYERS]
        entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
        ///client_print 0, print_chat, "%s is colliding with world.", SzMonster_class
        entity_set_int(Apache, EV_INT_solid, SOLID_NOT)
        entity_set_float(Apache, EV_FL_friction, FRICTION_ICE)
        set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE)
        //set_pev(Apache, pev_movetype, MOVETYPE_STEP )
        //entity_set_float(Apache, EV_FL_friction, FRICTION_ICE)
        //set_pev(Apache, pev_movetype, MOVETYPE_BOUNCEMISSILE) //crashing
        //set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE ) //Still stuck world
        set_task(random_num(1,3)*1.5,"@return_body",Apache)
    }
}
//NO CRASH WHEN APACHE PLUGIN OPENED
public plugin_precache()
{
    precache_model("models/hgrunt.mdl") //reg
    precache_model("models/hgrunt_opfor.mdl") //ally
    precache_model("models/gib_hgrunt.mdl")

    for (new list;list < sizeof grunt_sounds;list++)
        precache_sound(grunt_sounds[list])

    for(new list; list < sizeof apache_model;list++)
    {
        precache_model(apache_model[list])
        //precache_generic(apache_model[list])
    }

    for(new list; list < sizeof apache_snds;list++)
    {
        precache_sound(apache_snds[list])

        //Generic cache of sounds

        new SzReformat_SND_generic[MAX_PLAYERS]
        formatex(SzReformat_SND_generic,charsmax(SzReformat_SND_generic),"sound/%s",apache_snds[list])
        //precache_generic(SzReformat_SND_generic)

    }

}
//APACHE RIDES
public clcmd_apache_view(id)
{
    if(is_user_connected(id))
    {
        new arg[MAX_PLAYERS]
        new black_plane
        new plane
        read_argv(1,arg,charsmax(arg))

        black_plane = find_ent(charsmin, "monster_blkop_apache")
        plane = find_ent(charsmin, "monster_apache")
        if(black_plane && containi(arg,"black") > charsmin)
        {
            attach_view(id,black_plane)
            @return_body(black_plane)
        }
        else if(plane && containi(arg,"green") > charsmin)
        {
            attach_view(id,plane)
            entity_set_int(plane, EV_INT_solid, SOLID_NOT) 
            @return_body(plane)
        }
        else if((black_plane || plane ) && containi(arg,"me") > charsmin)
        {
            attach_view(id,id)
            entity_set_int(black_plane, EV_INT_solid, SOLID_NOT)
            entity_set_int(plane, EV_INT_solid, SOLID_NOT)
            client_print(id, print_chat, "Resetting your view.")
            @return_body(black_plane)
            @return_body(plane)
            
        }
        else
            attach_view(id,id)
    }
    return PLUGIN_HANDLED;
}

public client_putinserver(id)
{
    new black_plane = find_ent(charsmin, "monster_blkop_apache")
    new plane = find_ent(charsmin, "monster_apache")

    bSpec_Apache_Owner_lock[id] = false
    set_pev(black_plane, pev_owner, 0)
    bSpec_Apache_Owner_lock[0] = false

    bApache_Owner_lock[id] = false
    set_pev(plane, pev_owner, 0)
    bApache_Owner_lock[0] = false
}

///Amxx 182 backwards compatibility
#if !defined client_disconnected
#define client_disconnect client_disconnected
#endif

public client_disconnected(id)
{
    new black_plane
    new plane

    black_plane = find_ent(charsmin, "monster_blkop_apache")
    plane = find_ent(charsmin, "monster_apache")

    if(bSpec_Apache_Owner_lock[id])
    {
        bSpec_Apache_Owner_lock[id] = false
        set_pev(black_plane, pev_owner, 0)
        bSpec_Apache_Owner_lock[0] = false
    }

    if(bApache_Owner_lock[id])
    {
        bApache_Owner_lock[id] = false
        set_pev(plane, pev_owner, 0)
        bApache_Owner_lock[0] = false
        //bApache_Owner_lock[0]
    }
}

//APACHE ACQUISITIONS
public clcmd_apache_buy(id)
{
    new arg[MAX_PLAYERS]
    new black_plane
    new plane
    read_argv(1,arg,charsmax(arg))

    black_plane = find_ent(charsmin, "monster_blkop_apache")
    plane = find_ent(charsmin, "monster_apache")

    if(is_user_alive(id))
    {
        if( containi(arg,"release") > charsmin )
        {
            //restock them for other players.
            //otherwise acts like regular map enemy helcopter and cannot acquire it. have to kill it

            bSpec_Apache_Owner_lock[0] = false
            bApache_Owner_lock[0] = false

            if(pev(plane, pev_owner) == id)
            {
                set_pev(plane, pev_owner, 0)
                bApache_Owner_lock[id] = false
            }
            
            else if(pev(black_plane, pev_owner) == id)
            {
                set_pev(black_plane, pev_owner, 0)
                bSpec_Apache_Owner_lock[id] = false
            }
            set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,255)
            set_user_godmode(id, 0)
            client_print(0, print_chat, "%n released both copters!", id)
            return PLUGIN_HANDLED
        }
        if(black_plane && containi(arg,"black") > charsmin)
        {
            if(!bSpec_Apache_Owner_lock[id])
            {
                client_print(0, print_chat, "%n tried to acquire %n Spec Ops Apache", id, pev(black_plane, pev_owner))
                set_pev(black_plane, pev_owner, id)
                bSpec_Apache_Owner_lock[id] = true
                //entity_set_int(black_plane, EV_INT_solid, SOLID_NOT) //fixes stuck world?
                attach_view(id, black_plane);
                set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
                set_user_godmode(id, 1)

            }
            else
            client_print(0, print_chat, "%n tried to steal %n Apache", id, pev(black_plane, pev_owner))
        }
        else if(plane)
        {
            if(!bApache_Owner_lock[id])
            {
                client_print(0, print_chat, "%n tried to acquire %n Apache", id, pev(plane, pev_owner))
                set_pev(plane, pev_owner, id)
                bApache_Owner_lock[id] = true
                //entity_set_int(plane, EV_INT_solid, SOLID_NOT) //fixes stuck world?
                attach_view(id, plane);
                set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
                set_user_godmode(id, 1)
            }
            else
            client_print(0, print_chat, "%n tried to steal %n Apache", id, pev(plane, pev_owner) )
        }
        else
            attach_view(id,id) //reset view
        client_print 0, print_chat, "%n made an Apache grab attempt.", id
    }
    else
    {
        client_print 0, print_chat, "Hey everybody %n thinks he can own Apache as a dead man!", id
        attach_view(id,id) //reset view
    }

    return PLUGIN_CONTINUE;
}

//MAKING THEM GO TO POINTS WE PICK IN GAME AS A PLAYER WITH PUFF OF SMOKE ::WAYPOINTING
public clcmd_apache_waypoint(id)
{
    if(is_user_connected(id))
    {
        new bool:bOps
        if(!find_ent_by_tname(charsmin, "blk_apache_way_point") || !find_ent_by_tname(charsmin, "apache_way_point"))
        {
            new arg[MAX_PLAYERS]
            read_argv(1,arg,charsmax(arg))
            new way_type[MAX_PLAYERS]
    
            if(containi(arg,"black") > charsmin && !find_ent_by_tname(charsmin, "blk_apache_way_point") && bSpec_Apache_Owner_lock[id])
            {
                //set client command later not a task, tested
                way_type = "blk_apache_way_point"
                bOps = true
            }
            else if(!find_ent_by_tname(charsmin, "apache_way_point") && bApache_Owner_lock[id])
            {
                way_type = "apache_way_point"
            }
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
    
            //if(is_valid_ent(ent) && ent > 0)
            if(pev_valid(ent) == 2 && ent > 0)
                dllfunc( DLLFunc_Spawn, ent )
        }
        else
        {
            PRINT:
            client_print id, print_chat, "%L", LANG_PLAYER, "NO_ACC_COM"
            new SzMessage[64]
            new const SzWay[]= "waypoint already defined."
    
            formatex(SzMessage, charsmax(SzMessage), bOps ? "Black Ops Apache %s" : "Apache %s",SzWay)
            client_print id, print_center, "%s", SzMessage
        }
    
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

//SPAWNING THE COPTERS
public clcmd_apache(id)
{
    if(is_user_alive(id))
    {
        new bool:bOps
        new black_plane
        new plane
        new arg[MAX_PLAYERS]
        new plane_type[MAX_PLAYERS]
    
    
        black_plane = find_ent(charsmin, "monster_blkop_apache")
        plane = find_ent(charsmin, "monster_apache")
        read_argv(1,arg,charsmax(arg))
        if(containi(arg,"black") > charsmin && !black_plane)
        {
            plane_type = "monster_blkop_apache"
            bOps = true
        }
        else if(containi(arg,"osprey") > charsmin)
            plane_type = "monster_osprey"
        else if(containi(arg,"blkosprey") > charsmin)
            plane_type = "monster_blkop_osprey"
        else if(!plane)
            plane_type = "monster_apache"
        else if(black_plane && plane)
            goto PRINT
            
    
        if(!black_plane | !plane)
        {
            new Float:fplayerorigin[3];
            entity_get_vector(id, EV_VEC_origin, fplayerorigin);
    
            fplayerorigin[1] += 150.0 //offside offset
            fplayerorigin[2] += 250.0 //overhead offset
    
            new apache = create_entity(plane_type);
            if(containi(plane_type, "osprey") != charsmin)
            {
                new man = create_entity("monster_human_grunt_ally")
                if(pev_valid(man) == 2&& man > 0) //just a handyman
                {
                    fplayerorigin[1] -= 90.0 //offside offset
                    fplayerorigin[2] += 200.0 //overhead offset
                    fm_set_kvd(man, "angles", "0 0 0") //no yel dots?
                    entity_set_origin(man, fplayerorigin);
                    //dllfunc( DLLFunc_Spawn, man )
                    //@delay_man(man)
                    set_task(5.0,"@delay_man", man)
                }
                new osprey_man = create_entity("monster_human_grunt")
                //new osprey_man = create_entity("monster_grunt_repel") //monster_grunt_ally_repel
                new pathway = create_entity("path_corner")
                if(pev_valid(pathway) && pathway > 0) //all the manuals say will crash without
                {
                    /*
                    "origin" "-190 2033 -3068"
                    "angles" "0 0 0"
                    "wait" "0"
                    "speed" "0"
                    "yaw_speed" "0"
                    "classname" "path_corner"
                    */
                    fm_set_kvd(pathway, "wait", "30")
                    fm_set_kvd(pathway, "speed", "500")
                    fm_set_kvd(pathway, "yaw_speed", "100")
                    fm_set_kvd(pathway, "angles", "45 90 180")

                    entity_set_origin(pathway, fplayerorigin);
                    dllfunc( DLLFunc_Spawn, pathway )

                    if(pev_valid(osprey_man) == 2&& osprey_man > 0) //need for osprey to appear for more than split sec
                    {
                        fplayerorigin[1] += 150.0 //offside offset
                        fplayerorigin[2] += 100.0 //overhead offset
                        fm_set_kvd(osprey_man, "angles", "0 0 0") //no yel dots?
                        entity_set_origin(osprey_man, fplayerorigin);
                        dllfunc( DLLFunc_Spawn, osprey_man )
                    }
                }
            }
    
            entity_set_origin(apache, fplayerorigin);

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
            if(pev_valid(apache) == 2 && apache > 0)
                dllfunc( DLLFunc_Spawn, apache )
        }
        else
        {
            PRINT:
            client_print id, print_chat, "%L", LANG_PLAYER, "NO_ACC_COM"
            new SzMessage[128]
            new const SzWay[]= "is dispatched already!^n^nOne will have to due."
    
            formatex(SzMessage, charsmax(SzMessage), bOps ? "Black Ops Apache %s":"Apache %s",SzWay)
            client_print id, print_center, "%s", SzMessage
    
        }
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

@delay_man(man)
    dllfunc( DLLFunc_Spawn, man )
