/* IMPULSE 206 - Take control of bot.
*
*   SSSSSSSSSSSSSSS PPPPPPPPPPPPPPPPP     iiii  NNNNNNNN        NNNNNNNNXXXXXXX       XXXXXXX
* SS:::::::::::::::SP::::::::::::::::P   i::::i N:::::::N       N::::::NX:::::X       X:::::X
*S:::::SSSSSS::::::SP::::::PPPPPP:::::P   iiii  N::::::::N      N::::::NX:::::X       X:::::X
*S:::::S     SSSSSSSPP:::::P     P:::::P        N:::::::::N     N::::::NX::::::X     X::::::X
*S:::::S              P::::P     P:::::Piiiiiii N::::::::::N    N::::::NXXX:::::X   X:::::XXX
*S:::::S              P::::P     P:::::Pi:::::i N:::::::::::N   N::::::N   X:::::X X:::::X
* S::::SSSS           P::::PPPPPP:::::P  i::::i N:::::::N::::N  N::::::N    X:::::X:::::X
*  SS::::::SSSSS      P:::::::::::::PP   i::::i N::::::N N::::N N::::::N     X:::::::::X
*    SSS::::::::SS    P::::PPPPPPPPP     i::::i N::::::N  N::::N:::::::N     X:::::::::X
*       SSSSSS::::S   P::::P             i::::i N::::::N   N:::::::::::N    X:::::X:::::X
*            S:::::S  P::::P             i::::i N::::::N    N::::::::::N   X:::::X X:::::X
*            S:::::S  P::::P             i::::i N::::::N     N:::::::::NXXX:::::X   X:::::XXX
*SSSSSSS     S:::::SPP::::::PP          i::::::iN::::::N      N::::::::NX::::::X     X::::::X
*S::::::SSSSSS:::::SP::::::::P          i::::::iN::::::N       N:::::::NX:::::X       X:::::X
*S:::::::::::::::SS P::::::::P          i::::::iN::::::N        N::::::NX:::::X       X:::::X
* SSSSSSSSSSSSSSS   PPPPPPPPPP          iiiiiiiiNNNNNNNN         NNNNNNNXXXXXXX       XXXXXXX
*
*──────────────────────────────▄▄
*──────────────────────▄▄▄▄▄▄▄▄▌▐▄
*─────────────────────█▄▄▄▄▄▄▄▄▌▐▄█
*────────────────────█▄▄▄▄▄▄▄█▌▌▐█▄█
*──────▄█▀▄─────────█▄▄▄▄▄▄▄▌░▀░░▀░▌
*────▄██▀▀▀▀▄──────▐▄▄▄▄▄▄▄▐ ▌█▐░▌█▐▌
*──▄███▀▀▀▀▀▀▀▄────▐▄▄▄▄▄▄▄▌░░░▄▄▌░▐
*▄████▀▀▀▀▀▀▀▀▀▀▄──▐▄▄▄▄▄▄▄▌░░▄▄▄▄░▐
*████▀▀▀▀▀▀▀▀▀▀▀▀▀▄▐▄▄▄▄▄▄▌░▄░░▀▀░░▌
*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▌░▐▀▄▄▄▄▀
*▒▒▒▒▄▄▀▀▀▀▀▀▀▀▄▄▄▄▀▀█▄▄▄▄▄▌░░░░░▌
*▒▄▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌
*▒▌░░░░░▀▄░░░░░░░░░░░░░░░▀▄▄▄▄▄▄░▀▄▄▄▄▄
*▒▌░░░░░░░▀▄░░░░░░░░░░░░░░░░░░░░▀▀▀▀▄░▀▀▀▄
*▒▌░░░░░░░▄▀▀▄░░░░░░░░░░░░░░░▀▄░▄░▄░▄▌░▄░▄▌
*▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
*
*
*
*
*
* __..__  .  .\  /
*(__ [__)*|\ | ><
*.__)|   || \|/  \
*
*    Respawn from bots.
*    Copyleft (C) Nov 2020-2025 .sρiηX҉.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*    Credits: AMXX DEV TEAM for everything including adminhelp.sma.
*    AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
*
*    V1.0 to 1.1 -better unsticking code when bots are crouched against wall.
*                -take the place of AFK humans for round.
*    V1.1 to 1.2 -focus on correct side-arms and unsticking. Switch to "impulse 206" instead of prethink.
*    V1.2 to 1.3 -Pause and log plugin if dependecy is not found.
*    V1.3 to 1.4 -Restart round when no player has C4 post spawn. Remove prefixes on weapon and item when announcing.
*    V1.4 to 1.5 -Code for cs_set_user_bpammo failing on random weapons. If client has no weapon as a result one is given to stop crash on beginning of next round.
*    V1.5 to 1.6 -Optimize, bugfix, and remove need for unsticking code.
*/

