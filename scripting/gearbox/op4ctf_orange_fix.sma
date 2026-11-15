#include amxmodx
#include engine
#include engine_stocks
#include fakemeta

static const ent_type[]="game_player_equip"

static const GIVES[][]=
{
    "ammo_357",
    "ammo_9mmclip",
    "ammo_buckshot",
    "item_battery",
    "weapon_tripmine"
}

public plugin_init()
{
    new Origin[3], iSwap, ent2;

    iSwap = find_ent(MaxClients+1,"item_ctfportablehev")

    if(pev_valid(iSwap))
    {
        pev(iSwap, pev_origin, Origin)
        remove_entity(iSwap)

        ent2 = create_entity("item_ctfregeneration")

        if(pev_valid(ent2))
        {
            set_pev(ent2, pev_origin, Origin)
            DispatchSpawn(ent2);
        }

    }

    iSwap = find_ent(MaxClients+1,"weapon_displacer")

    if(pev_valid(iSwap))
    {
        pev(iSwap, pev_origin, Origin)
        remove_entity(iSwap)

        ent2 = create_entity("item_ctflongjump")

        if(pev_valid(ent2))
        {
            set_pev(ent2, pev_origin, Origin)
            DispatchSpawn(ent2);
        }
    }

    iSwap = find_ent(MaxClients+1,"weapon_gauss")

    if(pev_valid(iSwap))
    {
        pev(iSwap, pev_origin, Origin)
        remove_entity(iSwap)

        ent2 = create_entity("weapon_displacer")
        if(pev_valid(ent2))
        {
            set_pev(ent2, pev_origin, Origin)
            DispatchSpawn(ent2);
        }
    }

    remove_entity_name("weapon_shotgun");
    remove_entity_name("ammo_buckshot");

    remove_entity_name("weapon_9mmAR");
    remove_entity_name("ammo_9mmbox");
}

public plugin_precache()
{
    register_plugin("op4ctf_orange_fix","1.2","SPiNX");
    static mapname[MAX_NAME_LENGTH];get_mapname(mapname, charsmax(mapname));
    if(!equal(mapname, "op4ctf_orange"))
    {
        pause "a"
        return PLUGIN_HANDLED
    }

    new ent = create_entity(ent_type)
    if(pev_valid(ent))
    {
        for(new i;i < sizeof GIVES;++i)
        {
            DispatchKeyValue( ent, GIVES[i], "4" )
        }
        DispatchKeyValue( ent, "weapon_crowbar", "1" )
        DispatchKeyValue( ent, "weapon_knife", "1" )
        DispatchKeyValue( ent, "weapon_pipewrench", "1" )
        DispatchKeyValue( ent, "weapon_shotgun", "1" )
        DispatchKeyValue( ent, "weapon_9mmAR", "1" )
        DispatchKeyValue( ent, "weapon_9mmhandgun", "1" )
        DispatchKeyValue( ent, "weapon_eagle", "1" )

        DispatchSpawn(ent);
    }

    return PLUGIN_CONTINUE

}
