/*Fixes missing sounds in map.*/
#include amxmodx

public plugin_precache()
{
    register_plugin("claustraphobia_mix", "1.0", "SPiNX")
    precache_sound("debris/metal1.wav")
    precache_sound("debris/metal3.wav")
}
