#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta

#define PLUGIN "OF:Grenades Only"
#define ACCESS_LEVEL    ADMIN_USER|ADMIN_CFG //ADMIN_LEVEL_A
#define VOTE_ACCESS     ADMIN_ALL
#define VERSION "1.1"

new g_counter[2], g_Grenades;

new const just_grenades[]="game_player_equip"
new const weap_strip[]="player_weaponstrip"
new const szCage[]="sound/misc/Bring_Knife.mp3"

new const szWeapons[][]=
{
    "item_ctfbackpack",
    "item_ctfregeneration",
    "item_ctfportablehev",
    "item_ctflongjump",
    "item_ctfaccelerator",
    "item_airtank",
    "item_longjump",
    "weapon_pipewrench",
    "weapon_penguin",
    "weapon_knife",
    "weapon_shockrifle",
    "weapon_sporelauncher",
    "weapon_m249",
    "weapon_grapple",
    "weapon_eagle",
    "weapon_sniperrifle",
    "weapon_displacer",
    "weapon_rpg",
    "ammo_556",
    "ammo_762",
    "ammo_357",
    "ammo_9mmclip",
    "ammo_9mmbox",
    "ammo_9mmAR",
    "ammo_ARgrenades",
    "ammo_crossbow",
    "ammo_gaussclip",
    "ammo_rpgclip",
    "ammo_buckshot",
    "ammo_spore",
    "item_longjump",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_crossbow",
    "weapon_crowbar",
    "weapon_egon",
    "weapon_gauss",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
    "weapon_9mmhandgun"
}

public plugin_init()
{
     register_plugin(PLUGIN, VERSION, ".sρiηX҉.");
     register_menucmd(register_menuid("Grenades?"),MENU_KEY_1|MENU_KEY_2,"voteGrenades")
}

public plugin_precache()
{
    register_concmd("vote_grenades","cmdVote",VOTE_ACCESS,": Vote for nades n' knives only!");
    bind_pcvar_num(get_cvar_pointer("mp_grenades") ? get_cvar_pointer("mp_grenades") : register_cvar("mp_grenades", "0"), g_Grenades)
    precache_generic(szCage)
    if(g_Grenades)
    {
        new ent2 = create_entity(weap_strip)
        {
            DispatchKeyValue( ent2,"targetname", "game_playerspawn")
            DispatchSpawn(ent2);
        }

        new ent = create_entity(just_grenades)
        {
            DispatchKeyValue( ent, "weapon_handgrenade", "1" )
            DispatchKeyValue( ent, "ammo_9mmclip", "2" )
            DispatchKeyValue( ent, "weapon_knife", "1" )
            DispatchKeyValue( ent, "weapon_9mmhandgun", "1" )
            DispatchKeyValue( ent, "targetname", "game_playerspawn")
            DispatchSpawn(ent);
        }
    }
}

public cmdVote(player,level,cid)
{
    if(!cmd_access(player,level,cid,1) || task_exists(8845)) return PLUGIN_HANDLED

    new keys = MENU_KEY_1|MENU_KEY_2
    for(new i = 0; i < 2; i++)
        g_counter[i] = 0

    new menu[MAX_USER_INFO_LENGTH]

    new len = format(menu,charsmax(menu),"[AMX] Grenades?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes")
    len += format(menu[len],charsmax(menu),"^n2. No")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_results",8845)
    return PLUGIN_HANDLED
}

public voteGrenades(player, key)
    g_counter[key]++

public vote_results()
{
    if(g_counter[0] > g_counter[1])
    {
        g_Grenades = 1
        set_cvar_num("mp_grenades", 1)
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") %s is now %s on next map.", PLUGIN, VERSION, g_counter[0], g_counter[1], PLUGIN, g_Grenades? "enabled" : "disabled")
    }
    else if(g_counter[1] > g_counter[0])
    {
        g_Grenades = 0
        set_cvar_num("mp_grenades", 0)
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") %s is now %s, on next map.", PLUGIN, VERSION, g_counter[0], g_counter[1], PLUGIN, g_Grenades ? "enabled" : "disabled")
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed. No votes counted.", PLUGIN, VERSION)
        client_cmd 0, "mp3 play ^"%s^"", szCage
    }
}

public plugin_cfg()
{
    if(g_Grenades)
        set_task(0.1,"@remove")
}

@remove()
{
    server_print "Scanning new map to remove weapons..."
    for(new ent; ent < sizeof szWeapons;++ent)
    if(has_map_ent_class(szWeapons[ent]))
    {
        server_print "Attempting to remove: %s.", szWeapons[ent]
        remove_entity_name(szWeapons[ent])
    }
}
