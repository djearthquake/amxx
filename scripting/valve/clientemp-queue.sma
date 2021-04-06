/*
    *
    *   SSSSSSSSSSSSSSS PPPPPPPPPPPPPPPPP     iiii  NNNNNNNN        NNNNNNNNXXXXXXX       XXXXXXX
    * SS:::::::::::::::SP::::::::::::::::P   i::::i N:::::::N       N::::::NX:::::X       X:::::X
    *S:::::SSSSSS::::::SP::::::PPPPPP:::::P   iiii  N::::::::N      N::::::NX:::::X       X:::::X
    *S:::::S     SSSSSSSPP:::::P     P:::::P        N:::::::::N     N::::::NX::::::X     X::::::X
    *S:::::S              P::::P     P:::::Piiiiiii N::::::::::N    N::::::NXXX:::::X   X:::::XXX
    *S:::::S              P::::P     P:::::Pi:::::i N:::::::::::N   N::::::N   X:::::X X:::::X
    * S::::SSSS           P::::PPPPPP:::::P  i::::i N:::::::N::::N  N::::::N    X:::::X:::::X
    *  SS::::::SSSSS      P:::::::::::::PP   i::::i N::::::N N::::N N::::::N     X:::::::::X
    *    SSS::::::::SS    P::::PPPPPPPPP     i::::i N::::::N  N::::N:::::::N     X:::::::::X
    *       SSSSSS::::S   P::::P             i::::i N::::::N   N:::::::::::N    X:::::X:::::X
    *            S:::::S  P::::P             i::::i N::::::N    N::::::::::N   X:::::X X:::::X
    *            S:::::S  P::::P             i::::i N::::::N     N:::::::::NXXX:::::X   X:::::XXX
    *SSSSSSS     S:::::SPP::::::PP          i::::::iN::::::N      N::::::::NX::::::X     X::::::X
    *S::::::SSSSSS:::::SP::::::::P          i::::::iN::::::N       N:::::::NX:::::X       X:::::X
    *S:::::::::::::::SS P::::::::P          i::::::iN::::::N        N::::::NX:::::X       X:::::X
    * SSSSSSSSSSSSSSS   PPPPPPPPPP          iiiiiiiiNNNNNNNN         NNNNNNNXXXXXXX       XXXXXXX
    *
    *──────────────────────────────▄▄
    *──────────────────────▄▄▄▄▄▄▄▄▌▐▄
    *─────────────────────█▄▄▄▄▄▄▄▄▌▐▄█
    *────────────────────█▄▄▄▄▄▄▄█▌▌▐█▄█
    *──────▄█▀▄─────────█▄▄▄▄▄▄▄▌░▀░░▀░▌
    *────▄██▀▀▀▀▄──────▐▄▄▄▄▄▄▄▐ ▌█▐░▌█▐▌
    *──▄███▀▀▀▀▀▀▀▄────▐▄▄▄▄▄▄▄▌░░░▄▄▌░▐
    *▄████▀▀▀▀▀▀▀▀▀▀▄──▐▄▄▄▄▄▄▄▌░░▄▄▄▄░▐
    *████▀▀▀▀▀▀▀▀▀▀▀▀▀▄▐▄▄▄▄▄▄▌░▄░░▀▀░░▌
    *▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▌░▐▀▄▄▄▄▀
    *▒▒▒▒▄▄▀▀▀▀▀▀▀▀▄▄▄▄▀▀█▄▄▄▄▄▌░░░░░▌
    *▒▄▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌
    *▒▌░░░░░▀▄░░░░░░░░░░░░░░░▀▄▄▄▄▄▄░▀▄▄▄▄▄
    *▒▌░░░░░░░▀▄░░░░░░░░░░░░░░░░░░░░▀▀▀▀▄░▀▀▀▄
    *▒▌░░░░░░░▄▀▀▄░░░░░░░░░░░░░░░▀▄░▄░▄░▄▌░▄░▄▌
    *▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    *
    *
    *
    *
    *
    * __..__  .  .\  /
    *(__ [__)*|\ | >< Thu 31 Dec 2020 06:05:58 PM CST
    *.__)|   || \|/  \
    *    ℂ𝕝𝕚𝕖𝕟𝕥𝕖𝕞𝕡. Displays clients temperature. REQ:HLDS, AMXX, Openweather key.
    *    Get a free 32-bit API key from openweathermap.org. Pick metric or imperial.
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

    #define PLUGIN "Client's temperature"
    #define VERSION "1.8.2"
    #define AUTHOR ".sρiηX҉."

    #define LOG
    #define MOTD

    #define WEATHER                    7007
    #define ADMIN                      707
    #define BLOCK                      307
    #define WITHOUT_PORT               1

    //MACROS for AMXX 1.8.2 local compile.

    #if !defined MAX_PLAYERS
    #define MAX_PLAYERS                32
    #endif

    #if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH   64
    #endif

    #if !defined MAX_MENU_LENGTH
    #define MAX_MENU_LENGTH            512
    #endif

    #if !defined MAX_NAME_LENGTH
    #define MAX_NAME_LENGTH            32
    #endif

    #if !defined MAX_AUTHID_LENGTH
    #define MAX_AUTHID_LENGTH          64
    #endif

    #if !defined MAX_IP_LENGTH
    #define MAX_IP_LENGTH              16
    #endif

    #if !defined MAX_USER_INFO_LENGTH
    #define MAX_USER_INFO_LENGTH      256
    #endif

    #if !defined charsmin
    #define charsmin                   -1
    #endif

    #define GEOSTATS  get_user_name(id,g_name,charsmax(g_name)), get_user_authid(id,authid,charsmax(authid)), geoip_city(ip,g_city,charsmax(g_city),1), geoip_region_name(ip,g_region,charsmax(g_region),2);

    new iRED_TEMP,iBLU_TEMP,iGRN_HI,iGRN_LO;

    new bool:IS_SOCKET_IN_USE

    new const g_szRequired_Files[][]={"GeoLite2-Country.mmdb","GeoLite2-City.mmdb"};
    new word_buffer[MAX_PLAYERS], g_debug, g_timeout, Float:g_task;

    new g_name[ MAX_NAME_LENGTH ], ip[ MAX_IP_LENGTH ], authid[ MAX_AUTHID_LENGTH + 1 ], g_city[ MAX_AUTHID_LENGTH ], g_country[ MAX_NAME_LENGTH ], g_region[ MAX_NAME_LENGTH ];
    new Float:g_lat[ MAX_PLAYERS ], Float:g_lon[ MAX_PLAYERS ];
    new g_Weather_Feed, g_cvar_uplink, g_cvar_units, g_cvar_token, g_filepath[ MAX_NAME_LENGTH ];
    new g_szFile[ MAX_RESOURCE_PATH_LENGTH ][ MAX_RESOURCE_PATH_LENGTH ], g_admins, g_long;

    new buffer[ MAX_MENU_LENGTH ];
    new token[MAX_PLAYERS + 1];

    new const SOUND_GOTATEMP[] = "misc/Temp.wav";
    new bool:gotatemp[ MAX_PLAYERS + 1 ]

    new const faren_country[][]={
    //Bahamas
                "BHS",

    //Cayman Islands
                "CYM",

    //Liberia
                "LBR",

    //Palau
                "PLW",

    //The Federated States of Micronesia
                "FSM",

    //Marshall Islands
                "MHL",

    //The United States of America
                "USA"
}

new const DIC[] = "clientemp.txt"

public plugin_init()

{
    register_cvar("client-temp_version", VERSION, FCVAR_SERVER);

    register_plugin(PLUGIN, VERSION, AUTHOR);

    if(!lang_exists(DIC))

        register_dictionary(DIC);

        else

            {
                log_amx("%s %s by %s paused to prevent data key leakage from missing %s.", PLUGIN, VERSION, AUTHOR, DIC);
                pause "a";
            }

    g_cvar_units  = register_cvar("sv_units", "metric");
    g_cvar_token  = register_cvar("sv_openweather-key", "null", FCVAR_PROTECTED);
    g_cvar_uplink = register_cvar("sv_uplink2", "GET /data/2.5/weather?q=");
    g_admins      = register_cvar("temp_admin", "1");
    g_debug       = register_cvar("temp_debug", "0");
    g_long        = register_cvar("temp_long", "0"); //Uses longitude or city to get weather
    g_timeout     = register_cvar("temp_block", "25"); //how long minimum in between client temp requests
    set_task(900.0, "the_queue",7451,"",0,"b"); //makes sure all players temp is read minimal socket hang
    register_clcmd("say !mytemp","client_temp_cmd",1,"Shows your local temp.");
    g_task = 5.0;
}

public plugin_precache()

{
    if(file_exists("sound/misc/Temp.wav")){
        precache_sound(SOUND_GOTATEMP);
    }
        else
    {
            log_amx("Paused to prevent crash from missing %s.",SOUND_GOTATEMP);
            pause "a";
    }
}

public client_temp_cmd(id)

{

    if (task_exists(id+BLOCK) )
        {
            client_print(id,print_chat, "%L", LANG_PLAYER,"ALREADY_CHECKED", get_pcvar_num(g_timeout));
            num_to_word(get_pcvar_num(g_timeout), word_buffer, charsmax(word_buffer));
            if(!is_user_bot(id))
            client_cmd(id, "spk ^"Warning. We did check your temperature check platform in %s minutes^"", word_buffer );
            change_task(id+BLOCK,get_pcvar_num(g_timeout)*60.0);
        }
    else
    set_task(3.0,"client_temp_filter",id)
}

public client_putinserver(id)
{
    new players[ MAX_PLAYERS ];
    new playercount, m;
    if(is_user_admin(id) && get_pcvar_num(g_admins) == 0)
        gotatemp[id] = true;
    if(!is_user_bot(id))
    {
    get_players(players,playercount,"c")
    for (new m=0; m<playercount; ++m)
    if(!gotatemp[players[m]] && !is_user_bot(players[m]))
    {
    get_user_name(players[m], g_name, charsmax(g_name));
    set_task(random_float(5.0,10.0),"client_temp_cmd",players[m]);
    server_print("We do not have %s's temp yet.",g_name);
    if(task_exists(7451))
        change_task(7451, 40.0)
    }

    if(gotatemp[players[m]] && !is_user_bot(players[m]))
    {
    get_user_name(players[m], g_name, charsmax(g_name));
    server_print("We have %s's temp already.",g_name);
    }

    }
}

public client_remove(id)
{
    if( get_playersnum() == 0 && task_exists(7151))
        remove_task(7451);
}

public client_temp_filter(id)

{
    if(is_user_connected(id) && id > 0)

    if (is_user_bot(id) || is_user_hltv(id) || is_user_admin(id) && get_pcvar_num(g_admins) == 0)
        return PLUGIN_HANDLED_MAIN;

    if(IS_SOCKET_IN_USE == false && !gotatemp[id])
    {
        set_task(3.0,"client_temp",id);
    }
    if(IS_SOCKET_IN_USE == true && !gotatemp[id])
    {
        set_task(8.0,"client_temp",id);
    }

    if (task_exists(id+WEATHER))
    {
        change_task(id+WEATHER,(get_pcvar_num(g_timeout)*3.0)/2);
        get_user_name(id,g_name,charsmax(g_name));
        server_print("Queuing %s's weather socket for %f to prevent lag", g_name, (get_pcvar_num(g_timeout)*3.0)/2);
    }

    return PLUGIN_CONTINUE;
}

public client_temp(id)

{
    if(is_user_connected(id) && gotatemp[id] == false)
    {
    new buf[9], country[ 4 ];
    get_user_ip( id, ip, charsmax( ip ), WITHOUT_PORT );

    get_pcvar_string(g_cvar_units, buf, charsmax(buf));

    #if AMXX_VERSION_NUM == 182
        geoip_code3( ip, country );
    #endif

    #if AMXX_VERSION_NUM != 182
        geoip_code3_ex( ip, country );
    #endif

    for (new heit;heit < sizeof faren_country;heit++)
    if (equal(country, faren_country[heit]))

        set_pcvar_string(g_cvar_units, "imperial");

    else

    set_pcvar_string(g_cvar_units, "metric");

    get_datadir(g_filepath, charsmax(g_filepath));

    formatex(g_szFile[0], charsmax(g_szFile), "%s/%s", g_filepath, g_szRequired_Files[0]);
    formatex(g_szFile[1], charsmax(g_szFile), "%s/%s", g_filepath, g_szRequired_Files[1]);

    if( (!file_exists(g_szFile[0])) || !file_exists(g_szFile[1]) ){
        server_print("Check your Maxmind databases...%s|%s...halting to prevent crash.",g_szFile[0],g_szFile[1]);
        pause("a");
    }

    #if AMXX_VERSION_NUM == 182
        geoip_country( ip, g_country, charsmax(g_country) );
    #endif

    #if AMXX_VERSION_NUM != 182
        geoip_country_ex( ip, g_country, charsmax(g_country), 2 );
    #endif

    GEOSTATS

    if (task_exists(id+WEATHER))
        return PLUGIN_HANDLED;

    if (containi(ip, "127.0.0.1") != charsmin)
        return PLUGIN_HANDLED;

    g_lat[id] = geoip_latitude(ip);
    g_lon[id] = geoip_longitude(ip);

    new Float:timing;
    timing = g_task+5.0;

    new ping, loss;
    get_user_ping(id,ping,loss);
    new Float:timing2;
    timing2 = tickcount() * (ping * (0.7)) + power(loss,4);

    set_task( timing+timing2, "Weather_Feed", id+WEATHER, ip, charsmax (ip) );

    g_task = timing;

    if(g_task > 20.0) g_task = 5.0;


    #if defined LOG
    log_amx("Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined. |lat:%f lon:%f|", g_name, authid, g_country, g_city, g_region, g_lat[id], g_lon[id]);
    #endif
    client_print(0,print_chat,"%s %s from %s appeared on %s, %s radar.", g_name, authid, g_country, g_city, g_region);

    if(get_pcvar_num(g_debug))
        log_amx("%s|%s", g_name, authid);

    client_print(0,print_chat,"%s connected from %s.", g_name, g_city);

    if(get_pcvar_num(g_debug) && is_user_admin(id) )
        set_task(float(get_pcvar_num(g_timeout)), "needan", id+ADMIN);
    }

    return PLUGIN_CONTINUE;
}

public Block(chill)

    {
        new player = chill - BLOCK;

        if( is_user_connected(player) )
        {
            get_user_name(player,g_name,charsmax(g_name));
            client_print(player,print_console,"%s block over. Ok to say !mytemp %s", PLUGIN, g_name);
        }
        else
            server_print("%s block for %s possibly.", PLUGIN, g_name);
    }


public needan(keymissing)

{
    new id = keymissing - ADMIN;
    get_pcvar_string(g_cvar_token, token, charsmax (token));

    if (equal(token, "null") || equal(token, "") )

        {
            if ( cstrike_running() || (is_running("dod") == 1)  )

            {
                new motd[128];
                format(motd, charsmax (motd), "<html><meta http-equiv='Refresh' content='0; URL=https://openweathermap.org/appid'><body BGCOLOR='#FFFFFF'><br><center>Null sv_openweather-keydetected.</center></html>");
                show_motd(id, motd, "Invalid 32-bit API key!");
            }

            else

            {
                client_print(id,print_chat,"Check your API key validity!");
                client_print(id,print_center,"Null sv_openweather-key detected. %s %s %s", AUTHOR, PLUGIN,VERSION);
                client_print(id,print_console,"Get key from openweathermap.org/appid.");
            }

        }
}

public client_disconnected(id)

{
    if (is_user_bot(id) || is_user_hltv(id)) return;

    #if AMXX_VERSION_NUM == 182
        geoip_country( ip, g_country, charsmax(g_country) );
    #endif

    #if AMXX_VERSION_NUM != 182
        geoip_country_ex( ip, g_country, charsmax(g_country), 2 );
    #endif

    GEOSTATS
    if ( AMXX_VERSION_NUM == 182 || !cstrike_running() && AMXX_VERSION_NUM != 182 )
    client_print(0,print_chat,"%s %s from %s disappeared on %s, %s radar.", g_name, authid, g_country, g_city, g_region);

#if AMXX_VERSION_NUM != 182
    client_print_color(0,id, "^x03%s^x01 ^x04%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", g_name, authid, g_country, g_city, g_region);
#endif
}


public Weather_Feed( ip[ MAX_IP_LENGTH ], feeding )

{

    new id = feeding - WEATHER;

    if(is_user_connected(id))
    {

    g_lat[id] = geoip_latitude(ip);
    g_lon[id] = geoip_longitude(ip);

    if(get_pcvar_num(g_debug))
        log_amx("Client_Temperature:Starting the sockets routine...");

    new Soc_O_ErroR2, constring[MAX_USER_INFO_LENGTH], uplink[27], units[9];
    get_pcvar_string(g_cvar_uplink, uplink, charsmax (uplink) );
    get_pcvar_string(g_cvar_units, units, charsmax (units) );
    get_pcvar_string(g_cvar_token, token, charsmax (token) );

    g_Weather_Feed = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);

    if(get_pcvar_num(g_long) && g_lat[id] != 0.0 && g_lat[id] != 0.0)

        formatex(constring, charsmax (constring), "GET /data/2.5/weather?lat=%f&lon=%f&units=%s&APPID=%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n",g_lat[id], g_lon[id], units, token);

    else

        formatex(constring,charsmax (constring), "%s%s&units=%s&APPID=%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n", uplink, g_city, units, token);


    set_task(2.5, "write_web", id+WEATHER, constring, charsmax(constring) );

    if(get_pcvar_num(g_debug))
    {
        log_amx("This is where we are trying to get weather from");
        log_amx(constring);
        log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
    }

    set_task(5.5, "read_web", id+WEATHER);

    }

}

public write_web(text[MAX_USER_INFO_LENGTH], Task)

{
    IS_SOCKET_IN_USE = true;
    new id = Task - WEATHER
    get_user_name(id, g_name, charsmax(g_name) );
    server_print("%s:Is %s soc writable?",PLUGIN, g_name);
    #if AMXX_VERSION_NUM != 182
    if (socket_is_writable(g_Weather_Feed, 100000))
    #endif
        {
            socket_send(g_Weather_Feed,text,charsmax (text));
            server_print("Yes! %s:writing the web for ^n%s",PLUGIN, g_name);
        }

}

public read_web(feeding)

{
    new id = feeding - WEATHER

    get_user_name(id,g_name,charsmax(g_name));

    if(IS_SOCKET_IN_USE == true && !gotatemp[id])
    {
        new Float:vary;
        vary = floatsqroot(random_float(25.0,200.0))
        change_task(id+WEATHER,vary);
        server_print("Queuing %s's %s for %f to prevent lag on socket", g_name, PLUGIN, vary)
        //return PLUGIN_CONTINUE; //killed everytihng!!
    }

    else
    if(!IS_SOCKET_IN_USE && gotatemp[id] == false)
    IS_SOCKET_IN_USE = true;

    server_print("%s:reading %s temp",PLUGIN, g_name)
    #if AMXX_VERSION_NUM != 182
    if (socket_is_readable(g_Weather_Feed, 100000))
    #endif
    {
        socket_recv(g_Weather_Feed,buffer,charsmax(buffer) )
    }

    if (!equal(buffer, ""))

    {

    if (containi(buffer, "temp") > charsmin && !equal(g_city, ""))

    {
        server_print("%s:Ck temp",PLUGIN);
        new out[8];
        copyc(out, 6, buffer[containi(buffer, "temp") + 6], '"');
        replace(out, 6, ":", "");
        replace(out, 6, ",", "");

        #define PITCH (random_num (90,111))
        emit_sound(0, CHAN_AUTO, SOUND_GOTATEMP, 5.0, ATTN_NORM, 0, PITCH);
        gotatemp[id] = true;
/*
	    if(gotatemp[id] == true && task_exists(id + WEATHER))
	    {
	        remove_task(id + WEATHER);
	    }
*/
        set_task(get_pcvar_num(g_timeout)*60.0, "Block", id+BLOCK); //anti-flood

        new Float:Real_Temp = floatstr(out);

        #if defined MOTD
            log_amx("Temp is %i degrees in %s.", floatround(Real_Temp), g_region);
        #endif

        new bufferck[8];
        get_pcvar_string(g_cvar_units,bufferck,charsmax(bufferck));


        if (containi(buffer, "imperial") > charsmin)

        {
            iRED_TEMP =  70;
            iBLU_TEMP =  45;
            iGRN_HI   =  69;
            iGRN_LO   =  46;
        }

        else

        if (containi(buffer, "metric") > charsmin)

            {
                iRED_TEMP =  15;
                iBLU_TEMP = -15;
                iGRN_HI   =  14;
                iGRN_LO   = -14;
            }

        #if defined LOG
            log_amx("%L", LANG_PLAYER, "LOG_CLIENTEMP_PRINT", g_name, g_city, floatround(Real_Temp));
        #endif

        ////////////////////////////////
        #define HUD_PLACE1 random_float(-0.75,-1.10),random_float(0.25,0.50)
        #define HUD_PLACE2 random_float(0.75,2.10),random_float(-0.25,-1.50)
        ////////////////////////////////
        server_print("New Temp is %i", floatround(Real_Temp));
        ////////////////////////////////

        if( floatround(Real_Temp) >= iRED_TEMP )
        {
            #define HUD_RED random_num(100,255),0,0
            #if AMXX_VERSION_NUM > 182
            set_dhudmessage(HUD_RED,HUD_PLACE1,0,3.0,5.0,1.0,1.5);
            #endif
            set_hudmessage(HUD_RED,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
        }
        if( floatround(Real_Temp) <= iBLU_TEMP )
        {
            #define HUD_BLU 0,0,random_num(100,255)
            #if AMXX_VERSION_NUM != 182
            set_dhudmessage(HUD_BLU,HUD_PLACE1,0,3.0,5.0,1.0,1.5);
            #endif
            set_hudmessage(HUD_BLU,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
        }
        else
        if( (floatround(Real_Temp) > iGRN_LO) || (floatround(Real_Temp) < iGRN_HI) )
        {
            #define HUD_GRN 0,random_num(100,255),0
            #if AMXX_VERSION_NUM != 182
            set_dhudmessage(HUD_GRN,HUD_PLACE1,0,3.0,5.0,1.0,1.5)
            #endif
            set_hudmessage(HUD_GRN,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
        }
        {
        if ( cstrike_running() || (is_running("dod") == 1)  )
        {
            #if AMXX_VERSION_NUM != 182
            client_print_color(0,0,"%L", LANG_PLAYER,"CS_CLIENTEMP_PRINT", g_name, g_city, floatround(Real_Temp)) &&
            show_dhudmessage(players_who_see_effects(),"%L", LANG_PLAYER, "HUD_CLIENTEMP_PRINT", g_name, g_city, floatround(Real_Temp));
            #endif
            show_hudmessage(players_who_see_effects(),"%L", LANG_PLAYER, "HL_CLIENTEMP_PRINT", g_city, floatround(Real_Temp))
        }
        #if AMXX_VERSION_NUM != 182
        else
        #endif
        {
            client_print(0,print_chat, "%L", LANG_PLAYER,"LOG_CLIENTEMP_PRINT", g_name, g_city, floatround(Real_Temp))
            show_hudmessage(players_who_see_effects(),"%L", LANG_PLAYER,"HL_CLIENTEMP_PRINT", g_city, floatround(Real_Temp))
        }

        }
        //Speak the temperature.
        num_to_word(floatround(Real_Temp), word_buffer, charsmax(word_buffer))

        if (equal(bufferck, "imperial", charsmax(bufferck)))
        {
            if(Real_Temp < 0)
                client_cmd(0, "spk ^"temperature right now is %s degrees sub zero^"", word_buffer );

            else
                client_cmd(0, "spk ^"temperature right now is %s degrees^"", word_buffer );
        }

        if (equal(bufferck, "metric", charsmax(bufferck)))
        {
            if(Real_Temp < 0)
                client_cmd(0, "spk ^"temperature right now is %s degrees sub zero celsius^"", word_buffer );

            else
                client_cmd(0, "spk ^"temperature right now is %s degrees celsius^"", word_buffer );

        }
        socket_close(g_Weather_Feed);
        server_print("%s finished %s reading",PLUGIN, g_name);

        set_task(8.0, "@mark_socket", id);
/*
        new players[ MAX_PLAYERS ];
        new playercount, q;

        get_players(players,playercount,"c")

        for (q=0; q<playercount; ++q)
        if( gotatemp[players[q]] && !is_user_bot(players[q]) )
        {
            change_task(7451, 1200.0);
            server_print("The Queue is going sleep...^n----------------------------");
        }
*/
        return PLUGIN_CONTINUE;

    }

    if(!gotatemp[id])
        set_task(8.0, "read_web",id+WEATHER);
    }

    return PLUGIN_HANDLED_MAIN;

}

@mark_socket(){IS_SOCKET_IN_USE = false;}

public the_queue(q)
{
    server_print("---------------- The Q -------------------^n%s queue is running.^n------------------------------------------",PLUGIN)
    new players[ MAX_PLAYERS ];
    new playercount;
    get_players(players,playercount,"c")
    for (q=0; q<playercount; ++q)
    if(!gotatemp[players[q]] && !is_user_bot(players[q]))
    {
        server_print("There are players queued for %s",PLUGIN);
        get_user_name(players[q], g_name, charsmax(g_name));

        new Float:retask = playercount * 2.0
        if(task_exists(players[q] + WEATHER))
            change_task((players[q] + WEATHER),random_float(6.0,12.0))
        else
            set_task(retask+random_float(5.0,10.0),"client_temp",players[q]);
        server_print("We STILL need %s's temp already.",g_name);
    }
    else
    {
        change_task(7451, 90.0);
        server_print("The Queue is going idle...^n-----------------------------");
    }
}

stock players_who_see_effects()

{
    new players[MAX_PLAYERS], playercount, SEE;

    get_players(players,playercount,"ch");


    for (SEE=0; SEE<playercount; SEE++)

        return SEE;

    return PLUGIN_CONTINUE;
}
