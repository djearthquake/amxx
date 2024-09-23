/*Fix bots shooting at sky.*/
#include amxmodx
#include fakemeta_util

public plugin_init()
{
    register_plugin("op4ctf_specfix","0.0.3","SPiNX");
    {
        if(!has_map_ent_class("info_ctfdetect"))
        {
            pause "a";
        }
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        set_pev(id, pev_deadflag, DEAD_DEAD)
    }

}
