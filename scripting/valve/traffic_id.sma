#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <geoip>

#define PLUGIN "TrafficID"
#define VERSION "B2"
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

#define local                  "127.0.0.1"
#define charsmin           -1

new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH]
new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH]

new ClientCountry[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientCity[MAX_PLAYERS+1][MAX_RESOURCE_PATH_LENGTH]
new ClientCountry_code[MAX_PLAYERS+1][4]
new ClientRegion[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH]
new bool: b_Bot[MAX_PLAYERS+1], bool: b_CS

static const SzBotTag[]="BOT"
static const szSearch[]="[s]"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    RegisterHam(Ham_Killed, "player", "client_death", 1);
    new SzModName[MAX_NAME_LENGTH]
    get_modname(SzModName, charsmax(SzModName));
    if(equal(SzModName, "cstrike"))
        b_CS = true
}

public client_authorized(id, const authid[])
{
    copy(ClientAuth[id], charsmax(ClientAuth[]), authid)
    b_Bot[id] = equali(authid, "BOT") ? true : false
    if(b_Bot[id])
    {
        copy(ClientAuth[id], charsmax(ClientAuth[]),  SzBotTag )
        copy(ClientCountry_code[id], charsmax(ClientCountry_code[]), SzBotTag)
    }
}

public client_connectex(id, const name[], const ip[], reason[128])
{
    copyc(ClientIP[id], charsmax(ClientIP[]), ip, ':')
    reason = (containi(ip, local) > charsmin) ? "IP address misread!" : "Bad STEAMID!"
/*
    if(containi(ip, local) != charsmin)
    {
        log_amx("Localhost blocked...%s, %s, %s",name, ip)
        return PLUGIN_HANDLED_MAIN
    }
*/
    copy(ClientName[id],charsmax(ClientName[]), name)

    track(id)

    return PLUGIN_CONTINUE
}

public track(id)
{
    if(b_Bot[id] || is_user_hltv(id)) return;
    if(!equal(ClientIP[id], ""))
    {
        #if AMXX_VERSION_NUM == 182
            geoip_country( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]) );
        #else
            geoip_country_ex( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]), 2 );
        #endif
        get_user_authid(id, ClientAuth[id], charsmax(ClientAuth[]))

        geoip_city(ClientIP[id], ClientCity[id], charsmax(ClientCity[]), 1)
        geoip_region_name(ClientIP[id], ClientRegion[id], charsmax(ClientRegion[]), 2)

        geoip_code3_ex(ClientIP[id], ClientCountry_code[id])

        if ( b_CS )
        {
            client_print_color 0, 0, "^x03%s^x01 ^x04%s^x01 from ^x04%s^x01 appeared on ^x04%s^x01 , ^x04%s^x01 radar.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
        }
        else
        {
            client_print 0, print_chat,"%s %s from %s appeared on %s, %s radar.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
        }
        log_amx "Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    }
}

public client_infochanged(id)
{

    if(is_user_connected(id))
    {
        new szBuffer[MAX_NAME_LENGTH]
        get_user_name(id, szBuffer, charsmax(szBuffer))

        if(contain(szBuffer, szSearch) == charsmin)
            copy(ClientName[id], charsmax(ClientName[]), szBuffer)
    }
}

public client_death(victim, killer)
{
    if(is_user_connected(killer)) //filter out mortars etc!
    {
        new ClientVicName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
        new ClientKilName[MAX_PLAYERS+1][MAX_NAME_LENGTH]

        formatex(ClientKilName[killer], charsmax(ClientKilName[]), "[%s]%s", ClientCountry_code[killer], ClientName[killer] )
        formatex(ClientVicName[victim], charsmax(ClientVicName[]), "[%s]%s", ClientCountry_code[victim], ClientName[victim] )

        if(!equal(ClientVicName[victim],"") && !equal(ClientKilName[killer],"") )
        {
            client_print 0, print_chat, "%s killed %s", ClientKilName[killer], ClientVicName[victim]
        }
    }
}

public client_disconnected(id)
{
    if (b_Bot[id] || is_user_hltv(id)) return;
    #if AMXX_VERSION_NUM != 182
    if ( b_CS )
        client_print_color 0, 0, "%s %s by %s|^x03%s^x01 ^x04%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", PLUGIN,VERSION,AUTHOR, ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    else
        client_print 0, print_chat, "%s %s by %s|%s %s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    #else
        client_print 0, print_chat, "%s %s by %s|%s %s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
    #endif
}
