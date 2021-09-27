/*Type query "COMPLETE_STEAMID" in console*/
#include amxmodx
#include amxmisc

#define MAX_PLAYERS                32
#define MAX_USER_INFO_LENGTH       256
#define MAX_COMMAND                128

new const URL[]="https://www.steamidfinder.com/lookup/"
new motd[MAX_USER_INFO_LENGTH ],Theurl[MAX_COMMAND], iArg1[MAX_PLAYERS]
new const alias[][]={"aka", "bka", "lookup", "names", "realname", "snoop", "query"}

public plugin_init()
{
    register_plugin("Amxx steamid name","Sept2021",".sρiηX҉.")
    for(new es = 0;es < sizeof alias; ++es)
        register_clcmd(alias[es],"@cmd_steamname",ADMIN_KICK,"<--Type command and quote STEAMID for name lookup.")
}
@cmd_steamname(id,level,cid)
{
    if(!cmd_access ( id, level, id, 1 ))
        return PLUGIN_HANDLED;

    if ( !cstrike_running() || (is_running("dod") == 1)  )
    {
        client_print id,print_center,"Client does not support^n browsing."
        return PLUGIN_HANDLED;
    }

    if(is_user_connected(id))
    {
        read_argv(1,iArg1,charsmax(iArg1));
        format(Theurl, charsmax(Theurl),"%s%s",URL,iArg1);
        client_print id, print_console, "Trying %s",Theurl
        format(motd, charsmax(motd), "<html><meta http-equiv='Refresh' content='0; URL=%s'><body BGCOLOR='#FFFFFF'><br><center>Name lookup</center></html>", Theurl);
        show_motd(id, motd, "SteamID Name checker");
    }
    return PLUGIN_HANDLED;
}
