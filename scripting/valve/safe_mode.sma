/*Manually backup plugins.ini prior to using this script! USE AT YOUR OWN RISK!*/
///CVAR safe_mode 0|1 Run server without Amxx or any plugins then return back to normal mode
#include amxmodx
#include amxmisc
#define MAX_CMD_LENGTH             128
#define PLUGIN  "safe_mode"
new Xsafe
new SzSave[MAX_CMD_LENGTH]
new mname[MAX_NAME_LENGTH]
new Trie:g_SafeMode
new g_cvar_debugger

enum _:Safe_Mode
{
    SzMaps[ MAX_NAME_LENGTH ],
    SzPlugins[ MAX_NAME_LENGTH ]
}
new Data[ Safe_Mode ]

public plugin_init()
{
    /*1.0 - 1.1 Added a init file over hard-coded test plugin*/
    register_plugin(PLUGIN,"1.1", "SPiNX")
    Xsafe = register_cvar("safe_mode", "0")
    g_cvar_debugger   = register_cvar("safemode_debug", "1");
    g_SafeMode = TrieCreate()
}

@reload_map()
    server_cmd "amx_map %s",mname
    //flushes out Amxx

public ReadSafeModeFromFile( )
{
    new szDataFromFile[ MAX_CMD_LENGTH ]
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/safe_mode.ini" )

    new debugger = get_pcvar_num(g_cvar_debugger)

    new f = fopen( szFilePath, "rt" )

    if( !f )
    {
        return
    }

    while( !feof( f ) )
    {
        fgets( f, szDataFromFile, charsmax( szDataFromFile ) )

        if( !szDataFromFile[ 0 ] || szDataFromFile[ 0 ] == ';' || szDataFromFile[ 0 ] == '/' && szDataFromFile[ 1 ] == '/' )
            continue

        trim
        (
            szDataFromFile
        )
        parse
        (
            szDataFromFile,
            Data[ SzMaps], charsmax( Data[ SzMaps ] ),
            Data[ SzPlugins ], charsmax( Data[SzPlugins] )
        )

        if(debugger)
            server_print "Read %s,%i^n^nfrom file",Data[ SzMaps ], Data[ SzPlugins ]
        TrieSetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data )

    }
    fclose( f )
    if(debugger)
        server_print "................Safe Mode init file....................."
///////////////////////////////////////////////////////////////////////////////////////////////////
    new szFilePathSafe[ MAX_CMD_LENGTH ]

    get_mapname(mname, charsmax(mname));
    server_print "[%s]map name is %s", PLUGIN, mname

    Data[ SzMaps ] = mname

    if(TrieGetArray( g_SafeMode, Data[ SzMaps ], Data, sizeof Data ))
    {
        set_pcvar_num(Xsafe, 1)
    }
    else
    {
        set_pcvar_num(Xsafe, 0)
    }

    get_configsdir( szFilePath, charsmax( szFilePath ) )
    copy(szFilePathSafe,charsmax(szFilePathSafe),szFilePath)

    add( szFilePath, charsmax( szFilePath ), "/plugins.ini" )
    add( szFilePathSafe, charsmax( szFilePathSafe ), "/plugins.ini.safe" )

    new f2 = fopen( szFilePathSafe, "r" )

    if(!f2 && get_pcvar_num(Xsafe))
    {
        rename_file(szFilePath,szFilePathSafe,1)
        server_print "trying save^n^n%s", szFilePathSafe
        formatex(SzSave,charsmax(SzSave),"%s.amxx", PLUGIN)

        write_file(szFilePath, SzSave)

        write_file(szFilePath, Data[ SzPlugins ])

        client_print 0,print_chat, "reloading %s", mname
        server_print"reloading %s", mname

        set_task(1.0,"@reload_map",2021,mname,charsmax(mname))

    }

    else if(!f2 && !get_pcvar_num(Xsafe))
        server_print "File not found and safemode is off!"

    else if(f2 && get_pcvar_num(Xsafe))
        server_print "File found and safemode is on!"

    else
    {
        server_print "File found. Renaming"
        rename_file(szFilePathSafe,szFilePath,1)
    }

}

public plugin_cfg()
{
    ReadSafeModeFromFile( )
}
