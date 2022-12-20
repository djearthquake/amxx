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
#define VERSION "1.0.3"
#define AUTHOR ".sρiηX҉."

#define MOTD    1337
#define RESET    1999
#define TOGGLE 2022

//heads up display char gen
#define HUD_PLACE1 random_float(-0.75,-1.10),random_float(0.25,0.50)
#define HUD_PLACE2 random_float(0.75,2.10),random_float(-0.25,-1.50)

#define OK if(is_user_connected(id)
new bool:g_spectating[MAX_PLAYERS+1]
new bool:bAlready_shown_menu[MAX_PLAYERS + 1]
new bool:bListening[MAX_PLAYERS + 1]
new bool:bFirstPerson[MAX_PLAYERS + 1]
new bool:g_bRenderApplied[MAX_PLAYERS + 1]
new bool:g_bFlagMap
new g_random_view[MAX_PLAYERS+1]
new g_spec_msg, g_iHeadcount, g_players[ MAX_PLAYERS ]
new g_motd[MAX_RESOURCE_PATH_LENGTH]
new const DIC[] = "of_spectate.txt"
new Float:g_user_origin[MAX_PLAYERS + 1][3]

new g_iViewtype[MAX_PLAYERS + 1]

new g_startaspec
new bool:g_bGunGameRunning

new Float:g_Angles[MAX_PLAYERS + 1][3], Float:g_Plane[MAX_PLAYERS + 1][3], Float:g_Punch[MAX_PLAYERS + 1][3], Float:g_Vangle[MAX_PLAYERS + 1][3], Float:g_Mdir[MAX_PLAYERS + 1][3]
new Float:g_Velocity[MAX_PLAYERS + 1][3], g_Duck[MAX_PLAYERS + 1], g_BackPack[MAX_PLAYERS + 1]

new SzClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH]

#define IS_THERE (~(1<<IN_SCORE))

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
    if(is_plugin_loaded("gungame.amxx",true)!=charsmin)
    {
        g_bGunGameRunning = true
        //pause "a";
    }
    new mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname));
    g_bFlagMap = containi(mname,"op4c") > charsmin?true:false

    server_print("Loading %s.", PLUGIN)
    register_clcmd("!spec", "@menu", 0, "- Spectator Menu")
    register_concmd("say !spec","@go_spec",0,"spectate|rejoin")
    register_concmd("say !spec_switch","random_view",0,"spectate random")

    //g_startaspec = register_cvar("sv_spectate_spawn", "0")  //how many sec afk goes into spec mode

    bind_pcvar_num( create_cvar("sv_spectate_spawn", "0", FCVAR_NONE, "OF SPEC",.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 60.0),  g_startaspec )
    g_spec_msg = register_cvar("sv_spectate_motd", "motd.txt")

    register_forward(FM_PlayerPreThink, "client_prethink", 0);
    register_forward(FM_AddToFullPack, "fwdAddToFullPack_Post", 1)
    register_event("WeapPickup", "@strip_spec", "bef")

    RegisterHam(Ham_Spawn, "player", "@play", 1);
}

@strip_spec(id)
{
    if( bFirstPerson[id] && g_spectating[id] )
    {
        fm_strip_user_weapons(id)
    }
}

