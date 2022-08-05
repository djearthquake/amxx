/* 
 * Elements
 * 
 * CVARS:
 *  dark	<0-25> D: 24	| The higher the number, the darker after sunset.
 *  lums	<0-25> D: 0	| The lower the number, the brighter it gets at noon.
 *  time	<0-24> D: 0	| Manually sets timeOday 0 = off
 *  region	<region>	| "region" is "4887398&units=imperial&APPID=32bitcoderegisterfromopenweathermap.org" 
 *  uplink	<GET data URL>  | "uplink" is "GET /data/2.5/weather?id="
 *                                       
 *
 * CL_COMMANDS
 *
 * say temp, weather, or climate	- displays weather feed
 * say /mytemp for local temp
 * say /news for news
 */
#include <amxmodx>
#include <sockets>
#include <fakemeta>
#include <nvault>
#pragma semicolon 1
#pragma tabsize 0
#define PLUGIN	"Elements"
#define AUTHOR	"SPiNX" //inspired and modeled after TeddyDesTodes' Automatic weather (BBC).
#define VERSION	"4" //4 The snow steps got pruned out and code was indented in better form.
//#define DEBUG	//uncomment this for debug mode

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
#define fm_set_lights(%1)    engfunc(EngFunc_LightStyle, 0, %1)

#define Radian2Degree(%1) (%1 * 180.0 / M_PI)
const OFFSET_AMBIENCE = (1<<0);
new g_cvar_minlight, g_cvar_maxlight, g_cvar_region, g_cvar_uplink, g_cvar_time;
new g_sckelement, g_temp, g_curr_temp, g_temp_min, g_element, g_hum, g_heat, g_code, g_visi;
new g_env, g_fog, g_sunrise, g_sunset, g_location[32];
new g_vault;
new g_LightLevel[][]=   { "z","y","x","w","v","u","t","s","r","q","p","o","n","m","l","k","j","i","h","g","f","e","d","c","b","a" };
new g_env_name[][]=     { ""," ..::DRY::.. "," ..::WET::.. "," ..::ICE::.. " }; // APPLIED SIM: (1-3)(no rain, rain, snow)
new g_element_name[][]= { "","..fair..","..cloud..","..partial.." };
new g_skysuf[6][3]=     { "up", "dn", "ft", "bk", "lf", "rt" };

//        0       1      2      3       4
//     normal  sunrise  noon  sunset   night
new g_skynames[][] = {
       "sunny","3dm_bikini","ava","sunset1","52h03",     //SUNNY
       "52h05","nordawn","tornsky","blue","52h03",       //PARTLY CLOUDED
       "sunbeams_","morningdew","cx","st","paris_night", //CLOUDED
       "CCCP","CCCP","CCCP","dashnight256","CCCP"        //FOGGY
                     };
public plugin_init() {
        register_plugin(PLUGIN, VERSION, AUTHOR);
        register_cvar("element_version", VERSION, FCVAR_SERVER);
        register_clcmd("say /news", "ClCmd_NewS", 0, "<url>");
        register_clcmd("say /mytemp", "ClCmd_TemP", 0, "<url>");
        g_cvar_minlight = register_cvar("dark", "23");  //not too dark
        g_cvar_uplink = register_cvar("uplink", "GET /data/2.5/weather?id=");
        g_cvar_maxlight = register_cvar("lums", "0");  //vivid at noon
        g_cvar_time = register_cvar("time", "0");      //auto light
        g_cvar_region = register_cvar("region", "4887398&units=imperial&APPID=04cfbf74c089b9d44e1a32ccb4e5cf83");
        register_cvar("element_hud", "200");
        register_clcmd("say temp", "showinfo");
        register_clcmd("say weather", "showinfo");
        register_clcmd("say climate", "showinfo");
        get_element();
        daylight();
        set_task(15.0, "daylight", _, _, _, "b");
}
public ClCmd_NewS(id, level, cid) {
        new motd[512];
        format(motd, 511, "<html><meta http-equiv='Refresh' content='0; URL=https://4chan.org/'><body BGCOLOR='#FFFFFF'><br><center>Loading</center></HTML>");
        show_motd(id, motd, "International and local news");
}
public ClCmd_TemP(id, level, cid) {
        new motd[512];
        format(motd, 511, "<html><meta http-equiv='Refresh' content='0; URL=https://google.com/search?q=weather'><body BGCOLOR='#FFFFFF'><br><center>If we can not determine your country off your IP then this will display generic weather page...</center></HTML>");
        show_motd(id, motd, "Weather Browser");
}
public plugin_end() {
        nvault_close(g_vault);

}
public plugin_precache() {
        g_vault = nvault_open("element");
        makeelement();
}
public client_putinserver(id) {
        client_cmd(id, "cl_element 1");
        set_task(15.0, "daylight");
        if (!is_user_bot(id)) set_task(15.0, "display_info", id);
}

