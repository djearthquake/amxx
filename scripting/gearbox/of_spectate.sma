#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#define MAX_PLAYERS                    32
#define MAX_RESOURCE_PATH_LENGTH       64
#define MAX_MENU_LENGTH                512
#define MAX_NAME_LENGTH                32
#define MAX_AUTHID_LENGTH              64
#define MAX_IP_LENGTH                  16
#define MAX_USER_INFO_LENGTH           256
#define charsmin                      -1

#define PLUGIN "OF spectator"
#define VERSION "1.0.4"
#define AUTHOR ".sρiηX҉."

#define MOTD    1337
#define RESET    1999
#define TOGGLE 2022

//heads up display char gen
#define HUD_PLACE1 random_float(-0.75,-1.10),random_float(0.25,0.50)
#define HUD_PLACE2 random_float(0.75,2.10),random_float(-0.25,-1.50)

#define OK if(is_user_connected(id)

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new g_AI /*,maxplayers*/
new bool:g_spectating[MAX_PLAYERS + 1]
new bool:bDemo[MAX_PLAYERS +1]
new bool:bAlready_shown_menu[MAX_PLAYERS + 1]
new bool:bListening[MAX_PLAYERS + 1]
new bool:bFirstPerson[MAX_PLAYERS + 1]
new bool:g_bRenderApplied[MAX_PLAYERS + 1]
new bool:g_bFlagMap
new g_random_view[MAX_PLAYERS+1]
new g_spec_msg, g_iHeadcount, g_players[ MAX_PLAYERS ], g_cvar_nametag
new g_motd[MAX_RESOURCE_PATH_LENGTH]
new const DIC[] = "of_spectate.txt"
new Float:g_user_origin[MAX_PLAYERS + 1][3]

new g_iViewtype[MAX_PLAYERS + 1]

new g_startaspec, cvar_gg
new bool:g_bGunGameRunning, bool:g_bGrenadesOnlyRunning
new bool:g_bSpecNam[MAX_PLAYERS + 1]
new SzSpecName[MAX_PLAYERS + 1][MAX_NAME_LENGTH]

new Float:g_Angles[MAX_PLAYERS + 1][3], Float:g_Plane[MAX_PLAYERS + 1][3], Float:g_Punch[MAX_PLAYERS + 1][3], Float:g_Vangle[MAX_PLAYERS + 1][3], Float:g_Mdir[MAX_PLAYERS + 1][3]
new /*Float:g_Velocity[MAX_PLAYERS + 1][3],*/ g_Duck[MAX_PLAYERS + 1], g_BackPack[MAX_PLAYERS + 1]

new SzClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH]

#define IS_THERE (~(0<<IN_SCORE))

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
    if(is_plugin_loaded("grenades_only.amxx",true)!=charsmin)
    {
        g_bGrenadesOnlyRunning = true
    }
    new mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname));
    g_bFlagMap = containi(mname,"op4c") > charsmin?true:false

    server_print("Loading %s.", PLUGIN)
    register_clcmd("!spec", "@menu", 0, "- Spectator Menu")
    register_concmd("say !spec","@go_spec",0,"spectate|rejoin")
    register_concmd("say !spec_switch","@switch_views",0,"spectate random")
    register_clcmd("!spec_switch", "@switch_views", 0, "- Spectator Menu")

    //g_startaspec = register_cvar("sv_spectate_spawn", "0")  //how many sec afk goes into spec mode

    bind_pcvar_num( create_cvar("sv_spectate_spawn", "0", FCVAR_NONE, "OF SPEC",.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 60.0),  g_startaspec )
    bind_pcvar_num( create_cvar("mp_spectag", "1", FCVAR_NONE, "SPEC TAG",.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0), g_cvar_nametag )
    g_spec_msg = register_cvar("sv_spectate_motd", "motd.txt")

    register_forward(FM_PlayerPreThink, "client_prethink", 0);
    register_forward(FM_AddToFullPack, "fwdAddToFullPack_Post", 1)
    register_event("WeapPickup", "@strip_spec", "bef")

    //RegisterHam(Ham_Spawn, "player", "@play", 1); //ents can disappear on map start.
    register_event("ResetHUD", "@play", "b")
    register_clcmd("say", "handle_say")
    ///set_task_ex(11.0,"plugin_end", 84151, .flags = SetTask_BeforeMapChange)
    //maxplayers = get_maxplayers()
}

