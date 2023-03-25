/*Randomize connection times module:: https://github.com/Arkshine/BotPlayedTimeFaker/releases/tag/1.2*/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#define charsmin                    -1
#define MAX_IP_LENGTH               16
#define MAX_PLAYERS                 32
#define MAX_NAME_LENGTH             32
#define MAX_RESOURCE_PATH_LENGTH    64
#define MAX_CMD_LENGTH             128
#define PLUGIN "Fake Full"
#define VERSION "1.0"

#define FLAGS FL_PROXY|FL_FAKECLIENT|FL_NOTARGET|FL_SPECTATOR|FL_DORMANT

#define V6 "::1"
#if !defined client_disconnected
#define client_disconnect client_disconnected
#endif
new g_ifakesMn, g_ifakesMx, g_cvar_debugger, g_fake_count
new new_bot_spec
new SzSave[MAX_CMD_LENGTH]
new SzMasterNameList[MAX_RESOURCE_PATH_LENGTH][MAX_NAME_LENGTH]
new g_fake_name_pick
new Trie:g_fakeclients, g_maxplayers
enum _:Fake_client
{
    SzFakeName[ MAX_NAME_LENGTH ],
    bool:SzFakeNameInUse[ MAX_PLAYERS ]
}
new Data[ Fake_client ]
new bool: b_Bot[MAX_PLAYERS+1]

public client_authorized(id, const authid[])
{
    if(is_user_connected(id))
    {
        //b_Bot[id] = equali(authid, "BOT") ? true : false
        b_Bot[id] = is_user_bot(id) ? true : false
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id) && !b_Bot[id])
    {
        new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"d") //filter only bots
        new keystore[MAX_IP_LENGTH]
        for(new botspec;botspec < sizeof players;botspec++)
        if(is_user_connected(botspec))
        {
            get_user_info(botspec, "*bot", keystore,charsmax(keystore))
            if(str_to_num(keystore))
            {
                server_cmd( "kick #%d ^"Bot spec balance.^"", get_user_userid(players[0]) )
                g_fake_count--
            }
        }
    }
}

public client_disconnected(id)
{
    if(!b_Bot[id])
    if(g_fake_count+1 < get_pcvar_num(g_ifakesMx) && g_fake_count+1 > get_pcvar_num(g_ifakesMn)-1)
        @make_fake(id)
}
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "Anonymous");
    register_clcmd("bot_spec","@make_fake")

    g_ifakesMx = register_cvar("bot_specs","4")
    g_ifakesMn = register_cvar("bot_min","1")

    g_cvar_debugger = register_cvar("fake_debug", "1");
    g_fakeclients   = TrieCreate()
    g_fake_name_pick = charsmin
    ReadFakeFromFile( )
    g_maxplayers = get_maxplayers()
}
@init_fake_file()
{
    static SzInitFakeName[] = "Sirnumbskull"
    Data[SzFakeName] = SzInitFakeName
    if (TrieGetArray( g_fakeclients, Data[ SzFakeName ], Data, sizeof Data ))
    TrieSetArray( g_fakeclients, Data[ SzFakeName ], Data, sizeof Data )

    formatex(SzSave,charsmax(SzSave),"%s", Data[ SzFakeName ])
    @file_data(SzSave)
    ReadFakeFromFile( )
}
@file_data(SzSave[MAX_CMD_LENGTH])
{
    new debugger = get_pcvar_num(g_cvar_debugger)
    if(debugger > 1)
        server_print "%s|trying save", PLUGIN
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/fake_clients.ini" )

    write_file(szFilePath, SzSave)
}
public ReadFakeFromFile( )
{
    new szDataFromFile[ MAX_CMD_LENGTH ]
    new szFilePath[ MAX_CMD_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), "/fake_clients.ini" )
    new debugger = get_pcvar_num(g_cvar_debugger)

    new f = fopen( szFilePath, "rt" )

    if( !f )
    {
        @init_fake_file()
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
            Data[ SzFakeName ], charsmax( Data[ SzFakeName ] )
        )
        if(!equal(Data[ SzFakeName ], ""))
        {
            TrieSetArray( g_fakeclients, Data[ SzFakeName ], Data, sizeof Data )
            g_fake_name_pick++
        }

        if(debugger > 1)
            server_print "Read %s from file",Data[ SzFakeName ]

        if(g_fake_name_pick < sizeof(SzMasterNameList)-1)
        {
            copy( SzMasterNameList[g_fake_name_pick], charsmax(SzMasterNameList[]), Data[ SzFakeName ] )
            if(debugger > 1)
                server_print "Fake slot:%d",g_fake_name_pick
        }
        else
        {
            server_print "Validation of %s^n%s, is not needed now!",SzMasterNameList[g_fake_name_pick],Data[ SzFakeName ]
            goto END
        }

    }
    END:
    fclose( f )
    if(debugger > 1)
        server_print "................Fake name list file....................."
}

