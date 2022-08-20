#include <amxmodx>

new g_ForceRoundTimer

#define PLUGIN "RoundTimer Fix"
#define VERSION "1.2"
#define AUTHOR ".sρiηX҉."

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    g_ForceRoundTimer = get_user_msgid("ShowTimer")
}

public client_putinserver(id)
    set_task(5.0, "@fix_roundtimer", id + g_ForceRoundTimer)

@fix_roundtimer(Tsk)
{
    new id = Tsk - g_ForceRoundTimer
    emessage_begin(is_user_connected(id) ? MSG_ONE : MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
    emessage_end();
}
