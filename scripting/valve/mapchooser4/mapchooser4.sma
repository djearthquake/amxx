
    /*  AMX Mod X
    *   Nextmap Chooser Plugin
    *
    * by the AMX Mod X Development Team
    *  originally developed by OLO
    *
    * This file is part of AMX Mod X.
    *
    *
    *  This program is free software; you can redistribute it and/or modify it
    *  under the terms of the GNU General Public License as published by the
    *  Free Software Foundation; either version 2 of the License, or (at
    *  your option) any later version.
    *
    *  This program is distributed in the hope that it will be useful, but
    *  WITHOUT ANY WARRANTY; without even the implied warranty of
    *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    *  General Public License for more details.
    *
    *  You should have received a copy of the GNU General Public License
    *  along with this program; if not, write to the Free Software Foundation,
    *  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
    *
    *  In addition, as a special exception, the author gives permission to
    *  link the code of this program with the Half-Life Game Engine ("HL
    *  Engine") and Modified Game Libraries ("MODs") developed by Valve,
    *  L.L.C ("Valve"). You must obey the GNU General Public License in all
    *  respects for all of the code used other than the HL Engine and MODs
    *  from Valve. If you modify this file, you may extend this exception
    *  to your version of the file, but you are not obligated to do so. If
    *  you do not wish to do so, delete this exception statement from your
    *  version.
    *  Maps to select are in config/maps.ini file, mapcycle file or maps folder.
    *
    *  If amx_mapchooser_type is set to 1, players can nominate maps for the vote.
    *  They have to type "nominate mapname" or "vote mapname" or "mapname" in the chat.
    *  They can type "nominations" in the chat to see the list of nominated maps.
    *  They can type "amx_listmaps2" in console to see the maps that can be nominated if
    *  amx_nominfromfile is set to 1.
    *
    *  Cvars:
    *  amx_mapchooser_type <0/1/2> - 0: random maps from amx_mapchooser_mapsfile/mapcycle/maps folder
    *                                1: nominations
    *                                2: the nextmap is a random map chosen from amx_mapchooser_mapsloc (no vote)
    *  amx_mapchooser_mapsloc <0|1|2> - 0: amx_mapchooser_mapsfile
    *                                   1: mapcycle
    *                                   2: maps folder
    *  amx_mapchooser_mapsfile "maps.ini" - File used when amx_mapchooser_mapsloc is set to 0
    *                                      The file must be in amxmodx/configs/ folder.
    *  amx_mapchooser_mapsfile_s "maps_small.ini" - File used when amx_mapchooser_mapsloc is set to 0 and there
    *                                      is less than 10 players on the server
    *                                      The file must be in amxmodx/configs/ folder.

    *  amx_nominfromfile <0/1> - 0: players can nominate all the maps from the map folder
    *                            1: players can only nominate maps from amx_mapchooser_mapsfile/mapcycle
    *  amx_maxnominperplayer <num> - how many maps each player can nominate
    *  amx_map_history <num> - how many last played maps shouldn't go to the maps vote menu
    *
    *  amx_extendmap_max <time in mins.> - max. time for overall extending
    *  amx_extendmap_step <time in mins.> - with what time the map will be extended
    *  amx_ext_round_max <number of possible polls for extend> - how many times the map can be extended
    *  amx_ext_round_step <number of rounds> - with what rounds number the map will be extended
    *  amx_ext_win_max <number of possible polls for extend> - how many times the map can be extended
    *  amx_ext_win_step <number of rounds> - with what rounds number the map will be extended
    *
    *  amx_rtv <0/1> - 0 - disables rockthevote option
    *  amx_rtv_percent <0.0-1.0> - rockthevote ratio (%/100 human-players they need to say rockthevote
    *                              to start voting for the next map.
    *  amx_rtv_min_time <time in mins.> - minimum time (in minutes) required to play the map before players
    *                                     can use rockthevote feature.
    *  amx_rtv_map_time <time in sec.> - time after successful rtv then voting for the new map, the map
    *                                    will change to the new one (instead waiting until round end)
    *
    *  NOTE: Nextmap plugin is required for proper working of this plugin.
    *
    *  Some parts of the nominations code are taken from Deagles's map management plugin and AMX 2006.3 mapchooser.
    *
    */

    #include <amxmodx>
    #include <amxmisc>

    #define VOTE_TIME 15
    #define CHECK_MENU_TIME 0.5

    #define FLAG_AMX_VOTENEXTMAP ADMIN_VOTE

    #define MAX_MAPS MAX_MOTD_LENGTH
    #define SELECTMAPS  5

    #define MAP_HISTORY_MAX  15
    // #define MAP_HISTORY  5
    #define NOMINATIONS_HELPMSG 12  // a help message telling people they can nominate maps will be displayed
    // every 15 * value seconds (ie: 15 * 12 = 3mns)
    // if amx_mapchooser_type is set to 1
    #define LISTMAPAMOUNT 10

    #define DOD_OFFSET 129
    #define OP4_OFFSET 175

    new g_hist_mapName[MAP_HISTORY_MAX][MAX_PLAYERS]
    new g_MapHistory = 5
    new g_mapName[MAX_MAPS][MAX_PLAYERS]
    new g_mapsNum = 0

    new g_nominMapName[SELECTMAPS][MAX_PLAYERS]
    new g_nominMapsNum = 0
    new g_nominated[MAX_PLAYERS + 1]
    new g_whoNominMapNum[SELECTMAPS]

    new bool:g_hasVoted[MAX_PLAYERS + 1]

    new g_mapVoteName[SELECTMAPS][MAX_PLAYERS]
    new g_voteCount[SELECTMAPS+3]
    new g_mapVoteNum = 0
    new g_teamScore[2]
    new g_lastMap[MAX_PLAYERS]
    new g_maphistFile[128]

    new g_coloredMenus
    new g_maxplayers
    new bool:g_selected = false
    new bool:g_call_say_vote = false
    new bool:g_vote_finished = false
    new bool:g_buyingtime = true

    new g_extendCount = 0
    new bool:g_extend
    new bool:g_forceVote
    new g_forceVoteTime

    new g_active_players = 0
    new bool:g_inprogress = false
    new bool:g_hasbeenrocked = false
    new bool:g_rockthevote = false
    new bool:g_ForceChangeMap = false
    new g_rocks = 0
    new g_rocked[MAX_PLAYERS + 1]

    new g_nominationsHelpMsgIter
    new g_mapsOnServerNum

    new pv_amx_mapchooser_type
    new pv_amx_map_history
    new pv_amx_vote_time
    new pv_amx_vote_delay
    new pv_amx_last_voting
    new pv_amx_rtv
    new pv_amx_rtv_percent
    new pv_amx_rtv_min_time
    new pv_amx_rtv_map_time

    new menuid_choosenextmap

    new const PLUGINNAME[] = "Nextmap Chooser 4"
    new const VERSION[] = "4.5" ///OP4 SUPPORT
    new const AUTHOR[] = "AMXX DEVKWoSPiNX"

    public NEXTMAP_MSG
    public NEXTMAP_ROUNDCOUNT
    public NEXTMAP_WINCOUNT
    public NEXTMAP_TIMECOUNT

    public plugin_init()
    {

    register_plugin(PLUGINNAME,VERSION,AUTHOR)
    register_dictionary("mapchooser4.txt")
    register_dictionary("common.txt")

    register_logevent( "eNewRound", 2, "1=Round_Start" )
    //  register_event("RoundTime", "eNewRound", "bc")
    if ( cstrike_running() )  ///random errors in log if not cstrike, disco 2018
    register_event( "SendAudio", "eEndRound", "a",
    "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw" )
    //  register_logevent( "Log_Event_RoundEnd", 2, "1=Round_End" )

    pv_amx_mapchooser_type = register_cvar("amx_mapchooser_type","0")
    pv_amx_map_history = register_cvar("amx_map_history","5")
    register_cvar("amx_mapchooser_mapsloc", "0")
    register_cvar("amx_mapchooser_mapsfile", "maps.ini")
    register_cvar("amx_mapchooser_mapsfile_s", "maps_small.ini")
    register_cvar("amx_nominfromfile","0")
    register_cvar("amx_maxnominperplayer","1")

    register_cvar("amx_extendmap_max","90")
    register_cvar("amx_extendmap_step","15")
    register_cvar("amx_ext_round_max","3")
    register_cvar("amx_ext_round_step","3")
    register_cvar("amx_ext_win_max","3")
    register_cvar("amx_ext_win_step","3")

    pv_amx_vote_time = register_cvar("amx_vote_time","20")
    pv_amx_vote_delay = register_cvar("amx_vote_delay","60")
    pv_amx_rtv = register_cvar("amx_rtv","1")
    pv_amx_rtv_percent = register_cvar("amx_rtv_percent","0.6")
    pv_amx_rtv_min_time = register_cvar("amx_rtv_min_time","10")
    pv_amx_rtv_map_time = register_cvar("amx_rtv_map_time","10")

    pv_amx_last_voting = get_cvar_pointer("amx_last_voting")
    set_cvar_float("amx_last_voting",0.0)

    register_concmd("amx_votenextmap","cmdVoteNextMap",FLAG_AMX_VOTENEXTMAP,"<time> : the map will be changed <time> seconds after the end of the vote")
    register_clcmd("say","handleSay")

    register_clcmd("amx_listmaps2","cmdListMaps",0,"- lists maps that can be nominated.")
    
    if(cstrike_running() || get_cvar_pointer("mp_teamplay"))
    register_event("TeamScore", "team_score", "a")

    g_maxplayers = get_maxplayers()

    get_localinfo("lastMap",g_lastMap,31)
    set_localinfo("lastMap","")

    new MenuName[64]
    format(MenuName,63,"%L","en","CHOOSE_NEXTM")
    menuid_choosenextmap = register_menuid(MenuName)
    register_menucmd(menuid_choosenextmap,(-1^(-1<<(SELECTMAPS+2))),"countVote")

    g_coloredMenus = colored_menus()
    g_forceVote = false

    g_active_players = 0
    g_rocks = 0
    g_inprogress = false
    g_hasbeenrocked = false
    g_rockthevote = false
    g_ForceChangeMap = false

    for(new i = 1; i < 33; ++i)
    {
    g_rocked[i] = 0
    }

    g_nominationsHelpMsgIter = 0
    getMapsOnServerNum()
    /// set_task(7.0, "load_settings_delayed", 64973123)

    if ( cstrike_running() ) ///NEEDED TO RTV WHEN MOD != CSTRIKE
    g_buyingtime = true
    else g_buyingtime = false
    }

    /*
    public plugin_precache(){
    if ((file_exists(g_maphistFile)) && (g_MapHistory > 0))
    {
    new text[MAX_PLAYERS]
    new a = 0
    // shift list up 1
    for (new pos = 0; pos < g_MapHistory; pos++)
    {
    read_file(g_maphistFile,pos+1,text,31,a)
    write_file(g_maphistFile,text,pos)
    }
    }
    new current_map[MAX_PLAYERS]
    get_mapname(current_map, 31)
    write_file(g_maphistFile,current_map,g_MapHistory-1);

    }
    */
    public OnAutoConfigsBuffered()
    ///public load_settings_delayed()
    {
    new filename[128]
    new cfgdir[128]
    get_configsdir(cfgdir, charsmax(cfgdir))
    format(g_maphistFile, charsmax(g_maphistFile), "%s/maphist.ini", cfgdir)

    load_history(g_maphistFile)

    if (get_cvar_num("amx_mapchooser_mapsloc") == 0)
    {
    new mapslocfile[MAX_PLAYERS]
    get_cvar_string("amx_mapchooser_mapsfile", mapslocfile, 31)
    format(filename, 127, "%s/%s", cfgdir, mapslocfile)

    if (loadSettings(filename))
    {
    log_message("[AMXX] - Nextmap Chooser 4: %s succesfully loaded (%d maps).",mapslocfile, g_mapsNum)
    set_task(15.0, "voteNextmap", 987456, "", 0, "b")
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_task(1.0, "setXvars", 64973122)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to load %s or no maps inside the file. Trying to load mapcycle." ,mapslocfile)
    get_cvar_string("mapcyclefile", filename, 63)
    if (loadSettings(filename))
    {
    log_message("[AMXX] - Nextmap Chooser 4: mapcycle succesfully loaded (%d maps).", g_mapsNum)
    set_task(15.0, "voteNextmap", 987456, "", 0, "b")
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_task(1.0, "setXvars", 64973122)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to load mapcycle or no maps inside the file. Trying to load maps folder.")
    set_cvar_num("amx_nominfromfile", 0)
    if (loadMapsFolder())
    {
    log_message("[AMXX] - Nextmap Chooser 4: maps folder succesfully loaded (%d maps).", g_mapsNum)
    set_task(15.0, "voteNextmap", 987456, "", 0, "b")
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_task(1.0, "setXvars", 64973122)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to load maps folder. No maps loaded.")
    }
    }
    }
    }
    else if (get_cvar_num("amx_mapchooser_mapsloc") == 1)
    {
    get_cvar_string("mapcyclefile", filename, 63)
    if (loadSettings(filename))
    {
    log_message("[AMXX] - Nextmap Chooser 4: mapcycle succesfully loaded (%d maps).", g_mapsNum)
    set_task(15.0, "voteNextmap", 987456, "", 0, "b")
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_task(1.0, "setXvars", 64973122)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to load mapcycle or no maps inside the file. Trying to load maps folder.")
    set_cvar_num("amx_nominfromfile", 0)
    if (loadMapsFolder())
    {
    log_message("[AMXX] - Nextmap Chooser 4: maps folder succesfully loaded (%d maps).", g_mapsNum)
    set_task(15.0, "voteNextmap", 987456, "", 0, "b")
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_task(1.0, "setXvars", 64973122)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to load maps folder. No maps loaded.")
    }
    }
    }
    else if (get_cvar_num("amx_mapchooser_mapsloc") == 2)
    {
    set_cvar_num("amx_nominfromfile", 0)
    if (loadMapsFolder())
    {
    log_message("[AMXX] - Nextmap Chooser 4: maps folder succesfully loaded (%d maps).", g_mapsNum)
    set_task(15.0, "voteNextmap", 987456, "", 0, "b")
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_task(1.0, "setXvars", 64973122)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to load maps folder. No maps loaded.")
    }
    }
    }

    public client_putinserver(id)
    {
    if (!is_user_bot(id))
    {
    g_active_players++
    g_rocked[id] = 0
    }
    }
    #if !defined client_disconnected
    #define client_disconnected client_disconnect
    #endif
    public client_disconnected(id)
    {
    if(is_user_bot(id))
    return PLUGIN_CONTINUE

    g_active_players--

    if (g_rocked[id])
    {
    g_rocked[id] = 0
    g_rocks--
    }

    return PLUGIN_CONTINUE
    }

    public setXvars()
    {
    if (get_pcvar_num(pv_amx_mapchooser_type) == 2)
    {
    remove_task(987456)
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 3)
    new a, i, randNum = random_num(1,10)
    for(i = 0; i < randNum; ++i)
    {
    a = random_num(0,g_mapsNum-1)
    }
    set_cvar_string("amx_nextmap", g_mapName[a])
    pause "a";
    return
    }

    new timeleft = get_timeleft()
    new count = 1
    while((timeleft -= 15) > 129) ++count
    set_xvar_num(get_xvar_id("NEXTMAP_TIMECOUNT"), count*15)
    set_xvar_num(get_xvar_id("NEXTMAP_ROUNDCOUNT"), get_cvar_num("mp_maxrounds") - 2)
    set_xvar_num(get_xvar_id("NEXTMAP_WINCOUNT"), get_cvar_num("mp_winlimit") - 2)

    if (NEXTMAP_MSG || NEXTMAP_ROUNDCOUNT || NEXTMAP_WINCOUNT || NEXTMAP_TIMECOUNT) // against the compiler which cannot see these xvars ARE used...
    log_amx("xvars for mapchooser 4 setuped.")

    }

    public check_menu(param[])
    {
    new iter = param[0]
    new Float:vote_time = get_pcvar_float(pv_amx_vote_time) - (iter * CHECK_MENU_TIME)
    new menutime = floatround(vote_time, floatround_floor)
    if (menutime > 0)
    {
    new mapsmenu[512], mkeys, pos
    mkeys = (1<<SELECTMAPS+1)
    pos = 0
    for(new i = 0; i < g_mapVoteNum; ++i)
    {
    pos += format(mapsmenu[pos], 511, "%d. %s^n", i+1, g_mapVoteName[i])
    mkeys |= (1<<i)
    }
    mapsmenu[pos++] = '^n'
    pos = 0
    new mapname[MAX_PLAYERS]
    get_mapname(mapname, 31)
    new nextMap[MAX_PLAYERS]
    get_cvar_string("amx_nextmap", nextMap, 31)
    new players[MAX_PLAYERS], numplayers, player
    new menuid, keys
    new menu[512]
    get_players(players, numplayers, "c")
    for(numplayers--; numplayers >= 0; numplayers--)
    {
    player = players[numplayers]
    if (g_hasVoted[player]) continue
    get_user_menu(player, menuid, keys)
    if (keys == 0 || menuid < 0)
    {
    menu[0] = '^0'
    pos = format(menu,511,g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTM")

    pos += format(menu[pos], 511-pos, "%s", mapsmenu)
    if (g_extend)
    {
    pos += format(menu[pos],511-pos,"%d. %L^n",SELECTMAPS+1,LANG_SERVER,"EXTEND_MAP",mapname)
    }
    format(menu[pos], 511-pos, "%d. %L", SELECTMAPS+2,LANG_SERVER,"KEEP_CURRENT_NEXTMAP", nextMap)
    show_menu(player, mkeys, menu, menutime, "AMX Choose nextmap:")
    }
    else if(menuid != menuid_choosenextmap)
    {
    if(menutime <= 6)
    {
    menu[0] = '^0'
    pos = format(menu,511,g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTM")
    pos += format(menu[pos], 511-pos, "%s", mapsmenu)
    if( g_extend)
    {
    pos += format(menu[pos],511-pos,"%d. %L^n",SELECTMAPS+1,LANG_SERVER,"EXTEND_MAP",mapname)
    }
    format(menu[pos], 511-pos, "%d. %L", SELECTMAPS+2,LANG_SERVER,"KEEP_CURRENT_NEXTMAP", nextMap)
    show_menu(player, mkeys, menu, menutime, "AMX Choose nextmap:")
    }
    }
    }
    param[0] += 1
    set_task(CHECK_MENU_TIME, "check_menu", 1467853, param, 1)
    }
    }


    public checkVotes()
    {
    remove_task(1467853)
    for(new i = 1; i <= g_maxplayers; ++i)
    {
    g_hasVoted[i] = true
    }

    new b = 0
    new Float:timelimit = get_cvar_float("mp_timelimit")
    new maxrounds = get_cvar_num("mp_maxrounds")
    new winlimit = get_cvar_num("mp_winlimit")

    for(new a = 0; a < g_mapVoteNum; ++a)
    {
    if (g_voteCount[b] < g_voteCount[a])
    {
    b = a
    }
    }

    if ( (timelimit > 0) && ( g_voteCount[SELECTMAPS] > g_voteCount[b] )
    && (g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+1])
    && (g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+2]))
    {
    new mapname1[MAX_PLAYERS]
    get_mapname(mapname1,31)
    new Float:steptime = get_cvar_float("amx_extendmap_step")
    set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + steptime )
    client_print(0,print_chat,"%L", LANG_PLAYER, "CHO_FIN_EXT_T", steptime )
    log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %.0f minutes",
    mapname1 , steptime )
    ++g_extendCount
    new timeleft = get_timeleft()
    new count = 1
    while((timeleft -= 15) > 129) ++count
    set_xvar_num(get_xvar_id("NEXTMAP_TIMECOUNT"), count*15)
    g_ForceChangeMap = false
    g_vote_finished = true
    g_inprogress  = false
    return
    }

    if ( ( maxrounds > 0 ) && ( g_voteCount[SELECTMAPS] > g_voteCount[b] )
    && (g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+1])
    && (g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+2]))
    {
    new mapname2[MAX_PLAYERS]
    get_mapname(mapname2,31)
    new stepround = get_cvar_num("amx_ext_round_step")
    set_cvar_num("mp_maxrounds", maxrounds + stepround )
    client_print(0,print_chat,"%L", LANG_PLAYER, "CHO_FIN_EXT_R", stepround  )
    log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %d rounds",
    mapname2 , stepround )
    g_vote_finished = true
    g_inprogress  = false
    g_ForceChangeMap = false
    ++g_extendCount
    set_xvar_num(get_xvar_id("NEXTMAP_ROUNDCOUNT"), (get_cvar_num("mp_maxrounds") - 2) - (g_teamScore[0] + g_teamScore[1]))

    log_amx("Vote: Map %s will be extended %d time(s)", mapname2 , g_extendCount )
    client_print(0,print_chat,"%L", LANG_PLAYER, "CHO_FIN_EXT_HMT", mapname2 , g_extendCount )
    return
    }

    if ( (winlimit > 0 ) && ( g_voteCount[SELECTMAPS] > g_voteCount[b] )
    && (g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+1])
    && (g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+2]))
    {
    new mapname3[MAX_PLAYERS]
    get_mapname(mapname3,31)
    new stepwin = get_cvar_num("amx_ext_win_step")
    set_cvar_num("mp_winlimit", winlimit + stepwin )
    client_print(0,print_chat,"%L", LANG_PLAYER, "CHO_FIN_EXT_W", stepwin )
    log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %.0d wins",
    mapname3 , stepwin )
    g_vote_finished = true
    g_inprogress  = false
    g_ForceChangeMap = false
    new c = get_cvar_num("mp_winlimit") - 2
    set_xvar_num(get_xvar_id("NEXTMAP_WINCOUNT"), min(c-g_teamScore[0],c-g_teamScore[1]))

    ++g_extendCount
    log_amx("Vote: Map %s will be extended %d time(s)", mapname3 , g_extendCount )
    client_print(0,print_chat,"%L", LANG_PLAYER, "CHO_FIN_EXT_HMT", mapname3 , g_extendCount )
    return
    }

    if ( g_voteCount[b] && g_voteCount[SELECTMAPS+1] <= g_voteCount[b] )
    set_cvar_string("amx_nextmap", g_mapVoteName[b])

    new smap[MAX_PLAYERS]
    get_cvar_string("amx_nextmap",smap,31)
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 3)
    new Float:MapChangeTime = get_pcvar_float(pv_amx_rtv_map_time)

    if (g_forceVote == true)
    {
    g_ForceChangeMap = true
    /*
    if (MapChangeTime < 5.0)
    MapChangeTime = 5.0
    else if (MapChangeTime > 500.0)
    MapChangeTime = 500.0
    */
    // stopped immediate rtv map changes and weak clamps
    if (!task_exists(6482257))
    set_task(MapChangeTime, "doMapChange", 6482257)

    }

    client_print(0,print_chat,"%L", LANG_PLAYER, "CHO_FIN_NEXT", smap )
    log_amx("Vote: Voting for the nextmap finished. The nextmap will be %s", smap)

    g_vote_finished = true
    g_inprogress  = false
    g_forceVote = false
    }

    public countVote(id,key)
    {
    if(g_hasVoted[id])
    {
    return PLUGIN_HANDLED
    }
    g_hasVoted[id] = true

    if ( get_cvar_float("amx_vote_answers")  && (!g_vote_finished) )
    {
    new name[MAX_PLAYERS]
    get_user_name(id,name,31)
    if(key == SELECTMAPS+1)
    {
    new nextMap[MAX_PLAYERS]
    get_cvar_string("amx_nextmap", nextMap, 31)
    client_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_CURR_NEXT", name, nextMap)
    log_amx("%L", LANG_SERVER, "CHOSE_CURR_NEXT", name, nextMap)
    }
    else if ( key == SELECTMAPS )
    {
    client_print(0,print_chat,"%L", LANG_PLAYER, "CHOSE_EXT", name )
    log_amx("%L", LANG_SERVER, "CHOSE_EXT", name )
    }
    else if ( key < SELECTMAPS )
    {
    client_print(0,print_chat,"%L", LANG_PLAYER, "X_CHOSE_X", name, g_mapVoteName[key])
    log_amx("%L", LANG_SERVER, "X_CHOSE_X", name, g_mapVoteName[key])
    }
    }
    ++g_voteCount[key]
    return PLUGIN_HANDLED
    }

    bool:isInMenu(map[])
    {
    for(new a=0; a<g_mapVoteNum; ++a)
    if(equal(g_mapVoteName[a], map))
    return true
    return false
    }

    public voteNextmap()
    {
    if (g_buyingtime)
    {
    return
    }

    new timelimit = get_cvar_num("mp_timelimit")
    new maxrounds = get_cvar_num("mp_maxrounds")
    new winlimit = get_cvar_num("mp_winlimit")

    if ((g_forceVote == false) && (g_rockthevote == false))
    {
    new mapchoosertype = get_pcvar_num(pv_amx_mapchooser_type)
    if (maxrounds > 0)
    {
    if (((maxrounds - 2) > (g_teamScore[0] + g_teamScore[1])) && (!g_call_say_vote) && (!g_inprogress))
    {
    set_xvar_num(get_xvar_id("NEXTMAP_ROUNDCOUNT"), (maxrounds - 2)-(g_teamScore[0] + g_teamScore[1]))
    g_selected = false

    if ((mapchoosertype == 1) && ++g_nominationsHelpMsgIter >= NOMINATIONS_HELPMSG)
    {
    g_nominationsHelpMsgIter = 0
    set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0, "%L", LANG_PLAYER, "NOMINATE_MAP")
    }

    if ((get_pcvar_num(pv_amx_rtv) > 0) && (g_nominationsHelpMsgIter + 6 == NOMINATIONS_HELPMSG) && (!g_hasbeenrocked))
    {
    set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0, "%L", LANG_PLAYER, "RTV_MAP")
    }

    return
    }
    }
    else if (winlimit > 0)
    {
    new c = winlimit - 2
    if (((c > g_teamScore[0]) && (c > g_teamScore[1])) && (!g_call_say_vote) && (!g_inprogress))
    {
    set_xvar_num(get_xvar_id("NEXTMAP_WINCOUNT"), min(c-g_teamScore[0],c-g_teamScore[1]))
    g_selected = false

    if (mapchoosertype == 1 && ++g_nominationsHelpMsgIter >= NOMINATIONS_HELPMSG)
    {
    g_nominationsHelpMsgIter = 0
    set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0, "%L", LANG_PLAYER, "NOMINATE_MAP")
    }

    if ((get_pcvar_num(pv_amx_rtv) > 0) && (g_nominationsHelpMsgIter + 6 == NOMINATIONS_HELPMSG) && (!g_hasbeenrocked))
    {
    set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0, "%L", LANG_PLAYER, "RTV_MAP")
    }

    return
    }
    }
    else
    {
    new timeleft = get_timeleft()
    //if ((timeleft < 1 || timeleft > 129) && (!g_call_say_vote) && (!g_inprogress))

    new intercept = cstrike_running() ? OP4_OFFSET : DOD_OFFSET
    ///////
    if ((timeleft < 1 || timeleft > intercept) && (!g_call_say_vote) && (!g_inprogress))

    {
    if (timeleft > 0)
    {
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    new count = 1
    while((timeleft -= 15) > 21) ++count ///129
    set_xvar_num(get_xvar_id("NEXTMAP_TIMECOUNT"), count*15)
    }
    g_selected = false

    if (mapchoosertype == 1 && ++g_nominationsHelpMsgIter >= NOMINATIONS_HELPMSG)
    {
    g_nominationsHelpMsgIter = 0
    set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0, "%L", LANG_PLAYER, "NOMINATE_MAP")
    }

    if ((get_pcvar_num(pv_amx_rtv) > 0) && (g_nominationsHelpMsgIter + 6 == NOMINATIONS_HELPMSG) && (!g_hasbeenrocked))
    {
    set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0, "%L", LANG_PLAYER, "RTV_MAP")
    }

    return
    }
    }
    }
    if ((g_selected) && (!g_call_say_vote) && (!g_rockthevote))
    return

    g_selected = true
    g_vote_finished = false

    new menu[512], mapsmenu[512], a, mkeys, pos
    new dmax = ((g_mapsNum + g_nominMapsNum - 1) > SELECTMAPS) ? SELECTMAPS : (g_mapsNum + g_nominMapsNum - 1)
    new players[MAX_PLAYERS], numplayers
    g_voteCount[SELECTMAPS] = 0
    g_voteCount[SELECTMAPS+1] = 0

    new mapname[MAX_PLAYERS]
    get_mapname(mapname, 31)
    new nextMap[MAX_PLAYERS]
    get_cvar_string("amx_nextmap", nextMap, 31)
    new error_cnt = 0

    // For small amount of players - maps_small.ini if amx_mapchooser_mapsloc is 0

    if (get_cvar_num("amx_mapchooser_mapsloc") == 0)
    {
    if (get_playersnum() < 11)
    {
    new mapslocfile_s[MAX_PLAYERS]
    new mapslocfile[MAX_PLAYERS]
    new filename[128]
    new cfgdir[128]
    get_configsdir(cfgdir, 127)

    get_cvar_string("amx_mapchooser_mapsfile_s", mapslocfile_s, 31)
    format(filename, 127, "%s/%s", cfgdir, mapslocfile_s)
    if (loadSettings(filename))
    log_message("[AMXX] - Nextmap Chooser 4: %s succesfully loaded.", mapslocfile_s)
    else if (g_mapsNum == 0)
    {
    get_cvar_string("amx_mapchooser_mapsfile", mapslocfile, 31)
    format(filename, 127, "%s/%s", cfgdir, mapslocfile)
    if (loadSettings(filename))
    log_message("[AMXX] - Nextmap Chooser 4: %s succesfully loaded instead %s.", mapslocfile, mapslocfile_s)
    else
    {
    get_cvar_string("mapcyclefile", filename, 63)
    if (loadSettings(filename))
    {
    log_message("[AMXX] - Nextmap Chooser 4: mapcycle succesfully loaded instead %s.", mapslocfile_s)
    }
    else
    {
    log_message("[AMXX] - Nextmap Chooser 4: Failed to loads maps from mapsfile. No maps loaded. ")
    }
    }
    }
    }
    }

    // Build the maps entries and the valid keys (same for all players)
    mkeys = (1<<SELECTMAPS+1)
    mapsmenu[0] = '^0'
    pos = 0
    for(g_mapVoteNum = 0; g_mapVoteNum < dmax; ++g_mapVoteNum)
    {
    if(g_nominMapsNum > 0 && g_mapVoteNum < g_nominMapsNum)
    {
    copy(g_mapVoteName[g_mapVoteNum], 31, g_nominMapName[g_mapVoteNum])
    }
    else
    {
    a = random_num(0,g_mapsNum-1)
    while((equal(g_mapName[a], nextMap) || isInMenu(g_mapName[a])) && (error_cnt < 100))
    {
    if(++a >= g_mapsNum)
    a = 0
    error_cnt++
    }
    if (error_cnt < 100)
    copy(g_mapVoteName[g_mapVoteNum], 31, g_mapName[a])
    else
    {
    client_print(0,print_chat,"[DEBUG] Preparing the map menu error!")
    log_amx("[DEBUG] Preparing the map menu error!")
    }
    }
    pos += format(mapsmenu[pos], 511-pos, "%d. %s^n", g_mapVoteNum+1, g_mapVoteName[g_mapVoteNum])
    mkeys |= (1<<g_mapVoteNum)
    g_voteCount[g_mapVoteNum] = 0
    }
    mapsmenu[pos++] = '^n'

    g_extend = false
    if (((winlimit + maxrounds) == 0) && (timelimit > 0) && (g_extendCount < get_cvar_num("amx_extendmap_max")))
    {
    mkeys |= (1<<SELECTMAPS)
    g_extend = true
    }
    if((timelimit == 0) && (maxrounds > 0) && (g_extendCount < get_cvar_num("amx_ext_round_max")))
    {
    mkeys |= (1<<SELECTMAPS)
    g_extend = true
    }
    if ((timelimit == 0) && (winlimit > 0) && (g_extendCount < get_cvar_num("amx_ext_win_max")))
    {
    mkeys |= (1<<SELECTMAPS)
    g_extend = true
    }

    for(new i = 1; i <= g_maxplayers; ++i)
    {
    g_hasVoted[i] = false
    }

    // Now build (translated) menu for each player and send it
    new menuid, tempkeys, player
    new votetime = get_pcvar_num(pv_amx_vote_time)
    get_players(players, numplayers, "c")
    for(numplayers--; numplayers >= 0; numplayers--)
    {
    player = players[numplayers]
    get_user_menu(player, menuid, tempkeys)
    if (tempkeys == 0 || menuid <= 0)
    {
    pos = format(menu,511,g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTM")
    pos += format(menu[pos], 511-pos, "%s", mapsmenu)
    if (g_extend)
    {
    pos += format(menu[pos],511-pos,"%d. %L^n",SELECTMAPS+1,LANG_SERVER,"EXTEND_MAP",mapname)
    }
    format(menu[pos], 511-pos, "%d. %L", SELECTMAPS+2,LANG_SERVER,"KEEP_CURRENT_NEXTMAP", nextMap)
    show_menu(player, mkeys, menu, votetime, "AMX Choose nextmap:")
    }
    }

    remove_task(1467853)
    new param[1]
    param[0] = 1
    set_task(CHECK_MENU_TIME, "check_menu", 1467853, param, 1)

    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 2)
    set_task(get_pcvar_float(pv_amx_vote_time), "checkVotes")
    if (!g_call_say_vote && !g_rockthevote)
    {
    client_print(0,print_chat,"%L",LANG_SERVER,"TIME_CHOOSE")
    }
    client_cmd(0, "spk Gman/Gman_Choose2")
    g_call_say_vote = false

    if (g_hasbeenrocked && g_rockthevote)
    g_rockthevote = false

    log_amx("Vote: Voting for the nextmap started")
    if (task_exists(987457)) remove_task(987457)
    }

    public cmdVoteNextMap(id,level,cid)
    {
    if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED

    if (get_xvar_num(get_xvar_id("NEXTMAP_MSG")) != 1 || g_forceVote == true)
    {
    console_print(id, "%L", LANG_PLAYER, "VOT_NOT_ALLOWED")
    return PLUGIN_HANDLED
    }

    new arg[MAX_PLAYERS]
    read_argv(1, arg, 31)
    g_forceVoteTime = str_to_num(arg)
    if (g_forceVoteTime < 2) g_forceVoteTime = 20

    g_forceVote = true
    voteNextmap()

    new authid[MAX_PLAYERS], name[MAX_PLAYERS], ipaddress[24]
    get_user_authid(id, authid, 31)
    get_user_name(id, name, 31)
    get_user_ip(id, ipaddress, 23, 1)
    log_amx("VoteNextMap: ^"%s<%d><%s><%s>^" start the vote for the next map",name,get_user_userid(id),authid,ipaddress)
    switch(get_cvar_num("amx_show_activity"))
    {
    //      case 3: print_to_admins("acdefghijklmnopqrstuvw", print_chat, _T("ADMIN %s: start the vote for the next map"), name)
    case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "X_START_VOTE", name)
    case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "START_VOTE", name)
    }

    return PLUGIN_HANDLED
    }

    public delayedChange(param[])
    {
    server_cmd("changelevel %s", param)
    }

    public doMapChange()
    {
    new string[MAX_PLAYERS], current_map[MAX_PLAYERS]
    new len = get_cvar_string("amx_nextmap", string, 31)
    get_mapname(current_map, 31)
    new modName[8]
    get_modname(modName, 7)
    if (!equal(current_map, string))
    {
    /*
    if (!equal(modName, "zp"))
    {
    message_begin(MSG_ALL, SVC_INTERMISSION)
    message_end()
    }
    */
    set_task(1.0, "delayedChange", 0, string, len)
    }
    g_forceVote = false
    }

    isLastMaps(map[])
    {
    g_MapHistory = get_pcvar_num(pv_amx_map_history)

    if (g_MapHistory < 0)
    {
    g_MapHistory = 0
    set_pcvar_num(pv_amx_map_history, 0)
    }
    else if (g_MapHistory > MAP_HISTORY_MAX)
    {
    g_MapHistory = MAP_HISTORY_MAX
    set_pcvar_num(pv_amx_map_history, MAP_HISTORY_MAX)
    }

    for (new i = 0; i < g_MapHistory; ++i)
    {
    if (equali(map, g_hist_mapName[i]))
    {
    return 1
    }
    }
    return 0
    }

    public cmdListMaps(id)
    {
    if(get_pcvar_num(pv_amx_mapchooser_type) == 1)
    {
    new arg1[8]
    new start = read_argv(1, arg1, 7) ? str_to_num(arg1) : 1
    if (--start < 0) start = 0
    if (get_cvar_num("amx_nominfromfile") == 1)
    {
    if (start >= g_mapsNum) start = g_mapsNum - 1
    console_print(id, "%L", LANG_PLAYER, "MAPS_CAN_NOMIN")
    new end = start + LISTMAPAMOUNT
    if (end > g_mapsNum) end = g_mapsNum
    for(new i = start; i < end; ++i)
    {
    console_print(id, "%3d: %s", i+1, g_mapName[i])
    }
    console_print(id, "%L", LANG_PLAYER, "MAPS_NOMIN_LIST_OF", start+1, end, g_mapsNum)
    if (end < g_mapsNum)
    console_print(id, "%L", LANG_PLAYER, "USE_LISTMAPS_MORE", end+1)
    else
    console_print(id, "%L", LANG_PLAYER, "USE_LISTMAPS_BEGIN")
    }
    else
    {
    if (start >= g_mapsOnServerNum) start = g_mapsOnServerNum - 1
    console_print(id, "%L", LANG_PLAYER, "MAPS_CAN_NOMIN")
    new end = start + LISTMAPAMOUNT
    if (end > g_mapsOnServerNum) end = g_mapsOnServerNum
    new len, pos = 2, iter = 0, text[MAX_PLAYERS]
    while((pos = read_dir("maps", pos, text, 31, len)) && iter < end)
    {
    if (len <= 4 || (len > 4 && !equali(text[len-4], ".bsp", 4))) continue
    text[len-4] = '^0'
    if (is_map_valid(text))
    {
    if (iter >= start)
    {
    console_print(id, "%3d: %s", iter+1, text)
    }
    ++iter
    }
    }
    console_print(id, "%L", LANG_PLAYER, "MAPS_NOMIN_LIST_OF", start+1, end, g_mapsOnServerNum)
    if (end < g_mapsOnServerNum)
    console_print(id, "%L", LANG_PLAYER, "USE_LISTMAPS_MORE", end+1)
    else
    console_print(id, "%L", LANG_PLAYER, "USE_LISTMAPS_BEGIN")
    }
    }
    return PLUGIN_HANDLED
    }

    public listNominations(id)
    {
    if (get_pcvar_num(pv_amx_mapchooser_type) == 1)
    {
    new a = 0, message[512], len = 0
    if (g_nominMapsNum > 0)
    {
    len = format(message, 511, "%L", id, "MAPS_NOMIN_FOR_VOTE")
    new name[24]
    while(a < g_nominMapsNum)
    {
    name[0] = '^0'
    get_user_name(g_whoNominMapNum[a], name, 23)
    len += format(message[len], 511-len, "%L", id, "MAPS_NOMIN_BY", g_nominMapName[a], name)
    ++a
    }
    set_hudmessage(0, 150, 255, 0.01, 0.18, 0, 15.0, 12.0, 1.5, 3.75, 2)
    show_hudmessage(id, message)
    }
    }
    return PLUGIN_HANDLED
    }

    public handleSay(id)
    {
    new message[256]
    read_args(message, 255)
    remove_quotes(message)

    if ((equali(message, "votenext", 8)) && (access(id, FLAG_AMX_VOTENEXTMAP)))
    {
    new Float:voting = get_pcvar_float(pv_amx_last_voting) + get_pcvar_float(pv_amx_vote_time)
    if ( voting > get_gametime() )
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "ALEADY_VOTING")
    return PLUGIN_CONTINUE
    }
    if (( voting && (voting + get_pcvar_float(pv_amx_vote_delay) > get_gametime()) ) || g_buyingtime)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "VOT_NOT_ALLOWED")
    return PLUGIN_CONTINUE
    }

    new Float:vote_time2 = get_cvar_float("amx_vote_time") + 2.0
    set_cvar_float("amx_last_voting",  get_gametime() + vote_time2 )
    client_print(id, print_chat, "%L", LANG_PLAYER, "VOTING_STARTED")
    g_call_say_vote = true
    set_task(5.0,"voteNextmap",987457)
    return PLUGIN_CONTINUE
    }
    else if ((equali(message, "rockthevote", 11)) || (equali(message, "rtv", 3)) || (equali(message, "!rtv", 4)) )
    {
    new Float:voting = get_pcvar_float(pv_amx_last_voting) + get_pcvar_float(pv_amx_vote_time)
    if (( voting && (voting + get_pcvar_float(pv_amx_vote_delay) > get_gametime()) ) || g_buyingtime)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "VOT_NOT_ALLOWED")
    if ( voting && (voting + get_pcvar_float(pv_amx_vote_delay) > get_gametime()) )
    client_print(id, print_chat, "Map voting is temporarily prohibited.")
    if (g_buyingtime)
    client_print(id, print_chat, "Buying time (15s) not elapsed yet from the round start.")
    return PLUGIN_CONTINUE
    }
    rock_the_vote(id)
    return PLUGIN_CONTINUE
    }
    else if (get_pcvar_num(pv_amx_mapchooser_type) == 1)
    {
    if (containi(message, "<") != -1
    || containi(message, "?") != -1
    || containi(message, ">") != -1
    || containi(message, "*") != -1
    || containi(message, "&") != -1
    || containi(message, ".") != -1
    || containi(message, "/") != -1
    || containi(message, "\") != -1
    || containi(message, "!") != -1)
    {
    return PLUGIN_CONTINUE
    }
    if (equali(message, "nominations", 11 || equali(message, "noms", 4)))  ///2017
    {
    if (get_xvar_num(get_xvar_id("NEXTMAP_MSG")) == 2)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "VOTING_IN_PROGRESS")
    }
    else
    {
    if(!g_nominMapsNum)
    client_print(id, print_chat, "%L", LANG_PLAYER, "NO_MAPS_NOMIN")
    else
    listNominations(id)
    }
    return PLUGIN_CONTINUE
    }
    else if (equali(message, "nominate ", 9))
    {
    handleNominate(id, message[9])
    }
    else if (equali(message, "nom ", 4)) ///JULY 2019
    {
    handleNominate(id, message[4])
    }
    else if (equali(message, "vote ", 5))
    {
    handleNominate(id, message[5])
    }
    else if (is_map_valid(message))
    {
    nominateMap(id, message)
    }
    else
    {
    new mapname[MAX_PLAYERS], saymap[29]
    read_args(saymap, 28)
    remove_quotes(saymap)
    format(mapname,31, "aim_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "as_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "awp_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "cs_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "de_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "fy_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "he_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "ka_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "kz_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname,31, "op4ctf_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname,31, "op4_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname,31, "ook_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    format(mapname, 31, "dod_%s", saymap)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_CONTINUE
    }
    }
    }
    return PLUGIN_CONTINUE
    }

    public handleNominate(id,map[])
    {
    if (is_map_valid(map))
    {
    nominateMap(id, map)
    }
    else
    {
    new mapname[MAX_PLAYERS]
    format(mapname, 31, "aim_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "as_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "awp_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "cs_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "de_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "fy_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "he_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "ka_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "kz_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "ook_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "op4ctf_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "op4_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    format(mapname, 31, "dod_%s", map)
    if (is_map_valid(mapname))
    {
    nominateMap(id, mapname)
    return PLUGIN_HANDLED
    }
    client_print(id, print_chat, "%L", LANG_PLAYER, "MAP_NOT_FOUND_LIST", map)
    }
    return PLUGIN_HANDLED
    }
    public nominateMap(id,map[])
    {
    strtolower(map)
    new current_map[MAX_PLAYERS]
    new n = 0, i, done = 0, isreplacement = 0
    get_mapname(current_map, 31)
    new temp_nominMapNums = g_nominMapsNum
    if (get_xvar_num(get_xvar_id("NEXTMAP_MSG")) == 2)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "VOTING_IN_PROGRESS")
    return PLUGIN_HANDLED
    }
    if (get_xvar_num(get_xvar_id("NEXTMAP_MSG")) == 3)
    {
    new nextmap[MAX_PLAYERS]
    get_cvar_string("amx_nextmap", nextmap, 31)
    client_print(id, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", nextmap)
    return PLUGIN_HANDLED
    }
    if (!is_map_valid(map))
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "MAP_NOT_FOUND_LIST", map)
    return PLUGIN_HANDLED
    }
    if (isLastMaps(map) && !equali(map,current_map))
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "CANNOT_NOM_LAST_PLAYED", g_MapHistory)
    return PLUGIN_HANDLED
    }
    if (equali(map,current_map))
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "X_CURR_MAP_EV_EXT", map)
    return PLUGIN_HANDLED
    }
    new isinthelist = 0
    if (get_cvar_num("amx_nominfromfile") == 1)
    {
    for (i = 0; i < g_mapsNum; ++i)
    {
    if (equali(map, g_mapName[i]))
    {
    isinthelist = 1
    break
    }
    }
    }
    else
    {
    if (is_map_valid(map))
    isinthelist = 1
    }
    if (!isinthelist)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "NOM_CERTAIN_MAPS_ONLY")
    return PLUGIN_HANDLED
    }
    new maxnom = get_cvar_num("amx_maxnominperplayer")
    if (g_nominMapsNum >= SELECTMAPS || g_nominated[id] >= maxnom)
    {
    if (g_nominated[id] > maxnom)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "NOMIN_TOO_MANY", maxnom)
    return PLUGIN_HANDLED
    }
    new plname[MAX_PLAYERS]
    for(i = 0; i < g_nominMapsNum; ++i)
    {
    if (equali(map, g_nominMapName[i]))
    {
    get_user_name(g_whoNominMapNum[i], plname, 31)
    client_print(id, print_chat, "%L", LANG_PLAYER, "MAP_ALREADY_NOMIN_BY", map, plname)
    return PLUGIN_HANDLED
    }
    }
    while(n < g_nominMapsNum && !done && g_nominated[id] > 1)
    {
    if (g_whoNominMapNum[n] == id)
    {
    g_nominated[id]--
    g_nominMapsNum = n
    done = 1
    isreplacement = 1
    }
    ++n
    }
    if (!done)
    {
    n = 0
    while(n < g_nominMapsNum && !done && g_nominated[id] > 0)
    {
    if(g_whoNominMapNum[n] == id)
    {
    g_nominated[id]--
    g_nominMapsNum = n
    done = 1
    isreplacement = 1
    }
    ++n
    }
    }
    if (!done)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "MAXIM_NOMIN_REACHED", g_nominMapsNum)
    return PLUGIN_HANDLED
    }
    }
    new plname[MAX_PLAYERS]
    for(i = 0; i < g_nominMapsNum; ++i)
    {
    if (equali(map, g_nominMapName[i]))
    {
    get_user_name(g_whoNominMapNum[i], plname, 31)
    client_print(id, print_chat, "%L", LANG_PLAYER, "MAP_ALREADY_NOMIN_BY", map, plname)
    g_nominMapsNum = temp_nominMapNums
    return PLUGIN_HANDLED
    }
    }
    new name[MAX_PLAYERS]
    get_user_name(id, name, 31)
    if (isreplacement == 1)
    {
    client_print(id, print_chat, "%L", LANG_PLAYER, "YOUR_NOMIN_REPLACED", g_nominMapName[g_nominMapsNum])
    }
    else if (isreplacement == 2)
    {
    client_print(0, print_chat, "%L", LANG_PLAYER, "THE_NOMIN_OF_X_REPLACED", g_nominMapName[g_nominMapsNum])
    }
    ++g_nominated[id]
    console_print(id, "%L", LANG_PLAYER, "NOMIN_MAP_ADDED", map, g_nominMapsNum+1)
    copy(g_nominMapName[g_nominMapsNum], 31, map)
    g_whoNominMapNum[g_nominMapsNum] = id
    if (isreplacement)
    {
    g_nominMapsNum = temp_nominMapNums
    }
    else
    {
    g_nominMapsNum = temp_nominMapNums + 1
    }
    client_print(0, print_chat, "%L", LANG_PLAYER, "X_NOMIN_MAP_SEE_LIST" , name, map)
    return PLUGIN_HANDLED
    }

    load_history(filename[])
    {
    g_MapHistory = get_pcvar_num(pv_amx_map_history)

    if (g_MapHistory < 0)
    {
    g_MapHistory = 0
    set_pcvar_num(pv_amx_map_history, 0)
    }
    else if (g_MapHistory > MAP_HISTORY_MAX)
    {
    g_MapHistory = MAP_HISTORY_MAX
    set_pcvar_num(pv_amx_map_history, MAP_HISTORY_MAX)
    }

    if (!file_exists(filename)) return 0

    new a = 0
    for (new pos = 0; pos < g_MapHistory; pos++)
    read_file(filename,pos,g_hist_mapName[pos],31,a)

    return 1
    }

    loadSettings(filename[])
    {
    if (!file_exists(filename)) return 0

    g_mapsNum = 0
    new szText[MAX_PLAYERS]
    new a = 0, pos = 0, i
    new currentMap[MAX_PLAYERS]
    get_mapname(currentMap,31)

    g_MapHistory = get_pcvar_num(pv_amx_map_history)

    if (g_MapHistory < 0)
    {
    g_MapHistory = 0
    set_pcvar_num(pv_amx_map_history, 0)
    }
    else if (g_MapHistory > MAP_HISTORY_MAX)
    {
    g_MapHistory = MAP_HISTORY_MAX
    set_pcvar_num(pv_amx_map_history, MAP_HISTORY_MAX)
    }

    while(g_mapsNum < MAX_MAPS && (pos = read_file(filename, pos, szText, 31, a)))
    {
    if(!a || szText[0] == ';' || szText[0] == '/') continue

    parse(szText, g_mapName[g_mapsNum], 31)

    replace_all(g_mapName[g_mapsNum], 31, " ", "")
    replace_all(g_mapName[g_mapsNum], 31, ".bsp", "")

    if (is_map_valid(g_mapName[g_mapsNum])
    && !equali(g_mapName[g_mapsNum], g_lastMap)
    && !equali(g_mapName[g_mapsNum], currentMap))
    {
    ++g_mapsNum
    for(i = 0; i < g_MapHistory; ++i)
    {
    if(equali(g_mapName[g_mapsNum-1], g_hist_mapName[i]))
    {
    --g_mapsNum
    break
    }
    }
    }
    }
    return g_mapsNum
    }


    loadMapsFolder()
    {
    g_mapsNum = 0

    new len, pos = 2, i
    new currentMap[MAX_PLAYERS]
    get_mapname(currentMap, 31)

    g_MapHistory = get_pcvar_num(pv_amx_map_history)

    if (g_MapHistory < 0)
    {
    g_MapHistory = 0
    set_pcvar_num(pv_amx_map_history, 0)
    }
    else if (g_MapHistory > MAP_HISTORY_MAX)
    {
    g_MapHistory = MAP_HISTORY_MAX
    set_pcvar_num(pv_amx_map_history, MAP_HISTORY_MAX)
    }

    while(g_mapsNum < MAX_MAPS && (pos = read_dir("maps/", pos, g_mapName[g_mapsNum], 31, len)))
    {
    if (len <= 4 || (len > 4 && !equali(g_mapName[g_mapsNum][len-4], ".bsp", 4))) continue

    g_mapName[g_mapsNum][len-4] = '^0'
    if (is_map_valid(g_mapName[g_mapsNum])
    && !equali(g_mapName[g_mapsNum], g_lastMap)
    && !equali(g_mapName[g_mapsNum], currentMap))
    {
    ++g_mapsNum
    for(i = 0; i < g_MapHistory; ++i)
    {
    if (equali(g_mapName[g_mapsNum-1], g_hist_mapName[i]))
    {
    --g_mapsNum
    break
    }
    }
    }
    }

    return g_mapsNum
    }

    getMapsOnServerNum()
    {
    new len, pos = 2, text[MAX_PLAYERS]
    while((pos = read_dir("maps/", pos, text, 31, len)))
    {
    if (len <= 4 || (len > 4 && !equali(text[len-4], ".bsp", 4))) continue
    text[len-4] = '^0'
    if (is_map_valid(text))
    {
    ++g_mapsOnServerNum
    }
    }
    log_amx("Found %d maps in maps folder", g_mapsOnServerNum)
    log_message("[AMXX] - Nextmap Chooser 4: Found %d maps in maps folder", g_mapsOnServerNum)
    }

    public team_score()
    {
    new team[2]
    read_data(1, team, 1)
    g_teamScore[(team[0]=='C') ? 0 : 1] = read_data(2)
    new winlimit = get_cvar_num("mp_winlimit")
    new maxrounds = get_cvar_num("mp_maxrounds")
    if (maxrounds > 0)
    {
    if ((maxrounds - 2) > (g_teamScore[0] + g_teamScore[1]))
    {
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_xvar_num(get_xvar_id("NEXTMAP_ROUNDCOUNT"), (maxrounds - 2) - (g_teamScore[0] + g_teamScore[1]))
    }
    else
    set_xvar_num(get_xvar_id("NEXTMAP_ROUNDCOUNT"), 0)
    }
    if (winlimit > 0)
    {
    new c = winlimit - 2
    if ((c > g_teamScore[0]) && (c > g_teamScore[1]))
    {
    set_xvar_num(get_xvar_id("NEXTMAP_MSG"), 1)
    set_xvar_num(get_xvar_id("NEXTMAP_WINCOUNT"), min(c-g_teamScore[0],c-g_teamScore[1]))
    }
    else
    set_xvar_num(get_xvar_id("NEXTMAP_WINCOUNT"), 0)
    }
    }

    public plugin_end()
    {
    new current_map[MAX_PLAYERS]
    get_mapname(current_map,31 )
    set_localinfo("lastMap",current_map)

    g_MapHistory = get_pcvar_num(pv_amx_map_history)

    if (g_MapHistory < 0)
    {
    g_MapHistory = 0
    set_pcvar_num(pv_amx_map_history, 0)
    }
    else if (g_MapHistory > MAP_HISTORY_MAX)
    {
    g_MapHistory = MAP_HISTORY_MAX
    set_pcvar_num(pv_amx_map_history, MAP_HISTORY_MAX)
    }


    if ((file_exists(g_maphistFile)) && (g_MapHistory > 0))
    {
    new text[MAX_PLAYERS]
    new a = 0
    // shift list up 1
    for (new pos = 0; pos < g_MapHistory; pos++)
    {
    read_file(g_maphistFile,pos+1,text,31,a)
    write_file(g_maphistFile,text,pos)
    }
    }
    write_file(g_maphistFile,current_map,g_MapHistory-1)
    }

    public eNewRound()
    {
    if (!task_exists(987400))
    {
    set_task(15.0,"buyFinished",987400)
    g_buyingtime = true
    }
    }

    public eEndRound()
    {
    if (g_ForceChangeMap)
    {
    g_ForceChangeMap = false
    if (task_exists(6482257)) remove_task(6482257)
    doMapChange()
    }
    else
    {
    if (!task_exists(987400))
    {
    set_task(15.0,"buyFinished",987400)
    }
    g_buyingtime = true
    }
    }

    public buyFinished()
    {
    g_buyingtime = false
    return
    }

    public rock_the_vote(id)
    {
    new Float:rtv_percent = get_pcvar_float(pv_amx_rtv_percent)
    new needed
    new kName[MAX_PLAYERS]
    get_user_name(id,kName,31)
    new timeleft = get_timeleft()
    new Float:minutesplayed = get_gametime() / 60.0
    new Float:wait = get_pcvar_float(pv_amx_rtv_min_time)
    new Float:timelimit = get_cvar_float("mp_timelimit")
    new maxrounds = get_cvar_num("mp_maxrounds")
    new winlimit = get_cvar_num("mp_winlimit")

    if (wait < 1.0)
    wait = 1.0
    else if (wait > 100.0)
    wait = 100.0

    if (rtv_percent < 0.03)
    rtv_percent = 0.03
    else if (rtv_percent > 1.00)
    rtv_percent = 1.00

    needed = floatround(float(g_active_players) * rtv_percent + 0.49)

    if (get_pcvar_num(pv_amx_rtv) == 0)
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"RTV_DISABLED")
    return
    }
    if (g_inprogress || task_exists(987457))
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"VOTE_BEGINNING")
    return
    }
    if (g_selected || g_vote_finished)
    {
    new smap[MAX_PLAYERS]
    get_cvar_string("amx_nextmap",smap,31)
    client_print(id,print_chat,"%L",LANG_PLAYER,"VOTING_COMPLETED",smap)
    return
    }
    if (g_hasbeenrocked)
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"MAP_ALREADY_ROCKED")
    return
    }

    if ((timeleft < 120) && (timelimit > 0.0))
    {
    if (timeleft < 1)
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"NOT_ENOUGH_TIME")
    return
    }
    }

    if (maxrounds > 0)
    {
    if ((maxrounds - 2) <= (g_teamScore[0] + g_teamScore[1]))
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"NOT_ENOUGH_TIME")
    return
    }
    }

    if (winlimit > 0)
    {
    new c = winlimit - 2
    if ((c <= g_teamScore[0]) || (c <= g_teamScore[1]))
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"NOT_ENOUGH_TIME")
    return
    }
    }

    if ((minutesplayed + 0.5) < wait)
    {
    if (wait - 0.5 - minutesplayed > 0.0)
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"RTV_WAIT",
    (floatround(wait + 0.5 - minutesplayed) > 0) ? (floatround(wait + 0.5 - minutesplayed)):(1))
    }
    else
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"RTV_1MIN")
    }
    return
    }

    if (!g_rocked[id])
    {
    g_rocked[id] = 1
    g_rocks++
    }
    else
    {
    client_print(id,print_chat,"%L",LANG_PLAYER,"MAP_ALREADY_ROCKED")
    return
    }

    if (g_rocks >= needed)
    {
    client_print(0,print_chat,"%L",LANG_PLAYER,"RTV_STARTING", g_rocks)
    set_hudmessage(222, 70,0, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4)
    show_hudmessage(0,"%L",LANG_PLAYER,"RTV_START",g_rocks )
    g_hasbeenrocked = true
    g_rockthevote = true
    g_inprogress = true
    g_vote_finished = false
    set_task(15.0, "voteNextmap", 987457)

    for(new i = 1; i < 33; ++i)
    {
    g_rocked[i] = 0
    }
    g_rocks = 0

    g_forceVoteTime = 20
    g_forceVote = true

    new Float:vote_time2 = get_cvar_float("amx_vote_time") + 2.0
    set_cvar_float("amx_last_voting",  get_gametime() + vote_time2 )
    }
    else
    client_print(0,print_chat,"%L",LANG_PLAYER,"RTV_NEEDED",(needed - g_rocks))
    return
    }
