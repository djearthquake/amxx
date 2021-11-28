/*Manually backup plugins.ini prior to using this script! USE AT YOUR OWN RISK!*/
///CVAR safe_mode 0|1 Run server without Amxx or any plugins then return back to normal mode
#include amxmodx
#include amxmisc
#define MAX_CMD_LENGTH             128
#define PLUGIN  "safe_mode"
new Xsafe
new SzSave[MAX_CMD_LENGTH]
public plugin_init()
{
    register_plugin(PLUGIN,"1.0", "SPiNX")
    Xsafe = register_cvar("safe_mode", "0")

    new szFilePath[ MAX_CMD_LENGTH ]
    new szFilePathSafe[ MAX_CMD_LENGTH ]

    get_configsdir( szFilePath, charsmax( szFilePath ) )
    copy(szFilePathSafe,charsmax(szFilePathSafe),szFilePath)

    add( szFilePath, charsmax( szFilePath ), "/plugins.ini" )
    add( szFilePathSafe, charsmax( szFilePathSafe ), "/plugins.ini.safe" )

    new f = fopen( szFilePathSafe, "r" )

    if(!f && get_pcvar_num(Xsafe))
    {
        rename_file(szFilePath,szFilePathSafe,1)
        server_print "trying save^n^n%s", szFilePathSafe
        formatex(SzSave,charsmax(SzSave),"%s.amxx", PLUGIN)
        write_file(szFilePath, SzSave)
    }
    else if(!f && !get_pcvar_num(Xsafe))
        server_print "File not found and safemode is off!"
    else if(f && get_pcvar_num(Xsafe))
        server_print "File found and safemode is on!"
    else
    {
        server_print "File found. Renaming"
        rename_file(szFilePathSafe,szFilePath,1)
    }

}
