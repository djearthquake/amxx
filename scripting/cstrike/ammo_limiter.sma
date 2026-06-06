#include <amxmodx>
#include <cstrike>

// Weapon IDs to skip (Items without traditional backpack ammo)
#define CSW_KNIFE     29
#define CSW_C4        6
#define CSW_HEGREN    4
#define CSW_SMOKEGREN 9
#define CSW_FLASHBANG 25

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
    register_plugin("Ammo Limiter", "2.0.7", "SPiNX / Dynamic Pool Fixed");
    p_max_mags = register_cvar("amx_max_mags", "2");

    register_event("AmmoX", "Event_AmmoChange", "be");

    // Hook all native buy inputs to process instant single-tap spacebar macros
    register_clcmd("buyammo1", "CmdBuyAmmo")
    register_clcmd("buyammo2", "CmdBuyAmmo")
    register_clcmd("cl_buyammo", "CmdBuyAmmo")
    register_clcmd("primammo", "CmdBuyAmmo")
    register_clcmd("secammo", "CmdBuyAmmo")
}

bool:IsValidAmmoWeapon(wpn_id)
{
    if (wpn_id <= 0 || wpn_id >= sizeof(g_MaxClip))
    {
        return false;
    }

    switch (wpn_id)
    {
        case CSW_KNIFE, CSW_C4, CSW_HEGREN, CSW_SMOKEGREN, CSW_FLASHBANG:
        {
            return false;
        }
        default:
        {
            return (g_MaxClip[wpn_id] > 0);
        }
    }

    return false;
}

// FIXED LOGIC: Checks all player-owned weapons in a pool and matches the highest capacity clip.
GetHighestPoolLimit(id, wpn_id)
{
    new pool_id = g_WeaponToAmmoPool[wpn_id];
    new highest_clip = g_MaxClip[wpn_id];

    if (pool_id == -1)
    {
        return highest_clip * get_pcvar_num(p_max_mags);
    }

    static weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    new bool:has_matching_weapon = false;
    new user_highest = 0;

    for (new i = 0; i < num; i++)
    {
        new w = weapons[i];
        if (IsValidAmmoWeapon(w) && g_WeaponToAmmoPool[w] == pool_id)
        {
            has_matching_weapon = true;
            // Evaluates the physical weapon clip sizes owned to pull the largest value (e.g., Colt's 30 vs Clarion's 25)
            if (g_MaxClip[w] > user_highest)
            {
                user_highest = g_MaxClip[w];
            }
        }
    }

    if (has_matching_weapon)
    {
        highest_clip = user_highest;
    }

    return highest_clip * get_pcvar_num(p_max_mags);
}

public CmdBuyAmmo(id)
{
    if (!is_user_alive(id))
    {
        return PLUGIN_CONTINUE;
    }

    set_task(0.05, "TaskForceFill", id);
    return PLUGIN_CONTINUE;
}

public Event_AmmoChange(id)
{
    set_task(0.1, "TaskEnforceLimit", id);
}

public TaskForceFill(id)
{
    if (!is_user_alive(id))
    {
        return;
    }

    static weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (!IsValidAmmoWeapon(wpn_id))
        {
            continue;
        }

        new current_bp = cs_get_user_bpammo(id, wpn_id);
        new limit = GetHighestPoolLimit(id, wpn_id);

        if (current_bp < limit)
        {
            cs_set_user_bpammo(id, wpn_id, limit);
        }
    }
}

public TaskEnforceLimit(id)
{
    if (!is_user_alive(id))
    {
        return;
    }

    new bool:over_limit = false;

    for (new wpn_id = 1; wpn_id < sizeof(g_MaxClip); wpn_id++)
    {
        if (!IsValidAmmoWeapon(wpn_id))
        {
            continue;
        }

        new current_bp = cs_get_user_bpammo(id, wpn_id);
        new limit = GetHighestPoolLimit(id, wpn_id);

        if (current_bp > limit)
        {
            cs_set_user_bpammo(id, wpn_id, limit);
            over_limit = true;
        }
    }

    if (over_limit)
    {
        DisplayLimitMessage(id, get_pcvar_num(p_max_mags));
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
