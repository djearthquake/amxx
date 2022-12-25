// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// Nextmap Chooser Plugin
//

#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>

#define SELECTMAPS  8

#define PLUGIN "Nextmap Chooser+"
#define AUTHOR "SPINX|AMXX Dev Team"
#define VOTE_MAP_TASK 987456
///MACROS for AMXX 1.8.2 local compile.


#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_CMD_LENGTH             128
#define MAX_MENU_LENGTH            512
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH              16
#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1

new Array:g_mapName;
new g_mapNums;
new Pcvar_captures
new g_counter
new bool:b_set_caps
new bool:B_op4c_map

new g_nextName[SELECTMAPS]
new g_voteCount[SELECTMAPS + 2]
new g_mapVoteNum
new g_teamScore[2]
new g_lastMap[MAX_RESOURCE_PATH_LENGTH]

new g_coloredMenus
new bool:g_selected = false
new bool:g_rtv = false
new bool:bOF_run
new g_mp_chattime, g_auto_pick, g_max, g_step, g_rnds, g_wins, g_frags, g_frags_remaining, g_timelim, g_votetime
new Float:checktime

public plugin_init()
{
    register_plugin(PLUGIN, AMXX_VERSION_STR, AUTHOR)
    register_dictionary("mapchooser.txt")
    register_dictionary("common.txt")

    g_mapName=ArrayCreate(MAX_RESOURCE_PATH_LENGTH);

    new MenuName[MAX_RESOURCE_PATH_LENGTH]

    format(MenuName, charsmax(MenuName), "%L", "en", "CHOOSE_NEXTM")
    register_menucmd(register_menuid(MenuName), (charsmin^(charsmin<<(SELECTMAPS+2))), "countVote")
    #if !defined create_cvar
    #define create_cvar register_cvar
    #endif
    bOF_run = is_running("gearbox") == 1
    g_max       = create_cvar("amx_extendmap_max", "90")
    g_step      = create_cvar("amx_extendmap_step", "15")
    g_auto_pick = create_cvar("mapchooser_auto", "0")

    Pcvar_captures = get_cvar_pointer("mp_captures") ? get_cvar_pointer("mp_captures") : register_cvar("mp_captures", "0")

    get_localinfo("lastMap", g_lastMap, charsmax(g_lastMap))
    set_localinfo("lastMap", "")

    new maps_ini_file[MAX_RESOURCE_PATH_LENGTH]
    get_configsdir(maps_ini_file, charsmax(maps_ini_file));
    format(maps_ini_file, charsmax(maps_ini_file), "%s/maps.ini", maps_ini_file);

    if (!file_exists(maps_ini_file))
        get_cvar_string("mapcyclefile", maps_ini_file, charsmax(maps_ini_file))
    if (loadSettings(maps_ini_file))
    {
        checktime = cstrike_running() ? 15.0 : 2.0 ;
        set_task(checktime, "voteNextmap", VOTE_MAP_TASK, "", 0, "b")
    }

#if AMXX_VERSION_NUM == 182
    g_mp_chattime       = get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : register_cvar("mp_chattime", "20")
    g_wins              = get_cvar_pointer("mp_winlimit")
    g_rnds              = get_cvar_pointer("mp_maxrounds")
    g_counter           = get_cvar_pointer("mp_captures")
    g_frags             = get_cvar_pointer("mp_fraglimit")
    g_frags_remaining   = get_cvar_pointer("mp_fragleft")
    g_timelim           = get_cvar_pointer("mp_timelimit")
    g_votetime          = get_cvar_pointer("amx_vote_time")
#else
    g_coloredMenus      = colored_menus()
    bind_pcvar_num(get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : register_cvar("mp_chattime", "20"),g_mp_chattime)

    if ( bOF_run )
    {

        B_op4c_map = false
        if(find_ent(charsmin,"info_ctfdetect") > 0)
            B_op4c_map = true

        if(B_op4c_map)
        {
            g_counter = get_pcvar_num(Pcvar_captures)
            (b_set_caps) ? g_counter : set_pcvar_num(Pcvar_captures, 6) &g_counter
            server_print "CAPTURE POINT MAP DETECTED!"
            register_logevent("@count", 3, "2=CapturedFlag")
        }
        else
            set_pcvar_num(Pcvar_captures, 0)

    }

    if(get_cvar_pointer("mp_winlimit"))
        bind_pcvar_num(get_cvar_pointer("mp_winlimit"),g_wins)

    if(get_cvar_pointer("mp_maxrounds"))
        bind_pcvar_num(get_cvar_pointer("mp_maxrounds"),g_rnds)

    if(get_cvar_pointer("mp_fraglimit"))
        bind_pcvar_num(get_cvar_pointer("mp_fraglimit"),g_frags)

    if(get_cvar_pointer("mp_fragsleft"))
        bind_pcvar_num(get_cvar_pointer("mp_fragsleft"),g_frags_remaining)

    if(get_cvar_pointer("mp_timelimit"))
        bind_pcvar_num(get_cvar_pointer("mp_timelimit"),g_timelim)

    if(get_cvar_num("amx_vote_time"))
        bind_pcvar_num(get_cvar_pointer("amx_vote_time"),g_votetime)

    if(cstrike_running() || get_cvar_pointer("mp_teamplay"))
        register_event("TeamScore", "team_score", "a")
#endif
}

