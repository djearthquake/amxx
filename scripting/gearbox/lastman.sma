#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <fakemeta>

#define PLUGIN "Last Man Standing Op4"
#define VERSION "0.2"
#define AUTHOR "SPiNX"

#define TASK_STATUS 888
#define TASK_BEAMS 555
#define WINNERS_FILE "lms_winners.txt"

public g_bLmsActive = 0;
new bool:g_bHasDied[33];
new g_iPlayerHud[33];
new g_iVotesYes, g_iVotesNo, g_iRoundTime, g_sModelIndexBeam;
new bool:g_bDuelStarted = false;

// --- OPFOR HELPER: BOTS ARE PLAYERS, SPECS ARE NOT ---
stock bool:is_user_participant(id)
{
    if (!is_user_connected(id) || is_user_hltv(id)) return false;

    // Skip anyone with the Engine Spectator Flag (God-Tier Spec)
    if (pev(id, pev_flags) & FL_SPECTATOR) return false;

    return true;
}

public plugin_precache()
{
    g_sModelIndexBeam = precache_model("sprites/laserbeam.spr");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Pre", 0);

    register_clcmd("say /winners", "cmd_ShowWinners", ADMIN_ALL, "- Displays the LMS Hall of Fame");
    register_clcmd("say /vote_lms", "cmd_CallVote", ADMIN_ALL, "- Starts a vote to enable LMS mode");
    register_clcmd("say /lms", "cmd_LmsMenu", ADMIN_ALL, "- Opens the LMS configuration menu");

    set_task(1.0, "task_DisplayStatus", TASK_STATUS, _, _, "b");
}

public client_putinserver(id)
{
    g_iPlayerHud[id] = 1;
    g_bHasDied[id] = false;
}

public task_DisplayStatus()
{
    if (!g_bLmsActive) return;

    g_iRoundTime++;

    static szAlive[512], szDead[512], szName[32];
    new iPlayers[32], iNum, id, iTarget, iAliveCount = 0;
    szAlive[0] = 0; szDead[0] = 0;

    // Flag "h" = include bots. No "c" flag used here.
    get_players(iPlayers, iNum, "h");
    for (new i = 0; i < iNum; i++)
    {
        iTarget = iPlayers[i];

        if (!is_user_participant(iTarget)) continue;

        get_user_name(iTarget, szName, charsmax(szName));
        if (is_user_alive(iTarget))
        {
            iAliveCount++;
            add(szAlive, charsmax(szAlive), szName); add(szAlive, charsmax(szAlive), "^n");
        }
        else
        {
            add(szDead, charsmax(szDead), szName); add(szDead, charsmax(szDead), "^n");
        }
    }

    for (new i = 0; i < iNum; i++)
    {
        id = iPlayers[i];
        if (is_user_bot(id) || !is_user_participant(id)) continue;

        if (g_iPlayerHud[id])
        {
            set_hudmessage(0, 255, 0, 0.75, 0.15, 0, 0.0, 1.1, 0.1, 0.1, 1);
            show_hudmessage(id, "LMS ROUND [%d:%02d]^n^nALIVE:^n%s", g_iRoundTime / 60, g_iRoundTime % 60, szAlive);

            set_hudmessage(255, 50, 50, 0.75, 0.60, 0, 0.0, 1.1, 0.1, 0.1, 2);
            show_hudmessage(id, "DEAD:^n%s", szDead);
        }
        else
        {
            client_print(id, print_center, "LMS ACTIVE | Time: %d:%02d | Survivors: %d", g_iRoundTime / 60, g_iRoundTime % 60, iAliveCount);
        }
    }
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
    if (g_bLmsActive && is_user_participant(victim))
    {
        g_bHasDied[victim] = true;
        check_last_man();
    }
}

public check_last_man()
{
    new iPlayers[32], iNum, iAlive[32], iAliveCount = 0;

    // Flag "a" includes alive bots
    get_players(iPlayers, iNum, "a");

    for(new i = 0; i < iNum; i++)
    {
        if(is_user_participant(iPlayers[i]))
        {
            iAlive[iAliveCount] = iPlayers[i];
            iAliveCount++;
        }
    }

    if (iAliveCount == 2 && !g_bDuelStarted)
    {
        g_bDuelStarted = true;
        set_task(0.1, "task_ShowBeams", TASK_BEAMS, _, _, "b");
        client_print(0, print_center, "FINAL SHOWDOWN!");
    }

    if (iAliveCount == 1) declare_winner(iAlive[0]);
    else if (iAliveCount == 0 && g_bLmsActive) force_lms_end();
}

public declare_winner(id)
{
    new szName[32], szMap[32], szTime[32], szPath[128], szLog[256];
    get_user_name(id, szName, charsmax(szName));
    get_mapname(szMap, charsmax(szMap));
    get_time("%Y-%m-%d %H:%M", szTime, charsmax(szTime));

    get_configsdir(szPath, charsmax(szPath));
    formatex(szPath, charsmax(szPath), "%s/%s", szPath, WINNERS_FILE);

    formatex(szLog, charsmax(szLog), "[%s] %s won on %s", szTime, szName, szMap);
    write_file(szPath, szLog);

    client_print(0, print_chat, "[LMS] %s IS THE LAST MAN STANDING!", szName);
    force_lms_end();
}

