/*
*   Half-Life GunGame plugin by serfreeman1337
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/
/*
*   Thanks:
*       Safety1st
*       KORD_12.7
*       ET^NiK
*/
/*
*   Translators:
*       Safety1st - English.
*       ACM1PT - Spanish.
*/
/*
* More information:
*
*  http://gf.hldm.org/hl-gungame/ - serfreeman1337's site
*  http://aghl.ru/forum/viewtopic.php?f=19&t=702 - Russian HL and AG Community
*  https://forums.alliedmods.net/showthread.php?t=180714 - Official AMXX forum
*/
#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#define PLUGIN "Half-Life GunGame"
#define VERSION "2.7"
#define AUTHOR "SPiNX|serfreeman1337"   // ICQ: 50429042
#define LASTUPDATE  "7, Mar (27), 2023"
#define MAX_PLAYERS                32
#if !defined get_cvar_bool
#define get_pcvar_bool get_pcvar_num
#define get_cvar_bool get_cvar_num
#endif
// Enable detection and usage of color codes in notify messages
// This is only for AGHL.ru client.dll and RCD
//#define AGHL_COLOR
// Enable support for Half-Life Weapon Mod by KORD_12.7
// ---> http://aghl.ru/forum/viewtopic.php?f=42&t=721
//#define HLWPNMOD
// Enable if you using Sturmbot for Day Of Defeat
// This prevents bot from staying in spectator
//#define DODBOTFIX
// Enable colorchat support for Counter-Strike
// Don't forget to replace gungame_cstrike.txt with your gungame.txt file
//#define CSCOLOR
#define extraoffset_weapon 4
// maximum win sounds
#define WINSOUNDS 15
// -------------------------------------------------------------------------------------------------
#if defined CSCOLOR
// -- CSTRIKE COLOR -- //
#if AMXX_VERSION_NUM < 183
#include <colorchat>
#define print_team_default DontChange
#define print_team_grey Grey
#define print_team_red Red
#define print_team_blue Blue
#endif
new const chatTeamColor[] = {
    print_team_grey,
    print_team_red,
    print_team_blue
}
#undef AGHL_COLOR
#endif
new task_Refill_Id
new task_Refill_Max
new task_Hud_Id
new task_Icon_Blink
new task_Equip_Id
new task_Change_Id
new task_WarmUp_Id
new task_ProLevel_Id = 3446
new task_EntRemove_Id = 3447
#if defined AGHL_COLOR
new task_RequestColor_Id
#endif
// -- DATA STRUCTS -- //
enum _:weaponAmmoStruct {
    WAMMO_PRIMARY_AMMOID,
    WAMMO_SECONDARY_AMMOID,
    WAMMO_PRIMARY_MAXAMMO,
    WAMMO_SECONDARY_MAXAMMO
}
enum _:dataOffsetsStruct {
    m_pPlayer,
    m_iClip,
    m_pActiveItem,
    m_rgAmmo,
    offsetAmmoDiff,
    msgWeaponList
}
// this is for level settings parse
enum _:keyNames {
    KEYSET_SHOWNAME,
    KEYSET_KILLS,
    KEYSET_SKIP,
    KEYSET_REFIL_TIME_1,
    KEYSET_REFIL_AMMOUNT_1,
    KEYSET_DISABLE_FULLAMO_1,
    KEYSET_REFIL_TIME_2,
    KEYSET_REFIL_AMMOUNT_2,
    KEYSET_DISABLE_FULLAMO_2,
    KEYSET_CLIP,
    KEYSET_ICONSPRITE,
    KEYSET_BOTCANT
}
enum _:playersDataStruct {
    PLAYER_CURRENTLEVEL,
    PLAYER_LASTLEVEL,
    PLAYER_KILLS,
    PLAYER_NEEDKILLS,
    PLAYER_WEAPONNAME[MAX_PLAYERS],
    PLAYER_RANKPOS,
    PLAYER_ICON[MAX_PLAYERS],
    PLAYER_TEAM,
    Trie:PLAYER_INFLICTORS,
    Trie:PLAYER_NOREFIL,
    bool:PLAYER_BOT,
    #if defined AGHL_COLOR && !defined CSCOLOR
    bool:PLAYER_AGHL
    #endif
}
enum _:weaponSetStruct {
    WSET_SHOWNAME[MAX_PLAYERS],
    WSET_KILLS,
    WSET_SKIP,
    WSET_ICONSPRITE[MAX_PLAYERS],
    Array:WSET_EQUIP_ITEMS,
    Trie:WSET_INFLICTORS_MAP,
    Array:WSET_INFARRAY,
    Trie:WSET_NOREFIL_MAP,
    bool:WSET_BOTCANT
    #if defined HLWPNMOD
    ,bool:WSET_WPNMOD
#endif
}
enum _:equipStruct {
    EQUIP_NAME[MAX_PLAYERS],
    EQUIP_CLIP,
    Float:EQUIP_PRIMARY_REFIL_TIME,
    Float:EQUIP_SECONDARY_REFIL_TIME,
    EQUIP_PRIMARY_REFIL_AMMOUNT,
    EQUIP_SECONDARY_REFIL_AMMOUNT,
    bool:EQUIP_FULL_PRIMARY,
    bool:EQUIP_FULL_SECONDARY,
}
enum _:autoSaveStruct {
    ASAVE_LEVEL,
    ASAVE_KILLS,
    Float:ASAVE_TIME
}
enum _:refilTaskStruct {
    REFIL_PLAYERID,
    REFIL_WEAPONID,
    REFIL_AMMOID,
    REFIL_AMMOUNT,
    REFIL_MAXAMMO,
    REFIL_TASKID
}
enum _:cvars {
    CVAR_SOUND_WINNER,
    CVAR_SOUND_LEVELUP,
    CVAR_SOUND_LEVELDOWN,
    CVAR_UPARMOR,
    CVAR_DESCORE,
    CVAR_AUTOSAVE,
    CVAR_ENDGAME_DELAY,
    CVAR_SHOWSTATS,
    CVAR_STATS_COLOR,
    CVAR_STATS_POS,
    CVAR_MAPCHOOSER_TYPE,
    CVAR_MAPCHANGES_STYLE,
    CVAR_NEARLEVEL,
    CVAR_INFORMER_DISPLAY,
    CVAR_INFORMER_POS,
    CVAR_INFORMER_COLOR,
    CVAR_INFORMER_HOLDTIME,
    CVAR_CHAT_MESSAGE,
    CVAR_RESTORE_HP,
    CVAR_DEFAULT_HP,
    CVAR_DEFAULT_AP,
    CVAR_INFLICTORS_NODAMAGE,
    CVAR_ICON,
    CVAR_ICON_BLINKTIME,
    CVAR_ICON_COLOR,
    CVAR_ICON_BLINKCOLOR1,
    CVAR_ICON_BLINKCOLOR2,
    CVAR_HANDICAP,
    CVAR_WARMUP,
    CVAR_PROLEVEL_MUSIC,
    // 2.1
    CVAR_ENABLED,
    CVAR_CFGFILE,
    CVAR_TEAMPLAY,
    CVAR_TEAMMULGOAL,
    CVAR_MAPCHANGE_CMD
}
enum _:informerDisplay {
    INF_TPL_WEAPON,
    INF_TPL_LEVEL,
    INF_TPL_MAXLEVEL,
    INF_TPL_SAMELEVEL,
    INF_TPL_KILLS,
    INF_TPL_NEEDKILLS,
    INF_TPL_RANK,
    INF_TPL_RANKNUM,
    INF_TPL_LEADER,
    INF_TPL_LWEAPON
}
enum _:notifyType {
    NOTIFY_UP,
    NOTIFY_DOWN,
    NOTIFY_NOW,
    NOTIFY_LAST,
    NOTIFY_SKIP,
    NOTIFY_WIN,
    NOTIFY_ENABLED,
    NOTIFY_DISABLED,
    NOTIFY_TEAMUP,
    NOTIFY_TEAMWIN,
    NOTIFY_TEAMLAST
}
// -- DATAS -- //
new offsetsForMe[dataOffsetsStruct][] = { // offsets names
    "m_pPlayer",
    "m_iClip",
    "m_pActiveItem",
    "m_rgAmmo",
    "offsetAmmoDiff",
    "msgWeaponList"
}
new informerTplKeys[informerDisplay][] = {
    "<weapon>",
    "<level>",
    "<maxlevel>",
    "<samelevel>",
    "<kills>",
    "<needkills>",
    "<rank>",
    "<ranknum>",
    "<leader>",
    "<lweapon>"
}
new informerBitSum
new setKeys[keyNames][] = {
    "name",
    "kills",
    "skip",
    "refil_time_1",
    "refil_ammount_1",
    "disable_fullammo_1",
    "refil_time_2",
    "refil_ammount_2",
    "disable_fullammo_2",
    "clip",
    "icon",
    "botcant"
}
new cvar[cvars];
new modOffsets[dataOffsetsStruct]
new Trie:weaponAmmoTrie
new Trie:ammoMaxMap
new Trie:autoSaveMap
new Array:weaponSets
new playersData[MAX_PLAYERS + 1][playersDataStruct]
new bool:isValve
new bool:isAG
new StatusIcon
new ScreenFade
new AmmoPickup
new AmmoX
new WeapPickup
new currentPlayers
#if !defined MaxClients
    static MaxClients
#endif
new maxLevel
new bool:isEndGame = false
new bool:isVoteStarted = false
new leader_name[MAX_PLAYERS] = "--"
new wp_leader[MAX_PLAYERS] = "--"
new striper
new Float:autoSaveTime
new warmUpMode = 0
new Array:warmUpSet
new cfgFileWas[30]
// leet sound
new sound_winner[MAX_RESOURCE_PATH_LENGTH],
sound_levelup[MAX_RESOURCE_PATH_LENGTH],
sound_leveldown[MAX_RESOURCE_PATH_LENGTH],
prolevel_music[MAX_RESOURCE_PATH_LENGTH];
new Float:proLevelLoop
new bool:proLevelPlayed = false
// -- HUD -- //
new informerColor[3],Float:informerPos[2]
new syncInformerHud
new endHudColor[3],Float:endHudPos[3]
new Float:holdTime
// -- ICON -- //
new Float:blinkTime
new iconColors[9]
// -- CHAT -- //
new chatInformerBitsum
// -- API -- //
new fwdRet // dummy var
new fwdWin,fwdLevelUp,fwdWarmUpStart,fwdWarmUpEnd
new fwdState,fwdEquip
// -- EFFECTS -- //
new noDmgSnds[][] = {
    "weapons/electro4.wav",
    "weapons/electro5.wav",
    "weapons/electro6.wav"
}
public Array:ggblockedItems
#if defined HLWPNMOD
// -- WPNMOD -- //
#include <hl_wpnmod>
new Trie:wpnModMap

stock wpnmod_give_item(const iPlayer, const szItem[])
{
    new Float: vecOrigin[3];
    pev(iPlayer, pev_origin, vecOrigin);
    new iItem = wpnmod_create_item(szItem, vecOrigin);
    if(is_valid_ent(iItem))
    {
        entity_set_int(iItem, EV_INT_spawnflags, entity_get_int(iItem,EV_INT_spawnflags) | SF_NORESPAWN);
        dllfunc(DLLFunc_Touch,iItem,iPlayer)
        return iItem;
    }
    return -1;
}
#endif
// Sound Precache
public plugin_precache()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    task_Refill_Id = 100
    task_Refill_Max = 4 // maximum number of refil tasks per player
    task_Hud_Id = task_Refill_Id + (task_Refill_Max * 33)
    task_Icon_Blink = task_Hud_Id + 33
    task_Equip_Id = task_Icon_Blink + 33
    task_Change_Id = task_Equip_Id + 33
    task_WarmUp_Id = task_Change_Id + 33
    // we are ninjas
    //
    // end game music
    // separate with semicolon
    //
    cvar[CVAR_SOUND_WINNER] = register_cvar("gg_sound_winner","media/Half-Life03.mp3;media/Half-Life08.mp3;media/Half-Life11.mp3;media/Half-Life17.mp3")
    //
    // level up and level down sounds
    // leave empty for disable this feature
    //
    cvar[CVAR_SOUND_LEVELUP] = register_cvar("gg_sound_levelup","debris/beamstart5.wav")
    cvar[CVAR_SOUND_LEVELDOWN] = register_cvar("gg_sound_leveldown","debris/beamstart5.wav")
    //
    // bonus armor value on levelup
    // player has 1 for 3 chance to get bonus armor
    //
    cvar[CVAR_UPARMOR] = register_cvar("gg_uparmor","30")
    //
    // allows/disallows level down for selfkill
    //
    cvar[CVAR_DESCORE] = register_cvar("gg_descore","1")
    //
    // auto save function
    // plugin will rembemer player kills and level after disconnect
    //
    cvar[CVAR_AUTOSAVE] = register_cvar("gg_autosave","300.0")
    //
    // end game delay time
    // TODO: check out how it works XD
    //
    cvar[CVAR_ENDGAME_DELAY] = register_cvar("gg_endgame_delay","15")
    // information messages
    cvar[CVAR_SHOWSTATS] = register_cvar("gg_showstats", "1")
    //
    // end game hud color
    //  r g b
    //
    cvar[CVAR_STATS_COLOR] = register_cvar("gg_stats_color","255 255 0")
    //
    // end game hud pos
    //  x y
    //
    cvar[CVAR_STATS_POS] = register_cvar("gg_stats_pos","0.73 0.40")
    //
    // map change style
    //  0 - no vote, just change to nextmap
    //  1 - start vote at end of the game
    //  2 - start vote if someone reaches pre end level
    //
    cvar[CVAR_MAPCHANGES_STYLE] = register_cvar("gg_mapchange_style","1")
    //
    // mapchooser you have
    //  0 - auto detect
    //  1 - Galileo
    //  2 - default amxx mapchooser
    //  3 - use custom command
    //  4 - Deagle's Map Manager
    //
    cvar[CVAR_MAPCHOOSER_TYPE] = register_cvar("gg_mapchooser_type","0")
    //
    // for mapchange style 2 sets near level from max level to start vote
    //
    cvar[CVAR_NEARLEVEL] = register_cvar("gg_startvote_nearlevel","2")
    //
    // hud informer display
    //  0 - off
    //  1 - on
    //
    cvar[CVAR_INFORMER_DISPLAY] = register_cvar("gg_informer_display","1")
    //
    // hud informer position
    //
    cvar[CVAR_INFORMER_POS] = register_cvar("gg_informer_pos","-1.0 0.97")
    //
    // hud informer color
    //
    cvar[CVAR_INFORMER_COLOR] = register_cvar("gg_informer_color","128 255 0")
    //
    // hud informer hold time
    //
    cvar[CVAR_INFORMER_HOLDTIME] = register_cvar("gg_informer_holdtime","20.0")
    //
    // enable chat messages bitsumm
    //  a - level up message
    //  b - level down message
    //  c - level now message
    //  d - reached last level notify
    //  e - level skip message
    //  f - winner message
    //  g - enable message
    //  h - disable message
    //
    cvar[CVAR_CHAT_MESSAGE] = register_cvar("gg_chat_messages","abcdefgh")
    //
    // restore hp on levelup
    //
    cvar[CVAR_RESTORE_HP]=  register_cvar("gg_restore_hp","1")
    //
    // default hp
    //
    cvar[CVAR_DEFAULT_HP] = register_cvar("gg_default_hp","100")
    //
    // default ap
    //
    cvar[CVAR_DEFAULT_AP] = register_cvar("gg_default_ap","100")
    //
    // enables status icon of current weapon
    //  only if current mod supports StatusIcon message
    //
    cvar[CVAR_ICON] = register_cvar("gg_icon_enable","1")
    //
    // weapon icon color
    //  r g b
    //
    cvar[CVAR_ICON_COLOR] = register_cvar("gg_icon_color","255 127 0")
    //
    // weapon icon blink time on level time
    //  sets the time which weapon icon will blink for level up
    cvar[CVAR_ICON_BLINKTIME] = register_cvar("gg_icon_blink","3.0")
    //
    // blink color 1
    //  r g b
    //
    cvar[CVAR_ICON_BLINKCOLOR1] = register_cvar("gg_icon_blink1","45 215 255")
    //
    // blink color 2
    //  r g b
    //
    cvar[CVAR_ICON_BLINKCOLOR2] = register_cvar("gg_icon_blink2","255 0 0")
    //
    // handicap mode
    //  0 - disable
    //  1 - new player will have average level of all players
    //  2 - new player will have lowest level of all players
    //
    cvar[CVAR_HANDICAP] = register_cvar("gg_handicap_on","1")
    //
    // warmup mode
    //  specify time of warump round duration
    //  user 0.0 for disable this opiton
    //
    cvar[CVAR_WARMUP] = register_cvar("gg_warmup","20")
    //
    // endlevel music
    //  sets music which will be played when someone need one kill to win
    //  leave blank for disable
    //      only mp3 files is supported
    //  you can also loop music to play, for example:
    //                          media/csgo02.mp3 21.4
    //                              this will loop csgo02.mp3 file for 21.4 seconds
    //
    cvar[CVAR_PROLEVEL_MUSIC] = register_cvar("gg_prolevel_music","")
    //
    // enable disable gungame on start
    //
    cvar[CVAR_ENABLED] = register_cvar("gg_enabled","1")
    //
    // teamplay mode
    //
    cvar[CVAR_TEAMPLAY] = register_cvar("gg_teamplay","0")
    //
    // required kills multipler for all weapons for teamplay mode
    //
    cvar[CVAR_TEAMMULGOAL] = register_cvar("gg_teamplay_multigoal","2")
    //
    // default cfg file name
    //
    cvar[CVAR_CFGFILE] = register_cvar("gg_cfg_file","gungame.ini")
    //
    // custom map change command
    //
    cvar[CVAR_MAPCHANGE_CMD] = register_cvar("gg_mapchange_cmd","amx_votenextmap")
    load_cfg()
    // load multiply sounds

    new winnerSnd[256]
    get_pcvar_string(cvar[CVAR_SOUND_WINNER],winnerSnd,charsmax(winnerSnd))

    new ePos,stPos,i
    new winSnds[WINSOUNDS][sizeof sound_winner]

    if(winnerSnd[0])
    {
        do
        {
            ePos = strfind(winnerSnd[stPos],";")
            formatex(winSnds[i++],ePos,winnerSnd[stPos])
            if(i >= WINSOUNDS)
            break
            stPos += ePos + 1
        }
        while (ePos != -1)
        ePos = random(i)
        copy(sound_winner,charsmax(sound_winner),winSnds[ePos])
        precache_generic(sound_winner)
        /*
        if(file_exists(winSnds[ePos])){
        copy(sound_winner,charsmax(sound_winner),winSnds[ePos])
        precache_generic(sound_winner)
        }else{
        log_amx("WARNING! Can't find ^"%s^" sound file! Win music is disabled.",
        winSnds[ePos])
        }
        */
    }
    get_pcvar_string(cvar[CVAR_PROLEVEL_MUSIC],winnerSnd,charsmax(winnerSnd))
    for(i = 0 ; i < WINSOUNDS ; ++i)
    arrayset(winSnds[i],0,sizeof sound_winner)
    i = 0
    ePos = 0
    stPos = 0
    if(winnerSnd[0])
    {
        do
        {
            ePos = strfind(winnerSnd[stPos],";")
            formatex(winSnds[i++],ePos,winnerSnd[stPos])
            if(i >= WINSOUNDS)
            break
            stPos += ePos + 1
        }
        while (ePos != -1)
        new snd[128],loop[10]
        parse(winSnds[random(i)],snd,charsmax(snd),loop,charsmax(loop))
        proLevelLoop = str_to_float(loop)
        if(file_exists(snd))
        {
            copy(prolevel_music,charsmax(prolevel_music), snd)
            precache_generic(prolevel_music)
        }
        else
        {
            log_amx("WARNING! Can't find ^"%s^" sound file! End level music is disabled.", snd)
        }
    }
    get_pcvar_string(cvar[CVAR_SOUND_LEVELUP],sound_levelup,charsmax(sound_levelup))
    get_pcvar_string(cvar[CVAR_SOUND_LEVELDOWN],sound_leveldown,charsmax(sound_leveldown))
    if(sound_levelup[0])
        precache_generic(sound_levelup)
    if(sound_leveldown[0])
        precache_generic(sound_leveldown)
    if(modOffsets[msgWeaponList] > 0) // register weapon list
        register_message(modOffsets[msgWeaponList],"MSG_WeaponList")
    for(new i ; i < sizeof noDmgSnds ; ++i)
    precache_sound(noDmgSnds[i])
}
public plugin_init()
{
    register_cvar("gungame", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED)
    register_dictionary("gungame.txt")
}
public OnAutoConfigsBuffered()
    console_cmd 0, "gg_enable" //stops game being stuck on 24/7.
