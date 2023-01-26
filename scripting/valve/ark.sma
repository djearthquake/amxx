/*This is what I was using prior to fixing BadCamper for HL -SPiNX.
 *
 *  Author:     Cheesy Peteza (original script this is based on.)
 *  Date:       18-Mar-2004
 *
 *
 *  Description:    A generic ark Morph that should work with nearly all Half-Life mods.
 *          Tested with Natural-Selection v3.0 beta 3, Counter-Strike 1.6 and Day of Defeat.
 *
 *  Cvars:
 *          mp_arktime 45       Time a player is allowed to be ark in seconds before they are morphed. (minimum 30 sec)
 *          The time is only accumulated while they are alive.
 *          mp_arkminplayers 4  Minimum number of players required to be on the server before the plugin starts kicking.
 *
 *
 *  Requirements:   AMXModX
 *
 *
 */

#include <amxmodx>
#include <fakemeta>
#include <fun> //for weapon gives

#define MIN_ark_TIME 30     // I use this incase stupid admins accidentally set mp_arktime to something silly.
#define WARNING_TIME 20     // Start warning the user this many seconds before they are about to be morphed.
#define CHECK_FREQ 5        // This is also the warning message frequency.
#define HURT            // Uses the OUTCOMES section, if defined.
#define MODEL           // make entity appear in middle of map to entertain

new g_oldangles[MAX_PLAYERS + 1][3]
new g_arktime[MAX_PLAYERS + 1]
new bool:g_spawned[MAX_PLAYERS + 1] = {true, ...}
new g_Money, g_Funny

#if defined(MODEL)
new g_Sunny, g_Spec, g_Spec2, g_Spec3
#endif

public plugin_precache()
{
    //sprites
    g_Money = precache_model("sprites/camper2.spr")
    g_Funny = precache_model("sprites/zerogxplode.spr")
    
    
    #if defined(MODEL)
    //models
    g_Sunny = precache_model("models/geneworm.mdl")
    g_Spec  = precache_model("models/oceanfront/blondbab.mdl")
    g_Spec2  = precache_model("models/voltigore.mdl")
    g_Spec3  = precache_model("models/antfarms/looker35.mdl")
    #endif
}

public plugin_init() {
    register_plugin("ark Morph","2","SPiNX/Cheesy Peteza")
    register_cvar("ark_version", "2", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)

    register_cvar("mp_arktime", "151")  // Kick people ark longer than this time
    register_cvar("mp_arkminplayers", "5")  // Only kick arks when there is atleast this many players on the server
    set_task(float(CHECK_FREQ),"checkPlayers",_,_,_,"b")
    register_event("ResetHUD", "playerSpawned", "be")
}

public checkPlayers() {
    for (new i = 1; i <= get_maxplayers(); i++) {
            if (is_user_connected(i) && is_user_alive(i) && g_spawned[i]) {

            new newangle[3]
            get_user_origin(i, newangle)

            if ( newangle[0] == g_oldangles[i][0] && newangle[1] == g_oldangles[i][1] && newangle[2] == g_oldangles[i][2] ) {
                g_arktime[i] += CHECK_FREQ
                check_arktime(i)
            } else {
                g_oldangles[i][0] = newangle[0]
                g_oldangles[i][1] = newangle[1]
                g_oldangles[i][2] = newangle[2]
                g_arktime[i] = 0
            }
        }
    }
    return PLUGIN_HANDLED
}

