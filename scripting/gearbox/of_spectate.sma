#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#define MAX_PLAYERS                                  32
#define MAX_RESOURCE_PATH_LENGTH  64
#define MAX_MENU_LENGTH                     512
#define MAX_NAME_LENGTH                     32
#define MAX_AUTHID_LENGTH                  64
#define MAX_IP_LENGTH                             16
#define MAX_USER_INFO_LENGTH            256
#define charsmin                                            -1

#define PLUGIN "OF spectator"
#define VERSION "1.0.1"
#define AUTHOR ".sρiηX҉."

#define MOTD    1337

//heads up display char gen
#define HUD_PLACE1 random_float(-0.75,-1.10),random_float(0.25,0.50)
#define HUD_PLACE2 random_float(0.75,2.10),random_float(-0.25,-1.50)

#define OK if(is_user_connected(id)
new bool:g_spectating[MAX_PLAYERS]
new bool:g_bFlagMap
new g_spec_msg, g_iHeadcount, g_players[ MAX_PLAYERS ]
new g_motd[MAX_RESOURCE_PATH_LENGTH]
new const DIC[] = "of_spectate.txt"
new g_iViewtype[MAX_PLAYERS] 
new g_startaspec

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    if(!lang_exists(DIC))

        register_dictionary(DIC);

    else

    {
        log_amx("%s %s by %s paused to prevent data key leakage from missing %s.", PLUGIN, VERSION, AUTHOR, DIC);
        pause "a";
    }
    new mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname));
    g_bFlagMap = containi(mname,"op4c") > charsmin?true:false
/*
    if(g_bFlagMap)
        pause "a"
*/
    server_print("Loading %s.", PLUGIN)
    register_concmd("say !spec","@go_spec",0,"spectate|rejoin")
    register_concmd("!spec_switch","random_view",0,"spectate random")
    g_startaspec = register_cvar("sv_spectate_spawn", "0")  //how many sec afk goes into spec mode
    g_spec_msg = register_cvar("sv_spectate_motd", "motd.txt")
    register_forward(FM_PlayerPreThink, "client_prethink");
    RegisterHam(Ham_Spawn, "player", "@play", 1);
}

public client_prethink( id )
{
    if(is_user_connected(id) && g_spectating[id])
    {
        //Remember!
        #define OBS_NONE                        0
        #define OBS_CHASE_LOCKED                1           // Locked Chase Cam
        #define OBS_CHASE_FREE                  2           // Free Chase Cam
        #define OBS_ROAMING                     3           // Free Look
        #define OBS_IN_EYE                      4           // First Person //attach_view(id,id)
        #define OBS_MAP_FREE                    5           // Free Overview
        #define OBS_MAP_CHASE                   6           // Chase Overview

        if( pev(id, pev_button) & IN_RELOAD)
        {
            set_pev(id, pev_iuser1, g_iViewtype[id])
            //switch(iView)
            {
                client_print id, print_center, "Trying spec %d", g_iViewtype[id]
                g_iViewtype[id]++  //cycle through the 6

                //reset back to one
                if(g_iViewtype[id] > 6 )
                {
                     client_print id, print_chat, "Reset spec counter %i", g_iViewtype[id] 
                     g_iViewtype[id]  = 0
                }
            }
        }
    }
}

@play(id)
{
    if(is_user_connected(id))
    set_task(2.0,"@reset",id)
    //@reset(id)
}

@reset(id)
{
    if(g_spectating[id] && is_user_connected(id) )
    {
        set_user_godmode(id,false)
        server_print "Spec mode reset for ^n%n",id
        g_spectating[id] = false
        set_view(id, CAMERA_NONE)
        console_cmd(id, "default_fov 100")
        new effects = pev(id, pev_effects)
        set_pev(id, pev_effects, (!effects | !EF_NODRAW | !FL_SPECTATOR | !FL_NOTARGET | !FL_PROXY | !FL_DORMANT));
        pev(id, pev_flags) & FL_CLIENT | FL_GRAPHED
    }
}
public client_putinserver(id)
OK)
{
        //if(!is_user_admin(id)) //with cvar later
        if(!g_bFlagMap)
        get_pcvar_num(g_startaspec) ? g_spectating[id] : g_spectating[id], set_task(1.0,"@go_spec",id)
}

