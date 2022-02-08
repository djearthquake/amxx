
#define CSTRIKE /*uncomment for continued cstrike buy system.*/
///comment or uncomment to switch between cstrike or non-cstrike mods
//#define TEST //missile menu shoots non-lethal
/**
*    AMXX MISSILES. Missile menu launcher for GoldSrc.
*
*    Copyleft (C) Oct 2020 .sρiηX҉.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*
*    10/24/2020 SPiNX https://forums.alliedmods.net/member.php?u=245430
*    Change log 3.8.4 to 3.8.5
*    -Parachuter coding to mods outside of Counter-strike. Many bug and feat fixes.
*    -Heat seeker custom signatures like 1984 movie Runaway. Can add name tag.
*    -Bot heat seekers default.
*
*    03/12/21 SPiNX
*    Change log 3.8.5 3.8.6
*    -Cleaned up the scoreboard. The frags were not showing up in 'real time'.
*
*
****************************************************************************
*
*  Add missiles to GoldSrc game engine. Fire a variety of types of missiles
*  including laser guided missiles, heat seeking missiles, and missiles with
*  guncam on so you see what the missile sees and control it thusly. Missiles
*  can either be bought or given free to clients and there are several options
*  for this. In game menus and help pages are included. Note: Heatseeking
*  missiles are upgraded as of October 27th 2020 so client can type
*  setinfo heat "client name or part of their name"
*  to make seekers like the American 1984 movie Runaway and go off parts of name or tags.
*  To make it exactly like the movie it can be done with my plugin clientemp. No need as setifo is better.0
*  In addition, missiles can be shot down
*  with common guns or with the laser from my "CS Laser Guns and Laser Stats"
*  plugin. If you successfully shoot down a missile with a laser, you get a
*  prize of free missiles for the remainder of the round plus extra missiles
*  for the next round.
*
*  TODO: make think for all bots.
*
*  PODBOT: If using my podbots controller, podbots use this plugin too.
*  *NOTE* PODBot code is untested in the current version,
*   the podbot controller plugin needs to be updated to AMXx first.
*
*  Admin Commands:
*
*    amx_missiles             - toggles on and off missiles enabled
*    amx_missilesbuying       - toggles on/off missile buy requirements
*
*    amx_missiles_ammo1       - # of common missiles given per round
*    amx_missiles_ammo2       - # of laserguide missiles given per round
*    amx_missiles_ammo3       - # of guncam missiles given per round
*    amx_missiles_ammo4       - # of anti-missile shots given per round
*    amx_missiles_ammo5       - # of heat-seeking missiles given per round
*    amx_missiles_ammo6       - # of Parachute-seeking missiles given per round
*    amx_missiles_ammo7       --# of swirling death missiles given per round
*
*
*    amx_missile1 [speed] [chicken:0|1|2] [deadly:0|1] - common missile
*    amx_missile2 [speed] [chicken:0|1|2] [deadly:0|1] - laser guided missile
*    amx_missile3 [speed] [chicken:0|1|2] [deadly:0|1] - gun camera missile
*    amx_missile5 [speed] [chicken:0|1|2] [deadly:0|1] - heat-seeking missile
*    amx_missile6 [speed] [chicken:0|1|2] [deadly:0|1] - Parachute-seeking missile
*    amx_missile7 [speed] [chicken:0|1|2] [deadly:0|1] - swirling death missile
*
*   Examples:
*
*    amx_missile2 2000 0 0   - fires fast non-lethal laserguided missile
*    amx_missile5 500 1 1    - fires slow lethal jetpack seeking chicken
*
*  Client Commands:
*
*    amx_missile                - fires common missile
*    amx_laserguided_missile    - fires missile seeking red dot in aim
*    amx_guncamera_missile      - fires missile you control in camera veiw
*    amx_anti_missile           - activates antimissile system, aim at missile you want
*                                    to destroy, if it sees the missile in your aim,
*                                    it automatically launches a missile interceptor at it
*    amx_heatseeking_missile    - seeks nearest running jetpack
*    amx_Parachuteseeking_missile    - seeks nearest ninja-Parachute (lud/jtp10181's only)
*    amx_swirlingdeath_missile  - a central missile with ring of 6 (default) missiles rotating
*                                    around it. When missiles run out of fuel, they break
*                                    formation and cause massive destruction.
*
*    amx_sdmf <fuel>            - client uses this to set amount of time swirling death missile
*                                    flies until it runs out of fuel. Only works if cvar
*                                    amx_missile_allow_sdmf is 1. Default: 0
*    missile_menu               - opens the client missile menu
*    say /missile               - opens the client missile menu
*    say /missile_help          - show window with info about missles
*
*  CVARs: Paste the following into your amxx.cfg to change defaults.
*       You must uncomment cvar lines for them to take effect
*
****************************************************************************
*  CVAR CONFIG BEGIN
****************************************************************************

// ******************  Missile Settings  ******************

//1 to enable missiles, 0 to disable
//amx_luds_missiles 1

//Set to 1 to require missiles to be purchased
//amx_missile_buy 0

//
//The following "COST" settings only apply if buying mode is ON
//
//Ammount of money taken each time you fire a common missile
//amx_missile_cost1 1000

//Ammount of money taken each time you fire a laser guided missile
//amx_missile_cost2 3000

//Ammount of money taken each time you fire a gun camera missile
//amx_missile_cost3 3000

//Ammount of money taken each time you fire an anti-missile shot
//amx_missile_cost4 2000

//Ammount of money taken each time you fire a heat seeking missile
//amx_missile_cost5 4000

//Ammount of money taken each time you fire a Parachute seeking missile
//amx_missile_cost6 4000

//Ammount of money taken each time you fire a swirling death missile
//amx_missile_cost7 5000

//
//The following "AMMO" settings only apply if buying mode is OFF
//
//Ammount of common missiles given per round free to clients
//amx_missile_ammo1 1

//Ammount of laser guided missiles given per round free to clients
//amx_missile_ammo2 1

//Ammount of gun camera missiles given per round free to clients
//amx_missile_ammo3 1

//Ammount of anti-missile shots given per round free to clients
//amx_missile_ammo4 2

//Ammount of heat seeking missiles given per round free to clients
//amx_missile_ammo5 1

//Ammount of Parachute seeing missiles given per round free to clients
//amx_missile_ammo6 1

//Ammount of swirling death missiles given per round free to clients
//amx_missile_ammo7 1

//If set to 1, this cvar causes swirling death missile to use 7 missiles in the
//player's missile inventory. It draws from all types of missiles instead of
//it having its own indepedent inventory count.
//amx_missile_ammo7ta 0

//Sets the default speed of most missiles
//amx_missile_speed 1000

//Sets the speed of Parachuteseeking missiles
//amx_missile_rsspeed 1400

//Sets the speed of heatseeking missiles
//amx_missile_hsspeed 1100

//Number of seconds a missile is driven before it falls to the ground out of fuel
//amx_missile_fuel 6.0

//Number of seconds a swirling death missile is driven before
//it "mirvs" or breaks then falls to the ground out of fuel
//amx_missile_sdfuel 2.0

//Sets the speed of swirling death missiles
//amx_missile_sdspeed 750

//Sets the number missiles in swirling death
//amx_missile_sdcount 6

//Sets the rotation speed of swirling death
//amx_missile_sdrotate 6

//Sets the radius of swirling death missiles
//amx_missile_sdradius 32

//sets whether clients are allowed to set thier own fuel amounts
//for swirling death missile. Default 0. Enable with 1
//amx_missile_allow_sdmf 0

//makes missile obey server gravity rules, set to 0 for missiles
//that travel straight because they are not affected by gravity
//amx_missile_obeygravity 1

//Makes missile obey server friendly fire rules.
//amx_missile_obeyffcvar 1

//Max distance from the blast that damage will occur at
//amx_missile_damradius 240

//Maximum Blast damage from explsion this damage accours when distance
//is zero and decreases as the distance fomr the blast increases
//amx_missile_maxdamage 140

//For friendlyfire on, the option to punish team killer.
//Quota is from the cvar amx_missile_tkpunsish2. options:
//  0 = no action on team killer
//  1 = kick tker on tk quota
//  2 = 3 hour ban tker on quota
//  3 = always kill tker, kick on quota
//  4 = always kill tker, ban on quota
//amx_missile_tkpunish1 1

//For friendlyfire on, quantity of teammates a player can kill before a kick or ban can
//result depending on the above cvar amx_missile_tkpunish1 is set
//amx_missile_tkpunish2 3

//If in the rare event a player shoots down a missile belonging to an
//opposing player, he gets a prize, free missiles. Cvar sets
//how many of each type of missile are given
//amx_missile_prizes 5

//Sets the amount of time a player can use his anti-missile radar per round.
//amx_missile_radarbattery 100

//Since bots are stupid and waste their missiles, we give them a handicap with this
//cvar set to 1 so that bots get an unlimited quantity of missiles
//amx_missile_botsnolimit 1

//This cvar limits the two types of missiles responsible for spawn rape, guncamera and
//swirling death, from being fired until 15 seconds of a round has passed. Set cvar to 0
//to allow those missiles to be fired without being limited by round start
//amx_missile_spawndelay 0

****************************************************************************
*  CVAR CONFIG END
****************************************************************************
*
*  Additional info:
*
*  This plugin logs missile kills in the standard HL format so that stats
*  parsing programs like psychostats will record missile kills.
*
*  Big huge thanks to SpaceDude for the swirling death missile's math. He
*  basically made swirling death, sent it to me, and I put it in here.
*
*
*                 ******** Engine Module REQUIRED ********
*                   ******** FUN Module REQUIRED ********
*
*  Changelog:
*
*  v3.8.4 - JTP10181 - 02/11/06
*   - Fixed runtime error in anti-missile code when server has 32 players
*   - Fixed runtime in make_rocket if user had died or disconnected
*
*  v3.8.3 - JTP10181 - 01/11/05
*   - Made entity checking better to avoid runtime errors
*
*  v3.8.2 - JTP10181 - 10/02/04
*   - Fixed bug, menu key not being registered correctly
*   - Fixed bug, wrong cost cvar being used in heat seeking check
*
*  v3.8.1 - JTP10181 - 09/28/04
*   - Now works on AMXModX 0.20
*
*  v3.8 - JTP10181 - 07/23/04
*   - Converted MOTD boxes to work with steam and possibly with WON still
*   - Fixed all authid variables to be 34 chars so STEAMIDs are handled pParachuterly
*   - Changed wc3 specific code to use the engine module for AMXx
*   - Added code so the missile buying can only be enabled for CS
*       since the money functions are only for CS in AMXx
*   - Fixed logging to admin log for AMXx
*   - Working on non-CS support that broke with AMXx, must be a #define compile option now.
*   - Removed all DoD support as it needs ot be a totally separate plugin.
*   - Made it update the scores right away instead of waiting till next round
*   - Changed all printed messages to use the [AMXX] tag instead of [AMX]
*   - Changed death message blocking to BLOCK_ONCE for better compatibility
*   - Removed "redundant plugin" code as it was made useless by BLOCK_ONCE change
*   - Gave all missiles different colored trails (common is still white)
*   - Changed the damage system to be much more versatile.
*   - Rearranged the order of the missiles in the menu and for the command numbers
*   - Commented out bot code for now because I don't want to
*       deal with it and the interface plugin is not ported yet
*   - MANY other tweaks and fixes, too many to list.
*
*  Below v3.8 was maintained by Eric Lidman
*
**************************************************************************/

#include <amxmodx>
#include <amxmisc>

#if defined CSTRIKE
    #include <cstrike>
#endif

#include <engine>
#include <fakemeta_util>

#include <fun>
#include <hamsandwich>


//Set this to the admin level at which
//they are allowed to fire multiple missiles at once
#define ADMIN_MULTISHOT ADMIN_LEVEL_D

//Set this to the admin level at which they can fire missiles
#define ADMIN_MISSILES ADMIN_LEVEL_B

//Set this to the admin level at which they can change missile settings
#define ADMIN_MISSILE_SET ADMIN_LEVEL_H

/***********************************************************************************
*                                                                                  *
*  *END* customizable section of code. other changes can be done with the cvars    *
*                                                                                  *
************************************************************************************/
#define MAX_PLAYERS                32

#define MAX_RESOURCE_PATH_LENGTH   64

#define MAX_MENU_LENGTH            512

#define MAX_NAME_LENGTH            32

#define MAX_AUTHID_LENGTH          64

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define MAX_MOTD_LENGTH            1536

#define charsmin                  -1

#define DT 0.1
#define PI 3.1415926535897932384626433832795
#define client_disconnect client_disconnected
#define WITHOUT_PORT                   1
#define charsmin                      -1

#if !defined MAX_PLAYERS
const MAX_PLAYERS                =    32
const MAX_AUTHID_LENGTH          =    64
const MAX_IP_LENGTH              =    16
const MAX_USER_INFO_LENGTH       =    256
const MAX_MENU_LENGTH            =    512
const MAX_NAME_LENGTH            =    32
const MAX_MOTD_LENGTH            =    1536
const MAX_RESOURCE_PATH_LENGTH   =    64
#endif

new beam, boom, ls_dot;
new Float:fAngle;
new bool:roundfreeze
new round_delay;
new has_rocket[ MAX_PLAYERS + 1 ];
//new is_parachuting[ MAX_PLAYERS + 1 ];

