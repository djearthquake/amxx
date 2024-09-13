/*Map spawntype changer*/

#include amxmodx
#include engine_stocks

#define MAX_CMD_LENGTH 128

///////////////////////////////////////////////////////////
static const Ent_of_interest[] = "info_gangsta_dm_start" //  <--Spawn class map.
static const szNewClass[] = "info_player_deathmatch"     //  <--Spawn class mod.
//////////////////////////////////////////////////////////

static const SzSpawns[][]={"info_gangsta_dm_start", "info_italian_start", "info_russian_start"} //GW Mod

public plugin_init()
{
    register_plugin( "Spawn Transformer", "1.1", "SPiNX" );
}

public pfn_keyvalue( ent )
{
    static Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ];
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    for(new ent;ent < sizeof SzSpawns;++ent)
    if(equal(Classname,SzSpawns[ent]))
    {
        new ent = create_entity(szNewClass)
        DispatchKeyValue( ent, key, value )
        DispatchSpawn(ent);
    }
}
