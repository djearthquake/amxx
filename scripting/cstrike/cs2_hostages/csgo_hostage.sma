#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <engine>

#define PLUGIN             "CSGO Hostage Mode"
#define VERSION            "1.2.5"
#define AUTHOR             "mjf_0.0|SPiNX"

#define MAX_PLAYERS        32
#define MAX_HOSTAGES       8
#define Body_sizeA         50.0
#define Body_sizeB         15.0

// Constants
static const HOSTAGE_MODEL[]     = "models/csgo_hostage/hostage.mdl";
static const CARRY_MODEL[]       = "models/csgo_hostage/p_hostage_back.mdl";
static const HOSTAGE_CLASSNAME[] = "hostage_entity";

static const szHostageResMsg[]   = "HOSTAGE RESCUE ZONE^n^nBring the hostages here!";
static const  Float:fNullOrigin[3] = {0.0, 0.0, -1000000.0};

static const szCZsuffixes[][] ={"A",  "B",  "C", "D"};


// Global variables
new
g_iCarryHostageBackEnt[MAX_PLAYERS + 1],
g_CarriedHostage[MAX_PLAYERS + 1],
g_CarryCount[MAX_PLAYERS + 1],
g_carryspeed,
g_pickuptime,
g_cor,
g_PendingHostage[MAX_PLAYERS + 1],
g_HostageEnts[MAX_HOSTAGES],
g_HostageCount,
g_rescue_area, g_rescue_area2, g_rescue_area3, g_rescue_area4, g_max_seek,
g_remove_zones, g_full_rescue, g_hosties_seeker,g_pick_distance, g_bot_think,
g_fake_rescue, g_fake_rescue2, g_fake_rescue3, g_fake_rescue4, g_freezetime,
//Float:g_range,
Float:g_rescue_origin[3],
Float:g_rescue_origin2[3],
Float:g_rescue_origin3[3],
Float:g_rescue_origin4[3],
Float:g_PickupStartTime[MAX_PLAYERS + 1],
Float:g_LastDropTime[MAX_PLAYERS + 1],
Float:g_HostageOrigins[MAX_HOSTAGES][3],

bool:bIsBot[MAX_PLAYERS + 1],
bool:bAttacked[MAX_PLAYERS + 1],
bool:bScouting[MAX_PLAYERS + 1],
bool:g_bTryingPickup[MAX_PLAYERS + 1],
bool:g_bCarryingHostage[MAX_PLAYERS + 1],
bool:g_bRescueEnded,
bool:g_bHostageMap,
bool:bCarryingAlready[MAX_PLAYERS + 1],
bool:bGetarea,
bool:bClean,
bool:bCsBeta,
bool:bPerformingRescue,
bool:bRegistered,
bool:bRescuing,
bool:bPlanted,
bool:bInfo,
bool:bFunc;

static g_status_msg, gmsgBarTime;
static g_mod[MAX_NAME_LENGTH];


//CONDITION ZERO TYPE BOTS. SPiNX
@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity( Ham_Spawn, ham_bot, "@spawn", 1);
        RegisterHamFromEntity( Ham_TakeDamage, ham_bot, "fw_PlayerTakeDamage", 0 );
        RegisterHamFromEntity( Ham_Killed, ham_bot, "fw_PlayerKilled", 1 );

        server_print("Respawn ham bot from %N", ham_bot)
        bRegistered = true;
    }
}

/* ========== Plugin Initialization ========== */
public plugin_precache()
{
    g_bHostageMap = has_map_ent_class(HOSTAGE_CLASSNAME) ? true : false
    
    if(!g_bHostageMap)
    {
        pause("c");
    }

    if (!file_exists(HOSTAGE_MODEL)) {
        log_amx("[Hostage] ERROR: Missing model %s", HOSTAGE_MODEL);
        pause("d")
    }
    if (!file_exists(CARRY_MODEL)) {
        log_amx("[Hostage] ERROR: Missing model %s", CARRY_MODEL);
        pause("d")
    }

    precache_model(HOSTAGE_MODEL);
    precache_model(CARRY_MODEL);

    get_modname(g_mod, charsmax(g_mod));
    if(equal(g_mod, "czero"))
    //if(equal(g_mod, "czero") && g_bHostageMap)
    for(new lot;lot < sizeof szCZsuffixes;++lot)
    {
        new szCZhostages[MAX_PLAYERS];
        formatex(szCZhostages, charsmax(szCZhostages),"models/hostage%s.mdl", szCZsuffixes[lot]);
        server_print "%s PRECACHED...", szCZhostages;
        precache_model(szCZhostages);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // Detect if current map is a hostage map
    //g_bHostageMap = has_map_ent_class(HOSTAGE_CLASSNAME) || has_map_ent_class("monster_scientist")
    g_bHostageMap = find_ent(MaxClients, HOSTAGE_CLASSNAME) > MaxClients ? true : false;
    if(!g_bHostageMap)
    {
        pause("a");
    }

    bCsBeta = get_cvar_num("hostage_use") ? true : false

    g_remove_zones = register_cvar("remove_zones", "0"); //Working left in. No longer needed with fake rescue points.
    //Dual objective maps like de_jeepathon bugfix for PodBot.
    register_logevent("FnPlant",3,"2=Planted_The_Bomb");
    g_pick_distance = register_cvar("pickup_distance", "120.0");
    g_carryspeed = register_cvar("carry_speed", "120.0");
    g_full_rescue = register_cvar("full_rescue", "0"); //rescue all like beta or 1 like cs2
    g_pickuptime = register_cvar("pickup_time", "4.0");
    g_bot_think = register_cvar("cs2_bot_think", "3.5");
    g_max_seek = register_cvar("cs2_bot_seek", "3"); //MAX_HOSTAGE_SEEKER

    g_freezetime = get_cvar_pointer("mp_freezetime");

    // Register events and messages
    gmsgBarTime = get_user_msgid("BarTime");
    g_status_msg = get_user_msgid("StatusIcon");
    g_cor = get_user_msgid( "ClCorpse" );

    register_event("TeamInfo", "event_team_switch", "a");
    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    register_event("StatusIcon", "@inzone", "be", "1=1", "2=rescue");
    register_event("StatusIcon", "@inzone", "be", "1=1", "2=buyzone");

    register_event("HostageK", "hostage_kill", "bc") //Thx VEN

    register_forward(FM_PlayerPreThink, "fw_PlayerThink");

    register_forward(FM_Use, "fw_UseHostageBlock", 0);
    register_logevent("logevent_round_start", 2, "1=Round_Start");
    register_logevent("@round_end", 2, "1=Round_End");

    register_logevent("logevent_hostage_rescued",3,"2=Rescued_A_Hostage");

    register_event("SendAudio", "@hostage_two", "a", "2&%!MRAD_escaped");

    // Register ham hooks
    RegisterHam(Ham_Use, HOSTAGE_CLASSNAME, "fw_HostageUse", 1);
    RegisterHam(Ham_Spawn, HOSTAGE_CLASSNAME, "fw_HostageSpawn", 1);
    RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage", 0);
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1);

    register_concmd("hostage_armor","@buy_armour", 0,": Buy hostage armor.");

    if(!equal(g_mod, "czero"))
    {
            bRegistered = true;
    }
    @find_zone();
    #if !defined MaxClients
    MaxClients = get_maxplayers();
    #endif
}

