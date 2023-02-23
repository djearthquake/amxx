/*vote_map_orange CS map revised for GoldSRC*/
#include amxmodx
#include engine

new bool:bPatched
new const ent_type[]="game_player_equip"
new mod_name[MAX_NAME_LENGTH]

public plugin_init()
{
    register_plugin("Fix:CS-HL map guns", "1.2", "SPiNX");
}

public plugin_precache()
{
    get_modname(mod_name, charsmax(mod_name));
    new ent = create_entity(ent_type)

    log_amx "Attempting to partially patch Counter-Strike map for %s.", mod_name

    if(equal(mod_name,"dod"))
    {
        DispatchKeyValue( ent,"weapon_colt", "1")
        DispatchKeyValue( ent,"weapon_amerknife", "1")
        DispatchKeyValue( ent, "weapon_handgrenade", "1")
        DispatchKeyValue( ent, "weapon_stickgrenade", "1")
    }
    else if(equal(mod_name,"gearbox"))
    {
        DispatchKeyValue( ent, "weapon_knife", "1" );
        DispatchKeyValue( ent, "weapon_m249", "1" );
        DispatchKeyValue( ent, "weapon_pipewrench", "1" );
        DispatchKeyValue( ent, "weapon_sniperrifle", "1" );
    }
    else if(equal(mod_name,"valve"))
    {
        DispatchKeyValue( ent, "weapon_crowbar", "1" );
    }

    DispatchKeyValue( ent, "targetname", "game_playerspawn");
    DispatchSpawn(ent);
}


public pfn_keyvalue(ent)
{
    if(!bPatched)
    {
        bPatched = true
        new szMap[MAX_NAME_LENGTH]
        get_mapname(szMap, charsmax(szMap))

        if(equal(szMap, "vote_map_final"))
        {
            remove_entity_name(ent_type)
        }
    }
}
