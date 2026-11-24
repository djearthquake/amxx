#include <amxmodx>
#include <engine>
#include <fakemeta>

#define TASK_BREATH 1001
#define SEND_MSG_ALLPLAYERS 0

#define VERTICAL_MARCH_STEP 5.0       // Height step increment for outdoor sky checks
#define VECTOR_PUSH_DISTANCE 36.0     // Total units to advance breath origin horizontally (12.0 * 3)
#define VECTOR_SPRAY_VELOCITY 36.0    // Total scaling velocity multiplier for fallback mode

static const SPRITE_IDEAL[] = "sprites/gas_puff_01.spr";
static const SPRITE_FALLBACK[] = "sprites/steam1.spr";

new g_face, g_pant, g_breath;
new bool:g_fallback_mode = false;

new bool:g_bIsConnected[MAX_PLAYERS + 1];
new g_iTotalPlayers = 0;

#if !defined MaxClients
new g_iMaxPlayers;
#define MaxClients g_iMaxPlayers
#endif

public plugin_init()
{
    register_plugin("Winter breath", "1.0", "SPiNX|2026");

    g_face = register_cvar("chin_level", "60");  // Chin level tested on OP4
    g_pant = register_cvar("winter_breath", "1.5");

    #if defined g_iMaxPlayers
    g_iMaxPlayers = get_maxplayers();
    #endif
}

public plugin_precache()
{
    if (file_exists(SPRITE_IDEAL))
    {
        g_breath = precache_model(SPRITE_IDEAL);
        g_fallback_mode = false;
    }
    else
    {
        log_amx("[Winter Breath] Custom sprite not found! Activating fallback mode.");
        g_breath = precache_model(SPRITE_FALLBACK);
        g_fallback_mode = true;
    }
}

public client_putinserver(id)
{
    if (is_user_bot(id) || is_user_hltv(id))
        return;

    if (!g_bIsConnected[id])
    {
        g_bIsConnected[id] = true;
        g_iTotalPlayers++;

        if (g_iTotalPlayers && !task_exists(TASK_BREATH))
        {
            set_task(1.0, "global_breath_loop", TASK_BREATH);
        }
    }
}

public client_disconnected(id)
{
    if (is_user_bot(id) || is_user_hltv(id))
        return;

    if (g_bIsConnected[id])
    {
        g_bIsConnected[id] = false;
        
        if (g_iTotalPlayers > 0)
            g_iTotalPlayers--;

        if (g_iTotalPlayers == 0)
        {
            remove_task(TASK_BREATH);
        }
    }
}

public global_breath_loop()
{
    if (g_iTotalPlayers <= 0)
    {
        remove_task(TASK_BREATH);
        return;
    }

    new Float:delay = get_pcvar_float(g_pant);
    if (delay <= 0.0)
    {
        set_task(2.0, "global_breath_loop", TASK_BREATH);
        return;
    }

    new iChinLevel = get_pcvar_num(g_face);
    static Float:vOrigin[3], Float:vForward[3], Float:vSpawn[3], Float:vVelocity[3];

    for (new id = 1; id <= MaxClients; id++)
    {
        if (!g_bIsConnected[id])
            continue;

        if (!is_user_alive(id) || (pev(id, pev_flags) & FL_SPECTATOR))
            continue;

        if (pev(id, pev_waterlevel) >= 3)
            continue;

        if (!is_user_outside(id))
            continue;

        pev(id, pev_origin, vOrigin);
        velocity_by_aim(id, 1, vForward);

        vSpawn[0] = vOrigin[0] + (vForward[0] * VECTOR_PUSH_DISTANCE);
        vSpawn[1] = vOrigin[1] + (vForward[1] * VECTOR_PUSH_DISTANCE);
        vSpawn[2] = vOrigin[2] + float(iChinLevel) + (vForward[2] * VECTOR_PUSH_DISTANCE);

        if (g_fallback_mode)
        {
            vVelocity[0] = vForward[0] * VECTOR_SPRAY_VELOCITY;
            vVelocity[1] = vForward[1] * VECTOR_SPRAY_VELOCITY;
            vVelocity[2] = vForward[2] * VECTOR_SPRAY_VELOCITY;

            emessage_begin(MSG_PVS, SVC_TEMPENTITY, _, SEND_MSG_ALLPLAYERS);
            ewrite_byte(TE_SPRAY);
            ewrite_coord(floatround(vSpawn[0]));
            ewrite_coord(floatround(vSpawn[1]));
            ewrite_coord(floatround(vSpawn[2]));
            ewrite_coord(floatround(vVelocity[0]));
            ewrite_coord(floatround(vVelocity[1]));
            ewrite_coord(floatround(vVelocity[2]));
            ewrite_short(g_breath);
            ewrite_byte(3);   // Count
            ewrite_byte(6);   // Speed
            ewrite_byte(4);   // Noise
            ewrite_byte(0);   // Render mode
            emessage_end();
        }
        else
        {
            emessage_begin(MSG_PVS, SVC_TEMPENTITY, _, SEND_MSG_ALLPLAYERS);
            ewrite_byte(TE_FIREFIELD);
            ewrite_coord(floatround(vSpawn[0]));
            ewrite_coord(floatround(vSpawn[1]));
            ewrite_coord(floatround(vSpawn[2]));
            ewrite_short(2);  // Radius variation
            ewrite_short(g_breath);
            ewrite_byte(2);  // Count
            ewrite_byte(TEFIRE_FLAG_ALPHA); 
            ewrite_byte(10); // Duration
            emessage_end();
        }
    }

    set_task(delay, "global_breath_loop", TASK_BREATH);
}

stock bool:is_user_outside(id)
{
    static Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);

    while (engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_EMPTY)
    {
        vOrigin[2] += VERTICAL_MARCH_STEP;
    }

    if (engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
    {
        return true;
    }

    return false;
}
