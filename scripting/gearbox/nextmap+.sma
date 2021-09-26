    // vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// NextMap Plugin
//

#include <amxmodx>
#include <amxmisc>
#include engine

// WARNING: If you comment this line make sure
// that in your mapcycle file maps don't repeat.
// However the same map in a row is still valid.
#define OBEY_MAPCYCLE
#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32
#define charsmin -1
#define ZERO_TIME "30"

new g_nextMap[MAX_NAME_LENGTH]
new g_mapCycle[MAX_NAME_LENGTH]
new g_pos
new g_currentMap[MAX_NAME_LENGTH]


// pcvars
new g_mp_friendlyfire, g_teamplay, g_map_ent
new g_mp_chattime, g_counter
new g_amx_nextmap, g_finale
new g_finale_msg[64]
new g_Szstring[MAX_NAME_LENGTH]
#if AMXX_VERSION_NUM != 182
new const CvarChatTimeDesc[]="Added by nextmap to include end game chat time."
#endif
public plugin_init()
{
    register_plugin("NextMap", AMXX_VERSION_STR, "AMXX Dev Team")
    register_dictionary("nextmap.txt")

    get_mapname(g_currentMap, charsmax(g_currentMap))

    register_event(ZERO_TIME, "changeMap", "a")

    register_clcmd("say nextmap", "sayNextMap", 0, "- displays nextmap")
    register_clcmd("say currentmap", "sayCurrentMap", 0, "- display current map")


    g_amx_nextmap = register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
    #if AMXX_VERSION_NUM == 182
    g_mp_chattime = register_cvar("mp_chattime", "10")
    #else
    bind_pcvar_num(get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : create_cvar("mp_chattime", "10" ,FCVAR_SERVER, CvarChatTimeDesc,.has_min = true, .min_val = 0, .has_max = true, .max_val = 105),g_mp_chattime)
    #endif
    if(get_cvar_pointer("mp_teamplay"))
    #if AMXX_VERSION_NUM == 182
    g_teamplay = get_cvar_pointer("mp_teamplay")
        #else
        bind_pcvar_num(get_cvar_pointer("mp_teamplay"), g_teamplay)
        #endif
    new szString[MAX_NAME_LENGTH+8], szString2[MAX_NAME_LENGTH], szString3[8]

    get_localinfo("lastmapcycle", szString, charsmax(szString))
    parse(szString, szString2, charsmax(szString2), szString3, charsmax(szString3))

    get_cvar_string("mapcyclefile", g_mapCycle, charsmax(g_mapCycle))

    if (!equal(g_mapCycle, szString2))
        g_pos = 0   // mapcyclefile has been changed - go from first
    else
        g_pos = str_to_num(szString3)

    readMapCycle(g_mapCycle, g_nextMap, charsmax(g_nextMap))
    set_pcvar_string(g_amx_nextmap, g_nextMap)
    formatex(szString, charsmax(szString), "%s %d", g_mapCycle, g_pos)  // save lastmapcycle settings
    set_localinfo("lastmapcycle", szString)

    if(get_cvar_num("mp_friendlyfire")) //pointer makes wack numbers appear in end chat timer
    {
        #if AMXX_VERSION_NUM == 182
        g_mp_friendlyfire = get_cvar_pointer("mp_friendlyfire")
        #else
        bind_pcvar_num(get_cvar_pointer("mp_friendlyfire"),g_mp_friendlyfire)
        #endif
        register_clcmd("say ff", "sayFFStatus", 0, "- display friendly fire status")
    }
    g_map_ent = find_ent_by_class(charsmin, "item_ctfbase")

    g_finale = register_cvar("amx_nextmap_finale", "3") /*0- no end game finale | 1-finale | 2-finale,tunes | 3-finale,tunes,gametitle*/
    if(cstrike_running())
        g_counter = get_cvar_pointer("mp_chattime")
    else
        g_counter = get_cvar_num("mp_chattime")

}

public sayNextMap(id)
if(is_user_connected(id))
{
    new name[MAX_NAME_LENGTH]
    get_pcvar_string(g_amx_nextmap,name,charsmax(name))

    client_print id, print_chat, "%L %s", LANG_PLAYER, "NEXT_MAP", name
}

public sayCurrentMap(id)
if(is_user_connected(id))
    client_print id, print_chat, "%L: %s", LANG_PLAYER, "PLAYED_MAP", g_currentMap

