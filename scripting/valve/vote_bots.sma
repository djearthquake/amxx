#include amxmodx
#include amxmisc

new votekeys = (1<<0)|(1<<1)|(1<<2)
new g_counter[3];
new g_round_counter
new XBots
new bool: gCStrike
new bool: bFlagMap

static const CvarBotDesc[]="- Allow vote for bots."
static Bots[3][MAX_PLAYERS]
new Float:fFake_Round

#define MAX_PLAYERS 32
#define PLUGIN "vote_bots"
#define VOTE_ACCESS     ADMIN_USER|ADMIN_CFG
#define VERSION "1.0"
#define charsmin    -1

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, ".sρiηX҉.");
    //mod
    static mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name))

    static mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname))

    if(equal(mod_name, "cstrike") || equal(mod_name, "czero"))
    {
        gCStrike = true
    }
    //map
    bFlagMap = containi(mname,"op4c") > charsmin?true:false
    //log_events
    if(gCStrike)
    {
        register_logevent("round_start", 2, "1=Round_Start")
        register_logevent("round_end", 2, "1=Round_End")
    }
    //vote
    register_menucmd(register_menuid("Bots"),votekeys,"voteCount");
    //commands
    register_concmd("vote_bots","cmdVoteBots",0,": Vote bots.");
    //binds cvars
    bind_pcvar_num(get_cvar_pointer("vote_bot") ? get_cvar_pointer("vote_bot") :
    create_cvar("vote_bot", "0", FCVAR_NONE, CvarBotDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), XBots )
}


//Admins load up bot commands.
public plugin_cfg()
{
    if(gCStrike) //cz for now
    {
        Bots[0] = "bot_quota 5"
        Bots[1] = "bot_quota 11"
        Bots[2] = "bot_quota 0"
    }
    else if(!bFlagMap) //deathmatch
    {
        Bots[0] = "jk_botti max_bots 5"
        Bots[1] = "jk_botti max_bots 11"
        Bots[2] = "jk_botti max_bots 0"
    }
    else //flag map
    {
        Bots[0] = "HPB_Bot max_bots 5"
        Bots[1] = "HPB_Bot max_bots 11"
        Bots[2] = "HPB_Bot max_bots 0"
    }
}

public round_start()
{
    g_round_counter++
    if(!gCStrike)
    {
        round_end();
    }
}

public round_end()
{
    if(g_round_counter>2)
    {
        ServerBots()
        g_round_counter = 0;
        if(!gCStrike)
        {
            fFake_Round = random_float(30.0, 210.0)
            change_task(2024, fFake_Round)
        }
    }
}

public client_putinserver()
{
    if(XBots)
    if(!gCStrike && !task_exists(2024))
    {
        fFake_Round = random_float(60.0, 120.0)
        set_task(fFake_Round, "round_start", 2024, _,_, "b")
    }
}

public client_disconnected()
{
    if(XBots)
    if(!get_playersnum())
    {
        remove_task(2024)
    }
}

@zero_bots()
{
    server_cmd("jk_botti min_bots 0;jk_botti max_bots 0;HPB_Bot min_bots 0; HPB_Bot max_bots 0")
    for(new list = 1 ;list <= MaxClients;++list)
    if(is_user_connected(list) && is_user_bot(list))
    {
        server_print("Starting purge %N", list)
        server_cmd("kick %n ^"Purging bots.^"",list);
    }
    return PLUGIN_HANDLED
}
//vote handling
public voteCount(player, key)
{
    server_print "Being accessed!"
    client_print(0,print_chat,"%n voted for option #%d",player,key+1)
    ++g_counter[key];
}

public ServerBots()
{
    if(task_exists(1402))
    {
        client_print(0, print_chat,"%s vote already in progress!",PLUGIN)
        return PLUGIN_HANDLED
    }

    new keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3
    for(new i = 0; i < 3; i++)
        g_counter[i] = 0

    new menu[MAX_USER_INFO_LENGTH]

    new len; len = format(menu,charsmax(menu),"[AMX] Bots?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes^n")
    len += format(menu[len],charsmax(menu),"^n2. Fill^n")
    len += format(menu[len],charsmax(menu),"^n3. No^n")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_bot_results",1402)
    return PLUGIN_HANDLED
}

public cmdVoteBots(player,level,cid)
{
    if(!is_user_connected(player))
        return PLUGIN_HANDLED

    if(!cmd_access(player,level,cid,1))
    {
        client_print(player,print_chat,"You do not have access to %s vote!",PLUGIN)
        return PLUGIN_HANDLED
    }
    ServerBots()
    return PLUGIN_HANDLED
}

public vote_bot_results()
{
    if(g_counter[0] > g_counter[1] && g_counter[0] > g_counter[2])
    {
        XBots = 1
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (fill ^"%d^") (no ^"%d^") Bots are now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], g_counter[2], XBots? "enabled" : "disabled")
        console_cmd( 0, Bots[0] )
    }
    else if(g_counter[1] > g_counter[0] && g_counter[1] > g_counter[2])
    {
        XBots = 1
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (fill ^"%d^") (no ^"%d^")  Bot fill is now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], g_counter[2], XBots ? "enabled" : "disabled")
        console_cmd( 0, Bots[1] )
    }
    else if(g_counter[1] != 0 &&  g_counter[1] == g_counter[0])
    {
        XBots = 1
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (fill ^"%d^") (no ^"%d^")  Bots are now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], g_counter[2], XBots ? "enabled" : "disabled")
        console_cmd( 0, Bots[0] )
    }
    else if(g_counter[2] > g_counter[0] && g_counter[2] > g_counter[1])
    {
        XBots = 0
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (fill ^"%d^") (no ^"%d^")  Bots are now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], g_counter[2], XBots ? "enabled" : "disabled")
        console_cmd( 0, Bots[2] )
        if(!gCStrike)
        {
            @zero_bots()
        }
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed or tied. No votes counted.", PLUGIN, VERSION)
    }
}
