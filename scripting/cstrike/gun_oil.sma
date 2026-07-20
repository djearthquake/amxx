#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define MAX_CONDITION         100
#define JAM_THRESHOLD         30
#define BASE_JAM_CHANCE       5
#define REPAIR_TIME           3
#define TASKID_REPAIR         2000

#define pev_condition         pev_iuser1
#define pev_is_initialized    pev_iuser2

#define m_flNextPrimaryAttack 46
#define m_pActiveItem         373
#define XO_WEAPON             4
#define XO_PLAYER             5

// Native integer wear chances per bullet (0 = never wears, 20 = 20% chance, 50 = 50% chance, etc.)
static const g_iWeaponWearChance[CSW_P90 + 1] =
{
    0,  // None
    15, // CSW_P228
    0,  // CSW_GLOCK (Skip placeholder)
    0,  // CSW_SCOUT
    0,  // CSW_HEGRENADE
    0,  // CSW_XM1014
    0,  // CSW_C4
    30, // CSW_MAC10
    50, // CSW_AUG
    0,  // CSW_SMOKEGRENADE
    20, // CSW_ELITE
    20, // CSW_FIVESEVEN
    40, // CSW_UMP45
    60, // CSW_SG550
    50, // CSW_GALIL
    50, // CSW_FAMAS
    15, // CSW_USP
    15, // CSW_GLOCK18
    0,  // CSW_AWP
    30, // CSW_MP5NAVY
    80, // CSW_M249
    0,  // CSW_M3
    50, // CSW_M4A1
    30, // CSW_TMP
    60, // CSW_G3SG1
    0,  // CSW_FLASHBANG
    30, // CSW_DEAGLE
    50, // CSW_SG552
    50, // CSW_AK47
    0,  // CSW_KNIFE
    40  // CSW_P90
};

static g_iPCvarMaintCost, g_iHudSync, g_iSpriteSmoke, g_iMsgBar;
static g_iRepairingWeapon[MAX_PLAYERS + 1];

public plugin_precache()
{
    g_iSpriteSmoke = precache_model("sprites/steam1.spr");
    precache_sound("weapons/dryfire_pistol.wav");
    precache_sound("ambience/steamburst1.wav");
}

public plugin_init()
{
    register_plugin("Weapon Maintenance", "2.5", "SPiNX (Cinematic Restored)");

    g_iPCvarMaintCost = register_cvar("amx_oil_cost", "50");
    g_iHudSync = CreateHudSyncObj();
    g_iMsgBar  = get_user_msgid("BarTime");

    for (new iId = 1; iId <= CSW_P90; iId++)
    {
        if (g_iWeaponWearChance[iId] == 0) continue;

        new szWeaponName[32];
        get_weaponname(iId, szWeaponName, charsmax(szWeaponName));

        RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "Ham_CheckJam", 0);
        RegisterHam(Ham_Item_Deploy,          szWeaponName, "Ham_CheckDeploy", 1);
        RegisterHam(Ham_Item_AttachToPlayer,  szWeaponName, "Ham_InitWeapon", 0);
        RegisterHam(Ham_Item_Holster,         szWeaponName, "Ham_WeaponHolster", 0);
    }

    register_clcmd("say /oil", "CmdRepair");
    register_clcmd("/oil", "CmdRepair");
}

public client_putinserver(id)
{
    set_task(10.0, "Task_WelcomeMessage", id);
}

public Task_WelcomeMessage(id)
{
    if (is_user_connected(id))
    {
        client_print_color(id, print_team_default, "^4[Service]^1 This server uses Weapon Wear! Type ^4/oil^1 in the Buyzone to service your guns.");
    }
}

public Ham_InitWeapon(iWeapon, id)
{
    if (pev_valid(iWeapon) && !pev(iWeapon, pev_is_initialized))
    {
        set_pev(iWeapon, pev_condition, MAX_CONDITION);
        set_pev(iWeapon, pev_is_initialized, 1);
    }
}

public Ham_CheckDeploy(iWeapon)
{
    new id = pev(iWeapon, pev_owner);
    if (is_user_alive(id))
    {
        UpdateHud(id, pev(iWeapon, pev_condition));
    }
    return HAM_IGNORED;
}

public Ham_WeaponHolster(iWeapon)
{
    new id = pev(iWeapon, pev_owner);
    if (is_user_connected(id) && g_iRepairingWeapon[id] == iWeapon)
    {
        CancelRepair(id);
    }
    return HAM_IGNORED;
}

