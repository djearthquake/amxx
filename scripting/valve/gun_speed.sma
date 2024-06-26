#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>
#include <fakemeta>
#tryinclude <gearbox>
#include <hamsandwich>
#include <xs>

#define charsmin                  -1
#define ACCESS_LEVEL    ADMIN_USER|ADMIN_CFG
#define VOTE_ACCESS     ADMIN_USER|ADMIN_CFG

#define HLW_GRAPPLE         16
#define HLW_357             17
#define HLW_PIPEWRENCH      18
#define HLW_KNIFE           0x0019
#define HLW_DISPLACER       20
#define HLW_SHOCKROACH      22
#define HLW_SPORE           23
#define HLW_SNIPER          25
#define HLW_PENGUIN         26

#define CART_PARABELUM  356
#define SHOTGUN_SHELLS  355
#define CART_RIFLE  370
#define CART_MAG    358
#define CART_U  359
#define CART_BOLT   361
#define CART_SUB    367

#define MAG_CONTENDER   1
#define MAG_CALIFORNIA  5
#define MAG_POKER   10
#define MAG_COP 16
#define MAG_DRUM    100
#define MAG_BOX 255
#define MAG_ARSEN   1000

#define PLUGIN  "Gun Speed"
#define VERSION "1.0.4"
#define AUTHOR "SPiNX"


const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;

/* VARIABLES */

static ARMS_EXCLUDED
static g_mod_name[MAX_NAME_LENGTH];

new
    bool: b_Bot[MAX_PLAYERS+1],
    cl_weapon[MAX_PLAYERS + 1],
    gOldClip[ MAX_PLAYERS + 1 char ],
    gOldSpecialReload[ MAX_PLAYERS + 1 char ],
    gbCS,
    gbDod,
    gbHL,
    gbSven,
    g_counter[2],
    m_pPlayer ,
    m_fInSpecialReload ,
    m_flNextPrimaryAttack ,
    m_flNextSecondaryAttack ,
    m_flTimeWeaponIdle ,
    m_iClip,
    m_flNextAttack,
    Float:g_Speed,
    gWeaponClassname[MAX_NAME_LENGTH],
    pcvars[MAX_PLAYERS];


static const SzHLAmmo[][]={"ammo_9mmclip", "ammo_9mmbox", "ammo_gaussclip", "ammo_357", "ammo_crossbow", "ammo_buckshot", "ammo_556", "ammo_762"}
//static const SzCSAmmo[][]={"ammo_9mmclip", "ammo_9mmbox", "ammo_57", "ammo_357", "ammo_7", "ammo_buckshot", "ammo_556", "ammo_762"};

new HamHook:XhookReloadPre, HamHook:XhookReloadPost, HamHook:XhookPrimaryAPre, HamHook:XhookPrimaryAPos;

new bool:bAccess[MAX_PLAYERS + 1];
static votekeys = (1<<0)|(1<<1);

@dim(iMsgId, iDest, id)
{
    return PLUGIN_HANDLED
}

public plugin_precache()
{
    get_modname(g_mod_name, charsmax(g_mod_name))
    if(equal(g_mod_name, "gearbox") || equal(g_mod_name, "valve"))
    {
        gbHL = true
        ARMS_EXCLUDED = ((1<<HLW_NONE | 1<<HLW_CROWBAR | 1<<HLW_EGON | 1<<HLW_HANDGRENADE | 1<<HLW_TRIPMINE | 1<<HLW_RPG |1 <<HLW_SATCHEL | 1<<HLW_SNARK | 1<<HLW_GRAPPLE | 1<<HLW_PIPEWRENCH  | 1<<HLW_KNIFE | 1<<HLW_DISPLACER | 1<<HLW_GAUSS | 1<<HLW_PENGUIN))
        precache_model("models/w_chainammo.mdl");
    }
    if(equal(g_mod_name, "cstrike") || equal(g_mod_name, "czero") )
    {
        gbCS = true
        ARMS_EXCLUDED = ((1<<CSW_HEGRENADE | 1<<CSW_C4| 1<<CSW_SMOKEGRENADE| 1<<CSW_FLASHBANG| 1<<CSW_KNIFE))
    }
    else if(equal(g_mod_name, "dod"))
    {
        gbDod = true
    }
    else if(containi(g_mod_name, "sven") > charsmin)
    {
        gbSven = true
    }
}

