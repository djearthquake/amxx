#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Caliber Scavenger"
#define VERSION "1.2"
#define AUTHOR "SPiNX"

/* Offsets */
#define m_pPlayer 41
#define m_iId 43
#define m_iClip 51
#define m_rgAmmo_Player 376
#define m_rgAmmo_Box 37
#define PEV_GROUP_MAG 8812

new const MODEL_W_BOX[] = "models/w_weaponbox.mdl";

/* Caliber Bitmasks */
#define BIT_9MM (1<<CSW_GLOCK18|1<<CSW_MP5NAVY|1<<CSW_TMP|1<<CSW_ELITE)
#define BIT_45ACP (1<<CSW_USP|1<<CSW_MAC10|1<<CSW_UMP45)
#define BIT_556NATO (1<<CSW_GALIL|1<<CSW_FAMAS|1<<CSW_M4A1|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_M249|1<<CSW_SG550)
#define BIT_762NATO (1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_G3SG1)
#define BIT_50AE (1<<CSW_DEAGLE)
#define BIT_338MAG (1<<CSW_AWP)
#define BIT_57NATO (1<<CSW_FIVESEVEN|1<<CSW_P90)
#define BIT_357SIG (1<<CSW_P228)

public plugin_precache()
{
    precache_model(MODEL_W_BOX);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Touch, "info_target", "OnMagTouch");
    RegisterHam(Ham_Touch, "weaponbox", "OnMagTouch");

    new const szWeapons[][] =
    {
        "weapon_famas", "weapon_m4a1", "weapon_aug", "weapon_sg552", "weapon_galil",
        "weapon_usp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_tmp",
        "weapon_glock18", "weapon_elite", "weapon_ak47", "weapon_scout", "weapon_g3sg1",
        "weapon_deagle", "weapon_awp", "weapon_p228", "weapon_fiveseven", "weapon_p90"
    };

    for (new i = 0; i < sizeof(szWeapons); i++)
    {
        RegisterHam(Ham_Weapon_Reload, szWeapons[i], "OnReloadPost", 1);
    }
}

public OnReloadPost(const iWeapon)
{
    if (!pev_valid(iWeapon)) return;

    new iClip = get_pdata_int(iWeapon, m_iClip, 4);

    if (iClip > 0)
    {
        new id = get_pdata_cbase(iWeapon, m_pPlayer, 4);

        if (is_user_alive(id))
        {
            new iWpnID = get_pdata_int(iWeapon, m_iId, 4);
            SpawnVisibleMag(id, iWpnID, iClip);
            set_pdata_int(iWeapon, m_iClip, 0, 4);
        }
    }
}

void:SpawnVisibleMag(id, iWpnID, iAmt)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(iEnt)) return;

    set_pev(iEnt, pev_groupinfo, PEV_GROUP_MAG);
    engfunc(EngFunc_SetModel, iEnt, MODEL_W_BOX);

    new Float:vOrigin[3], Float:vVel[3];
    pev(id, pev_origin, vOrigin);
    velocity_by_aim(id, 100, vVel);

    vVel[2] -= 50.0;
    vOrigin[2] += 10.0;

    set_pev(iEnt, pev_origin, vOrigin);
    set_pev(iEnt, pev_velocity, vVel);
    set_pev(iEnt, pev_movetype, MOVETYPE_TOSS);
    set_pev(iEnt, pev_solid, SOLID_TRIGGER);

    set_pev(iEnt, pev_iuser1, iWpnID);
    set_pev(iEnt, pev_iuser2, iAmt);
    set_pev(iEnt, pev_fuser1, get_gametime() + 0.3);

    engfunc(EngFunc_SetSize, iEnt, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 8.0});
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

public OnMagTouch(iEnt, id)
{
    if (!pev_valid(iEnt) || id < 1 || id > MAX_PLAYERS || !is_user_alive(id)) return;

    if (pev(iEnt, pev_fuser1) > get_gametime()) return;

    new iPlayerWeapons[MAX_PLAYERS], iNum;
    get_user_weapons(id, iPlayerWeapons, iNum);

    new bool:bIsMag = (pev(iEnt, pev_groupinfo) == PEV_GROUP_MAG);
    new bool:bChanged = false;

    if (bIsMag)
    {
        new iMagWpnID = pev(iEnt, pev_iuser1);
        new iMagAmt = pev(iEnt, pev_iuser2);
        new iAmmoSlot = GetWeaponAmmoSlot(iMagWpnID);

        if (iAmmoSlot > 0)
        {
            if (ApplyRawAmmo(id, iEnt, iAmmoSlot, iMagAmt, true))
            {
                set_pev(iEnt, pev_flags, FL_KILLME);
            }
        }
    }
    else
    {
        for (new i = 1; i <= 14; i++)
        {
            new iBoxAmmo = get_pdata_int(iEnt, m_rgAmmo_Box + i, 4);
            if (iBoxAmmo <= 0) continue;

            for (new j = 0; j < iNum; j++)
            {
                if (CheckIndex(i, iPlayerWeapons[j]))
                {
                    if (ApplyRawAmmo(id, iEnt, i, i, false))
                    {
                        bChanged = true;
                        break;
                    }
                }
            }
        }
        if (bChanged && IsEmpty(iEnt)) set_pev(iEnt, pev_flags, FL_KILLME);
    }
}

bool:CheckIndex(iIdx, iWpnID)
{
    switch (iIdx)
    {
        case 3, 10: return !!(BIT_9MM & (1<<iWpnID));
        case 8: return !!(BIT_45ACP & (1<<iWpnID));
        case 4, 5: return !!(BIT_556NATO & (1<<iWpnID));
        case 2: return !!(BIT_762NATO & (1<<iWpnID));
        case 6: return !!(BIT_50AE & (1<<iWpnID));
        case 1: return !!(BIT_338MAG & (1<<iWpnID));
        case 7: return !!(BIT_57NATO & (1<<iWpnID));
        case 9: return !!(BIT_357SIG & (1<<iWpnID));
    }
    return false;
}

bool:ApplyRawAmmo(id, iEnt, iAmmoSlot, iVal, bool:bIsAmt)
{
    new iMax = GetStaticSlotLimit(iAmmoSlot);
    new iCur = get_pdata_int(id, m_rgAmmo_Player + iAmmoSlot, 5);

    if (iCur >= iMax) return false;

    new iAmt = bIsAmt ? iVal : get_pdata_int(iEnt, m_rgAmmo_Box + iVal, 4);
    new iTake = (iAmt + iCur > iMax) ? (iMax - iCur) : iAmt;

    set_pdata_int(id, m_rgAmmo_Player + iAmmoSlot, iCur + iTake, 5);

    if (!bIsAmt) set_pdata_int(iEnt, m_rgAmmo_Box + iVal, iAmt - iTake, 4);

    return true;
}

bool:IsEmpty(iEnt)
{
    for (new i = 1; i <= 14; i++)
    {
        if (get_pdata_int(iEnt, m_rgAmmo_Box + i, 4) > 0) return false;
    }
    return true;
}

GetStaticSlotLimit(iAmmoSlot)
{
    new p_max_mags = get_cvar_pointer("amx_max_mags");
    new iMultiplier = p_max_mags ? get_pcvar_num(p_max_mags) : 2;

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
