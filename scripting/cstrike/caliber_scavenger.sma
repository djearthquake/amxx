#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Caliber Scavenger Pro"
#define VERSION "1.0"
#define AUTHOR "SPiNX"

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif

#define m_pPlayer 41
#define m_iId 43
#define m_iClip 51
#define m_fInReload 54
#define PEV_GROUP_MAG 8812

new Trie:g_tModels;
static const SOUND_PICKUP[] = "items/9mmclip1.wav";

// Bitmasks for caliber grouping
#define BIT_9MM (1<<CSW_GLOCK18|1<<CSW_MP5NAVY|1<<CSW_TMP|1<<CSW_ELITE|1<<CSW_P228|1<<CSW_USP|1<<CSW_MAC10|1<<CSW_UMP45)
#define BIT_556NATO (1<<CSW_GALIL|1<<CSW_FAMAS|1<<CSW_M4A1|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_M249|1<<CSW_SG550)
#define BIT_762NATO (1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_G3SG1)
#define BIT_50AE (1<<CSW_DEAGLE)
#define BIT_338LAPUA (1<<CSW_AWP)

static const g_szMagWeapons[][] =
{
    "weapon_famas", "weapon_m4a1", "weapon_aug", "weapon_sg552", "weapon_galil",
    "weapon_usp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_tmp",
    "weapon_glock18", "weapon_elite", "weapon_ak47", "weapon_scout", "weapon_g3sg1",
    "weapon_deagle", "weapon_awp", "weapon_p228", "weapon_fiveseven", "weapon_p90", "weapon_m249"
};

new g_pcvar_cleanup, g_iBitBotHooked;

public plugin_precache()
{
    g_tModels = TrieCreate();
    new szConfigDir[64], szFilePath[128];
    get_configsdir(szConfigDir, charsmax(szConfigDir));
    formatex(szFilePath, charsmax(szFilePath), "%s/scavenger_models.ini", szConfigDir);

    new const szFallback[] = "models/w_9mmclip.mdl";
    TrieSetString(g_tModels, "9mm", szFallback);
    TrieSetString(g_tModels, "556", szFallback);
    TrieSetString(g_tModels, "762", szFallback);
    TrieSetString(g_tModels, "50ae", szFallback);
    TrieSetString(g_tModels, "338", szFallback);
    TrieSetString(g_tModels, "default", szFallback);

    if (file_exists(szFallback)) precache_model(szFallback);

    if (file_exists(szFilePath))
    {
        new iFile = fopen(szFilePath, "rt");
        if (iFile)
        {
            new szData[128], szKey[MAX_PLAYERS], szVal[96];
            while (!feof(iFile))
            {
                fgets(iFile, szData, charsmax(szData));
                trim(szData);
                if (!szData[0] || szData[0] == ';' || szData[0] == '#') continue;
                strtok(szData, szKey, charsmax(szKey), szVal, charsmax(szVal), '=');
                trim(szKey); trim(szVal);
                if (szVal[0] && file_exists(szVal))
                {
                    TrieSetString(g_tModels, szKey, szVal);
                    precache_model(szVal);
                }
            }
            fclose(iFile);
        }
    }
    else
    {
        new iFile = fopen(szFilePath, "wt");
        if (iFile)
        {
            fprintf(iFile, "; Caliber Scavenger Pro Config^n");
            fprintf(iFile, "9mm = %s^n", szFallback);
            fprintf(iFile, "556 = %s^n", szFallback);
            fprintf(iFile, "762 = %s^n", szFallback);
            fprintf(iFile, "50ae = %s^n", szFallback);
            fprintf(iFile, "338 = %s^n", szFallback);
            fprintf(iFile, "default = %s^n", szFallback);
            fclose(iFile);
        }
    }
    precache_sound(SOUND_PICKUP);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    g_pcvar_cleanup = register_cvar("scavenger_round_cleanup", "1");
    RegisterHam(Ham_Touch, "info_target", "OnMagTouch");
    register_forward(FM_Think, "OnMagThink");
    register_logevent("OnRoundEnd", 2, "1=Round_End");
    for (new i = 0; i < sizeof(g_szMagWeapons); i++)
        RegisterHam(Ham_Weapon_Reload, g_szMagWeapons[i], "OnReloadPre", 0);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawnPost", 1);
}

public client_disconnected(id)
    g_iBitBotHooked &= ~(1 << (id & 31));

public OnPlayerSpawnPost(id)
{
    if (!is_user_alive(id) || !is_user_bot(id)) return;
    if (!(g_iBitBotHooked & (1 << (id & 31))))
    {
        for (new i = 0; i < sizeof(g_szMagWeapons); i++)
        {
            new iWpn = fm_find_ent_by_owner(-1, g_szMagWeapons[i], id);
            if (pev_valid(iWpn))
                RegisterHamFromEntity(Ham_Weapon_Reload, iWpn, "OnReloadPre", 0);
        }
        g_iBitBotHooked |= (1 << (id & 31));
    }
}

