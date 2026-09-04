#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <gearbox>
#include <xs>
#include <fun>

#define PEV_STATE pev_iuser1
#define PEV_TIME pev_fuser1

#define STATE_FLYING 0
#define STATE_RETURNING 1
#define STATE_STUCK 2

static const szWeaponNames[][] = { "weapon_crowbar", "weapon_knife", "weapon_pipewrench" };
static const szMeleeClasses[][] = { "fly_crowbar", "fly_knife", "fly_pipe" };
static const SzClass[][] =
{
    "func_breakable", "func_button", "momentary_door",
    "func_healthcharger", "func_recharge",
    "func_door", "func_door_rotating",
    "func_wall", "func_wall_toggle",
    "func_pushable", "monster_tentacle"
};

static blood_drop, blood_spray, trail, lightning;
static m_pPlayer, m_flNextSecondaryAttack, m_pActiveItem;
static melee_speed, melee_trail, melee_damage, melee_time;
static pCvarStuckTime;

static const szWorldSounds[][] =
{
    "weapons/cbar_hit1.wav",
    "weapons/cbar_hit2.wav"
};

static g_iMeleeAmmo[MAX_PLAYERS + 1];
static g_iPlayerTier[MAX_PLAYERS + 1];
static g_iBreakableSmashes[MAX_PLAYERS + 1];

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_OFFSET_PLAYER = 5;

public plugin_init()
{
    register_plugin("Flying Melee Homing Boomerang", "0.1", "SPiNX");

    for (new i; i < sizeof szWeaponNames; i++)
    {
        RegisterHam(Ham_Weapon_SecondaryAttack, szWeaponNames[i], "fw_MeleeSecondaryAttack");
    }

    for (new i; i < sizeof szMeleeClasses; i++)
    {
        register_think(szMeleeClasses[i], "FlyMelee_Think");
        register_touch(szMeleeClasses[i], "*", "FlyMelee_Touch");

        for (new j; j < sizeof SzClass; j++)
        {
            register_touch(szMeleeClasses[i], SzClass[j], "fw_WorldTouch");
        }
    }

    register_event("DeathMsg", "Event_DeathMsg", "a");

    melee_speed = register_cvar("fly_melee_speed", "2400.0");
    melee_trail = register_cvar("fly_melee_trail", "1");
    melee_damage = register_cvar("fly_melee_damage", "240.0");
    melee_time = register_cvar("fly_melee_time", "1.5");
    pCvarStuckTime = register_cvar("fly_melee_stuck_time", "15.0");

    m_pPlayer = (find_ent_data_info("CBasePlayerItem", "m_pPlayer") / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS;
    m_flNextSecondaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextSecondaryAttack") / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS;
    m_pActiveItem = (find_ent_data_info("CBasePlayer", "m_pActiveItem") / LINUX_OFFSET_PLAYER) - LINUX_OFFSET_PLAYER;
}

public plugin_precache()
{
    blood_drop = precache_model("sprites/blood.spr");
    blood_spray = precache_model("sprites/bloodspray.spr");
    trail = precache_model("sprites/zbeam3.spr");
    lightning = precache_model("sprites/lgtning.spr");

    precache_sound("weapons/cbar_hitbod1.wav");
    precache_sound("weapons/cbar_miss1.wav");

    for (new i = 0; i < sizeof szWorldSounds; i++)
    {
        precache_sound(szWorldSounds[i]);
    }
}

public client_connect(id)
{
    g_iMeleeAmmo[id] = 1;
    g_iPlayerTier[id] = 0;
    g_iBreakableSmashes[id] = 0;
}

public Event_DeathMsg()
{
    new iAttacker = read_data(1);
    new iVictim = read_data(2);

    if (iAttacker != iVictim && is_user_connected(iAttacker))
    {
        g_iMeleeAmmo[iAttacker]++;

        if (g_iPlayerTier[iAttacker] < 2 && g_iMeleeAmmo[iAttacker] >= 3)
        {
            g_iPlayerTier[iAttacker] = 2;
            client_print(iAttacker, print_center, "TIER UPGRADED: MASTER LEVEL (BOOSTED DAMAGE & SPEED)!");
        }
        else if (g_iPlayerTier[iAttacker] < 1)
        {
            g_iPlayerTier[iAttacker] = 1;
            client_print(iAttacker, print_center, "TIER UPGRADED: SKILLET (WALL PUNCTURE UNLOCKED)!");
        }
    }
}

public client_PostThink(id)
{
    if (!is_user_alive(id))
    {
        return;
    }

    static Float:fPlayerOrigin;
    pev(id, pev_origin, fPlayerOrigin);

    new iEnt = -1;
    static szClassName[MAX_NAME_LENGTH];

    while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, fPlayerOrigin, 60.0)) != 0)
    {
        if (!pev_valid(iEnt))
        {
            continue;
        }

        pev(iEnt, pev_classname, szClassName, charsmax(szClassName));

        if (containi(szClassName, "fly_") != -1 && pev(iEnt, PEV_STATE) == STATE_STUCK)
        {
            g_iMeleeAmmo[id]++;
            emit_sound(id, CHAN_ITEM, "weapons/cbar_miss1.wav", 0.7, ATTN_NORM, 0, PITCH_NORM);
            client_print(id, print_center, "Harvested Wall Weapon! Total Ammo Stockpile: %d", g_iMeleeAmmo[id]);

            remove_task(iEnt + 100);
            remove_task(iEnt + 200);

            set_pev(iEnt, pev_flags, FL_KILLME);
        }
    }
}

