/*
*
*   SSSSSSSSSSSSSSS PPPPPPPPPPPPPPPPP     iiii  NNNNNNNN        NNNNNNNNXXXXXXX       XXXXXXX
* SS:::::::::::::::SP::::::::::::::::P   i::::i N:::::::N       N::::::NX:::::X       X:::::X
*S:::::SSSSSS::::::SP::::::PPPPPP:::::P   iiii  N::::::::N      N::::::NX:::::X       X:::::X
*S:::::S     SSSSSSSPP:::::P     P:::::P        N:::::::::N     N::::::NX::::::X     X::::::X
*S:::::S              P::::P     P:::::Piiiiiii N::::::::::N    N::::::NXXX:::::X   X:::::XXX
*S:::::S              P::::P     P:::::Pi:::::i N:::::::::::N   N::::::N   X:::::X X:::::X
* S::::SSSS           P::::PPPPPP:::::P  i::::i N:::::::N::::N  N::::::N    X:::::X:::::X
*  SS::::::SSSSS      P:::::::::::::PP   i::::i N::::::N N::::N N::::::N     X:::::::::X
*    SSS::::::::SS    P::::PPPPPPPPP     i::::i N::::::N  N::::N:::::::N     X:::::::::X
*       SSSSSS::::S   P::::P             i::::i N::::::N   N:::::::::::N    X:::::X:::::X
*            S:::::S  P::::P             i::::i N::::::N    N::::::::::N   X:::::X X:::::X
*            S:::::S  P::::P             i::::i N::::::N     N:::::::::NXXX:::::X   X:::::XXX
*SSSSSSS     S:::::SPP::::::PP          i::::::iN::::::N      N::::::::NX::::::X     X::::::X
*S::::::SSSSSS:::::SP::::::::P          i::::::iN::::::N       N:::::::NX:::::X       X:::::X
*S:::::::::::::::SS P::::::::P          i::::::iN::::::N        N::::::NX:::::X       X:::::X
* SSSSSSSSSSSSSSS   PPPPPPPPPP          iiiiiiiiNNNNNNNN         NNNNNNNXXXXXXX       XXXXXXX
*
*──────────────────────────────▄▄
*──────────────────────▄▄▄▄▄▄▄▄▌▐▄
*─────────────────────█▄▄▄▄▄▄▄▄▌▐▄█
*────────────────────█▄▄▄▄▄▄▄█▌▌▐█▄█
*──────▄█▀▄─────────█▄▄▄▄▄▄▄▌░▀░░▀░▌
*────▄██▀▀▀▀▄──────▐▄▄▄▄▄▄▄▐ ▌█▐░▌█▐▌
*──▄███▀▀▀▀▀▀▀▄────▐▄▄▄▄▄▄▄▌░░░▄▄▌░▐
*▄████▀▀▀▀▀▀▀▀▀▀▄──▐▄▄▄▄▄▄▄▌░░▄▄▄▄░▐
*████▀▀▀▀▀▀▀▀▀▀▀▀▀▄▐▄▄▄▄▄▄▌░▄░░▀▀░░▌
*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▌░▐▀▄▄▄▄▀
*▒▒▒▒▄▄▀▀▀▀▀▀▀▀▄▄▄▄▀▀█▄▄▄▄▄▌░░░░░▌
*▒▄▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌
*▒▌░░░░░▀▄░░░░░░░░░░░░░░░▀▄▄▄▄▄▄░▀▄▄▄▄▄
*▒▌░░░░░░░▀▄░░░░░░░░░░░░░░░░░░░░▀▀▀▀▄░▀▀▀▄
*▒▌░░░░░░░▄▀▀▄░░░░░░░░░░░░░░░▀▄░▄░▄░▄▌░▄░▄▌
*▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
*
*
*
*
*
* __..__  .  .\  /
*(__ [__)*|\ | ><
*.__)|   || \|/  \
*
*    Repawn from bots.
*    Copyleft (C) Nov 2020 .sρiηX҉.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*    Credits: AMXX DEV TEAM for everything including adminhelp.sma.
*    AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
*
*    V1.0 to 1.1 -better unsticking code when bots are crouched against wall.
*                -take the place of AFK humans for round.
*
*/

#include amxmodx
#include cstrike
#include engine
#include fakemeta
#include fun
#include hamsandwich

#define FRICTION_NOT    1.0
#define FRICTION_MUD    1.8
#define FRICTION_ICE    0.3
#define MAX_NAME_LENGTH 32

new Float:Plane[ 3 ], Origin[3], wpnname[ MAX_NAME_LENGTH ];
new bots_name[ MAX_NAME_LENGTH + 1 ], spec_name[ MAX_NAME_LENGTH + 1 ];
new alive_bot, arm, ammo, magazine, part, wpnid, g_stuck;
new bool:cool_down_active;
new bool:ok_to_takeover[MAX_NAME_LENGTH]
new Float:vec[3];

public plugin_init()
{
    register_plugin("Repawn from bots", "1.1", "SPiNX");
    g_stuck = register_cvar("respawn_unstick", "0.4");
    register_logevent("round_start", 2, "1=Round_Start")
    register_logevent("round_end", 2, "1=Round_End")
    register_touch( "player", "worldspawn", "Touch" );
    register_touch( "player", "func_wall", "Touch" );
    register_touch( "player", "func_breakable", "Touch" );
}

