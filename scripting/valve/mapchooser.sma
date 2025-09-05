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
#include <fakemeta_util>

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

#define CAPTURE_INCREASE 5

new Array:g_mapName;
new g_mapNums
new Pcvar_captures;
new g_counter;
new bool:b_set_caps;
static bool:B_op4c_map;

new g_nextName[SELECTMAPS]
new g_voteCount[SELECTMAPS + 2]
new g_mapVoteNum
new g_teamScore[2]
new g_lastMap[MAX_PLAYERS]

static g_coloredMenus;
new bool:g_selected = false;
new bool:g_rtv = false;
static bool:bOF_run, bool:bHL_run, bool:bStrike, bool:bFreed;
new g_mp_chattime, g_auto_pick, g_hlds_logging[4], g_max, g_step, g_rnds, g_wins, g_frags, g_frags_remaining, g_timelim, g_votetime;
new g_checktime;

public plugin_init()
{
    register_plugin(PLUGIN, AMXX_VERSION_STR, AUTHOR)
    register_dictionary("mapchooser.txt")
    register_dictionary("common.txt")

    g_mapName=ArrayCreate(MAX_NAME_LENGTH);

    static MenuName[MAX_RESOURCE_PATH_LENGTH]

    format(MenuName, charsmax(MenuName), "%L", "en", "CHOOSE_NEXTM")
    register_menucmd(register_menuid(MenuName), (charsmin^(charsmin<<(SELECTMAPS+2))), "countVote")

    #if !defined create_cvar
    #define create_cvar register_cvar
    #endif

    static modname[MAX_PLAYERS];
    get_modname(modname, charsmax(modname))

    bStrike = equali(modname, "cstrike") || equali(modname, "czero") ? true : false
    bHL_run = equali(modname, "gearbox") || equali(modname, "valve") ? true : false
    bOF_run = equali(modname, "gearbox") ? true : false

    g_max       = create_cvar("amx_extendmap_max", "90")
    g_step      = create_cvar("amx_extendmap_step", "15")
    g_auto_pick = create_cvar("mapchooser_auto", "0")

    get_localinfo("lastMap", g_lastMap, charsmax(g_lastMap))
    set_localinfo("lastMap", "")

    static maps_ini_file[MAX_RESOURCE_PATH_LENGTH]
    get_configsdir(maps_ini_file, charsmax(maps_ini_file));
    format(maps_ini_file, charsmax(maps_ini_file), "%s/maps.ini", maps_ini_file);

    if (!file_exists(maps_ini_file))
        get_cvar_string("mapcyclefile", maps_ini_file, charsmax(maps_ini_file))
    if (loadSettings(maps_ini_file))
    {
        //make cvar
        g_checktime = register_cvar("mapvote_check_time", "5.0")
        //set_pcvar_float(g_checktime, bStrike ? 15.0 : 3.0); //good for frags bad for all else can make a double vote
        //set_task(get_pcvar_num(g_checktime)*1.0, "voteNextmap", VOTE_MAP_TASK, _, _, "b")
        //set_task(15.0, "voteNextmap", VOTE_MAP_TASK, _, _, "b")
        set_task(get_pcvar_float(g_checktime), "voteNextmap", VOTE_MAP_TASK, _, _, "b")
    }

#if AMXX_VERSION_NUM == 182
    g_mp_chattime       = get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : register_cvar("mp_chattime", "20")
    g_wins                     = get_cvar_pointer("mp_winlimit")
    g_rnds                     = get_cvar_pointer("mp_maxrounds")
    g_frags                     = get_cvar_pointer("mp_fraglimit")
    g_frags_remaining   = get_cvar_pointer("mp_fragsleft")
    g_timelim                 = get_cvar_pointer("mp_timelimit")
    g_votetime               = get_cvar_pointer("amx_vote_time")
    g_hlds_logging         = get_cvar_pointer("log")
#else
    g_coloredMenus = colored_menus()

    bind_pcvar_num(get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : register_cvar("mp_chattime", "20"), g_mp_chattime)

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
    if(get_cvar_pointer("log"))
        bind_pcvar_string(get_cvar_pointer("log"), g_hlds_logging, charsmax(g_hlds_logging))
    if(bStrike || get_cvar_pointer("mp_teamplay"))
        register_event("TeamScore", "team_score", "a")
#endif

    if ( bOF_run )
    {
        new info_detect = find_ent(MaxClients,"info_ctfdetect")

        B_op4c_map = info_detect ? true : false

        if(B_op4c_map)
        {
            if(equal(g_hlds_logging, "off"))
            {
                console_cmd 0, "log on"
                log_amx "Logging is required for Capture the Flag!"
            }
            fm_set_kvd(info_detect, "map_score_max", "0")
            log_amx "CAPTURE POINT MAP DETECTED!"
            register_logevent("@count", 3, "2=CapturedFlag")
            register_logevent("@count", 2, "1=CP1score")
            register_logevent("@count", 2, "1=op_score", "1=bm_score")
            register_logevent("@count", 2, "1=tc1_bmscore", "1=tc1_opscore", "1=tc2_bmscore", "1=tc2_opscore","1=tc3_bmscore", "1=tc3_opscore","1=tc4_bmscore", "1=tc4_opscore","1=tc5_bmscore", "1=tc5_opscore","1=tc6_bmscore", "1=tc6_opscore")
        }
        else
        {
            set_pcvar_num(Pcvar_captures, 0)
            set_cvar_num("mp_captures", 0)
            console_cmd 0, "amx_cvar mp_captures 0"
            log_amx "This is not a flag/capture point map"
        }

        g_counter = get_pcvar_num(Pcvar_captures)

    }

}

