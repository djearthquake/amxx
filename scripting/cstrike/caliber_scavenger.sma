#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Caliber Scavenger"
#define VERSION "1.1"
#define AUTHOR "SPiNX"

#define m_pPlayer 41
#define m_iId 43
#define m_iClip 51
#define m_fInReload 54
#define linux_diff_weapon 4
#define PEV_GROUP_MAG 8812

#define BIT_45ACP (1<<CSW_USP|1<<CSW_MAC10|1<<CSW_UMP45)
#define BIT_9MM (1<<CSW_GLOCK18|1<<CSW_MP5NAVY|1<<CSW_TMP|1<<CSW_ELITE)
#define BIT_556NATO (1<<CSW_GALIL|1<<CSW_FAMAS|1<<CSW_M4A1|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_M249|1<<CSW_SG550)
#define BIT_762NATO (1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_G3SG1)
#define BIT_50AE (1<<CSW_DEAGLE)
#define BIT_338LAPUA (1<<CSW_AWP)
#define BIT_57MM (1<<CSW_P90|1<<CSW_FIVESEVEN)
#define BIT_357SIG (1<<CSW_P228)

new Trie:g_tModels, Trie:g_tGlow;
new g_pcvar_cleanup, g_pMaxMags, g_pcvar_toss;
static const SOUND_PICKUP[] = "items/9mmclip1.wav";

static const g_szMagWeapons[][] =
{
	"weapon_famas", "weapon_m4a1", "weapon_aug", "weapon_sg552", "weapon_galil",
	"weapon_usp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_tmp",
	"weapon_glock18", "weapon_elite", "weapon_ak47", "weapon_scout", "weapon_g3sg1",
	"weapon_deagle", "weapon_awp", "weapon_p228", "weapon_fiveseven", "weapon_p90", "weapon_m249"
};

public plugin_precache()
{
	g_tModels = TrieCreate();
	g_tGlow = TrieCreate();

	new szConfigDir[64], szFilePath[128];
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	formatex(szFilePath, charsmax(szFilePath), "%s/magazine_models.ini", szConfigDir);

	if (!file_exists(szFilePath))
	{
		new iFile = fopen(szFilePath, "wt");
		if (iFile)
		{
			fputs(iFile, "; Magazine Caliber Config^n; format: caliber = model | R G B^n");
			fputs(iFile, "9mm = models/w_9mmclip.mdl | 0 255 0^n");
			fputs(iFile, "45acp = models/w_9mmclip.mdl | 0 0 255^n");
			fputs(iFile, "50ae = models/w_9mmclip.mdl | 255 0 0^n");
			fputs(iFile, "57mm = models/w_9mmclip.mdl | 255 255 0^n");
			fputs(iFile, "338lapua = models/w_9mmclip.mdl | 255 0 255^n");
			fputs(iFile, "default = models/w_9mmclip.mdl | 255 255 255^n");
			fclose(iFile);
		}
	}

	new iFile = fopen(szFilePath, "rt");
	if (iFile)
	{
		new szData[128], szKey[32], szVal[96], szModel[64], szColor[32];
		while (!feof(iFile))
		{
			fgets(iFile, szData, charsmax(szData)); trim(szData);
			if (!szData[0] || szData[0] == ';' || szData[0] == '#') continue;

			strtok(szData, szKey, charsmax(szKey), szVal, charsmax(szVal), '=');
			trim(szKey); trim(szVal);

			if (szVal[0])
			{
				strtok(szVal, szModel, charsmax(szModel), szColor, charsmax(szColor), '|');
				trim(szModel); trim(szColor);

				if (file_exists(szModel))
				{
					TrieSetString(g_tModels, szKey, szModel);
					precache_model(szModel);
					if (szColor[0]) TrieSetString(g_tGlow, szKey, szColor);
				}
			}
		}
		fclose(iFile);
	}
	precache_sound(SOUND_PICKUP);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	g_pcvar_cleanup = register_cvar("amx_mag_cleanup", "1");
	g_pMaxMags = register_cvar("amx_reload_max_mags", "3");
	g_pcvar_toss = register_cvar("amx_mag_toss_speed", "175.0");

	RegisterHam(Ham_Touch, "info_target", "OnMagTouch");
	register_forward(FM_Think, "OnMagThink");
	register_logevent("OnRoundEnd", 2, "1=Round_End");

	for (new i = 0; i < sizeof(g_szMagWeapons); i++)
	{
		RegisterHam(Ham_Weapon_Reload, g_szMagWeapons[i], "OnReloadPre", 0);
	}
}

public OnReloadPre(const iWeapon)
{
	if (!pev_valid(iWeapon)) return HAM_IGNORED;
	new id = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
	if (!is_user_alive(id) || get_pdata_int(iWeapon, m_fInReload, linux_diff_weapon)) return HAM_IGNORED;

	new iWpnID = get_pdata_int(iWeapon, m_iId, linux_diff_weapon);
	new iClip = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);

	if (iClip > 0 && iClip < GetMaxClip(iWpnID) && cs_get_user_bpammo(id, iWpnID) > 0)
	{
		SpawnVisibleMag(id, iWpnID, iClip);
		set_pdata_int(iWeapon, m_iClip, 0, linux_diff_weapon);
	}
	return HAM_IGNORED;
}

