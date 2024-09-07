/*Automatic braking of Half-Life cars and trains in relation to team mate distance by cvar.*/

//uncomment to add purchase requirements
#define CSTRIKE

#include amxmodx

#if defined CSTRIKE
    #include cstrike
    #include hamsandwich
    new bool:g_brake_owner[MAX_PLAYERS +1], g_item_cost;
#endif

#include engine_stocks
#include fakemeta

#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

#define IDLE_SPEED 0.1
#define GO_SPEED 1200.0

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

static bool:bLoco
static m_speed
static g_mod_car[MAX_PLAYERS +1]

const LINUX_DIFF = 5;
const LINUX_OFFSET_WEAPONS = 4;

public plugin_init()
{
    register_plugin( "Auto Braking", "0.0.4", "SPiNX" );

    #if !defined MaxClients
        #define MaxClients get_maxplayers( )
    #endif

    if(find_ent(MaxClients, CARS))
    {
        bLoco = false
    }
    else if(find_ent(MaxClients, LOCO))
    {
        bLoco = true
    }
    else
    {
        pause "d"
    }

    cvar_range = register_cvar("brake_range", "250")
    m_speed = (find_ent_data_info("CFuncVehicle", "m_speed")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF

    server_print "%i trains modified!",g_fun_train
    server_print "%i paths modified!",g_path_corn

    #if defined CSTRIKE
        register_clcmd ( "buy_brakes", "buy_brakes", 0, " - Automatic brakes." );
        g_item_cost = register_cvar("brakes_cost", "2500" )
        RegisterHam(Ham_Killed, "player", "no_brakes");
    #endif
}

public client_command(id)
{
    static iRange; iRange = get_pcvar_num(cvar_range)
    if(iRange)

    #if defined CSTRIKE
        if(g_brake_owner[id])
    #endif
    is_driving(id) ?  remove_task(id) : set_task(0.1, "@brake_think", id, _,_, "b");
}

@brake_think(id)
{
    static iRange; iRange = get_pcvar_num(cvar_range)
    if(iRange)

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
                        if(get_user_team(iPlayer) == get_user_team(id))
                        {
                            static iDistance; iDistance = get_entity_distance(id, iPlayer)

                            if( iDistance < iRange)
                            {
                                bLoco ?
                                DispatchKeyValue(g_mod_car[id], WOT,0)
                                :set_pdata_float(g_mod_car[id], m_speed, IDLE_SPEED, LINUX_DIFF);
                                client_print( id, print_center, "EMERGENCY BRAKES ENGAGED!^n^n%n was nearly ran down!!", iPlayer)
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
}

public pfn_touch(ptr, ptd)
{
    static iCar; iCar = get_pcvar_num(cvar_range)

    if(iCar)
    {
        if(is_user_alive(ptr) && pev_valid(ptd))
        {
            static iPlayer;iPlayer = ptr
            if(is_driving(iPlayer))
            {
                g_mod_car[iPlayer] = ptd
            }
        }
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
                    client_print(Client, print_center, "You can't afford brakes %s!", name);
                    client_print(0, print_chat, "Hey guys %s keeps trying to buy brakes they can't afford!", name);
                    return PLUGIN_HANDLED;
                }
                else
                {
                    cs_set_user_money(Client, tmp_money - get_pcvar_num(g_item_cost));
                    g_brake_owner[Client] = true;
                    client_print(Client, print_center, "You bought brakes!");
                }

            }
            else
            {
                client_print(Client, print_center, "You ALREADY OWN a brakes...");
                client_print(0, print_chat, "Hey guys %s keeps trying to buy brakes and already owns them!", name);
            }
        }
    }
    return PLUGIN_HANDLED;
}

public no_brakes(id)
{
    g_brake_owner[id] = false
}
#endif
