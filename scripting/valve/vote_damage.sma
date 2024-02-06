#include amxmodx
#include amxmisc
#include fakemeta
#include hamsandwich

#define PLUGIN "HL:DAMAGE ADJ"
#define VOTE_ACCESS     ADMIN_ALL
#define DAMAGE_LEVEL ADMIN_LEVEL_F
#define VERSION "1.0"

new const CvarXMultiplerDesc[]="Damage multiplier"
new const CvarXBotDesc[]="Bot Damage"
new const szSND[]="vox_login.wav"

new Float:XMultipler, XBotDamage, g_Adm, g_AI;
new votekeys = (1<<0)|(1<<1)
new g_counter[2];

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, ".sρiηX҉.");
    register_concmd("vote_botdamage","cmdVoteBot",VOTE_ACCESS,": Vote to reduce bot damage to you!");
    register_concmd("vote_damage","cmdVoteDamage",VOTE_ACCESS,": Vote to change damage to you!");
    RegisterHam(Ham_TakeDamage, "player", "Event_Damage", 0);

    bind_pcvar_float(get_cvar_pointer("mp_damage_multiplier") ?
    get_cvar_pointer("mp_damage_multiplier") :
    create_cvar("mp_damage_multiplier", "1.0", FCVAR_SERVER, CvarXMultiplerDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 10.0), XMultipler)

    bind_pcvar_num(get_cvar_pointer("mp_damage_from_bots") ?
    get_cvar_pointer("mp_damage_from_bots") :
    create_cvar("mp_damage_from_bots", "1", FCVAR_SERVER, CvarXBotDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), XBotDamage)

    register_menucmd(register_menuid("Bot_Damage?"),votekeys,"voteCount");
    register_menucmd(register_menuid("Damage_adjustment"),votekeys,"voteCount");
}

public voteCount(player, key)
{
    server_print "Being accessed!"
    client_print(0,print_chat,"%n voted for option #%d",player,key+1)
    ++g_counter[key];
}

public Event_Damage(victim, inflictor, attacker, Float:fDamage, dmgbits)
{
    if(is_user_connected(attacker))
    {
        #define DAMAGE       4
        new Float:Damage_adj  = fDamage*XMultipler;

        static szClass[MAX_NAME_LENGTH];
        pev(inflictor, pev_classname, szClass, charsmax(szClass))
        //client_print attacker, print_center, "%s", szClass
        if( dmgbits != DMG_FALL )
        {
            if(!XMultipler || CheckPlayerBit(g_AI, attacker) && CheckPlayerBit(g_Adm, victim) || !XBotDamage && CheckPlayerBit(g_AI, attacker) && equali(szClass,"player"))
                return HAM_SUPERCEDE
            else
                SetHamParamFloat(DAMAGE, Damage_adj)
            client_print attacker, print_center, "%i", floatround(Damage_adj)
        }
        else return HAM_IGNORED
    }
    return PLUGIN_HANDLED

}

public client_putinserver(id)
{
    client_infochanged(id)
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        get_user_flags(id) & DAMAGE_LEVEL ? (SetPlayerBit(g_Adm, id)) : (ClearPlayerBit(g_Adm, id))
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
    }
}

public cmdVoteBot(player,level,cid)
{
    if(!is_user_connected(player))
        return PLUGIN_HANDLED

    if(!cmd_access(player,level,cid,1))
    {
        client_print(player,print_chat,"You do not have access to %s vote!",PLUGIN)
        return PLUGIN_HANDLED
    }

    if(task_exists(1845))
    {
        client_print(player,print_chat,"%s vote already in progress!",PLUGIN)
        return PLUGIN_HANDLED
    }

    new keys = MENU_KEY_1|MENU_KEY_2
    for(new i = 0; i < 2; i++)
        g_counter[i] = 0

    new menu[MAX_USER_INFO_LENGTH]

    new len; len = format(menu,charsmax(menu),"[AMX] Bot_Damage?^n")

    len += format(menu[len],charsmax(menu),"^n1. Yes")
    len += format(menu[len],charsmax(menu),"^n2. No")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_bot_results",1845)
    return PLUGIN_HANDLED
}

public vote_bot_results()
{
    if(g_counter[0] > g_counter[1])
    {
        XBotDamage = 1
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") Bot damage is now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], XBotDamage? "enabled" : "disabled")
    }
    else if(g_counter[1] > g_counter[0])
    {
        XBotDamage = 0
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") Bot damage is now %s.", PLUGIN, VERSION, g_counter[0], g_counter[1], XBotDamage ? "enabled" : "disabled")
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed. No votes counted.", PLUGIN, VERSION)
        client_cmd 0, "spk ^"%s^"", szSND
    }
}

public cmdVoteDamage(player,level,cid)
{
    if(!is_user_connected(player))
        return PLUGIN_HANDLED

    if(!cmd_access(player,level,cid,1))
    {
        client_print(player,print_chat,"You do not have access to %s vote!",PLUGIN)
        return PLUGIN_HANDLED
    }

    if(task_exists(1845))
    {
        client_print(player,print_chat,"%s vote already in progress!",PLUGIN)
        return PLUGIN_HANDLED
    }

    new keys = MENU_KEY_1|MENU_KEY_2
    for(new i = 0; i < 2; i++)
        g_counter[i] = 0

    new menu[MAX_USER_INFO_LENGTH]

    new len; len = format(menu,charsmax(menu),"[AMX] Damage_adjustment?^n")

    len += format(menu[len],charsmax(menu),"^n1. More damage")
    len += format(menu[len],charsmax(menu),"^n2. Less damage")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_damage_results",1845)
    return PLUGIN_HANDLED
}

public vote_damage_results()
{
    if(g_counter[0] > g_counter[1])
    {
        XMultipler = 2.0
        client_print(0,print_chat,"[%s %s] Voting for double damage successful (yes ^"%d^") (no ^"%d^")", PLUGIN, VERSION, g_counter[0], g_counter[1])
    }
    else if(g_counter[1] > g_counter[0])
    {
        XMultipler = 0.5
        client_print(0,print_chat,"[%s %s] Voting for half damage successful (yes ^"%d^") (no ^"%d^")", PLUGIN, VERSION, g_counter[0], g_counter[1])
    }
    else
    {
        client_print(0,print_chat,"[%s %s] Voting failed. No votes counted.^nDamage normalized.", PLUGIN, VERSION)
        XMultipler = 1.0
    }
}
