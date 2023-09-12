#include amxmodx
#include amxmisc

#define MAX_NAME_LENGTH 32
#define charsmin -1

new Xcvar_access

public plugin_init()
{
    register_plugin( "Map say!", "1.0", "SPiNX" );

    Xcvar_access = register_cvar("admins_votemap_only", "0")
    new iPick = get_pcvar_num(Xcvar_access)

    register_clcmd("say", "sayChangeMap", iPick?ADMIN_RESERVATION:0, "- say !mapname to vote!")
}

public sayChangeMap(id,level,cid)
{
    new szArgs[MAX_NAME_LENGTH + 3], szArg2[MAX_NAME_LENGTH];
    if(is_user_connected(id))
    {
        if( (!cmd_access ( id, level, cid, 1 )) )
            return PLUGIN_HANDLED;

        read_args(szArgs, charsmax(szArgs));replace(szArgs, charsmax(szArgs), "^"", "");
        if(containi(szArgs, "!")>-1)
        {
            replace(szArgs, charsmax(szArgs), "!", "");
            parse(szArgs, szArg2, charsmax(szArg2));

            if(is_map_valid(szArg2))
            {
                log_amx( "%n called map vote for %s.", id, szArg2 );
                console_cmd( 0, "amx_votemap ^"%s^"", szArg2 );

            }

        }

    }
    return PLUGIN_CONTINUE;
}
