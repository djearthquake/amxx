#define WEATHER_SCRIPT "clientemp.amxx" ///name you gave clientemp.sma
//This is used to prevent both plugins of mine from uncontrollably clutching sockets mod.
///If you do not use it, ignore or study it.
//https://github.com/djearthquake/amxx/blob/main/scripting/valve/clientemp.sma
/**
*    Proxy Snort. Handles proxy users using proxycheck.io and GoldSrc.
*
*    Copyleft (C) March 2020-2023 .sρiηX҉.
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
*
*    05/01/2020 SPiNX
*    Change log 1.0 to 1.1
*    -Resolve occasional Run time error 4: index out of bounds @read_web (Provider/Risk fields)
*
*    06/17/2020 SPiNX
*    Change log 1.1 to 1.2
*    -Updated Regex pattern due to 'obvious typo' and tested via regexr.com.
*
*    09/29/2020 SPiNX
*    Change log 1.2 to 1.3
*    -Bug fixes. Optimizations. Less load on CPU and no more double prints.
*
*    07/17/2021 SPiNX
*    Change log 1.3 to 1.4
*    -VPN checking.
*    -Finished migrating the messaging into debug mode.
*    -Spread out proxy check tasks.
*
*    08/02/2021 SPiNX
*    Change log 1.4 to 1.5
*    -Interfaced with the queue made on proxysnort.sma
*
*    11/26/2021 SPiNX
*    Change log 1.5 to 1.6
*    -Remade array based off the IP instead of client index.
*    -Tuned plugin to be more misery when debug is off.
*    -Assured all the GoldSrc mods can run this when putin server.
*
*    02/19/2022 SPiNX
*    Change log 1.6 to 1.7
*    -Added type https://proxycheck.io/api/#type_responses
*
*    03/16/2023 SPiNX
*    Change log 1.7 to 1.8
*   -Discontinue regex module usage. Found leak.
*
*/
#include <amxmodx>
#include <amxmisc>
//#include <regex>
#include <sockets>
#define PLUGIN "ProxySnort"
#define VERSION "1.8"
#define AUTHOR "SPiNX"
#define USER 7007
#define USERREAD 5009
#define USERWRITE 6016
#define ADMIN 707
#define WITHOUT_PORT                   1
#define PATTERN "(127\.(0))|(10\.(42))|(172\.(0)?1[6-9]\.)|(172\.(0)?2[0-9]\.)|(172\.(0)?3[0-1]\.)|(169\.254\.)|(192\.168\.)"
//#define DEBUG //Echoes steps.
#define DEBUG2 //Dumps file.
///MACROS for AMXX 1.8.2 local compile.
#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_MENU_LENGTH            512
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH_V6           40
#define MAX_USER_INFO_LENGTH       256
#define MAX_CMD_LENGTH             128
#define charsmin                  -1
#define FCVAR_NOEXTRAWHITEPACE     512 // Automatically strips trailing/leading white space from the string value
new const SzGet[]="GET /v2/%s?key=%s&inf=1&vpn=1&risk=1&tag=%s,%s HTTP/1.1^nHost: proxycheck.io^n^n"
//new iResult, Regex:hPattern, szError[MAX_AUTHID_LENGTH], iReturnValue;
new g_cvar_token, token[MAX_PLAYERS + 1], g_cvar_tag, tag[MAX_PLAYERS + 1];
// Just proxy or vpn yes or no length MAX_MENU_LENGTH
//to be able to get the risk and risk type
new proxy_socket_buffer[ MAX_MENU_LENGTH + MAX_MENU_LENGTH ]

new name[MAX_NAME_LENGTH], Ip[MAX_IP_LENGTH_V6], ip[MAX_IP_LENGTH_V6], authid[ MAX_AUTHID_LENGTH + 1 ];
new provider[MAX_RESOURCE_PATH_LENGTH], type[ MAX_NAME_LENGTH ];
new g_proxy_socket, g_cvar_iproxy_action, g_cvar_admin, g_maxPlayers;
new const MESSAGE[] = "Proxysnort by Spinx"
new risk[ 3 ];
new g_cvar_debugger;
new bool:IS_SOCKET_IN_USE;
new bool:g_has_been_checked[MAX_PLAYERS + 1];
new bool:g_processing[MAX_PLAYERS + 1];