#include amxmodx
#include amxmisc
#include cstrike
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#define charsmin -1
#define MAX_NAME_LENGTH 32

new
//Cvars
g_dust, g_humans, g_keep, g_sound_reminder, g_freeze,
//Strings
SzWeaponClassname[MAX_NAME_LENGTH], bots_name[ MAX_NAME_LENGTH + 1 ],
//Integers
g_iSpawnBackpackCT, g_iSpawnBackpackT, iBotOwned[MAX_PLAYERS+1], iBotOwner[MAX_PLAYERS+1], alive_bot, arm, ammo, magazine, wpnid, iMaxplayers,

//Global variables
g_Ouser_origin[MAX_PLAYERS + 1][3], g_Duck[MAX_PLAYERS + 1], g_BackPack[MAX_PLAYERS + 1], g_cor, g_times,
g_iTempCash[MAX_PLAYERS + 1], g_bot_controllers, g_item_cost, g_c4_client,
respawner[MAX_PLAYERS +1],

//Floats
Float:vec[3], Float:g_Angles[MAX_PLAYERS + 1][3], Float:g_Plane[MAX_PLAYERS + 1][3], Float:g_Punch[MAX_PLAYERS + 1][3], Float:g_Vangle[MAX_PLAYERS + 1][3], Float:g_Mdir[MAX_PLAYERS + 1][3],
Float:g_user_origin[MAX_PLAYERS + 1][3],

//Bools
bool:bIsBot[MAX_PLAYERS + 1], bool:bIsCtrl[MAX_PLAYERS + 1], bool:bBotUser[MAX_PLAYERS + 1], bool:g_JustTook[MAX_PLAYERS + 1], bool:cool_down_active, bool:bIsBound[MAX_PLAYERS + 1],
bool:bIsVip[MAX_PLAYERS + 1], bool:bRegistered, bool:bDucking[MAX_PLAYERS + 1], bool:bBotOwner[MAX_PLAYERS + 1], bool:bShield[MAX_PLAYERS + 1],
bool:bDefuser[MAX_PLAYERS + 1];

static g_mod[MAX_NAME_LENGTH];

static const SzSuit[]="item_assaultsuit";

static const SzCsAmmo[][]=
{
    "ammo_9mm",
    "ammo_357sig",
    "ammo_57mm",
    "ammo_45acp",
    "ammo_50ae"
};

//Make translations later.
static const SzAdvert[]="Bind impulse 206 to control bot.";
static const SzAdvertAll[]="Bind impulse 206 to control bot/AFK human.";
static const SzAdvertSale[]="Purchasing a bot to respawn costs $%i.";
static const szMsg[]="No more respawns this round!";


