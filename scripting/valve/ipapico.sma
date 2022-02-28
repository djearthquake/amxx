/*Geo API*/
#include amxmodx
#include sockets

#define PLUGIN "Geo API"
#define VERSION "1.1"
#define AUTHOR ".sρiηX҉."

#define COORD 3245
#define READ 777
#define WRITE 4444
#define charsmin                   -1
#define WITHOUT_PORT               1
#define MAX_IP_LENGTH              16
#define MAX_PLAYERS                32
#define MAX_NAME_LENGTH            32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_CMD_LENGTH             128
#define MAX_USER_INFO_LENGTH       256
#define MAX_MENU_LENGTH            512
#define MAX_MOTD_LENGTH            1536

public plugin_init()
    register_plugin(PLUGIN, VERSION, AUTHOR);

new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientIP[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
//new ClientSuccess[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
//new ClientType[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientContinent[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientContinent_code[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCountry[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCountry_code[MAX_PLAYERS+1][MAX_NAME_LENGTH]
//new ClientCountry_flag[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCountry_capital[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
//new ClientCountry_phone[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
//new ClientCountry_neighbours[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientRegion[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCity[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientLatitude[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientLongitude[MAX_PLAYERS+1][MAX_NAME_LENGTH]
/*
new ClientAsn[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientOrg[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientTimezone[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientTimezone_name[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientTimezone_dstoffset[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientTimezone_gmtoffset[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientTimezone_gmt[MAX_PLAYERS+1][MAX_NAME_LENGTH]
*/
new ClientIsp[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCurrency[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCurrency_code[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCurrency_symbol[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
new ClientCurrency_rates[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
//new ClientCurrency_plural[MAX_PLAYERS+1][MAX_NAME_LENGTH] 
//new ClientCompleted_requests[MAX_PLAYERS+1][MAX_NAME_LENGTH]


new geo_data[MAX_RESOURCE_PATH_LENGTH][MAX_PLAYERS]

new buffer[MAX_MOTD_LENGTH];
new bool:got_coords[ MAX_PLAYERS + 1 ]
new const api[]= "ipwhois.app"

#if !defined SOCK_NON_BLOCKING
 #error Go make a new script or post and wait on forums/Discord if you are not autodidactic.
#endif

new g_socket_pass[MAX_PLAYERS+1]
new ip_api_socket

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

    server_print "%s,%s",ClientName[id],ClientIP[id]
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
            copyc(msg, charsmax(msg), buffer[containi(buffer, "success") - MAX_IP_WITH_PORT_LENGTH], '}');
            new infinity = explode_string(msg, "^",^"", geo_data, MAX_PLAYERS, MAX_RESOURCE_PATH_LENGTH, false)
            log_to_file "geo_data.txt","%s",infinity
            new list = 1
            for(new parameters;parameters < sizeof geo_data[];parameters++)
                server_print("%d:%s",list++,geo_data[parameters])

            copy(ClientLatitude[id],charsmax(ClientLatitude[]),geo_data[15][containi(geo_data[15],"latitude")+10])
            copy(ClientLongitude[id],charsmax(ClientLongitude[]),geo_data[16][containi(geo_data[16],"longitude")+11])
            copyc(ClientIsp[id],charsmax(ClientIsp[]),geo_data[19][containi(geo_data[19],"isp")+6],'"')
            copy(ClientCurrency[id],charsmax(ClientCurrency[]),geo_data[25][containi(geo_data[25],"currency")+10])
            copy(ClientCurrency_code[id],charsmax(ClientCurrency_code[]),geo_data[26][containi(geo_data[26],"currency_code")+15])
            copy(ClientCurrency_rates[id],charsmax(ClientCurrency_rates[]),geo_data[28][containi(geo_data[28],"currency_rates")+16])
            copy(ClientCurrency_symbol[id],charsmax(ClientCurrency_symbol[]),geo_data[27][containi(geo_data[27],"currency_symbol")+17])
            copy(ClientContinent[id],charsmax(ClientContinent[]),geo_data[3][containi(geo_data[3],"continent")+11])
            copy(ClientContinent_code[id],charsmax(ClientContinent_code[]),geo_data[4][containi(geo_data[4],"continent_code")+17])
            copy(ClientCountry[id],charsmax(ClientCountry[]),geo_data[5][containi(geo_data[5],"country")+9])
            copy(ClientCity[id],charsmax(ClientCity[]),geo_data[14][containi(geo_data[14],"country_city")+14])
            copy(ClientRegion[id],charsmax(ClientRegion[]),geo_data[13][containi(geo_data[13],"region")+8])
            copy(ClientCountry_code[id],charsmax(ClientCountry_code[]),geo_data[6][containi(geo_data[6],"country_code")+14])
            copy(ClientCountry_capital[id],charsmax(ClientCountry_capital[]),geo_data[8][containi(geo_data[8],"country_capital")+17])
            server_print"%s's coords: %s %s^nISP:%s. Paid in %s %s %s rate is %s. Capital of %s is %s. County code %s. %s %s",ClientName[id], ClientLatitude[id], ClientLongitude[id], ClientIsp[id], ClientCurrency_code[id], ClientCurrency_symbol[id], ClientCurrency[id], ClientCurrency_rates[id], ClientCountry[id], ClientCountry_capital[id], ClientCountry_code[id], ClientContinent[id], ClientContinent_code[id]
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
