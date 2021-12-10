/** AMX Mod X script.
*
*    Flame Thrower (amx_ejl_flamethrower.sma)
*    Enjoy the effects of a flameflower on GoldSrc.
*    Copyleft (C) 2019 .s ^ i  X ^ .
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
****************************************************************************
*
*   Version 5.3.7 = Date: 12/09/2021
*
*   Original by Eric Lidman aka "Ludwig van" <ejlmozart@hotmail.com>
*   Homepage: http://lidmanmusic.com/cs/plugins.html
*
*   Upgraded to STEAM and ported to AMXx by: jtp10181 <jtp@jtpage.net>
*   Homepage: http://www.jtpage.net
*
*   Ported to Half-Life by SPiNX.
*
****************************************************************************
*
*   Add a flamethrower weapon to any Half-Life mod. Clients need to bind a key
*   to amx_fire_flamethrower and then use that key to use their flame-
*   thrower. The flamethower is a deadly weapon and give frag credit to the
*   player who burned another player with a flamethrower burst. Lots of cool
*   FX fire etc. It is sensitive to the mp_friendlyfire cvar and will thus
*   kill teamates if friendlyfire is on and not if its off.
*
*  PODBOT: If using my podbots controller, podbots use this plugin too.
*  *NOTE* PODBot code is untested is current sersion,
*   the podbot controller plugin needs to be updated to AMXx first.
*
*  Admin Commands:
*
*   amx_flamethrowers                --toggles flamethrowers enabled or not
*
*   amx_flamethrowers_buytype        --toggles flamethrowers to be bought
*                                      with money or armor points
*
*   amx_flamethrowers_cost <ammount> --sets the cost of a flamethrower
*
*
*  Client Commands:
*
*   amx_fire_flamethrower     - should be bound to a key, fires flamethrower
*                                if enabled and if there are sufficient funds
*                                from the client in either armor or money
*                                depending on the buytype cvar
*
*   say /flamethrower         - gives cleints info on setup of the
*                                flamethrower in an motd window
*
*
*  CVARs: Paste the following into your amxx.cfg to change defaults.
*       You must uncomment cvar lines for them to take effect
*
****************************************************************************
*  CVAR CONFIG BEGIN
****************************************************************************

// ******************  FlameThrower Settings  ******************

//0 = disable  1= enable
//amx_luds_flamethrower 1

//0= armor    1= money
//amx_flamethrower_buytype 0

//amount of money or armor depending on buytype for each flameburst
//amx_flamethrower_cost 30

//for mods other than cstrike which do not have money and armor to use as
//payment for flamethrower. Set the number of flamethrower blasts given
//to each player at spawn. If this is set to 1 or higher in CS it will
//override the buying system.
//amx_flamethrower_free 0

// if mp_friendlyfire is 1 and this cvar is set to 0, this plugin will
//act as if friendlyfire is off... even if its on.
//amx_flamethrower_obeyffcvar 1

//for friendlyfire on, the option to punish team killer. Quota is from
//amx_flamethrower_tkpunsish2 cvar. Options: a mix of kill,kick, and ban
//   0 = no action on team killer
//   1 = kick tker on tk quota
//   2 = 3 hour ban tker on quota
//   3 = always kill tker, kick on quota
//   4 = always kill tker, ban on quota
//amx_flamethrower_tkpunish1 1

//for friendlyfire on, quantity of teammates a player can kill before a
//kick or ban can result depending on how amx_flamethrower_tkpunish1 cvar is set
//amx_flamethrower_tkpunish2 3

//since bots are stupid, wasting their flamebursts, we give them a handicap
//with this cvar set to 1 so that bots get an unlimited flamethrower use
//amx_flamethrower_botsnolimit 1

****************************************************************************
*  CVAR CONFIG END
****************************************************************************
*
*  Additional info:
*
*   Flamethrower kills and damage are sent to the sever logs in the same
*   format as normal kills and damage. A log parser (like pysychostats) should
*   be able to take the log output of this plugin and include them in the
*   stats output. Flamethrower kills count on the CS scoreboard, but are only
*   refeshed at the end of each round. This is for CS only by the way.
*
*                 ******** Engine Module REQUIRED ********
*
*  Changelog:
*  v5.3.7 - SPiNX - 12/09/2021
*   - Correct Death messages for all mods. Assure deaths occur.
*  v5.3.6 - SPiNX - 09/19/2019
*   - Finished porting to plugins other than Counter-Strike 1.6.
*   - Designed for Amxx1.8.2 and tested on Amxx1.9.0.
*
*  v5.3.5 - JTP10181 - 10/16/04
*   - Updated for AMXModX 0.20
*
*  v5.3.4 - JTP10181 - 07/10/04
*   - Made it so flamethrower cannot be used during freezetime at start of round
*   - Removed all voting code, use amx_customvotes instead
*   - Changed authid arrays to be 34 usable chars for future compatibility
*
*  v5.3.3 - JTP10181 - 06/08/04
*   - Tweaked the help messages a little for the commands
*   - Removed all \ line breaks, not supported anymore.
*
*  v5.3.2 - JTP10181 - 05/26/04
*   - Changed all printed messages to use the [AMXX] tag instead of [AMX]
*   - Converted MOTD boxes to work with steam and possibly with WON still (untested)
*   - Fixed all authid variables to be 32 chars to STEAMIDs are handled properly
*   - Changed wc3 specific code to use the engine module for AMXx
*   - Started to reorganize the code so its easier for me to follow
*   - Redid the commented section with the cvars so it can be copy/pasted into a config file
*   - Changed death message blocking to BLOCK_ONCE for better compatibility
*   - Removed "redundant plugin" code as it was made useless by BLOCK_ONCE change
*   - Made it update the scores right away instead of waiting till next round (thanks -]ToC[-Bludy)
*   - Made plugin use the AMXx vault.ini instead of using its own code, might as well use AMXx.
*   - Fixed logging to admin log for AMXx
*   - Removed all DoD code as it needs to be a totally separate plugin
*
*  Below v5.3.2 was maintained by Eric Lidman
*
***************************************************************************/

