//https://github.com/ValveSoftware/halflife/blob/master/dlls/handgrenade.cpp
//https://github.com/ValveSoftware/halflife/blob/master/dlls/ggrenade.cpp

#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#define PLUGIN  "Put pin back Grenade"
#define VERSION "1.0.0"
#define AUTHOR "SPiNX"
#define HEGREN 364

#define MAX_PLAYERS 32

//If using customs sounds they will need to be placed into precache function.
static const SzPinSound[] = "spk weapons/dryfire1.wav"  //saw_reload1.wav
static const SzPinSound2[] ="spk weapons/weapondrop1.wav"  //saw_reload2.wav

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
static const gWeaponClassname[] = "weapon_handgrenade";
static const SzReplySeek[] = "Seeking pin.";
static const SzReplyRem[] = "Seeking remote.";
static const SzReplyPin[] = "Remotely pinned grenade!";
static const SzReplyPop[] = "Remotely fired grenade!";
static bool:bRepinning[MAX_PLAYERS + 1];
static bool:played[MAX_PLAYERS + 1];
static bool:hasNade[MAX_PLAYERS + 1];
new g_grenade_prime;
new iGrenades[MAX_PLAYERS +1];

static m_pPlayer;

public plugin_init()
{
    register_plugin( PLUGIN, VERSION, AUTHOR )
    //RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_PrimaryAttack_Pre" , 0 )
    RegisterHam( Ham_Weapon_PrimaryAttack  , gWeaponClassname, "Weapon_PrimaryAttack_Post", 1 )
    //RegisterHam( Ham_Weapon_SecondaryAttack  , gWeaponClassname, "Weapon_SecondaryAttack_Pre" , 0 )
    RegisterHam( Ham_Weapon_SecondaryAttack  , gWeaponClassname, "Weapon_SecondaryAttack_Post", 1 )
    m_pPlayer = (find_ent_data_info("CBasePlayerItem", "m_pPlayer") / LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    register_concmd("repin_grenade","@repin_procedure", 0, "Unprime grenade")
    register_event("CurWeapon", "CurentWeapon", "bce", "1=HLW_HANDGRENADE");
    g_grenade_prime = register_cvar("grenade_prime_type", "1")
}


public CurentWeapon(id)
{
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        if(is_user_alive(id))
        {
            hasNade[id] = true
        }
    }
}

public Weapon_PrimaryAttack_Pre( const weapon )
{
    static player
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS )
    
        if(!player)
            player = pev(weapon, pev_owner)
        if(is_user_alive(player))
        {
            return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}

public Weapon_PrimaryAttack_Post ( const weapon )
{
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
        if(is_user_alive(player))
        {
            iGrenades[player] = get_pdata_int(player, HEGREN)
            if(iGrenades[player] == 1)
                iGrenades[player] = 0;
            
            if(!played[player])
            {
                played[player] = true
                client_cmd player, SzPinSound2
            }
            if(!weapon)
                played[player] = false
            return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}

public Weapon_SecondaryAttack_Pre( const weapon )
{
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        static player
        player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS )
    
        if(!player)
            player = pev(weapon, pev_owner)
        if(is_user_alive(player))
        {
            return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}
public Weapon_SecondaryAttack_Post( const weapon )
{
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        static player
        player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS )
    
        if(!player)
            player = pev(weapon, pev_owner)
        if(is_user_alive(player) && weapon > MaxClients && bRepinning[player]) 
        {
            client_print player, print_center, iPrime_type > 3 ? SzReplyPop:SzReplyPin
            iGrenades[player] = get_pdata_int(player, HEGREN)
    
            static model[MAX_PLAYERS]
            static weapon; weapon = get_grenade_id(player, model, charsmax(model), MaxClients);
            if(weapon)
            {
                switch(_random(2))
                {
                    case 0: client_cmd(player,"spk weapons/357_cock1.wav")
                    case 1: client_cmd(player,"spk weapons/cbar_miss1.wav")
                }
                new DTime; DTime = pev(weapon, pev_dmgtime)
                if(iPrime_type>3)
                {
                    set_pev(weapon, pev_dmgtime, DTime--) //make it pop on command
                    goto END
                }
                if(DTime)
                {
                    set_pev(weapon, pev_dmgtime, DTime-20)
                }
                new TTime= pev(weapon, pev_nextthink)
                if(TTime)
                 set_pev(weapon, pev_nextthink, TTime-10)
                else
                    set_pev(weapon, pev_nextthink, TTime+100)
                call_think(weapon)
                remove_entity(weapon)
                played[player] = false
            }
            bRepinning[player] = false
    
            return PLUGIN_HANDLED;
        }
        END:
        bRepinning[player] = false
        played[player] = false
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;

} 

@repin_procedure(player_id)
{
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        if(is_user_alive(player_id))
        {
            iGrenades[player_id] = get_pdata_int(player_id, HEGREN)
            if( !iPrime_type && hasNade[player_id] || iPrime_type )
            {
                bRepinning[player_id] = bRepinning[player_id] ? false : true
                if(bRepinning[player_id])
                {
                    client_print player_id, print_chat, iPrime_type > 3 ? SzReplyRem:SzReplySeek

                    new iWeapon, clip, ammo;
                    iWeapon = get_user_weapon(player_id, clip, ammo)
    
                    if(iWeapon == HLW_HANDGRENADE && iPrime_type|| iWeapon != HLW_HANDGRENADE && iPrime_type == 2|| iPrime_type == 3)
                    {
                        fm_strip_user_gun(player_id, _, gWeaponClassname)
                        if(iGrenades[player_id])
                        {
                            give_item(player_id, gWeaponClassname)
                            set_pdata_int(player_id, HEGREN,  iGrenades[player_id])
                        }
    
                        if(iWeapon == HLW_HANDGRENADE)
                            played[player_id] = false
    
                        client_cmd player_id, "-attack"
                        client_cmd(player_id, SzPinSound) 
                    }
                    else if(iPrime_type)
                    {
                        hasNade[player_id] = false
                    }
    
                }
                else
                {
                    client_print player_id, print_chat, "Dropping pin"
                }
                return PLUGIN_HANDLED
            }

        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED;
}

stock timer(player)
{

}

stock _random(i)return random(i)

public client_putinserver(id)
{
    static iPrime_type; iPrime_type = get_pcvar_num(g_grenade_prime);
    if(iPrime_type)
    {
        bRepinning[id] = false
    }
    return PLUGIN_HANDLED;
}
