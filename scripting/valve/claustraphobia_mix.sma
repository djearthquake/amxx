/*Fixes missing sounds in map.*/
#include <amxmodx>

public plugin_precache()
{
    register_plugin("claustraphobia_mix", "1.1", "SPiNX")

    static szMapName[MAX_PLAYERS]
    get_mapname(szMapName, charsmax(szMapName))

    if (equal(szMapName, "claustraphobia_mix"))
    {
        precache_sound("debris/metal1.wav")
        precache_sound("debris/metal3.wav")
    }
    else
    {
        pause("ad")
    }
}
