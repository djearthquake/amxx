/*  Weaponbox Sweeper - keep ent count down.
 *   ----------------------------
 *  -Remove excess Half-Life 1 weaponboxes by CVAR.
 *  -Display who got whose box in debug 2.
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
 *
 */

#include amxmodx
#include amxmisc
#include engine_stocks
#include fakemeta
#include hamsandwich
#define charsmin -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

#define SWEEP_LEVEL ADMIN_LEVEL_F

new const ent_type[]="weaponbox"

new g_Adm, g_box_debug, g_ent_count, g_box_lim
new Picked[MAX_PLAYERS+1]
static g_maxplayers

public plugin_init()
{
    register_plugin( "Weaponbox sweeper", "1.1", "SPiNX" );
    register_touch(ent_type, "player", "minus")
    if(get_cvar_pointer("sv_hookpickweapons"))
    {
        static register_ent; register_ent = find_ent_by_class(charsmin, ent_type);
        RegisterHamFromEntity(Ham_Touch, register_ent, "minus_hook")
    }

    RegisterHam(Ham_Spawn, "weaponbox", "@_weaponbox", 1)
    g_box_lim =  register_cvar("weaponbox_sweep", "10") //Box limit.
    g_box_debug =  register_cvar("weaponbox_debug", "0"); //Show count.
    g_maxplayers = get_maxplayers()
}

public minus_hook()
{
    static ent; ent = g_maxplayers;
    g_ent_count = 0;
    while( (ent = find_ent(ent, ent_type) ) > g_maxplayers )
    if(pev_valid(ent) && pev(ent, pev_owner) > 0 && pev(ent, pev_owner) <= g_maxplayers)
    {
        g_ent_count++
    }
    if(g_ent_count)
    {
        box_status();
    }
}

public minus(box, player)
{
    static box_owner; box_owner = pev(box, pev_owner)
    static box_debug; box_debug = get_pcvar_num(g_box_debug);
    if(is_user_alive(player) && !Picked[player])
    {
        Picked[player] = true
        g_ent_count--

        if(is_user_connected(box_owner) && box_debug>1)
        {
            client_print 0, print_chat, "%n picked up %n's box.", player, box_owner
        }

        if(!task_exists(player))
        {
            set_task(0.1, "end_clamp", player)
        }
    }
    box_status()
}

public end_clamp(player)
{
    Picked[player] = false
}

@_weaponbox(iloot_crate)
{
    g_ent_count++
    static box_limit; box_limit = get_pcvar_num(g_box_lim)

    if(g_ent_count >= box_limit)
    {
        ent_limiter()
    }

    box_status();

}

ent_limiter()
{
    static ent; ent = g_maxplayers
    while( (ent = find_ent(ent, ent_type) ) > g_maxplayers )
    pev_valid(ent) ? (set_pev(ent, pev_flags, FL_KILLME) & g_ent_count--) : (g_ent_count--);
}

public client_putinserver(id)
{
    client_infochanged(id)
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        get_user_flags(id) & SWEEP_LEVEL ? (SetPlayerBit(g_Adm, id)) : (ClearPlayerBit(g_Adm, id))
    }
}

box_status()
{
    static box_debug; box_debug = get_pcvar_num(g_box_debug);

    if(!box_debug)
        return;

    for (new admin=1; admin<=g_maxplayers; ++admin)
    if (is_user_connected(admin) && CheckPlayerBit(g_Adm, admin))
        client_print admin, print_center, "%s:%d", ent_type, g_ent_count
}
