/*Map spawntype changer*/
#include amxmodx
#include engine_stocks

#define MAX_CMD_LENGTH 128
//////////////////////////////////////////////////////////
static const Ent_of_interest[] = "info_gangsta_dm_start"
static const szNewClass[] = "info_player_deathmatch"
//////////////////////////////////////////////////////////

enum _:authors_details
{
    plugin[MAX_NAME_LENGTH],
    version[MAX_IP_LENGTH],
    author[MAX_NAME_LENGTH]
}

static plugin_registry[ authors_details ]

new ent_counter

static vbuffer[MAX_IP_LENGTH]

public plugin_init()
{
    static hour,min,sec
    time(hour,min,sec)
    formatex(vbuffer,charsmax(vbuffer),"%i:%i:%i", hour, min, sec)
    plugin_registry[ plugin ] = "Spawn type changer"
    plugin_registry[ version ] = vbuffer
    plugin_registry[ author ] = ".sρiηX҉."
    set_task( 1.0, "@register", 777, plugin_registry, authors_details )
}

@register()
{
    register_plugin
    (
        .plugin_name = plugin_registry[ plugin ],
        .version =  plugin_registry[ version ],
        .author = plugin_registry[ author ]
    )

    if(ent_counter)
        log_amx "%s altered %i ents!", plugin_registry[ plugin ], ent_counter

}

public pfn_keyvalue( ent )
{
    static Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ];
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(equal(Classname,Ent_of_interest))
    {
        new ent = create_entity(szNewClass)
        DispatchKeyValue( ent, key, value )
        DispatchSpawn(ent);
        
        ent_counter++
    }
}
