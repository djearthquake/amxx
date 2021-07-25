#include amxmodx
#include amxmisc
#include engine
#include hamsandwich
#define NOT_RIGHT AMXX_VERSION_NUM != 190 && AMXX_VERSION_NUM != 110

public plugin_init()
    RegisterHam(Ham_Spawn, "player", "client_spawn", 1) && RegisterHam(Ham_Killed, "player", "client_death") &&
    register_plugin("Death cam", "1.0", "SPiNX")

#if NOT_RIGHT
#define client_disconnected client_disconnect

public plugin_precache()
    precache_model("models/rpgrocket.mdl");
#endif

public client_putinserver(id)
    if(is_user_connected(id))
        set_task(0.5,"client_spawn",id)

public client_disconnected(id)
    if(task_exists(id))
        remove_task(id)

public client_spawn(id)
    if(is_user_connected(id) && !is_user_bot(id) || is_user_connected(id) && !is_user_hltv(id))
        set_view(id, CAMERA_NONE) &&
        console_cmd(id, "default_fov 100")

public client_death(victim,killer)

    if(killer > 0 && is_user_connected(victim) && killer != victim  && !is_user_alive(victim) && !is_user_bot(victim) && is_user_connected(killer))
        set_view(victim, CAMERA_3RDPERSON) &&
        console_cmd(victim, "default_fov 150")
