#include amxmodx
#include engine
#include engine_stocks
#include fakemeta

new const ent_type[]="game_player_equip"

new const GIVES[][]=
{
    "weapon_knife",
    "weapon_pipewrench",
    "weapon_crowbar",
    "weapon_eagle",
    "weapon_9mmhandgun",
    "ammo_357",
    "ammo_357",
    "ammo_357",
    "weapon_9mmAR",
    "ammo_9mmclip",
    "ammo_9mmclip",
    "weapon_shotgun",
    "ammo_buckshot",
    "ammo_buckshot",
    "ammo_buckshot",
    "item_battery",
    "item_battery",
    "item_battery"
}
public plugin_init()
{
    new Origin[3], iSwap, ent2

    iSwap = find_ent(-1,"item_ctfportablehev")

    if(iSwap)
    {
        pev(iSwap, pev_origin, Origin)
        remove_entity(iSwap)
    }

    ent2 = create_entity("item_ctfregeneration")
    set_pev(ent2, pev_origin, Origin)
    DispatchSpawn(ent2);

    iSwap = find_ent(-1,"weapon_displacer")

    if(iSwap)
    {
        pev(iSwap, pev_origin, Origin)
        remove_entity(iSwap)
    }

    ent2 = create_entity("item_ctflongjump")
    set_pev(ent2, pev_origin, Origin)
    DispatchSpawn(ent2);

    iSwap = find_ent(-1,"weapon_gauss")

    if(iSwap)
    {
        pev(iSwap, pev_origin, Origin)
        remove_entity(iSwap)
    }

    ent2 = create_entity("weapon_displacer")
    set_pev(ent2, pev_origin, Origin)
    DispatchSpawn(ent2);

    remove_entity_name("weapon_shotgun");
    remove_entity_name("ammo_buckshot");

    remove_entity_name("weapon_9mmAR");
    remove_entity_name("ammo_9mmbox");
}

public plugin_precache()
{
    register_plugin("op4ctf_orange_fix","1.1","SPiNX");
    static mapname[MAX_NAME_LENGTH];get_mapname(mapname, charsmax(mapname));
    if(!equal(mapname, "op4ctf_orange"))
        pause "a"


    new ent = create_entity(ent_type)

    for(new i;i < sizeof GIVES;++i)
    {
        DispatchKeyValue( ent, GIVES[i], "1" )
        DispatchSpawn(ent);
    }

}
