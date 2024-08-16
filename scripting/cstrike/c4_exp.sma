///C4 time is adjusted based on experience (frags).

#include amxmodx
#include amxmisc
#include cstrike
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util

#define IDENTIFY register_plugin("c4 Experience","1.24","SPiNX")
#define MAX_IP_LENGTH              16
#define MAX_NAME_LENGTH            32
#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define charsmin -1

#define INT_BYTES                    4
#define BYTE_BITS                    8
#define SHORT_BYTES                  2

#define ADMIN_FLAG "l"

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
const UNIX_DIFF = 20;

static m_bIsC4, m_flNextBeep, m_flNextFreqInterval, m_flDefuseCountDown, m_fAttenu;

#if !defined MaxClients
    new MaxClients
#endif

new g_fExperience_offset;
static Float:g_fUninhibited_Walk = 272.0;
new g_fire;
new g_boomtime;
new g_weapon_c4_index, g_maxPlayers, g_debug;
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH];
new bool:Client_C4_adjusted_already[MAX_PLAYERS+1];

public plugin_precache()
g_fire = precache_model("sprites/laserbeam.spr");

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
        g_debug = register_cvar("c4_debug", "0")

        g_fExperience_offset = register_cvar("exp_offset",  "1.03");
        m_bIsC4 = find_ent_data_info("CGrenade", "m_bIsC4") + UNIX_DIFF
        m_flNextBeep =  (find_ent_data_info("CGrenade", "m_flNextBeep") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF
        m_flNextFreqInterval =  (find_ent_data_info("CGrenade", "m_flNextFreqInterval") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF
        m_flDefuseCountDown = (find_ent_data_info("CGrenade", "m_flDefuseCountDown") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF
        m_fAttenu = (find_ent_data_info("CGrenade", "m_fAttenu") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF
    }
    else
    {
        pause( "a" );
    }
    g_maxPlayers = get_maxplayers()
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        Client_C4_adjusted_already[id] = false
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
    }
}

public client_infochanged(id)
{
    if(is_user_connected(id))
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
}

#if !defined get_pdata_bool
stock bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5)
{
    return !!(get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)))
}
#endif

public FnPlant()
{
    c4_from_grenade();
    static id; id = get_loguser_index();
    if(is_user_alive(id))
    {
        server_print "Is %n planting?", id
        if(pev_valid(g_weapon_c4_index))
        if(g_weapon_c4_index > MaxClients && get_pdata_bool(g_weapon_c4_index, m_bIsC4, UNIX_DIFF, UNIX_DIFF) && pev_valid(g_weapon_c4_index) > 1)
        {
            set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 255, 215, 0, kRenderGlow, 50)

            static Float:fExp
            static Float:fC4_factor
            fExp = get_pcvar_float(g_fExperience_offset)
            fC4_factor = get_user_frags(id)*fExp

            if(!get_pdata_bool(g_weapon_c4_index, m_bIsC4, UNIX_DIFF, UNIX_DIFF))
            {
                c4_from_grenade()
                log_amx("C4 index out of bounds!")
                return
            }
            c4_from_grenade();
            if((cs_get_c4_explode_time(g_weapon_c4_index)-get_gametime()-fC4_factor) < 9.0)
            {
                set_pcvar_float(g_fExperience_offset, get_pcvar_float(g_fExperience_offset)/2)
                fC4_factor = get_user_frags(id)*fExp
                client_print 0, print_chat, "C4 Experience adjusted on server."
            }

            g_weapon_c4_index ? cs_set_c4_explode_time(g_weapon_c4_index, cs_get_c4_explode_time(g_weapon_c4_index)-fC4_factor) : c4_from_grenade()

            if(g_weapon_c4_index && g_weapon_c4_index > MaxClients && pev_valid(g_weapon_c4_index) > 1)
            {
                new iC4TimeOffset

                iC4TimeOffset = floatround(cs_get_c4_explode_time(g_weapon_c4_index)-fC4_factor)
                new Float:fTime
                fTime = float(iC4TimeOffset)

                static iBoom_time
                iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
                if(cs_get_c4_explode_time(g_weapon_c4_index) <=7.0)
                {
                    cs_set_c4_explode_time(g_weapon_c4_index, 9.0)
                }
                server_print "boom time is %f seconds!", fTime

                //Multi-task
                entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);

                if(iBoom_time)
                    g_boomtime = iBoom_time

                set_task(1.0,"@count_down",5656,_,0,"b")
                client_print 0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_boomtime, ClientName[id]

                if(get_pcvar_num(g_debug))
                    set_task(0.1,"@c4_status",3400,_,_,"b")
            }
            else
            {
                c4_from_grenade()
            }
        }
        else
        {
            c4_from_grenade()
        }
    }
    return;
}

