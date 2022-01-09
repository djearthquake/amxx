#include amxmodx
//nclude amxmisc
#include engine
#include fakemeta
#include fakemeta_util

#define MAX_PLAYERS 32
#define PERMISSION ADMIN_ALL //ADMIN_CHAT

#define FRICTION_NOT    1.0
#define FRICTION_MUD    1.8
#define FRICTION_ICE    0.3

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
    register_plugin("OP4 Apache", "1.0", ".sρiηX҉.");

    //Sensors
    register_touch("monster_apache", "monster_blkop_apache", "@Apache_Sensor")
    register_touch("monster_apache", "worldspawn", "@Apache_World")
    register_touch("monster_blkop_apache", "world", "@Apache_World")
    register_touch("monster_apache", "player", "@Apache_Player")
    register_touch("monster_blkop_apache", "player", "@Apache_Player")
    register_touch("monster_apache", "*", "@Apache_Sensor")
    register_touch("monster_blkop_apache", "func_breakable", "@Apache_Sensor")

    //waypointing
    g_puff_hp = register_cvar("smoke_puff_hp", "50")
    g_puff_scale = register_cvar("smoke_puff_scale", "150")

    //Apache
    register_concmd(".apache_buy","clcmd_apache_buy",PERMISSION,".apache_buy - Befriend the apache")
    register_concmd(".apache","clcmd_apache",PERMISSION,".apache - makes apache. Add black to make BlackOps")
    register_concmd(".apache_way","clcmd_apache_waypoint",PERMISSION,".apache_way - makes apache waypoint. Append black to make BlackOps")
    register_concmd(".apache_view","clcmd_apache_view",PERMISSION,".apache_view - Look from Apache pilot seat. Reset your view.")

    register_dictionary("common.txt")
}

@Apache_Sensor(Apache, Sensor)
{
    if(pev_valid(Apache))
    {
        new SzMonster_class[MAX_PLAYERS], SzSensor_class[MAX_PLAYERS]
        entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))

        if(pev_valid(Sensor))
        {
            entity_get_string(Sensor,EV_SZ_classname,SzSensor_class,charsmax(SzSensor_class))
            client_print 0, print_center, "%s is next to^n^n%s",SzMonster_class, SzSensor_class
        }
        entity_set_int(Apache, EV_INT_solid, SOLID_NOT)
        entity_set_float(Apache, EV_FL_friction, FRICTION_ICE)
        set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE)
        set_task(random_num(3,7)*1.0,"@return_body",Apache)
    }
}

@return_body(Apache)
{
    if(pev_valid(Apache))
    {
        if(pev(Apache, pev_owner) > 0 && is_user_alive(pev(Apache, pev_owner)) || pev(Apache, pev_owner) > 32 && is_valid_ent(Apache))
        {
            new SzMonster_class[MAX_PLAYERS]
            entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
            set_pev(Apache, pev_movetype, MOVETYPE_FLY)
            entity_set_int(Apache, EV_INT_solid, SOLID_BBOX)
    
            entity_set_float(Apache, EV_FL_friction, FRICTION_MUD)
    
            client_print 0, print_center, "%s back on course", SzMonster_class
        }
    }
}

@Apache_Player(Apache, Player)
{
    if(is_user_connected(Player) && pev_valid(Apache))
    {
        new SzMonster_class[MAX_PLAYERS]
        entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
        client_print 0, print_center, "%s is on %n", SzMonster_class, Player
        set_pev(Apache, pev_movetype, MOVETYPE_BOUNCEMISSILE )
        //set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE) 
    }
    //set_task(2.0,"@return_body",Apache)
}

@Apache_World(Apache, World)
{
    //client_print 0, print_center, "Apache is on world"

    if(pev_valid(Apache))
    {
        new SzMonster_class[MAX_PLAYERS]
        entity_get_string(Apache,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))
        client_print 0, print_center, "%s is colliding with world.", SzMonster_class
        //entity_set_int(Apache, EV_INT_solid, SOLID_NOT)
        //set_pev(Apache, pev_movetype, MOVETYPE_STEP )
        //entity_set_float(Apache, EV_FL_friction, FRICTION_NOT)

        set_pev(Apache, pev_movetype, MOVETYPE_BOUNCE )
        //set_task(random_num(1,3)*1.0,"@return_body",Apache)
    }
}