@rtv(id)
{
    static timeleft; timeleft = get_timeleft()
    ///Initial edit was due to HL gungame in 2023.
    if(is_user_connected(id))
    {
        log_amx "%s|%n called RTV.", PLUGIN, id

        g_rtv=true

        if(timeleft>120)
        {
            task_exists(VOTE_MAP_TASK) ? change_task(VOTE_MAP_TASK,1.0) : set_task(get_pcvar_num(g_checktime)*1.0, "voteNextmap", VOTE_MAP_TASK, _, _, "b")
        }
        else
        {
            client_print(id, print_chat, "Map pick already completed. Changing levels in %i seconds.", timeleft)
        }
    }
}

public checkVotes()
{
    new timeleft = get_timeleft();
    //server_print "%i time left", timeleft;

    new b = 0

    static iTrigger; iTrigger = bStrike ? 129 : g_mp_chattime + (g_votetime*3);

    for (new a = 0; a < g_mapVoteNum; ++a)
        if (g_voteCount[b] < g_voteCount[a])
            b = a

    //server_print "Trigger time %i", iTrigger
    if(g_voteCount[SELECTMAPS] > g_voteCount[b] &&
    g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+1])
    {
        static mapname[MAX_NAME_LENGTH]
        get_mapname(mapname, charsmax(mapname))

        static Float:steptime; steptime = get_pcvar_float(g_step)

        //Half-Life Frags
        if(!timeleft || timeleft - iTrigger > 60)
        {
            if(g_frags)
            {
                //server_print "Frags enabled"
                if(g_frags_remaining <= 3)
                {
                    //server_print "Few Frags left"
                    set_cvar_num("mp_fraglimit", g_frags + floatround(steptime))
                    client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_FRAG", g_frags)
                    //client_print 0, print_chat, "Incrementing frag limit to %i.", g_frags
                    log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to %i frags.", mapname, g_frags)
                    g_rtv=false
                    g_selected = false
                    return
                }
            }
            if(B_op4c_map)
            {
                server_print "Flag MAP"
                //FLAGMAP:
                if(Pcvar_captures && get_pcvar_num(Pcvar_captures) <=3)
                {///new from here
                    if(!B_op4c_map || !get_pcvar_num(Pcvar_captures))
                        return
                    log_amx"Setting capture points."
                    set_pcvar_num(Pcvar_captures, get_pcvar_num(Pcvar_captures) + CAPTURE_INCREASE)
                    ///Pcvar_captures = Pcvar_captures +5
                    g_counter += CAPTURE_INCREASE
                    client_print 0, print_chat, "Incrementing capture points to %i.", get_pcvar_num(Pcvar_captures)
                    log_amx("Vote:                   Voting for the nextmap finished. Map %s will be extended to %i captures.", mapname, CAPTURE_INCREASE) //get_pcvar_num(Pcvar_captures))
                    g_selected = false
                    g_rtv=false
                    return
                }
            }
        }
        else
        {
            log_amx"Setting ext time"
            set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + steptime)
            client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_EXT", steptime)
            log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %.0f minutes.", mapname, steptime)
            g_selected = false
            g_rtv=false
            return
        }
    }

    static smap[MAX_NAME_LENGTH]
    if (g_voteCount[b] && g_voteCount[SELECTMAPS + 1] <= g_voteCount[b])
    {
        ArrayGetString(g_mapName, g_nextName[b], smap, charsmax(smap));
        set_cvar_string("amx_nextmap", smap);
    }

    get_cvar_string("amx_nextmap", smap, charsmax(smap))
    client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", smap)
    log_amx("Vote: Voting for the nextmap finished. The nextmap will be %s.", smap)

    if(g_rtv)
    {
        remove_task(VOTE_MAP_TASK)
        if(g_mp_chattime < 2)
            g_mp_chattime = 5

        set_task(float(g_mp_chattime),"@changemap",VOTE_MAP_TASK,smap,charsmax(smap))
        if(is_plugin_loaded("spectate.amxx",true)!=charsmin)
        {
            @op4_spec()
        }
    }
}


