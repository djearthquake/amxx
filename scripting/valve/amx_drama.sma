#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#define PITCH (random_num (90,111))
#define get_user_model(%1,%2,%3) engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, %1 ), "model", %2, %3 )
static sModel[MAX_PLAYERS];
new const SND_BOTDEATH1[]   = "sound/pitworm/pit_worm_alert.wav"
new const SND_BOTDEATH2[]   = "sound/bullchicken/bc_die2.wav"
new const SND_BOTDEATH3[]   = "sound/turret/tu_die2.wav"
new const SND_BOTDEATH4[]   = "sound/turret/tu_die3.wav"
new const SND_HUMANDIE1[]   = "sound/scientist/c1a0_sci_catscream.wav"
new const SND_HUMANDIE2[]   = "sound/scientist/scream07.wav"
new const SND_DRAMA1[]      = "sound/misc/ear_ringing.wav"
new const SND_DRAMA2[]      = "sound/items/suit2.wav"
new const SND_FART[]        = "sound/turret/tu_ping.wav"

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

public plugin_init() {
    register_plugin("Drama death sounds","1.2","SPiNX");
    register_event("ScoreInfo", "plugin_log", "bcf", "1=committed suicide with", "2=trigger_hurt" );
    RegisterHam(Ham_TraceAttack, "player", "SnDamage");
    RegisterHam(Ham_Killed, "player", "client_death");
    RegisterHam(Ham_Killed, "player", "model_sniffer");
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

    precache_generic(SND_BOTDEATH1);
    precache_generic(SND_BOTDEATH2);
    precache_generic(SND_BOTDEATH3);
    precache_generic(SND_BOTDEATH4);
    precache_generic(SND_HUMANDIE1);
    precache_generic(SND_HUMANDIE2);
    precache_generic(SND_DRAMA1);
    precache_generic(SND_DRAMA2);
    precache_generic(SND_FART);
    G_FielD = precache_model("models/skeleton.mdl")
    precache_generic("models/skeleton.mdl")
    g_Zunny = precache_model("sprites/smoke.spr")
    precache_generic("sprites/smoke.spr");
    g_Drama = precache_model("models/sat_globe.mdl")
    precache_generic("models/sat_globe.mdl")
}

public plugin_log()

{
    new szDummy[ MAX_PLAYERS ];
    read_logargv(2,szDummy, charsmax(szDummy))
    if (containi(szDummy, "trigger_hurt") != -1)make_deathsound();
}
public make_deathsound()

{
    new victim = get_loguser_index();

    if(is_user_connected(victim))
    
    {
        emit_sound(victim, CHAN_AUTO, SOUND_DRAMA1, 5.0, ATTN_IDLE, 0, PITCH);
        burial(victim);
    }

    {
    return PLUGIN_HANDLED;
    }
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
    if ( get_user_health(victim) < 35.0 )
    {
        switch(random_num(0,1))
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
    if(is_user_connected(killer) && get_user_weapon(killer) == HLW_KNIFE|HLW_CROWBAR)return;
    if (is_user_bot(victim))
    switch(random_num(0,3))
    {
        case 0: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH1, VOL_NORM, ATTN_IDLE, 0, PITCH);
        case 1: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH2, VOL_NORM, ATTN_IDLE, 0, PITCH);
        case 2: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH3, VOL_NORM, ATTN_IDLE, 0, PITCH);
        case 3: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH4, VOL_NORM, ATTN_IDLE, 0, PITCH);
    }

    if (!is_user_bot(victim) && !cstrike_running() )
    switch(random_num(0,2))
    {
        case 0: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE1, VOL_NORM, ATTN_IDLE, 0, PITCH);
        case 1: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE2, VOL_NORM, ATTN_IDLE, 0, PITCH);
        case 2: emit_sound(victim, CHAN_AUTO, SOUND_DRAMA2, 3.0, ATTN_IDLE, 0, PITCH);
    }
    port(victim, killer);
}

public port(victim, killer)
{
    if(is_user_connected(victim) && is_user_connected(killer) && !is_user_bot(killer))
    {
        new Float:Wector[3];
        pev(victim,pev_origin,Wector);

        if(!is_user_bot(victim))
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

public model_sniffer(victim, killer)

{
    new name[MAX_PLAYERS];

    if( is_user_connected(killer) )
      get_user_name( killer, name, charsmax( name ) );


    if (killer == victim) return PLUGIN_HANDLED_MAIN;

    get_user_model(killer, sModel, charsmax( sModel ) );
      
    if(equal(sModel,""))return PLUGIN_HANDLED_MAIN;
    
    else

    client_print( victim, print_chat, ".............%s .....uses...model................... %s", name, sModel );
    ////BUG:·Only·shows·to·full·admin·right·users·on·Gearbox·with·Amxx110?
    return PLUGIN_CONTINUE;
}

public burial(victim)
if(is_user_connected(victim))
{
    new Float:Wector[3];
    pev(victim,pev_origin,Wector);
    engfunc(EngFunc_PlaybackEvent, FEV_NOTHOST, 0, g_suicide, 0.0, Float:Wector, Float:{0.0, 0.0, 0.0}, 0.0, 0.0, 0, 0, 0, 0)

    //emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, victim);
    emessage_begin(0,23)
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

    //emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, victim);
    emessage_begin(0,23)
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