public plugin_init()
{
    register_plugin("Repawn from bots", "1.5.8", "SPiNX");
    //cvars
    g_dust = register_cvar("respawn_dust", "1")
    g_humans = register_cvar("respawn_humans", "1")
    g_keep = register_cvar("respawn_keep", "0")
    g_sound_reminder = register_cvar("respawn_sound", "1")
    g_freeze = get_cvar_pointer("mp_freezetime")
    g_times = register_cvar("respawn_times", "3")
    g_item_cost = register_cvar("respawn_cost", "2500" )
    //Ham
    RegisterHam(Ham_Spawn, "player", "@PlayerSpawn", 1)
    RegisterHam(Ham_Killed, "player", "@died", 1)
    //Events
    register_logevent("round_start", 2, "1=Round_Start")
    register_logevent("round_end", 2, "1=Round_End")
    register_logevent("logevent_function_p", 3, "2=Spawned_With_The_Bomb")
    //control
    register_impulse(206,"@buy_bot")
    //Misc
    iMaxplayers = get_maxplayers()
    g_cor = get_user_msgid( "ClCorpse" )
    g_bot_controllers = 0
    bIsCtrl[0] = true
    get_modname(g_mod, charsmax(g_mod))
}

stock get_loguser_index()
{
    static loguser[80], name[MAX_NAME_LENGTH];
    read_logargv(0, loguser, charsmax(loguser));
    parse_loguser(loguser, name, charsmax(loguser));

    return get_user_index(name);
}

public logevent_function_p()
{
    if(g_bot_controllers)
    {
        new id = get_loguser_index();
        if(is_user_connected(id))
        {
            g_c4_client = id
            if(g_bot_controllers)
            {
                give_item(id, "weapon_c4")  
                cs_set_user_plant(id, .plant = 1, .showbombicon = 1)
            }
        }
    }
}

@died(id)
{
    bBotOwner[id] = false;

    if(is_user_connected(id))
    {
        if(bIsCtrl[id])
        {
            strip_user_weapons(id)
        }
        if(!cool_down_active && !bIsBound[id])
        {
            client_print id, print_chat, get_pcvar_num(g_humans) ? SzAdvertAll : SzAdvert
        }
    }
}

public client_putinserver(id)
{
    if(!equal(g_mod, "czero"))
    {
            bRegistered = true
    }
    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
        if(bIsBot[id] && !bRegistered)
        {
            set_task(0.1, "@register", id);
        }
    }
}

public client_disconnected(id)
{
    bIsBot[id] = false
    bBotOwner[id] = false;
}

public CS_OnBuyAttempt(id)
{
    return bIsCtrl[id] ?  PLUGIN_HANDLED_MAIN : PLUGIN_CONTINUE;
}

public CS_OnBuy(id, item)
{
    return bIsCtrl[id] ?  PLUGIN_HANDLED_MAIN : PLUGIN_CONTINUE;
}

@BotSpawn(bot)
{
    if(is_user_alive(bot))
    {
        if(bIsCtrl[bot])
        {
            g_iTempCash[bot] = cs_get_user_money(bot)
            cs_set_user_money(bot, 0, 0)
            server_print("%n was controlled last round", bot)
        }
        set_task(0.1,"@ReSpawn", bot)
    }
}

@PlayerSpawn(id)
{
    set_task(0.1, "@PlayerSpawn_",id)
}

@PlayerSpawn_(id)
{
    if(bIsBot[id])
    {
        @BotSpawn(id)
    }
    if(is_user_connected(id))
    {
        if(!g_JustTook[id] && !bBotOwner[id])
        {
            @ReSpawn(id)
        }
    }
}