///cvar gg_enabled 1 in server.cfg might be unstable!!

new gameName[MAX_RESOURCE_PATH_LENGTH] = "Unknown"
new bool:modFound = false
new ggActive
public plugin_cfg()
{
    server_print "^n^n^n   Half-Life GunGame Copyright (c) 2014-2023 %s^n",AUTHOR
    server_print "   Version %s build on %s^n^n^n", VERSION, LASTUPDATE
    ggActive = get_pcvar_num(cvar[CVAR_ENABLED])
    #if defined AGHL_COLOR && !defined CSCOLOR
    if(isValve)
    {
        task_RequestColor_Id = task_WarmUp_Id + 1
        register_dictionary("gungame_clr.txt")
    }
    #endif
    if(!modOffsets[msgWeaponList])
    {
        new weaponListMsg = get_user_msgid("WeaponList")
        if(!weaponListMsg)
        {
            log_amx("ERROR! Unable to get weapon list!")
            set_fail_state("weapon list retrieve failed")
        }
        register_message(weaponListMsg,"MSG_WeaponList")
    }
    if(get_pcvar_num(cvar[CVAR_ICON]))
    {
        StatusIcon = get_user_msgid("StatusIcon")
        if(!StatusIcon)
        {
            // valve client.dll has StatusIcon
            if(isValve)
            {
                StatusIcon = engfunc(EngFunc_RegUserMsg,"StatusIcon",-1)
                isValve = true
            }
        }
        new tmpStr[MAX_RESOURCE_PATH_LENGTH],parseStr[3][10]
        blinkTime = get_pcvar_float(cvar[CVAR_ICON_BLINKTIME])
        // magic, no have idea how it works
        for(new i,z,j; i < sizeof iconColors ; i++,z++)
        {
            if(!(i % 3))
            {
                get_pcvar_string(cvar[CVAR_ICON_COLOR + j ++],tmpStr,charsmax(tmpStr))
                parse(tmpStr,
                parseStr[0],charsmax(parseStr[]),
                parseStr[1],charsmax(parseStr[]),
                parseStr[2],charsmax(parseStr[]))
            }
            if(z == 3)
            z  =0
            iconColors[i] = str_to_num(parseStr[z])
            if(i > 2 && !blinkTime)
            break
        }
    }
    if(get_pcvar_num(cvar[CVAR_SHOWSTATS]))
    {
        new tmpStr2[MAX_RESOURCE_PATH_LENGTH],parseStr2[3][10]
        get_pcvar_string(cvar[CVAR_STATS_COLOR],tmpStr2,charsmax(tmpStr2))
        parse(tmpStr2,
        parseStr2[0],charsmax(parseStr2[]),
        parseStr2[1],charsmax(parseStr2[]),
        parseStr2[2],charsmax(parseStr2[]))

        endHudColor[0]  = str_to_num(parseStr2[0])
        endHudColor[1]  = str_to_num(parseStr2[1])
        endHudColor[2]  = str_to_num(parseStr2[2])
        get_pcvar_string(cvar[CVAR_STATS_POS],tmpStr2,charsmax(tmpStr2))
        parse(tmpStr2,
        parseStr2[0],charsmax(parseStr2[]),
        parseStr2[1],charsmax(parseStr2[]))

        endHudPos[0] = str_to_float(parseStr2[0])
        endHudPos[1] = str_to_float(parseStr2[1])
    }
    if(get_pcvar_num(cvar[CVAR_INFORMER_DISPLAY]))
    {
        new informerText[312]
        formatex(informerText,charsmax(informerText),"%L",LANG_SERVER,"INFORMER")
        for(new i ; i < informerDisplay ; ++i)
        if(contain(informerText,informerTplKeys[i]) != -1)
        informerBitSum |= (1 << i)
        new forParse[30],parsedValue[3][10]
        get_pcvar_string(cvar[CVAR_INFORMER_POS],forParse,charsmax(forParse))
        parse(forParse,parsedValue[0],charsmax(parsedValue[]),parsedValue[1],charsmax(parsedValue[]))
        informerPos[0] = str_to_float(parsedValue[0])
        informerPos[1] = str_to_float(parsedValue[1])
        get_pcvar_string(cvar[CVAR_INFORMER_COLOR],forParse,charsmax(forParse))
        parse(forParse,parsedValue[0],charsmax(parsedValue[]),parsedValue[1],charsmax(parsedValue[]),parsedValue[2],charsmax(parsedValue[]))
        informerColor[0] = str_to_num(parsedValue[0])
        informerColor[1] = str_to_num(parsedValue[1])
        informerColor[2] = str_to_num(parsedValue[2])
        holdTime = get_pcvar_float(cvar[CVAR_INFORMER_HOLDTIME])
    }
    else
    task_Hud_Id = 0
    ScreenFade = get_user_msgid("ScreenFade")
    AmmoX = get_user_msgid("AmmoX")
    AmmoPickup = get_user_msgid("AmmoPickup")
    WeapPickup = get_user_msgid("WeapPickup")
    syncInformerHud = CreateHudSyncObj()

    #if !defined MaxClients
        MaxClients = get_maxplayers()
    #endif

    new gh[10]
    get_pcvar_string(cvar[CVAR_CHAT_MESSAGE],gh,charsmax(gh))
    chatInformerBitsum = read_flags(gh) //get_pcvar_flags(cvar[CVAR_CHAT_MESSAGE])
    autoSaveTime = get_pcvar_float(cvar[CVAR_AUTOSAVE])
    // block drop command
    register_clcmd("drop","block_drop")
    fwdWin = CreateMultiForward("gg_win",ET_IGNORE,FP_CELL)
    fwdLevelUp = CreateMultiForward("gg_levelup",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL)
    fwdWarmUpStart = CreateMultiForward("gg_warmup_start",ET_IGNORE)
    fwdWarmUpEnd = CreateMultiForward("gg_warmup_end",ET_STOP)
    fwdState = CreateMultiForward("gg_state",ET_IGNORE,FP_CELL)
    fwdEquip = CreateMultiForward("gg_player_equip",ET_IGNORE,FP_CELL)
    if(ggActive)
    {
        ggActive = false // for retrigger Enable_GunGame function
        Enable_GunGame()
    }
    // op. cmds
    register_concmd("gg_enable","CMD_GGToggle",ADMIN_RCON,"[0|1] - toggles the functionality of GunGame.")
}
//
// --- GG CMDS ---
//

