#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Grenade Trail Plus"
#define VERSION "0.0.1"
#define AUTHOR  "SPiNX"

#define iRandomColor random(256)

#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32

#define URL              "https://github.com/djearthquake

//Amx 182
#if !defined set_ent_rendering
#define set_ent_rendering set_rendering
#endif

//Globals
static g_AR_think, g_bolt_think;

//Precache
static sprite;

//Arms
static const sz_Spawn[][]=
{
    "grenade",
    "hornet",
    "rpg_rocket",
    "monster_satchel"
}

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 || AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR)
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL)
    #endif

    for(new s;s<sizeof sz_Spawn;++s)
    {
        RegisterHam(Ham_Spawn, sz_Spawn[s], "@grenade_spawn", 1);
    }

    g_AR_think = register_think("ARgrenade","@grenade_spawn");
    g_bolt_think = register_think("bolt","@grenade_spawn");
}

public plugin_precache()
{
    sprite = precache_model("sprites/smoke.spr");
}

@grenade_spawn(ent)
{
    @Trail_me(ent)
    @Glow_me(ent)
}

@Trail_me(ent)
{
    static lums;  lums  = random_num(20,500);
    static time;  time  = random_num(18,40);
    static width; width = random_num(5,15);

    if(pev_valid(ent))
    {
        emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
        ewrite_byte(TE_BEAMFOLLOW);
        ewrite_short(ent);
        ewrite_short(sprite);
        ewrite_byte(time);
        ewrite_byte(width);
        ewrite_byte(iRandomColor);
        ewrite_byte(iRandomColor);
        ewrite_byte(iRandomColor);
        ewrite_byte(lums);
        emessage_end();
    }
}

@Glow_me(ent)
{
    if(pev_valid(ent))
    {
        switch(random(2))
        {
            case 0: set_rendering(ent, kRenderFxExplode, iRandomColor, iRandomColor, iRandomColor, kRenderGlow, power(50,10));
            case 1: set_rendering(ent, kRenderFxGlowShell, iRandomColor, iRandomColor, iRandomColor, kRenderNormal, random_num(8,100));
        }
    }
}

public plugin_end()
{
    unregister_think(g_AR_think);
    unregister_think(g_bolt_think);
}
