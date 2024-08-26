/*
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

#define charsmin -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

static const CvarTeamDesc[]="Allow admins, bots, and spec on scoreboard."
//Make up whatever tag you want for the teams.
static const szBot[]   = "bot"
static const szClient[]= "player"
static const szSpec[]  = "!spec"
static const szAdm[]   = "Admin"

new bool:b_Toggle[MAX_PLAYERS+1]

static
g_MsgTeamInfo, g_MsgGameMode, bool:info_detect, bool:B_op4c_map;
new
g_AI, g_Adm, g_TeamName[MAX_NAME_LENGTH][MAX_PLAYERS +1], g_cvar;

public plugin_init()
{
    register_plugin("Admin Scoreboard","AUG-2024",".sρiηX҉.");
    //Inspired by C.ix Colored Names & Teams

    info_detect = find_ent(charsmin,"info_ctfdetect") ? true : false
    B_op4c_map = info_detect ? true : false

    if(B_op4c_map)
    {
        pause("a")
    }
    g_MsgGameMode  = get_user_msgid("GameMode");
    g_MsgTeamInfo  = get_user_msgid("TeamInfo");

    register_concmd("scoreboard","@scoreboard", ADMIN_ALL, "- Bot/spec/admin on scoreboard.");

    bind_pcvar_num(get_cvar_pointer("team_type") ? get_cvar_pointer("team_type") :
    create_cvar("team_type", "1", FCVAR_NONE, CvarTeamDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0), g_cvar )
    register_forward(FM_UpdateClientData, "@fw_UpdateClientData")
}

@fw_UpdateClientData(id)
{
    if(is_user_connected(id))
    if((pev(id, pev_button) & IN_SCORE) && (pev(id, pev_oldbuttons) & IN_SCORE) && !b_Toggle[id])
    {
        client_print(id, print_center, "Type scoreboard in console to see^n^nbots, specs, and admins.");
    }
}

@scoreboard(id)
{
    if(is_user_connected(id))
    {
        b_Toggle[id]  = b_Toggle[id]  ?  false : true
        if(b_Toggle[id])
        {
            @get_team(id)
            client_print(id,print_center, "Admin Scoreboard.");
        }
        else
        {
            emessage_begin(MSG_ONE_UNRELIABLE, g_MsgGameMode,_,id);
            ewrite_byte(b_Toggle[id]);
            emessage_end();
            client_print(id,print_center, "Default Scoreboard.");
        }
    }
    return PLUGIN_HANDLED
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? (SetPlayerBit(g_AI, id)) : (ClearPlayerBit(g_AI, id))
        is_user_admin(id) ? (SetPlayerBit(g_Adm, id)) : (ClearPlayerBit(g_Adm, id))
        @get_team(id)
    }
}

@get_team(id)
{
    if(is_user_connected(id))
    {
        static flags; flags = pev(id, pev_flags);

        if(is_user_hltv(id))
        {
            g_TeamName[id] = "HLTV";
        }
        if(flags & FL_SPECTATOR && ~CheckPlayerBit(g_Adm, id))
        {
            g_TeamName[id] = szSpec;
        }
        else if(CheckPlayerBit(g_Adm, id))
        {
            g_TeamName[id] = g_cvar == 1 ?  szAdm : (flags & FL_SPECTATOR ? szSpec : szAdm);
        }
        else if(CheckPlayerBit(g_AI, id))
        {
            g_TeamName[id] = szBot;
        }
        else
        {
            g_TeamName[id] = szClient;
        }
    }
    @message(id);
}

@message(id)
{
    if(g_cvar)
    if(get_playersnum())
    {
        emessage_begin(MSG_ONE_UNRELIABLE, g_MsgGameMode,_,id);
        ewrite_byte(b_Toggle[id]);
        emessage_end();

        for(new id = 1 ;id <= MaxClients;++id)
        if(is_user_connected(id))
        {
            emessage_begin(MSG_BROADCAST, g_MsgTeamInfo);
            ewrite_byte(id);
            ewrite_string(g_TeamName[id]);
            emessage_end();
        }
    }
}
