#include <amxmodx>
#include <engine_stocks>
new const c4[][]={"weapon_c4","func_bomb_target","info_bomb_target"};
new g_ForceRoundTimer

public plugin_init()
{
    register_plugin("RoundTimer Fix", "1.0", ".sρiηX҉.")

    for(new ent;ent < sizeof c4;++ent)
    {
        if(find_ent(-1,c4[ent]))
            pause "a"
    }

    g_ForceRoundTimer = get_user_msgid("ShowTimer")
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        set_task(0.5,"@RoundTimerFix",id)
    }
}

@RoundTimerFix(id)
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
    emessage_end();
}