/* ========== Hostage Rescue Zone Functions ========== */
@find_zone()
{

    if(has_map_ent_class("func_hostage_rescue"))
    {
        bFunc = true
    }
    else if(has_map_ent_class("info_hostage_rescue"))
    {
        bInfo = true
    }
    if(bInfo || bFunc)
    {
        @multi_zone();
    }
    new cvar = get_pcvar_num(g_remove_zones)
    if(cvar)
    {
        set_task(0.5, "@remove_zones", 2025)
    }

    RegisterHam(Ham_Spawn, "player", "@spawn", 1)
    register_event("StatusIcon", "@inzone", "be", "1=1", "2=buyzone");
}

@multi_zone()
{
    new zone[MAX_PLAYERS];
    new zones

    zone = bInfo ? "info_hostage_rescue" : "func_hostage_rescue"

    g_rescue_area  = find_ent(MaxClients, zone)
    if(g_rescue_area)
    {
        zones++
        get_brush_entity_origin(g_rescue_area, g_rescue_origin)
        @make_fake_rescue()

        g_rescue_area2  = find_ent(g_rescue_area, zone)
        if(g_rescue_area2)
        {
            zones++
            get_brush_entity_origin(g_rescue_area2, g_rescue_origin2)
            @make_fake_rescue2()
        }
        g_rescue_area3  = find_ent(g_rescue_area2, zone)
        if(g_rescue_area3)
        {
            zones++
            get_brush_entity_origin(g_rescue_area3, g_rescue_origin3)
            @make_fake_rescue3()
        }
        g_rescue_area4  = find_ent(g_rescue_area3, zone)
        if(g_rescue_area4)
        {
            zones++
            get_brush_entity_origin(g_rescue_area4, g_rescue_origin4)
            @make_fake_rescue4()
        }
        remove_entity_name(zone)
        static szName[MAX_PLAYERS];
        get_mapname(szName, charsmax(szName))

        server_print "^n^nMap %s has (%i) ^"%s^" zones.^n^n", szName, zones, zone
    }

}

@remove_zones()
{
    if(has_map_ent_class("info_hostage_rescue"))
        remove_entity_name("func_hostage_rescue")

    if(has_map_ent_class("func_hostage_rescue"))
        remove_entity_name("func_hostage_rescue")
}

@make_fake_rescue()
{
    g_fake_rescue = create_entity("info_target")

    if(!g_fake_rescue)
        return 0

    set_pev(g_fake_rescue, pev_origin, g_rescue_origin)
    set_pev(g_fake_rescue,pev_classname, "fake_rescue");
    server_print "^n^n%f, %f, %f", g_rescue_origin[0], g_rescue_origin[1], g_rescue_origin[2]
    return g_fake_rescue;
}

@make_fake_rescue2()
{
    g_fake_rescue2 = create_entity("info_target")

    if(!g_fake_rescue2)
        return 0

    set_pev(g_fake_rescue2, pev_origin, g_rescue_origin2)
    set_pev(g_fake_rescue2,pev_classname, "fake_rescue");
    server_print "%f, %f, %f", g_rescue_origin2[0], g_rescue_origin2[1], g_rescue_origin2[2]
    return g_fake_rescue2;
}

@make_fake_rescue3()
{
    g_fake_rescue3 = create_entity("info_target")

    if(!g_fake_rescue3)
        return 0

    set_pev(g_fake_rescue3, pev_origin, g_rescue_origin3)
    set_pev(g_fake_rescue3,pev_classname, "fake_rescue");
    server_print "%f, %f, %f", g_rescue_origin3[0], g_rescue_origin3[1], g_rescue_origin3[2]
    return g_fake_rescue3;
}

@make_fake_rescue4()
{
    g_fake_rescue4 = create_entity("info_target")

    if(!g_fake_rescue4)
        return 0

    set_pev(g_fake_rescue4, pev_origin, g_rescue_origin4)
    set_pev(g_fake_rescue4,pev_classname, "fake_rescue");
    server_print "%f, %f, %f", g_rescue_origin4[0], g_rescue_origin4[1], g_rescue_origin4[2]
    return g_fake_rescue4;
}

@inzone(id)
{
    if(is_user_alive(id))
    {
         if(g_bCarryingHostage[id])
         {
            @hostage_one(id)
         }
         else
         {
            client_print id, print_center, szHostageResMsg
        }
    }
    return PLUGIN_HANDLED;
}

@spawn(id)
{
    set_task(0.5, "@spawn_", id)
}