public client_impulse(id)
{
    if(g_spectating[id])
        return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public client_prethink( id )
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        if(g_spectating[id] && !is_user_bot(id))
        {
            //Remember!
            #define OBS_NONE                        0
            #define OBS_CHASE_LOCKED                1           // Locked Chase Cam
            #define OBS_CHASE_FREE                  2           // Free Chase Cam
            #define OBS_ROAMING                     3           // Free Look
            #define OBS_IN_EYE                      4           // First Person //attach_view(id,id)
            #define OBS_MAP_FREE                    5           // Free Overview
            #define OBS_MAP_CHASE                   6           // Chase Overview

            ///if(get_user_time(id) < 30)
            if(pev(id, pev_button) & IN_SCORE)
            {
                entity_get_vector(id, EV_VEC_v_angle, g_Vangle[id]);
                client_print id, print_center, "%f|%f|%f^n^n%f|%f", g_user_origin[id][0], g_user_origin[id][1], g_user_origin[id][2], g_Vangle[id][0], g_Vangle[id][1]
            }

            if( pev(id, pev_button) & IN_RELOAD && is_user_admin(id))
            {
                //helps unsticking
                set_pev(id, pev_iuser1, g_iViewtype[id]) //not op4
                {
                    client_print id, print_center, "Trying spec %d.", g_iViewtype[id]
                    g_iViewtype[id]++  //cycle through the 6

                    //reset back to one
                    if(g_iViewtype[id] > 6 )
                    {
                         client_print id, print_chat, "Reset spec counter %i.", g_iViewtype[id]
                         g_iViewtype[id]  = 0
                    }
                }
            }

            if(g_bGunGameRunning)
            {
                if(g_spectating[id])
                {
                    fm_strip_user_weapons(id)
                    set_view(id, CAMERA_NONE)
                    entity_set_float(id, EV_FL_fov, 100.0)
                }
            }

            if(g_random_view[id])
            {
                set_pev(id, pev_origin, g_user_origin[g_random_view[id]])

                new effects = pev(id, pev_effects)
                set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET))

                g_spectating[id] = true

                if(bFirstPerson[id])
                {
                    new iTarget = g_random_view[id]
                    if(is_user_connected(iTarget)) //needs checked here as index was made up!
                    {
                        attach_view(id, iTarget);
                        set_view(id, CAMERA_NONE)
                        entity_set_float(id, EV_FL_fov, 100.0)

                        entity_set_vector(id, EV_VEC_angles, g_Angles[iTarget]);
                        entity_set_vector(id, EV_VEC_view_ofs, g_Plane[iTarget]);
                        entity_set_vector(id, EV_VEC_punchangle, g_Punch[iTarget]);
                        entity_set_vector(id, EV_VEC_v_angle, g_Vangle[iTarget]);
                        entity_set_vector(id, EV_VEC_movedir, g_Mdir[iTarget]);

                        //trace_line(0, g_Plane[id], g_Plane[iTarget], g_Velocity[iTarget])
                        entity_set_int( id, EV_INT_fixangle, 1 )
                        if(loss() > 1)
                        {
                            bFirstPerson[id] = false
                        }
                        else
                        {
                            g_bRenderApplied[iTarget] = true
                        }
                    }
                }
                else
                {
                    attach_view(id, id);
                    set_view(id, CAMERA_3RDPERSON)
                    entity_set_int( id, EV_INT_fixangle, 0 )
                    entity_set_float(id, EV_FL_fov, 150.0)
                }

            }
        }
        if(!is_user_connecting(id))
        {
            pev(id, pev_origin, g_user_origin[id]);
        }
        if(!g_spectating[id])
        {
            entity_get_vector(id, EV_VEC_angles, g_Angles[id]);
            entity_get_vector(id, EV_VEC_view_ofs, g_Plane[id]);
            entity_get_vector(id, EV_VEC_punchangle, g_Punch[id]);
            entity_get_vector(id, EV_VEC_v_angle, g_Vangle[id]);
            entity_get_vector(id, EV_VEC_movedir, g_Mdir[id]);
        }
    }
}

public fwdAddToFullPack_Post( es_handle, e, ent, host, hostflags, player, pset )
{
    if (!player)
        return FMRES_IGNORED;

    if( bFirstPerson[host] && host != ent )
    {
        if( ent == g_random_view[host]  && g_bRenderApplied[ent])
        {
            set_es(es_handle, ES_Effects, get_es(es_handle, ES_Effects) | EF_NODRAW)
        }

    }
    return FMRES_IGNORED;
}

stock loss()
{
    new iPing,iLoss
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"i")

    for(new lot;lot < sizeof players;lot++)
        get_user_ping(players[lot],iPing,iLoss)

    return iLoss
}

@play(id)
{
    if(is_user_connected(id))
    {
        console_print 0,"%n spectator mode is resetting.", id
        client_cmd id,"spk valve/sound/UI/buttonclick.wav"

        if(g_startaspec)
            set_task(2.0,"@reset", id+RESET)

        if(task_exists(id+MOTD))
            remove_task(id + MOTD)

        if(task_exists(id + TOGGLE))
            remove_task(id + TOGGLE)
    }

}