public display_info(id) {

        client_print(id, print_chat, "Say climate, temp, or weather for conditions.");
        client_print(id, print_chat, "Humidity, Clouds, Sunrise/Sunset all effect visibility.");
}

public showinfo(id) {

        set_hudmessage(250, 120, 200, -1.0, 0.55, 1, 2.0, 3.0, 0.7, 0.8, -1);
        show_hudmessage(id, "Location: %s^nReal Temp: %d  Forecasted: %d ^nSim:%s%s ^nHumidity: %d ^n^n^n^nCS1.6|Say /news /mytemp for more.", g_location, g_heat, g_curr_temp, g_env_name[g_env], g_element_name[g_element], g_hum);
        client_print(id, print_console, "Welcome to %s! Visibility is %d'. Temperature is %d while forecasted to be %d degrees.", g_location, g_visi, g_heat, g_curr_temp);
        client_print(id, print_console, "|||||||||||code %d||||||||||Element: %s%s | humidity: %d | dawn %d dusk %d", g_code, g_env_name[g_env], g_element_name[g_element], g_hum, g_sunrise, g_sunset);
}

public get_element() {
        #if defined DEBUG
        log_amx("Starting the sockets routine...");
        #endif
        new error, constring[512], uplink[25], region[63];
        get_pcvar_string(g_cvar_region, region, 63);
        get_pcvar_string(g_cvar_uplink, uplink, 25);
        g_sckelement = socket_open("api.openweathermap.org", 80, SOCKET_TCP, error);
        format(constring, 511, "%s%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n", uplink, region);
        write_web(constring);
        #if defined DEBUG
        log_amx("This is where we are trying to get weather from");
        log_amx(constring);
        log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
        #endif
        read_web();
}

public write_web(text[512])

socket_send(g_sckelement, text, 511);

