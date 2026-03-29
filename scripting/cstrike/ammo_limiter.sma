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
    register_plugin("Ammo Limiter & Blocker", "1.1", "SPiNX");
    p_max_mags = register_cvar("amx_max_mags", "1");
    
    register_event("AmmoX", "Event_AmmoChange", "be");
    
    // Hooks for VGUI menu
    register_clcmd("buy", "Cmd_BlockBuy");
    
    // Hooks for aliases/binds like "primammo" and "secammo"
    register_clcmd("buyammo1", "Cmd_BlockBuyAmmo");
    register_clcmd("buyammo2", "Cmd_BlockBuyAmmo");
    register_clcmd("primammo", "Cmd_BlockBuyAmmo");
    register_clcmd("secammo", "Cmd_BlockBuyAmmo");
}

public Cmd_BlockBuy(id)
{
    if (!is_user_alive(id)) return PLUGIN_CONTINUE;

    new args[32];
    read_args(args, charsmax(args));

    if (containi(args, "ammo") != -1)
    {
        if (IsAtAmmoLimit(id))
        {
            DisplayLimitMessage(id, get_pcvar_num(p_max_mags));
            return PLUGIN_HANDLED; 
        }
    }
    return PLUGIN_CONTINUE;
}

public Cmd_BlockBuyAmmo(id)
{
    // Using id here prevents the "symbol never used" compiler warning
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
    
    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (wpn_id >= sizeof(g_MaxClip) || g_MaxClip[wpn_id] <= 0) continue;

        if (cs_get_user_bpammo(id, wpn_id) < GetWeaponLimit(id, wpn_id, weapons, num, max_mags))
            return false; 
    }
    return true; 
}

GetWeaponLimit(id, wpn_id, weapons[], num, max_mags)
{
    #pragma unused id 
    new highest_clip = g_MaxClip[wpn_id];

    if (wpn_id == 12 || wpn_id == 16 || wpn_id == 7) { 
        for(new i=0; i<num; i++) {
            if((weapons[i]==12 || weapons[i]==16 || weapons[i]==7) && g_MaxClip[weapons[i]] > highest_clip)
                highest_clip = g_MaxClip[weapons[i]];
        }
    }
    else if (wpn_id == 19 || wpn_id == 17 || wpn_id == 23 || wpn_id == 10) { 
        for(new i=0; i<num; i++) {
            if((weapons[i]==19 || weapons[i]==17 || weapons[i]==23 || weapons[i]==10) && g_MaxClip[weapons[i]] > highest_clip)
                highest_clip = g_MaxClip[weapons[i]];
        }
    }
    return highest_clip * max_mags;
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

    new bool:capped = false;
    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (wpn_id >= sizeof(g_MaxClip) || g_MaxClip[wpn_id] <= 0) continue;

        new limit = GetWeaponLimit(id, wpn_id, weapons, num, max_mags);
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
