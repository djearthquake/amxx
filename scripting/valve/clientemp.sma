#define PROXY_SCRIPT "proxysnort.amxx" //This is used to prevent both plugins of mine from uncontrollably clutching sockets mod.
///If you do not use it, ignore or study it.
///https://github.com/djearthquake/amxx/blob/main/scripting/valve/proxysnort.sma
//#define SOCK_NON_BLOCKING (1 << 0)    /* Set the socket a nonblocking */
//#define SOCK_LIBC_ERRORS  (1 << 1)    /* Enable libc error reporting */

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
    *(__ [__)*|\ | >< Tues 28th Dec 2021
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
    #include amxmodx
    #include amxmisc
    #include geoip
    #include sockets

    #define PLUGIN "Client's temperature"
    #define VERSION "1.8.7"
    #define AUTHOR ".sρiηX҉."

    #define LOG
    #define MOTD
    #define iQUEUE                     7451
    #define WEATHER                    7007
    #define ADMIN                      707
    #define BLOCK                      307
    #define WITHOUT_PORT               1

    //MACROS for AMXX 1.8.2 local compile.

    #define MAX_MENU_LENGTH            512
    #define MAX_USER_INFO_LENGTH       256
    #define MAX_CMD_LENGTH             128
    #define MAX_RESOURCE_PATH_LENGTH   64
    #define MAX_AUTHID_LENGTH          64
    #define MAX_IP_LENGTH_V6           40
    #define MAX_PLAYERS                32
    #define MAX_NAME_LENGTH            32
    #define MAX_IP_LENGTH              16
    #define charsmin                   -1


    new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH]
    new ClientCountry[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
    new ClientCity[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
    new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
    new ClientRegion[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
    new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH]
    new g_ClientTemp[MAX_PLAYERS+1][MAX_IP_LENGTH]

    new iRED_TEMP,iBLU_TEMP,iGRN_HI,iGRN_LO;

    new bool:IS_SOCKET_IN_USE, bool:bServer, mask

    new const g_szRequired_Files[][]={"GeoLite2-Country.mmdb","GeoLite2-City.mmdb"};
    new word_buffer[MAX_PLAYERS], g_debug, g_timeout, Float:g_task;

    new g_queue_weight, g_q_weight;
    new g_Weather_Feed, g_cvar_uplink, g_cvar_units, g_cvar_token, g_filepath[ MAX_NAME_LENGTH ];
    new g_szFile[ MAX_RESOURCE_PATH_LENGTH ][ MAX_RESOURCE_PATH_LENGTH ], g_admins, g_long;

    new buffer[ MAX_MENU_LENGTH ];
    new token[MAX_PLAYERS + 1];

    new const SOUND_GOTATEMP[] = "misc/Temp.wav";
    new bool:gotatemp[ MAX_PLAYERS + 1 ]
    new bool:somebody_is_being_help
    new g_players[ MAX_PLAYERS ],g_iHeadcount

    new g_clients_saved
    new SzSave[MAX_CMD_LENGTH]

    new Trie:g_client_temp

    enum _:Client_temp
    {
        SzAddress[ MAX_IP_LENGTH_V6 ],
        SzCountry[ MAX_RESOURCE_PATH_LENGTH ],
        SzCity[ MAX_RESOURCE_PATH_LENGTH ],
        SzRegion[ MAX_RESOURCE_PATH_LENGTH ],
        fLatitude[ 8 ],
        fLongitude[ 8 ],
        iTemp[ MAX_IP_LENGTH ],
        ifaren[4]
    }
    new Data[ Client_temp ]

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

new const faren_countries[][]={
    "Bahamas",
    "Cayman Islands",
    "Liberia",
    "Palau",
    "Federated States of Micronesia",
    "Marshall Islands",
    "United States"
}

//New Geo API v.187+/////////////////////////////////////
new ClientLON[MAX_PLAYERS+1][8]
new ClientLAT[MAX_PLAYERS+1][8]
#define COORD 3245
#define READ 777
#define WRITE 4444

new bool:got_coords[ MAX_PLAYERS + 1 ]
new const api[]= "ipwhois.app" //will see unassigned.psychz.net on NETSTAT DO NOT blacklist!
new g_socket_pass[MAX_PLAYERS+1]
new ip_api_socket
/////////////////////////////////////////////////////////
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

    g_cvar_units   = register_cvar("sv_units", "metric");
    g_cvar_token   = register_cvar("sv_openweather-key", "null", FCVAR_PROTECTED);
    g_cvar_uplink  = register_cvar("sv_uplink2", "GET /data/2.5/weather?q=");
    g_admins       = register_cvar("temp_admin", "1");
    g_debug        = register_cvar("temp_debug", "0");
    g_long         = register_cvar("temp_long", "1"); //Uses longitude or city to get weather
    g_timeout      = register_cvar("temp_block", "10"); //how long minimum in between client temp requests
    g_queue_weight = register_cvar("temp_queue_weight", "5"); //# passes before putting queue to sleep


    register_clcmd("say !mytemp","Speak",0,"Shows your local temp.");
    register_clcmd("queue_test","@queue_test",ADMIN_SLAY,"Turns up the queue.");
    register_clcmd("queue_test2","@queue_test2",ADMIN_SLAY,"Puts self unto queue.");

    set_task(900.0, "@the_queue",iQUEUE,"",0,"b"); //makes sure all players temp is read minimal socket hang

    g_task         = 5.0;
    g_q_weight     = 1
    g_client_temp = TrieCreate()
    ReadClientFromFile( )
}

public plugin_end()
{
    TrieDestroy(g_client_temp)
}

public plugin_precache()
{
    if(file_exists("sound/misc/Temp.wav")){
        precache_sound(SOUND_GOTATEMP);
        precache_generic("sound/misc/Temp.wav")
    }
        else
    {
        log_amx("Paused to prevent crash from missing %s.",SOUND_GOTATEMP);
        pause "a";
    }
}

@queue_test(id)
{
    change_task(iQUEUE, 10.0)
    client_cmd(id,"spk buttons/bell1.wav");
    server_print "Turning on queue per request by %s.",ClientName[id]
    return PLUGIN_HANDLED;
}
@fixadmins(id)
{
    client_print id,print_chat,"Changed admin_temp 1 to allow admins to get temp."
    set_pcvar_num(g_admins, 1)
    gotatemp[id] = false
    client_cmd id, "spk ^"computer malfunction. system is on zero. system is on one now for temperature control^""
    change_task(iQUEUE, 10.0)
    client_temp_cmd(id)
}
@queue_test2(id)
{
    if(is_user_connected(id))
    {
        set_pcvar_num(g_admins, 1)
        gotatemp[id] = false
        client_cmd(id,"spk buttons/bell1.wav");
        server_print "Throwing %s into queue per request by %s.",ClientName[id], ClientName[id]
    }
    return PLUGIN_HANDLED;
}
public client_putinserver(id)
{
    if(is_user_bot(id))
        return PLUGIN_HANDLED_MAIN
    if( is_user_connected(id) && !is_user_bot(id) && (!task_exists(id+WEATHER) || !task_exists(id)) ) //will do server's weather
    {
        get_user_ip( id, ClientIP[id], charsmax( ClientIP[] ), WITHOUT_PORT );
        if (equali(ClientIP[id], "127.0.0.1"))
        {
            server_print "%s IP shows as 127.0.0.1, stopping %s script!", ClientName[id], PLUGIN
            server_cmd( "kick #%d ^"Please reconnect we misread your ID^"", get_user_userid(id) );
            return PLUGIN_HANDLED;
        }
        else
            client_putinserver_now(id)
    }
    return PLUGIN_CONTINUE
}
@country_finder(Tsk)
{
    mask = Tsk - WEATHER

    new Float:task_expand = random_num(5,10)*1.0
    if(is_user_connected(mask))
    {
        if(equal(ClientIP[mask],""))
        {
            server_print"We did not have the network address captured right."
            get_user_ip( mask, ClientIP[mask], charsmax( ClientIP[] ), WITHOUT_PORT );
        }

        Data[SzAddress] = ClientIP[mask]

        TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )

        if(equal(ClientCountry[mask],""))
        {
            server_print"We did not have the COUNTRY captured right.^nUsing Maxmind."
            #if AMXX_VERSION_NUM == 182
                geoip_country( ClientIP[mask], ClientCountry[mask], charsmax(ClientCountry[]) );
            #else
                geoip_country_ex( ClientIP[mask], ClientCountry[mask], charsmax(ClientCountry[]), 2 );
            #endif
        }
        Data[SzCountry] = ClientCountry[mask]

        if(equal(ClientName[mask],""))
        {
            server_print"We did not have the name captured right."
            get_user_name(mask,ClientName[mask],charsmax(ClientName[]))
        }

        if(equal(ClientAuth[mask],""))
        {
            server_print"We did not have the AuthID captured."
            get_user_authid(mask,ClientAuth[mask],charsmax(ClientAuth[]))
        }

        if(equal(ClientCity[mask],""))
        {
            server_print"We did not have the CITY captured right.^nUsing Maxmind."
            geoip_city(ClientIP[mask],ClientCity[mask],charsmax(ClientCity[]),1)
        }

        if(equal(ClientRegion[mask],""))
        {
            server_print"We did not have the REGION captured right.^nUsing Maxmind."
            geoip_region_name(ClientIP[mask],ClientRegion[mask],charsmax(ClientRegion[]),2)
        }

        //Transfer coords from other API into this one.
        if(got_coords[mask])
        {
            Data[fLatitude] = ClientLAT[mask]
            Data[fLongitude] = ClientLON[mask]
        }
        else
        {
            client_putinserver_now(mask)
            return
        }

        Data[SzCity] = ClientCity[mask]
        Data[SzRegion] = ClientRegion[mask]

        if(!TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        {
            TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
            server_print "Adding Client to check temp"
            formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", Data[SzAddress], Data[SzCity], Data[SzRegion], Data[SzCountry], Data[fLatitude], Data[fLongitude] ) ///likes quotes not comma TAB
            @file_data(SzSave)
        }
        else if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ) && !equali(Data[ iTemp ], ""))
        {
            server_print "We already displayed temp to this IP"
            gotatemp[mask] = true; //get them out of queue
            set_task(10.0,"@speakit",mask)
            return
        }

        server_print "checking temp country"

        client_print 0, print_chat, "%s from %s appeared on %s, %s radar.", ClientName[mask], ClientCountry[mask], ClientCity[mask], ClientRegion[mask]
        server_print "%s from %s appeared on %s, %s radar.", ClientName[mask], ClientCountry[mask], ClientCity[mask], ClientRegion[mask]
        ///if(!IS_SOCKET_IN_USE)
        set_task(task_expand,"@que_em_up",mask)

    }
}
@speakit(id)
{
    new new_temp

    if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ) && !equali(Data[ iTemp ], ""))
        new_temp = Data[iTemp]
    else
        new_temp = str_to_num(g_ClientTemp[id])

    //Speak the temperature.
    num_to_word(new_temp, word_buffer, charsmax(word_buffer))
    if(new_temp < 0)
        client_cmd(id, "spk ^"temperature right now is %s degrees sub zero^"", word_buffer );

    else
        client_cmd(id, "spk ^"temperature right now is %s degrees^"", word_buffer );

    server_print "Spoke temp for^n^n%s",ClientName[id]
}

