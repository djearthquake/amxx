#include amxmodx
#include engine
#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

new const TRAIN[]= "func_train"
new const TTRAIN[]= "func_tracktrain"

new const CORNER[]= "path_corner"
new const BOOST[]= "yaw_speed"
new const WOT[]= "speed"
new const LIFE[]= "damage"

//Speed stages
new const norm[]= "500"
new const fast[]= "820"
new const realfast[]= "1132"

new g_fun_train, g_path_corn

public plugin_init()
{
    register_plugin("Crzzy Train", "A", ".sρiηX҉.");
    server_print "%i trains modified!",g_fun_train
    server_print "%i paths modified!",g_path_corn
}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(containi(Classname,CORNER) > charsmin || containi(Classname,TRAIN) > charsmin || containi(Classname,TTRAIN) > charsmin)
    {
        if(equali(key,BOOST))
        {
            DispatchKeyValue(BOOST,realfast)
            g_path_corn++
        }
        else if(equali(key,LIFE))
            DispatchKeyValue(LIFE,"-1")

        else if(equali(key,WOT))
        {
            DispatchKeyValue(WOT,fast)
            g_fun_train++
        }
        else if(equali(key,"volume"))
            DispatchKeyValue("volume","0")///emit something else later
    }
    if(containi(Classname,"ambient_generic") > charsmin)

    if(equali(key,"message") && equali(value,"ambience/warn3.wav"))
        DispatchKeyValue("message","ambience/warn2.wav")
}
