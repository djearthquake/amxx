#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>

#define PLUGIN "Advanced Bullet Damage"
#define VERSION "2.2" ///1.0 to 2.0 is Half-Life port along with SFX. Both by SPiNX.
#define AUTHOR "Sn!ff3r & SPiNX"

#define SetBits(%1,%2)       %1 |=   1<<(%2 & 31)
#define ClearBits(%1,%2)     %1 &= ~(1<<(%2 & 31))
#define GetBits(%1,%2)       %1 &    1<<(%2 & 31)

#define charsmin    -1

new const Float:g_flCoords[][] =
{
    {0.50, 0.40},
    {0.56, 0.44},
    {0.60, 0.50},
    {0.56, 0.56},
    {0.50, 0.60}, /*Conner's contstant*/
    {0.44, 0.56},
    {0.40, 0.50},
    {0.44, 0.44}
}

new g_iPlayerPos[MAX_PLAYERS+1]

new g_iMaxPlayers
new g_pCvarEnabled

new g_type, g_enabled, g_recieved, bool:g_showrecieved, g_hudmsg1, g_hudmsg2
new g_fade_human, g_fade_npc, g_shake_human, g_shake_npc, g_cry, g_AI
new g_modname[16], g_abd_event
static g_event_fade, g_event_shake, bool:bStrike

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    g_pCvarEnabled = register_cvar("bullet_damage", "1")
    g_iMaxPlayers = get_maxplayers()

    get_modname(g_modname, charsmax(g_modname))
    bStrike = equali(g_modname, "cstrike") || equali(g_modname, "czero") ? true : false

    register_logevent("@LogEvent_Round_Start", 2, "1=Round_Start")
    register_logevent("@LogEvent_Round_End", 2, "1=Round_End")

    g_event_fade = get_user_msgid("ScreenFade")
    g_event_shake = get_user_msgid("ScreenShake")

    g_abd_event =  register_event("Damage", "@abd_event", "b", "2!0", "3=0", "4!0")

    g_type = register_cvar("amx_bulletdamage","1>0")
    g_recieved = register_cvar("amx_bulletdamage_recieved","1")

    g_hudmsg1 = CreateHudSyncObj()
    g_hudmsg2 = CreateHudSyncObj()

    g_fade_human = register_cvar("hn_human","1") //fadescreen or 'hit notify' from human attacker's landed hits.
    g_fade_npc = register_cvar("hn_npc", "1") //fadescreen from bot or npc attacker's landed hits.
    g_shake_human = register_cvar("hn_dam_hum","1") //screenshake effect on or off from human attacker's landed hits.
    g_shake_npc = register_cvar("hn_dam_npc","1") //screenshake effect on or off from bot attacker's landed hits.
    g_cry = register_cvar("hn_cry","0") //victim cries out each time you shoot them and land a shot! Different sound if human or bot. Human's squeek and bots make a short cowardly scientist cry.
}

public plugin_cfg()
if ( !bStrike )  @LogEvent_Round_Start()

@LogEvent_Round_Start()
{
    if(g_pCvarEnabled)
        enable_event(g_abd_event)
    g_enabled = get_pcvar_num(g_type)
    if(get_pcvar_num(g_recieved)) g_showrecieved = true
}

@LogEvent_Round_End()
{
    disable_event(g_abd_event)
}

public client_putinserver(id)
{
    if(is_user_connected(id))
        is_user_bot(id) ? (SetBits(g_AI, id)) : (ClearBits(g_AI, id))
}

@abd_event(id)
{
    new iType = get_pcvar_num(g_pCvarEnabled)
    if(is_user_connected(id))
    switch(iType)
    {
        case 1:sniffer(id)
        case 2:conner(id)
        case 3:spinx(id)
        default:
        {
            sniffer(id)
            conner(id)
            spinx(id);
        }
    }
}