@rtv(id)
if(is_user_connected(id))
{
    server_print "%s|%n called RTV", PLUGIN, id
    g_rtv=true
    change_task(987456,1.0)
}

public checkVotes()
{
    new b = 0

    for (new a = 0; a < g_mapVoteNum; ++a)
        if (g_voteCount[b] < g_voteCount[a])
            b = a

    if (g_voteCount[SELECTMAPS] > g_voteCount[b]
        && g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+1])
    {
        new mapname[MAX_RESOURCE_PATH_LENGTH]
        get_mapname(mapname, charsmax(mapname))

        new Float:steptime = get_pcvar_float(g_step)

        //Half-Life Frags
        new timeleft = get_timeleft()
        if(g_frags && g_frags_remaining && timeleft > 129 )
        {
            log_amx"Setting frags"
            set_cvar_num("mp_fraglimit", g_frags + floatround(steptime))
            //client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_EXT", steptime) //need frags instead of min translated
            client_print 0, print_chat, "Incrementing frag limit to %i.", g_frags
            log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to  %i frags", mapname, g_frags)
            g_selected = false
        }

        else
        {
            log_amx"Setting ext time"
            set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + steptime)
            client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_EXT", steptime)
            log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %.0f minutes", mapname, steptime)
            g_selected = false
        }

        return
    }

    new smap[MAX_RESOURCE_PATH_LENGTH]
    if (g_voteCount[b] && g_voteCount[SELECTMAPS + 1] <= g_voteCount[b])
    {
        ArrayGetString(g_mapName, g_nextName[b], smap, charsmax(smap));
        set_cvar_string("amx_nextmap", smap);
    }

    get_cvar_string("amx_nextmap", smap, charsmax(smap))
    client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", smap)
    log_amx("Vote: Voting for the nextmap finished. The nextmap will be %s", smap)
/*
    if(is_plugin_loaded("safe_mode.amxx",true)!=charsmin)
    {
        log_amx "Pushing map %s through safemode plugin.", smap
        callfunc_begin("@cmd_call","safe_mode.amxx")
        callfunc_push_str(smap)
        callfunc_end()
    }
*/
    if(g_rtv)
    {
        remove_task(987456)
        if(g_mp_chattime < 2)
        {
            g_mp_chattime = 5
        }
        set_task(float(g_mp_chattime),"@changemap",987456,smap,charsmax(smap))
    }

}

@changemap(smap[MAX_RESOURCE_PATH_LENGTH])
{
    if(ValidMap(smap))
    {

        if(is_plugin_loaded("safe_mode.amxx",true)!=charsmin)
        {
            log_amx "Pushing map %s through safemode plugin...", smap
            callfunc_begin("@cmd_call","safe_mode.amxx")
            callfunc_push_str(smap)
            callfunc_end()
        }

        set_task(float(g_mp_chattime),"@changemap",987456,smap,charsmax(smap))
        server_print "Trying to change to map %s", smap
        engine_changelevel(smap)
    }
}

#if AMXX_VERSION_NUM == 182
stock engine_changelevel(smap[MAX_RESOURCE_PATH_LENGTH])
{
    server_cmd("changelevel %s", smap)
}
#endif

public countVote(id, key)
{
    if (get_cvar_float("amx_vote_answers"))
    {
        new name[MAX_RESOURCE_PATH_LENGTH]
        get_user_name(id, name, charsmax(name))

        if (key == SELECTMAPS)
            client_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_EXT", name)
        else if (key < SELECTMAPS)
        {
            new map[MAX_RESOURCE_PATH_LENGTH];
            ArrayGetString(g_mapName, g_nextName[key], map, charsmax(map));
            client_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", name, map);
        }
    }
    ++g_voteCount[key]

    return PLUGIN_HANDLED
}

