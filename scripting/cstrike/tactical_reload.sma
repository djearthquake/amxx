#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Tactical Reload: Tension & Tradeoffs"
#define VERSION "1.1"
#define AUTHOR "SPiNX"

#define MAX_PLAYERS 32
#define OFFSET_LINUX 5
#define OFFSET_LINUX_WEAPONS 4
#define m_pActiveItem 373
#define m_flNextPrimaryAttack 46

static g_iBitIsBot, g_iBitIsSaving;
static Float:g_fHoldStart[MAX_PLAYERS+1], Float:g_fNextClick[MAX_PLAYERS+1], g_msgBarTime, g_sMagModel;
static g_pCvarEnabled;

#define set_bit(%1,%2)      (%1|=(1<<(%2&31)))
#define clear_bit(%1,%2)    (%1&=~(1<<(%2&31)))
#define get_bit(%1,%2)      (%1&(1<<(%2&31)))

static const GSZ_WEAPONS[][] =
{
    "weapon_p228", "weapon_scout", "weapon_xm1014", "weapon_mac10", "weapon_aug",
    "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
    "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy",
    "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
    "weapon_sg552", "weapon_ak47", "weapon_p90", "weapon_deagle"
};

public plugin_precache()
{
    g_sMagModel = precache_model("models/w_9mmclip.mdl");
    precache_sound("weapons/scout_bolt.wav");
    precache_sound("weapons/usp_sliderelease.wav");
    precache_sound("items/9mmclip1.wav");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    g_pCvarEnabled = register_cvar("amx_tactical_reload", "1");

    for(new i=0; i<sizeof(GSZ_WEAPONS); i++)
        RegisterHam(Ham_Item_PostFrame, GSZ_WEAPONS[i], "fw_PostFrame_Pre", 0);

    RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeaponBox");
    register_forward(FM_CmdStart, "fw_CmdStart");
    g_msgBarTime = get_user_msgid("BarTime");
}

public client_putinserver(id) is_user_bot(id) ? set_bit(g_iBitIsBot, id) : clear_bit(g_iBitIsBot, id);

public client_disconnected(id)
{
    clear_bit(g_iBitIsBot, id);
    clear_bit(g_iBitIsSaving, id);
}

public fw_CmdStart(id, uc_handle, seed)
{
    if(!get_pcvar_num(g_pCvarEnabled) || !is_user_alive(id))
        return FMRES_IGNORED;

    static iButtons, iOldButtons, iEnt, iWeaponID;
    iButtons = get_uc(uc_handle, UC_Buttons);
    iOldButtons = pev(id, pev_oldbuttons);
    iEnt = get_pdata_cbase(id, m_pActiveItem, OFFSET_LINUX);

    if(!pev_valid(iEnt)) return FMRES_IGNORED;
    iWeaponID = cs_get_weapon_id(iEnt);

    if((iButtons & IN_RELOAD) && !(iOldButtons & IN_RELOAD))
    {
        if(can_reload(iEnt, id))
        {
            g_fHoldStart[id] = get_gametime();
            set_bit(g_iBitIsSaving, id);
            util_show_bartime(id, floatround(get_weapon_bias(iWeaponID)));
            client_print(id, print_center, "HOLD TO SECURE MAGAZINE");
        }
    }

    if(get_bit(g_iBitIsSaving, id) && (iButtons & IN_RELOAD))
    {
        static Float:fCurTime;
        fCurTime = get_gametime();

        if(fCurTime >= g_fNextClick[id])
        {
            if(iWeaponID == CSW_AWP || iWeaponID == CSW_G3SG1 || iWeaponID == CSW_SG550)
            {
                emit_sound(id, CHAN_WEAPON, "weapons/scout_bolt.wav", 0.6, ATTN_NORM, 0, 85);
                g_fNextClick[id] = fCurTime + 0.7;
            }
            else
            {
                emit_sound(id, CHAN_WEAPON, "weapons/usp_sliderelease.wav", 0.4, ATTN_NORM, 0, PITCH_NORM);
                g_fNextClick[id] = fCurTime + 0.4;
            }
        }

        if(fCurTime - g_fHoldStart[id] >= get_weapon_bias(iWeaponID))
        {
            clear_bit(g_iBitIsSaving, id);
            util_show_bartime(id, 0);
            emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM);
            ExecuteHamB(Ham_Weapon_Reload, iEnt);
        }
    }

    if(!(iButtons & IN_RELOAD) && (iOldButtons & IN_RELOAD) && get_bit(g_iBitIsSaving, id))
    {
        clear_bit(g_iBitIsSaving, id);
        util_show_bartime(id, 0);
        force_emergency_reload(id, iEnt);
    }
    return FMRES_IGNORED;
}

public fw_PostFrame_Pre(iEnt)
{
    static iPlayer;
    iPlayer = pev(iEnt, pev_owner);
    if(iPlayer > 0 && iPlayer <= MAX_PLAYERS && get_bit(g_iBitIsSaving, iPlayer))
        return HAM_SUPERCEDE;
    return HAM_IGNORED;
}

