/*Manually backup plugins.ini prior to using this script! USE AT YOUR OWN RISK!*/
///CVAR safe_mode 0|1 Run server without Amxx or any plugins then return back to normal mode
#include amxmodx
#include amxmisc
#define MAX_CMD_LENGTH                128
#define MAX_MOTD_LENGTH               1536
#define PLUGIN  "safe_mode"
#define VERSION "1.33"
#define AUTHOR "SPiNX"
#define charsmin                      -1
#define MAX_MAPS                      512

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new Xsafe
new SzSave[MAX_CMD_LENGTH]
static mname[MAX_RESOURCE_PATH_LENGTH]
new Trie:g_SafeMode
new g_cvar_debugger
new g_Adm
new g_maxPlayers
new g_szDataFromFile[ MAX_MOTD_LENGTH + MAX_MOTD_LENGTH ]
new g_szFilePath[ MAX_CMD_LENGTH + MAX_NAME_LENGTH ]
new g_szFilePathSafe[ MAX_CMD_LENGTH ]
new g_SzNextMap[MAX_NAME_LENGTH]
new g_SzNextMapCmd[MAX_RESOURCE_PATH_LENGTH]

new bool:bCallingfromEnd
new bool:bBackupPluginsINI
new bool:bCMDCALL
new szArg[MAX_CMD_LENGTH];
new szArgCmd[MAX_NAME_LENGTH], szArgCmd1[MAX_NAME_LENGTH];
new const SzSafeModeFileName[]="/safe_mode.ini"

