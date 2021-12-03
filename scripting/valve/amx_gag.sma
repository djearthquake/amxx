/*Amx gag*/
#include <amxmodx>
#include <amxmisc>
#include <time>

#define ADMIN_FLAG ADMIN_RCON
const charsmin              =   -1
const MAX_CMD_LENGTH        =   128

new gaglist[MAX_CMD_LENGTH]
new g_flood_time
new g_aggers;
new g_advise;

new Trie:g_Orders
new g_Dcheck[MAX_IP_LENGTH]
new szDataFromFile[ MAX_CMD_LENGTH ]

new g_szAuthID[ MAX_PLAYERS+1 ][ MAX_AUTHID_LENGTH ]

new g_Time_now
new Lift_date

enum _:Gags
{
    SteamID[ MAX_AUTHID_LENGTH ],
    Expiration_date[ MAX_PLAYERS ],
    Seconds_left[ MAX_PLAYERS ]
}
new Data[ Gags ]

new szExpiration_date[MAX_PLAYERS]

new debugger

public client_authorized( id )
    get_user_authid( id, g_szAuthID[ id ], charsmax( g_szAuthID[ ] ) )

public plugin_init()
{
    register_plugin("Gag bad players", "1.1", "SPiNX")
    register_dictionary("time.txt")
    register_clcmd("say", "OnSay")
    register_clcmd("say_team", "OnSay")

    g_flood_time = register_cvar("gag_flood_time", "2.5")
    g_advise = register_cvar("gag_flood_advise", "1")
    g_aggers = register_cvar("sv_gaglist", "");

    time_now()
    g_Orders = TrieCreate( )

    ReadGagsFromFile( )

    debugger = get_pcvar_num(g_advise) > 1
    register_concmd( "amx_gag", "GagCmd", ADMIN_FLAG, "<STEAMID to block> <HH:MM:SS MM/DD/YYYY>" )

}

public OnSay(id)
{

    if (is_user_connected(id))
    {
        get_pcvar_string(g_aggers, gaglist, charsmax (gaglist))
        if(TrieGetArray( g_Orders, g_szAuthID[ id ], Data, sizeof Data ) &&  Data[ Seconds_left ] > 0 || task_exists(id) || containi( g_szAuthID[ id ], gaglist) != charsmin )
        {

            if(get_pcvar_num(g_advise))
            {
                updated_gag_time(id)
                new locale[MAX_CMD_LENGTH], type = timeunit_seconds, unitCnt =  Data[ Seconds_left ]

                get_time_length(id, unitCnt, type, locale, charsmax(locale))
                replace(Data[ Seconds_left ],charsmax(Data[ Seconds_left ]),".","")
                Data[ Seconds_left ] > 0 && !equali(locale,"") ? client_print( id, print_chat, "Steam ID: %s Gag Expiration:^n^n%s.", Data[ SteamID ], locale) :

                client_print(id,print_center,"Chat message blocked!");

            }
            return PLUGIN_HANDLED_MAIN;

        }
        if(!task_exists(id))
            set_task(get_pcvar_float(g_flood_time),"@antiflood",id)
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED

}

@antiflood(id)
if(get_pcvar_num(g_advise) > 1)
{
    switch(random_num(0,2))
    {
        case 0 : client_cmd(id,"spk intro/g7_copy_hq.wav");
        case 1 : client_cmd(id,"spk intro/g3_copy.wav");
        case 2 : client_cmd(id,"spk shocktrooper/ras.wav");
    }

}

public GagCmd( id, level, cid )
{
    if( !cmd_access( id, level, cid, 2 ) )
        return PLUGIN_HANDLED

    new SzGag[MAX_CMD_LENGTH]
    read_args(SzGag,charsmax(SzGag))

    new szIdentifier[ MAX_AUTHID_LENGTH ]
    read_argv( 1, szIdentifier, charsmax( szIdentifier ) )

    new szExpire[ MAX_PLAYERS]
    read_argv( 2, szExpire, charsmax( szExpire ) )

    TrieGetArray( g_Orders, szIdentifier, Data, sizeof Data )
    client_print( id, print_console, "User has a history with us." )

    time_now()
    copy(szExpiration_date, charsmax( szExpiration_date ),szExpire)
    expiration(szExpiration_date)

    if(Lift_date > g_Time_now)
    {
        Data[ Seconds_left ] = (Lift_date - g_Time_now)
        client_print( id, print_console, "Gag added with success." )
    }
    else
    {
        Data[ Seconds_left ] = 0
        client_print( id, print_console, "Ungagged %s|%s",szIdentifier, szExpiration_date )
    }

    Data[ SteamID ]        = szIdentifier
    Data[ Expiration_date] = szExpire
    TrieGetArray( g_Orders, Data[ SteamID ], Data, sizeof Data ) ?
    TrieSetArray( g_Orders, Data[ SteamID ], Data, sizeof Data ) :
    @file_gag(SzGag), TrieSetArray( g_Orders, Data[ SteamID ], Data, sizeof Data )

    return PLUGIN_HANDLED
}


@file_gag(SzGag[MAX_CMD_LENGTH])
{
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/gagged_players.ini" )

    write_file(szFilePath, SzGag)
}

public ReadGagsFromFile( )
{
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/gagged_players.ini" )

    new f = fopen( szFilePath, "rt" )

    if( !f )
    {
        new szMessage[ MAX_USER_INFO_LENGTH ]
        formatex( szMessage, charsmax( szMessage ), "Unable to open %s", szFilePath )
        set_fail_state( szMessage )
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
            Data[ SteamID ], charsmax( Data[ SteamID ] ),
            szExpiration_date, charsmax( szExpiration_date )
        )

        if(debugger)
            server_print "%s|Exp date:%s",Data[ SteamID ],szExpiration_date

        expiration(szExpiration_date)

        if(Lift_date > g_Time_now)
        {
            Data[ Seconds_left ] = (Lift_date - g_Time_now)
            Data[ Expiration_date] = szExpiration_date

            TrieSetArray( g_Orders, Data[ SteamID ], Data, sizeof Data )
        }


    }
    fclose( f )
    if(debugger)
        server_print "................HALL OF GAG SHAME....................."
}
stock expiration(szExpiration_date[MAX_PLAYERS])

    return Lift_date = parse_time( szExpiration_date, "%H:%M:%S %m:%d:%Y", -1 )

