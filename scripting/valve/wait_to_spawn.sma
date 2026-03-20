#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#define PLUGIN "!OpFor Reincarnation: Genesis Global"
#define VERSION "50.4.8"
#define AUTHOR "SPiNX"

#define TASK_VOID 7023
#define TASK_RAINBOW 2024
#define TASK_PROTECTION 3025
#define TASK_RESPAWN_PAD 4026

new bool:IsBot[MAX_PLAYERS + 1];
new g_pSpawnDelay, g_pForceRespawn, g_msgScreenFade, g_msgScreenShake;
new g_iPlayerTimer[MAX_PLAYERS + 1], bool:g_bWaiting[MAX_PLAYERS + 1], bool:g_bReadyToSpawn[MAX_PLAYERS + 1];
new Float:g_fLastSpawnTime[MAX_PLAYERS + 1], bool:g_bProtected[MAX_PLAYERS + 1], g_iProtTimer[MAX_PLAYERS + 1];
new g_sModelLaser, g_pLmsStatus;

new const SFX_LOOP[] = "ambience/industrial2.wav";
new const SFX_SPAWN[] = "ambience/steamburst1.wav";

new const g_iRainbow[7][3] =
{
    {148, 0, 211}, {75, 0, 130}, {0, 0, 255},
    {0, 255, 0}, {255, 255, 0}, {255, 127, 0}, {255, 0, 0}
};

public plugin_precache()
{
    precache_sound(SFX_LOOP);
    precache_sound(SFX_SPAWN);
    g_sModelLaser = precache_model("sprites/laserbeam.spr");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    g_pSpawnDelay = register_cvar("amx_spawn_delay", "10");
    g_pForceRespawn = get_cvar_pointer("mp_forcerespawn");
    g_msgScreenFade = get_user_msgid("ScreenFade");
    g_msgScreenShake = get_user_msgid("ScreenShake");

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1);
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Pre", 0);
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre", 0);
    register_forward(FM_CmdStart, "fw_CmdStart");

    g_pLmsStatus = get_xvar_id("g_bLmsActive");
}

public client_putinserver(id)
{
    IsBot[id] = is_user_bot(id) ? true : false;
    reset_player_vars(id);
}

public client_disconnected(id)
{
    reset_player_vars(id);
}

public fw_CmdStart(id, uc_handle, seed)
{
    if(!is_user_connected(id)) return FMRES_IGNORED;

    new iButtons = get_uc(uc_handle, UC_Buttons);
    new iOldButtons = pev(id, pev_oldbuttons);

    // FIXED: Only trigger if a NEW key is pressed (prevents instant-spawn while holding W/S)
    if(g_bReadyToSpawn[id] && (iButtons & ~iOldButtons))
    {
        g_bReadyToSpawn[id] = false;
        set_task(0.1, "task_ExecuteRespawn", id + TASK_RESPAWN_PAD);
        return FMRES_HANDLED;
    }

    if(is_user_alive(id) && g_bProtected[id])
    {
        if(iButtons & (IN_ATTACK | IN_ATTACK2))
        {
            client_print(id, print_chat, "* Aura Dissipated: Aggression Detected.");
            remove_protection(id);
        }
    }
    return FMRES_IGNORED;
}

public fw_PlayerSpawn_Pre(id)
{
    if(g_pLmsStatus != -1 && get_xvar_num(g_pLmsStatus) == 1) return HAM_IGNORED;

    // FIXED: Strictly block engine-forced spawns if the reincarnation process is active
    if(g_bWaiting[id] || g_bReadyToSpawn[id])
    {
        return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

public fw_PlayerKilled(id, attacker, shouldgib)
{
    if(!is_user_connected(id)) return;

    if(g_pLmsStatus != -1 && get_xvar_num(g_pLmsStatus) == 1)
    {
        reset_player_vars(id);
        return;
    }

    reset_player_vars(id);

    static Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2] + 800.0);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2]);
    write_short(g_sModelLaser);
    write_byte(0); write_byte(0); write_byte(20); write_byte(80); write_byte(50);
    write_byte(255); write_byte(255); write_byte(255); write_byte(255); write_byte(0);
    message_end();

    set_task(0.5, "start_void_sequence", id);
}

public start_void_sequence(id)
{
    if(!is_user_connected(id)) return;
    g_bWaiting[id] = true;
    g_iPlayerTimer[id] = get_pcvar_num(g_pSpawnDelay);
    set_task(1.0, "task_countdown", id + TASK_VOID, _, _, "b");
}

