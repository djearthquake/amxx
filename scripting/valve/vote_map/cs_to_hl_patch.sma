/*vote_map_orange CS map revised for GoldSRC*/
#include amxmodx
#include engine
#define charsmin                  -1
#define MAX_CMD_LENGTH  128

new bool:bPatched, bool:bHL
new const ent_type[]="game_player_equip"
static g_mod_name[MAX_NAME_LENGTH]

new const szAnnoyingEnts[][]= {"ambient_generic"/*"armoury_entity"*/, "cycler_sprite", "env_render", "func_button", "multi_manager"}

public plugin_init()
{
    register_plugin("Fix:CS-HL map guns", "1.3", "SPiNX")

    if(has_map_ent_class("monster_nihilanth"))
        remove_entity_name("monster_nihilanth")

    get_modname(g_mod_name, charsmax(g_mod_name));
    //bHL = true

    log_amx "Attempting to partially patch Counter-Strike map for %s.", g_mod_name

    if(bPatched && has_map_ent_class("ambient_generic"))
    {
        remove_entity_name("ambient_generic")
        remove_entity_name(ent_type)
    }

    new ent; ent = create_entity(ent_type)

    if(equal(g_mod_name,"dod"))
    {
        DispatchKeyValue( ent, "weapon_colt", "1")
        DispatchKeyValue( ent, "weapon_amerknife", "1")
        DispatchKeyValue( ent, "weapon_handgrenade", "1")
        DispatchKeyValue( ent, "weapon_stickgrenade", "1")
    }
    else if(equal(g_mod_name,"gearbox"))
    {
        if(has_map_ent_class("player_weaponstrip"))
        {
            remove_entity_name("player_weaponstrip")
            DispatchKeyValue( ent, "weapon_sniperrifle", "1" )
            DispatchKeyValue( ent, "weapon_m249", "1" )
            //goto END
        }
    }
    else if(equal(g_mod_name,"valve"))
    {
        DispatchKeyValue( ent, "weapon_crowbar", "1" )
    }
    else if(equal(g_mod_name,"tfc"))
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
        log_amx "Update script for %s please.", g_mod_name
        server_print "Post in URL::github.com/djearthquake"
        pause("a")
    }

    DispatchKeyValue( ent, "targetname", "game_playerspawn")
    if(is_valid_ent(ent))
        DispatchSpawn(ent)

    //if(bPatched)
    static szMap[MAX_NAME_LENGTH]
    get_mapname(szMap, charsmax(szMap))
    if(equal(szMap, "vote_map_final"))
    {
        server_print szMap
        //bPatched = true
        for(new list;list<sizeof(szAnnoyingEnts);list++)
        if(has_map_ent_class(szAnnoyingEnts[list]))
        {
            server_print szAnnoyingEnts[list]
            remove_entity_name(szAnnoyingEnts[list])
        }
    }
}

public plugin_precache()
{
    precache_sound("fgrunt/gr_death2.wav")
    precache_sound("fgrunt/gr_death3.wav")
    precache_sound("fgrunt/gr_death4.wav")
    precache_sound("fgrunt/gr_death5.wav")
    precache_sound("fgrunt/gr_death6.wav")
}


public pfn_keyvalue(ent)
{
    static Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(equali(Classname,"ambient_generic"))
        DispatchKeyValue("message", "0")

    if(!bHL)
    {
        bHL = true
        new szMap[MAX_NAME_LENGTH]
        get_mapname(szMap, charsmax(szMap))

        if(equal(szMap, "vote_map_final"))
        {
            server_print szMap
            bPatched = true
        }
    }
}
/*
public pfn_keyvalue(ent)
{
    static Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(equali(Classname,"ambient_generic"))
        DispatchKeyValue("message", "0")

    //if(equali(Classname,"game_player_equip"))
    //    DispatchKeyValue("target", "0")
    //if(!bPatched)
}
*/
