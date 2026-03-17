/*
 * camera_cycle.sma
 *
 * Purpose:
 * Allows players to cycle through available map cameras via a slideshow.
 * Includes a chat notification for the current camera index.
 *
 * Copyright (C) 2026 SPiNX
 * Refined by AI on Google Search
 */

#include <amxmodx>
#include <engine>
#include <hamsandwich>

#define MAX_CAMS 6

new g_Cameras[MAX_CAMS];
new g_CamCount;
new g_pSlideShow;
new g_PlayerCamIndex[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin("Camera Cycle Optimized", "1.5", ".sρiηX҉.");

    register_clcmd("check_camera", "cmd_check_camera");
    g_pSlideShow = register_cvar("camera_slideshow", "1");
}

public plugin_cfg()
{
    g_CamCount = 0;
    new ent = -1;

    while ((ent = find_ent_by_class(ent, "trigger_camera")) > 0 && g_CamCount < MAX_CAMS)
    {
        g_Cameras[g_CamCount++] = ent;
    }
}

public client_disconnected(id)
{
    remove_task(id);
}

public cmd_check_camera(id)
{
    if (g_CamCount == 0)
    {
        client_print(id, print_chat, "* No cameras found on this map.");
        return PLUGIN_HANDLED;
    }

    remove_task(id);

    g_PlayerCamIndex[id] = 0;
    use_camera(id, 0);

    client_print(id, print_chat, "* Viewing Camera: 1 of %d", g_CamCount);

    if (get_pcvar_num(g_pSlideShow) && g_CamCount > 1)
    {
        set_task(5.0, "task_cycle_camera", id, _, _, "b");
    }

    return PLUGIN_HANDLED;
}

public task_cycle_camera(id)
{
    if (!is_user_connected(id))
    {
        remove_task(id);
        return;
    }

    g_PlayerCamIndex[id]++;

    if (g_PlayerCamIndex[id] >= g_CamCount)
    {
        client_print(id, print_chat, "* Camera slideshow finished.");
        remove_task(id);
        return;
    }

    use_camera(id, g_PlayerCamIndex[id]);
    client_print(id, print_chat, "* Viewing Camera: %d of %d", g_PlayerCamIndex[id] + 1, g_CamCount);
}

use_camera(id, index)
{
    if (index < g_CamCount && is_valid_ent(g_Cameras[index]))
    {
        ExecuteHamB(Ham_Use, g_Cameras[index], id, id, 3, 1.0);
    }
}
