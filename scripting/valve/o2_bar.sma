/*
Current Version - 1.0.1 June 2022

Oxygen Bar

- Description -

While you're underwater, it shows how much oxygen you still have. When the last line from the bar disappears you will start to receive damage.

- Changelog -
1.0.1
Jun 23, 2022
Issue: Lag from plugin think and showing as spectator.
Resolution: Slow think to a task and set as a client command to toggle. Filter out bots.

1.0.0
Sept 18, 2019
Issue: Run-Time error. Bar would not work since 2009 until player dies first.
Resoultion: B-TEAM SPiNX took over project and fixed error. Shortened plugin name.

0.7.0
*Initial Release
*/

#include <amxmodx>
#include <engine_stocks>
#include <fakemeta>
#include <fakemeta_stocks>
#include <hamsandwich>

#define VERSION "1.0.1"

#define MAX_PLAYERS 32

//Handler think time
#define HANDLER_THINK_TIME 0.01

//Time player can stay underwater, until he starts receiving damage
#define UNDERWATER_MAX_TIME 12.012

//Lines in the oxygen bar
#define BAR_LINES 12

//Time per line in oxygen bar
#define TIME_PER_LINE UNDERWATER_MAX_TIME / BAR_LINES

//Bar array size // 6 - name 'oxygen' // 2 - '^n' // 2 - '[' and ']'
#define BAR_STRING_LENGTH BAR_LINES + 6 + 2 + 2

//Oxygen bar chars.
#define FULL_CHAR   "|"
#define EMPTY_CHAR  "="

//pev_waterlevel 3 - head is underwater
#define UNDERWATER 3

//Is player alive?
new bool:g_PlayerAlive[MAX_PLAYERS + 1]

//Hold the time when player dived into the water
new Float:g_PlayerWaterGametime[MAX_PLAYERS]

//Holds the gametime of players last bar update.
new Float:g_PlayerUpdateGametime[MAX_PLAYERS]

//Toggle feat
new bool:g_Wants_O2_View[MAX_PLAYERS + 1]

new g_maxPlayers

new const SzWater[]="func_water"
new const SzWaterFake[]="func_illusionary" //can be reskinned to water, lava, or slime.


public plugin_init() {

    register_plugin("O2-bar",VERSION,"SPiNX")

    //Originally coded as a think by shine771 https://forums.alliedmods.net/member.php?u=28238
    //original plugin https://forums.alliedmods.net/showthread.php?t=96782

    register_cvar("O2-bar",VERSION,FCVAR_SERVER|FCVAR_SPONLY)

    //find_ent(-1, SzWater) ? server_print("%s found.", SzWater) : log_amx("%s NOT found on map.", SzWater)&pause("a")
    find_ent(-1, SzWater) ||  find_ent(-1, SzWaterFake) ? server_print("%s found.", SzWater) : log_amx("%s NOT found on map.", SzWater)&pause("a")

    //Events
    register_event("DeathMsg","PlayerDeath","a")

    //Ham Forwards
    RegisterHam(Ham_Spawn,"player","PlayerSpawn",1)

    set_task(0.3,"HandlerThink", 2022, .flags="b")

    register_clcmd("o2","@o2_view", 0, "- toggle underwater Oxygen bar / O2 view.")
    register_clcmd("oxygen_bar","@o2_view", 0, "- toggle underwater Oxygen bar / O2 view.")

    g_maxPlayers = get_maxplayers()
}

public client_putinserver(id)
if(is_user_alive(id))
        g_PlayerAlive[id] = true

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

public client_disconnected(id)
{
    g_PlayerAlive[id] = false

    g_PlayerWaterGametime[id] = 0.0

    g_PlayerUpdateGametime[id] = 0.0
}

@o2_view(id)
{
    if(is_user_connected(id))
    {
        if(g_Wants_O2_View[id])
        {
            g_Wants_O2_View[id] = false
            client_print id, print_chat, "O2 bar is OFF."
        }
        else
        {
            g_Wants_O2_View[id] = true
            client_print id, print_chat, "O2 bar is ON."
        }

    }
    return PLUGIN_HANDLED
}

public PlayerDeath() g_PlayerAlive[read_data(2)] = false

public PlayerSpawn(id) if(is_user_alive(id)) g_PlayerAlive[id] = true

public HandlerThink(Ent)
{
    static Float:Gametime, i, x
    Gametime = get_gametime()

    set_hudmessage(255,0,0,-1.0,0.9,0,6.0,TIME_PER_LINE + 0.01)

    for(i = 1; i < g_maxPlayers  ; i++)
    {
        if(g_PlayerAlive[i] && !is_user_bot(i) && !is_user_hltv(i))
        {
            if(g_Wants_O2_View[i])

            if(pev(i,pev_waterlevel) == UNDERWATER && !g_PlayerWaterGametime[i])
                g_PlayerWaterGametime[i] = Gametime

            else if(pev(i,pev_waterlevel) != UNDERWATER)
                g_PlayerWaterGametime[i] = 0.0

            else if(Gametime - g_PlayerUpdateGametime[i] >= TIME_PER_LINE)
            {
                static sBar[BAR_STRING_LENGTH], Float:UnderWaterGametime

                //Static looks cooler
                sBar[0] = 0

                UnderWaterGametime = UNDERWATER_MAX_TIME - (Gametime - g_PlayerWaterGametime[i])

                add(sBar,BAR_STRING_LENGTH - 1,"Oxygen^n[")

                for(x = 0; x < BAR_LINES; x++)
                UnderWaterGametime >= x * TIME_PER_LINE ?  add(sBar,BAR_STRING_LENGTH - 1,FULL_CHAR) : add(sBar,BAR_STRING_LENGTH - 1,EMPTY_CHAR)

                add(sBar,BAR_STRING_LENGTH - 1,"]")

                show_hudmessage(i,sBar)

                g_PlayerUpdateGametime[i] = Gametime
            }
        }
    }
}
