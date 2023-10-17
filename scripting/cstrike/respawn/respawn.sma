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
*    Copyleft (C) Nov 2020-2023 .sρiηX҉.
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
*
*
*/

#include amxmodx
#include amxmisc
#include cstrike
#include engine
#include fakemeta
#include fakemeta_util
#include fun
#include hamsandwich

#include unstick
//CZ install instructions. Per Ham install this plugin first.
#define SPEC_PRG    "cs_ham_bots_api.amxx"
#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/czero/AI"

#include cs_ham_bots_api //COMMENT OUT WITH // TO PLAY REGULAR CS.
//#tryinclude cs_ham_bots_api

#define FRICTION_NOT    1.0
#define FRICTION_MUD    1.8
#define FRICTION_ICE    0.3

#define charsmin -1
#define MAX_NAME_LENGTH 32


new
//Cvars
g_dust, g_humans, g_keep, g_sound_reminder, g_stuck,
//Strings
SzWeaponClassname[MAX_NAME_LENGTH], bots_name[ MAX_NAME_LENGTH + 1 ],
//Integers
iSpawnBackpackCT, iSpawnBackpackT, iBotOwned[MAX_PLAYERS+1], iBotOwner[MAX_PLAYERS+1], alive_bot, arm, ammo, magazine, wpnid, iMaxplayers,

//Global variables
g_Ouser_origin[MAX_PLAYERS + 1][3], g_Duck[MAX_PLAYERS + 1], g_BackPack[MAX_PLAYERS + 1], g_cor,
g_counter[ MAX_PLAYERS + 1 ], g_iTempCash[MAX_PLAYERS + 1],

//Floats
Float:vec[3], Float:g_Angles[MAX_PLAYERS + 1][3], Float:g_Plane[MAX_PLAYERS + 1][3], Float:g_Punch[MAX_PLAYERS + 1][3], Float:g_Vangle[MAX_PLAYERS + 1][3], Float:g_Mdir[MAX_PLAYERS + 1][3],
Float:g_Velocity[MAX_PLAYERS + 1][3], Float:g_user_origin[MAX_PLAYERS + 1][3],

//Bools
bool:bIsBot[MAX_PLAYERS + 1], bool:bIsCtrl[MAX_PLAYERS + 1], bool:bBotUser[MAX_PLAYERS + 1], bool:g_JustTook[MAX_PLAYERS + 1], bool:cool_down_active, bool:bIsBound[MAX_PLAYERS + 1],
bool:bIsVip[MAX_PLAYERS + 1];

new const SzSuit[]="item_assaultsuit"

new const SzCsAmmo[][]=
{
    "ammo_9mm",
    "ammo_357sig",
    "ammo_57mm",
    "ammo_45acp",
    "ammo_50ae"
}

new const SzAdvert[]="Bind impulse 206 to control bot."
new const SzAdvertAll[]="Bind impulse 206 to control bot/AFK human."

public plugin_precache()
{
    //fail-safe although plugin is expected to stop before hand like this.
    /////[AMXX] Plugin "respawn.amxx" failed to load: Module/Library "cs_ham_bots_api" required for plugin.  Check modules.ini.
    if (is_running("czero"))
    {
        if(is_plugin_loaded(SPEC_PRG,true) == charsmin)
        {
            log_amx("%s must be installed! %s", SPEC_PRG, URL)
            pause("c")
        }
        else
        {
            RegisterHamBots(Ham_Spawn, "@PlayerSpawn");
            RegisterHamBots(Ham_Killed, "@died")
        }
    }
}

public plugin_init()
{
    register_plugin("Repawn from bots", "1.3", "SPiNX");
    //cvars
    g_dust = register_cvar("respawn_dust", "1")
    g_humans = register_cvar("respawn_humans", "1");
    g_keep = register_cvar("respawn_keep", "0")
    g_sound_reminder = register_cvar("respawn_sound", "1")
    g_stuck = register_cvar("respawn_unstick", "0.3");
    //Ham
    RegisterHam(Ham_Spawn, "weaponbox", "@_weaponbox", 1)
    RegisterHam(Ham_Spawn, "player", "@PlayerSpawn");
    RegisterHam(Ham_Killed, "player", "@died")
    //Events
    register_event("ResetHUD", "@BotSpawn", "bg")
    register_logevent("round_start", 2, "1=Round_Start")
    register_logevent("round_end", 2, "1=Round_End")
    //control
    register_impulse(206,"@buy_bot")
    //Misc
    iMaxplayers = get_maxplayers()
    g_cor = get_user_msgid( "ClCorpse" )
    bIsCtrl[0] = true
}

