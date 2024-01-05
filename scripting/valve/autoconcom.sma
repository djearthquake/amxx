//updated JAN 4 2024
#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Autoconcom"
#define VERSION "J" //Make sure bots can be zeroed automatically with players and admin command.
#define AUTHOR "SPINX"

#define NUKE "amx_leave *"

#define MAX_PLAYERS                32

#define MAX_RESOURCE_PATH_LENGTH   64

#define MAX_MENU_LENGTH            512

#define MAX_NAME_LENGTH            32

#define MAX_AUTHID_LENGTH          64

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1

new g_name[MAX_PLAYERS +1];
new g_bot_min, g_bot_max, g_bot_control, g_iHeadcount;
new const SzAdvert[] = "Presenting the OP4 (C)apture (T)he (F)lag legacy bot(s)...with b-team tags"
new const SzFlagCapMap[] = "op4c"
new bool:FirstRun
static bool:bStrike
static g_mname[MAX_NAME_LENGTH]

public OnAutoConfigsBuffered() @zero_bots()

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    g_bot_min = register_cvar("sv_autocon_botmin", "0");
    g_bot_max = register_cvar("sv_autocon_botmax", "0");

    g_bot_control = register_cvar("sv_autocon_autobot", "1");

    get_mapname(g_mname,charsmax(g_mname));
    bStrike = cstrike_running() ? true : false
    register_clcmd("amx_purge_bots", "@zero_bots", ADMIN_CFG, "- Remove all bots!")
}

public plugin_natives()
{
    register_native("autocon_botmin", "@bots_native_min")
    register_native("autocon_botmax", "@bots_native_max")
}

@bots_native_min(iMin)
    server_cmd "jk_botti min_bots %i;", iMin;

@bots_native_max(iMax)
    server_cmd "jk_botti max_bots %i;", iMax;

public plugin_cfg()
{
    set_task(2.0, "@zero_bots", 2023)
    //set_task_ex(30.0, "plugin_end", 2023, .flags = SetTask_BeforeMapChange, .repeat = 1 );
    set_task(2.5,"mop_bot", 186)
}

public plugin_end()
{
    @zero_bots()
    //set_task(2.5,"mop_bot", 186)
}

public client_putinserver(id)
{
    if(get_pcvar_num(g_bot_control))
    {
        if(!is_user_bot(id) && is_user_connected(id) && id > 0)
        {
            if(!task_exists(210012))
                set_task(5.0,"on_join", 210012);
        }
    }
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        get_user_name(id, g_name, charsmax(g_name))
        if(is_user_bot(id) && containi(g_name,"(1)") > -1 )
        {
            server_cmd("amx_kick (1)%s ^"bot_infochanged_badname^"",g_name);
        }
    }
}

public client_disconnected(id)
{
    if (!bStrike)
    if (!is_user_bot(id))
    if (!is_user_hltv(id))

    if (get_pcvar_num(g_bot_control))
    {
        static mname[MAX_PLAYERS];
        static numplayers; numplayers = iPlayers();
        get_mapname(mname,charsmax(mname));

        if ( (containi(mname,SzFlagCapMap) > -1) && (numplayers < 2) )
        {
            //set_task_ex(1.0, "on_join", 34, .flags = SetTask_RepeatTimes, .repeat = 1 );
            set_task(1.0,"on_join", 34)
            //set_task_ex(5.0, "on_exit", 56, .flags = SetTask_RepeatTimes, .repeat = 1 );
            set_task(5.0, "on_exit", 56)
        }
        else if (numplayers > 1 && numplayers < 5)
        {
            if(!task_exists(340043))
                //set_task_ex(10.0, "on_join", 340043, .flags = SetTask_RepeatTimes, .repeat = 1 );
                set_task(10.0, "on_join", 340043)
        }
        else
        {
            @zero_bots()
        }
    }
}

public bots_()
{
    if(iPlayers())
    {
        static min; min = get_pcvar_num(g_bot_min);
        static max; max = get_pcvar_num(g_bot_max);
        if(!FirstRun)
        {
            @zero_bots();
            FirstRun = true
        }
        server_cmd("jk_botti min_bots %i; jk_botti max_bots %i;", min, max);
        return;
    }
    @zero_bots();
}

public bots_flag()
{

    static mname[MAX_NAME_LENGTH];
    get_mapname(mname,charsmax (mname));
    static adjmsize, Float:mega;
    mega = (0.001);
    static Float:msize; msize = (filesize("maps/%s.bsp",mname, charsmax (mname))*(mega)/1024)
    adjmsize = floatround(msize, floatround_ceil);

    static numplayers; numplayers = iPlayers()

    if (numplayers > 1)
    {
        new g_Bots_Min = floatround(adjmsize * 1.5) + 2;
        new g_Bots_Max = floatround(adjmsize * 2.5) + 4;
        server_cmd("HPB_Bot min_bots %i; HPB_Bot max_bots %i", g_Bots_Min, g_Bots_Max);
        server_print ("%s",SzAdvert)
    }

    else
        @zero_bots()
}

public on_exit(id)
{
    if (get_pcvar_num(g_bot_control))
    {
        new numplayers = iPlayers()

        if ( numplayers || cstrike_running() )
            return;

        else
        {
            @zero_bots()
            //set_task_ex(5.0, "mop_bot", 186, .flags = SetTask_RepeatTimes, .repeat = 2 );
            set_task(5.0, "mop_bot", 186, "a", 2)
            server_cmd NUKE
        }
    }
}

public mop_bot()
{
    //set_task_ex(15.0, "on_join", 186, .flags = SetTask_RepeatTimes, .repeat = 0 );
    set_task(15.0, "on_join", 186)
}

@zero_bots()
{
    server_cmd("jk_botti min_bots 0;jk_botti max_bots 0;HPB_Bot min_bots 0; HPB_Bot max_bots 0")
    for(new list;list <= MaxClients;++list)
    if(is_user_connected(list) && is_user_bot(list))
    {
        server_cmd("amx_kick %n ^"Purging bots.^"",list);
    }
    return PLUGIN_HANDLED
}

public on_join()
{
    new numplayers = iPlayers()

    if (get_pcvar_num(g_bot_control))
    {
        if (containi(g_mname, SzFlagCapMap) > -1)
        {
            if ( numplayers > 1 && numplayers < 7 )
                bots_flag();

            if( numplayers > 6 )
            {
                @zero_bots()
                server_print "Autoconcom bot adjustment."
            }
            if ( !numplayers )
            {
                @zero_bots()
                server_cmd NUKE
                server_print "Autoconcom bot adjustment cstrike not running 0 players."
            }

        }
        else
        {
            if(!task_exists(14785))
            {
                //set_task_ex(random_float(5.0,35.0),"bots_",14785, .flags = SetTask_Once);
                set_task(random_float(5.0,35.0),"bots_",14785)
            }
        }
    }
}

stock iPlayers()
{
    #if !defined get_playersnum_ex;
        new players[ MAX_PLAYERS ],pNum
        get_players(players,pNum,"chi")
        g_iHeadcount = pNum;

    #else

        g_iHeadcount = get_playersnum_ex(GetPlayersFlags:GetPlayers_ExcludeBots)

    #endif
    server_print "%s|Detected %i players", PLUGIN, g_iHeadcount;
    return g_iHeadcount;
}
