/*https://forums.alliedmods.net/showthread.php?t=340800*/
#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta
#include hamsandwich

#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

#define HLW_357             17
#define EAGLE 358
#define MAX_BOX 200
#define MAX_MAG 16

new iEagle;

new const SzDebug[]="Made %n set laser sight on 357."
new const SzBindAlias[]="+attack2;wait;+attack2;wait;-attack2;-attack2"
new const CvarLserDesc[] ="Auto laser on with CVARS!"
new const ent_type[]="game_player_equip"

new  XCvar_deagle_ray

new bool:g_bLasered_357[ MAX_PLAYERS + 1 ][MAX_CMD_LENGTH]
new bool:g_bSpawned[ MAX_PLAYERS + 1]
new bool:g_bMapSpawns357

public plugin_init()
{
    bind_pcvar_num( create_cvar("mp_eagle_laser", "1", FCVAR_NONE, CvarLserDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0), XCvar_deagle_ray )
    register_event("CurWeapon", "trigger_laser", "b", "0=17");
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_eagle", "Ham_EagleSecondaryAttack")
    register_plugin("Weapon_eagle CVARS","12-12-22",".sρiηX҉.");
    register_event ( "ResetHUD" , "@client_spawn", "be"  )
    ///RegisterHam(Ham_Spawn, "player", "@client_spawn", 1)
    RegisterHam(Ham_Killed, "player", "@death");

    register_clcmd("weapon_eagle", "trigger_laser", 0, "- null")
}

public Ham_EagleSecondaryAttack(const iEagle, iPlayer)
{
    if(XCvar_deagle_ray == 2)
    {
        client_print iPlayer, print_center, "[BLOCKED]^n^n EAGLE SCOPE"
        return  HAM_SUPERCEDE
    }
    else if(XCvar_deagle_ray == 1)
    {
        if(!g_bLasered_357[iPlayer][iEagle])
        {
            if(pev_valid(iEagle))
                g_bLasered_357[iPlayer][iEagle] = true

            client_print iPlayer, print_center, "[ALLOWED]^n^n EAGLE SCOPE"
            return  HAM_IGNORED
        }
        else
        {
            client_print iPlayer, print_center, "[BLOCKED]^n^n EAGLE SCOPE"
            return  HAM_SUPERCEDE
        }
    }
    return  HAM_IGNORED
}

@client_spawn(iPlayer)
{
    if(is_user_alive(iPlayer))
    {
        g_bLasered_357[iPlayer][iEagle] = false
        g_bSpawned[iPlayer] =  true
        if(XCvar_deagle_ray == 3)
        {
            set_pdata_int(iPlayer, EAGLE, MAX_BOX)
        }
    }
}

@death(iPlayer)
{
    g_bSpawned[iPlayer] =  false
    g_bLasered_357[iPlayer][iEagle] = false
}

public client_putinserver(iPlayer)
{
    if(is_user_connected(iPlayer))
        g_bLasered_357[iPlayer][iEagle] = false

    if(g_bMapSpawns357)
        set_task(0.2, "@mouse2", iPlayer+357)
}

public client_disconnected(iPlayer)
{
    g_bSpawned[iPlayer] =  false
    g_bLasered_357[iPlayer][iEagle] = false
}

public trigger_laser(iPlayer)
{
    if(g_bSpawned[iPlayer] == true && get_user_weapon(iPlayer) == HLW_357 && XCvar_deagle_ray == 1)
    {

        if(is_user_bot(iPlayer))
            set_pev(iPlayer,pev_button,IN_ATTACK2)

        if(g_bLasered_357[iPlayer][iEagle] == false && !task_exists(iPlayer + 357))
        {
            set_task(0.7, "@mouse2", iPlayer+357)
        }

    }
}

@mouse2(Tsk)
{
    new iPlayer = Tsk -357
    if(is_user_connected(iPlayer))
    {
        g_bLasered_357[iPlayer][iEagle] = true
        is_user_bot(iPlayer) ? set_pev(iPlayer,pev_button,~IN_ATTACK2) : client_cmd(iPlayer, SzBindAlias)
        log_amx SzDebug, iPlayer
    }
}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    if(equali( Classname, ent_type) && containi(key,"weapon_eagle") > charsmin )
    {
        g_bMapSpawns357 = true
    }

}

public plugin_precache()
{
    if(!g_bMapSpawns357 && XCvar_deagle_ray > 2)
    {
        new ent = create_entity(ent_type)
        DispatchKeyValue( ent, "weapon_eagle", "1" )
        DispatchSpawn(ent);
    }
}
