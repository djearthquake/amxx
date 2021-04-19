#include amxmodx
#include engine_stocks
new const c4[][]={"weapon_c4","func_bomb_target","info_bomb_target"};

public plugin_init()
{
    register_plugin("c4 killer", "SPiNX", "04-2021");
    for(new ent;ent < sizeof c4;++ent)
        remove_entity_name(c4[ent]);
}
