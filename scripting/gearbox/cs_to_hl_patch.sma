/*vote_map_orange CS map revised for HL/OP4*/
#include amxmodx
#include engine

new const ent_type[]="game_player_equip"

enum{ammo_57mm, ammo_556natobox,weapon_fiveseven,item_assaultsuit};
enum{func_buyzone,armoury_entity,func_escapezone,env_rain,info_map_parameters,func_hostage_rescue};

public plugin_init()
{
    register_plugin("CS to HL/OP4 map weapons patch", "1.1", "SPiNX");
}

public pfn_keyvalue()
{
    remove_entity_name("game_player_equip")
    new ent = create_entity(ent_type)

    DispatchKeyValue( ent, "weapon_crowbar", "1" )
    DispatchKeyValue( ent, "targetname", "game_playerspawn")
    DispatchSpawn(ent);
}
