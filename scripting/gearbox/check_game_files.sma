#include amxmodx

new const dlls[][]={"dlls/opfor.dll","dlls/opfor.dylib","dlls/opfor.so"/*,"decals.wad"*/}
new const szReason[]= "Your DLL game files are corrupted."

public plugin()register_plugin("OF DLL CHECK", "1.0", ".sρiηX҉.");

public plugin_precache( ) 
    for( new antihack;antihack < sizeof dlls;antihack++ )
        force_unmodified( force_exactfile, { 0, 0, 0 }, { 0, 0, 0 }, dlls[antihack] );

public inconsistent_file(id,const filename[],reason[MAX_AUTHID_LENGTH])
{
    new name[MAX_NAME_LENGTH], uid[MAX_AUTHID_LENGTH];
    get_user_authid(id,uid,charsmax(uid));get_user_name(id,name,charsmax(name))
    format(reason,charsmax(reason),szReason)
    log_to_file("Filecheck.log","FILECHECK:- Player Name: %s. SteamID: %s. Failed File: %s.",name,uid,filename)
    return PLUGIN_CONTINUE
}
