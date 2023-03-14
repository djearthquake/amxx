/*
 * flag_time_fix.sma
 * The time left projector is a decent workaround for Linux.
 * Copyright 2023 SPiNX <Fixes the op4ctf timer from reappearing on regular maps.>
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
#include engine_stocks
#include fakemeta
#define charsmin -1

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
#define m_bIsTimer (1<<4)
static g_compatible1, g_compatible2, m_iHideHUD, bool:B_op4c_map

public plugin_init()
{
    register_plugin("OF:FlagTimer", "1.0", ".sρiηX҉.");
    g_compatible1 = get_user_msgid("FlagTimer")
    g_compatible2 = get_user_msgid("HudColor")
    if(!g_compatible1|!g_compatible2)
    {
        log_amx "Your mod does not support 'OP4CTF'."
        pause "c"
    }
    register_event ( "ResetHUD" , "@flag_time_fix" , "bef" )
    m_iHideHUD = (find_ent_data_info("CBasePlayer", "m_iHideHUD") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    new info_detect = find_ent(charsmin,"info_ctfdetect")
    B_op4c_map = info_detect ? true : false
}

@flag_time_fix(id)
if(is_user_connected(id))
{
    set_pdata_int(id, m_iHideHUD, get_pdata_int(id, m_iHideHUD) | m_bIsTimer ) //unhide timer?

    emessage_begin(MSG_ONE_UNRELIABLE, g_compatible1, _, id)
    ewrite_byte(B_op4c_map ? 1 : 0) //show TIME REMAINING
    emessage_end()

    if(B_op4c_map)
    {
        new SzTeam[MAX_PLAYERS]
        get_user_team(id, SzTeam, charsmax(SzTeam));
        
        //client_print id, print_chat, SzTeam
        emessage_begin(MSG_ONE_UNRELIABLE, g_compatible2, _, id)
        if(equal(SzTeam,"Opposing Force"))
        {
            ewrite_byte(0)
            ewrite_byte(255) //GREEN HUD
            ewrite_byte(0)
        }
        else
        {
            ewrite_byte(234)
            ewrite_byte(151) //ORANGE HUD
            ewrite_byte(25)
        }
        emessage_end()
    }
    else
    {
        emessage_begin(MSG_ONE_UNRELIABLE, g_compatible2, _, id)
        ewrite_byte(0)
        ewrite_byte(255) //GREEN HUD REGULAR MAP
        ewrite_byte(0)
        emessage_end()
    }
}
