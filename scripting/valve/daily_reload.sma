#include <amxmodx>

#define PLUGIN  "Proactive Reload"
#define VERSION "3.7"
#define AUTHOR  "SPiNX"

#define BOOT_MIN    25
#define BOOT_SEC    40
#define TASK_ID     120422

static g_pCvarTimes, g_pCvarExitMode

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    g_pCvarTimes    = register_cvar("reboot_times", "3, 9, 13, 23")
    g_pCvarExitMode = register_cvar("reboot_exit_mode", "1")

    set_task(30.0, "check_time", TASK_ID, .flags="b")
}

public check_time()
{
    static hour, min, sec, day, month, year, i, iCount, bool:bMatch
    static szCfg[128], szHours[12][4], szWkDay[2]

    time(hour, min, sec); date(year, month, day); get_time("%w", szWkDay, charsmax(szWkDay))
    get_pcvar_string(g_pCvarTimes, szCfg, charsmax(szCfg))

    iCount = explode_string(szCfg, ",", szHours, 12, 3); bMatch = false

    for (i = 0; i < iCount; i++)
    {
        trim(szHours[i])
        if (str_to_num(szHours[i]) == hour)
        {
            bMatch = true
            break
        }
    }

    if (!bMatch)
    {
        change_task(TASK_ID, 30.0)
        return
    }

    if (min == BOOT_MIN && get_playersnum(1) < 2)
    {
        change_task(TASK_ID, 1.0)

        static iMode, bool:bExit
        iMode = get_pcvar_num(g_pCvarExitMode)
        bExit = (iMode == 1 && szWkDay[0] == '1') || (iMode == 2 && day == 1)

        if (sec == BOOT_SEC)
        {
            if (bExit)
            {
                log_amx("[%s] Scheduled FULL EXIT triggered.", PLUGIN)
                server_cmd("exit")
            }
            else
            {
                log_amx("[%s] Scheduled RELOAD triggered.", PLUGIN)
                server_cmd("reload")
            }
            return
        }

        if (sec < BOOT_SEC)
        {
            client_print(0, print_center, "[ %s ]^nRefresh in %d seconds", (bExit ? "FULL RESTART" : "RELOAD"), (BOOT_SEC - sec))
            client_cmd(0, "spk UI/buttonrollover.wav")
        }
    }
    else
    {
        change_task(TASK_ID, 30.0)
    }
}
