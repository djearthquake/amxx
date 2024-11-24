/*Make speak commands public.*/
/*CREDITS: WATCH_D0GS UNITED for bitwise functions.*/

#include amxmodx

const MAX_CMD_LENGTH = 128;

static g_bConnected, g_bBot, g_iHighestClientIndex, g_iPrevHighestClientIndex,g_Debug;

public plugin_init()
{
    register_plugin("SPEAK ALL", "0.0.5", "SPiNX");
    register_concmd("amx_speakall","@speakall",ADMIN_CHAT,": Vox speak.");
    g_Debug = register_cvar("speakall_debug", "0") 
}

public client_putinserver( id )
{
    g_iPrevHighestClientIndex = g_iHighestClientIndex;
    g_iHighestClientIndex = ( id > g_iPrevHighestClientIndex ) ? id : g_iPrevHighestClientIndex;

    g_bConnected |= ( 1 << id );
    g_bBot |= ( is_user_bot( id ) << id );
}

@speakall(id)
{
    static
    szArgCmd1[ MAX_CMD_LENGTH ], szName1[32], szName2[32];
    if ( g_bConnected & ( 1 << id ) )
    {
        get_user_name(id, szName1, charsmax(szName1))
        read_argv( 1, szArgCmd1, charsmax( szArgCmd1 ) );

        for(new i=1; i <= g_iHighestClientIndex; ++i )
        {
           if((g_bConnected & ( 1 << i )) &~(g_bBot & ( 1 << i )))
            {
                if(get_pcvar_num(g_Debug))
                {
                    get_user_name(i, szName2, charsmax(szName2))
                    server_print( "%s spaketh %s to %s", szName1, szArgCmd1, szName2 );
                }
                console_cmd( i, "speak ^"%s^"", szArgCmd1 );
            }
        }
        server_print( "%s spaketh %s.", szName1, szArgCmd1 );
    }
    return PLUGIN_HANDLED;
}

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

public client_disconnected( id )
{
    g_bBot       &= ~( 1 << id );
    g_bConnected &= ~( 1 << id );

    g_iHighestClientIndex = ( id == g_iHighestClientIndex ) ? g_iPrevHighestClientIndex : g_iHighestClientIndex;
}