public OnMagTouch(iEnt, id)
{
	if (!pev_valid(iEnt) || !is_user_alive(id) || pev(iEnt, pev_groupinfo) != PEV_GROUP_MAG) return;

	if (Float:pev(iEnt, pev_fuser1) > get_gametime()) return;

	new iMagWpnID = pev(iEnt, pev_iuser1);
	new iMagAmt = pev(iEnt, pev_iuser2);
	new iWeapons = pev(id, pev_weapons);

	for (new iWpn = CSW_P228; iWpn <= CSW_P90; iWpn++)
	{
		if ((iWeapons & (1<<iWpn)) && CheckCaliber(iMagWpnID, iWpn))
		{
			if (ApplyAmmo(id, iWpn, iMagAmt))
			{
				engfunc(EngFunc_RemoveEntity, iEnt);
				return;
			}
		}
	}
}

bool:ApplyAmmo(id, iWpnID, iVal)
{
	new iMax = GetMaxBP(iWpnID) * get_pcvar_num(g_pMaxMags);
	new iCur = cs_get_user_bpammo(id, iWpnID);
	if (iCur >= iMax) return false;

	new iTake = (iVal < (iMax - iCur)) ? iVal : (iMax - iCur);
	cs_set_user_bpammo(id, iWpnID, iCur + iTake);

	new szName[32]; GetCaliberName(iWpnID, szName, charsmax(szName));
	set_hudmessage(0, 255, 0, -1.0, 0.8, 0, 0.1, 2.0, 0.1, 0.1, -1);
	show_hudmessage(id, "+%d %s Scavenged", iTake, szName);
	emit_sound(id, CHAN_ITEM, SOUND_PICKUP, 0.8, ATTN_NORM, 0, PITCH_NORM);
	return true;
}

bool:CheckCaliber(w1, w2)
{
	if (w1 == w2) return true;
	if ((BIT_50AE & (1<<w1)) && (BIT_50AE & (1<<w2))) return true;
	if ((BIT_45ACP & (1<<w1)) && (BIT_45ACP & (1<<w2))) return true;
	if ((BIT_9MM & (1<<w1)) && (BIT_9MM & (1<<w2))) return true;
	if ((BIT_556NATO & (1<<w1)) && (BIT_556NATO & (1<<w2))) return true;
	if ((BIT_762NATO & (1<<w1)) && (BIT_762NATO & (1<<w2))) return true;
	if ((BIT_338LAPUA & (1<<w1)) && (BIT_338LAPUA & (1<<w2))) return true;
	if ((BIT_57MM & (1<<w1)) && (BIT_57MM & (1<<w2))) return true;
	if ((BIT_357SIG & (1<<w1)) && (BIT_357SIG & (1<<w2))) return true;
	return false;
}

stock SpawnVisibleMag(id, iWpnID, iAmt)
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	if (!pev_valid(iEnt)) return;

	new szKey[32], szModel[64], szColor[32];
	if (BIT_50AE & (1<<iWpnID)) copy(szKey, charsmax(szKey), "50ae");
	else if (BIT_45ACP & (1<<iWpnID)) copy(szKey, charsmax(szKey), "45acp");
	else if (BIT_9MM & (1<<iWpnID)) copy(szKey, charsmax(szKey), "9mm");
	else if (BIT_57MM & (1<<iWpnID)) copy(szKey, charsmax(szKey), "57mm");
	else if (BIT_338LAPUA & (1<<iWpnID)) copy(szKey, charsmax(szKey), "338lapua");
	else copy(szKey, charsmax(szKey), "default");

	if (!TrieGetString(g_tModels, szKey, szModel, charsmax(szModel)))
		TrieGetString(g_tModels, "default", szModel, charsmax(szModel));

	set_pev(iEnt, pev_classname, "scavenger_mag");
	set_pev(iEnt, pev_groupinfo, PEV_GROUP_MAG);
	engfunc(EngFunc_SetModel, iEnt, szModel);

	if (TrieGetString(g_tGlow, szKey, szColor, charsmax(szColor)))
	{
		new szR[4], szG[4], szB[4], Float:vCol[3];
		parse(szColor, szR, 3, szG, 3, szB, 3);
		vCol[0] = str_to_float(szR); vCol[1] = str_to_float(szG); vCol[2] = str_to_float(szB);
		set_pev(iEnt, pev_renderfx, kRenderFxGlowShell);
		set_pev(iEnt, pev_renderamt, 16.0);
		set_pev(iEnt, pev_rendercolor, vCol);
	}

	new Float:vOrg[3], Float:vVel[3], Float:vAng[3], Float:vSpin[3], Float:vForward[3];
	pev(id, pev_origin, vOrg); pev(id, pev_v_angle, vAng);
	velocity_by_aim(id, 35, vForward);
	vOrg[0] += vForward[0] * 2.0; vOrg[1] += vForward[1] * 2.0; vOrg[2] += 15.0;

	velocity_by_aim(id, floatround(get_pcvar_float(g_pcvar_toss)), vVel);
	vVel[0] += random_float(-10.0, 10.0); vVel[1] += random_float(-10.0, 10.0); vVel[2] += 220.0;

	vSpin[0] = random_float(-250.0, 250.0); vSpin[1] = random_float(-250.0, 250.0); vSpin[2] = random_float(-250.0, 250.0);

	set_pev(iEnt, pev_origin, vOrg); set_pev(iEnt, pev_velocity, vVel);
	set_pev(iEnt, pev_angles, vAng); set_pev(iEnt, pev_avelocity, vSpin);
	set_pev(iEnt, pev_movetype, MOVETYPE_TOSS); set_pev(iEnt, pev_solid, SOLID_TRIGGER);
	set_pev(iEnt, pev_iuser1, iWpnID); set_pev(iEnt, pev_iuser2, iAmt);
	set_pev(iEnt, pev_fuser1, get_gametime() + 0.8); set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
	engfunc(EngFunc_SetSize, iEnt, Float:{-3.0, -3.0, 0.0}, Float:{3.0, 3.0, 3.0});
}

