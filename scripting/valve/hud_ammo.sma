#include amxmodx
#include amxmisc
//#define CSTRIKE  //uncomment if jeeps lag
#if defined CSTRIKE
#include cstrike
#endif
#include engine
#include fakemeta
#include fakemeta_stocks                                      /*crosshair*/
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
    new MaxClients
#endif

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
#define RAINBOW random_num  (1,255)
#define charsmin            -1

static m_iHideHUD, m_iWeaponFlash, m_iWeaponVolume

new red,grn,blu,msk, x, y;
new iRed, iGreen, iBlue;
new g_think, g_mag_offset;
new const updated_mod[] = "sven"
new const hl_mag   = 20
new const sven_mag = 300

new magazine, ammo, wpnid;
new pXPosition,pYPosition,pHoldTime,Float:fXPos,Float:fYPos,Float:fHoldTime;
new cl_weapon[MAX_PLAYERS + 1]
new bool:b_Bot[MAX_PLAYERS+1], bool:bCS, bool:bNice, bool:bDrive[MAX_PLAYERS+1];
new g_mod_name[MAX_NAME_LENGTH];
static iWeapon_Modded

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
    register_plugin( "Show Ammo Hud", "1.1", "SPiNX" )
    bCS = is_running("cstrike") || is_running("czero") ? true : false

    register_event("CurWeapon", "event_active_weapon", "be")

    if(bCS)
    {
        register_event( "CurWeapon", "EV_CurWeapon", "b", "1=1" )
        RegisterHam(Ham_OnControls, "func_vehicle", "driving", 1)
        iWeapon_Modded = CSW_M249
    }
    else
        iWeapon_Modded = HLW_GAUSS



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
    msk         = register_cvar( "hud_ammo_mask", "1"     ); //mask ammo on bottom_right. Warning: blocks xhair and slots!!
    x           = register_cvar( "hud_ammo_x"   , "0.912" );
    y           = register_cvar( "hud_ammo_y"   , "0.95"  );

    //xhair replacement for mask
    pXPosition  = register_cvar("hud_ammo_hair_x"    , "-1.0"  );
    pYPosition  = register_cvar("hud_ammo_hair_y"    , "-1.0"  );
    pHoldTime   = register_cvar("hud_ammo_hair_time" ,  "0.1"  );

    g_think = register_forward(FM_PlayerPreThink, "client_prethink", true);

    get_modname(g_mod_name, charsmax(g_mod_name));
    if(!equal(g_mod_name, updated_mod))
        g_mag_offset = hl_mag
    else
        g_mag_offset = sven_mag
}

public EV_CurWeapon( plr )
{

    if(is_user_bot(plr))
        return PLUGIN_HANDLED;
    if(!is_user_alive(plr) || cl_weapon[plr] != iWeapon_Modded)
        return PLUGIN_HANDLED;

    if(is_user_connected(plr))
    {
        weapon_details(plr);

        new button = get_user_button(plr), oldbutton = get_user_oldbutton(plr);
        if((oldbutton & IN_ATTACK || button & IN_ATTACK2) && magazine > g_mag_offset && get_pcvar_num(msk))
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO )

        else
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
    }

    return PLUGIN_CONTINUE
}

public make_new_ammo_hud(plr)
{
    fHoldTime = get_pcvar_float(pHoldTime)
    set_hudmessage(get_pcvar_num(red), get_pcvar_num(grn), get_pcvar_num(blu), get_pcvar_float(x),  get_pcvar_float(y), 0, 6.0, fHoldTime)
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
    //HUD (plr, "%s", bNice ? thinker[0][random(sizeof(thinker))]:thinker[1][random(sizeof(thinker))])
    //25th anniversay may have adversely affected. Tested on Linux Client. Blank. OSX. Seeing half the symbol.
    HUD (plr, "%s", thinker[1][random(sizeof(thinker))]) //Working on Linux Client.
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

public driving(plr){if(is_user_alive(plr))bDrive[plr] = bDrive[plr] ? false : true;}

public client_putinserver(plr)
{
    b_Bot[plr] = is_user_bot(plr) ? true : false
}

public client_prethink(plr)
{
    if(!is_user_alive(plr) || b_Bot[plr] || plr < 1 ||  plr > MaxClients || bDrive[plr])
        return PLUGIN_HANDLED;

    #if defined CSTRIKE
    if(cs_get_user_driving(plr))
        return PLUGIN_HANDLED;
    #endif

    set_pdata_int(plr, m_iWeaponVolume, SILENCER);

    new button = get_user_button(plr), oldbutton = get_user_oldbutton(plr)

    if(cl_weapon[plr] == iWeapon_Modded)
    {
        if(button & IN_ATTACK2)
        {
            make_crosshair_hud(plr)
        }
    }
    else if(cl_weapon[plr] == HLW_GLOCK)
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

    if(cl_weapon[plr] == iWeapon_Modded)
    {
        weapon_details(plr);
        if( (oldbutton & IN_ATTACK || button & IN_ATTACK2) && magazine > g_mag_offset  && get_pcvar_num(msk))
        {
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO );
            make_crosshair_hud(plr);
        }
        else
        if(magazine > g_mag_offset)
        {
            make_new_ammo_hud(plr);
            set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }
    }

    if(!bCS)
    {
        //if(is_user_admin(plr
        if(oldbutton & IN_ATTACK || button & IN_ATTACK2)
        {
            //static Float:fX,Float:fY;
            //fX += fX, fY += fY
            cl_weapon[plr] == iWeapon_Modded  || cl_weapon[plr] == HLW_GLOCK ?
            client_cmd(plr, "crosshair 0") : client_cmd(plr, "crosshair 1")
            //EF_CrosshairAngle(plr, 98.0, 98.0 ) : EF_CrosshairAngle(plr, 0.0, 0.0 )
            ///set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO ) : set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
        }
        else
        {
            client_cmd(plr, "crosshair 1")
        }
    }
    return PLUGIN_CONTINUE;
}

public plugin_end()
{
    unregister_forward(FM_PlayerPreThink, g_think);
}