public plugin_init()
{
    register_plugin( PLUGIN, VERSION, AUTHOR )
    register_concmd("vote_gunspeed","cmdVote",VOTE_ACCESS,": Vote for gun speed!")
    register_message(TE_ELIGHT, "@dim") //flash supressor

    #if !defined MaxClients
        static MaxClients = get_maxplayers()
    #endif
    
    for (new i=CSW_P228;i<=CSW_P90;++i)
    {
        if(!(ARMS_EXCLUDED & (1<<i)) && get_weaponname(i, gWeaponClassname, charsmax(gWeaponClassname)))
        {
            static cvar_name[MAX_PLAYERS + 1];
            formatex(cvar_name, charsmax(cvar_name), "gunspeed_%s", gWeaponClassname)
            replace(cvar_name, charsmax(cvar_name), "weapon_", "")
            pcvars[i] = register_cvar(cvar_name,"0.015")

            pcvars[0] = register_cvar("gunspeed_mode","1") //enable and disable plugin
            pcvars[9] = register_cvar("gunspeed_all","1.0") //has to go with access and second safety like a 1911.

            if(gbSven)
            {
                //Postponed development
                //m_fInSpecialReload = (find_ent_data_info("CBasePlayerWeapon", "SpecialReload") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
                //SpecialReloadEiifi
            }
            if(gbDod)
            {
                //nuances may not be needed.
            }
            else
            {
                m_flNextPrimaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextPrimaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
                m_pPlayer = (find_ent_data_info("CBasePlayerItem", gbSven ? "MyItemPointer" : "m_pPlayer") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
                m_fInSpecialReload = (find_ent_data_info("CBasePlayerWeapon", "m_fInSpecialReload") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS

                XhookReloadPre = RegisterHam( Ham_Weapon_Reload         , gWeaponClassname, "Weapon_Reload_Pre" , 0 );

                if(XhookPrimaryAPre)
                    EnableHamForward(XhookPrimaryAPre)

                XhookReloadPost = RegisterHam( Ham_Weapon_Reload         , gWeaponClassname, "Weapon_Reload_Post", 1 );

                if(XhookPrimaryAPos)
                    EnableHamForward(XhookPrimaryAPos)

            }

            XhookPrimaryAPre = RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_PrimaryAttack_Pre" , 0 );
            if(XhookReloadPre)
                EnableHamForward(XhookReloadPre)


            XhookPrimaryAPos = RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_PrimaryAttack_Post", 1 );
            if(XhookReloadPost)
                EnableHamForward(XhookReloadPost)

            m_flNextSecondaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextSecondaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
            m_flTimeWeaponIdle = (find_ent_data_info("CBasePlayerWeapon", "m_flTimeWeaponIdle") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
            m_iClip = (find_ent_data_info("CBasePlayerWeapon", "m_iClip") / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS

            m_flNextAttack = (find_ent_data_info("CBaseMonster", "m_flNextAttack") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF
        }
    }

    //Enable plugin handled via vote now
    bind_pcvar_float(get_cvar_pointer("mp_gunspeed") ? get_cvar_pointer("mp_gunspeed") : register_cvar("mp_gunspeed", "0.0"), g_Speed)

    //Since 25th Anniversary update ham has become unstable on Linux. Use at your own risk.
    //RegisterHam(Ham_Spawn, "player", "@spawn", 1);
   //RegisterHam(Ham_Killed, "player", "@death", 1);

    register_event_ex ( "ResetHUD" , "@spawn", RegisterEventFlags:RegisterEvent_Single|RegisterEvent_OnlyAlive)
    register_event_ex ( "CurWeapon", "event_active_weapon", RegisterEventFlags:RegisterEvent_Single|RegisterEvent_OnlyAlive)
    register_event("DeathMsg","@death","a")
    for(new map;map < sizeof SzHLAmmo;++map)
    {
        if(has_map_ent_class(SzHLAmmo[map]))
            remove_entity_name(SzHLAmmo[map])
    }
    register_menucmd(register_menuid("Gunspeed?"),votekeys,"voteGunspeed")
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        b_Bot[id] = is_user_bot(id) ? true : false
    }
}

public event_active_weapon(player)
{
    if(player  > 0 && player <= MaxClients && is_user_connected(player))
    {
        cl_weapon[player] = read_data(2);
        if(cl_weapon[player])
        {
            cl_weapon[player] = get_user_weapon(player)
            return PLUGIN_CONTINUE
        }
    }
    return PLUGIN_HANDLED
}

@death(victim,killer)
{
    if(is_user_alive(killer))
        @spawn(killer)
}

@spawn(player)
{
    if(g_Speed > 0.0 && bAccess[player] && !b_Bot[player] && is_user_connected(player))
    {
        if(XhookPrimaryAPre)
            EnableHamForward(XhookPrimaryAPre)

        if(XhookPrimaryAPos)
            EnableHamForward(XhookPrimaryAPos)

        if(XhookReloadPre)
            EnableHamForward(XhookReloadPre)

        if(XhookReloadPost)
            EnableHamForward(XhookReloadPost)

        if(gbHL)
            set_task(1.0, "@delayed_ammo_give_hl", player)
    }
    else if(!g_Speed)
        plugin_end()
}

@delayed_ammo_give_hl(player)
{
    if(is_user_alive(player))
    {
        ///server_print "%n spawned gunspeed ammo", player    

        if(gbHL)
        {
            set_pdata_int( player, CART_U, MAG_DRUM )
            set_pdata_int( player, CART_BOLT, MAG_DRUM )
            set_pdata_int( player, CART_PARABELUM, MAG_BOX )
            set_pdata_int( player, SHOTGUN_SHELLS, MAG_BOX )
            set_pdata_int( player, CART_RIFLE, MAG_DRUM )
            set_pdata_int( player, CART_MAG, MAG_ARSEN)
            set_pdata_int( player, CART_SUB, MAG_DRUM )    
        }
        if(gbCS)
        {
            //give ammo or buy?
        }

    }

}

public Weapon_PrimaryAttack_Pre ( const weapon )
{
    if(g_Speed > 0.0)
    {
        static player
        //player = gbSven ? pev(weapon, pev_owner) : get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        if(!player)
            player = pev(weapon, pev_owner)
        gOldClip{ player } = get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS );

        if ( gOldClip{ player } <= 0 ||!bAccess[player])
        {
            return;
        }
    }
    else
    {
        plugin_end()
    }

}

public Weapon_PrimaryAttack_Post ( const weapon )
{
    if(g_Speed > 0.0)
    {
        static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        static Float:fGunSpeedOffset
        if(is_user_alive(player))
        if(pcvars[cl_weapon[player]] && get_pcvar_float(pcvars[cl_weapon[player]]))
        {
            fGunSpeedOffset  =  get_pcvar_float(pcvars[cl_weapon[player]])
        }
        //new player = pev(weapon, pev_owner)
        //new player = gbSven ? pev(weapon, pev_owner) : get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        //if(is_user_connected(player) && is_user_alive(player) && pev_valid(weapon)>1)
        if(get_pcvar_num(pcvars[0]) && fGunSpeedOffset>0.0)
        switch(get_pcvar_num(pcvars[0]))
        {
            case 0:
            {
                goto END
            }
            case 1:
            {
                goto CHAOS
                /*
                if(is_user_alive(player))
                {
                    server_print "%n | %i %f %s", player, cl_weapon[player], fGunSpeedOffset, PLUGIN //debug there was a 0 or something being thrown on line 226
                    goto CHAOS
                }
                else
                    return
                */
            }
            case 2:
            {
                if(pcvars[9] && get_pcvar_float(pcvars[9]))
                    goto CHAOS
            }
            default:
            {
                goto END
            }
        }
        CHAOS:
        if ( gOldClip{ player } <= 0 ||!bAccess[player])
        {
            return;
        }

        set_pdata_float( weapon, m_flNextPrimaryAttack,  fGunSpeedOffset*5, LINUX_OFFSET_WEAPONS );

        if ( get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
        {
            set_pdata_float( weapon, m_flTimeWeaponIdle,  fGunSpeedOffset*3, LINUX_OFFSET_WEAPONS );
        }
        else
        {
            set_pdata_float( weapon, m_flTimeWeaponIdle,  fGunSpeedOffset, LINUX_OFFSET_WEAPONS );
        }

        if(gbCS)
            return

        static Float:g_fDelay = 0.01
        const m_flNextPrimaryAttackB = 46
        const m_flNextSecondaryAttackB = 47

        if ( pev_valid(weapon)>1)
        {
            set_pdata_float(weapon, m_flNextPrimaryAttackB, g_fDelay, LINUX_OFFSET_WEAPONS)
            set_pdata_float(weapon, m_flNextSecondaryAttackB, g_fDelay, LINUX_OFFSET_WEAPONS)
        }
    }
    else
    {
        plugin_end()
    }
    END:
}

public Weapon_SecondaryAttack_Pre ( const weapon )
{
    static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Weapon_SecondaryAttack_Post ( const weapon )
{
    if(g_Speed > 0.0)
    {
        static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

        if ( gOldClip{ player } <= 1 ||!bAccess[player])
        {
            return;
        }

        set_pdata_float( weapon, m_flNextPrimaryAttack  ,  0.05, LINUX_OFFSET_WEAPONS );
        set_pdata_float( weapon, m_flNextSecondaryAttack, 0.1, LINUX_OFFSET_WEAPONS );

        if ( get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
        {
            set_pdata_float( weapon, m_flTimeWeaponIdle, 0.3, LINUX_OFFSET_WEAPONS );
        }
        else
        {
            set_pdata_float( weapon, m_flTimeWeaponIdle, 0.85, LINUX_OFFSET_WEAPONS );
        }
    }
    else
    {
        plugin_end()
    }
}

public Weapon_Reload_Pre ( const weapon )
{
    static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

    if(!is_user_connected(player) || player > MaxClients)
        gOldSpecialReload{ player } = get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS );
}

public Weapon_Reload_Post ( const weapon )
{
    if(g_Speed > 0.0)
    {
        static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        if(!is_user_connected(player) || player > MaxClients)
            return

        if(gOldSpecialReload{ player } <= 0  || !bAccess[ player ])
            return

        switch ( gOldSpecialReload{ player } )
        {
            case 0 :
            {
                if ( get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 1 )
                {
                    set_pdata_float( player, m_flNextAttack, 0.3 );

                    set_pdata_float( weapon, m_flTimeWeaponIdle     , 0.1, LINUX_OFFSET_WEAPONS );
                    set_pdata_float( weapon, m_flNextPrimaryAttack  ,  0.05, LINUX_OFFSET_WEAPONS );
                    set_pdata_float( weapon, m_flNextSecondaryAttack, 0.1, LINUX_OFFSET_WEAPONS );
                }
            }
            case 1 :
            {
                if ( get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 2 )
                {
                    set_pdata_float( weapon, m_flTimeWeaponIdle, 0.1, LINUX_OFFSET_WEAPONS );
                }
            }
        }
    }
}

public cmdVote(player,level,cid)
{
    if(!cmd_access(player,level,cid,1) || task_exists(7845)) return PLUGIN_HANDLED

    static keys; keys = MENU_KEY_1|MENU_KEY_2
    for(new i = 0; i < 2; i++)
        g_counter[i] = 0

    static menu[MAX_USER_INFO_LENGTH]
    static len; len = format(menu,charsmax(menu),"[AMX] Gunspeed?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes")
    len += format(menu[len],charsmax(menu),"^n2. No")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_results",7845)
    return PLUGIN_HANDLED
}

public voteGunspeed(player, key)
{
    client_print(0,print_chat,"%n voted for option #%d",player,key+1)
    ++g_counter[key]
}

public vote_results()
{
    if(g_counter[0] > g_counter[1])
    {
        g_Speed =  0.01185
        set_cvar_float("mp_gunspeed", 0.01185)
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") %s is now %s", PLUGIN, VERSION, g_counter[0], g_counter[1], PLUGIN, g_Speed ? "enabled" : "disabled")
    }
    else if(g_counter[1] > g_counter[0])
    {
        g_Speed = 0.0
        set_cvar_float("mp_gunspeed",  0.0 )
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") %s is now %s", PLUGIN, VERSION, g_counter[0], g_counter[1], PLUGIN, g_Speed ? "enabled" : "disabled")
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed. No votes counted.", PLUGIN, VERSION)
    }
}

public client_infochanged(player)
{
    bAccess[player] = get_user_flags(player) & VOTE_ACCESS ? true : false
}

public plugin_end()
{
    g_Speed = 0.0

    if(XhookPrimaryAPre)
        DisableHamForward(XhookPrimaryAPre)

    if(XhookPrimaryAPos)
        DisableHamForward(XhookPrimaryAPos)

    if(XhookReloadPre)
        DisableHamForward(XhookReloadPre)

    if(XhookReloadPost)
        DisableHamForward(XhookReloadPost)
}