@died(id)
{
    if(is_user_connected(id) && !cool_down_active && !bIsBound[id])
        client_print id, print_chat, get_pcvar_num(g_humans) ? SzAdvertAll : SzAdvert
}

public client_putinserver(id)
{
    bIsBot[id] = is_user_connected(id) && is_user_bot(id)
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
    if(is_user_connected(bot) && bIsCtrl[bot])
    {
        g_iTempCash[bot] = cs_get_user_money(bot)
        cs_set_user_money(bot, 0, 0)
        if(is_user_alive(bot))strip_user_weapons(bot)
    }
}

@PlayerSpawn(id)
{
    if(is_user_connected(id))
    {
        bIsVip[id] = cs_get_user_vip(id) ? true : false

        if(!g_JustTook[id])
            set_task(0.1,"@ReSpawn", id)
    }
}

@ReSpawn(id)
{
    static iDefaultTeamPack,
    SzParaphrase[128], iDust, iKeep, iSound;
    iDust = get_pcvar_num(g_dust), iKeep = get_pcvar_num(g_keep), iSound = get_pcvar_num(g_sound_reminder);
    if(is_user_alive(id))
    {
        g_BackPack[id] = entity_get_int(id, EV_INT_weapons)
        if(!iSpawnBackpackCT || !iSpawnBackpackT)
        {
            ///if(is_user_alive(id))
            {
                static iTeam; iTeam = get_user_team(id)
                if(iTeam == 1 && !iSpawnBackpackT && !user_has_weapon(id, CSW_C4))
                {
                    iSpawnBackpackT = entity_get_int(id, EV_INT_weapons)
                }
                else if(iTeam == 2 && !iSpawnBackpackCT )
                {
                    iSpawnBackpackCT = entity_get_int(id, EV_INT_weapons)
                }
            }
        }
        if(bIsCtrl[id])
        {
            if(is_user_alive(iBotOwner[id]))
                g_BackPack[id] = g_BackPack[iBotOwner[id]]
            fm_set_kvd(id, "zhlt_lightflags", "0")
            set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 255)

            if(!iKeep)
                goto TRADE
            goto RECLAIM
        }
        if(bBotUser[id])
        {
            if(iSound)
            {
                client_cmd(id, iKeep ? "spk turret/tu_spinup.wav" : "spk turret/tu_spindown.wav")
            }
            if(iKeep > charsmin)
            {
                client_print(id, print_chat, iKeep ?  "Respawn with weapons." : "Normal Respawn.")
            }
            if(!iKeep)
            {
                if(cs_get_user_shield(id))
                {
                    formatex(SzParaphrase, charsmax(SzParaphrase), "%n returned %n's %s.", id, iBotOwned[id], "weapon_shield");
                    client_print iBotOwner[id], print_chat,  SzParaphrase
                    give_item(iBotOwned[id], "weapon_shield");
                }

                iDefaultTeamPack = get_user_team(id) == 1 ? iSpawnBackpackT :  iSpawnBackpackCT
                g_BackPack[id] = entity_get_int(id, EV_INT_weapons)
                if(is_user_alive(id))strip_user_weapons(id)
                for (new iArms = CSW_P228; iArms <= CSW_LAST_WEAPON; iArms++)
                {
                    if(iDefaultTeamPack & 1<<iArms)
                    if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
                    {
                        if(equal(SzWeaponClassname, "weapon_c4"))
                        {
                            return
                        }
                        give_item(id, SzWeaponClassname)

                        client_print id, print_chat,  SzWeaponClassname
                    }
                    TRADE:
                    if(bIsCtrl[id])
                    {
                        strip_user_weapons(id) //double-pistol bugfix
                        new Float:fBuyOrigin[3];
                        pev(id, pev_origin, fBuyOrigin)

                        for (new iArms = CSW_P228; iArms <= CSW_LAST_WEAPON; iArms++)
                        {
                            if(g_BackPack[id] & 1<<iArms)
                            if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
                            {
                                if(equal(SzWeaponClassname, "weapon_c4"))
                                {
                                    return
                                }
                                give_item(id, SzWeaponClassname)

                                formatex(SzParaphrase, charsmax(SzParaphrase), "%n returned %n's %s.", iBotOwner[id], id, SzWeaponClassname);
                                client_print iBotOwner[id], print_chat,  SzParaphrase
                            }
                        }

                        new iBuyOrigin[3];

                        iBuyOrigin[0] = floatround(fBuyOrigin[0]);
                        iBuyOrigin[1] = floatround(fBuyOrigin[1]);
                        iBuyOrigin[2] = floatround(fBuyOrigin[2])
                        if(iDust)
                        {
                            emessage_begin( iDust > 1 ? MSG_BROADCAST : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0},  iDust > 1 ? 0 : iBotOwner[id]);
                            ewrite_byte(TE_PARTICLEBURST)
                            ewrite_coord(iBuyOrigin[0])
                            ewrite_coord(iBuyOrigin[1])
                            ewrite_coord(iBuyOrigin[2])
                            ewrite_short(500)//(radius)
                            ewrite_byte(random(256))
                            ewrite_byte(MAX_IP_LENGTH * 10) //(duration * 10) (will be randomized a bit)
                            emessage_end()
                        }

                        RECLAIM:
                        iBotOwned[id] = 0;
                        client_print 0, print_chat, "%n is no longer owned by %n.", id, iBotOwner[id]

                        if(g_iTempCash[id])
                            cs_set_user_money(id, g_iTempCash[id], 0);

                        iBotOwner[id] = 0;
                        bIsCtrl[id] = false;
                    }
                }
            }
            bBotUser[id] = false;
        }
    }
}