@spawn_(id)
{
    static szentClass[MAX_NAME_LENGTH];
    if(!bGetarea)
    {
        if(is_user_alive(id) && get_user_team(id) ==2)
        {
            client_print id, print_chat, "Getting point..."
            bGetarea = true
            pev(id, pev_origin, g_rescue_origin)
            g_rescue_area = engfunc(EngFunc_FindEntityInSphere, MaxClients, g_rescue_origin, 64.0)
            {
                pev(g_rescue_area, pev_classname, szentClass, charsmax(szentClass))
                if(equal(szentClass, "info_player_start"))
                {
                    pev(g_rescue_area, pev_origin, g_rescue_origin)
                    client_print id, print_chat, "Got hostage rescue from your spawn point..."
                }
                else
                {
                    while ((g_rescue_area = engfunc(EngFunc_FindEntityInSphere, g_rescue_area, g_rescue_origin, 256.0)) > MaxClients && pev_valid(g_rescue_area))
                    {
                        pev(g_rescue_area, pev_classname, szentClass, charsmax(szentClass))
                        if(equal(szentClass, "info_player_start"))
                        {
                            pev(g_rescue_area, pev_origin, g_rescue_origin)
                            client_print id, print_chat, "Got hostage rescue from your spawn point..."
                            break;
                        }
                    }
                }
            }
        }
    }
}

stock get_loguser_index()
{
    new log_user[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_PLAYERS];
    read_logargv(0, log_user, charsmax(log_user));

    parse_loguser(log_user, name, charsmax(name));

    return get_user_index(name);
}

public logevent_hostage_rescued()
{
    new id = get_loguser_index();
    if(is_user_alive(id))
    {
        @hostage_one(id)
    }
}

@hostage_two()
{
    new ihostie = MaxClients;
    while((ihostie = find_ent(ihostie, HOSTAGE_CLASSNAME)) && pev_valid(ihostie))
    {
        #define TOGGLE "3"
        set_pev(ihostie, pev_origin, g_rescue_origin);
        ExecuteHam(Ham_Touch, ihostie, g_rescue_area);
    }
}

@hostage_one(id)
{
    #define TOGGLE "3"
    new ihostie = MaxClients;
    static buffer[4]
    if(is_user_alive(id) && g_bCarryingHostage[id])
    {
        new pick = random(2)
        switch(pick)
        {
            case 0: client_cmd id, "spk player/breathe1.wav"
            case 1: client_cmd id, "spk player/breathe2.wav"
        }
        while((ihostie = find_ent(ihostie, HOSTAGE_CLASSNAME)))
        if(pev_valid(ihostie))
        {
            set_pev(ihostie, pev_origin, g_rescue_origin)
            ExecuteHamB(Ham_Use, ihostie, id, id, TOGGLE,3.0); //ok info 3.0
            ///server_print "Hosatge #%i", ihostie

            num_to_str(ihostie, buffer, charsmax(buffer))
            set_task(0.23, "@Hammer", id, buffer, charsmax(buffer), "a", g_HostageCount-1)
        }
        rescue_hostage(id)
        FnPlant(); // when others are carrying
        @strip_piggyback()
    }
}

stock colored()
{
    return random(256);
}

@Hammer(buffer[], id)
{
    new ihostie = str_to_num(buffer)
    if(is_user_connected(id) && pev_valid(ihostie))
    {
        set_pev(ihostie, pev_origin, g_rescue_origin)
        ExecuteHamB(Ham_Use, ihostie, id, id, TOGGLE, 1.0);
        show_status_icon(id, "hostage", colored(),colored(),colored());
    }
}

@strip_piggyback()
{
    for (new index = 1; index <= MaxClients; index++)
    {
        if(g_bCarryingHostage[index])
        {
            FnPlant()
            ///client_print(0, print_chat, "Removed %N back carry", index)
            show_bar(index, 0);
            RemoveHostageOnBack(index)
        }
    }
}

public FnPlant()
{
    bPlanted = true
    for (new id = 1; id <= MaxClients; id++)
    {
        //For PodBot bug on Jeep when rescuing and C4 is planted they freeze.
        if(is_user_alive(id) && bIsBot[id] && g_bCarryingHostage[id])
        {
            static hostage; hostage = 0, hostage = g_CarriedHostage[id];
            if(pev_valid(hostage))
            {
                set_pev(hostage, pev_owner, 0)
                drop_carried_hostage(id)

                set_pev(hostage, pev_origin, g_rescue_origin)
                set_pev(hostage, pev_origin, fNullOrigin) //stop rescuing them all
                ExecuteHamB(Ham_Touch,hostage,g_rescue_area)
                RemoveHostageOnBack(id)
            }
        }
    }
}

/* ========== Hostage Back Model Functions ========== */
public ShowHostageOnBack(id) {
    if(is_user_alive(id))
    {
        new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
        if(ent>MaxClients)

        if(pev_valid(ent) == 2)
        {
            g_bCarryingHostage[id] = true;
            set_pev(ent, pev_classname, HOSTAGE_CLASSNAME);
            set_pev(ent, pev_movetype, MOVETYPE_FOLLOW);
            set_pev(ent, pev_aiment, id);
            set_pev(ent, pev_solid, SOLID_SLIDEBOX);
            set_pev(ent, pev_takedamage, DAMAGE_YES)
            set_pev(ent, pev_owner, id)
            set_pev(ent, pev_rendermode, kRenderNormal);
            set_pev(ent, pev_renderamt, 255.0);

            new Float:minbox[3] = { -Body_sizeB, -Body_sizeB, -Body_sizeA }
            new Float:maxbox[3] = { Body_sizeB, Body_sizeB, Body_sizeA }

            entity_set_size(ent, minbox, maxbox )

            engfunc(EngFunc_SetModel, ent, CARRY_MODEL);
            set_pev(ent, pev_body, 0);
            set_pev(ent, pev_sequence, 0);
            set_pev(ent, pev_animtime, get_gametime());
            set_pev(ent, pev_framerate, 1.0);
            set_pev(ent, pev_angles, Float:{0.0, 180.0, 0.0});
            bCarryingAlready[id]= true
            g_iCarryHostageBackEnt[id] = ent;
        }
        else
        {
            RemoveHostageOnBack(id);
        }
    }
    return PLUGIN_HANDLED;
}

