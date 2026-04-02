#include <amxmodx>
#include <engine>
#include <hamsandwich>

#define PLUGIN "Camera Changer"
#define VERSION "3.7"
#define AUTHOR "SPiNX"

#if !defined CAMERA_UPLEFT
    #define CAMERA_UPLEFT 3
#endif

new g_IsBot;
new g_IsConnected;

#define set_bit(%1,%2)      (%1 |= (1<<(%2 & 31)))
#define clear_bit(%1,%2)    (%1 &= ~(1<<(%2 & 31)))
#define get_bit(%1,%2)      (%1 & (1<<(%2 & 31)))

public plugin_precache()
{
    precache_model("models/rpgrocket.mdl");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say /cam", "cmdMenu");
    register_clcmd("say_team /cam", "cmdMenu");

    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);

    register_menucmd(register_menuid("CamMenu"), 1023, "handleMenu");
}

public client_putinserver(id)
{
    set_bit(g_IsConnected, id);

    if (is_user_bot(id) || is_user_hltv(id))
    {
        set_bit(g_IsBot, id);
    }
    else
    {
        clear_bit(g_IsBot, id);
    }
}

public client_disconnected(id)
{
    clear_bit(g_IsConnected, id);
    clear_bit(g_IsBot, id);
}

public fw_PlayerSpawn_Post(id)
{
    if (get_bit(g_IsBot, id) || !is_user_alive(id))
    {
        return;
    }

    set_view(id, CAMERA_NONE);
    client_cmd(id, "default_fov 100");
}

public fw_PlayerKilled_Post(id)
{
    set_view(id, CAMERA_NONE);
}

public cmdMenu(id)
{
    if (get_bit(g_IsBot, id))
    {
        return PLUGIN_HANDLED;
    }

    static menu[256];
    static len;
    len = 0;

    len += formatex(menu[len], charsmax(menu) - len, "\yCamera View^n^n");
    len += formatex(menu[len], charsmax(menu) - len, "\r1. \w3rd Person^n");
    len += formatex(menu[len], charsmax(menu) - len, "\r2. \wTop-Down^n");
    len += formatex(menu[len], charsmax(menu) - len, "\r3. \wTop-Left (Isometric)^n");
    len += formatex(menu[len], charsmax(menu) - len, "\r4. \wNormal View^n^n");
    len += formatex(menu[len], charsmax(menu) - len, "\r0. \wExit");

    show_menu(id, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<9), menu, -1, "CamMenu");
    return PLUGIN_HANDLED;
}

public handleMenu(id, key)
{
    if (!is_user_alive(id))
    {
        return PLUGIN_HANDLED;
    }

    switch (key)
    {
        case 0:
        {
            set_view(id, CAMERA_3RDPERSON);
        }
        case 1:
        {
            set_view(id, CAMERA_TOPDOWN);
        }
        case 2:
        {
            set_view(id, CAMERA_UPLEFT);
        }
        case 3:
        {
            set_view(id, CAMERA_NONE);
        }
    }
    return PLUGIN_HANDLED;
}
