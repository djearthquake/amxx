#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Oxygen Status Icon"
#define VERSION "1.2"
#define AUTHOR  "SPiNX"

#define TASK_OXYGEN 5000

#define OXYGEN_MAX_TIME 12.0
#define REFRESH_INTERVAL 0.2
#define COLOR_STEPS 60

static g_msgStatusIcon;
static g_msgHudColor;

new bool:g_bWantsO2[MAX_PLAYERS + 1] = { true, ... };
new g_iLastColorState[MAX_PLAYERS + 1];

static const g_iRainbowR[COLOR_STEPS] =
{
    130, 134, 138, 142, 146, 150, 120, 90,  60,  30,   0,   0,   0,   0,   0,   0,   0,  30,  60,  90,
    120, 150, 180, 210, 240, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 230, 200, 170, 140, 110,  80,  50,  20
};

static const g_iRainbowG[COLOR_STEPS] =
{
    0,   5,   10,  15,  20,  25,  40,  55,  70,  85,  100, 105, 110, 115, 120, 125, 128, 132, 136, 140,
    144, 148, 152, 156, 160, 164, 168, 172, 176, 180, 185, 190, 195, 200, 205, 210, 215, 220, 190, 160,
    130, 100, 70,  40,  20,  15,  10,  5,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
};

static const g_iRainbowB[COLOR_STEPS] =
{
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 230, 205, 180, 155, 130, 0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   5,   10,  15,  20,  25,  30,  40,  50,  45,  40,
    35,  30,  25,  20,  50,  70,  90,  110, 130, 147, 120, 90,  70,  50,  30,  20,  10,  5,   0,   0
};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_msgStatusIcon = get_user_msgid("StatusIcon");
    g_msgHudColor = get_user_msgid("HudColor");

    register_message(g_msgStatusIcon, "msg_status_icon");

    register_clcmd("o2", "cmd_toggle_o2");
    register_clcmd("oxygen_bar", "cmd_toggle_o2");

    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", 1);

    set_task(REFRESH_INTERVAL, "task_oxygen_processor", TASK_OXYGEN, _, _, "b");
}

public client_putinserver(id)
{
    g_bWantsO2[id] = is_user_bot(id) ? false : true;
    g_iLastColorState[id] = -1;
}

public client_disconnected(id)
{
    g_iLastColorState[id] = -1;
}

public OnPlayerKilled(id)
{
    clear_oxygen_hud_state(id);
}

public msg_status_icon(msg_id, msg_dest, id)
{
    new sIcon[32];
    get_msg_arg_string(1, sIcon, charsmax(sIcon));

    if (equal(sIcon, "oxygen"))
        return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
}

public cmd_toggle_o2(id)
{
    g_bWantsO2[id] = !g_bWantsO2[id];
    client_print(id, print_chat, "* Oxygen Icon is now %s.", g_bWantsO2[id] ? "ON" : "OFF");

    if (!g_bWantsO2[id])
    {
        clear_oxygen_hud_state(id);
    }
    return PLUGIN_HANDLED;
}

public task_oxygen_processor()
{
    new players[MAX_PLAYERS], num;
    get_players(players, num, "ch");

    new id;
    new Float:gameTime = get_gametime();

    for (new i = 0; i < num; i++)
    {
        id = players[i];

        if (!is_user_alive(id) || !g_bWantsO2[id])
        {
            clear_oxygen_hud_state(id);
            continue;
        }

        if (pev(id, pev_waterlevel) != 3)
        {
            clear_oxygen_hud_state(id);
            continue;
        }

        new Float:airFinished;
        pev(id, pev_air_finished, airFinished);

        new Float:remaining = airFinished - gameTime;
        if (remaining < 0.0)
            remaining = 0.0;

        new Float:fRatio = remaining / OXYGEN_MAX_TIME;
        new iIndex = floatround(fRatio * (COLOR_STEPS - 1));
        iIndex = clamp(iIndex, 0, COLOR_STEPS - 1);

        new iTargetIndex = (COLOR_STEPS - 1) - iIndex;

        new r = g_iRainbowR[iTargetIndex];
        new g = g_iRainbowG[iTargetIndex];
        new b = g_iRainbowB[iTargetIndex];

        new mode = (remaining <= 1.0) ? 2 : 1;

        if (g_iLastColorState[id] != iTargetIndex)
        {
            g_iLastColorState[id] = iTargetIndex;
            update_custom_sprite(id, mode, r, g, b);

            if (g_msgHudColor)
            {
                message_begin(MSG_ONE_UNRELIABLE, g_msgHudColor, _, id);
                write_byte(r);
                write_byte(g);
                write_byte(b);
                message_end();
            }
        }
    }
}

stock update_custom_sprite(id, mode, r, g, b)
{
    message_begin(MSG_ONE_UNRELIABLE, g_msgStatusIcon, _, id);
    write_byte(mode);
    write_string("dmg_drown");
    write_byte(r);
    write_byte(g);
    write_byte(b);
    message_end();
}

stock clear_oxygen_hud_state(id)
{
    if (g_iLastColorState[id] != -1)
    {
        g_iLastColorState[id] = -1;

        update_custom_sprite(id, 0, 0, 0, 0);

        if (g_msgHudColor)
        {
            message_begin(MSG_ONE_UNRELIABLE, g_msgHudColor, _, id);
            write_byte(255);
            write_byte(255);
            write_byte(255);
            message_end();
        }
    }
}
