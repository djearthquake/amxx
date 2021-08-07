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

// WARNING: If you comment this line make sure
// that in your mapcycle file maps don't repeat.
// However the same map in a row is still valid.
#define OBEY_MAPCYCLE
#define PLUGIN "NextMap+"
#define MAX_NAME_LENGTH 32

new g_nextMap[MAX_NAME_LENGTH]
new g_mapCycle[MAX_NAME_LENGTH]
new g_pos
new g_currentMap[MAX_NAME_LENGTH]

// pcvars
new g_mp_friendlyfire, g_mp_chattime
new g_amx_nextmap, g_teamplay, g_finale

public plugin_init()
{
    register_plugin(PLUGIN, AMXX_VERSION_STR, "SPiNX|AMXX Dev Team")
    register_dictionary("nextmap.txt")
    register_event("30", "changeMap", "a")
    register_clcmd("say nextmap", "sayNextMap", 0, "- displays nextmap")
    register_clcmd("say currentmap", "sayCurrentMap", 0, "- display current map")

    g_amx_nextmap = register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
    g_finale = register_cvar("amx_nextmap_finale", "3") /*0- no end game finale | 1-finale | 2-finale,tunes | 3-finale,tunes,gametitle*/

    g_mp_chattime = get_cvar_pointer("mp_chattime") ? get_cvar_pointer("mp_chattime") : register_cvar("mp_chattime", "20")

    g_mp_friendlyfire = get_cvar_pointer("mp_friendlyfire")
    g_teamplay = get_cvar_pointer("mp_teamplay")

    register_clcmd("say ff", "sayFFStatus", 0, "- display friendly fire status")

    get_mapname(g_currentMap, charsmax(g_currentMap))

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
}

getNextMapName(szArg[], iMax)
{
    new len = get_pcvar_string(g_amx_nextmap, szArg, iMax)

    if (ValidMap(szArg)) return len
    len = copy(szArg, iMax, g_nextMap)
    set_pcvar_string(g_amx_nextmap, g_nextMap)

    return len
}

public sayNextMap()
{
    new name[MAX_NAME_LENGTH]

    getNextMapName(name, charsmax(name))
    client_print(0, print_chat, "%L %s", LANG_PLAYER, "NEXT_MAP", name)
}

public sayCurrentMap()
    client_print(0, print_chat, "%L: %s", LANG_PLAYER, "PLAYED_MAP", g_currentMap)

public sayFFStatus()
    if (cstrike_running() || !cstrike_running() && get_pcvar_num(g_teamplay))
        client_print(0, print_chat, "%L: %L", LANG_PLAYER, "FRIEND_FIRE", LANG_PLAYER, get_pcvar_num(g_mp_friendlyfire) ? "ON" : "OFF")

public delayedChange(Szstring[MAX_NAME_LENGTH])
{

    if (g_mp_chattime)
    {
        server_print "%s adj chattime",PLUGIN
        set_pcvar_float(g_mp_chattime, get_pcvar_float(g_mp_chattime) - 2.0)
    }
    server_print "%s delayed map change",PLUGIN
    engine_changelevel(Szstring)
}

@changemap(smap[MAX_NAME_LENGTH])
{
    server_print "Trying to change to map %s",smap
    engine_changelevel(smap)
}

#if AMXX_VERSION_NUM == 182
stock engine_changelevel(smap[32])
{
    server_cmd("changelevel %s", smap)
}
#endif

public changeMap()
{
    new time_left = get_timeleft()
    log_amx "Event 30 ClanTimer called with %i sec remaining.",time_left
    new Szstring[MAX_NAME_LENGTH]
    new Float:chattime = g_mp_chattime ? get_pcvar_float(g_mp_chattime) : 10.0; // mp_chattime defaults to 10 in other mods

    if (g_mp_chattime)
        set_pcvar_float(g_mp_chattime, chattime + 2.0)      // make sure mp_chattime is long

    get_pcvar_string(g_amx_nextmap,Szstring,charsmax(Szstring))
    server_print "%s",Szstring
    new Float:djleyedtask = floatclamp(chattime,1.0,122.0)
    server_print "%s starting to make new task for %f",PLUGIN,djleyedtask
    set_task(djleyedtask, "delayedChange", 0, Szstring, charsmax(Szstring)) //Over 2min6-7sec regular 'unannounced' mapcycle instead of vote would be next map
    new finale[128]
    formatex(finale,charsmax(finale),"Next map is %s!",Szstring)
    //Some mods do not have chat time so we make one. -SPiNX 2021
    @finale(finale) //Pins players down for a true mp_chattime
    @title()
    @tunes()
    
}

@finale(finale[128])
if(get_pcvar_num(g_finale))
{
    message_begin(MSG_BROADCAST,SVC_FINALE,{0,0,0},0);write_string(finale);message_end()
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