public plugin_end()
{
    TrieDestroy(g_fakeclients)
    new debugger = get_pcvar_num(g_cvar_debugger)
    if(debugger < -1)
        server_cmd "meta unload bot_played_time_faker_mm_i386.so"
}

@make_fake(new_bot_spec)
{
    new SzBotName[MAX_NAME_LENGTH]
    new debugger = get_pcvar_num(g_cvar_debugger)
    //TrieetArray( g_fakeclients, Data[ SzFakeName ], Data, sizeof Data )
    copy(SzBotName,charsmax(SzBotName),SzMasterNameList[random(g_fake_name_pick+1)])
    new_bot_spec = engfunc( EngFunc_CreateFakeClient, SzBotName )
    if(new_bot_spec > 0 && new_bot_spec < g_maxplayers )
    {
        g_fake_count++
        engfunc(EngFunc_FreeEntPrivateData,new_bot_spec)
        if(debugger > 1)
            server_print "[%s]Freed data on %s fake %d",PLUGIN, SzBotName, g_fake_count
        bot_settings(new_bot_spec)
        static szRejectReason[MAX_CMD_LENGTH]
        {
            set_pev(new_bot_spec,pev_spawnflags, pev(new_bot_spec,pev_spawnflags) | FLAGS)

            dllfunc( DLLFunc_ClientConnect,new_bot_spec, SzBotName,"127.0.0.1",szRejectReason)
            if(debugger > 1)
                server_print "[%s]Connecting %s fake %d",PLUGIN, SzBotName, g_fake_count

            dllfunc(DLLFunc_ClientPutInServer,new_bot_spec)
            if(debugger > 1)
                server_print "[%s]Put fake %d in as %s",PLUGIN, g_fake_count, SzBotName

            //pev(new_bot_spec, pev_flags) & FLAGS
            //set_pev(new_bot_spec,pev_flags, pev(new_bot_spec,pev_flags) & FLAGS)
            new effects = pev(new_bot_spec, pev_effects)
            //set_pev(new_bot_spec, pev_effects, (effects | EF_BRIGHTLIGHT|EF_NODRAW))
            set_pev(new_bot_spec, pev_effects, (effects | EF_LIGHT))

            set_pev(new_bot_spec, pev_takedamage, DAMAGE_YES)
            entity_set_float(new_bot_spec, EV_FL_health, 101.0)
            set_pev(new_bot_spec, pev_solid, SOLID_SLIDEBOX)
            //set_pev(new_bot_spec, pev_solid, SOLID_SLIDEBOX)
            set_pev(new_bot_spec, pev_movetype, MOVETYPE_WALK)
        }

    }

}

bot_settings(new_bot_spec)
{
    set_user_info(new_bot_spec, "model",    "ctf_gina")
    set_user_info(new_bot_spec, "team",             "BlackMesa")
    set_user_info(new_bot_spec, "rate",          "3500")
    set_user_info(new_bot_spec, "cl_updaterate",  "40")
    set_user_info(new_bot_spec, "cl_lw",            "0")
    set_user_info(new_bot_spec, "cl_lc",            "0")
    set_user_info(new_bot_spec, "tracker",          "0")
    set_user_info(new_bot_spec, "cl_dlmax",       "0")
    set_user_info(new_bot_spec, "lefthand",         "1")
    set_user_info(new_bot_spec, "friends",          "0")
    set_user_info(new_bot_spec, "dm",               "1")
    set_user_info(new_bot_spec, "ah",               "1")
    set_user_info(new_bot_spec, "*bot",             "1")
    set_user_info(new_bot_spec, "_cl_autowepswitch","1")
    set_user_info(new_bot_spec, "_vgui_menu",       "0")        //disable vgui so we dont have to
    set_user_info(new_bot_spec, "_vgui_menus",      "0")        //register both 2 types of menus :)
}

public plugin_cfg()
{
    new request_of_fakes = get_pcvar_num(g_ifakesMx)
    new unfill_server = (get_maxplayers() - 4)/2
    if( request_of_fakes >= get_maxplayers())
    {
        set_pcvar_num(g_ifakesMx,unfill_server)
        server_print "^n[%s] adjusted max fakes to %d to avoid filling server entirely^n",PLUGIN, unfill_server
    }
    set_task(float(get_pcvar_num(g_ifakesMx))*1.0, "@make_fake",new_bot_spec,_,_,"a", get_pcvar_num(g_ifakesMx));
    new debugger = get_pcvar_num(g_cvar_debugger)
    if(debugger < -1)
        server_cmd "meta load addons/bot_played_time_faker/bot_played_time_faker_mm_i386.so"
}
