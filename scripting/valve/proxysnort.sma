#define WEATHER_SCRIPT "clientemp.amxx" ///name you gave clientemp.sma
//#define SOCK_NON_BLOCKING (1 << 0)    /* Set the socket a nonblocking */
//#define SOCK_LIBC_ERRORS  (1 << 1)    /* Enable libc error reporting */
/**
*    Proxy Snort. Handles proxy users using proxycheck.io and GoldSrc.
*
*    Copyleft (C) March 2020 .sρiηX҉.
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
*/

#include <amxmodx>
#include <amxmisc>
#include <regex>
#include <sockets>

#define PLUGIN "ProxySnort"
#define VERSION "1.5"
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

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1

#define FCVAR_NOEXTRAWHITEPACE     512 // Automatically strips trailing/leading white space from the string value


new iResult, Regex:hPattern, szError[MAX_AUTHID_LENGTH], iReturnValue;

new proxy_socket_buffer[ MAX_USER_INFO_LENGTH + MAX_MENU_LENGTH ], g_cvar_token, token[MAX_PLAYERS + 1], g_cvar_tag, tag[MAX_PLAYERS + 1];

new name[MAX_NAME_LENGTH], Ip[MAX_IP_LENGTH], ip[MAX_IP_LENGTH], authid[ MAX_AUTHID_LENGTH + 1 ], provider[MAX_RESOURCE_PATH_LENGTH];

new g_proxy_socket, g_cvar_iproxy_action, g_cvar_admin;

new const MESSAGE[] = "Proxysnort by Spinx"

new risk[ 4 ], g_iHeadcount, g_cvar_debugger;

new bool:IS_SOCKET_IN_USE

new g_clientemp_version

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    hPattern = regex_compile(PATTERN, iReturnValue, szError, charsmax(szError), "is");

    g_cvar_token            = register_cvar("sv_proxycheckio-key", "null", FCVAR_SERVER|FCVAR_PROTECTED|FCVAR_NOEXTRAWHITEPACE|FCVAR_SPONLY);
    g_cvar_tag              = register_cvar("sv_proxytag", "GoldSrc", FCVAR_PRINTABLEONLY);
    g_cvar_admin            = register_cvar("proxy_admin", "0"); //check admins
    g_cvar_iproxy_action    = register_cvar("proxy_action", "1");
    g_cvar_debugger         = register_cvar("proxy_debug", "1");
    //proxy_action: 1 is kick. 2 is banip. 3 is banid. 4 is warn-only. 5 is log-only (silent).

    g_clientemp_version     = get_cvar_pointer("temp_queue_weight") ? get_cvar_pointer("temp_queue_weight") : 0


    //Tag positive findings by mod.

    new mod_name[MAX_NAME_LENGTH] //Thx Pizzahut! https://forums.alliedmods.net/member.php?s=cffd384455c06423cc6504018c7326d5&u=2605
    get_modname(mod_name, charsmax(mod_name));
    set_pcvar_string(g_cvar_tag, mod_name);
}


public client_putinserver(id)
{
    if(is_user_bot(id))
        return PLUGIN_HANDLED_MAIN

    if(is_user_alive(id) && !is_user_bot(id) && id > 0 && !is_user_connecting(id))
    {
        get_user_ip( id, ip, charsmax( ip ), WITHOUT_PORT );

        new total = iPlayers()
        new Float:retask = (float(total++)*3.0)
        new Float:task_expand = floatround(random_float(retask+1.0,retask+2.0), floatround_ceil)*1.0

        /*new Float:buffering = iPlayers() * 5.2
        if(buffering == 0.0 ||  buffering > 20.0) buffering = random_float(4.0, 8.0)*/
        server_print "%s task input time = %f", PLUGIN,task_expand
        set_task(task_expand , "client_proxycheck", id, ip, charsmax(ip))

    }
    return PLUGIN_CONTINUE;

}


