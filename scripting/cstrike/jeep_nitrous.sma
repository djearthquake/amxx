#include amxmodx
#include engine
#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

new const ACCEL[]= "acceleration"
new const CARS[]= "func_vehicle"
new const VRMM[]= "speed"

//Nitrous stages
//new const norm[]= "650"
//new const fast[]= "1300"
new const realfast[]= "1500"

//Super-chargers
//new const blower1[]= "9"
//new const blower2[]= "11"
new const blower3[]= "15"
new g_hotroded

public plugin_init()
{
    register_plugin("Jeep Nitros", "1.5", ".sρiηX҉.");
    server_print "%i cars modified!",g_hotroded
}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    //new nitros = register_cvar("jeep_nitros", "1")
    if(containi(Classname,CARS) > charsmin)
    {
        if(equali(key,ACCEL))
            DispatchKeyValue(ACCEL,blower3)

        else if(equali(key,VRMM))
        {
            DispatchKeyValue(VRMM,realfast)
            g_hotroded++
        }
    }
}
