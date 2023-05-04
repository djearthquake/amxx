/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */

#include amxmodx
#include amxmisc
#include hamsandwich
#define  CZERO                     //COMMENT OUT WITH // TO NOT PLAY CZ.
#tryinclude cs_ham_bots_api //COMMENT OUT WITH // TO PLAY REGULAR CS.

#define  charsmin -1

//CZ install instructions. Per Ham install this plugin first.
#define SPEC_PRG    "cs_ham_bots_api.amxx"
#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/czero/AI"
new bool:bIsBot[MAX_PLAYERS + 1]
new g_SyncMarks

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
/* DoD weapons */
enum {
    DODW_AMERKNIFE = 1,
    DODW_GERKNIFE,
    DODW_COLT,
    DODW_LUGER,
    DODW_GARAND,
    DODW_SCOPED_KAR,
    DODW_THOMPSON,
    DODW_STG44,
    DODW_SPRINGFIELD,
    DODW_KAR,
    DODW_BAR,
    DODW_MP40,
    DODW_HANDGRENADE,
    DODW_STICKGRENADE,
    DODW_STICKGRENADE_EX,
    DODW_HANDGRENADE_EX,
    DODW_MG42,
    DODW_30_CAL,
    DODW_SPADE,
    DODW_M1_CARBINE,
    DODW_MG34,
    DODW_GREASEGUN,
    DODW_FG42,
    DODW_K43,
    DODW_ENFIELD,
    DODW_STEN,
    DODW_BREN,
    DODW_WEBLEY,
    DODW_BAZOOKA,
    DODW_PANZERSCHRECK,
    DODW_PIAT,
    DODW_SCOPED_FG42,
    DODW_FOLDING_CARBINE,
    DODW_KAR_BAYONET,
    DODW_SCOPED_ENFIELD,
    DODW_MILLS_BOMB,
    DODW_BRITKNIFE,
    DODW_GARAND_BUTT,
    DODW_ENFIELD_BAYONET,
    DODW_MORTAR,
    DODW_K43_BUTT,
};

#define PLUGIN "HitMarx"
//Works on DOD, CS, CZ, OP4, and plain HL. Missing your mod? PM me.
#define VERSION "A2"
//Demo of selected style 1-8
#define AUTHOR "SPiNX"
//This is better than NapoleoN# script as it as a copy of Bugsy's work, mine and Call of Duty. This is 100% original idea.
//This is a mult-mod Hitmark demo which I intend to evolve over time even further.
//Please see my jail break of ABD on that thread. If works outside of Counter-strike now.

#define iRainbow random_num(1, 255)
#define FLAGS write_short(0x0001)
#define ALPHA write_byte(500)

//Screenfade color. TODO:Multiple random fade styles next.
#define BLU write_byte(0);write_byte(0);write_byte(random_num(200,255))
#define GRN write_byte(0);write_byte(random_num(200,255));write_byte(0)

