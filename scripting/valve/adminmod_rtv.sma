/***********************************************************************************
* Adminmod Style RTV Plugin
* Fixed Version with Map Validation Checking on Chat Entry
***********************************************************************************/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Adminmod Style RTV"
#define VERSION "0.3"
#define AUTHOR "SPiNX"

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif

#define VOTE_RATIO 0.51
#define IMMUNITY_TIME 180.0
#define NOMINATION_TIME 60
#define MAX_MAP_LEN 32

new bool:g_HasRTVed[MAX_PLAYERS + 1]
new g_RTVCount = 0
new Float:g_MapStartTime

public bool:g_NominationActive = false
new g_NominationTimeLeft
new g_PlayerNomination[MAX_PLAYERS + 1][MAX_MAP_LEN]

new g_HudSyncObj
new bool:g_IsCS

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_clcmd("say rockthevote", "HandleRTV")
    register_clcmd("say rtv", "HandleRTV")
    register_clcmd("say /rtv", "HandleRTV")

    register_clcmd("say", "HookPlayerChat")

    g_HudSyncObj = CreateHudSyncObj()
    g_MapStartTime = get_gametime()

    static modName[MAX_MAP_LEN]
    get_modname(modName, charsmax(modName))
    if (equal(modName, "cstrike") || equal(modName, "czero"))
    {
        g_IsCS = true
    }
    else
    {
        g_IsCS = false
    }
}

public client_connect(id)
{
    g_HasRTVed[id] = false
    g_PlayerNomination[id][0] = '^0'
}

public client_disconnected(id, bool:destroied, reason[], code)
{
    if (g_HasRTVed[id])
    {
        g_RTVCount--
        g_HasRTVed[id] = false
        if (!g_NominationActive)
        {
            CheckRTVThreshold()
        }
    }
    g_PlayerNomination[id][0] = '^0'
}

PrintChat(id, const message[], any:...)
{
    new buffer[192]
    vformat(buffer, charsmax(buffer), message, 3)

    if (g_IsCS)
    {
        client_print_color(id, print_team_default, buffer)
    }
    else
    {
        replace_all(buffer, charsmax(buffer), "^1", "")
        replace_all(buffer, charsmax(buffer), "^3", "")
        replace_all(buffer, charsmax(buffer), "^4", "")
        client_print(id, print_chat, buffer)
    }
}

public HandleRTV(id)
{
    if (g_NominationActive)
    {
        PrintChat(id, "^4[RTV]^1 Map nomination is already running! Type a map name in chat.")
        return PLUGIN_HANDLED
    }

    new Float:currentTime = get_gametime()
    if (currentTime - g_MapStartTime < IMMUNITY_TIME)
    {
        new remaining = floatround(IMMUNITY_TIME - (currentTime - g_MapStartTime))
        PrintChat(id, "^4[RTV]^1 Too early. Wait^3 %d ^1more seconds.", remaining)
        return PLUGIN_HANDLED
    }

    if (g_HasRTVed[id])
    {
        PrintChat(id, "^4[RTV]^1 You have already rocked the vote.")
        return PLUGIN_HANDLED
    }

    g_HasRTVed[id] = true
    g_RTVCount++

    CheckRTVThreshold()
    return PLUGIN_HANDLED
}

CheckRTVThreshold()
{
    new numPlayers = get_playersnum()
    if (numPlayers == 0)
    {
        return
    }

    new required = floatround(float(numPlayers) * VOTE_RATIO, floatround_ceil)

    if (g_RTVCount >= required)
    {
        StartNominationWindow()
    }
    else
    {
        PrintChat(0, "^4[RTV]^1 Progress:^3 %d/%d ^1votes needed to rock the vote.", g_RTVCount, required)
    }
}

StartNominationWindow()
{
    g_NominationActive = true
    g_NominationTimeLeft = NOMINATION_TIME

    // ADD THIS LINE HERE: Notifies the bot think plugin instantly
    server_cmd("amx_rtv_active 1") 

    new maxPlayers = get_maxplayers()
    for (new i = 1; i <= maxPlayers; i++)
    {
        g_PlayerNomination[i][0] = '^0'
    }

    PrintChat(0, "^4[RTV]^1 Rock The Vote succeeded!")
    PrintChat(0, "^4[RTV]^1 Everyone has^3 60 seconds^1 to type a valid map name in chat!")

    set_task(1.0, "NominationCountdown", 999, _, _, "b")
}

public NominationCountdown()
{
    g_NominationTimeLeft--

    if (g_NominationTimeLeft <= 0)
    {
        remove_task(999)
        ClearSyncHud(0, g_HudSyncObj)
        ProcessWinningMap()
        return
    }

    if (g_NominationTimeLeft % 15 == 0 || g_NominationTimeLeft <= 5)
    {
        PrintChat(0, "^4[RTV]^3 %d ^1seconds left to type your map choice in chat!", g_NominationTimeLeft)
    }

    UpdateVoteHud()
}

