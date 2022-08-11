#include amxmodx
#include engine
#include engine_stocks
#include hamsandwich
#define MAX_NAME_LENGTH 32
#define charsmin        -1
#define fNULL 0.0
new g_leets,g_usp

public plugin_init()
{
    RegisterHam(Ham_TakeDamage,"player","Damage", 0)
    register_plugin("Elite:no USP", "1.0", ".sρiηX҉.Snake");
    g_usp = register_cvar("mp_usp", "0")
    new mapname[MAX_NAME_LENGTH];get_mapname(mapname, charsmax(mapname))
    if(containi(mapname,"as_") != charsmin)
    {
        log_amx "Assassination map detected"
        pause "a";
    }

    /*Conflicts with Gungame*/
    if(get_cvar_pointer("gg_enabled") || get_cvar_pointer("scope_colt_cost"))
        set_task(10.0,"@eval_incompat",2448)

}

public plugin_precache()
{
    new ent;g_leets = register_cvar("mp_leets", "1")
    if(get_pcvar_num(g_leets))
    {
        ent = find_ent(charsmin,"game_player_equip") ? find_ent(charsmin,"game_player_equip") : create_entity("game_player_equip")
        !is_valid_ent(ent) ? log_amx("ERROR! Unable to init player equipment functions.") & set_fail_state("unable to equip player"):
        DispatchKeyValue( ent, "item_assaultsuit", "1"),
        DispatchKeyValue( ent, "weapon_knife", "1"),
        DispatchKeyValue( ent, "weapon_elite", "1" ),
        DispatchKeyValue( ent, "ammo_9mm", "4"),
        DispatchSpawn(ent);
    }


}

@eval_incompat()
{
    server_print "Checking if we should control USP damage"

    if(get_cvar_num("gg_enabled") == 1)
    {
        log_amx "Gungame is on"
        pause "a";
    }
    else if(get_cvar_pointer("scope_colt_cost"))
    client_print 0, print_chat, "Scoped colt USP is firing blanks because of .Snake!"
    server_print "No plugin conflicts found."
}

public Damage ( Victim, Inflictor, Attacker, Float:fDamage )
{
    if(get_pcvar_num(g_usp) || get_pcvar_num(g_leets))
    {

        if(is_user_alive(Attacker))
        {
            new damwpnname[MAX_NAME_LENGTH]
            new weapon = get_user_weapon(Attacker)
            get_weaponname(weapon,damwpnname,charsmax(damwpnname))

            if(get_pcvar_num(g_usp) && containi(damwpnname,"usp") != charsmin)
            {
                SetHamParamFloat(4,fNULL)
                server_print "%n is shooting USP blanks at %n", Attacker,Victim
                client_print 0, print_chat, "%n is shooting USP blanks at %n", Attacker,Victim
                client_cmd Attacker,"spk idiot"
                return HAM_SUPERCEDE
            }
            else if(get_pcvar_num(g_leets) && containi(damwpnname,"elite") != charsmin)
            {

                SetHamParamFloat(4,fDamage*3.5)
                client_print 0, print_chat, "%n is shooting Armor piercers at %n", Attacker,Victim

            }
            else  return HAM_IGNORED




        }


    }
    return HAM_HANDLED
}