@go_spec(id)
//if(!g_bFlagMap)
{
    OK)
    {
//        fm_strip_user_weapons(id)
        if(!is_user_bot(id) && !is_user_hltv(id))
        {
            fm_strip_user_weapons(id)
            if(!g_spectating[id])
            {
                dllfunc(DLLFunc_SpectatorConnect, id)
                server_print "GOING TO SPEC"
                g_spectating[id] = true
                set_user_info(id, "Spectator", "yes")
                //set_view(id, CAMERA_3RDPERSON)
                new effects = pev(id, pev_effects)
                set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET)) // | FL_PROXY | FL_DORMANT));
                console_cmd(id, "default_fov 150")
                get_pcvar_string(g_spec_msg, g_motd, charsmax(g_motd))
                set_user_godmode(id,true) //specs can be killed otherwise
                set_task(10.0,"@show_motd", id+MOTD) // too late comes up as they start playing which is off
                //inform client they are in spec
                set_task(10.0,"@update_player",id,_,_,"b")
            }
            else
            {
                server_print "EXITING SPEC"
                dllfunc(DLLFunc_ClientPutInServer, id)
                dllfunc(DLLFunc_SpectatorDisconnect, id)
                set_user_godmode(id,false)
                g_spectating[id] = false
                set_user_info(id, "Spectator", "no")
                //set_view(id, CAMERA_NONE)
                console_cmd(id, "default_fov 100")
                change_task(id, 60.0) //less spam
                remove_task(id+MOTD)

            }

        }

    }

}

@show_motd(value)
{
    new id = value - MOTD
    show_motd(id, g_motd, "SPECTATOR MODE")
}

@update_player(id)
if(is_user_connected(id) && !is_user_bot(id))
    //g_spectating[id] ? client_print(id,print_chat,"Spectator mode.^nSay !spec to play.") : client_print(id,print_chat,"Regular mode.^nSay !spec to spectate.")
    g_spectating[id] ? client_print(id,print_chat, "%L", LANG_PLAYER,"OF_SPEC_SPEC") : client_print(id, print_chat, "%L", LANG_PLAYER,"OF_SPEC_NORM")


public client_command(id)
{
    new szArg[MAX_PLAYERS];
    new szArgCmd[MAX_IP_LENGTH], szArgCmd1[MAX_IP_LENGTH];

    read_args(szArg, charsmax(szArg));
    read_argv(0,szArgCmd, charsmax(szArgCmd));
    read_argv(1,szArgCmd1, charsmax(szArgCmd1));

    if(g_spectating[id] == true && !equal(szArgCmd, "say") && !equal(szArgCmd1, "!spec") )
    {
        //client_print(id,print_center,"Spectator mode...")
        client_print(id,print_center, "%L", LANG_PLAYER,"OF_SPEC_HELO")

        #define HUD_RAN 0,0,random_num(0,255)
        #if AMXX_VERSION_NUM != 182
        set_dhudmessage(HUD_RAN,HUD_PLACE1,0,3.0,5.0,1.0,1.5);
        #endif
        set_hudmessage(HUD_RAN,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
        show_hudmessage(players_who_see_effects(),"%L", LANG_PLAYER, "OF_SPEC_HELO")
        //end HUD

        set_user_godmode(id,true)
        fm_strip_user_weapons(id)
        //client_print(id,print_chat,"Spectator mode.^nSay !spec to play.")
        client_print(id,print_chat, "%L", LANG_PLAYER,"OF_SPEC_SPEC")
        return PLUGIN_HANDLED_MAIN
    }
    return PLUGIN_CONTINUE
}

public random_view(id)
{
    new players[MAX_PLAYERS], playercount, viewable, ent;
    get_players(players,playercount,"i");

    for (viewable=1; viewable < playercount; viewable++)
    if(playercount > 1)
    ent = random_num(1,playercount+1)
    fm_attach_view(id,ent)
    engfunc(EngFunc_SetView, id, ent);
    return PLUGIN_HANDLED;
}
#if !defined client_disconnected
#define client_disconnect client_disconnected
#endif
public client_disconnected(id)
{
    if(task_exists(id))
        remove_task(id)
    g_spectating[id] = false
    id > 0 && id < 33 ?
    console_cmd(id, "default_fov 100") : server_print("Invalid client") 
}

stock players_who_see_effects()
{
    iPlayers()
    for (new SEE; SEE<g_iHeadcount; SEE++)
        return SEE;
    return PLUGIN_CONTINUE;
}

stock iPlayers()
{
    get_players(g_players, g_iHeadcount,"ch")
    return g_iHeadcount
}
