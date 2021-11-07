/*
   Script voids, fixes. or overrides classname game_text.
   Creates modifiable, sv_gametxt "hello world", if you want with sv_gametxtfix 3.

   CVARS:
   sv_gametxtfix 0|1|2|3 void|fix|override|create
   sv_gametxt "Whatever you want as a message override"

   -Includes Map beach_head text fix and overall game_text creation.
*/

#include amxmodx
#include engine_stocks
#include fakemeta

public plugin_init()
{
    new game_text_pawn
    register_plugin("GAME_PLAYERJOIN REPLACE", "1.0", ".sρiηX҉.");

    #define HOLD DispatchKeyValue(game_text, "holdtime", "10.0")
    #define RIG  DispatchKeyValue(game_text, "message",
    #define VOID DispatchKeyValue(game_text, "targetname","")
    
    #define charsmin        -1
    #define MAX_CMD_LENGTH 128

    new SzBuffer[MAX_CMD_LENGTH]
    new const SzMsg[]= "This server is using Amxmodx\n\nComment out users.cfg localhost to avoid bot admin exploit on random players!"

    new Xcvar = register_cvar("sv_gametxt", SzMsg)
    new Xcvar_fix = register_cvar("sv_gametxtfix", "1")
    NEW_ENT:
    new game_text = find_ent(charsmin,"game_text")
    new adj_gametxt = get_pcvar_num(Xcvar_fix)

    new mname[MAX_PLAYERS];
    get_mapname(mname, charsmax(mname));

    if(game_text)
    {
        !adj_gametxt ? VOID /*Disable Msg.*/:DispatchKeyValue(game_text, "targetname", "game_playerjoin") /*Make it work as designed*/

        if(adj_gametxt > 1)
        {
            ///override stock map msg
            get_pcvar_string(Xcvar, SzBuffer, charsmax(SzBuffer))
            equali(SzBuffer, "") ? RIG SzMsg) &HOLD : RIG SzBuffer)
        }

        if (equali(mname,"beach_head"))
            @gametxt_param(game_text)

    }
    else if(adj_gametxt > 2)
    {
        //add to all maps?
        game_text_pawn = create_entity("game_text")
        dllfunc(DLLFunc_Spawn, game_text_pawn)
        @gametxt_param(game_text_pawn) //as there was nothing before
        goto NEW_ENT
        return
    }

}

@gametxt_param(game_text)
{
    DispatchKeyValue(game_text, "channel", "4")
    DispatchKeyValue(game_text, "y", "-1")
    DispatchKeyValue(game_text, "x", "0.1")
    DispatchKeyValue(game_text, "fxtime", ".5")
    DispatchKeyValue(game_text, "holdtime", "10")
    DispatchKeyValue(game_text, "fadeout", "4")
    DispatchKeyValue(game_text, "fadein", ".1")
    DispatchKeyValue(game_text, "color2", "238 234 49")
    DispatchKeyValue(game_text, "color", "17 78 236")
    DispatchKeyValue(game_text, "effect", "2")
    DispatchKeyValue(game_text, "spawnflags", "1") //repeat to all