public CMD_GGToggle(id,level,cid)
{
    if(!cmd_access(id,level,cid,0))
        return PLUGIN_HANDLED
    new sArg[10]
    read_argv(1,sArg,charsmax(sArg))
    if(sArg[0])
        str_to_num(sArg) ?  Enable_GunGame() : Disable_GunGame()
    else    // azazazaza
        ggActive ? Disable_GunGame() : Enable_GunGame()
    new adminName[MAX_PLAYERS],adminAuth[36],adminIp[15]
    get_user_name(id,adminName,charsmax(adminName))
    get_user_authid(id,adminAuth,charsmax(adminAuth))
    get_user_ip(id,adminIp,charsmax(adminIp),true)
    log_amx("%s<%s><%s> toggled gungame",adminName,adminAuth,adminIp)
    return PLUGIN_HANDLED
}
// --- GG HOOKS --- //
new hookMsgAmmoX,hookMsgWeapPickup,hookMsgAmmoPickup
new HamHook:hookSpawn,HamHook:hookKilled,HamHook:hookDamage,HamHook:hookTrace,HamHook:hookUseGame,HamHook:hookUseStrip
//
// Enable GunGame plugin
//
public Enable_GunGame()
{
    if(ggActive)
        return
    if(weaponSets)
        ArrayClear(weaponSets)
    if(warmUpSet)
        ArrayClear(warmUpSet)
    new cvarState = get_pcvar_num(cvar[CVAR_ENABLED])
    load_cfg()
    // power on self test
    if(!modFound)
    {
        server_print("[GunGame] Mod settings is not preset!")
        set_fail_state("missing mod settings")
    }
    new offsetsPreset
    // check offsets
    for(new i ;i < dataOffsetsStruct ; ++i)
    {
        if(!modOffsets[i] && i < offsetAmmoDiff)
            log_amx("ERROR! Offset ^"%s^" is not present!",offsetsForMe[i])
        else
        offsetsPreset ++
    }
    if(offsetsPreset < dataOffsetsStruct)
    {
        server_print("[GunGame] Offsets is missing")
        set_fail_state("missing offsets")
    }
    else
    {
        server_print("[GunGame] Offsets for %s loaded",gameName)
    }
    // check level weapons for valid
    if(weaponSets == Invalid_Array)
    {
        server_print("[GunGame] No active levels^n")
        log_amx("ERROR! No active levels!")
        return
    }
    maxLevel = ArraySize(weaponSets)
    server_print("[GunGame] Total %d levels loaded from ^"%s^" configuration file",maxLevel,cfgFileWas)
    // set hooks for players
    if(!hookSpawn)
    {   // register new hooks
        hookSpawn = RegisterHam(Ham_Spawn,"player","On_PlayerSpawn",true)
        hookKilled = RegisterHam(Ham_Killed,"player","On_PlayerKilled",true)
        hookDamage = RegisterHam(Ham_TakeDamage,"player","On_PlayerTakeDamage",false)
        hookTrace = RegisterHam(Ham_TraceAttack,"player","On_TraceAttack",false)
        hookUseGame = RegisterHam(Ham_Use,"player_weaponstrip","HS_BlockUse",false)
        hookUseStrip = RegisterHam(Ham_Use,"game_player_equip","HS_BlockUse",false)
    }
    else
    {
        // enable hooks
        EnableHamForward(hookSpawn)
        EnableHamForward(hookKilled)
        EnableHamForward(hookDamage)
        EnableHamForward(hookTrace)
        EnableHamForward(hookUseGame)
        EnableHamForward(hookUseStrip)
    }
    // create stripper of player equipments
    if(!striper)
        striper = create_entity("player_weaponstrip")
    if(!is_valid_ent(striper))
    {
        log_amx("ERROR! Unable to init weapon striper functions.")
        set_fail_state("unable to create striper")
    }
    if(get_pcvar_num(cvar[CVAR_MAPCHANGES_STYLE]) && !get_cvar_num(cvar[CVAR_MAPCHOOSER_TYPE]))
        mapchooser_detect()
    // infinity ammo
    hookMsgAmmoX = register_message(AmmoX,"MSG_AmmoX")
    // block weapon pickup draw icon
    hookMsgWeapPickup = register_message(WeapPickup,"MSG_BlockDraw")
    hookMsgAmmoPickup = register_message(AmmoPickup,"MSG_BlockDraw")
    set_pcvar_num(cvar[CVAR_ENABLED],true)
    ggActive = true
    ExecuteForward(fwdState,fwdRet,ggActive)
    if(!cvarState)
    {
        new players[MAX_PLAYERS],pnum
        get_players(players,pnum)
        #if defined AGHL_COLOR
        new bool:rmb
        #endif
        for(new i,player  ; i < pnum ; i++)
        {
            player = players[i]
            #if defined AGHL_COLOR
            rmb = playersData[player][PLAYER_AGHL]
            #endif
            client_putinserver(player)
            #if defined AGHL_COLOR
            playersData[rmb][PLAYER_AGHL] = rmb
            #endif
            if(is_user_alive(player))
                Equip_PlayerWithWeapon(player)
        }
        gg_notify_msg(0,NOTIFY_ENABLED)
    }
    Map_LockItems(true)
}
//
// Disable GunGame plugin
//
public Disable_GunGame()
{
    if(ggActive)
    {
        DisableHamForward(hookSpawn)
        DisableHamForward(hookKilled)
        DisableHamForward(hookDamage)
        DisableHamForward(hookTrace)
        DisableHamForward(hookUseGame)
        DisableHamForward(hookUseStrip)
        unregister_message(AmmoX,hookMsgAmmoX)
        unregister_message(WeapPickup,hookMsgWeapPickup)
        unregister_message(AmmoPickup,hookMsgAmmoPickup)
        set_pcvar_num(cvar[CVAR_ENABLED],false)
        ggActive = false
        new players[MAX_PLAYERS],pnum
        get_players(players,pnum)
        for(new i,player ; i < pnum ; i++)
        {
            player = players[i]
            if(task_Hud_Id && !playersData[player][PLAYER_BOT])
                ClearSyncHud(player,syncInformerHud) // reset hud
            Reset_RefilTasks(player) // reset refil tasks
            StatusIcon_Display(player,3)
            remove_task(task_Icon_Blink + player)
            remove_task(task_Hud_Id + player)
            remove_task(task_Equip_Id + player)
            remove_task(task_Change_Id + player)
        }
        warmUpMode = 0
        remove_task(task_WarmUp_Id)
        remove_task(task_ProLevel_Id)
        remove_task(task_EntRemove_Id)
        gg_notify_msg(0,NOTIFY_DISABLED)
        Map_LockItems(false)
        ExecuteForward(fwdState,fwdRet,ggActive)
    }
}
public plugin_natives()
{
    register_library("gungame")
    register_native("gg_get_max_level","api_get_max_level")
    register_native("gg_get_level_data","api_get_level_data")
    register_native("gg_get_player_level","api_get_player_level")
    register_native("gg_set_player_level","api_set_player_level")
    register_native("gg_equip_force","api_equip_force",true)
}
// parse configuration files
// thanks to Safety1st for his tips
public load_cfg()
{
    new mapName[MAX_PLAYERS],cfgFilePath[MAX_MENU_LENGTH],cfgFileLen,bool:isMapCfg
    get_mapname(mapName,charsmax(mapName))
    // build path for config folder
    cfgFileLen = get_configsdir(cfgFilePath,charsmax(cfgFilePath))
    cfgFileLen += formatex(cfgFilePath[cfgFileLen],charsmax(cfgFilePath) - cfgFileLen,"/gungame/")
    // check that we have map config
    formatex(cfgFilePath[cfgFileLen],charsmax(cfgFilePath) - cfgFileLen,"%s.ini",mapName)
    if(file_exists(cfgFilePath))
        isMapCfg = true
    cfgFilePath[cfgFileLen] = 0 // keep our path clean
    new cfgFile[30]
    get_pcvar_string(cvar[CVAR_CFGFILE],cfgFile,charsmax(cfgFile))
    copy(cfgFileWas,charsmax(cfgFileWas),cfgFile)
    formatex(cfgFilePath[cfgFileLen],charsmax(cfgFilePath) - cfgFileLen,cfgFileWas)
    new Trie:keyTrie  = TrieCreate()
    static Trie:hamHooks
    for(new i ; i < keyNames ; ++i) // i'm realy lazy for write few strings of code, lets do amxx dirty work
    TrieSetCell(keyTrie,setKeys[i],i)
    new f = fopen(cfgFilePath,"rt")
    new buffer[MAX_MENU_LENGTH],lineCount
    if(f)
    {
        #define CFG_BLOCK_NONE      0
        #define CFG_BLOCK_CVARS     1
        #define CFG_BLOCK_WEAPONS   2
        #define CFG_BLOCK_MODSETTINGS   3
        #define CFG_MOD_NONE        0
        #define CFG_MOD_OFFSETS     1
        #define CFG_MOD_BLOCKSPAWN  2
        #define CFG_MOD_WARMUP      3
        #define CFG_MOD_WEAPONLIST  4
        #define CFG_LEVEL_NONE      0
        #define CFG_LEVEL_MAIN      1
        #define CFG_LEVEL_EQUIP     2
        #define CFG_LEVEL_WEAPON    3
        #define CFG_LEVEL_INFLICTORS    4
        new currentBlockId // cfg vars
        new modName[20] // mod settings vars
        new modBlockId = CFG_MOD_NONE
        get_cvar_pointer("sv_ag_version") ? copy(modName,charsmax(modName),"agmini") : get_modname(modName,charsmax(modName))
        if(strcmp(modName,"valve") == 0)
            isValve = true
        else if(strcmp(modName,"agmini") == 0 || strcmp(modName,"ag") == 0)
            isAG = true
        while(!feof(f))
        {
            fgets(f,buffer,charsmax(buffer))
            trim(buffer)
            lineCount ++
            // skip comments and empty lines
            if(!buffer[0] || buffer[0] == ';' || contain(buffer,"//") == 0)
                continue
            switch(currentBlockId)
            {
                case CFG_BLOCK_NONE:
                {
                    if(buffer[0] == '<')
                    {
                        if(strcmp(buffer,"<cvars>") == 0)
                            currentBlockId = CFG_BLOCK_CVARS
                        else if(strcmp(buffer,"<sets>") == 0)
                            currentBlockId = CFG_BLOCK_WEAPONS
                        else if(strcmp(buffer,"<mods>") == 0)
                            currentBlockId = CFG_BLOCK_MODSETTINGS
                    }
                }
                case CFG_BLOCK_CVARS:
                {
                    // parse cvar block
                    if(buffer[0] == '<')
                    {
                        if(strcmp(buffer,"</cvars>") == 0)
                            currentBlockId = CFG_BLOCK_NONE
                        continue
                    }
                    new cvarName[40],cvarValue[256],cvarId
                    parse(buffer,cvarName,charsmax(cvarName),cvarValue,charsmax(cvarValue))
                    cvarId = get_cvar_pointer(cvarName)
                    if(cvarId)
                    {
                        set_pcvar_string(cvarId,cvarValue)
                    }
                    else
                    {
                        log_amx("WARNING! Unknown cvar ^"%s^" on line %d",cvarName,lineCount)
                    }
                }
                case CFG_BLOCK_WEAPONS:
                {
                    // parse weapons block
                    if(isMapCfg)
                    {
                        // we will parse weapons block later
                        currentBlockId = CFG_BLOCK_NONE
                        continue
                    }
                    if(buffer[0] == '<')
                    {
                        if(strcmp(buffer,"</sets>") == 0)
                        {
                            currentBlockId = CFG_BLOCK_NONE
                            continue
                        }
                    }
                    Parse_WeaponSets(buffer,lineCount,keyTrie,hamHooks,false)
                }
                case CFG_BLOCK_MODSETTINGS:
                {
                    // parse mod settings
                    if(buffer[0] == '<')
                    {
                        if(strcmp(buffer,"</mods>") == 0)
                        {
                            currentBlockId = CFG_BLOCK_NONE
                            continue
                        }
                    }
                    if(!modFound)
                    {
                        if(buffer[0] == '<')
                        {
                            new checkingMod[12]
                            new endBracket = strfind(buffer,">")
                            if(endBracket == -1)
                                continue
                            if(strlen(buffer) > charsmax(checkingMod))
                                continue
                            formatex(checkingMod,strlen(buffer) - 2,"%s",buffer[1])
                            if(strcmp(checkingMod,modName) == 0)
                                modFound = true
                        }
                        continue
                    }
                    switch(modBlockId)
                    {
                        case CFG_MOD_NONE:
                        {
                            if(buffer[0] == '<')
                            {
                                new tagKey[20]
                                new endBracket = strfind(buffer,">")
                                if(endBracket == -1)
                                    continue
                                if(strlen(buffer) > charsmax(tagKey))
                                    continue
                                formatex(tagKey,strlen(buffer) - 2,"%s",buffer[1])
                                if(strcmp(tagKey,"offsets") == 0)
                                    modBlockId = CFG_MOD_OFFSETS
                                else if(strcmp(tagKey,"blockspawn") == 0)
                                    modBlockId = CFG_MOD_BLOCKSPAWN
                                else if(strcmp(tagKey,"weaponlist") == 0)
                                    modBlockId = CFG_MOD_WEAPONLIST
                                else if(strcmp(tagKey,"warmup") == 0)
                                {
                                    modBlockId  = CFG_MOD_WARMUP
                                    Parse_WeaponSets(buffer,lineCount,keyTrie,hamHooks,true)
                                }
                                else if(strcmp(tagKey[1],modName) == 0) // mod settings parse finished
                                    currentBlockId = CFG_BLOCK_NONE
                            }
                            else
                            {
                                new keyName[20],keyValue[MAX_RESOURCE_PATH_LENGTH]
                                strtok(buffer,keyName,charsmax(keyName),keyValue,charsmax(keyValue),'=',1)
                                replace(keyValue,charsmax(keyValue),"=","")
                                trim(keyValue)
                                if(strcmp(keyName,"name") == 0)
                                    copy(gameName,charsmax(gameName),keyValue)
                            }
                        }
                        case CFG_MOD_OFFSETS:
                        {
                            // parse offsets block
                            if(strcmp(buffer,"</offsets>") == 0)
                            {
                                // offsets block parse finished
                                modBlockId = CFG_MOD_NONE
                                continue
                            }
                            new offsetName[30],offsetDiff[10]
                            strtok(buffer,offsetName,charsmax(offsetName),offsetDiff,charsmax(offsetDiff),'=',1)
                            // TODO: check out new strtok2 native in AMXX 1.8.3
                            replace(offsetDiff,charsmax(offsetDiff),"=","")
                            trim(offsetDiff)
                            for(new i ; i < sizeof offsetsForMe ; ++i)
                            {
                                if(strcmp(offsetName,offsetsForMe[i]) == 0)
                                    modOffsets[i] = str_to_num(offsetDiff)
                            }
                        }
                        case CFG_MOD_BLOCKSPAWN:
                        {
                            if(strcmp(buffer,"</blockspawn>") == 0)
                            {
                                // block spawn parse finished
                                modBlockId = CFG_MOD_NONE
                                continue
                            }
                            if(!ggblockedItems)
                                ggblockedItems = ArrayCreate(32)
                            ArrayPushString(ggblockedItems,buffer)
                        }
                        case CFG_MOD_WARMUP:
                        {
                            if(strcmp(buffer,"</warmup>") == 0)
                            {
                                Parse_WeaponSets(buffer,lineCount,keyTrie,hamHooks,true)
                                modBlockId = CFG_MOD_NONE
                                continue
                            }
                            Parse_WeaponSets(buffer,lineCount,keyTrie,hamHooks,true)
                        }
                        case CFG_MOD_WEAPONLIST:
                        {
                            if(strcmp(buffer,"</weaponlist>") == 0)
                            {
                                modBlockId = CFG_MOD_NONE
                                continue
                            }
                            new weaponName[MAX_PLAYERS],szData[4][10]
                            parse(buffer,weaponName,charsmax(weaponName),
                            szData[0],charsmax(szData[]),
                            szData[1],charsmax(szData[]),
                            szData[2],charsmax(szData[]),
                            szData[3],charsmax(szData[]))

                            if(!ammoMaxMap)
                                ammoMaxMap = TrieCreate()
                            if(!weaponAmmoTrie)
                                weaponAmmoTrie = TrieCreate()
                            new ammoKey[10]
                            new weaponAmmo[weaponAmmoStruct]
                            weaponAmmo[WAMMO_PRIMARY_AMMOID] = str_to_num(szData[0])
                            weaponAmmo[WAMMO_PRIMARY_MAXAMMO] = str_to_num(szData[1])
                            weaponAmmo[WAMMO_SECONDARY_AMMOID] = str_to_num(szData[2])
                            weaponAmmo[WAMMO_SECONDARY_MAXAMMO] = str_to_num(szData[3])
                            // set ammo map
                            for(new i ;  i < 2; i++)
                            {
                                if(weaponAmmo[WAMMO_PRIMARY_AMMOID + i] == -1)
                                continue
                                num_to_str(weaponAmmo[WAMMO_PRIMARY_AMMOID + i],ammoKey,charsmax(ammoKey))
                                TrieSetCell(ammoMaxMap,ammoKey,weaponAmmo[WAMMO_PRIMARY_MAXAMMO + i])
                            }
                            // set weapon ammo details
                            TrieSetArray(weaponAmmoTrie,weaponName,weaponAmmo,weaponAmmoStruct)
                            //modOffsets[msgWeaponList] = -1
                        }
                    }
                }
            }
        }
        fclose(f)
    }
    if(isMapCfg)
    {
        cfgFilePath[cfgFileLen] = 0 // keep our path clean
        formatex(cfgFileWas,charsmax(cfgFileWas),"%s.ini",mapName)
        formatex(cfgFilePath[cfgFileLen],charsmax(cfgFilePath) - cfgFileLen,cfgFileWas)
        new f = fopen(cfgFilePath,"rt")
        buffer[0] = 0
        lineCount = 0
        while(!feof(f))
        {
            fgets(f,buffer,charsmax(buffer))
            trim(buffer)
            lineCount ++
            // skip comments and empty lines
            if(!buffer[0] || buffer[0] == ';' || contain(buffer,"//") == 0)
                continue
            Parse_WeaponSets(buffer,lineCount,keyTrie,hamHooks,false)
        }
        fclose(f)
    }
    TrieDestroy(keyTrie)
    /*if(hamHooks)
    TrieDestroy(hamHooks)*/
}
//#define âîçâðàùåíèå_îëîâà return
#if AMXX_VERSION_NUM == 182
#define ITEM_FLAG_SELECTONEMPTY       1
#define ITEM_FLAG_NOAUTORELOAD        2
#define ITEM_FLAG_NOAUTOSWITCHEMPTY   4
#define ITEM_FLAG_LIMITINWORLD        8
#define ITEM_FLAG_EXHAUSTIBLE        16
#endif
// parse weapon list
public MSG_WeaponList(MsgDEST,MsgID,id)
{
    #define argWeaponName           1
    #define argPrimaryAmmoId        2
    #define argPrimaryAmmoMaxAmount     3
    #define argSecondaryAmmoId      4
    #define argSecondaryAmmoMaxAmount   5
    #define argSlotId           6
    #define argNumberInSlot         7
    #define argWeaponID         8
    #define argFlags            9
    // TODO: recheck item flags
    static bool:weaponListInited
    if(weaponListInited) // weapon list is already parsed
    return PLUGIN_CONTINUE
    static Float:lastInited
    if(lastInited && lastInited != get_gametime())
    {
        // all weapons info are sending to client at same time
        weaponListInited = true
        return PLUGIN_CONTINUE
    }
    lastInited = get_gametime()
    if(!ammoMaxMap)
        ammoMaxMap = TrieCreate()
    if(!weaponAmmoTrie)
        weaponAmmoTrie = TrieCreate()
    new weaponName[MAX_PLAYERS]
    new ammoKey[10]
    new weaponAmmo[weaponAmmoStruct]
    get_msg_arg_string(argWeaponName,weaponName,charsmax(weaponName))
    weaponAmmo[WAMMO_PRIMARY_AMMOID] = get_msg_arg_int(argPrimaryAmmoId)
    weaponAmmo[WAMMO_PRIMARY_MAXAMMO] = get_msg_arg_int(argPrimaryAmmoMaxAmount)
    weaponAmmo[WAMMO_SECONDARY_AMMOID] = get_msg_arg_int(argSecondaryAmmoId)
    weaponAmmo[WAMMO_SECONDARY_MAXAMMO] = get_msg_arg_int(argSecondaryAmmoMaxAmount)
    // set ammo map
    for(new i ;  i < 2; i++)
    {
        if(weaponAmmo[WAMMO_PRIMARY_AMMOID + i] == -1)
            continue
        num_to_str(weaponAmmo[WAMMO_PRIMARY_AMMOID + i],ammoKey,charsmax(ammoKey))
        TrieSetCell(ammoMaxMap,ammoKey,weaponAmmo[WAMMO_PRIMARY_MAXAMMO + i])
    }
    // set weapon ammo details
    TrieSetArray(weaponAmmoTrie,weaponName,weaponAmmo,weaponAmmoStruct)
    #if defined HLWPNMOD
    if(wpnmod_get_weapon_info(get_msg_arg_int(argWeaponID),ItemInfo_bCustom))
    {
        if(!wpnModMap)
        {
            wpnModMap = TrieCreate()
            TrieSetCell(wpnModMap,weaponName,true)
        }
    }
    #endif
    return PLUGIN_CONTINUE
}
public MSG_BlockDraw(MsgDEST,MsgID,player)
{
    return PLUGIN_HANDLED
}
new Trie:mapItems
//
// Hook state meaning:
//  0 - new hook
//  1 - active hook
//  2 - disabled hook
//
enum _:mapItemsHooks
{
    HamHook:HOOK_TOUCH,
    HamHook:HOOK_SPAWN,
    HamHook:HOOK_THINK,
    HOOK_STATE
}
//
// Lock some items on map
//
Map_LockItems(bool:lock)
{
    if(!mapItems && !lock)
    return
    new entCount = entity_count()
    new classname[MAX_PLAYERS]
    /*  if (is_running("dod") == 1 )
    for(new i,count =  1 ; i <  count ; ++i)
    if (is_running("dod") != 1 )
    */
    for(new i,count =  ArraySize(ggblockedItems) ; i <  count ; ++i)
    {
        ArrayGetString(ggblockedItems,i,classname,charsmax(classname))
        if(strfind(classname,"*") == -1)
        {
            if(!mapItems)
            mapItems = TrieCreate()
            else
            Item_SetLock(classname,0,lock,true)
        }
    }
    // Loop through all entites
    for(new ent = MaxClients +  1 ; ent <= entCount ; ++ent)
    {
        if(is_valid_ent(ent) && Item_LockCheck(ent))
        { // find our blocked entity
            entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))
            Item_SetLock(classname,ent,lock)
        }
    }
}
Item_SetLock(classname[MAX_PLAYERS],ent,bool:lock = true,bool:special = false)
{
    if(!mapItems)
    mapItems = TrieCreate()
    new itemHooks[mapItemsHooks]
    if(lock)
    {
        // lock this entity
        if(!TrieGetArray(mapItems,classname,itemHooks,sizeof itemHooks) || itemHooks[HOOK_STATE] == 0){ // set block hooks
        itemHooks[HOOK_TOUCH] = _:RegisterHam(Ham_Touch,classname,"Item_BlockHook")
        itemHooks[HOOK_SPAWN] = _:RegisterHam(Ham_Spawn,classname,!special ? "Item_SpawnHook" : "HS_EntitySpawnBlock",true)
        itemHooks[HOOK_THINK] = _:RegisterHam(Ham_Think,classname,"Item_SpawnHook",true)
        itemHooks[HOOK_STATE] = 1
        TrieSetArray(mapItems,classname,itemHooks,sizeof itemHooks)
        }
        else if(itemHooks[HOOK_STATE] == 2)
        {
            // reenable exists hooks
            EnableHamForward(itemHooks[HOOK_TOUCH])
            EnableHamForward(itemHooks[HOOK_SPAWN])
            //EnableHamForward(itemHooks[HOOK_THINK])
            itemHooks[HOOK_STATE] = 1
            TrieSetArray(mapItems,classname,itemHooks,sizeof itemHooks)
        }
        // hide it
        if(is_valid_ent(ent))
        {
            if(entity_get_int(ent,EV_INT_movetype))
                entity_set_int(ent,EV_INT_effects,entity_get_int(ent,EV_INT_effects) | EF_NODRAW) //blanks out resources
            if(entity_get_float(ent,EV_FL_takedamage) != DAMAGE_NO)
            {
                entity_set_float(ent,EV_FL_fuser1,entity_get_float(ent,EV_FL_takedamage))
                entity_set_float(ent,EV_FL_takedamage,DAMAGE_NO)
            }
        }
        else
        {
            new targetEnt
            while((targetEnt = find_ent_by_class(targetEnt,classname))){
            if(entity_get_int(targetEnt,EV_INT_movetype))
            entity_set_int(targetEnt,EV_INT_effects,entity_get_int(targetEnt,EV_INT_effects) | EF_NODRAW)
            entity_set_float(targetEnt,EV_FL_fuser1,entity_get_float(targetEnt,EV_FL_takedamage))
            entity_set_float(targetEnt,EV_FL_takedamage,DAMAGE_NO)
            }
        }
    }
    else
    {
         // unlock this entity
        if(TrieGetArray(mapItems,classname,itemHooks,sizeof itemHooks) && itemHooks[HOOK_STATE] == 1)
        {
            DisableHamForward(itemHooks[HOOK_TOUCH])
            DisableHamForward(itemHooks[HOOK_SPAWN])
            DisableHamForward(itemHooks[HOOK_THINK])
            itemHooks[HOOK_STATE] = 2
            TrieSetArray(mapItems,classname,itemHooks,sizeof itemHooks)
        }
        // show int
        if(is_valid_ent(ent))
        {
            if(entity_get_int(ent,EV_INT_movetype))
                entity_set_int(ent,EV_INT_effects,entity_get_int(ent,EV_INT_effects) & ~EF_NODRAW)
            if(entity_get_float(ent,EV_FL_fuser1))
                entity_set_float(ent,EV_FL_takedamage,entity_get_float(ent,EV_FL_fuser1))
        }
        else
        {
            // pisal buhim, hz 4to za func
            new targetEnt
            while((targetEnt = find_ent_by_class(targetEnt,classname))){
            if(entity_get_int(targetEnt,EV_INT_movetype))
                entity_set_int(targetEnt,EV_INT_effects,entity_get_int(targetEnt,EV_INT_effects) & ~EF_NODRAW)
            if(entity_get_float(targetEnt,EV_FL_fuser1))
                entity_set_float(targetEnt,EV_FL_takedamage,entity_get_float(targetEnt,EV_FL_fuser1))
            }
        }
    }
}
//
// Block touch while gungame runing
//
public Item_BlockHook(ent)
{
    if(entity_get_int(ent,EV_INT_spawnflags) & SF_NORESPAWN)
        return HAM_IGNORED
    return HAM_SUPERCEDE
}
//
// Hide entity on spawn while gungame runing
//
public Item_SpawnHook(ent)
{
    if(!is_valid_ent(ent))
        return HAM_IGNORED

    new classname[MAX_PLAYERS]

    entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))
    if(entity_get_int(ent,EV_INT_spawnflags) & SF_NORESPAWN)
        return HAM_IGNORED

    if(entity_get_int(ent,EV_INT_movetype))
        entity_set_int(ent,EV_INT_effects,entity_get_int(ent,EV_INT_effects) | EF_NODRAW)

    if(entity_get_float(ent,EV_FL_takedamage) != DAMAGE_NO)
    {
        entity_set_float(ent,EV_FL_fuser1,entity_get_float(ent,EV_FL_takedamage))
        entity_set_float(ent,EV_FL_takedamage,DAMAGE_NO)
    }
    return HAM_IGNORED
}

