#include amxmodx
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

#define OK if(is_user_connected(id)
new bool:g_spectating[MAX_PLAYERS]
new g_spec_msg
new g_motd[MAX_RESOURCE_PATH_LENGTH]


new g_startaspec

public plugin_init()
{
    register_plugin("OF spectator","1.1", "SPiNX")
    register_concmd("say !spec","@go_spec",0,"spectate|rejoin")
    register_concmd("!spec_switch","random_view",0,"spectate random")
    g_startaspec = register_cvar("sv_spectate_spawn", "0")  //how many sec afk goes into spec mode
    g_spec_msg = register_cvar("sv_spectate_motd", "motd.txt")
    RegisterHam(Ham_Spawn, "player", "@play", 1);
}

@play(id)
{
    if(is_user_alive(id) && !is_user_bot(id))
    set_task(1.5,"@reset",id)
}

@reset(id)
{
    if(g_spectating[id] && is_user_connected(id) || is_user_hltv(id) && !is_user_bot(id) && !is_user_hltv(id))
    {
        set_user_godmode(id,false)
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
    get_pcvar_num(g_startaspec) ? g_spectating[id] : g_spectating[id], set_task(1.0,"@go_spec",id)
}

@go_spec(id)
{
    OK)
    {
        fm_strip_user_weapons(id)
        if(!is_user_bot(id) && !is_user_hltv(id))
        {
            if(!g_spectating[id])
            {
                dllfunc(DLLFunc_SpectatorConnect, id)
                server_print "GOING TO SPEC"
                g_spectating[id] = true
                set_user_info(id, "Spectator", "yes")
                set_view(id, CAMERA_3RDPERSON)
                new effects = pev(id, pev_effects)
                set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET | FL_PROXY | FL_DORMANT));
                console_cmd(id, "default_fov 150")
                get_pcvar_string(g_spec_msg, g_motd, charsmax(g_motd))
                set_user_godmode(id,true) //specs can be killed otherwise
                set_task(3.0,"@show_motd", id)
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
                set_view(id, CAMERA_NONE)
                console_cmd(id, "default_fov 100")
                change_task(id, 60.0) //less spam

            }

        }

    }

}

@show_motd(id)show_motd(id, g_motd, "SPECTATOR MODE")

@update_player(id)
if(is_user_connected(id))
    g_spectating[id] ? client_print(id,print_chat,"Spectator mode.^nSay !spec to play.") : client_print(id,print_chat,"Regular mode.^nSay !spec to spectate.")

public client_command(id)
{
    new szArg[MAX_IP_LENGTH];
    new szArgCmd[MAX_IP_LENGTH], szArgCmd1[MAX_IP_LENGTH];

    read_args(szArg, charsmax(szArg));
    read_argv(0,szArgCmd, charsmax(szArgCmd));
    read_argv(1,szArgCmd1, charsmax(szArgCmd1));

    if(g_spectating[id] == true && !equal(szArgCmd, "say") && !equal(szArgCmd1, "!spec") )
    {
        client_print(id,print_center,"Spectator mode...")
        set_user_godmode(id,true)
        fm_strip_user_weapons(id)
        client_print(id,print_chat,"Spectator mode.^nSay !spec to play.")
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