public OnMagThink(iEnt)
{
	if (!pev_valid(iEnt) || pev(iEnt, pev_groupinfo) != PEV_GROUP_MAG) return FMRES_IGNORED;
	new Float:vVel[3]; pev(iEnt, pev_velocity, vVel);
	if (vector_length(vVel) > 15.0)
	{
		if (pev(iEnt, pev_flags) & FL_ONGROUND)
		{
			vVel[0] *= 0.4; vVel[1] *= 0.4; vVel[2] = 85.0;
			set_pev(iEnt, pev_velocity, vVel);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & ~FL_ONGROUND);
			new Float:vSpin[3]; vSpin[0] = random_float(-150.0, 150.0); vSpin[1] = random_float(-150.0, 150.0); vSpin[2] = random_float(-150.0, 150.0);
			set_pev(iEnt, pev_avelocity, vSpin);
		}
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
	}
	else set_pev(iEnt, pev_avelocity, Float:{0.0, 0.0, 0.0});
	return FMRES_HANDLED;
}

GetMaxClip(iWpn)
{
	switch(iWpn)
	{
		case CSW_P90: return 50;
		case CSW_M249: return 100;
		case CSW_GALIL: return 35;
		case CSW_AK47, CSW_M4A1, CSW_FAMAS, CSW_AUG, CSW_SG552, CSW_MP5NAVY, CSW_TMP, CSW_MAC10, CSW_ELITE: return 30;
		case CSW_UMP45: return 25;
		case CSW_GLOCK18, CSW_FIVESEVEN: return 20;
		case CSW_P228: return 13;
		case CSW_USP: return 12;
		case CSW_SCOUT, CSW_AWP: return 10;
		case CSW_DEAGLE: return 7;
	}
	return 30;
}

GetMaxBP(iWpn)
{
	switch(iWpn)
	{
		case CSW_AK47, CSW_M4A1, CSW_FAMAS, CSW_AUG, CSW_SG552, CSW_GALIL, CSW_MP5NAVY, CSW_TMP, CSW_ELITE, CSW_GLOCK18: return 30;
		case CSW_USP, CSW_MAC10, CSW_UMP45: return 12;
		case CSW_DEAGLE: return 7;
		case CSW_AWP, CSW_SCOUT: return 10;
		case CSW_P228: return 13;
		case CSW_FIVESEVEN, CSW_P90: return 50;
		case CSW_M249: return 100;
	}
	return 30;
}

stock GetCaliberName(iWpn, szName[], iLen)
{
	if (BIT_50AE & (1<<iWpn)) copy(szName, iLen, ".50 AE");
	else if (BIT_45ACP & (1<<iWpn)) copy(szName, iLen, ".45 ACP");
	else if (BIT_9MM & (1<<iWpn)) copy(szName, iLen, "9mm");
	else if (BIT_556NATO & (1<<iWpn)) copy(szName, iLen, "5.56 NATO");
	else if (BIT_762NATO & (1<<iWpn)) copy(szName, iLen, "7.62 NATO");
	else if (BIT_338LAPUA & (1<<iWpn)) copy(szName, iLen, ".338 Lapua");
	else if (BIT_57MM & (1<<iWpn)) copy(szName, iLen, "5.7mm");
	else if (BIT_357SIG & (1<<iWpn)) copy(szName, iLen, ".357 SIG");
	else copy(szName, iLen, "Ammo");
}

public OnRoundEnd()
{
	if (!get_pcvar_num(g_pcvar_cleanup)) return;
	new iEnt = -1;
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "scavenger_mag")))
		if (pev_valid(iEnt)) engfunc(EngFunc_RemoveEntity, iEnt);
}
