///C4 time is adjusted based on experience (frags).

#include amxmodx
#include cstrike
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util

#define IDENTIFY register_plugin("c4 Experience","1.1","SPiNX")
#define MAX_IP_LENGTH              16
#define MAX_NAME_LENGTH            32
#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define charsmin -1

new g_fExperience_offset
static Float:g_fUninhibited_Walk = 272.0;
new g_defuse_sfx
new g_fire
new g_boomtime
new g_weapon_c4_index
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]

public plugin_precache()
g_fire = precache_model("sprites/laserbeam.spr")

public plugin_init()
{
    IDENTIFY;

    if(find_ent( charsmin, "func_bomb_target") || find_ent( charsmin,"info_bomb_target"))
    {
        g_defuse_sfx  = create_entity("env_beam")
        register_logevent("@round_start",2,"1=Round_Start");
        register_logevent("@round_end", 2, "1=Round_End")
        register_logevent("FnPlant",3,"2=Planted_The_Bomb");
        register_event("BarTime", "fnDefusal", "be", "1=5", "1=10");

        g_fExperience_offset = register_cvar("exp_offset",  "1.03");
    }
    else
    {
        pause( "a" );
    }
}

public client_putinserver(id)
    if(equal(ClientName[id],""))
        get_user_name(id,ClientName[id],charsmax(ClientName[]))

public FnPlant()
{
    //get username via log
    new id = get_loguser_index();

    g_weapon_c4_index = find_ent(charsmin,"grenade") //grenade is 'planted c4' class

    new Float:fC4_factor = ( ( get_user_frags(id) * get_pcvar_float(g_fExperience_offset) ) * (-1.0) )
    cs_set_c4_explode_time(g_weapon_c4_index,cs_get_c4_explode_time(g_weapon_c4_index)+fC4_factor)

    //Multi-task
    entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);

    new iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
    if(iBoom_time)
        g_boomtime = iBoom_time
    set_task(1.0,"@count_down",5656,_,0,"b")
    client_print 0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_boomtime,ClientName[id]

    return;
}

public fnDefusal(id)
{
    new Float:fC4_factor = get_user_frags(id)*get_pcvar_float(g_fExperience_offset)
    cs_set_c4_explode_time(g_weapon_c4_index,cs_get_c4_explode_time(g_weapon_c4_index)+fC4_factor)

    new iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
    if(iBoom_time)
        g_boomtime = iBoom_time
    new Float:fplayervector[3];
    entity_get_vector(id, EV_VEC_origin, fplayervector);
    client_print 0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_boomtime,ClientName[id]

    if(!is_user_bot(id))
        entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);

    set_task(0.1, "nice", id+911);
    return;
}

@count_down() g_boomtime ? client_print( 0, print_center, "Explode time:%i", --g_boomtime) : client_print( 0, print_center, "BOOM!")

public nice(show)
{
    new ct_defusing = show - 911;
    new playerorigin[3];
    new Float:C4_origin[3];

    fm_get_brush_entity_origin(g_weapon_c4_index, C4_origin)

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
    fm_set_kvd( g_defuse_sfx , "LightningStart", "playerorigin"          );
    fm_set_kvd( g_defuse_sfx , "LightningEnd",   "C4_origin"             );
    fm_set_kvd( g_defuse_sfx , "angles",         "0 0 0"                 );
    dllfunc( DLLFunc_Spawn, g_defuse_sfx);

}

@round_start()
if(task_exists(5656))
    remove_task(5656)

@round_end()@round_start()

stock get_loguser_index()
{
    new loguser[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_NAME_LENGTH]
    read_logargv(0, loguser, charsmax(loguser))
    parse_loguser(loguser, name, charsmax(name))
    return get_user_index(name)
}
