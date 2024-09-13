#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>

#define PLUGIN "RoundTimer Fix"
#define VERSION "1.31"
#define AUTHOR ".sρiηX҉."

static g_ForceRoundTimer
static const c4[][]={"weapon_c4","func_bomb_target","info_bomb_target"};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    for(new ent;ent < sizeof c4;++ent)
    {
        find_ent(MaxClients, c4[ent]) ? pause("d") : register_concmd("fix_timer","@RoundTimerFix",0,": Fix round timer.");
    }

    g_ForceRoundTimer = get_user_msgid("ShowTimer")

}

@RoundTimerFix(id)
{
    if(is_user_connected(id))
    {
        server_print("%N used %s", id, PLUGIN)
        emessage_begin(MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
        emessage_end();
        client_print( id, print_chat, "%s|%s|%s applied patch!", PLUGIN, VERSION, AUTHOR)
    }
    return PLUGIN_HANDLED
}
