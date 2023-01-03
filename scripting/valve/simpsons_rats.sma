#include <amxmodx>
#include <fakemeta_util>
#include <engine_stocks>

public plugin_init()
{
    register_plugin("Simpsons_rats Floor Fix","1.0",".sρiηX҉.");
    new iEnt = find_ent(-1, "func_breakable")
    fm_set_kvd(iEnt, "material", "7");
}
