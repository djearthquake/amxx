/*
 * glow_flashlight.sma Toggle Flashlight and you glow depending on team.
 *
 * Copyright 2020 SPiNX
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
 * 2020-12-02  1.0 to 1.1 SPiNX
 * Updated so opposing team cannot see.
 *
*/

#include amxmodx
#tryinclude colorchat
#include engine
#include fakemeta

#define MAX_IP_LENGTH     16
#define MAX_NAME_LENGTH   32
#define MAX_PLAYERS       32
#define MAX_AUTHID_LENGTH 64

new bool:cool_down_active
new glowteam[MAX_IP_LENGTH], g_radius, g_time, overhead_icon_ct,overhead_icon_t;
new players[ MAX_PLAYERS ], team_name[ MAX_NAME_LENGTH ], signalers_name[ MAX_NAME_LENGTH ], playercount;
new Origin[3];
new g_debug

public plugin_init()
{
    register_plugin("Team Glow flashlight", "1.2", "SPiNX");
    register_impulse(100, "client_impulse_flashlight");
    g_radius = register_cvar("glow_radius", "20")
    g_time = register_cvar("glow_time", "10")
    g_debug = register_cvar("glow_debug", "0")
    register_logevent("round_start", 2, "1=Round_Start");
    register_logevent("round_end", 2, "1=Round_End");
}

public client_impulse_flashlight(iPlayers_index)

    glowinsteadofflashlight(iPlayers_index);


public round_start()

    cool_down_active = false


public round_end()

    cool_down_active = true


public plugin_precache()
{
    new const model_ct[]="models/in_teleport.mdl"
    new const model_t[]="models/out_teleport.mdl"

    overhead_icon_ct = precache_model(model_ct);
    precache_generic(model_ct)
    
    overhead_icon_t  = precache_model(model_t);
    precache_generic(model_t)
}

public glowinsteadofflashlight(iPlayers_index)
{
    get_user_team(iPlayers_index, glowteam, charsmax(glowteam));

    if(is_user_alive(iPlayers_index) && !cool_down_active)
    {
        new print = get_pcvar_num(g_debug)
        get_user_origin(iPlayers_index, Origin);
        get_players(players,playercount,"ae", glowteam)

        for (new m=0; m < playercount; ++m)
        {

            if(print)
            {
                server_print "Team is %s", glowteam
                client_print iPlayers_index, print_console, "Team is %s", glowteam
            }

            get_user_name(players[m], team_name, charsmax(team_name) );

            if(!is_user_bot(players[m]))
                get_user_name(iPlayers_index, signalers_name, charsmax(signalers_name) );

            if(print)
            {
                client_print(iPlayers_index, print_chat, "Trying to send glow to %s",team_name);
                client_print(players[m], print_chat, "%s is signaling",signalers_name)
            }
            else
            {
               
                #if AMXX_VERSION_NUM == 182
                #if defined ColorChat
                    ColorChat(players[m], GREEN, "^3Asking ^1for pass ^4%s",signalers_name) :
                #endif
                #else
                    client_print_color iPlayers_index, print_team_grey, "^4Asking ^3for pass ^1%n",iPlayers_index ;
                #endif
            }
            emessage_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, players[m] );
            ewrite_byte(TE_PLAYERATTACHMENT)
            ewrite_byte(iPlayers_index)
            ewrite_coord(MAX_AUTHID_LENGTH) //(attachment origin.z = player origin.z + vertical offset)
            if(equal(glowteam, "CT"))
                ewrite_short(overhead_icon_ct)
            else
                ewrite_short(overhead_icon_t)
            ewrite_short(MAX_IP_LENGTH) //life * 10
            emessage_end();

            emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},players[m]);
            ewrite_byte(TE_DLIGHT);

            ewrite_coord(Origin[0]);
            ewrite_coord(Origin[1]);
            ewrite_coord(Origin[2]);

            ewrite_byte(get_pcvar_num(g_radius)); ///(radius in 10's)

            //CS team RGB messaging
            if(equal(glowteam, "CT"))
            {
                if (entity_get_float(iPlayers_index, EV_FL_armorvalue) < 101.0)
                {
                    ewrite_byte(0);
                    ewrite_byte(0);
                    ewrite_byte(255);
                }

                else /* VIP */
                {
                    ewrite_byte(0);
                    ewrite_byte(255);
                    ewrite_byte(0);
                }

            }

            else

            {
                ewrite_byte(255);
                ewrite_byte(0);
                ewrite_byte(0);
            }

            ewrite_byte(get_pcvar_num(g_time));  ///life
            ewrite_byte(get_pcvar_num(g_time));  ///(decay rate in 10's)
            emessage_end();

            message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},players[m]);
            ewrite_byte(TE_ELIGHT);

            ewrite_short(iPlayers_index);

            ewrite_coord(Origin[0]);
            ewrite_coord(Origin[1]);
            ewrite_coord(Origin[2]);

            ewrite_coord(get_pcvar_num(g_radius));  ///(radius in 10's)

            //CS team RGB messaging
            if(equal(glowteam, "CT"))
            {
                if (entity_get_float(iPlayers_index, EV_FL_armorvalue) < 101.0)
                {
                    ewrite_byte(0);
                    ewrite_byte(0);
                    ewrite_byte(255);
                }

                else /* VIP */
                {
                    ewrite_byte(0);
                    ewrite_byte(255);
                    ewrite_byte(0);
                }

            }

            else

            {
                ewrite_byte(255);
                ewrite_byte(0);
                ewrite_byte(0);
            }

            ewrite_byte(get_pcvar_num(g_time));   ///life
            ewrite_coord(get_pcvar_num(g_time));  ///(decay rate in 10's)
            emessage_end();
        }


    }


}
