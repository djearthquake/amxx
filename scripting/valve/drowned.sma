#include <amxmodx>
#include <engine>
#include <engine_stocks>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define UNDERWATER 3

new bool:g_bis_underwater[MAX_PLAYERS + 1]
new bool:g_bhas_splashed[MAX_PLAYERS + 1]
new bool:g_bis_fallen[MAX_PLAYERS + 1]
new bool:g_bis_mortar[MAX_PLAYERS + 1]

new const SPLASH[] = "common/splash_large.wav"

public plugin_init()
{
    register_plugin("Drowning Announcer", "1.1", "SPiNX");

    RegisterHam(Ham_Killed, "player", "@check_water");
    RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_player");

    register_impulse(111, "@impulse_handler");
    RegisterHam(Ham_Spawn, "player", "@client_spawn", 1);
    RegisterHam(Ham_TakeHealth, "player", "@client_newhealth", 1);

    RegisterHam(Ham_Weapon_ShouldWeaponIdle, "weapon_egon", "@client_noammo", 1);
    RegisterHam(Ham_Weapon_RetireWeapon, "weapon_egon", "@egon_respawn");

    RegisterHamPlayer(Ham_BarnacleVictimReleased, "@barn_release");
    RegisterHamPlayer(Ham_BarnacleVictimBitten, "@barn_bite");
    RegisterHamPlayer(Ham_FBecomeProne, "@barn_grab");
}

public client_PreThink(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
        return;

    new bool:bIsFalling = (pev(id, pev_flFallVelocity) > 100.0);

    if (bIsFalling)
    {
        if (pev(id, pev_waterlevel) == 2 && !task_exists(id))
        {
            set_task(random_float(0.1, 0.3), "@splash_snd", id);
        }
    }
    else
    {
        g_bhas_splashed[id] = false;
    }
}

@splash_snd(id)
{
    if (is_user_alive(id) && !g_bhas_splashed[id])
    {
        emit_sound(id, CHAN_AUTO, SPLASH, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        g_bhas_splashed[id] = true;
    }
}

@client_noammo(wpn_id)
{
    new id = pev(wpn_id, pev_owner);

    if (is_user_alive(id))
    {
        client_print(id, print_center, "%n you are out of ammo!", id);
    }
}

@client_newhealth(id, Float:health, damagebits)
{
    if (is_user_alive(id))
    {
        new Float:flCurrentHp = entity_get_float(id, EV_FL_health);

        if (flCurrentHp < 100.0 && pev(id, pev_button) != IN_USE && damagebits > 0)
        {
            client_print(id, print_chat, "You're healing!");
        }
        if (damagebits < 0)
        {
            client_print(id, print_chat, "You're being hurt!");
        }
    }
}

@egon_respawn(wpn_id)
{
    client_print(0, print_chat, "Egon's gone!");
}

@barn_grab(id)
{
    if (is_user_alive(id))
    {
        client_print(0, print_chat, "%n was grabbed by barnacle.", id);
    }
}

@barn_release(id)
{
    if (is_user_alive(id))
    {
        client_print(0, print_chat, "%n was released by barnacle.", id);
    }
}

@barn_bite(id)
{
    if (is_user_alive(id))
    {
        client_print(0, print_chat, "%n was bitten by a barnacle.", id);
    }
}

@is_underwater(id)
{
    if (is_user_alive(id))
    {
        if (pev(id, pev_waterlevel) != UNDERWATER)
        {
            g_bis_underwater[id] = false;
        }
        else
        {
            g_bis_underwater[id] = true;
            client_print(id, print_chat, "%n surface for air.", id);
        }
    }
}

@client_spawn(id)
{
    if (is_user_alive(id))
    {
        g_bis_underwater[id] = false;
        g_bhas_splashed[id] = false;
        g_bis_fallen[id] = false;
        g_bis_mortar[id] = false;
    }
}

@check_water(id)
{
    if (g_bis_underwater[id])
    {
        client_print(0, print_chat, "%n must have drowned or died a watery death.", id);
    }
    else if (g_bis_mortar[id])
    {
        client_print(0, print_chat, "%n needs to move their ass next time.", id);
    }
    else if (g_bis_fallen[id])
    {
        client_print(0, print_chat, "%n must have fallen or something.", id);
    }
}

@impulse_handler(id)
{
    if (is_user_alive(id))
    {
        give_item(id, "item_airtank");
    }
}

public plugin_precache()
{
    precache_sound("doors/aliendoor3.wav");
    precache_sound(SPLASH);
    precache_model("models/w_oxygen.mdl");
}

public Ham_TakeDamage_player(id, ent, idattacker, Float:damage, damagebits)
{
    if (is_user_alive(id))
    {
        g_bis_fallen[id] = ((damagebits & DMG_FALL) != 0);
        g_bis_mortar[id] = ((damagebits & DMG_BLAST) != 0);

        if (damagebits & DMG_DROWN)
        {
            @is_underwater(id);
        }
        else
        {
            g_bis_underwater[id] = false;
        }
    }

    if (!(damagebits & (DMG_FALL | DMG_BLAST | DMG_DROWN)))
        return HAM_IGNORED;

    return HAM_HANDLED;
}
