#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util

#define OK if(is_user_alive(id) && !is_user_bot(id)
new bool:g_spectating[MAX_PLAYERS]
new g_spec_msg
//new motd[MAX_MOTD_LENGTH]
new g_motd[MAX_RESOURCE_PATH_LENGTH]


new g_startaspec

public plugin_init()
{
    register_plugin("OF spectator","1.1", "SPiNX")
    register_concmd("say !spec","@go_spec",0,"spectate|rejoin")
    register_concmd("!spec","random_view",0,"spectate random")
    g_startaspec = register_cvar("sv_spectate_spawn", "0")
    g_spec_msg = register_cvar("sv_spectate_motd", "motd.txt")
}

public client_putinserver(id)
OK)(get_pcvar_num(g_startaspec) ? g_spectating[id] : g_spectating[id], set_task(1.0,"@go_spec",id))

@go_spec(id)
{
    OK)
    {
        if(g_spectating[id])
        {
            dllfunc(DLLFunc_SpectatorConnect, id)
            fm_strip_user_weapons(id)
            client_print(id,print_chat,"Spectator mode.^nSay !spec to play.")
            g_spectating[id] = false 
            set_view(id, CAMERA_3RDPERSON)
            new effects = pev(id, pev_effects)
            set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET | FL_PROXY | FL_DORMANT));
            console_cmd(id, "default_fov 150")


            get_pcvar_string(g_spec_msg, g_motd, charsmax(g_motd))
            show_motd(id, g_motd, "SPECTATOR MODE")
        }
        else
        {
            dllfunc(DLLFunc_ClientPutInServer, id)
            dllfunc(DLLFunc_SpectatorDisconnect, id)
            client_print(id,print_chat,"Regular mode.^nSay !spec to spectate.")
            g_spectating[id] = true
            set_view(id, CAMERA_NONE)
            console_cmd(id, "default_fov 100")
        }

    }

}


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