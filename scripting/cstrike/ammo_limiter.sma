#include <amxmodx>
#include <cstrike>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

new p_max_mags;
new Float:g_LastMsgTime[MAX_PLAYERS + 1];

// Official Individual Magazine Sizes
static const g_MaxClip[] =
{
    0, 13, 0, 10, 0, 7, 0, 30, 30, 0, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50
};

// Maps every weapon to its shared Ammo Pool Index (0-14)
static const g_WeaponToAmmoPool[] =
{
    -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 9, 7, 6, 4, 4, 4, 6, 9, 1, 9, 3, 5, 4, 9, 2, 11, 8, 4, 2, -1, 7
};

public plugin_init()
{
    register_plugin("Ammo Limiter", "1.2", "SPiNX");
    p_max_mags = register_cvar("amx_max_mags", "2");

    register_event("AmmoX", "Event_AmmoChange", "be");

    register_clcmd("buyammo1", "Cmd_BlockBuyAmmo");
    register_clcmd("buyammo2", "Cmd_BlockBuyAmmo");
    register_clcmd("primammo", "Cmd_BlockBuyAmmo");
    register_clcmd("secammo", "Cmd_BlockBuyAmmo");
}

public Cmd_BlockBuyAmmo(id)
{
    if (is_user_alive(id) && IsAtAmmoLimit(id))
    {
        DisplayLimitMessage(id, get_pcvar_num(p_max_mags));
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

bool:IsAtAmmoLimit(id)
{
    new weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    new active_wpn = get_user_weapon(id);
    if (active_wpn <= 0 || active_wpn >= 31)
    {
        return false;
    }

    new current_bp = cs_get_user_bpammo(id, active_wpn);
    new limit = GetHighestOwnedLimit(active_wpn, weapons, num);

    return (current_bp >= limit);
}

// Finds the largest magazine size for the ammo pool among ALL held weapons
GetHighestOwnedLimit(wpn_id, weapons[], num)
{
    new pool_id = g_WeaponToAmmoPool[wpn_id];
    new highest_clip = g_MaxClip[wpn_id];

    if (pool_id == -1)
    {
        return highest_clip * get_pcvar_num(p_max_mags);
    }

    for (new i = 0; i < num; i++)
    {
        new w = weapons[i];
        // If this held weapon is in the same pool and has a larger mag, use it for the limit
        if (g_WeaponToAmmoPool[w] == pool_id && g_MaxClip[w] > highest_clip)
        {
            highest_clip = g_MaxClip[w];
        }
    }

    return highest_clip * get_pcvar_num(p_max_mags);
}

public Event_AmmoChange(id)
{
    set_task(0.1, "TaskEnforceLimit", id);
}

public TaskEnforceLimit(id)
{
    if (!is_user_alive(id))
    {
        return;
    }

    new weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (wpn_id <= 0 || wpn_id >= 31 || g_MaxClip[wpn_id] <= 0)
        {
            continue;
        }

        new current_bp = cs_get_user_bpammo(id, wpn_id);
        new limit = GetHighestOwnedLimit(wpn_id, weapons, num);

        if (current_bp > limit)
        {
            cs_set_user_bpammo(id, wpn_id, limit);
        }
    }
}

DisplayLimitMessage(id, max_mags)
{
    new Float:cur_time = get_gametime();
    if (cur_time - g_LastMsgTime[id] > 2.5)
    {
        client_print(id, print_center, "Ammo limit reached (%d mag%s max)", max_mags, max_mags == 1 ? "" : "s");
        g_LastMsgTime[id] = cur_time;
    }
}