Item_LockCheck(ent)
{
    if (!is_running("dod"))
    {
        new classname[MAX_PLAYERS],checkClassName[MAX_PLAYERS]
        entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))

        for(new i,count =  ArraySize(ggblockedItems) ; i <  count ; ++i)
        {
            ArrayGetString(ggblockedItems,i,checkClassName,charsmax(checkClassName))
            if(strfind(checkClassName,"*") == -1)
                continue
            else
            checkClassName[strlen(checkClassName) - 1] = 0
            if(contain(classname,checkClassName) == 0)
                return true
        }
    }
    return false
}
//
// Prevent entity from spawn
//
public HS_EntitySpawnBlock(ent)
{
    set_task(0.1,"ENT_DelayedRemove",task_EntRemove_Id + ent)
    //return HAM_SUPERCEDE
}
//
// I realy no have idea why instant removing crashes linux server.
// Just leave as is :D
//
public ENT_DelayedRemove(taskId)
{
    new ent = taskId - task_EntRemove_Id
    if(is_valid_ent(ent))
        remove_entity(ent)
}
public HS_BlockUse(ent)
    return HAM_SUPERCEDE

public HS_DisableAutoSwitch(ent)
{
    SetHamReturnInteger(true)
    return HAM_OVERRIDE
}

public block_drop()
{
    if(ggActive)
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}

public Play_ProLevelMusic()
{
    for (new human=1; human<=MaxClients; human++)
    if(!playersData[human][PLAYER_BOT])
        client_cmd(human,"mp3 play ^"%s^"",prolevel_music)
    if(proLevelLoop)
        set_task(proLevelLoop,"Play_ProLevelMusic",task_ProLevel_Id)
}
// check equipment for valid
public Test_ValidEnt(classname[])
{
    return true
    // TODO: figure out why create entity in precache cause DOD crash
    /*
    new testEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,classname))
    if(!is_valid_ent(testEnt))
    return false
    else
    remove_entity(testEnt)
    return true
    */
}
// parse level set
// narkoman configurtaion file format
public Parse_WeaponSets(buffer[],lineCount,Trie:keyTrie,&Trie:hamHooks,bool:warmUp)
{
    static weaponSet[weaponSetStruct],equipItem[equipStruct]
    static setBlockId
    switch(setBlockId)
    {
        case CFG_LEVEL_NONE:
        {
            if(buffer[0] == '<')
            {
                if(strcmp(buffer,!warmUp ? "<level>" : "<warmup>") == 0)
                {
                    // new level block
                    arrayset(weaponSet,0,weaponSetStruct)
                    setBlockId = CFG_LEVEL_MAIN
                }
            }
        }
        case CFG_LEVEL_MAIN:
        {
            // parse level vars
            if(buffer[0] == '<')
            {
                if(strcmp(buffer,!warmUp ? "</level>" : "</warmup>") == 0)
                {
                    // level block read finished
                    setBlockId = CFG_LEVEL_NONE
                    if(!weaponSet[WSET_EQUIP_ITEMS])
                        return
                    if(!weaponSet[WSET_SHOWNAME][0])
                    {
                        ArrayGetArray(weaponSet[WSET_EQUIP_ITEMS],0,equipItem)
                        copy(weaponSet[WSET_SHOWNAME],
                        charsmax(weaponSet[WSET_SHOWNAME]),
                        equipItem[EQUIP_NAME])
                        replace(weaponSet[WSET_SHOWNAME],charsmax(weaponSet[WSET_SHOWNAME]),"weapon_","")
                        ucfirst(weaponSet[WSET_SHOWNAME])
                    }
                    if(!weaponSets && !warmUp)
                        weaponSets  = ArrayCreate(weaponSetStruct)
                    else if(!warmUpSet && warmUp)
                        warmUpSet = ArrayCreate(weaponSetStruct)
                    if(!warmUp)
                        ArrayPushArray(weaponSets ,weaponSet) // push the level data
                    else
                        ArrayPushArray(warmUpSet,weaponSet) // push the level data
                    return
                }
                else if(strcmp(buffer,"<equip>") == 0)
                {
                    // equip block start
                    setBlockId = CFG_LEVEL_EQUIP
                    return
                }
                else if(strcmp(buffer,"<inflictors>") == 0)
                {
                    // inflictors calssname for this weapon
                    setBlockId = CFG_LEVEL_INFLICTORS
                    return
                }
            }
            // TODO: checkout new strtok2 native
            new keyName[20],keyValue[40]
            strtok(buffer,keyName,charsmax(keyName),keyValue,charsmax(keyValue),'=',1)
            replace(keyValue,charsmax(keyValue),"=","")
            trim(keyValue)
            new keyId
            if(!TrieGetCell(keyTrie,keyName,keyId))
                return
            switch(keyId)
            {
                case KEYSET_SHOWNAME: copy(weaponSet[WSET_SHOWNAME],charsmax(weaponSet[WSET_SHOWNAME]),keyValue)
                case KEYSET_KILLS: weaponSet[WSET_KILLS] = str_to_num(keyValue)
                case KEYSET_SKIP: weaponSet[WSET_SKIP] = str_to_num(keyValue)
                case KEYSET_ICONSPRITE: copy(weaponSet[WSET_ICONSPRITE],charsmax(weaponSet[WSET_ICONSPRITE]),keyValue)
                case KEYSET_BOTCANT: weaponSet[WSET_BOTCANT] = str_to_num(keyValue) == 1
                default: log_amx("WARNING! Unknown key ^"%s^" on line %d",keyName,lineCount)
            }
        }
        case CFG_LEVEL_EQUIP:
        {
            if(buffer[0] == '<')
            {
                if(strcmp(buffer,"</equip>") == 0)
                {
                    setBlockId = CFG_LEVEL_MAIN
                    return
                }
            }
            if(buffer[0] == '<' && buffer[strlen(buffer) - 1] == '>')
            {
                arrayset(equipItem,0,equipStruct)
                formatex(equipItem[EQUIP_NAME],strlen(buffer) - 2,"%s",buffer[1])
                equipItem[EQUIP_FULL_PRIMARY] = true
                equipItem[EQUIP_FULL_SECONDARY] = true
                equipItem[EQUIP_CLIP] = -1
                setBlockId = CFG_LEVEL_WEAPON
            }
            else
            {
                #if !defined HLWPNMOD
                if(!Test_ValidEnt(buffer))
                {
                    log_amx("WARNING! Invalid equipment ^"%s^" on line %d",buffer,lineCount)
                    return
                }
                #endif
                arrayset(equipItem,0,equipStruct)
                copy(equipItem[EQUIP_NAME],charsmax(equipItem[EQUIP_NAME]),buffer)
                equipItem[EQUIP_FULL_PRIMARY] = true
                equipItem[EQUIP_FULL_SECONDARY] = true
                equipItem[EQUIP_CLIP] = -1
                if(weaponSet[WSET_EQUIP_ITEMS] == Invalid_Array)
                weaponSet[WSET_EQUIP_ITEMS] = _:ArrayCreate(equipStruct)
                ArrayPushArray(weaponSet[WSET_EQUIP_ITEMS],equipItem)
            }
        }
        case CFG_LEVEL_WEAPON:
        {
            if(buffer[0] == '<')
            {
                new tmp[40]
                formatex(tmp,charsmax(tmp),"</%s>",equipItem[EQUIP_NAME])
                if(strcmp(buffer,tmp) == 0){
                if(weaponSet[WSET_EQUIP_ITEMS] == Invalid_Array)
                weaponSet[WSET_EQUIP_ITEMS] = _:ArrayCreate(equipStruct)
                ArrayPushArray(weaponSet[WSET_EQUIP_ITEMS],equipItem)
                setBlockId = CFG_LEVEL_EQUIP
                }
                return
            }
            new keyName[20],keyValue[40]
            strtok(buffer,keyName,charsmax(keyName),keyValue,charsmax(keyValue),'=',1)
            replace(keyValue,charsmax(keyValue),"=","")
            trim(keyValue)
            new keyId
            if(!TrieGetCell(keyTrie,keyName,keyId))
                return
            switch(keyId)
            {
                case KEYSET_REFIL_TIME_1: equipItem[EQUIP_PRIMARY_REFIL_TIME] = _:(str_to_float(keyValue) ? str_to_float(keyValue) : -1.0)
                case KEYSET_REFIL_AMMOUNT_1: equipItem[EQUIP_PRIMARY_REFIL_AMMOUNT] = str_to_num(keyValue) ? str_to_num(keyValue) : 1
                case KEYSET_DISABLE_FULLAMO_1: equipItem[EQUIP_FULL_PRIMARY] = !str_to_num(keyValue)
                case KEYSET_REFIL_TIME_2: equipItem[EQUIP_SECONDARY_REFIL_TIME] = _:(str_to_float(keyValue) ? str_to_float(keyValue) : -1.0)
                case KEYSET_REFIL_AMMOUNT_2: equipItem[EQUIP_SECONDARY_REFIL_AMMOUNT] = str_to_num(keyValue) ? str_to_num(keyValue) : 1
                case KEYSET_DISABLE_FULLAMO_2: equipItem[EQUIP_FULL_SECONDARY] = !str_to_num(keyValue)
                case KEYSET_CLIP: equipItem[EQUIP_CLIP] = str_to_num(keyValue)
                default: log_amx("WARNING! Unknown key ^"%s^" on line %d",keyName,lineCount)
            }
        }
        case CFG_LEVEL_INFLICTORS:
        {
            if(buffer[0] == '<')
            {
                if(strcmp(buffer,"</inflictors>") == 0)
                {
                    setBlockId = CFG_LEVEL_MAIN
                    return
                }
            }
            if(weaponSet[WSET_INFLICTORS_MAP] == Invalid_Trie)
                weaponSet[WSET_INFLICTORS_MAP] = _:TrieCreate()
            new parseInf[3][36]
            parse(buffer,parseInf[0],charsmax(parseInf[]),
            parseInf[1],charsmax(parseInf[]),
            parseInf[2],charsmax(parseInf[]))

            new inflictorData[4]
            inflictorData[0] = str_to_num(parseInf[1]) // limit
            inflictorData[1] = str_to_num(parseInf[2]) // allow damage from other players flag

            TrieSetArray(weaponSet[WSET_INFLICTORS_MAP],parseInf[0],inflictorData,sizeof inflictorData)
            if(inflictorData[0]){ // register limit handler
            if(!Test_ValidEnt(parseInf[0]))
            {
                log_amx("WARNING! Invalid inflictor item ^"%s^" on line %d",parseInf[0],lineCount)
                return
            }
            if(!weaponSet[WSET_INFARRAY])
            weaponSet[WSET_INFARRAY] = _:ArrayCreate(32)
            ArrayPushString(weaponSet[WSET_INFARRAY],parseInf[0])
            if(!hamHooks)
                hamHooks = TrieCreate()
            if(TrieKeyExists(hamHooks,parseInf[0])) // already registred
                return
            else
            TrieSetCell(hamHooks,parseInf[0],true) // new hook
            RegisterHam(Ham_Spawn,parseInf[0],"Inflictors_SpawnHandler",true)
            RegisterHam(Ham_Killed,parseInf[0],"Inflictors_DestroyHandler",true)
            RegisterHam(Ham_Use,parseInf[0],"Inflictors_DestroyHandler",true)
            RegisterHam(Ham_TakeDamage,parseInf[0],"Inflictors_DamageHandler",false)
            }
        }
    }
}
//
// Player join server
//
public client_putinserver(id)
{
    if(!ggActive)
        return
    arrayset(playersData[id],0,playersDataStruct)
    playersData[id][PLAYER_LASTLEVEL] = -1
    Update_PlayersRanks()
    currentPlayers = get_playersnum()

    playersData[id][PLAYER_BOT] = is_user_bot(id) ? true : false

    if(!playersData[id][PLAYER_BOT])
    {
        console_cmd id, "spk ^"gun time is in effect^""
        #if defined AGHL_COLOR && !defined CSCOLOR
        if(task_RequestColor_Id) // Check
            set_task(0.1,"RequestColor_Task",task_RequestColor_Id + id)
        #endif
        if(autoSaveTime && autoSaveMap)
        {
            new authId[MAX_AUTHID_LENGTH],aSave[autoSaveStruct]
            get_user_authid(id,authId,charsmax(authId))
            if(TrieGetArray(autoSaveMap,authId,aSave,autoSaveStruct))
            {
                if(aSave[ASAVE_TIME] + autoSaveTime > get_gametime())
                {
                    playersData[id][PLAYER_CURRENTLEVEL] = aSave[ASAVE_LEVEL]
                    playersData[id][PLAYER_KILLS] = aSave[ASAVE_KILLS]
                }
                TrieDeleteKey(autoSaveMap,authId)
            }
        }
        if(!playersData[id][PLAYER_CURRENTLEVEL] && !get_pcvar_num(cvar[CVAR_TEAMPLAY]))
        {
            new handicap = get_pcvar_num(cvar[CVAR_HANDICAP])
            if(handicap)
                SetLevel_ForNewPlayer(id,handicap)
        }
        if(!warmUpMode && (get_pcvar_num(cvar[CVAR_WARMUP])))
        {
            // start warmup mode
            warmUpMode = 1
            new data[1]
            data[0] = get_pcvar_num(cvar[CVAR_WARMUP])
            set_task(1.0,"WarmUp_Timer",task_WarmUp_Id,data,sizeof data)
            ///server_print "GUNGAME SETTING WARMUP TIMER ...%i", data[0]
            ExecuteForward(fwdWarmUpStart,fwdRet)
        }
        else if(warmUpMode == 0)
            warmUpMode = 2
        if(proLevelPlayed && !isEndGame)
            client_cmd(id,"mp3 play ^"%s^"", prolevel_music)
        else if(isEndGame && !playersData[id][PLAYER_BOT])
            client_cmd(id,"mp3 play ^"%s^"", sound_winner)
    }
}

public WarmUp_Timer(data[1])
{
    set_hudmessage(255, 255, 255, -1.0, 0.3, 0, 6.0, 0.7, 0.1, 0.2)
    ///server_print ("GG WARMUP TIMER FCN, mode %i | %i", warmUpMode, data[0])
    switch(warmUpMode)
    {
        case 1:
        {
            if(!data[0])
            {
                warmUpMode = 3
                data[0] = 3
                if(!isAG)
                {
                    new players[MAX_PLAYERS],pnum
                    get_players(players,pnum,"ah")
                    for(new i,player ; i < pnum ; ++i)
                    {
                        player = players[i]
                        if(checkPlayerSpectator(player) != -1)
                            continue
                        entity_set_vector(player,EV_VEC_velocity,Float:{0.0,0.0,0.0})
                        set_user_maxspeed(player,0.0)
                        set_pev(player,pev_flags,pev(player,pev_flags) | FL_WORLDBRUSH)
                    }
                }
            }
        }
        case 3:
        {
            if(!data[0])
            {
                warmUpMode = 2
                new players[MAX_PLAYERS],pnum
                get_players(players,pnum,"ah") // ah oh oh oh ah oh
                for (new human=1; human<=MaxClients; human++)
                if(!playersData[human][PLAYER_BOT])
                {
                    show_hudmessage(human,"%L",LANG_PLAYER,"WARMUP_ROUND_OVER")
                    client_cmd(human,"spk buttons/bell1.wav")
                }
                ArrayDestroy(warmUpSet)
                warmUpSet = Invalid_Array
                ExecuteForward(fwdWarmUpEnd,fwdRet)
                if(fwdRet == PLUGIN_HANDLED)
                    return
                for(new i,player ; i < pnum ; ++i)
                {
                    player = players[i]
                    if(checkPlayerSpectator(player) != -1)
                        continue
                    if(!isAG)
                    {
                        set_pev(player,pev_flags,pev(player,pev_flags) &~ FL_WORLDBRUSH)
                        ExecuteHam(Ham_Use,striper,player,player,1.0,0.0) // strip player's weapons
                        ExecuteHamB(Ham_Spawn,player)
                    }
                }
                return
            }
        }
    }
    if(data[0])
    {
        data[0] --
        set_task(1.0,"WarmUp_Timer",task_WarmUp_Id,data,sizeof data)
        for (new human=1; human<=MaxClients; human++)
        {
            if(!playersData[human][PLAYER_BOT])
            show_hudmessage(human,"%L",LANG_PLAYER,warmUpMode == 1 ? "WARMUP_ROUND_DISPLAY" : "WARMUP_ROUND_PREPARE", data[0])
            switch(data[0])
            {
                case 26:console_cmd human, "spk ^"ambience/port_suckin1.wav^""
                case 24:console_cmd human, "spk ^"gun^""
                case 23:console_cmd human, "spk ^"time^""
                case 22:console_cmd human, "spk ^"is^""
                case 21:console_cmd human, "spk ^"in^""
                case 20:console_cmd human, "spk ^"effect^""
                case 17:console_cmd human, "spk ^"effect^""
                case 11:console_cmd human, "spk ^"ambience/port_suckout1.wav^""
                case 30, 15, 10, 5:console_cmd human, "spk ^"gun time is in effect^""
                case 19, 14, 9, 3, 0  :console_cmd human, "spk ^"agrunt/ag_pain2.wav^""
                case 7:console_cmd human, "spk ^"be^""
                case 4:console_cmd human, "spk ^"tride/c0a0_tr_arrive.wav^"",console_cmd human, "spk ^"common/bodydrop2.wav^""
                case 6:console_cmd human, "spk ^"team^""
            }
        }
    }
    if(warmUpMode == 3)
    {
        for (new human=1; human<=MaxClients; human++)
        if(!playersData[human][PLAYER_BOT])
            client_cmd(human,"spk buttons/blip1.wav")///bot should not play
    }
}
//
// Check whatever player spectator or not
//  @return
//      -1 - no spectator
//      0 - free look mode
//      player id - spectating player
//
stock checkPlayerSpectator(id)
{
    new flags = pev(id, pev_flags)
    new iUser1 = entity_get_int(id,EV_INT_iuser1)
    new iUser2 = entity_get_int(id,EV_INT_iuser2)

    if(iUser1 || iUser2 || flags & FL_SPECTATOR)
        return id
    return -1
}
//
// Set level for new player
//  id - player id
//  handicap - level calculation mode
//
public SetLevel_ForNewPlayer(id,handicap)
{
    new players[MAX_PLAYERS],pnum
    get_players(players,pnum)
    switch(handicap)
    {
        case 1:
        { // calculate average level
            new lvlSum
            for(new i,player ; i < pnum ; ++i)
            {
                player = players[i]
                if(checkPlayerSpectator(id) != -1)
                continue
                lvlSum += playersData[player][PLAYER_CURRENTLEVEL]
            }
            playersData[id][PLAYER_CURRENTLEVEL] = lvlSum / pnum
        }
        case 2:
        { // calculate lowest level
            new lowLvl = 9999
            for(new i,player; i < pnum ; ++i)
            {
                player = players[i]
                if(checkPlayerSpectator(id) != -1)
                continue
                if(playersData[player][PLAYER_CURRENTLEVEL] < lowLvl)
                lowLvl = playersData[player][PLAYER_CURRENTLEVEL]
            }
            playersData[id][PLAYER_CURRENTLEVEL] = lowLvl
        }
    }
}
//
// Player disconnect
//