/*
public plugin_end()
{
    for(new id = 1 ; id <= maxplayers ; ++id)
    if(containi(SzSpecName[id], "[s]") != charsmin)
    {
        if(containi(SzClientName[id], "[s]") == charsmin)
        {
            set_user_info(id, "name", SzClientName[id])
        }
        else
        {
            replace(SzClientName[id], charsmax(SzClientName[]), "[s]", "")
            set_user_info(id, "name", SzClientName[id])
        }
    }
}
*/

public handle_say(id, blah[MAX_USER_INFO_LENGTH])
{
    OK && g_cvar_nametag)
    {
        static reblah[MAX_USER_INFO_LENGTH]
        read_args(blah,charsmax(blah))
        remove_quotes(blah)

        if(g_spectating[id])
        {
            format(reblah, charsmax(reblah), "[Spectator]%n: %s", id, blah)
            client_print 0, print_chat, "%s", reblah
            return PLUGIN_HANDLED
        }

    }
    return PLUGIN_CONTINUE
}

@strip_spec(id)
{
    OK && bFirstPerson[id] && g_spectating[id] )
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
    OK)
    {
        if(!g_spectating[id])
        {
            pev(id, pev_origin, g_user_origin[id]);
            entity_get_vector(id, EV_VEC_angles, g_Angles[id]);
            entity_get_vector(id, EV_VEC_view_ofs, g_Plane[id]);
            entity_get_vector(id, EV_VEC_punchangle, g_Punch[id]);
            entity_get_vector(id, EV_VEC_v_angle, g_Vangle[id]);
            entity_get_vector(id, EV_VEC_movedir, g_Mdir[id]);

            if(CheckPlayerBit(g_AI, id))
                return
        }
        else
        {
            //Remember!
            #define OBS_NONE                        0
            #define OBS_CHASE_LOCKED                1           // Locked Chase Cam
            #define OBS_CHASE_FREE                  2           // Free Chase Cam
            #define OBS_ROAMING                     3           // Free Look
            #define OBS_IN_EYE                      4           // First Person //attach_view(id,id)
            #define OBS_MAP_FREE                    5           // Free Overview
            #define OBS_MAP_CHASE                   6           // Chase Overview

            if(pev(id, pev_button) & IN_SCORE)
            {
                static iTOS; iTOS = get_user_time(id)
                if(iTOS > 30 && iTOS < 120 )
                {
                    entity_get_vector(id, EV_VEC_v_angle, g_Vangle[id]);
                    client_print id, print_center, "%f|%f|%f^n^n%f|%f", g_user_origin[id][0], g_user_origin[id][1], g_user_origin[id][2], g_Vangle[id][0], g_Vangle[id][1]
                }
            }
/*
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
*/
            if(g_bGunGameRunning)
            {
                cvar_gg = get_cvar_pointer("gg_enabled")
                if(cvar_gg)
                {
                    //set_view(id, CAMERA_NONE)
                    fm_strip_user_weapons(id)
                    //entity_set_float(id, EV_FL_fov, 100.0)
                }
            }

            if(g_random_view[id])
            {
                set_pev(id, pev_origin, g_user_origin[g_random_view[id]])

                static effects; effects = pev(id, pev_effects)
                set_pev(id, pev_effects, (effects | EF_NODRAW))
                fm_strip_user_weapons(id)

                g_spectating[id] = true

                if(bFirstPerson[id])
                {
                    static iTarget; iTarget = g_random_view[id]
                    if(is_user_connected(iTarget)) //needs checked here as index was made up!
                    {
                        //attach_view(id, iTarget);
                        set_view(id, CAMERA_NONE)
                        entity_set_float(id, EV_FL_fov, 100.0)

                        entity_set_vector(id, EV_VEC_angles, g_Angles[iTarget]);
                        entity_set_vector(id, EV_VEC_view_ofs, g_Plane[iTarget]);
                        entity_set_vector(id, EV_VEC_punchangle, g_Punch[iTarget]);
                        entity_set_vector(id, EV_VEC_v_angle, g_Vangle[iTarget]);
                        entity_set_vector(id, EV_VEC_movedir, g_Mdir[iTarget]);

                        //trace_line(0, g_Plane[id], g_Plane[iTarget], g_Velocity[iTarget])
                        entity_set_int( id, EV_INT_fixangle, 1 )
                        if(loss() > 2) //MAKE CVAR
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
    static iPing,iLoss
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"i")

    for(new lot;lot < sizeof players;lot++)
        get_user_ping(players[lot],iPing,iLoss)

    return iLoss
}

@play(id)
{
    OK)
    {
        if(CheckPlayerBit(g_AI, id))
            return
        //server_print "%n spectator mode is resetting.", id

        client_cmd id,"spk valve/sound/UI/buttonclick.wav"

        if(g_startaspec)
            set_task(2.0,"@reset", id+RESET)

        if(task_exists(id+MOTD))
            remove_task(id + MOTD)

        if(task_exists(id + TOGGLE))
            remove_task(id + TOGGLE)

        if(g_bSpecNam[id])
        {
            set_user_info(id, "name", SzClientName[id])
            g_bSpecNam[id] = false
        }
        set_view(id, CAMERA_NONE)
    }
}

@reset(Tsk)
{
    static id; id = Tsk - RESET
    OK)
    if(g_spectating[id])
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

        static effects; effects = pev(id, pev_effects)
        set_pev(id, pev_effects, (effects | ~EF_NODRAW))

        static flags; flags = pev(id, pev_flags)
        set_pev(id, pev_flags, (flags | ~FL_SPECTATOR | ~FL_NOTARGET | ~FL_PROXY  | ~FL_PROXY | ~FL_CUSTOMENTITY))
        //set_pev(id, pev_flags, (flags | ~FL_SPECTATOR))
    }
}

