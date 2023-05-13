#include <amxmodx>

#define PLUGIN  "Zero Round"
#define VERSION "1.0.0"
#define AUTHOR  "SPiNX|victorrr"

#define MAX_NAME_LENGTH 32
#define charsmin -1

#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/cstrike"

new bool:bCalled

new const szZeroRnd[][] =
{
    "Hostages_Not_Rescued",
    "Round_Draw",
    "Target_Saved",
    "VIP_Not_Escaped"
}

#if AMXX_VERSION_NUM == 182
new  g_cvar_cmd_182
#endif

new g_cvar_rnd, g_cvar_cmd[MAX_NAME_LENGTH]

public plugin_init()
{
    register_event("ScoreInfo", "plugin_log", "a", "1=Team");
    ///register_logevent("@rnd_zero", 2, "1=Round_End")
    register_logevent("@rnd_start", 2, "1=Round_Start")
    #if AMXX_VERSION_NUM != 182
    bind_pcvar_string(create_cvar("rnd_cmd_cvar", "say Round over!"), g_cvar_cmd, charsmax(g_cvar_cmd))
    #else
    g_cvar_cmd_182 = register_cvar("rnd_cmd_cvar", "say Round over!")
    #endif

    #if AMXX_VERSION_NUM >= 182 || AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR)
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL)
    #endif
    g_cvar_rnd = get_cvar_pointer("mp_roundtime") //For maps without objectives.
    state ON
}

@rnd_start()
{
    new iRestart = get_cvar_pointer("sv_restartround")

    switch(iRestart)
    {
        case 0: state ON
        default: state OFF
    }

    @plugin_control()
}

@rnd_zero()
{
    if(!bCalled)
    {
        #if AMXX_VERSION_NUM == 182
        get_pcvar_string(g_cvar_cmd_182, g_cvar_cmd, charsmax(g_cvar_cmd))

        console_cmd( 0, g_cvar_cmd )
        #else
        console_cmd( 0, g_cvar_cmd )
        #endif
        state ON
    }
    @plugin_control()
}

public plugin_log()
{
    new szDummy[ MAX_NAME_LENGTH ];
    read_logargv(3,szDummy, charsmax(szDummy))

    for(new list;list < sizeof szZeroRnd;list++)
    if(containi(szDummy, szZeroRnd[list]) != charsmin)
    {
        @rnd_zero()
    }
}

@plugin_control()<ON>
{
    bCalled = true;
    remove_task(2023);
}

@plugin_control()<OFF>
{
    bCalled = false;
    set_task(get_pcvar_num(g_cvar_rnd)*60.0, "@rnd_zero", 2023);
}
