/*https://forums.alliedmods.net/showthread.php?t=340800*/
#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta
#include hamsandwich

#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define WRITEABLE_ENT   2
#define charsmin        -1

#define OP4

#if defined OP4
    #define OP4_OFFSET 3
#else
    #define OP4_OFFSET 0
#endif

/* WEAPONS HL OFFSETS */
const m_pPlayer               = 28 + OP4_OFFSET
const m_flNextPrimaryAttack   = 35 + OP4_OFFSET
const m_flNextSecondaryAttack = 36 + OP4_OFFSET
const m_flTimeWeaponIdle      = 37 + OP4_OFFSET
const m_iClip                 = 40 + OP4_OFFSET
    
/* WEAPONS OF OFFSETS */
const m_iLaserActive                 = 50
const m_fSpotVisible                   = 51
const m_usFireEagle                     = 52  // short unsigned int 1

/* PLAYER HL OFFSETS */
const m_flNextAttack   = 148 + OP4_OFFSET

 /* CONSTANTS */
new const gEagleClassname[] = "weapon_eagle";
const LINUX_OFFSET_WEAPONS = 4;

/* VARIABLES */

new gRedot         [ MAX_PLAYERS + 1 char ];
new const CvarLserDesc[] ="Auto laser"


public plugin_init()
{
    register_plugin(CvarLserDesc, "12-19-22",".sρiηX҉.");
    RegisterHam(Ham_Weapon_PrimaryAttack, gEagleClassname, "@fwd_AttackSpeed" , 1)
}

@fwd_AttackSpeed( const iEagle)
{
    new iPlayer = get_pdata_cbase( iEagle, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if( gRedot{ iPlayer } < 0 )
    {
        return;
    }

    new iLaserActive = get_pdata_int (iEagle, m_iLaserActive, LINUX_OFFSET_WEAPONS)
    //new Float:fSpotVisible = get_pdata_float( iEagle, m_fSpotVisible, LINUX_OFFSET_WEAPONS)

    if( !iLaserActive ) 
    {
        set_pdata_int( iEagle, m_iLaserActive, 1, LINUX_OFFSET_WEAPONS );
    }
    else if( pev(iPlayer, pev_button) & IN_ATTACK2)
    {
        set_pdata_int( iEagle, m_fSpotVisible, 0, LINUX_OFFSET_WEAPONS );
    }

}
