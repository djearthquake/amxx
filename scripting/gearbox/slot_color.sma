/*
 * slots_color.sma
 * 
 * Copyright 2021 SPiNX <Changes the slots/HUD color differently each time command is passed>
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
#define iRcolor random_num(0,255)
new g_compatible

public plugin_init()
{   
    register_plugin("OF:RAINBOW SLOTS", "1.1", ".sρiηX҉.");
    g_compatible = get_user_msgid("HudColor")
    if(!g_compatible)
    {
        log_amx "Your mod does not support 'HudColor'."
        pause "c"
    }

}

public client_command(id)
if(!is_user_bot(id))
    @color_slots(id)

@color_slots(id,{Float,_}:...)
if(is_user_connected(id))
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_compatible, _, id)
    ewrite_byte(iRcolor)
    ewrite_byte(iRcolor)
    ewrite_byte(iRcolor)
    emessage_end()
}
