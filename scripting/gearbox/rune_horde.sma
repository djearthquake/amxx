#include amxmodx
#include engine_stocks
#include fakemeta

#define charsmin                  -1

new const SzMakersMark[]="𝓼𝓹𝓲𝓷𝔁"

new g_runefix, szPowerup[ MAX_PLAYERS ];

new const SzRune[][]=
{
    "item_ctfbackpack",
    "item_ctfregeneration",
    "item_ctfportablehev",
    "item_ctflongjump",
    "item_ctfaccelerator"
}

@CTFGameReset()
{
    server_print SzMakersMark
    return PLUGIN_HANDLED
}

public plugin_init()
{
    register_plugin("powerup mgmt(rune_horde)","0.0.1","SPiNX")
    g_runefix = register_event_ex("CustomIcon", "plugin_log", RegisterEventFlags:RegisterEvent_Single|RegisterEvent_OnceForMultiple|RegisterEvent_OnlyAlive, "2=drop_Ammo_Powerup", "2=drop_Damage_Powerup", "2=drop_Jump_Powerup", "2=drop_Health_Powerup", "2=drop_Shield_Powerup");
    register_event_ex ( "ResetHUD" , "@event_disable", RegisterEventFlags: RegisterEvent_Single)
    new iMsg = get_user_msgid("TextMsg")
    register_message(iMsg, "@CTFGameReset")
}

public client_connect(id)
{
    enable_event(g_runefix)
}

@event_disable()
{
    disable_event(g_runefix)
}

public plugin_log()
{
    read_logargv(2,szPowerup, charsmax(szPowerup));

    if(containi(szPowerup, "drop_") != charsmin)
    {

        new target = get_loguser_index()

        if(is_user_connected(target))
            @rune(target)

    }

}

@rune(id)
{
    new iRune, Float:fOrigin[3];
    for(new s;s < sizeof SzRune; s++)
    {
        iRune = find_ent(charsmin, SzRune[s])
        if(iRune)
        {
            pev(id, pev_origin, fOrigin)
            set_pev(iRune, pev_oldorigin, fOrigin)
        }
    }
}

stock get_loguser_index()
{
    new log_user[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_PLAYERS];
    read_logargv(0, log_user, charsmax(log_user));

    parse_loguser(log_user, name, charsmax(name));

    return get_user_index(name);
}
