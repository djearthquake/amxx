/*vote_map_orange CS map revised for HL/OP4*/
#include amxmodx
#include engine
new bool:bPatched, bool: op4_running
new const ent_type[]="game_player_equip"

enum{ammo_57mm, ammo_556natobox,weapon_fiveseven,item_assaultsuit};
enum{func_buyzone,armoury_entity,func_escapezone,env_rain,info_map_parameters,func_hostage_rescue};

public plugin_init()
{
    register_plugin("CS to HL/OP4 map weapons patch", "1.2", "SPiNX");
}

public pfn_keyvalue()
{
    if(!bPatched)
    {
        bPatched = true
        if(get_user_msgid("OldWeapon"))
        {
            op4_running = true
        }

        remove_entity_name(ent_type)
        new ent = create_entity(ent_type)

        if(op4_running)
        {
            DispatchKeyValue( ent, "weapon_knife", "1" );
            DispatchKeyValue( ent, "weapon_m249", "1" );
            DispatchKeyValue( ent, "weapon_pipewrench", "1" );
            DispatchKeyValue( ent, "weapon_sniperrifle", "1" );
        }

        DispatchKeyValue( ent, "targetname", "game_playerspawn");
        DispatchSpawn(ent);
    }
}
