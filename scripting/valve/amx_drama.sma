#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#define PITCH (random_num (85,116))

#if !defined ewrite_coord_f
    #define ewrite_coord_f ewrite_coord
#endif

#define MAX_PLAYERS                32

#define MAX_RESOURCE_PATH_LENGTH   64

#define MAX_MENU_LENGTH            512

#define MAX_NAME_LENGTH            32

#define MAX_AUTHID_LENGTH          64

#define MAX_IP_LENGTH              16

#define MAX_USER_INFO_LENGTH       256

#define charsmin                  -1

new bool: b_Bot[MAX_PLAYERS+1]

static sModel[MAX_PLAYERS];

new const SOUND_BOTDEATH1[] = "pitworm/pit_worm_alert.wav"
new const SOUND_BOTDEATH2[] = "bullchicken/bc_die2.wav"
new const SOUND_BOTDEATH3[] = "turret/tu_die2.wav"
new const SOUND_BOTDEATH4[] = "turret/tu_die3.wav"
new const SOUND_HUMANDIE1[] = "scientist/c1a0_sci_catscream.wav"
new const SOUND_HUMANDIE2[] = "scientist/scream07.wav"
new const SOUND_DRAMA1[]    = "misc/ear_ringing.wav"
new const SOUND_DRAMA2[]    = "items/suit2.wav"
new const SOUND_FART[]      = "turret/tu_ping.wav"
new G_FielD, g_Zunny, g_Drama, g_suicide;
new bStrike

public plugin_init() {
    register_plugin("Drama death sounds","1.21","SPiNX");
    register_event("ScoreInfo", "plugin_log", "bcf", "1=committed suicide with", "2=trigger_hurt");
    RegisterHam(Ham_TraceAttack, "player", "SnDamage");
    RegisterHam(Ham_Killed, "player", "client_death", 0);
    RegisterHam(Ham_Killed, "player", "model_sniffer", 1);
    bStrike = cstrike_running()
    g_suicide = engfunc(EngFunc_PrecacheEvent, 1, "events/displacer.sc")
}

public plugin_precache() {

    precache_sound(SOUND_BOTDEATH1);
    precache_sound(SOUND_BOTDEATH2);
    precache_sound(SOUND_BOTDEATH3);
    precache_sound(SOUND_BOTDEATH4);
    precache_sound(SOUND_HUMANDIE1);
    precache_sound(SOUND_HUMANDIE2);
    precache_sound(SOUND_DRAMA1);
    precache_sound(SOUND_DRAMA2);
    precache_sound(SOUND_FART);

    G_FielD = precache_model("models/skeleton.mdl")
    g_Zunny = precache_model("sprites/smoke.spr")
    g_Drama = precache_model("models/sat_globe.mdl")
}

public plugin_log()
{
    new szDummy[ MAX_PLAYERS ];
    read_logargv(2,szDummy, charsmax(szDummy))

    if (containi(szDummy, "trigger_hurt") > charsmin)
    {
        make_deathsound();
    }
}

public make_deathsound()
{
    new victim = get_loguser_index();

    if(is_user_connected(victim))
    {
        emit_sound(victim, CHAN_AUTO, SOUND_DRAMA1, 5.0, ATTN_IDLE, 0, PITCH);
        burial(victim);
    }
    return PLUGIN_HANDLED;
}

stock get_loguser_index()
{
    new loguser[80], name[32]

    read_logargv(0, loguser, 79)
    parse_loguser(loguser, name, 31)

    return get_user_index(name);
}

public SnDamage(victim)
{
    if(is_user_connected(victim) && is_user_alive(victim))
    if(get_user_health(victim) < 35.0 )
    {
        switch(random(2))
        {
            case 0: emit_sound(victim, CHAN_AUTO, SOUND_DRAMA1, VOL_NORM, ATTN_IDLE, 0, PITCH);
            case 1: emit_sound(victim, CHAN_AUTO, SOUND_FART, VOL_NORM, ATTN_IDLE, 0, PITCH);
        }
    }
}

