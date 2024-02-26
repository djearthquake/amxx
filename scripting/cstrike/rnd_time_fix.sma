#include <amxmodx>
#include <engine_stocks>
#include <hamsandwich>

new g_ForceRoundTimer
new fix_counter

new bool:bFixAllPlayers
new bool:bFixedPlayer[MAX_PLAYERS + 1]
new bool:bRoundTimerFixed[MAX_PLAYERS + 1]
new bool:bDefuseMap

/*
 * Request by: Ark_Procession https://forums.alliedmods.net/member.php?u=301170
 * Aug 9 2022 1.0-1.1 make script more robust to prevent bug from reoccuring albeit temporarily.
 */


#define PLUGIN "RoundTimer Fix"
#define VERSION "1.1"
#define AUTHOR ".sρiηX҉."

new g_cvar_debugger_on

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    bind_pcvar_num(get_cvar_pointer("roundfix_debug") ? get_cvar_pointer("roundfix_debug") : create_cvar("roundfix_debug", "1" ,FCVAR_SERVER, "Roundfix plugin debugger", .has_min = false, .has_max = false), g_cvar_debugger_on)

    g_ForceRoundTimer = get_user_msgid("ShowTimer")
    //register_logevent("@RoundTimerFixAllPlayers", 3 ,"2=Planted_The_Bomb");
    register_event("BarTime", "@RoundTimerFixAllPlayers", "be", "1=3")
    register_logevent("@round_start", 2, "1=Round_Start");
    RegisterHamPlayer(Ham_Spawn, "@eventSpawn", 1)
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        set_task(0.5,"@RoundTimerFix",id)
    }
}

@RoundTimerFixAllPlayers()
{
    bFixAllPlayers = true

    if(g_cvar_debugger_on > 0)
        server_print("%s %s %s| Fix needs to be reapplied to everybody!",PLUGIN, VERSION, AUTHOR)
}

@eventSpawn(id)
{
    if(bFixAllPlayers || !bFixedPlayer[id])
        @RoundTimerFix(id)
}

@round_start()
{
    bFixAllPlayers = false
}

@Plant()
    bDefuseMap = true

@RoundTimerFix(id)
if(is_user_connected(id) || is_user_connecting(id))
{
    emessage_begin(is_user_connected(id) ? MSG_ONE : MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
    emessage_end();

    if(bFixAllPlayers)
    {
        bFixedPlayer[id] = true

        if(!bDefuseMap)
            bRoundTimerFixed[id] = true

        if(g_cvar_debugger_on > 0)
            server_print("%s %s %s| Fix reapplied to [%n]", PLUGIN, VERSION, AUTHOR, id)
    }
    fix_counter++
}

public client_disconnected(id)
{
    @RoundTimerFix(id)
    bRoundTimerFixed[id] = false
}

public plugin_end()
{
    if(fix_counter)
        log_amx fix_counter == 1 ? "%s %s by %s fixed %i client." : "%s %s by %s fixed %i clients!", PLUGIN, VERSION, AUTHOR, fix_counter
}