check_arktime(id)
{
    new numplayers = get_playersnum()
    new minplayers = get_cvar_num("mp_arkminplayers")
    #if defined(MODEL)
    new Float:sOrigin[3];
    #endif

    //start disk
    new Float:bOrigin[3];
    pev(id,pev_origin,bOrigin);
    bOrigin[2] += 20
    //end disk
    if (numplayers >= minplayers)
    {
        new maxarktime = get_cvar_num("mp_arktime")
        if (maxarktime < MIN_ark_TIME)
        {
            log_amx("cvar mp_arktime %i is too low. Minimum value is %i.", maxarktime, MIN_ark_TIME)
            maxarktime = MIN_ark_TIME
            set_cvar_num("mp_arktime", MIN_ark_TIME)
        }
    
        if ( maxarktime-WARNING_TIME <= g_arktime[id] < maxarktime)
        {
            new timeleft = maxarktime - g_arktime[id]
            client_print(id, print_chat, "[ARK] You have %i seconds to move or you will be morphed for camping afk!", timeleft)
        }
        else if(g_arktime[id] > maxarktime)
        {
            ////////////////
            //AFK OUTCOMES//
            ///////////////
            //get name and ID of player
            new name[MAX_PLAYERS]
            get_user_name(id, name, 31)
            new Authid[MAX_PLAYERS]
            get_user_authid( id, Authid, 31)
        
            #if defined(HURT)
            switch(random(25))
            {
                case 0: user_slap(id, 5, 0)
                case 1: user_slap(id, 2, 1)
                case 2: server_cmd("allow_nukes 1")
                case 3: server_cmd("allow_nukes 0")
                case 4: console_cmd(id, "nuke 40 12000")
                case 5: client_print(0, print_chat, "[ARK] %s %s was morphed for camping afk longer than %i seconds", name, Authid, maxarktime)
                case 6: console_cmd(id,"say /hook")
                case 7: client_cmd(id, "say temp")
                case 8: log_amx("%s %s was morphed for camping longer than %i seconds", name, Authid, maxarktime)
                case 9: give_item(id, "weapon_pipewrench")
                case 10: give_item(id, "weapon_penguin")
                case 11: give_item(id, "weapon_knife")
                case 12: give_item(id, "item_longjump")
                case 13: give_item(id, "weapon_shockrifle")
                case 14: give_item(id, "weapon_hornetgun")
                case 16: give_item(id, "weapon_sporelauncher")
                case 17: give_item(id, "weapon_eagle")
                case 18: give_item(id, "weapon_shotgun")
                case 19: give_item(id, "weapon_m249")
                case 20: give_item(id, "weapon_grapple")
                case 21: give_item(id, "weapon_eagle")
                case 22: give_item(id, "weapon_sniperrifle")
                case 23: give_item(id, "weapon_displacer")
                case 24: server_cmd("say %s is a camper!", name)
            }
            #endif
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////makes a sign around campers head///////////////////////////////////////////////////////////////
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0 }, id )
            write_byte(TE_PLAYERSPRITES)
            write_short(id)  //(playernum)
            write_short(g_Money)  //(sprite modelindex)
            write_byte(7)     //(count)
            write_byte(75) // (variance) (0 = no variance in size) (10 = 10% variance in size)
            message_end()
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0 }, 0)
            write_byte(19)  //(TE_BEAMTORUS)
            write_coord(floatround(bOrigin[0]+random_num(-11,11)));  //pos x
            write_coord(floatround(bOrigin[1]-random_num(-11,11)));
            write_coord(floatround(bOrigin[2]+random_num(-11,11)));  //pos z
            write_coord(floatround(bOrigin[0]/random_num(-11,11)));
            write_coord(floatround(bOrigin[1]*random_num(-11,11)));
            write_coord(floatround(bOrigin[2]+random_num(-11,11))); //axis z
            write_short(g_Funny)     //(sprite index)
            write_byte(random_num(3,450));    //(starting frame)
            write_byte(random_num(2,500));   //(frame rate in 0.1's)
            write_byte(random_num(30,1000));   //(life in 0.1's)
            write_byte(random_num(50,800));    //(line width in 0.1's)
            write_byte(random_num(40,3000))   //(noise amplitude in 0.01's)
            write_byte(random_num(0,255))     //(red)
            write_byte(random_num(0,255))   //(green)
            write_byte(random_num(0,255))   //(blue)
            write_byte(random_num(100,2000))  //(brightness)
            write_byte(random_num(2,200))      //(scroll speed in 0.1's)
            message_end()
            /*
            *
            *   makes ent populate from this in middle of map. made notes to make to make it of id not 0,0,0 of map itself
            *
            */
            #if defined(MODEL)
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0 }, 0)
            write_byte(TE_MODEL)
            write_coord(floatround(sOrigin[0]/150))                      // XYZ (start)
            write_coord(floatround(sOrigin[1]*3))  //was flat no pluses anything  100 75 300
            write_coord(floatround(sOrigin[2]*15))
            write_coord(random_num(1,300))  //xyz velocity 50 20 10 100  then  2000 500 100  //20 50 10 is tame
            write_coord(random_num(1,500))
            write_coord(random_num(1,300))
            write_angle(random_num(2,200)) //100                      //(initial yaw)
                                         //(model index)
            switch(random_num(0,3))
            {
                case 0: write_short(g_Sunny)
                case 1: write_short(g_Spec)
                case 2: write_short(g_Spec2)
                case 3: write_short(g_Spec3)
            }
            write_byte(random_num(1,2))  //0                     //(bounce sound type)  1 is shell casing 2 is shotgun shell
            write_byte(random_num(25,65)) //(life in 0.1's)
            message_end()
        
            #endif
        }
    }
}

public client_connect(id) {
    g_arktime[id] = 0
    return PLUGIN_HANDLED
}

public client_putinserver(id) {
    g_arktime[id] = 0
    return PLUGIN_HANDLED
}

public playerSpawned(id) {
    g_spawned[id] = false
    new sid[1]
    sid[0] = id
    set_task(2.0, "delayedSpawn",_, sid, 1) // Give the player time to drop to the floor when spawning
    return PLUGIN_HANDLED
}

public delayedSpawn(sid[]) {
    get_user_origin(sid[0], g_oldangles[sid[0]])
    g_spawned[sid[0]] = true
    return PLUGIN_HANDLED
}