#if !defined client_disconnect
#define client_disconnected client_disconnect
#endif

public client_disconnected(id)
{
    if(!ggActive)
        return
    Reset_RefilTasks(id)
    if(task_Hud_Id && !playersData[id][PLAYER_BOT])
        remove_task(id + task_Hud_Id)
    #if defined AGHL_COLOR && !defined CSCOLOR
    if(task_RequestColor_Id &&  !playersData[id][PLAYER_BOT])
        remove_task(id + task_RequestColor_Id)
    #endif
    currentPlayers --
    Update_PlayersRanks()
    if(autoSaveTime && !playersData[id][PLAYER_BOT])
    {
        new aSave[autoSaveStruct]
        aSave[ASAVE_LEVEL] = playersData[id][PLAYER_CURRENTLEVEL]
        aSave[ASAVE_KILLS] = playersData[id][PLAYER_KILLS]
        aSave[ASAVE_TIME] = _:get_gametime()
        new authId[36]
        get_user_authid(id,authId,charsmax(authId))
        if(!autoSaveMap)
            autoSaveMap = TrieCreate()
        TrieSetArray(autoSaveMap,authId,aSave,autoSaveStruct)
    }
    if(proLevelPlayed || isEndGame)
        client_cmd(id,"mp3 stop")
}

#if defined AGHL_COLOR && !defined CSCOLOR
public RequestColor_Task(taskId)
{
    new id = taskId - task_RequestColor_Id
    query_client_cvar(id,"hud_colortext","RequestColor_Handler")
}
public RequestColor_Handler(id,cvar[],value[])
    playersData[id][PLAYER_AGHL] = str_to_num(value) == 1
#endif

