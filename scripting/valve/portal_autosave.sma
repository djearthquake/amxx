/* AMX Portal
* (c) Copyright 2005, Kleenex
* Updated by SPINX
* Added Map Save/Load System & Precache Failsafe
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <engine>

#define MAX_PORTALS 20
#define MAX_TARGETS 20
#define MAX_ALLROUNDS 20
#define MAX_BLACKHOLES 28

#define ADMIN_FLAG ADMIN_LEVEL_A

new mapPortals[MAX_PORTALS]
new mapTargets[MAX_TARGETS]
new mapAllrounds[MAX_ALLROUNDS]
new mapBlackholes[MAX_BLACKHOLES]

new numPortals
new numTargets
new numAllrounds
new numBlackholes

new portal_model[64] = "sprites/e-tele1.spr"
new target_model[64] = "sprites/b-tele1.spr"
new allround_model[64] = "sprites/exit1.spr"
new blackhole_model[64] = "models/blackhole.mdl"

new g_config_dir[128]
new bool:g_bPluginEnabled = true

public plugin_precache()
{
    // Verify models before precaching to prevent fatal server crashes
    if (!check_asset(portal_model, true) ||
        !check_asset(target_model, true) ||
        !check_asset(allround_model, true) ||
        !check_asset(blackhole_model, true) ||
        !check_asset("sound/debris/beamstart1.wav", false) ||
        !check_asset("sound/debris/beamstart7.wav", false))
    {
        server_print("[AMX Portal] CRITICAL: One or more assets missing! Plugin paused to prevent crash.")
        g_bPluginEnabled = false
        pause("a")
        return
    }

    precache_model(portal_model)
    precache_model(target_model)
    precache_model(allround_model)
    precache_model(blackhole_model)
    
    precache_sound("debris/beamstart1.wav")
    precache_sound("debris/beamstart7.wav")
}

bool:check_asset(const szFile[], bool:bIsModel)
{
    new szValveFile[128]
    formatex(szValveFile, charsmax(szValveFile), "../valve/%s", szFile)

    // Check current mod dir (gearbox) OR fall back to base valve dir
    if (file_exists(szFile) || file_exists(szValveFile))
    {
        return true
    }

    server_print("[AMX Portal] ERROR: Missing %s: %s", bIsModel ? "model" : "sound", szFile)
    return false
}

public plugin_init()
{
    register_plugin("AMX Portal", "1.7", "KleeneX | SPINX")
    
    if (!g_bPluginEnabled) return

    // Creation commands
    register_clcmd("amx_portal", "cmd_create_portal", ADMIN_FLAG, ": Create a Portal")
    register_clcmd("amx_ptarget", "cmd_create_target", ADMIN_FLAG, ": Create a Portal Target")
    register_clcmd("amx_aportal", "cmd_create_allround", ADMIN_FLAG, ": Create an Allround")
    register_clcmd("amx_blackhole", "cmd_create_blackhole", ADMIN_FLAG, ": Create a Blackhole")
    
    // Removal commands
    register_clcmd("amx_r_portal", "remove_portal", ADMIN_FLAG, ": Remove all Portals")
    register_clcmd("amx_r_ptarget", "remove_target", ADMIN_FLAG, ": Remove all Targets")
    register_clcmd("amx_r_aportal", "remove_allround", ADMIN_FLAG, ": Remove all Allrounds")
    register_clcmd("amx_r_blackhole", "remove_blackhole", ADMIN_FLAG, ": Remove all Blackholes")
    
    // Save/Menu commands
    register_clcmd("amx_save_portals", "cmd_save_portals", ADMIN_FLAG, ": Save Portal Config for Map")
    register_clcmd("amx_portalmenu", "cmdPortalMenu", ADMIN_FLAG, ": Open the Portal Menu")
    
    register_menucmd(register_menuid("Portal Menu:"), 1023, "actionPortalMenu")
}

public plugin_cfg()
{
    if (!g_bPluginEnabled) return

    get_configsdir(g_config_dir, charsmax(g_config_dir))
    format(g_config_dir, charsmax(g_config_dir), "%s/portals", g_config_dir)
    
    if (!dir_exists(g_config_dir))
    {
        mkdir(g_config_dir)
    }
    
    load_portals()
}

public plugin_end()
{
    if (g_bPluginEnabled)
    {
        save_portals()
    }
}

// ==========================================
// CREATION FUNCTIONS
// ==========================================

public cmd_create_portal(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    if (numPortals >= MAX_PORTALS)
    {
        console_print(id, "[Portal] Too many portals.")
        return PLUGIN_HANDLED
    }
    
    new Origin[3], Float:pOrigin[3]
    get_user_origin(id, Origin)
    IVecFVec(Origin, pOrigin)
    pOrigin[2] += 10.0
    
    spawn_portal(pOrigin)
    return PLUGIN_HANDLED
}

public spawn_portal(Float:pOrigin[3])
{
    if (!g_bPluginEnabled || numPortals >= MAX_PORTALS) return 0

    new portal = create_entity("info_target")
    if (!is_valid_ent(portal)) return 0

    entity_set_string(portal, EV_SZ_classname, "amx_portal")
    entity_set_model(portal, portal_model)
    entity_set_int(portal, EV_INT_flags, FL_ALWAYSTHINK)
    set_rendering(portal, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
    
    new Float:MinBox[3] = {-16.0, -16.0, 0.0}
    new Float:MaxBox[3] = {16.0, 16.0, 16.0}
    entity_set_vector(portal, EV_VEC_mins, MinBox)
    entity_set_vector(portal, EV_VEC_maxs, MaxBox)
    entity_set_int(portal, EV_INT_solid, SOLID_TRIGGER)
    entity_set_origin(portal, pOrigin)

    mapPortals[numPortals] = portal
    numPortals++
    return portal
}

public cmd_create_target(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    if (numTargets >= MAX_TARGETS)
    {
        console_print(id, "[Portal] Too many targets.")
        return PLUGIN_HANDLED
    }
    
    new Origin[3], Float:pOrigin[3]
    get_user_origin(id, Origin)
    IVecFVec(Origin, pOrigin)
    pOrigin[2] += 10.0
    
    spawn_target(pOrigin)
    return PLUGIN_HANDLED
}

public spawn_target(Float:pOrigin[3])
{
    if (!g_bPluginEnabled || numTargets >= MAX_TARGETS) return 0

    new target = create_entity("info_target")
    if (!is_valid_ent(target)) return 0

    entity_set_string(target, EV_SZ_classname, "amx_ptarget")
    entity_set_model(target, target_model)
    entity_set_int(target, EV_INT_flags, FL_ALWAYSTHINK)
    set_rendering(target, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
    entity_set_origin(target, pOrigin)

    mapTargets[numTargets] = target
    numTargets++
    return target
}

public cmd_create_allround(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    if (numAllrounds >= MAX_ALLROUNDS)
    {
        console_print(id, "[Portal] Too many allrounds.")
        return PLUGIN_HANDLED
    }
    
    new Origin[3], Float:pOrigin[3]
    get_user_origin(id, Origin)
    IVecFVec(Origin, pOrigin)
    pOrigin[2] += 10.0
    
    spawn_allround(pOrigin)
    return PLUGIN_HANDLED
}

public spawn_allround(Float:pOrigin[3])
{
    if (!g_bPluginEnabled || numAllrounds >= MAX_ALLROUNDS) return 0

    new allround = create_entity("info_target")
    if (!is_valid_ent(allround)) return 0

    entity_set_string(allround, EV_SZ_classname, "amx_aportal")
    entity_set_model(allround, allround_model)
    entity_set_int(allround, EV_INT_flags, FL_ALWAYSTHINK)
    set_rendering(allround, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
    
    new Float:MinBox[3] = {-16.0, -16.0, 0.0}
    new Float:MaxBox[3] = {16.0, 16.0, 16.0}
    entity_set_vector(allround, EV_VEC_mins, MinBox)
    entity_set_vector(allround, EV_VEC_maxs, MaxBox)
    entity_set_int(allround, EV_INT_solid, SOLID_TRIGGER)
    entity_set_origin(allround, pOrigin)

    mapAllrounds[numAllrounds] = allround
    numAllrounds++
    return allround
}

public cmd_create_blackhole(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    if (numBlackholes >= MAX_BLACKHOLES)
    {
        console_print(id, "[Portal] Too many blackholes.")
        return PLUGIN_HANDLED
    }
    
    new Float:vOrigin[3], Float:vTraceDirection[3], Float:vTraceEnd[3], Float:vTraceResult[3], Float:vNormal[3]
    entity_get_vector(id, EV_VEC_origin, vOrigin)
    
    VelocityByAim(id, 64, vTraceDirection)
    vTraceEnd[0] = vTraceDirection[0] + vOrigin[0]
    vTraceEnd[1] = vTraceDirection[1] + vOrigin[1]
    vTraceEnd[2] = vTraceDirection[2] + vOrigin[2]
    
    trace_line(id, vOrigin, vTraceEnd, vTraceResult)
    
    if (trace_normal(id, vOrigin, vTraceEnd, vNormal) == 0)
    {
        console_print(id, "[Portal] You must create a blackhole on a wall!")
        return PLUGIN_HANDLED
    }
    
    new Float:vNewOrigin[3], Float:vEntAngles[3]
    vNewOrigin[0] = vTraceResult[0] + (vNormal[0] * 10.0)
    vNewOrigin[1] = vTraceResult[1] + (vNormal[1] * 10.0)
    vNewOrigin[2] = vTraceResult[2] + (vNormal[2] * 10.0)
    
    vector_to_angle(vNormal, vEntAngles)
    spawn_blackhole(vNewOrigin, vEntAngles)
    
    return PLUGIN_HANDLED
}

public spawn_blackhole(Float:vOrigin[3], Float:vAngles[3])
{
    if (!g_bPluginEnabled || numBlackholes >= MAX_BLACKHOLES) return 0

    new blackhole = create_entity("info_target")
    if (!is_valid_ent(blackhole)) return 0

    entity_set_string(blackhole, EV_SZ_classname, "amx_blackhole")
    entity_set_model(blackhole, blackhole_model)
    entity_set_size(blackhole, Float:{-40.0, -30.0, -40.0}, Float:{40.0, 30.0, 40.0})
    entity_set_int(blackhole, EV_INT_solid, SOLID_TRIGGER)
    entity_set_int(blackhole, EV_INT_flags, FL_ALWAYSTHINK)
    entity_set_origin(blackhole, vOrigin)
    entity_set_vector(blackhole, EV_VEC_angles, vAngles)

    mapBlackholes[numBlackholes] = blackhole
    numBlackholes++
    return blackhole
}

// ==========================================
// REMOVAL FUNCTIONS
// ==========================================

public remove_portal(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    for (new a = 0; a < numPortals; a++)
    {
        if (is_valid_ent(mapPortals[a])) remove_entity(mapPortals[a])
    }
    numPortals = 0
    return PLUGIN_HANDLED
}

public remove_target(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    for (new a = 0; a < numTargets; a++)
    {
        if (is_valid_ent(mapTargets[a])) remove_entity(mapTargets[a])
    }
    numTargets = 0
    return PLUGIN_HANDLED
}

public remove_allround(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    for (new a = 0; a < numAllrounds; a++)
    {
        if (is_valid_ent(mapAllrounds[a])) remove_entity(mapAllrounds[a])
    }
    numAllrounds = 0
    return PLUGIN_HANDLED
}

public remove_blackhole(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    for (new a = 0; a < numBlackholes; a++)
    {
        if (is_valid_ent(mapBlackholes[a])) remove_entity(mapBlackholes[a])
    }
    numBlackholes = 0
    return PLUGIN_HANDLED
}

// ==========================================
// FRAME THINK & TOUCH LOGIC
// ==========================================

public server_frame()
{
    if (!g_bPluginEnabled) return

    for (new a = 0; a < numPortals; ++a)
    {
        if (is_valid_ent(mapPortals[a]))
        {
            new Float:frame = entity_get_float(mapPortals[a], EV_FL_frame)
            if (frame < 0.0 || frame > 25.0) entity_set_float(mapPortals[a], EV_FL_frame, 0.0)
            else entity_set_float(mapPortals[a], EV_FL_frame, frame + 0.5)
        }
    }
    for (new a = 0; a < numTargets; ++a)
    {
        if (is_valid_ent(mapTargets[a]))
        {
            new Float:frame = entity_get_float(mapTargets[a], EV_FL_frame)
            if (frame < 0.0 || frame > 25.0) entity_set_float(mapTargets[a], EV_FL_frame, 0.0)
            else entity_set_float(mapTargets[a], EV_FL_frame, frame + 0.5)
        }
    }
    for (new a = 0; a < numAllrounds; ++a)
    {
        if (is_valid_ent(mapAllrounds[a]))
        {
            new Float:frame = entity_get_float(mapAllrounds[a], EV_FL_frame)
            if (frame < 0.0 || frame > 25.0) entity_set_float(mapAllrounds[a], EV_FL_frame, 0.0)
            else entity_set_float(mapAllrounds[a], EV_FL_frame, frame + 0.5)
        }
    }
    for (new a = 0; a < numBlackholes; ++a)
    {
        if (is_valid_ent(mapBlackholes[a]))
        {
            new Float:frame = entity_get_float(mapBlackholes[a], EV_FL_frame)
            if (frame < 195.0 || frame > 255.0) entity_set_float(mapBlackholes[a], EV_FL_frame, 195.0)
            else entity_set_float(mapBlackholes[a], EV_FL_frame, frame + 1.5)
        }
    }
}

public pfn_touch(ptr, ptd)
{
    if (!g_bPluginEnabled) return PLUGIN_CONTINUE

    if (ptr > 0 && ptd > 0)
    {
        new Portal[64]
        entity_get_string(ptr, EV_SZ_classname, Portal, charsmax(Portal))

        if (equal(Portal, "amx_portal"))
        {
            if (numTargets == 0) return PLUGIN_HANDLED
            
            new random_target, Origin[3], Float:eOrigin[3], Float:velocity[3]
            random_target = mapTargets[random_num(0, numTargets - 1)]
            entity_get_vector(random_target, EV_VEC_origin, eOrigin)
            FVecIVec(eOrigin, Origin)
            Origin[0] += 80
            Origin[1] += 80
            Origin[2] += 10
            
            emit_sound(ptr, CHAN_WEAPON, "debris/beamstart1.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)
            if (is_user_alive(ptd))
            {
                entity_get_vector(ptd, EV_VEC_velocity, velocity)
                set_user_origin(ptd, Origin)
                velocity[2] = random_float(200.0, 225.0)
                entity_set_vector(ptd, EV_VEC_velocity, velocity)
                emit_sound(random_target, CHAN_WEAPON, "debris/beamstart7.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)
            }
        }
        else if (equal(Portal, "amx_aportal"))
        {
            if (numAllrounds <= 1) return PLUGIN_HANDLED
            
            new random_target, Origin[3], Float:eOrigin[3], Float:velocity[3]
            random_target = mapAllrounds[random_num(0, numAllrounds - 1)]
            
            if (random_target != ptr)
            {
                entity_get_vector(random_target, EV_VEC_origin, eOrigin)
                FVecIVec(eOrigin, Origin)
                Origin[0] += 80
                Origin[1] += 80
                Origin[2] += 10
                
                emit_sound(ptr, CHAN_WEAPON, "debris/beamstart1.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)
                if (is_user_alive(ptd))
                {
                    entity_get_vector(ptd, EV_VEC_velocity, velocity)
                    set_user_origin(ptd, Origin)
                    velocity[2] = random_float(200.0, 225.0)
                    entity_set_vector(ptd, EV_VEC_velocity, velocity)
                    emit_sound(random_target, CHAN_WEAPON, "debris/beamstart7.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)
                }
            }
        }
        else if (equal(Portal, "amx_blackhole"))
        {
            if (numBlackholes <= 1) return PLUGIN_HANDLED
            
            new random_target, Float:eOrigin[3], Float:vEntAngles[3], Float:velocity[3]
            random_target = mapBlackholes[random_num(0, numBlackholes - 1)]
            
            if (random_target != ptr)
            {
                entity_get_vector(random_target, EV_VEC_origin, eOrigin)
                entity_get_vector(random_target, EV_VEC_angles, vEntAngles)
                
                if (vEntAngles[0] < 181.0) eOrigin[2] += 50.0
                else if (vEntAngles[0] < 361.0) eOrigin[2] -= 50.0

                if (vEntAngles[1] == 0.0) eOrigin[0] += 80.0
                else if (vEntAngles[1] < 91.0) eOrigin[1] += 80.0
                else if (vEntAngles[1] < 181.0) eOrigin[0] -= 80.0
                else if (vEntAngles[1] < 271.0) eOrigin[1] -= 80.0

                emit_sound(ptr, CHAN_WEAPON, "debris/beamstart1.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)
                entity_set_vector(ptd, EV_VEC_origin, eOrigin)
                emit_sound(random_target, CHAN_WEAPON, "debris/beamstart7.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)

                entity_get_vector(ptd, EV_VEC_velocity, velocity)
                if (vEntAngles[0] < 361.0 && vEntAngles[0] > 180.0)
                    velocity[2] = random_float(-200.0, -225.0)
                else
                    velocity[2] = random_float(200.0, 225.0)

                entity_set_vector(ptd, EV_VEC_velocity, velocity)
            }
        }
    }
    return PLUGIN_CONTINUE
}

// ==========================================
// FILE I/O (SAVE / LOAD)
// ==========================================

public cmd_save_portals(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    
    save_portals()
    console_print(id, "[Portal] Configurations saved for current map.")
    return PLUGIN_HANDLED
}

public save_portals()
{
    new mapname[32], filepath[160]
    get_mapname(mapname, charsmax(mapname))
    formatex(filepath, charsmax(filepath), "%s/%s.cfg", g_config_dir, mapname)

    if (file_exists(filepath)) delete_file(filepath)

    new f = fopen(filepath, "at")
    if (!f) return

    new Float:origin[3], Float:angles[3], line[128]

    // Save Portals (Type 1)
    for (new i = 0; i < numPortals; i++)
    {
        if (is_valid_ent(mapPortals[i]))
        {
            entity_get_vector(mapPortals[i], EV_VEC_origin, origin)
            formatex(line, charsmax(line), "1 %.1f %.1f %.1f 0.0 0.0 0.0^n", origin[0], origin[1], origin[2])
            fputs(f, line)
        }
    }

    // Save Targets (Type 2)
    for (new i = 0; i < numTargets; i++)
    {
        if (is_valid_ent(mapTargets[i]))
        {
            entity_get_vector(mapTargets[i], EV_VEC_origin, origin)
            formatex(line, charsmax(line), "2 %.1f %.1f %.1f 0.0 0.0 0.0^n", origin[0], origin[1], origin[2])
            fputs(f, line)
        }
    }

    // Save Allrounds (Type 3)
    for (new i = 0; i < numAllrounds; i++)
    {
        if (is_valid_ent(mapAllrounds[i]))
        {
            entity_get_vector(mapAllrounds[i], EV_VEC_origin, origin)
            formatex(line, charsmax(line), "3 %.1f %.1f %.1f 0.0 0.0 0.0^n", origin[0], origin[1], origin[2])
            fputs(f, line)
        }
    }

    // Save Blackholes (Type 4)
    for (new i = 0; i < numBlackholes; i++)
    {
        if (is_valid_ent(mapBlackholes[i]))
        {
            entity_get_vector(mapBlackholes[i], EV_VEC_origin, origin)
            entity_get_vector(mapBlackholes[i], EV_VEC_angles, angles)
            formatex(line, charsmax(line), "4 %.1f %.1f %.1f %.1f %.1f %.1f^n", origin[0], origin[1], origin[2], angles[0], angles[1], angles[2])
            fputs(f, line)
        }
    }

    fclose(f)
}

public load_portals()
{
    new mapname[32], filepath[160]
    get_mapname(mapname, charsmax(mapname))
    formatex(filepath, charsmax(filepath), "%s/%s.cfg", g_config_dir, mapname)

    if (!file_exists(filepath)) return

    new f = fopen(filepath, "rt")
    if (!f) return

    new line[128], type_str[4], sX[16], sY[16], sZ[16], sA1[16], sA2[16], sA3[16]
    new Float:origin[3], Float:angles[3], type

    while (!feof(f))
    {
        fgets(f, line, charsmax(line))
        trim(line)

        if (!line[0] || line[0] == ';') continue

        parse(line, type_str, charsmax(type_str), sX, charsmax(sX), sY, charsmax(sY), sZ, charsmax(sZ), sA1, charsmax(sA1), sA2, charsmax(sA2), sA3, charsmax(sA3))

        type = str_to_num(type_str)
        origin[0] = str_to_float(sX)
        origin[1] = str_to_float(sY)
        origin[2] = str_to_float(sZ)
        angles[0] = str_to_float(sA1)
        angles[1] = str_to_float(sA2)
        angles[2] = str_to_float(sA3)

        switch (type)
        {
            case 1: spawn_portal(origin)
            case 2: spawn_target(origin)
            case 3: spawn_allround(origin)
            case 4: spawn_blackhole(origin, angles)
        }
    }

    fclose(f)
}

// ==========================================
// MENU SYSTEM
// ==========================================

public cmdPortalMenu(id, level, cid)
{
    if (!g_bPluginEnabled || !cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
    displayPortalMenu(id)
    return PLUGIN_HANDLED
}

public displayPortalMenu(id)
{
    new MenuBody[512], keys
    new nLen = format(MenuBody, charsmax(MenuBody), "\yPortal Menu:\w^n^n")

    if (numPortals >= MAX_PORTALS) nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "1. Create Portal \r(Limit reached)\w^n")
    else nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "1. Create Portal^n")

    if (numTargets >= MAX_TARGETS) nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "2. Create Target \r(Limit reached)\w^n")
    else nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "2. Create Target^n")

    if (numAllrounds >= MAX_ALLROUNDS) nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "3. Create Allround \r(Limit reached)\w^n")
    else nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "3. Create Allround^n")

    if (numBlackholes >= MAX_BLACKHOLES) nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "4. Create Blackhole \r(Limit reached)\w^n^n")
    else nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "4. Create Blackhole^n^n")

    nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "5. Remove Portals^n")
    nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "6. Remove Targets^n")
    nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "7. Remove Allrounds^n")
    nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "8. Remove Blackholes^n^n")
    nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "9. Save Config^n")
    nLen += format(MenuBody[nLen], charsmax(MenuBody)-nLen, "0. Exit")

    keys = (1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<<8 | 1<<9)
    show_menu(id, keys, MenuBody, -1)
    return PLUGIN_CONTINUE
}

public actionPortalMenu(id, key)
{
    new cid, level
    switch(key)
    {
        case 0: cmd_create_portal(id, level, cid)
        case 1: cmd_create_target(id, level, cid)
        case 2: cmd_create_allround(id, level, cid)
        case 3: cmd_create_blackhole(id, level, cid)
        case 4: remove_portal(id, level, cid)
        case 5: remove_target(id, level, cid)
        case 6: remove_allround(id, level, cid)
        case 7: remove_blackhole(id, level, cid)
        case 8: cmd_save_portals(id, level, cid)
    }

    if (key != 9) displayPortalMenu(id)
    return PLUGIN_HANDLED
}

