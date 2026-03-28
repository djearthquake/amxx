#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define MAX_STR_LEN 64
#define MAX_SPAWNS 64

new const g_szPowerup_sounds[][] =
{
    "items/ammopickup1.wav",
    "ctf/itemthrow.wav",
    "ctf/pow_armor_charge.wav",
    "ctf/pow_backpack.wav",
    "ctf/pow_health_charge.wav",
    "turret/tu_ping.wav"
}

new const g_szValidClasses[][] = 
{
    "item_ctflongjump",
    "item_ctfregeneration",
    "item_ctfaccelerator",
    "item_ctfportablehev"
}

new g_szSpawnClasses[MAX_SPAWNS][MAX_STR_LEN]
new Float:g_fSpawnOrigins[MAX_SPAWNS][3]
new g_iTotalSpawns = 0

public plugin_precache()
{
    precache_model("models/w_accelerator.mdl")
    precache_model("models/w_jumppack.mdl")
    precache_model("models/w_backpack.mdl")
    precache_model("models/w_porthev.mdl")
    precache_model("models/w_health.mdl")

    for (new i = 0; i < sizeof g_szPowerup_sounds; i++)
    {
        precache_sound(g_szPowerup_sounds[i])
    }
}

public plugin_init()
{
    register_plugin("OpFor Powerup Saver", "1.0", "SPiNX")

    register_clcmd("say !powerups", "cmdSpawnMenu", ADMIN_BAN)
    register_concmd("amx_powerup_menu", "cmdSpawnMenu", ADMIN_BAN)

    register_forward(FM_SetPhysicsKeyValue, "Hook_SetPhysicsKeyValue_Post", 1)

    set_task(1.5, "LoadMapSpawns")
}

public Hook_SetPhysicsKeyValue_Post(id, const key[], const value[])
{
    if (!is_user_connected(id))
    {
        return FMRES_IGNORED
    }

    if (equal(key, "jpj"))
    {
        engfunc(EngFunc_SetPhysicsKeyValue, id, "slj", value)
    }

    return FMRES_IGNORED
}

public cmdSpawnMenu(id)
{
    if (!is_user_admin(id))
    {
        return PLUGIN_HANDLED
    }

    new menu = menu_create("\yPowerup Manager:", "main_handler")

    menu_additem(menu, "Spawn Jump Pack", "item_ctflongjump")
    menu_additem(menu, "Spawn Backpack (Regen)", "item_ctfregeneration")
    menu_additem(menu, "Spawn Accelerator", "item_ctfaccelerator")
    menu_additem(menu, "Spawn Portable HEV", "item_ctfportablehev")
    
    menu_additem(menu, " ", "none") 

    menu_additem(menu, "\r--- SAVE ALL TO MAP ---", "save")
    menu_additem(menu, "\y--- DELETE NEAREST ---", "delete")
    menu_additem(menu, "\w--- DELETE ALL (MAP) ---", "clear")

    menu_display(id, menu, 0)
    return PLUGIN_HANDLED
}

public main_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new szClass[MAX_STR_LEN], szDummy[MAX_STR_LEN], iUnused
    menu_item_getinfo(menu, item, iUnused, szClass, charsmax(szClass), szDummy, charsmax(szDummy), iUnused)

    if (equal(szClass, "save"))
    {
        SaveMapSpawns(id)
    }
    else if (equal(szClass, "clear"))
    {
        DeleteAll(id)
    }
    else if (equal(szClass, "delete"))
    {
        DeleteNearest(id)
    }
    else if (szClass[0] && !equal(szClass, "none"))
    {
        CreatePowerup(id, szClass)
    }

    menu_destroy(menu)
    cmdSpawnMenu(id)
    
    return PLUGIN_HANDLED
}

public CreatePowerup(id, const szClass[])
{
    if (g_iTotalSpawns >= MAX_SPAWNS)
    {
        client_print(id, print_chat, "* Limit reached (%d).", MAX_SPAWNS)
        return
    }

    new ent = create_entity(szClass)
    if (!is_valid_ent(ent))
    {
        return
    }

    new iOrigin[3], Float:fOrigin[3]
    get_user_origin(id, iOrigin, 3)
    IVecFVec(iOrigin, fOrigin)
    fOrigin[2] += 20.0

    entity_set_origin(ent, fOrigin)
    DispatchSpawn(ent)
    emit_sound(ent, CHAN_ITEM, g_szPowerup_sounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)

    copy(g_szSpawnClasses[g_iTotalSpawns], MAX_STR_LEN - 1, szClass)
    g_fSpawnOrigins[g_iTotalSpawns][0] = fOrigin[0]
    g_fSpawnOrigins[g_iTotalSpawns][1] = fOrigin[1]
    g_fSpawnOrigins[g_iTotalSpawns][2] = fOrigin[2]
    g_iTotalSpawns++
    
    client_print(id, print_chat, "* Added %s to session.", szClass)
}

