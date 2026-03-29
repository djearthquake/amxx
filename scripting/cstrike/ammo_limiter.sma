#include <amxmodx>
#include <cstrike>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

new p_max_mags;
new Float:g_LastMsgTime[MAX_PLAYERS + 1];

static const g_MaxClip[] =
{
    0, 13, 0, 10, 0, 7, 0, 30, 30, 0, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50
};

public plugin_init()
{
    register_plugin("Ammo Limiter", "1.2", "SPiNX");
    p_max_mags = register_cvar("amx_max_mags", "2");

    register_event("AmmoX", "Event_AmmoChange", "be");
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");

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
    new weapons[MAX_PLAYERS], num, max_mags = get_pcvar_num(p_max_mags);
    get_user_weapons(id, weapons, num);
    new active_wpn = get_user_weapon(id);

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (wpn_id >= sizeof(g_MaxClip) || g_MaxClip[wpn_id] <= 0) continue;

        if (cs_get_user_bpammo(id, wpn_id) < GetDynamicLimit(wpn_id, active_wpn, max_mags))
        {
            return false;
        }
    }
    return true;
}

GetDynamicLimit(wpn_id, active_wpn, max_mags)
{
    new base_clip = g_MaxClip[wpn_id];

    if ((wpn_id == 16 || wpn_id == 12 || wpn_id == 7) && (active_wpn == 16 || active_wpn == 12 || active_wpn == 7))
        base_clip = g_MaxClip[active_wpn];

    else if ((wpn_id == 11 || wpn_id == 30) && (active_wpn == 11 || active_wpn == 30))
        base_clip = g_MaxClip[active_wpn];

    else if ((wpn_id == 17 || wpn_id == 19 || wpn_id == 23 || wpn_id == 10) && (active_wpn == 17 || active_wpn == 19 || active_wpn == 23 || active_wpn == 10))
        base_clip = g_MaxClip[active_wpn];

    else if ((wpn_id == 28 || wpn_id == 3 || wpn_id == 24) && (active_wpn == 28 || active_wpn == 3 || active_wpn == 24))
        base_clip = g_MaxClip[active_wpn];

    else if ((wpn_id == 20 || wpn_id == 22 || wpn_id == 14 || wpn_id == 15 || wpn_id == 8 || wpn_id == 27 || wpn_id == 13) &&
             (active_wpn == 20 || active_wpn == 22 || active_wpn == 14 || active_wpn == 15 || active_wpn == 8 || active_wpn == 27 || active_wpn == 13))
        base_clip = g_MaxClip[active_wpn];

    return base_clip * max_mags;
}

public Event_CurWeapon(id)
{
    if (!is_user_alive(id)) return;

    new active_wpn = get_user_weapon(id);
    new max_mags = get_pcvar_num(p_max_mags);
    new current_bp = cs_get_user_bpammo(id, active_wpn);
    new target_limit = g_MaxClip[active_wpn] * max_mags;

    // AUTO-RESTORE: If the player switches to a weapon that SHOULD have more ammo
    // than the current backpack (because it was previously shrunk by a pistol),
    // we give them the missing rounds back.
    if (current_bp < target_limit)
    {
        cs_set_user_bpammo(id, active_wpn, target_limit);
    }

    TaskCapAmmo(id);
}

public Event_AmmoChange(id)
{
    set_task(0.1, "TaskCapAmmo", id);
}

public TaskCapAmmo(id)
{
    if (!is_user_alive(id)) return;

    new weapons[MAX_PLAYERS], num, max_mags = get_pcvar_num(p_max_mags);
    get_user_weapons(id, weapons, num);
    new active_wpn = get_user_weapon(id);
    new bool:capped = false;

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (wpn_id >= sizeof(g_MaxClip) || g_MaxClip[wpn_id] <= 0) continue;

        new limit = GetDynamicLimit(wpn_id, active_wpn, max_mags);

        if (cs_get_user_bpammo(id, wpn_id) > limit)
        {
            cs_set_user_bpammo(id, wpn_id, limit);
            capped = true;
        }
    }

    if (capped) DisplayLimitMessage(id, max_mags);
}

DisplayLimitMessage(id, max_mags)
{
    new Float:cur_time = get_gametime();
    if (cur_time - g_LastMsgTime[id] > 2.0)
    {
        client_print(id, print_center, "Ammo limit reached (%d mag%s max)", max_mags, max_mags == 1 ? "" : "s");
        g_LastMsgTime[id] = cur_time;
    }
}