public client_putinserver(id)
{
    OK)
    {
        is_user_bot(id) ? (SetPlayerBit(g_AI, id)) : (ClearPlayerBit(g_AI, id))

        g_spectating[id] = false
        bAlready_shown_menu[id] = false
        g_random_view[id] = 0

        if(CheckPlayerBit(g_AI, id))
            return

        set_task(3.0,"@clear_menu", id)

        static szSpec[4]
        get_user_info(id,"spectate", szSpec, charsmax(szSpec))

        if(equali(szSpec, "1"))
        {
            dllfunc(DLLFunc_ClientPutInServer, id)
            @go_spec(id)
        }

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
}

public client_connectex(id, const name[], const ip[], reason[128])
{
    copy(SzClientName[id],charsmax(SzClientName[]), name)
    if(containi(name, "[s]") > charsmin)
    {
        replace(SzClientName[id], charsmax(SzClientName[]), "[s]", "")
        set_user_info(id, "name", SzClientName[id])
    }
    g_spectating[id] = false
    return PLUGIN_CONTINUE
}

@go_check(id)
{
    OK)
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
    OK && pev_valid(id)>1)
    {
        static menu; menu = menu_create ("Spectate", "@spec_menu");

        menu_additem(menu, "PLAY/WATCH^n", "1");
        //if(g_spectating[id])
        menu_additem(menu, "Chase Cam/Free-look^n^n", "2")
        //if(g_random_view[id] && !bFirstPerson[id])
        menu_additem(menu, "First Person Chase Cam^n^n", "3")
        bFirstPerson[id] && CheckPlayerBit(g_AI, g_random_view[id]) ?
        menu_additem(menu, "Take-over Bot!^n^n^n^n", "4"):menu_additem(menu, "...^n^n^n^n^n", "5")

        menu_additem(menu, "Play/STOP song^n^n^n^n^n", "5")
        //if(!g_spectating[id])
        //menu_additem(menu, "New Map^n^n^n", "6")
        menu_additem(menu, "Toggle views^n^n^n", "6")
        menu_additem(menu, "LEAVE SERVER!^n", "7")
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0, 9);
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

