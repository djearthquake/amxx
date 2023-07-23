#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>

#define PLUGIN "Advanced Bullet Damage"
#define VERSION "2.1" ///1.0 to 2.0 is Half-Life port along with SFX. Both by SPiNX.
#define AUTHOR "Sn!ff3r & SPiNX"

#define SetBits(%1,%2)       %1 |=   1<<(%2 & 31)
#define ClearBits(%1,%2)     %1 &= ~(1<<(%2 & 31))
#define GetBits(%1,%2)       %1 &    1<<(%2 & 31)

//Conners contstant
new const Float:g_flCoords[][] =
{
    {0.50, 0.40},
    {0.56, 0.44},
    {0.60, 0.50},
    {0.56, 0.56},
    {0.50, 0.60},
    {0.44, 0.56},
    {0.40, 0.50},
    {0.44, 0.44}
}

new g_iPlayerPos[MAX_PLAYERS+1]

new g_iMaxPlayers
new g_pCvarEnabled

//end conner's constant

new g_type, g_enabled, g_recieved, bool:g_showrecieved, g_hudmsg1, g_hudmsg2
new g_fade_human, g_fade_npc, g_shake_human, g_shake_npc, g_cry, g_AI
static g_event_fade, g_event_shake

public plugin_init()
{
    //conner mccloud
    g_pCvarEnabled = register_cvar("bullet_damage", "1")

    register_event("Damage", "Event_Damage", "b", "2>0", "3=0")

    g_iMaxPlayers = get_maxplayers()

    //conner end

    register_plugin(PLUGIN, VERSION, AUTHOR)

    g_event_fade = get_user_msgid("ScreenFade")
    g_event_shake = get_user_msgid("ScreenShake")

    register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")
    if ( cstrike_running() )register_event("HLTV", "on_new_round", "a", "1=0", "2=0");

    g_type = register_cvar("amx_bulletdamage","1")
    g_recieved = register_cvar("amx_bulletdamage_recieved","1")

    g_hudmsg1 = CreateHudSyncObj()
    g_hudmsg2 = CreateHudSyncObj()

    /////*//*//*/////
    ///*//half-life/*///
    /////*//*//*////
     /*HL PORT*/
    register_event("Damage", "got_hit", "b")
    g_fade_human = register_cvar("hn_human","1") //fadescreen or 'hit notify' from human attacker's landed hits.
    g_fade_npc = register_cvar("hn_npc", "1") //fadescreen from bot or npc attacker's landed hits.
    g_shake_human = register_cvar("hn_dam_hum","1") //screenshake effect on or off from human attacker's landed hits.
    g_shake_npc = register_cvar("hn_dam_npc","1") //screenshake effect on or off from bot attacker's landed hits.
    g_cry = register_cvar("hn_cry","0") //victim cries out each time you shoot them and land a shot! Different sound if human or bot. Human's squeek and bots make a short cowardly scientist cry.

    if ( cstrike_running() ) return;
    else
    {
        g_enabled = get_pcvar_num(g_type)
        if(get_pcvar_num(g_recieved)) g_showrecieved = true
    }
     /*HL PORT*/
    /////*//*//*/////
    ///*//halflife/*///
    /////*//*//*////
}

public on_new_round()
{
    g_enabled = get_pcvar_num(g_type)
    if(get_pcvar_num(g_recieved)) g_showrecieved = true
}

public client_putinserver(id)
{
    is_user_bot(id) ? (SetBits(g_AI, id)) : (ClearBits(g_AI, id))
}
//Conner's

public Event_Damage( iVictim )
{
    if( get_pcvar_num(g_pCvarEnabled) && (read_data(4) || read_data(5) || read_data(6)) )
    {
        new id = get_user_attacker(iVictim)
        if( (1 <= id <= g_iMaxPlayers) && is_user_connected(id) )
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

//Conner's

///arcade classic effects
#include <engine>
#include <fun>
public plugin_precache()
{
    precache_sound("misc/ni1.wav")
    precache_sound("../../valve/sound/scientist/scream19.wav")
}

public on_damage(id)
{
    if(g_enabled)
    {
        static attacker; attacker = get_user_attacker(id)
        static damage; damage = read_data(2)
        if(g_showrecieved)
        {
            set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
            ShowSyncHudMsg(id, g_hudmsg2, "%i^n", damage)
        }
        if(is_user_connected(attacker))
        {
            switch(g_enabled)
            {
                case 1:
                {
                    set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
                    ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)
                }
                case 2:
                {
                    if(fm_is_ent_visible(attacker,id))
                    {
                        set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
                        ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)
                    }
                }
            }
        }
    }
}

public got_hit(id)
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
                if(is_user_connected(attacker))
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
            if(is_user_connected(attacker))
            {
                client_cmd(attacker,"spk misc/ni1.wav")
            }
        }
    }
    return PLUGIN_HANDLED
}
