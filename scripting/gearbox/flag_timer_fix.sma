/*
 * flag_time_fix.sma
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
#include amxmisc
#include engine_stocks
#include fakemeta
#define charsmin -1

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
#define m_bIsTimer (1<<4) //CS only then
static g_compatible1, g_compatible2,bool:B_op4c_map//, m_iHideHUD, m_iUpdateTime,m_iClientHideHUD
new bool:bProjector[MAX_PLAYERS+1]
new bool:bBlackMesa[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin("OF:FlagTimer", "1.1", ".sρiηX҉.");
    g_compatible1 = get_user_msgid("FlagTimer")
    g_compatible2 = get_user_msgid("HudColor")
    if(!g_compatible1|!g_compatible2)
    {
        log_amx "Your mod does not support 'OP4CTF'."
        pause "c"
    }
    register_event ( "ResetHUD" , "@flag_time_fix" , "bef" )
    //m_iHideHUD = (find_ent_data_info("CBasePlayer", "m_iHideHUD") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS //ALL 3 OS have this in DLL/SO/DYLIB
    //m_iUpdateTime = (find_ent_data_info("CBasePlayer", " m_iUpdateTime") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    new info_detect = find_ent(charsmin,"info_ctfdetect")
    B_op4c_map = info_detect ? true : false
}

@flag_time_fix(id)
if(is_user_connected(id))
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_compatible1, _, id)
    //ewrite_byte(B_op4c_map ? 1 : 0) //show TIME REMAINING resets working OSes to zero time not counting
    ewrite_byte(0)
    emessage_end()
    

    if(B_op4c_map)
    {
        new SzTeam[MAX_PLAYERS]
        get_user_team(id, SzTeam, charsmax(SzTeam));
        
        client_print id, print_chat, SzTeam

        emessage_begin(MSG_ONE_UNRELIABLE, g_compatible2, _, id)
        if(equal(SzTeam,"Opposing Force"))
        {
            bBlackMesa[id] = false
            ewrite_byte(0)
            ewrite_byte(255) //GREEN HUD
            ewrite_byte(0)
            emessage_end()

            if(!task_exists(id))
                set_task_ex(0.33, "show_timer", id, .flags = SetTask_Repeat);
        }
        else if(equal(SzTeam,"Black Mesa"))
        {
            bBlackMesa[id] = true
            ewrite_byte(234)
            ewrite_byte(151) //ORANGE HUD
            ewrite_byte(25)
            emessage_end()

            if(!task_exists(id))
                set_task_ex(0.33, "show_timer", id, .flags = SetTask_Repeat);
        }
        else //spec
        {
            ewrite_byte(29)
            ewrite_byte(211) //OCEANBLUE/TEAL HUD
            ewrite_byte(199)
            emessage_end()
        }

    }
    else
    {
        emessage_begin(MSG_ONE_UNRELIABLE, g_compatible2, _, id)
        ewrite_byte(0)
        ewrite_byte(255) //GREEN HUD REGULAR MAP
        ewrite_byte(0)
        emessage_end()
    }
    if(!task_exists(id) && bProjector[id])
    {
        bBlackMesa[id] = false
        set_task_ex(1.0, "show_timer", id, .flags = SetTask_Repeat);
    }
}


public client_disconnected(id)
{
    bProjector[id] = false
}

public show_timer(id)
{
    new timeleft = get_timeleft();
    static effects=0,Float:fxtime=1.0,Float:fadeintime = 0.1, Float:holdtime=1.0, Float:fadouttime = 0.2, channel = 13,
    Float:Xpos =0.08, Float:Ypos = 0.96 
    bBlackMesa[id] ? set_hudmessage(234,151,25,Xpos, Ypos,effects, fxtime, holdtime, fadeintime, fadouttime, channel) :
    set_hudmessage(0,255,0,Xpos,Ypos,effects, fxtime, holdtime, fadeintime, fadouttime, channel)
    ///set_hudmessage(255,255,255,0.11,0.90,0, 1.0, 1.0, 0.1, 0.2, 13) //above

    show_hudmessage(id,"         %d:%02d",timeleft / 60, timeleft % 60)
    return PLUGIN_CONTINUE
}
