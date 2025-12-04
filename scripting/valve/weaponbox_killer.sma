#include amxmodx
#include engine_stocks
#include fakemeta
#include hamsandwich
#define BOX_MAX  7

static g_touch_group[11];
new g_ent_count, bool:bRegistered

static const ents[][]={"worldspawn", "trigger_hurt", "func_breakable", "func_pushable", "func_wall", "func_door", "func_train", "func_platrot", "func_door_rotating", "func_conveyor", "func_tankmortar"};

public plugin_init()
{
    register_plugin("Real Weaponbox Killer","0.3","SPiNX")
    RegisterHam(Ham_Spawn, "weaponbox", "@_weaponbox", 1)
}

@ent_count()
{
    g_ent_count = 0;
    new ent = MaxClients;
    while( (ent = find_ent(ent, "weaponbox") ) > MaxClients && pev_valid(ent) )
    g_ent_count++;
    server_print "Boxes found:%i", g_ent_count
    if(g_ent_count<BOX_MAX-2)
    {
        @unregister();
    }
}

@_weaponbox(iloot_crate)
{
    if(iloot_crate)
    {
        g_ent_count++;
    }
    if(g_ent_count>BOX_MAX)
    {
        if(!bRegistered)
        {
            bRegistered = true
            for(new list; list < sizeof ents;list++)
            {
                g_touch_group[list] = register_touch("weaponbox",ents[list], "@kill");
                server_print "Registering: %s to forward ID %i array slot %i",ents[list],g_touch_group[list], list;
            }
        }
        set_task 5.0, "@ent_count", 2025
    }
}

@kill(iBox,world)
{
    if(pev_valid(iBox))#include amxmodx
#include engine_stocks

static const ents[]={"worldspawn", "func_breakable", "func_wall", "func_door","func_train"};

public plugin_init()
{
    register_plugin("Real Weaponbox Killer","0.1","SPiNX")
    for(new list; list <sizeof ents;list++)
    register_touch("weaponbox",ents[list], "@kill")
}

@kill(iBox,world)if(iBox>MaxClients)call_think(iBox);

    {
        call_think(iBox);
    }
}

@unregister()
{
    for(new list; list < sizeof ents;list++)
    {
        if(unregister_touch(g_touch_group[list]))
        {
            server_print"Unregistering %i", g_touch_group[list]
        }

    }
    bRegistered = false
    remove_task(2025)

    return PLUGIN_CONTINUE;
}