//naming the crosshair/hitmarkers
#define VOLKS beta_symbols[9][random_num(0,2)]
#define GRATEFUL_DEAD beta_symbols[8][random_num(0,2)]
#define JAX beta_symbols[3][random_num(0,2)]
#define HALF beta_symbols[4][random_num(0,2)]
#define COLT two_spinners[0][random_num(0,1)]
#define PYRAMID two_spinners[1][random_num(0,1)]
#define RADIO two_spinners[2][random_num(0,1)]
#define DIAMONDS beta_symbols[2][random_num(0,2)]
#define STAR beta_symbols[1][random_num(0,2)]
//For super kills over 150HP.
new g_cvar_bsod_iConfmkills,g_cvar_bsod_iDelay;
new g_cvar_iHitSym;
new pRainbow,pSpinners,pMarkerRed,pMarkerGRN,pMarkerBLU,pHUDx,pHUDy,pLinger,bool:bStrike, bool:bDod, g_teams;

    ///Future could be objective oriented like certain markers for windage and or VIP.
    ///Use my plugin Element for accurate real world wind conditions and windage.
    new const beta_symbols[10][3][30] =

                {
/*0*/       {"╳",       "X",          "│"}, // The Napoleon. CSW_P90
/*1*/       {"★",       "✪",          "✩"}, // Starter
/*2*/       {"◇",       "◈",          "◆"}, // Diamonds are Forever. CSW_ALL_SHOTGUNS CSW_ALL_GRENADES ☄
/*3*/       {"✾",       "✢",          "✽"}, // Jack's
/*4*/       {"◐",       "◑",          "◒"}, // Half~Sir CSW_ALL_SMGS //navy
/*5*/       {"◔",       "◐",          "◕"}, // Cake
/*6*/       {"✙",       "✠",          "✜"}, // Spray-and-Pray
/*7*/       {"✁",       "✂",          "✃"}, // Cut-it-out. knife //CSW_KNIFE
/*8*/       {"☾",       "ϟ",          "☽"}, // The Grateful Dead. CSW_ALL_MACHINEGUNS
/*9*/       {"⊕",       "⊗",          "⊛"}  // Us Spokes. CSW_ALL_PISTOLS ⋖⑅⋗
                };

    new const two_spinners[][][] =
                {
            {"♘",   "♞"}, // The Samuel. CSW_M4A1 ◖◗
            {"◭",   "◮"}, // Pyramid Man. CSW_ALL_RIFLES
            {"✇",   "☢"} // Radio CSW_UMP //c4
                };
//Pre-Counter-Strike support
    new const alpha_symbols[][] =

                {
        "X", "\", "|", "/", "+"
                };


    new const TestArray[4][6][24] =
                {
        {"X",   "|",    "◌",    "⫸",    "❆",    "<"}, //mach
        {">",   "-",    "☄",    "⫷",    "/",    "X"}, //shotty
        {"*",   "❅",    "◗",    "x",    "|",    "╳"}, //default
        {"~",   "*",    "+",    "☣",    "️️⚔",  "☠"}  //if enemy is bot
                };



    new const test_spinner0[][] =

                {
         "└","┌","┘","┐"
                };

    new const test_spinner1[][] =
                {
        "╳","╲","＋","✖","│","╱"
                };

    new const test_spinner2[][] =
                {
         "⋮","⋯","⋰","⋱"
                };

    #define DISPLAY ShowSyncHudMsg(iAttacker,g_SyncMarks, "%s" , pSpinners ?
    #define IS get_user_weapon(iAttacker) ==
    #define HUDSUP set_dhudmessage(iRainbow,iRainbow,iRainbow, -1.0, -1.0, 0, 0.0, 0.1)
    #define DEMO show_dhudmessage(id,   "%s",
    #define SPEED   change_task(id,random_float(0.1,0.3),0)
    #define SLOW change_task(id,random_float(0.5,0.9),0)
    //CSW_ALL_SHOTGUNS CSW_ALL_RIFLES //CSW_ALL_SMGS //CSW_ALL_SNIPERRIFLES

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_clcmd("hitmark_demo","@demo",ADMIN_KICK,"|Hitmarker Demo");
    register_clcmd("nodemo","@demo_end",ADMIN_KICK,"|End Hitmarker Demo");

    RegisterHam(Ham_TakeDamage, "player", "@PostTakeDamage", 1);

    //Reused a few of Napolean's cvars to make the 2 plugins more interchangeable.
    pRainbow    = register_cvar("amx_hmrainbow", "1"); // Enables/disables random colors on every hit.
    bind_pcvar_num(register_cvar("amx_hmrandom", "1"), pSpinners); //Enables/disables random hit markers.
    pMarkerRed  = register_cvar("amx_hmrcolor", "165"); // RGB - Red (This won't work when amx_hmrainbow = 1)
    pMarkerGRN  = register_cvar("amx_hmgcolor", "165"); // RGB - GRN (This won't work when amx_hmrainbow = 1)
    pMarkerBLU  = register_cvar("amx_hmbcolor", "165"); // RGB - BLU (This won't work when amx_hmrainbow = 1)
    pHUDx       = register_cvar("amx_hmxpos", "-1.0"); // x pos
    pHUDy       = register_cvar("amx_hmypos", "-1.0"); // y pos
    pLinger     = register_cvar("amx_hmholdtime", "0.5"); // hud hold time

    g_cvar_bsod_iConfmkills     = register_cvar("bsod_confirm_kills", "11");
    g_cvar_bsod_iDelay          = register_cvar("bsod_delay", "5");
    g_cvar_iHitSym              = register_cvar("hitmarx", "2"); //compatibility mode works on everything.
    bDod = is_running("dod") == 1  ? true : false
    bStrike = cstrike_running() ? true : false
    g_teams            = !bStrike ? get_cvar_pointer("mp_teamplay") : get_cvar_pointer("mp_friendlyfire")

    g_SyncMarks = CreateHudSyncObj()

    //hitmarx 1-8. 1 snipers-only (w/ legacy HL support).2 all (w/ legacy HL support) . 3 Dice. (Future organized DOD) 4. Crosses. 5. Organized just for Cstrike. 6. Dice again. 7.Random inventory 8.Random inventory 2.
    //Type hitmark_demo in console or nodemo to test without players or as a spec.
    //bsod_confirm_kills # <0-?> sets how many times screen flashes you you kill an opponent.
    //bsod_delay # <1-?> Seconds the victim who gets obliterated endures the Blue Screen of Death.

    //later larger array can depict from bots, to humans, friendlies, to objective mark (c4 carrier), to low hp or a skull for high.
    #define TICKER test_spinner2
    #if !defined CS_OnBuy
        register_message(get_user_msgid("Money"), "OnMoneyChange")
        register_event("HLTV", "OnMoneyChange", "a", "1=0", "2=0")
    #endif
}

