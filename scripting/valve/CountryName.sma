/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 * WHOIS happens on conflict. Country tag on kill!
 *
 *
 */

#include <amxmodx>
#include <amxmisc>

#include hamsandwich
/*Geo API*/
#include sockets

#define PLUGIN "CountryName"
#define VERSION "1.3"
#define AUTHOR ".sρiηX҉."

#define COORD 3245
#define READ 777
#define WRITE 4444
#define charsmin                   -1
#define WITHOUT_PORT               1
#define MAX_IP_LENGTH              16
#define MAX_IP_WITH_PORT_LENGTH    22
#define MAX_PLAYERS                32
#define MAX_NAME_LENGTH            32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_CMD_LENGTH             128
#define MAX_USER_INFO_LENGTH       256
#define MAX_MENU_LENGTH            512
#define MAX_MOTD_LENGTH            1536

#define MAX_PLAYERS                32
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_USER_INFO_LENGTH       256

new SzSave[MAX_MOTD_LENGTH + MAX_MENU_LENGTH];

new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH];
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH];

new ClientIP[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
//new ClientSuccess[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientType[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientContinent[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientContinent_code[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCountry[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCountry_code[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
//new ClientCountry_flag[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientCountry_capital[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
//new ClientCountry_phone[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientCountry_neighbours[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientRegion[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCity[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientLatitude[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientLongitude[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]

new ClientAsn[MAX_PLAYERS+1][MAX_NAME_LENGTH]

/*
new ClientOrg[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientTimezone[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientTimezone_name[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientTimezone_dstoffset[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientTimezone_gmtoffset[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientTimezone_gmt[MAX_PLAYERS+1][MAX_NAME_LENGTH]
*/
new ClientIsp[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCurrency[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCurrency_code[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCurrency_symbol[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCurrency_rates[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
//new ClientCurrency_plural[MAX_PLAYERS+1][MAX_NAME_LENGTH]
//new ClientCompleted_requests[MAX_PLAYERS+1][MAX_NAME_LENGTH]


new geo_data[MAX_RESOURCE_PATH_LENGTH][MAX_PLAYERS+MAX_IP_LENGTH]

new buffer[MAX_MOTD_LENGTH];
new bool:got_coords[ MAX_PLAYERS + 1 ]
new const api[]= "ipwhois.app"

#if !defined SOCK_NON_BLOCKING
 #error Go make a new script or post and wait on forums/Discord if you are not autodidactic.
#endif

new g_socket_pass[MAX_PLAYERS+1]
new ip_api_socket

new g_cvar_debugger;

new Trie:g_client_whois;

/*
enum _:Client_whois
{
    SzAddress[MAX_NAME_LENGTH],
    SzLatitude[MAX_IP_LENGTH],
    SzLongitude[MAX_IP_LENGTH],
    SzIsp[MAX_RESOURCE_PATH_LENGTH],
    SzCurrency_code[4],
    SzCurrency_symbol[4],
    SzCurrency[MAX_IP_LENGTH],
    SzCurrency_rates[4],
    SzCountry[MAX_NAME_LENGTH],
    SzCountry_capital[4],
    SzCountry_code[4],
    SzContinent[MAX_NAME_LENGTH],
    SzContinent_code[4],
    SzNeighbors[MAX_RESOURCE_PATH_LENGTH]
}
*/

enum _:Client_whois
{
    SzAddress[MAX_RESOURCE_PATH_LENGTH],
    SzASN[MAX_RESOURCE_PATH_LENGTH],
    SzType[MAX_RESOURCE_PATH_LENGTH],
    SzLatitude[MAX_RESOURCE_PATH_LENGTH],
    SzLongitude[MAX_RESOURCE_PATH_LENGTH],
    SzIsp[MAX_RESOURCE_PATH_LENGTH],
    SzCurrency_code[MAX_RESOURCE_PATH_LENGTH],
    SzCurrency_symbol[MAX_RESOURCE_PATH_LENGTH],
    SzCurrency[MAX_RESOURCE_PATH_LENGTH],
    SzCurrency_rates[MAX_RESOURCE_PATH_LENGTH],
    SzCountry[MAX_RESOURCE_PATH_LENGTH],
    SzCountry_capital[MAX_RESOURCE_PATH_LENGTH],
    SzCountry_code[MAX_RESOURCE_PATH_LENGTH],
    SzContinent[MAX_RESOURCE_PATH_LENGTH],
    SzContinent_code[MAX_RESOURCE_PATH_LENGTH],
    SzNeighbors[MAX_RESOURCE_PATH_LENGTH]
}

new Data[ Client_whois ]

public client_death(victim, killer)
{
    if(is_user_connected(killer)) //filter out mortars etc!
    {
        new ClientVicName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
        new ClientKilName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
        static const SzBotTag[]="BOT"

        if(is_user_bot(victim))
        {
            get_user_authid(victim,ClientAuth[victim],charsmax(ClientAuth[]))
            if(!equali(ClientAuth[victim], "BOT"))
                return

            copy(ClientCountry_code[victim], charsmax(ClientCountry_code[]), SzBotTag)
        }
        else
            remove_quotes(ClientCountry_code[victim])

        if(is_user_bot(killer))
        {
            get_user_authid(killer,ClientAuth[killer],charsmax(ClientAuth[]))
            if(!equali(ClientAuth[killer], "BOT"))
                return

            new const SzBotTag[]="BOT"
            copy(ClientCountry_code[killer], charsmax(ClientCountry_code[]), SzBotTag)
        }
        else
            remove_quotes(ClientCountry_code[killer])



        formatex(ClientKilName[killer], charsmax(ClientKilName[]), "[%s]%s", ClientCountry_code[killer], ClientName[killer] )
        formatex(ClientVicName[victim], charsmax(ClientVicName[]), "[%s]%s", ClientCountry_code[victim], ClientName[victim] )

        client_print 0, print_chat, "%s killed %s", ClientKilName[killer], ClientVicName[victim]

        if(!is_user_bot(killer))
        {
            client_print victim, print_center, "%s's coords: %s %s^n^n^nISP:%s.",ClientName[killer], ClientLatitude[killer], ClientLongitude[killer], ClientIsp[killer]
            client_print victim, print_chat, "Paid in %s %s %s rate is %f.^n^nCapital of %s is %s. County code %s. %s %s", ClientCurrency_code[killer], ClientCurrency_symbol[killer], str_to_float(ClientCurrency[killer]), ClientCurrency_rates[killer], ClientCountry[killer], ClientCountry_capital[killer], ClientCountry_code[killer], ClientContinent[killer], ClientContinent_code[killer]
            client_print victim, print_chat, "Asn:%s, Type:%s, Neighbors:%s",ClientAsn[killer], ClientType[killer], ClientCountry_neighbours[killer]

        }
        if(!is_user_bot(victim))
        {
            client_print killer, print_center, "%s's coords: %s %s^n^n^nISP:%s.",ClientName[victim], ClientLatitude[victim], ClientLongitude[victim], ClientIsp[victim]
            client_print killer, print_chat, "Paid in %s %s %s rate is %f.^n^nCapital of %s is %s. County code %s. %s %s", ClientCurrency_code[killer], ClientCurrency_symbol[victim], ClientCurrency[victim], str_to_float(ClientCurrency_rates[victim]), ClientCountry[victim], ClientCountry_capital[victim], ClientCountry_code[victim], ClientContinent[victim], ClientContinent_code[victim]
            client_print killer, print_chat, "Asn:%s, Type:%s, Neighbors:%s",ClientAsn[victim], ClientType[victim], ClientCountry_neighbours[victim]
        }

    }

}
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHam(Ham_Killed, "player", "client_death");
    g_client_whois = TrieCreate()
    g_cvar_debugger = register_cvar("whois_debug", "0");

    ReadGeoFromFile( )
}
public client_putinserver(id)
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
    get_user_ip( id, ClientIP[id], charsmax( ClientIP[] ), WITHOUT_PORT )

    server_print "%s,%s,%s,%s",ClientName[id],ClientIP[id], PLUGIN, VERSION, AUTHOR
    Data[SzAddress] = ClientIP[id]
    TrieGetArray( g_client_whois, Data[ SzAddress ], Data, sizeof Data ) ? @Geo_cache(id,ClientIP[id]) : set_task(0.5,"@get_client_data", id+COORD)
}

@file_data(SzSave[])
{
    server_print "%s|trying save", PLUGIN
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/geo_cache.ini" )
    write_file(szFilePath, SzSave)
}

@Geo_cache(id,ClientIP[])
{
    server_print "Trying to get the data from file added to player %s", PLUGIN
    if(TrieGetArray( g_client_whois, Data[ SzAddress ], Data, sizeof Data ))
    {
        server_print "Address found in Trie %s", PLUGIN
        TrieGetArray( g_client_whois, Data[ SzAddress ], Data, sizeof Data )

        ///Data[ SzCountry_code ]    = ClientCountry_code[id]
        Data[ SzASN ]             = ClientAsn[id]
        Data[ SzType ]            = ClientCity[id]
        Data[ SzCountry_code ]    = ClientCountry_code[id]
        //copy(ClientCountry_code[id], charsmax(ClientCountry_code[]), Data[ SzCountry_code ])
        Data[ SzLatitude ]        = ClientLatitude[id]
        Data[ SzLongitude ]       = ClientLongitude[id]

        Data[ SzIsp ]             = ClientIsp[id]
        Data[ SzCurrency_code ]   = ClientCurrency_code[id]
        Data[ SzCurrency_symbol ] = ClientCurrency_symbol[id]

        Data[ SzCurrency ]        = ClientCurrency[id]
        //copy(ClientCurrency[id], charsmax(ClientCurrency[]), Data[ SzCurrency ])

        Data[ SzCurrency_rates ]  = ClientCurrency_rates[id]
        //copy(SzCurrency_rates[id], charsmax(SzCurrency_rates[]), Data[ SzCurrency_rates ])

        Data[ SzCountry ]         = ClientCountry[id]
        Data[ SzCountry_capital ] = ClientCountry_capital[id]
        Data[ SzContinent ]       = ClientContinent[id]
        Data[ SzContinent_code ]  = ClientContinent_code[id]
        //copy(SzContinent_code[id], charsmax(SzContinent_code[]), Data[ SzContinent_code ])


        ///Data[ SzNeighbors ]       = ClientCountry_neighbours[id]
        copy(ClientCountry_neighbours[id], charsmax(ClientCountry_neighbours[]), Data[ SzNeighbors ])


    }

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
    /*
        new msg[MAX_MOTD_LENGTH]
        server_print "%s:reading %s coords",PLUGIN, ClientName[id]
        #if AMXX_VERSION_NUM != 182
        if (socket_is_readable(ip_api_socket, 100000))
        #endif
        socket_recv(ip_api_socket,buffer,charsmax(buffer) )
        if (!equal(buffer, "") && containi(buffer,"completed_requests") > charsmin)
        {
            if(socket_close(ip_api_socket) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
            else
                server_print "%s already closed the socket on %s!",api,ClientName[id]
            //copyc(msg, charsmax(msg), buffer[containi(buffer, "success") - MAX_IP_WITH_PORT_LENGTH], '}');
            copyc(msg, charsmax(msg), buffer[containi(buffer, "success") - MAX_IP_WITH_PORT_LENGTH], '}');

            new infinity = explode_string(msg, ",", geo_data, MAX_PLAYERS+MAX_IP_LENGTH, MAX_RESOURCE_PATH_LENGTH, false)
//            log_to_file "geo_data.txt","%s",infinity
            new list = 1
            for(new parameters;parameters < sizeof geo_data[];parameters++)
                server_print("%d:%s",list++,geo_data[parameters])

            copyc(ClientLatitude[id],charsmax(ClientLatitude[]),msg[containi(msg,"latitude")+10],'"')

            copyc(ClientLongitude[id],charsmax(ClientLongitude[]),msg[containi(msg,"longitude")+11],'"')

            copyc(ClientIsp[id],charsmax(ClientIsp[]), msg[containi(msg,"isp")+6],'"')

            //copyc(ClientAsn[id],charsmax(ClientAsn[]), msg[containi(msg,"asn")+6],'"') //"Krasnoyarsk Krai","city" ==> Asn: rsk Krai
            copyc(ClientAsn[id],charsmax(ClientAsn[]), msg[containi(msg,"^"asn^":")+6],',') //ok now
            remove_quotes(ClientAsn[id])
            replace(ClientAsn[id],charsmax(ClientAsn[]), ",", "")

            copyc(ClientCountry_neighbours[id],charsmax(ClientCountry_neighbours[]), msg[containi(msg,"country_neighbours")+21],'"')
            copyc(ClientType[id],charsmax(ClientType[]), msg[containi(msg,"type")+7],'"')

            copyc(ClientCurrency[id],charsmax(ClientCurrency[]),msg[containi(msg,"currency")+11],'"')

            copyc(ClientCurrency_code[id],charsmax(ClientCurrency_code[]),msg[containi(msg,"currency_code")+16],'"')

            copyc(ClientCurrency_rates[id],charsmax(ClientCurrency_rates[]),msg[containi(msg,"currency_rates")+16],'"')

            copyc(ClientCurrency_symbol[id],charsmax(ClientCurrency_symbol[]),msg[containi(msg,"currency_symbol")+18],'"')

            copy(ClientContinent[id],charsmax(ClientContinent[]),geo_data[3][containi(geo_data[3],"continent")+11])
            copy(ClientContinent_code[id],charsmax(ClientContinent_code[]),geo_data[4][containi(geo_data[4],"continent_code")+17])
            copy(ClientCountry[id],charsmax(ClientCountry[]),geo_data[5][containi(geo_data[5],"country")+9])

            copyc(ClientCity[id],charsmax(ClientCity[]),msg[containi(msg,"country_city")+14],'"')

            copyc(ClientRegion[id],charsmax(ClientRegion[]),msg[containi(msg,"region")+8],'"')

            copy(ClientCountry_code[id],charsmax(ClientCountry_code[]),geo_data[6][containi(geo_data[6],"country_code")+15])
            copy(ClientCountry_capital[id],charsmax(ClientCountry_capital[]),geo_data[8][containi(geo_data[8],"country_capital")+17])
            */
        new msg[MAX_MOTD_LENGTH]
        server_print "%s:reading %s coords",PLUGIN, ClientName[id]
        #if AMXX_VERSION_NUM != 182
        if (socket_is_readable(ip_api_socket, 100000))
        #endif
        socket_recv(ip_api_socket,buffer,charsmax(buffer) )
        if (!equal(buffer, "") && containi(buffer,"completed_requests") > charsmin)
        {
            if(socket_close(ip_api_socket) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
            else
                server_print "%s already closed the socket on %s!",api,ClientName[id]
            //copyc(msg, charsmax(msg), buffer[containi(buffer, "success") - MAX_IP_WITH_PORT_LENGTH], '}');
            copyc(msg, charsmax(msg), buffer[containi(buffer, "success") - MAX_IP_WITH_PORT_LENGTH], '}');
#if AMXX_VERSION_NUM != 182
            new infinity = explode_string(msg, ",", geo_data, MAX_PLAYERS+MAX_IP_LENGTH, MAX_RESOURCE_PATH_LENGTH, false)
            ///log_to_file "geo_data.txt","%s",infinity
            new list = 1
            for(new parameters;parameters < sizeof geo_data[];parameters++)
                server_print("%d:%s",list++,geo_data[parameters])
#endif

            copyc(ClientLatitude[id],charsmax(ClientLatitude[]),msg[containi(msg,"latitude")+10],'"')

            copyc(ClientLongitude[id],charsmax(ClientLongitude[]),msg[containi(msg,"longitude")+11],'"')

            copyc(ClientIsp[id],charsmax(ClientIsp[]), msg[containi(msg,"isp")+6],'"')

            //copyc(ClientAsn[id],charsmax(ClientAsn[]), msg[containi(msg,"asn")+6],'"') //"Krasnoyarsk Krai","city" ==> Asn: rsk Krai
            copyc(ClientAsn[id],charsmax(ClientAsn[]), msg[containi(msg,"^"asn^":")+6],',') //ok now
            remove_quotes(ClientAsn[id])
            replace(ClientAsn[id],charsmax(ClientAsn[]), ",", "")

            copyc(ClientCountry_neighbours[id],charsmax(ClientCountry_neighbours[]), msg[containi(msg,"country_neighbours")+21],'"')
            copyc(ClientType[id],charsmax(ClientType[]), msg[containi(msg,"type")+7],'"')

            copyc(ClientCurrency[id],charsmax(ClientCurrency[]), msg[containi(msg,"currency")+11],'"')

            copyc(ClientCurrency_code[id],charsmax(ClientCurrency_code[]), msg[containi(msg,"currency_code")+16],'"')

            copyc(ClientCurrency_rates[id],charsmax(ClientCurrency_rates[]), msg[containi(msg,"currency_rates")+16],',')
            replace(ClientCurrency_rates[id],charsmax(ClientCurrency_rates[]), ",", "")
            

            copyc(ClientCurrency_symbol[id],charsmax(ClientCurrency_symbol[]), msg[containi(msg,"currency_symbol")+18],'"')
            //////
            //copy(ClientContinent[id],charsmax(ClientContinent[]),geo_data[3][containi(geo_data[3],"continent")+11])
            copyc(ClientContinent[id],charsmax(ClientContinent[]),msg[containi(msg,"continent")+12],'"')
            ///////

            ///////
            //copy(ClientContinent_code[id],charsmax(ClientContinent_code[]),geo_data[4][containi(geo_data[4],"continent_code")+17])
            copyc(ClientContinent_code[id],charsmax(ClientContinent_code[]), msg[containi(msg,"continent_code")+17],'"')
            replace(ClientContinent_code[id],charsmax(ClientContinent_code[]), ",", "")
            //"continent_code":"NA"

            ///////
            
            ///////
            //copy(ClientCountry[id],charsmax(ClientCountry[]),geo_data[5][containi(geo_data[5],"country")+9])
            copyc(ClientCountry[id], charsmax(ClientCountry[]), msg[containi(msg,"country")+10], '"') //field length inc quotes +1 with a " on the end otherwise same length with a , to grab it in quotes
            //replace(ClientCountry[id], charsmax(ClientCountry[]), ",", "")
            //remove_quotes(ClientCity[id])
            ///////
            
            

            copyc(ClientCity[id],charsmax(ClientCity[]), msg[containi(msg,"country_city")+15],'"')
            //replace(ClientCity[id],charsmax(ClientCity[]), ",", "")
            //remove_quotes(ClientCity[id])

            copyc(ClientRegion[id],charsmax(ClientRegion[]), msg[containi(msg,"region")+8],'"')

            
            

            ///////
            //copy(ClientCountry_code[id],charsmax(ClientCountry_code[]),geo_data[6][containi(geo_data[6],"country_code")+14])
            copyc(ClientCountry_code[id],charsmax(ClientCountry_code[]),msg[containi(msg,"country_code")+15],'"')
            ///////
            
            ///////
            //copy(ClientCountry_capital[id],charsmax(ClientCountry_capital[]),geo_data[8][containi(geo_data[8],"country_capital")+17])
            copyc(ClientCountry_capital[id],charsmax(ClientCountry_capital[]),msg[containi(msg,"country_capital")+18],'"')
            /////////
            

            server_print"%s's coords: %s %s^nISP: %s. Paid in %s %s %s rate is %s. Capital of %s is %s. County code: %s. %s, %s",ClientName[id], ClientLatitude[id], ClientLongitude[id], ClientIsp[id], ClientCurrency_code[id], ClientCurrency_symbol[id], ClientCurrency[id], ClientCurrency_rates[id], ClientCountry[id], ClientCountry_capital[id], ClientCountry_code[id], ClientContinent[id], ClientContinent_code[id]
            server_print"Asn: %s, Type: %s, Neighbors: %s",ClientAsn[id], ClientType[id], ClientCountry_neighbours[id]

            ////////////////CACHE THE DATA SQL NEXT!

            Data[ SzAddress ]         = ClientIP[id]
            Data[ SzASN ]             = ClientAsn[id]
            Data[ SzType]             = ClientType[id]
            Data[ SzCountry_code ]    = ClientCountry_code[id]
            Data[ SzLatitude ]        = ClientLatitude[id]
            Data[ SzLongitude ]       = ClientLongitude[id]
            Data[ SzIsp ]             = ClientIsp[id]
            Data[ SzCurrency_code ]   = ClientCurrency_code[id]
            Data[ SzCurrency_symbol ] = ClientCurrency_symbol[id]
            Data[ SzCurrency ]        = ClientCurrency[id]
            Data[ SzCurrency_rates ]  = ClientCurrency_rates[id]
            Data[ SzCountry ]         = ClientCountry[id]
            Data[ SzCountry_capital ] = ClientCountry_capital[id]
            Data[ SzContinent ]       = ClientContinent[id]
            Data[ SzContinent_code ]  = ClientContinent_code[id]
            Data[ SzNeighbors ]       = ClientCountry_neighbours[id]


            TrieSetArray( g_client_whois, Data[ SzAddress], Data, sizeof Data )
            formatex(SzSave,charsmax(SzSave),"^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", Data[ SzAddress ], Data[ SzASN], Data[ SzType], Data[ SzCountry_code ], Data[ SzLatitude ], Data[ SzLongitude ], Data[ SzIsp ],
            Data[ SzCurrency_code ], Data[ SzCurrency_symbol ], Data[ SzCurrency ], Data[ SzCurrency_rates ], Data[ SzCountry ], Data[ SzCountry_capital ], Data[ SzContinent ], Data[ SzContinent_code], Data[ SzNeighbors ] )
            //save the string of geo data from IP/sockets to INI in configs
            @file_data(SzSave)
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
                remove_task(id+READ)
                remove_task(id+WRITE)
                server_print"Removed task %d",id
            }
            server_print "Could not get a read =("
            client_putinserver(id)
        }
        else if(g_socket_pass[id]>15 && task_exists(id+READ))
        {
            remove_task(id)
            server_print"Removed task %d",id
            server_print"CAN NOT CONNECT!"
        }

        else
        {
            if(socket_close(ip_api_socket) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
        }

    }
    return PLUGIN_CONTINUE
}
public ReadGeoFromFile( )
{
    new szDataFromFile[ MAX_CMD_LENGTH + MAX_RESOURCE_PATH_LENGTH ] //MAX_MOTD_LENGTH ]
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/geo_cache.ini" )
    new debugger = get_pcvar_num(g_cvar_debugger)
    new f = fopen( szFilePath, "rt" )
    if( !f )
    {
        ///@init_proxy_file()
        server_print "No file to read GEO from yet."
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
            Data[ SzASN ], charsmax( Data[ SzASN ] ),
            Data[ SzType ], charsmax( Data[ SzType ] ),
            Data[ SzCountry_code ], charsmax( Data[SzCountry_code] ),
            Data[ SzLatitude ], charsmax( Data[SzLatitude] ),
            Data[ SzLongitude ], charsmax( Data[SzLongitude] ),
            Data[ SzIsp ], charsmax( Data[SzIsp] ),
            Data[ SzCurrency_code ], charsmax( Data[SzCurrency_code] ),
            Data[ SzCurrency_symbol ], charsmax( Data[SzCurrency_symbol] ),
            Data[ SzCurrency ], charsmax( Data[SzCurrency] ),
            Data[ SzCurrency_rates ], charsmax( Data[SzCurrency_rates] ),
            Data[ SzCountry ], charsmax( Data[SzCountry] ),
            Data[ SzCountry_capital ], charsmax( Data[SzCountry_capital] ),
            Data[ SzContinent ], charsmax( Data[SzContinent] ),
            Data[ SzContinent_code ], charsmax( Data[SzContinent_code] ),
            Data[ SzNeighbors ], charsmax( Data[ SzNeighbors ] )
        )

        TrieSetArray( g_client_whois, Data[ SzAddress], Data, sizeof Data )

        if(debugger)
            server_print "Read %s,%s^n^nfrom file",Data[ SzAddress ], Data[ SzCountry_code ]
    }
    fclose( f )
    if(debugger)
        server_print "................WHOIS cache from file....................."
}
public plugin_end()
    TrieDestroy(g_client_whois)
