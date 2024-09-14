/*Automatic braking of Half-Life cars and trains in relation to team mate distance by cvar.*/
#include amxmodx
#include fakemeta_util
#include fun

#if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM < 190
    #error Wrong Amxx version!
#endif

#define NAMED_PLUGIN "plugin.amxx"  /*add a plugin to block center chat*/
///uncomment to add purchase requirements
#define CSTRIKE

#if defined CSTRIKE
    #include cstrike
    #include hamsandwich
    new bool:bRegistered
    new bool:g_brake_owner[MAX_PLAYERS +1], g_item_cost, g_nitrous;
    static g_saytxt;
#endif

#include engine_stocks
#include fakemeta

#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

#define IDLE_SPEED 0.1
#define GO_SPEED 1200.0

//task
#define PRINTING 2024

new cvar_range;

static const CARS[]= "func_vehicle"
static const LOCO[] ="func_tracktrain"
static const TRAIN[]= "func_train"

static const CORNER[]= "path_corner"
static const BOOST[]= "yaw_speed"
static const WOT[]= "speed"
static const LIFE[]= "damage"

//Speed stages
///static const norm[]= "500"
static const fast[]= "820"
static const realfast[]= "1132"

static g_fun_train, g_path_corn

static bool:bLoco, g_score, g_deathmsg
static m_speed, g_teams, bool:bStrike, bool:bHost
new g_mod_car[MAX_PLAYERS +1]
new bool:b_Airbourne[MAX_PLAYERS +1]
new bool:bPrinting[MAX_PLAYERS +1]

const LINUX_DIFF = 5;
const LINUX_OFFSET_WEAPONS = 4;

