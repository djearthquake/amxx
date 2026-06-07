#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define PLUGIN  "Ammo Pool Separator"
#define VERSION "0.5"
#define AUTHOR  "SPiNX"

#define m_rgAmmo_Player 376
#define MAX_AMMO_SLOTS 15

static g_iStoredSecondary[MAX_PLAYERS + 1][MAX_AMMO_SLOTS];
static g_iStoredPrimary[MAX_PLAYERS + 1][MAX_AMMO_SLOTS];
static g_iLastWeapon[MAX_PLAYERS + 1];
static bool:g_bIgnoreSync[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_event("CurWeapon", "event_CurWeapon", "be", "1=1");
    register_event("AmmoX", "event_AmmoX", "be");

    register_clcmd("buyammo1", "CmdBlockBuy");
    register_clcmd("buyammo2", "CmdBlockBuy");
    register_clcmd("cl_buyammo", "CmdBlockBuy");
}

public client_command(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
        return PLUGIN_CONTINUE;

    // Sized as a clean text array string block to pass data smoothly
    new szCmd[32];
    read_argv(0, szCmd, charsmax(szCmd));

    // FIXED: Evaluates the absolute first character of the string array to fire cases perfectly
    switch (szCmd[0])
    {
        case 's': // Tracks "secammo" safely without string pointer mismatches
        {
            if (equal(szCmd, "secammo"))
            {
                ForceMacroTopOff(id, false);
                return PLUGIN_HANDLED;
            }
        }
        case 'p': // Tracks "primammo" safely without string pointer mismatches
        {
            if (equal(szCmd, "primammo"))
            {
                ForceMacroTopOff(id, true);
                return PLUGIN_HANDLED;
            }
        }
    }

    return PLUGIN_CONTINUE;
}

GetWeaponAmmoSlot(iWpnID)
{
    switch (iWpnID)
    {
        case CSW_FIVESEVEN, CSW_P90: return 7;
        case CSW_USP, CSW_MAC10, CSW_UMP45: return 8;
        case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: return 10;
    }
    return 0;
}

GetWeaponMaxReserve(iWpnID)
{
    switch (iWpnID)
    {
        case CSW_FIVESEVEN: return 40;
        case CSW_USP: return 24;
        case CSW_GLOCK18: return 40;
        case CSW_P90: return 100;
        case CSW_UMP45: return 50;
        case CSW_MAC10: return 100;
        case CSW_MP5NAVY, CSW_TMP, CSW_ELITE: return 60;
    }
    return 90;
}

public CmdBlockBuy(id)
{
    if (!is_user_connected(id) || !is_user_alive(id)) return PLUGIN_CONTINUE;

    new iWeapon = get_user_weapon(id);
    new iSlot = GetWeaponAmmoSlot(iWeapon);
    if (iSlot <= 0) return PLUGIN_CONTINUE;

    new iCurrentVal = 0;
    if (cstrike_user_has_primary(id) && iWeapon == get_user_primary_id(id))
    {
        iCurrentVal = g_iStoredPrimary[id][iSlot];
    }
    else
    {
        iCurrentVal = g_iStoredSecondary[id][iSlot];
    }

    if (iCurrentVal <= 0)
    {
        iCurrentVal = get_pdata_int(id, m_rgAmmo_Player + iSlot, 5);
    }

    if (iCurrentVal >= GetWeaponMaxReserve(iWeapon))
    {
        client_print(id, print_center, "Ammo limit reached max capacity");
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

public event_AmmoX(id)
{
    if (!is_user_connected(id) || !is_user_alive(id)) return;
    if (g_bIgnoreSync[id]) return;

    new iWeapon = get_user_weapon(id);
    new iSlot = GetWeaponAmmoSlot(iWeapon);
    if (iSlot <= 0) return;

    new iCurRawAmmo = get_pdata_int(id, m_rgAmmo_Player + iSlot, 5);
    new iMaxAllowed = GetWeaponMaxReserve(iWeapon);

    if (cstrike_user_has_primary(id) && iWeapon == get_user_primary_id(id))
    {
        g_iStoredPrimary[id][iSlot] = iCurRawAmmo;
    }
    else
    {
        g_iStoredSecondary[id][iSlot] = iCurRawAmmo;
    }

    if (iCurRawAmmo > iMaxAllowed)
    {
        g_bIgnoreSync[id] = true;
        set_pdata_int(id, m_rgAmmo_Player + iSlot, iMaxAllowed, 5);

        message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id);
        write_byte(iSlot);
        write_byte(iMaxAllowed);
        message_end();
        g_bIgnoreSync[id] = false;

        if (cstrike_user_has_primary(id) && iWeapon == get_user_primary_id(id))
        {
            g_iStoredPrimary[id][iSlot] = iMaxAllowed;
        }
        else
        {
            g_iStoredSecondary[id][iSlot] = iMaxAllowed;
        }
    }
}

ForceMacroTopOff(id, bool:bIsPrimaryRequest)
{
    static weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);

    for (new i = 0; i < num; i++)
    {
        new wpn_id = weapons[i];
        new iSlot = GetWeaponAmmoSlot(wpn_id);
        if (iSlot <= 0) continue;

        new bool:bIsCurrentPrimary = (wpn_id == get_user_primary_id(id));
        if (bIsPrimaryRequest != bIsCurrentPrimary) continue;

        new iMaxAllowed = GetWeaponMaxReserve(wpn_id);

        if (bIsCurrentPrimary)
        {
            g_iStoredPrimary[id][iSlot] = iMaxAllowed;
        }
        else
        {
            g_iStoredSecondary[id][iSlot] = iMaxAllowed;
        }

        if (get_user_weapon(id) == wpn_id)
        {
            g_bIgnoreSync[id] = true;
            set_pdata_int(id, m_rgAmmo_Player + iSlot, iMaxAllowed, 5);

            message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id);
            write_byte(iSlot);
            write_byte(iMaxAllowed);
            message_end();
            g_bIgnoreSync[id] = false;
        }
    }
}

