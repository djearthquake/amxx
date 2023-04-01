///C4 time is adjusted based on experience (frags).

#include amxmodx
#include amxmisc
#include cstrike
//#include csx
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util

#define IDENTIFY register_plugin("c4 Experience","1.2","SPiNX")
#define MAX_IP_LENGTH              16
#define MAX_NAME_LENGTH            32
#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define charsmin -1

#define m_bIsC4                    385
#define INT_BYTES                    4
#define BYTE_BITS                    8
#define SHORT_BYTES                  2

#if !defined MaxClients
    new MaxClients
#endif

new g_fExperience_offset
static Float:g_fUninhibited_Walk = 272.0;
new g_fire
new g_boomtime
new g_weapon_c4_index
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new bool:Client_C4_adjusted_already[MAX_PLAYERS+1]

public plugin_precache()
g_fire = precache_model("sprites/laserbeam.spr")

public plugin_init()
{
    IDENTIFY;

    #if !defined MaxClients
        MaxClients = get_maxplayers()
    #endif

    if(find_ent( charsmin, "func_bomb_target") || find_ent( charsmin,"info_bomb_target"))
    {
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
{
    if(is_user_connected(id))
    {
        Client_C4_adjusted_already[id] = false

        if(equal(ClientName[id],""))
            get_user_name(id,ClientName[id],charsmax(ClientName[]))
    }
}
#if AMXX_VERSION_NUM == 182
stock bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5)
{
    return !!(get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)))
}
#endif

public FnPlant()
{
    //get username via log
    g_weapon_c4_index = 0
    new id = get_loguser_index();
    server_print "Is %n planting?", id
    if(is_user_alive(id))
    {
        c4_from_grenade();
        g_weapon_c4_index ? set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 255, 215, 0, kRenderGlow, 50) : c4_from_grenade()

        new Float:fC4_factor =  get_user_frags(id) * get_pcvar_float(g_fExperience_offset)
        if(g_weapon_c4_index)
            cs_set_c4_explode_time(g_weapon_c4_index,cs_get_c4_explode_time(g_weapon_c4_index)-fC4_factor)

        //Multi-task
        entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);

        new iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
        if(iBoom_time > 0)
            g_boomtime = iBoom_time
        else
            return
        set_task(1.0,"@count_down",5656,_,0,"b")
        client_print 0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_boomtime,ClientName[id]
    }

    return;
}

public fnDefusal(id)
{
    if(is_user_alive(id) && !Client_C4_adjusted_already[id] /*&& cs_get_c4_defusing(g_weapon_c4_index)*/)
    {
        c4_from_grenade();
        new Float:fC4_factor = get_user_frags(id)*get_pcvar_float(g_fExperience_offset)
        g_weapon_c4_index ? cs_set_c4_explode_time(g_weapon_c4_index,cs_get_c4_explode_time(g_weapon_c4_index)+fC4_factor) : c4_from_grenade()

        new iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
        if(iBoom_time > 0)
            g_boomtime = iBoom_time
        else
            return
        new Float:fplayervector[3];
        entity_get_vector(id, EV_VEC_origin, fplayervector);
        client_print 0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_boomtime,ClientName[id]

        if(!is_user_bot(id))
            entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);

        set_task(0.1, "nice", id+911);
        Client_C4_adjusted_already[id] = true
    }
    return;
}

@count_down() g_boomtime ? client_print( 0, print_center, "Explode time:%i", --g_boomtime) : client_print( 0, print_center, "BOOM!")

public nice(show)
{
    new ct_defusing = show - 911;
    new iPlayerOrigin[3];
    new Float:C4_origin[3];

    fm_get_brush_entity_origin(g_weapon_c4_index, C4_origin)
    get_user_origin(ct_defusing, iPlayerOrigin, 3)

    #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters

    new iC4_origin[3];
    iC4_origin[0] = floatround(C4_origin[0]);
    iC4_origin[1] = floatround(C4_origin[1]);
    iC4_origin[2] = floatround(C4_origin[2]);

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0);
    write_byte(TE_LIGHTNING)
    write_coord(iC4_origin[0])      // start position
    write_coord(iC4_origin[1])
    write_coord(iC4_origin[2])
    write_coord(iPlayerOrigin[0])      // end position
    write_coord(iPlayerOrigin[1])
    write_coord(iPlayerOrigin[2])
    write_byte(g_boomtime*60)       // life in 0.1's
    write_byte(35)        // width in 0.1's
    write_byte(75) // amplitude in 0.01's
    write_short(g_fire)     // sprite model index
    message_end()
}

@round_start()
{
    if(task_exists(5656))
        remove_task(5656)
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount)
    for(new CT;CT < sizeof players;CT++)
    Client_C4_adjusted_already[players[CT]] = false
}

@round_end()@round_start()

stock get_loguser_index()
{
    new loguser[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_NAME_LENGTH]
    read_logargv(0, loguser, charsmax(loguser))
    parse_loguser(loguser, name, charsmax(name))
    return get_user_index(name)
}
stock iPlayers()
{
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"ch")
    return iHeadcount
}

stock c4_from_grenade()
{
    new iC4
    {
        while ((iC4= find_ent(charsmin,"grenade")))
        {
            if(pev_valid(iC4) > 1 && iC4 > MaxClients)
            {
                if(get_pdata_bool(iC4, m_bIsC4))
                    g_weapon_c4_index = iC4
                break;
            }
            if(g_weapon_c4_index < 1)
                c4_from_grenade()
        }
    }
}