public OnRoundEnd()
{
    if (!get_pcvar_num(g_pcvar_cleanup)) return;
    new iEnt = -1;
    while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "info_target")))
    {
        if (pev_valid(iEnt) && pev(iEnt, pev_groupinfo) == PEV_GROUP_MAG)
            engfunc(EngFunc_RemoveEntity, iEnt);
    }
}

public OnReloadPre(const iWeapon)
{
    if (!pev_valid(iWeapon) || get_pdata_int(iWeapon, m_fInReload, 4)) return HAM_IGNORED;
    new iClip = get_pdata_int(iWeapon, m_iClip, 4);
    if (iClip > 0)
    {
        new id = get_pdata_cbase(iWeapon, m_pPlayer, 4);
        if (is_user_alive(id))
        {
            SpawnVisibleMag(id, get_pdata_int(iWeapon, m_iId, 4), iClip);
            set_pdata_int(iWeapon, m_iClip, 0, 4);
        }
    }
    return HAM_IGNORED;
}

public OnMagThink(iEnt)
{
    if (!pev_valid(iEnt) || pev(iEnt, pev_groupinfo) != PEV_GROUP_MAG) return FMRES_IGNORED;
    new Float:vVel[3];
    pev(iEnt, pev_velocity, vVel);
    if (vector_length(vVel) > 15.0)
    {
        if (pev(iEnt, pev_flags) & FL_ONGROUND)
        {
            vVel[0] *= 0.4; vVel[1] *= 0.4; vVel[2] = 85.0;
            set_pev(iEnt, pev_velocity, vVel);
            set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & ~FL_ONGROUND);
            new Float:vSpin[3];
            vSpin[0] = random_float(-150.0, 150.0); vSpin[1] = random_float(-150.0, 150.0); vSpin[2] = random_float(-150.0, 150.0);
            set_pev(iEnt, pev_avelocity, vSpin);
        }
        set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
    }
    else set_pev(iEnt, pev_avelocity, Float:{0.0, 0.0, 0.0});
    return FMRES_HANDLED;
}

public OnMagTouch(iEnt, id)
{
    if (!pev_valid(iEnt) || !is_user_alive(id)) return;
    if (pev(iEnt, pev_fuser1) > get_gametime()) return;
    new iPlayerWeapons[MAX_PLAYERS], iNum;
    get_user_weapons(id, iPlayerWeapons, iNum);
    if (pev(iEnt, pev_groupinfo) == PEV_GROUP_MAG)
    {
        new iMagWpnID = pev(iEnt, pev_iuser1);
        new iMagAmt = pev(iEnt, pev_iuser2);
        for (new i = 0; i < iNum; i++)
        {
            if (CheckCaliber(iMagWpnID, iPlayerWeapons[i]))
            {
                if (ApplyAmmo(id, iPlayerWeapons[i], iMagAmt))
                {
                    engfunc(EngFunc_RemoveEntity, iEnt);
                    return;
                }
            }
        }
    }
}

bool:ApplyAmmo(id, iWpnID, iVal)
{
    new iMax = GetMax(iWpnID);
    new iCur = cs_get_user_bpammo(id, iWpnID);
    if (iCur >= iMax) return false;
    new iTake = (iVal + iCur > iMax) ? (iMax - iCur) : iVal;
    cs_set_user_bpammo(id, iWpnID, iCur + iTake);
    new szAmmoName[MAX_PLAYERS];
    GetCaliberName(iWpnID, szAmmoName, charsmax(szAmmoName));
    set_hudmessage(200, 200, 200, -1.0, 0.8, 0, 0.1, 1.5, 0.1, 0.1, -1);
    show_hudmessage(id, "+%d %s Scavenged", iTake, szAmmoName);
    emit_sound(id, CHAN_ITEM, SOUND_PICKUP, 0.8, ATTN_NORM, 0, PITCH_NORM);
    return true;
}

GetMax(iWpn)
{
    switch (iWpn)
    {
        case CSW_M4A1, CSW_FAMAS, CSW_AUG, CSW_SG552, CSW_GALIL, CSW_AK47: return 90;
        case CSW_USP, CSW_MAC10, CSW_UMP45: return 100;
        case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: return 120;
        case CSW_DEAGLE: return 35;
        case CSW_AWP: return 30;
        case CSW_SCOUT: return 90;
        case CSW_FIVESEVEN, CSW_P90: return 100;
        case CSW_P228: return 52;
        case CSW_M3, CSW_XM1014: return 32;
        case CSW_M249: return 200;
    }
    return 0;
}