public DeleteNearest(id)
{
    if (g_iTotalSpawns == 0)
    {
        return
    }

    new Float:fPlayerOrigin[3], Float:fEntOrigin[3], Float:fDist, Float:fMinDist = 999999.0
    new iTargetEnt = -1, iTargetIdx = -1
    entity_get_vector(id, EV_VEC_origin, fPlayerOrigin)

    for (new i = 0; i < g_iTotalSpawns; i++)
    {
        fDist = get_distance_f(fPlayerOrigin, g_fSpawnOrigins[i])
        if (fDist < fMinDist)
        {
            fMinDist = fDist
            iTargetIdx = i
        }
    }

    if (iTargetIdx != -1)
    {
        for (new c = 0; c < sizeof g_szValidClasses; c++)
        {
            new ent = -1
            while ((ent = find_ent_by_class(ent, g_szValidClasses[c])) != 0)
            {
                entity_get_vector(ent, EV_VEC_origin, fEntOrigin)
                if (get_distance_f(fEntOrigin, g_fSpawnOrigins[iTargetIdx]) < 50.0)
                {
                    iTargetEnt = ent
                    break
                }
            }
            if (is_valid_ent(iTargetEnt)) break
        }

        if (is_valid_ent(iTargetEnt))
        {
            remove_entity(iTargetEnt)
        }

        for (new j = iTargetIdx; j < g_iTotalSpawns - 1; j++)
        {
            copy(g_szSpawnClasses[j], MAX_STR_LEN - 1, g_szSpawnClasses[j + 1])
            g_fSpawnOrigins[j][0] = g_fSpawnOrigins[j + 1][0]
            g_fSpawnOrigins[j][1] = g_fSpawnOrigins[j + 1][1]
            g_fSpawnOrigins[j][2] = g_fSpawnOrigins[j + 1][2]
        }
        g_iTotalSpawns--
        client_print(id, print_chat, "* Deleted nearest powerup.")
    }
}

public DeleteAll(id)
{
    for (new c = 0; c < sizeof g_szValidClasses; c++)
    {
        new ent = -1
        while ((ent = find_ent_by_class(ent, g_szValidClasses[c])) != 0)
        {
            remove_entity(ent)
        }
    }

    new szPath[128], szMap[32]
    get_mapname(szMap, charsmax(szMap))
    get_configsdir(szPath, charsmax(szPath))
    format(szPath, charsmax(szPath), "%s/powerup_spawns/%s.ini", szPath, szMap)
    
    if (file_exists(szPath))
    {
        delete_file(szPath)
    }

    g_iTotalSpawns = 0
    client_print(id, print_chat, "* ALL spawns deleted and file wiped.")
}

public SaveMapSpawns(id)
{
    new szPath[128], szMap[32]
    get_mapname(szMap, charsmax(szMap))
    get_configsdir(szPath, charsmax(szPath))
    format(szPath, charsmax(szPath), "%s/powerup_spawns", szPath)
    if (!dir_exists(szPath))
    {
        mkdir(szPath)
    }

    format(szPath, charsmax(szPath), "%s/%s.ini", szPath, szMap)
    new f = fopen(szPath, "wt")
    if (!f)
    {
        return
    }

    for (new i = 0; i < g_iTotalSpawns; i++)
    {
        fprintf(f, "^"%s^" %f %f %f^n", g_szSpawnClasses[i], g_fSpawnOrigins[i][0], g_fSpawnOrigins[i][1], g_fSpawnOrigins[i][2])
    }
    fclose(f)
    
    client_cmd(id, "spk turret/tu_ping.wav")
    client_print(id, print_chat, "* %d spawns saved.", g_iTotalSpawns)
}

public LoadMapSpawns()
{
    new szPath[128], szMap[32], szLine[128]
    get_mapname(szMap, charsmax(szMap))
    get_configsdir(szPath, charsmax(szPath))
    format(szPath, charsmax(szPath), "%s/powerup_spawns/%s.ini", szPath, szMap)
    if (!file_exists(szPath))
    {
        return
    }
    
    new f = fopen(szPath, "rt")
    if (!f)
    {
        return
    }

    while (!feof(f) && g_iTotalSpawns < MAX_SPAWNS)
    {
        fgets(f, szLine, charsmax(szLine))
        trim(szLine)
        if (!szLine[0] || szLine[0] == ';' || szLine[0] == '#')
        {
            continue
        }
        
        new szX[16], szY[16], szZ[16]
        parse(szLine, g_szSpawnClasses[g_iTotalSpawns], MAX_STR_LEN - 1, szX, charsmax(szX), szY, charsmax(szY), szZ, charsmax(szZ))
        g_fSpawnOrigins[g_iTotalSpawns][0] = str_to_float(szX)
        g_fSpawnOrigins[g_iTotalSpawns][1] = str_to_float(szY)
        g_fSpawnOrigins[g_iTotalSpawns][2] = str_to_float(szZ)
        
        new ent = create_entity(g_szSpawnClasses[g_iTotalSpawns])
        if (is_valid_ent(ent))
        {
            entity_set_origin(ent, g_fSpawnOrigins[g_iTotalSpawns])
            DispatchSpawn(ent)
        }
        g_iTotalSpawns++
    }
    fclose(f)
}
