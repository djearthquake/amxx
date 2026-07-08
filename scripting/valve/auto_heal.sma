#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Auto Heal"
#define VERSION "0.2"
#define AUTHOR "SPiNX"

#define TASK_HEALTH 1001

new g_pCvarPercent;
new g_pCvarInterval;
new g_pCvarMaxHealth;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pCvarPercent = create_cvar("auto_heal_percent", "10");
    g_pCvarInterval = create_cvar("auto_heal_interval", "30.0");
    g_pCvarMaxHealth = create_cvar("auto_heal_max", "100");

    set_task(get_pcvar_float(g_pCvarInterval), "give_health_kit", TASK_HEALTH, _, _, "b");
}

public give_health_kit()
{
    new players[MAX_PLAYERS], num, player;

    get_players(players, num, "a");

    if (num == 0)
    {
        return;
    }

    new percent = get_pcvar_num(g_pCvarPercent);
    new max_health = get_pcvar_num(g_pCvarMaxHealth);

    for (new i = 0; i < num; i++)
    {
        player = players[i];

        if (is_user_alive(player))
        {
            new Float:current_health;
            pev(player, pev_health, current_health);

            if (current_health >= 90.0 || current_health >= float(max_health))
            {
                continue;
            }

            new Float:health_bonus = float(floatround((current_health * float(percent)) / 100.0, floatround_ceil));

            if (health_bonus < 1.0)
            {
                health_bonus = 1.0;
            }

            new Float:new_health = current_health + health_bonus;

            if (new_health > float(max_health))
            {
                new_health = float(max_health);
            }

            set_pev(player, pev_health, new_health);
        }
    }
}
