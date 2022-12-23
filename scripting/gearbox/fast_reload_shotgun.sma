#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>


const m_flNextAttack   = 151
new const gShotgunClassname[] = "weapon_shotgun";

const MAX_CLIENTS          = 32;
const LINUX_OFFSET_WEAPONS = 4;


/* VARIABLES */
new
    gOldClip         [ MAX_CLIENTS + 1 char ],
    gOldSpecialReload[ MAX_CLIENTS + 1 char ],
    m_pPlayer ,
    m_flPumptime ,
    m_fInSpecialReload ,
    m_flNextPrimaryAttack ,
    m_flNextSecondaryAttack ,
    m_flTimeWeaponIdle ,
    m_iClip;
    //m_flNextAttack ;

public plugin_init()
{

    register_plugin( "OF Street Sweeper", "1.0.1", "SPiNX" ); //originally "Shotgun Reload/Fire Rate", "1.0.0", "Arkshine"
 
    RegisterHam( Ham_Weapon_PrimaryAttack  , gShotgunClassname, "Shotgun_PrimaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_PrimaryAttack  , gShotgunClassname, "Shotgun_PrimaryAttack_Post", 1 );
    /*
    RegisterHam( Ham_Weapon_SecondaryAttack, gShotgunClassname, "Shotgun_SecondaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_SecondaryAttack, gShotgunClassname, "Shotgun_SecondaryAttack_Post", 1 );
    */
    RegisterHam( Ham_Weapon_Reload         , gShotgunClassname, "Shotgun_Reload_Pre" , 0 );
    RegisterHam( Ham_Weapon_Reload         , gShotgunClassname, "Shotgun_Reload_Post", 1 );

    m_pPlayer = (find_ent_data_info("CBasePlayerItem", "m_pPlayer") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS

    m_flPumptime = (find_ent_data_info("CBasePlayerWeapon", "m_flPumpTime") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_fInSpecialReload = (find_ent_data_info("CBasePlayerWeapon", "m_fInSpecialReload") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_flNextPrimaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextPrimaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_flNextSecondaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextSecondaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_flTimeWeaponIdle= (find_ent_data_info("CBasePlayerWeapon", "m_flTimeWeaponIdle") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_iClip = (find_ent_data_info("CBasePlayerWeapon", "m_iClip") / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS

    //m_flNextAttack = find_ent_data_info("CBasePlayerWeapon", "m_flNextAttack" / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS

    log_amx "%i |%i |%i |%i |%i |%i |%i |", m_pPlayer, m_flPumptime, m_fInSpecialReload, m_flNextPrimaryAttack, m_flNextSecondaryAttack, m_iClip, m_flNextAttack
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

    set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.05, LINUX_OFFSET_WEAPONS );
    //set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.6, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( shotgun, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 2.0, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( shotgun, m_flTimeWeaponIdle, 0.3, LINUX_OFFSET_WEAPONS );
    }
    
    
    new Float:g_fDelay = 0.1
    #define m_flNextPrimaryAttackB 46
    #define m_flNextSecondaryAttackB 47

    if ( pev_valid(shotgun)>1)
    {
        set_pdata_float(shotgun, m_flNextPrimaryAttackB, g_fDelay, LINUX_OFFSET_WEAPONS)
        set_pdata_float(shotgun, m_flNextSecondaryAttackB, g_fDelay, LINUX_OFFSET_WEAPONS)
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
