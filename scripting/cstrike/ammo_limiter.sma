#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

// Weapon IDs to skip
#define CSW_KNIFE      29
#define CSW_C4         6
#define CSW_HEGREN     4
#define CSW_SMOKEGREN 9
#define CSW_FLASHBANG 25

new p_max_mags;
new Float:g_LastMsgTime[MAX_PLAYERS + 1];

// Absolute, bulletproof magazine sizes matching standard CS 1.6
static const g_MaxClip[] =
{
    0,  // None
    13, // P228
    0,  // Shield
    10, // Scout
    0,  // HEGrenade
    7,  // XM1014
    0,  // C4
    30, // Mac10
    30, // AUG
    0,  // SmokeGrenade
    30, // Elite
    20, // Fiveseven
    20, // G3SG1
    25, // UMP45
    30, // SG550
    35, // Galil
    25, // Famas (Clarion)
    12, // USP
    20, // Glock18
    10, // AWP
    30, // MP5Navy
    100,// M249
    8,  // M3
    30, // M4A1 (Colt)
    30, // TMP
    0,  // Flashbang
    7,  // Deagle
    30, // SG552
    30, // AK47
    0,  // Knife
    50  // P90
};

// Array of weapon classnames that require deployment checking
static const g_WeaponClassnames[][] = 
{
    "weapon_p228", "weapon_scout", "weapon_xm1014", "weapon_mac10", 
    "weapon_aug", "weapon_elite", "weapon_fiveseven", "weapon_g3sg1", 
    "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", 
    "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", 
    "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", 
    "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"
};

public plugin_init()
{
    register_plugin("Proactive Ammo Limiter", "3.1.1", "SPiNX");
    p_max_mags = register_cvar("amx_max_mags", "2");

    // Cleanly loop through the array to hook weapon deployment/switching
    for (new i = 0; i < sizeof(g_WeaponClassnames); i++)
    {
        RegisterHam(Ham_Item_Deploy, g_WeaponClassnames[i], "DynamicWeaponCheck", 1);
    }

    // Engine fallback for ammo modifications
    register_event("AmmoX", "Event_AmmoChange", "be");

    register_clcmd("buyammo1", "CmdBuyAmmo");
    register_clcmd("buyammo2", "CmdBuyAmmo");
    register_clcmd("cl_buyammo", "CmdBuyAmmo");
}

public client_command(id)
{
    if (!is_user_alive(id))
        return PLUGIN_CONTINUE;

    static cmd[32];
    read_argv(0, cmd, charsmax(cmd));

    if (equal(cmd, "secammo") || equal(cmd, "primammo"))
    {
        ForceFillActiveWeapon(id);
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

public CmdBuyAmmo(id)
{
    if (!is_user_alive(id))
        return PLUGIN_CONTINUE;

    set_task(0.05, "TaskForceFill", id);
    return PLUGIN_CONTINUE;
}

public Event_AmmoChange(id)
{
    if (!is_user_alive(id))
        return;

    EnforceActiveLimit(id);
}

public DynamicWeaponCheck(const weapon_ent)
{
    if (!pev_valid(weapon_ent))
        return;

    new id = get_pdata_cbase(weapon_ent, 41, 4); 
    if (is_user_alive(id))
    {
        EnforceActiveLimit(id);
    }
}

public TaskForceFill(id)
{
    ForceFillActiveWeapon(id);
}

GetWeaponStaticLimit(wpn_id)
{
    if (wpn_id <= 0 || wpn_id >= sizeof(g_MaxClip))
        return 0;

    switch (wpn_id)
    {
        case CSW_KNIFE, CSW_C4, CSW_HEGREN, CSW_SMOKEGREN, CSW_FLASHBANG: return 0;
        case CSW_USP: return 24;      
        case CSW_UMP45: return 50;    
        case CSW_FAMAS: return 50;
        case CSW_M4A1: return 60;     // Explicit hardcoded protection for Colt M4A1 (30 * 2)
    }
    
    return g_MaxClip[wpn_id] * get_pcvar_num(p_max_mags);
}

ForceFillActiveWeapon(id)
{
    if (!is_user_alive(id))
        return;

    new clip, ammo;
    new wpn_id = get_user_weapon(id, clip, ammo);
    new limit = GetWeaponStaticLimit(wpn_id);

    if (limit > 0)
    {
        new current_bp = cs_get_user_bpammo(id, wpn_id);
        if (current_bp < limit)
        {
            cs_set_user_bpammo(id, wpn_id, limit);
        }
    }
}

EnforceActiveLimit(id)
{
    new clip, ammo;
    new wpn_id = get_user_weapon(id, clip, ammo);
    new limit = GetWeaponStaticLimit(wpn_id);

    if (limit > 0)
    {
        new current_bp = cs_get_user_bpammo(id, wpn_id);
        if (current_bp > limit)
        {
            cs_set_user_bpammo(id, wpn_id, limit);
            DisplayLimitMessage(id, get_pcvar_num(p_max_mags));
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