public event_CurWeapon(id)
{
    if (!is_user_connected(id) || !is_user_alive(id)) return;

    static iWeapon;
    iWeapon = read_data(2);

    new iLastWpn = g_iLastWeapon[id];
    g_iLastWeapon[id] = iWeapon;

    new iSlot = GetWeaponAmmoSlot(iWeapon);
    if (iSlot <= 0) return;

    if (iLastWpn > 0 && iLastWpn != iWeapon && GetWeaponAmmoSlot(iLastWpn) == iSlot)
    {
        new iOldReserve = get_pdata_int(id, m_rgAmmo_Player + iSlot, 5);
        if (cstrike_user_has_primary(id) && iLastWpn == get_user_primary_id(id))
        {
            g_iStoredPrimary[id][iSlot] = iOldReserve;
        }
        else
        {
            g_iStoredSecondary[id][iSlot] = iOldReserve;
        }
    }

    new iNewReserve = 0;
    if (cstrike_user_has_primary(id) && iWeapon == get_user_primary_id(id))
    {
        iNewReserve = g_iStoredPrimary[id][iSlot];
    }
    else
    {
        iNewReserve = g_iStoredSecondary[id][iSlot];
    }

    if (iNewReserve <= 0)
    {
        iNewReserve = get_pdata_int(id, m_rgAmmo_Player + iSlot, 5);
    }

    new iMaxAllowed = GetWeaponMaxReserve(iWeapon);
    if (iNewReserve > iMaxAllowed)
    {
        iNewReserve = iMaxAllowed;
    }

    g_bIgnoreSync[id] = true;
    set_pdata_int(id, m_rgAmmo_Player + iSlot, iNewReserve, 5);

    message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id);
    write_byte(iSlot);
    write_byte(iNewReserve);
    message_end();
    g_bIgnoreSync[id] = false;
}

public client_putinserver(id)
{
    g_iLastWeapon[id] = 0;
    g_bIgnoreSync[id] = false;
    for (new i = 0; i < MAX_AMMO_SLOTS; i++)
    {
        g_iStoredSecondary[id][i] = 0;
        g_iStoredPrimary[id][i] = 0;
    }
}

get_user_primary_id(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
    {
        return 0;
    }

    static weapons[MAX_PLAYERS], num;
    get_user_weapons(id, weapons, num);
    for (new i = 0; i < num; i++)
    {
        new w = weapons[i];
        if ((1<<w) & ((1<<CSW_P90)|(1<<CSW_UMP45)|(1<<CSW_MAC10)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)))
        {
            return w;
        }
    }
    return 0;
}

bool:cstrike_user_has_primary(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
    {
        return false;
    }

    return (get_user_primary_id(id) > 0);
}