public Touch( alive_bot, Ent )
{
     if( ~get_entity_flags( alive_bot ) & FL_ONGROUND )
          //Player touching wall
          ok_to_takeover[alive_bot] = false
     //else
          //Player on ground, might be touching wall
}
public round_start()
{
    cool_down_active = false
}

public round_end()
{
    cool_down_active = true
}


public client_PreThink(dead_spec)
{
    if (!cool_down_active)
    if(!is_user_bot(dead_spec) || !is_user_alive(dead_spec)) {

    if(pev(dead_spec, pev_button) & IN_RELOAD && pev(dead_spec, pev_oldbuttons) & IN_RELOAD )
        control_bot(dead_spec);

    get_user_aiming(dead_spec, alive_bot, part, 9999);
    //get_user_velocity(alive_bot, vec);

    if(is_user_bot(alive_bot) && get_user_team(dead_spec) == get_user_team(alive_bot) && !is_user_alive(dead_spec) && ok_to_takeover[alive_bot] == true /*&& vec[0] != 0.0 && vec[1] != 0.0*/)
        get_user_name(alive_bot,bots_name,charsmax(bots_name)) &&
        client_print(dead_spec, print_center,"Press 'reload' to control %s", bots_name);

    }

    return PLUGIN_CONTINUE;
}

public control_bot(dead_spec)
{

    if(!is_user_alive(dead_spec))
    {

        get_user_aiming(dead_spec, alive_bot, part, 9999);
        get_user_velocity(alive_bot, vec);

        #define IS_THERE (~(1<<IN_SCORE))

        if(get_user_team(dead_spec) == get_user_team(alive_bot))
        if(is_user_bot(alive_bot) && (vec[0] != 0.0 || vec[1] != 0.0) || !is_user_bot(alive_bot) && vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0 && (pev(alive_bot, pev_button) & IS_THERE == 0)  && (pev(alive_bot, pev_movetype) != MOVETYPE_FLY) )

        {
            ExecuteHamB(Ham_CS_RoundRespawn, dead_spec);
            attach_view(dead_spec, alive_bot);

            entity_get_vector(alive_bot,EV_VEC_angles, Plane);
            get_user_origin(alive_bot, Origin);

            arm = get_user_armor(alive_bot);

            weapon_details(alive_bot)

            set_user_armor(dead_spec, arm);

            entity_set_vector(dead_spec,EV_VEC_angles, Plane);

            get_user_name(alive_bot,bots_name,charsmax(bots_name))
            &&
            get_weaponname(wpnid,wpnname,charsmax (wpnname));
            get_user_name(dead_spec,spec_name,charsmax(spec_name));

            server_print("%s took control of %s's %s. %i in mag, %i bullets total and %i armor.", spec_name, bots_name, wpnname, magazine, ammo, arm);
            client_print(dead_spec, print_console, "%s took control of %s's %s. %i in mag, %i bullets total and %i armor.", spec_name, bots_name, wpnname, magazine, ammo, arm);

            give_item(dead_spec, wpnname)

            cs_set_user_bpammo(dead_spec, wpnid, ammo)

            entity_set_int(dead_spec, EV_INT_solid, SOLID_NOT)

            new Float:unstuck_time_factor = floatclamp(get_pcvar_float(g_stuck),0.3,1.0)

            if(get_user_velocity(alive_bot, vec) == 0.0 || pev(alive_bot, pev_button) & IN_DUCK && pev(alive_bot, pev_oldbuttons) & IN_DUCK )

            {
                Origin[2] = Origin[2] + 15;
                entity_set_int(dead_spec, EV_INT_solid, SOLID_NOT);

                //entity_set_float(dead_spec, EV_FL_friction, FRICTION_ICE);
                client_print(dead_spec,print_chat,"Move now or risk being stuck to wall!");

                set_task(unstuck_time_factor*4,"Normalizer",dead_spec);
                set_user_origin(dead_spec, Origin);
            }


            else

            {
                Origin[2] = Origin[2] + 25;
                entity_set_int(dead_spec, EV_INT_solid, SOLID_NOT);
                set_task(unstuck_time_factor,"Normalizer",dead_spec) && client_print(dead_spec,print_console,"Moving X:%f Y:%f Z:%f", vec[0], vec[1], vec[2]);
                set_user_origin(dead_spec, Origin);
            }

            client_print(dead_spec, print_center,"You are now taking the place of %s", bots_name);

            client_print(0, print_chat,"%s is taking the place of %s", spec_name, bots_name);
            client_cmd(dead_spec, "spk turret/tu_spindown.wav")

            user_kill(alive_bot, 1 );
        }


    }

    return PLUGIN_HANDLED;
}

public client_PostThink(alive_bot)

    if(is_user_alive(alive_bot))
 
        ok_to_takeover[alive_bot] = true


stock weapon_details(alive_bot)

{
    wpnid = get_user_weapon(alive_bot, magazine, ammo);

    return wpnid, magazine, ammo;

}

public Normalizer(dead_spec)

if (is_user_alive(dead_spec))
    {
        entity_set_int(dead_spec, EV_INT_solid, SOLID_SLIDEBOX);
        set_pev(dead_spec, pev_movetype, MOVETYPE_WALK);
        entity_set_float(dead_spec, EV_FL_friction, FRICTION_NOT);
        attach_view(dead_spec, dead_spec);
        client_cmd(dead_spec, "spk turret/tu_spinup.wav");
    }
