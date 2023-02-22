/*vote_map_orange CS map revised for HL/OP4*/
//need models/chick.mdl
#include amxmodx
#include engine
new bool:bPatched
new const ent_type[]="game_player_equip"

enum{ammo_57mm, ammo_556natobox,weapon_fiveseven,item_assaultsuit};
enum{func_buyzone,armoury_entity,func_escapezone,env_rain,info_map_parameters,func_hostage_rescue};
enum{info_player_coop};

public plugin_init()
{
    register_plugin("Fix:CS-HL map guns", "1.2", "SPiNX");
}

public pfn_keyvalue()
{
    if(!bPatched)
    {
        bPatched = true
        new mod_name[MAX_NAME_LENGTH]
        get_modname(mod_name, charsmax(mod_name));

        if(has_map_ent_class("func_buyzone"))
        {
            log_amx"Attempting to partially patch Counter-Strike map for other GoldSrc mod."

            if(has_map_ent_class(ent_type))
            {
                remove_entity_name(ent_type)
            }

            new ent = create_entity(ent_type)

            if(equali(mod_name,"dod"))
            {
                DispatchKeyValue( ent,"weapon_colt", "1")
                DispatchKeyValue( ent,"weapon_amerknife", "1")
                DispatchKeyValue( ent, "weapon_handgrenade", "1")
                DispatchKeyValue( ent, "weapon_stickgrenade", "1")
            }
            else if(equali(mod_name,"gearbox"))
            {
                DispatchKeyValue( ent, "weapon_knife", "1" );
                DispatchKeyValue( ent, "weapon_m249", "1" );
                DispatchKeyValue( ent, "weapon_pipewrench", "1" );
                DispatchKeyValue( ent, "weapon_sniperrifle", "1" );
            }
            else if(equali(mod_name,"valve"))
            {
                DispatchKeyValue( ent, "weapon_crowbar", "1" );
            }
    
            DispatchKeyValue( ent, "targetname", "game_playerspawn");
            DispatchSpawn(ent);
        }
    }
}
