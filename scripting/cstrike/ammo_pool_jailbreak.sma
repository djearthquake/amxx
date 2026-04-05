#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Ammo Pool Separator"
#define VERSION "0.3"
#define AUTHOR  "SPiNX"

static g_iWeaponReserveBullets[MAX_PLAYERS + 1][CSW_P90 + 1];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_event("AmmoX", "event_AmmoX", "be");
    register_event("CurWeapon", "event_CurWeapon", "be", "1=1");
}

public event_AmmoX(id)
{
    static iWeapon;
    iWeapon = get_user_weapon(id);

    if (iWeapon > 0 && iWeapon <= CSW_P90)
    {
        g_iWeaponReserveBullets[id][iWeapon] = cs_get_user_bpammo(id, iWeapon);
    }
}

public event_CurWeapon(id)
{
    if (!is_user_alive(id)) return;

    static iWeapon;
    iWeapon = read_data(2);

    if (iWeapon > 0 && iWeapon <= CSW_P90)
    {
        cs_set_user_bpammo(id, iWeapon, g_iWeaponReserveBullets[id][iWeapon]);
    }
}

public client_putinserver(id)
{
    for (new i = 0; i <= CSW_P90; i++) g_iWeaponReserveBullets[id][i] = 0;
}