@spec_menu(id, menu, item)
{
    OK && pev_valid(id)>1)
    {
        bAlready_shown_menu[id] = true
        /*
        static szSpec[4]
        get_user_info(id,"spectate", szSpec, charsmax(szSpec))

        if(equali(szSpec, "1"))
            g_spectating[id] = true
        */

        switch(item)
        {
            case 0:
            {
                @go_spec(id)
                if(g_spectating[id])
                    menu_display(id, menu, 0, 10);
            }
            case 1:
            {
                if(g_spectating[id])
                {
                    random_view(id)
                    bFirstPerson[id] = false
                    menu_display(id, menu, 0,15);
                }
                else
                {
                    client_print id, print_chat, "Must be spectating!"
                }
            }
            case 2:
            {
                if(g_spectating[id])
                {
                    bFirstPerson[id] = true
                    ///menu_display(id, menu, 0,15);
                }
                else
                {
                    client_print id, print_chat, "Must be spectating!"
                }
            }
            case 3:
            {
                if(g_spectating[id])
                {
                    static iTarget; iTarget = g_random_view[id]
                    if(bFirstPerson[id] && is_user_connected(iTarget)) //add take over AFK human next
                    {
                        if(CheckPlayerBit(g_AI, iTarget) || pev(iTarget, pev_button) & ~IS_THERE)
                        {
                            server_print "TAKING OVER BOT/ AFK PLAYER!"
                            g_Duck[iTarget] = entity_get_int(iTarget, EV_INT_bInDuck);
                            dllfunc(DLLFunc_ClientPutInServer, id)
                            dllfunc(DLLFunc_SpectatorDisconnect, id)
                            g_iViewtype[id]  = 0
                            g_spectating[id] = false
                            g_random_view[id] = 0
                            set_user_info(id, "_spec", "0")

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
                    }
                    else
                    {
                        client_print id, print_chat, "Must be in First Person view!"
                        menu_display(id, menu, 0,900);
                    }
                }
                else
                {
                    client_print id, print_chat, "Must be in First Person view!"
                }
            }
            case 4:
            {
                new Loop, iTrack; iTrack = random_num(1,27)
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
                //client_print id, print_chat, "Say rtv"
                @switch_views(id)
                menu_display(id, menu, 0,900);
            }
            case 6:
            {
                server_cmd "kick #%i", get_user_userid(id)
            }
        }
    }
    return PLUGIN_HANDLED
}


public client_infochanged(id)
{
    //name sync
    OK && !g_bSpecNam[id])
    {
        get_user_name(id, SzClientName[id], charsmax(SzClientName[]));
    }
}


