#include amxmodx
#include amxmisc
#include fun
#define ALIVE "a"
#define CMD amxclient_cmd //console_cmd
new g_bots_think, g_think_debug, g_think_speed, g_admin_only, g_bot_ammo

public plugin_init()
{
    register_plugin("Bot missile think","SPiNX","1.0")
    g_bots_think = register_cvar("deathwish_missile","0")
    g_think_speed = register_cvar("deathwish_missile_think","3")
    g_admin_only = register_cvar("deathwish_missile_vip","1")
    g_think_debug = register_cvar("deathwish_missile_debug","0")
    g_bot_ammo = register_cvar("deathwish_bot_ammo","amx_missile5")
}

public client_putinserver(id)
    !task_exists(1615) && is_user_bot(id) ? set_task(3.0, "bot_missile_think",1615,"",0,"b") : server_print("Bot missile think already active")

public client_disconnected(id)
    task_exists(1615) && get_playersnum(0) <= 1 ?  remove_task(1615) & server_print("Bot missile think removed.") : server_print("Bot missile think remaining active")

public bot_missile_think()
{
    new players[MAX_PLAYERS], playercount
    get_players(players,playercount, ALIVE);

    if(get_pcvar_num(g_bots_think) && playercount > 0)
    {

        for(new id=0;id < playercount;++id)

        //trying get bots to fire missile
        if( get_user_health(id) < 50.0)
        {

            if(is_user_alive(id) && !is_user_bot(id))

                (!is_user_admin(id) && !get_pcvar_num(g_admin_only) ? CMD(id,"amx_missile5") : CMD(id,"amx_missile6"))

            if(is_user_alive(id) && is_user_bot(id))
            {
                //new custom;
                //custom = random_num(1,5)
                //new formated[MAX_IP_LENGTH]
                //set_user_godmode(id,true)
                //formatex(formated,charsmax(formated), "amx_missile6")
                //CMD(id,formated);
                new bot_ammo[MAX_IP_LENGTH]
                get_pcvar_string(g_bot_ammo,bot_ammo, charsmax(bot_ammo))
                CMD(id,bot_ammo)
                //CMD(id,"bot_missile")
                //CMD(id,".sprite_blk_ops")//other mod, waypoint to draw in helecopter
                if(get_pcvar_num(g_think_debug) >1 )
                    server_print "Bot %n should have fired missile", id ;
                if(get_pcvar_num(g_think_debug) > 2)
                    client_print(0,print_console,"%n should be firing!",id);
            }

            if(get_pcvar_num(g_think_debug))
                server_print "Bio-=Missile =-Guidance project functional...";

        }

        change_task(1615,float(get_pcvar_num(g_think_speed))); //cvar the frequency of timing

    }

    return PLUGIN_CONTINUE;

}