public HookPlayerChat(id)
{
    if (!g_NominationActive)
    {
        return PLUGIN_CONTINUE
    }

    new speech[MAX_MAP_LEN]
    read_args(speech, charsmax(speech))
    remove_quotes(speech)
    trim(speech)

    if (speech[0] == '/' || equali(speech, "rtv") || equali(speech, "rockthevote"))
    {
        return PLUGIN_CONTINUE
    }

    // --- CORE FIX: PRE-VALIDATE MAP STRING VIA SERVER MAPS DIRECTORY ---
    if (!is_map_valid(speech))
    {
        PrintChat(id, "^4[RTV]^1 Chat text '^3%s^1' is not a valid server map! Try again.", speech)
        return PLUGIN_CONTINUE
    }

    // Explicit matrix assignment bounds fix
    copy(g_PlayerNomination[id], MAX_MAP_LEN - 1, speech)
    PrintChat(id, "^4[RTV]^1 Registered your map nomination:^3 %s", speech)

    return PLUGIN_CONTINUE
}

UpdateVoteHud()
{
    new maxPlayers = get_maxplayers()
    new uniqueMaps[MAX_PLAYERS][MAX_MAP_LEN]
    new mapVotes[MAX_PLAYERS]
    new uniqueCount = 0

    for (new i = 1; i <= maxPlayers; i++)
    {
        if (!is_user_connected(i) || g_PlayerNomination[i][0] == '^0')
        {
            continue
        }

        new foundIndex = -1
        for (new j = 0; j < uniqueCount; j++)
        {
            if (equali(g_PlayerNomination[i], uniqueMaps[j]))
            {
                foundIndex = j
                break
            }
        }

        if (foundIndex != -1)
        {
            mapVotes[foundIndex]++
        }
        else if (uniqueCount < MAX_PLAYERS)
        {
            copy(uniqueMaps[uniqueCount], MAX_MAP_LEN - 1, g_PlayerNomination[i])
            mapVotes[uniqueCount] = 1
            uniqueCount++
        }
    }

    new hudBuffer[512]
    formatex(hudBuffer, charsmax(hudBuffer), "=== ROCK THE VOTE (%ds Left) ===^n^n", g_NominationTimeLeft)

    if (uniqueCount == 0)
    {
        add(hudBuffer, charsmax(hudBuffer), "Type a map name in chat to nominate!")
    }
    else
    {
        new tempVotes
        new tempMap[MAX_MAP_LEN]

        for (new i = 0; i < uniqueCount - 1; i++)
        {
            for (new j = i + 1; j < uniqueCount; j++)
            {
                if (mapVotes[i] < mapVotes[j])
                {
                    tempVotes = mapVotes[i]
                    mapVotes[i] = mapVotes[j]
                    mapVotes[j] = tempVotes

                    copy(tempMap, MAX_MAP_LEN - 1, uniqueMaps[i])
                    copy(uniqueMaps[i], MAX_MAP_LEN - 1, uniqueMaps[j])
                    copy(uniqueMaps[j], MAX_MAP_LEN - 1, tempMap)
                }
            }
        }

        new line[64]
        formatex(line, charsmax(line), "LEADING: %s (%d vote%s)^n^nRUNNERS-UP:^n", uniqueMaps[0], mapVotes[0], (mapVotes[0] == 1) ? "" : "s")
        add(hudBuffer, charsmax(hudBuffer), line)

        for (new i = 1; i < uniqueCount && i < 5; i++)
        {
            formatex(line, charsmax(line), "- %s (%d vote%s)^n", uniqueMaps[i], mapVotes[i], (mapVotes[i] == 1) ? "" : "s")
            add(hudBuffer, charsmax(hudBuffer), line)
        }
    }

    set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 0.0, 1.1, 0.0, 0.0, -1)
    ShowSyncHudMsg(0, g_HudSyncObj, "%s", hudBuffer)
}

ProcessWinningMap()
{
    g_NominationActive = false

    new maxPlayers = get_maxplayers()
    new uniqueMaps[MAX_PLAYERS][MAX_MAP_LEN]
    new mapVotes[MAX_PLAYERS]
    new uniqueCount = 0

    for (new i = 1; i <= maxPlayers; i++)
    {
        if (!is_user_connected(i) || g_PlayerNomination[i][0] == '^0')
        {
            continue
        }

        new foundIndex = -1
        for (new j = 0; j < uniqueCount; j++)
        {
            if (equali(g_PlayerNomination[i], uniqueMaps[j]))
            {
                foundIndex = j
                break
            }
        }

        if (foundIndex != -1)
        {
            mapVotes[foundIndex]++
        }
        else if (uniqueCount < MAX_PLAYERS)
        {
            copy(uniqueMaps[uniqueCount], MAX_MAP_LEN - 1, g_PlayerNomination[i])
            mapVotes[uniqueCount] = 1
            uniqueCount++
        }
    }

    if (uniqueCount == 0)
    {
        PrintChat(0, "^4[RTV]^1 No maps were nominated. Map cycle continues normally.")
        return
    }

    new maxVotes = 0
    new winningIndex = 0
    for (new i = 0; i < uniqueCount; i++)
    {
        if (mapVotes[i] > maxVotes)
        {
            maxVotes = mapVotes[i]
            winningIndex = i
        }
    }

    new winningMap[MAX_MAP_LEN]
    copy(winningMap, MAX_MAP_LEN - 1, uniqueMaps[winningIndex])

    PrintChat(0, "^4[RTV]^1 Nomination over! The winner is^4 %s ^1with^3 %d ^1nominations.", winningMap, maxVotes)
    PrintChat(0, "^4[RTV]^1 Changing map now...")

    set_task(3.0, "DelayedChangeMap", 0, winningMap, MAX_MAP_LEN - 1)
}

public DelayedChangeMap(winningMap[])
{
    server_cmd("changelevel %s", winningMap)
}
