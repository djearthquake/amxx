#include <amxmodx>
#include <amxmisc>
#include <geoip>
#include <sockets>
#include <json>

#define PLUGIN "ClientTemp Lite"
#define VERSION "1.0"
#define AUTHOR ".sρiηX҉."

#define MAX_PLAYERS 32
#define MAX_RESOURCE_PATH_LENGTH 64

#pragma semicolon 1

#if !defined geoip_code3_ex
#define geoip_code3_ex(%1,%2) geoip_code3(%1,%2)
#endif

new g_pcvar_key, g_pcvar_debug, g_pcvar_fx_time, g_HudSync;
new g_iChoice[MAX_PLAYERS + 1];
new g_iSocket[MAX_PLAYERS + 1];
new g_szGhostIP[MAX_PLAYERS + 1][MAX_PLAYERS];
new g_szGhostName[MAX_PLAYERS + 1][MAX_PLAYERS];
new g_word_buffer[MAX_RESOURCE_PATH_LENGTH];

static const faren_country[][] = {"BHS", "CYM", "LBR", "PLW", "FSM", "MHL", "USA"};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pcvar_key = register_cvar("sv_openweather-key", "YOUR_KEY", FCVAR_PROTECTED);
    g_pcvar_debug = register_cvar("weather_debug", "0");
    g_pcvar_fx_time = register_cvar("sv_weather_fx_duration", "15.0");
    g_HudSync = CreateHudSyncObj();

    register_clcmd("say /weather", "cmd_weather");
}

public client_connect(id)
{
    if (is_user_bot(id))
    {
        return;
    }

    get_user_ip(id, g_szGhostIP[id], 31, 1);
    get_user_name(id, g_szGhostName[id], 31);

    new iPos = contain(g_szGhostIP[id], ":");
    if (iPos != -1)
    {
        g_szGhostIP[id][iPos] = '^0';
    }

    g_iChoice[id] = 0;
    g_iSocket[id] = 0;
}

public client_putinserver(id)
{
    if (is_user_bot(id))
    {
        return;
    }
    set_task(10.0, "ShowWeatherMenu", id);
}

public cmd_weather(id)
{
    ShowWeatherMenu(id);
    return PLUGIN_HANDLED;
}

public ShowWeatherMenu(id)
{
    if (!is_user_connected(id))
    {
        return;
    }

    new menu = menu_create("\yDisplay local weather?", "menu_handler");
    menu_additem(menu, "Private (HUD + Vox + FX)", "1");
    menu_additem(menu, "Global (Chat + HUD + FX)", "2");
    menu_display(id, menu, 0);
}