public fw_MeleeSecondaryAttack(ent)
{
    if (pev_valid(ent))
    {
        new id = get_pdata_cbase(ent, m_pPlayer, LINUX_OFFSET_WEAPONS);

        if (is_user_connected(id))
        {
            static szClass[MAX_NAME_LENGTH];
            pev(ent, pev_classname, szClass, charsmax(szClass));

            if (!FlyMelee_Spawn(id, szClass))
            {
                return HAM_IGNORED;
            }

            new bool:isAdmin = bool:(get_user_flags(id) & ADMIN_BAN);
            set_pdata_float(ent, m_flNextSecondaryAttack, 0.2, LINUX_OFFSET_WEAPONS);

            if (isAdmin)
            {
                set_pev(id, pev_viewmodel2, "");
            }
            else
            {
                g_iMeleeAmmo[id]--;

                if (g_iMeleeAmmo[id] <= 0)
                {
                    ExecuteHam(Ham_RemovePlayerItem, id, ent);
                    ExecuteHamB(Ham_Item_Kill, ent);
                    g_iMeleeAmmo[id] = 0;
                }
                else
                {
                    client_print(id, print_center, "Throws Remaining: %d", g_iMeleeAmmo[id]);
                }
            }
        }
    }
    return HAM_IGNORED;
}

public FlyMelee_Spawn(id, const szClassname[])
{
    new melee = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

    if (!pev_valid(melee))
    {
        return 0;
    }

    static szFlyClass[MAX_NAME_LENGTH];
    copy(szFlyClass, charsmax(szFlyClass), szClassname);
    replace(szFlyClass, charsmax(szFlyClass), "weapon_", "fly_");

    if (equal(szFlyClass, "fly_pipewrench"))
    {
        copy(szFlyClass, charsmax(szFlyClass), "fly_pipe");
    }

    set_pev(melee, pev_classname, szFlyClass);

    if (equal(szFlyClass, "fly_crowbar"))
    {
        engfunc(EngFunc_SetModel, melee, "models/w_crowbar.mdl");
    }
    else if (equal(szFlyClass, "fly_knife"))
    {
        engfunc(EngFunc_SetModel, melee, "models/w_knife.mdl");
    }
    else if (equal(szFlyClass, "fly_pipe"))
    {
        engfunc(EngFunc_SetModel, melee, "models/w_pipe_wrench.mdl");
    }

    engfunc(EngFunc_SetSize, melee, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});

    static Float:fOrigin[3], Float:fAngles[3], Float:fVelocity[3];
    get_projective_pos(id, fOrigin);
    engfunc(EngFunc_SetOrigin, melee, fOrigin);

    pev(id, pev_v_angle, fAngles);
    set_pev(melee, pev_owner, id);
    set_pev(melee, pev_angles, fAngles);
    set_pev(melee, pev_movetype, MOVETYPE_FLY);
    set_pev(melee, pev_solid, SOLID_BBOX);
    set_pev(melee, PEV_STATE, STATE_FLYING);
    set_pev(melee, PEV_TIME, get_gametime() + get_pcvar_float(melee_time));

    new iTier = g_iPlayerTier[id];
    new Float:fCvarSpeed = get_pcvar_float(melee_speed);

    if (iTier == 2)
    {
        fCvarSpeed *= 1.25;
    }

    static hp; hp = pev(id, pev_health);
    new Float:speed_multiplier = floatmax(0.6, hp / 100.0);
    velocity_by_aim(id, floatround(fCvarSpeed * speed_multiplier), fVelocity);
    set_pev(melee, pev_velocity, fVelocity);
    set_pev(melee, pev_nextthink, get_gametime() + 0.01);

    if (get_pcvar_num(melee_trail))
    {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMFOLLOW);
        write_short(melee);
        write_short((iTier == 2) ? lightning : trail);
        write_byte(10);
        write_byte((iTier == 2) ? 6 : 2);
        write_byte(random(255)); write_byte(random(255)); write_byte(random(255));
        write_byte(200);
        message_end();
    }

    emit_sound(id, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);
    return melee;
}

