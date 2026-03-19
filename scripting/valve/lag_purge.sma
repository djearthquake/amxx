#include <amxmodx>

#define MAX_WARNINGS 3
#define CHECK_INTERVAL 5.0
#define LOSS_THRESHOLD 5
#define PING_THRESHOLD 250
#define IMMUNITY_FLAG ADMIN_IMMUNITY

new g_iWarnings[MAX_PLAYERS + 1]
new bool:g_bImmune[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin("Lag Purge", "0.0.7", "SPINX")
    register_clcmd("say lag", "check_lag")
    set_task(CHECK_INTERVAL, "check_lag", 2024, _, _, "b")
}

public client_putinserver(id)
{
    g_iWarnings[id] = 0
    g_bImmune[id] = true
    set_task(15.0, "remove_protection", id)
}

public remove_protection(id)
{
    g_bImmune[id] = false
}

public client_disconnected(id)
{
    g_bImmune[id] = false
    g_iWarnings[id] = 0
}

public check_lag()
{
    static iPing, iLoss, iPlayers[MAX_PLAYERS], iNum, id
    get_players(iPlayers, iNum, "ch")

    for(new i = 0; i < iNum; i++)
    {
        id = iPlayers[i]
        if(g_bImmune[id] || (get_user_flags(id) & IMMUNITY_FLAG))
            continue

        get_user_ping(id, iPing, iLoss)

        if(iPing > PING_THRESHOLD || iLoss > LOSS_THRESHOLD)
        {
            g_iWarnings[id]++
            if(g_iWarnings[id] >= MAX_WARNINGS)
            {
                server_cmd("kick #%d ^"Lag Purge: Connection unstable (%dms/%d%%)^"", get_user_userid(id), iPing, iLoss)
            }
            else
            {
                client_print(id, print_chat, "[Lag Purge] Warning %d/%d: Stabilize your connection!", g_iWarnings[id], MAX_WARNINGS)
            }
        }
        else if(g_iWarnings[id] > 0)
        {
            g_iWarnings[id]--
        }
    }
    return PLUGIN_HANDLED
}
