#include amxmodx
#include amxmisc
#include engine
#include hamsandwich
#include fakemeta

#define alert 911
#define SPEC_PRG "spectate.amxx"
//Define your spec plugin pathway!
#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_MENU_LENGTH            512
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH              16
#define MAX_USER_INFO_LENGTH       256
#define charsmin                  -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new g_timer[MAX_PLAYERS + 1]
new g_afk_spec_player
new const CvarAFKTimeDesc[] = "Seconds before moving AFK player into spectator mode."
new sleepy[MAX_PLAYERS + 1], g_spec
new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new DownloaderName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new g_mname[MAX_NAME_LENGTH]
new bool:b_Walled[MAX_PLAYERS + 1] //dont spam cmds to wall
new bool:b_Op4c
new bool:g_bFlagMap
new afk_sync_msg, download_sync_msg//, g_spawn_wait
new g_SzMapName[MAX_NAME_LENGTH]
new bool:bCS, g_bGunGameRunning, g_AI, g_Adm
static g_event_fade

#define ALRT 84641
#define FADE_HOLD (1<<2)

public plugin_init()
{
    register_plugin("Connect Alert System","1.3","SPiNX");
    g_event_fade = get_user_msgid("ScreenFade")
    bCS = cstrike_running() == 1 ? true : false
    get_mapname(g_SzMapName, charsmax(g_SzMapName));
    g_bFlagMap = containi(g_SzMapName,"op4c") > charsmin ? true : false
    set_task(1.0, "new_users",alert,"",0,"b");

    //g_spawn_wait = get_cvar_pointer("sv_sptime") ? get_cvar_pointer("sv_sptime") : 1

    #if AMXX_VERSION_NUM == 182
        g_afk_spec_player = register_cvar("mp_autospec", "75")
    #else
        bind_pcvar_num(get_cvar_pointer("mp_autospec") ? get_cvar_pointer("mp_autospec") : create_cvar("mp_autospec", "90", FCVAR_NONE, CvarAFKTimeDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 300.0),g_afk_spec_player)
    #endif

    g_spec = get_cvar_pointer("sv_spectate_spawn")
    RegisterHam(Ham_Spawn, "player", "screensaver_stop", 1);
    get_mapname(g_mname, charsmax(g_mname))
    if(containi(g_mname, "op4c") > charsmin)
        b_Op4c=true
    //no over-lapping
    afk_sync_msg        = CreateHudSyncObj( )
    download_sync_msg   = CreateHudSyncObj( )
    if(is_plugin_loaded("gungame.amxx",true)!=charsmin)
    {
        g_bGunGameRunning = true
    }
}

public client_putinserver(index)
{
    if(is_user_connected(index))
    {
        g_timer[index] = 1
        is_user_bot(index) ? SetPlayerBit(g_AI, index) : ClearPlayerBit(g_AI, index)
        is_user_admin(index) ? SetPlayerBit(g_Adm, index) : ClearPlayerBit(g_Adm, index)
        if(CheckPlayerBit(g_AI, index) || CheckPlayerBit(g_Adm, index))
            return

        if(!task_exists(ALRT))
        {
            set_task(1.75,"the_alert", ALRT)
        }
    }
}

public the_alert()
{
    new iPlayers = get_playersnum()
    if(iPlayers)
    {
        static iSaid[MAX_PLAYERS]; num_to_word(iPlayers, iSaid, charsmax(iSaid))
        iPlayers == 1 ? client_cmd(0,"spk ^"alert a intruder is here^"")
        : client_cmd(0,"spk ^"alert %s intruder are here^"", iSaid)
    }
}

public client_authorized(id) //auth was messing up names on download
{
    get_user_name(id,ClientName[id],charsmax(ClientName[]))
    client_print 0, print_chat, "%s is lurking...", ClientName[id]
    server_print "%s is lurking...", ClientName[id]
}

public client_infochanged(id)
{
    if(is_user_connected(id))
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
}