public FlyMelee_Think(ent)
{
    if (!pev_valid(ent))
    {
        return;
    }

    new iState = pev(ent, PEV_STATE);

    if (iState == STATE_STUCK)
    {
        set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
        set_pev(ent, pev_nextthink, 0.0);
        return;
    }

    new owner = pev(ent, pev_owner);
    new bool:isAdmin = bool:(get_user_flags(owner) & ADMIN_BAN);

    static Float:fAngles[3], Float:fOrigin[3], Float:fTarget[3], Float:fViewOfs[3];
    pev(ent, pev_angles, fAngles);
    fAngles[0] += 65.0; fAngles[1] += 15.0;
    set_pev(ent, pev_angles, fAngles);
    pev(ent, pev_origin, fOrigin);

    if (iState == STATE_FLYING && get_gametime() >= pev(ent, PEV_TIME))
    {
        set_pev(ent, PEV_STATE, STATE_RETURNING);
    }

    if (isAdmin && iState == STATE_FLYING)
    {
        new iTargetEnt = -1;
        new Float:fMinDist = 600.0;

        while ((iTargetEnt = engfunc(EngFunc_FindEntityInSphere, iTargetEnt, fOrigin, fMinDist)) != 0)
        {
            if (iTargetEnt == owner || !pev_valid(iTargetEnt))
            {
                continue;
            }
            if (!(pev(iTargetEnt, pev_flags) & (FL_CLIENT | FL_MONSTER)))
            {
                continue;
            }
            if (pev(iTargetEnt, pev_health) <= 0.0)
            {
                continue;
            }

            pev(iTargetEnt, pev_origin, fTarget);
            goto apply_vel;
        }
    }

    if (pev(ent, PEV_STATE) == STATE_RETURNING && is_user_alive(owner))
    {
        pev(owner, pev_origin, fTarget);
        pev(owner, pev_view_ofs, fViewOfs);
        xs_vec_add(fTarget, fViewOfs, fTarget);
    }
    else if (pev(ent, PEV_STATE) == STATE_FLYING)
    {
        set_pev(ent, pev_nextthink, get_gametime() + 0.01);
        return;
    }

apply_vel:
    static Float:fDir[3], Float:fCurVel[3];
    xs_vec_sub(fTarget, fOrigin, fDir);
    xs_vec_normalize(fDir, fDir);

    new Float:fSpeedCvar = get_pcvar_float(melee_speed);
    if (g_iPlayerTier[owner] == 2)
    {
        fSpeedCvar *= 1.25;
    }

    xs_vec_mul_scalar(fDir, fSpeedCvar, fDir);
    pev(ent, pev_velocity, fCurVel);

    new Float:fReturnFactor = (g_iPlayerTier[owner] == 2) ? 0.30 : 0.12;
    new Float:fStabilizeFactor = 1.0 - fReturnFactor;

    for (new i = 0; i < 3; i++)
    {
        fCurVel[i] = (fCurVel[i] * fStabilizeFactor) + (fDir[i] * fReturnFactor);
    }
    set_pev(ent, pev_velocity, fCurVel);

    if (pev(ent, PEV_STATE) == STATE_RETURNING && vector_distance(fOrigin, fTarget) < 65.0)
    {
        Catch_Melee(owner, ent);
        return;
    }

    set_pev(ent, pev_nextthink, get_gametime() + 0.01);
}

