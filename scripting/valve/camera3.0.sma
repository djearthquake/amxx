#include <amxmodx>
#include <engine>
#include <hamsandwich>

#define PLUGIN "Camera Changer"
#define VERSION "3.1"
#define AUTHOR "SPiNX"

#if !defined CAMERA_UPLEFT
    #define CAMERA_UPLEFT 3
#endif

new g_IsBot;
new bool:g_SupportsModernUI;

#define set_bit(%1,%2)      (%1 |= (1<<(%2 & 31)))
#define clear_bit(%1,%2)    (%1 &= ~(1<<(%2 & 31)))
#define get_bit(%1,%2)      (%1 & (1<<(%2 & 31)))

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    if (get_user_msgid("StatusValue") > 0)
    {
        g_SupportsModernUI = true;
    }

    register_clcmd("say /cam", "cmdMenu");
    register_clcmd("say_team /cam", "cmdMenu");

    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);

    register_menucmd(register_menuid("CamMenuClassic"), 1023, "handleClassicMenu");
}

public plugin_precache()
{
    precache_model("models/rpgrocket.mdl");
}

public client_putinserver(id)
{
    set_bit(g_IsBot, (is_user_bot(id) || is_user_hltv(id)) ? 1 : 0);
}

public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id) || get_bit(g_IsBot, id)) return;
    set_view(id, CAMERA_NONE);
}

public fw_PlayerKilled_Post(id)
{
    set_view(id, CAMERA_NONE);
}

public cmdMenu(id)
{
    if (!is_user_alive(id) || get_bit(g_IsBot, id)) return PLUGIN_HANDLED;

    if (g_SupportsModernUI)
        show_modern_menu(id);
    else
        show_classic_menu(id);

    return PLUGIN_HANDLED;
}

public show_modern_menu(id)
{
    new menu = menu_create("\yCamera View", "handleModernMenu");
    menu_additem(menu, "3rd Person", "0");
    menu_additem(menu, "Top-Down", "1");
    menu_additem(menu, "Top-Left (Isometric)", "2");
    menu_additem(menu, "Normal View", "3");
    menu_display(id, menu, 0);
}

public handleModernMenu(id, menu, item)
{
    if (item != MENU_EXIT && is_user_alive(id))
    {
        apply_camera(id, item);
    }
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public show_classic_menu(id)
{
    static menu[256];
    new len = 0;

    len += formatex(menu[len], charsmax(menu) - len, "\yCamera View^n^n");
    len += formatex(menu[len], charsmax(menu) - len, "1. 3rd Person^n");
    len += formatex(menu[len], charsmax(menu) - len, "2. Top-Down^n");
    len += formatex(menu[len], charsmax(menu) - len, "3. Top-Left^n");
    len += formatex(menu[len], charsmax(menu) - len, "4. Normal View^n^n");
    len += formatex(menu[len], charsmax(menu) - len, "0. Exit");

    show_menu(id, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<9), menu, -1, "CamMenuClassic");
}

public handleClassicMenu(id, key)
{
    if (is_user_alive(id) && key != 9)
    {
        apply_camera(id, key);
    }
    return PLUGIN_HANDLED;
}

apply_camera(id, type)
{
    switch (type)
    {
        case 0: set_view(id, CAMERA_3RDPERSON);
        case 1: set_view(id, CAMERA_TOPDOWN);
        case 2: set_view(id, CAMERA_UPLEFT);
        case 3: set_view(id, CAMERA_NONE);
    }
}
