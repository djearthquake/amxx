#include amxmodx
#include amxmisc
#include cstrike
#include engine
#include fakemeta
#include fakemeta_util
#include fun

#define MAX_NAME_LENGTH 32
#define MAX_PLAYERS     32
#define MAX_CMD_LENGTH 128
#define charsmin        -1
#define iCOLOR random_num(1,255)
#define JEEP 7594

static const prefix[] = { "!g[!tGarage!g]!n" }

new iArmor[MAX_PLAYERS +1], g_mod_car[MAX_PLAYERS + 1],
g_owned_car[MAX_PLAYERS][4], g_price_fuel, g_saytxt,
bool:bSet[MAX_PLAYERS + 1], bool:bRegisteredCar[MAX_PLAYERS + 1], iVehicular[MAX_PLAYERS + 1]

static const CARS[]= "func_vehicle"
static m_acceleration, m_speed, m_flVolume;

//Stages
#define IDLE_SPEED 250.0
#define NORM_SPEED 650.0
#define FAST_SPEED 1300.0
#define REALFAST_SPEED 1500.0
#define DRAG_SPEED 1900.0

//Super-chargers
#define BLOWER1 9
#define BLOWER2 11
#define BLOWER3 15
static g_hotroded, g_kills, g_iNitrous, g_sprite, g_brakes

