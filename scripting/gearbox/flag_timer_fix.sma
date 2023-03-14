/*
 * flag_timer_fix.sma
 *
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
new g_compatible1, g_compatible2;

public plugin_init()
{
    register_plugin("OF:FlagTimer", "1.0", ".sρiηX҉.");
    g_compatible1 = get_user_msgid("FlagTimer")
    g_compatible2 = get_user_msgid("HudColor")
    if(!g_compatible1|!!g_compatible2)
    {
        log_amx "Your mod does not support 'OP4CTF'."
        pause "c"
    }
    register_event ( "ResetHUD" , "@flag_time_fix" , "b" )

}

@flag_time_fix(id)
if(is_user_connected(id))
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_compatible1, _, id)
    ewrite_byte(0)
    emessage_end()

    emessage_begin(MSG_ONE_UNRELIABLE, g_compatible2, _, id)
    ewrite_byte(0)
    ewrite_byte(255)
    ewrite_byte(0)
    emessage_end()
}
