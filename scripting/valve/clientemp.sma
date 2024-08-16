#define PROXY_SCRIPT "proxysnort.amxx" //This is used to prevent both plugins of mine from uncontrollably clutching sockets mod.
///If you do not use it, ignore or study it.
///https://github.com/djearthquake/amxx/blob/main/scripting/valve/proxysnort.sma
//#define SOCK_NON_BLOCKING (1 << 0)    /* Set the socket a nonblocking */
//#define SOCK_LIBC_ERRORS  (1 << 1)    /* Enable libc error reporting */
//////DUE TO GEO DATABASE AND MODULE BEING ASKEW TOO OFTEN

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
    *(__ [__)*|\ | >< Thurs 8th Aug 2024
    *.__)|   || \|/  \
    *    ℂ𝕝𝕚𝕖𝕟𝕥𝕖𝕞𝕡. Displays clients temperature. REQ:HLDS, AMXX, Openweather key.
    *    Get a free 32-bit API key from openweathermap.org. Pick metric or imperial.
    *    Copyleft (C) 2019-2023 .sρiηX҉.
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

    #if !defined SOCK_NON_BLOCKING
     #error Go make a new script or post and wait on forums/Discord if you are not autodidactic.
    #endif

    #define PLUGIN "Client's temperature"
    #define VERSION "1.9.2"
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
    #define MAX_IP_WITH_PORT_LENGTH    22
    #define MAX_IP_LENGTH              16
    #define charsmin                   -1
    #define MAX_MOTD_LENGTH            1536

    #define GLOBAL_SOCKET_BUFFER_SIZE           MAX_MENU_LENGTH  + MAX_RESOURCE_PATH_LENGTH

    #if !defined client_disconnected
    #define client_disconnected client_disconnect
    #endif

    #define COORD 3245
    #define READ 777
    #define WRITE 4444

    #pragma dynamic 9600000 // local cache growing

    //New Geo API v.187+/////////////////////////////////////

    new ClientLON[MAX_PLAYERS+1][8]
    new ClientLAT[MAX_PLAYERS+1][8]

    new bool:got_coords[ MAX_PLAYERS + 1 ]
    new const api[]= "ipwho.is"; //will see unassigned.psychz.net on NETSTAT DO NOT blacklist!
    new g_socket_pass[MAX_PLAYERS+1];
    new ip_api_socket
    new XAutoTempjoin
    /////////////////////////////////////////////////////////

    new bool:bAssisted;

    new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH];
    new ClientCountry[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
    new ClientCity[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
    new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
    new ClientRegion[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
    new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH] //ocassional run-time errors outofbounds
    new g_ClientTemp[MAX_PLAYERS+1][MAX_IP_LENGTH]

    new iRED_TEMP,iBLU_TEMP,iGRN_HI,iGRN_LO

    new bool:IS_SOCKET_IN_USE, bool:bServer;

    ///new g_vault

    new const g_szRequired_Files[][]={"GeoLite2-Country.mmdb","GeoLite2-City.mmdb"};
    new g_word_buffer[MAX_PLAYERS]
    new g_debug, g_timeout, Float:g_task

    new g_queue_weight, g_q_weight, g_maxmind
    new g_Weather_Feed, g_cvar_uplink, g_cvar_units, g_cvar_token, g_filepath[ MAX_NAME_LENGTH ]
    new g_szFile[ MAX_RESOURCE_PATH_LENGTH ][ MAX_RESOURCE_PATH_LENGTH ], g_admins, g_long;


    ///new g_constring[GLOBAL_SOCKET_BUFFER_SIZE][MAX_PLAYERS + 1]

    new g_buffer[ GLOBAL_SOCKET_BUFFER_SIZE ]//[MAX_PLAYERS + 1] //otherwise meshing of data can occur

    new g_api_buffer[ MAX_MOTD_LENGTH ]
    new g_api[ MAX_CMD_LENGTH + MAX_IP_WITH_PORT_LENGTH + 1 ]

    ///new bool:g_testingip[MAX_IP_LENGTH][MAX_PLAYERS +1]
    new bool:g_testingip[MAX_PLAYERS +1]


    new token[MAX_PLAYERS + 1]

    new const SOUND_GOTATEMP[] = "misc/Temp.wav";
    new bool:gotatemp[ MAX_PLAYERS + 1 ]
    new bool:somebody_is_being_help
    new g_players[ MAX_PLAYERS ],g_iHeadcount;
    new g_proxy_version, g_in_use

    new g_clients_saved
    new SzSave[MAX_CMD_LENGTH]

    new Trie:g_client_temp;

    new bool: b_Bot[MAX_PLAYERS+1];
    new bool: b_Admin[MAX_PLAYERS+1];
    new bool: b_CS;
    new bool: b_DoD;

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
};

new const faren_countries[][]={
    "Bahamas",
    "Cayman Islands",
    "Liberia",
    "Palau",
    "Federated States of Micronesia",
    "Marshall Islands",
    "United States"
};

new const DIC[] = "clientemp.txt";

enum _:Client_temp
{
    SzAddress[ MAX_IP_LENGTH ],
    SzCountry[ MAX_RESOURCE_PATH_LENGTH ],
    SzCity[ MAX_RESOURCE_PATH_LENGTH ],
    SzRegion[ MAX_RESOURCE_PATH_LENGTH ],
    fLatitude[ 8 ],
    fLongitude[ 8 ],
    iTemp[ MAX_IP_LENGTH ],
    ifaren[4]
    //iTimeLast[MAX_PLAYERS]
};

new Data[ Client_temp ];

static const unicoding_table[79][2][158] =
{///https://en.wikipedia.org/wiki/List_of_Unicode_characters
  ///https://www.fileformat.info/info/unicode/char/0165/index.htm
    {"\u2013", "-"},
    {"\u00c0", "A"},
    {"\u00c1", "A"},
    {"\u00c2", "A"},
    {"\u00c3", "A"},
    {"\u00c4", "A"},
    {"\u00c5", "A"},
    {"\u00c6", "Ae"},
    {"\u00c7", "C"},
    {"\u00c8", "E"},
    {"\u00c9", "E"},
    {"\u00ca", "E"},
    {"\u00cb", "E"},
    {"\u00cc", "I"},
    {"\u00cd", "I"},
    {"\u00ce", "I"},
    {"\u00cf", "I"},
    {"\u00d0", "Eth"},
    {"\u00d1", "N"},
    {"\u00d2", "O"},
    {"\u00d3", "O"},
    {"\u00d4", "O"},
    {"\u00d5", "O"},
    {"\u00d6", "O"},
    {"\u00d8", "O"},
    {"\u00d9", "U"},
    {"\u00da", "U"},
    {"\u00db", "U"},
    {"\u00dc", "U"},
    {"\u00ds", "Y"},
    {"\u00de", "Y"},
    {"\u00df", "S"},
    {"\u00e0", "a"},
    {"\u00e1", "a"},
    {"\u00e2", "a"},
    {"\u00e3", "a"},
    {"\u00e4", "a"},
    {"\u00e5", "a"},
    {"\u00e6", "ae"},
    {"\u00e7", "cc"},
    {"\u00e8", "e"},
    {"\u00e9", "e"},
    {"\u00ea", "e"},
    {"\u00eb", "e"},
    {"\u00ec", "i"},
    {"\u00ed", "i"},
    {"\u00ee", "i"},
    {"\u00ef", "i"},
    {"\u00f0", "eth"},
    {"\u00f1", "n"},
    {"\u00f2", "o"},
    {"\u00f3", "o"},
    {"\u00f4", "o"},
    {"\u00f5", "o"},
    {"\u00f6", "o"},
    {"\u00f7", "o"},
    {"\u00f8", "u"},
    {"\u00fa", "u"},
    {"\u00fb", "u"},
    {"\u00fc", "u"},
    {"\u00fd", "y"},
    {"\u00fe", "y"},
    {"\u00ff", "y"},
    {"\u0161", "s"},
    {"\u0130", "I"},
    {"\u0131", "i"},
    {"\u015",  "s"},
    {"\u021a", "T"},
    {"\u021b", "t"},
    {"\u017d", "Z"},
    {"\u0141", "L"},
    {"\u011f", "g"},
    {"\u0105", "a"},
    {"\u011b", "e"},
    {"\u0165", "t"},
    {"\u0103", "a"},
    {"\u0219", "s"},
    {"\u0144", "n"},
    {"\u017a", "z"}
};

public plugin_init()
{
    register_cvar("client-temp_version", VERSION, FCVAR_SERVER);

    register_plugin(PLUGIN, VERSION, AUTHOR);

    if(!lang_exists(DIC))
    {
        register_dictionary(DIC);
    }

    else

    {
        log_amx("%s %s by %s paused to prevent data key leakage from missing %s.", PLUGIN, VERSION, AUTHOR, DIC);
        pause "a";
    }

    g_cvar_units    = register_cvar("sv_units", "metric");
    g_cvar_token    = register_cvar("sv_openweather-key", "null", FCVAR_PROTECTED);
    g_cvar_uplink   = register_cvar("sv_uplink2", "GET /data/2.5/weather?q=");
    g_admins        = register_cvar("temp_admin", "1");
    g_debug         = register_cvar("temp_debug", "0");
    g_long          = register_cvar("temp_long", "1"); //Uses longitude or city to get weather
    g_timeout       = register_cvar("temp_block", "10"); //how long minimum in between client temp requests
    g_queue_weight  = register_cvar("temp_queue_weight", "15"); //# passes before putting queue to sleep
    g_proxy_version = get_cvar_pointer("proxy_action") ? get_cvar_pointer("proxy_action") : 0
    g_maxmind       = register_cvar("temp_maxmind", "0") //use Maxmind and Geo Module or built-in Amxx API
    XAutoTempjoin   =  register_cvar("temp_auto", "1");  // zero relies on Geo mod for now.


    register_clcmd("say !mytemp","Speak",0,"Shows your local temp.");
    register_clcmd("queue_test","@queue_test",ADMIN_SLAY,"Turns up the queue.");
    register_clcmd("queue_test2","@queue_test2",ADMIN_SLAY,"Puts self unto queue.");

    register_clcmd("!temp","@temp_test",ADMIN_SLAY,"Check temp specified IP.");

    set_task(60.0, "@the_queue",iQUEUE,"",0,"b"); //makes sure all players temp is read minimal socket hang

    g_task         = 5.0;
    g_q_weight     = 1
    g_client_temp = TrieCreate()
    ReadClientFromFile( )

    static SzModName[MAX_NAME_LENGTH]
    get_modname(SzModName, charsmax(SzModName));
    if(equal(SzModName, "cstrike"))
    {
        b_CS = true
    }
    else if (equal(SzModName, "dod"))
    {
        b_DoD = true
    }

}

public plugin_end()
{
    TrieDestroy(g_client_temp);
}

@temp_test(id,level,cid)
{
    static iArg1[MAX_IP_LENGTH]
    if( !cmd_access ( id, level, cid, 1 ) || !is_user_connected(id))
        return PLUGIN_HANDLED;

    g_testingip[id] = true
    gotatemp[id] = false

    read_argv(1,iArg1,charsmax(iArg1));
    ClientIP[id] = iArg1
    server_print("Copied IP as %s", ClientIP[id])
    copy(Data[SzAddress] , charsmax(Data[SzAddress]), ClientIP[id])

    client_print(id,print_chat,"Testing temp on IP %s",iArg1)
    server_print("%N testing %s", id, iArg1)
    @get_user_data(id)

    return PLUGIN_HANDLED;

}

public plugin_precache()
{
    if(file_exists("sound/misc/Temp.wav")){
        precache_sound(SOUND_GOTATEMP);
        //precache_generic("sound/misc/Temp.wav")
    }
        else
    {
        log_amx("Paused to prevent crash from missing %s.",SOUND_GOTATEMP);
        pause "a";
    }
}

@queue_test(id)
{
    if(is_user_connected(id))
    {
        change_task(iQUEUE, 10.0)
        client_cmd(id,"spk buttons/bell1.wav");
        server_print "Turning on queue per request by %s.",ClientName[id]
    }
    return PLUGIN_HANDLED;
}

@fixadmins(id)
{
    if(is_user_connected(id))
    {
        client_print id,print_chat,"Changed admin_temp 1 to allow admins to get temp."
        set_pcvar_num(g_admins, 1)
        gotatemp[id] = false
        ///client_cmd id, "spk ^"computer malfunction. system is on zero. system is on one now for temperature control^""
        change_task(iQUEUE, 10.0)
        client_temp_cmd(id)
    }
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
    static iDebug; iDebug = get_pcvar_num(g_debug)
    if(is_user_connected(id))
    {
        get_user_ip( id, ClientIP[id], charsmax( ClientIP[] ), WITHOUT_PORT );
        get_user_authid(id,ClientAuth[id],charsmax(ClientAuth[]))

        b_Bot[id] = is_user_bot(id) ? true : false

        if(iDebug)
            b_Bot[id] = equali(ClientAuth[id], "BOT") ? true : false

        b_Admin[id] = is_user_admin(id) ? true : false

        if(b_Bot[id] || is_user_hltv(id))
            return PLUGIN_HANDLED_MAIN
        if(!get_pcvar_num(XAutoTempjoin))
            return PLUGIN_HANDLED_MAIN

        if(equali(ClientIP[id], "127.0.0.1") && id > 0)
        {
            server_print "%N IP shows as 127.0.0.1, stopping %s script!", id, PLUGIN
            server_cmd( "kick #%d ^"Please reconnect we misread your ID^"", get_user_userid(id) );
            return PLUGIN_HANDLED;
        }

        if(!task_exists(id+WEATHER) || !task_exists(id))
        {
            if(b_Admin[id] && !get_pcvar_num(g_admins))
            {

                gotatemp[id] = true;
                return PLUGIN_HANDLED;
            }
            else
            {
                server_print("%N being put in server clientemp", id)
                client_putinserver_now(id)
            }
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

@country_finder(Tsk)
{
    new mask; mask = Tsk - WEATHER;
    static g_max; g_max = get_pcvar_num(g_maxmind)

    new Float:task_expand;task_expand = random_num(5,10)*1.0
    if(is_user_connected(mask))
    change_task(iQUEUE, 10.0)
    {
        if(equal(ClientIP[mask],"") || b_Admin[mask] && !g_testingip[mask])
        {
            server_print"We did not have the network address captured right."
            get_user_ip( mask, ClientIP[mask], charsmax( ClientIP[] ), WITHOUT_PORT );
        }

        Data[SzAddress] = ClientIP[mask]
        server_print(is_user_connected(mask)?"%N shows %s on country_finder":"Client shows %s on country_finder", mask, ClientIP[mask])

        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
            TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )

        if(equal(ClientCountry[mask],""))
        {
            server_print"We did not have the COUNTRY captured right.^nUsing Maxmind."
            #if AMXX_VERSION_NUM == 182
                geoip_country( ClientIP[mask], ClientCountry[mask], charsmax(ClientCountry[]) );
            #else
                geoip_country_ex( ClientIP[mask], ClientCountry[mask], charsmax(ClientCountry[]), LANG_SERVER );
            #endif
            if(equal(ClientCountry[mask],"") && !task_exists(mask+COORD))
            {
                 set_task(0.5,"@get_client_data", mask+COORD)
            }
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
            server_print"We did not have the CITY captured right."

            if(equal(ClientCity[mask],"") /*&& !task_exists(mask+COORD)*/)
            {
                !g_max ? set_task(0.5,"@get_client_data", mask+COORD) : geoip_city(ClientIP[mask],ClientCity[mask],charsmax(ClientCity[]),charsmin)&server_print("Using Maxmind.")
                return
            }
        }

        if(equal(ClientRegion[mask],""))
        {
            server_print"We did not have the REGION captured right."
            if(equal(ClientRegion[mask],""))
            {
                !g_max ? set_task(0.5,"@get_client_data", mask+COORD) : geoip_region_name(ClientIP[mask],ClientRegion[mask],charsmax(ClientRegion[]),charsmin)&server_print("Using Maxmind.")
                return
            }
        }

        //Transfer coords from other API into this one.
        if(got_coords[mask])
        {
            Data[fLatitude] = ClientLAT[mask]
            Data[fLongitude] = ClientLON[mask]
        }
        else
        {
            if(!task_exists(mask+COORD))
            {
                set_task(0.5,"@get_client_data", mask+COORD)
                return
            }
        }
        Data[SzCity] = ClientCity[mask]
        Data[SzRegion] = ClientRegion[mask]

        if(!TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        {
            TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
            server_print "Saving Client to check temp file."
            formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", Data[SzAddress], Data[SzCity], Data[SzRegion], Data[SzCountry], Data[fLatitude], Data[fLongitude]) ///likes quotes not comma TAB
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
        set_task(task_expand,"@que_em_up", mask)

    }
}

@speakit(id)
{
    static new_temp;
    if(is_user_connected(id))
    {
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ) && !equali(Data[ iTemp ], ""))
            new_temp = Data[iTemp]
        else
            new_temp = str_to_num(g_ClientTemp[id])

        //Speak the temperature.
        num_to_word(new_temp, g_word_buffer, charsmax(g_word_buffer))
        if(new_temp < 0)
            client_cmd(id, "spk ^"temperature right now is %s degrees sub zero^"", g_word_buffer );

        else
            client_cmd(id, "spk ^"temperature right now is %s degrees^"", g_word_buffer );

        server_print "Spoke temp for^n^n%s",ClientName[id]
    }
}

public Speak(id)
{
    if(is_user_connected(id))
    {
        if(!get_pcvar_num(XAutoTempjoin))
            client_putinserver_now(id)

        if(b_Admin[id])
        {
            if(!g_testingip[id])
                get_pcvar_num(g_admins) ? @speakit(id) : @fixadmins(id)
        }

        if(gotatemp[id]) //remind them otherwise fetch it
        {
            @speakit(id)
        }
        else
        {
            client_temp_cmd(id) //fetch
            client_cmd id, "spk ^"temperature is going through now^""
        }
    }
}

public client_temp_cmd(id)
{
    //if(id>0 && id <= MaxClients)
    if(is_user_connected(id))
    {
        if(got_coords[id])
        {
            server_print "client_temp_cmd for slot:%d|%s", id, ClientName[id]
            if(!task_exists(id))
            {
                get_playersnum() > 2 ? set_task(random_num(8,16)*1.0,"client_temp_filter", id) : set_task(1.0,"client_temp_filter", id)
                server_print "Making a filter task for %s", ClientName[id]
            }
        }
        else
        {
            set_task(0.1, "@get_client_data", id+COORD)
            //@country_finder(id+WEATHER)
        }
    }
}

@que_em_up(m)
{
    server_print "q em up^nWhen somebody connects it checks all here."
    if(is_user_connecting(m))
    {
        change_task(m,20.0)
        server_print "Rescheduling %n until they connect.", m
    }
    else if(is_user_connected(m))
    {
        server_print "%s is still connected at moment.", ClientName[m]

        if(b_Admin[m] && get_pcvar_num(g_admins) == 0 && !g_testingip[m])
            gotatemp[m] = true;

        else if(!gotatemp[m] && m > 0)
        {
            get_playersnum() > 2 ? set_task(random_num(5,12)*1.0,"client_temp_cmd",m) :

            set_task(1.0,"client_temp_cmd",m)

            server_print("q temp que em up cmd tsk made %s", ClientIP[m])
            ////////////////////////////////////////////////////////////////////////////////
            server_print "We do not have %s's temp yet.",ClientName[m]

            if(task_exists(iQUEUE))
            {
                change_task(iQUEUE, 30.0)
                server_print "Resuming queue per %s connected.",ClientName[m]
                @get_user_data(m)
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
    if(g_iHeadcount == 0)
    {
        server_print "NOBODY IS ONLINE HIBERNATING THE QUEUE CYCLE"
        change_task(iQUEUE, 1800.0)
        remove_task(id);
    }
}

public client_temp_filter(id)
{
    if( is_user_connected(id) )     //still get temp post disco
    {
        server_print "CLIENT TEMP FILTER FUNCTION"
        if(b_Admin[id] && g_testingip[id])
            goto JUMP
        if (b_Bot[id] || b_Admin[id] && !get_pcvar_num(g_admins) )
            return PLUGIN_HANDLED_MAIN;
        JUMP:
        server_print "Temp task will be accessed soon"
        if(!gotatemp[id])
        {
            if(!IS_SOCKET_IN_USE)
            {
                if(equali(ClientIP[id], ""))
                    get_user_ip( id, ClientIP[id], charsmax(ClientIP[]), WITHOUT_PORT )
                server_print("Filter %s", ClientIP[id])
                client_temp(id)
            }
            else
            {
                g_in_use++
                server_print "Socket shows in use. Pass(%d)", g_in_use
                if(!somebody_is_being_help)
                    goto RESET

                if(g_in_use>3)
                {
                    RESET:
                    IS_SOCKET_IN_USE = false
                    g_in_use = 0
                }

                if(!task_exists(id))
                {
                    set_task(random_num(10,20)*1.0,"client_temp",id);
                    server_print "Setting task."
                }
                else
                    change_task(id,random_num(7,11)*1.0)
                if(get_playersnum() > 3 && task_exists(id+WEATHER))
                {
                    change_task(id+WEATHER,random_num(20,30)*1.0);
                    server_print "Queuing %s's weather socket for %f to prevent lag", ClientName[id], get_pcvar_num(g_timeout)*3.0/1.5
                }

            }

        }

    }

    return PLUGIN_CONTINUE;
}

public client_temp(id)
{
    if(!gotatemp[id] && !is_user_hltv(id))
    {
        server_print "client_temp function"
        Data[ SzAddress ] = ClientIP[id]
        server_print("client_temp %s", ClientIP[id])
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        {
            static country[ 4 ];

            #if AMXX_VERSION_NUM == 182
                geoip_code3( ClientIP[id], country );
            #else
                geoip_code3_ex( ClientIP[id], country );
            #endif

            for (new heit;heit < sizeof faren_country;heit++)

            if(equali(country, faren_country[heit]))
            {
                set_pcvar_string(g_cvar_units, "imperial")
                Data[ifaren] = "1"
            }
            else
            {
                set_pcvar_string(g_cvar_units, "metric")
                Data[ifaren] = "0"
            }

            TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
            server_print "Adding Client units to check temp"


            get_datadir(g_filepath, charsmax(g_filepath));

            //////////THIS STOPS CRASHING SERVER DUE TO MAXMIND NOT BEING ON SERVER.
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
            //if (task_exists(id+WEATHER))
             //   return PLUGIN_HANDLED;

            if(containi(ClientIP[id], "127.0.0.1") != charsmin)
            {
                server_print "%s IP shows as 127.0.0.1, stopping script!", ClientName[id]
                return PLUGIN_HANDLED;
            }
            ////////////GEO COORDINATES GATHERING/////////////////////////////////
            ///Amxx module w/ Maxmind geoip database
            ///g_lat[id] = geoip_latitude(ClientIP[id]);
            ///g_lon[id] = geoip_longitude(ClientIP[id]);
            static Float:timing;
            timing = g_task+5.0;

            static ping, loss;

            get_user_ping(id,ping,loss);
            static Float:timing2;
            timing2 = tickcount() * (ping * (0.7)) + power(loss,4);

            set_task( timing+timing2, "Weather_Feed", id+WEATHER, ClientIP[id], charsmax(ClientIP[]) );
            server_print("Client temp IP %s", ClientIP[id])

            g_task = timing;

            if(g_task > 20.0) g_task = 5.0;


            #if defined LOG
            if(/*(equal(ClientName[id],"") && */g_testingip[id])
            {
                //reformat name with test
                copy(ClientName[id],charsmax(ClientName[]), "TEST");
            }

            get_user_authid(id,ClientAuth[id],charsmax(ClientAuth[]))

            log_amx "Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined. |lat:%f lon:%f|", ClientName[id], ClientAuth[id], Data[SzCountry], Data[SzCity], Data[SzRegion], str_to_float(Data[fLatitude]), str_to_float(Data[fLongitude]);
            #endif

            if(get_pcvar_num(g_debug) && b_Admin[id] )
                set_task(float(get_pcvar_num(g_timeout)), "needan", id+ADMIN);
        }
        else
        {
            client_putinserver(id)
        }

    }
    return PLUGIN_CONTINUE;
}

public needan(keymissing)
{
    static id; id = keymissing - ADMIN;
    get_pcvar_string(g_cvar_token, token, charsmax (token));
    if(is_user_connected(id))
    {

        if (equal(token, "null") || equal(token, "") )
        {
            if ( b_CS || b_DoD  )

            {
                static motd[128];
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

}

public client_disconnected(id)
{
    new iHeadcount
    if(b_Bot[id]) return

    Data[ SzAddress ] = ClientIP[id]

    if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
    else
        return

    if( iHeadcount > 0 )
    {
        for (new admin=1; admin<=iHeadcount; admin++)

        if(is_user_connected(admin) && !b_Bot[admin])
        {
            if (!b_Admin[admin])
            {
                if ( AMXX_VERSION_NUM == 182 || !b_CS && AMXX_VERSION_NUM != 182 )
                client_print admin,print_chat,"%s from %s disappeared on %s, %s radar.", ClientName[id], Data[SzCountry], Data[SzCity], Data[SzRegion]
                #if AMXX_VERSION_NUM != 182
                client_print_color admin,0, "^x03%n^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", id, Data[SzCountry], Data[SzCity], Data[SzRegion]
                #endif
            }

            else
            {
                if ( AMXX_VERSION_NUM == 182 || !b_CS && AMXX_VERSION_NUM != 182 )
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
    if(somebody_is_being_help)
        set_task(45.0,"@unbusy_disco", id)
}

@unbusy_disco(id)
{
    somebody_is_being_help = false
    IS_SOCKET_IN_USE = false;
    bServer = false
}

public Weather_Feed(ClientIP[MAX_PLAYERS+1][], feeding)
{
    if(get_pcvar_num(g_debug))
        server_print "Feeding %s", PLUGIN
    static id; id = feeding - WEATHER;

    if(is_user_connected(id) && !gotatemp[id])
    {

        if(get_pcvar_num(g_debug))
            log_amx("Client_Temperature:Starting the sockets routine...");

        static Soc_O_ErroR2, uplink[27], units[9];
        static constring[MAX_MENU_LENGTH]

        get_pcvar_string(g_cvar_uplink, uplink, charsmax(uplink) );
        get_pcvar_string(g_cvar_token, token, charsmax(token) );

        if(!is_user_connected(id))
        {
            server_print "User disconnected while getting temp socket ready."
            ///return
        }
        #if defined SOCK_NON_BLOCKING
            g_Weather_Feed = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS); //used newer inc on 182;compiles works ok
        #else
            g_Weather_Feed = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2); //tested 182 way
        #endif

        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
            //Make sure client gets the right unit
            str_to_num(Data[ifaren]) == 1 ? copy(units,charsmax(units),"imperial") : copy(units,charsmax(units),"metric")
        else
        {
            //fall-back
            equali(ClientCountry[id],"United States") ? copy(units,charsmax(units),"imperial") : copy(units,charsmax(units),"metric")
        }
        //USA SHOULD NEVER SLIP METRIC DUE TO ANY ERROR ON MY PART
        for(new imperial; imperial < sizeof faren_countries;imperial++)
        if(containi(ClientCountry[id],faren_countries[imperial]) > charsmin)
            copy(units,charsmax(units),"imperial")
        else //Handful of countries are like USA
            copy(units,charsmax(units),"metric")

        //Pick what is more reliable or chosen first on cvar lon+lat or city to acquire temp
        if(get_pcvar_num(g_long) && got_coords[id])
        {
            formatex(constring, charsmax(constring), "GET /data/2.5/weather?lat=%f&lon=%f&units=%s&APPID=%s&u=c HTTP/1.1^nHost: api.openweathermap.org^n^n", str_to_float(Data[fLatitude]), str_to_float(Data[fLongitude]), units, token)
        }
        else if (!equali(ClientCity[id], ""))
        {
            static city_space_remover[MAX_RESOURCE_PATH_LENGTH]
            copy(city_space_remover,charsmax(city_space_remover),ClientCity[id])
            replace(city_space_remover,charsmax(city_space_remover)," ", "")
            formatex(constring,charsmax(constring), "%s%s&units=%s&APPID=%s&u=c HTTP/1.1^nHost: api.openweathermap.org^n^n", uplink, city_space_remover, units, token);
        }
        else
        {
            if(get_pcvar_num(g_debug))
                server_print "Unable to get %s due to no city nor lon and lat!! on %s", PLUGIN, ClientName[id]
            log_amx "Unable to get %s due to no city nor lon and lat!! on %s", PLUGIN, ClientName[id]
            return
        }
        if(get_pcvar_num(g_debug))
            server_print "Is server busy?"
        if(!bServer)
        {
            set_task(1.0, "@write_web", id+WEATHER, constring, charsmax(constring) );
            //set_task(1.0, "@write_web", id+WEATHER);

            if(get_pcvar_num(g_debug))
            {
                log_amx("This is where we are trying to get weather from");
                log_amx(constring);
                log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
            }

            set_task(1.5, "@read_web", id+WEATHER);
            bServer = true
            if(get_pcvar_num(g_debug))
                server_print "Server made busy"
        }
        else
        if(get_pcvar_num(g_debug))
            server_print "Server shows busy"

    }

}

@write_web(text[MAX_MENU_LENGTH], Task)
//@write_web(Task)
{
    static id; id = Task - WEATHER
    ///if(is_user_connected(id))
    if(id > 0 && id <=MaxClients)
    {
        if(get_pcvar_num(g_debug))
            server_print "%s:Is %s soc writable?",PLUGIN, ClientName[id]
        #if AMXX_VERSION_NUM != 182
        if (socket_is_writable(g_Weather_Feed, 0))
        #endif
        {
            //IS_SOCKET_IN_USE = true;
            socket_send(g_Weather_Feed,text,charsmax(text));
            if(get_pcvar_num(g_debug))
                server_print "Yes! %s:writing the web for ^n%s",PLUGIN, ClientName[id]
            //@latch(id)
        }
        else
        {
            server_print "Yes! %s:writing the web for ^n%s",PLUGIN, ClientName[id]
        }

    }

}

@latch(id)
{
    if(id > 0 && id <=MaxClients)
    {
        if(is_plugin_loaded(PROXY_SCRIPT,true)!=charsmin)
        {
            if(get_pcvar_num(g_debug))
                server_print("Proxy snort detected!")
            if( g_proxy_version )
            {
                callfunc_begin("@lock_socket",PROXY_SCRIPT)
                callfunc_end()
            }
            else
                log_amx("Be sure to download and install %s!", PROXY_SCRIPT);
        }
    }
}

@read_web(feeding)
{
    static id; id = feeding - WEATHER
    static iBugger; iBugger=get_pcvar_num(g_debug)
    ///static iTime; iTime = get_systime();
    ///if(!IS_SOCKET_IN_USE)
    if(!b_Bot[id] && id > 0)
    {
        Data[SzAddress] = ClientIP[id]
        /////////////////////////////////////////////////////
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
            TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
        //if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ) && !equali(Data[ iTemp ], "")) //~20 min exp date instead. works across maps
        static iFaren; iFaren = str_to_num(Data[ifaren]);

        if(equal(ClientCity[id], ""))
        {
            geoip_city(ClientIP[id],ClientCity[id],charsmax(ClientCity[]),LANG_SERVER)
            Data[SzCity] = ClientCity[id]
            TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )
        }

        if(IS_SOCKET_IN_USE && !gotatemp[id])
        {
            if(iBugger)
            {
                server_print "Socket in use for %s", ClientName[id]
            }
            goto END
        }

        else
        if(g_proxy_version && is_plugin_loaded(PROXY_SCRIPT,true)!=charsmin && !IS_SOCKET_IN_USE && !gotatemp[id])
        {
            callfunc_begin("@lock_socket",PROXY_SCRIPT) ? callfunc_end() : log_amx("Be sure to download and install %s!", PROXY_SCRIPT);
        }

        if(iBugger)
            server_print "%s:reading %s temp",PLUGIN, ClientName[id]  ///looping
        IS_SOCKET_IN_USE = true;

        #if AMXX_VERSION_NUM != 182
        if (socket_is_readable(g_Weather_Feed, 0))
        #endif
        socket_recv(g_Weather_Feed,g_buffer,charsmax(g_buffer) )
        if (!equal(g_buffer, "") /*&& IS_SOCKET_IN_USE == true*/ && containi(g_buffer, "temp") > charsmin)
        {
            server_print "Buffer loaded for %s.", ClientName[id]
            ///IS_SOCKET_IN_USE = true

            if (get_timeleft() > 9) ///Refrain from running sockets on map change!
            {
                if(iBugger)
                    server_print "%s:Ck temp",PLUGIN
                static out[8];
                copyc(out, 6, g_buffer[containi(g_buffer, "temp") + 6], '"');
                replace(out, 6, ":", "");
                replace(out, 6, ",", "");

                #define PITCH (random_num(90,111))
                emit_sound(id, CHAN_STATIC, SOUND_GOTATEMP, 5.0, ATTN_NORM, 0, PITCH);
                gotatemp[id] = true;

                static Float:Real_Temp; Real_Temp = floatstr(out);

                formatex(g_ClientTemp[id], charsmax (g_ClientTemp[]), "%i",floatround(Real_Temp));
                static new_temp; new_temp = str_to_num(g_ClientTemp[id])

                if(iFaren)
                {
                    iRED_TEMP =  70;
                    iBLU_TEMP =  45;
                    iGRN_HI   =  69;
                    iGRN_LO   =  46;
                }
                else
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
                gotatemp[id] = true
                TrieSetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data )

                ////////////////////////////////
                #define HUD_PLACE1 random_float(-0.75,-1.10),random_float(0.25,0.50)
                #define HUD_PLACE2 random_float(0.75,2.10),random_float(-0.25,-1.50)
                ////////////////////////////////
                if(iBugger)
                    //server_print "New Temp is %i", str_to_num(Data[iTemp]) //new_temp
                    server_print "New Temp is %i", Data[iTemp] //new_temp
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


                if ( b_CS || b_DoD  )
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
                num_to_word(new_temp, g_word_buffer, charsmax(g_word_buffer))

                if(iBugger)
                    server_print("Faren before speak = %i",str_to_num(Data[ifaren]) )
                if(iFaren)
                {
                    if(new_temp < 0)
                        client_cmd(0, "spk ^"temperature right now is %s degrees sub zero^"", g_word_buffer );

                    else
                        client_cmd(0, "spk ^"temperature right now is %s degrees^"", g_word_buffer );
                }

                else
                {
                    if(new_temp < 0)
                        client_cmd(0, "spk ^"temperature right now is %s degrees sub zero celsius^"", g_word_buffer );

                    else
                        client_cmd(0, "spk ^"temperature right now is %s degrees celsius^"", g_word_buffer );

                }
                if(equali(ClientCity[id],"") && containi(g_buffer, "name") > charsmin) //city blank from Geodat?
                {
                    static out[MAX_NAME_LENGTH];
                    copyc(out, charsmax(out), g_buffer[containi(g_buffer, "name") + 6], '"');
                    replace(out, charsmax(out), ":", "");
                    replace(out, charsmax(out), ",", "");
                    log_amx "%s city is %s was missing on local geoip", ClientName[id], out
                    copy(ClientCity[id],charsmax(ClientCity[]),out)
                    if(iBugger)
                        server_print "%s city is %s",ClientName[id], out
                }
                #if defined MOTD
                    log_amx "^"Temp is %i degrees in %s, %s, %s.^"", floatround(Real_Temp), ClientCity[id], ClientRegion[id], ClientCountry[id]
                    log_to_file("clientemp.log", "^"Temp is %i degrees in %s, %s, %s.^"", floatround(Real_Temp), ClientCity[id], ClientRegion[id], ClientCountry[id])
                #endif
                if(socket_close(g_Weather_Feed) == 1)
                {
                    if(iBugger)
                        server_print "%s finished %s reading",PLUGIN, ClientName[id]
                    set_task(5.0, "@mark_socket_client", id);

                    if(g_proxy_version && find_plugin_byfile(PROXY_SCRIPT) != charsmin  && callfunc_begin("@mark_socket", PROXY_SCRIPT))
                    {
                        static work[MAX_PLAYERS]
                        format(work,charsmax(work),PLUGIN,"")
                        callfunc_push_str(work)
                        callfunc_end()
                    }


                }
                /*
                if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
                {
                    Data[ iTimeLast ] = iTime;
                }
                */

                IS_SOCKET_IN_USE = false
                return PLUGIN_CONTINUE;
            }
            else
            {
                set_cvar_num("mp_timelimit", get_cvar_num("mp_timelimit")+60)
                client_print 0, print_chat, "Adding time to finish pending admin temp task."
            }
        }
        else if(!gotatemp[id])
            set_task(0.1, "@read_web",id+WEATHER);
        else
        {
            if(task_exists(id+WEATHER))
                remove_task(id+WEATHER)

            socket_close(g_Weather_Feed);
            bAssisted = false
            @mark_socket_client(id);
        }
        if(g_testingip[id])
        {
            g_testingip[id] = false
            gotatemp[id] = true
        }
    }
    END:
    return PLUGIN_HANDLED
}

@mark_socket(work[MAX_PLAYERS])
{
    if(get_pcvar_num(g_debug))
        server_print "Socket marked as not being in use"
    IS_SOCKET_IN_USE = false;
    bServer = false //unbusy for next in queue
    somebody_is_being_help = false
    if(!equal(work, ""))
        if(get_pcvar_num(g_debug))
            server_print "%s | %s locking socket!", PLUGIN, work
}

@mark_socket_client(id)
{
    IS_SOCKET_IN_USE = false;
    bServer = false //unbusy for next in queue
    somebody_is_being_help = false
    is_user_connected(id) || is_user_connecting(id) ? server_print("Socket is being freed up from %s", ClientName[id]) : server_print("Socket is being freed up from client.")

    if(g_testingip[id])
    {
        g_testingip[id] = false
        gotatemp[id] = false
        got_coords[id] = false
    }
}

@lock_socket()
{
    IS_SOCKET_IN_USE = true
    if(get_pcvar_num(g_debug))
        server_print "%s other plugin locking socket!", PLUGIN
}

@unlock_socket()
{
    IS_SOCKET_IN_USE = false
    if(get_pcvar_num(g_debug))
        server_print "%s other plugin releasing socket!", PLUGIN
    change_task(iQUEUE, 10.0)
}

@the_queue(player)
{
    //Assure admins queue is really running
    server_print "^n^n---------------- The Q -------------------^n%s queue is running.^n------------------------------------------",PLUGIN
    //How many runs before task is put to sleep given diminished returns
    static gopher; gopher = get_pcvar_num(g_queue_weight)

    get_players(g_players,g_iHeadcount,"ch")

    for(new player;player < sizeof g_players; ++player)

    if(g_players[player] > 0 && g_players[player] <= MaxClients && !b_Bot[g_players[player]])
    {
        new client = g_players[player];
        //Make array of non-bot connected players who need their temp still.
        //spread tasks apart to go easy on sockets with player who are in game and need their temps taken!
        if(!gotatemp[client] /* && !bAssisted */)
        {
            //ATTEMPT STOP TASKS FROM BEING BACK-TO-BACK
            ////bAssisted = true

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
                    got_coords[client] ? client_temp_cmd(client) : set_task(queued_task++*1.0,"@country_finder",client+WEATHER);
                    ///got_coords[client] ?  client_temp_cmd(client) : set_task(1.0, "@get_client_data", client+COORD)
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
                change_task(iQUEUE, 100.0) //make cvar for sleep time
                server_print "Pass: %i: the Queue is going to sleep.^n------------------------------------------", gopher
                g_q_weight = 1;
            }

        }

    }
    server_print "^n^n---------------- The Q -------------------^n"
    bAssisted = false
    somebody_is_being_help = false
}

public client_putinserver_now(id)
{
    if(get_pcvar_num(g_debug))
        server_print("ID:%d entered!",id)
    if(is_user_connected(id))
    {
        if(!task_exists(id))
        {
            set_task(0.5,"@get_user_data", id)
        }
    }
}

@get_user_data(id)
{
    if(is_user_connected(id))
    {

        if(!g_testingip[id])
        {
            get_user_ip( id, ClientIP[id], charsmax(ClientIP[]), WITHOUT_PORT)
            get_user_name(id, ClientName[id], charsmax(ClientName[]))
            copy(Data[ SzAddress ], charsmax(Data[ SzAddress ]), ClientIP[id])
            server_print("%N is not testing this ip", id)
        }
        else
        {
            //reformat name with test
            copy(ClientName[id],charsmax(ClientName[]), "TEST");
            server_print("%N test on %s precopy", id, ClientIP[id])
            copy(Data[ SzAddress ], charsmax(Data[ SzAddress ]), ClientIP[id])
            server_print("%N test on %s postcopy", id, ClientIP[id])
        }

        if(get_pcvar_num(g_debug))
            server_print "%s,%s",ClientName[id],ClientIP[id]
        if(TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        {
            server_print "%s ip is already cached. -%s.", ClientName[id], PLUGIN

            copy( ClientLAT[id], charsmax(ClientLAT[]), Data[ fLatitude ])
            copy( ClientLON[id], charsmax(ClientLAT[]), Data[ fLongitude ])

            //Not using Maxmind for GeoTrio. Using newly built cache. Have yet to see omitted city and region as Maxmind does often in Middle East especially.
            copy(ClientCountry[id],charsmax(ClientCountry[]), Data[ SzCountry ])

            copy(ClientCity[id],charsmax(ClientCity[]), Data[ SzCity ])

            copy(ClientRegion[id],charsmax(ClientRegion[]), Data[ SzRegion ])

            //was working on not checking so much like 45 min spread

            ////if( Data[ iTimeLast ] <= iTime - 45 * 60 * 1000) //do not recheck for another 45 min CVAR later

            ///gotatemp[id] = true

            got_coords[id] = true

            ////@country_finder(id+WEATHER)
            ///set_task(1.0,"@que_em_up", id) //looping
            if(b_Admin[id] && get_pcvar_num(g_admins) || g_testingip[id] || !b_Admin[id])
                @the_queue(id)
        }
        else if(!TrieGetArray( g_client_temp, Data[ SzAddress ], Data, sizeof Data ))
        {
            server_print "%s ip is NOT cached. -%s.", ClientName[id], PLUGIN
             #if AMXX_VERSION_NUM == 182
                geoip_country( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]) );
            #else
                geoip_country_ex( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]), LANG_SERVER );
            #endif
            //set_task(0.5,"@get_client_data", id+COORD)
        }
    }
}

@get_client_data(goldsrc)
{
    new Soc_O_ErroR2,
    id; id = goldsrc - COORD
    if(is_user_connected(id)) //cvar later to stop after disco or not
    //if(is_user_connected(id) && !equal(ClientIP[id], ""))
    {
        ///static constring[MAX_CMD_LENGTH + MAX_IP_WITH_PORT_LENGTH + 1]
        ip_api_socket = socket_open(api, 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
        formatex(g_api, charsmax(g_api), "GET http://%s/%s HTTP/1.1^nHost: %s^n^n", api, ClientIP[id], api)
        if(get_pcvar_num(g_debug))
            server_print "%s", g_api

        if(!task_exists(id+WRITE))
            set_task(0.4, "@write_api", id+WRITE,g_api, charsmax(g_api))

        if(!task_exists(id+READ))
            set_task(0.6, "@read_api", id+READ)
        //announce or make menu so they can keep it silent. Spooks some clients.
        ///client_print 0, print_chat, "%s %s %s Checking your city temp!", PLUGIN, AUTHOR, VERSION
    }
}

@write_api(text[MAX_CMD_LENGTH + MAX_IP_WITH_PORT_LENGTH + 1], Task)
{

    static id; id = Task - WRITE
    if(is_user_connected(id))
    {
        ///@latch(id)
        #if AMXX_VERSION_NUM != 182
        if (socket_is_writable(ip_api_socket, 0))
        #endif
        {
            IS_SOCKET_IN_USE = true
            socket_send(ip_api_socket,text,charsmax(text));
            if(get_pcvar_num(g_debug))
                server_print("Yes! %s:writing the web for %s",PLUGIN, ClientName[id])
        }
        else
        {
            remove_task(id+READ) && remove_task(id+WRITE)
            server_print("%s %s socket wasn't writable", PLUGIN,ClientName[id])
            set_task(0.5,"@get_client_data", id+COORD)
        }
    }
}

@read_api(Tsk)
{
    static id; id = Tsk - READ
    new msg[MAX_MOTD_LENGTH+1]
    if(is_user_connected(id) && !got_coords[id])
    #if AMXX_VERSION_NUM != 182
    if(socket_is_readable(ip_api_socket, 0))
    {
    #endif
        socket_recv(ip_api_socket,g_api_buffer,charsmax(g_api_buffer) )
        if(!equal(g_api_buffer, "") )
        {
            if(get_pcvar_num(g_debug))
                server_print "%s:reading %s coords",PLUGIN, ClientName[id]

            IS_SOCKET_IN_USE = true
            copyc(msg, charsmax(msg), g_api_buffer[containi(msg, "{") + 1], '}')

            if(containi(msg, "latitude") > charsmin && containi(msg, "longitude") > charsmin)
            {
                new float:lat[8],float:lon[8];
                copyc(lat, 6, msg[containi(msg, "latitude") + 10], '"');
                replace(lat, 6, ":", "");
                replace(lat, 6, ",", "");

                copy(ClientLAT[id], charsmax( ClientLAT[] ),lat)

                copyc(lon, 6, msg[containi(msg, "longitude") + 11], '"');
                replace(lon, 6, ":", "");
                replace(lon, 6, ",", "");

                copy(ClientLON[id], charsmax( ClientLON[] ),lon)

                server_print("%s's lat:%f|lon:%f",ClientName[id],str_to_float(ClientLAT[id]),str_to_float(ClientLON[id]))
            }
            if(containi(msg, "^"region^"") > charsmin)
            {
                new region[MAX_RESOURCE_PATH_LENGTH]
                copyc(region, charsmax(region), msg[containi(msg, "^"region^"") + 10], '"')
                replace(region, charsmax(region), ":", "");
                replace(region, charsmax(region), ",", "");
                remove_quotes(region)
                server_print "EXTRACTED %s", region

                if(contain(region, "\u")>charsmin)
                    unicoding_replace(region)

                copy(ClientRegion[id],charsmax(ClientRegion[]),region)
            }
            if(containi(msg, "^"city^"") > charsmin)
            {
                new city[MAX_RESOURCE_PATH_LENGTH]
                copyc(city, charsmax(city), msg[containi(msg, "^"city^"") + 8], '"')
                replace(city, charsmax(city), ":", "");
                replace(city, charsmax(city), ",", "");
                server_print "EXTRACTED %s", city

                if(contain(city, "\u")>charsmin)
                    unicoding_replace(city)

                copy(ClientCity[id],charsmax(ClientCity[]),city)
            }
            if(containi(msg, "^"country^"") > charsmin)
            {
                new country[MAX_RESOURCE_PATH_LENGTH]
                copyc(country, charsmax(country), msg[containi(msg, "^"country^"") + 11], '"')
                replace(country, charsmax(country), ":", "");
                replace(country, charsmax(country), ",", "");
                server_print "EXTRACTED %s", country

                if(contain(country, "\u")>charsmin)
                    unicoding_replace(country)

                copy(ClientCountry[id],charsmax(ClientCountry[]),country)
            }
            got_coords[id] = true
            IS_SOCKET_IN_USE = false
            if(socket_close(ip_api_socket) == 1)
            {
                server_print "%s finished %s reading",PLUGIN, ClientName[id]

            }
            else
            {
                server_print "%s already closed the socket on %s!",api,ClientName[id]
            }

            ////if(!somebody_is_being_help)
            set_task(random_num(2,7)*1.0,"@country_finder",id+WEATHER);

        }
        else if(g_socket_pass[id] < 3 && (!got_coords[id] || equal(ClientCountry[id],"") || equal(ClientCity[id],"") || equal(ClientRegion[id],"")))
        {
            server_print "No %s GEO buffer checking again",ClientName[id]
            ///set_task(0.5, "@read_api",id+READ)
            set_task(1.0,"@get_client_data", id+COORD)

            g_socket_pass[id]++
            server_print "pass:%i",g_socket_pass[id]

        }
        else if(!got_coords[id] && g_socket_pass[id] >= 3)
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
            {
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
                set_task(random_num(2,7)*1.0,"@country_finder",id+WEATHER);
            }
            else
                log_amx("Trouble closing API socket.")

            IS_SOCKET_IN_USE = false

        }

    }
    else
    {
        socket_close(ip_api_socket)
        remove_task(id+READ) && remove_task(id+WRITE)
        IS_SOCKET_IN_USE = false
    }
    IS_SOCKET_IN_USE = false
    return PLUGIN_CONTINUE
}

stock unicoding_replace(szLettercode[MAX_RESOURCE_PATH_LENGTH])
{
    for(new a; a < sizeof unicoding_table; a++)
    {
        for(new b; b < sizeof unicoding_table[]; b++)
        {
            for(new c; c < sizeof unicoding_table[][];c++)
            {
                replace(szLettercode, charsmax(szLettercode), unicoding_table[a][0], unicoding_table[a][1])
            }
        }
    }
    return szLettercode
}

public ReadClientFromFile( )
{
    static szDataFromFile[ MAX_CMD_LENGTH ]
    static szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/client_temp.ini" )
    static debugger; debugger = get_pcvar_num(g_debug)

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
            ///Data[ iTimeLast ], charsmax(Data[ iTimeLast ] )
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
    if(get_pcvar_num(g_debug))
        server_print "%s|trying save", PLUGIN

    static szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/client_temp.ini" )

    write_file(szFilePath, SzSave)
}

stock ExplodeString( p_szOutput[][], p_nMax, p_nSize, p_szInput[], p_szDelimiter )
{///https://forums.alliedmods.net/showpost.php?p=63298&postcount=14 //xeroblood
    new nIdx; nldx = 0, l = strlen(p_szInput)
    new nLen; nLen = (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput, p_szDelimiter ))
    while( (nLen < l) && (++nIdx < p_nMax) )
        nLen += (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput[nLen], p_szDelimiter ))
    return PLUGIN_CONTINUE
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

/*
#~/bin/sh
SERVICE="opfor.so"
#declare -g mod=gearbox
ID=`whoami`
if (lsof -w | grep "$SERVICE" > /dev/null)
then
    {
        MYAD=`date +L%Y%m%d.log`
        #MYAD=`grep date +%m/%0e/%Y clientemp.log`
        cd /home/$ID/Steam/steamapps/common/Half-Life/gearbox/addons/amxmodx/logs
        touch `date +L%Y%m%d.log` #prevents spam.
#57-120
        grep degree $MYAD |cut -c 43-180 > /tmp/_temps.txt
        #$MYAD |cut -c 57-180 > /tmp/_temps.txt
        cat /tmp/_temps.txt | sort | uniq > /tmp/temps.txt
        sleep 1
        grep degree $MYAD |cut -c 43-180 |tail -n 30 | tac > /home/$ID/Steam/steamapps/common/Half-Life/valve/_motd.txt
        #$MYAD |cut -c 57-180 |tail -n 30 | tac > /home/$ID/Steam/steamapps/common/Half-Life/valve/_motd.txt
        cat /home/$ID/Steam/steamapps/common/Half-Life/valve/_motd.txt | sort -du | jq . > /home/$ID/Steam/steamapps/common/Half-Life/valve/
        #cat /home/$ID/Steam/steamapps/common/Half-Life/valve/_motd.txt | sort -du > /home/$ID/Steam/steamapps/common/Half-Life/valve/motd.txt
    }
fi
*/