#if defined CZERO
public plugin_precache()
{
    //fail-safe although plugin is expected to stop beforehand.
    if(is_running("czero"))
    {
        if(is_plugin_loaded(SPEC_PRG,true) == charsmin)
        {
            log_amx("%s must be installed! %s", SPEC_PRG, URL)
            pause("c")
        }
        else
        {
            RegisterHamBots(Ham_TakeDamage, "@PostTakeDamage");
        }
    }
}
#endif

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
        if(bIsBot[id])return;
        if(bStrike || bDod)
            set_task_ex(random_float(7.0,8.0), "newlog", id, .flags = SetTask_Once);
    }
}

public newlog(id)
{
    if(is_user_connected(id) && !bIsBot[id])
    {
        client_print(id, print_chat, "Your landed shots appear...in HUD!");
        if(is_user_admin(id))
        {
            client_print(id, print_chat, "amx_cvar hitmarx 1-8");
            @demo(id);
        }
    }
}

#if !defined CS_OnBuy
public OnMoneyChange(iMsgId, iDest, id)
#else
public CS_OnBuy( id, anything )
#endif
{
    if(is_user_connected(id) && !bIsBot[id])
        @delayed_end(id)
}

@PostTakeDamage(iVictim, iInflictor, iAttacker, Float:iDamage, iDamagebits)
{
    static iRed, iGRN, iBLU, iCvar_Hitmark_type;
    iCvar_Hitmark_type = get_pcvar_num(g_cvar_iHitSym)
    if(iCvar_Hitmark_type >= 1)
    if(is_user_connected(iAttacker) && is_user_connected(iVictim))
    if(!bIsBot[iAttacker])
    if(get_pcvar_num(g_teams))
    {
        new killers_team[MAX_PLAYERS], victims_team[MAX_PLAYERS];
        get_user_team(iAttacker, killers_team, charsmax(killers_team));
        get_user_team(iVictim, victims_team, charsmax(victims_team));
        if(equal(killers_team,victims_team))
        {
            FnFade(iAttacker)
            //return PLUGIN_HANDLED
        }
    }
    if( iDamage > 250.0)
    {
        @FnWow(iAttacker, iDamage, iVictim);
    }
    if(is_user_alive(iAttacker) && is_user_alive(iVictim))
    {
        if(iCvar_Hitmark_type == 1)
        {
            if(bStrike)
            {
                if(CSW_ALL_SNIPERRIFLES & (~1 << get_user_weapon(iAttacker)))
                    return PLUGIN_HANDLED
            }
        }

        if(get_pcvar_num(pRainbow))
        {
            iRed = iRainbow;
            iGRN = iRainbow;
            iBLU = iRainbow;
        }
        else
        {
            iRed = get_pcvar_num(pMarkerRed);
            iGRN = get_pcvar_num(pMarkerGRN);
            iBLU = get_pcvar_num(pMarkerBLU);
        }

        set_hudmessage(iRed, iGRN, iBLU, get_pcvar_float(pHUDx), get_pcvar_float(pHUDy) , 0, 2.0, get_pcvar_float(pLinger) , 0.0, 0.0, -1);

        if(iCvar_Hitmark_type == 2 )
            DISPLAY alpha_symbols[random(sizeof(alpha_symbols))] : "X");

        if(bStrike|bDod)
        {
            new iGat = get_user_weapon(iAttacker)

            if(iCvar_Hitmark_type == 5 )
            {
                if(bStrike)
                {
                    switch(iGat)
                    {
                        case CSW_P90:
                        {
                            DISPLAY beta_symbols[0][random_num(0,2)] : "╳" );
                        }
                        case CSW_M4A1:
                        {
                            DISPLAY COLT : "╳" );
                        }
                        case CSW_UMP45:
                        {
                            DISPLAY JAX : "╳" );
                        }
                        case CSW_MAC10:
                        {
                            DISPLAY STAR: "╳" );
                        }
                        case CSW_AK47:
                        {
                            DISPLAY HALF : "╳" );
                        }
                        case CSW_GALI:
                        {
                            DISPLAY test_spinner2[random(sizeof(test_spinner2))] : "╳");
                        }
                        case CSW_FAMAS:
                        {
                            DISPLAY test_spinner0[random(sizeof(test_spinner0))] : "╳");
                        }
                        case CSW_MP5NAVY:
                        {
                            DISPLAY beta_symbols[5][random_num(0,2)] : "╳" );
                        }
                        case CSW_AUG:
                        {
                            DISPLAY PYRAMID : "╳" );
                        }
                        case CSW_SG552:
                        {
                            DISPLAY PYRAMID: "╳" );
                        }
                        case CSW_KNIFE:
                        {
                            DISPLAY beta_symbols[7][random_num(0,2)] : "╳" );
                        }
                        case CSW_TMP:
                        {
                            DISPLAY GRATEFUL_DEAD: "╳" );
                        }
                        case CSW_M249:
                        {
                            DISPLAY GRATEFUL_DEAD : "╳" );
                        }
                    }
                    if(CSW_ALL_SNIPERRIFLES & (1 << get_user_weapon(iAttacker)))
                    {
                        DISPLAY beta_symbols[6][random_num(0,2)] : "╳" );
                    }
                    if(CSW_ALL_PISTOLS & (1 << get_user_weapon(iAttacker)))
                    {
                        DISPLAY RADIO : "╳" );
                    }
                    if(CSW_ALL_SHOTGUNS & (1 << get_user_weapon(iAttacker)))
                    {
                        DISPLAY DIAMONDS : "╳" );
                    }
                }
                if(bDod)
                {
                    switch(iGat)
                    {
                        case DODW_MG42:
                        {
                            DISPLAY GRATEFUL_DEAD : "╳" );
                        }
                        case DODW_MG34:
                        {
                            DISPLAY GRATEFUL_DEAD : "╳" );
                        }
                        case DODW_COLT:
                        {
                            DISPLAY COLT : "╳" );
                        }
                        case DODW_THOMPSON:
                        {
                            DISPLAY COLT : "╳" );
                        }
                        case DODW_FG42:
                        {
                            DISPLAY STAR : "╳" );
                        }
                        case DODW_BREN:
                        {
                            DISPLAY STAR : "╳" );
                        }
                        case DODW_30_CAL:
                        {
                            DISPLAY STAR : "╳" );
                        }
                        default:
                        {
                            DISPLAY VOLKS : "╳" );
                        }
                    }
                }
            }
            else
            {
                if (iCvar_Hitmark_type <= 2 )
                {
                    DISPLAY test_spinner1[random(sizeof(test_spinner1))] : "╳");
                }
                if (iCvar_Hitmark_type == 3 )
                {
                    DISPLAY test_spinner2[random(sizeof(test_spinner2))] : "╳");
                }
                if (iCvar_Hitmark_type == 4 )
                {
                    DISPLAY test_spinner0[random(sizeof(test_spinner0))] : "╳");
                }
                if (iCvar_Hitmark_type == 6 )
                {
                    DISPLAY TICKER[random(sizeof(TICKER))] : "╳");
                }
                if (iCvar_Hitmark_type == 7 )
                {
                    DISPLAY beta_symbols[random_num(0,9)][random_num(0,2)] : "╳" );
                }

                if (iCvar_Hitmark_type == 8 )
                {
                    DISPLAY TestArray[random_num(0,3)][random_num(0,5)] : "╳");
                }
            }
        }
        else
        {
            DISPLAY alpha_symbols[random(sizeof(alpha_symbols))] : "X");
        }
    }
    return PLUGIN_HANDLED
}