public Speak(id)
{
    if(gotatemp[id]) //remind them otherwise fetch it
    {
        if(is_user_admin(id))
            (get_pcvar_num(g_admins) ? @speakit(id) : @fixadmins(id))
        else
            @speakit(id)

    }
    else
    {
        client_cmd id, "spk ^"temperature is going through now^""
        client_temp_cmd(id) //fetch
    }

}

public client_temp_cmd(id)
{
    server_print "client_temp_cmd for slot:%d|%s", id, ClientName[id]
    if(is_user_connected(id))
    {
        set_task(random_num(8,16)*1.0,"client_temp_filter",id)
        server_print "Making a filter task for %s", ClientName[id]
    }
}

@que_em_up(m)
{
    server_print "q em up^nWhen somebody connects it checks all here."
    if(is_user_connecting(m))
    {
        change_task(m,20.0)
        server_print "Rescheduling %n until they connect.",m
    }
    else
    {
        server_print "%s is still connected at moment.", ClientName[m]

        if(is_user_admin(m) && get_pcvar_num(g_admins) == 0)
        gotatemp[m] = true;

        else if(!gotatemp[m] && m > 0)
        {
            set_task(random_num(5,12)*1.0,"client_temp_cmd",m)
            ////////////////////////////////////////////////////////////////////////////////
            server_print "We do not have %s's temp yet.",ClientName[m]

            if(task_exists(iQUEUE))
            {
                change_task(iQUEUE, 30.0)
                server_print "Resuming queue per %s connected.",ClientName[m]
            }

        }

        else if(gotatemp[m])
        {
            server_print "We have %s's temp already.",ClientName[m]
        }

    }

}

