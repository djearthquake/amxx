#include amxmodx
#include engine_stocks

static const ents[]={"worldspawn", "func_breakable", "func_wall", "func_door","func_train"};

public plugin_init()
{
    register_plugin("Real Weaponbox Killer","0.1","SPiNX")
    for(new list; list <sizeof ents;list++)
    register_touch("weaponbox",ents[list], "@kill")
}

@kill(iBox,world)if(iBox>MaxClients)remove_entity(iBox);
