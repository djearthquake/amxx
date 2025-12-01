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
#define MAX_ITEM_TYPES 6

static const m_rgpPlayerItems_CWeaponBox[MAX_ITEM_TYPES] = {22, 23, ...} //OP4
static m_pNext;

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
const UNIX_DIFF = 20;

static const ent_type[]="weaponbox"

new g_Adm, g_box_debug, g_ent_count, g_master_count, g_box_lim
new Picked[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin( "Weaponbox sweeper", "1.3", "SPiNX" );
    register_touch(ent_type, "player", "minus")
    register_touch("trigger_hurt", ent_type, "@destroy")
    if(get_cvar_pointer("sv_hookpickweapons"))
    {
        static register_ent; register_ent = find_ent_by_class(charsmin, ent_type);
        RegisterHamFromEntity(Ham_Touch, register_ent, "minus_hook")
    }

    RegisterHam(Ham_Spawn, "weaponbox", "@_weaponbox", 1)
    g_box_lim =  register_cvar("weaponbox_sweep", "10") //Box limit.
    g_box_debug =  register_cvar("weaponbox_debug", "0"); //Show count.
    m_pNext = 46;
}

@destroy(iHurt, iWeaponbox)
{
    if(iWeaponbox>MaxClients)
    {
        //remove_entity(iWeaponbox)
        call_think(iWeaponbox)
    }
    if(!iWeaponbox)
    {
        g_ent_count--
    }
}

@GetWeaponBoxWeaponType(WeaponBoxEntity)
{
    static null[32];
    null ="weapon";
    if(WeaponBoxEntity)
    {
        static iWeapon
        for(new i; i < MAX_ITEM_TYPES; ++i)
        {
            iWeapon = get_pdata_cbase(WeaponBoxEntity, m_rgpPlayerItems_CWeaponBox[i], LINUX_OFFSET_WEAPONS)
            while(iWeapon>MaxClients)
            {
                static szClass[MAX_PLAYERS]
                pev(iWeapon, pev_classname, szClass, charsmax(szClass))

                iWeapon = get_pdata_cbase(iWeapon, m_pNext, LINUX_OFFSET_WEAPONS)
                replace(szClass, charsmax(szClass), "weapon_", "")
                return szClass;
            }
        }
    }
    return null
}


public minus_hook()
{
    static ent; ent = MaxClients;
    g_ent_count = 0;
    while( (ent = find_ent(ent, ent_type) ) > MaxClients )
    if(pev_valid(ent) && pev(ent, pev_owner) > 0 && pev(ent, pev_owner) <= MaxClients)
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
    static box_debug; box_debug = get_pcvar_num(g_box_debug);
    static box_owner; box_owner = pev(box, pev_owner);
    new szWeapon[32];
    copy(szWeapon, charsmax(szWeapon), @GetWeaponBoxWeaponType(box))

    if(is_user_alive(player) && !Picked[player])
    {
        Picked[player] = true
        if(!box)
        {
            g_ent_count--
        }

        if(box_debug>1)
        if(player != box_owner)
        //if(is_user_connected(box_owner))
        {
            client_print 0, print_chat, "%n picked up %n's %s.", player, box_owner, szWeapon
            //static buffer[4];num_to_str(box, buffer, charsmax(buffer));
            //set_task 0.1, "@delayed_print",player, buffer, charsmax(buffer);
        }

        if(!task_exists(player))
        {
            set_task(0.1, "end_clamp", player)
        }
    }
    box_status()
}

@delayed_print(buffer[], player)
{
    new box = str_to_num(buffer);
    static box_owner; box_owner = pev(box, pev_owner);
    if(is_user_connected(player) && is_user_connected(box_owner))
    {
        if(player != box_owner)
        {
            new szWeapon[32];
            copy(szWeapon, charsmax(szWeapon), @GetWeaponBoxWeaponType(box))
            //client_print 0, print_chat, "%n picked up %n's %s.", player, box_owner, @GetWeaponBoxWeaponType(box);
            client_print 0, print_chat, "%n picked up %n's %s.", player, box_owner, szWeapon
        }
    }
}

public end_clamp(player)
{
    Picked[player] = false
}

@_weaponbox(iloot_crate)
{
    if(iloot_crate)
    {
        g_ent_count++;g_master_count++
        static box_limit; box_limit = get_pcvar_num(g_box_lim)

        if(g_ent_count >= box_limit)
        {
            ent_limiter()
        }

        box_status();

    }

}

ent_limiter()
{
    #define OVERFLOW MAX_MOTD_LENGTH

    static ent, ent_debug;
    ent_debug = get_pcvar_num(g_box_debug);
    new bool:bChanged

    ent = MaxClients
    while( (ent = find_ent(ent, ent_type) ) > MaxClients && pev_valid(ent) )
    {
        //iThinking_ent = pev(ent, pev_nextthink);

        if(ent_debug)
        {
            static iEnts, iEntMax;
            iEnts = engfunc(EngFunc_NumberOfEntities)
            iEntMax = global_get(glb_maxEntities)
            //server_print("%d spawned --%d/%d ents/max...|Index (to be removed):%d: \%s/ (next think):%i", g_master_count, iEnts, iEntMax, ent, ent_type, iThinking_ent);
            server_print("%d spawned --%d/%d ents/max...|Index (to be removed):%d: \%s/", g_master_count, iEnts, iEntMax, ent, ent_type);
        }
        //iThinking_ent ? remove_entity(ent)  :  call_think(ent) ///set_pev(ent, pev_flags, FL_KILLME);
        set_task 1.0, "@remove_box", ent;

        if(ent > OVERFLOW && !bChanged)
        {
            bChanged = true
            static mapname[MAX_NAME_LENGTH];get_mapname(mapname, charsmax(mapname));
            log_amx("Reloading map due to ent limit reached.")
            console_cmd 0,  "changelevel %s", mapname
        }
    }
}

@remove_box(ent)
{
    if(pev_valid(ent))
    {
        call_think(ent)
        g_ent_count--;
    }

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

    for (new admin=1; admin<=MaxClients; ++admin)
    if (is_user_connected(admin) && CheckPlayerBit(g_Adm, admin))
        client_print admin, print_center, "%s:%d", ent_type, g_ent_count
}