const LINUX_DIFF = 5;
const LINUX_OFFSET_WEAPONS = 4;
public plugin_precache(){g_sprite = precache_model("sprites/smoke.spr");}
public plugin_init()
{
    register_plugin("Jeep Nitrous", "1.62", ".sρiηX҉.");

    if(!find_ent(MaxClients, CARS))
    {
        pause "d"
    }
    g_saytxt = get_user_msgid("SayText")
    register_touch("player","func_vehicle","fn_shield_proximity2")

    register_clcmd("say /nos", "@nos", 0, "- say /nos for Car Mods!" , 0)
    register_clcmd("say_team /nos", "@nos")

    register_event("ScoreInfo", "plugin_log", "bc", "1=committed suicide with", "2=vehicle");
    register_logevent("round_start", 2, "1=Round_Start")
    g_iNitrous = register_cvar("jeep_nitrous", "1")
    bind_pcvar_num(get_cvar_pointer("jeep_fuel") ? get_cvar_pointer("jeep_fuel") : register_cvar("jeep_fuel", "15"), g_price_fuel)
    m_acceleration = (find_ent_data_info("CFuncVehicle", "m_acceleration")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF
    m_speed = (find_ent_data_info("CFuncVehicle", "m_speed")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF
    m_flVolume = (find_ent_data_info("CFuncVehicle", "m_flVolume") /LINUX_OFFSET_WEAPONS) - LINUX_DIFF

    g_brakes = (is_plugin_loaded("emergency_brakes.amxx",true)!=charsmin)
}

public pfn_touch(ptr, ptd)
{
    static iCar; iCar = get_pcvar_num(g_iNitrous)
    if(g_iNitrous && iCar)
    {
        if(is_user_alive(ptr) && pev_valid(ptd) > 1)
        {
            static iPlayer;iPlayer = ptr
            if(is_driving(iPlayer))
            {
                g_mod_car[iPlayer] = ptd
                set_pev(g_mod_car[iPlayer], pev_owner, iPlayer + 50)
                bSet[iPlayer] = true
            }
            else
                set_pev(g_mod_car[iPlayer], pev_owner, 0)
        }
    }
}

public plugin_log()
{
    new szDummy[ MAX_PLAYERS ];
    read_logargv(2,szDummy, charsmax(szDummy))
    if(containi(szDummy, "vehicle") != charsmin)
    {
        new victim = get_loguser_index()
        new iOwner = pev(iVehicular[victim], pev_owner) - 50
        if(is_user_connected(iOwner))
        {
            client_print iOwner, print_chat, "%n ran down %n!", iOwner, victim
            if(get_user_team(iOwner) != get_user_team(victim))
            {
                set_user_frags(iOwner, get_user_frags(iOwner) +1)
                cs_set_user_money(iOwner, cs_get_user_money(iOwner)  + 1500)
            }
            else
            {
                set_user_frags(iOwner, get_user_frags(iOwner) -2)
                cs_set_user_money(iOwner, cs_get_user_money(iOwner)  -  2500)
            }
        }
        g_kills++
    }
}
stock get_loguser_index() {
new loguser[80], name[MAX_PLAYERS]
read_logargv(0, loguser, charsmax(loguser))
parse_loguser(loguser, name, charsmax(name))
return get_user_index(name);
}

public round_start()
{
    for(new iPlayer = 1 ; iPlayer <= MaxClients ; ++iPlayer)
    {
        if(is_user_connected(iPlayer))
        {
            if(bSet[iPlayer])
            {
                bSet[iPlayer] = false
                ///g_mod_car[iPlayer] = 0;

                set_ent_rendering(iPlayer, kRenderNormal, 0, 0, 0, kRenderNormal, 0)
                if(g_mod_car[iPlayer] && pev_valid(g_mod_car[iPlayer]) > 1)
                {
                    set_ent_rendering(g_mod_car[iPlayer], kRenderNormal, 0, 0, 0, kRenderNormal, 0)
                    @Nitrous(iPlayer)
                }
            }
        }
    }
    if(task_exists(JEEP))
    {
        remove_task(JEEP)
    }
    if(g_iNitrous && get_pcvar_num(g_iNitrous))
    set_task(0.1, "driving_think", JEEP, _,_,"b")
    if(g_hotroded)
    {
        client_print 0, print_chat, "%i car mods made!", g_hotroded
        g_hotroded = 0
    }
    if(g_kills)
    {
        client_print 0, print_chat, "%i car kills last round...", g_kills
        g_kills = 0
    }
}

public driving_think()
{
    new iCar = get_pcvar_num(g_iNitrous)
    if(g_iNitrous && !iCar && task_exists(JEEP))
    {
        remove_task(JEEP)
    }

    for(new iPlayer = 1 ; iPlayer <= MaxClients ; ++iPlayer)
    {
        ///if(bRegisteredCar[iPlayer])
        {
            if(is_user_alive(iPlayer) && g_mod_car[iPlayer] && pev_valid(g_mod_car[iPlayer] > 1))
            {
                new iRColor1 = random(255), iRColor2 = random(255), iRColor3 = random(255)

                iArmor[iPlayer] = get_user_armor(iPlayer);
                if(is_driving(iPlayer))
                {
                    static tmp_money; tmp_money = cs_get_user_money(iPlayer)
                    if(tmp_money > g_price_fuel)
                    {
                        if(iArmor[iPlayer] < 200.0)
                        {
                            //set_pev(iPlayer, pev_armortype, 2)
                            entity_set_float(iPlayer, EV_FL_armorvalue, float(iArmor[iPlayer])+1.0);
                            if(is_user_alive(iPlayer))
                            {
                                set_ent_rendering(iPlayer, kRenderFxGlowShell, iRColor2, iRColor3, iRColor1, kRenderGlow, 5);
                                if(g_mod_car[iPlayer] && pev_valid(g_mod_car[iPlayer] > 1))
                                {
                                    set_ent_rendering(g_mod_car[iPlayer], kRenderFxNone, iRColor1, iRColor2, iRColor3, kRenderTransColor, 75);
                                    if(is_user_admin(iPlayer))
                                    {
                                        static Accel; Accel = get_pdata_int(g_mod_car[iPlayer], m_acceleration, LINUX_DIFF);
                                        static fSpeed; fSpeed = get_pdata_int(g_mod_car[iPlayer], m_speed, LINUX_DIFF);
                                        static Float:fVol; fVol = get_pdata_float(g_mod_car[iPlayer], m_flVolume, LINUX_DIFF);
                                        if(!g_brakes)
                                        {
                                            client_print iPlayer, print_center, "%f|%i|%f", fSpeed, Accel, fVol //max
                                        }
                                    }
                                }
                            }
                        }
                        cs_set_user_money(iPlayer, tmp_money - g_price_fuel)
                    }
                    else
                    {
                        set_pdata_float(g_mod_car[iPlayer], m_speed, IDLE_SPEED, LINUX_DIFF);
                        //client_printc(iPlayer, "%s You !gare !n!tlow !non !gfuel!n!", prefix);
                        client_print iPlayer, print_center, "LOW ON FUEL!"
                    }
                }
                else if(!is_driving(iPlayer))
                {
                    if(iArmor[iPlayer] > 100.0)
                        entity_set_float(iPlayer, EV_FL_armorvalue, float(iArmor[iPlayer])-1.0);

                    set_ent_rendering(iPlayer, kRenderNormal, 0, 0, 0, kRenderNormal, 0)
                    if(g_mod_car[iPlayer] && pev_valid(g_mod_car[iPlayer] > 1))
                    {
                        set_ent_rendering(g_mod_car[iPlayer], kRenderNormal, 0, 0, 0, kRenderNormal, 0)
                    }
                }
            }
        }
    }
}

stock is_driving(iPlayer)
{
    if(is_user_connected(iPlayer))
    {
        return pev(iPlayer,pev_flags) & FL_ONTRAIN
    }
    return PLUGIN_HANDLED
}

@Nitrous(id)
{
    if(is_user_connecting(id) ||  is_user_bot(id))return;
    if(is_user_connected(id))
    {
        new Float:xTex
        xTex = -1.0
        new Float:yTex
        yTex = -1.0
        new Float:fadeInTime = 0.5;
        new Float:fadeOutTime = 1.5;
        new Float:holdTime = 1.5;
        new Float:scanTime = 1.7;
        new effect = 2;

        emessage_begin ( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id )
        ewrite_byte(TE_TEXTMESSAGE);
        ewrite_byte(0);      //(channel)
        ewrite_short(FixedSigned16(xTex,1<<13));  //(x) -1 = center)
        ewrite_short(FixedSigned16(yTex,1<<13));  //(y) -1 = center)
        ewrite_byte(effect);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
        ewrite_byte(0);  //(red) - text color
        ewrite_byte(255);  //(green)
        ewrite_byte(64);  //(blue)
        ewrite_byte(200);  //(alpha)
        ewrite_byte(255);  //(red) - effect color
        ewrite_byte(0);  //(green)
        ewrite_byte(0);  //(blue)
        ewrite_byte(25);  //(alpha)
        ewrite_short(FixedUnsigned16(fadeInTime,1<<8));
        ewrite_short(FixedUnsigned16(fadeOutTime,1<<8));
        ewrite_short(FixedUnsigned16(holdTime,1<<8));
        if (effect == 2)
            ewrite_short(FixedUnsigned16(scanTime,1<<8));
        //[optional] ewrite_short(fxtime) time the highlight lags behing the leading text in effect 2
        ewrite_string("Nitrous  ☄☄☄  shot..."); //(text message) 512 chars max string size
        emessage_end();
    }
}

public fn_shield_proximity2(iPlayer,iCar)
{
    if(is_user_alive(iPlayer) /*&& !is_user_bot(iPlayer)*/) ///bots and czero running
    //FATAL ERROR (shutting down): Tried to create a message with a bogus message type ( 0 ) ???
    {
        iVehicular[iPlayer] = iCar
        emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, iCar)
        ewrite_byte(TE_BEAMRING)
        ewrite_short(iPlayer)
        ewrite_short(iCar)
        ewrite_short(g_sprite)
        ewrite_byte(10)  //starting frame
        ewrite_byte(1) //rate
        ewrite_byte(random_num(1,6)) //life
        ewrite_byte(random_num(5,50)) //width
        ewrite_byte(random_num(1,100)) //amp
        ewrite_byte(iCOLOR)  //Red
        ewrite_byte(iCOLOR) //Green
        ewrite_byte(iCOLOR) //blue
        ewrite_byte(random_num(1,5)) //bright
        ewrite_byte(1) //speed
        emessage_end();
    }
    return PLUGIN_HANDLED;
}

stock FixedSigned16( Float:value, scale )
// Converts floating-point number to signed 16-bit fixed-point representation
{
    new Output;
    Output = floatround( value * scale )

    if ( Output > 3276 )
        Output = 32767
    if ( Output < -32768 )
        Output = -32768;

    return  Output;
}
stock FixedUnsigned16( Float:value, scale )
// Converts floating-point number to unsigned 16-bit fixed-point representation
{
    new Output;
    Output = floatround( value * scale )

    if ( Output < 0 )
        Output = 0;
    if ( Output > 0xFFFF )
        Output = 0xFFFF;

    return  Output;
}

public @nos(id)
{
    if(!is_user_alive(id))
    {
        client_printc(id, "%s You !gmust !nbe !talive !nto !topen !nthe !gGarage!n!", prefix);
        return PLUGIN_HANDLED
    }
    @The_garage(id);
    return PLUGIN_HANDLED;
}

@The_garage(id)
{
    if(!is_user_alive(id))
    {
        client_printc(id, "%s You !gmust !nbe !talive !nto !topen !nthe !gGarage!n!", prefix);
        return PLUGIN_HANDLED
    }
    if(!is_driving(id) || !g_mod_car[id])
    {
        client_printc(id, "%s You !gmust !n !town !ncar !tor !nbe !gdriving!n!", prefix);
        return PLUGIN_HANDLED
    }
    new menu = menu_create("The Car Garage", "shop_cars");

    menu_additem(menu, "Blower   [$1000] ", "1", 0);
    menu_additem(menu, "Gears     [$2500] ", "2", 0);
    menu_additem(menu, "Muffler  [$1500] ", "3", 0);
    menu_additem(menu, "Nitrous  [$1500] ", "4", 0);
    menu_additem(menu, "Turbo     [$500] ", "5", 0);

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);

    return PLUGIN_HANDLED
}

