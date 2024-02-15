#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fun>

#define MAX_PLAYERS 32
#define PLUGIN "Scouts N knives" //some code may have been used / inspired by from Exolent on Random players. I was using get_players wrong even with direct dopy/paste it seemed so I made my own stock.
#define VOTE_ACCESS     ADMIN_ALL
#define DAMAGE_LEVEL ADMIN_LEVEL_F
#define VERSION "1.0"
static const CvarScoutDesc[]="- Knives only with 1 scout per team."
new votekeys = (1<<0)|(1<<1)
new g_counter[2];
new XScouts, bool:bNoBuy

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, ".sρiηX҉.");
    register_concmd("!scouts", "concmd_RandomPlayer", ADMIN_BAN, CvarScoutDesc);
    register_concmd("vote_scout_knives","cmdVoteScout",0,": Vote knives only with 1 scout per team.!");
    register_logevent("@NewRound", 2, "1=Round_Start");
    register_menucmd(register_menuid("Scout"),votekeys,"voteCount");
}

public plugin_precache()
{
    bind_pcvar_num(get_cvar_pointer("mp_scouts") ?
    get_cvar_pointer("mp_scouts") :
    create_cvar("mp_scouts", "0", FCVAR_SERVER, CvarScoutDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), XScouts)

    if(XScouts)
        @no_buy()
}

public CS_OnBuyAttempt(iPlayer, iHardware)
{
    if(bNoBuy)
        return PLUGIN_HANDLED;
    return PLUGIN_CONTINUE;
}

public voteCount(player, key)
{
    server_print "Being accessed!"
    client_print(0,print_chat,"%n voted for option #%d",player,key+1)
    ++g_counter[key];
}

public cmdVoteScout(player,level,cid)
{
    if(!is_user_connected(player))
        return PLUGIN_HANDLED

    if(!cmd_access(player,level,cid,1))
    {
        client_print(player,print_chat,"You do not have access to %s vote!",PLUGIN)
        return PLUGIN_HANDLED
    }

    if(task_exists(1402))
    {
        client_print(player,print_chat,"%s vote already in progress!",PLUGIN)
        return PLUGIN_HANDLED
    }

    new keys = MENU_KEY_1|MENU_KEY_2
    for(new i = 0; i < 2; i++)
        g_counter[i] = 0

    new menu[MAX_USER_INFO_LENGTH]

    new len; len = format(menu,charsmax(menu),"[AMX] 1 Scout per team n Knives?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes")
    len += format(menu[len],charsmax(menu),"^n2. No")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_scout_results",1402)
    return PLUGIN_HANDLED
}

public vote_scout_results()
{
    if(g_counter[0] > g_counter[1])
    {
        XScouts = 1
        @scouts_knives()
        bNoBuy = true
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") are now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], XScouts? "enabled" : "disabled")
    }
    else if(g_counter[1] > g_counter[0])
    {
        XScouts = 0
        bNoBuy = false
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^")  are now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], XScouts ? "enabled" : "disabled")
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed. No votes counted.", PLUGIN, VERSION)
        //client_cmd 0, "spk ^"%s^"", szSND
    }
}

@no_buy()
{
    new Ent = create_entity( "info_map_parameters" );
    DispatchKeyValue( Ent, "buying", "3" ) & DispatchSpawn( Ent )
}

public concmd_RandomPlayer(id)
{
    @scouts_knives()
}

@NewRound()
{
    if(XScouts)
        @scouts_knives()
}

@scouts_knives()
{
    stripweps()

    static player1, player2;
    static players[MAX_PLAYERS], iPnum;
    get_players(players, iPnum, "e", "TERRORIST");

    player1 = players[random(iPnum)];

    if(!player1)
    {
        //console_print(id, "[AMXX] Random player not found.");
        client_print 0, print_chat, "[AMXX] Random player not found."
        return PLUGIN_HANDLED;
    }

    get_players(players, iPnum, "e", "CT");

    player2 = players[random(iPnum)];

    if(!player2)
    {
        client_print 0, print_chat, "[AMXX] Random player not found."
        return PLUGIN_HANDLED;
    }

    static sName[MAX_PLAYERS];
    static const iNameLen = sizeof(sName) - 1

    get_user_name(player1, sName, iNameLen);
    client_print(0, print_chat, "[AMXX] Random player for Terrorist will be %s.", sName);

    get_user_name(player2, sName, iNameLen);
    client_print(0, print_chat, "[AMXX] Random player for CT will be %s.", sName);

    give_item(player1,"weapon_scout")
    give_item(player2,"weapon_scout")

    return PLUGIN_HANDLED;
}

stock stripweps()
{
    static Players[MAX_PLAYERS], PlayersNum, id
    get_players(Players, PlayersNum, "h")

    for( new i; i < PlayersNum; i++ )
    {
        id = Players[i]

        if( is_user_connected(id) && is_user_alive(id) )
        {
            strip_user_weapons(id)
            give_item(id,"weapon_knife")
        }
    }
}