public client_remove(id)
{
    iPlayers()
    if( g_iHeadcount == 0)
    {
        server_print "NOBODY IS ONLINE HIBERNATING THE QUEUE CYCLE"
        change_task(iQUEUE, 1800.0)
        remove_task(id);
    }
}

public client_temp_filter(id)
{
    server_print "CLIENT TEMP FILTER FUNCTION"
    if(is_user_connected(id) && id > 0)
    {

        if (is_user_bot(id) || is_user_admin(id) && get_pcvar_num(g_admins) == 0)
            return PLUGIN_HANDLED_MAIN;
        server_print "Temp task will be accessed soon"
        if(IS_SOCKET_IN_USE == false && !gotatemp[id])
        {
            client_temp(id)
        }

        if(IS_SOCKET_IN_USE == true && !gotatemp[id])

        {
            server_print "Socket shows in use."
            if(!task_exists(id))
            {
                set_task(random_num(10,20)*1.0,"client_temp",id);
                server_print "Setting task."
            }
            else
                change_task(id,random_num(7,11)*1.0)

        }

        if(task_exists(id+WEATHER))
        {
            change_task(id+WEATHER,random_num(20,30)*1.0);
            server_print "Queuing %s's weather socket for %f to prevent lag", ClientName[id], get_pcvar_num(g_timeout)*3.0/1.5
        }


    }

    return PLUGIN_CONTINUE;
}

