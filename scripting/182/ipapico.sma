/*Fix Amxx not getting lon and lat*/
#include amxmodx
#include sockets

#define PLUGIN "Geo API"
#define VERSION "1.0"
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
new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH]

new buffer[ MAX_MENU_LENGTH ];
new bool:got_coords[ MAX_PLAYERS + 1 ]
new const api[]= "ipwhois.app"

///////////COPY AND PASTE HERE BELOW TO UTILIZE IP TO LON&LAT API INTO EXISTING SOCKETS PLUGIN
#if !defined SOCK_NON_BLOCKING
 #error Go make a new script or post and wait on forums/Discord if you are not autodidactic.
#endif
new ClientLON[MAX_PLAYERS+1][8]
new ClientLAT[MAX_PLAYERS+1][8]

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
            g_socket_pass[id] = 0
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

            server_print("%s's lat:%f|lon:%f",ClientName[id],str_to_float(ClientLAT[id]),str_to_float(ClientLON[id]))
            got_coords[id] = true
            if(socket_close(ip_api_socket) == 1)
                server_print "%s finished %s reading",PLUGIN, ClientName[id]
            else
                server_print "%s already closed the socket on %s!",api,ClientName[id]

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