@reset(Tsk)
{
    new id = Tsk - RESET
    if(g_spectating[id] && is_user_connected(id) )
    {
        set_user_godmode(id,false)
        server_print "Spec mode reset for ^n%n",id

        if(task_exists(id+MOTD))
            remove_task(id + MOTD)

        if(task_exists(id))
            remove_task(id)

        g_spectating[id] = false
        set_view(id, CAMERA_NONE)
        entity_set_float(id, EV_FL_fov, 100.0)

        new effects = pev(id, pev_effects)
        set_pev(id, pev_effects, (!effects | !EF_NODRAW | !FL_SPECTATOR | !FL_NOTARGET));
        pev(id, pev_flags) & FL_CLIENT | FL_GRAPHED
/*
        if(g_bGunGameRunning)
        {
            fm_strip_user_weapons(id)
        }
*/
    }
}


public client_putinserver(id)
OK && !is_user_bot(id))
{
    if(!g_bFlagMap)
    {
        if(!g_startaspec)
        {
            if(g_spectating[id])
            {
                g_spectating[id] = false
            }

        }
        else
        {
            set_task(g_startaspec*1.0,"@go_check",id)
        }
    }
}

@go_check(id)
{
    if(is_user_connected(id))
    {
        server_print("spec check %n if AFK...", id)

        if(pev(id, pev_button) & IS_THERE & pev(id, pev_oldbuttons) & IS_THERE)
            return PLUGIN_HANDLED

        //@go_spec(id)
        if(!g_spectating[id])
        {
            set_task(10.0,"@go_spec",id)
            server_print("spec check %n IS AFK...", id)
        }
    }
    return PLUGIN_CONTINUE
}