/* missile_inv:  fake,common,laserguide,guncam,antimissile,heatseeker,Parachuteseeking,multimissile */
new missile_inv[ MAX_PLAYERS + 1 ][8];
new missile_win[ MAX_PLAYERS + 1 ];
new using_menu[ MAX_PLAYERS + 1 ];
new is_scan_rocket[ MAX_PLAYERS + 1 ];
new is_heat_rocket[ MAX_PLAYERS + 1 ];
new radar_batt[ MAX_PLAYERS + 1 ];
new tkcount[ MAX_PLAYERS + 1 ];
new Float:user_sdmf[ MAX_PLAYERS + 1 ];
new hookgrabtask[ MAX_PLAYERS + 1 ];
new cmd_onParachute[ MAX_PLAYERS + 1 ];
new gmsgDeathMsg, gmsgScoreInfo, g_costcvar, g_heatseeker_tag, g_heatseeker_bot, g_heatseeker_user, g_logdetail;


public plugin_init(){
    register_plugin("Missiles Launcher","3.8.6","SPINX") //Original by EJL. AMXX PORT JTP10181. HL/OP4 PORT SPiNX.

    register_concmd("amx_missiles","admin_missiles",ADMIN_MISSILE_SET,"- Toggles Missiles Mode ON and OFF")
    register_concmd("amx_missilesbuying","admin_missilebuy",ADMIN_MISSILE_SET,"- Toggles Missile Buy Requirement mode ON and OFF")
    register_concmd("amx_missiles_ammo1","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Common Missiles free each round if missile buying is off")
    register_concmd("amx_missiles_ammo2","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Laser Guided Missiles free each round if missile buying is off")
    register_concmd("amx_missiles_ammo3","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Gun Cam Missiles free each round if missile buying is off")
    register_concmd("amx_missiles_ammo4","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Anti-Missile Shots free each round if missile buying is off")
    register_concmd("amx_missiles_ammo5","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Heat-Seeking Missiles given per round free if missile buying is off")
    register_concmd("amx_missiles_ammo6","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Parachute-Seeking Missiles free each round if missile buying is off")
    register_concmd("amx_missiles_ammo7","admin_missile_ammo",ADMIN_MISSILE_SET,"<quantity> - Swirling Death Missiles free each round if missile buying is off")
    register_concmd("amx_missile1","admin_missile",ADMIN_MISSILES,"[speed] [chicken:0|1|2] [deadly:0|1] - Common Missile")
    register_concmd("amx_missile2","admin_missile",ADMIN_MISSILES,"[speed] [chicken:0|1|2] [deadly:0|1] - Laser Guided Missile")
    register_concmd("amx_missile3","admin_missile",ADMIN_MISSILES,"[speed] [chicken:0|1|2] [deadly:0|1] - Gun Cam Missile")
    register_concmd("amx_missile5","admin_missile",ADMIN_MISSILES,"[speed] [chicken:0|1|2] [deadly:0|1] - Heat-Seeking Missile")
    register_concmd("amx_missile6","admin_missile",ADMIN_MISSILES,"[speed] [chicken:0|1|2] [deadly:0|1] - Parachute-Seeking Missile")
    register_concmd("amx_missile7","admin_missile",ADMIN_MISSILES,"[speed] [chicken:0|1|2] [deadly:0|1] - Swrirling Death Missile")

    register_clcmd("amx_missile","fire_missile")
    register_clcmd("amx_laserguided_missile","fire_missile")
    register_clcmd("amx_guncamera_missile","fire_missile")
    register_clcmd("amx_anti_missile","fire_missile")
    register_clcmd("amx_heatseeking_missile","fire_missile")
    register_clcmd("amx_Parachuteseeking_missile","fire_missile")
    register_clcmd("amx_swirlingdeath_missile","fire_missile")

    register_clcmd("amx_sdmf","player_sdmf",0,"<fuel ammount in 10ths/second>")
    register_clcmd("say", "HandleSay")
    register_clcmd("say /missile_help","rocket_motd")
    register_clcmd("say /missile","show_main_menu")
    register_clcmd("missile_menu", "show_main_menu",0,"- Brings up the missile selection menu")
    register_menucmd(register_menuid("Fire Missile Menu"),1023,"action_main_menu")
    register_srvcmd("lasermissile_chk","ls_missile_ck")
    register_srvcmd("jetpackmissile_chk","jp_missile_ck")
    register_srvcmd("Parachutemissile_chk","rp_missile_ck")

    register_srvcmd("bot_missile","bot_interface")
    //make bot think instead of other plugin

    register_cvar("amx_luds_missiles","1",FCVAR_SERVER)
    register_cvar("amx_missile_buy","0")
    register_cvar("amx_missile_fuel","6.0")
    register_cvar("amx_missile_sdfuel","2.0")
    register_cvar("amx_missile_sdcount","6")
    register_cvar("amx_missile_sdrotate","6")
    register_cvar("amx_missile_sdradius","32")
    register_cvar("amx_missile_allow_sdmf","0")
    register_cvar("amx_missile_ammo1","2")
    register_cvar("amx_missile_ammo2","2")
    register_cvar("amx_missile_ammo3","1")
    register_cvar("amx_missile_ammo4","1")
    register_cvar("amx_missile_ammo5","1")
    register_cvar("amx_missile_ammo6","1")
    register_cvar("amx_missile_ammo7","1")
    register_cvar("amx_missile_ammo7ta","0")
    register_cvar("amx_missile_cost1","1000")
    register_cvar("amx_missile_cost2","3000")
    register_cvar("amx_missile_cost3","3000")
    register_cvar("amx_missile_cost4","2000")
    register_cvar("amx_missile_cost5","4000")
    register_cvar("amx_missile_cost6","4000")
    register_cvar("amx_missile_cost7","5000")
    register_cvar("amx_missile_speed","1000")
    register_cvar("amx_missile_sdspeed","750")
    register_cvar("amx_missile_hsspeed","1200")
    register_cvar("amx_missile_rsspeed","1200")
    register_cvar("amx_missile_obeygravity","1")
    register_cvar("amx_missile_damradius","240")
    register_cvar("amx_missile_maxdamage","140")
    register_cvar("amx_missile_obeyffcvar","1")
    register_cvar("amx_missile_tkpunish1","1")
    register_cvar("amx_missile_tkpunish2","3")
    register_cvar("amx_missile_prizes","5")
    register_cvar("amx_missile_radarbattery","100")
    register_cvar("amx_missile_botsnolimit","1")
    register_cvar("amx_missile_spawndelay","0")

    //SPiNX2020 down

    g_logdetail       = register_cvar("mp_logdetail", "3")

    g_costcvar        = register_cvar("amx_missile_cost", "1000")
    g_heatseeker_tag  = register_cvar("heatseeker_nametag", "bteam") //made into exclude to cover wider range
    g_heatseeker_bot  = register_cvar("heatseeker_bot", "0")

    g_heatseeker_user = register_cvar("heatseeker_runaway", "1")

    register_event("DeathMsg","death_event","a")

    if(cstrike_running())

        {
            register_logevent("round_start", 2, "1=Round_Start")
            register_logevent("round_end", 2, "1=Round_End")
        }

    else

    RegisterHam(Ham_Spawn, "player", "round_start", 1);

    set_task(0.1,"RocketThink",30500,"",0,"b")

    gmsgDeathMsg = get_user_msgid("DeathMsg")
    gmsgScoreInfo = get_user_msgid("ScoreInfo")

}

public plugin_precache() {

    precache_sound("vox/_period.wav")
    precache_sound("debris/beamstart8.wav")
    precache_sound("weapons/explode3.wav")
    precache_sound("weapons/rocketfire1.wav")
    precache_sound("ambience/rocket_steam1.wav")
    precache_sound("weapons/rocket1.wav")
    precache_sound("ambience/particle_suck2.wav")
    precache_sound("misc/arnold_heatseeker.wav")
    precache_model("models/rpgrocket.mdl")
    precache_model("models/hvr.mdl")

    if(cstrike_running())
    precache_model("models/chick.mdl")

    beam = precache_model("sprites/smoke.spr")
    boom = precache_model("sprites/zerogxplode.spr")
    ls_dot = precache_model("sprites/laserdot.spr")
}

public client_connect(id) {
    is_scan_rocket[id] = 0
    is_heat_rocket[id] = 0
    using_menu[id] = 0
    has_rocket[id] = 0
    missile_win[id] = 0

    if(get_cvar_num("amx_missile_buy") == 0){
        missile_inv[id][1] = get_cvar_num("amx_missile_ammo1")
        missile_inv[id][2] = get_cvar_num("amx_missile_ammo2")
        missile_inv[id][3] = get_cvar_num("amx_missile_ammo3")
        missile_inv[id][4] = get_cvar_num("amx_missile_ammo4")
        missile_inv[id][5] = get_cvar_num("amx_missile_ammo5")
        missile_inv[id][6] = get_cvar_num("amx_missile_ammo6")
        missile_inv[id][7] = get_cvar_num("amx_missile_ammo7")
    }
    radar_batt[id] = get_cvar_num("amx_missile_radarbattery")
    tkcount[id] = 0
    user_sdmf[id] = 0.0
    hookgrabtask[id] = 0
    cmd_onParachute[id] = 0
}

public client_disconnect(id){
    remove_task(35632+id)
    is_scan_rocket[id] = 0
    is_heat_rocket[id] = 0
    has_rocket[id] = 0
    tkcount[id] = 0
    user_sdmf[id] = 0.0
    hookgrabtask[id] = 0
    cmd_onParachute[id] = 0
}

public admin_missiles(id,level,cid){
    if (!cmd_access(id,level,cid,1)) return

    new authid[ MAX_AUTHID_LENGTH ],name[ MAX_NAME_LENGTH ]
    get_user_authid(id,authid,charsmax(authid))
    get_user_name(id,name,charsmax(name))

    if(get_cvar_num("amx_luds_missiles") == 0){
        set_cvar_num("amx_luds_missiles",1)
        client_print(0,print_chat,"[AMXX] Admin has enabled missiles")
        console_print(id,"[AMXX] You have enabled missiles")
        log_amx("^"%s<%d><%s><>^" enabled missiles",name,get_user_userid(id),authid)
    }else {
        set_cvar_num("amx_luds_missiles",0)
        client_print(0,print_chat,"[AMXX] Admin has disabled missiles")
        console_print(id,"[AMXX] You have disabled missiles")
        log_amx("^"%s<%d><%s><>^" disabled missiles",name,get_user_userid(id),authid)
    }
}

public admin_missilebuy(id,level,cid) {
    if (!cmd_access(id,level,cid,1)) return

    new authid[ MAX_AUTHID_LENGTH ],name[ MAX_NAME_LENGTH ]
    get_user_authid(id,authid,charsmax(authid))
    get_user_name(id,name,charsmax(name))

    if(get_cvar_num("amx_missile_buy") == 0){
        set_cvar_num("amx_missile_buy",1)
        client_print(0,print_chat,"[AMXX] Missile shots must be paid for now")
        console_print(id,"[AMXX] You have required players pay for missiles")
        log_amx("^"%s<%d><%s><>^" enabled missiles buying",name,get_user_userid(id),authid)
    }else {
        set_cvar_num("amx_missile_buy",0)
        client_print(0,print_chat,"[AMXX] Missile shots are now FREE")
        console_print(id,"[AMXX] You have made missiles free")
        log_amx("^"%s<%d><%s><>^" disabled missiles buying",name,get_user_userid(id),authid)
    }
}

public admin_missile_ammo(id,level,cid){
    if (!cmd_access(id,level,cid,1)) return

    if(get_cvar_num("amx_missile_buy")){
        console_print(id,"[AMXX] For this command to have effect, disable missile buying first: amx_missilesbuying")
        return
    }

    new cmd[ MAX_PLAYERS ],arg[10]
    read_argv(0,cmd,charsmax(cmd))
    read_argv(1,arg,charsmax(arg))
    new quantity = str_to_num(arg)

    if(equal(cmd[17],"1",1)){
        set_cvar_num("amx_missile_ammo1",quantity)
        console_print(id,"[AMXX] Effective next round, free Guncam Missiles is %d",quantity)
    }
    else if(equal(cmd[17],"2",1)){
        set_cvar_num("amx_missile_ammo2",quantity)
        console_print(id,"[AMXX] Effective next round, free Laser Guided Missiles is %d",quantity)
    }
    else if(equal(cmd[17],"3",1)){
        set_cvar_num("amx_missile_ammo3",quantity)
        console_print(id,"[AMXX] Effective next round, free Heat-Seeking Missiles is %d",quantity)
    }
    else if(equal(cmd[17],"4",1)){
        set_cvar_num("amx_missile_ammo4",quantity)
        console_print(id,"[AMXX] Effective next round, free Common Missiles is %d",quantity)
    }
    else if(equal(cmd[17],"5",1)){
        set_cvar_num("amx_missile_ammo5",quantity)
        console_print(id,"[AMXX] Effective next round, free Anti-Missiles is %d",quantity)
    }
    else if(equal(cmd[17],"6",1)){
        set_cvar_num("amx_missile_ammo6",quantity)
        console_print(id,"[AMXX] Effective next round, free Parachute-Seeking Missiles is %d",quantity)
    }
    else if(equal(cmd[17],"7",1)){
        set_cvar_num("amx_missile_ammo7",quantity)
        console_print(id,"[AMXX] Effective next round, free Swirling Death Missiles is %d",quantity)
    }
    new authid[ MAX_AUTHID_LENGTH ],name[ MAX_NAME_LENGTH ]
    get_user_authid(id,authid,charsmax(authid))
    get_user_name(id,name,charsmax(name))
    log_amx("^"%s<%d><%s><>^" set %s to %d",name,get_user_userid(id),authid,cmd,quantity)
}

