 /*
 * flag_time_fix.sma
 *
 * Purpose:
 * Fixes the Opposing Force CTF (OP4CTF) timer from reappearing or
 * displaying incorrectly on regular/non-CTF maps. It ensures the
 * HUD color and timer sync correctly with the game mode and team.
 *
 * Copyright (C) 2026 SPiNX
 * Refined by AI on Google Search
 */

#include <amxmodx>
#include <amxmisc>
#include <engine>

new g_msgFlagTimer, g_msgHudColor;
new bool:g_isOp4Map;
new g_playerTeam[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin("OF:FlagTimer Fixed", "1.2", ".sρiηX҉.");

    g_msgFlagTimer = get_user_msgid("FlagTimer");
    g_msgHudColor = get_user_msgid("HudColor");

    if (!g_msgFlagTimer || !g_msgHudColor) {
        set_fail_state("Mod does not support OP4CTF messages.");
    }

    register_event("ResetHUD", "on_player_spawn", "be");
    register_event("TeamInfo", "on_team_change", "a");

    g_isOp4Map = (find_ent_by_class(-1, "info_ctfdetect") > 0);
}

public client_disconnected(id) {
    remove_task(id);
}

public on_team_change() {
    new id = read_data(1);
    static team[2]; read_data(2, team, charsmax(team));

    switch(team[0]) {
        case 'B': g_playerTeam[id] = 1; // Black Mesa
        case 'O': g_playerTeam[id] = 2; // Opposing Force
        default:  g_playerTeam[id] = 3; // Spectator/None
    }
}

public on_player_spawn(id) {
    if (is_user_bot(id)) return;

    message_begin(MSG_ONE_UNRELIABLE, g_msgFlagTimer, _, id);
    write_byte(g_isOp4Map ? 1 : 0);
    if (g_isOp4Map) write_short(get_timeleft());
    message_end();

    message_begin(MSG_ONE_UNRELIABLE, g_msgHudColor, _, id);
    switch(g_playerTeam[id]) {
        case 1: { write_byte(234); write_byte(151); write_byte(25);  }
        case 2: { write_byte(0);   write_byte(255); write_byte(0);   }
        default:{ write_byte(29);  write_byte(211); write_byte(199); }
    }
    message_end();

    if (g_isOp4Map && !task_exists(id)) {
        set_task(1.0, "show_timer", id, .flags = "b");
    }
}

public show_timer(id) {
    if (!is_user_connected(id)) {
        remove_task(id);
        return;
    }

    new timeleft = get_timeleft();
    new r, g, b;

    switch(g_playerTeam[id]) {
        case 1: { r = 234; g = 151; b = 25;  }
        case 2: { r = 0;   g = 255; b = 0;   }
        default:{ r = 33;  g = 209; b = 175; }
    }

    set_hudmessage(r, g, b, 0.08, 0.947, 0, 1.0, 1.1, 0.1, 0.2, 13);
    show_hudmessage(id, "         %d:%02d", timeleft / 60, timeleft % 60);
}
