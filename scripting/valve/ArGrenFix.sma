/*Original Powerplay script was removing them and noticed the stability issues also.*/
#include amxmodx
#include engine

new const SzEnt[]="ammo_ARgrenades"

public plugin_init()
{
    register_plugin("AR Grenade removal","1.0",".sρiηX҉.");

    if(has_map_ent_class(SzEnt))
        remove_entity_name(SzEnt)
}
