#include amxmodx
#include engine_stocks
#include fakemeta
#include cstrike
#include hamsandwich

static const szEnt[]="func_breakable"
new g_item_cost

public plugin_init()
{
    register_plugin ("Breakable Cost", "0.2", "spinx")

    static iEnt; iEnt = MaxClients
    iEnt = find_ent(iEnt, szEnt)

    if(iEnt)
    {
        RegisterHamFromEntity(Ham_TakeDamage, iEnt, "Ham_Killed_Post", 1)
        //RegisterHamFromEntity(Ham_Killed, iEnt, "Ham_Killed_Post", 1)
    }
    else
    {
        pause("a")
    }

    g_item_cost = register_cvar("break_cost", "5")
}


public Ham_Killed_Post(victim, inflictor, attacker, Float:damage, damagebits)
//public Ham_Killed_Post(victim, attacker, shouldgib)
{
    static iHp, iCost;
    iCost = get_pcvar_num(g_item_cost)
    if(victim)
    {
        iHp = pev(victim, pev_health)
    }
    if(iHp<2)
    if(is_user_connected(attacker))
    {
        //charge them
        static tmp_money; tmp_money = cs_get_user_money(attacker);
        client_print 0, print_chat, "%n will be charged $ %i for breaking that!", attacker, iCost
        cs_set_user_money(attacker, tmp_money-iCost)
    }
}
