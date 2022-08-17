#include amxmodx
//If client retries in 20 sec auto CT.
#define SNAKE 5000
#define disconnected disconnect

public plugin_init()
{
    register_plugin("Force CT on 20s retry","A",".sρiηX҉.");
}

public client_putinserver(id)
{
    set_user_info(id,"_vgui_menus", "0")

    if(task_exists(id+SNAKE))
        change_task(id+SNAKE, 0.3) &&
        set_msg_block( get_user_msgid( "MOTD" ), BLOCK_SET );
    else
        CS_OnBuyAttempt(id)
}

public set_team_ct(TaskID)
{
    new id = TaskID-SNAKE
    set_user_info(id,"_vgui_menus", "0")

    client_cmd(id,"jointeam 2");
}

public CS_OnBuyAttempt(id){ set_user_info(id,"_vgui_menus", "0");}

public client_disconnected(id)
{
    set_task(20.0,"set_team_ct", id+SNAKE);
}