public vexd_pfntouch(pToucher, pTouched) {

    //if ( !is_valid_ent(pToucher) ) return

    //if ( !is_user_connected(pTouched) ) return
    //nice travel but undev it stays put. at best it wraps around buildings etc. Good for more advanced bot or team seeking later
    //wish I could use it midway of shot. Wrap around at desireable time instead of fall in lap.

    new szClassName[ MAX_NAME_LENGTH ]
    if(is_valid_ent(pToucher))
    entity_get_string(pToucher, EV_SZ_classname, szClassName, charsmax(szClassName))

    if(equal(szClassName, "func_rocket")) {
        new damradius = get_cvar_num("amx_missile_damradius")
        new maxdamage = get_cvar_num("amx_missile_maxdamage")

        if (damradius <= 0) {
            log_amx("Damage Radius must be set higher than 0, defaulting to 240")
            damradius = 240
            set_cvar_num("amx_missile_damradius",damradius)
        }
        if (maxdamage <= 0) {
            log_amx("Max Damage must be set higher than 0, defaulting to 140")
            maxdamage = 140
            set_cvar_num("amx_missile_maxdamage",maxdamage)
        }

        remove_task(2020+pToucher)
        new tk = 0
        new Float:fl_vExplodeAt[3]
        entity_get_vector(pToucher, EV_VEC_origin, fl_vExplodeAt)
        new vExplodeAt[3]
        vExplodeAt[0] = floatround(fl_vExplodeAt[0])
        vExplodeAt[1] = floatround(fl_vExplodeAt[1])
        vExplodeAt[2] = floatround(fl_vExplodeAt[2])
        new id = entity_get_edict(pToucher, EV_ENT_owner)
        new unarmed = missile_inv[id][0]
        new origin[3],dist,i,Float:dRatio,damage
        if(is_user_connected(id))attach_view(id, id)
        if(has_rocket[id] == pToucher)
        has_rocket[id] = 0

        for ( i = 1; i < 32; i++) {

            if((is_user_alive(i)) && (i != id)){
                get_user_origin(i,origin)
                dist = get_distance(origin,vExplodeAt)
                if (dist <= damradius) {

                    dRatio = floatdiv(float(dist),float(damradius))
                    damage = maxdamage - floatround( maxdamage * dRatio)

                    if ( !is_user_connected(pTouched) ) //continue //will make not moving bypass etc moton detect.
                        entity_set_int(pToucher/*rocket*/, EV_INT_movetype, MOVETYPE_BOUNCEMISSILE)
                    else
                        entity_set_int(pToucher/*rocket*/, EV_INT_movetype, MOVETYPE_FLY)
                    if(cvar_exists("mp_friendlyfire"))
                    {
                        if( get_cvar_num("mp_friendlyfire") && get_cvar_num("amx_missile_obeyffcvar") )
                        {
                            if(get_user_team(i) == get_user_team(id))
                                tk = 1 && do_victim(i,id,damage,unarmed,tk);
                        }
                        if(get_user_team(i) != get_user_team(id))
                            do_victim(i,id,damage,unarmed,0)
                    }


                    if (!cstrike_running())
                            do_victim(i,id,damage,unarmed,0)

                            else

                            do_victim(i,id,damage,unarmed,0)
                }
            }
        }

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(3)
        write_coord(vExplodeAt[0])
        write_coord(vExplodeAt[1])
        write_coord(vExplodeAt[2])
        write_short(boom)
        write_byte(100)
        write_byte(15)
        write_byte(0)
        message_end()

        emit_sound(pToucher, CHAN_WEAPON, "weapons/explode3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        emit_sound(pToucher, CHAN_VOICE, "weapons/explode3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

        remove_entity(pToucher)
        is_heat_rocket[id] = 0
        is_scan_rocket[id] = 0

        if ( is_valid_ent(pTouched) ) {
            new szClassName2[ MAX_PLAYERS ]
            if(is_valid_ent(pTouched))
            entity_get_string(pTouched, EV_SZ_classname, szClassName2, charsmax(szClassName2))

            if(equal(szClassName2, "func_rocket")) {
                remove_task(2020+pTouched)
                emit_sound(pTouched, CHAN_WEAPON, "weapons/explode3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                emit_sound(pTouched, CHAN_VOICE, "weapons/explode3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                new id2 = entity_get_edict(pTouched, EV_ENT_owner)
                if(is_user_connected(id))attach_view(id2, id2)
                if(has_rocket[id2] == pTouched){
                    has_rocket[id2] = 0
                    is_heat_rocket[id2] = 0
                    is_scan_rocket[id2] = 0
                }
                remove_entity(pTouched)
            }
        }
    }
}


do_victim(victim,attacker,damage,unarmed,tk){
    new namek[ MAX_NAME_LENGTH ],namev[ MAX_NAME_LENGTH ],authida[ MAX_AUTHID_LENGTH ],authidv[ MAX_AUTHID_LENGTH ],teama[ 4 ],teamv[ 4 ]
    get_user_name(victim,namev,charsmax (namev))
    get_user_name(attacker,namek,charsmax (namek))
    get_user_authid(victim,authidv,charsmax (authidv))
    get_user_authid(attacker,authida,charsmax (authida))
    get_user_team(victim,teamv,charsmax (teamv))
    get_user_team(attacker,teama,charsmax (teama))

#if defined TEST
    if(unarmed == 0)
    {
        if(damage >= get_user_health(victim))
            client_print(attacker,print_chat,"[AMXX] NON-LETHAL TEST MODE:  You would have killed %s with that missile",namev)
        else
            client_print(attacker,print_chat,"[AMXX] NON-LETHAL TEST MODE:  You would have hurt %s with that missile",namev)
    }
    else
    {
#endif
    if(damage >= get_user_health(victim))


        {


            if(is_heat_rocket[attacker] == 1)
                set_task(1.0,"delay_arnold")

            if(get_pcvar_num(g_logdetail) == 3){
                log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"missile^" (hit ^"chest^") (damage ^"%d^") (health ^"0^")",
                    namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv,damage)
            }

            if(unarmed == 2){
                log_amx("^"%s<%d><%s><%s>^" admin missile killed ^"%s<%d><%s><%s>^"",
                    namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv)

                client_print(attacker,print_chat,"[AMXX] You killed %s with that admin missile",namev)
                client_print(victim,print_chat,"[AMXX] You were killed by %s's admin missile",namek)
            }
            #if defined TEST
            //belongs as a death message not here as cstrike maybe others does a double print
            else {
                client_print(attacker,print_chat,"[AMXX] You killed %s with that missile",namev)
                client_print(victim,print_chat,"[AMXX] You were killed by %s's missile",namek)
            }
           #endif

            if(tk == 0) {
                set_user_frags(attacker,get_user_frags(attacker) + 1 )
            }
            else {
                tkcount[attacker] += 1
                client_print(attacker,print_center,"You killed a teammate")
                set_user_frags(attacker,get_user_frags(attacker) - 1 )
            }

                set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE);

            fakedamage(victim," Missile",500.0,DMG_MORTAR);


            replace_dm(attacker,victim,0);

            new killer;
            killer = attacker;
            pin_scoreboard(killer);

            log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"missile^"",
                namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv)

        }
        else {
            set_user_health(victim,get_user_health(victim) - damage )

            if(get_cvar_num("mp_logdetail") == 3) {
                log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"missile^" (hit ^"chest^") (damage ^"%d^") (health ^"%d^")",
                    namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv,damage,get_user_health(victim))
            }

            if(unarmed == 2) {
                log_amx("^"%s<%d><%s><%s>^" admin missile hurt ^"%s<%d><%s><%s>^"",
                    namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv)

                client_print(attacker,print_chat,"[AMXX] You hurt %s with that admin missile",namev)
                client_print(victim,print_chat,"[AMXX] You were hurt by %s's admin missile",namek)
            }
            else {
                client_print(attacker,print_chat,"[AMXX] You hurt %s with that missile",namev)
                client_print(victim,print_chat,"[AMXX] You were hurt by %s's missile",namek)
            }
        }

    if(tk)

        {
            new players[ MAX_PLAYERS ],pNum
            get_players(players,pNum,"e",teama)
            for(new i=0;i<pNum;i++)
                client_print(players[i],print_chat,"%s attacked a teammate",namek)

            new punish1 = get_cvar_num("amx_missile_tkpunish1")
            new punish2 = get_cvar_num("amx_missile_tkpunish2")

            if (!(get_user_flags(attacker)&ADMIN_IMMUNITY)){
                if(punish1 > 2){
                    user_kill(attacker,0)
                    set_hudmessage(255,50,50, -1.0, 0.45, 0, 0.02, 10.0, 1.01, 1.1, 4)
                    show_hudmessage(attacker,"YOU WERE KILLED FOR ATTACKING TEAMMATES.^nSEE THAT IT HAPPENS NO MORE!")
                }
                if((punish1) && (tkcount[attacker] >= punish2 )){
                    if(punish1 == 1 || punish1 == 3)
                        client_cmd(attacker,"echo You were kicked for team killing;disconnect")
                    else if(punish1 == 2 || punish1 == 4){
                        client_cmd(attacker,"echo You were banned for team killing")
                        if (equal("4294967295",authida)){
                            new ipa[ MAX_PLAYERS ]
                            get_user_ip(attacker,ipa,31,1)
                            server_cmd("addip 180.0 %s;writeip",ipa)
                        }else{
                            server_cmd("banid 180.0 %s kick;writeid",authida)
                        }
                    }
                }
            }
        }
#if defined DEBUG
    }
#endif
}

public delay_arnold(){
    client_cmd(0,"play misc/arnold_heatseeker.wav")
}

public delay_prizewin(){
    client_cmd(0,"play ambience/lv4.wav")
}

public player_sdmf(id,level,cid){
    if(get_cvar_num("amx_missile_allow_sdmf") == 0){
        console_print(id,"[AMXX] Players are not allowed to set thier own fuel for Swirling Death Missiles.")
        return
    }
    if (!cmd_access(id,level,cid,2)) return

    new arg[8]
    read_argv(1,arg,charsmax(arg))
    new iarg = str_to_num(arg)
    if(iarg < 1 || iarg > 1000){
        console_print(id,"[AMXX] Fuel ammount must be a number between 1 and 1000")
        return
    }
    user_sdmf[id] = float(iarg) / 10
    console_print(id,"[AMXX] Your swirling death missiles now run out of fuel after %.1f seconds",user_sdmf[id])
}

public admin_missile(id,level,cid) {
    if (!cmd_access(id,level,cid,1) || roundfreeze) return PLUGIN_HANDLED;

    if(!is_dedicated_server()) {
        if(!id) id = 1
    }

    if( (has_rocket[id]) && (!(get_user_flags(id)&ADMIN_MULTISHOT)) ) {
        client_print(id,print_chat,"[AMXX] You cannot have more than one missile in the air at a time.")
        return PLUGIN_HANDLED;
    }

    using_menu[id] = 0
    new arg1[10], arg2[10], arg3[10], cmd[ MAX_PLAYERS ],icmd
    read_argv(0,cmd, charsmax(cmd))
    read_argv(1,arg1,charsmax(arg1))
    read_argv(2,arg2,charsmax(arg2))
    read_argv(3,arg3,charsmax(arg3))

    new iarg1 = str_to_num(arg1)
    new iarg2 = str_to_num(arg2)
    new iarg3 = str_to_num(arg3)

    if(equal(cmd[11],"1",1)) {
        icmd = 1
    }
    else if(equal(cmd[11],"2",1)) {
        icmd = 2
    }
    else if(equal(cmd[11],"3",1)) {
        icmd = 3
    }
    else if(equal(cmd[11],"5",1)) {
        icmd = 5
    }
    else if(equal(cmd[11],"6",1)) {
        icmd = 6
    }
    else {
        icmd = 7
    }

    if(iarg1 < 1 || iarg1 > 10000){
        if(icmd == 5) {
            iarg1 = get_cvar_num("amx_missile_hsspeed")
        }
        else if(icmd == 6) {
            iarg1 = get_cvar_num("amx_missile_rsspeed")
        }
        else if(icmd == 7) {
            iarg1 = get_cvar_num("amx_missile_sdspeed")
        }
        else {
            iarg1 = get_cvar_num("amx_missile_speed")
        }
    }

    if(iarg2 == 1 && !cstrike_running()) {
        iarg2 = 0
    }
    else if(iarg2 > 2) {
        iarg2 = 0
    }
    make_rocket(id,icmd,iarg1,iarg2,iarg3,1,0)
    return PLUGIN_HANDLED;

}

