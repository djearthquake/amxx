/*Manually backup plugins.ini prior to using this script! USE AT YOUR OWN RISK!*/
///CVAR safe_mode 0|1 Run server without Amxx or any plugins then return back to normal mode
#include amxmodx
#include amxmisc
#define MAX_CMD_LENGTH                        128
#define MAX_MOTD_LENGTH                     1536
#define PLUGIN  "safe_mode"
#define VERSION "1.32"
#define AUTHOR "SPiNX"
#define charsmin                                            -1

new Xsafe, XAlready
new SzSave[MAX_CMD_LENGTH]
new mname[MAX_NAME_LENGTH]
new Trie:g_SafeMode
new g_cvar_debugger
new g_szDataFromFile[ MAX_MOTD_LENGTH + MAX_MOTD_LENGTH ]
new g_szFilePath[ MAX_CMD_LENGTH + MAX_NAME_LENGTH ]
new g_szFilePathSafe[ MAX_CMD_LENGTH ]
new g_szFilePathSafeAlready[ MAX_CMD_LENGTH ]
new g_SzNextMap[MAX_NAME_LENGTH]
new g_SzNextMapCmd[MAX_NAME_LENGTH]
new bool:bCallingfromEnd
new bool:bBackupPluginsINI
new bool:bCMDCALL

enum _:Safe_Mode
{
    SzMaps[ MAX_NAME_LENGTH ],
    SzPlugin0[ MAX_NAME_LENGTH ],
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
    /*1.2 - 1.3 Enhance stability via proactive triggering of safemode on plugin_end when next map requires safemode. Also when triggered by admin command*/

    register_plugin(PLUGIN,VERSION, AUTHOR)
    Xsafe = register_cvar("safe_mode", "0")
    XAlready = register_cvar("safe_already", "0")
    g_cvar_debugger   = register_cvar("safemode_debug", "0");
    set_task_ex(3.5,"@clear_plugins", 2022, .flags = SetTask_BeforeMapChange)
    g_SafeMode = TrieCreate()
    
    //Backup file check time
    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    new SzSafeMap_Revert[MAX_CMD_LENGTH]
    new Sz_RevertPath[MAX_CMD_LENGTH]
    copy(Sz_RevertPath, charsmax(Sz_RevertPath), g_szFilePath)

    add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )
    formatex(SzSafeMap_Revert, charsmax( SzSafeMap_Revert ), "/plugins.ini.backup")

    add( Sz_RevertPath, charsmax(Sz_RevertPath), SzSafeMap_Revert )

    new f = fopen( Sz_RevertPath, "rt" )

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
    server_cmd "amx_map %s",mname
    //flushes out Amxx
}

@reload_map_already()
{
    client_print 0, print_center, "Reloading map specific plugins^back-to-back-safemode"
    set_pcvar_num(XAlready, 0) //stop loop
    server_cmd "changelevel %s",mname
}

