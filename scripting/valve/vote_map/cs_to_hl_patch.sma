/*vote_map_orange CS map revised for GoldSRC*/
#include amxmodx
#include engine

new bool:bPatched, bool:bHL
new const ent_type[]="game_player_equip"
new mod_name[MAX_NAME_LENGTH]

public plugin_init()
{
    register_plugin("Fix:CS-HL map guns", "1.2", "SPiNX")
}

public plugin_precache()
{
    get_modname(mod_name, charsmax(mod_name));
    new ent = create_entity(ent_type)

    log_amx "Attempting to partially patch Counter-Strike map for %s.", mod_name

    if(bPatched)
    {
        remove_entity_name(ent_type)
        remove_entity_name("ambient_generic")
        remove_entity_name("armoury_entity")
        remove_entity_name("cycler_sprite")
        remove_entity_name("env_render")
        remove_entity_name("env_shooter")
        remove_entity_name("func_button")
        remove_entity_name("multi_manager")
        remove_entity_name("player_weaponstrip")
    }
    if(equal(mod_name,"dod"))
    {
        DispatchKeyValue( ent, "weapon_colt", "1")
        DispatchKeyValue( ent, "weapon_amerknife", "1")
        DispatchKeyValue( ent, "weapon_handgrenade", "1")
        DispatchKeyValue( ent, "weapon_stickgrenade", "1")
    }
    else if(equal(mod_name,"gearbox"))
    {
        DispatchKeyValue( ent, "weapon_knife", "1" )
        DispatchKeyValue( ent, "weapon_m249", "1" )
        DispatchKeyValue( ent, "weapon_pipewrench", "1" )
        DispatchKeyValue( ent, "weapon_sniperrifle", "1" )
    }
    else if(equal(mod_name,"valve"))
    {
        DispatchKeyValue( ent, "weapon_crowbar", "1" )
    }
    else if(equal(mod_name,"tfc"))
    {
        precache_model("models/v_crowbar.mdl")
        precache_model("models/w_crowbar.mdl")
        precache_model("models/p_crowbar.mdl")

        DispatchKeyValue( ent, "weapon_crowbar", "1" )
        DispatchKeyValue( ent, "tf_weapon_knife", "1" )
        DispatchKeyValue( ent, "tf_weapon_spanner", "1" )
    }
    else
    {
        log_amx "Update script for %s please.", mod_name
        server_print "Post in URL::github.com/djearthquake"
        pause("a")
    }

    DispatchKeyValue( ent, "targetname", "game_playerspawn")
    DispatchSpawn(ent);
}


public pfn_keyvalue(ent)
{
    if(!bHL)
    {
        bHL = true
        new szMap[MAX_NAME_LENGTH]
        get_mapname(szMap, charsmax(szMap))

        if(equal(szMap, "vote_map_final"))
        {
            bPatched = true
        }
    }
}
