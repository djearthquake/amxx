#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_stocks
#include hamsandwich

#define MAX_PLAYERS          32
#define MAX_NAME_LENGTH      32
#define ALL_NULL (0<<0)
#define HIDEHUD_AMMO        (1<<0)
#define HIDEHUD_CROSSHAIR   (1<<6)
#define HIDEHUD_RETURN      (1<<7)

#define LOUD_GUN_VOLUME             1000
#define NORMAL_GUN_VOLUME           600
#define QUIET_GUN_VOLUME            200
#define SILENCER                               100
#define GAUSS_PRIMARY_CHARGE_VOLUME 256// how loud gauss is while charging
#define GAUSS_PRIMARY_FIRE_VOLUME   450// how loud gauss is when discharged

#define BRIGHT_GUN_FLASH            512
#define NORMAL_GUN_FLASH            256
#define DIM_GUN_FLASH               128
#define FLASH_SUPRESSOR             4

#if !defined MaxClients
    static MaxClients
#endif

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
#define RAINBOW random_num  (1,255)
#define charsmin            -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

static m_iHideHUD, m_iWeaponFlash, m_iWeaponVolume

new red,grn,blu,msk, x, y;
new iRed, iGreen, iBlue;
new g_mag_offset;
static const updated_mod[] = "sven"
static const hl_mag   = 20
static const sven_mag = 300

new magazine, ammo, wpnid;
new pXPosition,pYPosition,pHoldTime,Float:fXPos,Float:fYPos,Float:fHoldTime;
new cl_weapon[MAX_PLAYERS + 1]
static bool:bCS, bool:bNice
static g_mod_name[MAX_NAME_LENGTH];
static iWeapon_Modded

new g_crosshair
static g_Adm, g_AI;

