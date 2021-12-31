#include amxmodx
#include engine
#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1
new g_door_speed
new g_door_mod
public plugin_init()
{
    register_plugin("Door sound repair", "A", ".sρiηX҉.");
    server_print "%i doors modified!",g_door_mod
}

public pfn_keyvalue( ent )
{
    g_door_speed = register_cvar("mp_door_speed", "1")
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(containi(Classname,"door") > charsmin)
    {
        if(equali(key,"stopsnd"))
            DispatchKeyValue("stopsnd","5")

        else if(equali(key,"movesnd"))
            DispatchKeyValue("movesnd","5")

        else if(equali(key,"speed"))
            DispatchKeyValue("speed", get_pcvar_num(g_door_speed)?"100":"15") &&

        g_door_mod++
    }
}
