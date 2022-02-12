/*Manually backup plugins.ini prior to using this script! USE AT YOUR OWN RISK!*/
///CVAR safe_mode 0|1 Run server without Amxx or any plugins then return back to normal mode
#include amxmodx
#include amxmisc
#define MAX_CMD_LENGTH             128
#define MAX_MOTD_LENGTH            1536
#define PLUGIN  "safe_mode"
new Xsafe, XFastRest
new SzSave[MAX_CMD_LENGTH]
new mname[MAX_NAME_LENGTH]
new Trie:g_SafeMode
new g_cvar_debugger
new g_szDataFromFile[ MAX_MOTD_LENGTH + MAX_MOTD_LENGTH ]
new g_szFilePath[ MAX_CMD_LENGTH + MAX_NAME_LENGTH ]

enum _:Safe_Mode
{
    SzMaps[ MAX_NAME_LENGTH ],
    SzPlugin1[ MAX_NAME_LENGTH ],
    SzPlugin2[ MAX_NAME_LENGTH ],
    SzPlugin3[ MAX_NAME_LENGTH ],
    SzPlugin4[ MAX_NAME_LENGTH ],
    SzPlugin5[ MAX_NAME_LENGTH ],
    SzPlugin6[ MAX_NAME_LENGTH ],
    SzPlugin7[ MAX_NAME_LENGTH ],
    SzPlugin8[ MAX_NAME_LENGTH ],
    SzPlugin9[ MAX_NAME_LENGTH ]
}
new Data[ Safe_Mode ]

public plugin_init()
{
    /*1.0 - 1.1 Added a init file over hard-coded test plugin*/
    /*1.1 - 1.2 Test and bugfix. Allow more plugins. Reload maps that are not in safe-mode to get out of it. Work on safemode back-to-back as it will load previous map not current.*/

    register_plugin(PLUGIN,"1.2", "SPiNX")
    Xsafe = register_cvar("safe_mode", "0")
    XFastRest = register_cvar("safe_fast_reset", "1") //otherwise it takes 2 map changes to get back to normal
    g_cvar_debugger   = register_cvar("safemode_debug", "1");
    g_SafeMode = TrieCreate()
}

@reload_map()
{
    client_print 0, print_center, "Reloading map specific plugins"
    server_cmd "amx_map %s",mname
    //flushes out Amxx
}

public ReadSafeModeFromFile( )
{
    new SzSafeMap_Extension[MAX_NAME_LENGTH]
    new g_szFilePathSafe[ MAX_CMD_LENGTH ]

    get_mapname(mname, charsmax(mname));

    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    //formatex(SzSafeMap_Extension, charsmax( SzSafeMap_Extension ), "/plugins.ini.%s.safe", mname )
    formatex(SzSafeMap_Extension, charsmax( SzSafeMap_Extension ), "/plugins.ini.safe")

    add( g_szFilePath, charsmax( g_szFilePath ), "/safe_mode.ini" )

    new debugger = get_pcvar_num(g_cvar_debugger)

    new f = fopen( g_szFilePath, "rt" )

    if( !f )
    {
        return
    }

    while( !feof( f ) )
    {
        fgets( f, g_szDataFromFile, charsmax( g_szDataFromFile ) )

        if( !g_szDataFromFile[ 0 ] || g_szDataFromFile[ 0 ] == ';' || g_szDataFromFile[ 0 ] == '/' && g_szDataFromFile[ 1 ] == '/' )
            continue

        trim
        (
            g_szDataFromFile
        )
        parse
        (
            g_szDataFromFile,
            Data[ SzMaps], charsmax( Data[ SzMaps ] ),
            Data[ SzPlugin1 ], charsmax( Data[SzPlugin1] ),
            Data[ SzPlugin2 ], charsmax( Data[SzPlugin2] ),
            Data[ SzPlugin3 ], charsmax( Data[SzPlugin3] ),
            Data[ SzPlugin4 ], charsmax( Data[SzPlugin4] ),
            Data[ SzPlugin5 ], charsmax( Data[SzPlugin5] ),
            Data[ SzPlugin6 ], charsmax( Data[SzPlugin6] ),
            Data[ SzPlugin7 ], charsmax( Data[SzPlugin7] ),
            Data[ SzPlugin8 ], charsmax( Data[SzPlugin8] ),
            Data[ SzPlugin9 ], charsmax( Data[SzPlugin9] )
        )

        if(debugger)
            server_print "Read %s^n%s^n%s^n%s^n%s^n%s^n%s,%i^n^nfrom file",Data[ SzMaps ], Data[ SzPlugin1 ], Data[ SzPlugin2 ], Data[ SzPlugin3 ], Data[ SzPlugin4 ], Data[ SzPlugin5 ], Data[ SzPlugin6 ], Data[ SzPlugin7 ]

        TrieSetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data )

    }
    fclose( f )
    if(debugger)
        server_print "................Safe Mode init file....................."
