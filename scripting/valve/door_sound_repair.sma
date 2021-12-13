#include amxmodx
#include engine
#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

new g_door_mod
public plugin_init()
{
    register_plugin("Door sound repair", "A", ".sρiηX҉.");
    server_print "%i doors modified!",g_door_mod
}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    //door sound loop fix
    if(containi(Classname,"func_door") > charsmin)
    {
        if(equali(key,"stopsnd"))
            DispatchKeyValue("stopsnd","5")

        else if(equali(key,"movesnd"))
            DispatchKeyValue("movesnd","5")

        else if(equali(key,"speed"))
            DispatchKeyValue("speed","15")

        else if(equali(key,"rendercolor"))
        {
            DispatchKeyValue("rendercolor","125 68 152")
            g_door_mod++
        }
    }
}
