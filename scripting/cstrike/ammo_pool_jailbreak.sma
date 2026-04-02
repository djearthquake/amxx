#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Ammo Pool Jailbreak"
#define VERSION "0.1"
#define AUTHOR  "SPiNX"

#define m_fWeaponState 74
#define m_pActiveItem 373

new g_iIsBot;
new g_iWeaponReserveBullets[MAX_PLAYERS + 1][CSW_P90 + 1];
new g_iSyncHud;
new g_pCvarPersist;
new g_iLastClip[MAX_PLAYERS + 1];
new g_iAwaitingAck;

static const g_iMaxClip[] =
{
    0, 13, 0, 10, 0, 7, 0, 30, 30, 0, 30, 20, 25, 30, 35, 25,
    12, 20, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50
};

static const g_szBuyCommands[][] =
{
    "buyammo1", "buyammo2", "primammo", "secammo"
};

stock get_max_mags(id, iId)
{
    switch (iId)
    {
        case CSW_AWP: return 2;
        case CSW_M4A1:
        {
            new iEnt = get_pdata_cbase(id, m_pActiveItem);
            if (pev_valid(iEnt) && (get_pdata_int(iEnt, m_fWeaponState, 4) & (1<<0)))
            {
                return 3;
            }
            return 4;
        }
        case CSW_GALIL: return 4;
        case CSW_DEAGLE: return 3;
        case CSW_P90, CSW_M249: return 2;
    }
    return 3;
}

stock get_fill_meter(iCur, iMax, szOut[], iLen)
{
    copy(szOut, iLen, "----------");
    if (iMax <= 0) return;
    new iDots = (iCur * 10) / iMax;
    if (iDots > 10) iDots = 10;
    for (new i = 0; i < iDots; i++) szOut[i] = '|';
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    g_iSyncHud = CreateHudSyncObj();
    g_pCvarPersist = register_cvar("amx_jailbreak_hud_persist", "1");

    register_event("CurWeapon", "event_CurWeapon", "be", "1=1");
    register_event("AmmoPickup", "event_AmmoPickup", "be");

    for (new i = 0; i < sizeof g_szBuyCommands; i++)
    {
        register_clcmd(g_szBuyCommands[i], "cmd_BlockAmmo");
    }

    register_clcmd("say y", "cmd_Acknowledge");
    register_clcmd("say_team y", "cmd_Acknowledge");

    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);

    static szWpnName[32];
    for (new iId = CSW_P228; iId <= CSW_P90; iId++)
    {
        if (get_weaponname(iId, szWpnName, charsmax(szWpnName)))
        {
            RegisterHam(Ham_Weapon_Reload, szWpnName, "fw_WeaponReload_Pre", 0);
            RegisterHam(Ham_Item_AddToPlayer, szWpnName, "fw_AddToPlayer_Post", 1);
        }
    }
}

public plugin_precache()
{
    precache_sound("weapons/dryfire1.wav");
}

public client_putinserver(id)
{
    if (is_user_bot(id))
    {
        g_iIsBot |= (1 << (id & 31));
        set_task(0.1, "task_RegisterBotHooks", id);
    }
}

public task_RegisterBotHooks(id)
{
    if (!is_user_connected(id)) return;
    RegisterHamFromEntity(Ham_Weapon_Reload, id, "fw_WeaponReload_Pre", 0);
    RegisterHamFromEntity(Ham_Item_AddToPlayer, id, "fw_AddToPlayer_Post", 1);
}

public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id) || (g_iIsBot & (1 << (id & 31)))) return;

    static bool:bFirstSpawn[MAX_PLAYERS + 1];
    if (!bFirstSpawn[id])
    {
        set_task(1.0, "task_StartBriefing", id);
        bFirstSpawn[id] = true;
    }
}

public task_StartBriefing(id)
{
    if (!is_user_alive(id)) return;

    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
    g_iAwaitingAck |= (1 << (id & 31));

    client_print_color(id, print_team_default, "^4[JAILBREAK] ^3SYSTEM OVERHAUL ACTIVE.");
    client_print_color(id, print_team_default, "^4[JAILBREAK] ^1Every ^3Reload ^1discards your magazine.");
    client_print_color(id, print_team_default, "^4[JAILBREAK] ^1Ammo pools are now ^3Independent^1.");
    client_print_color(id, print_team_default, "^4[JAILBREAK] ^1Type ^3'y' ^1in chat to acknowledge and release.");
}