@ReSpawn(id)
{
    new iDefaultTeamPack,
    SzParaphrase[128], iDust, iKeep, iSound;
    iDust = get_pcvar_num(g_dust), iKeep = get_pcvar_num(g_keep), iSound = get_pcvar_num(g_sound_reminder);

    if(is_user_connected(id))
    {
        bIsVip[id] = cs_get_user_vip(id) ? true : false
        if(!g_iSpawnBackpackCT || !g_iSpawnBackpackT)
        {
            static iTeam; iTeam = get_user_team(id);
            if(iTeam == 1 && !g_iSpawnBackpackT)
            {
                if(!user_has_weapon(id, CSW_C4))
                {
                    g_iSpawnBackpackT = entity_get_int(id, EV_INT_weapons)
                    server_print "RESPAWN| Grabbed default provisions from T, %N",id
                }

            }
            else if(iTeam == 2 && !g_iSpawnBackpackCT )
            {
                g_iSpawnBackpackCT = entity_get_int(id, EV_INT_weapons)
                server_print "RESPAWN| Grabbed default provisions from CT, %N",id
            }
        }
        iDefaultTeamPack = get_user_team(id) == 1 ? g_iSpawnBackpackT : g_iSpawnBackpackCT
        if(bIsCtrl[id])
        {
            fm_set_kvd(id, "zhlt_lightflags", "0")
            set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 255) //some bots missed

            switch(iKeep)
            {
                case 0 : goto TRADE
                case 1 : goto RECLAIM
                case 2 :
                if(is_user_alive(iBotOwner[id]))
                {
                    if(g_BackPack[iBotOwner[id]] != iDefaultTeamPack)
                    {
                        g_BackPack[id] = g_BackPack[iBotOwner[id]]
                    }
                    goto TRADE;
                }
            }
            bIsCtrl[id] = false;
        }
        if(bBotUser[id])
        {
            bBotUser[id] = false;
            if(iSound)
            {
                client_cmd(id, iKeep ? "spk turret/tu_spinup.wav" : "spk turret/tu_spindown.wav")
            }
            if(iKeep > charsmin)
            {
                client_print(id, print_chat, iKeep ?  "Respawn with weapons." : "Normal Respawn.")
            }
            if(!iKeep || iKeep==2)
            {
                if(is_user_alive(id))
                {
                    if(!iKeep)
                    {
                        strip_user_weapons(id)
                        if( id == g_c4_client)
                        {
                            @give_c4(id)
                        }
                    }
                    for (new iArms = CSW_P228; iArms <= CSW_LAST_WEAPON; iArms++)
                    {
                        if(iDefaultTeamPack & 1<<iArms)
                        if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
                        {
                            if(!equal(SzWeaponClassname, "weapon_c4") || !equal(SzWeaponClassname, "weapon_null"))
                            {
                                give_item(id, SzWeaponClassname)

                                if(containi(SzWeaponClassname, "item_")!=charsmin)
                                    replace(SzWeaponClassname, charsmax(SzWeaponClassname), "item_", "")
                                if(containi(SzWeaponClassname, "weapon_")!=charsmin)
                                    replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")

                                client_print id, print_chat,  SzWeaponClassname
                            }
                        }
                        TRADE:
                        if(bIsCtrl[id])
                        {
                            strip_user_weapons(id) //double-pistol bugfix
                            static Float:fBuyOrigin[3];
                            pev(id, pev_origin, fBuyOrigin)


                            if(bShield[id])
                            {
                                formatex(SzParaphrase, charsmax(SzParaphrase), "%n returned %n's %s.", iBotOwner[id], id, "shield");
                                client_print iBotOwner[id], print_chat,  SzParaphrase
                                give_item(id, "weapon_shield");
                                bShield[id] = false
                            }
                            if(bDefuser[id])
                            {
                                bDefuser[id] = false
                                formatex(SzParaphrase, charsmax(SzParaphrase), "%n returned %n's %s.", iBotOwner[id], id, "defuser");
                                client_print iBotOwner[id], print_chat,  SzParaphrase
                                @give_defuser(id)
                            }


                            for (new iArms = CSW_P228; iArms <= CSW_LAST_WEAPON; iArms++)
                            {
                                if(g_BackPack[id] & 1<<iArms)
                                if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
                                {
                                    if(!equal(SzWeaponClassname, "weapon_c4") || !equal(SzWeaponClassname, "weapon_null"))
                                    {
                                        give_item(id, SzWeaponClassname)

                                        if(containi(SzWeaponClassname, "item_")!=charsmin)
                                            replace(SzWeaponClassname, charsmax(SzWeaponClassname), "item_", "")
                                        if(containi(SzWeaponClassname, "weapon_")!=charsmin)
                                            replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")

                                        is_user_connected(iBotOwner[id]) ? formatex(SzParaphrase, charsmax(SzParaphrase), "%n returned %n's %s.", iBotOwner[id], id, SzWeaponClassname) :
                                        formatex(SzParaphrase, charsmax(SzParaphrase), "Disconnected player returned %n's %s.", id, SzWeaponClassname)
                                        client_print( 0, print_chat,  SzParaphrase);
                                    }
                                }
                            }

                            if(iDust && is_user_connected(iBotOwner[id]))
                            {
                                emessage_begin_f( iDust > 1 ? MSG_BROADCAST : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Float:{0,0,0},  iDust > 1 ? 0 : iBotOwner[id]);
                                ewrite_byte(TE_PARTICLEBURST)
                                ewrite_coord_f(fBuyOrigin[0])
                                ewrite_coord_f(fBuyOrigin[1])
                                ewrite_coord_f(fBuyOrigin[2])
                                ewrite_short(500)//(radius)
                                ewrite_byte(random(256))
                                ewrite_byte(MAX_IP_LENGTH * 10) //(duration * 10) (will be randomized a bit)
                                emessage_end()
                            }

                            RECLAIM:
                            iBotOwned[id] = 0;
                            is_user_connected(iBotOwner[id]) ?
                            client_print( 0, print_chat, "%n is no longer owned by %n.", id, iBotOwner[id])
                            : client_print( 0, print_chat, "%n is no longer owned by human.", id)

                            if(g_iTempCash[id])
                                cs_set_user_money(id, g_iTempCash[id], 0);

                            bIsCtrl[id] = false;
                        }
                    }
                }
            }
        }
        set_task(2.0, "@check_arms", id)
    }
}