public client_temp(id)
{
    server_print "client_temp function"
    if(is_user_connected(id) && gotatemp[id] == false)
    {

        Data[ SzAddress ] = ClientIP[id]
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        {
            new country[ 4 ];
    
            #if AMXX_VERSION_NUM == 182
                geoip_code3( ClientIP[id], country );
            #else
                geoip_code3_ex( ClientIP[id], country );
            #endif
    
            for (new heit;heit < sizeof faren_country;heit++)
    
            if(equali(country, faren_country[heit]))
            {
                set_pcvar_string(g_cvar_units, "imperial")
                copy( Data[ifaren], charsmax(Data[ifaren]), "1" )
            }
            else
            {
                set_pcvar_string(g_cvar_units, "metric")
                copy( Data[ifaren], charsmax(Data[ifaren]), "0" )
            }
    
            TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
            server_print "Adding Client units to check temp"
    
    
            get_datadir(g_filepath, charsmax(g_filepath));
    
            //////////THIS STOPS CRASHING SERVER DUE TO MAXMIND NOT BEING COPIED
            formatex(g_szFile[0], charsmax(g_szFile), "%s/%s", g_filepath, g_szRequired_Files[0]);
            formatex(g_szFile[1], charsmax(g_szFile), "%s/%s", g_filepath, g_szRequired_Files[1]);
            if( (!file_exists(g_szFile[0])) && !file_exists(g_szFile[1]) )
            {
                server_print "Check BOTH your Maxmind databases...%s|%s...halting to prevent crash.",g_szFile[0],g_szFile[1]
                pause("a");
            }
            else if(!file_exists(g_szFile[0]))
            {
                server_print "Check your Maxmind database...%s...halting to prevent crash.",g_szFile[0]
                pause("a")
            }
            else if(!file_exists(g_szFile[1]))
            {
                server_print "Check your Maxmind database...%s...halting to prevent crash.",g_szFile[1]
                pause("a")
            }
            ///////////////////////////////////////////////////////////////////////
            if (task_exists(id+WEATHER))
                return PLUGIN_HANDLED;
    
            if (containi(ClientIP[id], "127.0.0.1") != charsmin)
            {
                server_print "%s IP shows as 127.0.0.1, stopping script!", ClientName[id]
                return PLUGIN_HANDLED;
            }
            ////////////GEO COORDINATES GATHERING/////////////////////////////////
            ///Amxx module w/ Maxmind geoip database
            ///g_lat[id] = geoip_latitude(ClientIP[id]);
            ///g_lon[id] = geoip_longitude(ClientIP[id]);
            new Float:timing;
            timing = g_task+5.0;
    
            new ping, loss;
    
            get_user_ping(id,ping,loss);
            new Float:timing2;
            timing2 = tickcount() * (ping * (0.7)) + power(loss,4);
    
            set_task( timing+timing2, "Weather_Feed", id+WEATHER, ClientIP[id], charsmax(ClientIP[]) );

            g_task = timing;
    
            if(g_task > 20.0) g_task = 5.0;
    
    
            #if defined LOG
            //log_amx "Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined. |lat:%f lon:%f|", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id], str_to_float(ClientLAT[id]), str_to_float(ClientLON[id]) // g_lat[id], g_lon[id]);
            log_amx "Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined. |lat:%f lon:%f|", ClientName[id], ClientAuth[id], Data[SzCountry], Data[SzCity], Data[SzRegion], str_to_float(Data[fLatitude]), str_to_float(Data[fLongitude]) // g_lat[id], g_lon[id]);
            #endif
    
            if(get_pcvar_num(g_debug) && is_user_admin(id) )
                set_task(float(get_pcvar_num(g_timeout)), "needan", id+ADMIN);
        }
        else
            client_putinserver(id)

    }
    return PLUGIN_CONTINUE;
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

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif
public client_disconnected(id)
{
    new iHeadcount
    if( is_user_bot(id)) return

    Data[ SzAddress ] = ClientIP[id]

    if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
    else
        return

    if( iHeadcount > 0 )
    {
        for (new admin=1; admin<=iHeadcount; admin++)

        if(is_user_connected(admin) && !is_user_bot(admin))
        {
            if (!is_user_admin(admin))
            {
                if ( AMXX_VERSION_NUM == 182 || !cstrike_running() && AMXX_VERSION_NUM != 182 )
                client_print admin,print_chat,"%s from %s disappeared on %s, %s radar.", ClientName[id], Data[SzCountry], Data[SzCity], Data[SzRegion]
                #if AMXX_VERSION_NUM != 182
                client_print_color admin,0, "^x03%n^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", id, Data[SzCountry], Data[SzCity], Data[SzRegion]
                #endif
            }

            else
            {
                if ( AMXX_VERSION_NUM == 182 || !cstrike_running() && AMXX_VERSION_NUM != 182 )
                client_print admin,print_chat,"%s from %s disappeared on %s, %s radar.", ClientName[id], ClientAuth[id], Data[SzCountry], Data[SzCity], Data[SzRegion]

                #if AMXX_VERSION_NUM != 182
                client_print_color admin,0, "^x03%n^x01 ^x04%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", id, ClientAuth[id], Data[SzCountry], Data[SzCity], Data[SzRegion]
                #endif
            }

        }

    }
    #if AMXX_VERSION_NUM == 182
        set_task(5.0,"client_remove",id)
    #endif
    server_print "%s %s from %s disappeared on %s, %s radar.", ClientName[id], ClientAuth[id], Data[SzCountry], Data[SzCity], Data[SzRegion]
}

public Weather_Feed( ClientIP[MAX_IP_LENGTH], feeding )
{

    new id = feeding - WEATHER;

    if(is_user_connected(id) && !gotatemp[id])
    {

        if(get_pcvar_num(g_debug))
            log_amx("Client_Temperature:Starting the sockets routine...");

        new Soc_O_ErroR2, constring[MAX_USER_INFO_LENGTH], uplink[27], units[9];
        get_pcvar_string(g_cvar_uplink, uplink, charsmax (uplink) );
        get_pcvar_string(g_cvar_token, token, charsmax (token) );
        g_Weather_Feed = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS); //used newer inc on 182;compiles works ok
        //g_Weather_Feed = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2); //tested 182 way

        ClientIP[id] = Data[ SzAddress ]
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
            //Make sure client gets the right unit
            str_to_num(Data[ifaren]) == 1 ? copy(units,charsmax(units),"imperial") : copy(units,charsmax(units),"metric")
        else
        {
            //fall-back
            equali(ClientCountry[id],"United States") ? copy(units,charsmax(units),"imperial") : copy(units,charsmax(units),"metric")
        }
        //USA SHOULD NEVER SLIP METRIC DUE TO ANY ERROR ON MY PART
        for(new imperial = 1; imperial < sizeof faren_countries;imperial++)
        //if(equali(ClientCountry[id],"United States")) //array later
        if(containi(ClientCountry[id],faren_countries[imperial]) > charsmin)
            copy(units,charsmax(units),"imperial")
        else //Handful of countries are like USA
            copy(units,charsmax(units),"metric")

        //Pick what is more reliable or chosen first on cvar lon+lat or city to acquire temp
        if(get_pcvar_float(g_long) && got_coords[id])
        {
            formatex(constring, charsmax(constring), "GET /data/2.5/weather?lat=%f&lon=%f&units=%s&APPID=%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n", str_to_float(Data[fLatitude]), str_to_float(Data[fLongitude]), units, token)
        }
        else if (!equali(ClientCity[id], ""))
        {
            new city_space_remover[MAX_RESOURCE_PATH_LENGTH]
            copy(city_space_remover,charsmax(city_space_remover),ClientCity[id])
            replace(city_space_remover,charsmax(city_space_remover)," ", "")
            formatex(constring,charsmax (constring), "%s%s&units=%s&APPID=%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n", uplink, city_space_remover, units, token);
        }
        else
        {
            server_print "Unable to get %s due to no city nor lon and lat!! on %s", PLUGIN, ClientName[id]
            log_amx "Unable to get %s due to no city nor lon and lat!! on %s", PLUGIN, ClientName[id]
            return
        }
        server_print "Is server busy?"
        if(!bServer)
        {
            set_task(1.0, "write_web", id+WEATHER, constring, charsmax(constring) );
    
            if(get_pcvar_num(g_debug))
            {
                log_amx("This is where we are trying to get weather from");
                log_amx(constring);
                log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
            }
    
            set_task(1.5, "read_web", id+WEATHER);
            bServer = true
            server_print "Server made busy"
        }
        else
            server_print "Server shows busy"

    }

}