public client_proxycheck(Ip[ MAX_IP_LENGTH ], id)
{
    if (is_user_connected(id) && !is_user_connecting(id) && id > 0)
    if(is_user_admin(id) && get_pcvar_num(g_cvar_admin) || !is_user_admin(id))
    if ( !is_user_bot(id) )

    {
        server_print "Checking connected user if not a bot"

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

        get_pcvar_string(g_cvar_token, token, charsmax (token));

        new Soc_O_ErroR2, constring[ MAX_USER_INFO_LENGTH ];

        if ( equal(token, "null") || equal(token, "") && is_user_admin(id) )

            set_task(40.0, "@needan", id+ADMIN);

        if(get_pcvar_num(g_cvar_debugger) > 1)
            server_print"%s %s by %s:Starting to open socket!", PLUGIN, VERSION, AUTHOR

        get_user_authid(id,authid,charsmax (authid));

        g_proxy_socket = socket_open("proxycheck.io", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
        //g_proxy_socket = socket_open("proxycheck.io", 80, SOCKET_TCP, Soc_O_ErroR2);


        get_pcvar_string(g_cvar_token, token, charsmax (token));

        get_pcvar_string(g_cvar_tag, tag, charsmax (tag));

        formatex(constring,charsmax (constring), "GET /v2/%s?key=%s&inf=1&asn=1&vpn=1&risk=2&days=30&tag=%s,%s HTTP/1.0^nHost: proxycheck.io^n^n", Ip, token, tag, authid);

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

    if(IS_SOCKET_IN_USE)
        client_putinserver(id)
    else
        IS_SOCKET_IN_USE = true
    if(find_plugin_byfile(WEATHER_SCRIPT) != charsmin && g_clientemp_version && get_pcvar_num(g_clientemp_version))
    if(callfunc_begin("@lock_socket",WEATHER_SCRIPT))
    callfunc_end()

    if(get_pcvar_num(g_cvar_debugger) > 1 )
        server_print "%s %s by %s:Is socket writable?", PLUGIN, VERSION, AUTHOR

    #if AMXX_VERSION_NUM != 182
    if (socket_is_writable(g_proxy_socket, 100000))
    #endif

    socket_send(g_proxy_socket,text,charsmax (text));

    if(get_pcvar_num(g_cvar_debugger) > 1 )
    {
        if(is_user_connected(id))
            server_print "%s %s by %s:Yes! Writing to the socket of %s", PLUGIN, VERSION, AUTHOR, name
    }
}

@read_web(proxy_snort)
{
    new id = proxy_snort - USERREAD

    if( id > 0 )
    if (is_user_connected(id) || !is_user_bot(id) )

    {

        get_user_name(id,name,charsmax(name) );
        get_user_authid(id,authid,charsmax(authid) );
        get_user_ip(id,Ip,charsmax(Ip),1);

        if(get_pcvar_num(g_cvar_debugger) > 1)
            server_print "%s %s by %s:reading the socket", PLUGIN, VERSION, AUTHOR

        #if AMXX_VERSION_NUM != 182
        if (socket_is_readable(g_proxy_socket, 100000))
        #endif
        {
            socket_recv(g_proxy_socket,proxy_socket_buffer,charsmax (proxy_socket_buffer));
        }

        if (!equal(proxy_socket_buffer, ""))

        {
            if(get_pcvar_num(g_cvar_debugger) > 2)
                server_print "%s", proxy_socket_buffer



            //Proxy user treatments
            if (containi(proxy_socket_buffer, "yes") >= 0 || containi(proxy_socket_buffer, "Compromised") >= 0)

            {

            server_print "Proxy sniff...%s|%s", Ip, authid
            log_amx "%s, %s uses a proxy!", name, authid

            if (get_pcvar_num(g_cvar_iproxy_action) <= 4)
            {

            for (new admin=1; admin<=32; admin++)

            if (is_user_connected(admin) && is_user_admin(admin))

                client_print admin,print_chat,"%s, %s uses a proxy!", name, authid
            }
            //ban steamid
            if (get_pcvar_num(g_cvar_iproxy_action) == 3)

                server_cmd("amx_addban ^"%s^" ^"60^" ^"Anonymizing is NOT allowed!^"", authid);
            //ban ip
            if (get_pcvar_num(g_cvar_iproxy_action) == 2)

                server_cmd("amx_addban ^"%s^" ^"0^" ^"Anonymizing is NOT allowed!^"", Ip);

            //kick
            if (get_pcvar_num(g_cvar_iproxy_action) == 1)

                server_cmd( "kick #%d ^"Anonymizing is NOT allowed!^"", get_user_userid(id) );

            }

            //What if they aren't on proxy or VPN?
            if (containi(proxy_socket_buffer, "no") >= 0  && containi(proxy_socket_buffer, "error") == charsmin )
            {
                server_print "No proxy found on %s, %s",name,authid
            }

            if (containi(proxy_socket_buffer, "no") >= 0  && containi(proxy_socket_buffer, "error") >= 0 )
            {
                server_print "No proxy found on %s, %s",name,authid
            }
            //Handle erroneous IP's like 127.0.0.1 and print message as could be query limits as well when erroring.
            if (containi(proxy_socket_buffer, "error") >= 0  && containi(proxy_socket_buffer, "message") >= 0 )
            {
                new msg[128];
                copyc(msg, charsmax (msg), proxy_socket_buffer[containi(proxy_socket_buffer, "message") + 11], '"');
                /*replace(msg, charmin (msg), ":", "");*/
                server_print "Message is: %s",msg
            }

                //Example of a potentially more reliable 'City ID' or 'Country on Name' as per MaxMind database is updated via proxycheck.io. Provider is echoed.

            if (containi(proxy_socket_buffer, "provider") > charsmin )
            {
                copyc(provider, charsmax (provider), proxy_socket_buffer[containi(proxy_socket_buffer, "provider") + 12], '"');
                //copy(provider, charsmax(provider), proxy_socket_buffer[containi(proxy_socket_buffer, "provider") + 12])

                //Misc data and stats
                if(get_pcvar_num(g_cvar_debugger))
                    server_print "%s %s %s | %s uses %s for an ISP.",PLUGIN, VERSION, AUTHOR, name, provider
            }
            if (get_pcvar_num(g_cvar_iproxy_action) <= 4  && get_pcvar_num(g_cvar_debugger))
            {
                if(get_pcvar_num(g_cvar_debugger) > 2 )
                    server_cmd("amx_tsay yellow %s %s %s | %s uses %s for an ISP.",PLUGIN, VERSION, AUTHOR, name, provider);
                set_hudmessage(random_num(0,255),random_num(0,255),random_num(0,255), -1.0, 0.55, 1, 2.0, 3.0, 0.7, 0.8, 3);  //charsmin auto makes flicker

                for (new admin=1; admin<=32; admin++)

                if (is_user_connected(admin) && is_user_admin(admin))

                    show_hudmessage(admin, "%s %s %s | %s uses^n^n %s for an ISP.",PLUGIN, VERSION, AUTHOR, name, provider);

            }

        }

    }

    if (containi(proxy_socket_buffer, "risk") != charsmin && get_pcvar_num(g_cvar_iproxy_action) <= 4 )

    {
        new risk_buffer_fix = containi(proxy_socket_buffer, "yes") >= 0 ? 7 : 5
        copy(risk, charsmax(risk), proxy_socket_buffer[containi(proxy_socket_buffer, "risk") + risk_buffer_fix])

        if (!equal(risk, "") && get_pcvar_num(g_cvar_debugger) )

            {

                server_print "%s %s by %s | %s's risk is %i.",PLUGIN, VERSION, AUTHOR, name, str_to_num(risk)
                if(get_pcvar_num(g_cvar_debugger) > 2 )
                    server_cmd "amx_csay red %s %s by %s | %s's risk is %i.",PLUGIN, VERSION, AUTHOR, name, str_to_num(risk)

                for (new admin=1; admin<=32; admin++)

                    if (is_user_connected(admin) && is_user_admin(admin))

                client_print admin,print_chat,"%s %s by %s | %s's risk is %i.",PLUGIN, VERSION, AUTHOR, name, str_to_num(risk)

            }

        socket_close(g_proxy_socket);

        if(get_pcvar_num(g_cvar_debugger) > 4 ) bright_message();

    }


    else if (containi(proxy_socket_buffer, "risk") == charsmin)
    {

        set_task(3.5, "@read_web",id+USERREAD);
    }

    else

    {

    socket_close(g_proxy_socket);

    if(get_pcvar_num(g_cvar_debugger) > 4 )bright_message();

    if (equal(proxy_socket_buffer, "") && get_pcvar_num(g_cvar_debugger) )
    {
        server_print "Buffer is now blank for %s|%s",name,authid
    }

    if(get_pcvar_num(g_cvar_debugger))
        server_print "%s %s by %s:finished reading the socket", PLUGIN, VERSION, AUTHOR
    }
    set_task(1.0, "@mark_socket", id);

    if(find_plugin_byfile(WEATHER_SCRIPT) != charsmin && g_clientemp_version && get_pcvar_num(g_clientemp_version))
    if(callfunc_begin("@mark_socket",WEATHER_SCRIPT))
    {
        new work[MAX_PLAYERS]
        format(work,charsmax(work),PLUGIN,"")
        callfunc_push_str(work)
        callfunc_end()
    }

    return PLUGIN_CONTINUE;

}

@mark_socket(work[MAX_PLAYERS])
{
    IS_SOCKET_IN_USE = false;

    if(!equal(work, ""))
    server_print "%s | %s locking socket!", PLUGIN, work
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
                    new motd[128];
                    format(motd, charsmax (motd), "<html><meta http-equiv='Refresh' content='0; URL=https://proxycheck.io/'><body BGCOLOR='#FFFFFF'><br><center>Null proxy key detected.</center></html>");
                    show_motd(id, motd, "Invalid API key!");
                }

                else
                for (new admin=1; admin<=32; admin++)

                    if (is_user_connected(admin) && is_user_admin(admin))


                    {
                        client_print admin,print_chat,"Check your API key validity!"
                        client_print admin,print_center,"Null sv_proxycheckio-key detected. %s %s %s", AUTHOR, PLUGIN,VERSION
                        client_print admin,print_console,"Get key from proxycheck.io."
                    }
        }
}

public plugin_end() {
    regex_free(hPattern);
}

public bright_message() {
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
/*
 *
 * name: stock iPlayers()
 * @param depends on what flavor of amxx you use.
 * @return total number of humans on multi-player.
 *
 */

stock iPlayers()

{

    #if AMXX_VERSION_NUM != 190
    #if AMXX_VERSION_NUM != 110

        g_iHeadcount = get_playersnum()

    #else

        g_iHeadcount = get_playersnum_ex(GetPlayersFlags:GetPlayers_ExcludeBots)

    #endif
    #endif

    return g_iHeadcount
}