new Trie:g_already_checked;
new g_clientemp_version;
new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH];
new SzSave[MAX_CMD_LENGTH];
enum _:Client_proxy
{
    SzAddress[ MAX_IP_LENGTH_V6 ],
    SzIsp[ MAX_RESOURCE_PATH_LENGTH ],
    SzType[ MAX_NAME_LENGTH ],
    SzProxy[ 3 ],
    iRisk[ 3 ]
}
new Data[ Client_proxy ]
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    ///hPattern = regex_compile(PATTERN, iReturnValue, szError, charsmax(szError), "is");
    g_cvar_token            = register_cvar("sv_proxycheckio-key", "null", FCVAR_PROTECTED|FCVAR_NOEXTRAWHITEPACE|FCVAR_SPONLY);
    g_cvar_tag              = register_cvar("sv_proxytag", "GoldSrc", FCVAR_PRINTABLEONLY);
    g_cvar_admin            = register_cvar("proxy_admin", "1"); //check admins
    g_cvar_iproxy_action    = register_cvar("proxy_action", "1");
    g_cvar_debugger         = register_cvar("proxy_debug", "0");
    //proxy_action: 0 is rename. 1 is kick. 2 is banip. 3 is banid. 4 is warn-only. 5 is log-only (silent).
    //Want more ask! Love to put them in SVC_FINALE. They are frozen people can shoot them and text slowly comes across.
    g_clientemp_version     = get_cvar_pointer("temp_queue_weight") ? get_cvar_pointer("temp_queue_weight") : 0
    g_maxPlayers = get_maxplayers()
    //Tag positive findings by mod.
    new mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name));
    set_pcvar_string(g_cvar_tag, mod_name);
    g_already_checked = TrieCreate()
    ReadProxyFromFile( )
}
@init_proxy_file()
{
    static SzLoopback[] = "127.0.0.1"
    Data[SzAddress] = SzLoopback
    Data[ SzProxy ] = 1
    if (TrieGetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data ))
    TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
    formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%i^"", Data[ SzAddress ],Data[SzProxy])
    @file_data(SzSave)
    ReadProxyFromFile( )
}

#if !defined client_disconnect
#define client_disconnected client_disconnect
#endif

public client_disconnected(id)
{
    g_has_been_checked[id]  = false
    g_processing[id] = false
}

public client_putinserver(id)
    @proxy_begin(id)

