#include <amxmodx>
#include <engine_stocks>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Oxygen Status Icon"
#define VERSION "1.3"
#define AUTHOR  "SPiNX"

#define TASK_OXYGEN 5000

#define OXYGEN_MAX_TIME 12.0
#define REFRESH_INTERVAL 0.2
#define COLOR_STEPS 60
#define UNDER_WATER 3

static g_msgStatusIcon;
static g_msgHudColor;

static g_sModelIndexBubbles;

static const SzWater[]="func_water"
static const SzWaterFake[]="func_illusionary" //can be reskinned to water, lava, or slime.

new bool:g_bWantsO2[MAX_PLAYERS + 1] = { true, ... };
new bool:g_bSpokenWarning[MAX_PLAYERS + 1];
new g_iLastColorState[MAX_PLAYERS + 1];
new g_PlayerAlive[MAX_PLAYERS + 1];

new g_iO2Tanks[MAX_PLAYERS + 1];
new g_iLastFrags[MAX_PLAYERS + 1];
new g_cvar_o2_frags;

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
    find_ent(FM_NULLENT, SzWater) ||  find_ent(FM_NULLENT, SzWaterFake) ? server_print("%s found.", SzWater) : log_amx("%s NOT found on map.", SzWater)&pause("a")
    g_msgStatusIcon = get_user_msgid("StatusIcon");
    g_msgHudColor = get_user_msgid("HudColor");

    register_message(g_msgStatusIcon, "msg_status_icon");

    register_clcmd("o2", "cmd_toggle_o2");
    register_clcmd("oxygen_bar", "cmd_toggle_o2");

    g_cvar_o2_frags = register_cvar("amx_o2_frags", "3");

    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_RewardCheck", 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", 1);
    RegisterHam(Ham_Spawn,"player","PlayerLife",1)

    set_task(REFRESH_INTERVAL, "task_oxygen_processor", TASK_OXYGEN, _, _, "b");
}

public plugin_precache()
{
    precache_model("models/w_oxygen.mdl");
    precache_sound("items/ammopickup1.wav"); 
    g_sModelIndexBubbles = precache_model("sprites/bubble.spr");
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        g_bWantsO2[id] = is_user_bot(id) ? false : true;
        g_iLastColorState[id] = -1;
        g_bSpokenWarning[id] = false;
        g_iO2Tanks[id] = 0;
        g_iLastFrags[id] = 0;
        g_PlayerAlive[id] = true
    }
}

public client_disconnected(id)
{
    g_iLastColorState[id] = -1;
    g_bSpokenWarning[id] = false;
}

public OnPlayerKilled(id)
{
    clear_oxygen_hud_state(id);
}

public OnPlayerKilled_RewardCheck(victim, killer, shouldgib)
{
    if (!is_user_connected(killer) || g_bWantsO2[killer] || killer == victim)
        return;

    new iFragsNeeded = get_pcvar_num(g_cvar_o2_frags);
    if (iFragsNeeded <= 0)
        return;

    new iCurrentFrags = get_user_frags(killer);
    
    if (iCurrentFrags > 0)
    {
        new iOldMilestone = g_iLastFrags[killer] / iFragsNeeded;
        new iNewMilestone = iCurrentFrags / iFragsNeeded;

        if (iNewMilestone > iOldMilestone)
        {
            g_iO2Tanks[killer]++;
            emit_sound(killer, CHAN_ITEM, "items/ammopickup1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
            client_print(killer, print_center, "Earned an Oxygen Tank! (Total: %d)", g_iO2Tanks[killer]);
        }
    }
    
    g_iLastFrags[killer] = iCurrentFrags;
}

public msg_status_icon(msg_id, msg_dest, id)
{
    static sIcon[MAX_PLAYERS];
    get_msg_arg_string(1, sIcon, charsmax(sIcon));

    if (equal(sIcon, "oxygen"))
    {
        if (!g_msgHudColor)
        {
            return PLUGIN_HANDLED;
        }
    }

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
    static id;
    new Float:gameTime = get_gametime();
    for(id = 1; id < MaxClients+1  ; id++)
    {
        if (!g_PlayerAlive[id] || !g_bWantsO2[id])
        {
            clear_oxygen_hud_state(id);
            continue;
        }

        if (pev(id, pev_waterlevel) != UNDER_WATER)
        {
            clear_oxygen_hud_state(id);
            continue;
        }

        new Float:airFinished;
        pev(id, pev_air_finished, airFinished);

        new Float:remaining = airFinished - gameTime;
        
        if (remaining <= 0.0)
        {
            remaining = 0.0;
            
            if (g_iO2Tanks[id] > 0)
            {
                g_iO2Tanks[id]--;
                
                new Float:fNewAirTime = gameTime + OXYGEN_MAX_TIME;
                set_pev(id, pev_air_finished, fNewAirTime);
                remaining = OXYGEN_MAX_TIME;
                
                emit_sound(id, CHAN_ITEM, "items/ammopickup1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
                client_cmd(id, "spk ^"vox/tank used^"");
                client_print(id, print_center, "Oxygen Tank Used! Tanks left: %d", g_iO2Tanks[id]);
                
                g_bSpokenWarning[id] = false;

                new origin[3];
                get_user_origin(id, origin);

                new iBoxWidthOffset = 16;
                new iBoxFloorOffset = 10;
                new iBoxCeilingOffset = 32;
                new iBubbleRiseHeight = 45;
                new iBubbleDensityCount = 35;
                new iRiseSpeedMultiplier = 15;

                new iMinX = origin[0] - iBoxWidthOffset;
                new iMinY = origin[1] - iBoxWidthOffset;
                new iMinZ = origin[2] - iBoxFloorOffset;

                new iMaxX = origin[0] + iBoxWidthOffset;
                new iMaxY = origin[1] + iBoxWidthOffset;
                new iMaxZ = origin[2] + iBoxCeilingOffset;

                message_begin(MSG_PVS, SVC_TEMPENTITY);
                write_byte(TE_BUBBLES); 

                write_coord(iMinX);
                write_coord(iMinY);
                write_coord(iMinZ);

                write_coord(iMaxX);
                write_coord(iMaxY);
                write_coord(iMaxZ);

                write_coord(iBubbleRiseHeight);
                write_short(g_sModelIndexBubbles);
                write_byte(iBubbleDensityCount);
                write_coord(iRiseSpeedMultiplier);
                message_end();
            }
            else if (!g_bSpokenWarning[id])
            {
                g_bSpokenWarning[id] = true;
                
                new rRan = random(3);
                switch(rRan)
                {
                    case 0: client_cmd(id, "spk ^"vox/please surface from water now^"");
                    case 1: client_cmd(id, "spk ^"vox/warning evacuate liquid immediately go up alert^"");
                    case 2: client_cmd(id, "spk ^"vox/please leave water now you will die here^"");
                }
            }
        }

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

public PlayerLife(id)
{
    g_PlayerAlive[id] = is_user_alive(id) ? true : false
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
    g_bSpokenWarning[id] = false;

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