public plugin_init()
{
    register_plugin( "Auto Braking", "1.0.3", "SPiNX" );

    #if !defined MaxClients
        #define MaxClients get_maxplayers( )
    #endif

    if(find_ent(MaxClients, CARS))
    {
        bLoco = false
        register_touch("func_vehicle", "player", "@jeep")
    }
    else if(find_ent(MaxClients, LOCO))
    {
        bLoco = true
        register_touch("func_tracktrain", "player", "@jeep")
    }
    else
    {
        pause "d"
    }
    bHost  = has_map_ent_class("hostage_entity") ? true : false;
    cvar_range = register_cvar("brake_range", "135")

    m_speed = (find_ent_data_info("CFuncVehicle", "m_speed")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF

    server_print "%i trains modified!",g_fun_train
    server_print "%i paths modified!",g_path_corn

    g_score = get_user_msgid("ScoreInfo");
    g_deathmsg = get_user_msgid("DeathMsg")

    static modname[MAX_PLAYERS];
    get_modname(modname, charsmax(modname))
    bStrike = equali(modname, "cstrike") || equali(modname, "czero") ? true : false

    g_teams            =  bStrike ? get_cvar_pointer("mp_friendlyfire") : get_cvar_pointer("mp_teamplay")

    #if defined CSTRIKE
        register_clcmd ( "buy_brakes", "buy_brakes", 0, " - Automatic brakes." )
        g_item_cost = register_cvar("brakes_cost", "500" )
        RegisterHam(Ham_Killed, "player", "no_brakes")
        g_saytxt = get_user_msgid("SayText")
        g_nitrous = (is_plugin_loaded(NAMED_PLUGIN,true)!=charsmin)
    #endif
}

@brake_think(id)
{
    static iRange; iRange = get_pcvar_num(cvar_range)
    if(iRange)

    #if defined CSTRIKE
    if(g_brake_owner[id])
    #endif

    if(is_user_alive(id))
    {
        if(is_driving(id))
        {
            for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
            {
                if(is_user_alive(iPlayer))
                {
                    if(iPlayer != id)
                    {
                        static iDistance;

                        if(bHost)
                        {
                            new  ent = MaxClients; while( (ent = find_ent(ent, "hostage_entity") ) >= ent && pev(ent, pev_health)>0.5)
                            {
                                iDistance = get_entity_distance(g_mod_car[id], ent)
                                if(iDistance < 150)
                                {
                                    goto STOP
                                }
                            }
                        }

                        iDistance = get_entity_distance(g_mod_car[id], iPlayer)

                        if(iDistance < iRange)
                        {

                            if(get_user_team(iPlayer) == get_user_team(id))
                            {
                                STOP:
                                bLoco? DispatchKeyValue(g_mod_car[id], WOT,0) :
                                set_pdata_float(g_mod_car[id], m_speed, IDLE_SPEED, LINUX_DIFF);

                                set_pev(g_mod_car[id], pev_velocity, 0)

                                if(!g_nitrous && !bPrinting[id])
                                {
                                    bPrinting[id] = true
                                    client_print(id, print_center, "EMERGENCY BRAKES ENGAGED!^n^n%n was nearly ran down!!", iPlayer)
                                    set_task(3.0, "@end_task", id+PRINTING)
                                }
                            }
                            else /*Throw enemies up in the air*/
                            {
                                static Float:Origin[3]
                                pev(iPlayer, pev_origin, Origin)
                                Origin[2] += 200.0

                                set_pev(iPlayer, pev_origin, Origin)
                                if(!b_Airbourne[iPlayer])
                                {
                                    b_Airbourne[iPlayer] = true
                                    bStrike ? set_msg_block(g_deathmsg, BLOCK_SET) : set_msg_block(g_deathmsg, BLOCK_ONCE);
                                    fakedamage(iPlayer,"vehicle",400.0,DMG_CRUSH |DMG_ALWAYSGIB)
                                    log_kill(id,iPlayer,"vehicle",1);
                                }
                            }

                        }
                        else
                        {
                            if(!bLoco)
                            {
                                set_pdata_float(g_mod_car[id], m_speed, GO_SPEED, LINUX_DIFF);
                            }
                        }
                    }
                }
            }
        }
    }
}

@end_task(Tsk)
{
    static id
    id = Tsk-PRINTING
    bPrinting[id] = false
}

@jeep(iCar, iPlayer)
{
    if(is_driving(iPlayer))
    {
        g_mod_car[iPlayer] = iCar
        @brake_think(iPlayer)
    }
}

public pfn_keyvalue( ent )
{
    static Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ];
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(containi(Classname,CORNER) > charsmin || containi(Classname,TRAIN) > charsmin || containi(Classname,LOCO) > charsmin)
    {
        if(equali(key,BOOST))
        {
            DispatchKeyValue(BOOST,realfast)
            g_path_corn++
        }
        else if(equali(key,LIFE))
            DispatchKeyValue(LIFE,"-1")

        else if(equali(key,WOT))
        {
            DispatchKeyValue(WOT,fast)
            g_fun_train++
        }
        else if(equali(key,"volume"))
            DispatchKeyValue("volume","0")///emit something else later
    }
    if(containi(Classname,"ambient_generic") > charsmin)

    if(equali(key,"message") && equali(value,"ambience/warn3.wav"))
        DispatchKeyValue("message","ambience/warn2.wav")
}

stock is_driving(iPlayer)
{
    if(is_user_alive(iPlayer))
    {
        return pev(iPlayer,pev_flags) & FL_ONTRAIN
    }
    return PLUGIN_HANDLED
}

#if defined CSTRIKE
public buy_brakes(Client)
{
    if(is_user_alive(Client))
    {
        static name[MAX_PLAYERS];

        get_user_name(Client,name,charsmax(name));

        static tmp_money; tmp_money = cs_get_user_money(Client);
        if(is_user_connected(Client))
        {
            if ( !g_brake_owner[Client] )
            {

                if(tmp_money < get_pcvar_num(g_item_cost))
                {
                    //client_print(Client, print_center, "You can't afford brakes %s!", name);
                    client_printc(Client, "!tYou !ncan't !gafford !tbrakes!n!");
                    client_print(0, print_chat, "Hey guys %s keeps trying to buy brakes they can't afford!", name);
                    return PLUGIN_HANDLED;
                }
                else
                {
                    cs_set_user_money(Client, tmp_money - get_pcvar_num(g_item_cost));
                    g_brake_owner[Client] = true;
                    //client_print(Client, print_center, "You bought brakes!");
                    client_printc(Client, "!nYou !gbought !tbrakes!n!");
                }

            }
            else
            {
                //client_print(Client, print_center, "You ALREADY OWN brakes...");
                client_printc(Client, "!nYou !nALREADY !tOWN !gbrakes!n!");
                client_print(0, print_chat, "Hey guys %s keeps trying to buy brakes and already owns them!", name);
            }
        }
    }
    return PLUGIN_HANDLED;
}

