#include amxmodx
#include engine
#include fakemeta

new g_FlashCvarCk, g_flashB, g_flashL
new bool:g_showflashlight[ MAX_PLAYERS +1 ]
new bool:g_playerflashlight[ MAX_PLAYERS +1 ]


public plugin_init()
{
    register_plugin("OF:FLASHLIGHT", "0.4", ".sρiηX҉.");
    register_impulse(100, "@flashlight")
    bind_pcvar_num(get_cvar_pointer("mp_flashlight"),g_FlashCvarCk)
    g_flashB = get_user_msgid("FlashBat")
    g_flashL = get_user_msgid("Flashlight")
    register_clcmd("say /flashlight","@pick_flash", 0, "- toggle flashlight/nightvision.")
    register_concmd("/flashlight","@pick_flash", 0, "- toggle flashlight/nightvision.")
}

@pick_flash(id)
{
    if(is_user_connected(id))
    {
        g_playerflashlight[id] = g_playerflashlight[id] ? false : true
    }
    return PLUGIN_HANDLED
}

@flashlight(id, flashlight)
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        if(g_FlashCvarCk == 2)
        {
    
            if(!g_playerflashlight[id]  || g_playerflashlight[id]  &&  g_showflashlight[id] )
            {
                g_showflashlight[id] = g_showflashlight[id] ? false : true
                client_cmd id,"spk ../../valve/sound/items/flashlight1.wav"
                g_showflashlight[id] || g_playerflashlight[id] ? set_pev(id, pev_effects, !EF_DIMLIGHT) : set_pev(id, pev_effects, EF_DIMLIGHT)
                @flash_icon(id)
                return PLUGIN_HANDLED
            }

        }
        else if(g_FlashCvarCk == 3)
        {
            if(!g_playerflashlight[id] ||g_showflashlight[id])
            {
                g_showflashlight[id] = g_showflashlight[id] ? false : true
                client_cmd id,"spk ../../valve/sound/items/flashlight1.wav"
                g_showflashlight[id] || g_playerflashlight[id] ? set_pev(id, pev_effects, !EF_DIMLIGHT) : set_pev(id, pev_effects, EF_DIMLIGHT)
                @flash_icon(id)
                return PLUGIN_HANDLED
            }
            else
            {
                {
                    //remove green ...add screen fade for whatever color
                    emessage_begin(MSG_ONE_UNRELIABLE, g_flashL, _, id)
                    ewrite_byte(g_showflashlight[id] ?  1 : 0)
                    ewrite_byte(g_showflashlight[id] ? 50 : 0)
                    emessage_end()
        
                    emessage_begin(MSG_ONE_UNRELIABLE, g_flashB, _, id)
                    g_showflashlight[id] ? ewrite_byte(100) : ewrite_byte(0)
                    emessage_end()
                }
            }
        }
        else if(g_FlashCvarCk == 4)
        {
            if(!g_playerflashlight[id] ||g_showflashlight[id])
            {
                g_showflashlight[id] = g_showflashlight[id] ? false : true
                client_cmd id,"spk ../../valve/sound/items/flashlight1.wav"
                g_showflashlight[id] || g_playerflashlight[id] ? set_pev(id, pev_effects, (!EF_BRIGHTLIGHT)) : set_pev(id, pev_effects, (EF_MUZZLEFLASH | EF_BRIGHTLIGHT))
                @flash_icon(id)
                return PLUGIN_HANDLED
            }
        }
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

public client_putinserver(id)
{
    if(id < 33 && id > 1)
        g_showflashlight[id] = true
}
