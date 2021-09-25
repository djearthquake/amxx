#include <amxmodx>
#include <amxmisc>
#include <geoip>

#define PLUGIN "TrafficID"
#define VERSION "A1"
#define AUTHOR "SPiNX"
#define WITHOUT_PORT    1
#if !defined client_disconnected
#define client_disconnect client_disconnected
#endif

#define MAX_AUTHID_LENGTH          64
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_PLAYERS                32
#define MAX_NAME_LENGTH            32
#define MAX_IP_LENGTH              16

new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH+1]

new ClientCountry[MAX_PLAYERS+1][MAX_NAME_LENGTH+1]
new ClientCity[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH+1]
new ClientRegion[MAX_PLAYERS+1][MAX_NAME_LENGTH+1]
new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH+1]

public client_putinserver(id)
{
    if (is_user_bot(id) || is_user_hltv(id)) return;

    #if AMXX_VERSION_NUM == 182
        geoip_country( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]) );
    #else
        geoip_country_ex( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]), 2 );
    #endif

    get_user_name(id,ClientName[id],charsmax(ClientName[]))
    get_user_authid(id,ClientAuth[id],charsmax(ClientAuth[]))

    geoip_city(ClientIP[id],ClientCity[id],charsmax(ClientCity[]),1)
    geoip_region_name(ClientIP[id],ClientRegion[id],charsmax(ClientRegion[]),2)

    #if AMXX_VERSION_NUM != 182
    if ( cstrike_running() )
        client_print_color(0,id, "^x03%n^x01 ^x04%s^x01 from ^x04%s^x01 appeared on ^x04%s^x01 , ^x04%s^x01 radar.", id, ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
        && goto log;
    #else
        client_print 0,print_chat,"%s %s from %s appeared on %s, %s radar.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    #endif
    #if AMXX_VERSION_NUM != 182
    log:
    #endif

    log_amx "Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    
}
public plugin_init()
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
public client_authorized(id)
    get_user_ip( id, ClientIP[id], charsmax( ClientIP[] ), WITHOUT_PORT );

public client_disconnected(id)
{
    if (is_user_bot(id) || is_user_hltv(id)) return;
    #if AMXX_VERSION_NUM != 182
    if ( cstrike_running() )
        client_print_color 0,id, "%s %s by %s|^x03%n^x01 ^x04%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", PLUGIN,VERSION,AUTHOR, id, ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    #else
        client_print 0,print_chat,"%s %s by %s|%s %s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    #endif
} 
