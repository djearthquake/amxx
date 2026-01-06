#include amxmodx
#include amxmisc
#include fakemeta
#include fun
#define ALIVE "a"
//#define CMD client_cmd //console_cmd
#define CMD amxclient_cmd //console_cmd
#define charsmin -1
new g_bots_think, g_think_debug, g_think_speed, g_admin_only, g_bot_ammo, g_bot_trigger_hp
new bool:bIsBot[ MAX_PLAYERS + 1], bool:bIsAdmin[ MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin("Bot missile think","SPiNX","1.2")
    g_bots_think = register_cvar("deathwish_missile","1")
    g_think_speed = register_cvar("deathwish_missile_think","2")
    g_admin_only = register_cvar("deathwish_missile_vip","0")
    g_think_debug = register_cvar("deathwish_missile_debug","0")
    g_bot_ammo = register_cvar("deathwish_bot_ammo","amx_missile5")
    g_bot_trigger_hp = register_cvar("deathwish_hp","10")
    /*Be sure to allow in cmdaccess.ini*/
}

public client_putinserver(id)
{

    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
    }

    !task_exists(1615) && bIsBot[id] ? set_task(3.0, "bot_missile_think",1615,"",0,"b") : server_print("Bot missile think already active")
}

public client_infochanged(id)
{
    if(is_user_connected(id) && !bIsBot[id])
    {
        bIsAdmin[id] = is_user_admin(id) ? true : false
    }
}

public client_disconnected(id)
    task_exists(1615) && get_playersnum(0) <= 1 ?  remove_task(1615) & server_print("Bot missile think removed.") : server_print("Bot missile think remaining active")

public bot_missile_think()
{
    static iHP; iHP = get_pcvar_num(g_bot_trigger_hp)
    new players[MAX_PLAYERS], playercount
    get_players(players,playercount, ALIVE);

    if(get_pcvar_num(g_bots_think) && playercount > 1)
    {

        for(new id=0; id < playercount;++id)
        {

            //trying get bots to fire missile
            if(pev(players[id],pev_health)<iHP)
            {

                if(!bIsBot[players[id]])

                    (!bIsAdmin[players[id]] && !get_pcvar_num(g_admin_only) ? CMD(players[id],"amx_missile5") : CMD(players[id],"amx_missile6"))

                else
                {
                    //new custom;
                    //custom = random_num(1,5)
                    //new formated[MAX_IP_LENGTH]
                    //set_user_godmode(id,true)
                    //formatex(formated,charsmax(formated), "amx_missile6")
                    //CMD(id,formated);
                    new bot_ammo[MAX_IP_LENGTH]
                    get_pcvar_string(g_bot_ammo,bot_ammo, charsmax(bot_ammo))
                    CMD(players[id],bot_ammo)
                    switch(@ran_shot())
                    {
                        case 0: CMD(players[id], "amx_missile")
                        case 1: CMD(players[id], "amx_laserguided_missile")
                        case 2: CMD(players[id], "amx_heatseeking_missile")
                        case 3: CMD(players[id], "amx_anti_missile")
                        case 4: CMD(players[id], "amx_swirlingdeath_missile")
                        case 5: CMD(players[id], "amx_Parachuteseeking_missile")
                    }
                    //@bot_fire(id)
                    //CMD(id,"bot_missile")
                    //CMD(id,".sprite_blk_ops")//other mod, waypoint to draw in helecopter
                    if(get_pcvar_num(g_think_debug) >1 )
                        server_print "Bot %n should have fired missile", players[id]
                    if(get_pcvar_num(g_think_debug) > 2)
                        server_print "%n should be firing!", players[id]
                }

                if(get_pcvar_num(g_think_debug))
                    server_print "Bio-=Missile =-Guidance project functional...on %n", players[id];

            }

        }

        change_task(1615,float(get_pcvar_num(g_think_speed))); //cvar the frequency of timing

    }

    return PLUGIN_CONTINUE;

}

@ran_shot()return random(6);