@menu(id)
{
    if(is_user_connected(id))
    {
        new menu = menu_create ("Spectate", "@spec_menu");
        menu_additem(menu, "PLAY/WATCH^n", "1");
        menu_additem(menu, "Chase Cam/Free-look^n^n", "2")
        menu_additem(menu, "First Person Chase Cam^n^n", "3")
        menu_additem(menu, "Take-over Bot!^n^n^n^n", "4")
        menu_additem(menu, "Play/STOP song^n^n^n^n^n", "5")
        menu_additem(menu, "New Map(frags required)^n^n^n", "6")
        menu_additem(menu, "LEAVE SERVER!^n", "7")
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0, 900);
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

@spec_menu(id, menu, item)
{
    if(is_user_connected(id))
    {
        if(g_bGunGameRunning)
        {
            fm_strip_user_weapons(id)
        }
        bAlready_shown_menu[id] = true
        switch(item)
        {
            case 0:
            {
                @go_spec(id)
                if(g_spectating[id])
                    menu_display(id, menu, 0, 600);
            }
            case 1:
            {
                if(g_spectating[id])
                {
                    random_view(id)
                    bFirstPerson[id] = false
                    menu_display(id, menu, 0,900);
                }
            }
            case 2:
            {
                if(g_spectating[id])
                {
                    bFirstPerson[id] = true
                    menu_display(id, menu, 0,900);
                }
            }
            case 3:
            {
                if(g_spectating[id])
                {
                    new iTarget = g_random_view[id]
                    if(is_user_bot(iTarget) && bFirstPerson[id])
                    {
                        server_print "TAKING OVER BOT!"
                        g_Duck[iTarget] = entity_get_int(iTarget, EV_INT_bInDuck);
                        dllfunc(DLLFunc_ClientPutInServer, id)
                        dllfunc(DLLFunc_SpectatorDisconnect, id)
                        g_iViewtype[id]  = 0
                        g_spectating[id] = false
                        g_random_view[id] = 0
                        set_user_info(id, "spec", "0")

                        entity_set_float(id, EV_FL_fov, 100.0)
                        change_task(id, 60.0) //less spam
                        remove_task(id+MOTD)
                        entity_set_int(id, EV_INT_bInDuck, g_Duck[iTarget]);
                        entity_set_vector(id, EV_VEC_angles, g_Angles[iTarget]);
                        entity_set_vector(id, EV_VEC_view_ofs, g_Plane[iTarget]);
                        entity_set_vector(id, EV_VEC_punchangle, g_Punch[iTarget]);
                        entity_set_vector(id, EV_VEC_v_angle, g_Vangle[iTarget]);
                        entity_set_vector(id, EV_VEC_movedir, g_Mdir[iTarget]);

                        g_BackPack[iTarget] = entity_get_int(iTarget, EV_INT_weapons)
                        entity_set_int(id, EV_INT_weapons, g_BackPack[iTarget])


                        client_print id, print_chat, "%n took control of %n.", id, iTarget
                        set_pev(id, pev_origin, g_user_origin[iTarget]);
                        server_cmd( "kick #%d ^"Player took slot for being AFK!^"", get_user_userid(iTarget) );

                        set_user_godmode(id,false)
                        client_cmd 0, "spk debris/beamstart6.wav"
                    }
                    else
                        menu_display(id, menu, 0,900);
                }
            }
            case 4:
            {
                new Loop, iTrack = random_num(1,27)
                menu_display(id, menu, 0,300);
                if( bListening[id] )
                {
                    client_cmd id, "mp3 stop"
                    bListening[id] = false
                }
                else
                {
                    emessage_begin(MSG_ONE_UNRELIABLE,SVC_CDTRACK,{0,0,0},id);ewrite_byte(iTrack);ewrite_byte(Loop);emessage_end();
                    bListening[id] = true
                }

            }
            case 5:
            {
                client_cmd id, "say rtv"
            }
            case 6:
            {
                client_cmd id, "dropclient"
            }
        }
    }
    return PLUGIN_HANDLED
}

public client_infochanged(id)
{
    //name sync
    get_user_name(id, SzClientName[id], charsmax(SzClientName[]));
}

@go_spec(id)
{
    new SzSpecName[MAX_NAME_LENGTH]
    OK)
    {
        if(!is_user_bot(id) || !is_user_hltv(id))
        {
            //if(pev(id, pev_button) & ~IS_THERE)
            {
                fm_strip_user_weapons(id)
                if(!g_spectating[id])
                {
                    if(!g_bGunGameRunning)
                    {
                        get_user_name(id, SzClientName[id], charsmax(SzClientName[]));
                        format(SzSpecName, charsmax(SzSpecName), "[S]%s",SzClientName[id]);
                        set_user_info(id, "name", SzSpecName)

                        g_spectating[id] = true
                        dllfunc(DLLFunc_SpectatorConnect, id)
                        server_print "GOING TO SPEC"

                        if(!bAlready_shown_menu[id])
                            @menu(id)
    
                        set_user_info(id, "spec", "1")
                        new effects = pev(id, pev_effects)
                        set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET))
                        entity_set_float(id, EV_FL_fov, 150.0)
                        get_pcvar_string(g_spec_msg, g_motd, charsmax(g_motd))
                        set_user_godmode(id,true) //specs can be killed otherwise
                        set_task(10.0,"@show_motd", id+MOTD) // too late comes up as they start playing which is off
                        //inform client they are in spec
                        set_task(10.0,"@update_player",id,_,_,"b")
    
                        #define HUD_RAN 0,0,random_num(0,255)
                        #if AMXX_VERSION_NUM != 182
                        set_dhudmessage(HUD_RAN,HUD_PLACE1,0,3.0,5.0,1.0,1.5);
                        #endif
                        set_hudmessage(HUD_RAN,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
                        show_hudmessage(id,"%L", LANG_PLAYER, "OF_SPEC_HELO")
                    }
                }
                else
                {
                    set_user_info(id, "name", SzClientName[id])
                    server_print "EXITING SPEC"
                    dllfunc(DLLFunc_ClientPutInServer, id)
                    dllfunc(DLLFunc_SpectatorDisconnect, id)
                    g_iViewtype[id]  = 0
                    set_user_godmode(id,false)
                    g_spectating[id] = false
                    g_random_view[id] = 0
                    set_user_info(id, "spec", "0")
                    entity_set_float(id, EV_FL_fov, 100.0)
                    change_task(id, 60.0) //less spam
                    remove_task(id+MOTD)

                }
            }
        }
    }
}

@show_motd(value)
{
    new id = value - MOTD
    show_motd(id, g_motd, "SPECTATOR MODE")
    client_cmd id,"spk ../../valve/sound/UI/buttonrollover.wav"
    set_task(30.0,"random_view", id)
}

