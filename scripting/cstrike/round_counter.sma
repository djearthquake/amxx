#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

#define PLUGIN "Round Counter"
#define VERSION "1.1"
#define AUTHOR "SPiNX"

#define RED    255
#define GREEN    255
#define BLUE    255

new g_round = 1;
new g_syncmsg
new bool:bWarmedup;
new g_warmtime
new bool:bRegistered
new g_max, g_ctwin, g_terrwin;
static const szTheMsg[] = "speak ^"you are in warm up^"";
//static const szTheMsg[] = "speak ^"warm up^""
static const szEnt[] = "hostage_entity";
new g_Hostie, g_gungame;


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_event("HLTV", "@event_newround", "a", "1=0", "2=0");
    register_logevent("@round_end", 2, "1=Round_End")
    register_event( "SendAudio", "@ctwin", "a", "2=%!MRAD_ctwin")
    register_event( "SendAudio", "@terrwin", "a", "2=%!MRAD_terwin")
    g_warmtime = register_cvar("mp_warmup", "30")
    g_syncmsg = CreateHudSyncObj()
    bWarmedup = false
    g_max = get_cvar_pointer("mp_maxrounds")
    g_gungame = get_cvar_pointer("gg_enabled")
    if(get_cvar_pointer("respawn_humans"))
    {
        RegisterHam(Ham_Spawn, "player","playerSpawnPost",1)
    }
    g_Hostie = has_map_ent_class(szEnt) ? 1 : 0
}

@ctwin()
{
    g_ctwin++
}

@terrwin()
{
    g_terrwin++
}

@round_end()
{
    if(get_pcvar_num(g_max) && !get_pcvar_num(g_gungame))
    {
        new iMax = get_pcvar_num(g_max)
        new Float:roundtime = get_cvar_float("mp_roundtime") * 60
        if(g_round == iMax)
        {
            for(new players; players<=MaxClients; ++players)
            {
                console_cmd( players, "speak ^"round over^"")
            }
        }
        new Float:X,Float:Y;
        X = g_Hostie ? 0.01 : 0.47
        Y = g_Hostie ? 0.17 : 0.001
        set_hudmessage(255, 255, 255, X, Y, .effects= 0 , .holdtime = !bWarmedup ? 300.0 : roundtime)
        if(g_round <= iMax)
        {
            !bWarmedup ? set_task(7.5, "@warm_delay", 2027) : ShowSyncHudMsg(0, g_syncmsg, "Round: [ %d ] of [ %i ]. Score: [ CT:%d ] [ T:%d ]", g_round, iMax, g_ctwin, g_terrwin)
        }
    }
}

@event_newround()
{
    if(get_pcvar_num(g_max) && !get_pcvar_num(g_gungame))
    {
        set_task 0.1, "@delayed_showing", 2028
    }
}


public playerSpawnPost(id)
{
    new iMax = get_pcvar_num(g_max)
    if(iMax && !get_pcvar_num(g_gungame))
    if(!is_user_bot(id))
    {
        if(!bWarmedup)
        {
            set_task 5.0, "@reset", id
        }
        new Float:roundtime = get_cvar_float("mp_roundtime") * 60
        new Float:X,Float:Y;
        X = g_Hostie ? 0.01 : 0.42
        Y = g_Hostie ? 0.17 : 0.001
        set_hudmessage(255, 255, 255, X, Y, .effects= 0 , .holdtime = !bWarmedup ? 300.0 : roundtime)

        if(g_round <= iMax)
        {
            !bWarmedup ? set_task(7.5, "@warm_delay", 2027) : ShowSyncHudMsg(id, g_syncmsg, "Round: [ %d ] of [ %i ]. Score: [ CT:%d ] [ T:%d ]", g_round, iMax, g_ctwin, g_terrwin)
        }
    }
}