bool:isInMenu(id)
{
    for (new a = 0; a < g_mapVoteNum; ++a)
        if (id == g_nextName[a])
            return true
    return false
}

@auto_map_pick()
{   server_print "auto-picking maps"
    new players[MAX_PLAYERS]
    new playercount

    get_players(players,playercount,"i")

    for (new m=0; m<playercount; ++m)
    {
        #if defined amxclient_cmd
        amxclient_cmd(players[m],random_map_pick()) //hooks all with unknown command
        #endif
        server_print "Trying amxclient_cmd..."
        console_cmd(players[m],random_map_pick())
        server_print "Trying console_cmd..."
        client_cmd(players[m],random_map_pick()) //humans only
        server_print "Trying client_cmd..."
        //engclient_cmd(players[m],random_map_pick()) //joke
    }
}
stock random_map_pick()
{
    new custom;
    custom = random_num(1,5)
    new formated[MAX_IP_LENGTH]
    formatex(formated,charsmax(formated),"menuselect %i", custom)
    return formated;
}

public voteNextmap()
{
    new timeleft = get_timeleft()
    new votetime, chatime
    chatime = g_mp_chattime
    //new captures
    //captures = get_pcvar_num(Pcvar_captures)
    #if AMXX_VERSION_NUM == 182
    votetime = get_pcvar_num(g_votetime)
    chatime = get_pcvar_num(g_mp_chattime)
    #else
    votetime = g_votetime
    chatime = g_mp_chattime
    #endif
    new smap[MAX_RESOURCE_PATH_LENGTH]
    new vote_menu_display = cstrike_running() ? 129 : chatime + (votetime*2)

    if(g_frags > 0 && g_frags_remaining == 1)
    {
        log_amx"HL server frag limit map change"
        callfunc_begin("changeMap","nextmap.amxx")?callfunc_end():@changemap(smap)
        remove_task(987456)
        return
    }

    if(Pcvar_captures && get_pcvar_num(Pcvar_captures))
    {
        if(get_pcvar_num(Pcvar_captures) <2)
        {
            remove_task(987456)
            log_amx"CTF point map change"
            //@changemap(smap)
            callfunc_begin("changeMap","nextmap.amxx")?callfunc_end():@changemap(smap)
            B_op4c_map = false
            return
        }
    }

    if (g_selected)
        return


    #if AMXX_VERSION_NUM == 182
    if(g_wins & get_pcvar_num(g_wins))
    #else
    if (g_wins)
    #endif
    {
        new c = g_wins - 2
        if ((c > g_teamScore[0]) && (c > g_teamScore[1]))
        {
            g_selected = false
            return
        }
    }

    //if(is_running("gearbox") == 1 )
    else if(get_pcvar_num(Pcvar_captures))
    {
        if( get_pcvar_num(Pcvar_captures) > 3 && timeleft > (vote_menu_display + chatime + (votetime*2) ) )
        {
            g_selected = false
            return
        }
    }

    #if AMXX_VERSION_NUM == 182
    else if(g_rnds & get_pcvar_num(g_rnds))
    #else
    else if (g_rnds)
    #endif
    {
        if ((g_rnds - 2) > (g_teamScore[0] + g_teamScore[1]))
        {
            g_selected = false
            return
        }
    }

    #if AMXX_VERSION_NUM == 182
    else if(g_frags)
    {
        if ( get_pcvar_num(g_frags_remaining) > 5 && timeleft > (vote_menu_display + chatime + (votetime*2) ) && !g_rtv )

    #else
    else if (g_frags)
    {
        if ( g_frags_remaining > 5 && timeleft > (vote_menu_display + chatime + (votetime*2) ) && !g_rtv )
    #endif
        {
            g_selected = false
            return
        }
    }
    else
    {
        if (timeleft < 1 || timeleft > (vote_menu_display + chatime + (votetime*2) ) && !g_rtv)
        {
            g_selected = false
            return
        }
    }


    if (g_selected)
        return

    g_selected = true
    new menu[MAX_MENU_LENGTH], a, mkeys = (1<<SELECTMAPS + 1)

    new pos = format(menu, charsmax(menu), g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTM")
    new dmax = (g_mapNums > SELECTMAPS) ? SELECTMAPS : g_mapNums

    for (g_mapVoteNum = 0; g_mapVoteNum < dmax; ++g_mapVoteNum)
    {
        a = random_num(0, g_mapNums - 1)

        while (isInMenu(a))
            if (++a >= g_mapNums) a = 0

        g_nextName[g_mapVoteNum] = a
        pos += format(menu[pos], charsmax(menu) - pos, "%d. %a^n", g_mapVoteNum + 1, ArrayGetStringHandle(g_mapName, a));
        mkeys |= (1<<g_mapVoteNum)
        g_voteCount[g_mapVoteNum] = 0
    }

    menu[pos++] = '^n'
    g_voteCount[SELECTMAPS] = 0
    g_voteCount[SELECTMAPS + 1] = 0

    new mapname[MAX_NAME_LENGTH]
    get_mapname(mapname, charsmax(mapname))

    if ((g_wins + g_rnds) == 0 && (get_cvar_float("mp_timelimit") < get_pcvar_float(g_max)))
    {
        pos += format(menu[pos], charsmax(menu) - pos, "%d. %L^n", SELECTMAPS + 1, LANG_SERVER, "EXTED_MAP", mapname)
        mkeys |= (1<<SELECTMAPS)
    }

    format(menu[pos], charsmax(menu), "%d. %L", SELECTMAPS+2, LANG_SERVER, "NONE")
    new MenuName[MAX_RESOURCE_PATH_LENGTH]

    format(MenuName, charsmax(MenuName), "%L", "en", "CHOOSE_NEXTM")
    show_menu(0, mkeys, menu, 15, MenuName)
    set_task(15.0, "checkVotes")
    //AUTOPICK MAPS FOR DEBUGGING ETC
    if(get_pcvar_num(g_auto_pick))set_task(2.0,"@auto_map_pick")
    client_print(0, print_chat, "%L", LANG_SERVER, "TIME_CHOOSE")
    client_cmd(0, "spk Gman/Gman_Choose2")
    log_amx("Vote: Voting for the nextmap started")
    log_amx "Map vote conducted with %i sec remaining.",timeleft

}
stock bool:ValidMap(mapname[])
{
    if ( is_map_valid(mapname) )
    {
        return true;
    }
    // If the is_map_valid check failed, check the end of the string
    new len = strlen(mapname) - 4;

    // The mapname was too short to possibly house the .bsp extension
    if (len < 0)
    {
        return false;
    }
    if ( equali(mapname[len], ".bsp") )
    {
        // If the ending was .bsp, then cut it off.
        // the string is byref'ed, so this copies back to the loaded text.
        mapname[len] = '^0';

        // recheck
        if ( is_map_valid(mapname) )
        {
            return true;
        }
    }

    return false;
}

loadSettings(filename[])
{
    if (!file_exists(filename))
        return 0

    new szText[MAX_RESOURCE_PATH_LENGTH]
    new currentMap[MAX_RESOURCE_PATH_LENGTH]

    new buff[MAX_USER_INFO_LENGTH];

    get_mapname(currentMap, charsmax(currentMap))

    new fp=fopen(filename,"r");

    while (!feof(fp))
    {
        buff[0]='^0';
        szText[0]='^0';

        fgets(fp, buff, charsmax(buff));

        parse(buff, szText, charsmax(szText));


        if (szText[0] != ';' &&
            ValidMap(szText) &&
            !equali(szText, g_lastMap) &&
            !equali(szText, currentMap))
        {
            ArrayPushString(g_mapName, szText);
            ++g_mapNums;
        }

    }

    fclose(fp);

    return g_mapNums
}

public team_score()
{
    new team[2]

    read_data(1, team, charsmax(team))
    g_teamScore[(team[0]=='C') ? 0 : 1] = read_data(2)
}

public plugin_end()
{
    new current_map[MAX_RESOURCE_PATH_LENGTH]

    get_mapname(current_map, charsmax(current_map))
    set_localinfo("lastMap", current_map)

    ArrayDestroy(g_mapName)
}

public pfn_keyvalue( ent )
{
    if (is_running("gearbox") == 1 )
    {
        new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
        Pcvar_captures = get_cvar_pointer("mp_captures") ? get_cvar_pointer("mp_captures") : register_cvar("mp_captures", "0")

        copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

        if(equali(Classname,"info_ctfdetect") && equali(key,"map_score_max") && !b_set_caps)
        {
            b_set_caps = true
            set_pcvar_num(Pcvar_captures, str_to_num(value))
        }
    }
}

@count()
{
    g_counter--
    set_pcvar_num(Pcvar_captures,g_counter)
    server_print "[AMX]FLAG CAPTURED"
}