@update_player(id)
if(is_user_connected(id) && !is_user_bot(id))
    g_spectating[id] ? client_print(id,print_chat, "%L", LANG_PLAYER,"OF_SPEC_SPEC") : client_print(id, print_chat, "%L", LANG_PLAYER,"OF_SPEC_NORM")


public client_command(id)
{
    if(is_user_connected(id) && !is_user_bot(id))
    {
        new szArg[MAX_PLAYERS];
        new szArgCmd[MAX_IP_LENGTH], szArgCmd1[MAX_IP_LENGTH];

        read_args(szArg, charsmax(szArg));
        read_argv(0,szArgCmd, charsmax(szArgCmd));
        read_argv(1,szArgCmd1, charsmax(szArgCmd1));

        if(g_random_view[id] && !g_spectating[id])
            g_spectating[id] = true

        if(g_spectating[id])
            if( ( !equal(szArgCmd, "say")  && (!equal(szArgCmd1, "!spec") /*ok play/spec*/|| !equal(szArgCmd1, "!spec_switch" )) /*ok spec cam*/) )
            {
                set_user_godmode(id,true)
                fm_strip_user_weapons(id)

                if( equal(szArgCmd, "menuselect")/*MENU ALLOWANCE*/ || equal(szArgCmd, "amx_help") || equal(szArgCmd, ".")/*search alias*/ || equal(szArgCmd,"!spec"))
                    goto SKIP
                return PLUGIN_HANDLED_MAIN
            }
        SKIP:
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}
public random_view(id)
{
    if(is_user_connected(id) && g_spectating[id])
    {
        if(!task_exists(id+TOGGLE))
        {
            set_task(0.1,"@random_view",id+TOGGLE,.flags = "b")
            client_cmd id, "spk holo/tr_ba_use.wav"
        }
        else
        {
            g_random_view[id] = 0
            remove_task(id+TOGGLE)
            client_print(id, print_console,"Stopping spectator follow.")
            client_cmd id,"spk valve/sound/misc/talk.wav"
            client_print(id,print_center, "%L", LANG_PLAYER,"OF_SPEC_HELO")
            client_print(id,print_chat, "%L", LANG_PLAYER,"OF_SPEC_SPEC")
        }
    }
    return PLUGIN_HANDLED;
}

@random_view(Tsk)
{
    new id = Tsk - TOGGLE
    if(is_user_connected(id) && g_spectating[id])
    {
        new players[MAX_PLAYERS], playercount, viewable, iViewPlayer;
        get_players(players,playercount,"i");

        for (viewable=1; viewable < playercount; ++viewable)
        if(playercount > 1 && !g_random_view[id])
        {
            iViewPlayer = random_num(1,playercount+1)
            if( id != iViewPlayer && (pev(iViewPlayer, pev_button) & IS_THERE) && (pev(iViewPlayer, pev_oldbuttons) & IS_THERE) && is_user_connected(iViewPlayer) )
            {
                set_view(id, CAMERA_3RDPERSON)
                client_print(id, print_chat,"Trying random view on %n", iViewPlayer)
                client_cmd(id,"spk fvox/targetting_system.wav")
                client_print(id, print_chat, "Say !spec_switch to change perspectives.")
                //otherwise switches players randomly
                g_random_view[id] = iViewPlayer
                return PLUGIN_CONTINUE;
            }
        }
        else
        {
            set_pev(id, pev_origin, g_user_origin[g_random_view[id]]);
        }

    }
    else
    {
        if(task_exists(id + TOGGLE))
            remove_task(id + TOGGLE)
    }
    return PLUGIN_HANDLED

}

#if !defined client_disconnected
#define client_disconnect client_disconnected
#endif
public client_disconnected(id)
{
    if(task_exists(id))
        remove_task(id)

    g_spectating[id] = false
    bAlready_shown_menu[id] = false
    @clear_menu(id)

    id > 0 && id < 33 ?
        entity_set_float(id, EV_FL_fov, 100.0) : server_print("Invalid client")
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

@clear_menu(id)
{
    if(is_user_connected(id))
    {
        new menu = menu_create ("Menu cleaner", "@menu2");
        menu_additem(menu, "Server menu reset", "1");
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0,1);
    }

}

@menu2(id, menu, item)
{
    if(is_user_connected(id))
    {
        menu_destroy(menu)
    }
    return PLUGIN_HANDLED
}