public ggSpawnEquip = true
//
// Player spawn
//
public On_PlayerSpawn(id)
{
    if(!ggSpawnEquip)
        return HAM_IGNORED
    if(!is_user_alive(id))
    {
        // lalka style fix
        if(isAG && entity_get_int(id,EV_INT_flags) != 8)  // ya 8, a tbi - net azazazazaza
            return HAM_IGNORED
        set_task(0.1,"On_PlayerSpawn",id)
        return HAM_IGNORED
    }
    else
    {
        #if defined DODBOTFIX
        if(!get_user_team(id))
            return HAM_IGNORED
        #endif
        Equip_PlayerWithWeapon(id)
        if(warmUpMode == 3)
            set_pev(id,pev_flags,pev(id,pev_flags) | FL_WORLDBRUSH)
        if(isEndGame)
        {
            set_user_godmode(id,true)
            set_user_gravity(id,0.3)
            set_user_maxspeed(id,0.0) // da ya je freeman
            set_pev(id,pev_flags,pev(id,pev_flags) | FL_FROZEN);
            UTIL_ScreenFade(id,{0,0,0},get_pcvar_float(cvar[CVAR_ENDGAME_DELAY]) / 2.0,10.0,255,1)
            if(!is_user_bot(id))
            {
                set_view(id, CAMERA_3RDPERSON);
            }
        }
    }
    return HAM_IGNORED
}
//
// Player kill
//
public On_PlayerKilled(victim,killer)
{
    if(task_Hud_Id && !playersData[victim][PLAYER_BOT])
    ClearSyncHud(victim,syncInformerHud) // reset hud
    Reset_RefilTasks(victim) // reset refil tasks
    StatusIcon_Display(victim,3)
    if(!(0 < killer <= MaxClients)) // player was killed by world
        return HAM_IGNORED
    if(warmUpMode != 2 || playersData[killer][PLAYER_CURRENTLEVEL] != playersData[killer][PLAYER_LASTLEVEL])
        return HAM_IGNORED
    if(killer == victim && get_pcvar_num(cvar[CVAR_DESCORE]) && !get_pcvar_num(cvar[CVAR_TEAMPLAY]))
    {
        // descore function on selfkill
        playersData[victim][PLAYER_KILLS] --
        if(playersData[victim][PLAYER_KILLS] < 0)
        {
            if(playersData[victim][PLAYER_CURRENTLEVEL])
            {
                playersData[victim][PLAYER_CURRENTLEVEL] --
                //Equip_PlayerWithWeapon(victim)
            }
            else // reset kills for frist level
                playersData[victim][PLAYER_KILLS] = 0
        }
        return HAM_IGNORED
    }
    else if(killer == victim)
        return HAM_IGNORED
    new inflictor = entity_get_edict(victim,EV_ENT_dmg_inflictor) // get inflictor id
    if(killer == inflictor)
    { // player killed by hitscan weapon
        new wId
        if(!(wId = get_user_weapon(killer))) // can't get weapon id
            return HAM_IGNORED
        new weaponName[MAX_PLAYERS]
        if(!get_weaponname(wId,weaponName,charsmax(weaponName)))
            return HAM_IGNORED
        if(playersData[killer][PLAYER_INFLICTORS] && !TrieKeyExists(playersData[killer][PLAYER_INFLICTORS],weaponName))
            return HAM_IGNORED
    }
    else
    {
        new infClassname[MAX_PLAYERS]
        entity_get_string(inflictor,EV_SZ_classname,infClassname,charsmax(infClassname))
        if(playersData[killer][PLAYER_INFLICTORS] &&  !TrieKeyExists(playersData[killer][PLAYER_INFLICTORS],infClassname))
        return HAM_IGNORED
    }
    playersData[killer][PLAYER_KILLS] ++
    if(prolevel_music[0] && !proLevelPlayed  && playersData[killer][PLAYER_CURRENTLEVEL] == maxLevel - 1 &&
    ((playersData[killer][PLAYER_NEEDKILLS] - playersData[killer][PLAYER_KILLS])  == 1))
    {
        proLevelPlayed = true
        Play_ProLevelMusic()
    }
    if(playersData[killer][PLAYER_KILLS] >= playersData[killer][PLAYER_NEEDKILLS])
    { // level up
        playersData[killer][PLAYER_CURRENTLEVEL] ++
        // lets wait for weapon attack post
        set_task(0.1,"ReEquip_Player",task_Equip_Id + killer)
        if(get_pcvar_num(cvar[CVAR_TEAMPLAY]))
        {
            if(playersData[killer][PLAYER_CURRENTLEVEL] != maxLevel)
            gg_notify_msg(killer, playersData[killer][PLAYER_CURRENTLEVEL] != maxLevel - 1 ? NOTIFY_UP: NOTIFY_LAST)
            Update_TeamData(killer)
        }
        return HAM_IGNORED
    }
    // 2.1
    if(get_pcvar_num(cvar[CVAR_TEAMPLAY]))
    Update_TeamData(killer)
    Update_PlayersRanks()
    return HAM_IGNORED
}
//
// Update level and score for all teamates
//
Update_TeamData(id)
{
    new teamName[16]
    if(!get_user_team(id,teamName,charsmax(teamName)))
        return false
    new players[MAX_PLAYERS],pnum
    get_players(players,pnum,"e",teamName)
    for(new i, player; i < pnum ; ++i)
    {
        player = players[i]
        if(player == id)
            continue
        playersData[player][PLAYER_KILLS] = playersData[id][PLAYER_KILLS]
        if(playersData[player][PLAYER_CURRENTLEVEL] != playersData[id][PLAYER_CURRENTLEVEL])
        {
            playersData[player][PLAYER_CURRENTLEVEL] = playersData[id][PLAYER_CURRENTLEVEL]
            set_task(0.12,"ReEquip_Player",task_Equip_Id + player)  // oppa supa fix
        }
    }
    return true
}
//
// Delayed equip task
//
public ReEquip_Player(taskId)
{
    new id = taskId - task_Equip_Id
    if(is_user_alive(id))
    {
        Reset_RefilTasks(id)
        Equip_PlayerWithWeapon(id)
    }
}
//
// Player damage
//
public On_PlayerTakeDamage(victim,inflictor,attacker)
{
    if(victim == attacker || !(0 < attacker <= MaxClients))
    {
        if(inflictor > MaxClients && entity_get_int(inflictor,EV_INT_iuser4))
        return HAM_SUPERCEDE
        return HAM_IGNORED
    }
    if(inflictor != attacker && playersData[attacker][PLAYER_INFLICTORS])
    {
        new infClassname[MAX_PLAYERS]
        entity_get_string(inflictor,EV_SZ_classname,infClassname,charsmax(infClassname))
        if(playersData[attacker][PLAYER_INFLICTORS] && !TrieKeyExists(playersData[attacker][PLAYER_INFLICTORS],infClassname))
        {
            new victimOrigin[3]
            get_user_origin(victim,victimOrigin)
            client_cmd(attacker,"spk ^"%s^"",noDmgSnds[random(sizeof noDmgSnds - 1)])
            for(new i ; i < 5 ; i++)
            {
                new sparkOrigin[3]
                sparkOrigin[0] = victimOrigin[0] + random_num(-16,16)
                sparkOrigin[1] = victimOrigin[1] + random_num(-16,16)
                sparkOrigin[2] = victimOrigin[2] + random_num(-36,36)
                message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,sparkOrigin,attacker)
                write_byte(TE_SPARKS)
                write_coord(sparkOrigin[0])
                write_coord(sparkOrigin[1])
                write_coord(sparkOrigin[2])
                message_end()
            }
            return HAM_SUPERCEDE
        }
    }
    return HAM_IGNORED
}
//
// Trace attack
//
public On_TraceAttack(victim,attacker)
{
    if(!(0 < attacker <= MaxClients))
    return HAM_IGNORED
    static weaponName[MAX_PLAYERS],weaponId
    weaponId = get_user_weapon(attacker)
    if(!weaponId || !get_weaponname(weaponId,weaponName,charsmax(weaponName)))
    return HAM_SUPERCEDE
    if(playersData[attacker][PLAYER_INFLICTORS] && !TrieKeyExists(playersData[attacker][PLAYER_INFLICTORS],weaponName))
    {
        new victimOrigin[3]
        get_user_origin(victim,victimOrigin)
        client_cmd(attacker,"spk ^"%s^"",noDmgSnds[random(sizeof noDmgSnds - 1)])
        for(new i ; i < 5 ; i++)
        {
            new sparkOrigin[3]
            sparkOrigin[0] = victimOrigin[0] + random_num(-16,16)
            sparkOrigin[1] = victimOrigin[1] + random_num(-16,16)
            sparkOrigin[2] = victimOrigin[2] + random_num(-16,16)
            message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,sparkOrigin,attacker)
            write_byte(TE_SPARKS)
            write_coord(sparkOrigin[0])
            write_coord(sparkOrigin[1])
            write_coord(sparkOrigin[2])
            message_end()
        }
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}
#if AMXX_VERSION_NUM == 182
#define USE_ON 1.0
#endif
//
// Equip player with level weapon
//
public Equip_PlayerWithWeapon(const id)
{
    if(checkPlayerSpectator(id) != -1)

    ExecuteForward(fwdEquip,fwdRet,id)
    ExecuteHam(Ham_Use,striper,id,id,USE_ON,0.0) // strip player's weapons
    if(isEndGame)
        return
    if(playersData[id][PLAYER_CURRENTLEVEL] >= maxLevel)
    {
        // do endgame stuff
        endgame(id)
        return
    }
    new bool:isTeamPlay = get_pcvar_num(cvar[CVAR_TEAMPLAY]) == 1
    // 2.1
    if(isTeamPlay && warmUpMode != 1)
    {
        new teamName[MAX_IP_LENGTH]
        new teamIndex = get_user_team(id,teamName,charsmax(teamName))
        if(playersData[id][PLAYER_TEAM] != teamIndex)
        {  // recheck data for matching team stats
            new players[MAX_PLAYERS],pnum
            get_players(players,pnum,"e",teamName)
            if(pnum > 1)
            {   // can get valid inf
                for(new i,player ; i < pnum ; i++)
                {
                    player = players[i]
                    if(player == id)
                    continue
                    playersData[id][PLAYER_CURRENTLEVEL] = playersData[player][PLAYER_CURRENTLEVEL]
                    playersData[id][PLAYER_LASTLEVEL] = playersData[player][PLAYER_LASTLEVEL]
                    playersData[id][PLAYER_KILLS] = playersData[player][PLAYER_KILLS]
                    playersData[id][PLAYER_NEEDKILLS] = playersData[player][PLAYER_NEEDKILLS]
                    copy(playersData[id][PLAYER_WEAPONNAME], charsmax(playersData[][PLAYER_ICON]), playersData[player][PLAYER_WEAPONNAME])
                    copy(playersData[id][PLAYER_ICON],charsmax(playersData[][PLAYER_ICON]),playersData[player][PLAYER_ICON])
                    playersData[id][PLAYER_TEAM] = playersData[player][PLAYER_TEAM]
                    playersData[id][PLAYER_INFLICTORS] = _:playersData[player][PLAYER_INFLICTORS]
                    playersData[id][PLAYER_NOREFIL] = _:playersData[player][PLAYER_NOREFIL]
                    if(task_Hud_Id && !playersData[id][PLAYER_BOT] && !task_exists(id + task_Hud_Id)) // setup hud informer task for first time
                    {
                        set_task(0.5,"Show_HudInformer",id + task_Hud_Id,.flags = "b")
                        break
                    }
                }
            }
            else
            {
                // inital
                playersData[id][PLAYER_TEAM] = teamIndex
            }
        }
    }
    // get level wepons details
    new weaponSet[weaponSetStruct]
    ArrayGetArray(warmUpMode == 2 ? weaponSets : warmUpSet,playersData[id][PLAYER_CURRENTLEVEL],weaponSet)
    if(!playersData[id][PLAYER_BOT])
    {
        if(playersData[id][PLAYER_LASTLEVEL] == playersData[id][PLAYER_CURRENTLEVEL] && warmUpMode == 2)
        {
            StatusIcon_Display(id,0)
        }
        else
        {
            new data[3]
            data[0]=  id
            data[1] = 1
            data[2] = floatround(get_gametime() + blinkTime)
            set_task(0.1,"StatusIcon_Blink",task_Icon_Blink + id,data,sizeof data)
        }
    }
    if(playersData[id][PLAYER_CURRENTLEVEL] != playersData[id][PLAYER_LASTLEVEL] && warmUpMode == 2)
    {
        if(task_Hud_Id && !playersData[id][PLAYER_BOT] && !task_exists(id + task_Hud_Id) && !playersData[id][PLAYER_BOT]) // setup hud informer task for first time
            set_task(0.5,"Show_HudInformer",id + task_Hud_Id,.flags = "b")
        if(!isVoteStarted && get_pcvar_num(cvar[CVAR_MAPCHANGES_STYLE]) == 2 && (playersData[id][PLAYER_CURRENTLEVEL] > maxLevel - get_pcvar_num(cvar[CVAR_NEARLEVEL])))
        {
            start_map_vote(1.0)
        }
        new bool:levelSkipped
        if(!isTeamPlay)
        {
            // no skip with teamplay
            while(weaponSet[WSET_SKIP] && currentPlayers < weaponSet[WSET_SKIP] && playersData[id][PLAYER_CURRENTLEVEL] > playersData[id][PLAYER_LASTLEVEL]
            || playersData[id][PLAYER_BOT] && weaponSet[WSET_BOTCANT]){ // skip level for bot or on low plr count
            if(playersData[id][PLAYER_ICON])
            {
                StatusIcon_Display(id,3) // go nuts, when the bass go boom
                playersData[id][PLAYER_ICON][0] = 0
            }
            playersData[id][PLAYER_CURRENTLEVEL] ++
            if(playersData[id][PLAYER_CURRENTLEVEL] == maxLevel)
            {
                endgame(id)
                return
            }
            ArrayGetArray(weaponSets,playersData[id][PLAYER_CURRENTLEVEL],weaponSet)
            levelSkipped = true
            }
        }
        copy(playersData[id][PLAYER_WEAPONNAME], charsmax(playersData[]), weaponSet[WSET_SHOWNAME])
        playersData[id][PLAYER_NEEDKILLS] = !isTeamPlay ? weaponSet[WSET_KILLS] : floatround(float(weaponSet[WSET_KILLS]) * get_pcvar_float(cvar[CVAR_TEAMMULGOAL]))
        playersData[id][PLAYER_INFLICTORS] = _:weaponSet[WSET_INFLICTORS_MAP]
        playersData[id][PLAYER_NOREFIL] = _:weaponSet[WSET_NOREFIL_MAP]
        //  remove all inflictors on level change
        if(playersData[id][PLAYER_LASTLEVEL] >= 0)
        {
            new lastSet[weaponSetStruct]
            ArrayGetArray(weaponSets,playersData[id][PLAYER_LASTLEVEL],lastSet)
            if(lastSet[WSET_INFARRAY])
            Inflictors_DestroyAll(id,lastSet[WSET_INFARRAY])
        }
        // draw 3 next levels in hud
        if( (!playersData[id][PLAYER_BOT]))
        {
            if(is_user_admin(id))
            {
                Draw_LevelsInHud(id,3);
            }
        } // TODO: cvar ? ///crashes windows clients

        if(playersData[id][PLAYER_CURRENTLEVEL] > playersData[id][PLAYER_LASTLEVEL] && playersData[id][PLAYER_LASTLEVEL] != -1)
        {
            // do levelup stuff
            if(sound_levelup[0])
            client_cmd(id,"spk ^"%s^"",sound_levelup)
            new fadeColor[3]
            fadeColor[0] = random_num(0,255)
            fadeColor[1] = random_num(0,255)
            fadeColor[2] = random_num(0,255)
            UTIL_ScreenFade(id,fadeColor,0.1,0.1,128)
            UTIL_TeleportEffectForPlayer(id)
            StatusIcon_Display(id,3)
            if(is_user_alive(id)){
            if(get_pcvar_num(cvar[CVAR_RESTORE_HP]))
            set_user_health(id,get_pcvar_num(cvar[CVAR_DEFAULT_HP]))
            if(get_pcvar_num(cvar[CVAR_UPARMOR]))
            if(random_num(0,2)==1&&!(get_user_armor(id)+get_pcvar_num(cvar[CVAR_UPARMOR])> get_pcvar_num(cvar[CVAR_DEFAULT_AP])))
            set_user_armor(id,get_user_armor(id)+get_pcvar_num(cvar[CVAR_UPARMOR]))
            }
            playersData[id][PLAYER_KILLS] = 0
            // ïðîäàì ãàðàæ
            if(!isTeamPlay)
            {
                if(!levelSkipped)
                {
                    gg_notify_msg(id, playersData[id][PLAYER_CURRENTLEVEL] != maxLevel - 1 ? NOTIFY_UP : NOTIFY_LAST)
                }
                else
                {
                    gg_notify_msg(id,NOTIFY_SKIP)
                }
            }
            if(fwdLevelUp)
                ExecuteForward(fwdLevelUp,fwdRet,id,playersData[id][PLAYER_CURRENTLEVEL],playersData[id][PLAYER_LASTLEVEL])
        }
        else if(playersData[id][PLAYER_CURRENTLEVEL] < playersData[id][PLAYER_LASTLEVEL])
        {
            // do leveldown stuff
            playersData[id][PLAYER_KILLS] = weaponSet[WSET_KILLS] - 1
            if(sound_leveldown[0])
            client_cmd(id,"spk ^"%s^"",sound_leveldown)
            UTIL_ScreenFade(id,{0.0,0.0,0.0},0.1,0.1,156)
            UTIL_TeleportEffectForPlayer(id)
            StatusIcon_Display(id,3)
            gg_notify_msg(id,NOTIFY_DOWN)
            if(fwdLevelUp)
                ExecuteForward(fwdLevelUp,fwdRet,id,playersData[id][PLAYER_CURRENTLEVEL],playersData[id][PLAYER_LASTLEVEL])
        }
        copy(playersData[id][PLAYER_ICON],charsmax(playersData[]), weaponSet[WSET_ICONSPRITE])
        Update_PlayersRanks()
        playersData[id][PLAYER_LASTLEVEL] = playersData[id][PLAYER_CURRENTLEVEL]
    }
    if(prolevel_music[0] && !proLevelPlayed  && playersData[id][PLAYER_CURRENTLEVEL] == maxLevel - 1
    && ((playersData[id][PLAYER_NEEDKILLS] - playersData[id][PLAYER_KILLS])  == 1))
    {
        proLevelPlayed = true
        Play_ProLevelMusic()
    }
    if(!is_user_alive(id))
        return
    if(weaponSet[WSET_EQUIP_ITEMS])
    {
        new equipItem[equipStruct]
        for(new i,count = ArraySize(weaponSet[WSET_EQUIP_ITEMS]) ; i < count ; ++i)
        {
            ArrayGetArray(weaponSet[WSET_EQUIP_ITEMS],i,equipItem)
            Add_PlayerWeapon(id,equipItem,weaponSet)
            if(!i)
            {
                new inf[MAX_PLAYERS + 1]
                inf[0] = id
                formatex(inf[1],charsmax(inf) - 1,equipItem[EQUIP_NAME])
                set_task(0.3,"Change_Weapon",task_Change_Id + id,inf,sizeof inf)
            }
        }
    }
    // inflictor ammo settings
    if(!playersData[id][PLAYER_NOREFIL] && weaponSet[WSET_INFARRAY])
    {
        new inflictor[MAX_PLAYERS],inflictorAmmo[weaponAmmoStruct]
        new ammoKey[10],inflictorData[4]
        // update ammo cache for level inflictors
        for(new i,infSize = ArraySize(weaponSet[WSET_INFARRAY]) ; i < infSize ; i++)
        {
            ArrayGetString(weaponSet[WSET_INFARRAY],i,inflictor,charsmax(inflictor))
            TrieGetArray(weaponSet[WSET_INFLICTORS_MAP],inflictor,inflictorData,sizeof inflictorData)
            if(!inflictorData[0]) // don't need to update, unlimited ammo for this inflictor
            continue
            if(!TrieGetArray(weaponAmmoTrie,inflictor,inflictorAmmo,weaponAmmoStruct)) // no valid ammoid for this inflictor
            continue
            num_to_str(inflictorAmmo[WAMMO_PRIMARY_AMMOID],ammoKey,charsmax(ammoKey))
            if(!weaponSet[WSET_NOREFIL_MAP])
            weaponSet[WSET_NOREFIL_MAP] = _:TrieCreate()
            // remember ammo id for feature use
            inflictorData[2] = inflictorAmmo[WAMMO_PRIMARY_AMMOID]
            inflictorData[3] = inflictorAmmo[WAMMO_SECONDARY_AMMOID]
            TrieSetCell(weaponSet[WSET_NOREFIL_MAP],ammoKey,true)
            TrieSetArray(weaponSet[WSET_INFLICTORS_MAP],inflictor,inflictorData,sizeof inflictorData)
            // set ammo by depending on inflictors count
            set_pdata_int(id, modOffsets[m_rgAmmo] + inflictorAmmo[WAMMO_PRIMARY_AMMOID] - modOffsets[offsetAmmoDiff], inflictorData[0])
        }
    }
    else if(weaponSet[WSET_INFARRAY])
    {
        // read ammo cache for level inflictors
        new inflictor[MAX_PLAYERS],inflictorData[4]
        for(new i,infSize = ArraySize(weaponSet[WSET_INFARRAY]) ; i < infSize ; i++)
        {
            ArrayGetString(weaponSet[WSET_INFARRAY],i,inflictor,charsmax(inflictor))
            if(!TrieGetArray(weaponSet[WSET_INFLICTORS_MAP],inflictor,inflictorData,sizeof inflictorData))
            continue
            new entCount,stEnt
            while((stEnt = find_ent_by_class(stEnt,inflictor))) // count all exists inflictors
            if(entity_get_edict(stEnt,EV_ENT_owner) == id || entity_get_int(stEnt,EV_INT_iuser3) == id)
                entCount ++
            inflictorData[0] = clamp(inflictorData[0] - entCount,0,cellmax)
            // set ammo by depending on inflictor limit
            set_pdata_int(id, modOffsets[m_rgAmmo] + inflictorData[2] - modOffsets[offsetAmmoDiff], inflictorData[0])
        }
    }
    if(!playersData[id][PLAYER_NOREFIL] && weaponSet[WSET_NOREFIL_MAP])
    {
        // update no ininity ammo map
        ArraySetArray(weaponSets,playersData[id][PLAYER_CURRENTLEVEL],weaponSet)
        playersData[id][PLAYER_NOREFIL] = _:weaponSet[WSET_NOREFIL_MAP]
    }
}
//
// Draw next levels in hud
//  id - player id
//  num - number of next levels to display
//
Draw_LevelsInHud(id,num)
{
    new weaponSet[weaponSetStruct]
    for(new i = playersData[id][PLAYER_CURRENTLEVEL],equipItem[equipStruct] ; i < playersData[id][PLAYER_CURRENTLEVEL] + num && i < maxLevel;i++)
    {
        ArrayGetArray(weaponSets,i,weaponSet)
        if(!weaponSet[WSET_EQUIP_ITEMS])
        continue
        new weaponId
        ArrayGetArray(weaponSet[WSET_EQUIP_ITEMS],0,equipItem) // get equipment to display
        if((weaponId = get_weaponid(equipItem[EQUIP_NAME])))
        {
            new weaponAmmo[weaponAmmoStruct]
            if(TrieGetArray(weaponAmmoTrie,equipItem[EQUIP_NAME],weaponAmmo,weaponAmmoStruct) &&
            !get_pdata_int(id,modOffsets[m_rgAmmo] + weaponAmmo[WAMMO_PRIMARY_AMMOID] - modOffsets[offsetAmmoDiff]))
            {
                Update_AmmoX(id,weaponAmmo[WAMMO_PRIMARY_AMMOID],1)
            }
            // trick client to prevent out of ammo red hud
        }
        // draw in hud
        Update_WeapPickup(id,weaponId)
    }
}
//
// Delayed weapon change
//  inf[] - data string
//      inf[0] - player id
//      inf[1] - weapon class name
//
public Change_Weapon(inf[])
{
    new id = inf[0]
    engclient_cmd(id,inf[1])
}
//
// Add player weapon
//
public Add_PlayerWeapon(id,equipItem[equipStruct],weaponSet[weaponSetStruct])
{
    #if !defined HLWPNMOD
    new equipEnt = give_item(id,equipItem[EQUIP_NAME])
    #else
    new equipEnt
    if(wpnModMap && TrieKeyExists(wpnModMap,equipItem[EQUIP_NAME]))
    {
        equipEnt = wpnmod_give_item(id,equipItem[EQUIP_NAME])
        if(playersData[id][PLAYER_BOT] && !user_has_weapon(id,HLW_CROWBAR))
        give_item(id,"weapon_crowbar")
    }
    else
        equipEnt = give_item(id,equipItem[EQUIP_NAME])
    #endif
    if(pev_valid(equipEnt) != 2)
        return
    new weaponAmmo[weaponAmmoStruct]
    if(!weaponAmmoTrie || !TrieGetArray(weaponAmmoTrie,equipItem[EQUIP_NAME],weaponAmmo,weaponAmmoStruct))
        return
    for(new i ; i < 2 ; ++i)
    {
        // ammo functions
        if(weaponAmmo[WAMMO_PRIMARY_AMMOID + i] == -1)
        continue
        if(equipItem[EQUIP_FULL_PRIMARY + i]) // full ammo on spawn
        set_pdata_int(id,modOffsets[m_rgAmmo] + weaponAmmo[WAMMO_PRIMARY_AMMOID + i] - modOffsets[offsetAmmoDiff],weaponAmmo[WAMMO_PRIMARY_MAXAMMO + i])
        else if(equipItem[EQUIP_PRIMARY_REFIL_TIME +i] == 0.0 && equipItem[EQUIP_PRIMARY_REFIL_AMMOUNT + i]) // or refil ammo if no refil time specifed
        set_pdata_int(id,modOffsets[m_rgAmmo] + weaponAmmo[WAMMO_PRIMARY_AMMOID + i] - modOffsets[offsetAmmoDiff],equipItem[EQUIP_PRIMARY_REFIL_AMMOUNT + i])
        else
        {
            set_pdata_int(id,modOffsets[m_rgAmmo] + weaponAmmo[WAMMO_PRIMARY_AMMOID + i] - modOffsets[offsetAmmoDiff],0)
            Update_AmmoX(id,weaponAmmo[WAMMO_PRIMARY_AMMOID + i],0)
        }
        if(equipItem[EQUIP_PRIMARY_REFIL_TIME + i] > 0.0)
        {
            // set ammo refil tasks
            if(!playersData[id][PLAYER_NOREFIL]){ // update no ininity ammo map
            if(!weaponSet[WSET_NOREFIL_MAP])
            weaponSet[WSET_NOREFIL_MAP] = _:TrieCreate()
            new ammoKey[10]
            num_to_str(weaponAmmo[WAMMO_PRIMARY_AMMOID + i],ammoKey,charsmax(ammoKey))
            TrieSetCell(weaponSet[WSET_NOREFIL_MAP],ammoKey,1)
            }
            Set_RefilTask(id,
            weaponAmmo[WAMMO_PRIMARY_AMMOID + i],
            weaponAmmo[WAMMO_PRIMARY_MAXAMMO + i],
            equipItem[EQUIP_PRIMARY_REFIL_AMMOUNT + i],
            Float:equipItem[EQUIP_PRIMARY_REFIL_TIME + i],
            get_weaponid(equipItem[EQUIP_NAME]))
        }
    }
    if(equipItem[EQUIP_CLIP] > -1)
    set_pdata_int(equipEnt,modOffsets[m_iClip],equipItem[EQUIP_CLIP],extraoffset_weapon)
}
//
// Set ammo refil task
//
public Set_RefilTask(const id,const ammoId,const maxAmmo,const ammount,const Float:refilTime,const wId)
{
    new taskId = task_Refill_Id + (id * task_Refill_Max) // allocate task id
    // found new taks id
    while(task_exists(taskId))
    {
        if(-- taskId < (task_Refill_Id + (id * task_Refill_Max)) - task_Refill_Max) // no more tasks avaliable
            return false
    }
    new taskData[refilTaskStruct]
    taskData[REFIL_PLAYERID] = id
    taskData[REFIL_WEAPONID] = wId
    taskData[REFIL_AMMOID] = ammoId
    taskData[REFIL_AMMOUNT] = ammount
    taskData[REFIL_MAXAMMO] = maxAmmo
    taskData[REFIL_TASKID] = taskId
    set_task(refilTime,"Run_RefilTask",taskId,taskData,refilTaskStruct,"b") // run task
    return true
}
//
// Process refil task
//
public Run_RefilTask(taskData[refilTaskStruct])
{
    new currentAmmo = get_pdata_int(taskData[REFIL_PLAYERID],modOffsets[m_rgAmmo] + taskData[REFIL_AMMOID] - modOffsets[offsetAmmoDiff])
    if(currentAmmo >= taskData[REFIL_MAXAMMO])
        return PLUGIN_CONTINUE
    currentAmmo = clamp(currentAmmo + taskData[REFIL_AMMOUNT],0,taskData[REFIL_MAXAMMO])
    if(!user_has_weapon(taskData[REFIL_PLAYERID],taskData[REFIL_WEAPONID]))
    {
        new weaponName[MAX_PLAYERS]
        get_weaponname(taskData[REFIL_WEAPONID],weaponName,charsmax(weaponName))
        give_item(taskData[REFIL_PLAYERID],weaponName)
    }
    else
    Ammo_PickUpMaster(taskData[REFIL_PLAYERID],taskData[REFIL_AMMOID],taskData[REFIL_AMMOUNT])
    set_pdata_int(taskData[REFIL_PLAYERID],modOffsets[m_rgAmmo] + taskData[REFIL_AMMOID] - modOffsets[offsetAmmoDiff],currentAmmo)
    return PLUGIN_CONTINUE
}
//
// Reset refil tasks
//
public Reset_RefilTasks(const id)
{
    new taskId = task_Refill_Id + (id * task_Refill_Max)
    // freeman on the high mazafaka come get some
    while(task_exists(taskId))
    {
        remove_task(taskId)
        if(taskId >= (task_Refill_Id + (id * task_Refill_Max)) - task_Refill_Max)
        taskId --
    }
}
//
// Show status icon
//  id - player id
//  toShow - icon state
//      0 - display with normal color
//      1 - display with color1
//      2 - display with color2
//      3 - hide status icon
//
public StatusIcon_Display(id,toShow)
{
    if(!StatusIcon || playersData[id][PLAYER_BOT] || !playersData[id][PLAYER_ICON])
        return
    if(!isValve)
    {
        message_begin(MSG_ONE_UNRELIABLE,StatusIcon,{0.0,0.0,0.0},id)
    }
    else
    {
        engfunc(EngFunc_MessageBegin,MSG_ONE,StatusIcon,{0.0,0.0,0.0},id)
    }
    write_byte(toShow != 3 ? 1 : 0)
    write_string(playersData[id][PLAYER_ICON])
    // TODO: recode this shit
    switch(toShow)
    {
        case 0:
        {
            write_byte(iconColors[0])
            write_byte(iconColors[1])
            write_byte(iconColors[2])
        }
        case 1:
        {
            write_byte(iconColors[3])
            write_byte(iconColors[4])
            write_byte(iconColors[5])
        }
        case 2:
        {
            write_byte(iconColors[6])
            write_byte(iconColors[7])
            write_byte(iconColors[8])
        }
    }
    message_end()
}
//
// Blink status icon
//  data[3]
//      0 - player id
//      1 - last state
//      2 - end blink time
//
public StatusIcon_Blink(data[3])
{
    new id = data[0]
    new theState = data[1]
    new lastBlink = data[2]
    if(!is_user_alive(id) || isEndGame)
        return
    if(lastBlink < floatround(get_gametime()))
    {
        StatusIcon_Display(id,0)
        return
    }
    theState ++
    if(theState == 3)
    theState = 1
    data[1] = theState
    StatusIcon_Display(id,theState)
    set_task(0.3,"StatusIcon_Blink",task_Icon_Blink + id,data,sizeof data)
}
//
// Infinity ammo
//
public MSG_AmmoX(MSG_Dest,MSG_ID,id)
{
    #define MSG_AMMOX_AMMOID    1
    #define MSG_AMMOX_AMMOUNT   2

    if(!is_user_alive(id))
        return PLUGIN_HANDLED

    if(ammoMaxMap == Invalid_Trie) // ammo map not initialized yet
        return PLUGIN_CONTINUE

    static ammoId,ammoAmmount,ammoKey[10],maxAmmo
    ammoId = get_msg_arg_int(MSG_AMMOX_AMMOID)
    num_to_str(ammoId,ammoKey,charsmax(ammoKey))
    // disable infinity ammo for refil
    if( playersData[id][PLAYER_NOREFIL] && TrieKeyExists(playersData[id][PLAYER_NOREFIL],ammoKey))
        return PLUGIN_CONTINUE
    if(!TrieGetCell(ammoMaxMap,ammoKey,maxAmmo)) // check for ammo id
        return PLUGIN_CONTINUE
    ammoAmmount = get_msg_arg_int(MSG_AMMOX_AMMOUNT)
    if(ammoAmmount < maxAmmo)
    {
        // reset to max ammo
        set_pdata_int(id,modOffsets[m_rgAmmo] + ammoId -  modOffsets[offsetAmmoDiff],maxAmmo)
        return PLUGIN_HANDLED // and block hud update
    }
    return PLUGIN_CONTINUE
}
//
// Update player HUD ammo value
//  id - player
//  ammoId - ammo id
//  ammoAmount - new ammo value
//
Update_AmmoX(const id,const ammoId,const ammoAmount)
{
    message_begin(MSG_ONE,AmmoX,.player = id)
    write_byte(ammoId)
    write_byte(ammoAmount)
    message_end()
}
//
// Draw weapon pickup icon
//  id - player id
//  wid - weaponid
//
Update_WeapPickup(const id,const wpId)
{
    message_begin(MSG_ONE_UNRELIABLE,WeapPickup,.player = id)
    write_byte(wpId)
    message_end()
}
Ammo_PickUpMaster(const id,const ammoId,const ammoValue)
{
    if(!AmmoPickup) // vedb tak? - powel tbi!
        return
    message_begin(MSG_ONE_UNRELIABLE,AmmoPickup,.player = id)
    write_byte(ammoId)
    write_byte(ammoValue)
    message_end()
}
//
// Notify players by chat messages
//  id - invoker
//  notifyId - message type
//
public gg_notify_msg(id,notifyId)
{
    if(!(chatInformerBitsum & (1 << notifyId)))
        return
    new teamName[16]
    new teamId = get_user_team(id,teamName,charsmax(teamName))
    // check for teammode messages
    if(get_pcvar_num(cvar[CVAR_TEAMPLAY]))
    {
        static lastTeamId,lastTeamLevel // super object oriented method by serfreeman1337
        if(lastTeamId == playersData[id][PLAYER_TEAM] && lastTeamLevel == playersData[id][PLAYER_CURRENTLEVEL])
        return
        lastTeamId = playersData[id][PLAYER_TEAM]
        lastTeamLevel = playersData[id][PLAYER_CURRENTLEVEL]
        switch(notifyId)
        {
            case NOTIFY_UP:
            {
                notifyId = NOTIFY_TEAMUP
                new weaponSet[weaponSetStruct]
                ArrayGetArray(weaponSets,playersData[id][PLAYER_CURRENTLEVEL],weaponSet)
                copy(playersData[id][PLAYER_WEAPONNAME],
                charsmax(playersData[][PLAYER_WEAPONNAME]),
                weaponSet[WSET_SHOWNAME])
            }
            case NOTIFY_WIN:notifyId = NOTIFY_TEAMWIN
            case NOTIFY_LAST: notifyId = NOTIFY_TEAMLAST
        }
    }
    // your banny wrote
    enum _:teamLangPointer {
    T[20],
    O[20],
    S[20]
    }
    static const plrLangSelf[NOTIFY_DISABLED + 1][] = {
    "LEVEL_SELF",
    "LEVEL_SELF",
    "LEVEL_SELF",
    "LEVEL_SELF_LST",
    "SKIP_LESSPLR",
    "WINNER_SELF",
    "MODENABLED",
    "MODDISABLED"
    }
    static const plrLangOther[NOTIFY_DISABLED + 1][] = {
    "LEVEL_UP_MSG",
    "LEVEL_DOWN_MSG",
    "LEVEL_NOW_MSG",
    "REACHED_LAST_LEVEL",
    "SKIP_MSG",
    "WINNER_MSG",
    "MODENABLED",
    "MODDISABLED"
    }
    static const plrLangTeam[][teamLangPointer] = {
    {"TEAM_LEVELUP_T","TEAM_LEVELUP_O","TEAM_LEVELUP_S"},
    {"TEAM_WIN_T","TEAM_WIN_O","TEAM_WIN_S"},
    {"TEAM_LAST_S","TEAM_LAST_O","TEAM_LAST_S"}
    }
    #if defined AGHL_COLOR
    static const plrLangSelfClr[NOTIFY_DISABLED + 1][] = {
    "LEVEL_SELF_CLR",
    "LEVEL_SELF_CLR",
    "LEVEL_SELF_CLR",
    "LEVEL_SELF_LST_CLR",
    "SKIP_LESSPLR_CLR",
    "WINNER_SELF_CLR",
    "MODENABLED_CLR",
    "MODDISABLED_CLR"
    }
    static const plrLangOtherClr[NOTIFY_DISABLED + 1][] = {
    "LEVEL_UP_MSG_CLR",
    "LEVEL_DOWN_MSG_CLR",
    "LEVEL_NOW_MSG_CLR",
    "REACHED_LAST_LEVEL_CLR",
    "SKIP_MSG_CLR",
    "WINNER_MSG_CLR",
    "MODENABLED_CLR",
    "MODDISABLED_CLR"
    }
    static const plrLangTeamClr[][teamLangPointer] = {
    {"TEAM_LEVELUP_T_CLR","TEAM_LEVELUP_O_CLR","TEAM_LEVELUP_S_CLR"},
    {"TEAM_WIN_T_CLR","TEAM_WIN_O_CLR","TEAM_WIN_S_CLR"},
    {"TEAM_LAST_S_CLR","TEAM_LAST_O_CLR","TEAM_LAST_S_CLR"}
    }
    #endif
    #if defined CSCOLOR
    if(teamId >= sizeof chatTeamColor || teamId < 0)
        teamId = 0
    #endif
    new players[MAX_PLAYERS],pnum,name[MAX_PLAYERS],message[128],len
    get_players(players,pnum,"c")
    get_user_name(id,name,charsmax(name))
    // message to self
    if(!playersData[id][PLAYER_BOT] && id)
    {
        #if defined AGHL_COLOR
        len += formatex(message[len],charsmax(message) - len,"%L ",id,!playersData[id][PLAYER_AGHL] ? "CHAT_TAG" : "CHAT_TAG_CLR")
        #else
        len += formatex(message[len],charsmax(message) - len,"%L ",id,"CHAT_TAG")
        #endif
        switch(notifyId)
        {
            #if defined AGHL_COLOR
            case NOTIFY_TEAMUP,NOTIFY_TEAMWIN,NOTIFY_TEAMLAST:
            {
                if(!playersData[id][PLAYER_AGHL])
                {
                    len += formatex(message[len],charsmax(message) - len,"%L",
                    id,plrLangTeam[notifyId - (NOTIFY_TEAMWIN - 1)][S] ,
                    playersData[id][PLAYER_CURRENTLEVEL] + 1,
                    playersData[id][PLAYER_WEAPONNAME])
                }
                else
                {
                    len += formatex(message[len],charsmax(message) - len,"%L",
                    id,plrLangTeamClr[notifyId - (NOTIFY_TEAMWIN - 1)][S] ,
                    playersData[id][PLAYER_CURRENTLEVEL] + 1,
                    playersData[id][PLAYER_WEAPONNAME])
                }
            }
            case NOTIFY_ENABLED,NOTIFY_DISABLED:
            {
                if(!playersData[id][PLAYER_AGHL])
                    len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangSelf[notifyId])
                else
                    len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangSelfClr[notifyId])
            }
            default:
            {
                if(!playersData[id][PLAYER_AGHL])
                len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangSelf[notifyId],
                playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME]
                )
                else
                len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangSelfClr[notifyId],
                playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
            }
            #else
            case NOTIFY_TEAMUP,NOTIFY_TEAMWIN:
            {
                len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangTeam[notifyId - (NOTIFY_TEAMWIN - 1)][S],
                playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
            }
            case NOTIFY_ENABLED,NOTIFY_DISABLED:
            {
                len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangSelf[notifyId])
            }
            default:
            {
                len += formatex(message[len],charsmax(message) - len,"%L",
                id,plrLangSelf[notifyId],
                playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
            }
            #endif
        }
        #if defined CSCOLOR
        client_print_color(id,chatTeamColor[teamId],message)
        #else
        client_print(id,print_chat,message)
        #endif
    }
    // send message to players
    for(new i,player ; i < pnum ; i++)
    {
        player = players[i]
        if(player == id)
        continue
        len = 0
        #if defined AGHL_COLOR
        len += formatex(message[len],charsmax(message) - len,"%L ",player,!playersData[player][PLAYER_AGHL] ? "CHAT_TAG" : "CHAT_TAG_CLR")
        #else
        len += formatex(message[len],charsmax(message) - len,"%L ",player,"CHAT_TAG")
        #endif
        switch(notifyId)
        {
            case NOTIFY_TEAMUP,NOTIFY_TEAMWIN,NOTIFY_TEAMLAST:
            {
                // team messages
                #if defined AGHL_COLOR
                if(get_user_team(player) == teamId) // team realted message
                if(!playersData[player][PLAYER_AGHL])
                len += formatex(message[len],charsmax(message) - len,"%L",
                player,plrLangTeam[notifyId - (NOTIFY_TEAMWIN - 1)][T] ,
                name,playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
                else
                len += formatex(message[len],charsmax(message) - len,"%L",
                player,plrLangTeamClr[notifyId - (NOTIFY_TEAMWIN - 1)][T] ,
                name,playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
                else    // non team related message
                if(!playersData[player][PLAYER_AGHL])
                len += formatex(message[len],charsmax(message) - len,"%L",
                player,plrLangTeam[notifyId - (NOTIFY_TEAMWIN - 1)][O],
                teamName,playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
                else
                {
                    // use team colors
                    static const teamClr[5][3] =
                    {
                        "^^8",
                        "^^5",
                        "^^1",
                        "^^3",
                        "^^2"
                    }
                    if(teamId >= sizeof teamClr)
                    teamId = 0
                    new teamNameClr[20]
                    formatex(teamNameClr,charsmax(teamNameClr),"%s%s%s",
                    teamClr[teamId],teamName,"^^9")
                    len += formatex(message[len],charsmax(message) - len,"%L",
                    player,plrLangTeamClr[notifyId - (NOTIFY_TEAMWIN - 1)][O],
                    teamNameClr,playersData[id][PLAYER_CURRENTLEVEL] + 1,
                    playersData[id][PLAYER_WEAPONNAME])
                }
                #else
                if(get_user_team(player) == teamId) // team realted message
                len += formatex(message[len],charsmax(message) - len,"%L",
                player,plrLangTeam[notifyId - (NOTIFY_TEAMWIN - 1)][T],
                name,playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])

                else    // non team related messazge
                len += formatex(message[len],charsmax(message) - len,"%L",
                player,plrLangTeam[notifyId - (NOTIFY_TEAMWIN - 1)][O],
                teamName,playersData[id][PLAYER_CURRENTLEVEL] + 1,
                playersData[id][PLAYER_WEAPONNAME])
                #endif
            }
            default:
            #if defined AGHL_COLOR
            if(!playersData[player][PLAYER_AGHL])
            len += formatex(message[len],charsmax(message) - len,"%L",  // other messages
            player,plrLangOther[notifyId],
            name,
            playersData[id][PLAYER_CURRENTLEVEL] + 1,
            playersData[id][PLAYER_WEAPONNAME])
            else
            len += formatex(message[len],charsmax(message) - len,"%L",  // other messages
            player,plrLangOtherClr[notifyId],
            name,
            playersData[id][PLAYER_CURRENTLEVEL] + 1,
            playersData[id][PLAYER_WEAPONNAME])
            #else
            len += formatex(message[len],charsmax(message) - len,"%L",  // other messages
            player,plrLangOther[notifyId],
            name,
            playersData[id][PLAYER_CURRENTLEVEL] + 1,
            playersData[id][PLAYER_WEAPONNAME])
            #endif
        }
        #if defined CSCOLOR
        client_print_color(player,chatTeamColor[teamId],message)
        #else
        client_print(player,print_chat,message)
        #endif
    }
}
//
// Show hud informer
//
public Show_HudInformer(taskId)
{
    new id = taskId - task_Hud_Id
    if(!is_user_alive(id))
        return PLUGIN_CONTINUE

    //server_print "SHOWING INFORMER TO %N", id
    new message[312],tmp[30]
    formatex(message,charsmax(message),"%L",id,"INFORMER")
    for(new i ;  i < informerDisplay ; ++i)
    {
        if(informerBitSum & (1 << i))
        {
            switch(i)
            {
            case INF_TPL_WEAPON: replace(message,charsmax(message),informerTplKeys[i],playersData[id][PLAYER_WEAPONNAME])
            case INF_TPL_LEVEL:
            {
                num_to_str(playersData[id][PLAYER_CURRENTLEVEL] + 1,tmp,charsmax(tmp))
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_MAXLEVEL:
            {
                num_to_str(maxLevel,tmp,charsmax(tmp))
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_SAMELEVEL:
            {
                new f = gg_get_level_playersnum(playersData[id][PLAYER_CURRENTLEVEL])
                if(!f)
                    tmp[0] = 0
                else
                    formatex(tmp,charsmax(tmp)," (+%d)",f)
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_KILLS:
            {
                num_to_str(playersData[id][PLAYER_KILLS],tmp,charsmax(tmp))
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_NEEDKILLS:
            {
                num_to_str(playersData[id][PLAYER_NEEDKILLS],tmp,charsmax(tmp))
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_RANK:
            {
                num_to_str(playersData[id][PLAYER_RANKPOS],tmp,charsmax(tmp))
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_RANKNUM:
            {
                num_to_str(currentPlayers,tmp,charsmax(tmp))
                replace(message,charsmax(message),informerTplKeys[i],tmp)
            }
            case INF_TPL_LEADER: replace(message,charsmax(message),informerTplKeys[i],leader_name)
            case INF_TPL_LWEAPON: replace(message,charsmax(message),informerTplKeys[i],wp_leader)
            }
        }
    }
    set_hudmessage(informerColor[0], informerColor[1], informerColor[2], informerPos[0], informerPos[1], 0, 0.1, holdTime, 0.1, 0.2, 1)
    ShowSyncHudMsg(id,syncInformerHud,message)
    return PLUGIN_CONTINUE
}
//
// Get players num on specifed level
//
gg_get_level_playersnum(level)
{
    new players[MAX_PLAYERS],pnum,count = -1
    get_players(players,pnum)
    for(new i,player ; i < pnum ; ++i)
    {
        player = players[i]
        if(playersData[player][PLAYER_CURRENTLEVEL] == level)
            count++
    }
    return count
}
// limit handler
public Inflictors_SpawnHandler(ent)
{
    if(!ggActive)
        return HAM_IGNORED

    new owner = entity_get_edict(ent,EV_ENT_owner) // get ent owner
    if(!(0 < owner <= MaxClients))
        return HAM_IGNORED

    if(playersData[owner][PLAYER_INFLICTORS] == Invalid_Trie) // check that player has inflictors map
        return HAM_IGNORED

    new entClassname[MAX_PLAYERS],inflictorData[2]
    entity_get_string(ent,EV_SZ_classname,entClassname,charsmax(entClassname))
    if(!TrieGetArray(playersData[owner][PLAYER_INFLICTORS],entClassname,inflictorData,sizeof inflictorData))
    {
        // check if this inflictor is exists in map and get overall limit
        set_task(0.1,"ENT_DelayedRemove",task_EntRemove_Id + ent)
        return HAM_IGNORED
    }
    if(!inflictorData[0]) // no limit
        return HAM_IGNORED

    entity_set_int(ent,EV_INT_iuser3,owner) // this is for half-life snarks. SNAAARKKKKKKKSSSSSSSSS!!!!
    new entCount,stEnt
    while((stEnt = find_ent_by_class(stEnt,entClassname)))
    if(entity_get_edict(stEnt,EV_ENT_owner) == owner || entity_get_int(stEnt,EV_INT_iuser3) == owner)
        entCount ++
    if(entCount > inflictorData[0]) // remove new inflictor due to limit
        set_task(0.1,"ENT_DelayedRemove",task_EntRemove_Id + ent)
    return HAM_IGNORED
}
// reset inflictor ammo id
public Inflictors_DestroyHandler(ent)
{
    if(!ggActive)
        return HAM_IGNORED
    new classname[MAX_PLAYERS],inflictorAmmo[weaponAmmoStruct]
    entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))
    new owner = entity_get_edict(ent,EV_ENT_owner)

    if(!owner || owner > MaxClients || !is_user_connected(owner))
        return HAM_IGNORED

    if(!TrieGetArray(weaponAmmoTrie,classname,inflictorAmmo,weaponAmmoStruct) ||
    !playersData[owner][PLAYER_INFLICTORS] ||
    !TrieKeyExists(playersData[owner][PLAYER_INFLICTORS],classname))
        return HAM_IGNORED
    new curAmmo = get_pdata_int(owner,modOffsets[m_rgAmmo] + inflictorAmmo[WAMMO_PRIMARY_AMMOID] - modOffsets[offsetAmmoDiff])
    if(!curAmmo)
    {
        new weaponName[MAX_PLAYERS]
        if(get_weaponname(inflictorAmmo[WAMMO_SECONDARY_AMMOID],weaponName,charsmax(weaponName)))
            give_item(owner,weaponName)
    }
    set_pdata_int(owner, modOffsets[m_rgAmmo] + inflictorAmmo[WAMMO_PRIMARY_AMMOID] - modOffsets[offsetAmmoDiff], curAmmo + inflictorAmmo[WAMMO_PRIMARY_MAXAMMO]                              )
    return HAM_IGNORED
}
// inflictor hurt
public Inflictors_DamageHandler(ent,inflictor,attacker)
{
    if(!ggActive)
        return HAM_IGNORED

    if(!(0 < attacker <= MaxClients))
        return HAM_SUPERCEDE

    if(!playersData[attacker][PLAYER_INFLICTORS])
        return HAM_SUPERCEDE

    new classname[MAX_PLAYERS],inflictorData[2],owner = entity_get_int(ent,EV_INT_iuser3)
    entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))

    if(!playersData[owner][PLAYER_INFLICTORS] || !TrieGetArray(playersData[owner][PLAYER_INFLICTORS],classname,inflictorData,sizeof inflictorData))
        return HAM_IGNORED

    if(!inflictorData[1] &&  entity_get_int(ent,EV_INT_iuser3) != attacker &&
    (!playersData[attacker][PLAYER_INFLICTORS] || !TrieKeyExists(playersData[attacker][PLAYER_INFLICTORS],classname)))
        return HAM_SUPERCEDE
    return HAM_IGNORED
}
//
// Remove all player inflictors
//  id - player id
//  Array:infArray - inflictors array
//
public Inflictors_DestroyAll(id,Array:infArray)
{
    if(!ggActive)
    return HAM_IGNORED
    new inflictor[MAX_PLAYERS]
    for(new i,arSize = ArraySize(infArray),stEnt; i < arSize ; i++)
    {
        ArrayGetString(infArray,i,inflictor,charsmax(inflictor))
        stEnt = 0
        while((stEnt = find_ent_by_class(stEnt,inflictor)))
        if(entity_get_edict(stEnt,EV_ENT_owner) == id || entity_get_int(stEnt,EV_INT_iuser3) == id)
        {
            entity_set_int(stEnt,EV_INT_iuser4,1) // mark for no damage
            if(entity_get_float(stEnt,EV_FL_takedamage) != DAMAGE_NO)
                ExecuteHam(Ham_TakeDamage,stEnt,id,id,9999.0,0)
            else
                ExecuteHam(Ham_Use,stEnt,id,id,USE_ON,0)
        }
    }
    return HAM_IGNORED
}
// ranker
public Update_PlayersRanks()
{
    new players[MAX_PLAYERS],pnum
    get_players(players,pnum)
    SortCustom1D(players,pnum,"Sort_RankPos")
    for(new i,player ; i < pnum ; ++i)
    {
        player = players[i]
        playersData[player][PLAYER_RANKPOS] = i + 1
        if(!i)
        {
            if(!get_pcvar_num(cvar[CVAR_TEAMPLAY])) // get leader player
                get_user_name(player,leader_name,charsmax(leader_name))
            else    // get leader team
                get_user_team(player,leader_name,charsmax(leader_name))
            copy(wp_leader,charsmax(wp_leader),playersData[player][PLAYER_WEAPONNAME])
        }
    }
}
public Sort_RankPos(player1,player2)
{
    if(playersData[player1][PLAYER_CURRENTLEVEL] > playersData[player2][PLAYER_CURRENTLEVEL])
        return -1
    else if(playersData[player1][PLAYER_CURRENTLEVEL] < playersData[player2][PLAYER_CURRENTLEVEL])
        return 1
    else if(playersData[player1][PLAYER_KILLS] > playersData[player2][PLAYER_KILLS])
        return -1
    else if(playersData[player1][PLAYER_KILLS] < playersData[player2][PLAYER_KILLS])
        return 1
    return 0
}
public plugin_end()
{
    if(is_plugin_loaded("mapchooser.amxx",true)!=-1)
    if(cstrike_running())
        set_cvar_num("mp_maxrounds", 0)
}
// detect mapchoosers by cvars
public mapchooser_detect()
{
    if(is_plugin_loaded("mapchooser.amxx",true)!=-1)
        set_pcvar_num(cvar[CVAR_MAPCHOOSER_TYPE],2)
    else if(get_cvar_num("gal_version"))
        set_pcvar_num(cvar[CVAR_MAPCHOOSER_TYPE],1)
    else if(get_cvar_num("customnextmap"))
        set_pcvar_num(cvar[CVAR_MAPCHOOSER_TYPE],3)
    else if(is_plugin_loaded("DeagsMapManager")!=-1)
        set_pcvar_num(cvar[CVAR_MAPCHOOSER_TYPE],4)
}
// use part of code from original Counter-Strike GunGame
// start vote for nextmap
public start_map_vote(Float:delay)
{
    /// if(isVoteStarted)
    /// server_print("showing map vote is in progress already...hmmmm")
    ///     return
    switch(get_pcvar_num(cvar[CVAR_MAPCHOOSER_TYPE]))
    {
        case 1:
        {
            log_amx("Starting a map vote from Galileo")
            set_cvar_num("amx_extendmap_max",0)
            set_cvar_num("amx_extendmap_step",0)
            server_cmd(delay ? "gal_startvote" : "gal_startvote -nochange")
        }
        case 2:
        {
            new plugin = is_plugin_loaded("mapchooser.amxx",true)
            cstrike_running() ? set_cvar_num("mp_maxrounds",-1) : set_cvar_num("mp_fragsleft", 6), set_cvar_num("amx_extendmap_max", 0);
            if(callfunc_begin("@rtv","mapchooser.amxx"))
            {
                callfunc_push_int(0)
                callfunc_end()
                log_amx("New Nextmap Chooser voting system with RTV detected!")
            }
            log_amx("Starting a map vote from Nextmap Chooser.")
            if(callfunc_begin_i(get_func_id("voteNextmap",plugin),plugin) == 1)
            callfunc_end()
            else{
            log_amx("ERROR! Can't call ^"voteNextmap^" function from ^"%s^" plugin!",plugin)
            if(delay)
            set_task(delay,"goto_nextmap")
            }
            if(delay)
            set_task(15.1,"goto_nextmap") // amxx default vote time
        }
        case 3:
        {
            new cmd[128]
            get_pcvar_string(cvar[CVAR_MAPCHANGE_CMD],cmd,charsmax(cmd))
            ///         console_cmd(cmd);
            log_amx("custom vote activated");
            log_amx(cmd);
            ///         server_cmd("amx_votenextmap");
            server_cmd(cmd);
            server_exec()
        }
        // TODO: fix work with DeagsMapManager
        case 4:
        {
            new plugin = is_plugin_loaded("DeagsMapManager")
            register_cvar("mp_winlimit","9999.0") // don't allow extending  // fuck! didnt work D:
            set_cvar_float("mp_timelimit",0.0) // don't wait for buying
            set_cvar_num("enforce_timelimit",1) // don't change map after vote
            // call the vote
            if(callfunc_begin_i(get_func_id("startthevote",plugin),plugin) == 1)
                callfunc_end()
            set_task(20.1,"dmm_stop_mapchange") // TODO: recheck
        }
        default:
        {
            // TODO: something cool
            log_amx("Can't start vote because no valid mapchoosers detected")
        }
    }
    isVoteStarted = true
}
// stop DMM from changing maps after the vote has been tallied
public dmm_stop_mapchange()
{
    remove_task(333333,1); // outside the reality
}
public goto_nextmap()
{
    if(sound_winner[0])
    {
        for (new human=1; human<=MaxClients; human++)
        {
            if(!playersData[human][PLAYER_BOT])
            {
                if(containi(sound_winner,".mp3") != -1)
                {
                    client_cmd(human,"mp3 stop",sound_winner)
                }
                else
                {
                    client_cmd(human,"stopsound",sound_winner)
                }
            }
        }
    }
    new nextMap[MAX_PLAYERS]
    get_cvar_string("amx_votenextmap",nextMap,charsmax(nextMap))
    if(!nextMap[0])
    {
        // force change by hlds
        new gameEnd = create_entity("game_end")
        if(is_valid_ent(gameEnd))
            ExecuteHamB(Ham_Use,gameEnd,0,0,USE_ON,0.0)
    }
    else
        server_cmd("changelevel %s",nextMap)
}

new const statsHudPlayers = 7 // maximum players per hud message
new Float:showTime
// Êîíåö èãðû. Îòîáðàæåíèå ïîáåäèòåëÿ, âîñïðîèçâåäåíèå ìóçûêè è òï  // Äà ëàäíî?
public endgame(id)
{
    new winnerName[MAX_PLAYERS]
    for (new human=1; human<=MaxClients; human++)
    {
        if(!playersData[human][PLAYER_BOT])
        if(!get_pcvar_num(cvar[CVAR_TEAMPLAY]))
            get_user_name(id,winnerName,charsmax(winnerName))
        else
        {
            new len = formatex(winnerName,charsmax(winnerName),"%L ",LANG_SERVER,"TEAM_STR")
            get_user_team(id,winnerName[len],charsmax(winnerName) - len)
        }
        if(proLevelPlayed && proLevelLoop)
        {
            client_cmd(human,"mp3 stop")
            remove_task(task_ProLevel_Id)
        }
        set_hudmessage(255, 0, 0, -1.0, 0.15, 2, 1.0, 5.0, 0.1, 0.2, 4)
        show_hudmessage(human, "%L", LANG_PLAYER, "WINNER_HUD", winnerName)
        gg_notify_msg(id,NOTIFY_WIN)
        start_map_vote(1.0);
        ExecuteForward(fwdWin,fwdRet,id)
        if(fwdRet == PLUGIN_HANDLED)
            return
        if(sound_winner[0])
        {
            if(containi(sound_winner,".mp3") != -1)
                client_cmd(human,"mp3 play ^"%s^"",sound_winner)
            else
                client_cmd(human,"spk ^"%s^"",sound_winner)
        }
        new Float:endgame_delay = get_pcvar_float(cvar[CVAR_ENDGAME_DELAY])
        new players[MAX_PLAYERS],pnum
        get_players(players,pnum,"h")
        if(get_pcvar_num(cvar[CVAR_SHOWSTATS]))
        {
            // shows endgame stats
            new statsText[1024],len
            SortCustom1D(players,pnum,"Sort_RankPos")
            new Float:partTime = float(currentPlayers / statsHudPlayers) // calc maximum parts
            if(!partTime)
            partTime = 1.0
            showTime = endgame_delay / partTime // calc maximum show time per parts
            new parsedPlayers
            new Float:showCount
            for(new i,player; i < pnum ; ++i)
            {
                player = players[i]
                new usrName[MAX_PLAYERS]
                get_user_name(player,usrName,charsmax(usrName))
                if(i)
                {
                    len += formatex(statsText[len],charsmax(statsText) - len,
                    "%L^n",
                    LANG_PLAYER,"STATS_END_PLAYER",
                    i + 1,usrName,
                    playersData[player][PLAYER_CURRENTLEVEL] + 1,
                    playersData[player][PLAYER_WEAPONNAME],
                    playersData[player][PLAYER_KILLS],
                    playersData[player][PLAYER_NEEDKILLS],
                    get_user_frags(player))
                }
                else
                {
                    // for winner
                    len += formatex(statsText[len],charsmax(statsText) - len,
                    "%L^n",LANG_PLAYER,"STATS_END_WINNER",i + 1,usrName,get_user_frags(player))
                }
                parsedPlayers ++
                if(parsedPlayers == statsHudPlayers || i == pnum - 1)
                {
                    // show this part
                    new Float:taskTime = showTime * showCount
                    set_task(taskTime,"Show_EndGameStats",_,statsText,strlen(statsText))
                    if(i == pnum - 1) // reset hud messages
                    set_task(showTime * (showCount + 1.0),"Show_EndGameStats",_,"^n",1)
                    parsedPlayers = 0
                    showCount += 1.0
                    len = 0
                }
            }
        }
        new fadeColor[3]
        fadeColor[0] = random(255)
        fadeColor[1] = random(255)
        fadeColor[2] = random(255)
        for(new i,player; i < pnum ; ++i)
        {
            player = players[i]
            ExecuteHam(Ham_Use,striper,player,player,USE_ON,0.0)
            if(task_exists(player + task_Hud_Id))
            {
                remove_task(player + task_Hud_Id)
                ClearSyncHud(player,syncInformerHud)
            }
            remove_task(player + task_Equip_Id)
            StatusIcon_Display(player,3)
            set_user_godmode(player,true)
            set_user_gravity(player,0.3)
            set_user_maxspeed(player,9999.0)
            entity_set_vector(player,EV_VEC_velocity,Float:{0.0,0.0,0.0})
            set_pev(player,pev_flags,pev(player,pev_flags) | FTRACE_SIMPLEBOX)
        }
        UTIL_ScreenFade(0, {0,0,0}, endgame_delay, 40.0, 255, 1)
        set_user_rendering(id,kRenderFxGlowShell,fadeColor[0],fadeColor[1],fadeColor[2],kRenderNormal,128)
        if(get_pcvar_num(cvar[CVAR_MAPCHANGES_STYLE]) == 1)
        {
            start_map_vote(endgame_delay)
        }
        else
            set_task(endgame_delay,"goto_nextmap")
        isEndGame = true
    }
}
public Show_EndGameStats(hudMessage[])
{
    static showCount
    static hudSyncObj
    if(!hudSyncObj)
        hudSyncObj = CreateHudSyncObj()
    else
        ClearSyncHud(0,hudSyncObj)
    if(showCount ++ == 5)
        showCount = 1
    set_hudmessage(endHudColor[0], endHudColor[1],endHudColor[2],endHudPos[0],endHudPos[1], 2, 0.1, 20.0, 0.01, 0.05, showCount)
    ShowSyncHudMsg(0,hudSyncObj,hudMessage)
}
//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------
stock UTIL_ScreenFade(id=0,iColor[3]={0,0,0},Float:flFxTime=-1.0,Float:flHoldTime=0.0,iAlpha=0,iFlags=0x0000,bool:bReliable=false,bool:bExternal=false)
{
    if(!ScreenFade)
        return

    new iFadeTime

    if(flFxTime==-1.0)
        iFadeTime = 4
    else
        iFadeTime = FixedUnsigned16(flFxTime,1<<12)
    new MSG_DEST
    if(bReliable)
        MSG_DEST = id ? MSG_ONE : MSG_ALL
    else
        MSG_DEST = id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST
    if(bExternal)
    {
        emessage_begin(MSG_DEST,ScreenFade, _,id)
        ewrite_short(iFadeTime)
        ewrite_short(FixedUnsigned16(flHoldTime,1<<12 ))
        ewrite_short(iFlags)
        ewrite_byte(iColor[0])
        ewrite_byte(iColor[1])
        ewrite_byte(iColor[2])
        ewrite_byte(iAlpha)
        emessage_end()
    }
    else
    {
        message_begin(MSG_DEST,ScreenFade,_, id)
        write_short(iFadeTime)
        write_short(FixedUnsigned16(flHoldTime,1<<12 ))
        write_short(iFlags)
        write_byte(iColor[0])
        write_byte(iColor[1])
        write_byte(iColor[2])
        write_byte(iAlpha)
        message_end()
    }
}

stock FixedUnsigned16(Float:flValue, iScale)
{
    new iOutput;
    iOutput = floatround(flValue * iScale);

    if ( iOutput < 0 )
        iOutput = 0;
    if ( iOutput > 0xFFFF )
        iOutput = 0xFFFF;
    return iOutput;
}

stock UTIL_TeleportEffectForPlayer(id)
{
    new origin[3]
    get_user_origin(id,origin)
    message_begin(MSG_PVS,SVC_TEMPENTITY,origin,id)
    write_byte(TE_TELEPORT)
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    message_end()
}
// -- THIS IS APPIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIiI -- //
//
// Returns max level
//
// native gg_get_max_level()
//
public api_get_max_level(plugin,params)
return maxLevel
//
// Returns level data
//
// native gg_get_level_data(level,weaponSet[weaponSetStruct])
//  @level - level num for which you want to get info
//  @weaponSet - array for information
//  @return - false or true
//
public api_get_level_data(plugin,params)
{
    if(params != 2)
    {
        log_error(AMX_ERR_NATIVE,"bad arguments num, expected 2, passed %d",params)
        return false
    }
    new level = get_param(1)
    if(!(0 <= level < maxLevel))
    {
        log_error(AMX_ERR_NATIVE,"level out of bounds (%d)",level)
        return false
    }
    new weaponSet[weaponSetStruct]
    ArrayGetArray(weaponSets,level,weaponSet)
    set_array(2,weaponSet,weaponSetStruct)
    return true
}
//
// Returns player level and other related info
//
// native gg_get_player_level(id,playerData[playersDataStruct] = 0)
//  @id - player id
//  @playerData - array for information
//  @return - player level or -1
//
public api_get_player_level(plugin,params)
{
    if(params != 2)
    {
        log_error(AMX_ERR_NATIVE,"bad arguments num, expected 2, passed %d",params)
        return -1
    }
    new player = get_param(1)
    if(!(0 < player <= MaxClients))
    {
        log_error(AMX_ERR_NATIVE,"player out of bounds (%d)",player)
        return -1
    }
    if(!is_user_connected(player))
    {
        log_error(AMX_ERR_NATIVE,"player %d is not in game",player)
        return -1
    }
    set_array(2,playersData[player],playersDataStruct)
    return playersData[player][PLAYER_CURRENTLEVEL]
}
//
// Sets player level
//
// native gg_set_player_level(id,newLevel,kills)
//  @id - player id
//  @newLevel - player new level
//  @kills - level kills
//  @return - true or false
//
public api_set_player_level(plugin,params)
{
    if(params != 3)
    {
        log_error(AMX_ERR_NATIVE,"bad arguments num, expected 3, passed %d",params)
        return false
    }
    new player = get_param(1)
    if(!(0 < player <= MaxClients))
    {
        log_error(AMX_ERR_NATIVE,"player out of bounds (%d)",player)
        return false
    }
    if(!is_user_connected(player))
    {
        log_error(AMX_ERR_NATIVE,"player %d is not in game",player)
        return false
    }
    new level = get_param(2)
    if(!(0 <= level < maxLevel))
    {
        log_error(AMX_ERR_NATIVE,"level out of bounds (%d)",level)
        return false
    }
    new kills = get_param(3)
    new weaponSet[weaponSetStruct]
    ArrayGetArray(weaponSets,level,weaponSet)
    if(get_pcvar_num(cvar[CVAR_TEAMPLAY]))
    Update_TeamData(player)
    if(kills >= weaponSet[WSET_KILLS])
    {
        level ++
        kills = 0
        if(level == maxLevel)
        {
            playersData[player][PLAYER_CURRENTLEVEL] = level
            playersData[player][PLAYER_KILLS] = kills
            if(get_pcvar_num(cvar[CVAR_TEAMPLAY]))
            Update_TeamData(player)
            Equip_PlayerWithWeapon(player)
            return true
        }
        ArrayGetArray(weaponSets,level,weaponSet)
    }
    playersData[player][PLAYER_CURRENTLEVEL] = level
    playersData[player][PLAYER_KILLS] = kills
    Equip_PlayerWithWeapon(player)
    if(get_pcvar_num(cvar[CVAR_TEAMPLAY]))
        Update_TeamData(player)
    return true
}
//
// Force equip player
//
// native api_equip_force(id)
//  @id - player id
//
public api_equip_force(id)
{
    if(!(0 < id <= MaxClients))
    {
        log_error(AMX_ERR_NATIVE,"player out of bounds (%d)",id)
        return
    }
    Equip_PlayerWithWeapon(id)
}
//--------------------------------------------------------------------------------------------------
//--------------------------------
// There was Trie Hash Abstraction Layer by Zefir
// Update to lastes amxmodx build here: http://www.amxmodx.org/snapshots.php
// We dont support outdated software. Regards, HL GunGame Developing Team.
//--------------------------------
//--------------------------------------------------------------------------------------------------
/*
*  Feedback:
*   Steam: http://steamcommunity.com/id/serfreeman1337/
*   ICQ: 50429042
*   E-Mail: serfreeman1337@yandex.com
*   Site: http://gf.hldm.org/
*/