public plugin_precache()
{
    for(new list; list < sizeof apache_model;list++)
    {
        precache_model(apache_model[list])
        //precache_generic(apache_model[list])
    }

    for(new list; list < sizeof apache_snds;list++)
    {
        precache_sound(apache_snds[list])

        //Generic cache of sounds
        /*
        new SzReformat_SND_generic[MAX_PLAYERS]
        formatex(SzReformat_SND_generic,charsmax(SzReformat_SND_generic),"sound/%s",apache_snds[list])
        precache_generic(SzReformat_SND_generic)*/
    }

}
public clcmd_apache_view(id)
{
    if(!is_user_connecting(id))
    {
        new arg[MAX_PLAYERS]
        new black_plane
        new plane
        read_argv(1,arg,charsmax(arg))

        black_plane = find_ent(-1, "monster_blkop_apache")
        plane = find_ent(-1, "monster_apache")
        if(black_plane && containi(arg,"black") > -1)
        {
            attach_view(id,black_plane)
            @return_body(black_plane)
        }
        else if(plane && containi(arg,"green") > -1)
        {
            attach_view(id,plane)
            @return_body(plane)
        }
        else
            attach_view(id,id)
    }
    return PLUGIN_HANDLED;
}

public clcmd_apache_buy(id)
{
    new bool:bApache_Owner_lock
    new bool:bSpec_Apache_Owner_lock

    new arg[MAX_PLAYERS]
    new black_plane
    new plane
    read_argv(1,arg,charsmax(arg))

    black_plane = find_ent(-1, "monster_blkop_apache")
    plane = find_ent(-1, "monster_apache")

    if(is_user_alive(id))
    {

        if(black_plane && containi(arg,"black") > -1)
        {
            if(!bSpec_Apache_Owner_lock)
            {
                client_print(0, print_chat, "%n tried to acquire %n Spec Ops Apache", id, pev(black_plane, pev_owner))
                set_pev(black_plane, pev_owner, id)
                bSpec_Apache_Owner_lock = true
                entity_set_int(black_plane, EV_INT_solid, SOLID_NOT) //fixes stuck world?
                attach_view(id, black_plane);

            }
            else
            client_print(0, print_chat, "%n tried to steal %n Apache", id, pev(black_plane, pev_owner))
        }
        else if(plane)
        {
            if(!bApache_Owner_lock)
            {
                client_print(0, print_chat, "%n tried to acquire %n Apache", id, pev(plane, pev_owner))
                set_pev(plane, pev_owner, id)
                bApache_Owner_lock = true
                entity_set_int(plane, EV_INT_solid, SOLID_NOT) //fixes stuck world?
                attach_view(id, plane);
            }
            else
            client_print(0, print_chat, "%n tried to steal %n Apache", id, pev(plane, pev_owner) )
        }
        client_print 0, print_chat, "%n made an Apache grab attempt.", id
    }
    else
    {
        client_print 0, print_chat, "Hey everybody %n thinks he can own Apache as a dead man!", id
        attach_view(id,id) //reset view
    }

    return PLUGIN_HANDLED;
}

public clcmd_apache_waypoint(id)
{
    if(is_user_connected(id))
    {
        new bool:bOps
        if(!find_ent_by_tname(-1, "blk_apache_way_point"))
        {
            //server_cmd "sv_hook 0"//Rapid Hookgrab possibly makes crashing server an easy task.
    
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
    
            if(is_valid_ent(ent) && ent > 0)
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
    
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}

public clcmd_apache(id)
{
    if(is_user_alive(id))
    {
        new bool:bOps
        new black_plane
        new plane
        new arg[MAX_PLAYERS]
        new plane_type[MAX_PLAYERS]
    
    
        black_plane = find_ent(-1, "monster_blkop_apache")
        plane = find_ent(-1, "monster_apache")
        //server_cmd "sv_hook 0"//Rapid Hookgrab possibly makes crashing server an easy task.
        read_argv(1,arg,charsmax(arg))
        if(containi(arg,"black") > -1 && !black_plane)
        {
            plane_type = "monster_blkop_apache"
            bOps = true
        }
        else if(!plane)
            plane_type = "monster_apache"

        else if(black_plane && plane)
            goto PRINT
            
    
        if(!black_plane | !plane)
        {
            new Float:fplayerorigin[3];
    
            new apache = create_entity(plane_type);
    
            entity_get_vector(id, EV_VEC_origin, fplayerorigin);
    
            fplayerorigin[1] += 150.0 //offside offset
            fplayerorigin[2] += 250.0 //overhead offset
    
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
            if(is_valid_ent(apache) && apache > 0)
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
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}

