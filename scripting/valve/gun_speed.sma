#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define charsmin                  -1

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;


/* VARIABLES */
new
    cvar, 
    gbCS ,
    gbDod , 
    gbSven ,
    gOldClip[ MAX_PLAYERS + 1 char ],
    gOldSpecialReload[ MAX_PLAYERS + 1 char ],
    m_pPlayer ,
    //m_flPumptime ,
    m_fInSpecialReload ,
    m_flNextPrimaryAttack ,
    m_flNextSecondaryAttack ,
    m_flTimeWeaponIdle ,
    m_iClip,
    m_flNextAttack,
    Float:g_Speed,
    gWeaponClassname[MAX_PLAYERS];

public plugin_init()
{
    register_plugin( "Gun Speed", "1.0.2", "SPiNX" ); //Credit "Weapon Reload/Fire Rate", "1.0.0", "Arkshine". That kicked me off.
    cvar = register_cvar("mp_fast_gun", "")
    bind_pcvar_string(cvar, gWeaponClassname, charsmax( gWeaponClassname))

    new mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name))
    server_print mod_name
    if(equal(mod_name, "cstrike") || equal(mod_name, "czero") )
    {
        gbCS = true
    }
    else if(equal(mod_name, "dod"))
    {
        gbDod = true
    }
    else if(containi(mod_name, "sven") > charsmin)
    {
        gbSven = true
    }
    if(gbSven)
    {
        //m_fInSpecialReload = (find_ent_data_info("CBasePlayerWeapon", "SpecialReload") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
        //SpecialReloadEiifi
    }
    else
    {
        m_flNextPrimaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextPrimaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
        m_pPlayer = (find_ent_data_info("CBasePlayerItem", gbSven ? "MyItemPointer" : "m_pPlayer") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
        m_fInSpecialReload = (find_ent_data_info("CBasePlayerWeapon", "m_fInSpecialReload") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
        RegisterHam( Ham_Weapon_Reload         , gWeaponClassname, "Weapon_Reload_Pre" , 0 );
        RegisterHam( Ham_Weapon_Reload         , gWeaponClassname, "Weapon_Reload_Post", 1 );
    }

    /*
    RegisterHam( Ham_Weapon_SecondaryAttack, gWeaponClassname, "Weapon_SecondaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_SecondaryAttack, gWeaponClassname, "Weapon_SecondaryAttack_Post", 1 );
    */

    //m_flPumptime = (find_ent_data_info(cstrike_running() ?  "CXM1014" : "CBasePlayerWeapon", "m_flPumpTime") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS


    RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_PrimaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_PrimaryAttack_Post", 1 );


    m_flNextSecondaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextSecondaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_flTimeWeaponIdle = (find_ent_data_info("CBasePlayerWeapon", "m_flTimeWeaponIdle") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_iClip = (find_ent_data_info("CBasePlayerWeapon", "m_iClip") / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS

    m_flNextAttack = (find_ent_data_info("CBaseMonster", "m_flNextAttack") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF

    bind_pcvar_float(get_cvar_pointer("mp_gunspeed") ? get_cvar_pointer("mp_gunspeed") : register_cvar("mp_gunspeed", "0.06"), g_Speed)
}

/*
public plugin_cfg()
{
    //recommended settings
    if(gbDod)
        return
    else if(gbCS)
        g_Speed = 0.1
    else
        g_Speed = 0.01
}
*/

public Weapon_PrimaryAttack_Pre ( const weapon )
{
    new player
    player = gbSven ? pev(weapon, pev_owner) : get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    //player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    
    gOldClip{ player } = get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Weapon_PrimaryAttack_Post ( const weapon )
{
    //new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    new player = gbSven ? pev(weapon, pev_owner) : get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );


    if ( gOldClip{ player } <= 0 )
    {
        return;
    }
    //355 is weapon for gearbox (~+43 from hl), need to see cs offset
    set_pdata_int( player, 356, 32 ) //355 12

    set_pdata_float( weapon, m_flNextPrimaryAttack,  /*0.05*/ g_Speed*5, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( weapon, m_flTimeWeaponIdle,  /*0.03*/ g_Speed*3, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( weapon, m_flTimeWeaponIdle,  /*0.01*/g_Speed, LINUX_OFFSET_WEAPONS );
    }

    if(gbCS)
        return

    new Float:g_fDelay = 0.01
    #define m_flNextPrimaryAttackB 46
    #define m_flNextSecondaryAttackB 47

    if ( pev_valid(weapon)>1)
    {
        set_pdata_float(weapon, m_flNextPrimaryAttackB, g_fDelay, LINUX_OFFSET_WEAPONS)
        set_pdata_float(weapon, m_flNextSecondaryAttackB, g_fDelay, LINUX_OFFSET_WEAPONS)
    }

}

public Weapon_SecondaryAttack_Pre ( const weapon )
{
    new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Weapon_SecondaryAttack_Post ( const weapon )
{
    new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if ( gOldClip{ player } <= 1 )
    {
        return;
    }

    set_pdata_float( weapon, m_flNextPrimaryAttack  ,  0.05, LINUX_OFFSET_WEAPONS );
    set_pdata_float( weapon, m_flNextSecondaryAttack, 0.1, LINUX_OFFSET_WEAPONS );

    if ( get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
    {
        set_pdata_float( weapon, m_flTimeWeaponIdle, 0.3, LINUX_OFFSET_WEAPONS );
    }
    else
    {
        set_pdata_float( weapon, m_flTimeWeaponIdle, 0.85, LINUX_OFFSET_WEAPONS );
    }
}

public Weapon_Reload_Pre ( const weapon )
{
    new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldSpecialReload{ player } = get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS );
}

public Weapon_Reload_Post ( const weapon )
{
    new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

    switch ( gOldSpecialReload{ player } )
    {
        case 0 :
        {
            if ( get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 1 )
            {
                set_pdata_float( player , m_flNextAttack, 0.3 );

                set_pdata_float( weapon, m_flTimeWeaponIdle     , 0.1, LINUX_OFFSET_WEAPONS );
                set_pdata_float( weapon, m_flNextPrimaryAttack  ,  0.05, LINUX_OFFSET_WEAPONS );
                set_pdata_float( weapon, m_flNextSecondaryAttack, 0.1, LINUX_OFFSET_WEAPONS );
            }
        }
        case 1 :
        {
            if ( get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 2 )
            {
                set_pdata_float( weapon, m_flTimeWeaponIdle, 0.1, LINUX_OFFSET_WEAPONS );
            }
        }
    }
}