@delayed_showing()
{
    static szBuffer[64], szRound[16], szMax[16];

    new iMax = get_pcvar_num(g_max)
    new Float:roundtime = get_cvar_float("mp_roundtime") * 60

    g_round++
    new Float:X,Float:Y;
    X = g_Hostie ? 0.01 : 0.42
    Y = g_Hostie ? 0.17 : 0.001
    set_hudmessage(255, 255, 255, X, Y, .effects= 0 , .holdtime = !bWarmedup ? 300.0 : roundtime)
    if(g_round <= iMax)
    {
        !bWarmedup ? set_task(7.5, "@warm_delay", 2027) : ShowSyncHudMsg(0, g_syncmsg, "Round: [ %d ] of [ %i ]. Score: [ CT:%d ] [ T:%d ]", g_round, iMax, g_ctwin, g_terrwin)
    }

    num_to_word(g_round, szRound, charsmax(szRound));
    num_to_word(iMax, szMax, charsmax(szMax));

    formatex(szBuffer, charsmax(szBuffer), "speak ^"round %s out of %s^"", szRound, szMax)
    for(new players; players<=MaxClients; ++players)
    if(is_user_connected(players) && !is_user_bot(players))
    {
        if(g_round == iMax)
        {
            console_cmd( players, "speak ^"final last round^"")
        }
        else if(g_round < iMax)
        {
            console_cmd( players, !bWarmedup ? szTheMsg : szBuffer)
        }
        if(bWarmedup && g_ctwin || g_terrwin)
        {
            set_task 3.0,"@say_score", 2026
        }
    }
}

@say_score()
{
    static szScore[64], szCounterT[16], szTerr[16];

    num_to_word(g_terrwin, szTerr, charsmax(szTerr));
    num_to_word(g_ctwin, szCounterT, charsmax(szCounterT));
    formatex(szScore, charsmax(szScore), "speak ^"%s to %s^"", szCounterT, szTerr)

    for(new players; players<=MaxClients; ++players)
    {
        if(is_user_connected(players) && !is_user_bot(players))
        {
            console_cmd(players, szScore)
        }
    }
}

@warm_delay()
{
    new Float:roundtime = get_cvar_float("mp_roundtime") * 60
    set_hudmessage(255, 255, 255, 0.01, 0.17, .effects= 0 , .holdtime = roundtime)
    ShowSyncHudMsg(0, g_syncmsg, "WARMING UP...")
}

public client_connect(id)
{
    if(get_pcvar_num(g_max) && !get_pcvar_num(g_gungame))
    if(!bWarmedup)
    {
        set_task 5.0, "@reset", id
    }
}

public client_disconnected(id)
{
    if(get_pcvar_num(g_max) && !get_pcvar_num(g_gungame))
    {
        set_task 1.0, "@check_players", 2029
    }
}

@check_players()
{
    new iPlayers = get_playersnum();
    if(iPlayers <=1)
    {
        bWarmedup = false;
        g_round = 0;
        @reset_score();
    }
}

@reset(id)
{
    if(!bWarmedup)
    {
        if(is_user_connected(id) && 1 <= get_user_team(id, _, _) <= 2)
        {
            new iTime = get_pcvar_num(g_warmtime)
            bWarmedup = true
            console_cmd 0, "sv_restartround %i", iTime
            client_print 0, print_chat, "WARM UP!"
            g_round = 0;
            set_task(float(iTime), "@reset_score", 2030)
        }
    }
}

@reset_score()
{
    g_ctwin = 0;
    g_terrwin = 0;
}

public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT") && !bRegistered)
    {
        set_task(0.1, "@register", id);
    }
}

@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        bRegistered = true;
        if(get_cvar_pointer("respawn_humans"))
        {
            RegisterHamFromEntity(Ham_Spawn, ham_bot,"playerSpawnPost",1)
            server_print("%s|%s|%s hambot from %N", PLUGIN, VERSION, AUTHOR, ham_bot)
        }
    }
}
