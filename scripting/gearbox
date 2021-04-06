#include amxmodx
#include engine
#define ent create_entity("game_player_equip")

new const GIVES[][]={
"weapon_pipewrench",
"weapon_penguin",
"weapon_knife",
"item_longjump",
"weapon_9mmhandgun",
"weapon_shockrifle",
"weapon_hornetgun",
"weapon_sporelauncher",
"weapon_eagle",
"weapon_shotgun",
"weapon_m249",
"weapon_grapple",
"weapon_eagle",
"weapon_sniperrifle",
"weapon_displacer"}

public plugin_precache() for(new i;i < sizeof GIVES;++i) DispatchKeyValue( ent, GIVES[i], "1" ) && DispatchSpawn(ent)