public no_brakes(id)
{
    g_brake_owner[id] = false
    if(b_Airbourne[id])
    {
        client_print 0, print_chat, "%n was killed by vehicle!", id
        b_Airbourne[id] = false
    }
}

public client_disconnected(id)
{
    no_brakes(id)
    b_Airbourne[id] = false
}

//CONDITION ZERO TYPE BOTS. SPiNX
@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity( Ham_Killed, ham_bot, "no_brakes", 1 );
        bRegistered = true;
        server_print("E-brake bot from %N", ham_bot)
    }
}

public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT") && !bRegistered)
    {
        set_task(0.1, "@register", id);
    }
}


stock client_printc(const id, const input[], any:...)
{
    new count = 1, players[MAX_PLAYERS];
    static msg[191];
    vformat(msg, charsmax(msg), input, 3);

    replace_all(msg, charsmax(msg), "!g", "^x04"); // Green Color
    replace_all(msg, charsmax(msg), "!n", "^x01"); // Default Color
    replace_all(msg, charsmax(msg), "!t", "^x03"); // Team Color

    id ? (players[0] = id) : get_players(players, count, "ch");

    for (new i = 0; i < count; i++)
    {
        emessage_begin(MSG_ONE_UNRELIABLE, g_saytxt, _, players[i]);
        ewrite_byte(players[i]);
        ewrite_string(msg);
        emessage_end();
    }
}
#endif

stock log_kill(killer, victim, weapon[], headshot)
{

    if (containi(weapon,"vehicle") > -1)
        set_msg_block(g_deathmsg, BLOCK_SET);

    static killers_team[MAX_PLAYERS], victims_team[MAX_PLAYERS];
    get_user_team(killer, killers_team, charsmax(killers_team));
    get_user_team(victim, victims_team, charsmax(victims_team));

    if(is_user_connected(killer))
    {
       //Scoring
        if(get_pcvar_num(g_teams) == 1 || bStrike )
        {

            if(!equal(killers_team,victims_team))
            {
                set_user_frags(killer,get_user_frags(killer) +1)
            }
            else //if(equal(killers_team,victims_team))
            {
                set_user_frags(killer,get_user_frags(killer) -1);
            }
        }

        else

        fm_set_user_frags(killer,get_user_frags(killer) +1);
        ///////////////////////////////////////////////////

        set_msg_block(g_deathmsg, BLOCK_SET);

        set_msg_block(g_deathmsg, BLOCK_NOT);


        emessage_begin(MSG_BROADCAST, g_deathmsg, {0,0,0}, 0);
        ewrite_byte(killer);
        ewrite_byte(victim);

        if(bStrike)
            ewrite_byte(headshot);
        if( (get_pcvar_num(g_teams) == 1 || bStrike)
        &&
        equal(killers_team,victims_team))
            ewrite_string("teammate");
        else
            ewrite_string(weapon)
        emessage_end();

        //Logging the message as seen on console.
        new kname[MAX_PLAYERS+1], vname[MAX_PLAYERS+1], kauthid[MAX_PLAYERS+1], vauthid[MAX_PLAYERS+1], kteam[10], vteam[10]

        get_user_name(killer, kname, charsmax(kname))
        get_user_team(killer, kteam, charsmax(kteam))
        get_user_authid(killer, kauthid, charsmax(kauthid))

        get_user_name(victim, vname, charsmax(vname))
        get_user_team(victim, vteam, charsmax(vteam))
        get_user_authid(victim, vauthid, charsmax(vauthid))

        log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
        kname, get_user_userid(killer), kauthid, kteam,
        vname, get_user_userid(victim), vauthid, vteam, weapon)
        pin_scoreboard(killer);
    }

}

public pin_scoreboard(killer)
{
    if(is_user_connected(killer))
    {
        emessage_begin(MSG_BROADCAST,g_score)
        ewrite_byte(killer);
        ewrite_short(get_user_frags(killer));

        if(bStrike)
        {
            ewrite_short(get_user_deaths(killer));
            ewrite_short(0); //TFC CLASS
            ewrite_short(get_user_team(killer));
        }
        else
        {
            #define DEATHS 422
            static dead; dead = get_pdata_int(killer, DEATHS)
            ewrite_short(dead);
        }
        emessage_end();
    }

}