public fnDefusal(id)
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        if(!Client_C4_adjusted_already[id] && is_user_alive(id))
        {
            c4_from_grenade();
            static Float:fC4_factor
            fC4_factor = get_user_frags(id)*get_pcvar_float(g_fExperience_offset)
            g_weapon_c4_index > MaxClients ? cs_set_c4_explode_time(g_weapon_c4_index,cs_get_c4_explode_time(g_weapon_c4_index)+fC4_factor) : c4_from_grenade()

            static iBoom_time
            iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
            if(iBoom_time > 0)
            {
                g_boomtime = iBoom_time
            }

            static Float:fplayervector[3];
            entity_get_vector(id, EV_VEC_origin, fplayervector);
            client_print 0, print_chat, "C4 timer is now %i seconds due to the expertise of %s.", g_boomtime,ClientName[id]

            set_task(0.1, "nice", id+911, _, _, "b");
            Client_C4_adjusted_already[id] = true;

            if(!is_user_bot(id))
            {
                entity_set_float(id, EV_FL_maxspeed, g_fUninhibited_Walk);
            }
        }
        else if(!task_exists(id+911))
        {
            set_task(0.1, "nice", id+911, _, _, "b");
        }
    }
    return PLUGIN_HANDLED
}

@count_down()
{
    if(get_playersnum())g_boomtime ? client_print( 0, print_center, "Explode time:%i", --g_boomtime) : client_print( 0, print_center, "BOOM!")
}

public nice(show)
{
    static ct_defusing
    if(pev_valid(g_weapon_c4_index))
    {

        if(!is_user_bot(ct_defusing) && pev(ct_defusing,pev_button) & ~IN_USE)
            remove_task(ct_defusing+911)

        static iPlayerOrigin[3],
        Float:C4_origin[3];
        ct_defusing = show - 911
        if(is_user_alive(ct_defusing))
        {

            fm_get_brush_entity_origin(g_weapon_c4_index, C4_origin)
            get_user_origin(ct_defusing, iPlayerOrigin, 3)

            #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters

            static iC4_origin[3];
            iC4_origin[0] = floatround(C4_origin[0]);
            iC4_origin[1] = floatround(C4_origin[1]);
            iC4_origin[2] = floatround(C4_origin[2]);

            emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0);
            ewrite_byte(TE_LIGHTNING)
            ewrite_coord(iC4_origin[0])      // start position
            ewrite_coord(iC4_origin[1])
            ewrite_coord(iC4_origin[2])
            ewrite_coord(iPlayerOrigin[0])      // end position
            ewrite_coord(iPlayerOrigin[1])
            ewrite_coord(iPlayerOrigin[2])
            //write_byte(g_boomtime*60)       // life in 0.1's
            ewrite_byte(1)       // life in 0.1's
            ewrite_byte(35)        // width in 0.1's
            ewrite_byte(16) // amplitude in 0.01's
            ewrite_short(g_fire)     // sprite model index
            emessage_end()
        }
        else
        {
            remove_task(ct_defusing+911)
        }
    }
    else
    {
        c4_from_grenade()
        remove_task(ct_defusing+911)
    }
}

@round_start()
{
    //if(task_exists(5656))
    remove_task(5656)
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount)
    for(new CT;CT < sizeof players;CT++)
    Client_C4_adjusted_already[players[CT]] = false
}

@round_end()
{
    @round_start()
    if(task_exists(3400))
        remove_task(3400)
}

stock get_loguser_index()
{
    static loguser[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_NAME_LENGTH]
    read_logargv(0, loguser, charsmax(loguser))
    parse_loguser(loguser, name, charsmax(name))
    return get_user_index(name)
}
stock iPlayers()
{
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"ch")
    return iHeadcount
}


stock c4_from_grenade2()
{
    static iC4; iC4 = MaxClients;
    {
        while ((iC4= find_ent(iC4, "grenade")) && pev_valid(iC4))
        {
            if(get_pdata_bool(iC4, m_bIsC4, UNIX_DIFF, UNIX_DIFF))
            {
                static SzClass[MAX_NAME_LENGTH]
                pev(iC4,pev_classname, SzClass, charsmax(SzClass))
                if(equal(SzClass, "grenade"))
                {
                    g_weapon_c4_index = iC4
                    break;
                }
            }
        }
    }
}


stock c4_from_grenade()
{
    g_weapon_c4_index = fm_find_ent_by_model(MaxClients, "grenade", "models/w_c4.mdl")
    if(!g_weapon_c4_index)
    {
        c4_from_grenade2()
    }
}

@c4_status()
{
    if(pev_valid(g_weapon_c4_index))
    {
        static Float:fInterval, Float:fBeep, Float:fAttn, Float:fCount
        fAttn = get_pdata_float( g_weapon_c4_index, m_fAttenu, LINUX_DIFF )
        fCount =get_pdata_float( g_weapon_c4_index, m_flDefuseCountDown, LINUX_DIFF ) //expecting instant
        fInterval = get_pdata_float( g_weapon_c4_index, m_flNextFreqInterval, LINUX_DIFF ) //in your face
        fBeep =get_pdata_float( g_weapon_c4_index, m_flNextBeep, LINUX_DIFF);

        for (new admin=1; admin<=g_maxPlayers; admin++)
        if (is_user_connected(admin) && has_flag(admin, ADMIN_FLAG))
            client_print admin, print_chat, "Interval:%f|Beep:%f|Attn:%f|Count:%f", fInterval, fBeep, fAttn, fCount
    }
}
