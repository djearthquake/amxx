/*Fix bots shooting at sky.*/
#include amxmodx
#include engine_stocks
#include fakemeta_util
#define  charsmin          -1

public plugin_init()
{
    register_plugin("op4ctf_specfix","0.0.2","SPiNX");
    {
        if(!find_ent(charsmin,"info_ctfdetect"))
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