@proxy_begin(id)
{
    if(is_user_connected(id) && !g_processing[id])
    {
        if(is_user_bot(id) || g_has_been_checked[id] || id == 0)
            return PLUGIN_HANDLED_MAIN
        if(!is_user_bot(id) && id > 0)
        {
            g_processing[id] = true
            static SzLoopback[] = "127.0.0.1"
            get_user_ip( id, ip, charsmax( ip ), WITHOUT_PORT )
            new total = iPlayers()
            Data[SzAddress] = ip
            if(equali(ip,SzLoopback))
                client_proxycheck(ip,id)
            else if(!TrieGetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data ))
            {
                new Float:retask = (float(total++)*3.0)
                new Float:task_expand = floatround(random_float(retask+1.0,retask+2.0), floatround_ceil)*1.0
                server_print "%s task input time = %f", PLUGIN,task_expand
                Data[SzAddress] = ip
                TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
                if(!task_exists(id) && g_processing[id])
                    set_task(task_expand , "client_proxycheck", id, ip, charsmax(ip))
            }
            else if (TrieGetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data ) && str_to_num(Data[ SzProxy ]) == 1)
            {
                @handle_proxy_user(id)
                server_print "[%s] %s is NOT ok^n^nRisk:%i", PLUGIN, Data[ SzAddress ], Data[iRisk]
            }
            else
                server_print "[%s] %s is ok^n^n%s", PLUGIN, Data[ SzAddress ],Data[SzIsp]
        }
        else
        {
            get_user_authid(id,ClientAuth[id],charsmax(ClientAuth[]))
            if(!equali(ClientAuth[id], "BOT"))
                @handle_proxy_user(id)
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}
public client_proxycheck(Ip[], id)
{
    if(is_user_admin(id) && get_pcvar_num(g_cvar_admin) || !is_user_admin(id) && !g_has_been_checked[id] && g_processing[id])
    if ( !is_user_bot(id) ){
    //Use my updated version of Amxx 1.10 as this is controlled at the C++ level. Regex mod has a memory leak.
    /*
    {
        server_print "%s %s by %s:Checking if %s is a bot or something else.",PLUGIN, VERSION, AUTHOR, name
        get_user_name(id,name,charsmax(name))
        //Ignore LAN clients.
        iResult = regex_match_c(Ip, hPattern, iReturnValue);
        switch (iResult)
        {
            case REGEX_MATCH_FAIL:
            {
                log_amx "REGEX_MATCH_FAIL! %s", szError
            }
            case REGEX_PATTERN_FAIL:
            {
                log_amx "REGEX_PATTERN_FAIL! %s", szError
            }
            case REGEX_NO_MATCH:
            {
                server_print "Sniffing a public IP address...%s, %s",Ip,name
            }
            default:
            {
                server_print "%s %s by %s: Local IP. Stopping proxycheck on %s from %s.", PLUGIN, VERSION, AUTHOR, name, Ip
                server_cmd( "kick #%d ^"Please reconnect we misread your ID^"", get_user_userid(id) );
                return PLUGIN_HANDLED_MAIN; ///comment out or do not use plugin on local servers!
            }

        }
        */
        get_pcvar_string(g_cvar_token, token, charsmax (token));
        new Soc_O_ErroR2, constring[ MAX_USER_INFO_LENGTH ];
        if ( equal(token, "null") || equal(token, "") && is_user_admin(id) )
            set_task(40.0, "@needan", id+ADMIN);
        if(get_pcvar_num(g_cvar_debugger) > 1)
            server_print"%s %s by %s:Starting to open socket!", PLUGIN, VERSION, AUTHOR
        get_user_authid(id,authid,charsmax (authid));
        #if defined SOCK_NON_BLOCKING
            g_proxy_socket = socket_open("proxycheck.io", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
        #else
            g_proxy_socket = socket_open("proxycheck.io", 80, SOCKET_TCP, Soc_O_ErroR2);
        #endif
        get_pcvar_string(g_cvar_token, token, charsmax (token));
        get_pcvar_string(g_cvar_tag, tag, charsmax (tag));
        formatex(constring,charsmax (constring), SzGet, Ip, token, tag, authid);
        if(!task_exists(id+USERWRITE))
            set_task(1.0, "@write_web", id+USERWRITE, constring, charsmax (constring) );
        if(get_pcvar_num(g_cvar_debugger) > 2 )
        {
            server_print "This is where we are trying to get %s from:", PLUGIN
            server_print "telnet proxycheck.io 80 (Wait for a connection then paste.)^n%s",constring
            server_print "Debugging enabled::copy and paste last 2 lines from above into telnet session then press ENTER twice."
        }
        set_task(1.5, "@read_web", id+USERREAD);return PLUGIN_CONTINUE;
    }
    return PLUGIN_CONTINUE;
}
@write_web(text[MAX_USER_INFO_LENGTH], reader)
{
    new id = reader - USERWRITE;
    if(is_user_connected(id)/*on server*/ || is_user_connecting(id)/*downloading*/ && id > 0/*not the server*/ && !g_has_been_checked[id])
    {
        if(IS_SOCKET_IN_USE)
            set_task(10.0,"@proxy_begin",id)
        else
            IS_SOCKET_IN_USE = true
        server_print "%s %s by %s is locking socket for proxy check.^n^n",PLUGIN, VERSION, AUTHOR, name
        if(is_plugin_loaded(WEATHER_SCRIPT,true)!=charsmin && g_clientemp_version && get_pcvar_num(g_clientemp_version))
        {
            if(callfunc_begin("@lock_socket",WEATHER_SCRIPT))
            {
                    callfunc_end()
            }
        }
        if(get_pcvar_num(g_cvar_debugger) > 1 )
            server_print "%s %s by %s:Is the %s socket writable?^n^n", PLUGIN, VERSION, AUTHOR, name
        #if AMXX_VERSION_NUM != 182
        if (socket_is_writable(g_proxy_socket, 100000))
        #endif
        socket_send(g_proxy_socket,text,charsmax (text));
        if(get_pcvar_num(g_cvar_debugger) > 1 )
        {
            server_print "%s %s by %s:Yes! Writing to the socket of %s^n^n", PLUGIN, VERSION, AUTHOR, name
        }
    }
}
stock get_user_profile(id)
{
    get_user_name(id,name,charsmax(name) );
    get_user_authid(id,authid,charsmax(authid) );
    get_user_ip(id,Ip,charsmax(Ip),1);
    return authid, Ip, name
}
@handle_proxy_user(id)
{
    get_user_profile(id)
    new iAction = get_pcvar_num(g_cvar_iproxy_action)
    static const SzMsg[]="Anonymizing is NOT allowed!"

    bright_message()
    log_amx "Proxy found! Action is %d", iAction
    if (iAction <= 4)
    {
        for (new admin=1; admin<=g_maxPlayers; admin++)
            if (is_user_connected(admin) && is_user_admin(admin))
                client_print admin,print_chat,"%s, %s uses a proxy!", name, authid

        client_cmd( 0,"spk ^"bad entry detected^"" )
    }

    if(is_user_connected(id))
    {

        switch(iAction)
        {
            case 0:   set_user_info(id, "name", "Anon")
            case 1:   server_cmd( "kick #%d ^"%s^"", get_user_userid(id), SzMsg)
            case 2:   server_cmd( "amx_addban ^"%s^" ^"0^" ^"%s^"", Ip, SzMsg)
            case 3:   server_cmd( "amx_addban ^"%s^" ^"60^" ^"%s^"", authid, SzMsg)
            default:  server_cmd( "amx_addban ^"%s^" ^"60^" ^"%s^"", Ip, SzMsg)
        }

    }
    else if(is_user_connecting(id))
    {
        server_cmd "amx_addban ^"%s^" ^"60^" ^"%s^"", Ip, SzMsg
        server_cmd( "kick #%d ^"%s^"", get_user_userid(id), SzMsg) //test kick downloaders
    }
}
@read_web(proxy_snort)
{
    new id = proxy_snort - USERREAD
    if( id > 0 && !g_has_been_checked[id] )
    if (!is_user_bot(id))
    {
        get_user_profile(id)
        if(get_pcvar_num(g_cvar_debugger) > 1)
            server_print "%s %s by %s:reading the socket", PLUGIN, VERSION, AUTHOR
        #if AMXX_VERSION_NUM != 182
        if(socket_is_readable(g_proxy_socket, 100000))
        #endif
        socket_recv(g_proxy_socket,proxy_socket_buffer, charsmax(proxy_socket_buffer));
        if(!equal(proxy_socket_buffer, ""))
        {
            if(get_pcvar_num(g_cvar_debugger) > 2)
                server_print "%s", proxy_socket_buffer
            //Proxy user treatments
            if (containi(proxy_socket_buffer, "yes") != charsmin || containi(proxy_socket_buffer, "Compromised") != charsmin)
            {
                Data[SzProxy] = 1
                formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%i^"", Data[ SzAddress ], Data[ SzProxy ])
                TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
                @file_data(SzSave)
                server_print "Proxy sniff...%s|%s", Ip, authid
                log_amx "%s, %s uses a proxy!", name, authid
                //task per data wasn't being saved, kicking too quickly
                set_task(1.0,"@handle_proxy_user",id)
            }
            //What if they aren't on proxy or VPN?
            if (containi(proxy_socket_buffer, "no") != charsmin && containi(proxy_socket_buffer, "error") == charsmin && !g_has_been_checked[id])
            {
                Data[SzProxy] = 0
                formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%i^"", Data[ SzAddress ], Data[SzProxy])
                @file_data(SzSave)
                TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data)
                server_print "No proxy found on %s, %s error-free",name,authid
                if(!get_pcvar_num(g_cvar_debugger)) //need double print as it is a debugger passing point anyway to get all trivial details like risk and provider. Can whois later honestly.
                    g_has_been_checked[id] = true //stop double prints
                g_processing[id] = false
            }
            if (containi(proxy_socket_buffer, "no") != charsmin  && containi(proxy_socket_buffer, "error") != charsmin )
            {
                Data[SzProxy] = 0
                formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%i^"", Data[ SzAddress ],Data[SzProxy])
                @file_data(SzSave)
                TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
                server_print "No proxy found on %s, %s with error on packet",name,authid
                client_print 0, print_console, "No proxy found on %s, with error on packet", name
            }
            //Handle erroneous IP's like 127.0.0.1 and print message as could be query limits as well when erroring.
            if (containi(proxy_socket_buffer, "error") != charsmin  && containi(proxy_socket_buffer, "message") != charsmin )
            {
                new msg[MAX_CMD_LENGTH];
                copyc(msg, charsmax (msg), proxy_socket_buffer[containi(proxy_socket_buffer, "message") + 11], '"');
                server_print "Message is: %s",msg
            }
                //Example of a potentially more reliable 'City ID' or 'Country on Name' as per MaxMind database is updated via proxycheck.io. Provider is echoed.
            if (containi(proxy_socket_buffer, "provider") > charsmin )
            {
                copyc(provider, charsmax (provider), proxy_socket_buffer[containi(proxy_socket_buffer, "provider") + 12], '"');
                //Misc data and stats
                if(get_pcvar_num(g_cvar_debugger))
                    server_print "%s %s %s | %s uses %s for an ISP.",PLUGIN, VERSION, AUTHOR, name, provider
            }
            if (get_pcvar_num(g_cvar_iproxy_action) <= 4  && get_pcvar_num(g_cvar_debugger) && !equali(provider,""))
            {
                Data[SzIsp] = provider
                TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
                if(get_pcvar_num(g_cvar_debugger) > 2 )
                    server_cmd("amx_tsay yellow %s %s %s | %s uses %s for an ISP.",PLUGIN, VERSION, AUTHOR, name, provider);
                set_hudmessage(random_num(0,255),random_num(0,255),random_num(0,255), -1.0, 0.55, 1, 2.0, 3.0, 0.7, 0.8, 3);  //charsmin auto makes flicker
                for (new admin=1; admin<=g_maxPlayers; admin++)
                if (is_user_connected(admin) && is_user_admin(admin))
                    show_hudmessage(admin, "%s %s %s | %s uses^n^n %s for an ISP.",PLUGIN, VERSION, AUTHOR, name, provider);
            }
            if (containi(proxy_socket_buffer, "risk") != charsmin && get_pcvar_num(g_cvar_iproxy_action) <= 4 )
            {
                server_print "Copying the risk score."

                containi(SzGet, "v2") > charsmin ? copyc(risk, charsmax(risk), proxy_socket_buffer[containi(proxy_socket_buffer,"^"risk^":")+7],',') : //v2
                copyc(risk, charsmax(risk), proxy_socket_buffer[containi(proxy_socket_buffer,"^"risk^":")+6],'"') //v1


                remove_quotes(risk)
                replace(risk, charsmax(risk), ",", "")
                server_print "Risk:%d", str_to_num(risk)


                Data[iRisk] = risk
                TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
                if (!equal(risk, "") && get_pcvar_num(g_cvar_debugger) )
                {
                    new iRisk_conv = str_to_num(Data[iRisk])
                    server_print "%s %s by %s | %s's risk is %i.",PLUGIN, VERSION, AUTHOR, name, iRisk_conv
                    if(get_pcvar_num(g_cvar_debugger) > 2 )
                        server_cmd "amx_csay red %s %s by %s | %s's risk is %i.",PLUGIN, VERSION, AUTHOR, name, iRisk_conv

                    for (new admin=1; admin<=g_maxPlayers; admin++)
                        if (is_user_connected(admin) && is_user_admin(admin))
                            client_print admin,print_chat,"%s %s by %s | %s's risk is %i.",PLUGIN, VERSION, AUTHOR, name, iRisk_conv
                }
                if (containi(proxy_socket_buffer, "type") != charsmin)
                {
                    copyc(type, charsmax(type), proxy_socket_buffer[containi(proxy_socket_buffer,"^"type^":")+7],',')
                    remove_quotes(type)

                    if( !equal(type, "") )
                    {

                        replace(type, charsmax(type), ",", "")
                        Data[SzType] = type

                        TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )

                        for (new admin=1; admin<=g_maxPlayers; admin++)
                        if (is_user_connected(admin) && is_user_admin(admin))
                            client_print admin, print_chat, "%s is on %s.", name, Data[SzType]
                        log_amx "%s %s %s",Ip, authid, Data[SzType]
                    }
                }
                g_has_been_checked[id] = true
                g_processing[id] = false
                socket_close(g_proxy_socket);
                if(get_pcvar_num(g_cvar_debugger) > 4 )
                    bright_message();
            }
            else if (containi(proxy_socket_buffer, "risk") == charsmin)
            {
                //must be here to see the risk and provider
                set_task(3.5, "@read_web",id+USERREAD);
            }
            else
            {
                g_has_been_checked[id] = true
                g_processing[id] = false
                socket_close(g_proxy_socket);
                if(get_pcvar_num(g_cvar_debugger) > 4 )bright_message();
                if (equal(proxy_socket_buffer, "") && get_pcvar_num(g_cvar_debugger) )
                {
                    server_print "Buffer is now blank for %s|%s",name,authid
                }
                if(get_pcvar_num(g_cvar_debugger))
                    server_print "%s %s by %s:finished reading the socket", PLUGIN, VERSION, AUTHOR
            }
            ///UN-Lock the socket here so other clients can be checked.
            if(!task_exists(id))
                set_task(3.5, "@client_mark_socket", id);

        }
        else if(is_user_connected(id) || is_user_connecting(id) && !g_has_been_checked[id] && g_processing[id])
            set_task(3.5, "@read_web",id+USERREAD);
        else
        {
            if(task_exists(id+USERREAD))
                remove_task(id+USERREAD)

            socket_close(g_proxy_socket);
            @client_mark_socket(id)
        }
    }
    return PLUGIN_HANDLED
}
@client_mark_socket(id)
{
    IS_SOCKET_IN_USE = false;
    ///UN-Lock other script I made if used in tandom to prevent socket making game unplayable
    if(find_plugin_byfile(WEATHER_SCRIPT) != charsmin && g_clientemp_version && get_pcvar_num(g_clientemp_version))
    {
        if(callfunc_begin("@mark_socket",WEATHER_SCRIPT))
        {
            new work[MAX_PLAYERS]
            format(work,charsmax(work),PLUGIN,"")
            callfunc_push_str(work)
            callfunc_end()
        }
    }
    if(is_user_connected(id))
    {
        server_print "%s | %s unlocking socket!", PLUGIN, name
    }
}
@mark_socket(work[MAX_PLAYERS])
{
    IS_SOCKET_IN_USE = false;
    if(!equal(work, ""))
    server_print "%s | %s unlocking socket!", PLUGIN, work
}
@lock_socket()
{
    IS_SOCKET_IN_USE = true
    server_print "%s other plugin locking socket!", PLUGIN
}
@needan(keymissing)
{
    new id = keymissing - ADMIN
    if ( is_user_admin(id) )
    {
        if ( cstrike_running() || is_running("dod") == 1 )
        {
            new motd[MAX_CMD_LENGTH];
            format(motd, charsmax (motd), "<html><meta http-equiv='Refresh' content='0; URL=https://proxycheck.io/'><body BGCOLOR='#FFFFFF'><br><center>Null proxy key detected.</center></html>");
            show_motd(id, motd, "Invalid API key!");
        }
        else
        {
            for (new admin=1; admin<=g_maxPlayers; admin++)
            if (is_user_connected(admin) && is_user_admin(admin))
            {
                client_print admin,print_chat,"Check your API key validity!"
                client_print admin,print_center,"Null sv_proxycheckio-key detected. %s %s %s", AUTHOR, PLUGIN,VERSION
                client_print admin,print_console,"Get key from proxycheck.io."
            }
        }
    }
}
@file_data(SzSave[MAX_CMD_LENGTH])
{
    server_print "%s|trying save", PLUGIN
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/proxy_checked.ini" )
    write_file(szFilePath, SzSave)
}
public ReadProxyFromFile( )
{
    new szDataFromFile[ MAX_CMD_LENGTH ]
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/proxy_checked.ini" )
    new debugger = get_pcvar_num(g_cvar_debugger)
    new f = fopen( szFilePath, "rt" )
    if( !f )
    {
        @init_proxy_file()
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
            Data[ SzProxy ], charsmax( Data[SzProxy] )
        )
        if(debugger)
            server_print "Read %s,%i^n^nfrom file",Data[ SzAddress ], Data[ SzProxy ]
        str_to_num(Data[ SzProxy ])
        TrieSetArray( g_already_checked, Data[ SzAddress ], Data, sizeof Data )
    }
    fclose( f )
    if(debugger)
        server_print "................Proxy list from file....................."
}

