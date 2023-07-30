#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <engine_stocks>
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

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

//new const ent_type[]="func_rotating"

new g_AI

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
new bool:bIsAdmin[ MAX_PLAYERS + 1];
new G_FielD, g_Zunny, g_Drama, g_suicide, g_specter;
new bStrike

public plugin_init() {
    register_plugin("Drama death sounds","1.22","SPiNX");
    register_event("ScoreInfo", "plugin_log", "bcf", "1=committed suicide with", "2=trigger_hurt");
    register_event_ex ( "ResetHUD" , "@spawn", RegisterEvent_Single|RegisterEvent_OnlyAlive )

    RegisterHam(Ham_TraceAttack, "player", "SnDamage");
    RegisterHam(Ham_Killed, "player", "client_death", 0);
    RegisterHam(Ham_Spawn, "player", "@spawn", 1);

    bStrike = cstrike_running()
    g_suicide = engfunc(EngFunc_PrecacheEvent, 1, "events/displacer.sc")
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        bIsAdmin[id] = get_user_flags(id) &ADMIN_RESERVATION ? true : false
    }
}

@spawn(id)
{
    if(is_user_connected(id) && ~CheckPlayerBit(g_AI, id))
    {
        remove_task(id)
        attach_view(id,id)
    }

    new ineed_clean = find_ent_by_tname(charsmin, "temp_ent")
    if(ineed_clean)
        remove_entity(ineed_clean)
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
    g_specter =  precache_model("models/player/ghost.mdl")
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
    new loguser[80], name[MAX_NAME_LENGTH]

    read_logargv(0, loguser, charsmax(loguser))
    parse_loguser(loguser, name, charsmax(name))

    return get_user_index(name);
}

public SnDamage(victim)
{
    new alive, hp;
    if(is_user_connected(victim))
    {
        hp = get_user_health(victim)
        alive = is_user_alive(victim)

        if(alive)
        {
            if(hp < 35.0)
            {
                switch(random(2))
                {
                    case 0: emit_sound(victim, CHAN_AUTO, SOUND_DRAMA1, VOL_NORM, ATTN_IDLE, 0, PITCH);
                    case 1: emit_sound(victim, CHAN_AUTO, SOUND_FART, VOL_NORM, ATTN_IDLE, 0, PITCH);
                }
            }
        }
    }
}

public client_death_event(victim)
{
    #define HLW_KNIFE           0x0019
    #define HLW_CROWBAR         1
    new killer;
    if(is_user_connected(victim))
    {
        killer = get_user_attacker(victim)
        if(is_user_connected(killer))
        if(!bStrike && get_user_weapon(killer) != HLW_KNIFE|HLW_CROWBAR)

        if(CheckPlayerBit(g_AI, victim))
        {
            switch(random_num(0,3))
            {
                case 0: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH1, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 1: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH2, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 2: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH3, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 3: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH4, VOL_NORM, ATTN_IDLE, 0, PITCH);
            }
        }
        else
        {
            if(!bStrike)
            switch(random_num(0,2))
            {
                case 0: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE1, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 1: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE2, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 2: emit_sound(victim, CHAN_AUTO, SOUND_DRAMA2, 3.0, ATTN_IDLE, 0, PITCH);
            }
        }
        port(victim, killer);
    }
}

public client_death(victim, killer)
{
    #define HLW_KNIFE           0x0019
    #define HLW_CROWBAR         1

    if(is_user_connected(killer) && is_user_connected(victim))
    {
        if(!bStrike && get_user_weapon(killer) != HLW_KNIFE|HLW_CROWBAR)

        if(CheckPlayerBit(g_AI, victim))
        {
            switch(random_num(0,3))
            {
                case 0: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH1, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 1: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH2, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 2: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH3, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 3: emit_sound(victim, CHAN_AUTO, SOUND_BOTDEATH4, VOL_NORM, ATTN_IDLE, 0, PITCH);
            }
        }
        else
        {
            if(!bStrike)
            switch(random_num(0,2))
            {
                case 0: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE1, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 1: emit_sound(victim, CHAN_AUTO, SOUND_HUMANDIE2, VOL_NORM, ATTN_IDLE, 0, PITCH);
                case 2: emit_sound(victim, CHAN_AUTO, SOUND_DRAMA2, 3.0, ATTN_IDLE, 0, PITCH);
            }
        }
        port(victim, killer);
    }
}


