#include amxmodx
#include engine
#include fakemeta

new g_FlashCvarCk, g_flashB, g_flashL
new bool:g_showflashlight[ MAX_PLAYERS +1 ]

public plugin_init()
{
    register_plugin("OF:FLASHLIGHT", "0.3", ".sρiηX҉.");
    register_impulse(100, "@flashlight")
    bind_pcvar_num(get_cvar_pointer("mp_flashlight"),g_FlashCvarCk)
    g_flashB = get_user_msgid("FlashBat")
    g_flashL = get_user_msgid("Flashlight")
}

@flashlight(id, flashlight)
{
    if(is_user_connected(id) && is_user_alive(id) && g_FlashCvarCk > 1)
    {
        g_showflashlight[id] = g_showflashlight[id] ? false : true
        client_cmd id,"spk ../../valve/sound/items/flashlight1.wav"
        g_showflashlight[id]  ? set_pev(id, pev_effects, !EF_DIMLIGHT) : set_pev(id, pev_effects, EF_DIMLIGHT)
        @flash_icon(id)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

@flash_icon(id)
if(is_user_connected(id) && is_user_alive(id) && g_FlashCvarCk > 1)
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_flashL, _, id)
    ewrite_byte(0)
    ewrite_byte(70)
    emessage_end()

    emessage_begin(MSG_ONE_UNRELIABLE, g_flashB, _, id)
    g_showflashlight[id] ? ewrite_byte(100) : ewrite_byte(0)
    emessage_end()
}