public RemoveHostageOnBack(id)
{
    if(is_user_connected(id))
    {
        if (g_iCarryHostageBackEnt[id] )
        {
            if(g_bCarryingHostage[id])
            {
                //holster knife
                g_bCarryingHostage[id] = false
            }
            if(pev_valid(g_iCarryHostageBackEnt[id]))
            {
                set_pev(g_iCarryHostageBackEnt[id], pev_owner, 0)
                engfunc(EngFunc_RemoveEntity, g_iCarryHostageBackEnt[id]);
            }
            g_iCarryHostageBackEnt[id] = 0;
        }
    }
}

/* ========== Client Events ========== */
public client_putinserver(id)
{
    if(id&id<=MaxClients)
    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
        if(bIsBot[id])
        {
            if(!bRegistered)
            {
                set_task(0.1, "@register", id);
            }
            if(!task_exists(2025))
            {
                set_task(get_pcvar_float(g_bot_think), "@bot_think", 2025, "", 0, "b"); //directs bots
            }
        }
    }
}

public client_disconnected(id)
{
    drop_carried_hostage(id);
    RemoveHostageOnBack(id);
    show_bar(id, 0); // Added to ensure bar is cleared
    bIsBot[id] = false;
}

public event_team_switch() {
    static id, team[2];
    id = read_data(1);
    read_data(2, team, charsmax(team));

    if (!equal(team, "CT")) {
        RemoveHostageOnBack(id);
        drop_carried_hostage(id);
    }
}

/* ========== Round Management ========== */
public event_new_round() {
    g_hosties_seeker = 0;

    for (new id = 1; id <= MaxClients; id++){
    bScouting[id] = false
    if(!is_user_connected(id))
        return

    show_bar(id, 0); // Added to ensure bar is cleared

    if (g_bCarryingHostage[id]) {
        new hostage = g_CarriedHostage[id];
        if (pev_valid(hostage)) {
            static Float:origin[3];
            pev(id, pev_origin, origin);
            engfunc(EngFunc_SetOrigin, hostage, origin);
            set_pev(hostage, pev_solid, SOLID_SLIDEBOX);
            set_pev(hostage, pev_health, 100.0)
            set_pev(hostage, pev_armorvalue, 200.0)
            set_pev(hostage, pev_movetype, MOVETYPE_STEP);
            set_pev(hostage, pev_rendermode, kRenderNormal);
            set_pev(hostage, pev_renderamt, 255.0);
            set_pev(hostage, pev_iuser1, 0);
            set_ent_visibility_to_player(hostage, id, true);
        }

        g_bCarryingHostage[id] = false;
        g_CarriedHostage[id] = 0;
        initialize_hostages();
    }
  }
}

@round_end()
{
    new ent = MaxClients
    new iCount
    if(!bClean)
    {
        while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", HOSTAGE_CLASSNAME)) > MaxClients && pev_valid(ent))
        {
            bClean = true
            iCount++
            set_pev(ent, pev_origin, fNullOrigin)
        }
        g_HostageCount = iCount
        server_print "^n^nThere are %i hostages...^n^n", g_HostageCount
    }

    bPlanted = false
    bRescuing = false

    for (new id; id <= MaxClients; id++)
    {
        if(is_user_connected(id))
        {
            drop_carried_hostage(id)
            bScouting[id] = false
            remove_task(id)
            RemoveHostageOnBack(id)
        }
    }
    if(g_freezetime)
    {
        set_task(1.0, "event_new_round");
    }
}

public logevent_round_start()
{
    set_task(0.1, "initialize_hostages");
    //g_range = get_pcvar_float(g_pick_distance)
    change_task(2025, get_pcvar_float(g_bot_think))
    bClean = false
}

public initialize_hostages()
{
    new ent = MaxClients
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", HOSTAGE_CLASSNAME)) && pev_valid(ent) ==2 )
    {

        if (g_HostageCount < MAX_HOSTAGES)
        {
            pev(ent, pev_origin, g_HostageOrigins[g_HostageCount]);
            g_HostageEnts[g_HostageCount++] = ent;
        }

        set_pev(ent, pev_iuser1, 0);
        set_pev(ent, pev_rendermode, kRenderNormal);
        set_pev(ent, pev_renderamt, 255.0);
        set_pev(ent, pev_owner, 0)

        dllfunc(DLLFunc_Spawn, ent);
    }
    // Reset hostage positions
    for (new i = 0; i < g_HostageCount; i++)
    {
        if(pev_valid(g_HostageEnts[i]) == 2)
        {
            set_pev(g_HostageEnts[i], pev_origin, fNullOrigin)
            engfunc(EngFunc_SetOrigin, g_HostageEnts[i], g_HostageOrigins[i]);
            static effects; effects = pev(g_HostageEnts[i], pev_effects)
            set_pev(g_HostageEnts[i], pev_effects, (effects & ~EF_NODRAW))
        }
    }

    // Reset player states
    for (new id = 1; id <= MaxClients; id++) {
        set_task(5.0, "@shutup", id)
        if (is_user_connected(id) && g_bCarryingHostage[id]) {
            new hostage = g_CarriedHostage[id];
            if (hostage & pev_valid(hostage)) {
                static Float:origin[3];
                pev(id, pev_origin, origin);
                engfunc(EngFunc_SetOrigin, hostage, origin);
                set_pev(hostage, pev_renderamt, 255.0);
                set_pev(hostage, pev_iuser1, 0);
                set_ent_visibility_to_player(hostage, id, true);
            }

            g_CarriedHostage[id] = 0;
            g_bCarryingHostage[id] = false;
        }

        g_bTryingPickup[id] = false;
        g_LastDropTime[id] = 0.0;
        g_CarryCount[id] = 0;
        g_PendingHostage[id] = 0;

        show_bar(id, 0);
        show_status_icon(id, "hostage", 60, 60, 60);
    }

    g_bRescueEnded = false;

}