public cmd_Acknowledge(id)
{
    if (g_iAwaitingAck & (1 << (id & 31)))
    {
        set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
        g_iAwaitingAck &= ~(1 << (id & 31));
        client_print_color(id, print_team_default, "^4[JAILBREAK] ^1Briefing accepted. ^3Good luck out there.");
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
    g_iIsBot &= ~(1 << (id & 31));
    g_iAwaitingAck &= ~(1 << (id & 31));
    for (new i = 0; i <= CSW_P90; i++) g_iWeaponReserveBullets[id][i] = 0;
}

public cmd_BlockAmmo(id)
{
    if (!is_user_alive(id)) return PLUGIN_CONTINUE;
    new iId = get_user_weapon(id);
    if (iId <= 0 || iId > CSW_P90) return PLUGIN_CONTINUE;

    new iMax = get_max_mags(id, iId) * g_iMaxClip[iId];
    if (g_iWeaponReserveBullets[id][iId] >= iMax)
    {
        client_print(id, print_center, "#Cstrike_Titles_B_Ammo_Full");
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public event_AmmoPickup(id)
{
    if (!is_user_alive(id)) return;
    new iId = get_user_weapon(id);
    if (iId <= 0 || iId > CSW_P90) return;

    new iAmt = read_data(2);
    new iMax = get_max_mags(id, iId) * g_iMaxClip[iId];
    g_iWeaponReserveBullets[id][iId] = min(g_iWeaponReserveBullets[id][iId] + iAmt, iMax);
}

public event_CurWeapon(id)
{
    if (!is_user_alive(id)) return;
    new iWeapon = read_data(2);
    new iClip = read_data(3);
    if (iWeapon <= 0 || iWeapon > CSW_P90 || g_iMaxClip[iWeapon] == 0) return;

    cs_set_user_bpammo(id, iWeapon, g_iWeaponReserveBullets[id][iWeapon]);

    if (!(g_iIsBot & (1 << (id & 31))))
    {
        new Float:fFadeOut = get_pcvar_num(g_pCvarPersist) ? 0.0 : 2.0;
        if (iClip <= 3)
        {
            set_hudmessage(255, 0, 0, 0.88, 0.90, 0, 0.0, 0.3, 0.0, fFadeOut, -1);
            if (iClip < g_iLastClip[id]) client_cmd(id, "spk weapons/dryfire1");
        }
        else set_hudmessage(255, 255, 255, 0.88, 0.90, 0, 0.0, 0.3, 0.0, fFadeOut, -1);

        g_iLastClip[id] = iClip;
        static szBar[11];
        get_fill_meter(iClip, g_iMaxClip[iWeapon], szBar, charsmax(szBar));
        ShowSyncHudMsg(id, g_iSyncHud, "MAGS: %d^n%s",
            g_iWeaponReserveBullets[id][iWeapon] / g_iMaxClip[iWeapon], szBar);
    }
}

public fw_AddToPlayer_Post(iEnt, iPlayer)
{
    if (!is_user_alive(iPlayer)) return;
    new iId = cs_get_weapon_id(iEnt);
    if (g_iWeaponReserveBullets[iPlayer][iId] == 0)
        g_iWeaponReserveBullets[iPlayer][iId] = get_max_mags(iPlayer, iId) * g_iMaxClip[iId];
}

public fw_WeaponReload_Pre(iEnt)
{
    new iPlayer = pev(iEnt, pev_owner);
    if (!is_user_alive(iPlayer)) return;
    new iId = cs_get_weapon_id(iEnt);
    new iClip = cs_get_weapon_ammo(iEnt);
    new iMax = g_iMaxClip[iId];

    if (iMax > 0 && g_iWeaponReserveBullets[iPlayer][iId] >= iMax && iClip < iMax)
    {
        cs_set_weapon_ammo(iEnt, 0);
        g_iWeaponReserveBullets[iPlayer][iId] -= iMax;
        cs_set_user_bpammo(iPlayer, iId, g_iWeaponReserveBullets[iPlayer][iId]);
    }
}