public new_users()
{
    new players[MAX_PLAYERS], playercount;
    get_players(players,playercount,"i");

    for (new downloader; downloader<=playercount; ++downloader)
    {

        if(is_user_connecting(players[downloader]))
        {
            set_hudmessage(255, 255, 255, 0.00, 0.50, .effects= 0 , .holdtime= 5.0)
            static uptime
            uptime = g_timer[players[downloader]]++
            #if AMXX_VERSION_NUM == 182
            server_print"%s download time:%i", ClientName[players[downloader]], uptime
            #else
            server_print"%n download time:%i", players[downloader], uptime
            #endif

            if(uptime < 8)
            {
                #if AMXX_VERSION_NUM == 182

                client_print 0, print_chat,"%s is connecting...", ClientName[players[downloader]]
                server_print "%s is connecting...", ClientName[players[downloader]

                #else
                client_print 0, print_chat,"%n is connecting...", players[downloader]
                server_print "%n is connecting...", players[downloader]

                #endif
            }
            else if (uptime > 7 && uptime < 15)
            {

                #if AMXX_VERSION_NUM == 182

                ShowSyncHudMsg 0, download_sync_msg, "%s is downloading...", ClientName[players[downloader]]

                client_print 0,print_chat,"%s is downloading...", ClientName[players[downloader]]
                server_print "%s is downloading...", ClientName[players[downloader]]

                #else

                ShowSyncHudMsg 0, download_sync_msg, "%n is downloading...", players[downloader]

                client_print 0,print_chat,"%n is downloading...", players[downloader]
                server_print "%n is downloading...", players[downloader]

                #endif
            }
            else if(!b_Walled[players[downloader]])
            {
                b_Walled[players[downloader]] = true; //stop console thrash
                //Update server's built-in AMXX scrolling message.
                new SzScrolling[256], SzNewScroller[256]
                static iPlayers
                iPlayers = players[downloader]
                if(~CheckPlayerBit(g_AI, iPlayers) && is_user_connecting(iPlayers) && !is_user_connected(iPlayers))
                    copy(DownloaderName[iPlayers], charsmax(DownloaderName[]), ClientName[iPlayers])

                implode_strings( DownloaderName, charsmax(DownloaderName[]), " ", SzNewScroller, charsmax(SzNewScroller) )

                static SzBuffer[256]
                copy(SzBuffer, charsmax(SzBuffer), SzNewScroller)
                trim(SzBuffer)

                equal(SzNewScroller, "")
                ? format(SzScrolling, charsmax(SzScrolling), "%s --> downloading %s.", ClientName[iPlayers], g_SzMapName )
                :  format(SzScrolling, charsmax(SzScrolling), "%s downloaders: %s.", g_SzMapName, SzBuffer )

                server_cmd "amx_scrollmsg ^"%s^" 35", SzScrolling
            }

        }

        if(is_user_connected(players[downloader]) && !is_user_alive(players[downloader]) && ~CheckPlayerBit(g_AI, players[downloader]) && !g_bFlagMap) //stops pointless endless counting on maps with spec built already
        {
            static uptime
            uptime = sleepy[players[downloader]]++
            #if AMXX_VERSION_NUM == 182
            static spec_screensaver_engage
            spec_screensaver_engage = get_pcvar_num(g_afk_spec_player)
            #else
            static spec_screensaver_engage
            spec_screensaver_engage = g_afk_spec_player
            #endif

            if(spec_screensaver_engage < 0)
                return PLUGIN_HANDLED_MAIN

            if(!bCS)
            if(uptime > spec_screensaver_engage && !b_Op4c)
            {
                static flags
                flags = pev(players[downloader], pev_flags)
                if(flags &~ FL_SPECTATOR)
                set_hudmessage(255, 255, 255, 0.41, 0.00, .effects= 0 , .holdtime= 5.0)
                if(g_spec && is_plugin_loaded(SPEC_PRG,true)!=charsmin)
                {
                    static cvar_gg
                    cvar_gg = get_cvar_num("gg_enabled")
                    if(!g_bGunGameRunning || !cvar_gg)
                    {
                        static Group_of_players
                        Group_of_players = players[downloader]
                        log_amx "Sending %s to spec", ClientName[Group_of_players]

                        if(is_user_connected(Group_of_players) && ~CheckPlayerBit(g_AI, Group_of_players))
                        {
                            dllfunc(DLLFunc_ClientPutInServer, Group_of_players)
                            callfunc_begin("@go_spec",SPEC_PRG)
                            callfunc_push_int(Group_of_players)
                            callfunc_end()

                            sleepy[Group_of_players] = 1
                        }

                    }

                    else
                    {
                        ///SCREENSAVER:
                        screensaver(players[downloader], uptime)
                        ShowSyncHudMsg 0, afk_sync_msg, "%s is NO LONGER active...", ClientName[players[downloader]]
                    }

                }
                else
                {
                    ShowSyncHudMsg 0, afk_sync_msg, "%s is NO LONGER active...", ClientName[players[downloader]]
                    //server_print "Screensaver applied to %s",  ClientName[players[downloader]]
                    screensaver(players[downloader], uptime)
                }

            }
            else
            {
                ShowSyncHudMsg 0, afk_sync_msg, "%s is NO LONGER active...", ClientName[players[downloader]]
                client_print players[downloader], print_chat, "AFK time:%i", uptime
            }
        }
    }
    return PLUGIN_CONTINUE
}

@make_spec(id)
if(is_user_connected(id) && ~CheckPlayerBit(g_AI, id))
{
    server_print("Sending %N spec...", id)
    client_print id, print_chat, "Sending you to spec %n...", id
    client_cmd(id, "say !spec")
}

public screensaver_stop(id,{Float,_}:...)
{
    static duration, holdTime, fadeType, blindness
    duration = 1<<12
    holdTime = 1<<8
    fadeType = FADE_HOLD
    blindness = 0
    g_timer[id] = 1
    sleepy[id] = 1
    if(is_user_connected(id) && ~CheckPlayerBit(g_AI, id))
    {
        message_begin(MSG_ONE, g_event_fade, _, id);
        write_short(duration); // fade lasts this long duration
        write_short(holdTime); // fade lasts this long hold time
        write_short(fadeType); // fade type
        write_byte(0); // fade red
        write_byte(0); // fade green
        write_byte(0); // fade blue
        write_byte(blindness); // fade alpha
        message_end();
    }
}

public screensaver(id, uptime,{Float,_}:...)
if(is_user_connected(id) && ~CheckPlayerBit(g_AI, id))
{
    client_print id, print_center, "Screen saver active for:%i seconds", uptime
    message_begin(MSG_ONE_UNRELIABLE, g_event_fade, _, id);
    write_short(1<<12); // fade lasts this long duration
    write_short(1<<8); // fade lasts this long hold time
    write_short(FADE_HOLD); // fade type
    write_byte(0); // fade red
    write_byte(0); // fade green
    write_byte(0); // fade blue
    write_byte(255); // fade alpha
    message_end();
}
