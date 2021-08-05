#include amxmodx
#include engine
#include fakemeta

#define alert 911
new g_timer[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin("Connect Alert System","1.0","SPiNX");
    set_task(1.0, "@new_users",alert,"",0,"b");
}

public client_putinserver(index)

    if(!task_exists(index) && !is_user_bot(index))
    {
        set_task(0.5,"@alert", index)
        g_timer[index] = 0
    }

@alert()
    client_cmd(0,"spk ^"alert a intruder is here^"")

public client_authorized(id)
{
    client_print 0,print_chat,"%n is lurking...", id
    g_timer[id] = 0
    server_print "%n is lurking...", id
}

@new_users()
{
    new players[MAX_PLAYERS], playercount, downloader;
    get_players(players,playercount,"i");


    for (downloader=0; downloader<playercount; ++downloader)
    {

        if(is_user_connecting(players[downloader]))
        {
            new uptime = g_timer[players[downloader]]++
            server_print"%n uptime:%i", players[downloader], uptime

            if(uptime < 5)
            {
                client_print 0,print_chat,"%n is connecting...", players[downloader]
                server_print "%n is connecting...", players[downloader]
            }

            else
            {
                client_print 0,print_chat,"%n is downloading...", players[downloader]
                server_print "%n is downloading...", players[downloader]
            }

        }

        if(is_user_connected(players[downloader]) && !is_user_alive(players[downloader]) && !is_user_bot(players[downloader]))
        {
            new uptime = g_timer[players[downloader]]++
            if (uptime > 60)
            {
                dllfunc(DLLFunc_ClientPutInServer, players[downloader])
                if(callfunc_begin("@go_spec","of_spectate.amxx"))
                {
                    callfunc_push_int(players[downloader])
                    callfunc_end()
                }
            }
            else
                server_print( "%n is NO LONGER active...", players[downloader])
        }
    }
}
