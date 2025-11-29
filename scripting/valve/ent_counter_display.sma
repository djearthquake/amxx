/*
 * ent_counter_display.sma
 *
 * Copyright 2021 SPiNX <>
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
 *
 */

#include amxmodx
#include amxmisc
#include fakemeta

#define PLUGIN  "Ent Count Display"
#define VERSION "1.2"
#define AUTHOR  "SPiNX"

#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/"

static const DESC[]= "Display Ent count."
new bool:bEntSee[MAX_PLAYERS + 1]

public plugin_init()
{

    #if AMXX_VERSION_NUM == 200
    register_plugin(PLUGIN, VERSION, AUTHOR, URL, DESC);
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR)
    #endif

    register_clcmd ( "ent_count", "@ent_count_access", ADMIN_SLAY, " - Display Ent counter." );
}


@ent_count_access(id,level,cid)
{
    if(!is_user_connected(id))
        return PLUGIN_HANDLED

    if(!cmd_access(id,level,cid,1))
    {
        client_print(id,print_chat,"You do not have access to %s %s by %s!",PLUGIN, VERSION, AUTHOR)
        return PLUGIN_HANDLED
    }

    bEntSee[id] = bEntSee[id] ? false : true;

    if(bEntSee[id] && !task_exists(555))
    {
        set_task(0.5, "@ent_counter_display", 555,_,_,"b")
    }

    return PLUGIN_HANDLED
}


@ent_counter_display()
{
    new iViewers
    static iEnts; iEnts = engfunc(EngFunc_NumberOfEntities)
    for (new client=1; client <= MaxClients; ++client)
    {
        if(bEntSee[client])
        {
            iViewers++
            if(is_user_connected(client))
            {
                client_print client, print_center, "Ent count:%i",iEnts
            }
            else
            {
                iViewers--
                bEntSee[client] = false;
            }
        }
    }
    if(!iViewers)
    {
        remove_task(555)
    }
}
