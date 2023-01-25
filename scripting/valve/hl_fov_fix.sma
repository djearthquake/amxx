#include amxmodx

#define PLUGIN    "FOV Finder"
#define VERSION   "1.0"
#define AUTHOR    "SPiNX"
new const URL[]=  "https://github.com/djearthquake/"
new const DESC[]= "Cvar how to with FOV."
new szVersion[MAX_NAME_LENGTH];

public plugin_init()
get_amxx_verstring(szVersion, charsmax(szVersion))&containi(szVersion, "1.10.") != -1 ? register_plugin(PLUGIN, VERSION, AUTHOR, URL, DESC) : register_plugin(PLUGIN, VERSION, AUTHOR);

public client_putinserver(id)
if(!is_user_bot(id))
    set_task(3.0, "@fov_check",id)

@fov_check(id)
if(!is_user_bot(id) && is_user_connected(id))
    query_client_cvar(id,"default_fov","@fov_help")

@fov_help(id, const cvar[], const value[])
if(str_to_num(value) != 100)
    client_print id, print_chat, "Your %s is %s", cvar, value
