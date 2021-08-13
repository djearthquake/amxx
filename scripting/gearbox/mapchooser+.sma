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

#define SELECTMAPS  5
#define PLUGIN "Nextmap Chooser+"
#define AUTHOR "SPINX|AMXX Dev Team"
#define VOTE_MAP_TASK 987456
///MACROS for AMXX 1.8.2 local compile.


#define MAX_PLAYERS                32

#define MAX_RESOURCE_PATH_LENGTH   64

#define MAX_MENU_LENGTH            512

#define MAX_NAME_LENGTH            32

#define MAX_AUTHID_LENGTH          64

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1

new Array:g_mapName;
new g_mapNums;

new g_nextName[SELECTMAPS]
new g_voteCount[SELECTMAPS + 2]
new g_mapVoteNum
new g_teamScore[2]
new g_lastMap[MAX_PLAYERS]

new g_coloredMenus
new bool:g_selected = false
new g_mp_chattime, g_auto_pick, g_max, g_step, g_rnds, g_wins, g_frags, g_frags_remaining, g_timelim

public plugin_init()
{
    register_plugin(PLUGIN, AMXX_VERSION_STR, AUTHOR)
    register_dictionary("mapchooser.txt")
    register_dictionary("common.txt")

    g_mapName=ArrayCreate(MAX_NAME_LENGTH);

    new MenuName[MAX_RESOURCE_PATH_LENGTH]

    format(MenuName, charsmax(MenuName), "%L", "en", "CHOOSE_NEXTM")
    register_menucmd(register_menuid(MenuName), (charsmin^(charsmin<<(SELECTMAPS+2))), "countVote")
    g_max       = create_cvar("amx_extendmap_max", "90")
    g_step      = create_cvar("amx_extendmap_step", "15")
    g_auto_pick = create_cvar("mapchooser_auto", "0")

    get_localinfo("lastMap", g_lastMap, charsmax(g_lastMap))
    set_localinfo("lastMap", "")

    new maps_ini_file[64]
    get_configsdir(maps_ini_file, charsmax(maps_ini_file));
    format(maps_ini_file, charsmax(maps_ini_file), "%s/maps.ini", maps_ini_file);

    if (!file_exists(maps_ini_file))
        get_cvar_string("mapcyclefile", maps_ini_file, charsmax(maps_ini_file))
    if (loadSettings(maps_ini_file))
        set_task(15.0, "voteNextmap", VOTE_MAP_TASK, "", 0, "b")

    g_coloredMenus = colored_menus()
    bind_pcvar_num(get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : register_cvar("mp_chattime", "20"),g_mp_chattime)

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

    if(cstrike_running() || get_cvar_pointer("mp_teamplay"))
        register_event("TeamScore", "team_score", "a")
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
        new mapname[MAX_NAME_LENGTH]

        get_mapname(mapname, charsmax(mapname))
        new Float:steptime = get_pcvar_float(g_step) //get_cvar_float("amx_extendmap_step")
        set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + steptime)
        client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_EXT", steptime)
        log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %.0f minutes", mapname, steptime)

        return
    }

    new smap[MAX_NAME_LENGTH]
    if (g_voteCount[b] && g_voteCount[SELECTMAPS + 1] <= g_voteCount[b])
    {
        ArrayGetString(g_mapName, g_nextName[b], smap, charsmax(smap));
        set_cvar_string("amx_nextmap", smap);
    }

    get_cvar_string("amx_nextmap", smap, charsmax(smap))
    client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", smap)
    log_amx("Vote: Voting for the nextmap finished. The nextmap will be %s", smap)
}


#if AMXX_VERSION_NUM == 182
stock engine_changelevel(smap[MAX_NAME_LENGTH])
{
    server_cmd("changelevel %s", smap)
}
#endif

public countVote(id, key)
{
    if (get_cvar_float("amx_vote_answers"))
    {
        new name[MAX_NAME_LENGTH]
        get_user_name(id, name, charsmax(name))

        if (key == SELECTMAPS)
            client_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_EXT", name)
        else if (key < SELECTMAPS)
        {
            new map[MAX_NAME_LENGTH];
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
        amxclient_cmd(players[m],random_map_pick()) //hooks all with unknown command
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

    if (g_wins)
    {
        new c = g_wins - 2
        
        if ((c > g_teamScore[0]) && (c > g_teamScore[1]))
        {
            g_selected = false
            return
        }
    }
    else if (g_rnds)
    {
        if ((g_rnds - 2) > (g_teamScore[0] + g_teamScore[1]))
        {
            g_selected = false
            return
        }
    }
    else if (g_frags)
    {
        if ( g_frags_remaining > 3 && timeleft > 129 )
        {
            g_selected = false
            return
        }

    } else {

        if (timeleft < 1 || timeleft > 129)
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

    if ((g_wins + g_rnds) == 0 && (get_cvar_float("mp_timelimit") < get_pcvar_float(g_max)/*get_cvar_float("amx_extendmap_max")*/))
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

    new szText[MAX_NAME_LENGTH]
    new currentMap[MAX_NAME_LENGTH]

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
    new current_map[MAX_NAME_LENGTH]

    get_mapname(current_map, charsmax(current_map))
    set_localinfo("lastMap", current_map)

    ArrayDestroy(g_mapName)
}