public conner( iVictim )
{
    if( get_pcvar_num(g_pCvarEnabled) && (read_data(4) || read_data(5) || read_data(6)) )
    {
        new id = get_user_attacker(iVictim)
        if( (1 <= id <= g_iMaxPlayers) && is_user_connected(id) && ~GetBits(g_AI, id) )
        {
            new iPos = ++g_iPlayerPos[id]
            if( iPos == sizeof(g_flCoords) )
            {
                iPos = g_iPlayerPos[id] = 0
            }
            set_hudmessage(0, 40, 80, Float:g_flCoords[iPos][0], Float:g_flCoords[iPos][1], 0, 0.1, 2.5, 0.02, 0.02, -1)
            show_hudmessage(id, "%d", read_data(2))
        }
    }
}

///arcade classic effects
#include <engine>
#include <fun>
public plugin_precache()
{
    if (file_exists("sound/misc/ni1.wav"))
        precache_sound("misc/ni1.wav")
    else
        log_amx"Missing ni1.wav"
    equali(g_modname, "valve", charsmin) ? precache_sound("../../valve/sound/scientist/scream19.wav") : precache_sound("scientist/scream19.wav")
}

public sniffer(id)
{
    if(is_user_connected(id))
    {
        static attacker; attacker = get_user_attacker(id)
        static damage; damage = read_data(2)
        if(~GetBits(g_AI, id))
        {
            if(g_showrecieved)
            {
                set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.2, 0.1, 0.1, 0.0, -1)
                if(~GetBits(g_AI, id))
                    ShowSyncHudMsg(id, g_hudmsg2, "%i^n", damage)
            }
            set_hudmessage(0, 255, 100, -1.0, 0.55, 2, 0.2, 0.1, 0.1, 0.0, -1)
            switch(g_enabled)
            {
                case 1:
                {
                    if(is_user_connected(attacker))
                        ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)
                }
                case 2:
                {
                    if(fm_is_ent_visible(attacker,id))
                    {
                        if(is_user_connected(attacker))
                            ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)
                    }
                }
            }
        }
    }
}

public spinx(id)
{
    if(is_user_connected(id))
    if(is_user_alive(id))
    {
        if(~GetBits(g_AI, id))
        {
            if(get_pcvar_num(g_fade_human))
           {
                emessage_begin(MSG_ONE_UNRELIABLE,g_event_fade,{0,0,0},id)
                ewrite_short(300)       //duration
                ewrite_short(350)       //hold time
                ewrite_short(0x0001) //flags
                ewrite_byte(0)            //rgb alpha
                ewrite_byte(119)
                ewrite_byte(190)
                ewrite_byte(300)
                emessage_end()
            }
            if(get_pcvar_num(g_shake_human))
           {
                emessage_begin(MSG_ONE_UNRELIABLE,g_event_shake,{0,0,0},id)
                ewrite_short(5000)
                ewrite_short(1000)
                ewrite_short(1000)
                emessage_end()
            }
            if(get_pcvar_num(g_cry))
            {
                new attacker=get_user_attacker(id)
                if(is_user_connected(attacker) && ~GetBits(g_AI, attacker))
                {
                    client_cmd(attacker,"spk scientist/scream19.wav")
                    return PLUGIN_HANDLED
                }
            }
        }
        //NPC
        if(get_pcvar_num(g_fade_npc))
       {
            emessage_begin(MSG_ONE_UNRELIABLE,g_event_fade,{0,0,0},id)
            ewrite_short(300)
            ewrite_short(350)
            ewrite_short(0x0001)
            ewrite_byte(248)
            ewrite_byte(24)
            ewrite_byte(148)
            ewrite_byte(150)
            emessage_end()
        }
        if(get_pcvar_num(g_shake_npc))
       {
            emessage_begin(MSG_ONE_UNRELIABLE,g_event_shake,{0,0,0},id)
            ewrite_short(0)
            ewrite_short(10000)
            ewrite_short(1000)
            emessage_end()
        }
        if(get_pcvar_num(g_cry))
        {
            new attacker=get_user_attacker(id)
            if(is_user_connected(attacker && ~GetBits(g_AI, attacker)))
            {
                client_cmd(attacker,"spk misc/ni1.wav")
            }
        }
    }
    return PLUGIN_HANDLED
}
