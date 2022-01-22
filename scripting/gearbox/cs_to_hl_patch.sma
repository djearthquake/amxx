/*vote_map_orange log error patch:CS ents on HL:OP$ error response enum clears but I want them to appear*/
#include amxmodx
#include engine

#define item_assaultsuit "item_battery","item_battery"
#define ammo_556natobox  "ammo_556","ammo_556"
#define ammo_57mm        "ammo_357","ammo_357","ammo_357"
#define weapon_fiveseven "weapon_9mmhandgun", "weapon_eagle", "weapon_357"
enum{ammo_556natobox,ammo_57mm,weapon_fiveseven,item_assaultsuit};
enum{func_buyzone,armoury_entity,func_escapezone,env_rain,info_map_parameters,func_hostage_rescue};

new const GIVES[][]={item_assaultsuit, ammo_556natobox, ammo_57mm, weapon_fiveseven}

public plugin_precache()

{
    register_plugin("CS to OP4 map weapons patch", "1.0", "SPiNX");
    new mname[MAX_PLAYERS];
    new ent = create_entity("game_player_equip")
    get_mapname(mname, charsmax(mname));
    if (containi(mname,"vote_map_") == -1)
    {
        pause "a"
    }
    else
    {
        for(new i;i < sizeof GIVES;++i) DispatchKeyValue( ent, GIVES[i], "1" ) && DispatchSpawn(ent)
    }

}