public updated_gag_time(id)
{
    new time = time_now(), Lift_date1

    if(TrieGetArray( g_Orders, g_szAuthID[ id ], Data, sizeof Data ))
    {
        Lift_date1 = parse_time(  Data[ Expiration_date ], "%H:%M:%S %m:%d:%Y", -1 )
        debugger = get_pcvar_num(g_advise) > 1

        if(debugger)
           server_print "Lift date seconds %i^n^nfrom %s", Lift_date1,Data[ Expiration_date ]

        if(Lift_date1 > time)
            server_print "Sec left %i", Data[ Seconds_left ]
        else
             server_print "Ungagged %i seconds ago.", Data[ Seconds_left ]

        Data[ Seconds_left ] = (Lift_date1 - time)
        TrieSetArray( g_Orders, g_szAuthID[ id ],  Data[ Seconds_left ],  charsmax(Data[]) )

    }

}

public plugin_end()
    TrieDestroy(g_Orders)

stock time_now()
{
    static iHour,iMin,iSec;
    time(iHour,iMin,iSec)

    static SzYear,SzMonth,SzDay;
    date(SzYear,SzMonth,SzDay)

    debugger = get_pcvar_num(g_advise) > 1
    if(debugger)
        server_print "^n^n^n^n^n^nTime is %i:%i:%i.^n^nDate is %i/%i/%i",iHour,iMin,iSec,SzMonth,SzDay,SzYear

    formatex(g_Dcheck,charsmax(g_Dcheck),"%i:%i:i %i/%i/%i",iHour,iMin,iSec,SzMonth,SzDay,SzYear)

    g_Time_now = parse_time(g_Dcheck,"%H:%M:%S %m:%d:%Y", -1)
    if(debugger)
        server_print "Epoch now is %i",g_Time_now

    return g_Time_now
}
/*
 * ; sample of gagged_players.ini file
 * ; path addons/amxmodx/configs
 * ; remove semi-colon to uncomment
 * ;"STEAMID1" "HH:MM:SS MM/DD/2050"
 * ;"STEAMID2" "HH:MM:SS MM/DD/2020"
 * ;"STEAMID3" "HH:MM:SS MM/DD/2030"
 * ;"STEAM_0:1:10012" "02:02:02 12/01/2021"
*/
