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


new const ent_type[]="weaponbox"

new g_Adm, g_box_debug, g_ent_count, g_master_count, g_box_lim
new Picked[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin( "Weaponbox sweeper", "1.2", "SPiNX" );
    register_touch(ent_type, "player", "minus")
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

@_box(iWeaponbox)
{
    set_task 0.1, "@GetWeaponBoxWeaponType",iWeaponbox;
}

@GetWeaponBoxWeaponType(WeaponBoxEntity)
{
    static null[32];
    null ="gun";
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
    static box_owner; box_owner = pev(box, pev_owner)
    static box_debug; box_debug = get_pcvar_num(g_box_debug);
    if(is_user_alive(player) && !Picked[player])
    {
        Picked[player] = true
        g_ent_count--

        if(is_user_connected(box_owner) && box_debug>1)
        {
            client_print 0, print_chat, "%n picked up %n's %s.", player, box_owner, @GetWeaponBoxWeaponType(box)
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
    g_ent_count++;g_master_count++
    static box_limit; box_limit = get_pcvar_num(g_box_lim)

    if(g_ent_count >= box_limit)
    {
        ent_limiter()
    }

    box_status();

}

ent_limiter()
{
    #define OVERFLOW MAX_MOTD_LENGTH

    static ent, ent_debug, iThinking_ent; iThinking_ent = 0;
    ent_debug = get_pcvar_num(g_box_debug);
    new bool:bChanged

    ent = MaxClients
    while( (ent = find_ent(ent, ent_type) ) > MaxClients && pev_valid(ent) )
    {
        iThinking_ent = pev(ent, pev_nextthink);

        if(ent_debug)
        {
            static iEnts, iEntMax;
            iEnts = engfunc(EngFunc_NumberOfEntities)
            iEntMax = global_get(glb_maxEntities)
            server_print("%d spawned --%d/%d ents/max...|Index (to be removed):%d: \%s/ (next think):%i", g_master_count, iEnts, iEntMax, ent, ent_type, iThinking_ent);
        }

        iThinking_ent ? remove_entity(ent)  :  call_think(ent) ///set_pev(ent, pev_flags, FL_KILLME);

        g_ent_count--;

        if(ent > OVERFLOW && !bChanged)
        {
            bChanged = true
            static mapname[MAX_NAME_LENGTH];get_mapname(mapname, charsmax(mapname));
            log_amx("Reloading map due to ent limit reached.")
            console_cmd 0,  "changelevel %s", mapname
        }
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