public force_lms_end()
{
    remove_task(TASK_BEAMS);
    g_bLmsActive = 0;
    g_bDuelStarted = false;
    g_iRoundTime = 0;

    new iPlayers[32], iNum;
    get_players(iPlayers, iNum);
    for (new i = 0; i < iNum; i++) g_bHasDied[iPlayers[i]] = false;

    server_cmd("sv_restart 1");
}

public fw_PlayerSpawn_Pre(id)
{
    if (g_bLmsActive && is_user_participant(id) && g_bHasDied[id]) return HAM_SUPERCEDE;
    g_bHasDied[id] = false;
    return HAM_IGNORED;
}

public task_ShowBeams()
{
    if (!g_bLmsActive) return;

    new iPlayers[32], iNum, iAlive[2], iAliveCount = 0;
    get_players(iPlayers, iNum, "a");

    for(new i = 0; i < iNum; i++)
    {
        if(is_user_participant(iPlayers[i]))
        {
            if(iAliveCount < 2) iAlive[iAliveCount] = iPlayers[i];
            iAliveCount++;
        }
    }

    if (iAliveCount == 2)
    {
        new Float:v1[3], Float:v2[3];
        pev(iAlive[0], pev_origin, v1);
        pev(iAlive[1], pev_origin, v2);

        new Float:fDist = get_distance_f(v1, v2);
        new r, g, b;

        if (fDist > 1000.0) { r = 255; g = 0; b = 0; }
        else if (fDist > 350.0) { r = 255; g = 255; b = 0; }
        else { r = 0; g = 255; b = 0; }

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMPOINTS);
        engfunc(EngFunc_WriteCoord, v1[0]); engfunc(EngFunc_WriteCoord, v1[1]); engfunc(EngFunc_WriteCoord, v1[2] + 36.0);
        engfunc(EngFunc_WriteCoord, v2[0]); engfunc(EngFunc_WriteCoord, v2[1]); engfunc(EngFunc_WriteCoord, v2[2] + 36.0);
        write_short(g_sModelIndexBeam);
        write_byte(0); write_byte(0); write_byte(1); write_byte(20); write_byte(0);
        write_byte(r); write_byte(g); write_byte(b); write_byte(150); write_byte(0);
        message_end();
    }
}

public cmd_CallVote(id)
{
    if (g_bLmsActive) return PLUGIN_HANDLED;
    new menu = menu_create("\yStart Last Man Standing?", "menu_VoteHandler");
    menu_additem(menu, "Yes", "1"); menu_additem(menu, "No", "2");
    g_iVotesYes = 0; g_iVotesNo = 0;

    new iPlayers[32], iNum; get_players(iPlayers, iNum, "h");
    for (new i = 0; i < iNum; i++)
    {
        if (is_user_participant(iPlayers[i]) && !is_user_bot(iPlayers[i]))
            menu_display(iPlayers[i], menu, 0);
    }
    set_task(10.0, "task_FinishVote");
    return PLUGIN_HANDLED;
}

public menu_VoteHandler(id, menu, item)
{
    if (item == MENU_EXIT) return PLUGIN_HANDLED;
    (item == 0) ? g_iVotesYes++ : g_iVotesNo++;
    return PLUGIN_HANDLED;
}

public task_FinishVote()
{
    if (g_iVotesYes > g_iVotesNo)
    {
        g_bLmsActive = 1;
        server_cmd("sv_restart 3");
    }
}

public cmd_LmsMenu(id)
{
    new menu = menu_create("\r[!OpFor] \yLMS Settings^n", "menu_ConfigHandler");
    new szHudLabel[64];
    formatex(szHudLabel, charsmax(szHudLabel), "HUD Style: \w[%s]", (g_iPlayerHud[id]) ? "\yFull HUD" : "\rCenter Only");
    menu_additem(menu, szHudLabel, "1");
    menu_additem(menu, "View Hall of Fame", "2");
    menu_additem(menu, "\wStart Vote", "3");
    menu_display(id, menu, 0);
    return PLUGIN_HANDLED;
}

public menu_ConfigHandler(id, menu, item)
{
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    switch(item)
    {
        case 0: { g_iPlayerHud[id] = 1 - g_iPlayerHud[id]; cmd_LmsMenu(id); }
        case 1: cmd_ShowWinners(id);
        case 2: cmd_CallVote(id);
    }
    return PLUGIN_HANDLED;
}

public cmd_ShowWinners(id)
{
    new szPath[128];
    get_configsdir(szPath, charsmax(szPath));
    formatex(szPath, charsmax(szPath), "%s/%s", szPath, WINNERS_FILE);
    if (file_exists(szPath)) show_motd(id, szPath, "LMS Hall of Fame");
    return PLUGIN_HANDLED;
}
