#include amxmodx
#include engine
#include fakemeta

new g_FlashCvarCk
new bool:g_showflashlight[ MAX_PLAYERS +1 ]

public plugin_init()
{
    register_plugin("OF:FLASHLIGHT", "0.2", ".sρiηX҉.");
    register_impulse(100, "@flashlight") 
    bind_pcvar_num(get_cvar_pointer("mp_flashlight"),g_FlashCvarCk)
}

@flashlight(id, flashlight)
{
    if(is_user_connected(id) && is_user_alive(id) && g_FlashCvarCk > 1)
    {
        g_showflashlight[id] = g_showflashlight[id] ? false : true
        client_cmd(id, g_showflashlight[id] ? "spk items/flashlight2.wav" : "spk items/flashlight1.wav")
        g_showflashlight[id]  ? set_pev(id, pev_effects, !EF_DIMLIGHT) : set_pev(id, pev_effects, EF_DIMLIGHT)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}
