#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>

new g_ForceRoundTimer
new fix_counter

new bool:bFixedPlayer[MAX_PLAYERS + 1]
new bool:bRoundTimerFixed[MAX_PLAYERS + 1]
new g_Adm, g_AI;
new const c4[][]={"weapon_c4","func_bomb_target","info_bomb_target"};

/*
 * Request by: Ark_Procession https://forums.alliedmods.net/member.php?u=301170
 * Aug 9 2022 1.0-1.1 make script more robust to prevent bug from reoccuring albeit temporarily.
 * Jun 21 2024 1.1-1.2 don't run on bots. Stop uing hamsandwich. Use more bitwise. Remove redundancy.
 * Jun 25 2024 1.2-1.3 pause when on a demonlition map to prevent crash.
 */


#define PLUGIN "RoundTimer Fix"
#define VERSION "1.3"
#define AUTHOR ".sρiηX҉."


#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))


new g_cvar_debugger_on

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    for(new ent;ent < sizeof c4;++ent)
    if(find_ent(MaxClients, c4[ent]))
	    pause("a")

    bind_pcvar_num(get_cvar_pointer("roundfix_debug") ? get_cvar_pointer("roundfix_debug") : create_cvar("roundfix_debug", "0" ,FCVAR_SERVER, "Roundfix plugin debugger", .has_min = false, .has_max = false), g_cvar_debugger_on)

    g_ForceRoundTimer = get_user_msgid("ShowTimer")
    register_event_ex ( "ResetHUD" , "@eventSpawn", RegisterEvent_Single|RegisterEvent_OnlyAlive|RegisterEvent_OnlyHuman)
}


public client_putinserver(id)
    client_infochanged(id)

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
	    is_user_admin(id) ? (SetPlayerBit(g_Adm, id)) : (ClearPlayerBit(g_Adm, id))
	    is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)

	    if(CheckPlayerBit(g_AI, id))
	        bFixedPlayer[id] = true
    }
}

@eventSpawn(id)
{
    if(!CheckPlayerBit(g_AI, id))
        if(!bFixedPlayer[id])
		    @RoundTimerFix(id)
}

@RoundTimerFix(id)
if(is_user_connected(id) && !bFixedPlayer[id])
{
    emessage_begin(is_user_connected(id) ? MSG_ONE : MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
    emessage_end();
    bFixedPlayer[id] = true

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