//BOTS
public bot_interface(){
    if(get_cvar_num("amx_luds_missiles") == 0)
        return PLUGIN_HANDLED
    new sid[8],id
    read_argv(1,sid,charsmax(sid))
    id = str_to_num(sid)
    if(is_user_alive(id) == 0)
        return PLUGIN_HANDLED
    if(has_rocket[id])
        return PLUGIN_HANDLED
    new cmd[ MAX_PLAYERS ],icmd
    read_argv(2,cmd, charsmax(cmd))
    if(equal(cmd,"amx_guncamera_missile"))
        icmd = 1
    else if(equal(cmd,"amx_laserguided_missile"))
        icmd = 2
    else if(equal(cmd,"amx_heatseeking_missile"))
        icmd = 3
    else if(equal(cmd,"amx_missile"))
        icmd = 4
    else if(equal(cmd,"amx_Parachuteseeking_missile"))
        icmd = 6
    else if(equal(cmd,"amx_swirlingdeath_missile"))
        icmd = 7
    else
        icmd = 5
    if(icmd == 5){
        if(radar_batt[id] < 1)
            return PLUGIN_HANDLED
        if(is_scan_rocket[id] == 1) {
            remove_task(35632+id)
            is_scan_rocket[id] = 0
            missile_inv[id][icmd] += 1
            return PLUGIN_HANDLED
        }
    }

    if( (icmd == 1 || icmd == 7) && (round_delay == 1) && (get_cvar_num("amx_missile_spawndelay")) )
        return PLUGIN_HANDLED

    if(get_cvar_num("amx_missile_botsnolimit") == 0){
        #if defined CSTRIKE
        if(get_cvar_num("amx_missile_buy") == 1){
            new cvarname[ MAX_NAME_LENGTH ]
            format(cvarname,charsmax(cvarname),"amx_missile_cost%d",icmd)
            new umoney = cs_get_user_money(id)
            new m_cost = get_cvar_num(cvarname)
            if(umoney < m_cost)
                return PLUGIN_HANDLED
            else
                cs_set_user_money(id,umoney-m_cost,1)
        }
        else
        #endif
        {
            new pass
            if( (icmd == 7) && (get_cvar_num("amx_missile_ammo7ta") == 1) ){
                pass = 1
                new sum
                for(new i=1;i<8;i++)
                    sum += missile_inv[id][i]
                if(sum < 7)
                    return PLUGIN_HANDLED
                else{
                    new take
                    for(new b=1;b<8;b++){
                        if(take < 7){
                            for(new i=1;i<8;i++){
                                if( (missile_inv[id][i] > 0) && (take < 7) ){
                                    missile_inv[id][i] -= 1
                                    take +=1
                                }
                            }
                        }
                    }
                }
            }
            if( (!pass) && (missile_inv[id][icmd] < 1) )
                return PLUGIN_HANDLED
            else
                missile_inv[id][icmd] -= 1
        }
    }
    if(icmd != 5){
        switch(icmd){
            case 1: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,1,0,0)
            case 2: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,1,0,0)
            case 3: make_rocket(id,icmd,get_cvar_num("amx_missile_hsspeed"),0,1,0,0)
            case 4: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,1,0,0)
            case 6: make_rocket(id,icmd,get_cvar_num("amx_missile_rsspeed"),0,1,0,0)
            case 7: make_rocket(id,icmd,get_cvar_num("amx_missile_sdspeed"),0,1,0,0)
            default: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,1,0,0)
        }
    }else{
        is_scan_rocket[id] = 1
        new args[2]
        args[0] = id

        if(task_exists(35632+id))
            remove_task(35632+id);
        else
            set_task(0.2,"anti_missile_radar",35632+id,args,2,"b")

        set_task(0.3,"amr_pay",35632+id,args,2,"b")
    }
    return PLUGIN_CONTINUE
}


public fire_missile(id) {

    if (!is_dedicated_server()) {
        if(!id) id = 1
    }

    if(!get_cvar_num("amx_luds_missiles") || roundfreeze || !is_user_alive(id) && !is_user_bot(id))
        return PLUGIN_HANDLED

    show_missile_inv(id)
    if(has_rocket[id]){
        client_print(id,print_chat,"[AMXX] You cannot have more than one missile in the air at a time.")
        return PLUGIN_HANDLED
    }

    new cmd[ MAX_PLAYERS ],icmd
    read_argv(0,cmd, charsmax(cmd))

    if(equal(cmd,"amx_missile"))                        icmd = 1
    else if(equal(cmd,"amx_laserguided_missile"))       icmd = 2
    else if(equal(cmd,"amx_guncamera_missile"))         icmd = 3
    else if(equal(cmd,"amx_heatseeking_missile"))       icmd = 5
    else if(equal(cmd,"amx_Parachuteseeking_missile"))  icmd = 6
    else if(equal(cmd,"amx_swirlingdeath_missile"))     icmd = 7
    else                                                icmd = 4

    if(icmd == 4){
        if(radar_batt[id] <= 0){
            client_print(id,print_chat,"[AMXX] Your anti-missile radar batteries are dead.")
            return PLUGIN_CONTINUE
        }
        if(is_scan_rocket[id] == 1) {
            remove_task(35632+id)
            is_scan_rocket[id] = 0
            missile_inv[id][icmd] += 1
            set_hudmessage(0,255,0, -1.0, 0.30, 0, 0.02, 3.0, 1.01, 1.1, 4)
            show_hudmessage(id,"ANTIMISSILE RADAR DEACTIVATED")
            return PLUGIN_CONTINUE
        }
    }
    if( (icmd == 4 || icmd == 7) && (round_delay) && (get_cvar_num("amx_missile_spawndelay")) ){
        client_print(id,print_chat,"[AMXX] This missile type cannot be fired until 15 seconds after round start.")
        return PLUGIN_CONTINUE
    }
    if(get_cvar_num("amx_missile_buy") == 1) {
#if defined CSTRIKE
        new cvarname[ MAX_PLAYERS ]
        format(cvarname,31,"amx_missile_cost%d",icmd)
        new umoney = cs_get_user_money(id)
        new m_cost = get_cvar_num(cvarname)
        if(umoney < m_cost){
            client_print(id,print_chat,"[AMXX] Insufficient funds. Each of these missiles costs %d money",m_cost)
            return PLUGIN_HANDLED
        }
        else {
            cs_set_user_money(id,umoney-m_cost,1)
        }
#endif
    }
    else {
        if( icmd == 7 && get_cvar_num("amx_missile_ammo7ta")){
            new sum
            for(new i = 1; i <= 7; i++)
                sum += missile_inv[id][i]

            if(sum < 7) {
                client_print(id,print_chat,"[AMXX] You do not have enough missiles to make a Swirling Death Missile.")
                if (using_menu[id]) show_main_menu(id)
                return PLUGIN_HANDLED
            }
            else{
                new take
                for(new b = 1; b <= 7; b++){
                    if(take < 7) {
                        for(new i=1; i <= 7; i++){
                            if( (missile_inv[id][i] > 0) && (take < 7) ){
                                missile_inv[id][i]--
                                take++
                            }
                        }
                    }
                }
            }
        }
        else if( missile_inv[id][icmd] <= 0 ){
            switch(icmd){
                case 1: client_print(id,print_chat,"[AMXX] You have no more Common Missiles.")
                case 2: client_print(id,print_chat,"[AMXX] You have no more Laser Guided Missiles.")
                case 3: client_print(id,print_chat,"[AMXX] You have no more Gun Camera Missiles.")
                case 4: client_print(id,print_chat,"[AMXX] You have no more Anti-Missile Missiles.")
                case 5: client_print(id,print_chat,"[AMXX] You have no more Heat Seeking Missiles.")
                case 6: client_print(id,print_chat,"[AMXX] You have no more Parachute Seeking Missiles.")
                case 7: client_print(id,print_chat,"[AMXX] You have no more Swirling Death Missiles.")
            }
            return PLUGIN_CONTINUE
        }
        else {
            missile_inv[id][icmd] -= 1
        }
    }
    if(icmd != 4){
        show_missile_inv(id)
        switch(icmd){
            case 1: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,0,0,0)
            case 2: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,0,0,0)
            case 3: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,0,0,0)
            case 5: make_rocket(id,icmd,get_cvar_num("amx_missile_hsspeed"),0,0,0,0)
            case 6: make_rocket(id,icmd,get_cvar_num("amx_missile_rsspeed"),0,0,0,0)
            case 7: make_rocket(id,icmd,get_cvar_num("amx_missile_sdspeed"),0,0,0,0)
            default: make_rocket(id,icmd,get_cvar_num("amx_missile_speed"),0,0,0,0)
        }
    }
    else {
        is_scan_rocket[id] = 1
        new args[2]
        args[0] = id
        set_task(0.2,"anti_missile_radar",35632+id,args,2,"b")
        set_task(0.3,"amr_pay",35632+id,args,2,"b")
        set_hudmessage(0,255,0, -1.0, 0.26, 0, 0.02, 3.0, 1.01, 1.1, 54)
        show_hudmessage(id,"ANTIMISSILE RADAR SYSTEM ACTIVATED^nAim at missile you want to shoot down")
    }
    return PLUGIN_HANDLED
}

public anti_missile_radar(args[]) {
    new maxplayers = get_maxplayers()
    new id = args[0]
    new tid = 0
    new aimvec[3],origin[3],length
    new radarvec1[3],radarvec2[3],radarvec3[3],radarvec4[3],radarvec5[3]
    get_user_origin(id,origin)
    get_user_origin(id,aimvec,3)
    radarvec1[0]=aimvec[0]-origin[0]
    radarvec1[1]=aimvec[1]-origin[1]
    radarvec1[2]=aimvec[2]-origin[2]
    length = sqroot(radarvec1[0]*radarvec1[0]+radarvec1[1]*radarvec1[1]+radarvec1[2]*radarvec1[2])
    radarvec5[0]=radarvec1[0]*1750/length + origin[0]
    radarvec5[1]=radarvec1[1]*1750/length + origin[1]
    radarvec5[2]=radarvec1[2]*1750/length + origin[2]
    radarvec4[0]=radarvec1[0]*1350/length + origin[0]
    radarvec4[1]=radarvec1[1]*1350/length + origin[1]
    radarvec4[2]=radarvec1[2]*1350/length + origin[2]
    radarvec3[0]=radarvec1[0]*950/length + origin[0]
    radarvec3[1]=radarvec1[1]*950/length + origin[1]
    radarvec3[2]=radarvec1[2]*950/length + origin[2]
    radarvec2[0]=radarvec1[0]*700/length + origin[0]
    radarvec2[1]=radarvec1[1]*700/length + origin[1]
    radarvec2[2]=radarvec1[2]*700/length + origin[2]
    radarvec1[0]=radarvec1[0]*350/length + origin[0]
    radarvec1[1]=radarvec1[1]*350/length + origin[1]
    radarvec1[2]=radarvec1[2]*350/length + origin[2]

    for (new i = 1; i <= maxplayers; i++) {
        if( (has_rocket[i] > maxplayers) && (i != id) && (tid <= maxplayers) ) {
            new szClassName[ MAX_PLAYERS ]
            if(is_valid_ent(has_rocket[i]))
            entity_get_string(has_rocket[i], EV_SZ_classname, szClassName, charsmax (szClassName))
            if (equal(szClassName, "func_rocket")) {
                new rocketvec[3]
                new Float:fl_rocketvec[3]
                entity_get_vector(has_rocket[i], EV_VEC_origin, fl_rocketvec)
                rocketvec[0] = floatround(fl_rocketvec[0])
                rocketvec[1] = floatround(fl_rocketvec[1])
                rocketvec[2] = floatround(fl_rocketvec[2])
                if(get_distance(radarvec5,rocketvec) < 100)
                    tid = has_rocket[i]
                else if(get_distance(radarvec4,rocketvec) < 100)
                    tid = has_rocket[i]
                else if(get_distance(radarvec3,rocketvec) < 85)
                    tid = has_rocket[i]
                else if(get_distance(radarvec2,rocketvec) < 70)
                    tid = has_rocket[i]
                else if(get_distance(radarvec1,rocketvec) < 50)
                    tid = has_rocket[i]
            }
        }
    }
    if(tid > maxplayers){
        client_cmd(id,"spk fvox/beep")
        set_hudmessage(255,10,10, -1.0, 0.26, 0, 0.02, 3.0, 1.01, 1.1, 54)
        show_hudmessage(id,"ANTIMISSILE LOCKED ONTO TARGET")
        is_scan_rocket[id] = 0
        remove_task(35632+id)
        make_rocket(id,4,get_cvar_num("amx_missile_speed")*5,0,1,0,tid)
    }
    return PLUGIN_CONTINUE
}

public amr_pay(args[]) {
    new id = args[0]
    set_hudmessage(255,0,0, -1.0, 0.26, 0, 0.02, 3.0, 1.01, 1.1, 54)
    if(radar_batt[id] < 1){
        show_hudmessage(id,"WARNING: ANTIMISSILE RADAR SYSTEM FAILURE")
        client_print(id,print_center,"^n^nBattery is dead")
        is_scan_rocket[id] = 0
        remove_task(35632+id)
    }
    else{
        client_print(id,print_center,"^n^n^nBattery %d",radar_batt[id])
    }
    radar_batt[id]--
    client_cmd(id,"spk fvox/blip")
    return PLUGIN_CONTINUE
}

