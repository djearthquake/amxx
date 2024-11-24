/*Make speak commands public.*/
/*CREDITS: WATCH_D0GS UNITED for bitwise functions.*/

#include amxmodx

const MAX_CMD_LENGTH = 128;

static g_bConnected, g_bBot, g_iHighestClientIndex, g_iPrevHighestClientIndex;

public plugin_init()
{
    register_plugin("SPEAK ALL", "0.0.4", "SPiNX");
    register_concmd("amx_speakall","@speakall",ADMIN_CHAT,": Vox speak.");
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
    static szArgCmd1[ MAX_CMD_LENGTH ] ;
    if ( g_bConnected & ( 1 << id ) )
    {
        read_argv( 1, szArgCmd1, charsmax( szArgCmd1 ) );

        for(new i=1; i <= g_iHighestClientIndex; ++i )
        {
            if((g_bConnected & ( 1 << i ))&(g_bBot | ( 1 << i )))
            {
                console_cmd( i, "speak ^"%s^"", szArgCmd1 );
            }
            #if AMXX_VERSION_NUM != 182
            server_print( "%N spoke %s.", id, szArgCmd1 );
            #else
            server_print( "%d spaketh %s.", get_user_userid(id), szArgCmd1 );
            #endif
        }
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
