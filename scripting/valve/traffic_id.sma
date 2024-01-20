#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <geoip>

#define PLUGIN "TrafficID"
#define VERSION "B3"
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
new bool: b_Bot[MAX_PLAYERS+1], bool:b_Admin[MAX_PLAYERS + 1], bool: b_CS
new g_iHeadcount,g_players[ MAX_PLAYERS ]
new bNameCheck[MAX_PLAYERS + 1]

static const SzBotTag[]="BOT";

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_event("DeathMsg","death_event","a")
    static SzModName[MAX_NAME_LENGTH]
    get_modname(SzModName, charsmax(SzModName));
    if(equal(SzModName, "cstrike") || equal(SzModName, "czero") )
        b_CS = true
}
public client_connectex(id, const name[], const ip[], reason[128])
{
    copyc(ClientIP[id], charsmax(ClientIP[]), ip, ':')
    reason = (containi(ip, local) > charsmin) ? "IP address misread!" : "Bad STEAMID!"
    copy(ClientName[id],charsmax(ClientName[]), name)
    return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        b_Bot[id] = is_user_bot(id) ? true : false
        b_Admin[id] = is_user_admin(id) ? true : false
        track(id)
    }
}

stock iPlayers()
{
    get_players(g_players,g_iHeadcount,"ch")
    return g_iHeadcount
}

public track(id)
{
    if(is_user_connected(id))
    {
        if(!is_user_hltv(id))
        iPlayers()

        if(b_Bot[id])
        {
            copy(ClientAuth[id], charsmax(ClientAuth[]),  SzBotTag )
            copy(ClientCountry_code[id], charsmax(ClientCountry_code[]), SzBotTag)
            return PLUGIN_HANDLED
        }

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
            if( g_iHeadcount > 0 )
            {
                for (new admin=1; admin<=g_iHeadcount; ++admin)

                if(is_user_connected(admin) && !b_Bot[admin])

                if ( b_CS )
                {
                    b_Admin[admin] ? client_print_color(admin, 0, "^x03%s^x01 ^x04%s^x01 from ^x04%s^x01 appeared on ^x04%s^x01 , ^x04%s^x01 radar.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]) :
                    client_print_color(admin, 0, "^x03%s^x01  from ^x04%s^x01 appeared on ^x04%s^x01 , ^x04%s^x01 radar.", ClientName[id], ClientCountry[id], ClientCity[id], ClientRegion[id])
                }
                else
                {
                    b_Admin[admin] ? client_print(admin, print_chat,"%s %s from %s appeared on %s, %s radar.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]) :
                    client_print(admin, print_chat,"%s from %s appeared on %s, %s radar.", ClientName[id], ClientCountry[id], ClientCity[id], ClientRegion[id])
                }
                log_amx "Name: %s, ID: %s, Country: %s, City: %s, Region: %s joined.", ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]
            }
        }
    }
    return PLUGIN_CONTINUE
}

public client_command(id)
{
    if(is_user_connected(id))
    {
        static szArgCmd[MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH]
        read_argv(0, szArgCmd, charsmax(szArgCmd));

        if (equal(szArgCmd,"name") != charsmin && !bNameCheck[id])
        {
            client_infochanged(id)
            bNameCheck[id] = true
            return PLUGIN_HANDLED
        }
    }
    return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{

    if(is_user_connected(id))
    {
        static szBuffer[MAX_NAME_LENGTH]
        get_user_name(id, szBuffer, charsmax(szBuffer))

        copy(ClientName[id], charsmax(ClientName[]), szBuffer)
        b_Admin[id] = is_user_admin(id) ? true : false
        bNameCheck[id] = false
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public death_event()
{
    static killer,victim;
    victim = read_data(2); killer = get_user_attacker(victim);
    static ClientVicName[MAX_PLAYERS+1][MAX_NAME_LENGTH], ClientKilName[MAX_PLAYERS+1][MAX_NAME_LENGTH]
    ///filter out mortars etc!
    if(is_user_connected(killer) && is_user_connected(victim))
    {
        formatex(ClientKilName[killer], charsmax(ClientKilName[]), "[%s]%s", ClientCountry_code[killer], ClientName[killer] )
        formatex(ClientVicName[victim], charsmax(ClientVicName[]), "[%s]%s", ClientCountry_code[victim], ClientName[victim] )

        if(!equal(ClientVicName[victim],"") && !equal(ClientKilName[killer],"") )
        {
            client_print( 0, print_chat, "%s killed %s", ClientKilName[killer], ClientVicName[victim])
        }
    }
}

public client_disconnected(id)
{
    iPlayers()

    if( g_iHeadcount > 0 )
    {
        if(b_Bot[id] || is_user_hltv(id)) return;
        for (new admin=1; admin<=g_iHeadcount; admin++)
        if(is_user_connected(admin))
        {
            if(!b_Bot[admin])
            {
                #if AMXX_VERSION_NUM != 182
                if ( b_CS )
                    b_Admin[admin] ? client_print_color(admin, 0, "%s %s by %s|^x03%s^x01 ^x04%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", PLUGIN,VERSION,AUTHOR, ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]) :
                    client_print_color(admin, 0, "%s %s by %s|^x03%s^x01 from ^x04%s^x01 disappeared on ^x04%s^x01, ^x04%s^x01 radar.", PLUGIN,VERSION,AUTHOR, ClientName[id], ClientCountry[id], ClientCity[id], ClientRegion[id])
                else
                    b_Admin[admin] ? client_print(admin, print_chat, "%s %s by %s|%s %s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]) :
                    client_print(admin, print_chat, "%s %s by %s|%s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientCountry[id], ClientCity[id], ClientRegion[id])
                #else
                    b_Admin[admin] client_print(admin, print_chat, "%s %s by %s|%s %s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientAuth[id], ClientCountry[id], ClientCity[id], ClientRegion[id]) :
                    client_print(admin, print_chat, "%s %s by %s|%s from %s disappeared on %s, %s radar.", PLUGIN,VERSION,AUTHOR,ClientName[id], ClientCountry[id], ClientCity[id], ClientRegion[id])
                #endif
            }
        }
    }
}