public FlyMelee_Touch(toucher, touched)
{
    if (!pev_valid(toucher))
    {
        return;
    }

    new iState = pev(toucher, PEV_STATE);

    if (iState == STATE_STUCK)
    {
        return;
    }

    new owner = pev(toucher, pev_owner);

    if (touched == 0 && iState == STATE_FLYING)
    {
        fw_WorldTouch(toucher, touched);
        return;
    }

    if (is_user_alive(touched))
    {
        if (touched == owner && iState == STATE_RETURNING)
        {
            Catch_Melee(owner, toucher);
            return;
        }

        if (touched != owner && iState == STATE_FLYING)
        {
            new Float:fDamageValue = get_pcvar_float(melee_damage);
            if (g_iPlayerTier[owner] == 2)
            {
                fDamageValue *= 1.50;
            }

            ExecuteHamB(Ham_TakeDamage, touched, toucher, owner, fDamageValue, DMG_CLUB);
            emit_sound(toucher, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);

            static Float:fOrigin[3]; pev(toucher, pev_origin, fOrigin);
            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
            write_byte(TE_BLOODSPRITE);
            engfunc(EngFunc_WriteCoord, fOrigin[0]); engfunc(EngFunc_WriteCoord, fOrigin[1]); engfunc(EngFunc_WriteCoord, fOrigin[2]);
            write_short(blood_spray); write_short(blood_drop);
            write_byte(248); write_byte(15);
            message_end();

            set_pev(toucher, PEV_STATE, STATE_RETURNING);
        }
    }
}

public fw_WorldTouch(toucher, touched)
{
    if (!pev_valid(toucher))
    {
        return;
    }

    if (pev(toucher, PEV_STATE) != STATE_FLYING)
    {
        return;
    }

    new owner = pev(toucher, pev_owner);
    new iTier = g_iPlayerTier[owner];

    if (iTier == 0)
    {
        set_pev(toucher, PEV_STATE, STATE_RETURNING);
        emit_sound(toucher, CHAN_STATIC, szWorldSounds[random(sizeof szWorldSounds)], 0.6, ATTN_NORM, 0, 125);
        return;
    }

    set_pev(toucher, pev_velocity, Float:{0.0, 0.0, 0.0});
    set_pev(toucher, pev_nextthink, 0.0);
    set_pev(toucher, PEV_STATE, STATE_STUCK);

    static Float:fOrigin[3], Float:fVelocity[3];
    pev(toucher, pev_origin, fOrigin);
    pev(toucher, pev_velocity, fVelocity);
    xs_vec_normalize(fVelocity, fVelocity);
    xs_vec_mul_scalar(fVelocity, -6.0, fVelocity);
    xs_vec_add(fOrigin, fVelocity, fOrigin);

    new iPitch = random_num(95, 115);
    emit_sound(toucher, CHAN_STATIC, szWorldSounds[random(sizeof szWorldSounds)], 0.9, ATTN_NORM, 0, iPitch);

    new iTaskArgs[1];
    iTaskArgs[0] = toucher;

    set_task(0.01, "Task_AnchorPhysics", toucher, iTaskArgs, 1);

    new Float:fTotalStuckTime = get_pcvar_float(pCvarStuckTime);
    new Float:fWiggleTriggerTime = floatmax(1.0, fTotalStuckTime - 3.0);

    set_task(fWiggleTriggerTime, "Task_TriggerWallWiggle", toucher + 100, iTaskArgs, 1);
    set_task(fTotalStuckTime, "Task_ExecuteAutoRecall", toucher + 200, iTaskArgs, 1);

    if (touched > MAX_PLAYERS)
    {
        fm_set_kvd(touched, "explodemagnitude", "1");
        set_pev(touched, pev_health, 1.0);
        set_pev(touched, pev_takedamage, DAMAGE_AIM);
        fakedamage(touched, "Amxx_Alterations", 1.0, DMG_CRUSH);

        g_iBreakableSmashes[owner]++;

        if (g_iPlayerTier[owner] < 2 && g_iBreakableSmashes[owner] >= 15)
        {
            g_iPlayerTier[owner] = 2;
            client_print(owner, print_center, "TIER UPGRADED: MASTER LEVEL (BOOSTED DAMAGE & SPEED)!");
        }
        else if (g_iPlayerTier[owner] < 1 && g_iBreakableSmashes[owner] >= 6)
        {
            g_iPlayerTier[owner] = 1;
            client_print(owner, print_center, "TIER UPGRADED: SKILLET (WALL PUNCTURE UNLOCKED)!");
        }
    }
}