@demo(id)
{
    if(is_user_connected(id) && !bIsBot[id])
    {
        set_task_ex(random_float(0.1,0.3), "@Demo", id, .flags = SetTask_Repeat);
    }
    return PLUGIN_HANDLED;
}

@delayed_end(id)
{
    if(is_user_connected(id) && !bIsBot[id])
    {
        set_task_ex(random_float(2.0,5.0), "@demo_end", id, .flags = SetTask_RepeatTimes, .repeat = 3);
    }
}

@demo_end(id)
{
    if(is_user_connected(id))
    {
        if(task_exists(id))
            remove_task(id)
    }
    return PLUGIN_HANDLED;
}

@Demo(id)
{
    if(is_user_connected(id))
    {
        HUDSUP
        SPEED
        new iHit = get_pcvar_num(g_cvar_iHitSym)
        switch(iHit)
        {
            case 2: DEMO test_spinner1[random(sizeof(test_spinner1))]);
            case 3: DEMO test_spinner2[random(sizeof(test_spinner2))]);
            case 4: DEMO test_spinner0[random(sizeof(test_spinner0))]);
            case 5: @long_demo(id);
            case 6: DEMO TICKER[random(sizeof(TICKER))]);
            case 7: goto END
            case 8: DEMO TestArray[random_num(0,3)][random_num(0,5)]);
        }
        END:
        SLOW
        DEMO beta_symbols[random_num(0,9)][random_num(0,2)]);
    }
    return PLUGIN_HANDLED;
}

