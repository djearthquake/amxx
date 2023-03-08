#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>

#define HLW_GRAPPLE         16
#define HLW_357             17
#define HLW_PIPEWRENCH      18
#define HLW_KNIFE           0x0019
#define HLW_DISPLACER       20
#define HLW_SHOCKROACH      22
#define HLW_SPORE           23
#define HLW_SNIPER          25
#define HLW_PENGUIN         26

//Credits to:
//  Cheap_Suit      = The one who made the Bullet Whiz, which this mod was inspired from
//  ConnorMcLeod    = Using his optimized code as a reference
//  Hellmonja       = Sharing the general idea on how detection works
//    Agent             = Distant shot
//    SPiNX             = HL/OF port optimize

new PLUGIN_NAME[]       = "Distant Gunshot";
new PLUGIN_AUTHOR[]     = "SPiNX";
new PLUGIN_VERSION[]    = "1.4.4";


new g_WhizSounds[][] =
{
    "misc/whizz1.wav",
    "misc/whizz2.wav",
    "misc/whizz3.wav",
    "misc/whizz4.wav"
}

new g_SnapSounds[][] =
{
    "misc/snap1.wav",
    "misc/snap2.wav",
    "misc/snap3.wav",
    "misc/snap4.wav"
}

new g_ThudSounds[][] =
{
    "misc/thud.wav"
}

new g_LastWeapon[MAX_PLAYERS + 1];
new g_LastAmmo[MAX_PLAYERS + 1];

new gs_enabled, gs_measure, gs_whizdist, gs_snapdist, gs_thuddist;
new bool: b_CS
new bool: b_HL
new bool: b_OF
new bool: b_Bot[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
    gs_enabled  = register_cvar("gs_enabled",   "1");       //This checks if the plugin is enabled or disabled
    gs_measure  = register_cvar("gs_measure",   "0");       //Measure distance between you & shooter (outputs in chat) <--Enable this if you want to change Whiz/Snap/Thud distance
    gs_whizdist = register_cvar("gs_whizdist",  "400");     //Hear Whiz sounds at 400 meters and beyond
    gs_snapdist = register_cvar("gs_snapdist",  "1000");    //Hear Snap sounds between 1000 to 2000 meters
    gs_thuddist = register_cvar("gs_thuddist",  "2000");    //Hear Thud sounds beyond 2000 meteers

    new SzModName[MAX_NAME_LENGTH]
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
        b_Bot[id] = is_user_bot(id) ? true : false
    }
}

public plugin_precache()
{
    //Note: This exist just in-case you wanted to append more or remove less audios
    new SzFormat[128]
    for (new i = 0; i < sizeof(g_WhizSounds); ++i)
    {
        formatex(SzFormat,charsmax(SzFormat),"sound/%s", g_WhizSounds[i])
        if(file_exists(SzFormat))
        {
            precache_sound(g_WhizSounds[i])
        }
        else
        {
            log_amx("Paused to prevent crash from missing %s.", SzFormat)
            pause "a";
        }
    }
    for (new i = 0; i < sizeof(g_SnapSounds); ++i)
    {
        format(SzFormat,charsmax(SzFormat),"sound/%s", g_SnapSounds[i])
        if(file_exists(SzFormat))
        {
            precache_sound(g_SnapSounds[i])
        }
        else
        {
            log_amx("Paused to prevent crash from missing %s.", SzFormat)
            pause "a";
        }
    }
    for (new i = 0; i < sizeof(g_ThudSounds); ++i)
    {
        format(SzFormat,charsmax(SzFormat),"sound/%s", g_ThudSounds[i])
        if(file_exists(SzFormat))
        {
            precache_sound(g_ThudSounds[i])
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
    if(get_pcvar_num(gs_enabled) || is_user_connected(id))
    {
        if(is_user_connecting(id))
            return

        new WeaponID = read_data(2);

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

        new Clip = read_data(3);

        if (g_LastWeapon[id] == WeaponID && g_LastAmmo[id] > Clip)
        {
            new Players[32], iNum, Float:origin[3], Float:targetOrigin[3], temp[3], Float:fAim[3], target, Float:flAngle, Float:origDist;

            pev(id, pev_origin, origin);
            get_user_origin(id, temp, 3);
            IVecFVec(temp, fAim);
            get_players(Players, iNum, "a");

            for (--iNum; iNum >= 0; iNum--)
            {
                target = Players[iNum];

                if (id == target && !b_Bot[target])
                {
                    continue;
                }

                pev(target, pev_origin, targetOrigin);

                flAngle     = get_distance_to_line_f(origin, targetOrigin, fAim);
                origDist    = get_distance_f(origin, targetOrigin);

                if (get_pcvar_float(gs_measure))
                {
                    client_print(target, print_chat, "Distance (You & Shooter): %f Meters", origDist);
                }

                if (origDist >= get_pcvar_float(gs_whizdist) && flAngle > 0.0 && fm_is_ent_visible(id, target))
                {
                    client_cmd(target, "spk %s", g_WhizSounds[random(sizeof(g_WhizSounds))]);
                }

                if (origDist < get_pcvar_float(gs_snapdist))
                {
                    continue;
                }

                if (origDist >= get_pcvar_float(gs_snapdist) && flAngle > 0.0)
                {
                    client_cmd(target, "spk %s", g_SnapSounds[random(sizeof(g_SnapSounds))]);
                    continue;
                }

                if (origDist >= get_pcvar_float(gs_thuddist))
                {
                    client_cmd(target, "spk %s", g_ThudSounds[random(sizeof(g_ThudSounds))]);
                    continue;
                }
            }
        }
        g_LastWeapon[id] = WeaponID;
        g_LastAmmo[id] = Clip;
    }
}

Float:get_distance_to_line_f(Float:pos_start[3], Float:pos_end[3], Float:pos_object[3])
{
    new Float:vec_start_end[3], Float:vec_start_object[3], Float:vec_end_object[3], Float:vec_end_start[3];
    xs_vec_sub(pos_end, pos_start, vec_start_end);          // vector from start to end
    xs_vec_sub(pos_object, pos_start, vec_start_object);    // vector from end to object
    xs_vec_sub(pos_start, pos_end, vec_end_start);          // vector from end to start
    xs_vec_sub(pos_end, pos_object, vec_end_object);        // vector object to end

    new Float:len_start_object = vector_length(vec_start_object);
    new Float:angle_start = floatacos(xs_vec_dot(vec_start_end, vec_start_object) / (vector_length(vec_start_end) * len_start_object), degrees);
    new Float:angle_end = floatacos(xs_vec_dot(vec_end_start, vec_end_object) / (vector_length(vec_end_start) * vector_length(vec_end_object)), degrees);

    if (angle_start <= 105.0 && angle_end <= 105.0)
    {
        return len_start_object * floatsin(angle_start, degrees);
    }
    return -1.0;
}

bool:fm_is_ent_visible(index, entity)
{
    new Float:origin[3], Float:view_ofs[3], Float:eyespos[3];
    pev(index, pev_origin, origin);
    pev(index, pev_view_ofs, view_ofs);
    xs_vec_add(origin, view_ofs, eyespos);

    new Float:entpos[3];
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
