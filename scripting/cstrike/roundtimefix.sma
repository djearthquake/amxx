#include <amxmodx>
new bool:bRoundTimerFixed[MAX_PLAYERS + 1]
new vbuffer[MAX_IP_LENGTH]

enum _:authors_details
{
    plugin[MAX_NAME_LENGTH],
    version[MAX_IP_LENGTH],
    author[MAX_NAME_LENGTH]
}
new plugin_registry[ authors_details ]

new g_ForceRoundTimer
new fix_counter

public plugin_init()
{
    new hour,min,sec
    time(hour,min,sec)
    formatex(vbuffer,charsmax(vbuffer),"%i:%i:%i", hour, min, sec)

    plugin_registry[ plugin ] = "CS roundtimer fix"
    plugin_registry[ version ] = vbuffer
    plugin_registry[ author ] = ".sρiηX҉."

    set_task( 5.0, "@register", 777, plugin_registry, authors_details )
}

@register()
{
    register_plugin
    (
        .plugin_name = plugin_registry[ plugin ],
        .version =  plugin_registry[ version ],
        .author = plugin_registry[ author ]
    )

    new mname[MAX_RESOURCE_PATH_LENGTH]
    get_mapname(mname,charsmax(mname));
    if(containi(mname, "de_") !=-1)
        pause "a"

    register_event("ResetHUD", "@RoundTimerFix", "bef")
    g_ForceRoundTimer = get_user_msgid("ShowTimer")
}

@RoundTimerFix(id)
if(!bRoundTimerFixed[id])
{
    emessage_begin(MSG_ONE_UNRELIABLE, g_ForceRoundTimer, _, id);
    emessage_end();
    bRoundTimerFixed[id] = true
    fix_counter++
}

public client_disconnected(id)
{
    bRoundTimerFixed[id] = false
}

public plugin_end()
{
    if(fix_counter)
        log_amx "%s %s by %s fixed %i clients!", plugin_registry[ plugin ], plugin_registry[ version ], plugin_registry[ author ], fix_counter
}
