#include <amxmodx>
#define MAX_CMD_LENGTH             128
#define ADMIN_CHECK ADMIN_KICK

static const CONTACT[] = ""
new bool:Admin_count;
new adminnames[MAX_PLAYERS + 1][MAX_NAME_LENGTH]
new maxplayers

public plugin_init() {
    register_plugin("Admin Checker", "1.52", "SPiNX") //Originally OneEyed Admin Check,  until 1.52.
    maxplayers = get_maxplayers()
    register_clcmd("say", "handle_say")
    register_cvar("amx_contactinfo", CONTACT, FCVAR_SERVER)
}

public handle_say(iClient, saadmin[MAX_RESOURCE_PATH_LENGTH])
{
    read_args(saadmin,charsmax(saadmin))
    if( ( containi(saadmin, "who") != -1 && containi(saadmin, "admin") != -1 ) || contain(saadmin, "/admin") != -1 )
    {
        if(!task_exists(iClient))
        {
            set_task(0.1,"print_adminlist",iClient)
        }
    }
    return PLUGIN_CONTINUE
}

public print_adminlist(iClient, message[MAX_USER_INFO_LENGTH])
{
    new contactinfo[MAX_USER_INFO_LENGTH], contact[MAX_CMD_LENGTH]

    get_cvar_string("amx_contactinfo", contact, charsmax(contact))
    if(!equal(contact[0], ""))
    {
        format(contactinfo, charsmax(contactinfo), "Contact Server Admin -- %s", contact)
        client_print iClient, print_chat, contactinfo
        server_cmd "amx_tsay red %s", message
    }
    @get_admins()
    if(Admin_count)
    {
        new  SzNewMessage[MAX_USER_INFO_LENGTH]
        implode_strings( adminnames, charsmax(adminnames[]), " ", SzNewMessage, charsmax(SzNewMessage) )

        new SzBuffer[MAX_USER_INFO_LENGTH]
        copy(SzBuffer, charsmax(SzBuffer), SzNewMessage)
        trim(SzBuffer)
        format(message, charsmax(message), "ADMINS ONLINE: %s", SzBuffer)

        client_print(iClient, print_chat, message) & server_cmd("amx_tsay green %s", message);
    }
    else
    {
        server_cmd "amx_tsay blue Searching online players for an admin..."
    }

}

@get_admins()
{
    for(new admin = 1 ; admin <= maxplayers ; ++admin)
    {
        if(is_user_connected(admin))
        {
            if(get_user_flags(admin) & ADMIN_CHECK)
            {
                if(!Admin_count)
                {
                    Admin_count = true
                }
                get_user_name(admin, adminnames[admin], charsmax(adminnames[]))
            }
        }
    }
}