enum _:Safe_Mode
{
    SzMaps[ MAX_MAPS ],
    SzPlugin0[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin1[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin2[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin3[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin4[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin5[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin6[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin7[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin8[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin9[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin10[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin11[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin12[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin13[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin14[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin15[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin16[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin17[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin18[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin19[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin20[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin21[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin22[ MAX_RESOURCE_PATH_LENGTH ],
    SzPlugin23[ MAX_RESOURCE_PATH_LENGTH ]
}
new Data[ Safe_Mode ]

public plugin_init()
{
    /*1.0 - 1.1    Added a init file over hard-coded test plugin*/
    /*1.1 - 1.2    Test and bugfix. Allow more plugins. Reload maps that are not in safe-mode to get out of it. Work on safemode back-to-back as it will load previous map not current.*/
    /*1.2 - 1.3    Enhance stability via proactive triggering of safemode on plugin_end when next map requires safemode. Also when triggered by admin command.*/
    /*1.3 - 1.33  Optimize by moving plugins.ini creation to plugin_end instead of function calls on other map related plugins. Generate missing safe_mode.ini file instead of pausing.*/

    register_plugin(PLUGIN,VERSION, AUTHOR)
    Xsafe = register_cvar("safe_mode", "0")
    g_cvar_debugger  = register_cvar("safemode_debug", "0");

    g_SafeMode = TrieCreate()
    g_maxPlayers = get_maxplayers()

    //Backup file check time
    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    static SzSafeMap_Revert[MAX_CMD_LENGTH],
    Sz_RevertPath[MAX_CMD_LENGTH]
    copy(Sz_RevertPath, charsmax(Sz_RevertPath), g_szFilePath)

    add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )
    formatex(SzSafeMap_Revert, charsmax( SzSafeMap_Revert ), "/plugins.ini.backup")

    add( Sz_RevertPath, charsmax(Sz_RevertPath), SzSafeMap_Revert )

    static f; f = fopen( Sz_RevertPath, "rt" )

    if( f )
    {
        bBackupPluginsINI = true
    }
    else
    {
        log_amx "Make a manual backup of plugins.ini before using %s %s by %s", PLUGIN, VERSION, AUTHOR
        pause("a")
    }

    bBackupPluginsINI?server_print("Back up of PLUGINS.INI already captured."):server_print("Backing up of PLUGINS.INI")
}

@reload_map()
{
    client_print 0, print_center, "Reloading map specific plugins"
    console_cmd 0, "amx_map %s", mname
    //flushes out Amxx
}

public client_command(id)
{
    read_args(szArg, charsmax(szArg));
    read_argv(0,szArgCmd, charsmax(szArgCmd));
    read_argv(1,szArgCmd1, charsmax(szArgCmd1));
    if(is_user_connected(id) && CheckPlayerBit(g_Adm, id) && !is_str_num(szArgCmd1))
    {
        @cmd_call(szArgCmd1)
    }
}

@cmd_call(SzMapname[MAX_NAME_LENGTH])
{
    bCMDCALL = true

    if(!is_map_valid(SzMapname))
        return

    log_amx "Validating %s", SzMapname

    Data[ SzMaps ] =  SzMapname
    set_cvar_string "amx_nextmap", SzMapname

    if(!TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
    {
        @clear_plugins()
    }

    server_print("%s MUST preload %s via command", PLUGIN, SzMapname)
    copy(g_SzNextMapCmd, charsmax(g_SzNextMapCmd), SzMapname)
    ReadSafeModeFromFile( )
}

@clear_plugins()
{
    static SzSafeMap_Extension[MAX_NAME_LENGTH],
    SzSafeMap_Revert[MAX_CMD_LENGTH],
    Sz_RevertPath[MAX_CMD_LENGTH]
    bCallingfromEnd = true

    server_print("Clearing plugins if needed.")

    get_cvar_string("amx_nextmap", g_SzNextMap, charsmax(g_SzNextMap))
    server_print "Checking if %s needs to preload %s.", g_SzNextMap, PLUGIN
    Data[ SzMaps ] = g_SzNextMap

    if(TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
    {
        get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
        copy(g_szFilePathSafe, charsmax(g_szFilePathSafe), g_szFilePath)

        add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )
        formatex(SzSafeMap_Extension, charsmax( SzSafeMap_Extension ), "/plugins.ini.safe")
        add( g_szFilePathSafe, charsmax( g_szFilePathSafe ), SzSafeMap_Extension )

        if(!get_pcvar_num(Xsafe))
        {
            //Make a blanked out plugins.ini to load enough just to load the select plugins admin loads
            set_pcvar_num(Xsafe, 1) //set it to safemode in advance

            server_print("%s MUST preload %s.", PLUGIN, g_SzNextMap)

            static g; g = fopen( g_szFilePathSafe, "rt" )

            if( g )
            {
                server_print("%s already showing as made. Aborting...",g_szFilePathSafe )
                return PLUGIN_HANDLED
            }
            goto READ_FILE
            server_print "Renaming FROM %s^n TO: %s", g_szFilePath, g_szFilePathSafe

            get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
            copy(Sz_RevertPath, charsmax(Sz_RevertPath), g_szFilePath)

            add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )
            formatex(SzSafeMap_Revert, charsmax( SzSafeMap_Revert ), "/plugins.ini.safe")

            add( Sz_RevertPath, charsmax(Sz_RevertPath), SzSafeMap_Revert )

            static f; f = fopen( g_szFilePath, "rt" )

            if( f )
            {
                return PLUGIN_HANDLED
            }
            //if file does not exist make one with only this plugin to keep it loaded!
            formatex(SzSave,charsmax(SzSave),"%s.amxx debug", PLUGIN)

            write_file(g_szFilePath, SzSave)
            server_print "trying save^n^n%s", g_szFilePathSafe
            goto READ_FILE
        }
        else
        {
                server_print("Renaming %s back to ^n%s.", SzSafeMap_Revert,g_szFilePath)
                rename_file(SzSafeMap_Revert,g_szFilePath,1)
         }
    }
    server_print("%s needs NOT preload %s.", PLUGIN, g_SzNextMap)
    READ_FILE:
    ReadSafeModeFromFile( )
    return PLUGIN_CONTINUE
}

public ReadSafeModeFromFile( )
{
    static SzSafeMap_Extension[MAX_NAME_LENGTH]
    bCMDCALL ? copy(Data[ SzMaps ] , charsmax(Data[]), g_SzNextMapCmd) : get_mapname(mname, charsmax(mname))

    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    formatex(SzSafeMap_Extension, charsmax( SzSafeMap_Extension ), "/plugins.ini.safe")
    add( g_szFilePath, charsmax( g_szFilePath ), "/safe_mode.ini" )

    static debugger; debugger = get_pcvar_num(g_cvar_debugger)

    static f; f = fopen( g_szFilePath, "rt" )

    if( !f )
    {
        static SzBuffer[MAX_CMD_LENGTH], SzName[MAX_CMD_LENGTH]

        //make INI file when missing
        static SzMapname[MAX_NAME_LENGTH]
        get_cvar_string "amx_nextmap", SzMapname, charsmax(SzMapname)

        formatex(SzName, charsmax(SzName), "^"%s^" ^"admincmd.amxx^" ^"mapsmenu.amxx^" ^"menufront.amxx^"", SzMapname)
        copy(SzBuffer, charsmax(SzBuffer), SzName)
        @file_data(SzBuffer)
    }
    server_print "Continuing to read from: %s", g_szFilePath
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
            Data[ SzPlugin9 ], charsmax( Data[SzPlugin9] ),
            Data[ SzPlugin10 ], charsmax( Data[SzPlugin10] ),
            Data[ SzPlugin11 ], charsmax( Data[SzPlugin11] ),
            Data[ SzPlugin12 ], charsmax( Data[SzPlugin12] ),
            Data[ SzPlugin13 ], charsmax( Data[SzPlugin13] ),
            Data[ SzPlugin14 ], charsmax( Data[SzPlugin14] ),
            Data[ SzPlugin15 ], charsmax( Data[SzPlugin15] ),
            Data[ SzPlugin16 ], charsmax( Data[SzPlugin16] ),
            Data[ SzPlugin17 ], charsmax( Data[SzPlugin17] ),
            Data[ SzPlugin18 ], charsmax( Data[SzPlugin18] ),
            Data[ SzPlugin19 ], charsmax( Data[SzPlugin19] ),
            Data[ SzPlugin20 ], charsmax( Data[SzPlugin20] ),
            Data[ SzPlugin21 ], charsmax( Data[SzPlugin21] ),
            Data[ SzPlugin22 ], charsmax( Data[SzPlugin22] ),
            Data[ SzPlugin23 ], charsmax( Data[SzPlugin23] )

        )

        if(debugger)
            server_print "Read %s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s,%i^n^nfrom file",Data[ SzMaps ], Data[ SzPlugin1 ], Data[ SzPlugin2 ], Data[ SzPlugin3 ], Data[ SzPlugin4 ], Data[ SzPlugin5 ], Data[ SzPlugin6 ], Data[ SzPlugin7 ], Data[ SzPlugin8 ], Data[ SzPlugin9 ], Data[ SzPlugin10 ], Data[ SzPlugin11 ], Data[ SzPlugin12 ], Data[ SzPlugin13 ], Data[ SzPlugin14 ], Data[ SzPlugin15 ], Data[ SzPlugin16 ]
        Data[ SzPlugin0 ] = PLUGIN

        TrieSetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data )

    }
    fclose( f )
    if(debugger)
        server_print "................Safe Mode init file....................."
///////////////////////////////////////////////////////////////////////////////////////////////////

    if(bCallingfromEnd)
        copy(mname, charsmax(mname), g_SzNextMap)


    bCMDCALL ? copy(Data[ SzMaps ], charsmax(Data), g_SzNextMapCmd) : get_mapname(mname, charsmax(mname))

    if(bCallingfromEnd)
        copy(Data[ SzMaps ], charsmax(Data), g_SzNextMap)
    if(!bCMDCALL && !bCallingfromEnd)
        copy(Data[ SzMaps ], charsmax(Data), mname)

    server_print "[%s]map name is %s", PLUGIN, Data[ SzMaps ] //mname

    set_pcvar_num(Xsafe, TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ) ? 1 : 0)

    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    copy(g_szFilePathSafe,charsmax(g_szFilePathSafe),g_szFilePath)

    add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )

    add( g_szFilePathSafe, charsmax( g_szFilePathSafe ), SzSafeMap_Extension )

    static f2; f2 = fopen( g_szFilePathSafe, "r" )

    if(!f2 && get_pcvar_num(Xsafe))
    {
        rename_file(g_szFilePath,g_szFilePathSafe,1)
        server_print "trying save^n^n%s", g_szFilePathSafe
        //safemode plugin itself
        formatex(SzSave,charsmax(SzSave),"%s.amxx", PLUGIN)
        write_file(g_szFilePath, SzSave)
        is_plugin_loaded("admin.amxx",true)!=charsmin?formatex(SzSave,charsmax(SzSave),"admin.amxx")&write_file(g_szFilePath, SzSave):formatex(SzSave,charsmax(SzSave),"admin_sql.amxx")&write_file(g_szFilePath, SzSave)
        //safemode needs nextmap to work
        formatex(SzSave,charsmax(SzSave),"nextmap.amxx")
        write_file(g_szFilePath, SzSave)

        if(!debugger)
        {
            //basic map pick fcn
            is_plugin_loaded("mapchooser.amxx",true)!=charsmin?formatex(SzSave,charsmax(SzSave),"mapchooser.amxx")&write_file(g_szFilePath, SzSave):server_print("Be wary of 3rd party map choosers.")
            write_file(g_szFilePath, SzSave)
        }

        write_file(g_szFilePath, Data[ SzPlugin1 ])
        write_file(g_szFilePath, Data[ SzPlugin2 ])
        write_file(g_szFilePath, Data[ SzPlugin3 ])
        write_file(g_szFilePath, Data[ SzPlugin4 ])
        write_file(g_szFilePath, Data[ SzPlugin5 ])
        write_file(g_szFilePath, Data[ SzPlugin6 ])
        write_file(g_szFilePath, Data[ SzPlugin7 ])
        write_file(g_szFilePath, Data[ SzPlugin8 ])
        write_file(g_szFilePath, Data[ SzPlugin9 ])
        write_file(g_szFilePath, Data[ SzPlugin10])
        write_file(g_szFilePath, Data[ SzPlugin11])
        write_file(g_szFilePath, Data[ SzPlugin12])
        write_file(g_szFilePath, Data[ SzPlugin13])
        write_file(g_szFilePath, Data[ SzPlugin14])
        write_file(g_szFilePath, Data[ SzPlugin15])
        write_file(g_szFilePath, Data[ SzPlugin16])
        write_file(g_szFilePath, Data[ SzPlugin17])
        write_file(g_szFilePath, Data[ SzPlugin18])
        write_file(g_szFilePath, Data[ SzPlugin19])
        write_file(g_szFilePath, Data[ SzPlugin20])
        write_file(g_szFilePath, Data[ SzPlugin21])
        write_file(g_szFilePath, Data[ SzPlugin22])
        write_file(g_szFilePath, Data[ SzPlugin23])


        for (new admin=1; admin<=g_maxPlayers; admin++)
            if (is_user_connected(admin) && CheckPlayerBit(g_Adm, admin))
                client_print admin, print_chat, "reloading %s^nplugins:^n%s^n%s^n%s^n%s^n%s...", Data[ SzMaps ], Data[ SzPlugin1 ], Data[ SzPlugin2 ], Data[ SzPlugin3 ], Data[ SzPlugin4 ],Data[ SzPlugin5 ]

        server_print"reloading %s", Data[ SzMaps ]

        set_task(20.0,"@reload_map",2021,mname,charsmax(mname))

    }

    else if(!f2 && !get_pcvar_num(Xsafe))
        server_print "File not found and safemode is off!"
    else if(!f2 && get_pcvar_num(Xsafe) && !bCallingfromEnd)
    {
        rename_file(g_szFilePathSafe,g_szFilePath,1)
        server_print "Renamed %s to^n%s",g_szFilePathSafe,g_szFilePath
    }

    else if (f2 && !get_pcvar_num(Xsafe) )
    {
        server_print "%s found. Renaming...%s", g_szFilePathSafe, g_szFilePath
        rename_file(g_szFilePathSafe,g_szFilePath,1)

        log_amx ("Keeping Safemode off of unintended map.")
        set_task(10.0,"@push_map",2021,mname,charsmax(mname))

    }
    bCallingfromEnd?server_print("Exit %s %s", PLUGIN, VERSION):server_print("Init %s %s", PLUGIN, VERSION)
}

@push_map()
{
    client_print 0, print_center, "Reloading map plugins"
    console_cmd 0, "changelevel %s", mname
}

public plugin_cfg()
{
    bCallingfromEnd = false
    ReadSafeModeFromFile( )
}

public plugin_end()
{
    static SzMapname[MAX_NAME_LENGTH]
    get_cvar_string "amx_nextmap", SzMapname, charsmax(SzMapname)
    @cmd_call(SzMapname)
    TrieDestroy(g_SafeMode)
}

@file_data(SzBuffer[MAX_CMD_LENGTH])
{
    server_print "%s|trying save %s", PLUGIN, SzBuffer
    static szFilePath[ MAX_USER_INFO_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), SzSafeModeFileName )

    write_file(szFilePath, SzBuffer)
}

public client_infochanged(id)
{
    is_user_admin(id) ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id)
}

public client_putinserver(id)
{
    is_user_admin(id) ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id)
}

public client_disconnected(id)
{
    ClearPlayerBit(g_Adm, id)
}
