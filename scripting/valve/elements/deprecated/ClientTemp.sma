/**
*    Elements-Lite.  Player GeoIp connection reading and temp. Half-Life server of any mod.
*    Get a free 32-bit API key from openweathermap.org. Pick metric or imperial. Only cvar.
*    Copyleft (C) 2019 .sρiηX҉.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
#include <amxmodx>
#include <amxmisc>
#include <geoip>
#include <sockets>


#define PLUGIN "ClientTemp"
#define VERSION "A"
#define AUTHOR ".sρiηX҉."
#define DEBUG
#define MY public
#define KEY "................................"
#define UPLINK "GET /data/2.5/weather?lat="
#define U2 "&u=c HTTP/1.0^nHost: api.openweathermap.org"
new name[33], ip[32], authid[64], city[64], country[33], region[64];
new Float:g_lat[32], Float:g_lon[32];
new Soc_O_ErroR2, g_scknamede;

new buf[256], constring[256];
new g_cvar_unit;
new id, unit[16];

MY plugin_init()
{
    {
        {
        register_plugin(PLUGIN, VERSION, AUTHOR);
        g_cvar_unit = register_cvar("unit", "imperial");
       }
    }
}

MY client_putinserver(id)

{
    {
        {
        if (is_user_bot(id) || is_user_hltv(id)) return;
        get_user_name(id,name,32), get_user_ip(id,ip,31,1), get_user_authid(id,authid,63), geoip_city(ip,city,64,1), geoip_country_ex(ip,country,32,2), geoip_region_name(ip,region, 64,2);
        set_task_ex(1.5, "get_namede", 139, .flags = SetTask_Once);
        
        g_lat[id] = geoip_latitude(ip);
        g_lon[id] = geoip_longitude(ip);

        log_amx("Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined. |lat:%f lon:%f|", name, authid, country, city, region, g_lat[id], g_lon[id]);
        client_print(0,print_chat,"%s %s from %s appeared on %s, %s radar.", name, authid, country, city, region);
        }
    }
}

MY client_disconnected(id)

{
    {
        {
        if (is_user_bot(id) || is_user_hltv(id)) return;

        get_user_name(id,name,32), get_user_ip(id,ip,31,0), get_user_authid(id,authid,63), geoip_city(ip,city,64,1), geoip_country_ex(ip,country,32,2), geoip_region_name(ip,region, 64,2);

        client_print_color(0,id, "^x03%s^x01 ^x04%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", name, authid, country, city, region);

        if ( cstrike_running() ) return;
        client_print(0,print_chat,"%s %s from %s disappeared on %s, %s radar.", name, authid, country, city, region);
        }
    }
}

MY get_namede()

{
    {
        {
        #if defined DEBUG
        log_amx("Named:Starting the sockets routine...");
        #endif
        get_pcvar_string(g_cvar_unit, unit, 15);

        g_scknamede = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);

            g_lat[id] = geoip_latitude(ip);
        g_lon[id] = geoip_longitude(ip);
        formatex(constring, 256, "%s%f&lon=%f&units=%s&APPID=%s%s^n^n", UPLINK, g_lat[id], g_lon[id], unit, KEY, U2);
        write_web(constring);

        #if defined DEBUG
        log_amx("This is where we are trying to get weather from");
        log_amx(constring);
        log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
        #endif
        read_web();
        }
    }
}

MY write_web(text[256])

{
    {   server_print("Named:soc writable");
        {
        if (socket_is_writable(g_scknamede, 100000))
        socket_send(g_scknamede, text,255);
        }
    }   server_print("Named:writing the web");
}

MY read_web()

{
    {
        {
        server_print("Named:reading the web")
        if (socket_is_readable(g_scknamede, 100000))
        socket_recv(g_scknamede, buf, 255);
        if (!equal(buf, ""))
        {
        if (containi(buf, "temp") >= 0 )
        {
        server_print("Named:Ck temp");
        new out[8];
        copyc(out, 6, buf[containi(buf, "temp") + 6], '"');
        replace(out, 6, ":", "");
        replace(out, 6, ",", "");
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
        #if defined DEBUG
        log_amx("Temperature: %s", out);
        #endif
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
        client_print(0,print_chat,"Temp there is %s degrees in %s.", out, region);
        }
        set_task_ex(2.0, "read_web");
        }
        else
        {
        socket_close(g_scknamede);
        server_print("Named finished reading")
        }
        }
    }
}