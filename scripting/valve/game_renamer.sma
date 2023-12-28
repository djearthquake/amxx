/*Troubles? Use map command to change map to make it work.*/
#include <amxmodx>
#include <fakemeta>
#define MAX_NAME_LENGTH 32
#define MAX_RESOURCE_PATH_LENGTH   64
#define charsmin -1

static amx_gamename[MAX_RESOURCE_PATH_LENGTH];
static fw_game_renamer

new const CvarDesc[]="Rename GAME field!"

public plugin_init( ) {
    register_plugin( "Game Namer", "1.2", "NeuroToxin|SPiNX" );

    bind_pcvar_string(get_cvar_pointer("amx_gamename") ?
    get_cvar_pointer("amx_gamename") :
    create_cvar("amx_gamename", "", FCVAR_NONE, CvarDesc), amx_gamename, charsmax(amx_gamename));

    if(!equali(amx_gamename,""))/*Set something up in server.cfg or amxx.cfg*/
        fw_game_renamer = register_forward( FM_GetGameDescription, "GameDesc", false );
}

public GameDesc( ) {
    forward_return( FMV_STRING, amx_gamename );
    return FMRES_SUPERCEDE;
}

public plugin_end(){
    unregister_forward(FM_GetGameDescription, fw_game_renamer, false)
}
