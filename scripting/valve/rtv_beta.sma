#include amxmodx

public plugin_init()
{
    register_plugin("Simpler RTV", "1.1", "SPiNX")
    register_clcmd("say rtv", "cmd_rtv")
}

public cmd_rtv(id)
{
    amxclient_cmd(id, "amx_votemapmenu")
    return PLUGIN_HANDLED
}
