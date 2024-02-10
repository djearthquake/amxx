#include amxmodx
#include fakemeta
#include hamsandwich

#define PLUGIN "AR SHOTTY DAMAGE ADJ"
#define VERSION "1.0"

new const CvarXMultiplerDesc[]="Damage multiplier"

new const gWeaponClassname[] = "weapon_shotgun"
new bool:bShottyAttack[MAX_PLAYERS +1]
new Float:XMultipler

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, ".sρiηX҉.");
    
    RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_Attack_Pre" , 0 )
    RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_Attack_Post" , 1 )

    RegisterHam( Ham_Weapon_SecondaryAttack  , gWeaponClassname, "Weapon_Attack_Pre" , 0 )
    RegisterHam( Ham_Weapon_SecondaryAttack  , gWeaponClassname, "Weapon_Attack_Post" , 1 )
    RegisterHam(Ham_TakeDamage, "player", "Event_Damage", 0);
    bind_pcvar_float(get_cvar_pointer("mp_damage_multiplier") ?
    get_cvar_pointer("mp_damage_multiplier") :
    create_cvar("mp_damage_multiplier", "0.1", FCVAR_SERVER, CvarXMultiplerDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 10.0), XMultipler)
}

public Weapon_Attack_Pre( const weapon )
{
    static iPlayer;iPlayer = pev(weapon, pev_owner)
    bShottyAttack[iPlayer] = true
}

public Weapon_Attack_Post( const weapon )
{
    static iPlayer;iPlayer = pev(weapon, pev_owner)
    bShottyAttack[iPlayer] = false
}

public Event_Damage(victim, inflictor, attacker, Float:fDamage, dmgbits)
{
    if(is_user_connected(attacker))
    {
        #define DAMAGE       4
        new Float:Damage_adj  = fDamage*XMultipler;

        if(bShottyAttack[attacker] || dmgbits == DMG_BLAST )
        {
            if(!XMultipler)
                return HAM_SUPERCEDE
            else
                SetHamParamFloat(DAMAGE, Damage_adj)
            client_print attacker, print_center, "%i", floatround(Damage_adj)
        }
        else return HAM_IGNORED
    }
    return PLUGIN_HANDLED

}