///////////////////////////////////////////////////////////////////////////////////////////////////

    server_print "[%s]map name is %s", PLUGIN, mname

    Data[ SzMaps ] = mname
    //IF MAP IS IN THE INI FILE IT IS MARKED HERE
    if(TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
    {
        set_pcvar_num(Xsafe, 1)
    }
    else
    {
        set_pcvar_num(Xsafe, 0)
    }

    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    copy(g_szFilePathSafe,charsmax(g_szFilePathSafe),g_szFilePath)

    add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )

    add( g_szFilePathSafe, charsmax( g_szFilePathSafe ), SzSafeMap_Extension )

    new f2 = fopen( g_szFilePathSafe, "r" )

    if(!f2 && get_pcvar_num(Xsafe))
    {
        rename_file(g_szFilePath,g_szFilePathSafe,1)
        server_print "trying save^n^n%s", g_szFilePathSafe
        formatex(SzSave,charsmax(SzSave),"%s.amxx", PLUGIN)

        write_file(g_szFilePath, SzSave)

        //write_file(g_szFilePath, Data[ SzPlugins ])

        write_file(g_szFilePath, Data[ SzPlugin1 ])
        write_file(g_szFilePath, Data[ SzPlugin2 ])
        write_file(g_szFilePath, Data[ SzPlugin3 ])
        write_file(g_szFilePath, Data[ SzPlugin4 ])
        write_file(g_szFilePath, Data[ SzPlugin5 ])
        write_file(g_szFilePath, Data[ SzPlugin6 ])
        write_file(g_szFilePath, Data[ SzPlugin7 ])
        write_file(g_szFilePath, Data[ SzPlugin8 ])
        write_file(g_szFilePath, Data[ SzPlugin9 ])


        client_print 0,print_chat, "reloading %s", mname
        server_print"reloading %s", mname

        //set_task(1.0,"@reload_map",2021,mname,charsmax(mname)) //hosed HKP BOT
        set_task(20.0,"@reload_map",2021,mname,charsmax(mname))

    }

    else if(!f2 && !get_pcvar_num(Xsafe))
        server_print "File not found and safemode is off!"

    else if(f2 && get_pcvar_num(Xsafe))
    {
        if(!task_exists(2022) && get_pcvar_num(XFastRest))
            set_task(15.0,"fast_normalize",2022)
    }

    else
    {
        server_print "File found. Renaming..."
        rename_file(g_szFilePathSafe,g_szFilePath,1)

        log_amx ("Keeping Safemode off of unintended map.")
        set_task(20.0,"@push_map",2021,mname,charsmax(mname))

    }

}

@push_map()
{
    client_print 0, print_center, "Reloading map plugins"
    server_cmd "changelevel %s",mname
}

public fast_normalize(g_szFilePathSafe[],g_szFilePath[])
{
    rename_file(g_szFilePathSafe,g_szFilePath,1)
    server_print "Renamed file to prevent multiple reboots to normalcy."
}

public plugin_cfg()
{
    ReadSafeModeFromFile( )
}

public plugin_end()
    TrieDestroy(g_SafeMode)
