/*
 * flag_timer_fix.sma
 *
 * Purpose:
 * Fixes OP4CTF timer visibility and adds smooth HP-based HUD color fading.
 *
 * Copyright (C) 2026 SPiNX
 * GitHub: https://github.com/djearthquake
 */

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define PLUGIN  "OF:FlagTimer & Smooth HP"
#define VERSION "1.6"
#define AUTHOR  ".sρiηX҉."
#define URL     "https://github.com/djearthquake"

new g_msgFlagTimer, g_msgHudColor, bool:g_isOp4Map, p_hp_colors, g_lastHp[MAX_PLAYERS + 1];

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 183 || AMXX_VERSION_NUM <= 110
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR);
    #endif

    g_msgFlagTimer = get_user_msgid("FlagTimer");
    g_msgHudColor = get_user_msgid("HudColor");
    p_hp_colors = register_cvar("amx_hp_hud_nonctf", "1");

    if (!g_msgFlagTimer || !g_msgHudColor)
    {
        set_fail_state("Mod does not support OP4CTF messages.");
    }

    register_event("ResetHUD", "on_player_spawn", "be");
    g_isOp4Map = (find_ent_by_class(-1, "info_ctfdetect") > 0);
}

public client_putinserver(id)
{
    g_lastHp[id] = -1;
}

public on_player_spawn(id)
{
    if (is_user_bot(id))
    {
        return;
    }

    message_begin(MSG_ONE_UNRELIABLE, g_msgFlagTimer, _, id);
    write_byte(g_isOp4Map ? 1 : 0);
    message_end();

    if (!task_exists(id))
    {
        set_task(0.2, "update_hud", id, .flags = "b");
    }
}

public update_hud(id)
{
    if (!is_user_connected(id))
    {
        remove_task(id);
        return;
    }

    new r, g, b, hp = clamp(get_user_health(id), 0, 100);

    if (g_isOp4Map)
    {
        switch (get_user_team(id))
        {
            case 1:
            {
                r = 234; g = 151; b = 25; // Black Mesa
            }
            case 2:
            {
                r = 0; g = 255; b = 0;   // OpFor
            }
            default:
            {
                r = 33; g = 209; b = 175; // Spec
            }
        }

        if (hp != g_lastHp[id])
        {
            send_color(id, r, g, b);
            g_lastHp[id] = hp;
        }

        new tl = get_timeleft();
        set_hudmessage(r, g, b, 0.08, 0.947, 0, 0.0, 0.3, 0.0, 0.0, 4);
        show_hudmessage(id, "         %d:%02d", tl / 60, tl % 60);
    }
    else if (get_pcvar_num(p_hp_colors))
    {
        if (hp == g_lastHp[id])
        {
            return;
        }

        if (hp > 50)
        {
            r = floatround(255.0 * (100.0 - hp) / 50.0);
            g = 255;
        }
        else
        {
            r = 255;
            g = floatround(255.0 * hp / 50.0);
        }

        send_color(id, r, g, 0);
        g_lastHp[id] = hp;
    }
}

send_color(id, r, g, b)
{
    message_begin(MSG_ONE_UNRELIABLE, g_msgHudColor, _, id);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    message_end();
}
