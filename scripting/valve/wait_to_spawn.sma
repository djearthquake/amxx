#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Op4 Wait to Spawn Core"
#define VERSION "0.1"
#define AUTHOR  "SPiNX"

#define TASK_COUNTDOWN 3000

new g_pWaitTime;
new g_iSecondsLeft[33];
new bool:g_bBlockSpawn[33];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pWaitTime = register_cvar("respawn_wait_time", "10.0");

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Pre", 0);
}

public fw_PlayerKilled_Post(id)
{
    if (!is_user_connected(id))
    {
        return HAM_IGNORED;
    }

    // Check if player is a spectator using entity flags (FL_SPECTATOR = 1<<3)
    if (pev(id, pev_flags) & FL_SPECTATOR)
    {
        return HAM_IGNORED;
    }

    g_iSecondsLeft[id] = get_pcvar_num(g_pWaitTime);
    g_bBlockSpawn[id] = true;

    set_task(1.0, "task_Countdown", id + TASK_COUNTDOWN, _, _, "a", g_iSecondsLeft[id]);

    return HAM_HANDLED;
}

public fw_PlayerSpawn_Pre(id)
{
    if (is_user_connected(id) && g_bBlockSpawn[id])
    {
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public task_Countdown(id)
{
    id -= TASK_COUNTDOWN;

    if (!is_user_connected(id))
    {
        return;
    }

    g_iSecondsLeft[id]--;

    if (g_iSecondsLeft[id] > 0)
    {
        set_hudmessage(200, 200, 200, -1.0, 0.8, 0, 0.0, 1.1, 0.0, 0.0);
        show_hudmessage(id, "Respawning in %d seconds...", g_iSecondsLeft[id]);
    }
    else
    {
        g_bBlockSpawn[id] = false;

        if (!is_user_alive(id) && !(pev(id, pev_flags) & FL_SPECTATOR))
        {
            ExecuteHamB(Ham_Spawn, id);
        }
    }
}

public client_disconnected(id)
{
    g_bBlockSpawn[id] = false;

    if (task_exists(id + TASK_COUNTDOWN))
    {
        remove_task(id + TASK_COUNTDOWN);
    }
}