public task_countdown(taskid)
{
    new id = taskid - TASK_VOID;
    if(!is_user_connected(id))
    {
        remove_task(taskid);
        return;
    }

    new iMax = get_pcvar_num(g_pSpawnDelay);smiles@ns2:~/Steam/steamapps/c

    if(g_iPlayerTimer[id] > 0)
    {
        if(!IsBot[id])
        {
            if(g_iPlayerTimer[id] > (iMax / 2))
            {
                UTIL_ScreenFade(id, 0, 0, 0, 255, 1.1, 1.1, 0x0004);
                set_hudmessage(255, 255, 255, -1.0, 0.4, 0, 0.0, 1.1, 0.1, 0.1, 4);
                show_hudmessage(id, "[ VOID REINCARNATION: %d ]", g_iPlayerTimer[id]);
            }
            else
            {
                new iIdx = clamp((g_iPlayerTimer[id] * 6) / iMax, 0, 6);
                UTIL_ScreenFade(id, g_iRainbow[iIdx][0], g_iRainbow[iIdx][1], g_iRainbow[iIdx][2], 200, 1.1, 1.1, 0x0004);
                set_hudmessage(g_iRainbow[iIdx][0], g_iRainbow[iIdx][1], g_iRainbow[iIdx][2], -1.0, 0.4, 0, 0.0, 1.1, 0.1, 0.1, 4);
                show_hudmessage(id, "[ AWAKENING SPIRIT: %d ]", g_iPlayerTimer[id]);

                if(g_iPlayerTimer[id] <= 2 && !task_exists(id + TASK_RAINBOW))
                    set_task(0.1, "task_rapid_rainbow", id + TASK_RAINBOW, _, _, "a", 20);
            }
            client_cmd(id, "spk %s", SFX_LOOP);
        }
        g_iPlayerTimer[id]--;
    }
    else
    {
        remove_task(taskid);
        g_bWaiting[id] = false;
        client_cmd(id, "stopsound");

        // FIXED: Explicitly follow mp_forcerespawn CVAR
        if(get_pcvar_num(g_pForceRespawn) >= 1)
        {
            set_task(0.1, "task_ExecuteRespawn", id + TASK_RESPAWN_PAD);
        }
        else
        {
            g_bReadyToSpawn[id] = true;
            client_print(id, print_center, "[ REBIRTH READY ]^nPRESS ANY KEY TO AWAKEN");
        }
    }
}

public task_rapid_rainbow(taskid)
{
    new id = taskid - TASK_RAINBOW;
    if(!is_user_connected(id)) return;

    static iTick[MAX_PLAYERS + 1];
    new iIdx = ++iTick[id] % 7;
    UTIL_ScreenFade(id, g_iRainbow[iIdx][0], g_iRainbow[iIdx][1], g_iRainbow[iIdx][2], 190, 0.1, 0.0, 0x0000);
}

public task_ExecuteRespawn(taskid)
{
    new id = taskid - TASK_RESPAWN_PAD;
    if(!is_user_connected(id)) return;

    g_bWaiting[id] = false;
    g_bReadyToSpawn[id] = false;
    g_fLastSpawnTime[id] = get_gametime();

    client_cmd(id, "spk %s", SFX_SPAWN);

    // Safety: Put player in respawnable state before triggering DLL spawn
    set_pev(id, pev_deadflag, DEAD_RESPAWNABLE);
    dllfunc(DLLFunc_Spawn, id);

    apply_protection(id);

    if(!IsBot[id])
    {
        UTIL_ScreenFade(id, 255, 255, 255, 255, 0.5, 0.1, 0x0000);
        UTIL_ScreenShake(id, 15.0, 5.0);
    }
}

public apply_protection(id)
{
    g_bProtected[id] = true;
    g_iProtTimer[id] = 5;
    set_pev(id, pev_renderfx, kRenderFxGlowShell);
    set_pev(id, pev_rendercolor, Float:{255.0, 255.0, 255.0});
    set_pev(id, pev_rendermode, kRenderTransAlpha);
    set_pev(id, pev_renderamt, 180.0);
    remove_task(id + TASK_PROTECTION);
    set_task(1.0, "task_protection_hud", id + TASK_PROTECTION, _, _, "b");
}

public task_protection_hud(taskid)
{
    new id = taskid - TASK_PROTECTION;
    if(!is_user_connected(id) || !g_bProtected[id])
    {
        remove_task(taskid);
        return;
    }

    if(g_iProtTimer[id] > 0)
    {
        client_print(id, print_center, "[ AURA: %d ]", g_iProtTimer[id]--);
    }
    else
    {
        remove_protection(id);
    }
}

public remove_protection(id)
{
    g_bProtected[id] = false;
    remove_task(id + TASK_PROTECTION);
    if(is_user_connected(id))
    {
        set_pev(id, pev_renderfx, kRenderFxNone);
        set_pev(id, pev_rendermode, kRenderNormal);
        set_pev(id, pev_renderamt, 255.0);
    }
}

public fw_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damage_type)
{
    // FIXED: Added attacker bounds check to prevent crashing on fall/world damage
    if(1 <= attacker <= MaxClients && is_user_connected(attacker) && g_bProtected[victim])
    {
        return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

reset_player_vars(id)
{
    g_bWaiting[id] = false;
    g_bReadyToSpawn[id] = false;
    g_bProtected[id] = false;
    remove_task(id + TASK_VOID);
    remove_task(id + TASK_RAINBOW);
    remove_task(id + TASK_PROTECTION);
    remove_task(id + TASK_RESPAWN_PAD);
    client_cmd(id, "stopsound");
}

stock UTIL_ScreenFade(id, r, g, b, a, Float:fDur, Float:fHold, iFlags)
{
    if(!is_user_connected(id)) return;
    message_begin(MSG_ONE, g_msgScreenFade, _, id);
    write_short(floatround(fDur * 4096.0));
    write_short(floatround(fHold * 4096.0));
    write_short(iFlags);
    write_byte(r); write_byte(g); write_byte(b); write_byte(a);
    message_end();
}

stock UTIL_ScreenShake(id, Float:fAmp, Float:fDur)
{
    if(!is_user_connected(id)) return;
    message_begin(MSG_ONE, g_msgScreenShake, _, id);
    write_short(floatround(fAmp * 4096.0));
    write_short(floatround(fDur * 4096.0));
    write_short(floatround(1.0 * 4096.0));
    message_end();
}
