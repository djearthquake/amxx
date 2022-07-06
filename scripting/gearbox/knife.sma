#include amxmodx
#include engine

new const ent_type[]="game_player_equip"
new const GIVES[][]=
{
    "weapon_crowbar",
    "weapon_knife",
    "weapon_pipewrench"
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
