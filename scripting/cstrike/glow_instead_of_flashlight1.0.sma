/*
My request is to set glow to player who presses F (+flashlight or impulse 101).
Glow can be in radius little or bigger so i can set it, in .sma, no need for cvar.
Blue glow for CT and Red for TT.
When you are in CT blue glow and only counters see it, in TT red glow and only terrorists see it.
*/
#include amxmodx
#include amxmisc
#include engine

#include fun


#define OFF set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, g_SPShell)
new fx,r,g,b,render,amount,g_SPShell;


public plugin_init(){
    register_plugin("Team Glow flashlight", "1.0", "SPiNX");
    register_impulse(100, "client_impulse_flashlight");

}

public client_impulse_flashlight(id){
    if( is_user_alive(id) || (is_user_connected(id) && is_user_bot(id)) )
    g_SPShell = 75;
    
    //3-way toggle light switch. BOTH|FLASHLIGHT|GLOW|OFF
    get_user_rendering(id,fx,r,g,b,render,amount)
    if(r|g|b == 255)
        OFF
        else
    {

    if(entity_get_float(id, EV_FL_armorvalue) > 100.0 && get_user_team(id) == 2 )
    {
        set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, g_SPShell)
        return PLUGIN_CONTINUE;
    }

    if(get_user_team(id) == 1)
    {
        set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, g_SPShell)
        return PLUGIN_CONTINUE;
    }

    if(entity_get_float(id, EV_FL_armorvalue) <= 100.0 && get_user_team(id) == 2 )
    {
        set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, g_SPShell)
        return PLUGIN_CONTINUE;
    }

    }

    return PLUGIN_HANDLED_MAIN;
}
