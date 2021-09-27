#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define MAX_NAME_LENGTH  32
#define charsmin -1

new const GIVES[][]=
{
    "ammo_9mmbox",
    "ammo_ARgrenades",
    "ammo_buckshot",
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
    "item_longjump",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_crossbow",
    /*"weapon_crowbar",*/
    "weapon_egon",
    "weapon_gauss",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_rpg",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
    "weapon_9mmhandgun"
}

new const REPLACE[][] = {"ammo_", "weapon_", "item_"}
new const tracer[]={"ammo_buckshot"}
new g_map_ent

public plugin_init()
{
    register_plugin("Gives random weapon(s) on spawn.", "A", ".sρiηX҉.");
    RegisterHam(Ham_Spawn, "player", "client_getfreestuff", 1);

    new mname[MAX_NAME_LENGTH];
    get_mapname(mname,charsmax(mname));
    g_map_ent = find_ent_by_class(charsmin, tracer)
    if (containi(mname,"op4c") > charsmin || g_map_ent)
        pause "a";
}

public client_getfreestuff(id)
{
    if( !is_user_connected(id) || is_user_bot(id) )
    return PLUGIN_HANDLED_MAIN;

    client_print id, print_chat, "Free random items on spawn!"

    if( is_user_alive(id) && is_user_admin(id) )
    {
        #if AMXX_VERSION_NUM == 182;
        set_task(5.0, "reward", id, _, _, "a", 4);
        #else
        set_task_ex(5.0, "reward", id, .flags = SetTask_RepeatTimes, .repeat = 4);
        #endif
        give_item(id, "weapon_knife");
    }
    else
    if( is_user_alive(id) )
        #if AMXX_VERSION_NUM == 182;
        set_task(10.0, "reward", id, _, _, "a", 2);
        #else
        set_task_ex(10.0, "reward", id, .flags = SetTask_RepeatTimes, .repeat = 2);
        #endif

    return PLUGIN_CONTINUE;
}

public reward(needy)
{
    new charity[MAX_NAME_LENGTH];
    formatex(charity, charsmax(charity), GIVES[random(sizeof(GIVES))]);
    if( is_user_alive(needy) )
    {
        give_item(needy, charity);
        for ( new MENT; MENT < sizeof REPLACE; ++MENT )
            replace(charity, charsmax(charity), REPLACE[MENT], " ");

        if(!is_user_bot(needy))
            client_print(needy, print_center,"^n Free%s!", charity);
    }


}
