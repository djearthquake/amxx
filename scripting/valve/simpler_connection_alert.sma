#include amxmodx
#include engine
#include fakemeta

#define alert 911
#define SPEC_PRG "testing/of_spectate.amxx"
//Define your spec plugin pathway!
new g_timer[MAX_PLAYERS + 1]
new g_afk_spec_player, afk
new const CvarAFKTimeDesc[] = "Seconds before moving AFK player into spectator mode."
new sleepy[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin("Connect Alert System","1.0","SPiNX");
    set_task(1.0, "@new_users",alert,"",0,"b");
    bind_pcvar_num( create_cvar("mp_autospec", "90", FCVAR_NONE, CvarAFKTimeDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 300.0), g_afk_spec_player)
}

public client_putinserver(index)

    if(!task_exists(index) && !is_user_bot(index))
    {
        set_task(3.0,"@alert", index)
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
            new uptime = sleepy[players[downloader]]++
            client_print players[downloader],print_chat, "AFK time:%i", uptime

            if (uptime > g_afk_spec_player )
            {
                dllfunc(DLLFunc_ClientPutInServer, players[downloader])
                if(callfunc_begin("@go_spec",SPEC_PRG))
                log_amx "Sending %n to spec", players[downloader]
                {
                    callfunc_push_int(players[downloader])
                    callfunc_end()
                    sleepy[players[downloader]] = 0
                }
            }
            else
                server_print( "%n is NO LONGER active...", players[downloader])
        }
    }
}
