///C4 time is adjusted based on experience (frags).

#include amxmodx
#include cstrike
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util

#define IDENTIFY register_plugin("c4 Experience","1.0","SPiNX")
#define MAX_IP_LENGTH              16
#define MAX_NAME_LENGTH            32
#define MAX_RESOURCE_PATH_LENGTH   64
#define charsmin -1

new g_fExperience_offset, g_iNeutral, g_iSatchel_timer;
static Float:g_fUninhibited_Walk = 272.0;
new g_iC4_base_time, g_szName[MAX_NAME_LENGTH];
new g_defuse_sfx
new g_fire
new g_boomtime

public plugin_precache()
g_fire = precache_model("sprites/laserbeam.spr")

public plugin_init()
{
    IDENTIFY;

    register_logevent("@round_start", 2, "1=Round_Start")
    register_logevent("@round_end", 2, "1=Round_End")

    if(find_ent( charsmin, "func_bomb_target") || find_ent( charsmin,"info_bomb_target"))
    {
        g_defuse_sfx  = create_entity("env_beam")
        register_logevent("fnReset_C4",2,"1=Round_Start");
        register_logevent("FnPlant",3,"2=Planted_The_Bomb");
        register_event("BarTime", "fnDefusal", "be", "1=5", "1=10");
    
        g_iC4_base_time  = get_cvar_pointer("mp_c4timer");
        g_iNeutral       = register_cvar("exp_base",  "40");
        g_fExperience_offset = register_cvar("exp_offset",  "1.03");
    }
    else
    {
        pause( "a" );
    }
}

public fnReset_C4()
    set_pcvar_num(g_iC4_base_time,get_pcvar_num(g_iNeutral))

public FnPlant()
{
    //get username via log
    new id = get_loguser_index();
    
    //If T has frags it affects the timer for the next round.
    new Float:fC4_factor = ( ( get_user_frags(id) * get_pcvar_float(g_fExperience_offset) ) * (-1.0) )
    
    g_iSatchel_timer = clamp (floatround(  (get_pcvar_num(g_iNeutral)) + (fC4_factor) ), 15,60);
    //Adj C4 based on exp. *Works on next round.
    set_pcvar_num(g_iC4_base_time,g_iSatchel_timer);
    //Multi-task
    entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);
    //Advert
    get_user_name(id,g_szName,charsmax (g_szName));
    client_print(0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_iSatchel_timer,g_szName);
    
    
    return;
}

public fnDefusal(id)
{
    new Float:fC4_factor = get_user_frags(id)*get_pcvar_float(g_fExperience_offset)
    g_iSatchel_timer = clamp(floatround(get_pcvar_num(g_iNeutral)+fC4_factor),15,60);
    
    if(!is_user_bot(id))
        entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);
    set_pcvar_num(g_iC4_base_time,g_iSatchel_timer);
    
    get_user_name(id,g_szName,charsmax (g_szName));
    client_print(0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_iSatchel_timer,g_szName);
    set_task(0.1, "nice", id+911);
    return;
}                           

stock get_loguser_index()
{
    new loguser[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_NAME_LENGTH]
    read_logargv(0, loguser, charsmax(loguser))
    parse_loguser(loguser, name, charsmax(name))
    return get_user_index(name)
}
//@count_down(iBoom_time, SzBoom_time[1], ct_defusing)
@count_down()
{
    //iBoom_time = str_to_num(SzBoom_time)
    client_print 0, print_center, "Explode time:%i", --g_boomtime
    //client_print ct_defusing , print_chat, "Explode time (in sec):%i", --iBoom_time
}
@round_start()
if(task_exists(5656))
    remove_task(5656)
@round_end()@round_start()
public nice(show)
{
    new ct_defusing = show - 911;
    new playerorigin[3];
    new Float:fplayervector[3];
    new Float:C4_origin[3];

    new weapon_c4 = find_ent(charsmin,"grenade") //grenade is 'planted c4' class
    //weapon_c4  = engfunc(EngFunc_FindEntityByString, weapon_c4, "targetname","weapon_c4")

    new Float:fC4_factor = get_user_frags(ct_defusing)*get_pcvar_float(g_fExperience_offset)
    cs_set_c4_explode_time(weapon_c4,cs_get_c4_explode_time(weapon_c4)+fC4_factor)

    new iBoom_time =  floatround(cs_get_c4_explode_time(weapon_c4) - get_gametime())
    new SzBoom_time[1]
    num_to_str(iBoom_time,SzBoom_time,charsmax(SzBoom_time))

    client_print 0, print_chat, "Explode time:%i", iBoom_time
    client_print ct_defusing , print_center, "Explode time (in sec):%i", iBoom_time
    //set_task(1.0,"@count_down",5656,SzBoom_time, charsmax(SzBoom_time),"a",iBoom_time)
    set_task(1.0,"@count_down",5656,_,0,"b")
    g_boomtime = iBoom_time

    entity_get_vector(ct_defusing, EV_VEC_origin, fplayervector);
    //entity_get_vector(weapon_c4, EV_VEC_origin, fC4_origin);
    fm_get_brush_entity_origin(weapon_c4, C4_origin)
    //server_print("making the bolt of lightening");
    //client_print 0, print_chat, "making the bolt of lightening"
    //c4-white-lightening
    #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters
    get_user_origin(ct_defusing,playerorigin,3);
    emessage_begin(0,23);
    ewrite_byte(TE_LIGHTNING)
    ewrite_coord(floatround(C4_origin[0]))       // start position
    ewrite_coord(floatround(C4_origin[1]))
    ewrite_coord(floatround(C4_origin[2]))
    ewrite_coord(playerorigin[0])      // end position 
    ewrite_coord(playerorigin[1])
    ewrite_coord(playerorigin[2])
    ewrite_byte(1000)        // life in 0.1's 
    ewrite_byte(1000)        // width in 0.1's 
    ewrite_byte(700) // amplitude in 0.01's 
    ewrite_short(g_fire)     // sprite model index
    emessage_end()

    fm_set_kvd( g_defuse_sfx , "killtarget",     "grenade"               );
    fm_set_kvd( g_defuse_sfx , "texture",        "sprites/laserbeam.spr" );
    fm_set_kvd( g_defuse_sfx , "renderamt",      "100"                   );
    fm_set_kvd( g_defuse_sfx , "rendercolor",    "53 200 140"            );
    fm_set_kvd( g_defuse_sfx , "Radius",         "500"                   );
    fm_set_kvd( g_defuse_sfx , "BoltWidth",      "200"                   );
    fm_set_kvd( g_defuse_sfx , "TextureScroll",  "35"                    );
    fm_set_kvd( g_defuse_sfx , "StrikeTime",     "1"                     );
    fm_set_kvd( g_defuse_sfx , "damage",         "-20"                   );
    fm_set_kvd( g_defuse_sfx , "life",           "40"                    );
    fm_set_kvd( g_defuse_sfx , "NoiseAmplitude", "40"                    );
    fm_set_kvd( g_defuse_sfx , "targetname",     "defuser_sfx"           );
    fm_set_kvd( g_defuse_sfx , "LightningStart", "playerorigin"         );
    fm_set_kvd( g_defuse_sfx , "LightningEnd",   "C4_origin"            );
    fm_set_kvd( g_defuse_sfx , "angles",         "0 0 0"                 );
    dllfunc( DLLFunc_Spawn, g_defuse_sfx);

}
