/*
 * rad_suit.sma
 *
 * Copyright 2024  <SPiNX>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 0.1 - Fresh idea tested damage and made it handle CZ bots.
 * 0.2 - Added support for gungame and neon_grenades.
 */

#include amxmodx
#include amxmisc
#include fakemeta
#include hamsandwich

#define PLUGIN "RAD SUIT"
#define VERSION "0.2"
#define AUTHOR ".sρiηX҉."

#define fNULL 0.0
#define GUN_PRG "gungame.amxx"
#define GREN_PRG "neon_grenades.amxx"
#define charsmin -1

#define DAMAGE_LEVEL ADMIN_LEVEL_F
#define VIP_FLAG ADMIN_LEVEL_H

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new bool:bRegistered;
static bool:bNeon;
new bool:bSuit[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHam(Ham_TakeDamage, "player", "Fw_Damage", 0);
    bNeon = is_plugin_loaded(GREN_PRG,true)!=charsmin ? true : false
    if(bNeon)
    {
        server_print("Neon trace detected!")
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bSuit[id] = is_vip(id) ? true : false
        //Give everybody a suit when running Neon grenades and Gungame.
        //init is no good when gungame is not 24/7 and loaded only under some maps.
        if(bNeon)
        {
            new gun_game = is_plugin_loaded(GUN_PRG,true)!=charsmin ? true : false
            if(gun_game)
            {
                server_print("Gungame detected.")
                bSuit[id] = true
            }
        }

        if(bSuit[id])
        {
            server_print "Gave %n a rad suit.", id
            client_print 0, print_chat, "Gave %n a rad suit.", id
        }
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