@changemap(smap[MAX_NAME_LENGTH])
{
    server_print "Trying to change to map %s",smap
    if(ValidMap(smap))amxx_changelevel(smap)

}

@op4_spec()
{
    if(callfunc_begin("plugin_end","spectate.amxx"))
    {
        callfunc_end()
        log_amx "Checking for spectators."
    }
}

stock amxx_changelevel(smap[MAX_NAME_LENGTH])
{
    console_cmd(0,"changelevel %s", smap)
}

public countVote(id, key)
{
    if (get_cvar_float("amx_vote_answers"))
    {
        static name[MAX_NAME_LENGTH]
        get_user_name(id, name, charsmax(name))

        if (key == SELECTMAPS)
            client_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_EXT", name)
        else if (key < SELECTMAPS)
        {
            static map[MAX_NAME_LENGTH];
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
{
    log_amx "auto-picking maps"

    for (new m=1; m<=MaxClients; ++m)
    if(is_user_connected(m))
    {
        if(is_user_bot(m))
        {
            client_cmd(m,random_map_pick())

        }
        else if(is_user_admin(m) && !get_user_frags(m))
        {
            client_cmd(m,random_map_pick())
        }
    }
}

stock random_map_pick()
{
    static formated[MAX_NAME_LENGTH]
    //formatex(formated,charsmax(formated),"menuselect %i", _Random()) //humans
    formatex(formated,charsmax(formated),"slot%i", _Random())
    return formated;
}

stock _Random()
{
    return random_num(1,5)
}

public voteNextmap()
{
    static timeleft; timeleft = get_timeleft()

    static votetime, chatime
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
    static smap[MAX_NAME_LENGTH]
    static vote_menu_display; vote_menu_display = bStrike ? 129 : chatime + (votetime*2)
    
    change_task(VOTE_MAP_TASK, get_pcvar_num(g_checktime)*1.0)
    if(g_rtv)
    {
        change_task(VOTE_MAP_TASK, 30.0)
        goto AHEAD_LINE
    }
    
    if(!bStrike)
    {
        if(bOF_run)
        {
            #if AMXX_VERSION_NUM == 182
            if(g_frags && get_pcvar_num(g_frags_remaining))
            #else
            if(g_frags)
            #endif

            if(B_op4c_map)
            {
                set_cvar_num("mp_fraglimit", 0)
                log_amx("Set frags to 0 for mapchooser to function.")
                g_selected = false
                return
            }

            if(get_pcvar_num(Pcvar_captures) < 2)
            {
                remove_task(VOTE_MAP_TASK)
                log_amx"CTF point map change"

                B_op4c_map = false
                g_selected = true
                callfunc_begin("changeMap","nextmap.amxx")?callfunc_end():@changemap(smap)
                return
            }
        }
        if(bHL_run)
        {
            if(g_frags && g_frags_remaining == 1)
            {
                log_amx"HL server frag limit map change"
                callfunc_begin("changeMap","nextmap.amxx")?callfunc_end():@changemap(smap)
                remove_task(VOTE_MAP_TASK)
                return
            }
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
    else if(g_frags && get_pcvar_num(g_frags_remaining))
    {
        if ( get_pcvar_num(g_frags_remaining) > 5 && timeleft > (vote_menu_display + chatime + (votetime*2)) )

    #else
    else if (g_frags && g_frags_remaining )
    {
        if ( g_frags_remaining > 3 && timeleft > (vote_menu_display + chatime + (votetime*2)) )
    #endif
        {
            g_selected = false
            return
        }
    }
    else if(B_op4c_map)
    {
        if( get_pcvar_num(Pcvar_captures) > 3 && timeleft > (vote_menu_display + chatime + (votetime*2) ) )
        {
            g_selected = false
            return
        }

    }

    else
    {
        if ( !timeleft || timeleft > (vote_menu_display + chatime + (votetime*2)) )
        {
            g_selected = false
            return
        }
    }

    if(g_selected)
        return
    AHEAD_LINE:
    g_selected = true
    static menu[MAX_MENU_LENGTH], a, mkeys; mkeys = (1<<SELECTMAPS + 1)

    static pos; pos = format(menu, charsmax(menu), g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTM")
    static dmax; dmax = (g_mapNums > SELECTMAPS) ? SELECTMAPS : g_mapNums

    for (g_mapVoteNum = 0; g_mapVoteNum < dmax; ++g_mapVoteNum)
    {
        a = random_num(0, g_mapNums - 1)

        while (isInMenu(a))
            if (++a >= g_mapNums) a = 0

        g_nextName[g_mapVoteNum] = a
        pos += format(menu[pos], charsmax(menu) - pos, bHL_run ? "%d. %a^n^n" : "%d. %a^n", g_mapVoteNum + 1, ArrayGetStringHandle(g_mapName, a));
        mkeys |= (1<<g_mapVoteNum)
        g_voteCount[g_mapVoteNum] = 0
    }

    menu[pos++] = '^n'
    g_voteCount[SELECTMAPS] = 0
    g_voteCount[SELECTMAPS + 1] = 0

    static mapname[MAX_NAME_LENGTH]
    get_mapname(mapname, charsmax(mapname))

    if ((g_wins + g_rnds) == 0 && (get_cvar_float("mp_timelimit") < get_pcvar_float(g_max)) || g_frags && g_frags < get_pcvar_float(g_max))
    {
        pos += format(menu[pos], charsmax(menu) - pos, bHL_run ? "%d. %L^n^n" : "%d. %L^n", SELECTMAPS + 1, LANG_SERVER, "EXTED_MAP", mapname)
        mkeys |= (1<<SELECTMAPS)
    }

    format(menu[pos], charsmax(menu), "%d. %L", SELECTMAPS+2, LANG_SERVER, "NONE")
    static MenuName[MAX_RESOURCE_PATH_LENGTH]

    format(MenuName, charsmax(MenuName), "%L", "en", "CHOOSE_NEXTM")
    show_menu(0, mkeys, menu, 15, MenuName)
    set_task(float(g_votetime), "checkVotes")
    //AUTOPICK MAPS FOR DEBUGGING ETC

    static auto; auto = get_pcvar_num(g_auto_pick)

    if(auto == 1)
    {
        set_task(2.0,"@auto_map_pick")
    }
    else if(auto>1)
    {
        static iFun;iFun = random(1)
        if(iFun)
        {
            set_task(2.0,"@auto_map_pick")
        }
    }

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
    static len; len = strlen(mapname) - 4;

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

    static szText[MAX_NAME_LENGTH]
    static currentMap[MAX_NAME_LENGTH]

    static buff[MAX_USER_INFO_LENGTH];

    get_mapname(currentMap, charsmax(currentMap))

    static fp; fp=fopen(filename,"r");

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
    static team[2]

    read_data(1, team, charsmax(team))
    g_teamScore[(team[0]=='C') ? 0 : 1] = read_data(2)
}

public client_putinserver(id)
{
    if(!bFreed)
    if(g_selected && get_timeleft()>240)
    {
        #if AMXX_VERSION_NUM == 182
        if(bStrike || bHL_run && get_cvar_num("mp_fragsleft")>3)
        #else
        if(bStrike || bHL_run && g_frags_remaining>3)
        #endif
        {
            g_selected = false
            log_amx("Freeing up system to vote again.")
            bFreed = true
        }
    }
}

public plugin_end()
{
    static current_map[MAX_NAME_LENGTH]

    get_mapname(current_map, charsmax(current_map))
    set_localinfo("lastMap", current_map)

    ArrayDestroy(g_mapName)
    pause("a")
}

public pfn_keyvalue( ent )
{
    if (is_running("gearbox") == 1 && !b_set_caps)
    {
        static Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]

        copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

        if(equali(Classname,"info_ctfdetect") && equali(key,"map_score_max"))
        {
            set_cvar_num("mp_captures", str_to_num(value))
            DispatchKeyValue("map_score_max", "0")
        }
        Pcvar_captures = get_cvar_pointer("mp_captures") ? get_cvar_pointer("mp_captures") : register_cvar("mp_captures", "5")
        b_set_caps = true
    }
}

@count()
{
    g_counter--
    set_cvar_num("mp_captures", g_counter)
    server_print "[AMX]FLAG CAPTURED^n%i to go!", g_counter
    client_print 0, print_chat, "[AMX]FLAG CAPTURED^n%i to go!", g_counter
}
