#include <amxmodx>

static g_ForceRoundTimer

#define PLUGIN "RoundTimer Fix"
#define VERSION "1.21"
#define AUTHOR ".sρiηX҉."

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    g_ForceRoundTimer = get_user_msgid("ShowTimer")
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        if(!is_user_bot(id))
            set_task(5.0, "@fix_roundtimer", id + g_ForceRoundTimer)
    }
}

@fix_roundtimer(Tsk)
{
    new id = Tsk - g_ForceRoundTimer
    if(is_user_connected(id))
    {
        emessage_begin(MSG_ONE_UNRELIABLE , g_ForceRoundTimer, _, id);
        emessage_end();
        client_print id, print_chat, "Round timer restored on your client."
    }
}
