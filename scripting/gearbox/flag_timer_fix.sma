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

#define SetBits(%1,%2)       %1 |=   1<<(%2 & 31)
#define ClearBits(%1,%2)     %1 &= ~(1<<(%2 & 31))
#define GetBits(%1,%2)       %1 &    1<<(%2 & 31)

#define charsmin -1

static g_compatible1, g_compatible2,bool:B_op4c_map
//new bool:bProjector[MAX_PLAYERS+1]
new bBlackMesa[MAX_PLAYERS+1]
//new bool:bPatchRan[MAX_PLAYERS+1]
new g_AI, g_Projector, g_Ran_Patch

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
    register_event( "ResetHUD" , "@flag_time_fix" , "bef" )
    register_event( "TeamNames", "@flag_time_fix" , "b" )

    static info_detect
    info_detect = find_ent(charsmin,"info_ctfdetect")
    B_op4c_map = info_detect ? true : false
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? (SetBits(g_AI, id)) : (ClearBits(g_AI, id))
    }
    if(~GetBits(g_AI, id))
    {
        ClearBits(g_Ran_Patch, id)

        B_op4c_map ? (SetBits(g_Projector, id)) : (ClearBits(g_Projector, id))
    }
}

@flag_time_fix(id)
if(is_user_connected(id) && ~GetBits(g_AI, id))
{
    static iTimeleft; iTimeleft = get_timeleft()

    if(!B_op4c_map && ~GetBits(g_Ran_Patch, id))
    {
        emessage_begin(MSG_ONE_UNRELIABLE, g_compatible1, _, id)
        ewrite_byte(B_op4c_map ? 1 : 0)

        if(B_op4c_map)
        {
            ewrite_short(iTimeleft)
        }
        emessage_end()

        SetBits(g_Ran_Patch, id)
        client_print id, print_chat, "Fixed your broken Time Remaining counter"
        server_print "Fixed broken time remaining on %N", id
    }

    emessage_begin(MSG_ONE_UNRELIABLE, g_compatible1, _, id)
    ewrite_byte(B_op4c_map ? 1 : 0)

    if(B_op4c_map)
    {
        ewrite_short(iTimeleft)
    }
    emessage_end()

    if(B_op4c_map)
    {
        static SzTeam[MAX_PLAYERS]
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
            bBlackMesa[id] = 3
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
    if(!task_exists(id) && GetBits(g_Projector, id))
    {
        set_task_ex(1.0, "show_timer", id, .flags = SetTask_Repeat);
    }
}

public show_timer(id)
{
    static iTimeleft
    iTimeleft = get_timeleft();
    static effects=0,Float:fxtime=1.0,Float:fadeintime = 0.1, Float:holdtime=1.0, Float:fadouttime = 0.2, channel = 13, Float:Xpos =0.08, Float:Ypos = 0.947
    if(is_user_connected(id))
    if(~GetBits(g_AI, id))
    {
        static iRGB[3]
        iRGB = bBlackMesa[id] == 3 ? {33,209,175} : bBlackMesa[id] ? {234,151,25} : {0,255,0}

        set_hudmessage(iRGB[0], iRGB[1], iRGB[2], Xpos, Ypos,effects, fxtime, holdtime, fadeintime, fadouttime, channel)

        show_hudmessage(id,"         %d:%02d",iTimeleft / 60, iTimeleft % 60)
    }
    return PLUGIN_CONTINUE
}