@shutup(id)
{
    if(is_user_connected(id) && !bIsBot[id])
    {
        client_cmd id, "stopsound";
    }
}

/* ========== Player Think Functions ========== */
public fw_PlayerThink(id) {
    if (!is_user_alive(id) || !is_user_connected(id) || bIsBot[id])
        return;
    new Float:fRange = get_pcvar_float(g_pick_distance)
    // Restore speed after freeze time if not carrying
    if (!g_bCarryingHostage[id]) {
        if(!bCsBeta)
            set_pev(id, pev_maxspeed, 272.0);
        return;
    }

    // Carrying hostage logic
    static Float:origin[3], Float:offset[3];
    pev(id, pev_origin, origin);
    offset[0] = origin[0] - 20.0;
    offset[1] = origin[1];
    offset[2] = origin[2];

    new hostage = g_CarriedHostage[id];
    if (pev_valid(hostage)==2) {
        engfunc(EngFunc_SetOrigin, hostage, offset);
        set_pev(hostage, pev_angles, Float:{0.0, 0.0, 0.0});
    }

    if(g_fake_rescue)
    if(entity_range(id, g_fake_rescue) <= fRange)
    {
        @hostage_one(id)
    }
    if(g_fake_rescue2)
    {
        if(entity_range(id, g_fake_rescue2) <= fRange || entity_range(id, g_fake_rescue3) <= fRange || entity_range(id, g_fake_rescue4) <= fRange )
        {
            @hostage_one(id)
        }
    }
    new stabby = get_user_weapon(id) == CSW_KNIFE
    new Float:speed = get_pcvar_float(g_carryspeed)
    new crouch = pev(id, pev_button) & IN_DUCK & pev(id, pev_oldbuttons) & IN_DUCK
    if(!crouch)
    {
        set_pev(id, pev_maxspeed, stabby ? speed*3 : speed)
    }
}

/* ========== Hostage Pickup/Drop Functions ========== */

public fw_UseHostageBlock(ent, idcaller, idactivator, use_type, Float:value) {
    if (!pev_valid(ent) || !is_user_alive(idcaller) || g_CarriedHostage[idcaller] != 0  || bPerformingRescue == true)
        return FMRES_IGNORED;

    if(g_bCarryingHostage[idcaller])
        return FMRES_SUPERCEDE;

    // Block terrorists from initiating pickup
    if (get_user_team(idcaller) != 2)
        return FMRES_SUPERCEDE;

    static classname[MAX_PLAYERS];
    pev(ent, pev_classname, classname, charsmax(classname));
    if (!equal(classname, HOSTAGE_CLASSNAME))
        return FMRES_IGNORED;
    return FMRES_IGNORED;
}

public fw_HostageTouch(ent, id)
{
    if(pev_valid(ent))
    {
        if(pev(ent, pev_owner, id)==0)
            set_pev(ent, pev_owner, id)
        if(pev(ent, pev_owner, id)!=id)
            return HAM_SUPERCEDE;
        //maybe stop others from stealing/messing model on carrier
        if(g_CarriedHostage[ent] || g_bCarryingHostage[id])
        {
            if(is_user_alive(id))
            {
                client_print 0, print_center, "Canceled %n's hostage steal!", id
                return HAM_SUPERCEDE;
            }
        }
    }
    return HAM_IGNORED;
}

public fw_HostageUse(ent, idcaller, idactivator, use_type, Float:value)
{
    if(pev_valid(ent))
    if (!is_user_alive(idcaller) || get_user_team(idcaller) != 2 || g_bRescueEnded || pev(ent, pev_owner) != 0)
        return HAM_SUPERCEDE;

    if(g_bCarryingHostage[idcaller])
    {
        client_print(idcaller, print_center, "You're already carrying a hostage!");
        if(bIsBot[idcaller])
        {
            new ent = MaxClients
            while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", HOSTAGE_CLASSNAME)))
            {
                if(pev_valid(ent))
                {
                    set_pev(ent, pev_origin, fNullOrigin)
                }
            }
        }
        return HAM_SUPERCEDE;
    }

    if (g_bTryingPickup[idcaller] || get_gametime() - g_LastDropTime[idcaller] < 1.0)
        return HAM_SUPERCEDE;

    g_bTryingPickup[idcaller] = true;
    g_PickupStartTime[idcaller] = get_gametime();
    g_PendingHostage[idcaller] = ent;

    client_print(idcaller, print_center, "Hold USE to pick up the hostage...");
    show_bar(idcaller, floatround(get_pcvar_float(g_pickuptime)));

    new buffer[4];
    num_to_str(ent, buffer, charsmax(buffer));

    set_task(0.1, "show_progress_bar", idcaller, buffer, charsmax(buffer), "b");
    return HAM_SUPERCEDE;
}

public show_progress_bar(ent[], id) {
    if (!is_user_alive(id) || !g_bTryingPickup[id])
        return;
    new Float:fRange = get_pcvar_float(g_pick_distance)
    new hostie = str_to_num(ent)

    if(pev_valid(hostie))
        set_pev(hostie, pev_owner, id)

    if(entity_range(id, hostie) > fRange)
    {
        client_print id, print_center, "You are too far to rescue."
        cancel_pickup(id);
        return;
    }

    new iOwner = pev(hostie, pev_owner)
    if (iOwner != id) {
        remove_task(id);
        show_bar(id, 0);
        cancel_pickup(id);
        return;
    }

    if (g_bCarryingHostage[id]) {
        cancel_pickup(id);
        return;
    }

    if (!(pev(id, pev_button) & IN_USE)) {
        if(!bIsBot[id])
        {
            client_cmd id, "spk items/tr_kevlar.wav"
        }
        cancel_pickup(id);
        return;
    }
    show_status_icon(id, "hostage", colored(),colored(),colored());
    new Float:elapsed = get_gametime() - g_PickupStartTime[id];
    if (elapsed >= get_pcvar_num(g_pickuptime)) {
        pickup_hostage(id);
        remove_task(id);
        show_bar(id, 0);
    }
}

