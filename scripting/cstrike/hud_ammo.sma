#include amxmodx
#include cstrike
#include engine
#include fakemeta

#define MAX_PLAYERS          32
#define MAX_NAME_LENGTH      32
#define HIDEHUD_AMMO        (1<<0)
#define HIDEHUD_CROSSHAIR   (1<<6)
#define HIDEHUD_RETURN      (1<<7)
#define m_iHideHUD            361
#define RAINBOW random_num  (1,255)
#define charsmin            -1

new red,grn,blu,msk, x, y;
new iRed, iGreen, iBlue;
new g_think, g_mag_offset;
new const updated_mod[] = "sven"
new const hl_mag   = 100
new const sven_mag = 300

new magazine, ammo, wpnid;
new pXPosition,pYPosition,pHoldTime,Float:fXPos,Float:fYPos,Float:fHoldTime;

new g_mod_name[MAX_NAME_LENGTH];

public plugin_init( )
{
    register_plugin( "Show Ammo Hud", "1.0", "SPiNX" )
    register_event( "CurWeapon", "EV_CurWeapon", "b", "1=1" )

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

    g_think = register_forward(FM_PlayerPreThink, "client_prethink");

    get_modname(g_mod_name, charsmax(g_mod_name));
    if( !equal(g_mod_name, updated_mod))
        g_mag_offset = hl_mag
    else
        g_mag_offset = sven_mag
    


}

public EV_CurWeapon( plr )
{

    if(!is_user_alive(plr) || is_user_bot(plr))
        return PLUGIN_HANDLED;

    if(is_user_connected(plr))
    {
        weapon_details(plr);

        new button = get_user_button(plr), oldbutton = get_user_oldbutton(plr);
        if  ( (oldbutton & IN_ATTACK || button & IN_ATTACK2) && magazine > 100 && get_pcvar_num(msk))
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

public make_crosshair(plr)
{

    new const thinker[][] = 
                {
         "⋮","⋯","⋰","⋱"
                };
                
    iRed = RAINBOW;iGreen = RAINBOW; iBlue = RAINBOW;fXPos = get_pcvar_float(pXPosition);fYPos = get_pcvar_float(pYPosition);fHoldTime = get_pcvar_float(pHoldTime)
    set_hudmessage(iRed, iGreen, iBlue, fXPos, fYPos, 0, 2.0, fHoldTime, 0.0, 0.0, -1);
    #define HUD show_hudmessage

    show_hudmessage (plr, "%s", thinker[random(sizeof(thinker))]);
}

stock weapon_details(plr)
{

    wpnid = get_user_weapon(plr, magazine, ammo);

    return wpnid, magazine, ammo;
}

public client_prethink(plr)
{

    if( !is_user_alive(plr) || is_user_bot(plr) || plr < 1)
        return PLUGIN_HANDLED;
    if(equal(g_mod_name, "cstrike") || equal(g_mod_name, "czero") && cs_get_user_driving(plr))
        return PLUGIN_HANDLED;

    new button = get_user_button(plr), oldbutton = get_user_oldbutton(plr)
    weapon_details(plr);
    if  ( (oldbutton & IN_ATTACK || button & IN_ATTACK2) && magazine > g_mag_offset  && get_pcvar_num(msk))
    {
        set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) | HIDEHUD_AMMO );
            make_crosshair(plr);
    }
    else
    if(magazine > g_mag_offset)
    {
        make_new_ammo_hud(plr);
        set_pdata_int(plr, m_iHideHUD, get_pdata_int(plr, m_iHideHUD) & ~HIDEHUD_AMMO );
    }
    return PLUGIN_CONTINUE;
}

public plugin_end()
unregister_forward(FM_PlayerPreThink, g_think);
    