//make_rocket(userindex,commandtype,missilespeed,model,nofake,admincommand,antimissleid)
make_rocket(id,icmd,iarg1,iarg2,iarg3,admin,antimissile) {

    if (!is_user_alive(id)) return PLUGIN_CONTINUE

    new args[MAX_IP_LENGTH]
    new Float:vOrigin[3]
    new Float:vAngles[3]
    entity_get_vector(id, EV_VEC_origin, vOrigin)
    entity_get_vector(id, EV_VEC_v_angle, vAngles)
    new notFloat_vOrigin[3]
    notFloat_vOrigin[0] = floatround(vOrigin[0])
    notFloat_vOrigin[1] = floatround(vOrigin[1])
    notFloat_vOrigin[2] = floatround(vOrigin[2])

    if(icmd == 5)
        {
        new aimvec[3]
        get_user_origin(id,aimvec,3)
        new dist = get_distance(notFloat_vOrigin,aimvec)
        new found
        new dist1 = 1000

        new players[ MAX_PLAYERS ], inum
        get_players(players,inum,"ah")

        for(new i = 0 ;i < inum ;++i)

            if(players[i] != id)
                {

                    new SzTag[MAX_IP_LENGTH], szRunawayHeatSignature[MAX_IP_LENGTH];
                    new playername[MAX_NAME_LENGTH],output;
                    get_user_info(players[i],"name",playername,charsmax(playername))
                    get_user_info(id,"heat",szRunawayHeatSignature, charsmax(szRunawayHeatSignature))
                    //user puts set_info "heat" "spinx" to make seekers target player named spinx
                    /*Bot seekers SPINX 10-27-2020*/

                    server_print("heat signature shows as: %s", szRunawayHeatSignature);

                    get_pcvar_string(g_heatseeker_tag, SzTag, charsmax(SzTag));

                    if( get_pcvar_num(g_heatseeker_bot) && is_user_bot(players[i]) || containi(playername,SzTag) == charsmin
                        ||
                        get_pcvar_num(g_heatseeker_user) == 1 && containi(playername,szRunawayHeatSignature) > charsmin

                      )

                        output = 1

                    if(output)

                    if(is_user_connected(players[i]))

                    {
                            new temp[3]
                            get_user_origin(players[i],temp)
                            dist1 = get_distance(temp,aimvec)

                            if(dist1 < dist || dist1 < dist &&

                            cstrike_running() && get_user_team(id) != get_user_team(players[i]) )

                                {
                                    dist = dist1

                                    #if AMXX_VERSION_NUM == 182
                                        new name[MAX_NAME_LENGTH];
                                        get_user_name(players[i], name, charsmax(name))
                                        client_print(id,print_center,"[AMXX][TARGET-IN-VIEW]^n^nLocking coordinates on^n^n%s",name)
                                    #else
                                        client_print(id,print_center,"[AMXX][TARGET-IN-VIEW]^n^nLocking coordinates on^n^n%n",players[i])
                                    #endif

                                    found = 1

                                    args[6] = players[i]
                                }
                    }
        }

        if(!found){
            client_print(id,print_chat,"[AMXX] Cannot fire Heat-Seeker,^n^nthere are no heat signatures in view.")
            if(!admin){
                #if defined CSTRIKE
                if(get_cvar_num("amx_missile_buy") == 1){
                    new umoney = cs_get_user_money(id)
                    new m_cost = get_cvar_num("amx_missile_cost5")
                    cs_set_user_money(id,umoney+m_cost,1)
                }else
                #endif
                {
                    missile_inv[id][5] += 1
                    show_missile_inv(id)
                }
                if(using_menu[id])
                    show_main_menu(id)
            }
            return PLUGIN_HANDLED
        }

    }
    else if(icmd == 6){
        new aimvec[3], output;
        get_user_origin(id,aimvec,3)
        new dist = get_distance(notFloat_vOrigin,aimvec)
        new found
        new parachute_check[MAX_IP_LENGTH];
        new dist1 = 20000
        new players[ MAX_PLAYERS ], inum

        get_players(players,inum,"a")

        for(new i = 0 ;i < inum ;++i)

            if(players[i] != id){

            get_user_info(players[i],"is_parachuting",parachute_check,charsmax(parachute_check))
            if(containi(parachute_check, "false") == charsmin) {
                output = 1;

                if(output == 1){

                    new temp[3]
                    get_user_origin(players[i],temp)
                    dist1 = get_distance(temp,aimvec)

                    if(dist1 < dist){
                        dist = dist1
                        found = 1
                        args[6] = players[i]
                    }
                }
            }
        }
        if(!found){
            client_print(id,print_chat,"[AMXX] Cannot fire Parachute-Seeking Missile, no skydivers in view.")
            if(!admin){
                #if defined CSTRIKE
                if(get_cvar_num("amx_missile_buy") == 1 & cstrike_running() ){
                    new umoney = cs_get_user_money(id)
                    new m_cost = get_cvar_num("amx_missile_cost6")
                    cs_set_user_money(id,umoney+m_cost,1)
                }else
                #endif
                {
                    missile_inv[id][6] += 1
                    show_missile_inv(id)
                }
                if(using_menu[id])
                    show_main_menu(id)
            }
            return PLUGIN_HANDLED
        }
    }
    using_menu[id] = 0

    new NewEnt
    NewEnt = create_entity("info_target")
    if(NewEnt == 0) {
        client_print(id,print_chat,"Rocket Failure")
        return PLUGIN_HANDLED_MAIN
    }
    has_rocket[id] = NewEnt
    if(admin){
        if(iarg3 == 1)
            missile_inv[id][0] = 2
        else
            missile_inv[id][0] = 1
    }
    else {
        missile_inv[id][0] = 0
    }
    entity_set_string(NewEnt, EV_SZ_classname, "func_rocket")

    switch(iarg2){
        case 0: entity_set_model(NewEnt, "models/rpgrocket.mdl")
        case 1: entity_set_model(NewEnt, "models/chick.mdl")
        case 2: entity_set_model(NewEnt, "models/hvr.mdl")
    }

    new Float:fl_vecminsx[3] = {-1.0, -1.0, -1.0}
    new Float:fl_vecmaxsx[3] = {1.0, 1.0, 1.0}

    entity_set_vector(NewEnt, EV_VEC_mins,fl_vecminsx)
    entity_set_vector(NewEnt, EV_VEC_maxs,fl_vecmaxsx)

    entity_set_origin(NewEnt, vOrigin)
    entity_set_vector(NewEnt, EV_VEC_angles, vAngles)

    if(!iarg2) {
        entity_set_int(NewEnt, EV_INT_effects, 64) //tip
    }
    else {
        entity_set_int(NewEnt, EV_INT_effects, 2)
    }

    entity_set_int(NewEnt, EV_INT_solid, 2)
    if(get_cvar_num("amx_missile_obeygravity")) {
        entity_set_int(NewEnt, EV_INT_movetype, 6)
    }
    else {
        entity_set_int(NewEnt, EV_INT_movetype, 5)
    }
    entity_set_edict(NewEnt, EV_ENT_owner, id)
    entity_set_float(NewEnt, EV_FL_health, 10000.0)
    entity_set_float(NewEnt, EV_FL_takedamage, 100.0)
    entity_set_float(NewEnt, EV_FL_dmg_take, 100.0)

    new Float:fl_iNewVelocity[3]
    new iNewVelocity[3]
    VelocityByAim(id, iarg1, fl_iNewVelocity)
    entity_set_vector(NewEnt, EV_VEC_velocity, fl_iNewVelocity)
    iNewVelocity[0] = floatround(fl_iNewVelocity[0])
    iNewVelocity[1] = floatround(fl_iNewVelocity[1])
    iNewVelocity[2] = floatround(fl_iNewVelocity[2])

    emit_sound(NewEnt, CHAN_WEAPON, "weapons/rocketfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    emit_sound(NewEnt, CHAN_VOICE, "weapons/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    args[0] = id
    args[1] = NewEnt
    args[2] = iarg1
    args[3] = iNewVelocity[0]
    args[4] = iNewVelocity[1]
    args[5] = iNewVelocity[2]
    args[8] = notFloat_vOrigin[0]
    args[9] = notFloat_vOrigin[1]
    args[10] = notFloat_vOrigin[2]

    switch(icmd){
        case 1: {
            make_trail(NewEnt,icmd)
            entity_set_float(NewEnt, EV_FL_gravity, 0.25)
            set_task(0.1,"guide_rocket_comm",2020+NewEnt,args,16,"b")
            set_task(get_cvar_float("amx_missile_fuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }
        case 2: {
            make_trail(NewEnt,icmd)
            entity_set_float(NewEnt, EV_FL_gravity, 0.25)
            set_task(0.1,"guide_rocket_las",2020+NewEnt,args,16)
            set_task(get_cvar_float("amx_missile_fuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }
        case 3: {
            make_trail(NewEnt,icmd)
            entity_set_float(NewEnt, EV_FL_gravity, 0.25)
            entity_set_int(NewEnt, EV_INT_rendermode,1)
            if(is_user_connected(id))attach_view(id, NewEnt)
            args[11] = 1
            set_task(0.1,"guide_rocket_dir",2020+NewEnt,args,16,"b")
            set_task(get_cvar_float("amx_missile_fuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }
        case 4: {
            make_trail(NewEnt,icmd)
            args[6] = antimissile
            entity_set_float(NewEnt, EV_FL_gravity, 0.25)
            set_task(0.1,"guide_rocket_anti",2020+NewEnt,args,16)
            set_task(get_cvar_float("amx_missile_fuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }
        case 5: {
            is_heat_rocket[id] = 1
            make_trail(NewEnt,icmd)
            entity_set_float(NewEnt, EV_FL_gravity, 0.25)
            set_task(0.1,"guide_rocket_het",2020+NewEnt,args,16)
            set_task(get_cvar_float("amx_missile_fuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }
        case 6: {
            make_trail(NewEnt,icmd)
            entity_set_float(NewEnt, EV_FL_gravity, 0.25)
            set_task(0.1,"guide_rocket_Parachute",2020+NewEnt,args,16)
            set_task(get_cvar_float("amx_missile_fuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }
        case 7: {
            entity_set_float(NewEnt, EV_FL_gravity, 0.000001)
            SD_CircleRockets(NewEnt)
            set_task(0.1,"guide_rocket_swirl",2020+NewEnt,args,16)
            if( (user_sdmf[id] > 0.0) && (get_cvar_num("amx_missile_allow_sdmf") == 1) )
                set_task(user_sdmf[id],"rocket_fuel_timer",2020+NewEnt,args,16)
            else
                set_task(get_cvar_float("amx_missile_sdfuel"),"rocket_fuel_timer",2020+NewEnt,args,16)
        }

    }
    return PLUGIN_HANDLED_MAIN;
}

make_trail(NewEnt,style){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW)
    write_short(NewEnt) //to follow
    write_short(beam) //sprite index
    write_byte(45) //life
    write_byte(4) //width
    switch(style){ //rgb brightness
        case 1: {
            write_byte(254)
            write_byte(254)
            write_byte(254)
        }
        case 2: {
            write_byte(254)
            write_byte(254)
            write_byte(100)
        }
        case 3: {
            write_byte(random_num(200,255))
            write_byte(random_num(0,60))
            write_byte(random_num(0,50))
        }
        case 4: {
            write_byte(254)
            write_byte(150)
            write_byte(50)
        }
        case 5: {
            write_byte(random_num(200,255))
            write_byte(random_num(0,60))
            write_byte(random_num(0,50))
        }
        case 6: {
            write_byte(100)
            write_byte(250)
            write_byte(100)
        }
        case 7: {
            write_byte(100)
            write_byte(100)
            write_byte(250)
        }
        default: {
            write_byte(254)
            write_byte(254)
            write_byte(254)
        }

    }
    write_byte(100)
    message_end()
}

public guide_rocket_comm(args[]){
    new ent = args[1]
    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health <10000.0)
        vexd_pfntouch(ent,0)

    return PLUGIN_CONTINUE
}

public guide_rocket_dir(args[]){
    new id = args[0]
    new ent = args[1]
    new speed = args[2]
    new Float:fl_iNewVelocity[3]
    VelocityByAim(id, speed, fl_iNewVelocity)
    entity_set_vector(ent, EV_VEC_velocity, fl_iNewVelocity)

    new Float:vAngles[3]
    entity_get_vector(id, EV_VEC_v_angle, vAngles)
    entity_set_vector(ent, EV_VEC_angles, vAngles)

    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health <10000.0)
        vexd_pfntouch(ent,0)
    return PLUGIN_CONTINUE
}

public guide_rocket_las(args[]) {
    new aimvec[3],avgFactor
    new Float:fl_origin[3]
    new id = args[0]
    new ent = args[1]
    new speed = args[2]
    get_user_origin(id,aimvec,3)

    //Make the Laser Dot
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte( 17 )
    write_coord(aimvec[0])
    write_coord(aimvec[1])
    write_coord(aimvec[2])
    write_short( ls_dot )
    write_byte( 10 )
    write_byte( 255 )
    message_end()

    entity_get_vector(ent, EV_VEC_origin, fl_origin)
    new iNewVelocity[3]
    new origin[3]
    origin[0] = floatround(fl_origin[0])
    origin[1] = floatround(fl_origin[1])
    origin[2] = floatround(fl_origin[2])
    if(speed < 400)
        avgFactor = 10
    else if(speed < 850)
        avgFactor = 4
    else
        avgFactor = 2
    new velocityvec[3],length
    velocityvec[0]=aimvec[0]-origin[0]
    velocityvec[1]=aimvec[1]-origin[1]
    velocityvec[2]=aimvec[2]-origin[2]
    length = sqroot(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
    velocityvec[0]=velocityvec[0]*speed/length
    velocityvec[1]=velocityvec[1]*speed/length
    velocityvec[2]=velocityvec[2]*speed/length
    iNewVelocity[0] = (velocityvec[0] + (args[3] * (avgFactor-1) ) ) / avgFactor
    iNewVelocity[1] = (velocityvec[1] + (args[4] * (avgFactor-1) ) ) / avgFactor
    iNewVelocity[2] = (velocityvec[2] + (args[5] * (avgFactor-1) ) ) / avgFactor
    new Float:fl_iNewVelocity[3]
    fl_iNewVelocity[0] = iNewVelocity[0] + 0.0
    fl_iNewVelocity[1] = iNewVelocity[1] + 0.0
    fl_iNewVelocity[2] = iNewVelocity[2] + 0.0
    entity_set_vector(ent, EV_VEC_velocity, fl_iNewVelocity)
    args[3] = iNewVelocity[0]
    args[4] = iNewVelocity[1]
    args[5] = iNewVelocity[2]
    args[8] = origin[0]
    args[9] = origin[1]
    args[10] = origin[2]
    set_task(0.1,"guide_rocket_las",2020+ent,args,16)

    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health < 10000.0)
        vexd_pfntouch(ent,0)

    return PLUGIN_CONTINUE
}

public guide_rocket_het(args[]){
    new aimvec[3],avgFactor
    new Float:fl_origin[3]
    new t_aimvec[ MAX_PLAYERS + 1 ][3]
    new t_index[ MAX_PLAYERS + 1 ]
    new t_jp,dist
    new jp_dist = 2000000
    new id = args[0]
    new ent = args[1]
    new speed = args[2]
    new iNewVelocity[3]
    entity_get_vector(ent, EV_VEC_origin, fl_origin)
    new origin[3]
    origin[0] = floatround(fl_origin[0])
    origin[1] = floatround(fl_origin[1])
    origin[2] = floatround(fl_origin[2])

    new soutput[8],output
    get_user_info(args[6],"info_target",soutput,charsmax(soutput))
    output = str_to_num(soutput)
    if(hookgrabtask[args[6]] == 1)
        output = 1

    if((output == 1) || (args[7] < 5)){
        if(is_user_alive(args[6]) == 1){
            get_user_origin(args[6],aimvec)
            dist = get_distance(aimvec,origin)
        }
        else {
            args[7] = 100
        }
        if(output == 1)
            args[7] = 0
    }
    else {
        new players[ MAX_PLAYERS ], inum
        get_players(players,inum,"a")
        for(new i = 0 ;i < inum ;++i){
            if(players[i] != id){
                setc(soutput,8,0)
                get_user_info(players[i],"info_target",soutput,charsmax(soutput))
                output = str_to_num(soutput)
                if(hookgrabtask[players[i]] == 1)
                    output = 1
                if(output){
                    new temp[3]
                    get_user_origin(players[i],temp)
                    t_aimvec[t_jp][0] = temp[0]
                    t_aimvec[t_jp][1] = temp[1]
                    t_aimvec[t_jp][2] = temp[2]
                    t_index[t_jp] = players[i]
                    t_jp++
                }
            }
        }
        for(new i = 0 ;i < t_jp ;++i){
            new temp[3]
            temp[0] = t_aimvec[i][0]
            temp[1] = t_aimvec[i][1]
            temp[2] = t_aimvec[i][2]
            dist = get_distance(temp,origin)
            if(dist < jp_dist){
                aimvec[0] = temp[0]
                aimvec[1] = temp[1]
                aimvec[2] = temp[2]
                jp_dist = dist
                args[6] = t_index[i]
                args[7] = 0
            }
        }
    }
    if(dist){
        if(speed < 400)
            avgFactor = 10
        else if(speed < 850)
            avgFactor = 4
        else
            avgFactor = 2

        new length, velocityvec[3]
        velocityvec[0]=aimvec[0]-origin[0]
        velocityvec[1]=aimvec[1]-origin[1]
        velocityvec[2]=aimvec[2]-origin[2]
        length=sqroot(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
        velocityvec[0]=velocityvec[0]*speed/length
        velocityvec[1]=velocityvec[1]*speed/length
        velocityvec[2]=velocityvec[2]*speed/length

        iNewVelocity[0] = (velocityvec[0] + (args[3] * (avgFactor-1) ) ) / avgFactor
        iNewVelocity[1] = (velocityvec[1] + (args[4] * (avgFactor-1) ) ) / avgFactor
        iNewVelocity[2] = (velocityvec[2] + (args[5] * (avgFactor-1) ) ) / avgFactor

        args[3] = iNewVelocity[0]
        args[4] = iNewVelocity[1]
        args[5] = iNewVelocity[2]
        if(dist < 20){
            vexd_pfntouch(ent,0)
            return PLUGIN_CONTINUE
        }
    }
    args[7] += 1
    new Float:fl_iNewVelocity[3]
    fl_iNewVelocity[0] = args[3] +0.0
    fl_iNewVelocity[1] = args[4] +0.0
    fl_iNewVelocity[2] = args[5] +0.0

    entity_set_vector(ent, EV_VEC_velocity, fl_iNewVelocity)
    set_task(0.1,"guide_rocket_het",2020+ent,args,16)

    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health < 10000.0)
        vexd_pfntouch(ent,0)

    return PLUGIN_CONTINUE
}

public guide_rocket_anti(args[]){
    new Float:fl_aimvec[3]
    new Float:fl_origin[3]
    new avgFactor
    new id = args[0]
    new ent = args[1]
    new speed = args[2]
    new iNewVelocity[3]

    entity_get_vector(ent, EV_VEC_origin, fl_origin)
    new origin[3]
    origin[0] = floatround(fl_origin[0])
    origin[1] = floatround(fl_origin[1])
    origin[2] = floatround(fl_origin[2])

    if(find_ent_by_class(args[6], "func_rocket") != charsmin && is_valid_ent(args[6])){

        entity_get_vector(args[6], EV_VEC_origin, fl_aimvec)
        new aimvec[3]
        aimvec[0] = floatround(fl_aimvec[0])
        aimvec[1] = floatround(fl_aimvec[1])
        aimvec[2] = floatround(fl_aimvec[2])
        if(speed < 400)
            avgFactor = 10
        else if(speed < 850)
            avgFactor = 4
        else
            avgFactor = 2
        new length, velocityvec[3]
        velocityvec[0]=aimvec[0]-origin[0]
        velocityvec[1]=aimvec[1]-origin[1]
        velocityvec[2]=aimvec[2]-origin[2]
        length=sqroot(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
        velocityvec[0]=velocityvec[0]*speed/length
        velocityvec[1]=velocityvec[1]*speed/length
        velocityvec[2]=velocityvec[2]*speed/length
        iNewVelocity[0] = (velocityvec[0] + (args[3] * (avgFactor-1) ) ) / avgFactor
        iNewVelocity[1] = (velocityvec[1] + (args[4] * (avgFactor-1) ) ) / avgFactor
        iNewVelocity[2] = (velocityvec[2] + (args[5] * (avgFactor-1) ) ) / avgFactor
        args[3] = iNewVelocity[0]
        args[4] = iNewVelocity[1]
        args[5] = iNewVelocity[2]
        if(get_distance(origin,aimvec) < 150){
            vexd_pfntouch(ent,args[6])
            return PLUGIN_CONTINUE
        }
        new Float:fl_iNewVelocity[3]
        fl_iNewVelocity[0] = args[3] +0.0
        fl_iNewVelocity[1] = args[4] +0.0
        fl_iNewVelocity[2] = args[5] +0.0
        entity_set_vector(ent, EV_VEC_velocity, fl_iNewVelocity)
        set_task(0.1,"guide_rocket_anti",2020+ent,args,16)
    }
    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health < 10000.0)
        vexd_pfntouch(ent,0)

    client_cmd(id,"spk buttons/blip2")
    return PLUGIN_CONTINUE
}

public guide_rocket_Parachute(args[]){
    new aimvec[3],avgFactor
    new Float:fl_origin[3]
    new t_aimvec[ MAX_PLAYERS + 1 ][3]
    new t_index[ MAX_PLAYERS + 1 ]
    new t_jp,dist
    new jp_dist = 20000
    new id = args[0]
    new ent = args[1]
    new speed = args[2]
    new iNewVelocity[3]
    entity_get_vector(ent, EV_VEC_origin, fl_origin)
    new origin[3]
    origin[0] = floatround(fl_origin[0])
    origin[1] = floatround(fl_origin[1])
    origin[2] = floatround(fl_origin[2])

    if((cmd_onParachute[args[6]] == 1) || (args[7] < 31)){
        if(is_user_alive(args[6]) == 1){
            get_user_origin(args[6],aimvec)
            dist = get_distance(aimvec,origin)
        }
        else {
            args[7] = 100
        }
        if(cmd_onParachute[args[6]] == 1)
            args[7] = 0
    }
    else {
        new players[ MAX_PLAYERS ], inum
        get_players(players,inum,"a")
        for(new i = 0 ;i < inum ;++i){
            if(players[i] != id){
                if(cmd_onParachute[players[i]] == 1){
                    new temp[3]
                    get_user_origin(players[i],temp)
                    t_aimvec[t_jp][0] = temp[0]
                    t_aimvec[t_jp][1] = temp[1]
                    t_aimvec[t_jp][2] = temp[2]
                    t_index[t_jp] = players[i]
                    t_jp++
                }
            }
        }
        for(new i = 0 ;i < t_jp ;++i){
            new temp[3]
            temp[0] = t_aimvec[i][0]
            temp[1] = t_aimvec[i][1]
            temp[2] = t_aimvec[i][2]
            dist = get_distance(temp,origin)
            if(dist < jp_dist){
                aimvec[0] = temp[0]
                aimvec[1] = temp[1]
                aimvec[2] = temp[2]
                jp_dist = dist
                args[6] = t_index[i]
                args[7] = 0
            }
        }
    }
    if(dist){
        if(speed < 400)
            avgFactor = 10
        else if(speed < 850)
            avgFactor = 4
        else
            avgFactor = 2

        new length, velocityvec[3]
        velocityvec[0]=aimvec[0]-origin[0]
        velocityvec[1]=aimvec[1]-origin[1]
        velocityvec[2]=aimvec[2]-origin[2]
        length=sqroot(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
        velocityvec[0]=velocityvec[0]*speed/length
        velocityvec[1]=velocityvec[1]*speed/length
        velocityvec[2]=velocityvec[2]*speed/length

        iNewVelocity[0] = (velocityvec[0] + (args[3] * (avgFactor-1) ) ) / avgFactor
        iNewVelocity[1] = (velocityvec[1] + (args[4] * (avgFactor-1) ) ) / avgFactor
        iNewVelocity[2] = (velocityvec[2] + (args[5] * (avgFactor-1) ) ) / avgFactor

        args[3] = iNewVelocity[0]
        args[4] = iNewVelocity[1]
        args[5] = iNewVelocity[2]
        if(dist < 60){
            vexd_pfntouch(ent,0)
            return PLUGIN_CONTINUE
        }
    }
    args[7] += 1
    new Float:fl_iNewVelocity[3]
    fl_iNewVelocity[0] = args[3] +0.0
    fl_iNewVelocity[1] = args[4] +0.0
    fl_iNewVelocity[2] = args[5] +0.0

    entity_set_vector(ent, EV_VEC_velocity, fl_iNewVelocity)
    set_task(0.1,"guide_rocket_Parachute",2020+ent,args,16)

    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health <10000.0)
        vexd_pfntouch(ent,0)

    return PLUGIN_CONTINUE
}

public guide_rocket_swirl(args[]){
    new ent = args[1]
    set_task(0.1,"guide_rocket_swirl",2020+ent,args,16)
    new Float:missile_health
    missile_health = Float:entity_get_float(ent, EV_FL_health)
    if(missile_health <10000.0)
        vexd_pfntouch(ent,0)

    return PLUGIN_CONTINUE
}

public rocket_fuel_timer(args[]){
    new ent = args[1]
    new id = args[0]
    remove_task(2020+ent)
    entity_set_int(ent, EV_INT_effects, 2)
    entity_set_int(ent, EV_INT_rendermode,0)
    entity_set_float(ent, EV_FL_gravity, 1.0)
    entity_set_int(ent, EV_INT_iuser1, 0)
    emit_sound(ent, CHAN_WEAPON, "debris/beamstart8.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
    emit_sound(ent, CHAN_VOICE, "ambience/rocket_steam1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    if(args[11] == 1){
        set_hudmessage(250,10,10,-1.0,0.45, 0, 0.0, 1.5, 0.5, 0.15, 54)
        show_hudmessage(id,"WARNING: FUEL TANK EMPTY^nCONTROLS DISENGAGED")
    }
    set_task(0.1,"guide_rocket_comm",2020+ent,args,16,"b")
    return PLUGIN_CONTINUE
}

public ls_missile_ck(){
    new arg[ MAX_PLAYERS ]
    read_argv(1,arg,charsmax(arg))
    new iarg = str_to_num(arg)
    if(iarg){
        new szClassName[ MAX_PLAYERS ]
        if(is_valid_ent(iarg))
        entity_get_string(iarg, EV_SZ_classname, szClassName, charsmax(szClassName))
        if(equal(szClassName, "func_rocket")) {
            new prize = get_cvar_num("amx_missile_prizes")
            new obey = get_cvar_num("amx_missile_obeyffcvar")
            new ff = get_cvar_num("mp_friendlyfire")
            new arg2[ MAX_PLAYERS ],name[ MAX_PLAYERS ],nameowner[ MAX_PLAYERS ],Message[MAX_RESOURCE_PATH_LENGTH]
            read_argv(2,arg2,charsmax(arg2))
            new id = str_to_num(arg2)
            new owner = entity_get_edict(iarg, EV_ENT_owner)
            new Tid,Towner
            Tid = get_user_team(id)
            Towner = get_user_team(owner)
            get_user_name(id,name,charsmax(name))
            get_user_name(owner,nameowner,charsmax(nameowner))
            set_hudmessage(255,25,25, -1.0, 0.23, 0, 0.02, 8.0, 1.01, 1.1, 54)
            if( (Tid == Towner) && (cstrike_running() ) && ( ((ff == 1 ) && (obey == 0)) || (ff == 0) ) ){
                format(Message,charsmax(Message),"%s successfully shot down^n%s's missile with a laser",name,nameowner)
            }
            else {
                if(prize){
                    format(Message,191,"%s successfully shot down %s's missile wi a laser^nA total of %d free missiles of each type were won!",name,nameowner,prize)
                    client_print(id,print_chat,"[AMXX] You shot down a missile with the laser gun so you win free missiles")
                    missile_win[id] += 1
                    missile_inv[id][1] += prize
                    missile_inv[id][2] += prize
                    missile_inv[id][3] += prize
                    missile_inv[id][4] += prize
                    missile_inv[id][5] += prize
                    missile_inv[id][6] += prize
                    missile_inv[id][7] += prize
                }
                else {
                    format(Message,191,"%s successfully shot down^n%s's missile with a laser",name,nameowner)
                }
            }
            show_hudmessage(0,Message)
            client_cmd(0,"spk ^"rocket destroyed^"")
            set_task(2.0,"delay_prizewin")
            vexd_pfntouch(iarg,0)
        }
    }
    return PLUGIN_HANDLED
}

public jp_missile_ck(){
    new sid[4],sstat[4]
    read_argv(1,sid,charsmax(sid))
    read_argv(2,sstat,charsmax(sstat))
    new id = str_to_num(sid)

    if(id < 1 || id > MAX_PLAYERS)
        id = MAX_PLAYERS

    hookgrabtask[id] = str_to_num(sstat)

    return PLUGIN_CONTINUE
}

public rp_missile_ck(){
    new sid[4],sstat[4]
    read_argv(1,sid,charsmax(sid))
    read_argv(2,sstat,charsmax(sstat))
    cmd_onParachute[str_to_num(sid)] = str_to_num(sstat)
    return PLUGIN_CONTINUE
}

public HandleSay(id) {
    new Speech[ MAX_RESOURCE_PATH_LENGTH ]
    read_args(Speech,charsmax(Speech))
    remove_quotes(Speech)

    if( equal(Speech,"/missile") ) {
        show_main_menu(id)
    }
    else if( equal(Speech,"/missile_help") ) {
        rocket_motd(id)
    }
    else if( equal(Speech,"/missle") || equal(Speech,"/missl") || equal(Speech,"/misle")) {
        show_main_menux(id)
    }
    else if( containi(Speech, "vote") == charsmin && (containi(Speech, "rocket") != charsmin || containi(Speech, "missile") != charsmin || containi(Speech, "missle") != charsmin)){
        if(get_cvar_num("amx_luds_missiles") == 1){
            client_print(id,print_chat,"[AMXX] Missiles are enabled - For Help Say /missile_help")
        }
        else{
            client_print(id,print_chat,"[AMXX] Missiles are disabled.")
        }
    }

    return PLUGIN_CONTINUE
}

public rocket_motd(id){

    new buffer[MAX_MOTD_LENGTH]
    new len = charsmax(buffer)
    new n = 0

#if !defined NO_STEAM
    if ( cstrike_running() || (is_running("dod") == 1)  )
        n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n")
#endif

    n += copy( buffer[n],len-n,"To use your missile launcher have to bind a key to:^n^n")
    n += copy( buffer[n],len-n,"missile_menu^n^n")
    n += copy( buffer[n],len-n,"In order to bind a key you must open your console and use the bind command: ^n^n")
    n += copy( buffer[n],len-n,"bind ^"key^" ^"command^" ^n^n")

    n += copy( buffer[n],len-n,"In this case the command is ^"missile_menu^".  Here are some examples:^n^n")
    n += copy( buffer[n],len-n,"    bind f missile_menu         bind MOUSE3 missile_menu^n^n")

    n += copy( buffer[n],len-n,"When you press that key it brings up the menu^n")
    n += copy( buffer[n],len-n,"You can also say /missile in chat to activate the menu^n")

    n += copy( buffer[n],len-n,"If you prefer not to use the menu and to make,^n")
    n += copy( buffer[n],len-n,"your own binds, the direct console missile commands are:^n^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_missile^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_laserguided_missile^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_guncamera_missile^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_anti_missile^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_heatseeking_missile^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_Parachuteseeking_missile^n")
    n += copy( buffer[n],len-n,"     bind <any key> amx_swirlingdeath_missile^n^n")

    n += copy( buffer[n],len-n,"     amx_sdmf <swirling death fuel 10ths/second.>^n^n")

    n += copy( buffer[n],len-n,"Notes:^n")
    n += copy( buffer[n],len-n,"  - Heat-Seeking Missiles chase down the nearest running jetpack.^n")
    n += copy( buffer[n],len-n,"  - Parachute-Seeking Missiles chase down the nearest person on a ninja Parachute.^n")
    n += format( buffer[n],len-n,"  - Missiles currently have %.1f seconds worth of fuel.^n",get_cvar_float("amx_missile_fuel"))
    n += copy( buffer[n],len-n,"  - Anti-Missiles must be aimed at a missile, then the missile auto fires.^n")
    n += format( buffer[n],len-n,"  - Currently Missiles %s.^n",get_cvar_num("amx_missile_buy") ? "are free" : "must be paid for")

#if !defined NO_STEAM
    if ( cstrike_running() || (is_running("dod") == 1)  )
      n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

    show_motd(id,buffer ,"Missile Help:")
    return PLUGIN_CONTINUE
}

show_missile_inv(id){
    if(get_cvar_num("amx_missile_buy") == 0){
        new Message[MAX_USER_INFO_LENGTH]
        new len = charsmax(Message)
        new n = 0

        new sum
        for(new i=1;i<8;i++)
            sum += missile_inv[id][i]

        set_hudmessage(255, 10, 10, 0.80, 0.60, 0, 0.02, 6.0, 1.01, 1.1, 55)
        n += format( Message[n],len-n,"Common Missile  ( %d )^n",missile_inv[id][1])
        n += format( Message[n],len-n,"Laser Guided Missile  ( %d )^n",missile_inv[id][2])
        n += format( Message[n],len-n,"Gun Camera Missile  ( %d )^n",missile_inv[id][3])
        n += format( Message[n],len-n,"Anti-Missile Shots  ( %d )^n",missile_inv[id][4])
        n += format( Message[n],len-n,"Heat-Seeking Missile  ( %d )^n",missile_inv[id][5])
        n += format( Message[n],len-n,"Parachute-Seeking Missile  ( %d )^n",missile_inv[id][6])

        if(get_cvar_num("amx_missile_ammo7ta")) {
            new sdcount = sum / 7
            n += format( Message[n],len-n,"Swirling Death Missile  ( %d )",sdcount)
        }
        else
            n += format( Message[n],len-n,"Swirling Death Missile  ( %d )",missile_inv[id][7])

        show_hudmessage(id,Message)
    }
    return PLUGIN_HANDLED
}

public show_main_menux(id) {
    client_print(id,print_chat,"[AMXX] It's spelled ^"/missile^" but I'll help you anyway")
    show_main_menu(id)
    return PLUGIN_HANDLED
}

public show_main_menu(id) {
    new menu_body[MAX_MENU_LENGTH]
    new n = 0
    new len = charsmax(menu_body)

    if(!get_cvar_num("amx_luds_missiles") || !is_user_alive(id))
        return PLUGIN_HANDLED

    if (cstrike_running())
        n += format( menu_body[n],len-n,"\yFire Missile Menu^n\w^n")
    else
        n += format( menu_body[n],len-n,"Fire Missile Menu^n^n")

    if(get_cvar_num("amx_missile_buy") == 1 && cstrike_running()){

        n += format( menu_body[n],len-n,"1. Common Missile - $%d^n",get_cvar_num("amx_missile_cost1"))
        n += format( menu_body[n],len-n,"2. Laser Guided Missile - $%d^n",get_cvar_num("amx_missile_cost2"))
        n += format( menu_body[n],len-n,"3. Gun Camera Missile - $%d^n",get_cvar_num("amx_missile_cost3"))
        n += format( menu_body[n],len-n,"4. Anti-Missile Shots - $%d^n",get_cvar_num("amx_missile_cost4"))
        n += format( menu_body[n],len-n,"5. Heat-Seeking Missile - $%d^n",get_cvar_num("amx_missile_cost5"))
        n += format( menu_body[n],len-n,"6. Parachute-Seeking Missile - $%d^n",get_cvar_num("amx_missile_cost6"))
        n += format( menu_body[n],len-n,"7. Swirling Death Missile - $%d^n",get_cvar_num("amx_missile_cost7"))
    }
    else {

        new sum
        for(new i=1;i<8;i++)
            sum += missile_inv[id][i]

        n += format( menu_body[n],len-n,"1. Common Missile ( %d )^n",missile_inv[id][1])
        n += format( menu_body[n],len-n,"2. Laser Guided Missile ( %d )^n",missile_inv[id][2])
        n += format( menu_body[n],len-n,"3. Gun Camera Missile ( %d )^n",missile_inv[id][3])
        n += format( menu_body[n],len-n,"4. Anti-Missile Shots ( %d )^n",missile_inv[id][4])
        n += format( menu_body[n],len-n,"5. Heat-Seeking Missile ( %d )^n",missile_inv[id][5])
        n += format( menu_body[n],len-n,"6. Parachute-Seeking Missile ( %d )^n",missile_inv[id][6])

        if(get_cvar_num("amx_missile_ammo7ta")) {
            new sdcount = sum / 7
            n += format( menu_body[n],len-n,"7. Swirling Death Missile ( %d )^n",sdcount)
        }
        else
            n += format( menu_body[n],len-n,"7. Swirling Death Missile ( %d )^n",missile_inv[id][7])
    }

    n += format( menu_body[n],len-n,"^n9. Missile Info Window^n")
    n += format( menu_body[n],len-n,"0. Exit")

    new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8)|(1<<9)

    show_menu(id,keys,menu_body)
    return PLUGIN_HANDLED
}

public action_main_menu(id,key){
    using_menu[id] = 1

    if(!get_cvar_num("amx_luds_missiles") || !is_user_alive(id)) {
        using_menu[id] = 0
        return PLUGIN_HANDLED
    }

    if (roundfreeze) {
        show_main_menu(id)
        return PLUGIN_HANDLED
    }

    key++
    switch(key){
        case 1: client_cmd(id,"amx_missile")
        case 2: client_cmd(id,"amx_laserguided_missile")
        case 3: client_cmd(id,"amx_guncamera_missile")
        case 4: client_cmd(id,"amx_anti_missile")
        case 5: client_cmd(id,"amx_heatseeking_missile")
        case 6: client_cmd(id,"amx_Parachuteseeking_missile")
        case 7: client_cmd(id,"amx_swirlingdeath_missile")
        case 9: {
            rocket_motd(id)
            using_menu[id] = 0
        }
        case 10: using_menu[id] = 0
        default: show_main_menu(id)
    }

    if (key >= 1 && key <= 7) {
        if(get_cvar_num("amx_missile_buy")){
            #if defined CSTRIKE
            new costcvar[ MAX_PLAYERS ]
            format(costcvar,charsmax(costcvar),"amx_missile_cost%d",key)
            if(cs_get_user_money(id) < get_pcvar_num(g_costcvar))
            #endif
                show_main_menu(id)
        }
        else {
            if(key == 7 && !get_cvar_num("amx_missile_ammo7ta") && missile_inv[id][key] <= 0)
                show_main_menu(id)
            else if(missile_inv[id][key] <= 0)
                show_main_menu(id)
        }
    }

    return PLUGIN_HANDLED
}


public Death_msg()
{
    set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);
    //return PLUGIN_HANDLED; //void the data all together. handy
    return PLUGIN_CONTINUE;
}


public death_event(){

    new victim;
    victim = read_data(2)
    remove_task(35632+victim)
    if(is_user_connected(victim))
    {
        is_scan_rocket[victim] = 0
        using_menu[victim] = 0
    }
    return PLUGIN_CONTINUE;
}

public round_end(){

    roundfreeze = true

    if(get_cvar_num("amx_luds_missiles") == 0)
        return PLUGIN_CONTINUE

    for (new i=1; i <= get_maxplayers(); i++) {
        if(is_user_connected(i)) {
            if( !is_user_alive(i) && get_cvar_num("amx_missile_buy") ){
                missile_inv[i][1] = 0
                missile_inv[i][2] = 0
                missile_inv[i][3] = 0
                missile_inv[i][4] = 0
                missile_inv[i][5] = 0
                missile_inv[i][6] = 0
                missile_inv[i][7] = 0
            }
        }
        if(has_rocket[i] > 0)
            remove_missile(i,has_rocket[i])
    }
    return PLUGIN_CONTINUE
}

public round_start(){

    roundfreeze = false

    if (get_cvar_num("amx_missile_spawndelay") && !round_delay) {
        round_delay = 1
        set_task(15.0,"roundstart_delay")
    }

    if(get_cvar_num("amx_luds_missiles") == 0)
        return PLUGIN_CONTINUE

    new prize = get_cvar_num("amx_missile_prizes")

    for (new i = 1; i <= get_maxplayers(); i++) {
        radar_batt[i] = get_cvar_num("amx_missile_radarbattery")
        if(!get_cvar_num("amx_missile_buy")){
            missile_inv[i][1] = get_cvar_num("amx_missile_ammo1")
            missile_inv[i][2] = get_cvar_num("amx_missile_ammo2")
            missile_inv[i][3] = get_cvar_num("amx_missile_ammo3")
            missile_inv[i][4] = get_cvar_num("amx_missile_ammo4")
            missile_inv[i][5] = get_cvar_num("amx_missile_ammo5")
            missile_inv[i][6] = get_cvar_num("amx_missile_ammo6")
            missile_inv[i][7] = get_cvar_num("amx_missile_ammo7")
        }
        if(missile_win[i] > 0){
            missile_inv[i][1] += (prize * missile_win[i])
            missile_inv[i][2] += (prize * missile_win[i])
            missile_inv[i][3] += (prize * missile_win[i])
            missile_inv[i][4] += (prize * missile_win[i])
            missile_inv[i][5] += (prize * missile_win[i])
            missile_inv[i][6] += (prize * missile_win[i])
            missile_inv[i][7] += (prize * missile_win[i])
            missile_win[i] = 0
            client_print(i,print_chat,"[AMXX] You won extra missiles from shooting some down last round")
        }
    }
    new iCurrent = find_ent_by_class(charsmin, "func_rocket")

    while ((iCurrent = find_ent_by_class(charsmin, "func_rocket")) != 0){
        new id = entity_get_edict(iCurrent, EV_ENT_owner)
        remove_missile(id,iCurrent)
    }
    return PLUGIN_CONTINUE
}

public roundstart_delay(){
    round_delay = 0
}

remove_missile(id,missile){

    new Float:fl_origin[3]
    entity_get_vector(missile, EV_VEC_origin, fl_origin)

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(14)
    write_coord(floatround(fl_origin[0]))
    write_coord(floatround(fl_origin[1]))
    write_coord(floatround(fl_origin[2]))
    write_byte (200)
    write_byte (40)
    write_byte (45)
    message_end()

    emit_sound(missile, CHAN_WEAPON, "ambience/particle_suck2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    emit_sound(missile, CHAN_VOICE, "ambience/particle_suck2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    has_rocket[id] = 0
    is_heat_rocket[id] = 0
    is_scan_rocket[id] = 0
    remove_task(2020+missile)
    if(is_user_connected(id))attach_view(id,id)
    remove_entity(missile)
    return PLUGIN_CONTINUE
}

public replace_dm(id,tid,tbody) {

    emessage_begin(MSG_BROADCAST, gmsgDeathMsg, {0,0,0}, 0);

    ewrite_byte(id); //killer
    ewrite_byte(tid); //victim

    if(cstrike_running())
        ewrite_string(" rpg_rocket")
    else
        ewrite_string("rpg_rocket");

    emessage_end();
}

public pin_scoreboard(killer)
{
    if(is_user_connected(killer))
    {
        emessage_begin(MSG_BROADCAST,gmsgScoreInfo)
        ewrite_byte(killer);
        ewrite_short(get_user_frags(killer));
        static iDEATHS = 422
        ewrite_short(get_pdata_int(killer, iDEATHS))

        if(cstrike_running())
        {
            ewrite_short(0); //TFC CLASS
            ewrite_short(get_user_team(killer));
        }
        emessage_end();
    }

}




public SD_CircleRockets(Ent){
    new NUMBER_OF_ROCKETS = get_cvar_num("amx_missile_sdcount")
    new ROCKET_RADIUS =  get_cvar_num("amx_missile_sdradius")
    new Float:vOrigin[3]
    new Float:vVelocity[3]
    new Float:vEntOrig[3]
    new Float:RotMatrix[3][3]
    new Float:x, Float:y, Float:z, Float:theta
    new i, id, NewEnt
    entity_get_vector(Ent, EV_VEC_origin, vOrigin)
    entity_get_vector(Ent, EV_VEC_velocity, vVelocity)
    id = entity_get_edict(Ent, EV_ENT_owner)

    RotMatrix[0][0]=vVelocity[0]
    RotMatrix[0][1]=vVelocity[1]
    RotMatrix[0][2]=vVelocity[2]
    RotMatrix[1][0]=-vVelocity[1]
    RotMatrix[1][1]=vVelocity[0]
    RotMatrix[1][2]=0.0
    SD_Normalise(RotMatrix[0])
    SD_Normalise(RotMatrix[1])

    RotMatrix[2][0]=((RotMatrix[0][1])*(RotMatrix[1][2]))-((RotMatrix[0][2])*(RotMatrix[1][1]))
    RotMatrix[2][1]=((RotMatrix[0][2])*(RotMatrix[1][0]))-((RotMatrix[0][0])*(RotMatrix[1][2]))
    RotMatrix[2][2]=((RotMatrix[0][0])*(RotMatrix[1][1]))-((RotMatrix[0][1])*(RotMatrix[1][0]))

    for (i=0; i<NUMBER_OF_ROCKETS; i++){
        theta = (float(i)/float(NUMBER_OF_ROCKETS))*2*PI+fAngle
        x = 0.0
        y = floatcos(theta)*ROCKET_RADIUS
        z = floatsin(theta)*ROCKET_RADIUS

        vEntOrig[0]=RotMatrix[0][0]*x+RotMatrix[1][0]*y+RotMatrix[2][0]*z
        vEntOrig[1]=RotMatrix[0][1]*x+RotMatrix[1][1]*y+RotMatrix[2][1]*z
        vEntOrig[2]=RotMatrix[0][2]*x+RotMatrix[1][2]*y+RotMatrix[2][2]*z
        vEntOrig[0]+=vOrigin[0]
        vEntOrig[1]+=vOrigin[1]
        vEntOrig[2]+=vOrigin[2]
        NewEnt = SD_CreateRocket(vEntOrig, vVelocity, id)
        entity_set_int(NewEnt, EV_INT_iuser1, Ent)
        entity_set_int(NewEnt, EV_INT_iuser2, i)
    }
}

public SD_CreateRocket(Float:vOrigin[3], Float:vVelocity[3], id) {
    new Float:vAngles[3]
    vector_to_angle(vVelocity, vAngles)
    new NewEnt = create_entity("info_target")
    if(!NewEnt) return PLUGIN_CONTINUE
    entity_set_string(NewEnt, EV_SZ_classname, "func_rocket")
    entity_set_model(NewEnt, "models/rpgrocket.mdl")
    new Float:fl_vecminsx[3] = {-1.0, -1.0, -1.0}
    new Float:fl_vecmaxsx[3] = {1.0, 1.0, 1.0}
    entity_set_vector(NewEnt, EV_VEC_mins, fl_vecminsx)
    entity_set_vector(NewEnt, EV_VEC_maxs, fl_vecmaxsx)
    entity_set_origin(NewEnt, vOrigin)
    entity_set_vector(NewEnt, EV_VEC_angles, vAngles)
    entity_set_int(NewEnt, EV_INT_solid, 2)
    entity_set_int(NewEnt, EV_INT_movetype, 6)
    entity_set_edict(NewEnt, EV_ENT_owner, id)
    entity_set_float(NewEnt, EV_FL_health, 10000.0)
    entity_set_float(NewEnt, EV_FL_takedamage, 100.0)
    entity_set_float(NewEnt, EV_FL_dmg_take, 100.0)
    entity_set_vector(NewEnt, EV_VEC_velocity, vVelocity)
    make_trail(NewEnt,7) // 7 = Swirling Missiles
    entity_set_float(NewEnt, EV_FL_gravity, 0.000001 )

    emit_sound(NewEnt, CHAN_WEAPON, "weapons/rocketfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    emit_sound(NewEnt, CHAN_VOICE, "weapons/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    new args[16]
    args[0] = id
    args[1] = NewEnt
    args[2] = get_cvar_num("amx_missile_sdspeed")
    args[3] = floatround(vVelocity[0])
    args[4] = floatround(vVelocity[1])
    args[5] = floatround(vVelocity[2])
    if( get_cvar_num("amx_missile_allow_sdmf") && user_sdmf[id] > 0.0 )
        set_task(user_sdmf[id],"rocket_fuel_timer",2020+NewEnt,args,16)
    else
        set_task(get_cvar_float("amx_missile_sdfuel"),"rocket_fuel_timer",2020+NewEnt,args,16)

    return NewEnt
}

public SD_Normalise(Float:Vector[3]){
    new Float:NullVector[3] = {0.0,0.0,0.0}
    new Float:fLength = vector_distance(Vector, NullVector)
    Vector[0] /= fLength
    Vector[1] /= fLength
    Vector[2] /= fLength
}

public RocketThink() {
    new NUMBER_OF_ROCKETS = get_cvar_num("amx_missile_sdcount")
    new ANGULAR_VELOCITY = get_cvar_num("amx_missile_sdrotate")
    new ROCKET_RADIUS =  get_cvar_num("amx_missile_sdradius")
    new iCurrent, iCenterRocket, i
    new Float:vOrigin[3], Float:vVelocity[3]
    new Float:RotMatrix[3][3]
    new Float:vEntOrig[3], Float:vOldEntOrig[3]
    new Float:x, Float:y, Float:z, Float:theta
    new Float:vAngles[3], Float:fNewVelocity[3]
    new iTempEnt
    new bool:bFound
    fAngle += ANGULAR_VELOCITY * DT

    if (fAngle > 2*PI)
        fAngle -= 2*PI

    iCurrent = find_ent_by_class(charsmin, "func_rocket")

    while (iCurrent != 0){
        iCenterRocket = entity_get_int(iCurrent, EV_INT_iuser1)
        if (iCenterRocket){
            bFound = false
            iTempEnt = charsmin
            do{
                iTempEnt = find_ent_by_class(iTempEnt, "func_rocket")
                if (iTempEnt == iCenterRocket) bFound = true
            } while (iTempEnt != 0 && !bFound)

            iTempEnt = charsmin
            do{
                iTempEnt = find_ent_by_class(iTempEnt, "vexd_vrocket")
                if (iTempEnt == iCenterRocket) bFound = true
            } while (iTempEnt != 0 && !bFound)

            if (bFound){
                entity_get_vector(iCenterRocket, EV_VEC_origin, vOrigin)
                entity_get_vector(iCenterRocket, EV_VEC_velocity, vVelocity)
                entity_get_vector(iCurrent, EV_VEC_origin, vOldEntOrig)
                i = entity_get_int(iCurrent, EV_INT_iuser2)
                RotMatrix[0][0]=vVelocity[0]
                RotMatrix[0][1]=vVelocity[1]
                RotMatrix[0][2]=vVelocity[2]
                RotMatrix[1][0]=-vVelocity[1]
                RotMatrix[1][1]=vVelocity[0]
                RotMatrix[1][2]=0.0
                SD_Normalise(RotMatrix[0])
                SD_Normalise(RotMatrix[1])
                RotMatrix[2][0]=((RotMatrix[0][1])*(RotMatrix[1][2]))-((RotMatrix[0][2])*(RotMatrix[1][1]))
                RotMatrix[2][1]=((RotMatrix[0][2])*(RotMatrix[1][0]))-((RotMatrix[0][0])*(RotMatrix[1][2]))
                RotMatrix[2][2]=((RotMatrix[0][0])*(RotMatrix[1][1]))-((RotMatrix[0][1])*(RotMatrix[1][0]))
                theta = (float(i)/float(NUMBER_OF_ROCKETS))*2*PI+fAngle
                x = 0.0
                y = floatcos(theta)*ROCKET_RADIUS
                z = floatsin(theta)*ROCKET_RADIUS
                vEntOrig[0]=RotMatrix[0][0]*x+RotMatrix[1][0]*y+RotMatrix[2][0]*z
                vEntOrig[1]=RotMatrix[0][1]*x+RotMatrix[1][1]*y+RotMatrix[2][1]*z
                vEntOrig[2]=RotMatrix[0][2]*x+RotMatrix[1][2]*y+RotMatrix[2][2]*z
                vEntOrig[0]+=vOrigin[0]
                vEntOrig[1]+=vOrigin[1]
                vEntOrig[2]+=vOrigin[2]
                vEntOrig[0]+=vVelocity[0]*DT
                vEntOrig[1]+=vVelocity[1]*DT
                vEntOrig[2]+=vVelocity[2]*DT
                CalculateVelocity(vOldEntOrig, vEntOrig, fNewVelocity)
                entity_set_vector(iCurrent, EV_VEC_velocity, fNewVelocity)
                vector_to_angle(fNewVelocity, vAngles)
                entity_set_vector(iCurrent, EV_VEC_angles, vAngles)
                new Float:missile_health
                missile_health = Float:entity_get_float(iCurrent, EV_FL_health)
                if(missile_health < 10000.0)
                    vexd_pfntouch(iCurrent,0)
            }
            else {
                entity_set_int(iCurrent, EV_INT_iuser1, 0)
            }
        }
        iCurrent =  find_ent_by_class(iCurrent, "func_rocket")
    }
    return PLUGIN_CONTINUE;
}

public CalculateVelocity(Float:vOrigin[3], Float:vEnd[3], Float:vVelocity[3]){
    vVelocity[0] = (vEnd[0] - vOrigin[0]) / DT
    vVelocity[1] = (vEnd[1] - vOrigin[1]) / DT
    vVelocity[2] = (vEnd[2] - vOrigin[2]) / DT
}
