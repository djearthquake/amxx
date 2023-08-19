#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define MAX_PLAYERS 32
#define disconnected disconnect

new bool:scope_owner[ MAX_PLAYERS + 1 ], bool:scoped[ MAX_PLAYERS + 1 ], bool:bZooming_in[ MAX_PLAYERS + 1 ], bool:bZooming_out[ MAX_PLAYERS + 1 ];
new Float: gfFov[MAX_PLAYERS+1];
new const SzBuyMsg[] = "Type buy_scope in console to give glock a scope.^nAttack2 replacement.^n Impulse 105 Zooms."
new g_scope_zoomsound;
new g_fscope_autotime;
new g_Client
new buffer[MAX_RESOURCE_PATH_LENGTH];

public plugin_init()
{
    register_plugin( "Glock Scope!", "1.1", "SPiNX" );
    ///RegisterHam(Ham_Weapon_SendWeaponAnim, "weapon_9mmhandgun", "BlockAnimation")
    register_forward(FM_PlayerPreThink, "client_prethink");
    register_clcmd ( "buy_scope", "buy_scope", 0, " - Glock scope. (right-click replace)" );
    RegisterHam(Ham_Killed, "player", "no_scope");
    RegisterHam(Ham_TakeDamage, "player", "@PostTakeDamage", 1);
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_glock", "_SecondaryAttack_Pre" , 0 );
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_glock", "_SecondaryAttack_Post", 1 );
    g_scope_zoomsound = register_cvar("scope_glock_sound", "barnacle/bcl_chew1.wav" )
    g_fscope_autotime = register_cvar("scope_glock_time", "0.8" )
    register_impulse(105, "impulse_handler");

}

public buy_scope(Client)
{
    if ( !scope_owner[Client] )
    {
        scope_owner[Client] = true;
        get_pcvar_string(g_scope_zoomsound, buffer, charsmax(buffer))
        client_cmd(Client, "spk %s", buffer)
    }
    return PLUGIN_HANDLED;
}

public client_prethink( Client )
{
    if(is_user_connected(Client) && is_user_alive(Client))
    if(scope_owner[Client])
    {
        if( scoped[ Client ])
        {
            if( get_user_weapon( Client ) == HLW_GLOCK)
            {
                gfFov[Client] = entity_get_float(Client, EV_FL_fov)

                if(gfFov[Client] > 100.0)
                {
                    entity_set_float(Client, EV_FL_fov, gfFov[Client] - 0.1)
                }

                if( pev(Client,pev_button) & IN_JUMP ||  pev(Client,pev_button) & IN_FORWARD )
                {
                    set_task(0.2,"@running", Client )
                }

                if (pev(Client,pev_button) & IN_RELOAD)
                {
                    set_task(0.3,"@regular", Client )
                }

            }
            else
            {
                @regular(Client)
            }
        }
    }
}

public _SecondaryAttack_Pre(const gun)
{
    g_Client = pev(gun, pev_owner)
    if(is_user_connected(g_Client) && scope_owner[g_Client])
        return HAM_SUPERCEDE
    return HAM_IGNORED
}

public _SecondaryAttack_Post(const gun)
{
    static Client; Client = g_Client
    if(is_user_connected(Client) && scope_owner[Client])
    {
        @zoom(Client)
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}

public impulse_handler(Client)
{
    if(is_user_connected(Client))
    {
        bZooming_in[Client] = bZooming_in[Client] ? false : true
        bZooming_out[Client] = bZooming_out[Client] ? false : true
        client_cmd(Client, bZooming_in[Client] ? "spk common/menu3.wav" : "spk common/menu2.wav")
    }
}

@zoom( Client )
{
    if(is_user_connected(Client))
    {
        scoped[ Client ] = true

        if(task_exists( Client ))
        {
            remove_task( Client );
            return HAM_SUPERCEDE
        }


        gfFov[Client] = entity_get_float(Client, EV_FL_fov)

        if(bZooming_in[Client] && gfFov[Client] < 100.0 && gfFov[Client] > 15.0)
        {
            entity_set_float(Client, EV_FL_fov, gfFov[Client] - 0.4)
            if(gfFov[Client] < 20.0)
                impulse_handler(Client)
            return HAM_SUPERCEDE
        }
        else
        {
            @zoom_out( Client )
            bZooming_out[Client] = true
            return HAM_SUPERCEDE
        }
    }
    return HAM_IGNORED
}

@zoom_out( Client )
{
    if(is_user_connected(Client))
    {
        scoped[ Client ] = true

        gfFov[Client] = entity_get_float(Client, EV_FL_fov)
        if(gfFov[Client] > 110.0 && bZooming_out[Client] )
        {
            @regular( Client )
            return HAM_SUPERCEDE
        }
        else
        {
            entity_set_float(Client, EV_FL_fov, gfFov[Client] + 0.4)
            return HAM_SUPERCEDE
        }
    }
    return HAM_IGNORED
}

@running( Client )
{
    entity_set_float(Client, EV_FL_fov, 75.0)

    scoped[Client] = true;
    bZooming_in[Client] = false
    bZooming_out[Client] = true

    set_task( get_pcvar_float(g_fscope_autotime), "@regular", Client )
    return HAM_SUPERCEDE
}

@regular( Client )
{
    if(task_exists( Client ))
        remove_task( Client );

    entity_set_float(Client, EV_FL_fov, 100.0)

    scoped[Client] = false;
    bZooming_in[Client] = false
    bZooming_out[Client] = false
    impulse_handler(Client)
    return HAM_SUPERCEDE
}

@PostTakeDamage( Client )
if( scoped[Client] )
    @running( Client )

public BlockAnimation(this, iAnim, skiplocal, body)
     return HAM_SUPERCEDE

public client_putinserver( Client )
{
    scope_owner[Client] = false
    set_task 5.0, "@advert", Client
}

@advert(Client)
{
    if(is_user_connected(Client))
        client_print Client, print_chat, SzBuyMsg
}

public no_scope( Client )
    scope_owner[Client] = false && @regular( Client );
