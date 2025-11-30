/*Inspired by playing Sven and seeing need when playing HL:OF with lots of bots on cool maps with just too few spawn points. July 2024 -SPiNX*/

#include amxmodx
#include amxmisc
#include engine_stocks
#include fakemeta
#include fun
#include hamsandwich

#define DEATH_CHECK 2024
static const szMsg[]="Getting permission^nto spawn now.";
static bool:bRegistered;
new bool:OkSpawn[MAX_PLAYERS+1],
bool:bRanTask[MAX_PLAYERS+1],
g_playercount, g_users, g_mp_spawntime, g_spawn_timer[MAX_PLAYERS +1];


public plugin_init()
{
    register_plugin("Spawn wait time", "1.23", "SPiNX");
    RegisterHam(Ham_Killed, "player", "client_death", 1);
    RegisterHam(Ham_Spawn, "player", "client_spawn", 0);
    register_forward(FM_PlayerPreThink, "client_spawn_control");
    g_mp_spawntime = register_cvar("spawn_wait", "10")
    g_users = register_cvar("spawn_total", "4")
}

public client_disconnected(id)
{
    g_playercount--
}

public client_spawn_control(id)
{
    if(is_user_connected(id))
    {
        if(!OkSpawn[id])
        {
            set_pev(id, pev_deadflag, DEAD_DEAD)
            client_print(id, print_center, szMsg)
        }
    }
}

@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        bRegistered = true;
        RegisterHamFromEntity( Ham_Spawn, ham_bot, "client_spawn", 0 );
        RegisterHamFromEntity(Ham_Killed, ham_bot, "client_death", 1);
        server_print("Wait-to_Spawn ham bot from %N", ham_bot)
    }
}

public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT") && !bRegistered)
    {
        set_task(0.1, "@register", id)
    }
}

public client_putinserver(id)
{
    static szSpec[4]
    g_playercount++
    new iCount = get_pcvar_num(g_users)

    if(is_user_connected(id))
    {
        get_user_info(id,"spectate", szSpec, charsmax(szSpec))
        static flags; flags = pev(id, pev_flags)

        OkSpawn[id] = flags & ~FL_SPECTATOR ? true : false
        if(equali(szSpec, "1"))
            return

        OkSpawn[id] = g_playercount >= iCount ? false : true;
        if(!OkSpawn[id])
        {
            g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)
            set_task(float(g_spawn_timer[id]), "@spawn_buffer", id)

            if(!bRanTask[id])
            {
                @Ran_task(id)
                bRanTask[id] = true
            }

            fakedamage(id,"Welcome!",1000.0,DMG_GENERIC)
            set_pev(id, pev_deadflag, DEAD_DEAD)
            set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
        }
    }
}

public client_death(id)
{
    new iCount = get_pcvar_num(g_users)
    if(is_user_connected(id))
    {
        OkSpawn[id] = g_playercount >= iCount ? false : true;
        if(!OkSpawn[id])
        {
            if(!bRanTask[id])
            {
                bRanTask[id] = true
                @Ran_task(id)
            }
            static effects; effects = pev(id, pev_effects)
            set_pev(id, pev_effects, (effects | EF_NODRAW))
            set_pev(id, pev_fov, 150.0)

            set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
            set_view(id, CAMERA_3RDPERSON)

            g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)
            set_task(float(g_spawn_timer[id]), "@spawn_buffer",id)
        }
    }
}

@Ran_task(id)
{
    g_spawn_timer[id] = get_pcvar_num(g_mp_spawntime)
    set_task_ex(1.0, "@Show_spawn_time", id+2024, .flags = SetTask_RepeatTimes, .repeat = g_spawn_timer[id]+1)
}

public client_spawn(id)
{
    if(is_user_connected(id))
    {
        new iCount = get_pcvar_num(g_users)
        static effects; effects = pev(id, pev_effects)

        if(g_playercount>iCount)
        {
            if(id)
            {
                if(!OkSpawn[id])
                {
                    set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
                    set_pev(id, pev_effects, (effects | EF_NODRAW))
                    set_pev(id, pev_fov, 150.0)
                    set_view(id, CAMERA_3RDPERSON)
                    set_pev(id, pev_deadflag, DEAD_DEAD)
                }
                else
                {
                    set_pev(id, pev_deadflag, DEAD_NO)
                    set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,255)
                    set_pev(id, pev_effects, (effects | ~EF_NODRAW))
                    set_pev(id, pev_fov, 100.0)
                    set_view(id, CAMERA_NONE)
                    set_pev(id, pev_movetype, MOVETYPE_WALK)
                    set_pev(id, pev_solid, SOLID_SLIDEBOX)
                    bRanTask[id] = false
                }
                return PLUGIN_HANDLED;
            }
        }
        else
        {
            set_pev(id, pev_deadflag, DEAD_NO)
            set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,255)
            set_pev(id, pev_effects, (effects | ~EF_NODRAW))
            set_pev(id, pev_fov, 100.0)
            set_view(id, CAMERA_NONE)
            set_pev(id, pev_movetype, MOVETYPE_WALK)
            set_pev(id, pev_solid, SOLID_SLIDEBOX)
            bRanTask[id] = false
        }
    }
    return PLUGIN_HANDLED;
}

@Show_spawn_time(tsk)
{
    static id; id = tsk-2024

    if(is_user_connected(id))
    {
        if(g_spawn_timer[id])
        {
            client_print id, print_chat,"Spawn wait remaining %i seconds", g_spawn_timer[id]
            g_spawn_timer[id]--
            return
        }
        remove_task(tsk)
        client_cmd id, "+attack;wait;-attack"
    }
}

@spawn_buffer(id)
{
    if(is_user_connected(id))
    {
        OkSpawn[id] = true
        server_print "%N ALLOWED TO SPAWN.", id
    }
}
