#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Tactical Ammo Pool"
#define VERSION "0.2"
#define AUTHOR  "SPiNX"

// Linux Offsets
#define m_iClip 51
#define m_fInReload 54
#define XO_WEAPON 4

new g_iSyncHud;
new g_pCvarShowHud;

static g_iWeaponReserveBullets[MAX_PLAYERS + 1][CSW_P90 + 1];
static bool:g_bHasReceivedInitialAmmo[MAX_PLAYERS + 1][CSW_P90 + 1];

static const g_iMaxClip[] =
{
    0, 13, 0, 10, 0, 7, 0, 30, 30, 0, 30, 20, 25, 30, 35, 25,
    12, 20, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50
};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pCvarShowHud = register_cvar("amx_tactical_hud", "1");
    g_iSyncHud = CreateHudSyncObj();

    register_event("CurWeapon", "event_CurWeapon", "be", "1=1");

    static szWpnName[32];
    for (new iId = CSW_P228; iId <= CSW_P90; iId++)
    {
        if (get_weaponname(iId, szWpnName, charsmax(szWpnName)))
        {
            RegisterHam(Ham_Weapon_Reload, szWpnName, "fw_WeaponReload_Pre", 0);
            RegisterHam(Ham_Weapon_Reload, szWpnName, "fw_WeaponReload_Post", 1);
            RegisterHam(Ham_Item_AddToPlayer, szWpnName, "fw_AddToPlayer_Post", 1);
        }
    }
}

public fw_WeaponReload_Pre(iEnt)
{
    static iPlayer;
    iPlayer = pev(iEnt, pev_owner);

    if (!is_user_alive(iPlayer) || get_pdata_int(iEnt, m_fInReload, XO_WEAPON))
    {
        return HAM_IGNORED;
    }

    static iId;
    iId = cs_get_weapon_id(iEnt);
    static iMax;
    iMax = g_iMaxClip[iId];

    if (iMax > 0 && g_iWeaponReserveBullets[iPlayer][iId] >= iMax)
    {
        static iCurrentClip;
        iCurrentClip = get_pdata_int(iEnt, m_iClip, XO_WEAPON);

        if (iCurrentClip < iMax)
        {
            set_pdata_int(iEnt, m_iClip, 0, XO_WEAPON);
        }
    }
    return HAM_IGNORED;
}

public fw_WeaponReload_Post(iEnt)
{
    if (get_pdata_int(iEnt, m_fInReload, XO_WEAPON))
    {
        static iPlayer;
        iPlayer = pev(iEnt, pev_owner);
        static iId;
        iId = cs_get_weapon_id(iEnt);
        static iMax;
        iMax = g_iMaxClip[iId];

        if (g_iWeaponReserveBullets[iPlayer][iId] >= iMax)
        {
            g_iWeaponReserveBullets[iPlayer][iId] -= iMax;
            set_pdata_int(iEnt, m_iClip, iMax, XO_WEAPON);
            cs_set_user_bpammo(iPlayer, iId, g_iWeaponReserveBullets[iPlayer][iId]);
        }
    }
}

public fw_AddToPlayer_Post(iEnt, iPlayer)
{
    static iId;
    iId = cs_get_weapon_id(iEnt);

    if (iId <= 0 || iId > CSW_P90 || g_iMaxClip[iId] == 0)
    {
        return;
    }

    if (!g_bHasReceivedInitialAmmo[iPlayer][iId])
    {
        g_iWeaponReserveBullets[iPlayer][iId] = 3 * g_iMaxClip[iId];
        g_bHasReceivedInitialAmmo[iPlayer][iId] = true;
    }

    cs_set_user_bpammo(iPlayer, iId, g_iWeaponReserveBullets[iPlayer][iId]);
}

public event_CurWeapon(id)
{
    if (!is_user_alive(id))
    {
        return;
    }

    static iWeapon;
    iWeapon = read_data(2);

    // If it's a weapon we track, blank the stock numbers
    if (iWeapon > 0 && iWeapon <= CSW_P90 && g_iMaxClip[iWeapon] > 0)
    {
        cs_set_user_bpammo(id, iWeapon, g_iWeaponReserveBullets[id][iWeapon]);

        if (get_pcvar_num(g_pCvarShowHud))
        {
            blank_stock_ammo(id);

            static szMeter[12];
            static iClip, iMax, iR, iG;

            iClip = read_data(3);
            iMax = g_iMaxClip[iWeapon];

            magazine_meter(iClip, iMax, szMeter, charsmax(szMeter));

            if (iClip > (iMax / 2)) { iR = 0; iG = 255; }
            else if (iClip > (iMax / 4)) { iR = 255; iG = 255; }
            else { iR = 255; iG = 0; }

            set_hudmessage(iR, iG, 0, 0.88, 0.90, 0, 0.0, 0.3, 0.0, 0.0, -1);
            ShowSyncHudMsg(id, g_iSyncHud, "[%s] | %d", szMeter, g_iWeaponReserveBullets[id][iWeapon] / iMax);
        }
    }
}

stock magazine_meter(iCur, iMax, szOut[], iLen)
{
    copy(szOut, iLen, "----------");
    if (iMax <= 0) return;

    static iDots;
    iDots = clamp((iCur * 10) / iMax, 0, 10);

    for (new i = 0; i < iDots; i++)
    {
        szOut[i] = '|';
    }
}

stock blank_stock_ammo(id)
{
    // Sending -1 to Ammo tells the engine there is "no ammo" to display
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id);
    write_byte(1);
    write_byte(-1);
    message_end();
}

public client_putinserver(id)
{
    for (new i = 0; i <= CSW_P90; i++)
    {
        g_bHasReceivedInitialAmmo[id][i] = false;
    }
}
