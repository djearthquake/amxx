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

public plugin_init()
{
    register_plugin("Ammo Limiter", "2.1.0", "SPiNX / Command Intercept");
    p_max_mags = register_cvar("amx_max_mags", "2");

    register_event("AmmoX", "Event_AmmoChange", "be");

    // Hook standard buy commands
    register_clcmd("buyammo1", "CmdBuyAmmo")
    register_clcmd("buyammo2", "CmdBuyAmmo")
    register_clcmd("cl_buyammo", "CmdBuyAmmo")
}

// INTERCEPT ENGINE COMMANDS: Catches macro strings directly from the player console
public client_command(id)
{
    if (!is_user_alive(id))
    {
        return PLUGIN_CONTINUE;
    }

    static cmd[32];
    read_argv(0, cmd, charsmax(cmd));

    // If the spacebar macro sends "secammo" or "primammo", instantly trigger our top-off
    if (equal(cmd, "secammo") || equal(cmd, "primammo"))
    {
        ForceFillAllWeapons(id);
        return PLUGIN_HANDLED; // Block the engine from rejecting the unheld weapon command
    }

    return PLUGIN_CONTINUE;
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

GetWeaponStaticLimit(wpn_id)
{
    if (!IsValidAmmoWeapon(wpn_id))
    {
        return 0;
    }
    return g_MaxClip[wpn_id] * get_pcvar_num(p_max_mags);
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
    ForceFillAllWeapons(id);
}

// Core function to safely top off holstered and held weapons
ForceFillAllWeapons(id)
{
    if (!is_user_alive(id))
    {
        return;
    }

    for (new wpn_id = 1; wpn_id < sizeof(g_MaxClip); wpn_id++)
    {
        if (!IsValidAmmoWeapon(wpn_id))
        {
            continue;
        }

        if (user_has_weapon(id, wpn_id))
        {
            new current_bp = cs_get_user_bpammo(id, wpn_id);
            new limit = GetWeaponStaticLimit(wpn_id);

            if (current_bp < limit)
            {
                cs_set_user_bpammo(id, wpn_id, limit);
            }
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

        if (user_has_weapon(id, wpn_id))
        {
            new current_bp = cs_get_user_bpammo(id, wpn_id);
            new limit = GetWeaponStaticLimit(wpn_id);

            if (current_bp > limit)
            {
                cs_set_user_bpammo(id, wpn_id, limit);
                over_limit = true;
            }
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
