#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define CSW_KNIFE      29
#define CSW_C4         6
#define CSW_HEGREN     4
#define CSW_SMOKEGREN 9
#define CSW_FLASHBANG 25

new p_max_mags;
new Float:g_LastMsgTime[MAX_PLAYERS + 1];

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
    register_plugin("Ammo Limiter", "2.0", "SPiNX");
    p_max_mags = register_cvar("amx_max_mags", "2");

    for (new i = 0; i < sizeof(g_WeaponClassnames); i++)
    {
        RegisterHam(Ham_Item_Deploy, g_WeaponClassnames[i], "DynamicWeaponCheck", 1);
    }

    register_event("AmmoX", "Event_AmmoChange", "be");

    register_clcmd("buyammo1", "CmdBuyAmmo");
    register_clcmd("buyammo2", "CmdBuyAmmo");
    register_clcmd("cl_buyammo", "CmdBuyAmmo");
}

public client_command(id)
{
    if (!is_user_alive(id))
        return PLUGIN_CONTINUE;

    // FIXED PERMANENTLY: Sized as an explicit array to fix compiler argument mismatches
    static cmd[32];
    read_argv(0, cmd, charsmax(cmd));

    if (equal(cmd, "secammo") || equal(cmd, "primammo"))
    {
        ForceFillAllWeapons(id);
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
    ForceFillAllWeapons(id);
}

bool:IsValidAmmoWeapon(wpn_id)
{
    if (wpn_id <= 0 || wpn_id >= 31)
        return false;

    switch (wpn_id)
    {
        case CSW_KNIFE, CSW_C4, CSW_HEGREN, CSW_SMOKEGREN, CSW_FLASHBANG: return false;
    }
    return true;
}

GetWeaponAmmoSlot(iWpnID)
{
    switch (iWpnID)
    {
        case CSW_AWP: return 1;
        case CSW_AK47, CSW_SCOUT, CSW_G3SG1: return 2;
        case CSW_M249: return 3;
        case CSW_GALIL, CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG552, CSW_SG550: return 4;
        case CSW_XM1014, CSW_M3: return 5;
        case CSW_DEAGLE: return 6;
        case CSW_FIVESEVEN, CSW_P90: return 7; 
        case CSW_USP, CSW_MAC10, CSW_UMP45: return 8; 
        case CSW_P228: return 9;
        case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: return 10;
    }
    return 0;
}

GetStaticSlotLimit(iAmmoSlot)
{
    new iMultiplier = get_pcvar_num(p_max_mags);

    switch(iAmmoSlot)
    {
        case 1: return 10 * iMultiplier;  
        case 2: return 30 * iMultiplier;  
        case 3: return 100 * iMultiplier; 
        case 4: return 30 * iMultiplier;  
        case 5: return 8 * iMultiplier;   
        case 6: return 7 * iMultiplier;   
        case 7: return 50 * iMultiplier;  
        case 8: return 25 * iMultiplier;  
        case 9: return 13 * iMultiplier;  
        case 10: return 30 * iMultiplier; 
    }
    return 0;
}

ForceFillAllWeapons(id)
{
    if (!is_user_alive(id))
        return;

    static weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (!IsValidAmmoWeapon(wpn_id)) continue;

        new iAmmoSlot = GetWeaponAmmoSlot(wpn_id);
        if (iAmmoSlot <= 0) continue;

        new limit = GetStaticSlotLimit(iAmmoSlot);
        if (limit > 0)
        {
            new current_bp = cs_get_user_bpammo(id, wpn_id);
            if (current_bp < limit)
            {
                cs_set_user_bpammo(id, wpn_id, limit);
            }
        }
    }
}

EnforceActiveLimit(id)
{
    if (!is_user_alive(id))
        return;

    static weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    new bool:over_limit = false;

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        if (!IsValidAmmoWeapon(wpn_id)) continue;

        new iAmmoSlot = GetWeaponAmmoSlot(wpn_id);
        if (iAmmoSlot <= 0) continue;

        new limit = GetStaticSlotLimit(iAmmoSlot);
        if (limit > 0)
        {
            new current_bp = cs_get_user_bpammo(id, wpn_id);
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
