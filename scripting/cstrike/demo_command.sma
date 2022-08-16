#include amxmodx
#include amxmisc

#define MAX_NAME_LENGTH                      32
#define MAX_PLAYERS                          32
#define MAX_RESOURCE_PATH_LENGTH             64

public plugin_init( )
{
    register_plugin ( "Demo Command", "0.1", "spinx" )
    register_clcmd ( "amx_demo", "Command_demo", ADMIN_SLAY, "<name or #userid> on|off" )
}

public Command_demo ( id, level, cid )
{
    if ( !cmd_access ( id, level, cid, 3 ) )
        return PLUGIN_HANDLED

    new SzDemo[MAX_RESOURCE_PATH_LENGTH]
    new SzHostname[MAX_NAME_LENGTH]
    new SzNick [ MAX_NAME_LENGTH ]
    new SzRec[4]

    read_argv ( 1, SzNick, sizeof ( SzNick ) - 1 )
    read_argv ( 2, SzRec, sizeof ( SzRec ) - 1 )

    new iPlayer = cmd_target ( id, SzNick, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF )

    if ( !iPlayer )
        return PLUGIN_HANDLED

    get_cvar_string("hostname", SzHostname, charsmax(SzHostname));
    
    containi(SzRec, "on") != -1 ? formatex(SzDemo, charsmax(SzDemo), "record ^"%n|%s^"",iPlayer, SzHostname) :
    formatex(SzDemo, charsmax(SzDemo), "stop")
    set_task(1.0, "SendCmd", iPlayer, SzDemo, charsmax(SzDemo))

    return PLUGIN_HANDLED;

}

public client_disconnected(id)
{
    if(is_user_connected(id) || is_user_connecting(id))
    {
        client_cmd id, "stop"
    }

}

public SendCmd(SzCommand[], iPlayer)
{
    if(is_user_connected(iPlayer))
    {
        server_print "Trying %s on %n", SzCommand, iPlayer
        client_print iPlayer, print_chat, "Host issued command %s", SzCommand
        message_begin(MSG_ONE_UNRELIABLE, SVC_DIRECTOR, _, iPlayer);
        write_byte(strlen(SzCommand)+2);
        write_byte(10);
        write_string(SzCommand);
        message_end();
    }

}
