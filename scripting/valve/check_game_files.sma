#include amxmodx

static const szReason[]= "Your DLL game files are corrupted. Please Verify Integrity of Game Files."

public plugin()
{
    register_plugin("HL DLL CHECK", "1.1", ".sρiηX҉.");
}

public plugin_precache( )
{
    static mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name))
    if(equal(mod_name, "cstrike") || equal(mod_name, "czero") )
    {
        static const cs_dlls[][]={"dlls/cs_amd64.so","dlls/cs.dylib","dlls/cs.so","dlls/mp.dll"}
        for( new antihack;antihack < sizeof cs_dlls;antihack++ )
        {
            force_unmodified( force_exactfile, { 0, 0, 0 }, { 0, 0, 0 }, cs_dlls[antihack] );
        }
    }
    else if(equal(mod_name, "gearbox"))
    {
        static const of_dlls[][]={"dlls/opfor.dll","dlls/opfor.dylib","dlls/opfor.so"}
        for( new antihack;antihack < sizeof of_dlls;antihack++ )
        {
            force_unmodified( force_exactfile, { 0, 0, 0 }, { 0, 0, 0 }, of_dlls[antihack] );
        }
    }
    else if(equal(mod_name, "valve"))
    {
        static const hl_dlls[][]={"dlls/Director.dll", "dlls/director.dylib", "dlls/director.so", "dlls/hl.dll", "dlls/hl.dylib", "dlls/hl.so"/*,"decals.wad"*/}
        for( new antihack;antihack < sizeof hl_dlls;antihack++ )
        {
            force_unmodified( force_exactfile, { 0, 0, 0 }, { 0, 0, 0 }, hl_dlls[antihack] );
        }
    }
}

public inconsistent_file(id,const filename[],reason[MAX_AUTHID_LENGTH])
{
    static name[MAX_NAME_LENGTH], uid[MAX_AUTHID_LENGTH];
    if(is_user_connected(id))
    {
        get_user_authid(id,uid,charsmax(uid));get_user_name(id,name,charsmax(name))
        format(reason,charsmax(reason),szReason)
        log_to_file("Filecheck.log","FILECHECK:- Player Name: %s. SteamID: %s. Failed File: %s.",name,uid,filename)
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}
