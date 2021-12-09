#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_MENU_LENGTH            512
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH              16
#define MAX_USER_INFO_LENGTH       256
#define charsmin                  -1

#define OK if(is_user_connected(id) && !is_user_bot(id)
new bool:g_spectating[MAX_PLAYERS]
new g_spec_msg
new g_motd[MAX_RESOURCE_PATH_LENGTH]


new g_startaspec

public plugin_init()
{
    register_plugin("OF spectator","1.1", "SPiNX")
    register_concmd("say !spec","@go_spec",0,"spectate|rejoin")
    register_concmd("!spec","random_view",0,"spectate random")
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
    if(!g_spectating[id] && is_user_connected(id) && !is_user_bot(id))
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
OK)(get_pcvar_num(g_startaspec) ? g_spectating[id] : g_spectating[id], set_task(1.0,"@go_spec",id))

@go_spec(id)
{
    if(!is_user_bot(id))
    {
        fm_strip_user_weapons(id)
        OK)
        {
            if(g_spectating[id])
            {
                dllfunc(DLLFunc_SpectatorConnect, id)
    
                g_spectating[id] = false 
                set_view(id, CAMERA_3RDPERSON)
                //pev(id, pev_flags) & FL_SPECTATOR|FL_NOTARGET|FL_PROXY
                new effects = pev(id, pev_effects)
                set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET | FL_PROXY | FL_DORMANT));
                console_cmd(id, "default_fov 150")
                get_pcvar_string(g_spec_msg, g_motd, charsmax(g_motd))
                //formatex(motd, charsmax(motd), "")
                set_user_godmode(id,true) // I was killing specs while amusing it isn't ideal!!
                show_motd(id, g_motd, "SPECTATOR MODE")
                change_task(id, 10.0) //iform client they are in spec
            }
            else
            {
                dllfunc(DLLFunc_ClientPutInServer, id)
                dllfunc(DLLFunc_SpectatorDisconnect, id)
                set_user_godmode(id,false)
                g_spectating[id] = true
                set_view(id, CAMERA_NONE)
                console_cmd(id, "default_fov 100")
                change_task(id, 60.0) //less spam
            }
            set_task(30.0,"@update_player",id,_,_,"b")
        }
    
    }

}

@update_player(id)
if(is_user_connected(id))
    !g_spectating[id] ? client_print(id,print_chat,"Spectator mode.^nSay !spec to play.") : client_print(id,print_chat,"Regular mode.^nSay !spec to spectate.")

public random_view(id)
{
    new players[MAX_PLAYERS], playercount, viewable, ent;
    get_players(players,playercount,"i");

    for (viewable=0; viewable < playercount; viewable++)
    if(playercount > 1)
    ent = random_num(1,playercount)
    fm_attach_view(id,ent)
    engfunc(EngFunc_SetView, id, ent);
    return PLUGIN_HANDLED;
}
#if !defined client_disconnected
#define client_disconnect client_disconnected
#endif
public client_disconnected(id)
if(task_exists(id))
    remove_task(id)
