/*Spin-off idea derived from request by malec321 via https://forums.alliedmods.net/showthread.php?t=153046*/
#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>
#include <fakemeta>

#define PLUGIN  "!Alive"
#define VERSION "1.0.2"
#define AUTHOR  "SPiNX" //some work by vato loco [GE-S]
//Thx Bugsy https://forums.alliedmods.net/showthread.php?t=139916

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

#define TASK_GETPLAYER    37852
#define TASK_LOOP_TIME    1.0

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

#define charsmin -1

new g_cvar_cont, g_continuous, g_rescue, g_AI
new g_Hostie

static g_SyncTeamCount_CT,  g_SyncTeamCount_H, g_SyncTeamCount_T

new const szEnt[] = "hostage_entity"
new const szRescue[] = "2=Rescued_A_Hostage"
new const CvarDesc[] = "Show who is alive as round ends. 2 is more persistent."

new g_hasFeat[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_clcmd("amx_show_alive", "adj_hud", 0, "- toggle players alive.")

    g_SyncTeamCount_CT = CreateHudSyncObj()
    g_SyncTeamCount_H = CreateHudSyncObj()
    g_SyncTeamCount_T = CreateHudSyncObj()

    register_logevent("@rescue", 3, szRescue)
    register_logevent("@LogEvent_Round_Start", 2, "1=Round_Start")
    g_continuous = register_logevent("@Logevent_Round_End", 2, "1=Round_End")
    bind_pcvar_num(create_cvar("players_alive", "1",FCVAR_SERVER, CvarDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 2.0), g_cvar_cont)
    g_Hostie = has_map_ent_class(szEnt) ? 1 : 0
    state OFF
}

public adj_hud(id)
{
    if(is_user_connected(id))
    {
        if(g_hasFeat[id] < 2)
        {
            g_hasFeat[id]++
            client_print( id, print_chat, g_hasFeat[id] == 2 ? "%s zoomed in." : "Showing %s.", PLUGIN)
        }
        else
        {
            g_hasFeat[id] = 0
            client_print id, print_chat, "%s off", PLUGIN
        }
    }
    return PLUGIN_HANDLED
}

@rescue()
    ++g_rescue

@LogEvent_Round_Start()
{
    g_rescue = 0
    state ON
    @solid_state()

    g_cvar_cont ? disable_logevent(g_continuous) : enable_logevent(g_continuous)
}

@Logevent_Round_End()
    @solid_state()

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
        g_hasFeat[id] = CheckPlayerBit(g_AI, id) ? 0 : 2
    }
}

public client_disconnected(id)
    ClearPlayerBit(g_AI, id)

@solid_state()<ON>{set_task(TASK_LOOP_TIME, "@GetPlayers", TASK_GETPLAYER, .flags="b");if(g_cvar_cont>1)server_print("%s is on...", PLUGIN);}

@solid_state()<OFF>{remove_task( TASK_GETPLAYER );if(g_cvar_cont>1)server_print("%s is off..", PLUGIN);}

@GetPlayers()
{
    static
    R,G,B,
    Float:X, Float:Y;
    new iPlayers[MAX_PLAYERS], iNum, iTnum, iCTnum, Regular_hud

    get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)
    if(g_cvar_cont)
    {
        if(iNum)
        {
            for(new ALIVE; ALIVE <= iNum; ++ALIVE)
            {
                switch( get_user_team( iPlayers[ALIVE] ) )
                {
                    case 1: ++iTnum
                    case 2: ++iCTnum
                }
            }
            for(new ALIVE; ALIVE <= iNum; ++ALIVE)
            if(g_hasFeat[iPlayers[ALIVE]])
            {
                static id
                id = iPlayers[ALIVE]
                if(CheckPlayerBit(g_AI, id))return
                if(g_hasFeat[id] == 1)
                    Regular_hud = 1;

                if(iTnum && iCTnum)
                {
                    if(g_cvar_cont>1)
                        server_print "checking %i %N", id, id

                    B = 0, R = 255, X = 0.391;
                    Regular_hud ?
                    set_hudmessage(R, G, B, X, Y, _, _, TASK_LOOP_TIME+0.01, _,  _, 1) & ClearSyncHud(id, g_SyncTeamCount_T) :
                    set_dhudmessage(R, G, B, X +0.22, Y, _, _, TASK_LOOP_TIME+0.01, _,  _)

                    Regular_hud ?
                    ShowSyncHudMsg(id, g_SyncTeamCount_T, "[Alive T: %d]", iTnum) :
                    show_dhudmessage(id, "[Alive T: %d]", iTnum)

                    R = 0, B = 255, X = 0.54;
                    Regular_hud ?
                    set_hudmessage(R, G, B, X, Y, _, _, TASK_LOOP_TIME+0.01, _,  _, 1) & ClearSyncHud(id, g_SyncTeamCount_CT) :
                    set_dhudmessage(R, G, B, X -0.227, Y, _, _, TASK_LOOP_TIME+0.01, _,  _)

                    Regular_hud ?
                    ShowSyncHudMsg(id, g_SyncTeamCount_CT, "[Alive CT: %d]", iCTnum) :
                    show_dhudmessage(id, "[Alive CT: %d]", iCTnum)
                    if(g_Hostie)
                    {
                        new R, G, B
                        G = 255, B = 0, X = 0.462;
                        Regular_hud ?
                        set_hudmessage(R, G, B, X, Y, _, _, TASK_LOOP_TIME+0.01, _,  _, 1) & ClearSyncHud(id,g_SyncTeamCount_H) :
                        set_dhudmessage(R, G, B, X, Y, _, _, TASK_LOOP_TIME+0.01, _,  _)
                        new iHostage,  Is_Hostage_alive, iHostie_count
                        while ((iHostage = find_ent(iHostage , szEnt)) > 0)
                        {
                            Is_Hostage_alive = pev(iHostage, pev_health)
                            if(Is_Hostage_alive)
                                iHostie_count++
                        }
                        Regular_hud ?
                        ShowSyncHudMsg(id, g_SyncTeamCount_H, "[Hostages: %d]", iHostie_count-g_rescue) :
                        show_dhudmessage(id, "[Hostages: %d]", iHostie_count-g_rescue)
                    }
                }state OFF
            }
        }state OFF
    }
}