public cancel_pickup(id) {
    static ent;ent=0;
    if (pev_valid(g_PendingHostage[id])) {
        ent = g_PendingHostage[id]
        set_ent_visibility_to_player(ent, id, true);
    }
    if(pev_valid(ent))
    {
        set_pev(ent, pev_owner, 0)
    }
    g_bTryingPickup[id] = false;
    g_PendingHostage[id] = 0;
    remove_task(id);
    show_bar(id, 0);
    if(is_user_connected(id))
    {
        client_print(id, print_center, "Hostage pickup cancelled.");
        if(bIsBot [id])
        {
            set_pev(id,pev_flags,pev(id,pev_flags) & ~FL_FROZEN);
        }
    }
}

public pickup_hostage(id) {
    if(is_user_alive(id))
    {
        new ent = g_PendingHostage[id];
        if(bIsBot[id])
        {
            set_pev(id,pev_flags,pev(id,pev_flags) & ~FL_FROZEN);
        }

        if (g_bCarryingHostage[id])
            return;

        new iOwner = pev(ent, pev_owner)
        if (iOwner == 0 && pev_valid(ent))
        {
            set_pev(ent, pev_owner, id)
        }
        else if (iOwner != id)
        {
            client_print 0, print_center, "Canceled %n's hostage steal.", id
            return;
        }


        if (!is_user_alive(id) || !pev_valid(ent)) {
            g_bTryingPickup[id] = false;
            g_PendingHostage[id] = 0;
            return;
        }

        g_bTryingPickup[id] = false;
        g_bCarryingHostage[id] = true;
        g_CarriedHostage[id] = ent;
        g_PendingHostage[id] = 0;

        set_pev(ent, pev_movetype, MOVETYPE_NONE);
        set_pev(ent, pev_iuser1, 99);
        set_pev(ent, pev_target, 0);

        set_pev(ent, pev_renderfx, kRenderFxNone);
        set_pev(ent, pev_rendermode, kRenderTransTexture);
        set_pev(ent, pev_renderamt, 255.0);

        show_status_icon(id, "hostage", 0, 160, 255);
        set_ent_visibility_to_player(ent, id, false);

        client_print(id, print_center, "You picked up the hostage!");

        if(!bIsBot[id])
        {
            client_cmd id, "spk player/heartbeat1.wav"
        }

        ShowHostageOnBack(id);
        if(g_hosties_seeker == get_pcvar_num(g_max_seek))
        {
            bRescuing = true
        }
    }
}

/* ========== Hostage Rescue Functions ========== */
public rescue_hostage(id) {
    if (!is_user_alive(id) || !g_bCarryingHostage[id])
        return;

    new hostage = g_CarriedHostage[id];
    if (pev_valid(hostage)) {
        set_pev(hostage, pev_iuser1, 99);
        set_ent_visibility_to_player(hostage, id, true);
    }

    g_CarriedHostage[id] = 0;
    g_bCarryingHostage[id] = false;
    g_LastDropTime[id] = get_gametime();
    g_CarryCount[id]++;


    show_status_icon(id, "hostage", 60, 60, 60);
    bRescuing = false
    client_cmd 0, "spk ambience/copter.wav"
    client_cmd id, "spk events/task_complete.wav"
}

/* ========== Hostage Entity Functions ========== */
public fw_HostageSpawn(ent) {//spawns like this even after player dies not just new round
    if (!pev_valid(ent))
        return HAM_IGNORED;

    engfunc(EngFunc_SetModel, ent, HOSTAGE_MODEL);
    set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_MONSTER);

    set_pev(ent, pev_movetype, MOVETYPE_STEP);
    set_pev(ent, pev_solid, SOLID_SLIDEBOX);
    set_pev(ent, pev_classname, HOSTAGE_CLASSNAME)

    new Float:minbox[3] = { -Body_sizeB, -Body_sizeB, -Body_sizeA }
    new Float:maxbox[3] = { Body_sizeB, Body_sizeB, Body_sizeA }

    set_pev(ent, pev_takedamage, DAMAGE_YES)
    entity_set_size(ent, minbox, maxbox )
    return HAM_IGNORED;
}

public fw_HostageTakeDamage(ent, inflictor, attacker, Float:damage, damagebits) {
    return HAM_SUPERCEDE;
}

public hostage_kill()
{
    new Float:Axis[3], Float:Pos[3];
    new hid = read_data(1)
    new ent = cs_get_hostage_entid(hid)

    new Float:origin[3];
    if(ent & g_rescue_area)
    if(pev_valid(ent) && pev_valid(g_rescue_area))
    {
        pev(ent,pev_origin, origin)

        if(origin[0] != fNullOrigin[0] && origin[1] != fNullOrigin[1])
        if(entity_range(ent,g_rescue_area)>1000.0) //should not see death effects during rescue.
        {
            entity_get_vector(ent,EV_VEC_origin,Pos);
            entity_get_vector(ent,EV_VEC_angles,Axis);

            @hostage_splatter(Pos, Axis)

            for (new id = 1; id <= MaxClients; id++)
            {
                if(is_user_connected(id) && !bIsBot[id])
                {
                    client_cmd id, "spk radio/hosdown.wav"

                    new rPick = random_num(1,25);
                    new SzCry[MAX_PLAYERS];
                    formatex(SzCry, charsmax(SzCry), rPick < 10 ? "spk scientist/scream0%i.wav" : "spk scientist/scream%i.wav", rPick)

                    client_cmd id, "%s",SzCry;
                }
            }
        }
        new owner = pev(ent, pev_owner)
        if(owner && pev_valid(ent))
        {
            set_pev(ent, pev_owner, 0)
            RemoveHostageOnBack(owner)
            set_pev(ent, pev_origin, fNullOrigin)
        }
    }
}