//Comment this line out for mods other than cstrike
///#define CSTRIKE

/***********************************************************************************
*                                                                                  *
*  *end* customizable section of code. other changes can be done with the cvars    *
*                                                                                  *
************************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fun>

#if defined CSTRIKE
#include <cstrike>
#endif

new smoke
new fire
new burning
new isburning[33]
new bool:csmod_running
new bool:roundfreeze
new flame_count[33]
new tkcount[33]
new gmsgDeathMsg
new gmsgScoreInfo
new g_teams

public amx_fl(id,level,cid){
    if (!cmd_access(id,level,cid,1))
        return PLUGIN_HANDLED

    new command[60]
    new variable[6]
    new name[33]
    new authid[35]
    get_user_authid(id,authid,34)
    get_user_name(id,name,32)
    read_argv(0,command,59)
    read_argv(1,variable,5)

    if(get_cvar_num("amx_luds_flamethrower") == 1) {
        set_cvar_string("amx_luds_flamethrower","0")
        console_print(id,"[AMXX] %s has been turned OFF",command)
        switch(get_cvar_num("amx_show_activity"))   {
            case 2: client_print(0,print_chat,"ADMIN %s: Executed %s OFF",name,command)
            case 1: client_print(0,print_chat,"ADMIN: Executed %s OFF",command)
        }
        log_amx("FlameThrower: ^"%s<%d><%s><>^" disabled flamethrowers", name,get_user_userid(id),authid)
    }
    else {
        set_cvar_string("amx_luds_flamethrower","1")
        console_print(id,"[AMXX] %s has been turned ON.",command)
        switch(get_cvar_num("amx_show_activity"))   {
            case 2: client_print(0,print_chat,"ADMIN %s: Executed %s ON",name,command)
            case 1: client_print(0,print_chat,"ADMIN: Executed %s ON",command)
        }
        log_amx("FlameThrower: ^"%s<%d><%s><>^" enabled flamethrowers", name,get_user_userid(id),authid)
    }


    return PLUGIN_HANDLED
}

public amx_fl_b(id,level,cid){
    if (!cmd_access(id,level,cid,1))
        return PLUGIN_HANDLED
    if(!csmod_running){
        console_print(id,"[AMXX] Counter-Strike only. Other mods use the CVAR amx_flamethrower_free to set number of flame bursts")
        return PLUGIN_HANDLED
    }
    if(get_cvar_num("amx_flamethrower_free")){
        console_print(id,"[AMXX] amx_flamethrower_free cvar needs to be 0 to use this command")
        return PLUGIN_HANDLED
    }
    new variable[6]
    new name[32]
    new authid[35]
    get_user_authid(id,authid,34)
    get_user_name(id,name,32)
    read_argv(1,variable,5)

    if(get_cvar_num("amx_flamethrower_buytype") == 1) {
        set_cvar_string("amx_flamethrower_buytype","0")
        console_print(id,"[AMXX] Flamethrower has been set to use ARMOR")
        switch(get_cvar_num("amx_show_activity"))   {
            case 2: client_print(0,print_chat,"ADMIN %s: Set flamethrower to use ARMOR for fuel",name)
            case 1: client_print(0,print_chat,"ADMIN: Set flamethrower to use ARMOR for fuel")
        }
        log_amx("FlameThrower: ^"%s<%d><%s><>^" set flamethrowers_buytype to use armor", name,get_user_userid(id),authid)
    }
    else {
        set_cvar_string("amx_flamethrower_buytype","1")
        console_print(id,"[AMXX] Flamethrower has been set to use MONEY")
        switch(get_cvar_num("amx_show_activity"))   {
            case 2: client_print(0,print_chat,"ADMIN %s: Set flamethrower to use MONEY",name)
            case 1: client_print(0,print_chat,"ADMIN: Set flamethrower to use MONEY")
        }
        log_amx("FlameThrower: ^"%s<%d><%s><>^" set flamethrowers_buytype to use money", name,get_user_userid(id),authid)
    }


    return PLUGIN_HANDLED
}

public amx_fl_c(id,level,cid){
    if (!cmd_access(id,level,cid,1))
        return PLUGIN_HANDLED

    if(!csmod_running){
        console_print(id,"[AMXX] Counter-Strike only. Other mods use the CVAR amx_flamethrower_free to set number of flame bursts")
        return PLUGIN_HANDLED
    }
    if(get_cvar_num("amx_flamethrower_free")){
        console_print(id,"[AMXX] amx_flamethrower_free cvar needs to be 0 to use this command")
        return PLUGIN_HANDLED
    }
    new command[60]
    new variable[6]
    new name[32]
    new authid[35]
    get_user_authid(id,authid,34)
    get_user_name(id,name,32)
    read_argv(0,command,59)
    read_argv(1,variable,5)

    set_cvar_string("amx_flamethrower_cost",variable)
    console_print(id,"[AMXX] %s has been set to %s",command,variable)
    switch(get_cvar_num("amx_show_activity"))   {
        case 2: client_print(0,print_chat,"ADMIN %s: Executed %s %s",name,command,variable)
        case 1: client_print(0,print_chat,"ADMIN: Executed %s %s",command,variable)
    }
    log_amx("FlameThrower: ^"%s<%d><%s><>^" set flamethrowers_cost to %s", name,get_user_userid(id),authid,variable)
    return PLUGIN_HANDLED
}

//This block is for the bots to use the flamethrower
public bot_interface(){

    new sid[8],id
    read_argv(1,sid,7)
    id = str_to_num(sid)

    if(!get_cvar_num("amx_luds_flamethrower") || !is_user_alive(id) || roundfreeze)
        return PLUGIN_HANDLED

    if(get_cvar_num("amx_flamethrower_botsnolimit") == 0){
#if defined CSTRIKE
        new fl_cost = get_cvar_num("amx_flamethrower_cost")
#endif
        new freeF = get_cvar_num("amx_flamethrower_free")
        if((!csmod_running) || (freeF > 0)){
            if(flame_count[id] < 1)
                return PLUGIN_HANDLED
            flame_count[id] -= 1
        }
#if defined CSTRIKE
        else{
            if(get_cvar_num("amx_flamethrower_buytype") == 0){
                new armr = get_user_armor(id)
                if(armr < fl_cost)
                    return PLUGIN_HANDLED
                set_user_armor(id,armr - fl_cost)
            }else{

                new um = cs_get_user_money(id)
                if(um < fl_cost)
                    return PLUGIN_HANDLED
                else
                    cs_set_user_money(id,um - fl_cost)
            }
        }
#endif
    }
    fire_flamethrower(id)
    return PLUGIN_HANDLED
}

//This block is for players to fire the flamethrower
public amx_fflame(id){
    if(!get_cvar_num("amx_luds_flamethrower") || !is_user_alive(id) || roundfreeze)
        return PLUGIN_HANDLED

    new fl_cost = get_cvar_num("amx_flamethrower_cost")
    new freeF = get_cvar_num("amx_flamethrower_free")
    if((!csmod_running) || (freeF > 0)){
        if(flame_count[id] <= 0){
            client_print(id,print_chat,"[AMXX] Insufficient fuel. You have used all your flamethrower blasts")
            return PLUGIN_HANDLED
        }
        flame_count[id] -= 1
        new msg[64]
        format(msg,63,"Flamethrower Bursts Remaning: %d",flame_count[id])
        set_hudmessage(255,0,0, -1.0, 0.25, 0, 0.02, 3.0, 1.01, 1.1, 16)
        show_hudmessage(id,msg)

    }else{
        if(get_cvar_num("amx_flamethrower_buytype") == 0){
            new armr = get_user_armor(id)
            if(armr < fl_cost){
                client_print(id,print_chat,"[AMXX] Insufficient fuel. Flamethrower blasts cost %d armor points each",fl_cost)
                return PLUGIN_HANDLED
            }
            set_user_armor(id,armr - fl_cost)
#if defined CSTRIKE
        }else{
            new um = cs_get_user_money(id)
            if(um < fl_cost){
                client_print(id,print_chat,"[AMXX] Insufficient funds. Flamethrower bursts cost $%d each",fl_cost)
                return PLUGIN_HANDLED
            }else{
                client_print(id,print_center,"[AMXX] You bought flamethrower fuel for $%d.",fl_cost)
                cs_set_user_money(id,um - fl_cost)
            }
#endif
        }
    }
    fire_flamethrower(id)
    return PLUGIN_HANDLED
}

fire_flamethrower(id){
    emit_sound(id, CHAN_WEAPON, "ambience/flameburst1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new vec[3]
    new aimvec[3]
    new velocityvec[3]
    new length
    new speed = 10
    get_user_origin(id,vec)
    get_user_origin(id,aimvec,2)
    new dist = get_distance(vec,aimvec)

    new speed1 = 160
    new speed2 = 350
    new radius = 105

    if(dist < 50){
        radius = 0
        speed = 5
    }
    else if(dist < 150){
        speed1 = speed2 = 1
        speed = 5
        radius = 50
    }
    else if(dist < 200){
        speed1 = speed2 = 1
        speed = 5
        radius = 90
    }
    else if(dist < 250){
        speed1 = speed2 = 90
        speed = 6
        radius = 90
    }
    else if(dist < 300){
        speed1 = speed2 = 140
        speed = 7
    }
    else if(dist < 350){
        speed1 = speed2 = 190
        speed = 7
    }
    else if(dist < 400){
        speed1 = 150
        speed2 = 240
        speed = 8
    }
    else if(dist < 450){
        speed1 = 150
        speed2 = 290
        speed = 8
    }
    else if(dist < 500){
        speed1 = 180
        speed2 = 340
        speed = 9
    }

    velocityvec[0]=aimvec[0]-vec[0]
    velocityvec[1]=aimvec[1]-vec[1]
    velocityvec[2]=aimvec[2]-vec[2]
    length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
    velocityvec[0]=velocityvec[0]*speed/length
    velocityvec[1]=velocityvec[1]*speed/length
    velocityvec[2]=velocityvec[2]*speed/length

    new args[8]
    args[0] = vec[0]
    args[1] = vec[1]
    args[2] = vec[2]
    args[3] = velocityvec[0]
    args[4] = velocityvec[1]
    args[5] = velocityvec[2]
    set_task(0.1,"te_spray",0,args,8,"a",2)
    check_burnzone(id,vec,aimvec,speed1,speed2,radius)
}

public te_spray(args[]){

    //TE_SPRAY
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte (120) // Throws a shower of sprites or models
    write_coord(args[0]) // start pos
    write_coord(args[1])
    write_coord(args[2])
    write_coord(args[3]) // velocity
    write_coord(args[4])
    write_coord(args[5])
    write_short (fire) // spr
    write_byte (8) // count
    write_byte (70) // speed
    write_byte (100) //(noise)
    write_byte (5) // (rendermode)
    message_end()

    return PLUGIN_CONTINUE
}


public sqrt(num) {
    new div = num
    new result = 1
    while (div > result) { // end when div == result, or just below
        div = (div + result) / 2 // take mean value as new divisor
        result = num / div
    }
    return div
}

check_burnzone(id,vec[],aimvec[],speed1,speed2,radius)
{
    server_print "BURN ZONE"
    new maxplayers = get_maxplayers()+1
    new tid, tbody
    get_user_aiming(id,tid,tbody,550)
    if((tid > 0) && (tid < maxplayers))
    {
        server_print "PLAYER IN RANGE"
        new ffcvar = get_pcvar_num(g_teams)
        if(ffcvar)
        {
            if( (ffcvar == 0) || ((ffcvar == 1) && (get_cvar_num("amx_flamethrower_obeyffcvar") == 0)) )
            {
                if(get_user_team(tid) != get_user_team(id))
                {
                    burn_victim(tid,id,0)
                    server_print "SHOULD START BURNING NOW"
                }
            }
            else
            {
                if(get_user_team(tid) == get_user_team(id))
                    burn_victim(tid,id,1)
                else
                {
                    burn_victim(tid,id,0)
                    server_print "SHOULD START BURNING NOW"
                }
            }

        }
        else
        {
            burn_victim(tid,id,0)
            server_print "SHOULD START BURNING NOW"
        }

    }

    new burnvec1[3],burnvec2[3],length1

    burnvec1[0]=aimvec[0]-vec[0]
    burnvec1[1]=aimvec[1]-vec[1]
    burnvec1[2]=aimvec[2]-vec[2]

    length1=sqrt(burnvec1[0]*burnvec1[0]+burnvec1[1]*burnvec1[1]+burnvec1[2]*burnvec1[2])
    burnvec2[0]=burnvec1[0]*speed2/length1
    burnvec2[1]=burnvec1[1]*speed2/length1
    burnvec2[2]=burnvec1[2]*speed2/length1
    burnvec1[0]=burnvec1[0]*speed1/length1
    burnvec1[1]=burnvec1[1]*speed1/length1
    burnvec1[2]=burnvec1[2]*speed1/length1
    burnvec1[0] += vec[0]
    burnvec1[1] += vec[1]
    burnvec1[2] += vec[2]
    burnvec2[0] += vec[0]
    burnvec2[1] += vec[1]
    burnvec2[2] += vec[2]

    new origin[3]
    for (new i=1; i<=maxplayers; i++)
    {
        new ffcvar = get_pcvar_num(g_teams)
        if(ffcvar)
        {
            if( (ffcvar == 0) || ((ffcvar == 1) && (get_cvar_num("amx_flamethrower_obeyffcvar") == 0)) )
            {
                if(get_user_team(i) != get_user_team(id)){
                    if((is_user_alive(i) == 1) && (i != id)){
                        get_user_origin(i,origin)
                        if(get_distance(origin,burnvec1) < radius)
                            burn_victim(i,id,0)
                        else if(get_distance(origin,burnvec2) < radius)
                            burn_victim(i,id,0)
                    }
                }

            }
            else
            {
                if((is_user_alive(i) == 1) && (i != id))
                {
                    get_user_origin(i,origin)
                    if(get_user_team(i) == get_user_team(id)){
                        if(get_distance(origin,burnvec1) < radius)
                            burn_victim(i,id,1)
                        else if(get_distance(origin,burnvec2) < radius)
                            burn_victim(i,id,1)
                    }else{
                        if(get_distance(origin,burnvec1) < radius)
                            burn_victim(i,id,0)
                        else if(get_distance(origin,burnvec2) < radius)
                            burn_victim(i,id,0)
                    }
                }
            }
        }
        else
        {
            if((is_user_alive(i) == 1) && (i != id))
            {
                get_user_origin(i,origin)
                if(get_distance(origin,burnvec1) < radius)
                    burn_victim(i,id,0)
                else if(get_distance(origin,burnvec2) < radius)
                    burn_victim(i,id,0)

            }
        }

    }
    return PLUGIN_CONTINUE
}

burn_victim(id,killer,tk){
    server_print "SHOULD BE BURNING NOW"
    if(isburning[id] == 1)
        return PLUGIN_CONTINUE

    isburning[id] = 1

    emit_sound(id, CHAN_ITEM, "ambience/burning1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

    new hp,args[4]
    hp = get_user_health(id)
    if(hp > 250)
        hp = 250
    args[0] = id
    args[1] = killer
    args[2] = tk
    set_task(0.3,"on_fire",451,args,4,"a",hp / 10)
    set_task(0.7,"fire_scream",0,args,4)
    set_task(5.5,"stop_firesound",0,args,4)

    if(tk == 1)
    {
        new namea[32]
        get_user_name(killer,namea,31)
        new teama[32]
        get_user_team(killer,teama,31)
        new players[32],pNum
        get_players(players,pNum,"e",teama)
        for(new i=0;i<pNum;i++)
            client_print(players[i],print_chat,"%s  attacked a teammate",namea)
        new punish1 = get_cvar_num("amx_flamethrower_tkpunish1")
        new punish2 = get_cvar_num("amx_flamethrower_tkpunish2")
        if(punish1 > 2){
            user_kill(killer,0)
            set_hudmessage(255,50,50, -1.0, 0.45, 0, 0.02, 10.0, 1.01, 1.1, 16)
            show_hudmessage(killer,"YOU WERE KILLED^nFOR ATTACKING TEAMMATES.^nSEE THAT IT HAPPENS NO MORE!")
        }
        tkcount[killer] +=1
        if((punish1) && (tkcount[killer] > punish2 - 1)){
            if(punish1 == 1 || punish1 == 3)
                client_cmd(killer,"echo You were kicked for team killing;disconnect")
            else if(punish1 == 2 || punish1 == 4){
                client_cmd(killer,"echo You were banned for team killing")
                new authida[35]
                get_user_authid(killer,authida,34)
                if (equal("4294967295",authida)){
                    new ipa[32]
                    get_user_ip(killer,ipa,31,1)
                    server_cmd("addip 180.0 %s;writeip",ipa)
                }else{
                    server_cmd("banid 180.0 %s kick;writeid",authida)
                }
            }
        }
    }
    return PLUGIN_CONTINUE
}

public on_fire(args[]){

    new hp,rx,ry,rz,forigin[3]
    new id = args[0]
    new killer = args[1]
    new tk = args[2]
    new headshot = args[3]

    if(isburning[id] == 0)
        return PLUGIN_CONTINUE

    rx = random_num(-30,30)
    ry = random_num(-30,30)
    rz = random_num(-30,30)
    get_user_origin(id,forigin)

    //TE_SPRITE - additive sprite, plays 1 cycle
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte( 17 )
    write_coord(forigin[0]+rx) // coord, coord, coord (position)
    write_coord(forigin[1]+ry)
    write_coord(forigin[2]+10+rz)
    write_short( burning ) // short (sprite index)
    write_byte( 30 ) // byte (scale in 0.1's)
    write_byte( 200 ) // byte (brightness)
    message_end()

    //Smoke
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte( 5 )
    write_coord(forigin[0]+(rx*2)) // coord, coord, coord (position)
    write_coord(forigin[1]+(ry*2))
    write_coord(forigin[2]+100+(rz*2))
    write_short( smoke )// short (sprite index)
    write_byte( 60 ) // byte (scale in 0.1's)
    write_byte( 15 ) // byte (framerate)
    message_end()

    if(is_user_alive(id) == 0)
        return PLUGIN_CONTINUE

    hp = get_user_health(id)

    if((hp - 10) > 0)
    {
        set_user_health(id,hp - 10)
    }
    else
    {
        new namek[32],namev[32],authida[35],authidv[35],teama[32],teamv[32]
        get_user_name(id,namev,31)
        get_user_name(killer,namek,31)
        get_user_authid(id,authidv,34)
        get_user_authid(killer,authida,34)
        get_user_team(id,teamv,31)
        get_user_team(killer,teama,31)

        //Log the Kill
        log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"flamethrower^"",
            namek,get_user_userid(killer),authida,teama,namev,get_user_userid(id),authidv,teamv)

        //Print message to clients
        client_print(id,print_chat,"[AMXX] You were killed by %s's Flame Thrower",namek)
        client_print(killer,print_chat,"[AMXX] You killed %s with your Flame Thrower",namev)

        if(tk == 1)
        {
            client_print(killer,print_center,"You killed a teammate")
            set_user_frags(killer,get_user_frags(killer) - 1)
        }
        else
        {
            set_user_frags(killer,get_user_frags(killer) + 1)
        }

        //Kill the victim and block the messages
        set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
        set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
        fakedamage(id,"Flame Thrower",50.0,DMG_SLOWBURN|DMG_NEVERGIB)
        //Makes them stop burning
        isburning[id] = 0

        //Update killers scorboard with new info
        emessage_begin(MSG_BROADCAST,gmsgScoreInfo)
        ewrite_byte(killer)
        ewrite_short(get_user_frags(killer))
        #define DEATHS 422
        new living = get_pdata_int(killer, DEATHS)
        ewrite_short(living)
        if(csmod_running)
        {
            ewrite_short(0)
            ewrite_short(get_user_team(killer))
        }
        emessage_end()

        //Update victims scoreboard with correct info
        emessage_begin(MSG_BROADCAST,gmsgScoreInfo)
        ewrite_byte(id)
        ewrite_short(get_user_frags(id))
        new dead = get_pdata_int(id, DEATHS)
        ewrite_short(dead)
        if(csmod_running)
        {
            ewrite_short(0)
            ewrite_short(get_user_team(id))
        }
        emessage_end()

        //Replaced HUD death message
        emessage_begin( MSG_BROADCAST, gmsgDeathMsg,{0,0,0},0)
        ewrite_byte(killer)
        ewrite_byte(id)

        if(csmod_running)
            ewrite_byte(headshot);
        if (get_pcvar_num(g_teams) == 1 || csmod_running
        &&
        equal(teama,teamv))
            ewrite_string("teammate");
        else
        ewrite_string("flamethrower")
        emessage_end()

    }
    return PLUGIN_CONTINUE
}

public fire_scream(args[]){
    emit_sound(args[0], CHAN_AUTO, "scientist/c1a0_sci_catscream.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    return PLUGIN_CONTINUE
}

public stop_firesound(args[]){
    isburning[args[0]] = 0
    emit_sound(args[0], CHAN_ITEM, "vox/_period.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    return PLUGIN_CONTINUE
}

public HandleSay(id) {
    new Speech[192]
    read_args(Speech,192)
    remove_quotes(Speech)

    if (!equal(Speech,"vote",4) && ((containi(Speech, "fire") != -1) || (containi(Speech, "flam") != -1))){
        if(get_cvar_num("amx_luds_flamethrower") == 1)
            client_print(id,print_chat, "[AMXX] Flamethrowers enabled -  For help say /flame")
        else
            client_print(id,print_chat, "[AMXX] Flamethrowers disabled")
    }
    return PLUGIN_CONTINUE
}

public client_connect(id){
    isburning[id] = 0
    tkcount[id] = 0
    flame_count[id] = get_cvar_num("amx_flamethrower_free")
    return PLUGIN_CONTINUE
}

#if !defined client_disconnect
#define client_disconnected client_disconnect
#endif

public client_disconnected(id)
{
    isburning[id] = 0
    tkcount[id] = 0
    return PLUGIN_CONTINUE
}

public new_spawn(id){
    isburning[id] = 0
    new freeF = get_cvar_num("amx_flamethrower_free")
    if((!csmod_running) || (freeF > 0))
        flame_count[id] = freeF
    return PLUGIN_CONTINUE
}

public round_start() {
    roundfreeze = false
    for (new k = 1; k <= get_maxplayers(); k++) {
        isburning[k] = 0
        new freeF = get_cvar_num("amx_flamethrower_free")
        if(freeF > 0)
            flame_count[k] = freeF
    }
}

public round_end() {
    roundfreeze = false
}

/************************************************************
* MOTD Popups
************************************************************/

