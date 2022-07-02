#include amxmodx
#include amxmisc
#include fakemeta

new bool:Is_Ufo_map
new g_CurrentMap[MAX_NAME_LENGTH];

new const SzHostName[] = "Bots vs. Humans"

new const Sz_BotsVHumansMaps[][]=
{
    "city_scope",
    "city_snow2",
    "op4_city"
}

public plugin_init()
{
    register_plugin("UFO settings","1.1","SPiNX");
    register_forward(FM_CVarSetFloat, "CVarSetFloat");

    get_mapname(g_CurrentMap, charsmax(g_CurrentMap) );
    for(new check;check < sizeof Sz_BotsVHumansMaps;check++)
    if(containi(g_CurrentMap,Sz_BotsVHumansMaps[check]) != -1)
    {
        Is_Ufo_map = true

        new check = get_cvar_pointer("mp_teamplay")
        if(!check)
        {
            log_amx "Reloading %s", g_CurrentMap
            server_cmd "changelevel %s", g_CurrentMap
        }
        set_teamplay()
    }
}

public plugin_end()
{
    new SzNextMap[MAX_NAME_LENGTH]
    get_cvar_string("amx_nextmap", SzNextMap, charsmax(SzNextMap))
    for(new ufo;ufo < sizeof Sz_BotsVHumansMaps;ufo++)
    {
        if(containi(SzNextMap,Sz_BotsVHumansMaps[ufo]) > -1)
        {
            server_cmd("mp_teamplay 1")
            return
        }
        server_cmd("mp_teamplay 0")
    }

}

public set_teamplay()
{
    server_cmd("mp_teamplay 1;mp_teamoverride 0");
    new auto = get_cvar_pointer("mp_teamplay")

    if(auto)
    {
        server_cmd "amxx pause fake_full"
        server_cmd "amxx pause autoconcom"
    }
}

public OnAutoConfigsBuffered()
{
    if(Is_Ufo_map)
        set_task_ex(9.0,"@custom_settings", 999, .flags = SetTask_Once);
}

@custom_settings()
{
    server_cmd("jk_botti min_bots 0;jk_botti max_bots 0;jk_botti team_balancetype 0;mp_timelimit 60");
    server_cmd("sv_clienttrace 9999.0");
    server_cmd("hostname ^"%s^" ", SzHostName);
}

public client_putinserver(id)
{
    if(Is_Ufo_map && !is_user_bot(id) && is_user_connected(id))
    {
        server_cmd("jk_botti min_bots 0;jk_botti max_bots 0");
        set_task(15.0, "ufo", 2022)
    }
}

public ufo()
{
    new numplayers = get_playersnum_ex(GetPlayers_IncludeConnecting|GetPlayers_ExcludeBots)

    numplayers > 0 && numplayers < 6 ? server_cmd("jk_botti min_bots %i;jk_botti max_bots %i", numplayers*2, numplayers*2) : server_cmd("jk_botti min_bots 0;jk_botti max_bots 0;HPB_Bot min_bots 0; HPB_Bot max_bots 0")
    if(numplayers >= 6)
        server_cmd "jk_botti min_bots %i;jk_botti max_bots %i", numplayers, numplayers
    server_cmd(numplayers > 5 ? "mp_fraglimit 100" : "mp_fraglimit 50")
}

public client_authorized(id, const authid[])
{
    if(Is_Ufo_map && is_user_connected(id))
        equali(authid,"BOT")  ? client_cmd(id, "model dalek_black") :  client_cmd(id, "model scientist")
}

public client_infochanged(id)
    @model(id)

public model_picker(id)
{
    new iSpawn_Protect = get_cvar_pointer("sv_sptime")
    iSpawn_Protect ? set_task(iSpawn_Protect+1.0,"@model", id) : @model(id)
}

@model(id)
{
    if(Is_Ufo_map && is_user_connected(id))
        is_user_bot(id)  ? client_cmd(id, "model dalek_black") :  client_cmd(id, "model scientist")
}
