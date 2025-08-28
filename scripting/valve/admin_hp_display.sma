/*Intended for Windowed-mode*/

#include amxmodx
#include amxmisc
#include fakemeta

#define PLUGIN  "HP Display"
#define VERSION "0.0.1"
#define AUTHOR  "SPiNX"

#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/"

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 || AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR);
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);
    #endif
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        set_task(1.0, "@admin_check",id);
    }

}

@admin_check(id)
{
    if(is_user_admin(id))
    {
        set_task 0.5, "@show_hp",id,_,_,"b"
        client_print id, print_console, "ADMIN"
    }
}

@show_hp(id)
{
    if(is_user_alive(id))
    {
        static hp; hp = pev(id, pev_health);
        static arm; arm = pev(id, pev_armorvalue);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

        client_print id, print_center, arm ? "%i|%i" : "%i", hp, arm ;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }

}

public client_disconnected(id)
{
    if(task_exists(id))
    {
        remove_task(id)
    }

}