public client_command(id)
{
    new szArg[MAX_CMD_LENGTH];
    new szArgCmd[MAX_IP_LENGTH], szArgCmd1[MAX_NAME_LENGTH];
    if(is_user_connected(id) && is_user_admin(id))
    {
        bCMDCALL = true
        read_args(szArg, charsmax(szArg));
        read_argv(0,szArgCmd, charsmax(szArgCmd));
        read_argv(1,szArgCmd1, charsmax(szArgCmd1));
        if(!is_map_valid(szArgCmd1))
            return
        Data[ SzMaps ] =  szArgCmd1

        if(!TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
        {
            set_cvar_string "amx_nextmap", szArgCmd1
            @clear_plugins()
        }

        server_print("%s MUST preload %s via command", PLUGIN, szArgCmd1)
        copy(g_SzNextMapCmd, charsmax(g_SzNextMapCmd), szArgCmd1)
        ReadSafeModeFromFile( )
    }
}

@clear_plugins()
{
    new SzSafeMap_Extension[MAX_NAME_LENGTH]
    new SzSafeMap_Revert[MAX_CMD_LENGTH]
    new Sz_RevertPath[MAX_CMD_LENGTH]
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

            new g = fopen( g_szFilePathSafe, "rt" )
        
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

            new f = fopen( g_szFilePath, "rt" )
        
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
    new SzSafeMap_Extension[MAX_NAME_LENGTH]
    new bool:bOF_run =  is_running("gearbox") || is_running("valve")
    bCMDCALL ? copy(Data[ SzMaps ] , charsmax(Data[]), g_SzNextMapCmd) : get_mapname(mname, charsmax(mname))

    get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
    formatex(SzSafeMap_Extension, charsmax( SzSafeMap_Extension ), "/plugins.ini.safe")
    add( g_szFilePath, charsmax( g_szFilePath ), "/safe_mode.ini" )

    new debugger = get_pcvar_num(g_cvar_debugger)

    new f = fopen( g_szFilePath, "rt" )

    if( !f )
    {
        server_print "Aborting read from: %s^nFile not found!", g_szFilePath
        log_amx "%s %s by %s, needs config file %s to operate^n %s paused!", PLUGIN, VERSION, AUTHOR, PLUGIN
        pause("a")
        return
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
            Data[ SzPlugin9 ], charsmax( Data[SzPlugin9] )
        )

        if(debugger)
            server_print "Read %s^n%s^n%s^n%s^n%s^n%s^n%s,%i^n^nfrom file",Data[ SzMaps ], Data[ SzPlugin1 ], Data[ SzPlugin2 ], Data[ SzPlugin3 ], Data[ SzPlugin4 ], Data[ SzPlugin5 ], Data[ SzPlugin6 ], Data[ SzPlugin7 ]
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

    if(TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
    {
        set_pcvar_num(Xsafe, 1)
    }
    else
    {
        set_pcvar_num(Xsafe, 0)
    }

    if(get_pcvar_num(Xsafe) && get_pcvar_num(XAlready))

    {
       set_task(2.0,"@already_safe",1999)
       return
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

        //safemode plugin itself
        formatex(SzSave,charsmax(SzSave),"%s.amxx debug", PLUGIN)
        write_file(g_szFilePath, SzSave)
        //safemode needs nextmap to work
        formatex(SzSave,charsmax(SzSave),"nextmap.amxx")
        write_file(g_szFilePath, SzSave)

        if(!debugger)
        {
            ///amx_map discourage using archaic commands
            formatex(SzSave,charsmax(SzSave),"admin.amxx")
            write_file(g_szFilePath, SzSave)

            formatex(SzSave,charsmax(SzSave),"admincmd.amxx")
            write_file(g_szFilePath, SzSave)


            formatex(SzSave,charsmax(SzSave),"menufront.amxx")
            write_file(g_szFilePath, SzSave)

            formatex(SzSave,charsmax(SzSave),"mapsmenu.amxx")
            write_file(g_szFilePath, SzSave)

            //basic map pick fcn
            formatex(SzSave,charsmax(SzSave),"mapchooser.amxx")
            write_file(g_szFilePath, SzSave)

            //Stop HPB bot over-fills. JK support also.
            bOF_run?formatex(SzSave,charsmax(SzSave),"autoconcom.amxx")&write_file(g_szFilePath, SzSave):server_print("OP4 mod is NOT running.")
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


        client_print 0,print_chat, "reloading %s", Data[ SzMaps ]
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

@already_safe()
{
    server_print "Already safe function entry."
    if(get_pcvar_num(XAlready))
    {
        new bool:bOF_run =  is_running("gearbox") || is_running("valve")
        new debugger = get_pcvar_num(g_cvar_debugger)

        server_print "Already safe mark set!"
        get_mapname(mname, charsmax(mname));
        //back to back safemode to assure the correct plugin set is loaded
        log_amx "Attempt flush this file and start a fresh one"
        set_pcvar_num(XAlready, 1)
        bCMDCALL ? copy(Data[ SzMaps ] , charsmax(Data[]), g_SzNextMapCmd) : get_mapname(mname, charsmax(mname))
        
        if(bCallingfromEnd)
            copy(Data[ SzMaps ], charsmax(Data), g_SzNextMap)

        if(!bCMDCALL && !bCallingfromEnd)
            copy(Data[ SzMaps ], charsmax(Data), mname)

        server_print "[%s]map name is %s", PLUGIN, Data[ SzMaps ] //mname
    
        //Data[ SzMaps ] = mname

        ///The work to make it unique
        if(TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
        {
            TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data )
            /////////////////////////////////////////////////////////////
            get_configsdir( g_szFilePath, charsmax( g_szFilePath ) )
            copy(g_szFilePathSafeAlready, charsmax(g_szFilePathSafeAlready), g_szFilePath)
            add( g_szFilePathSafeAlready, charsmax( g_szFilePathSafeAlready ), "/plugins.ini.0" )

            add( g_szFilePath, charsmax( g_szFilePath ), "/plugins.ini" )

            if(get_pcvar_num(Xsafe))
            {
                rename_file(g_szFilePath,g_szFilePathSafeAlready,1)
                server_print "trying save^n^n%s", g_szFilePathSafeAlready

                //safemode plugin itself
                formatex(SzSave,charsmax(SzSave),"%s.amxx debug", PLUGIN)
                write_file(g_szFilePath, SzSave)
                //safemode needs nextmap to work
                formatex(SzSave,charsmax(SzSave),"nextmap.amxx")
                write_file(g_szFilePath, SzSave)
        
                if(!debugger)
                {
                    ///amx_map discourage using archaic commands
                    formatex(SzSave,charsmax(SzSave),"admin.amxx")
                    write_file(g_szFilePath, SzSave)
        
                    formatex(SzSave,charsmax(SzSave),"admincmd.amxx")
                    write_file(g_szFilePath, SzSave)
        
        
                    formatex(SzSave,charsmax(SzSave),"menufront.amxx")
                    write_file(g_szFilePath, SzSave)
        
                    formatex(SzSave,charsmax(SzSave),"mapsmenu.amxx")
                    write_file(g_szFilePath, SzSave)
        
                    //basic map pick fcn
                    formatex(SzSave,charsmax(SzSave),"mapchooser.amxx")
                    write_file(g_szFilePath, SzSave)
        
                    //Stop HPB bot over-fills. JK support also.
                    bOF_run?formatex(SzSave,charsmax(SzSave),"autoconcom.amxx")&write_file(g_szFilePath, SzSave):server_print("OP4 mod is NOT running.")
                }

                write_file(g_szFilePath, SzSave)
                write_file(g_szFilePath, Data[ SzPlugin1 ])
                write_file(g_szFilePath, Data[ SzPlugin2 ])
                write_file(g_szFilePath, Data[ SzPlugin3 ])
                write_file(g_szFilePath, Data[ SzPlugin4 ])
                write_file(g_szFilePath, Data[ SzPlugin5 ])
                write_file(g_szFilePath, Data[ SzPlugin6 ])
                write_file(g_szFilePath, Data[ SzPlugin7 ])
                write_file(g_szFilePath, Data[ SzPlugin8 ])
                write_file(g_szFilePath, Data[ SzPlugin9 ])


                client_print 0,print_chat, "reloading %s already", mname
                server_print"reloading %s already", mname
                set_task(20.0,"@reload_map_already",2021,mname,charsmax(mname))
                delete_file(g_szFilePathSafeAlready)
            }

        }

    }
    server_print "Already safe function exit.^nEverything already cleared for next map."
}

@push_map()
{
    client_print 0, print_center, "Reloading map plugins"
    server_cmd "changelevel %s",mname
}

public plugin_cfg()
{
    bCallingfromEnd = false
    ReadSafeModeFromFile( )
}

public plugin_end()
    TrieDestroy(g_SafeMode)
