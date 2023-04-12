#include amxmodx
#include hamsandwich

static const Map[]="st_bessjump"
new bIsBot[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin( "st_bessjump fix", "1.0", "SPiNX" );
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
    new origin[3];
    if(is_user_connected(id) && is_user_alive(id))
    {
        get_user_origin(id,origin,0)
        if(origin[2] < -3900)
        {
            ExecuteHamB(Ham_CS_RoundRespawn, id);
            console_cmd 0, "say ^"%n was down below!^"", id

            if(!bIsBot[id])
                console_cmd id, "spk buttons/blip2"
        }
    }
}
