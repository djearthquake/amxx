#include amxmodx
#include engine

static const ent_type[]="game_player_equip"
static const GIVES[][]=
{
    "weapon_crowbar",
    "weapon_knife",
    "weapon_pipewrench",
    "ammo_9mmclip"
}

public plugin_precache()
{
    register_plugin ( "Spawn Weapons", "0.0.2", "SPiNX" );
    new ent = create_entity(ent_type);

    for(new i;i < sizeof GIVES;++i)
    {
        DispatchKeyValue( ent, GIVES[i], "1" );
    }
    DispatchKeyValue( ent, "weapon_9mmhandgun", "1" );
    DispatchSpawn(ent);
}
