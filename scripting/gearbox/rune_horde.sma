#include amxmodx
#include engine_stocks
#include fakemeta

#define charsmin                  -1

///new const SzMakersMark[]="𝓼𝓹𝓲𝓷𝔁"

new bool:bFlagMap, g_runefix, szPowerup[ MAX_PLAYERS ];

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
    //server_print SzMakersMark
    return PLUGIN_HANDLED
}

public plugin_init()
{
    register_plugin("powerup mgmt(rune_horde)","0.0.3","SPiNX");
    g_runefix =
    register_event_ex("PlayerIcon"/*CustomIcon*/, "plugin_log",
    RegisterEventFlags: RegisterEvent_OnlyAlive,
    "2=drop_Ammo_Powerup",
    "2=drop_Damage_Powerup",
    "2=drop_Jump_Powerup",
    "2=drop_Health_Powerup",
    "2=drop_Shield_Powerup");

    register_event_ex ( "ResetHUD" , "@event_disable", RegisterEventFlags: RegisterEvent_Single)

    new iMsg = get_user_msgid("TextMsg");
    register_message(iMsg, "@CTFGameReset");
    new mname[MAX_NAME_LENGTH]
    get_mapname(mname, charsmax(mname));

    bFlagMap = containi(mname,"op4c") > charsmin?true:false
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
    new iRune, Float:fOrigin[3];
    read_logargv(2,szPowerup, charsmax(szPowerup));

    if(containi(szPowerup, "drop_") != charsmin)
    {
        new target = get_loguser_index()
        if(is_user_connected(target))
        {
            pev(target, pev_origin, fOrigin)
            if(bFlagMap)
            {
                if(containi(szPowerup, "Ammo") != charsmin||containi(szPowerup, "Jump") != charsmin ||containi(szPowerup, "Shield") != charsmin)
                {
                    for(new s=0;s < sizeof SzRune; ++s)
                    {
                        iRune = find_ent(charsmin, SzRune[s])
                        if(iRune)
                        {
                            set_pev(iRune, pev_oldorigin, fOrigin)
                        }
                    }
                }
                else
                {
                    for(new s=0;s < sizeof SzRune; ++s)
                    {
                        iRune = find_ent(charsmin, SzRune[s])
                        if(iRune)
                        {
                            set_pev(iRune, pev_origin, fOrigin)
                        }
                    }
                }
            }
            else
            {
                for(new s=0;s < sizeof SzRune; ++s)
                {
                    iRune = find_ent(charsmin, SzRune[s])
                    if(iRune)
                    {
                        set_pev(iRune, pev_oldorigin, fOrigin)
                    }
                }
            }
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