@motd()
{
    new Float:xTex
    xTex = -1.0
    new Float:yTex
    yTex = -1.0
    new Float:fadeInTime = 0.5;
    new Float:fadeOutTime = 1.5;
    new Float:holdTime = 1.5;
    new Float:scanTime = 1.1;
    new effect = 2;
    if(get_playersnum())
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
    write_byte(TE_TEXTMESSAGE);
    write_byte(0);      //(channel)
    write_short(FixedSigned16(xTex,1<<13));  //(x) -1 = center)
    write_short(FixedSigned16(yTex,1<<13));  //(y) -1 = center)
    write_byte(effect);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    write_byte(0);  //(red) - text color
    write_byte(255);  //(GRN)
    write_byte(64);  //(BLU)
    write_byte(200);  //(alpha)
    write_byte(255);  //(red) - effect color
    write_byte(0);  //(GRN)
    write_byte(0);  //(BLU)
    write_byte(25);  //(alpha)
    write_short(FixedUnsigned16(fadeInTime,1<<8));
    write_short(FixedUnsigned16(fadeOutTime,1<<8));
    write_short(FixedUnsigned16(holdTime,1<<8));
    if (effect == 2)
        write_short(FixedUnsigned16(scanTime,1<<8));
    //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
    write_string("Hitmark       demo..."); //(text message) 512 chars max string size
    message_end();
}

