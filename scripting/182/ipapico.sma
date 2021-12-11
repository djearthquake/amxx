/*Fix Amxx not getting lon and lat*/
#include amxmodx
#include sockets

#define PLUGIN "Geo API"
#define VERSION "1.0"
#define AUTHOR ".sρiηX҉."

#define COORD 3245

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

new buffer[ MAX_MOTD_LENGTH ];
new bool:got_coords[ MAX_PLAYERS + 1 ]
new const api[]= "ipwhois.app"

new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH]
new ClientLON[MAX_PLAYERS+1][8]
new ClientLAT[MAX_PLAYERS+1][8]

new ip_api_socket
public plugin_init()
    register_plugin(PLUGIN, VERSION, AUTHOR);

public client_putinserver(id)
{
    if(is_user_connected(id) && !is_user_bot(id) && id > 0)
    {
        if(!task_exists(id))
            set_task(1.0,"@get_user_data", id)
    }
}

@get_user_data(id)
if(is_user_connected(id))
{
    get_user_name(id, ClientName[id],charsmax(ClientName[]))
    get_user_ip( id, ClientIP[id], charsmax( ClientIP[] ), WITHOUT_PORT );
    server_print "%s,%s",ClientName[id],ClientIP[id]
    set_task(1.0,"get_client_data", id, ClientIP[id], charsmax( ClientIP[] ))
}

public get_client_data(ClientIP[])
{
    new id, Soc_O_ErroR2
    new constring[MAX_USER_INFO_LENGTH]
    ip_api_socket = socket_open(api, 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
    formatex(constring, charsmax (constring), "GET http://%s/json/%s HTTP/1.0^nHost: %s^n^n", api, ClientIP[id], api);
    server_print "%s",constring

    set_task(0.5, "write_web", id+COORD, constring, charsmax(constring) );
    set_task(1.5, "read_web", id+COORD);
}
public write_web(text[MAX_USER_INFO_LENGTH], Task)
{

    new id = Task - COORD

    #if AMXX_VERSION_NUM != 182
    if (socket_is_writable(ip_api_socket, 100000))
    #endif
    {
        socket_send(ip_api_socket,text,charsmax (text));
        get_user_name(id, ClientName[id],charsmax(ClientName[]))
        server_print "Yes! %s:writing the web for ^n%s",PLUGIN, ClientName[id]
    }

}
public read_web(Tsk)
{
    new id = Tsk - COORD
    server_print "%s:reading %s coords",PLUGIN, ClientName[id]
    #if AMXX_VERSION_NUM != 182
    if (socket_is_readable(ip_api_socket, 100000))
    #endif
    socket_recv(ip_api_socket,buffer,charsmax(buffer) )
    if (!equal(buffer, "") && containi(buffer, "latitude") > charsmin && containi(buffer, "longitude") > charsmin)
    {
        new float:lat[8],float:lon[8];
        copyc(lat, 6, buffer[containi(buffer, "latitude") + 11], '"');
        replace(lat, 6, ":", "");
        replace(lat, 6, ",", "");

        copy(ClientLAT[id], charsmax( ClientLAT[] ),lat)

        copyc(lon, 6, buffer[containi(buffer, "longitude") + 12], '"');
        replace(lon, 6, ":", "");
        replace(lon, 6, ",", "");

        copy(ClientLON[id], charsmax( ClientLON[] ),lon)

        server_print "%s's^n^nlat:%f|lon:%f",ClientName[id],str_to_float(ClientLAT[id]),str_to_float(ClientLON[id])
        got_coords[id] = true
    }
    else if(!got_coords[id])
    {
        server_print "No buffer checking again"
        set_task(1.5, "read_web",id+COORD)
    }
    else
    {
        if(socket_close(ip_api_socket) == 1)
            server_print "%s finished %s reading",PLUGIN, ClientName[id]
    }
    return PLUGIN_CONTINUE
}
