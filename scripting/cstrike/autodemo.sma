#include amxmodx
new SzTst[MAX_RESOURCE_PATH_LENGTH]
new SzReason[]="Demo autorecord failure!"

public client_connectex(id, const name[], const ip[], reason[128])
{
    copy(reason, charsmax(reason), SzReason)
    if(!is_user_bot(id))
    {
        new hostname[MAX_NAME_LENGTH];
        get_cvar_string("hostname", hostname, charsmax(hostname));

        formatex(SzTst, charsmax(SzTst), "record ^"%s|%s|%s^"", name, ip, hostname)
        set_task(10.0, "SendCmd",id, SzTst, charsmax(SzTst))
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED

}

public client_disconnected(id)
{
    if(is_user_connected(id) || is_user_connecting(id))
    {
        client_cmd id, "stop"
    }

}

public SendCmd(SzCommand[], id)
{
    if(is_user_connected(id))
    {
        server_print "Trying %s on %n", SzCommand, id
        client_print id, print_chat, "Host issued command %s", SzCommand
        message_begin(MSG_ONE_UNRELIABLE, SVC_DIRECTOR, _, id);
        write_byte(strlen(SzCommand)+2);
        write_byte(10);
        write_string(SzCommand);
        message_end();
    }

}
