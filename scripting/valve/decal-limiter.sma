#include <amxmodx>
#include <engine>

static g_iFreq;
new yourtime[MAX_PLAYERS+1]

public plugin_init()
{
    register_plugin("Decal Limiter","0.0.2","SPiNX")
    register_impulse(201, "SprayAppraiser")
    g_iFreq = get_cvar_num("decalfrequency")
}

public SprayAppraiser(id)
{
    if(is_user_connected(id))
    {
        if(task_exists(id))
        {
            client_print(id, print_chat, "Spray blocked for %i seconds.", yourtime[id]);
        }
        else
        {
            set_task(1.0, "@end", id, _, _, "a", g_iFreq)
            yourtime[id] = g_iFreq
        }
    }
}

@end(id)
{
    if(is_user_connected(id))
    {
        if(yourtime[id])
        {
            yourtime[id]--
        }
        else
        {
            remove_task(id)
        }
    }
    else
    {
        remove_task(id)
    }
}
