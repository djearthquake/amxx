/*
   Script voids, fixes. or overrides classname game_text.
   Creates modifiable, sv_gametxt "hello world", if you want with sv_gametxtfix 3.

   CVARS:
   sv_gametxtfix 0|1|2|3 void|fix|override|create
   sv_gametxt "Whatever you want as a message override"

   -Includes Map beach_head text fix and overall game_text creation.
   * 
   * 1.0 - 1.1: -Fix infinate loop on maps like aim_ak_colt3. Set this plugin on as default.
*/

#include amxmodx
//#include amxmisc
#include engine
#include engine_stocks
#include fakemeta

#define charsmin        -1
#define MAX_CMD_LENGTH 128
#define MAX_NAME_LENGTH 32
new g_value[ MAX_CMD_LENGTH ]
new bool:b_found_target

public plugin_init()
{
    new game_text_pawn
    register_plugin("GAME_PLAYERJOIN REPLACE", "1.1", ".sρiηX҉.");

    #define HOLD DispatchKeyValue(game_text, "holdtime", "10.0")
    #define RIG  DispatchKeyValue(game_text, "message",
    #define VOID DispatchKeyValue(game_text, "targetname","")

    new SzBuffer[MAX_CMD_LENGTH]
    new const SzMsg[]= "This server is using Amxmodx\n\nComment out users.cfg localhost to avoid bot admin exploit on random players!"

    new Xcvar = register_cvar("sv_gametxt", SzMsg)
    new Xcvar_fix = register_cvar("sv_gametxtfix", "3")
    NEW_ENT:/*search for it*/
    new game_text = find_ent(charsmin,"game_text")
    new adj_gametxt = get_pcvar_num(Xcvar_fix)


    if(game_text)
    {
        if(!adj_gametxt)
            VOID /*Disable Msg.*/
        else  @multi_manager /*softer*/

        if(adj_gametxt > 1)
        {
            ///override stock map msg
            get_pcvar_string(Xcvar, SzBuffer, charsmax(SzBuffer))
            equali(SzBuffer, "") ? RIG SzMsg) &HOLD : RIG SzBuffer)
        }
        @gametxt_param(game_text)
    }
    else if(adj_gametxt > 2)
    {
        //add to all maps?
        if(!game_text)//Is it NOT there already?
        {
            //Make it
            game_text_pawn = create_entity("game_text")
            dllfunc(DLLFunc_Spawn, game_text_pawn)
            @gametxt_param(game_text_pawn) //as there was nothing before
            //look for it
            goto NEW_ENT
        }
    }

}

@gametxt_param(game_text)
{
    DispatchKeyValue(game_text, "channel", "3")
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

    if(!b_found_target) 
        DispatchKeyValue(game_text, "targetname", "temp_game") //for multimanager to time it instead of instant on join
}

@multi_manager()
{
    new const temp_tname[]="temp_game"
    new mm_ent = create_entity("multi_manager")

    if(equali(g_value,""))
        copy(g_value, charsmax(g_value), temp_tname)

    DispatchKeyValue(mm_ent, g_value, "5")
    DispatchKeyValue(mm_ent, "targetname", "game_playerjoin")
    DispatchKeyValue(mm_ent, "spawnflags", "1")
    dllfunc(DLLFunc_Spawn, mm_ent)
}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(equali(Classname, "game_text") && equali(key, "targetname") && equali(value, "game_playerjoin") )
    {
        copy(g_value, charsmax(g_value), value)
        DispatchKeyValue("targetname", "game_playerspawn")
        server_print "game_text targetname is %s", g_value
        log_amx "game_text targetname is %s", g_value
        b_found_target = true
        return
    }
    else if(equali(Classname, "game_text") && equali(key, "targetname") && !equali(value, "game_playerjoin") )
    {
        if(equali(Classname, "game_text") && equali(key, "message"))
        {
        copy(g_value, charsmax(g_value), value)
        server_print "game_text %s", g_value
        log_amx "game_text is %s", g_value
        b_found_target = true
        return
        }
    }
}

/*
    NOTES
    DispatchKeyValue(mm_ent, "text" "2")                        //targetname of textmsg   _________ target of repeatable task and how long 2 sec
    DispatchKeyValue(mm_ent, "targetname" "game_playerjoin")    //what triggers it  ____ client_putinserver
    DispatchKeyValue(mm_ent, "spawnflags" "1")                  //broadcast to all
*/
