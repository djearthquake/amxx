/*Inspired by playing Sven and seeing need when playing HL:OF with lots of bots on cool maps with just too few spawn points. July 2024 -SPiNX*/
#define PLAYER_COUNT 5 //number of players to make code work.
#include amxmodx
#include amxmisc
#include engine_stocks
#include fakemeta
#include fun
#include hamsandwich

#define DEATH_CHECK 2024
static const szMsg[]="Getting permission^nto spawn now."
new bool:OkSpawn[MAX_PLAYERS+1], g_playercount
new g_mp_spawntime, g_spawn_timer[MAX_PLAYERS +1]


public plugin_init()
{
    register_plugin("Spawn wait time", "1.1", "SPiNX");
    RegisterHam(Ham_Killed, "player", "client_death", 1);
    RegisterHam(Ham_Spawn, "player", "client_spawn", 0);
    register_forward(FM_PlayerPreThink, "client_spawn_control");
    g_mp_spawntime = register_cvar("spawn_wait", "10")
}

public client_disconnected(id)
{
    g_playercount--
}

public client_spawn_control(id)
{
    if(is_user_connected(id) && !OkSpawn[id])
    {
         set_pev(id, pev_deadflag, DEAD_DEAD)
         client_print(id, print_center, szMsg)
    }
}

public client_putinserver(id)
{
    g_playercount++
    OkSpawn[id] = true
    if(is_user_connected(id) && g_playercount > PLAYER_COUNT)
    {
        if(is_user_alive(id))
        {
            static effects; effects = pev(id, pev_effects)
            set_pev(id, pev_effects, (effects | EF_NODRAW))
            fakedamage(id,"Welcome!",1000.0,DMG_GENERIC)
        }
        OkSpawn[id] = false
        g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)
        set_task(float(g_spawn_timer[id]), "@spawn_buffer", id)
    }
}

public client_death(id)
{
    if(is_user_connected(id) && g_playercount > PLAYER_COUNT)
    {
        g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)

        set_task(float(g_spawn_timer[id]), "@spawn_buffer",id)
        set_task_ex(1.0, "@Show_spawn_time", id+2024, .flags = SetTask_RepeatTimes, .repeat = g_spawn_timer[id])

        static effects; effects = pev(id, pev_effects)
        set_pev(id, pev_effects, (effects | EF_NODRAW))

        OkSpawn[id] = false
    }
}

public client_spawn(id)
{
    if(is_user_connected(id))
    {
        static effects; effects = pev(id, pev_effects)
        if(g_playercount>PLAYER_COUNT)
        {
            if(is_user_alive(id) && !OkSpawn[id])
            {
                set_pev(id, pev_deadflag, DEAD_DEAD)
                set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
                set_pev(id, pev_effects, (effects | EF_NODRAW))
                return
            }
        }
        set_pev(id, pev_effects, (effects | ~EF_NODRAW))
        set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,255)
    }
}

@Show_spawn_time(tsk)
{
    new id = tsk-2024

    if(is_user_connected(id) && g_spawn_timer[id])
    {
        client_print id, print_chat,"Spawn wait remaining %i seconds", --g_spawn_timer[id]
        return
    }
    remove_task(tsk)
}

@spawn_buffer(id)
{
    OkSpawn[id] = true
}
