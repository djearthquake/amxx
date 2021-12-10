/*Manually backup plugins.ini prior to using this script! USE AT YOUR OWN RISK!*/
///CVAR safe_mode 0|1 Run server without Amxx or any plugins then return back to normal mode
#include amxmodx
#include amxmisc
#define MAX_NAME_LENGTH             64
#define MAX_CMD_LENGTH             128
#define PLUGIN  "safe_mode"
new Xsafe
new SzSave[MAX_CMD_LENGTH]
new mname[MAX_NAME_LENGTH]

//modify this until I update the plugin to run off ini for maps you do not want amxx to run on
new const unsafe_maps[][]=
{
    "de_jeepathon2k",
    "awp_map"
}

public plugin_init()
{
    register_plugin(PLUGIN,"1.0", "SPiNX")
    Xsafe = register_cvar("safe_mode", "0")
    get_mapname(mname, charsmax(mname));
    for(new list;list < sizeof unsafe_maps;++list)
    {
        if (!equali(mname, unsafe_maps[list]))
            set_pcvar_num(Xsafe, 0)
        else
        {
            set_pcvar_num(Xsafe, 1)
            if(get_pcvar_num(Xsafe))
                //server_cmd "amx_map %s",mname
                client_print 0,print_chat, "reloading %s", mname
            set_task(3.5,"@reload_map",2021,mname,charsmax(mname))
            return
        }

    }

}
@reload_map()
    server_cmd "amx_map %s",mname
    //flushes out Amxx

public plugin_cfg()
{
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

        //Essential plugins ...will update to ini later
        write_file(szFilePath, SzSave)
        write_file(szFilePath,"mapchooser.amxx")
        write_file(szFilePath,"nextmap.amxx")
        //write_file(szFilePath,"rtv.amxx")
        //write_file(szFilePath,"ping_telepathy.amxx")
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