public round_start()
{
    new freeze = get_pcvar_num(g_freeze);
    set_task(freeze?1.0:freeze*1.0, "@cool")

    if(g_bot_controllers )
    {
        client_print 0, print_chat, "%i bots were purchased last round!", g_bot_controllers
    }
    for(new iPlayer; iPlayer <= iMaxplayers ; ++iPlayer)
        iBotOwner[iPlayer] = 0;
    g_bot_controllers = 0;
}

@cool()
{
    cool_down_active = false;
}

public round_end()
{
    set_msg_block( g_cor, BLOCK_NOT );
    cool_down_active = true
    g_c4_client = 0;
    for(new iPlayer; iPlayer <= iMaxplayers ; ++iPlayer)
    {
        respawner[iPlayer] = 0;
        bBotOwner[iPlayer] = false;
        if( g_JustTook[iPlayer] )
        {
             g_JustTook[iPlayer] = false
        }
    }
}

public purchase_respawn(Client)
{
    static name[MAX_PLAYERS];
    new iCost = get_pcvar_num(g_item_cost);
    if(!is_user_alive(Client))
    {
        get_user_name(Client,name,charsmax(name));
        static tmp_money; tmp_money = cs_get_user_money(Client);

        if (!bBotOwner[Client])
        {
            if(tmp_money < iCost)
            {
                client_print(Client, print_center, "You can't afford a 'bot respawn' %s!", name);
                client_print(Client, print_chat, SzAdvertSale,iCost)
                return PLUGIN_HANDLED;
            }
            else
            {
                cs_set_user_money(Client, tmp_money - iCost);
                bBotOwner[Client] = true;
                client_print(Client, print_center, "You bought a 'bot respawn'!");
            }
        }
    }
    return PLUGIN_HANDLED;
}

