#include amxmodx

#define PLUGIN    "FOV Finder"
#define VERSION   "1.0.1"
#define AUTHOR    "SPiNX"
new const URL[]=  "https://github.com/djearthquake/"
new const DESC[]= "Cvar how to with FOV."


public plugin_init()
#if AMXX_VERSION_NUM == 110
register_plugin(PLUGIN, VERSION, AUTHOR, URL, DESC)
#else
register_plugin(PLUGIN, VERSION, AUTHOR);
#endif

public client_putinserver(id)
if(!is_user_bot(id))
    set_task(3.0, "@fov_check",id)

@fov_check(id)
if(!is_user_bot(id) && is_user_connected(id))
    query_client_cvar(id,"default_fov","@fov_help")

@fov_help(id, const cvar[], const value[])
if(str_to_num(value) != 100)
    client_print id, print_chat, "Your %s is %s", cvar, value