#define COLT_TASK 1337
@long_demo(id)
{
    if(is_user_connected(id))
    {
        if(task_exists(id))
            remove_task(id)

        if(is_user_admin(id)) //too long for casual user
        {
            set_task_ex(random_float(0.1,0.2), "@cell01", id, .flags = SetTask_RepeatTimes, .repeat = 20)
            set_task_ex(18.0, "@cell001", id+COLT_TASK, .flags = SetTask_Once);
            @long_demo_motd(id)
        }
    }
}

@long_demo_motd(id)
{
    if(is_user_connected(id))
    {
        if(is_user_admin(id))
        {
            new Float:xTex
            xTex = -1.0
            new Float:yTex
            yTex = -1.0
            new Float:fadeInTime = 0.5;
            new Float:fadeOutTime = 1.5;
            new Float:holdTime = 1.5;
            new Float:scanTime = 1.1;
            new effect = 2;

            message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
            write_byte(TE_TEXTMESSAGE);
            write_byte(0);      //(channel)
            write_short(FixedSigned16(xTex,1<<13));  //(x) -1 = center)
            write_short(FixedSigned16(yTex,1<<13));  //(y) -1 = center)
            write_byte(effect);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
            write_byte(0);  //(red) - text color
            write_byte(155);  //(GRN)
            write_byte(111);  //(BLU)
            write_byte(20);  //(alpha)
            write_byte(180);  //(red) - effect color
            write_byte(75);  //(GRN)
            write_byte(200);  //(BLU)
            write_byte(30);  //(alpha)
            write_short(FixedUnsigned16(fadeInTime,1<<8));
            write_short(FixedUnsigned16(fadeOutTime,1<<8));
            write_short(FixedUnsigned16(holdTime,1<<8));
            if (effect == 2)
                write_short(FixedUnsigned16(scanTime,1<<8));
            //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
            write_string("Hitmarks to confirm your hits!"); //(text message) 512 chars max string size
            message_end();
        }
    }
}

