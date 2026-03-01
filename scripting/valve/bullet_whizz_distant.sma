#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>

#define HLW_GRAPPLE         16
#define HLW_357             17
#define HLW_PIPEWRENCH      18
#define HLW_KNIFE           25
#define HLW_DISPLACER       20
#define HLW_SHOCKROACH      22
#define HLW_SPORE           23
#define HLW_SNIPER          25
#define HLW_PENGUIN         26


#define PITCH (random_num (20,160))

//Credits to:
//  Cheap_Suit              = The one who made the Bullet Whiz, which this mod was inspired from
//  ConnorMcLeod            = Using his optimized code as a reference
//  Hellmonja               = Sharing the general idea on how detection works
//    Agent                 = Distant shot
//    SPiNX                 = HL/OF port optimize

static  PLUGIN[]            = "Distant Gunshot";
static  AUTHOR[]            = "SPiNX";
static VERSION[]            = "1.4.6";
static     URL[]            = "http://github.com/djearthquake/amxx";

//static g_snap, g_whiz, g_thud;
static g_impretty

static const tracer_model[]= "sprites/dot.spr"

static g_snap[3], g_whiz[3], g_thud[1];
static const g_WhizSounds[][] =
{
    "misc/whizz1.wav",
    "misc/whizz2.wav",
    "misc/whizz3.wav",
    "misc/whizz4.wav"
}

static const g_SnapSounds[][] =
{
    "misc/snap1.wav",
    "misc/snap2.wav",
    "misc/snap3.wav",
    "misc/snap4.wav"
}

//Note: This exist just in-case you wanted to append more or remove less audios
static const g_ThudSounds[][] =
{
    "misc/thud.wav"
}

new g_LastWeapon[MAX_PLAYERS + 1];
new g_LastAmmo[MAX_PLAYERS + 1];

new gs_enabled, gs_measure, gs_whizdist, gs_snapdist, gs_thuddist;
static bool: b_CS
static bool: b_HL
static bool: b_OF
static bool: b_Bot[MAX_PLAYERS+1]

public plugin_init()
{
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
    gs_enabled  = register_cvar("gs_enabled",   "2");       //This checks if the plugin and which parts are enabled or disabled.
    gs_measure  = register_cvar("gs_measure",   "0");       //Measure distance between you & shooter (outputs in chat) <--Enable this if you want to change Whiz/Snap/Thud distance
    gs_whizdist = register_cvar("gs_whizdist",  "400");     //Hear Whiz sounds at 400 meters and beyond
    gs_snapdist = register_cvar("gs_snapdist",  "1000");    //Hear Snap sounds between 1000 to 2000 meters
    gs_thuddist = register_cvar("gs_thuddist",  "2000");    //Hear Thud sounds beyond 2000 meteers

    static SzModName[MAX_NAME_LENGTH]
    get_modname(SzModName, charsmax(SzModName));
    if(equal(SzModName, "cstrike"))
        b_CS = true
    else if (equal(SzModName, "valve"))
        b_HL = true
    else if (equal(SzModName, "gearbox"))
        b_OF = true
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        b_Bot[id] = is_user_bot(id) ? true : false;
    }
}

public plugin_precache()
{
    #if AMXX_VERSION_NUM == 182
    register_plugin(PLUGIN, VERSION, AUTHOR)
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL)
    #endif
    register_cvar("bullwhiz_version", URL, FCVAR_SERVER);

    g_impretty = precache_model(tracer_model)
    static SzFormat[128]
    for (new list = 0; list < sizeof(g_WhizSounds); ++list)
    {
        formatex(SzFormat,charsmax(SzFormat),"sound/%s", g_WhizSounds[list])
        if(file_exists(SzFormat))
        {
            for (new can = 0; can < sizeof(g_whiz); ++can)
            {
                {
                    g_whiz[can] = precache_sound(g_WhizSounds[list])
                }
            }
        }
        else
        {
            log_amx("Paused to prevent crash from missing %s.", SzFormat)
            pause "a";
        }
    }
    for (new list = 0; list < sizeof(g_SnapSounds); ++list)
    {
        format(SzFormat,charsmax(SzFormat),"sound/%s", g_SnapSounds[list])
        
        if(file_exists(SzFormat))
        {
            for (new spam = 0; spam < sizeof(g_snap); ++spam)
            {
                g_snap[spam] = precache_sound(g_SnapSounds[list])
            }
        }
        else
        {
            log_amx("Paused to prevent crash from missing %s.", SzFormat)
            pause "a";
        }
    }
    for (new list = 0; list < sizeof(g_ThudSounds); ++list)
    {
        format(SzFormat,charsmax(SzFormat),"sound/%s", g_ThudSounds[list])
        if(file_exists(SzFormat))
        {
            for (new dam = 0; dam < sizeof(g_thud); ++dam)
            {
                g_thud[dam] = precache_sound(g_ThudSounds[list])
            }
        }
        else
        {
            log_amx("Paused to prevent crash from missing %s.", SzFormat)
            pause "a"
        }
    }
}