public flamet_motd(id){

    new len = 1024
    new buffer[1025]
    new n = 0
    new buytype[32]

    if (get_cvar_num("amx_flamethrower_buytype") == 1)
        buytype = "dollars"
    else
        buytype = "armor points"

#if !defined NO_STEAM
    n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>")
#endif

    n += copy( buffer[n],len-n,"To use your flame thrower gun have to bind a key to:^n^n")
    n += copy( buffer[n],len-n,"amx_fire_flamethrower^n^n")
    n += copy( buffer[n],len-n,"In order to bind a key you must open your console and use the bind command: ^n^n")
    n += copy( buffer[n],len-n,"bind ^"key^" ^"command^" ^n^n")

    n += copy( buffer[n],len-n,"In this case the command is ^"amx_fire_flamethrower^".  Here are some examples:^n^n")
    n += copy( buffer[n],len-n,"    bind f amx_fire_flamethrower         bind MOUSE3 amx_fire_flamethrower^n^n")

    n += copy( buffer[n],len-n,"Information:^n")
    n += copy( buffer[n],len-n,"- The Flame Thrower can enabled/disabled by admins or votes.^n")

    n += format( buffer[n],len-n,"- Each Flame Thrower burst costs you %d %s.^n", get_cvar_num("amx_flamethrower_cost"), buytype )

    if (get_cvar_num("amx_flamethrower_buytype") == 0)
        n += copy( buffer[n],len-n,"- You need to buy armor to use the Flame Thrower^n")

    n += copy( buffer[n],len-n,"^nThe flamethrower, while not having a long range, does not by^n")
    n += copy( buffer[n],len-n,"nature require a high degree of accuracy and is thus very^n")
    n += copy( buffer[n],len-n,"effective and highly lethal at short range against members^n")
    n += copy( buffer[n],len-n,"of the opposite team.")

#if !defined NO_STEAM
    n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

    show_motd(id, buffer, "Flamethrower Help:")
    return PLUGIN_CONTINUE
}