public read_web(){
        new buf[512];
        socket_recv(g_sckelement, buf, 511);
        if (!equal(buf, "")) {
        if (containi(buf, "name") >= 0) {
        new out[32];
        copyc(out, 32, buf[containi(buf, "name") + 7], '"');

        #if defined DEBUG
        log_amx("Position: %s", out);
        #endif
        nvault_set(g_vault, "location", out);
        g_location = out;
}
        if (containi(buf, "temp") >= 0 && g_heat == 0) {
        new out[32];
        copyc(out, 32, buf[containi(buf, "temp") + 6], '"');
        #if defined DEBUG
        log_amx("Temperature: %s", out);
        #endif
        nvault_set(g_vault, "heat", out);
        g_heat = str_to_num(out);
}
        if (containi(buf, "temp_max") >= 0 && g_temp == 0) {
        new out[32];
        copy(out, 4, buf[strfind(buf, "temp_max") + 10]);
        replace(out, 4, "&", "");
        replace(out, 4, "#", "");
        #if defined DEBUG
        log_amx("High of: %s", out);
        #endif
        nvault_set(g_vault, "maxtemp", out);
        g_temp = str_to_num(out);
}
        if (containi(buf, "temp_min") >= 0 && g_temp_min == 0) {
        new out[32];
        copy(out, 4, buf[strfind(buf, "temp_min") + 10]);
        replace(out, 4, ",", ""); //was 5 both
        replace(out, 4, "#", "");
        #if defined DEBUG
        log_amx("Low of: %s", out);
        #endif
        nvault_set(g_vault, "mintemp", out);
        g_temp_min = str_to_num(out);
}
        if (containi(buf, "visibility") >= 0) {
        new out[32];
        copyc(out, 32, buf[containi(buf, "visibility") + 12], '"');
        #if defined DEBUG
        log_amx("Visibility: %s", out);
        #endif
        nvault_set(g_vault, "visi", out);
        g_visi = str_to_num(out);
}
        if (containi(buf, "humidity") >= 0 && g_hum == 0) {
        new out[32];
        copyc(out, 32, buf[containi(buf, "humidity") + 10], '"');
        #if defined DEBUG
        log_amx("Humidity: %s", out);
        #endif
        nvault_set(g_vault, "humidity", out);
        g_hum = str_to_num(out);

}
        if (containi(buf, "lat") >= 0) {
        new out[32];
        copy(out, 3, buf[strfind(buf, "lat") + 29]);
        replace(out, 3, "&", "");
        replace(out, 3, "#", "");
        #if defined DEBUG
        log_amx("Code: %s", out);
        #endif
        nvault_set(g_vault, "code", out);
        g_code = str_to_num(out);
        if (g_code == 800) {
        g_env = 1;
        g_element = 1;
}
        if (g_code >= 801 && g_code <= 803) {
        g_env = 1;
        g_element = 2;
}
        if (g_code >= 701 && g_code <= 762) {
        g_env = 1;
        g_element = 2;
}
        if (g_code == 804) {
        g_element = 3;
        g_env = 1;
}
        if (g_code >= 200 && g_code <= 531) {
        g_env = 2;
        g_element = 3;
}
        if (g_code >= 600 && g_code <= 602) {

        g_element = 2;
        g_env = 3;
}
        if (g_code >= 611 && g_code <= 622) {
        g_element = 3;
        g_env = 3;
}
        new num[1];
        num_to_str(g_env, num, 1);
        nvault_set(g_vault, "env", num);

        num_to_str(g_element, num, 1);
        nvault_set(g_vault, "element", num);
}
        if (containi(buf, "sunrise") >= 0 && g_sunrise == 0) {
        new out[32];
        copy(out, 10, buf[strfind(buf, "sunrise") + 9]);
        replace(out, 10, "&", "");
        #if defined DEBUG
        log_amx("Sunrise: %s", out);
        #endif
        new num[10];
        num_to_str(g_sunrise, num, 10);
        nvault_set(g_vault, "sunrise", num);
        g_sunrise = str_to_num(out);
}
        if (containi(buf, "sunset") >= 0 && g_sunset == 0) {
        new out[32];
        copy(out, 10, buf[strfind(buf, "sunset") + 8]);
        replace(out, 10, "&", "");
        #if defined DEBUG
        log_amx("Sunset: %s", out);
        #endif
        new num[10];
        num_to_str(g_sunset, num, 10);
        nvault_set(g_vault, "sunset", num);
        g_sunset = str_to_num(out);
}
        set_task(0.5, "read_web");
        } else {
        socket_close(g_sckelement);
}        
}
public makeelement() {
        new humi = nvault_get(g_vault, "humidity");
        new e = nvault_get(g_vault, "env");
        if (humi > 90)
                makeFog(humi);
        switch (e)   {
        case 2:
                {
        fm_create_entity("env_rain");

                }

        case 3:
                {
        fm_create_entity("env_snow");
                }
        case 4:
                {
        fm_create_entity("env_rain");
        fm_create_entity("env_snow");
                }
        }
        set_sky(humi);
}
public set_sky(humi) {
        new phase, dusk, noon, dawn, temp[3];
        dusk = 21;
        dawn = 7;
        noon = 12;
        get_time("%H", temp, 2);
        new time = str_to_num(temp);
        if (time == noon - 1 || time == noon)
                phase = 2; //NOON
        else if (time == dawn - 1 || time == dawn)
                phase = 1; //SUNRISE
        else if (time == dusk - 1 || time == dusk)
                phase = 3; //SUNSET
        else if (time < dawn - 1 || time >= dusk + 1)
                phase = 4; //NIGHT
        else if (time > dawn + 1 && time < noon - 1)
                phase = 0; //DAY
        else if (time > noon + 1 && time < dusk - 1)
                phase = 0; //DAY
        if (humi <= 90) {
                precache_sky(g_skynames[((nvault_get(g_vault, "element") - 1) * 5) + phase]);
        } else
                precache_sky(g_skynames[(3 * 5) + phase]);     
}
public precache_sky(const skyname[]) {
        new bool: pres = true;
        static file[35];
        for (new i = 0; i < 6; ++i) {
                formatex(file, 34, "gfx/env/%s%s.tga", skyname, g_skysuf[i]);
                if (file_exists(file)) {
                        precache_generic(file);
                } else {
                        pres = false;
                        break;
                }
        }
        if (pres)
                set_cvar_string("sv_skyname", skyname);
}
public daylight() {
        new sunset = 21 + 1;
        new sunrise = 6 - 1;
        new totalDayLight = (sunset) - sunrise;
        new serv_time[3];
        get_time("%H", serv_time, 2);
        new now = str_to_num(serv_time);
        if (get_pcvar_num(g_cvar_time) > 0)
        now = get_cvar_num("time");
        new light, lightspan = get_pcvar_num(g_cvar_minlight) + 1 - get_pcvar_num(g_cvar_maxlight);
        new tempspan = g_temp - g_temp_min;
        new noon = (totalDayLight / 2) + sunrise;
        if (now < noon){
        if (now < sunrise) 
        {
        light = get_pcvar_num(g_cvar_minlight);
        g_curr_temp = g_temp_min;
        } else {
        new prenoon = noon - sunrise;
        light = get_pcvar_num(g_cvar_minlight) - (now - sunrise) * (lightspan / prenoon);
        g_curr_temp = g_temp - (now - sunrise) * (tempspan / prenoon);
                }
        }
        if (now == noon) {
                light = get_pcvar_num(g_cvar_maxlight);
                g_curr_temp = g_temp;
        }
        if (now > noon) {
                if (now > sunset) {
                        light = get_pcvar_num(g_cvar_minlight);
                        g_curr_temp = g_temp_min;
                           } else {
        new postnoon = noon - sunrise;
        light = (now - noon) * (lightspan / postnoon) + get_pcvar_num(g_cvar_maxlight);
        g_curr_temp = (now - sunrise) * (tempspan / postnoon) + g_temp_min;
        if (light > get_pcvar_num(g_cvar_minlight)) {
        light = get_pcvar_num(g_cvar_minlight);
                        }
                }
        }
        #if defined DEBUG
        log_amx("darkness %d", light);
        log_amx("dark %d phase %d lums %d", get_cvar_num("dark"), light, get_cvar_num("lums"));
        log_amx("darkness added to max light is %d out of 25 total darkness", light);
        #endif
        fm_set_lights(g_LightLevel[light]);
        new fogcolor = (get_pcvar_num(g_cvar_minlight) - light) * 10 + 20;
        new form[12];
        //model illumination
        set_cvar_num("sv_skycolor_r", fogcolor);
        set_cvar_num("sv_skycolor_g", fogcolor);
        set_cvar_num("sv_skycolor_b", fogcolor);
        //fog color
        format(form, 12, "%d %d %d", fogcolor, fogcolor, fogcolor);
        fm_set_kvd(g_fog, "rendercolor", form);
}
public makeFog(amount) {
        g_fog = fm_create_entity("env_fog");
        new Float: density = (0.0002 * (amount - 90)) + 0.001;
        new dens[7];
        float_to_str(density, dens, 6);
        fm_set_kvd(g_fog, "density", dens);
        fm_set_kvd(g_fog, "rendercolor", "200 200 200");
}
//DispatchKeyValue
stock fm_set_kvd(entity,
        const key[],
                const value[],
                        const classname[] = "") {
        if (classname[0])
                set_kvd(0, KV_ClassName, classname);
        else {
                new class[32];
                pev(entity, pev_classname, class, sizeof class - 1);
                set_kvd(0, KV_ClassName, class);
        }
        set_kvd(0, KV_KeyName, key);
        set_kvd(0, KV_Value, value);
        set_kvd(0, KV_fHandled, 0);
        return dllfunc(DLLFunc_KeyValue, entity, 0);
}