public Event_CurWeapon(id)
{
    static iCvar; iCvar = get_pcvar_num(gs_enabled)
    if(iCvar)
    {
        if(is_user_connected(id))
        {
            static WeaponID; WeaponID = read_data(2);

            if(b_CS)
            {
                switch(WeaponID)
                {
                    case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE, CSW_C4, CSW_KNIFE: return;
                }
            }
            else if(b_HL)
            {
                switch(WeaponID)
                {
                    case HLW_CROWBAR, HLW_CROSSBOW, HLW_EGON, HLW_HANDGRENADE, HLW_TRIPMINE,  HLW_SATCHEL, HLW_SNARK: return;
                }
            }
            else if(b_OF)
            {
                switch(WeaponID)
                {
                    case HLW_CROWBAR, HLW_CROSSBOW, HLW_EGON, HLW_HANDGRENADE, HLW_TRIPMINE,  HLW_SATCHEL, HLW_SNARK, HLW_GRAPPLE, HLW_PIPEWRENCH, HLW_KNIFE, HLW_DISPLACER, HLW_SHOCKROACH, HLW_SPORE, HLW_PENGUIN: return;
                }
            }

            static Clip;Clip = read_data(3);

            if (g_LastWeapon[id] == WeaponID && g_LastAmmo[id] > Clip)
            {
                new iMeasure = get_pcvar_num(gs_measure);
                new Players[MAX_PLAYERS];
                static iNum, Float:origin[3], Float:targetOrigin[3], temp[3], Float:fAim[3], target, Float:flAngle, Float:origDist;

                pev(id, pev_origin, origin);
                get_user_origin(id, temp, 3);
                IVecFVec(temp, fAim);
                get_players(Players, iNum, "a");

                for (--iNum; iNum >= 0; iNum--)
                {
                    target = Players[iNum];
                    if(!b_Bot[target] && id !=target)
                    {
                        pev(target, pev_origin, targetOrigin);

                        flAngle     = get_distance_to_line_f(origin, targetOrigin, fAim);
                        origDist    = get_distance_f(origin, targetOrigin);

                        if(iMeasure)
                        {
                            if(is_user_admin(target))
                            {
                                client_print(target, print_center, "%n's %f Meters away", id, origDist);
                                if(iMeasure>1)
                                {
                                    @make_pretty(target, id)
                                }
                            }
                        }

                        if (origDist >= get_pcvar_float(gs_whizdist) && flAngle > 0.0 && fm_is_ent_visible(id, target))
                        {
                            iCvar > 1 ? @MakeSound(target, g_whiz[random(sizeof(g_whiz))]):
                            emit_sound(target, CHAN_AUTO, g_WhizSounds[random(sizeof(g_WhizSounds))], VOL_NORM, ATTN_IDLE, 0, PITCH);
                        }

                        if (origDist < get_pcvar_float(gs_snapdist))
                        {
                            continue;
                        }
                        if (origDist >= get_pcvar_float(gs_snapdist) && flAngle > 0.0)
                        {
                            iCvar > 1 ? @MakeSound(target, g_snap[random(sizeof(g_snap))]):
                            emit_sound(target, CHAN_AUTO, g_SnapSounds[random(sizeof(g_SnapSounds))], VOL_NORM, ATTN_IDLE, 0, PITCH);
                            continue;
                        }
                        if (origDist >= get_pcvar_float(gs_thuddist))
                        {
                            iCvar > 1 ? @MakeSound(target, g_thud[random(sizeof(g_thud))]):
                            emit_sound(target, CHAN_AUTO, g_ThudSounds[random(sizeof(g_ThudSounds))], VOL_NORM, ATTN_IDLE, 0, PITCH);
                            //emit_sound(target, CHAN_AUTO, SOUND_THUD, VOL_NORM, ATTN_NORM, 0, PITCH); //pitch is not working with this wav but others it does
                            continue;
                        }
                    }
                }
            }
            g_LastWeapon[id] = WeaponID;
            g_LastAmmo[id] = Clip;
        }
    }
}