public client_death(victim, killer)
{
    #define HLW_KNIFE           0x0019
    #define HLW_CROWBAR         1

    if(is_user_connected(killer) && is_user_connected(victim))
    {
        if(get_user_weapon(killer) != HLW_KNIFE|HLW_CROWBAR)

        if(b_Bot[victim])
        switch(random_num(0,3))
        {
            case 0: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH1, VOL_NORM, ATTN_IDLE, 0, PITCH);
            case 1: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH2, VOL_NORM, ATTN_IDLE, 0, PITCH);
            case 2: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH3, VOL_NORM, ATTN_IDLE, 0, PITCH);
            case 3: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH4, VOL_NORM, ATTN_IDLE, 0, PITCH);
        }

        if(!b_Bot[victim] && !bStrike )
        switch(random_num(0,2))
        {
            case 0: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE1, VOL_NORM, ATTN_IDLE, 0, PITCH);
            case 1: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE2, VOL_NORM, ATTN_IDLE, 0, PITCH);
            case 2: emit_sound(victim, CHAN_AUTO, SOUND_DRAMA2, 3.0, ATTN_IDLE, 0, PITCH);
        }
        port(victim, killer);
    }
}

public port(victim, killer)
{
    if(is_user_connected(victim) && is_user_connected(killer) && !b_Bot[killer])
    {
        new Float:Wector[3];
        pev(victim,pev_origin,Wector);

        if(!b_Bot[victim])
            model_sniffer(victim, killer);

        emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, killer )
        ewrite_byte( TE_FIREFIELD );
        ewrite_coord_f( Wector[0] );
        ewrite_coord_f( Wector[1] );
        ewrite_coord_f( Wector[2] );
        ewrite_short( 50 );            /*(radius)*/
        ewrite_short( G_FielD );
        ewrite_byte( 1 );              /*(count)*/
        ewrite_byte( 2 );
        ewrite_byte( 50 );
        emessage_end();
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        b_Bot[id] = is_user_bot(id) ? true : false
    }
}

public model_sniffer(victim, killer)
{
    if(killer != victim)
    if(is_user_connected(killer) && is_user_connected(victim))
    {
        #if AMXX_VERSION_NUM == 182
        new name[MAX_PLAYERS];
        get_user_name( killer, name, charsmax( name ) );
        #endif

        #define get_user_model(%1,%2,%3) engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, %1 ), "model", %2, %3 )
        get_user_model(killer, sModel, charsmax( sModel ) );

        #if AMXX_VERSION_NUM == 182
        client_print( victim, print_chat, equal(sModel,"") ? "Unobtainable Player Model" : ".............%s .....uses...model................... %s", name, sModel );
        #else
        client_print( victim, print_chat, equal(sModel,"") ? "Unobtainable Player Model" : ".............%n .....uses...model................... %s", killer, sModel );
        #endif
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED
}

public burial(victim)
{
    if(is_user_connected(victim))
    {
        new Float:Wector[3];
        pev(victim,pev_origin,Wector);

        new Float:fDelay = 1.5
        new iAngles[3], Float:fParam1, Float:fParam2, iParam1, iParam2

        engfunc(EngFunc_PlaybackEvent, (FEV_CLIENT|FEV_GLOBAL|FEV_SERVER|FEV_NOTHOST|FEV_UPDATE), victim, g_suicide, fDelay, Float:Wector, iAngles, fParam1, fParam2, iParam1, iParam2, 0, 0);

        emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0);
        ewrite_byte(TE_FIREFIELD);
        ewrite_coord_f(Wector[0]);
        ewrite_coord_f(Wector[1]);
        ewrite_coord_f(Wector[2]);
        ewrite_short(0);
        ewrite_short(g_Drama);
        ewrite_byte(1);
        ewrite_byte(28);
        ewrite_byte(30);
        emessage_end();

        emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0);
        ewrite_byte(random_num(19,21));
        ewrite_coord_f(Wector[0]);
        ewrite_coord_f(Wector[1]);
        ewrite_coord_f(Wector[2]);
        ewrite_coord_f(Wector[0]);
        ewrite_coord_f(Wector[1]);
        ewrite_coord_f(Wector[2]+1000);
        ewrite_short(g_Zunny);
        ewrite_byte(random_num(1,3));        //(starting frame)
        ewrite_byte(random_num(5,65));       //(frame rate)
        ewrite_byte(random_num(7,35));       //(life)
        ewrite_byte(random_num(92,500));     //(width)
        ewrite_byte(random_num(5,10));       //(amplitude)
        ewrite_byte(random_num(5,255));      //(red)
        ewrite_byte(random_num(5,255));      //(green)
        ewrite_byte(random_num(5,255));      //(blue)
        ewrite_byte(random_num(1200,3000));  //(brightness)
        ewrite_byte(random_num(1,10));       //(scroll speed)
        emessage_end();
    }
}