public port(victim, killer)
{
    if(is_user_connected(victim) && is_user_connected(killer) /*&& ~CheckPlayerBit(g_AI, killer)*/)
    {
        static Float:fOrigin[3], Float:fVelo[3];
        pev(victim,pev_origin,fOrigin);

        pev(victim, pev_velocity, fVelo)

        new model = CheckPlayerBit(g_AI, victim) ? G_FielD : g_specter
        if(bIsAdmin[victim])
        {
            emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0 )
            ewrite_byte( TE_FIREFIELD );
            ewrite_coord_f( fOrigin[0] );
            ewrite_coord_f( fOrigin[1] );
            ewrite_coord_f( fOrigin[2] );
            ewrite_short( 300 );            ///(radius)
            ewrite_short( CheckPlayerBit(g_AI, victim) ? G_FielD : g_specter);
            ewrite_byte( 1 );              ///(count)
            ewrite_byte( 5 );
            ewrite_byte( 50 );
            emessage_end();
        }
        else
        {
            if(~CheckPlayerBit(g_AI, victim))
            {
                model_sniffer(victim, killer)
                new attacker[3]
                num_to_str(killer, attacker, charsmax(attacker))
                set_task(0.1, "@fake_think", victim, attacker, charsmax(attacker), "b")

                //emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, killer )
                emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0 )
                ewrite_byte(TE_PROJECTILE)
                ewrite_coord_f(fOrigin[0])
                ewrite_coord_f(fOrigin[1])
                ewrite_coord_f(fOrigin[2]+150.0)

                ewrite_coord_f(fVelo[0])
                ewrite_coord_f(fVelo[1])
                ewrite_coord_f(fVelo[2] + 50.0)

                ewrite_short(model)

                ewrite_byte(500) //life
                ewrite_byte(0)  //owner
                emessage_end()
            }
            /*
            new ent = create_entity(ent_type)
            DispatchKeyValue( ent, "model", "models/skeleton.mdl" )
            DispatchKeyValue( ent, "rendercolor", "0 0 0" )
            DispatchKeyValue( ent, "targetname", "temp_ent" )
            DispatchKeyValue( ent, "angles", "0 270 0" )
            DispatchKeyValue( ent, "speed", "150" )
            DispatchKeyValue( ent, "spawnflags", "97" )
            DispatchSpawn(ent);
            fOrigin[2] += 60.0
            set_pev(ent, pev_origin, fOrigin)
            */
            else
            {
                emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0 )
                ewrite_byte(TE_EXPLODEMODEL);
                ewrite_coord_f(fOrigin[0]+random_float(-11.0,11.0));
                ewrite_coord_f(fOrigin[1]-random_float(-11.0,11.0));
                ewrite_coord_f(fOrigin[2]+random_float(1.0,75.0));
                ewrite_coord(random_num(-150,1000));  //vel
                ewrite_short(model);
                ewrite_short(1);
                ewrite_byte(random_num(50,100)); //size
                emessage_end();
            }
        }
    }
}

@fake_think(attacker[3], victim)
{
    new killer = str_to_num(attacker)
    if(is_user_connected(killer) && is_user_connected(victim))
    {
        attach_view(victim,killer)
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id) && is_user_bot(id))
    {
        SetPlayerBit(g_AI, id)
    }
}

public client_disconnected(id)
    ClearPlayerBit(g_AI, id)

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
        static Float:iOrigin[3];
        pev(victim,pev_origin,iOrigin);

        new Float:fDelay = 1.5
        new iAngles[3], Float:fParam1, Float:fParam2, iParam1, iParam2

        engfunc(EngFunc_PlaybackEvent, (FEV_CLIENT|FEV_GLOBAL|FEV_SERVER|FEV_NOTHOST|FEV_UPDATE), victim, g_suicide, fDelay, Float:iOrigin, iAngles, fParam1, fParam2, iParam1, iParam2, 0, 0);

        emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0);
        ewrite_byte(TE_FIREFIELD);
        ewrite_coord_f(iOrigin[0]);
        ewrite_coord_f(iOrigin[1]);
        ewrite_coord_f(iOrigin[2]);
        ewrite_short(0);
        ewrite_short(g_Drama);
        ewrite_byte(1);
        ewrite_byte(28);
        ewrite_byte(30);
        emessage_end();

        emessage_begin(MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0);
        ewrite_byte(random_num(19,21));
        ewrite_coord_f(iOrigin[0]);
        ewrite_coord_f(iOrigin[1]);
        ewrite_coord_f(iOrigin[2]);
        ewrite_coord_f(iOrigin[0]);
        ewrite_coord_f(iOrigin[1]);
        ewrite_coord_f(iOrigin[2]+1000);
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