@make_pretty(target, id)
{
    static Float:Origin[3]
    pev(target, pev_origin, Origin);
    
    static iCvar; iCvar = get_pcvar_num(gs_enabled);
    emessage_begin_f( iCvar > 2 ? MSG_ONE : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Float:{ 0.0, 0.0, 0.0 }, target)
    ewrite_byte(TE_BEAMENTPOINT)
    ewrite_short(id)
    ewrite_coord_f(Origin[0])
    ewrite_coord_f(Origin[1])
    ewrite_coord_f(Origin[2])
    ewrite_short(g_impretty)
    ewrite_byte(16) //starting frame
    ewrite_byte(30) //frame rate in 0.1's)
    ewrite_byte(random_num(1,11))//life in 0.1's)
    ewrite_byte(random_num(50,100))//line width in 0.1's)
    ewrite_byte(random(256))//noise amplitude in 0.01's)
    ewrite_byte(156) //red)
    ewrite_byte(random(256))//green)
    ewrite_byte(1)//blue)
    ewrite_byte(1000)//brightness)
    ewrite_byte(random(100))//scroll speed in 0.1's)
    emessage_end;
}


Float:get_distance_to_line_f(Float:pos_start[3], Float:pos_end[3], Float:pos_object[3])
{
    static Float:vec_start_end[3], Float:vec_start_object[3], Float:vec_end_object[3], Float:vec_end_start[3];
    xs_vec_sub(pos_end, pos_start, vec_start_end);          // vector from start to end
    xs_vec_sub(pos_object, pos_start, vec_start_object);    // vector from end to object
    xs_vec_sub(pos_start, pos_end, vec_end_start);          // vector from end to start
    xs_vec_sub(pos_end, pos_object, vec_end_object);        // vector object to end

    static Float:len_start_object; len_start_object = vector_length(vec_start_object);
    static Float:angle_start; angle_start = floatacos(xs_vec_dot(vec_start_end, vec_start_object) / (vector_length(vec_start_end) * len_start_object), degrees);
    static Float:angle_end;angle_end = floatacos(xs_vec_dot(vec_end_start, vec_end_object) / (vector_length(vec_end_start) * vector_length(vec_end_object)), degrees);

    if (angle_start <= 105.0 && angle_end <= 105.0)
    {
        return len_start_object * floatsin(angle_start, degrees);
    }
    return -1.0;
}

bool:fm_is_ent_visible(index, entity)
{
    static Float:origin[3], Float:view_ofs[3], Float:eyespos[3];
    pev(index, pev_origin, origin);
    pev(index, pev_view_ofs, view_ofs);
    xs_vec_add(origin, view_ofs, eyespos);

    static Float:entpos[3];
    pev(entity, pev_origin, entpos);
    engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index);

    switch (pev(entity, pev_solid))
    {
        case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity;
    }

    new Float:fraction;
    global_get(glb_trace_fraction, fraction);

    if (fraction == 1.0)
    {
        return true;
    }
    return false;
}

@MakeSound(player, iSound)
{
    static iCvar; iCvar = get_pcvar_num(gs_enabled)
    static Float:fOrigin[3];
    new iAttn=random(256)*64, iVol = random_num(150, 255)*255
    if(is_user_alive(player))
    {
        pev(player, pev_origin, fOrigin);

        emessage_begin_f( iCvar > 2 ? MSG_ALL : MSG_BROADCAST, SVC_SPAWNSTATICSOUND, Float:{ 0.0, 0.0, 0.0 }, player = 0)

        ewrite_coord_f(fOrigin[0])
        ewrite_coord_f(fOrigin[1])
        ewrite_coord_f(fOrigin[2])

        ewrite_short(iSound)
        ewrite_byte(iVol) //vol cant be 0
        ewrite_byte(iAttn) //attn 0 worked
        ewrite_short(player)
        ewrite_byte(iVol) //pitch //theres no pitch. cant be 0
        ewrite_byte(CHAN_STREAM) //chan or flags
        emessage_end;

    }

}