@go_spec(id)
{
    static cvar_gg; cvar_gg = get_cvar_num("gg_enabled")
    OK)
    {
        if(~CheckPlayerBit(g_AI, id) || !is_user_hltv(id))
        {
            //if(pev(id, pev_button) & ~IS_THERE)
            {
                if(!g_spectating[id])
                {
                    //if(/*!g_bGunGameRunning*/)
                    {
                        if(!g_bSpecNam[id] && g_cvar_nametag > 1)
                        {
                            if(containi(SzClientName[id], "[s]") == charsmin)
                            {
                                format(SzSpecName[id], charsmax(SzSpecName[]), "[S]%s",SzClientName[id]);
                                set_user_info(id, "name", SzSpecName[id])
                                g_bSpecNam[id] = true
                            }
                        }
                        g_spectating[id] = true
                        static effects; effects = pev(id, pev_effects)

                        set_pev(id, pev_effects, (effects | EF_NODRAW))
                        static flags; flags = pev(id, pev_flags)
                        set_pev(id, pev_flags, (flags | FL_SPECTATOR | FL_NOTARGET | FL_PROXY | FL_CUSTOMENTITY))

                        dllfunc(DLLFunc_SpectatorConnect, id)

                        fm_strip_user_weapons(id)

                        server_print "%s GOING TO SPEC", SzClientName[id]

                        if(!bAlready_shown_menu[id])
                            @menu(id)

                        set_user_info(id, "_spec", "1")

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

                        if(g_bGrenadesOnlyRunning || g_bGunGameRunning)
                        {
                            if(g_spectating[id])
                            {
                                fm_strip_user_weapons(id)
                                if(cvar_gg)
                                    set_view(id, CAMERA_NONE)
                            }
                        }
                    }
                }
                else
                {
                    if(containi(SzSpecName[id], "[s]") != charsmin)
                    {
                        if(containi(SzClientName[id], "[s]") == charsmin)
                        {
                            set_user_info(id, "name", SzClientName[id])
                        }
                        else
                        {
                            replace(SzClientName[id], charsmax(SzClientName[]), "[s]", "")
                            set_user_info(id, "name", SzClientName[id])
                        }
                    }
                    server_print "%s EXITING SPEC", SzClientName[id]
                    dllfunc(DLLFunc_ClientPutInServer, id)
                    dllfunc(DLLFunc_SpectatorDisconnect, id)
                    g_iViewtype[id]  = 0
                    set_user_godmode(id,false)
                    g_spectating[id] = false
                    g_random_view[id] = 0
                    set_user_info(id, "_spec", "0")
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
    static id; id = value - MOTD
    OK)
    {
        show_motd(id, g_motd, "SPECTATOR MODE")
        client_cmd id,"spk ../../valve/sound/UI/buttonrollover.wav"
        set_task(30.0,"random_view", id)
    }
}

@update_player(id)
OK && ~CheckPlayerBit(g_AI, id))
    g_spectating[id] ? client_print(id,print_chat, "%L", LANG_PLAYER,"OF_SPEC_SPEC") : client_print(id, print_chat, "%L", LANG_PLAYER,"OF_SPEC_NORM")


public client_command(id)
{
    OK)
    {
        if(CheckPlayerBit(g_AI, id))
            goto SKIP
        static szArg[MAX_PLAYERS],
        szArgCmd[MAX_IP_LENGTH], szArgCmd1[MAX_IP_LENGTH];

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

                if( equal(szArgCmd, "menuselect")/*MENU ALLOWANCE*/ || equal(szArgCmd, "!spec_switch") || equal(szArgCmd, "amx_help") || equal(szArgCmd, ".")/*search alias*/ || equal(szArgCmd,"!spec"))
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
    OK && g_spectating[id] && ~CheckPlayerBit(g_AI, id))
    {
        if(!g_random_view[id])
        {
            set_task(0.5,"@random_view",id+TOGGLE,.flags = "b")
            if(!bDemo[id])
            {
                client_cmd id, "spk holo/tr_ba_use.wav"
            }
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

@switch_views(id)
{
    OK && g_spectating[id] && ~CheckPlayerBit(g_AI, id))
    {
        task_exists(id+TOGGLE) ? change_task(id+TOGGLE, 0.3)
        :
        set_task(0.5,"@random_view",id+TOGGLE,.flags = "b")
    }
    return PLUGIN_HANDLED;
}

@random_view(Tsk)
{
    static id; id = Tsk - TOGGLE
    OK && g_spectating[id])
    {
        new players[MAX_PLAYERS], playercount, viewable, iViewPlayer;
        get_players(players,playercount,"i");

        for (viewable=0; viewable < playercount; ++viewable)
        if(playercount > 1 && !g_random_view[viewable])
        {
            iViewPlayer = random_num(1,playercount+1) //make new menu instead of this shortcut
            if(is_user_connected(iViewPlayer))
            if( id != iViewPlayer && (pev(iViewPlayer, pev_button) & IS_THERE) && (pev(iViewPlayer, pev_oldbuttons) & IS_THERE) )
            {
                set_view(id, CAMERA_3RDPERSON)
                client_print(id, print_chat,"Trying random view on %n", iViewPlayer)
                if(!bDemo[id])
                {
                    bDemo[id] = true
                    client_cmd(id,"spk fvox/targetting_system.wav")
                }
                if(task_exists(id + TOGGLE))
                    remove_task(id + TOGGLE)
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
    ///if(!is_user_connected(id) && !is_user_connecting(id))
    {
        g_spectating[id] = false
        bAlready_shown_menu[id] = false
        g_random_view[id] = 0
    }
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
    OK)
    {
        static menu; menu = menu_create ("Menu cleaner", "@menu2");
        menu_additem(menu, "Server menu reset", "1");
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0,1)
        client_cmd id, "slot1"
    }

}

@menu2(id, menu, item)
{
    OK)
    {
        menu_destroy(menu)
    }
    return PLUGIN_HANDLED
}