stock cs_get_hostage_entid(hid) {
    new hent = MaxClients, field[] = "classname"
    while ((hent = engfunc(EngFunc_FindEntityByString, hent, field, HOSTAGE_CLASSNAME)) &&
        cs_get_hostage_id(hent) != hid) {}

    return hent;
}

@hostage_splatter(Float:Pos[], Float:Axis[])
{
    new color = 79
    new time = 500
    //https://github.com/baso88/SC_AngelScript/wiki/Temporary-Entities#miscellaneous
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, Float:{0.0,0.0,0.0}, 0)
    write_byte(TE_BLOODSTREAM)
    write_coord_f(Pos[0])
    write_coord_f(Pos[1])
    write_coord_f(Pos[2])
    write_coord_f(Axis[0])
    write_coord_f(Axis[1])
    write_coord_f(Axis[2])
    write_byte(color)
    write_byte(time)
    message_end
}

/* ========== Player Death Handling ========== */
public fw_PlayerKilled(id, attacker, shouldgib) {
    if(bScouting[id])
    {
        bScouting[id] = false
        g_hosties_seeker--
    }
    if(bIsBot[id])
    {
        set_pev(id,pev_flags,pev(id,pev_flags) & ~FL_FROZEN);
    }
    else
    {
        set_msg_block( g_cor, BLOCK_NOT );
    }

    if (!g_bCarryingHostage[id])
        return;

    @shutup(id)

    if(bIsBot[id])
    {
        set_msg_block( g_cor, BLOCK_SET );
    }

    if(is_user_connected(id))
    {
        new hostage = g_CarriedHostage[id];
        if (pev_valid(hostage))
        {
            set_pev(hostage, pev_owner, 0) //stealing
            static Float:death_origin[3];
            pev(id, pev_origin, death_origin);
            death_origin[2] -= 35.0;
            set_pev(hostage, pev_origin, death_origin)

            set_pev(hostage, pev_solid, SOLID_SLIDEBOX);
            set_pev(hostage, pev_movetype, MOVETYPE_STEP);

            set_pev(hostage, pev_classname, HOSTAGE_CLASSNAME);
            set_pev(hostage, pev_takedamage, DAMAGE_YES)

            set_pev(hostage, pev_rendermode, kRenderNormal);
            set_pev(hostage, pev_renderamt, 255.0);

            set_pev(hostage, pev_iuser1, 0);
            set_ent_visibility_to_player(hostage, id, true);
            bRescuing = false
            RemoveHostageOnBack(id);
            drop_to_floor(hostage)
        }

        g_CarriedHostage[id] = 0;
        g_bCarryingHostage[id] = false;
        g_bTryingPickup[id] = false;
        g_LastDropTime[id] = get_gametime();
        show_bar(id, 0);
        show_status_icon(id, "hostage", 60, 60, 60);
    }
}

/* ========== Hostage Drop Functions ========== */
stock drop_carried_hostage(id) {
    if (!g_bCarryingHostage[id])
        return;

    RemoveHostageOnBack(id);
    @shutup(id)
    new hostage = g_CarriedHostage[id];
    if (hostage & pev_valid(hostage)) {

        new Float:origin[3];

        if(is_user_connected(id))
            pev(id, pev_origin, origin);

        origin[2] -= 50.0

        pev(hostage, pev_origin, origin)

        drop_to_floor(hostage)

        set_pev(hostage, pev_movetype, MOVETYPE_STEP);
        set_pev(hostage, pev_solid, SOLID_SLIDEBOX);
        set_pev(hostage, pev_classname, HOSTAGE_CLASSNAME)

        new Float:minbox[3] = { -Body_sizeB, -Body_sizeB, -Body_sizeA }
        new Float:maxbox[3] = { Body_sizeB, Body_sizeB, Body_sizeA }

        set_pev(hostage, pev_takedamage, DAMAGE_YES)
        entity_set_size(hostage, minbox, maxbox ) //hitbox to be able to size the shots

        set_pev(hostage, pev_rendermode, kRenderNormal);
        set_pev(hostage, pev_renderamt, 255.0);
        set_pev(hostage, pev_iuser1, 0);
        set_ent_visibility_to_player(hostage, id, true);
        set_pev(hostage, pev_owner, 0);
    }

    g_CarriedHostage[id] = 0;
    g_bCarryingHostage[id] = false;
    g_bTryingPickup[id] = false;
    g_LastDropTime[id] = get_gametime();
    show_bar(id, 0);
    show_status_icon(id, "hostage", 60, 60, 60);
    bCarryingAlready[id] = false;
}

@buy_armour(id) //powerup
{
    new ihostage;
    new fHealth;
    if(is_user_connected(id))
    {
        if(is_user_alive(id) && g_bCarryingHostage[id])
        {

            for (new i = 0; i < g_HostageCount; i++)
            if (pev_valid(g_HostageEnts[i]))
            if(pev(g_HostageEnts[i], pev_owner) == id)

            ihostage = g_HostageEnts[i];

            if(get_user_team(id) == 2 && pev_valid(ihostage))
            {
                fHealth = pev(ihostage, pev_health);
                client_print id, print_chat, "Hostage health:%i", fHealth;

                if(fHealth == 100.0)
                {
                    set_pev(ihostage, pev_health, 200.0)
                    set_pev(ihostage, pev_max_health, 200.0)
                    set_pev(ihostage, pev_armorvalue, 300.0)
                    set_pev(ihostage, pev_armortype, 2)
                    client_print 0, print_chat, "Reinforced %n's hostage.", id
                }
            }
        }
        else
        {
            client_print id, print_chat, "Must be carrying a hostage to buy them armor!"
        }
    }
    return PLUGIN_HANDLED;
}

