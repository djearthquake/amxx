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

static const CvarTeamDesc[]="Allow admins, bots, amd spec on scoreboard."
//Make up whatever tag you want for the teams.
static const szBot[]   = "bot"
static const szClient[]= "player"
static const szSpec[]  = "!spec"
static const szAdm[]   = "Admin"

static
g_MsgTeamInfo, g_MsgGameMode, bool:info_detect, bool:B_op4c_map;
new
g_TeamName[MAX_NAME_LENGTH][MAX_PLAYERS +1], g_cvar, bool:bIsBot[MAX_PLAYERS+1];

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

    bind_pcvar_num(get_cvar_pointer("team_type") ? get_cvar_pointer("team_type") :
    create_cvar("team_type", "0", FCVAR_NONE, CvarTeamDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0), g_cvar )
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
        set_task(0.5, "@get_team", id)
    }
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        @get_team(id);
    }
}

@get_team(id)
{
    if(is_user_connected(id))
    {
        static flags; flags = pev(id, pev_flags);
        static bool:bAdm; bAdm = is_user_admin(id) ? true : false

        if(is_user_hltv(id))
        {
            g_TeamName[id] = "HLTV";
        }
        if(flags & FL_SPECTATOR && !bAdm)
        {
            g_TeamName[id] = szSpec;
        }
        else if(bAdm)
        {
            g_TeamName[id] = g_cvar == 1 ?  szAdm : (flags & FL_SPECTATOR ? szSpec : szAdm);
        }
        else if(bIsBot[id])
        {
            g_TeamName[id] = szBot;
        }
        else
        {
            g_TeamName[id] = szClient;
        }
    }
    @message();
}

@message()
{
    if(get_playersnum())
    {
        emessage_begin(MSG_BROADCAST, g_MsgGameMode);
        ewrite_byte(g_cvar ? 1 : 0);
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