#define DEMO_TIME 7.0
#define DEMO_REPEAT 12
@cell01(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO beta_symbols[0][random_num(0,2)]);
    client_print(id, print_center, "P90");
}
@cell001(tsk)
{
    new id = tsk - COLT_TASK
    if(is_user_alive(id))
    {
        set_task_ex(random_float(0.3,0.8), "@cell02", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
        set_task_ex(DEMO_TIME, "@cell002", id, .flags = SetTask_Once);
    }
}
@cell02(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO COLT);
    client_print(id, print_center, "COLT");
}
@cell002(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.3,0.8), "@cell03", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
    set_task_ex(DEMO_TIME, "@cell003", id, .flags = SetTask_Once);
}
@cell03(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO JAX);
    client_print(id, print_center, "ALL SHOTGUNS");
}
@cell003(id)
if(is_user_connected(id))
{
    set_task_ex(random_float(0.3,0.5), "@cell04", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
    set_task_ex(DEMO_TIME, "@cell004", id, .flags = SetTask_Once);
}
@cell04(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO JAX);
    client_print(id, print_center, "UMP45");
}
@cell004(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.3,0.8), "@cell05", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
    set_task_ex(DEMO_TIME, "@cell005", id, .flags = SetTask_Once);
}
@cell05(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO HALF);
    client_print(id, print_center, "Kalashnikov");
}
@cell005(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.3,0.7), "@cell06", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
    set_task_ex(DEMO_TIME, "@cell006", id, .flags = SetTask_Once);
}
@cell06(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO beta_symbols[5][random_num(0,2)]);
    client_print(id, print_center, "MP5");
}
@cell006(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.3,0.7), "@cell07", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
    set_task_ex(DEMO_TIME, "@cell007", id, .flags = SetTask_Once);
}
@cell07(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO beta_symbols[6][random_num(0,2)]);
    client_print(id, print_center, "ALL SNIPERS");
}
@cell007(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.3,0.7), "@cell08", id, .flags = SetTask_RepeatTimes, .repeat = DEMO_REPEAT);
    set_task_ex(DEMO_TIME, "@cell008", id, .flags = SetTask_Once);
}
@cell08(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO beta_symbols[7][random_num(0,2)]);
    client_print(id, print_center, "KNIFE");
}
@cell008(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.09,0.1), "@cell09", id, .flags = SetTask_RepeatTimes, .repeat = 150)
    set_task_ex(18.0, "@cell009", id, .flags = SetTask_Once);
}
@cell09(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO GRATEFUL_DEAD);
    client_print(id, print_center, "PARA or TMP");
}
@cell009(id)
if(is_user_alive(id))
{
    set_task_ex(random_float(0.1,0.3), "@cell10", id, .flags = SetTask_RepeatTimes, .repeat = 150);
}
@cell10(id)
if(is_user_connected(id))
{
    HUDSUP
    DEMO VOLKS);
    client_print(id, print_center, "ALL PISTOLS");
}

@FnWow(iAttacker, Float:iDamage, iVictim)
{
    if(is_user_connected(iAttacker) && is_user_connected(iVictim))
    {
        client_print(0,print_chat,"%n obliterated %n doing %i damage!",iAttacker,iVictim,floatround(iDamage))

        set_hudmessage(iRainbow,iRainbow,iRainbow, -1.0, 0.55, 1, 2.0, 3.0, 0.7, 0.8, 3);
        show_hudmessage(0, "%n obliterated %n doing %i damage!",iAttacker,iVictim,floatround(iDamage))
        if(!bIsBot[iAttacker])
        {
            client_cmd iAttacker, "spk exterminate"
            FnKiller(iAttacker);
        }
        if(!is_user_alive(iVictim))
            FnFade(iVictim);
    }
}

public FnKiller(iAttacker)
{
    if(is_user_alive(iAttacker) && !bIsBot[iAttacker])
        set_task_ex(0.1, "FnStrobe", iAttacker, .flags = SetTask_RepeatTimes, .repeat = get_pcvar_num(g_cvar_bsod_iConfmkills));
}

public FnStrobe(iAttacker)
{
    if(is_user_connected(iAttacker) && !bIsBot[iAttacker])
    {
        message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),{0,0,0},iAttacker);
        write_short(1000);
        write_short(1000);
        FLAGS;
        write_byte(iRainbow);
        write_byte(iRainbow);
        write_byte(iRainbow);
        ALPHA;
        message_end();
    }
    return;
}

#define DELAY write_short(get_pcvar_num(g_cvar_bsod_iDelay)*4096) //Remember 4096 is ~1-sec per 'spec unit'

public FnFade(iVictim)
{
    if(is_user_connected(iVictim) && !bIsBot[iVictim])
    {
        message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),{0,0,0},iVictim);
        DELAY;DELAY;FLAGS;BLU;ALPHA; //This is where one can change BLU to GRN.
        message_end();
    }
    return;
}
