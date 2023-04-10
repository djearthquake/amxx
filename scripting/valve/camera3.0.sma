#include <amxmodx>
#include <amxmisc>
#include <engine>
//#include <hamsandwich>

#define MAX_PLAYERS 32

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

public plugin_init()
{
    register_plugin("Camera Changer", "3.0", "XunTric|SPiNX");
    register_menucmd(register_menuid("Choose Camera View"), 1023, "setview");
    //RegisterHam(Ham_Spawn, "player", "client_spawn", 1);
    register_event_ex( "ResetHUD" , "client_spawn", RegisterEventFlags: RegisterEvent_Single)
    register_clcmd("say /cam", "chooseview", 0, "- displays camera menu");
    register_clcmd("say_team /cam", "chooseview", 0, "- displays camera menu");
    register_think("player","Fn_3rd_Person");
}

public client_disconnected(id)
{
    if(task_exists(id))
        remove_task(id);
}

public client_spawn(id)
{
    if(is_user_bot(id) || is_user_hltv(id) )
        return PLUGIN_HANDLED_MAIN;

    if(is_user_connected(id) && is_user_alive(id) )
    {
        set_view(id, CAMERA_NONE);
        console_cmd(id, "default_fov 100");
    }

    return PLUGIN_CONTINUE;
}

public Fn_3rd_Person(id)
{
    if(is_user_bot(id) || is_user_hltv(id) )
        return PLUGIN_HANDLED_MAIN;

    if(is_user_connected(id) && !is_user_alive(id) )

        {
            set_view(id, CAMERA_NONE);
            console_cmd(id, "default_fov 100");
        }

    return PLUGIN_CONTINUE;

}

public plugin_precache()
{
    #if AMXX_VERSION_NUM == 182
    precache_model("models/rpgrocket.mdl");
    #endif
}

public chooseview(id)
{
    new menu[192]
    new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3
    format(menu, charsmax(menu), "Choose Camera View^n^n1. 3rd Person View^n2. Upside View^n3. Normal View^n^n0. Exit")
    show_menu(id, keys, menu)
    return PLUGIN_CONTINUE
}

public setview(id, key, menu)
{
    if(key == 0) {
         set_view(id, CAMERA_3RDPERSON)
         return PLUGIN_HANDLED
    }

    if(key == 1) {
         set_view(id, CAMERA_TOPDOWN)
         return PLUGIN_HANDLED
    }

    if(key == 2) {
         set_view(id, CAMERA_NONE)
         return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE

}
