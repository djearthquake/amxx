/*Fix bots shooting at sky.*/
#include amxmodx
#include fakemeta_util
#define charsmin                  -1

public plugin_init()
{
    register_plugin("op4ctf_specfix","0.1","SPiNX");
    {
        static mname[MAX_PLAYERS];
        get_mapname(mname, charsmax(mname));

        if (containi(mname,"op4c") == charsmin)
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
