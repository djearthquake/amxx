#include amxmodx
#include fakemeta

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define PLUGIN "Rain, random"
#define VERSION "0.2"
#define AUTHOR "SPiNX"

#define MAX_NAME_LENGTH            32
#define MAX_PLAYERS                         32


new Float:g_fNextStep[MAX_PLAYERS + 1];

new bool:b_Is_raining, g_cvar_sky

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define MAX_SOUNDS 4
new const g_szStepSound[MAX_SOUNDS][] =
{
    "player/pl_slosh1.wav",
    "player/pl_slosh2.wav",
    "player/pl_slosh3.wav",
    "player/pl_slosh4.wav"
};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    if(b_Is_raining)
        register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink", 0);
}

public plugin_precache()
{
    register_cvar("rain_version", VERSION, FCVAR_SERVER);
    g_cvar_sky = register_cvar("sv_rain_sky", "de_storm")
    new iChance = get_systime()
    new iRandom_chance = random(iChance)

    if(iRandom_chance > iChance/2)
    {
        fm_create_entity("env_rain")
        new SzCloudySky[MAX_NAME_LENGTH]
        get_pcvar_string(g_cvar_sky, SzCloudySky, charsmax(SzCloudySky))
        set_cvar_string("sv_skyname", SzCloudySky);
        b_Is_raining = true

        for(new i = 0; i < MAX_SOUNDS ; i++)
            precache_sound(g_szStepSound[i]);

        const OFFSET_AMBIENCE = (1<<0);
        precache_sound("ambience/rain.wav");
        new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "ambient_generic"));
        set_pev(entity, pev_health, 10.0);
        set_pev(entity, pev_message,"ambience/rain.wav");
        set_pev(entity, pev_spawnflags, OFFSET_AMBIENCE);
        dllfunc(DLLFunc_Spawn, entity);
    }

}
public plugin_cfg()
if(b_Is_raining)
{
    server_print"       _"
    server_print"     _( )_          _      " //Keith R. Fulton | keith.fulton@chinalake.navy.mil
    server_print"   _(     )_      _( )_"
    server_print"  (_________)   _(     )_"
    server_print"    \  \  \    (_________)"
    server_print"      \  \       \  \  \"
    server_print"                   \  \"
}
public OnAutoConfigsBuffered()
    server_print(b_Is_raining ? "It's going to be a bit sloshy out today." : "No rain forecasted!") 

public fwd_PlayerPreThink(id)
{
    new Float:STEP_DELAY
    if(b_Is_raining)
    {
        if(!is_user_alive(id))
            return FMRES_IGNORED;

        if(!is_user_outside(id))
            return FMRES_IGNORED;

        set_pev(id, pev_flTimeStepSound, 999);

        new Float:fSpeed = fm_get_ent_speed(id)
        /*3 steps fast slow or none*/

        if(fSpeed < 150.0 && fSpeed > 50.0) //lurk
            STEP_DELAY = 1.0

        else if(fSpeed > 75.0 &&fSpeed <= 150.0  ) //march
            STEP_DELAY = 0.5

        else if (fSpeed >= 150.0 ) //run
            STEP_DELAY = 0.33

        else if (fSpeed < 20.0) //stealth
            set_task(0.5,"@stop_snd", id)

        new Button = pev(id,pev_button),OldButton = pev(id,pev_oldbuttons);

        //stop buzzing sound at crawl
        if(Button & IN_FORWARD && (OldButton & IN_FORWARD && fSpeed < 50.0 ))
            return FMRES_IGNORED;
        if(g_fNextStep[id] < get_gametime() || Button & IN_JUMP && (OldButton & IN_FORWARD) && pev(id, pev_flags) & FL_ONGROUND)
        {
            static Float:EMIT_VOLUME = 0.45
            if(fm_get_ent_speed(id) && (pev(id, pev_flags) & FL_ONGROUND) && is_user_outside(id))
                emit_sound(id, CHAN_BODY, g_szStepSound[random(MAX_SOUNDS)], EMIT_VOLUME, ATTN_STATIC, 0, PITCH_NORM);

            g_fNextStep[id] =get_gametime() + STEP_DELAY
        }

    }
    return FMRES_IGNORED;
}

@stop_snd(id)
if(!fm_get_ent_speed(id))
    emit_sound(id, CHAN_BODY, g_szStepSound[random(MAX_SOUNDS)], VOL_NORM, ATTN_STATIC, SND_STOP, PITCH_NORM)

stock Float:fm_get_ent_speed(id)
{
    if(!pev_valid(id))
        return 0.0;

    static Float:vVelocity[3];
    pev(id, pev_velocity, vVelocity);

    vVelocity[2] = 0.0;

    return vector_length(vVelocity);
}

stock Float:is_user_outside(id)
{
    new Float:vOrigin[3], Float:fDist;
    pev(id, pev_origin, vOrigin);
    fDist = vOrigin[2];

    while(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_EMPTY)
        vOrigin[2] += 5.0;

    if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
        return (vOrigin[2] - fDist);
    return 0.0;
}