public sayFFStatus(id)
{
    if(g_teamplay || g_map_ent > charsmin)
        client_print 0, print_chat, "%L: %L", LANG_PLAYER, "FRIEND_FIRE", LANG_PLAYER, g_mp_friendlyfire ? "ON" : "OFF"
    else if(is_user_connected(id))
        client_print id, print_chat, "%L: %L", LANG_PLAYER, "FRIEND_FIRE", LANG_PLAYER, g_mp_friendlyfire ? "ON" : "OFF"
}
#if !defined engine_changelevel
stock engine_changelevel(smap[MAX_NAME_LENGTH]){server_cmd("changelevel %s", smap)}
#endif

public delayedChange()
{
    log_amx "Pushing map through"
    //engine_changelevel(g_Szstring)
    server_cmd("amx_map %s", g_Szstring)
}

public changeMap()
{
    get_pcvar_string(g_amx_nextmap,g_Szstring,charsmax(g_Szstring))
    
    g_counter = get_pcvar_num(g_mp_chattime)

    set_task(float(g_counter), "delayedChange", 0, g_Szstring, charsmax(g_Szstring))
    set_task(1.0,"@Show_Chat_time",MAX_PLAYERS,"", 0, "b")
    client_print 0,print_chat,"Chat Time: %i",g_counter
    client_print 0,print_console,"babble time is: %i",get_pcvar_num(g_mp_chattime)

    log_amx "Chat time"
    formatex(g_finale_msg,charsmax(g_finale_msg),"Next map is %s!",g_Szstring)
    //Some mods do  not have chat time so we make one. -SPiNX 2021

    //Amxx-Hammer multi-manager in essence
    set_task(0.1,"@finale")
    set_task(0.2,"@title")
    set_task(0.3,"@tunes")
}

@Show_Chat_time()
    client_print 0, print_console,"Chat time remaining %i seconds",--g_counter

new g_warning[] = "WARNING: Couldn't find a valid map or the file doesn't exist (file ^"%s^")"

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

#if defined OBEY_MAPCYCLE
readMapCycle(szFileName[], szNext[], iNext)
{
    new b, i = 0, iMaps = 0
    new szBuffer[MAX_NAME_LENGTH], szFirst[MAX_NAME_LENGTH]

    if (file_exists(szFileName))
    {
        while (read_file(szFileName, i++, szBuffer, charsmax(szBuffer), b))
        {
            if (!isalnum(szBuffer[0]) || !ValidMap(szBuffer)) continue

            if (!iMaps)
                copy(szFirst, charsmax(szFirst), szBuffer)

            if (++iMaps > g_pos)
            {
                copy(szNext, iNext, szBuffer)
                g_pos = iMaps
                return
            }
        }
    }

    if (!iMaps)
    {
        log_amx(g_warning, szFileName)
        copy(szNext, iNext, g_currentMap)
    }
    else
        copy(szNext, iNext, szFirst)
    g_pos = 1
}

#else

readMapCycle(szFileName[], szNext[], iNext)
{
    new b, i = 0, iMaps = 0
    new szBuffer[MAX_NAME_LENGTH], szFirst[MAX_NAME_LENGTH]

    new a = g_pos

    if (file_exists(szFileName))
    {
        while (read_file(szFileName, i++, szBuffer, charsmax(szBuffer), b))
        {
            if (!isalnum(szBuffer[0]) || !ValidMap(szBuffer)) continue

            if (!iMaps)
            {
                iMaps = 1
                copy(szFirst, charsmax(szFirst), szBuffer)
            }

            if (iMaps == 1)
            {
                if (equali(g_currentMap, szBuffer))
                {
                    if (a-- == 0)
                        iMaps = 2
                }
            } else {
                if (equali(g_currentMap, szBuffer))
                    ++g_pos
                else
                    g_pos = 0

                copy(szNext, iNext, szBuffer)
                return
            }
        }
    }

    if (!iMaps)
    {
        log_amx(g_warning, szFileName)
        copy(szNext, iNext, g_currentMap)
    }
    else
        copy(szNext, iNext, szFirst)

    g_pos = 0
}
#endif

@finale()
if(get_pcvar_num(g_finale))
{
    message_begin(MSG_BROADCAST,SVC_FINALE,{0,0,0},0);write_string(g_finale_msg);message_end()
}

@title()
if(get_pcvar_num(g_finale)>1)
{
    emessage_begin(MSG_BROADCAST,get_user_msgid("GameTitle"),{0,0,0},0)
    ewrite_byte(1)
    emessage_end()
}

@tunes()
if(get_pcvar_num(g_finale)>2)
{
    new iTrack = random_num(2,27) //1 is blank
    emessage_begin(MSG_BROADCAST, SVC_CDTRACK, _, 0 );
    ewrite_byte(iTrack);
    ewrite_byte(1);
    emessage_end();
}