@buy_bot(dead_spec)
{
    if(is_user_connected(dead_spec))
    {
        alive_bot = entity_get_int(dead_spec, EV_INT_iuser2)
        if(!bIsBound[dead_spec])
        {
            bIsBound[dead_spec] = true
            client_print dead_spec, print_chat, "You have bot control set up!"
        }
        purchase_respawn(dead_spec)
        if ( !cool_down_active && bBotOwner[dead_spec])
        if(is_user_connected(dead_spec) && !bIsVip[alive_bot])
        {
            if(!bIsBot[dead_spec] && !is_user_alive(dead_spec))
            {
                if(is_user_alive(alive_bot))
                if(get_user_team(dead_spec) == get_user_team(alive_bot))
                {
                    if(!bIsCtrl[alive_bot])
                    {
                        get_user_name(alive_bot,bots_name,charsmax(bots_name))
                        client_print(dead_spec, print_center,"Ready to control %s.", bots_name);

                        entity_get_vector(alive_bot, EV_VEC_angles, g_Angles[alive_bot]);
                        entity_get_vector(alive_bot, EV_VEC_view_ofs, g_Plane[alive_bot]);
                        entity_get_vector(alive_bot, EV_VEC_punchangle, g_Punch[alive_bot]);
                        entity_get_vector(alive_bot, EV_VEC_v_angle, g_Vangle[alive_bot]);
                        entity_get_vector(alive_bot, EV_VEC_movedir, g_Mdir[alive_bot]);

                        g_Duck[alive_bot] = entity_get_int(alive_bot, EV_INT_bInDuck);

                        pev(alive_bot, pev_oldorigin, g_Ouser_origin[alive_bot]);
                        pev(alive_bot, pev_origin, g_user_origin[alive_bot]);

                        bDucking[alive_bot] = pev(alive_bot, pev_flags) & FL_DUCKING  ? true : false;
                    }
                    control_bot(dead_spec);
                }
            }
        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED
}

public control_bot(dead_spec)
{
    new respawns; respawns = get_pcvar_num(g_times)
    if(!is_user_alive(dead_spec))
    {
        alive_bot = entity_get_int(dead_spec, EV_INT_iuser2)
        if(is_user_alive(alive_bot))
        {
            #define IS_THERE (~(1<<IN_SCORE))

            if(!bIsVip[alive_bot])//Could move to NULL ORIGIN etc.

            if(get_user_team(dead_spec) == get_user_team(alive_bot))

            if(respawner[dead_spec] > respawns)
            {
                client_print dead_spec, print_chat, "%s", szMsg
                client_cmd dead_spec, "spk ^"sorry^";play ^"fvox/blip^""
                return PLUGIN_HANDLED
            }
            get_user_velocity(alive_bot, vec)
            if(bIsBot[alive_bot]  || !bIsBot[alive_bot] && get_pcvar_num(g_humans) && (/*AFK*/!vec[0] && !vec[1] && !vec[2]))
            {
                set_user_rendering(alive_bot, kRenderFxNone, 0, 0, 0, kRenderTransTexture,0)
                entity_set_int(dead_spec, EV_INT_fixangle, 1)
                g_JustTook[dead_spec] = true
                ExecuteHamB(Ham_CS_RoundRespawn, dead_spec);
                g_BackPack[alive_bot] = entity_get_int(alive_bot, EV_INT_weapons)
                bShield[alive_bot]= cs_get_user_shield(alive_bot) ? true : false
                bBotUser[dead_spec] = true
                strip_user_weapons(dead_spec)
                bIsCtrl[alive_bot] = true

                new iHP = get_user_health(alive_bot)
                set_user_health(dead_spec, iHP)
                iBotOwned[dead_spec] = alive_bot;
                @give_weapons(dead_spec, alive_bot)

                iBotOwner[alive_bot] = dead_spec;
                set_msg_block( g_cor, BLOCK_SET );

                client_print(dead_spec, print_center,"You are now taking the place of %n", alive_bot);
                client_print(0, print_chat,"%n is taking the place of %n", dead_spec, alive_bot);
                entity_set_vector(dead_spec, EV_VEC_angles, g_Angles[alive_bot]);


                set_pev(dead_spec, pev_origin, g_user_origin[alive_bot])


                entity_set_int(dead_spec, EV_INT_bInDuck, g_Duck[alive_bot])

                if(bDucking[alive_bot])
                {
                    set_pev(dead_spec, pev_flags, pev(dead_spec, pev_flags) | FL_DUCKING)
                    bDucking[alive_bot] = false
                }

                set_pev(dead_spec, pev_origin, g_user_origin[alive_bot])

                entity_set_vector(dead_spec, EV_VEC_view_ofs, g_Plane[alive_bot]);
                entity_set_vector(dead_spec, EV_VEC_punchangle, g_Punch[alive_bot]);
                entity_set_vector(dead_spec, EV_VEC_v_angle, g_Vangle[alive_bot]);
                entity_set_vector(dead_spec, EV_VEC_movedir, g_Mdir[alive_bot]);

                entity_set_int(dead_spec, EV_INT_fixangle, 1)
                set_task(2.0, "@check_arms", dead_spec)
                g_bot_controllers++
                respawner[dead_spec]++
            }

        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}

@check_arms(dead_spec) //observed when bot switches to knife then player takes control of them.
{
    if(is_user_alive(dead_spec))
    {
        if(!get_user_weapon(dead_spec))
        {
            log_amx("%N had no weapon.", dead_spec)
            @give_default(dead_spec)
            if(dead_spec == g_c4_client)
            {
                @give_c4(dead_spec)
                log_amx("%N needed the C4.", dead_spec)
            }
        }
    }
}

stock weapon_details(alive_bot)
{
    if(is_user_connected(alive_bot) && is_user_alive(alive_bot))
    {
        wpnid = get_user_weapon(alive_bot, magazine, ammo);
        if(wpnid)
        {
            get_weaponname(wpnid, SzWeaponClassname, charsmax(SzWeaponClassname))
            replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")
            replace(SzWeaponClassname, charsmax(SzWeaponClassname), "item_", "")
            return wpnid, magazine, ammo, SzWeaponClassname;
        }
    }
    wpnid=0,magazine=0,ammo=0,SzWeaponClassname="nothing";
    return wpnid,magazine,ammo,SzWeaponClassname;
}

@give_weapons(dead_spec, alive_bot)
{
    if(is_user_connected(dead_spec) && is_user_alive(alive_bot))
    {
        new wpnid = get_user_weapon(alive_bot)
        if(wpnid)
        {
            weapon_details(alive_bot)
            if(ammo)
            {
                client_print(dead_spec, print_chat, "%n took control of %n's %s. %i in mag, %i bullets total and %i armor.", dead_spec, alive_bot, SzWeaponClassname, magazine, ammo, arm);
            }
        }
        strip_user_weapons(dead_spec)
        if(wpnid & wpnid != CSW_KNIFE && wpnid != CSW_C4)
        {
            cs_set_user_bpammo(dead_spec, wpnid, ammo)
        }

        get_user_velocity(dead_spec, vec)

        #define CSW_LAST_WEAPON     CSW_P90
        #define CSI_DEFUSER             33              // Custom
        #define CSI_NVGS                34              // Custom
        #define OTHER_SCOUT              35              // Custom - The value passed by the forward, more convenient for plugins.
        #define CSW_VESTHELM2             36              // Custom
        #define CSI_SECAMMO             37              // Custom

        if( g_BackPack[alive_bot]  & 1<<CSI_NVGS)
        {
            client_print dead_spec, print_chat, "Night Vision..."
            cs_set_user_nvg(dead_spec, 1)
        }

        if( g_BackPack[alive_bot]  & 1<<CSW_VESTHELM2)
        {
            give_item(dead_spec, SzSuit)
            client_print dead_spec, print_chat, SzSuit
        }

        if( g_BackPack[alive_bot]  & 1<<CSI_DEFUSER)
        {
            give_item(dead_spec, "item_thighpack")
            client_print dead_spec, print_chat, "Possible defuser..."
        }
        if( g_BackPack[alive_bot]  & 1<<CSI_SECAMMO)
        {
            for (new mag; mag < sizeof SzCsAmmo; ++mag)
            {
                give_item(dead_spec, SzCsAmmo[mag]);
                client_print dead_spec, print_chat, "Possible shells showing..."
            }
        }
        if( g_BackPack[alive_bot]  & 1<<CSI_PRIAMMO) //often never scout
        {
            client_print dead_spec, print_chat, "Extra ammo showing."
        }
        if( g_BackPack[alive_bot]  & 1<< OTHER_SCOUT) //scout only
        {
            client_print dead_spec, print_chat, "Scout.."
        }
        for (new iArms = CSW_P228; iArms <= CSW_LAST_WEAPON; iArms++)
        {
            if(g_BackPack[alive_bot]  & 1<<iArms )
            if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
            {
                give_item(dead_spec, SzWeaponClassname)

                if(equal(SzWeaponClassname, "weapon_c4"))
                {
                    cs_set_user_plant(dead_spec, .plant = 1, .showbombicon = 1)
                }
                if(containi(SzWeaponClassname, "item_")!=charsmin)
                    replace(SzWeaponClassname, charsmax(SzWeaponClassname), "item_", "")
                if(containi(SzWeaponClassname, "weapon_")!=charsmin)
                    replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")

                client_print dead_spec, print_chat,  SzWeaponClassname
            }

        }
        if(bShield[alive_bot])
        {
            give_item(dead_spec, "weapon_shield");
        }
        bDefuser[alive_bot] = cs_get_user_defuse(alive_bot) ? true : false;

        if(bDefuser[alive_bot])
        {
            @give_defuser(dead_spec)
            client_print dead_spec, print_chat, "Has defuser..."
        }

        arm = get_user_armor(alive_bot);
        set_user_armor(dead_spec, arm);
        if(is_user_alive(dead_spec))
        {
            if(get_user_weapon(alive_bot) == CSW_C4)
            {
                client_cmd(dead_spec, "weapon_c4")
            }
            strip_user_weapons(alive_bot)
            user_silentkill(alive_bot, 1);
        }
    }
    return PLUGIN_HANDLED
}

@give_defuser(id)
{
    if(is_user_alive(id))
    {
        give_item(id, "item_thighpack")
        cs_set_user_defuse(id, 1)
        client_print id, print_chat, "Issuing defuser."
    }
}

@give_c4(id)
{
    if(is_user_alive(id))
    {
        give_item(id, "weapon_c4")
        cs_set_user_plant(id, .plant = 1, .showbombicon = 1)
        client_print id, print_chat, "Resssuing voided C4."
    }    
}

@give_default(id)
{
    if(is_user_alive(id))
    {
        g_BackPack[id] = get_user_team(id) == 1 ? g_iSpawnBackpackT : g_iSpawnBackpackCT
        for (new iArms = CSW_P228; iArms <= CSW_LAST_WEAPON; iArms++)
        {
            if(g_BackPack[id] & 1<<iArms)
            if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
            {
                if(!equal(SzWeaponClassname, "weapon_c4") || !equal(SzWeaponClassname, "weapon_null"))
                {
                    give_item(id, SzWeaponClassname)

                    if(containi(SzWeaponClassname, "item_")!=charsmin)
                        replace(SzWeaponClassname, charsmax(SzWeaponClassname), "item_", "")
                    if(containi(SzWeaponClassname, "weapon_")!=charsmin)
                        replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")

                    client_print id, print_chat,  SzWeaponClassname
                }
            }
        }
    }
}

//CONDITION ZERO TYPE BOTS. SPiNX
@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity( Ham_Spawn, ham_bot, "@BotSpawn", 1 );
        RegisterHamFromEntity( Ham_Killed, ham_bot, "@died", 1 );
        server_print("Respawn ham bot from %N", ham_bot)
        bRegistered = true;
    }
}
