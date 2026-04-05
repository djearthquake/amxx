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

static const g_szWeaponData[][] = 
{
    {"weapon_p228", "0.2"}, {"weapon_mac10", "0.3"}, {"weapon_aug", "0.5"}, 
    {"weapon_elite", "0.2"}, {"weapon_fiveseven", "0.2"}, {"weapon_ump45", "0.4"}, 
    {"weapon_sg550", "0.6"}, {"weapon_galil", "0.5"}, {"weapon_famas", "0.5"}, 
    {"weapon_usp", "0.15"}, {"weapon_glock18", "0.15"}, {"weapon_mp5navy", "0.3"}, 
    {"weapon_m249", "0.8"}, {"weapon_m4a1", "0.5"}, {"weapon_tmp", "0.3"}, 
    {"weapon_g3sg1", "0.6"}, {"weapon_sg552", "0.5"}, {"weapon_ak47", "0.5"}, 
    {"weapon_p90", "0.4"}, {"weapon_deagle", "0.3"},
    {"weapon_scout", "0.0"}, {"weapon_awp", "0.0"}, {"weapon_xm1014", "0.0"}
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
    register_plugin("Weapon Maintenance", "0.1", "SPiNX");

    g_iPCvarMaintCost = register_cvar("amx_oil_cost", "50");
    
    g_iHudSync = CreateHudSyncObj();
    g_iMsgBar  = get_user_msgid("BarTime");

    for (new i = 0; i < sizeof g_szWeaponData; i++)
    {
        RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponData[i][0], "Ham_CheckJam", 0);
        RegisterHam(Ham_Item_Deploy,          g_szWeaponData[i][0], "Ham_CheckDeploy", 1);
        RegisterHam(Ham_Item_AttachToPlayer,  g_szWeaponData[i][0], "Ham_InitWeapon", 0);
    }

    register_clcmd("say /oil", "CmdRepair");
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

public CmdRepair(id)
{
    if (!is_user_alive(id) || !cs_get_user_buyzone(id)) return PLUGIN_HANDLED;

    new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
    if (!pev_valid(iWeapon)) return PLUGIN_HANDLED;

    new iCost = get_pcvar_num(g_iPCvarMaintCost);
    if (cs_get_user_money(id) < iCost) return PLUGIN_HANDLED;

    g_iRepairingWeapon[id] = iWeapon;
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
    
    Util_BarTime(id, REPAIR_TIME);
    emit_sound(id, CHAN_ITEM, "ambience/steamburst1.wav", 0.4, ATTN_NORM, 0, PITCH_NORM);
    set_task(float(REPAIR_TIME), "Task_FinishRepair", id + TASKID_REPAIR);
    
    return PLUGIN_HANDLED;
}

public Task_FinishRepair(id)
{
    id -= TASKID_REPAIR;
    if (!is_user_connected(id)) return;

    set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
    emit_sound(id, CHAN_ITEM, "ambience/steamburst1.wav", 0.0, ATTN_NORM, SND_STOP, PITCH_NORM);

    if (!is_user_alive(id)) return;

    new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
    if (pev_valid(iWeapon) && iWeapon == g_iRepairingWeapon[id])
    {
        cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(g_iPCvarMaintCost));
        set_pev(iWeapon, pev_condition, MAX_CONDITION);
        UpdateHud(id, MAX_CONDITION);
        client_print_color(id, print_team_default, "^4[Service]^1 Weapon oiled.");
    }
    g_iRepairingWeapon[id] = 0;
}

public Ham_CheckJam(iWeapon)
{
    new id = pev(iWeapon, pev_owner);
    if (!is_user_alive(id)) return HAM_IGNORED;

    new szClass[32], Float:fWearRate = 1.0;
    pev(iWeapon, pev_classname, szClass, charsmax(szClass));
    
    for(new i = 0; i < sizeof g_szWeaponData; i++) {
        if(equal(szClass, g_szWeaponData[i][0])) {
            fWearRate = str_to_float(g_szWeaponData[i][1]);
            break;
        }
    }

    if (fWearRate == 0.0) return HAM_IGNORED;

    new iCond = pev(iWeapon, pev_condition);
    if (random_float(0.0, 1.0) <= fWearRate) 
    {
        iCond = (iCond > 0) ? iCond - 1 : 0;
        set_pev(iWeapon, pev_condition, iCond);
        UpdateHud(id, iCond);
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
    set_hudmessage((iCond < 40) ? 255 : 100, (iCond > 40) ? 255 : 100, 100, 0.02, 0.2, 0, 0.1, 1.0, 0.1, 0.1, -1);
    ShowSyncHudMsg(id, g_iHudSync, "Condition: %d%%", iCond);
}

public client_disconnected(id)
{
    remove_task(id + TASKID_REPAIR);
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
    write_byte(5); write_byte(10);
    message_end();
}
