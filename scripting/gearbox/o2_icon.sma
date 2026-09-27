#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define OXYGEN_MAX_TIME 12.0
#define REFRESH_INTERVAL 0.2

#define COLOR_STEPS 60

static g_msgStatusIcon;
static g_msgHudColor;

new bool:g_PlayerAlive[MAX_PLAYERS + 1];
new Float:g_fOxygen[MAX_PLAYERS + 1];
new g_iLastColorState[MAX_PLAYERS + 1];
new bool:g_bWantsO2[MAX_PLAYERS + 1] = { false, ... };

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
    register_plugin("O2 Icon", "1.0", "SPiNX");
    
    g_msgStatusIcon = get_user_msgid("StatusIcon");
    g_msgHudColor = get_user_msgid("HudColor");

    register_message(g_msgStatusIcon, "msg_status_icon");
    
    register_clcmd("o2", "cmd_toggle_o2");
    register_clcmd("oxygen_bar", "cmd_toggle_o2");
    
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", 1);
    
    set_task(REFRESH_INTERVAL, "task_oxygen_processor", 5000, _, _, "b");
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        g_bWantsO2[id] = is_user_bot(id) ?  true : false;
        g_PlayerAlive[id] = true;
        g_fOxygen[id] = OXYGEN_MAX_TIME;
        g_iLastColorState[id] = -1;
    }
}

public client_disconnected(id)
{
    g_PlayerAlive[id] = false;
    g_iLastColorState[id] = -1;
}

public OnPlayerSpawn(id)
{
    if (is_user_alive(id))
    {
        g_PlayerAlive[id] = true;
        g_fOxygen[id] = OXYGEN_MAX_TIME;
        g_iLastColorState[id] = -1;
    }
}

public OnPlayerKilled(id)
{
    g_PlayerAlive[id] = false;
    update_custom_sprite(id, 0, 0, 0, 0);
}

public msg_status_icon(msg_id, msg_dest, id)
{
    new sIcon[MAX_PLAYERS];
    get_msg_arg_string(1, sIcon, charsmax(sIcon));
    
    if (equal(sIcon, "oxygen")) 
        return PLUGIN_HANDLED;
        
    return PLUGIN_CONTINUE;
}

public cmd_toggle_o2(id)
{
    g_bWantsO2[id] = !g_bWantsO2[id];
    client_print(id, print_chat, "* Oxygen HUD is now %s.", g_bWantsO2[id] ? "ON" : "OFF");
    
    if (!g_bWantsO2[id])
    {
        g_iLastColorState[id] = -1;
        update_custom_sprite(id, 0, 0, 0, 0);
    }
    return PLUGIN_HANDLED;
}
public task_oxygen_processor()
{
    static id;
    
    for (id = 1; id < MaxClients + 1; id++)
    {
        if (!g_PlayerAlive[id] || !g_bWantsO2[id]) 
            continue;
        
        if (pev(id, pev_waterlevel) > 0 || (pev(id, pev_flags) & FL_INWATER))
        {
            g_fOxygen[id] -= REFRESH_INTERVAL; 
            if (g_fOxygen[id] < 0.0) 
                g_fOxygen[id] = 0.0;
            
            new Float:fRatio = g_fOxygen[id] / OXYGEN_MAX_TIME;
            new iIndex = floatround(fRatio * (COLOR_STEPS - 1));
            iIndex = clamp(iIndex, 0, COLOR_STEPS - 1);
            
            new iTargetIndex = (COLOR_STEPS - 1) - iIndex;
            
            new r = g_iRainbowR[iTargetIndex];
            new g = g_iRainbowG[iTargetIndex];
            new b = g_iRainbowB[iTargetIndex];
            
            new mode = (g_fOxygen[id] <= 1.0) ? 2 : 1;
            
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
        else
        {
            if (g_iLastColorState[id] != -1)
            {
                g_fOxygen[id] = OXYGEN_MAX_TIME;
                g_iLastColorState[id] = -1;
                update_custom_sprite(id, 0, 0, 0, 0);
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
