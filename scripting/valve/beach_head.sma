#include amxmodx
#include fakemeta
#include hamsandwich

static const Map[]="beach_head"
new bIsBot[MAX_PLAYERS+1], g_ceiling

public plugin_init()
{
    register_plugin( "beach_head fix", "1.0", "SPiNX" );
    g_ceiling = register_cvar("map_ceiling", "1700")
    static mapname[MAX_RESOURCE_PATH_LENGTH]
    get_mapname(mapname,charsmax(mapname))
    if(!equali(mapname, Map))
    {
        pause("a")
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
        set_task(15.0,  "client_command", id, _,_,"b")
    }
}

public client_disconnected(id)
{
    if(task_exists(id))
        remove_task(id)
}

public client_command(id)
{
    static origin[3];
    if(is_user_alive(id))
    {
        get_user_origin(id,origin,0)
        //spec_pos -24.4 403.7 3320.6 61.9 88.4
        static iCeiling;iCeiling = get_pcvar_num(g_ceiling)
        if(origin[2] > iCeiling)
        {
            //ExecuteHamB(Ham_CS_RoundRespawn, id);
            dllfunc(DLLFunc_ClientPutInServer, id)
            dllfunc(DLLFunc_SpectatorDisconnect, id)
            console_cmd 0, "say ^"%n was stuck in wall?^"", id

            if(!bIsBot[id])
                console_cmd id, "spk buttons/blip2"
        }
    }
}