public event_active_weapon(player)
{
    if(is_user_alive(player))
    {
        cl_weapon[player] = read_data(2);

        if(cl_weapon[player] > 0)
            return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public plugin_init( )
{
    register_plugin( "Show Ammo Hud", "1.21", "SPiNX" )
    get_modname(g_mod_name, charsmax(g_mod_name));

    bCS = equal(g_mod_name, "cstrike") || equal(g_mod_name, "czero")  ? true : false

    register_event("CurWeapon", "event_active_weapon", "be")

    if(bCS)
    {
        register_event( "CurWeapon", "EV_CurWeapon", "b", "1=1" )
        iWeapon_Modded = CSW_M249
    }
    else
    {
        iWeapon_Modded = HLW_GAUSS
        server_print("hud_ammo detected %s running.", g_mod_name)
    }

    #if !defined MaxClients
        MaxClients = get_maxplayers()
    #endif

    bNice = colored_menus() ? true : false

    m_iHideHUD = (find_ent_data_info("CBasePlayer", "m_iHideHUD") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF //ALL 3 OS have this in DLL/SO/DYLIB

    m_iWeaponFlash = (find_ent_data_info("CBasePlayer", "m_iWeaponFlash") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF

    m_iWeaponVolume = (find_ent_data_info("CBasePlayer", "m_iWeaponVolume") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF

    //ammo hud
    red         = register_cvar( "hud_ammo_red" , "120"   );
    grn         = register_cvar( "hud_ammo_grn" , "200"   );
    blu         = register_cvar( "hud_ammo_blu" , "75"    );
    msk         = register_cvar( "hud_ammo_mask", "1"     ); //mask ammo on bottom_right.
    x           = register_cvar( "hud_ammo_x"   , "0.912" );
    y           = register_cvar( "hud_ammo_y"   , "0.95"  );

    //xhair replacement for mask
    pXPosition  = register_cvar("hud_ammo_hair_x"    , "-1.0"  );
    pYPosition  = register_cvar("hud_ammo_hair_y"    , "-1.0"  );
    pHoldTime   = register_cvar("hud_ammo_hair_time" ,  "0.1"  );

    g_mag_offset = equal(g_mod_name, updated_mod) == 1 ? sven_mag : hl_mag

    g_crosshair = create_cvar("cross", "1")

}


public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
        is_user_admin(id) ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id)

        if(CheckPlayerBit(g_AI, id))
            return

        set_task(0.1,"client_think",id,.flags="b")
        server_print("Made hud think for %N", id )
    }
}

public client_disconnected(id)
{
    remove_task(id)
}

public EV_CurWeapon( plr )
{

    if(CheckPlayerBit(g_AI, plr))
        return PLUGIN_HANDLED;

    if(!is_user_alive(plr) || cl_weapon[plr] != iWeapon_Modded)
        return PLUGIN_HANDLED;

    if(is_user_connected(plr))
    {
        weapon_details(plr);

        static button, oldbutton; button  = get_user_button(plr), oldbutton = get_user_oldbutton(plr);
        if((oldbutton & IN_ATTACK || button & IN_ATTACK2) && magazine > g_mag_offset && get_pcvar_num(msk))
        {
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO )
        }
        else
        {
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }
    }
    return PLUGIN_CONTINUE
}

public make_new_ammo_hud(plr)
{
    fHoldTime = get_pcvar_float(pHoldTime)
    bNice?
    set_dhudmessage(get_pcvar_num(red), get_pcvar_num(grn), get_pcvar_num(blu), get_pcvar_float(x),  get_pcvar_float(y), 0, 6.0, fHoldTime)
    &show_dhudmessage(plr, "     %i         %i  " , magazine, ammo )
    :
    set_hudmessage(get_pcvar_num(red), get_pcvar_num(grn), get_pcvar_num(blu), get_pcvar_float(x),  get_pcvar_float(y), 0, 6.0, fHoldTime)&
    show_hudmessage(plr, "     %i         %i  " , magazine, ammo )
}

public make_crosshair_hud(plr)
{
    static const thinker[][][]=
    {

        {
             "⋮","⋯","⋰","⋱"
        },

        {
             "|","X","/","\"
        }

    };

    iRed = RAINBOW;iGreen = RAINBOW; iBlue = RAINBOW;fXPos = get_pcvar_float(pXPosition);fYPos = get_pcvar_float(pYPosition);fHoldTime = get_pcvar_float(pHoldTime)
    set_hudmessage(iRed, iGreen, iBlue, fXPos, fYPos, 0, 2.0, fHoldTime, 0.0, 0.0, -1);

    #define HUD show_hudmessage
    static iCross; iCross = get_pcvar_num(g_crosshair)

    switch(iCross)
    {
        case 1: HUD (plr, "%s", thinker[1][random(sizeof(thinker))]) //Working on Linux Client.
        //25th anniversay may have adversely affected. Tested on Linux Client. Blank. OSX. Seeing half the symbol.
        case 2: HUD (plr, "%s", bNice ? thinker[0][random(sizeof(thinker))]:thinker[1][random(sizeof(thinker))])
    }
    @muzzlebreak(plr, 1)
}

@muzzlebreak(plr,muzzle)
{
    set_pdata_int(plr, m_iWeaponFlash, 0);
    static effects; effects = pev(plr, pev_effects)

    switch(muzzle)
    {
        case 0: set_pev(plr, pev_effects, (effects | EF_MUZZLEFLASH))
        case 1: set_pdata_int(plr, m_iWeaponFlash, get_pdata_int(plr, m_iWeaponFlash) | FLASH_SUPRESSOR);
        default: set_pev(plr, pev_effects, (effects &~ EF_MUZZLEFLASH))
    }
}

stock weapon_details(plr)
{
    wpnid = get_user_weapon(plr, magazine, ammo);
    return wpnid, magazine, ammo;
}

public client_think(plr)
{
    if(!is_user_alive(plr))
        return PLUGIN_HANDLED;

    set_pdata_int(plr, m_iWeaponVolume, SILENCER);

    static button, oldbutton;
    button = get_user_button(plr)
    oldbutton = get_user_oldbutton(plr)

    if(cl_weapon[plr] == iWeapon_Modded)
    {
        if(oldbutton & IN_ATTACK2)
        {
            ///server_print("%n trying",plr)
            make_crosshair_hud(plr)
        }
    }

    else if (cl_weapon[plr] == HLW_GLOCK)
    {
        if(button & IN_ATTACK)
        {
            make_crosshair_hud(plr)
            set_pdata_int(plr, m_iWeaponVolume, 0 );
        }
        else if(button & IN_ATTACK2)
        {
            @muzzlebreak(plr, 3)
        }

    }
    //ammo hud adjustments
    if(cl_weapon[plr] == iWeapon_Modded)
    {
        weapon_details(plr);
        if( (oldbutton & IN_ATTACK || button & IN_ATTACK2 ) && magazine > g_mag_offset  && get_pcvar_num(msk))
        {
            make_new_ammo_hud(plr);
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO );
        }
        else
        if(magazine > g_mag_offset)
        {
            make_new_ammo_hud(plr);
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }
        else
        {
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }
    }

    if(!bCS)
    {
        //Mods like Sven, HL, and OP4
        if(oldbutton & IN_ATTACK || button & IN_ATTACK2)
        {
            static iOK;
            iOK = cl_weapon[plr] == iWeapon_Modded  || cl_weapon[plr] == HLW_GLOCK;
            iOK ? set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO ) :
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }
        else
        {
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }

    }
    return PLUGIN_CONTINUE;
}