force_emergency_reload(id, iEnt)
{
    static iWeaponID, iClip, iBpAmmo;
    iWeaponID = cs_get_weapon_id(iEnt);
    if(iWeaponID != CSW_KNIFE | CSW_C4)
    {
        iClip = cs_get_weapon_ammo(iEnt);
        iBpAmmo = cs_get_user_bpammo(id, iWeaponID);
    
        if(iClip > 0 && iBpAmmo > 0)
        {
            cs_set_weapon_ammo(iEnt, 0);
            cs_set_user_bpammo(id, iWeaponID, iBpAmmo - iClip);
            spawn_mag_drop(id);
            client_print(id, print_center, "EMERGENCY RELOAD: Mag Dropped!");
        }
        set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.0, OFFSET_LINUX_WEAPONS);
        ExecuteHamB(Ham_Weapon_Reload, iEnt);
    }
}

Float:get_weapon_bias(iId)
{
    switch(iId)
    {
        case CSW_P228,CSW_ELITE,CSW_FIVESEVEN,CSW_USP,CSW_GLOCK18,CSW_DEAGLE: return 0.7;
        case CSW_AK47,CSW_M4A1,CSW_FAMAS,CSW_GALIL,CSW_AUG,CSW_SG552: return 1.6;
        case CSW_M249,CSW_G3SG1,CSW_SG550,CSW_AWP: return 2.8;
    }
    return 1.2;
}

spawn_mag_drop(id)
{
    static Float:vOrigin[3], Float:vVelocity[3];
    entity_get_vector(id, EV_VEC_origin, vOrigin);
    vOrigin[2] -= 10.0;
    vVelocity[0] = random_float(-50.0, 50.0);
    vVelocity[1] = random_float(-50.0, 50.0);
    vVelocity[2] = -100.0;

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_MODEL);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2]);
    engfunc(EngFunc_WriteCoord, vVelocity[0]);
    engfunc(EngFunc_WriteCoord, vVelocity[1]);
    engfunc(EngFunc_WriteCoord, vVelocity[2]);
    write_angle(random_num(0, 360));
    write_short(g_sMagModel);
    write_byte(1);
    write_byte(25);
    message_end();
}

public fw_TouchWeaponBox(iBox, id)
{
    if(!get_pcvar_num(g_pCvarEnabled) || !is_user_alive(id)) return HAM_IGNORED;
    for(new i = 0; i < 6; i++)
    {
        static iWeapon;
        iWeapon = get_pdata_cbase(iBox, 34 + i, OFFSET_LINUX_WEAPONS);
        if(pev_valid(iWeapon))
        {
            static iWeaponID;
            iWeaponID = cs_get_weapon_id(iWeapon);
            if(iWeaponID != CSW_KNIFE | CSW_C4)
            {
                if(user_has_weapon(id, iWeaponID))
                {
                    static iClip;
                    iClip = cs_get_weapon_ammo(iWeapon);
                    if(iClip > 0)
                    {
                        cs_set_user_bpammo(id, iWeaponID, cs_get_user_bpammo(id, iWeaponID) + iClip);
                        emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
                        set_pev(iBox, pev_flags, pev(iBox, pev_flags) | FL_KILLME);
                        return HAM_HANDLED;
                    }
                }
            }
        }
    }
    return HAM_IGNORED;
}

bool:can_reload(iEnt, id)
{
    if(!pev_valid(iEnt)) return false;
    static iId;
    iId = cs_get_weapon_id(iEnt);
    return (iId && cs_get_weapon_ammo(iEnt) < get_max_clip(iId) && cs_get_user_bpammo(id, iId) > 0);
}

get_max_clip(iId)
{
    switch(iId)
    {
        case CSW_P228:return 13; case CSW_SCOUT:return 10; case CSW_XM1014:return 7; case CSW_MAC10:return 32;
        case CSW_AUG:return 30; case CSW_ELITE:return 30; case CSW_FIVESEVEN:return 20; case CSW_UMP45:return 25;
        case CSW_SG550:return 30; case CSW_GALIL:return 35; case CSW_FAMAS:return 25; case CSW_USP:return 12;
        case CSW_GLOCK18:return 20; case CSW_AWP:return 10; case CSW_MP5NAVY:return 30; case CSW_M249:return 100;
        case CSW_M3:return 8; case CSW_M4A1:return 30; case CSW_TMP:return 30; case CSW_G3SG1:return 20;
        case CSW_SG552:return 30; case CSW_AK47:return 30; case CSW_P90:return 50; case CSW_DEAGLE:return 7;
    }
    return 0;
}

stock util_show_bartime(id, seconds)
{
    if(get_bit(g_iBitIsBot, id)) return;
    message_begin(MSG_ONE_UNRELIABLE, g_msgBarTime, _, id);
    write_short(seconds);
    message_end();
}