public shop_cars(id, menu, item)
{
    if(!is_user_alive(id))
    {
        client_printc(id, "%s You !gmust !nbe !talive !nto !topen !nthe !gGarage!n!", prefix);
        return PLUGIN_HANDLED
    }

    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[6], iName[64];
    new access, callback;
    menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

    new key = str_to_num(data);
    new tmp_money = cs_get_user_money(id)

    switch(key)
    {
        case 1:
        {
            if(tmp_money < 1000)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix);
                return PLUGIN_HANDLED;
            }
            cs_set_user_money(id, tmp_money - 1000)
            set_pdata_int(g_mod_car[id], m_acceleration, BLOWER2, LINUX_DIFF);
            set_pdata_float(g_mod_car[id], m_speed, FAST_SPEED, LINUX_DIFF);
            client_printc(id, "%s You bought !gBlower", prefix);
            g_hotroded++
        }
        case 2:
        {
            if(tmp_money < 2500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix);
                return PLUGIN_HANDLED;
            }
            cs_set_user_money(id, tmp_money - 2500)
            set_pdata_float(g_mod_car[id], m_speed, DRAG_SPEED, LINUX_DIFF);
            client_printc(id, "%s You bought !gGears!", prefix);
            g_hotroded++
        }
        case 3:
        {
            if(tmp_money < 1500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix);
                return PLUGIN_HANDLED;
            }
            set_pdata_float(g_mod_car[id], m_flVolume, 0.0, LINUX_DIFF);
            cs_set_user_money(id, tmp_money - 1500)
            client_printc(id, "%s You bought !gMuffler!", prefix);
            g_hotroded++
        }
        case 4:
        {
            if(tmp_money < 1500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix);
                return PLUGIN_HANDLED;
            }
            cs_set_user_money(id, tmp_money - 1500)
            set_pdata_int(g_mod_car[id], m_acceleration, BLOWER3, LINUX_DIFF); //make temp
            set_pdata_float(g_mod_car[id], m_speed, REALFAST_SPEED, LINUX_DIFF);
            client_printc(id, "%s You bought !gNitrous!", prefix);
            g_hotroded++
        }
        case 5:
        {
            if(tmp_money < 500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix);
                return PLUGIN_HANDLED;
            }
            set_pdata_int(g_mod_car[id], m_acceleration, BLOWER1, LINUX_DIFF);
            cs_set_user_money(id, tmp_money - 500)
            client_printc(id, "%s You bought !gTurbo!", prefix);
            g_hotroded++
        }
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

stock client_printc(const id, const input[], any:...)
{
    new count = 1, players[32];
    static msg[191];
    vformat(msg, 190, input, 3);

    replace_all(msg, 190, "!g", "^x04"); // Green Color
    replace_all(msg, 190, "!n", "^x01"); // Default Color
    replace_all(msg, 190, "!t", "^x03"); // Team Color

    if(id)
        players[0] = id;
    else
        get_players(players, count, "ch");

    for (new i = 0; i < count; i++)
    {
        emessage_begin(MSG_ONE_UNRELIABLE, g_saytxt, _, players[i]);
        ewrite_byte(players[i]);
        ewrite_string(msg);
        emessage_end();
    }
}


///beta code
/*
new const ACCEL[]= "acceleration"
new const VRMM[]= "speed"
* //all or none approach preload
public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    if(containi(Classname, CARS) > charsmin)
    {
        if(equali(key,ACCEL))
            DispatchKeyValue(ACCEL, blower3)

        else if(equali(key,VRMM))
        {
            DispatchKeyValue(VRMM, realfast)
            g_hotroded++
        }
    }
}
*/