public Task_AnchorPhysics(const iTaskArgs[], id)
{
    new ent = iTaskArgs[0];
    if (pev_valid(ent))
    {
        set_pev(ent, pev_movetype, MOVETYPE_NONE);
        set_pev(ent, pev_solid, 0);
        set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
    }
}

public Task_TriggerWallWiggle(const iTaskArgs[], id)
{
    new ent = iTaskArgs[0];
    if (pev_valid(ent) && pev(ent, PEV_STATE) == STATE_STUCK)
    {
        static Float:fAngles[3]; pev(ent, pev_angles, fAngles);
        fAngles[2] += random_float(-15.0, 15.0);
        set_pev(ent, pev_angles, fAngles);

        set_task(0.1, "Task_TriggerWallWiggle", id, iTaskArgs, 1);
    }
}

public Task_ExecuteAutoRecall(const iTaskArgs[], id)
{
    new ent = iTaskArgs[0];
    if (pev_valid(ent))
    {
        new owner = pev(ent, pev_owner);
        if (is_user_connected(owner))
        {
            g_iMeleeAmmo[owner]++;
            client_print(owner, print_center, "Melee Automatically Recalled! Capacity: %d", g_iMeleeAmmo[owner]);
            emit_sound(owner, CHAN_ITEM, "weapons/cbar_miss1.wav", 0.5, ATTN_NORM, 0, PITCH_NORM);
        }

        remove_task(ent + 100);
        set_pev(ent, pev_flags, FL_KILLME);
    }
}

public Catch_Melee(id, ent)
{
    if (!is_user_alive(id))
        return
    static szFlyClass[MAX_NAME_LENGTH], szWeaponName[MAX_NAME_LENGTH];
    pev(ent, pev_classname, szFlyClass, charsmax(szFlyClass));
    copy(szWeaponName, charsmax(szWeaponName), szFlyClass);
    replace(szWeaponName, charsmax(szWeaponName), "fly_", "weapon_");

    if (equal(szWeaponName, "weapon_pipe"))
    {
        copy(szWeaponName, charsmax(szWeaponName), "weapon_pipewrench");
    }

    g_iMeleeAmmo[id]++;

    new iActiveItem = get_pdata_cbase(id, m_pActiveItem, LINUX_OFFSET_PLAYER);
    static szActiveClass[MAX_NAME_LENGTH];

    if (pev_valid(iActiveItem))
    {
        pev(iActiveItem, pev_classname, szActiveClass, charsmax(szActiveClass));
    }

    if (!equal(szActiveClass, szWeaponName))
    {
        give_item(id, szWeaponName);
    }

    emit_sound(id, CHAN_ITEM, "weapons/cbar_miss1.wav", 0.7, ATTN_NORM, 0, PITCH_NORM);

    if (pev_valid(iActiveItem) && equal(szActiveClass, szWeaponName))
    {
        ExecuteHamB(Ham_Item_Deploy, iActiveItem);
        set_pev(id, pev_weaponanim, 0);
    }

    set_pev(ent, pev_flags, FL_KILLME);
}

public get_projective_pos(player, Float:fOrigin[3])
{
    static Float:fForward[3], Float:fViewOfs[3];
    pev(player, pev_origin, fOrigin);
    pev(player, pev_view_ofs, fViewOfs);
    xs_vec_add(fOrigin, fViewOfs, fOrigin);
    global_get(glb_v_forward, fForward);
    xs_vec_mul_scalar(fForward, 85.0, fForward);
    xs_vec_add(fOrigin, fForward, fOrigin);
}
