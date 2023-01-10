#include <amxmodx>
#include <amxmisc>
#include <engine_stocks>
#include <fakemeta>
#include <gearbox>
#include <hamsandwich>
#include <xs>

#define charsmin                  -1
#define ACCESS_LEVEL    ADMIN_USER|ADMIN_CFG //ADMIN_LEVEL_A
#define VOTE_ACCESS     ADMIN_ALL

#define NO_RECOIL_WEAPONS_BITSUM  (1<<1 | 1<<HLW_HANDGRENADE | 1<<HLW_TRIPMINE | 1<<HLW_SATCHEL | 1<<HLW_SNARK | 1<<HLW_GRAPPLE | 1<<HLW_PIPEWRENCH  | 1<<HLW_KNIFE | 1<<HLW_PENGUIN )


const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;

#define	CART_PARABELUM	356
#define	SHOTGUN_SHELLS	355
#define	CART_RIFLE	370
#define	CART_MAG	358
#define	CART_U	359
#define	CART_BOLT	361
#define	CART_SUB	367

#define	MAG_CONTENDER	1
#define	MAG_CALIFORNIA	5
#define	MAG_POKER	10
#define	MAG_COP	16
#define	MAG_DRUM	100
#define	MAG_BOX	255
#define	MAG_ARSEN	1000

#define PLUGIN  "Gun Speed"
#define VERSION "1.0.2"
#define AUTHOR "SPiNX"
/* VARIABLES */

new
    cl_weapon[MAX_PLAYERS + 1],
    gbCS ,
    gbDod ,
    gbSven ,
    gOldClip[ MAX_PLAYERS + 1 char ],
    gOldSpecialReload[ MAX_PLAYERS + 1 char ],
    g_counter[2],
    m_pPlayer ,
    //m_flPumptime ,
    m_fInSpecialReload ,
    m_flNextPrimaryAttack ,
    m_flNextSecondaryAttack ,
    m_flTimeWeaponIdle ,
    m_iClip,
    m_flNextAttack,
    Float:g_Speed,
    gWeaponClassname[MAX_PLAYERS],
    pcvars[HLW_SNIPER + 1];

new const SzAmmo[][]={"ammo_9mmclip", "ammo_9mmbox", "ammo_gaussclip", "ammo_357", "ammo_crossbow", "ammo_buckshot", "ammo_556", "ammo_762"}

new HamHook:XhookReloadPre, HamHook:XhookReloadPost, HamHook:XhookPrimaryAPre, HamHook:XhookPrimaryAPos;