public round_start()
{
    cool_down_active = false
    set_msg_block( g_cor, BLOCK_NOT );
}

public round_end()
{
    cool_down_active = true
    for(new iPlayer = 1 ; iPlayer <= iMaxplayers ; ++iPlayer)
    {
        if( g_JustTook[iPlayer] )
        {
             g_JustTook[iPlayer] = false
        }
    }
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

        if ( !cool_down_active )
        if(is_user_connected(dead_spec) && !bIsVip[alive_bot])
        {
            if(!bIsBot[dead_spec] && !is_user_alive(dead_spec))
            {
                if(is_user_connected(alive_bot))
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
                    }
                    control_bot(dead_spec);
                }
            }
        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED
}

@_weaponbox(iNofreelunch)
{
    new iPlayer = pev(iNofreelunch, pev_owner);
    if(!is_user_alive(iPlayer) && pev_valid(iNofreelunch))
    {
        if(bIsCtrl[iPlayer])
        {
            set_pev(iNofreelunch, pev_flags, FL_KILLME);
            fm_set_kvd(iPlayer, "zhlt_lightflags", "1")
        }
    }
}

public control_bot(dead_spec)
{
    if(!is_user_alive(dead_spec))
    {
        alive_bot = entity_get_int(dead_spec, EV_INT_iuser2)
        if(alive_bot <= 0)
            return PLUGIN_HANDLED_MAIN

        if(is_user_alive(alive_bot))
        {
            #define IS_THERE (~(1<<IN_SCORE))

            if(!bIsVip[alive_bot])

            if(get_user_team(dead_spec) == get_user_team(alive_bot))
            get_user_velocity(alive_bot, vec)
            if(bIsBot[alive_bot]  && pev(alive_bot, pev_button) &~IN_ATTACK || !bIsBot[alive_bot] && get_pcvar_num(g_humans) && (vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0) && pev(alive_bot, pev_flags) & FL_ONGROUND)
            {
                set_user_rendering(alive_bot, kRenderFxNone, 0, 0, 0, kRenderTransTexture,0)
                entity_set_int(dead_spec, EV_INT_fixangle, 1)
                g_JustTook[dead_spec] = true
                ExecuteHamB(Ham_CS_RoundRespawn, dead_spec);
                g_BackPack[alive_bot] = entity_get_int(alive_bot, EV_INT_weapons)
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
                entity_set_vector(dead_spec, EV_VEC_view_ofs, g_Plane[alive_bot]);
                entity_set_vector(dead_spec, EV_VEC_punchangle, g_Punch[alive_bot]);
                entity_set_vector(dead_spec, EV_VEC_v_angle, g_Vangle[alive_bot]);
                entity_set_vector(dead_spec, EV_VEC_movedir, g_Mdir[alive_bot]);
                set_pev(dead_spec, pev_origin, g_user_origin[alive_bot])
                entity_set_int(dead_spec, EV_INT_bInDuck, g_Duck[alive_bot])

                set_pev(dead_spec, pev_origin, g_user_origin[alive_bot])
                entity_set_int(dead_spec, EV_INT_fixangle, 0)
            }
        }
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_HANDLED;
}

stock weapon_details(alive_bot)
{
    if(is_user_connected(alive_bot) && is_user_alive(alive_bot))
    {
        wpnid = get_user_weapon(alive_bot, magazine, ammo);
        get_weaponname(wpnid, SzWeaponClassname, charsmax(SzWeaponClassname))
        replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")
        return wpnid, magazine, ammo, SzWeaponClassname;
    }
    return wpnid=0,magazine=0,ammo=0,SzWeaponClassname;
}

@give_weapons(dead_spec, alive_bot)
{
    if(is_user_connected(dead_spec) && is_user_alive(alive_bot))
    {
        weapon_details(alive_bot)
        strip_user_weapons(dead_spec)
        if(wpnid != CSW_KNIFE)
        {
            cs_set_user_bpammo(dead_spec, wpnid, ammo)
        }

        client_print(dead_spec, print_chat, "%n took control of %n's %s. %i in mag, %i bullets total and %i armor.", dead_spec, alive_bot, SzWeaponClassname, magazine, ammo, arm);

        get_user_velocity(dead_spec, vec)

        if(vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0)
        {
            set_task(get_pcvar_num(g_stuck)*1.0, "stuck_timer", dead_spec)
        }

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
                    cs_set_user_plant(dead_spec, 1, 1)
                client_print dead_spec, print_chat,  SzWeaponClassname
            }
        }

        if(cs_get_user_shield(alive_bot))
            give_item(dead_spec, "weapon_shield");

        arm = get_user_armor(alive_bot);
        set_user_armor(dead_spec, arm);
        if(is_user_alive(dead_spec))strip_user_weapons(alive_bot)
        user_silentkill(alive_bot, 1);
    }
}

