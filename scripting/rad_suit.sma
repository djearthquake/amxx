#include amxmodx
#include amxmisc
#include fakemeta
#include hamsandwich

#define PLUGIN "RAD SUIT"
#define VERSION "0.1"
#define AUTHOR ".sρiηX҉."

#define fNULL 0.0
#define charsmin -1

#define DAMAGE_LEVEL ADMIN_LEVEL_F
#define VIP_FLAG ADMIN_LEVEL_H

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new bool:bRegistered;
new bool:bSuit[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHam(Ham_TakeDamage, "player", "Fw_Damage", 0);
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bSuit[id] = is_vip(id) ? true : false
    }
}

public Fw_Damage(victim, inflictor, attacker, Float:fDamage, dmgbits)
{
    if(is_user_alive(victim))
    {
        if(dmgbits == DMG_RADIATION || dmgbits == DMG_SONIC)
        {
            if(bSuit[victim])
            {
                #define DAMAGE 4
                SetHamParamFloat(DAMAGE,fNULL)
            }
        }
    }
    return PLUGIN_HANDLED
}

public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT")  && !bRegistered)
    {
        bRegistered = true;
        if(get_cvar_pointer("bot_quota"))
        {
            set_task(0.1, "@register", id);
        }
    }
}

@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity(Ham_TakeDamage, ham_bot, "Fw_Damage", 0 );
        server_print("%s|%s|%s hambot from %N", PLUGIN, VERSION, AUTHOR, ham_bot)
    }
}


#if defined CSTRIKE
stock is_vip(victim)

    return cstrike_running() ? cs_get_user_vip(victim) | get_user_flags(victim) & VIP_FLAG
    : get_user_flags(victim) & VIP_FLAG
#else
stock is_vip(victim)return is_user_connected(victim) && get_user_flags(victim) & VIP_FLAG
#endif

/*Do not edit this line! 01010011 01010000 01101001 01001110 01011000*/
