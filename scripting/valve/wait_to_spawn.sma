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
static bool:bRegistered;
new g_mp_spawntime, g_spawn_timer[MAX_PLAYERS +1]


public plugin_init()
{
    register_plugin("Spawn wait time", "1.2", "SPiNX");
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

@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity( Ham_Spawn, ham_bot, "client_spawn", 0 );
        server_print("Wait-to_Spawn ham bot from %N", ham_bot)
    }
}

public client_authorized(id, const authid[])
{
    //bIsBot[id] = equal(authid, "BOT") ? true : false
    if(equal(authid, "BOT") && !bRegistered)
    {
        set_task(0.1, "@register", id);
        bRegistered = true;
    }
}

public client_putinserver(id)
{
    g_playercount++
    OkSpawn[id] = true
    if(is_user_connected(id))
    {
        static szSpec[4]
        get_user_info(id,"spectate", szSpec, charsmax(szSpec))
        static flags; flags = pev(id, pev_flags)

        if(g_playercount > PLAYER_COUNT)
        {
            OkSpawn[id] = flags & ~FL_SPECTATOR ? true : false

            if(equali(szSpec, "1"))
                return

            set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
            static effects; effects = pev(id, pev_effects)
            set_pev(id, pev_effects, (effects | EF_NODRAW))
            fakedamage(id,"Welcome!",1000.0,DMG_GENERIC)

            g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)
            set_task(float(g_spawn_timer[id]), "@spawn_buffer", id)
        }
    }
}

public client_death(id)
{
    if(is_user_connected(id))
    {
        set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
        static effects; effects = pev(id, pev_effects)
        set_pev(id, pev_effects, (effects | EF_NODRAW))

        if(g_playercount > PLAYER_COUNT)
        {
            g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)

            set_task(float(g_spawn_timer[id]), "@spawn_buffer",id)
            set_task_ex(1.0, "@Show_spawn_time", id+2024, .flags = SetTask_RepeatTimes, .repeat = g_spawn_timer[id])

            set_pev(id, pev_effects, (effects | EF_NODRAW))

            static flags; flags = pev(id, pev_flags)
            OkSpawn[id] = flags & ~FL_SPECTATOR ? true : false
        }
    }
}

public _client_spawn(id)
{
    set_task(0.2, "client_spawn", id)
}

public client_spawn(id)
{
    if(is_user_connected(id))
    {
        static effects; effects = pev(id, pev_effects)

        if(g_playercount>PLAYER_COUNT)
        {
            if(is_user_alive(id))
            {
                static flags;flags = pev(id, pev_flags)

                if(!OkSpawn[id] && flags & ~FL_SPECTATOR)
                {
                    set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
                    set_pev(id, pev_effects, (effects | EF_NODRAW))
                    set_pev(id, pev_deadflag, DEAD_DEAD)
                }
                else
                {
                    set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,255)
                    set_pev(id, pev_effects, (effects | ~EF_NODRAW))
                }
            }
        }
        set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,255)
        set_pev(id, pev_effects, (effects | ~EF_NODRAW))
    }
}

@Show_spawn_time(tsk)
{
    static id; id = tsk-2024

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