/* ========== Utility Functions ========== */
stock show_status_icon(id, const icon[], r, g, b)
{
    if(is_user_alive(id) && get_user_team(id) == 2)
    {
        new flags = pev(id, pev_flags)
        if(flags & FL_SPECTATOR)
            return;

        emessage_begin(MSG_ONE_UNRELIABLE, g_status_msg, _, id);
        ewrite_byte(1);
        ewrite_string(icon);
        ewrite_byte(r);
        ewrite_byte(g);
        ewrite_byte(b);
        emessage_end();
    }
}

stock show_bar(id, duration) {
    if (!is_user_connected(id))
        return;
    emessage_begin(MSG_ONE_UNRELIABLE, gmsgBarTime, _, id);
    ewrite_short(duration);
    emessage_end();
}

stock set_ent_visibility_to_player(ent, player, bool:visible) {
    if (!is_user_connected(player) || !pev_valid(ent))
        return;

    set_pev(ent, pev_rendermode, visible ? kRenderNormal : kRenderTransTexture);
    set_pev(ent, pev_renderamt, visible ? 255.0 : 0.0);
}

stock bool:is_in_rescue_zone(Float:origin[3]) {
    static Float:rescue_origin[3], Float:mins[3], Float:maxs[3];
    pev(g_rescue_area, pev_origin, rescue_origin);
    pev(g_rescue_area, pev_mins, mins);
    pev(g_rescue_area, pev_maxs, maxs);

    if (origin[0] >= rescue_origin[0] + mins[0] && origin[0] <= rescue_origin[0] + maxs[0] &&
        origin[1] >= rescue_origin[1] + mins[1] && origin[1] <= rescue_origin[1] + maxs[1] &&
        origin[2] >= rescue_origin[2] + mins[2] && origin[2] <= rescue_origin[2] + maxs[2]) {
        return true;
    }
    return false;
}

stock bool:find_nearest_hostage(Float:from[3], Float:out[3]) {
    new Float:min_dist = 99999.0;
    new bool:found = false;

    for (new i = 0; i < g_HostageCount; i++) {
        new ent = g_HostageEnts[i];
        if (!pev_valid(ent) || pev(ent, pev_iuser1) != 0)
            continue;

        static Float:origin[3];
        pev(ent, pev_origin, origin);

        new Float:dist = get_distance_f(from, origin);
        if (dist < min_dist) {
            min_dist = dist;
            out[0] = origin[0];
            out[1] = origin[1];
            out[2] = origin[2];
            found = true;
        }
    }
    return found;
}


public fw_PlayerTakeDamage(ent, inflictor, attacker, Float:damage, damagebits)
{
    if(bIsBot[ent])
    {
        bAttacked[ent] = true
    }
}

/* ========== Bot AI Functions ========== */
@bot_think()
{
    new Float:bot_origin[3],Float:hostage_pos[3];
    new Float:fRange = get_pcvar_float(g_pick_distance)
    if(get_playersnum())
    {
        for (new id = 1; id <= MaxClients; id++)
        {
            if(bIsBot[id])
            {
                if(is_user_alive(id) && get_user_team(id) == 2)
                {
                    // Added cooldown check for bots
                    if (get_gametime() - g_LastDropTime[id] < 2.0)
                        continue;

                    pev(id, pev_origin, bot_origin);

                    // Carrying a hostage - move to nearest rescue zone
                    if (g_bCarryingHostage[id])
                    {
                        amxclient_cmd id, "hostage_armor"
                        if(!bAttacked[id])
                        {
                            if(get_user_weapon(id) != CSW_KNIFE)
                            {
                                if(pev(id,pev_button)  & IN_RELOAD)
                                    break;
                                else
                                {
                                    amxclient_cmd( id, "weapon_knife");
                                }
                            }
                        }
                        bAttacked[id] = false;

                        fRange = fRange*1.5
                        if(g_fake_rescue)
                        {
                            if(entity_range(id, g_fake_rescue) <= fRange)
                            {
                                @hostage_one(id)
                            }
                            if(g_fake_rescue2)
                            {
                                if(entity_range(id, g_fake_rescue2) <= fRange || entity_range(id, g_fake_rescue3) <= fRange || entity_range(id, g_fake_rescue4) <= fRange )
                                {
                                    @hostage_one(id)
                                }
                            }
                        }
                        if (get_distance_f(bot_origin, g_rescue_origin) <  fRange && is_in_rescue_zone(bot_origin)) {
                            rescue_hostage(id);
                            RemoveHostageOnBack(id);
                        }
                        continue;
                    }

                    if(bRescuing && !get_pcvar_num(g_full_rescue)|| bPlanted)
                        break;

                    if(!bScouting[id] && g_hosties_seeker != get_pcvar_num(g_max_seek))
                    {
                        bScouting[id] = true
                        g_hosties_seeker++
                    }

                    // Not carrying - move to nearest unclaimed hostage
                    if(bScouting[id])

                    ////////FIND AND GRAB CODE
                    if (find_nearest_hostage(bot_origin, hostage_pos)) {
                        if (get_distance_f(bot_origin, hostage_pos) < fRange) {
                            for (new i = 0; i < g_HostageCount; i++) {
                                new hostage = g_HostageEnts[i];
                                if (!pev_valid(hostage) || pev(hostage, pev_iuser1) != 0)
                                    continue;

                                static Float:ent_origin[3];
                                pev(hostage, pev_origin, ent_origin);
                                if(!g_PendingHostage[id] || !g_iCarryHostageBackEnt[id])
                                if (get_distance_f(bot_origin, ent_origin) < fRange) {
                                    g_PendingHostage[id] = hostage;

                                    new iOwner = pev(hostage, pev_owner)
                                    if (iOwner == 0)
                                    {
                                        set_pev(hostage, pev_owner, id)
                                    }
                                    set_pev(id,pev_flags,pev(id,pev_flags) | FL_FROZEN);
                                    set_task(float(get_pcvar_num(g_pickuptime)), "pickup_hostage", id);
                                    client_print 0, print_center, "%n[AI] is picking up hostage!", id
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    else
    {
        remove_task(2025)
    }
}
