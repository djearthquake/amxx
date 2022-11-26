#include amxmodx
#include engine_stocks

#define PLUGIN                   "Frictionless"
#define VERSION                           "1.1"
#define AUTHOR                          "SPiNX"
#define REMOVE                  "func_friction"
#define MAX_NAME_LENGTH                     32
#define charsmin                            -1

new bool:g_bFlagMap

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    new mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname));

    g_bFlagMap = containi(mname,"op4c") > charsmin?true:false
    
    g_bFlagMap ? remove_entity_name(REMOVE) &  server_print("%s|%s by %s is removing %s on %s.", PLUGIN, VERSION, AUTHOR, REMOVE, mname) : server_print("%s|%s by %s is not removing %s on %s.", PLUGIN, VERSION, AUTHOR, REMOVE, mname)
}
