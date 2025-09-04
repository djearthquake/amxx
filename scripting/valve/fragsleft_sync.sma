#include amxmodx

new g_cvar

public plugin_init()
{
    register_plugin("frags left sync","0.0.1","SPiNX")
    hook_cvar_change(get_cvar_pointer("mp_fraglimit"), "setDefaultValue");
    g_cvar = get_cvar_pointer("mp_fragsleft")
}

public setDefaultValue(PointerCvar, const OldValue[], const NewValue[])
{
    static iUpdate; iUpdate = str_to_num(NewValue)
    if(g_cvar != iUpdate)
    {
        set_pcvar_num(g_cvar, iUpdate)
        log_amx "Syncing the frags."
    }
}
