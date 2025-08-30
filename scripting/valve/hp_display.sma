/*Intended for Windowed-mode*/

#include amxmodx
#include amxmisc
#include fakemeta

#define PLUGIN  "HP Display"
#define VERSION "0.0.3"
#define AUTHOR  "SPiNX"

#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/"

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 || AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR);
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);
    #endif

    register_concmd("show_hp","cmdHP",0,": Show your HP in windowed-mode.");
}

public cmdHP(id,level,cid)
{
    if(!is_user_connected(id))
        return PLUGIN_HANDLED

    if(!cmd_access(id,level,cid,1))
    {
        client_print(id,print_chat,"You do not have access to %s %s by %s!",PLUGIN, VERSION, AUTHOR)
        return PLUGIN_HANDLED
    }

    task_exists(id) ? remove_task(id) : @task_hp(id);

    return PLUGIN_HANDLED
}

@task_hp(id)
{
    if(is_user_connected(id))
    {
        set_task 1.0, "@show_hp",id,_,_,"b"
    }
}

@show_hp(id)
{
    if(is_user_alive(id))
    {
        static hp; hp = pev(id, pev_health);
        static arm; arm = pev(id, pev_armorvalue);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

        //client_print id, print_center, arm ? "%i|%i" : "%i", hp, arm ;
        set_hudmessage(255, 255, 255, 0.02, 0.89, .effects= 0 , .holdtime= 5.0)
        show_dhudmessage id, arm ? "%i|%i" : "%i", hp, arm ;
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