stock SpawnVisibleMag(id, iWpnID, iAmt)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(iEnt)) return;
    new szModelPath[96];
    if (BIT_9MM & (1<<iWpnID)) TrieGetString(g_tModels, "9mm", szModelPath, charsmax(szModelPath));
    else if (BIT_556NATO & (1<<iWpnID)) TrieGetString(g_tModels, "556", szModelPath, charsmax(szModelPath));
    else if (BIT_762NATO & (1<<iWpnID)) TrieGetString(g_tModels, "762", szModelPath, charsmax(szModelPath));
    else if (BIT_50AE & (1<<iWpnID)) TrieGetString(g_tModels, "50ae", szModelPath, charsmax(szModelPath));
    else if (BIT_338LAPUA & (1<<iWpnID)) TrieGetString(g_tModels, "338", szModelPath, charsmax(szModelPath));
    else TrieGetString(g_tModels, "default", szModelPath, charsmax(szModelPath));
    set_pev(iEnt, pev_groupinfo, PEV_GROUP_MAG);
    engfunc(EngFunc_SetModel, iEnt, szModelPath);
    new Float:vOrigin[3], Float:vVel[3], Float:vAngle[3], Float:vSpin[3];
    pev(id, pev_origin, vOrigin); pev(id, pev_v_angle, vAngle);
    velocity_by_aim(id, 350, vVel);
    vVel[0] += random_float(-10.0, 10.0); vVel[1] += random_float(-10.0, 10.0); vVel[2] += 130.0;
    vOrigin[2] += 15.0;
    vSpin[0] = random_float(-250.0, 250.0); vSpin[1] = random_float(-250.0, 250.0); vSpin[2] = random_float(-250.0, 250.0);
    set_pev(iEnt, pev_origin, vOrigin); set_pev(iEnt, pev_velocity, vVel);
    set_pev(iEnt, pev_angles, vAngle); set_pev(iEnt, pev_avelocity, vSpin);
    set_pev(iEnt, pev_movetype, MOVETYPE_TOSS); set_pev(iEnt, pev_solid, SOLID_TRIGGER);
    set_pev(iEnt, pev_iuser1, iWpnID); set_pev(iEnt, pev_iuser2, iAmt);
    set_pev(iEnt, pev_fuser1, get_gametime() + 0.7);
    ApplyGlow(iEnt, iWpnID);
    set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
    engfunc(EngFunc_SetSize, iEnt, Float:{-3.0, -3.0, 0.0}, Float:{3.0, 3.0, 3.0});
}

stock ApplyGlow(iEnt, iWpnID)
{
    set_pev(iEnt, pev_renderfx, kRenderFxGlowShell);
    set_pev(iEnt, pev_renderamt, 18.0);
    new Float:fColor[3];
    if (BIT_9MM & (1<<iWpnID)) { fColor[0] = 50.0; fColor[1] = 50.0; fColor[2] = 255.0; }
    else if (BIT_556NATO & (1<<iWpnID)) { fColor[0] = 50.0; fColor[1] = 255.0; fColor[2] = 50.0; }
    else if (BIT_762NATO & (1<<iWpnID)) { fColor[0] = 255.0; fColor[1] = 50.0; fColor[2] = 50.0; }
    else if (BIT_50AE & (1<<iWpnID)) { fColor[0] = 255.0; fColor[1] = 215.0; fColor[2] = 0.0; }
    else if (BIT_338LAPUA & (1<<iWpnID)) { fColor[0] = 255.0; fColor[1] = 255.0; fColor[2] = 255.0; }
    else { fColor[0] = 200.0; fColor[1] = 200.0; fColor[2] = 200.0; }
    set_pev(iEnt, pev_rendercolor, fColor);
}

stock GetCaliberName(iWpn, szName[], iLen)
{
    if (BIT_9MM & (1<<iWpn)) copy(szName, iLen, "9mm");
    else if (BIT_556NATO & (1<<iWpn)) copy(szName, iLen, "5.56 NATO");
    else if (BIT_762NATO & (1<<iWpn)) copy(szName, iLen, "7.62 NATO");
    else if (BIT_50AE & (1<<iWpn)) copy(szName, iLen, ".50 AE");
    else if (BIT_338LAPUA & (1<<iWpn)) copy(szName, iLen, ".338 Lapua");
    else copy(szName, iLen, "Ammo");
}

bool:CheckCaliber(w1, w2)
{
    if (w1 == w2) return true;
    if ((BIT_9MM & (1<<w1)) && (BIT_9MM & (1<<w2))) return true;
    if ((BIT_556NATO & (1<<w1)) && (BIT_556NATO & (1<<w2))) return true;
    if ((BIT_762NATO & (1<<w1)) && (BIT_762NATO & (1<<w2))) return true;
    return false;
}

stock fm_find_ent_by_owner(index, const classname[], owner)
{
    new ent = index;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)))
    {
        if (pev(ent, pev_owner) == owner)
            return ent;
    }
    return 0;
}
