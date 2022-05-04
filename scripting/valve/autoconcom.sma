//updated JUL 04 2021
#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Autoconcom"
#define VERSION "G" // Optimized with Cvars.
#define AUTHOR "SPINX"

#define NUKE "amx_leave *"
#define ZERO_BOTS server_cmd("jk_botti min_bots 0;jk_botti max_bots 0;HPB_Bot min_bots 0; HPB_Bot max_bots 0")

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

public OnAutoConfigsBuffered() ZERO_BOTS

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    g_bot_min = register_cvar("sv_autocon_botmin", "0");
    g_bot_max = register_cvar("sv_autocon_botmax", "0");

    g_bot_control = register_cvar("sv_autocon_autobot", "1");
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
    ZERO_BOTS
    if (task_exists(186) ) return;
    //set_task_ex(2.5, "mop_bot", 186, .flags = SetTask_RepeatTimes, .repeat = 1 );
    set_task(2.5,"mop_bot", 186)
}


public client_putinserver(id)
{
    if (get_pcvar_num(g_bot_control))
    {
        if (!is_user_bot(id) && is_user_connected(id) && id > 0)
        {
            if(!task_exists(210012))
                set_task(5.0,"on_join", 210012);
        }
    }
}

public client_infochanged(id)
{
    get_user_name(id,g_name,charsmax (g_name))
    if ( (is_user_connected(id)) && (is_user_bot(id)) && (containi(g_name,"(1)") > -1) )

        server_cmd("amx_kick (1)%s ^"bot_infochanged_badname^"",g_name);
}

public client_disconnected(id)
{
    if (is_user_bot(id)) return;
    if (is_user_hltv(id)) return;
    if ( cstrike_running() ) return;

    if (get_pcvar_num(g_bot_control))
    {
    
        new mname[MAX_PLAYERS];
        new numplayers = iPlayers();
        get_mapname(mname,charsmax(mname));
    
        if ( (containi(mname,SzFlagCapMap) > -1) && (numplayers == 0) )
        {
            //set_task_ex(1.0, "on_join", 34, .flags = SetTask_RepeatTimes, .repeat = 1 );
            set_task(1.0,"on_join", 34)
            //set_task_ex(5.0, "on_exit", 56, .flags = SetTask_RepeatTimes, .repeat = 1 );
            set_task(5.0, "on_exit", 56)
        }
        else
    
        if (numplayers < 3)
            if(!task_exists(340043))
                //set_task_ex(10.0, "on_join", 340043, .flags = SetTask_RepeatTimes, .repeat = 1 );
                set_task(10.0, "on_join", 340043)
    }
}


public bots_()
{
    new min = get_pcvar_num(g_bot_min);
    new max = get_pcvar_num(g_bot_max);
    server_cmd("jk_botti min_bots %i; jk_botti max_bots %i;", min, max);
}

public bots_flag()
{

    new mname[MAX_NAME_LENGTH];
    get_mapname(mname,charsmax (mname));
    new adjmsize;
    new Float:mega;
    mega = (0.001);
    new Float:msize = (filesize("maps/%s.bsp",mname, charsmax (mname))*(mega)/1024)
    adjmsize = floatround(msize, floatround_ceil);

    new numplayers = iPlayers()

    if (numplayers > 1)
    {
        new g_Bots_Min = (adjmsize * 2) + 1;
        new g_Bots_Max = (adjmsize * 4) + 2;
        server_cmd("HPB_Bot min_bots %i; HPB_Bot max_bots %i", g_Bots_Min, g_Bots_Max);
        server_print ("%s",SzAdvert) 
    }

    else
        ZERO_BOTS
}

public on_exit(id)
{
    if (get_pcvar_num(g_bot_control))
    {
        new numplayers = iPlayers()

        if ( (numplayers != 0) ||  (cstrike_running()) )
            return;
        
        if (numplayers == 0)
        {
            ZERO_BOTS
            //set_task_ex(5.0, "mop_bot", 186, .flags = SetTask_RepeatTimes, .repeat = 2 );
            set_task(5.0, "mop_bot", 186, "a", 2)
            server_cmd NUKE
        }
    }
}

public mop_bot()

    //set_task_ex(15.0, "on_join", 186, .flags = SetTask_RepeatTimes, .repeat = 0 );
    set_task(15.0, "on_join", 186)


public on_join()
{
    new numplayers = iPlayers()
    new mname[MAX_NAME_LENGTH];

    if (get_pcvar_num(g_bot_control))
    {
        get_mapname(mname,charsmax(mname));
    
    
        if (containi(mname, SzFlagCapMap) > -1)
        {
    
            if ( numplayers > 0 && numplayers < 7)
                bots_flag();
    
            if( numplayers > 6 )
            {
                ZERO_BOTS
                server_print "Autoconcom bot adjustment."
            }


            if ( numplayers == 0 )
            {
                ZERO_BOTS
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
    #if AMXX_VERSION_NUM == 182;
        new players[ MAX_PLAYERS ],pNum
        get_players(players,pNum,"chi")
        g_iHeadcount = pNum;

    #else

        g_iHeadcount = get_playersnum_ex(GetPlayersFlags:GetPlayers_ExcludeBots|GetPlayers_IncludeConnecting)

    #endif

    return g_iHeadcount
}



//finish algorithm guess max bots on map size other than sheer size. Analyze wad count for second weight?
/*
    new mname[MAX_PLAYERS];
    get_mapname(mname,charsmax (mname));

    new adjmsize;
    new Float:mega;
    mega = (0.001);
    new Float:msize = (filesize("maps/%s.bsp",mname, charsmax (mname))*(mega)/1024)

    adjmsize = floatround(msize, floatround_ceil);

    log_amx("%s is %d Mb from %f", mname, adjmsize, msize, charsmax (msize));
*/
