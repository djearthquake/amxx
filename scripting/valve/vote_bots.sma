#include amxmodx
#include amxmisc

new votekeys = (1<<0)|(1<<1)|(1<<2)|(1<<3)
new g_counter[4];
new g_round_counter
new XBots
new bool: bCStrike;
new bool: bCZtrike;
new bool: bFlagMap;

static const CvarBotDesc[]="- Allow vote for bots."
static Bots[4][MAX_RESOURCE_PATH_LENGTH]
new Float:fFake_Round

#define MAX_PLAYERS 32
#define PLUGIN "vote_bots"
#define VOTE_ACCESS     ADMIN_USER|ADMIN_CFG
#define VERSION "1.0.2"
#define charsmin    -1

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, ".sρiηX҉.");
    //mod
    static mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name))

    static mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname))

    if(equal(mod_name, "cstrike") || get_cvar_pointer("pb"))
    {
        bCStrike = true
    }
    else if(equal(mod_name, "czero") || get_cvar_pointer("bot_quota"))
    {
        bCZtrike = true
    }
    //map
    bFlagMap = containi(mname,"op4c") > charsmin?true:false
    //log_events
    if(bCStrike)
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
    if(bCZtrike) //cz
    {
        Bots[0] = "bot_quota 5"
        Bots[1] = "bot_quota 11"
        Bots[2] = "bot_quota 0"
    }
    else if(bCStrike) //cs
    {
        Bots[0] = "pb remove;pb_minbots 5;pb_maxbots 5"
        Bots[1] = "pb_minbots 11;pb_maxbots 11"
        Bots[2] = "pb_minbots 0;pb_maxbots 0;pb remove"
    }
    else if(!bFlagMap) //deathmatch
    {
        Bots[0] = "jk_botti max_bots 5"
        Bots[1] = "jk_botti max_bots 11"
        Bots[2] = "jk_botti max_bots 0"
    }
    else //flag map
    {
        Bots[0] = "HPB_Bot max_bots 9"
        Bots[1] = "HPB_Bot max_bots 20;HPB_Bot min_bots 2"
        Bots[2] = "HPB_Bot max_bots 0"
    }
}

public round_start()
{
    if(XBots >1)
    {
        g_round_counter++
        if(!bCStrike || !bCZtrike)
        {
            round_end();
        }
    }
}

public round_end()
{
    if(XBots >1)
    {
        if(g_round_counter>2)
        {
            ServerBots()
            g_round_counter = 0;
            if(!bCStrike || !bCZtrike)
            {
                fFake_Round = random_float(30.0, 210.0)
                change_task(2024, fFake_Round)
            }
        }
    }
}

public client_putinserver(id)
{
    if(XBots)
    if(!bCStrike || !bCZtrike && !task_exists(2024))
    {
        fFake_Round = random_float(60.0, 120.0)
        set_task(fFake_Round, "round_start", 2024, _,_, "b")
    }
    set_task 7.0, "@Advert", id
}

@Advert(id)
{
    if(is_user_connected(id) && !is_user_bot(id))
    {
        client_print id, print_chat, "Use command vote_bots."
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
    for(new list = 1;list <= MaxClients;++list)
    if(is_user_connected(list) && is_user_bot(list))
    {
        server_print("Starting purge %N", list)
        console_cmd(0,"amx_kick %n ^"Purging bots.^"",list);
    }
    return PLUGIN_HANDLED
}

//vote handling
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

    static keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4
    for(new i = 0; i < 4; i++)
        g_counter[i] = 0

    static menu[MAX_USER_INFO_LENGTH]

    static len; len = format(menu,charsmax(menu),"[AMX] Bots?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes^n")
    len += format(menu[len],charsmax(menu),"^n2. Fill^n")
    len += format(menu[len],charsmax(menu),"^n3. No^n")
    len += format(menu[len],charsmax(menu),"^n4. Not voting^n")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_bot_results",1402)
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
    else if(g_counter[2] > g_counter[1] || g_counter[2] >  g_counter[0])
    {
        XBots = 0
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (fill ^"%d^") (no ^"%d^")  Bots are now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], g_counter[2], XBots ? "enabled" : "disabled")
        console_cmd( 0, Bots[2] )
        {
            set_task 1.5, "@zero_bots", 2025,_,_,"a", 3
        }
    }
    else if(g_counter[0] == g_counter[1] && g_counter[0] == g_counter[2] || g_counter[0] == g_counter[2] >> g_counter[1] || g_counter[1] == g_counter[2] >> g_counter[0])
    {
        client_print(0,print_chat,"[%s %s] Voting tied. No changes.", PLUGIN, VERSION)
    }
    else if(g_counter[3] == 0 &&  g_counter[2] == 0 &&  g_counter[1] == 0 && g_counter[0] == 0)
    {
        client_print(0,print_chat,"[%s %s] Nobody voted. No changes.", PLUGIN, VERSION)
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed or tied. No votes counted.", PLUGIN, VERSION)
    }
}