public plugin_end()
{
    //regex_free(hPattern)
    TrieDestroy(g_already_checked)
}

public bright_message()
{
    new Float:xTex
    xTex = -1.1
    new Float:yTex
    yTex = -0.7
    new Float:fadeInTime = 0.5;
    new Float:fadeOutTime = 0.5;
    new Float:holdTime = 1.0;
    new Float:scanTime = 1.2;
    new effect = 2;
    new iRainbow = random_num(100,200)
    emessage_begin ( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0 )
    ewrite_byte(TE_TEXTMESSAGE);
    ewrite_byte(0);      //(channel)
    ewrite_short(FixedSigned16(xTex,1<<13));  //(x) charsmin = center)
    ewrite_short(FixedSigned16(yTex,1<<13));  //(y) charsmin = center)
    ewrite_byte(effect);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    ewrite_byte(255);  //(red) - text color 255 100 75 20 25 200 175 30
    ewrite_byte(100);  //(GRN)
    ewrite_byte(iRainbow);  //(BLU)
    ewrite_byte(200);  //(alpha)
    ewrite_byte(25);  //(red) - effect color
    ewrite_byte(200);  //(GRN)
    ewrite_byte(iRainbow);  //(BLU)
    ewrite_byte(25);  //(alpha)
    ewrite_short(FixedUnsigned16(fadeInTime,1<<8));
    ewrite_short(FixedUnsigned16(fadeOutTime,1<<8));
    ewrite_short(FixedUnsigned16(holdTime,1<<8));
    if (effect == 2)
    ewrite_short(FixedUnsigned16(scanTime,1<<8));
    ewrite_string(MESSAGE);
    emessage_end();
}
stock FixedSigned16( Float:value, scale )
// Converts floating-point number to signed 16-bit fixed-point representation
{
    new Output;
    Output = floatround( value * scale )
    if ( Output > 3276 )
        Output = 32767
    if ( Output < -32768 )
        Output = -32768;
    return  Output;
}
stock FixedUnsigned16( Float:value, scale )
// Converts floating-point number to unsigned 16-bit fixed-point representation
{
    new Output;
    Output = floatround( value * scale )
    if ( Output < 0 )
        Output = 0;
    if ( Output > 0xFFFF )
        Output = 0xFFFF;
    return  Output;
}
stock players_who_see_effects()
{
    new players[MAX_PLAYERS], playercount, SEE;
    get_players(players,playercount,"ch");
    for (SEE=0; SEE<playercount; SEE++)
    return SEE;
    return PLUGIN_CONTINUE;
}
stock iPlayers()
{
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"ch")
    return iHeadcount
}
