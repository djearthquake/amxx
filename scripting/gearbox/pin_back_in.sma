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
#define GREN_LIMIT 10

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;
static const gWeaponClassname[] = "weapon_handgrenade";
static const SzReplySeek[] = "Seeking pin.";
static const SzReplyPin[] = "Remotely pinned grenade!";
static bool:bRepinning[MAX_PLAYERS + 1];
static bool:played[MAX_PLAYERS + 1];
static bool:hasNade[MAX_PLAYERS + 1];

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
}


public CurentWeapon(id)
{
    if(is_user_alive(id))
    {
        hasNade[id] = true
    }
}

public Weapon_PrimaryAttack_Pre( const weapon )
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

public Weapon_PrimaryAttack_Post ( const weapon )
{
    static player; player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS );
    if(is_user_alive(player))
    {
        if(!played[player])
        {
            played[player] = true
            client_cmd player, "spk weapons/saw_reload2.wav"
        }
        if(!weapon)
            played[player] = false
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public Weapon_SecondaryAttack_Pre( const weapon )
{
    static player
    player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS )

    if(!player)
        player = pev(weapon, pev_owner)
    if(is_user_alive(player))
    {
        //client_print player, print_chat, "Toss it!"
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;

}
public Weapon_SecondaryAttack_Post( const weapon )
{
    static player
    player = get_pdata_cbase( weapon, m_pPlayer, LINUX_OFFSET_WEAPONS )

    if(!player)
        player = pev(weapon, pev_owner)
    if(is_user_alive(player) && weapon > MaxClients && bRepinning[player]) 
    {
        client_print player, print_center, SzReplyPin

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
            ///set_pev(weapon, pev_dmgtime, DTime--) //make it pop on command
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
        }
        bRepinning[player] = false

        return PLUGIN_HANDLED;
    }
    bRepinning[player] = false
    return PLUGIN_CONTINUE;

} 

@repin_procedure(player_id)
{
    if(is_user_alive(player_id) && hasNade[player_id])
    {
        bRepinning[player_id] = bRepinning[player_id] ? false : true
        if(bRepinning[player_id])
        {
            client_print player_id, print_chat, SzReplySeek
            new iWeapon, clip, ammo;
            iWeapon = get_user_weapon(player_id, clip, ammo)
            if(iWeapon == HLW_HANDGRENADE)
            {
                fm_strip_user_gun(player_id, _, gWeaponClassname)
                {
                    give_item(player_id, gWeaponClassname)
                    if(ammo<=10)
                        set_pdata_int(player_id, HEGREN, ammo)
                    else 
                        set_pdata_int(player_id, HEGREN, GREN_LIMIT)
                    client_cmd player_id, "-attack"
                    client_cmd(player_id,"spk weapons/saw_reload1.wav") 
                }
            }
            else
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
    return PLUGIN_CONTINUE
}

stock timer(player)
{

}

stock _random(i)return random(i)

public client_putinserver(id)
{
    bRepinning[id] = false
}