/************************************************************
* CORE PLUGIN FUNCTIONS
************************************************************/

public plugin_init(){
    register_plugin("Flame Thrower","5.3.7","SPINX") //original by EJL. Port to Amxx EJL
    register_concmd("amx_flamethrowers","amx_fl",ADMIN_LEVEL_H,"- toggles flamethrowers on and off")
    register_concmd("amx_flamethrowers_cost","amx_fl_c",ADMIN_LEVEL_H,"- sets flamethrowers cost in money or armor amount")
    register_concmd("amx_flamethrowers_buytype","amx_fl_b",ADMIN_LEVEL_H,"- toggles flamethrowers buytype between armor and money")
    register_clcmd("amx_fire_flamethrower","amx_fflame",0,"- shoots the flame thrower if the plugin is enabled")
    register_clcmd("say /flamethrower","flamet_motd")
    register_clcmd("say /flame","flamet_motd")
    register_clcmd("say","HandleSay")
    register_cvar("amx_luds_flamethrower","1",FCVAR_SERVER)
    register_cvar("amx_flamethrower_cost","30")
    register_cvar("amx_flamethrower_buytype","0")
    register_cvar("amx_flamethrower_free","0")
    register_cvar("amx_flamethrower_tkpunish1","1")
    register_cvar("amx_flamethrower_tkpunish2","3")
    register_cvar("amx_flamethrower_obeyffcvar","1")
    register_cvar("amx_flamethrower_botsnolimit","1")
    csmod_running = cstrike_running() ? true : false

    g_teams            = !csmod_running ? get_cvar_pointer("mp_teamplay") : get_cvar_pointer("mp_friendlyfire")

    register_event("ResetHUD", "new_spawn", "b")
    register_srvcmd("bot_flamethrower","bot_interface")

    if(csmod_running)
    {
        register_logevent("round_start", 2, "1=Round_Start")
        register_logevent("round_end", 2, "1=Round_End")
    }
    gmsgDeathMsg = get_user_msgid("DeathMsg")
    gmsgScoreInfo = get_user_msgid("ScoreInfo")
}

public plugin_precache(){
    fire = precache_model("sprites/explode1.spr")
    precache_generic("sprites/explode1.spr")
    smoke = precache_model("sprites/steam1.spr")
    precache_generic("sprites/steam1.spr")
    burning = precache_model("sprites/xfire.spr")
    precache_generic("sprites/xfire.spr")
    precache_sound("ambience/burning1.wav")
    precache_generic("sound/ambience/burning1.wav")
    precache_sound("ambience/flameburst1.wav")
    precache_generic("sound/ambience/flameburst1.wav")
    precache_sound("scientist/c1a0_sci_catscream.wav")
    precache_generic("sound/scientist/c1a0_sci_catscream.wav")
    precache_sound("vox/_period.wav")
    precache_generic("sound/vox/_period.wav")
}