new bool:bAccess[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin( PLUGIN, VERSION, AUTHOR );
    register_concmd("vote_gunspeed","cmdVote",VOTE_ACCESS,": Vote for gun speed!")

    for (new i=HLW_GLOCK;i<=HLW_SNIPER;i++)
    {
        if(!(NO_RECOIL_WEAPONS_BITSUM & (1<<i)) && get_weaponname(i, gWeaponClassname, charsmax(gWeaponClassname)))
        {
            new cvar_name[MAX_PLAYERS + 1];
            formatex(cvar_name, charsmax(cvar_name), "gunspeed_%s", gWeaponClassname)
            replace(cvar_name, charsmax(cvar_name), "weapon_", "")
            pcvars[i] = register_cvar(cvar_name,"0.0")
            pcvars[0] = register_cvar("gunspeed_mode","1")
            pcvars[9] = register_cvar("gunspeed_all","1.0")

            new mod_name[MAX_NAME_LENGTH]
            get_modname(mod_name, charsmax(mod_name))
            server_print mod_name
            if(equal(mod_name, "cstrike") || equal(mod_name, "czero") )
            {
                gbCS = true
            }
            else if(equal(mod_name, "dod"))
            {
                gbDod = true
            }
            else if(containi(mod_name, "sven") > charsmin)
            {
                gbSven = true
            }
            if(gbSven)
            {
                //m_fInSpecialReload = (find_ent_data_info("CBasePlayerWeapon", "SpecialReload") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
                //SpecialReloadEiifi
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

    bind_pcvar_float(get_cvar_pointer("mp_gunspeed") ? get_cvar_pointer("mp_gunspeed") : register_cvar("mp_gunspeed", "0.0"), g_Speed)
    //RegisterHam(Ham_Spawn, "player", "@spawn", 1);
    register_event_ex ( "ResetHUD" , "@spawn" , .flags=RegisterEvent_Single|RegisterEvent_OnlyAlive|RegisterEvent_OnlyHuman )
    register_event("CurWeapon", "event_active_weapon", "b")
    RegisterHam(Ham_Killed, "player", "@death", 1);
    for( new map;map < sizeof SzAmmo;++map)
    {
        remove_entity_name(SzAmmo[map])
    }
    register_menucmd(register_menuid("Gunspeed?"),MENU_KEY_1|MENU_KEY_2,"voteGunspeed")
}

public event_active_weapon(player)
{
    cl_weapon[player] = read_data(2)
    return PLUGIN_CONTINUE
}

@death(victim,killer)
{
    @spawn(killer)
}

@spawn(player)
{
    if(is_user_connected(player) && g_Speed > 0.0 && bAccess[player])
    {
        if(XhookPrimaryAPre)
            EnableHamForward(XhookPrimaryAPre)

        if(XhookPrimaryAPos)
            EnableHamForward(XhookPrimaryAPos)

        if(XhookReloadPre)
            EnableHamForward(XhookReloadPre)

        if(XhookReloadPost)
            EnableHamForward(XhookReloadPost)
    
        server_print "%n spawned gunspeed ammo", player
        set_pdata_int( player, CART_PARABELUM, MAG_BOX )
        set_pdata_int( player, SHOTGUN_SHELLS, MAG_BOX )
        set_pdata_int( player, CART_RIFLE, MAG_DRUM )
        set_pdata_int( player, CART_MAG, MAG_ARSEN)
        set_pdata_int( player, CART_U, MAG_DRUM )
        set_pdata_int( player, CART_BOLT, MAG_DRUM )
        set_pdata_int( player, CART_SUB, MAG_DRUM )
    }
    else if(!g_Speed)
        plugin_end()
}

public Weapon_PrimaryAttack_Pre ( const weapon )
{
    if(g_Speed > 0.0)
    {
        new player
        player = gbSven ? pev(weapon, pev_owner) : get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        //player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        gOldClip{ player } = get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS );

        if ( gOldClip{ player } <= 0 ||!bAccess[player])
        {
            return;
        }
        //if recoil
        new Float:cl_pushangle[MAX_PLAYERS + 1][3]
        pev(player,pev_punchangle,cl_pushangle[player])

        new Float:push[3]
        pev(player,pev_punchangle,push)
        xs_vec_sub(push,cl_pushangle[player],push)

        xs_vec_mul_scalar(push,0.0,push)
        xs_vec_add(push,cl_pushangle[player],push)
        set_pev(player,pev_punchangle,push)
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
        //new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        new player = gbSven ? pev(weapon, pev_owner) : get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

        switch(get_pcvar_num(pcvars[0]))
        {
            case 1:
            {
                if(get_pcvar_float(pcvars[cl_weapon[player]]))
                    goto CHAOS
            }
            case 2:
            {
                if(get_pcvar_float(pcvars[9]))
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

        set_pdata_float( weapon, m_flNextPrimaryAttack,  g_Speed*5, LINUX_OFFSET_WEAPONS );

        if ( get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS ) != 0 )
        {
            set_pdata_float( weapon, m_flTimeWeaponIdle,  g_Speed*3, LINUX_OFFSET_WEAPONS );
        }
        else
        {
            set_pdata_float( weapon, m_flTimeWeaponIdle,  g_Speed, LINUX_OFFSET_WEAPONS );
        }

        if(gbCS)
            return

        new Float:g_fDelay = 0.01
        #define m_flNextPrimaryAttackB 46
        #define m_flNextSecondaryAttackB 47

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
    new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldClip{ player } = get_pdata_int( weapon, m_iClip, LINUX_OFFSET_WEAPONS );
}

public Weapon_SecondaryAttack_Post ( const weapon )
{
    if(g_Speed > 0.0)
    {
        new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

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
    new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    gOldSpecialReload{ player } = get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS );
}

public Weapon_Reload_Post ( const weapon )
{
    if(g_Speed > 0.0)
    {
        new player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );

        if(gOldSpecialReload{ player } <= 0  || !bAccess[ player ])
            return

        switch ( gOldSpecialReload{ player } )
        {
            case 0 :
            {
                if ( get_pdata_int( weapon, m_fInSpecialReload, LINUX_OFFSET_WEAPONS ) == 1 )
                {
                    set_pdata_float( player , m_flNextAttack, 0.3 );

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
    else
        plugin_end()
}

public cmdVote(player,level,cid) 
{
    if(!cmd_access(player,level,cid,1) || task_exists(7845)) return PLUGIN_HANDLED

    new keys = MENU_KEY_1|MENU_KEY_2
    for(new i = 0; i < 2; i++)
        g_counter[i] = 0

    new menu[MAX_USER_INFO_LENGTH]

    //new len = format(menu,charsmax(menu),"[AMX] %s Gunspeed?^n", g_Speed ? "Disable" : "Enable")
    new len = format(menu,charsmax(menu),"[AMX] Gunspeed?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes")
    len += format(menu[len],charsmax(menu),"^n2. No")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_results",7845)
    return PLUGIN_HANDLED
}

public voteGunspeed(player, key)
    g_counter[key]++

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
    bAccess[player] = get_user_flags(player) & ACCESS_LEVEL ? true : false
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