///C4 time is adjusted based on experience (frags).

#include amxmodx
#include amxmisc
#include cstrike
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util
#include hamsandwich

#define IDENTIFY register_plugin("c4 Experience","1.28","SPiNX")
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
static g_fire;
static g_radar;
new g_boomtime;
new g_weapon_c4_index, g_maxPlayers, g_debug;
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH];
new bool:Client_C4_adjusted_already[MAX_PLAYERS+1];
new bool:bRadarOwner[MAX_PLAYERS+1]
new g_radar_cost, g_timer;
new bool:bIsBot[MAX_PLAYERS + 1];
new bool:bRegistered;

public plugin_precache()
{
    g_fire = precache_model("sprites/laserbeam.spr");
    g_radar = precache_model("sprites/zerogxplode.spr");
}

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
        g_timer = register_cvar("c4_timer", "0")
        g_radar_cost = register_cvar("radar_cost", "500")
        RegisterHam(Ham_Killed, "player", "no_radar", 1);


        register_clcmd ( "buy_radar", "buy_radar", 0, " - C4 radar." );

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
        bIsBot[id] = is_user_bot(id) ? true : false
        Client_C4_adjusted_already[id] = false
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
        bRadarOwner[id] = false
        if(bIsBot[id] && !bRegistered)
        {
            set_task(0.1, "@register", id);
        }
    }
}

//CONDITION ZERO TYPE BOTS. SPiNX
@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        bRegistered = true;
        RegisterHamFromEntity( Ham_Killed, ham_bot, "no_radar", 1 );
        server_print("C4 exp ham bot from %N", ham_bot)
    }
}

public client_disconnected(id)
{
    bRadarOwner[id] = false
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
    }
}

public no_radar(id)
{
    if(bRadarOwner[id])
    {
        bRadarOwner[id] = false
    }
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
                //Give spec a show
                for (new spec; spec<=MaxClients; spec++)
                {
                    new flags = pev(spec, pev_flags)
                    if(flags & FL_SPECTATOR)
                    //if(!bRadarOwner[spec])
                    {
                        server_print "%n is spec...", spec
                        bRadarOwner[spec] = true
                    }
                }
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
            set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 255, 1, 255, kRenderGlow, 300)

            static Float:fC4_factor
            fC4_factor = get_user_frags(id)*get_pcvar_float(g_fExperience_offset)
            g_weapon_c4_index > MaxClients ? cs_set_c4_explode_time(g_weapon_c4_index,cs_get_c4_explode_time(g_weapon_c4_index)+fC4_factor) : c4_from_grenade()

            static iBoom_time
            iBoom_time =  floatround(cs_get_c4_explode_time(g_weapon_c4_index) - get_gametime())
            if(iBoom_time > 0)
            {
                g_boomtime = iBoom_time
            }

            static Float:fplayerfOrigin[3];
            entity_get_vector(id, EV_VEC_origin, fplayerfOrigin);
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
    --g_boomtime
    if(get_playersnum())
    {
        new Cvar = get_pcvar_num(g_timer)
        if(Cvar)
        {
            g_boomtime ? client_print( 0, print_center,"Explode time:%i",g_boomtime) : client_print( 0, print_center, "BOOM!")
        }

        c4_from_grenade()
        switch(g_boomtime)
        {
            case   0..5 : set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 255, 0, 0, kRenderGlow, 150)&@c4_radar(255,0,0)
            case  6..10 : set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 255, 255, 0, kRenderGlow, 100)&@c4_radar(255,255,0)
            case 11..20 : set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 255, 103, 0, kRenderGlow, 100)&@c4_radar(255,103,0)
            default     : set_rendering(g_weapon_c4_index, kRenderFxGlowShell, 5, 255, 75, kRenderGlow, 50)&@c4_radar(5,255,75)
        }
    }
}
@c4_radar(r,g,b)
{
    static Float:fOrigin[3]
    if(pev_valid(g_weapon_c4_index))
    {
        pev(g_weapon_c4_index, pev_origin, fOrigin)
        for(new i=1; i <= MaxClients; ++i )
        {
            if(is_user_connected(i) && bRadarOwner[i] || !is_user_alive(i) && !is_user_bot(i))
            {
                //debug
                ///server_print("%n is seeing radar...", i)
                emessage_begin ( MSG_ONE, SVC_TEMPENTITY, { 0, 0, 0 }, i )
                ewrite_byte(TE_BEAMTORUS)
                ewrite_coord_f(fOrigin[0]);
                ewrite_coord_f(fOrigin[1]);
                ewrite_coord_f(fOrigin[2] + 16);
                ewrite_coord_f(fOrigin[0]);
                ewrite_coord_f(fOrigin[1]);
                ewrite_coord_f(fOrigin[2] + 200);
                ewrite_short(g_radar);
                ewrite_byte(1); //start frame
                ewrite_byte(32); //frame rate
                ewrite_byte(255); //life in .1
                ewrite_byte(2); //line Width .1
                ewrite_byte(1); //noise amp .1
                ewrite_byte(r);
                ewrite_byte(g);
                ewrite_byte(b);
                ewrite_byte(254);  //brightness
                ewrite_byte(2); //scroll speed
                emessage_end();
            }
        }
    }
    return PLUGIN_HANDLED
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
        {
            client_print admin, print_chat, "Interval:%f|Beep:%f|Attn:%f|Count:%f", fInterval, fBeep, fAttn, fCount
        }
    }
}

public buy_radar(Client)
{
    if(is_user_alive(Client))
    {
        static name[MAX_PLAYERS];

        get_user_name(Client,name,charsmax(name));

        static tmp_money; tmp_money = cs_get_user_money(Client);
        if(is_user_alive(Client))
        {
            if ( !bRadarOwner[Client] )
            {

                if(tmp_money < get_pcvar_num(g_radar_cost))
                {
                    client_print(Client, print_center, "You can't afford a scope %s!", name);
                    client_print(0, print_chat, "Hey guys %s keeps trying to buy scope they can't afford!", name);
                    return PLUGIN_HANDLED;
                }
                else
                {
                    cs_set_user_money(Client, tmp_money - get_pcvar_num(g_radar_cost));
                    bRadarOwner[Client] = true;
                    client_print(Client, print_center, "You bought c4 radar!");
                }

            }
            else
            {
                client_print(Client, print_center, "You ALREADY OWN C4 radar...");
                client_print(0, print_chat, "Hey guys %s keeps trying to buy C4 radar and already owns one!", name);
            }
        }
    }
    return PLUGIN_HANDLED;
}
