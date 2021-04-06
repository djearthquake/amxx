#include amxmodx
#include engine
#define ent create_entity("game_player_equip")
new const GIVES[][]={"weapon_crowbar", "weapon_knife"}
public plugin_precache() for(new i;i < sizeof GIVES;++i)
DispatchKeyValue( ent, "weapon_9mmhandgun", "7" ) && DispatchKeyValue( ent, GIVES[i], "1" ) && DispatchSpawn(ent);
