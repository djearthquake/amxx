/*https://forums.alliedmods.net/showthread.php?t=340800*/
#include amxmodx
#include amxmisc
#include fakemeta
#include hamsandwich

#define HLW_357             17

/*https://forums.alliedmods.net/showthread.php?t=320610*/
new const SzDebug[]="Made %n set laser sight on 357."
new const SzBindAlias[]="+attack2;wait;+attack2;wait;-attack2;-attack2"
new const CvarLserDesc[] ="Force Eagle laser on 1|2 Force off bottomless mag"
new  XCvar_deagle_ray

new bool:g_bLazar[ MAX_PLAYERS + 1]

public plugin_init()
{
    bind_pcvar_num( create_cvar("mp_eagle_laser", "1", FCVAR_NONE, CvarLserDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0), XCvar_deagle_ray )
    register_event("CurWeapon", "trigger_laser", "b", "0=17");
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_eagle", "Ham_EagleSecondaryAttackPre", 1)
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_eagle", "Ham_EagleSecondaryAttackPst", 0)
    RegisterHam(Ham_Spawn, "player", "@client_spawn", 1);
    register_plugin("Weapon_eagle CVARS","12-12-22",".sρiηX҉.");
}

public Ham_EagleSecondaryAttackPre( const ent, iPlayer)
{
    if(!g_bLazar[iPlayer] && XCvar_deagle_ray == 1)
    {
        g_bLazar[iPlayer] = true
        client_print iPlayer, print_center, "[ALLOWED]^n^n EAGLE SCOPE"
        return  HAM_HANDLED
    }
    return  HAM_IGNORED
}

public Ham_EagleSecondaryAttackPst( const ent, iPlayer)
{
    if(g_bLazar[iPlayer] && XCvar_deagle_ray == 1)
    {
        if(is_user_admin(iPlayer))
            client_print iPlayer, print_chat, "ENT:%i",ent

        client_print iPlayer, print_center, "[BLOCKED]^n^n EAGLE SCOPE"
        return  HAM_SUPERCEDE
    }
    return  HAM_IGNORED
}

@client_spawn(iPlayer)
{
    if(is_user_connected(iPlayer) && XCvar_deagle_ray )
    {
        g_bLazar[iPlayer] = false
    }
}

public client_putinserver(iPlayer)
{
     if(is_user_connected(iPlayer) && XCvar_deagle_ray )
        g_bLazar[iPlayer] = false
}

public client_disconnected(iPlayer)
{
     if(!is_user_connected(iPlayer) && XCvar_deagle_ray )
        g_bLazar[iPlayer] = false
}

public trigger_laser(iPlayer)
{
    if(is_user_connected(iPlayer) && get_user_weapon(iPlayer) == HLW_357 && XCvar_deagle_ray == 1)
    {

        if(g_bLazar[iPlayer] == false)
        {
            set_task(0.5, "@mouse2", iPlayer+357)
        }

    }
}

public client_command(iPlayer)
{
    #define EAGLE 358
    #define MAX_BOX 200
    #define MAX_MAG 16
    new szArg[MAX_PLAYERS];
    new szArgCmd[MAX_IP_LENGTH], szArgCmd1[MAX_IP_LENGTH];

    read_args(szArg, charsmax(szArg));
    read_argv(0,szArgCmd, charsmax(szArgCmd));
    read_argv(1,szArgCmd1, charsmax(szArgCmd1));
    if(equal(szArgCmd,"weapon_eagle") && XCvar_deagle_ray == 2)
    {
        set_pdata_int(iPlayer, EAGLE, MAX_MAG)
        //laser sight toggle; first guess
        //native set_pdata_bool(_index, _offset, bool:_value, _linuxdiff = 20, _macdiff = 20);
        //2nd set_pdata_ehandle
    }
}

@mouse2(Tsk)
{
    new iPlayer = Tsk -357
    if(is_user_connected(iPlayer))
    {
        is_user_bot(iPlayer) ? /*HAMBOT TYPE CODE AMXX CLEVERNESS?*/ amxclient_cmd(iPlayer, SzBindAlias) : client_cmd(iPlayer, SzBindAlias/*HUMAN-ONLY*/)
        //amxclient_cmd iPlayer, SzBindAlias /*JK_BOTTI MENU ITEMS*/
        //engclient_cmd iPlayer, SzBindAlias /*NOTHING!*/
        g_bLazar[iPlayer] = true
        log_amx SzDebug, iPlayer
    }
}
