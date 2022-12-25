#include amxmodx
#include engine
#include engine_stocks

new const ent_type[]="game_player_equip"

new const GIVES[][]=
{
    "weapon_shotgun",
    "weapon_9mmAR",
    "ammo_9mmbox",
    "ammo_buckshot",
    "ammo_buckshot",
    "ammo_buckshot",
    "ammo_buckshot",
    "ammo_buckshot"
}

public plugin_init()
{
    register_plugin("op4ctf_orange_fix","1.0","SPiNX");
    remove_entity_name("weapon_displacer");
    remove_entity_name("item_ctfportablehev");
    remove_entity_name("item_ctfaccelerator");

    remove_entity_name("weapon_shotgun");
    remove_entity_name("ammo_buckshot");

    remove_entity_name("weapon_9mmAR");
    remove_entity_name("ammo_9mmbox");
}

public plugin_precache()
{
    new ent = create_entity(ent_type)

    for(new i;i < sizeof GIVES;++i)
    {
        DispatchKeyValue( ent, "weapon_9mmhandgun", "1" )
        DispatchKeyValue( ent, GIVES[i], "1" )
        DispatchSpawn(ent);
    }
}
