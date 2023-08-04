//If client retries in 20 sec auto CT.
#include amxmodx
#include amxmisc
#include cstrike
#include hamsandwich

#define SNAKE 5000
#if !defined disconnected
#define disconnected disconnect
#endif

static g_iTeam, g_iMotd
new const SzCMD[]="sv_restartround 3"

public plugin_init()
{
    register_plugin("Force CT on 20s retry","B",".sρiηX҉.");
    g_iMotd = get_user_msgid( "MOTD" )
    g_iTeam = get_user_msgid( "TeamInfo" )
}

public client_putinserver(id)
{
    if(is_user_connected(id) && task_exists(id+SNAKE) && !is_user_bot(id))
    {
        set_msg_block(g_iTeam, BLOCK_SET);
        set_msg_block(g_iMotd, BLOCK_SET);

        cs_set_user_team(id, 2);
        change_task(id+SNAKE, 2.0);
    }
}

public set_team_ct(TaskID)
{
    set_msg_block(g_iMotd, BLOCK_NOT);
    static id;id =TaskID-SNAKE
    if(is_user_connected(id))
    {
        ExecuteHamB(Ham_CS_RoundRespawn, id); // do after round start after checks
        if(is_user_admin(id))
            console_cmd( 0, SzCMD );
    }
}

public client_disconnected(id)
{
    if(!is_user_bot(id))
        set_task(20.0,"set_team_ct", id+SNAKE);
}
