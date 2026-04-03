#include amxmodx
#include fakemeta
#include hamsandwich

#define charsmin                  -1

public plugin_init()
{
    register_plugin("Inflictor Test","1.0.3-","SPiNX")
    RegisterHam(Ham_TakeDamage, "player", "Event_Damage", 1);
}

public Event_Damage(victim, inflictor, attacker, Float:damage, damagebits)
{
    static szClass[MAX_NAME_LENGTH];

    pev(inflictor, pev_classname, szClass, charsmax(szClass))

    if(equal(szClass, "player"))
    {
        if(is_user_alive(inflictor))
        {
            static weapon;weapon = get_user_weapon(attacker)
            if(!weapon)
                return
            get_weaponname(weapon, szClass, charsmax(szClass))
        }
    }
    if(containi(szClass, "weapon_")>charsmin)
    {
        replace(szClass, charsmax(szClass), "weapon_", "")
    }
    if(!attacker)
    {
        client_print(victim, print_center,"%s damage", szClass)
    }
    else if(attacker<=MaxClients)
    {
        if(is_user_connected(attacker) && is_user_connected(victim))
        {
            client_print(victim, print_center,"%n's^n^n%s did^n^n%i", attacker, szClass, floatround(damage))
        }
    }
}
