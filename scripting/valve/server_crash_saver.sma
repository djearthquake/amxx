#include <amxmodx>
#include <fakemeta>
#include <engine>

// Change to 2000 if liblist.gam is set to edicts "2048"
#define EDICT_THRESHOLD 850

new bool:g_bMapChanging;

public plugin_init()
{
    register_plugin("Max Edict Reloader", "1.1", ".sρiηX҉.");
}

public pfn_touch(ptr, ptd)
{
    if (g_bMapChanging)
    {
        return;
    }

    static iEntCount;
    iEntCount = engfunc(EngFunc_NumberOfEntities);

    if (iEntCount >= EDICT_THRESHOLD)
    {
        g_bMapChanging = true;

        static szMapName[MAX_PLAYERS];
        get_mapname(szMapName, charsmax(szMapName));

        log_amx("[Edict Guard] Entities reached %d. Reloading map %s.", iEntCount, szMapName);
        server_cmd("changelevel %s", szMapName);
    }
}
