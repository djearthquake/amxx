/*
 * Scoped Colt by SPiNX 2020.
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

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define MAX_PLAYERS 32
#define MAX_RESOURCE_PATH_LENGTH   64
#define disconnected disconnect

new bool:scope_owner[ MAX_PLAYERS + 1 ], bool:scoped[ MAX_PLAYERS + 1 ];
new g_item_cost, g_szMsgSetFov, g_scope_zoomsound;
new g_fscope_autotime;
new buffer[MAX_RESOURCE_PATH_LENGTH];


const bad_time_to_scope = ( 1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_FLASHBANG );

public plugin_init()
{
    register_plugin( "Buy a Colt Scope!", "1.0", "SPiNX" );
    register_forward( FM_CmdStart , "fw_CmdStart", true );
    register_forward(FM_PlayerPreThink, "client_prethink", true);
    register_clcmd ( "buy_scope", "buy_scope", 0, " - universal scope." );
    RegisterHam(Ham_Killed, "player", "no_scope");
    RegisterHam(Ham_TakeDamage, "player", "@PostTakeDamage", 1);
    g_szMsgSetFov = get_user_msgid ( "SetFOV" );
    g_item_cost = register_cvar("scope_colt_cost", "2500" )
    g_scope_zoomsound = register_cvar("scope_colt_sound", "weapons/zoom" )
    g_fscope_autotime = register_cvar("scope_colt_time", "0.8" )
}

public buy_scope(Client)
{
    if(is_user_alive(Client))
    {
        new name[MAX_PLAYERS];

        get_user_name(Client,name,charsmax(name));

        new tmp_money = cs_get_user_money(Client);
        if(is_user_connected(Client))
        {
            if ( !scope_owner[Client] )
            {

                if(tmp_money < get_pcvar_num(g_item_cost))
                {
                    client_print(Client, print_center, "You can't afford a scope %s!", name);
                    client_print(0, print_chat, "Hey guys %s keeps trying to buy scope they can't afford!", name);
                    return PLUGIN_HANDLED;
                }
                else
                {
                    cs_set_user_money(Client, tmp_money - get_pcvar_num(g_item_cost));
                    scope_owner[Client] = true;
                    client_print(Client, print_center, "You bought a scope!");
                }

            }
            else
            {
                client_print(Client, print_center, "You ALREADY OWN a scope...");
                client_print(0, print_chat, "Hey guys %s keeps trying to buy a scope and already owns one!", name);
            }
        }
    }
    return PLUGIN_HANDLED;
}


public client_prethink( Client )
{
    if(is_user_connected(Client) && !is_user_bot( Client ) )

    if( scoped[ Client ])
    {
        if( get_user_weapon( Client ) == CSW_M4A1 || get_user_weapon( Client ) == CSW_AK47 || get_user_weapon( Client ) == CSW_USP || get_user_weapon( Client ) == CSW_FIVESEVEN )

        if( pev(Client,pev_button) & IN_JUMP ||  pev(Client,pev_button) & IN_FORWARD )
            set_task(0.3,"@running", Client )

        if (pev(Client,pev_button) & IN_RELOAD)
            set_task(0.3,"@regular", Client )
    }
}

public fw_CmdStart( Client , Handle )
{
    static Buttons; Buttons = get_uc( Handle , UC_Buttons );
    if(!cs_get_user_shield(Client))
    if( scope_owner[Client] && ( Buttons & IN_ATTACK2 ) )

    if( get_user_weapon( Client ) == CSW_M4A1 || get_user_weapon( Client ) == CSW_AK47 || get_user_weapon( Client ) == CSW_USP || get_user_weapon( Client ) == CSW_FIVESEVEN )

    {


        Buttons &= ~IN_ATTACK2;
        set_uc( Handle , UC_Buttons , Buttons );

        if(scoped[Client])
            set_task(0.3,"@regular", Client )

        else
            set_task(0.3,"@zoom", Client )


        return FMRES_SUPERCEDE;


    }


    if( get_user_weapon( Client ) == CSW_KNIFE || get_user_weapon( Client ) == CSW_SMOKEGRENADE || get_user_weapon( Client ) == CSW_FLASHBANG || get_user_weapon( Client ) == CSW_HEGRENADE)

        set_fov ( Client, 90);


    return FMRES_HANDLED;

}

@zoom( Client )
{
    if(task_exists( Client ))
        remove_task( Client );
    set_fov ( Client, 15);
    scoped[Client] = true;
    get_pcvar_string(g_scope_zoomsound, buffer, charsmax(buffer))
    client_cmd(Client, "spk %s", buffer)
}

@running( Client )
{
    set_fov ( Client, 55);
    scoped[Client] = true;

    set_task( get_pcvar_float(g_fscope_autotime), "@regular", Client )
}

@regular( Client )
{
    if(task_exists( Client ))
        remove_task( Client );
    set_fov ( Client, 90);
    scoped[Client] = false;
    get_pcvar_string(g_scope_zoomsound, buffer, charsmax(buffer))
    client_cmd(Client, "spk %s", buffer)
}

@PostTakeDamage( Client )
if( scoped[Client] )
    @running( Client )


public client_putinserver( Client )

    scope_owner[Client] = false;


public no_scope( Client )

    scope_owner[Client] = false && @regular( Client );


public set_fov ( iClient, iValue )
{
    if(is_user_connected(iClient))
    {
        emessage_begin ( MSG_ONE_UNRELIABLE, g_szMsgSetFov, _, iClient );
        ewrite_byte ( iValue );
        emessage_end ( );
    }

}
