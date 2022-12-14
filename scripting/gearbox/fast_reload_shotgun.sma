#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#define OP4

#if defined OP4
    #define OP4_OFFSET 3
#else
    #define OP4_OFFSET 0
#endif

/* WEAPONS HL OFFSETS */

    const m_pPlayer               = 28 + OP4_OFFSET
    const m_flPumptime            = 33 + OP4_OFFSET
    const m_fInSpecialReload      = 34 + OP4_OFFSET
    const m_flNextPrimaryAttack   = 35 + OP4_OFFSET
    const m_flNextSecondaryAttack = 36 + OP4_OFFSET
    const m_flTimeWeaponIdle      = 37 + OP4_OFFSET
    const m_iClip                 = 40 + OP4_OFFSET

/* PLAYER HL OFFSETS */
    const m_flNextAttack   = 148 + OP4_OFFSET

 /* CONSTANTS */

    new const gShotgunClassname[] = "weapon_shotgun";

    const MAX_CLIENTS          = 32;
    const LINUX_OFFSET_WEAPONS = 4;

/* VARIABLES */

    new gOldClip         [ MAX_CLIENTS + 1 char ];
    new gOldSpecialReload[ MAX_CLIENTS + 1 char ];


public plugin_init()
{

    register_plugin( "Shotgun Reload/Fire Rate", "1.0.0", "Arkshine" );

    RegisterHam( Ham_Weapon_PrimaryAttack  , gShotgunClassname, "Shotgun_PrimaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_PrimaryAttack  , gShotgunClassname, "Shotgun_PrimaryAttack_Post", 1 );
    RegisterHam( Ham_Weapon_SecondaryAttack, gShotgunClassname, "Shotgun_SecondaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_SecondaryAttack, gShotgunClassname, "Shotgun_SecondaryAttack_Post", 1 );
    RegisterHam( Ham_Weapon_Reload         , gShotgunClassname, "Shotgun_Reload_Pre" , 0 );
    RegisterHam( Ham_Weapon_Reload         , gShotgunClassname, "Shotgun_Reload_Post", 1 );
}

public Shotgun_PrimaryAttack_Pre ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Shotgun_PrimaryAttack_Post ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if ( gOldClip{ player } <= 0 )
    {
        return;
    }

    set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.6, LINUX_OFFSET_WEAPONS );
    set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.6, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 2.0, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.3, LINUX_OFFSET_WEAPONS );
    }
}

public Shotgun_SecondaryAttack_Pre ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Shotgun_SecondaryAttack_Post ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if ( gOldClip{ player } <= 1 )
    {
        return;
    }

    set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS );
    set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.8, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 3.0, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.85, LINUX_OFFSET_WEAPONS );
    }
}

public Shotgun_Reload_Pre ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldSpecialReload{ player } = get_pdata_int( shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS );
}

public Shotgun_Reload_Post ( const shotgun )
{
    new player = get_pdata_cbase( shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS );

    switch ( gOldSpecialReload{ player } )
    {
        case 0 :
        {
            if ( get_pdata_int( shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 1 )
            {
                set_pdata_float( player , m_flNextAttack, 0.3 );

                set_pdata_float( shotgun, m_flTimeWeaponIdle     , 0.1, LINUX_OFFSET_WEAPONS );
                set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS );
                set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS );
            }
        }
        case 1 :
        {
            if ( get_pdata_int( shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 2 )
            {
                set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.1, LINUX_OFFSET_WEAPONS );
            }
        }
    }
}