public CmdRepair(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;
    if (g_iRepairingWeapon[id] > 0) return PLUGIN_HANDLED; 
    
    if (!cs_get_user_buyzone(id))
    {
        client_print_color(id, print_team_default, "^4[Service]^1 You must be inside the ^4Buyzone^1 to use gun oil.");
        return PLUGIN_HANDLED;
    }

    new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
    if (!pev_valid(iWeapon)) return PLUGIN_HANDLED;

    new iId = cs_get_weapon_id(iWeapon);
    if (iId <= 0 || iId > CSW_P90 || g_iWeaponWearChance[iId] == 0) return PLUGIN_HANDLED;

    new iCost = get_pcvar_num(g_iPCvarMaintCost);
    if (cs_get_user_money(id) < iCost)
    {
        client_print_color(id, print_team_default, "^4[Service]^1 You need ^4$%d^1 to afford gun oil.", iCost);
        return PLUGIN_HANDLED;
    }

    g_iRepairingWeapon[id] = iWeapon;
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
    
    Util_BarTime(id, REPAIR_TIME);
    emit_sound(id, CHAN_ITEM, "ambience/steamburst1.wav", 0.4, ATTN_NORM, 0, PITCH_NORM);
    set_task(float(REPAIR_TIME), "Task_FinishRepair", id + TASKID_REPAIR);
    
    return PLUGIN_HANDLED;
}

public CancelRepair(id)
{
    remove_task(id + TASKID_REPAIR);
    if (is_user_connected(id))
    {
        set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN); 
        Util_BarTime(id, 0); 
        emit_sound(id, CHAN_ITEM, "ambience/steamburst1.wav", 0.0, ATTN_NORM, SND_STOP, PITCH_NORM);
        client_print_color(id, print_team_default, "^4[Service]^1 Repair cancelled due to weapon switch.");
    }
    g_iRepairingWeapon[id] = 0;
}

public Task_FinishRepair(id)
{
    id -= TASKID_REPAIR;
    if (!is_user_connected(id)) return;

    set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
    emit_sound(id, CHAN_ITEM, "ambience/steamburst1.wav", 0.0, ATTN_NORM, SND_STOP, PITCH_NORM);

    if (!is_user_alive(id))
    {
        g_iRepairingWeapon[id] = 0;
        return;
    }

    new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
    if (pev_valid(iWeapon) && iWeapon == g_iRepairingWeapon[id])
    {
        cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(g_iPCvarMaintCost));
        set_pev(iWeapon, pev_condition, MAX_CONDITION);
        UpdateHud(id, MAX_CONDITION);
        client_print_color(id, print_team_default, "^4[Service]^1 Weapon oiled successfully.");
    }
    g_iRepairingWeapon[id] = 0;
}

public Ham_CheckJam(iWeapon)
{
    new id = pev(iWeapon, pev_owner);
    if (!is_user_alive(id)) return HAM_IGNORED;

    new iId = cs_get_weapon_id(iWeapon);
    if (iId <= 0 || iId > CSW_P90) return HAM_IGNORED;

    new iCond = pev(iWeapon, pev_condition);

    if (random_num(1, 100) <= g_iWeaponWearChance[iId])
    {
        iCond = (iCond > 0) ? iCond - 1 : 0;
        set_pev(iWeapon, pev_condition, iCond);
        UpdateHud(id, iCond);
        
        if (iCond == JAM_THRESHOLD)
        {
            client_print_color(id, print_team_default, "^4[WARNING]^1 Your weapon condition is critical! Head to a Buyzone and type ^4/oil^1.");
        }
    }

    if (iCond < JAM_THRESHOLD)
    {
        if (random_num(1, 100) <= ((JAM_THRESHOLD - iCond) + BASE_JAM_CHANCE))
        {
            client_print(id, print_center, "!!! JAMMED !!!");
            emit_sound(id, CHAN_WEAPON, "weapons/dryfire_pistol.wav", 0.8, ATTN_NORM, 0, PITCH_NORM);
            set_pdata_float(iWeapon, m_flNextPrimaryAttack, 1.0, XO_WEAPON);
            Util_VisualFailure(id);
            return HAM_SUPERCEDE;
        }
    }
    return HAM_IGNORED;
}

UpdateHud(id, iCond)
{
    set_hudmessage((iCond < 40) ? 255 : 100, (iCond > 40) ? 255 : 100, 100, 0.02, 0.2, 0, 0.1, 3.0, 0.1, 0.1, -1);
    ShowSyncHudMsg(id, g_iHudSync, "Condition: %d%%", iCond);
}

Util_BarTime(id, iSeconds)
{
    message_begin(MSG_ONE_UNRELIABLE, g_iMsgBar, _, id);
    write_short(iSeconds);
    message_end();
}

Util_VisualFailure(id)
{
    new Float:fOrigin[3];
    pev(id, pev_origin, fOrigin);
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_SMOKE);
    engfunc(EngFunc_WriteCoord, fOrigin[0]);
    engfunc(EngFunc_WriteCoord, fOrigin[1]);
    engfunc(EngFunc_WriteCoord, fOrigin[2] + 20.0);
    write_short(g_iSpriteSmoke);
    write_byte(5); 
    write_byte(10);
    message_end();
}

public client_disconnected(id)
{
    remove_task(id + TASKID_REPAIR);
    g_iRepairingWeapon[id] = 0;
}