public menu_handler(id, menu, item)
{
    if (item >= 0 && is_user_connected(id))
    {
        new szDataStr[6], iName[MAX_RESOURCE_PATH_LENGTH], iAccess, iCallback;
        menu_item_getinfo(menu, item, iAccess, szDataStr, charsmax(szDataStr), iName, charsmax(iName), iCallback);
        g_iChoice[id] = str_to_num(szDataStr);
        fetch_weather(id);
    }
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public fetch_weather(id)
{
    new iError;
    g_iSocket[id] = socket_open("api.openweathermap.org", 80, SOCKET_TCP, iError);

    if (iError > 0 || g_iSocket[id] <= 0)
    {
        return;
    }

    new szKey[MAX_RESOURCE_PATH_LENGTH], szCountry[4], szUnit[16], szRequest[512];
    get_pcvar_string(g_pcvar_key, szKey, charsmax(szKey));

    geoip_code3_ex(g_szGhostIP[id], szCountry);
    copy(szUnit, charsmax(szUnit), "metric");

    for (new i = 0; i < sizeof faren_country; i++)
    {
        if (equal(szCountry, faren_country[i]))
        {
            copy(szUnit, charsmax(szUnit), "imperial");
            break;
        }
    }

    formatex(szRequest, charsmax(szRequest), "GET /data/2.5/weather?lat=%f&lon=%f&units=%s&appid=%s HTTP/1.1^r^nHost: api.openweathermap.org^r^nUser-Agent: AMXModX-ANSI/1.10^r^nConnection: close^r^n^r^n",
        geoip_latitude(g_szGhostIP[id]), geoip_longitude(g_szGhostIP[id]), szUnit, szKey);

    socket_send(g_iSocket[id], szRequest, charsmax(szRequest));

    new iPing, iLoss;
    get_user_ping(id, iPing, iLoss);

    new Float:fWait = (float(iPing) / 500.0) + 1.2;
    if (fWait < 1.4) fWait = 1.4;

    set_task(fWait, "socket_read", id);
}

public socket_read(id)
{
    if (g_iSocket[id] <= 0)
    {
        return;
    }

    new szBuffer[2048];
    socket_recv(g_iSocket[id], szBuffer, charsmax(szBuffer));

    if (get_pcvar_num(g_pcvar_debug))
    {
        log_amx("[Weather Debug] Response: %s", szBuffer);
    }

    new iJsonStart = contain(szBuffer, "{");
    if (iJsonStart == -1)
    {
        socket_close(g_iSocket[id]);
        g_iSocket[id] = 0;
        return;
    }

    new JSON:szRoot = json_parse(szBuffer[iJsonStart]);
    if (szRoot != Invalid_JSON)
    {
        new JSON:szMain = json_object_get_value(szRoot, "main");
        new iTemp = floatround(json_object_get_real(szMain, "temp"));

        new JSON:szWeatherArr = json_object_get_value(szRoot, "weather");
        new JSON:szWeatherObj = json_array_get_value(szWeatherArr, 0);
        new szDesc[MAX_RESOURCE_PATH_LENGTH];
        json_object_get_string(szWeatherObj, "description", szDesc, charsmax(szDesc));

        new szCity
        [MAX_RESOURCE_PATH_LENGTH], szCountry[4], szUnitName[16], bool:isFaren = false;
        geoip_city(g_szGhostIP[id], szCity, charsmax(szCity));
        geoip_code3_ex(g_szGhostIP[id], szCountry);

        new r = 0, g = 255, b = 0;
        copy(szUnitName, charsmax(szUnitName), "Celsius");

        for (new i = 0; i < sizeof faren_country; i++)
        {
            if (equal(szCountry, faren_country[i]))
            {
                copy(szUnitName, charsmax(szUnitName), "Fahrenheit");
                isFaren = true;
                break;
            }
        }

        if ((isFaren && iTemp >= 85) || (!isFaren && iTemp >= 30)) { r = 255; g = 50; b = 0; }
        else if (iTemp <= 0) { r = 0; g = 200; b = 255; }

        if (is_user_connected(id))
        {
            set_hudmessage(r, g, b, 0.05, 0.2, 0, 6.0, 15.0, 0.1, 0.2, -1);
            ShowSyncHudMsg(id, g_HudSync, "Local Temp: %d %s^nConditions: %s in %s", iTemp, szUnitName, szDesc, szCity);

            if (containi(szDesc, "snow") != -1) start_fx_loop(id, 1);
            else if (containi(szDesc, "rain") != -1) start_fx_loop(id, 2);
        }

        if (g_iChoice[id] == 2)
        {
            client_print(0, print_chat, "* %s's weather: %d %s (%s) in %s.", g_szGhostName[id], iTemp, szUnitName, szDesc, szCity);
        }

        num_to_word(abs(iTemp), g_word_buffer, charsmax(g_word_buffer));

        if (is_user_connected(id))
        {
            client_cmd(id, "spk ^"vox/temperature right now is %s degrees %s^"", g_word_buffer, (iTemp < 0) ? "sub zero" : "");
        }
        json_free(szRoot);
    }
    socket_close(g_iSocket[id]);
    g_iSocket[id] = 0;
}

public start_fx_loop(id, type)
{
    new iData[2];
    iData[0] = id;
    iData[1] = type;

    set_task(0.1, "WeatherLoop", id + 1000, iData, 2, "a", floatround(get_pcvar_float(g_pcvar_fx_time) * 5.0));
}

public WeatherLoop(const iData[])
{
    new id = iData[0];
    new type = iData[1];

    if (!is_user_connected(id)) return;

    new iOrigin[3];
    get_user_origin(id, iOrigin);

    message_begin((g_iChoice[id] == 2) ? MSG_PVS : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, (g_iChoice[id] == 2) ? iOrigin : {0,0,0}, id);
    write_byte(TE_PARTICLEBURST);
    write_coord(iOrigin[0]);
    write_coord(iOrigin[1]);
    write_coord(iOrigin[2] + 50);
    write_short(80);
    write_byte(type == 1 ? 255 : 252);
    write_byte(2);
    message_end();
}
