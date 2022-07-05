#include <amxmodx>
new g_ForceRoundTimer

public plugin_init()
{
    register_plugin("RoundTimer Fix", "1.0", ".sρiηX҉.")
    g_ForceRoundTimer = get_user_msgid("ShowTimer")
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        set_task(2.0,"@RoundTimerFix",id)
    }
}

@RoundTimerFix(id)
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
    emessage_end();
}