public stuck_timer(dead_spec)
{
    if(is_user_connected(dead_spec) && is_user_alive(dead_spec))
    {
        pev(dead_spec, pev_velocity, g_Velocity[dead_spec])
        if(g_Velocity[dead_spec][0] == 0.0 || g_Velocity[dead_spec][1] == 0.0 )
        {
            @stuck(dead_spec)
            if(g_counter[dead_spec] >= MAX_PLAYERS)
            {
                ExecuteHamB(Ham_CS_RoundRespawn, dead_spec);
                client_print dead_spec, print_chat, "Respawned due to being stuck!"
                g_counter[dead_spec] = 0
                remove_task(dead_spec)
            }

        }
        else
        {
            remove_task(dead_spec)
            entity_set_float(dead_spec, EV_FL_friction, FRICTION_NOT);
        }
    }
}

@stuck(dead_spec)
{
    if(is_user_connected(dead_spec))
    {
        pev(dead_spec, pev_velocity, g_Velocity[dead_spec])
        pev(dead_spec, pev_origin, g_Ouser_origin[dead_spec])

        if(g_Velocity[dead_spec][0] == 0.0 && g_Velocity[dead_spec][1] == 0.0 && g_Velocity[dead_spec][2] == 0.0 )
        {
            unstick(dead_spec, get_pcvar_float(g_stuck))
            entity_set_float(dead_spec, EV_FL_friction, FRICTION_ICE);
            client_cmd(dead_spec, "spk common/menu1.wav")
            g_counter[dead_spec]++
        }

        set_task(get_pcvar_float(g_stuck), "stuck_timer", dead_spec)
    }
}
