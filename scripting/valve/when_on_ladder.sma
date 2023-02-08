#include amxmodx
#include fakemeta
///"skin" "-16"
new bMultiplayer
new bool:bReadble[MAX_PLAYERS];

public plugin_init()
{
    register_plugin("Ladder!","1.0.0","SPiNX")
}

public client_putinserver(iPlayer)
{
    if(is_user_connected(iPlayer))
    {
        bReadble[iPlayer] = true
        bMultiplayer = get_playersnum();
    }
}

public client_disconnected(iPlayer)
{
    bReadble[iPlayer] = false
    bMultiplayer = get_playersnum();
}

public client_PreThink(iPlayer)
{
    if(bReadble[iPlayer])
    {
        if(pev(iPlayer, pev_movetype) == MOVETYPE_FLY)
        {
            bMultiplayer ? client_print(0, print_center, "%n,^nis doing something with a ladder.", iPlayer) : client_print(iPlayer, print_center, "Ladder!")
        }
    }
    return PLUGIN_HANDLED;
}