public write_web(text[MAX_USER_INFO_LENGTH], Task)
{
    IS_SOCKET_IN_USE = true;
    callfunc_begin("@lock_socket",PROXY_SCRIPT)
    callfunc_end()
    new id = Task - WEATHER

    server_print "%s:Is %s soc writable?",PLUGIN, ClientName[id]
    #if AMXX_VERSION_NUM != 182
    if (socket_is_writable(g_Weather_Feed, 100000))
    #endif
    {
        socket_send(g_Weather_Feed,text,charsmax (text));
        server_print "Yes! %s:writing the web for ^n%s",PLUGIN, ClientName[id]
    }

}

public read_web(feeding)
{
    new id = feeding - WEATHER
    if (!is_user_bot(id) && id > 0)
    {
        Data[SzAddress] = ClientIP[id]
        /////////////////////////////////////////////////////
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
            TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
        //if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ) && !equali(Data[ iTemp ], "")) //~20 min exp date instead. works across maps

        if(equal(ClientCity[id], ""))
        {
            geoip_city(ClientIP[id],ClientCity[id],charsmax(ClientCity[]),1)
            Data[SzCity] = ClientCity[id]
            TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
        }

        if(IS_SOCKET_IN_USE && !gotatemp[id])
        {
            remove_task(id+WEATHER)
            server_print "Socket in use. Removing task for %s", ClientName[id]
        }

        else
        if(!IS_SOCKET_IN_USE && !gotatemp[id])
        {
            IS_SOCKET_IN_USE = true;
            callfunc_begin("@lock_socket",PROXY_SCRIPT)
            callfunc_end()
        }

        server_print "%s:reading %s temp",PLUGIN, ClientName[id]
        #if AMXX_VERSION_NUM != 182
        if (socket_is_readable(g_Weather_Feed, 100000))
        #endif
        socket_recv(g_Weather_Feed,buffer,charsmax(buffer) )
        if (!equal(buffer, "") && IS_SOCKET_IN_USE == true && containi(buffer, "temp") > charsmin)
        {
            server_print "We have a clientemp buffer"

            if (get_timeleft() > 30) ///Refrain from running sockets on map change!
            {
                server_print "%s:Ck temp",PLUGIN
                new out[8];
                copyc(out, 6, buffer[containi(buffer, "temp") + 6], '"');
                replace(out, 6, ":", "");
                replace(out, 6, ",", "");

                #define PITCH (random_num(90,111))
                emit_sound(id, CHAN_STATIC, SOUND_GOTATEMP, 5.0, ATTN_NORM, 0, PITCH);
                gotatemp[id] = true;

                new Float:Real_Temp = floatstr(out);

                formatex(g_ClientTemp[id], charsmax (g_ClientTemp[]), "%i",floatround(Real_Temp));
                new new_temp = str_to_num(g_ClientTemp[id])

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
                    log_amx("%L", LANG_PLAYER, "LOG_CLIENTEMP_PRINT", ClientName[id], ClientCity[id], new_temp);
                #endif
                Data[iTemp] = new_temp
                TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )

                ////////////////////////////////
                #define HUD_PLACE1 random_float(-0.75,-1.10),random_float(0.25,0.50)
                #define HUD_PLACE2 random_float(0.75,2.10),random_float(-0.25,-1.50)
                ////////////////////////////////
                server_print "New Temp is %i", str_to_num(Data[iTemp]) //new_temp
                ////////////////////////////////

                if( new_temp >= iRED_TEMP )
                {
                    #define HUD_RED random_num(100,255),0,0
                    #if AMXX_VERSION_NUM > 182
                    set_dhudmessage(HUD_RED,HUD_PLACE1,0,3.0,5.0,1.0,1.5);
                    #endif
                    set_hudmessage(HUD_RED,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
                }
                if( new_temp <= iBLU_TEMP )
                {
                    #define HUD_BLU 0,0,random_num(100,255)
                    #if AMXX_VERSION_NUM != 182
                    set_dhudmessage(HUD_BLU,HUD_PLACE1,0,3.0,5.0,1.0,1.5);
                    #endif
                    set_hudmessage(HUD_BLU,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
                }
                else
                if( (new_temp > iGRN_LO) || (new_temp < iGRN_HI) )
                {
                    #define HUD_GRN 0,random_num(100,255),0
                    #if AMXX_VERSION_NUM != 182
                    set_dhudmessage(HUD_GRN,HUD_PLACE1,0,3.0,5.0,1.0,1.5)
                    #endif
                    set_hudmessage(HUD_GRN,HUD_PLACE2,1,2.0,8.0,3.0,3.5,3);
                }


                if ( cstrike_running() || (is_running("dod") == 1)  )
                {
                    #if AMXX_VERSION_NUM != 182
                    client_print_color 0,0,"%L", LANG_PLAYER,"CS_CLIENTEMP_PRINT", ClientName[id], ClientCity[id], new_temp
                    show_dhudmessage(players_who_see_effects(),"%L", LANG_PLAYER, "HUD_CLIENTEMP_PRINT", ClientName[id], ClientCity[id], new_temp)
                    #endif
                    show_hudmessage players_who_see_effects(),"%L", LANG_PLAYER, "HL_CLIENTEMP_PRINT", ClientCity[id], new_temp
                }
                #if AMXX_VERSION_NUM != 182
                else
                #endif
                {
                    client_print 0,print_chat, "%L", LANG_PLAYER,"LOG_CLIENTEMP_PRINT", ClientName[id], ClientCity[id], new_temp
                    show_hudmessage (players_who_see_effects(),"%L", LANG_PLAYER,"HL_CLIENTEMP_PRINT", ClientCity[id], new_temp)
                }


                //Speak the temperature.
                num_to_word(new_temp, word_buffer, charsmax(word_buffer))

                if (equal(bufferck, "imperial", charsmax(bufferck)))
                {
                    if(new_temp < 0)
                        client_cmd(0, "spk ^"temperature right now is %s degrees sub zero^"", word_buffer );

                    else
                        client_cmd(0, "spk ^"temperature right now is %s degrees^"", word_buffer );
                }

                else if (equal(bufferck, "metric", charsmax(bufferck)))
                {
                    if(new_temp < 0)
                        client_cmd(0, "spk ^"temperature right now is %s degrees sub zero celsius^"", word_buffer );

                    else
                        client_cmd(0, "spk ^"temperature right now is %s degrees celsius^"", word_buffer );

                }
                if(equali(ClientCity[id],"") && containi(buffer, "name") > charsmin) //city blank from Geodat?
                {
                    new out[MAX_NAME_LENGTH];
                    copyc(out, charsmax(out), buffer[containi(buffer, "name") + 6], '"');
                    replace(out, charsmax(out), ":", "");
                    replace(out, charsmax(out), ",", "");
                    log_amx "%s city is %s was missing on local geoip", ClientName[id], out
                    copy(ClientCity[id],charsmax(ClientCity[]),out)
                    server_print "%s city is %s",ClientName[id], out
                }
                #if defined MOTD
                    log_amx "Temp is %i degrees in %s, %s, %s.", floatround(Real_Temp), ClientCity[id], ClientRegion[id], ClientCountry[id]
                    log_to_file("clientemp.log", "Temp is %i degrees in %s, %s, %s.", floatround(Real_Temp), ClientCity[id], ClientRegion[id], ClientCountry[id])
                #endif
                if(socket_close(g_Weather_Feed) == 1)
                {
                    server_print "%s finished %s reading",PLUGIN, ClientName[id]
                    set_task(5.0, "@mark_socket_client", id);

                    if(callfunc_begin("@mark_socket",PROXY_SCRIPT))
                    {
                        new work[MAX_PLAYERS]
                        format(work,charsmax(work),PLUGIN,"")
                        callfunc_push_str(work)
                        callfunc_end()
                    }


                }
                IS_SOCKET_IN_USE = false
                return PLUGIN_CONTINUE;

            }
        }
        else if(is_user_connected(id) && !gotatemp[id] &&  g_socket_pass[id] <15)
        {
            g_socket_pass[id]++
            server_print "No buffer checking again"
            set_task(1.5, "read_web",id+WEATHER)
        }
        else
        {
            set_task(5.0, "@mark_socket_client", id);
            if(socket_close(g_Weather_Feed) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
            IS_SOCKET_IN_USE = false
        }

        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED

}

@mark_socket(work[MAX_PLAYERS])
{
    server_print "Socket marked as not being in use"
    IS_SOCKET_IN_USE = false;
    bServer = false //unbusy for next in queue
    somebody_is_being_help = false
    if(!equal(work, ""))
    server_print "%s | %s locking socket!", PLUGIN, work
}

@mark_socket_client(id)
{
    if(is_user_connected(id))
        server_print "Socket is being freed up from %s", ClientName[id]
    IS_SOCKET_IN_USE = false;
    bServer = false //unbusy for next in queue
    somebody_is_being_help = false
}

@lock_socket()
{
    IS_SOCKET_IN_USE = true
    server_print "%s other plugin locking socket!", PLUGIN
}

@the_queue(player)
{

    //Assure admins queue is really running
    server_print "^n^n---------------- The Q -------------------^n%s queue is running.^n------------------------------------------",PLUGIN
    //How many runs before task is put to sleep given diminished returns
    new gopher = get_pcvar_num(g_queue_weight)
    new bool:bAssisted
    get_players(g_players,g_iHeadcount,"ch")

    for(new player;player < sizeof g_players; ++player)

    if(is_user_connected(g_players[player]) && !is_user_bot(g_players[player]))
    {
        new client = g_players[player]
        //Make array of non-bot connected players who need their temp still.
        //spread tasks apart to go easy on sockets with player who are in game and need their temps taken!
        if(!gotatemp[client])
        {
            //ATTEMPT STOP TASKS FROM BEING BACK-TO-BACK
            bAssisted = true

            server_print "%s queued for %s",ClientName[client],PLUGIN
            //task spread formula

            new total = g_iHeadcount
            server_print "Total players shows as: %i", total
            new retask = (total++)*2
            new queued_task = (total++)*3
            server_print "Total players for math adj to: %i", total
            get_user_name(client,ClientName[client],charsmax(ClientName[]))
            server_print "We STILL need %s's temp already.",ClientName[client]
            server_print "QUEUE NEXT::ID:%d %s",client, ClientName[client]
            change_task(iQUEUE, 30.0)

            //If no city showing here there will NEVER be a temp //happens when plugin loads map paused then is unpaused
            if(get_pcvar_num(g_long) > 0 && !got_coords[client] && !task_exists(client + WEATHER))
            {
                get_timeleft() > 60 ? set_task(get_pcvar_num(g_timeout)+(queued_task++)*1.0,"@country_finder",client+WEATHER)
                :
                client_print(0, print_console, "Map is about to change. Cancelling %s's weather reading.", ClientName[client])

            }
            //If they have a task set-up already adjust it
            if(task_exists(client+WEATHER))
            {
                change_task(client+WEATHER,(retask++)*1.0)
            }
            //If they don't have a task set-up make one
            else
            {
                if(!somebody_is_being_help)
                {
                    set_task(queued_task++*1.0,"@country_finder",client+WEATHER);
                    server_print "Index#:%d queued", client
                    somebody_is_being_help = true
                    server_print "%f|Queue task time for %s", queued_task++*1.0, ClientName[client]
                }
                else
                    server_print "Somebody is being helped. Waiting"

            }

        }

        if(!bAssisted)
        {
            //Count the inactive passes before lengthing task time.
            //Queue counter
            if(g_q_weight < gopher)
            {
                server_print "Pass: %i of %i: the Queue is going idle..^n------------------------------------------", g_q_weight, gopher
                change_task(iQUEUE, 60.0)
                g_q_weight++ //increment the weight each inactive pass through.
            }
            //queue sleeper
            else if(g_q_weight >= gopher)
            {
                change_task(iQUEUE, 600.0)
                server_print "Pass: %i: the Queue is going to sleep.^n------------------------------------------", gopher
                g_q_weight = 1;
            }

        }

    }
    server_print "^n^n---------------- The Q -------------------^n"
    bAssisted = false
    somebody_is_being_help = false
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
    get_players(g_players,g_iHeadcount,"ch")
    return g_iHeadcount
}

//////DUE TO GEO DATABASE AND MODULE BEING ASKEW TOO OFTEN

#if !defined SOCK_NON_BLOCKING
 #error Go make a new script or post and wait on forums/Discord if you are not autodidactic.
#endif

public client_putinserver_now(id)
{
    server_print("ID:%d entered!",id)
    if(is_user_connected(id) && !is_user_bot(id) && id > 0)
    {
        if(!task_exists(id))
        {
            set_task(0.5,"@get_user_data", id)
        }
    }
}
@get_user_data(id)
{
    get_user_name(id, ClientName[id],charsmax(ClientName[]))
    get_user_ip( id, ClientIP[id], charsmax(ClientIP[]), WITHOUT_PORT )

    copy(Data[ SzAddress ], charsmax(Data[ SzAddress ]), ClientIP[id])

    server_print "%s,%s",ClientName[id],ClientIP[id]
    if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
    {
        server_print "%s is already accounted for.", ClientName[id]

        copy( ClientLAT[id], charsmax(ClientLAT[]), Data[ fLatitude ])
        copy( ClientLON[id], charsmax(ClientLAT[]), Data[ fLongitude ])
        
        //Not using Maxmind for GeoTrio. Using newly built cache. Have yet to see omitted city and region as Maxmind does often in Middle East especially.
        copy(ClientCountry[id],charsmax(ClientCountry[]), Data[ SzCountry ])

        copy(ClientCity[id],charsmax(ClientCity[]), Data[ SzCity ])
    
        copy(ClientRegion[id],charsmax(ClientRegion[]), Data[ SzRegion ])

        got_coords[id] = true

        @country_finder(id+WEATHER)
    }
    else if(!TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        set_task(0.5,"@get_client_data", id+COORD)

    
}
@get_client_data(goldsrc)
{
    new Soc_O_ErroR2
    new id = goldsrc - COORD
    if(is_user_connected(id))
    {
        new constring[MAX_CMD_LENGTH]
        ip_api_socket = socket_open(api, 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
        formatex(constring, charsmax (constring), "GET http://%s/json/%s HTTP/1.0^nHost: %s^n^n", api, ClientIP[id], api)
        server_print "%s",constring

        if(!task_exists(id+WRITE))
            set_task(0.5, "@write_api", id+WRITE, constring, charsmax(constring) )

        if(!task_exists(id+READ))
            set_task(1.0, "@read_api", id+READ)
    }
}
@write_api(text[MAX_CMD_LENGTH], Task)
{

    new id = Task - WRITE
    if(is_user_connected(id))
    #if AMXX_VERSION_NUM != 182
    if (socket_is_writable(ip_api_socket, 100000))
    #endif
    {
        socket_send(ip_api_socket,text,charsmax (text));
        server_print("Yes! %s:writing the web for %s",PLUGIN, ClientName[id])
    }

}   
@read_api(Tsk)
{
    new id = Tsk - READ
    if(is_user_connected(id))
    {
        server_print "%s:reading %s coords",PLUGIN, ClientName[id]
        #if AMXX_VERSION_NUM != 182
        if (socket_is_readable(ip_api_socket, 100000))
        #endif
        socket_recv(ip_api_socket,buffer,charsmax(buffer) )
        if(!equal(buffer, "") && containi(buffer, "latitude") > charsmin && containi(buffer, "longitude") > charsmin && containi(buffer, "region") > charsmin)
        {
            if(containi(buffer, "latitude") > charsmin && containi(buffer, "longitude") > charsmin)
            {
                new float:lat[8],float:lon[8];
                copyc(lat, 6, buffer[containi(buffer, "latitude") + 10], '"');
                replace(lat, 6, ":", "");
                replace(lat, 6, ",", "");
    
                copy(ClientLAT[id], charsmax( ClientLAT[] ),lat)
    
                copyc(lon, 6, buffer[containi(buffer, "longitude") + 11], '"');
                replace(lon, 6, ":", "");
                replace(lon, 6, ",", "");
    
                copy(ClientLON[id], charsmax( ClientLON[] ),lon)
    
                server_print("%s's lat:%f|lon:%f",ClientName[id],str_to_float(ClientLAT[id]),str_to_float(ClientLON[id]))

                got_coords[id] = true
            }
            else if(containi(buffer, "region") > charsmin)
            {
                new region[MAX_NAME_LENGTH]
                copyc(region, charsmax(region), buffer[containi(buffer, "region") + 8], '"')
                replace(region, 6, ":", "");
                replace(region, 6, ",", "");
                server_print "EXTRACTED %s", region
                copy(ClientRegion[id],charsmax(ClientRegion[]),region)
            }
            else if(containi(buffer, "city") > charsmin)
            {
                new city[MAX_NAME_LENGTH]
                copyc(city, charsmax(city), buffer[containi(buffer, "city") + 6], '"')
                replace(city, 6, ":", "");
                replace(city, 6, ",", "");
                server_print "EXTRACTED %s", city
                copy(ClientCity[id],charsmax(ClientCity[]),city)
            }
            else if(containi(buffer, "country") > charsmin)
            {
                new country[MAX_NAME_LENGTH]
                copyc(country, charsmax(country), buffer[containi(buffer, "country") + 9], '"')
                replace(country, 6, ":", "");
                replace(country, 6, ",", "");
                server_print "EXTRACTED %s", country
                copy(ClientCountry[id],charsmax(ClientCountry[]),country)
            }
            if(socket_close(ip_api_socket) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
            else
                server_print "%s already closed the socket on %s!",api,ClientName[id]

            set_task(random_num(5,9)*1.0,"@country_finder",id+WEATHER)

        }
        else if(!got_coords[id] && g_socket_pass[id] < 10)
        {
            server_print "No %s buffer checking again",ClientName[id]
            set_task(0.2, "@read_api",id+READ)
            g_socket_pass[id]++
            server_print "pass:%i",g_socket_pass[id]
        }
        else if(!got_coords[id] && g_socket_pass[id] >= 10)
        {
            if(task_exists(id+READ))
            {
                remove_task(id)
                server_print"Removed task %d",id
            }
            server_print "Could not get a read =("
            client_putinserver(id)
        }
        else
        {
            if(socket_close(ip_api_socket) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
        }

    }
    return PLUGIN_CONTINUE
}
public ReadClientFromFile( )
{
    new szDataFromFile[ MAX_CMD_LENGTH ]
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/client_temp.ini" )
    new debugger = get_pcvar_num(g_debug)

    new f = fopen( szFilePath, "rt" )

    if( !f )
    {
        return
    }

    while( !feof( f ) )
    {
        fgets( f, szDataFromFile, charsmax( szDataFromFile ) )

        if( !szDataFromFile[ 0 ] || szDataFromFile[ 0 ] == ';' || szDataFromFile[ 0 ] == '/' && szDataFromFile[ 1 ] == '/' )
            continue

        trim
        (
            szDataFromFile
        )
        parse
        (
            szDataFromFile,
            Data[ SzAddress ], charsmax( Data[ SzAddress ] ),
            Data[ SzCity ], charsmax( Data[ SzCity ] ),
            Data[ SzRegion ], charsmax( Data[ SzRegion ] ),
            Data[ SzCountry ], charsmax( Data[ SzCountry] ),
            Data[ fLatitude ], charsmax( Data[ fLatitude ] ),
            Data[ fLongitude ], charsmax( Data[ fLongitude ] )
        )

        if(debugger)
            server_print "Read %s:: %s, %s, %s, %s, %s from file.", Data[ SzAddress ], Data[ SzCity ], Data[ SzRegion ], Data[ SzCountry ], Data[ fLatitude ], Data[ fLongitude ]

        TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
        g_clients_saved++

    }
    fclose( f )
    if(debugger)
        server_print "................Client Temp data file has %d IP addresses cached already.....................", g_clients_saved
}

@file_data(SzSave[MAX_CMD_LENGTH])
{
    server_print "%s|trying save", PLUGIN
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/client_temp.ini" )

    write_file(szFilePath, SzSave)
}
