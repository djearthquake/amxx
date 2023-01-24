#include amxmodx
#include amxmisc
#include cstrike
#include engine
#include fakemeta
#include fakemeta_util
#include fun

#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1
#define iCOLOR random_num(1,255)
#define JEEP 7594

new const prefix[] = { "!g[!tShop!g]!n" }

new iArmor[MAX_PLAYERS +1], g_mod_car[MAX_PLAYERS + 1], 
g_owned_car[MAX_PLAYERS][4], iMaxplayers,
bool:bSet[MAX_PLAYERS + 1], bool:bRegisteredCar[MAX_PLAYERS + 1]

new const CARS[]= "func_vehicle"

new m_acceleration, m_speed,m_flVolume;

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
new g_hotroded, g_iNitrous, g_sprite

const LINUX_DIFF = 5;
const LINUX_OFFSET_WEAPONS = 4;
public plugin_precache(){g_sprite = precache_model("sprites/smoke.spr");}
public plugin_init()
{
    register_plugin("Jeep Nitrous", "1.5", ".sρiηX҉.");

    if(!find_ent(charsmin, CARS))
    {
        pause "d"
    }
    
    register_touch("player","func_vehicle","fn_shield_proximity2")

    register_clcmd("say /nos", "@nos", 0, "- say /nos for Car Mods!" , 0) 
    register_clcmd("say_team /nos", "@nos")

    iMaxplayers = get_maxplayers()
    register_logevent("round_start", 2, "1=Round_Start")
    g_iNitrous = register_cvar("jeep_nitrous", "7")
    m_acceleration = (find_ent_data_info("CFuncVehicle", "m_acceleration")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF
    m_speed = (find_ent_data_info("CFuncVehicle", "m_speed")/LINUX_OFFSET_WEAPONS) - LINUX_DIFF
    m_flVolume = (find_ent_data_info("CFuncVehicle", "m_flVolume") /LINUX_OFFSET_WEAPONS) - LINUX_DIFF
}
public pfn_touch(ptr, ptd)
{
    new iCar = get_pcvar_num(g_iNitrous)
    if(g_iNitrous && iCar)
    {
        if(is_user_connected(ptr) && pev_valid(ptd) > 1)
        {
            new iPlayer = ptr
            if(is_driving(iPlayer))
            {
                g_mod_car[iPlayer] = ptd 
                bSet[iPlayer] = true
            }
        }
    }
}

public round_start()
{
    for(new iPlayer = 1 ; iPlayer <= iMaxplayers ; ++iPlayer)
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
}

public driving_think()
{ 
    new iCar = get_pcvar_num(g_iNitrous)
    if(g_iNitrous && !iCar && task_exists(JEEP))
    {
        remove_task(JEEP)
    }
    
    for(new iPlayer = 1 ; iPlayer <= iMaxplayers ; ++iPlayer)
    {
        ///if(bRegisteredCar[iPlayer])
        {
            if(is_user_connected(iPlayer) && g_mod_car[iPlayer] && pev_valid(g_mod_car[iPlayer] > 1))
            {
                new iRColor1 = random(255), iRColor2 = random(255), iRColor3 = random(255)
    
                iArmor[iPlayer] = get_user_armor(iPlayer);
    
                if(is_driving(iPlayer) && iArmor[iPlayer] < 200.0)
                {
                    //set_pev(iPlayer, pev_armortype, 2)
                    entity_set_float(iPlayer, EV_FL_armorvalue, float(iArmor[iPlayer])+1.0);
                    if(is_user_alive(iPlayer))
                    {
                        set_ent_rendering(iPlayer, kRenderFxGlowShell, iRColor1, iRColor2, iRColor3, kRenderGlow, 5);
                        if(g_mod_car[iPlayer] && pev_valid(g_mod_car[iPlayer] > 1))
                        {
                            set_ent_rendering(g_mod_car[iPlayer], kRenderFxNone, iRColor1, iRColor2, iRColor3, kRenderTransColor, 75);
                            if(is_user_admin(iPlayer))
                            {
                                new Accel = get_pdata_int(g_mod_car[iPlayer], m_acceleration, LINUX_DIFF);
                                new fSpeed = get_pdata_int(g_mod_car[iPlayer], m_speed, LINUX_DIFF);
                                new Float:fVol = get_pdata_float(g_mod_car[iPlayer], m_flVolume, LINUX_DIFF);
        
                                client_print iPlayer, print_center, "%f|%i|%f", fSpeed, Accel, fVol //max
                            }
                        }
                    }
                }
                else if(!is_driving(iPlayer) && iArmor[iPlayer] > 100.0)
                {
                    entity_set_float(iPlayer, EV_FL_armorvalue, float(iArmor[iPlayer])-1.0);
                    set_ent_rendering(iPlayer, kRenderNormal, 0, 0, 0, kRenderNormal, 0)
                    if(g_mod_car[iPlayer]  && pev_valid(g_mod_car[iPlayer] > 1))
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
    if( is_user_connected(id))
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
    
        ///message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
        message_begin ( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id )
        write_byte(TE_TEXTMESSAGE);
        write_byte(0);      //(channel)
        write_short(FixedSigned16(xTex,1<<13));  //(x) -1 = center)
        write_short(FixedSigned16(yTex,1<<13));  //(y) -1 = center)
        write_byte(effect);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
        write_byte(0);  //(red) - text color
        write_byte(255);  //(green)
        write_byte(64);  //(blue)
        write_byte(200);  //(alpha)
        write_byte(255);  //(red) - effect color
        write_byte(0);  //(green)
        write_byte(0);  //(blue)
        write_byte(25);  //(alpha)
        write_short(FixedUnsigned16(fadeInTime,1<<8));
        write_short(FixedUnsigned16(fadeOutTime,1<<8));
        write_short(FixedUnsigned16(holdTime,1<<8));
        if (effect == 2) 
            write_short(FixedUnsigned16(scanTime,1<<8));
        //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
        write_string("Nitrous  ☄☄☄  shot..."); //(text message) 512 chars max string size
        message_end();
    }
}

public fn_shield_proximity2(iPlayer,iCar)
{
    //car1 = find_ent(-1, CARS);
    //car2 = find_ent(car1, CARS);
    if(is_user_connected(iPlayer) && is_user_bot(iPlayer))
    {
        message_begin(0,23);
        write_byte(TE_BEAMRING)
        write_short(iPlayer)
        write_short(iCar)
        write_short(g_sprite)
        write_byte(10)  //starting frame
        write_byte(1) //rate
        write_byte(random_num(1,60)) //life
        write_byte(random_num(5,500)) //width
        write_byte(random_num(1,10000)) //amp
        write_byte(iCOLOR)  //Red
        write_byte(iCOLOR) //Green
        write_byte(iCOLOR) //blue
        write_byte(random_num(5,15)) //bright
        write_byte(1) //speed
        message_end();
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
    
    menu_additem(menu, "Blower   [$500] ", "1", 0); 
    menu_additem(menu, "Gears     [$500] ", "2", 0); 
    menu_additem(menu, "Muffler  [$500] ", "3", 0); 
    menu_additem(menu, "Nitrous  [$500] ", "4", 0); 
    menu_additem(menu, "Turbo     [$500] ", "5", 0); 
    
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL); 
    menu_display(id, menu, 0); 
    
    return PLUGIN_HANDLED 
} 

public shop_cars(id, menu, item) 
{ 
    if(!is_user_alive(id)) 
    { 
        client_printc(id, "%s You !gmust !nbe !talive !nto !topen !nthe !gShop!n!", prefix); 
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
            if(tmp_money < 500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix); 
                return PLUGIN_HANDLED;
            }
            cs_set_user_money(id, tmp_money - 500) 
            set_pdata_int(g_mod_car[id], m_acceleration, BLOWER2, LINUX_DIFF);
            client_printc(id, "%s You bought !gBlower", prefix);
            g_hotroded++
        } 
        case 2: 
        { 
            if(tmp_money < 500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix); 
                return PLUGIN_HANDLED;
            }
            cs_set_user_money(id, tmp_money - 500) 
            set_pdata_float(g_mod_car[id], m_speed, DRAG_SPEED, LINUX_DIFF);
            client_printc(id, "%s You bought !gGears!", prefix);
            g_hotroded++
        } 
        case 3: 
        { 
            if(tmp_money < 500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix); 
                return PLUGIN_HANDLED;
            }
            set_pdata_float(g_mod_car[id], m_flVolume, 0.0, LINUX_DIFF);
            cs_set_user_money(id, tmp_money - 500) 
            client_printc(id, "%s You bought !gMuffler!", prefix);
            g_hotroded++
        } 
        case 4: 
        { 
            
            if(tmp_money < 500)
            {
                client_printc(id, "%s You dont have enough !gMoney!", prefix); 
                return PLUGIN_HANDLED;
            }

            cs_set_user_money(id, tmp_money - 500)
            set_pdata_int(g_mod_car[id], m_acceleration, BLOWER3, LINUX_DIFF); //make temp
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
        message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]); 
        write_byte(players[i]); 
        write_string(msg); 
        message_end(); 
    } 
}

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
