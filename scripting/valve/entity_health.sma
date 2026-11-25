///Maps with monsters can load other custom maps. Some stock maps like boot_camp and op4_demise which are vanilla crash server later even with disabled hooks!

/*
 * entity_health.sma
 * CVAR: monster_kills 0|1|2|3|4
 * //1 show hp/kill | 2 show death messages, what weapon | 3 get frags |
 *   4 debugger
 *
 * Copyright 2021 SPiNX <>
 *
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

/*
2021-11-09  SPiNX  <>

 *V1.2 Optimize. Register ents based off map contents.
 *V1.1 Add monsters and frags.
 * Some maps like boot_camp and any with env_message crash later even several maps loads in the future until server only registers ham damage with small number of hooks with breakable and pushables and
maybe a few monsters.
 * Couple dozen monsters added to Ham Damage from any map before even dsabled hooks it crashes maps with 'env_message' or ones like boot_camp, and varrock. Unknown reasons for those 2. Other maps larger
and more contents do not do this.
 *
 *V1.0 Merge breakable HP with player HP script.
*/


new HamHook:XhookDamage_alt[8]
new g_AltHookCount
new g_szLastMap[32]
new bool:go_ahead

#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util
#include hamsandwich

#define charsmin        -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))
#define MAX_PLAYERS     32
#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128

#if AMXX_VERSION_NUM == 182;
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH], buffer[MAX_CMD_LENGTH], SzClass[MAX_CMD_LENGTH];
#endif

new The_Value_Copy[ MAX_CMD_LENGTH ],The_Value_Copy_copywrite[ MAX_CMD_LENGTH ]
#define client_disconnect client_disconnected

new const ents_with_health_native[][]={"func_breakable", "func_pushable"} // "item_airtank"

//new const ents_given_health_or_acct[][]={"func_door", "momentary_door", "func_door_rotating"}

new const REPLACE[][] = {"monster_", "func_", "item_"} //for printing announcments

new g_getakill;
new g_busy;
new g_teamtype;
new g_teams
new g_MsgTeamInfo
new g_AI, g_Adm
new g_SzMonster_class[MAX_NAME_LENGTH]

new bool:g_b_SzKilling_Monster[MAX_PLAYERS + 1]
new bool:bsetTrie

new Trie:g_mnames

public plugin_init()
{
    register_plugin("Entity Health","1.58","SPiNX");
    register_event("Damage","@event_damage","be")
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Pre", 0)
    register_forward(FM_ServerDeactivate, "OnServerDeactivate_Post", 1)
    g_teams       = !cstrike_running() ? get_cvar_pointer("mp_teamplay") : get_cvar_pointer("mp_friendlyfire")
    g_getakill    = register_cvar("monster_kill", "0")
    g_busy        = register_cvar("monster_kill_busy", "5")
    g_teamtype    = register_cvar("monster_kill_teams", "1")
    g_MsgTeamInfo = get_user_msgid("TeamInfo")

    set_task(0.2, "monster_scan", 42420, .flags="b")
    register_forward(FM_TraceLine, "OnTraceLine_Post", 1)
    new log = get_pcvar_num(g_getakill)
    if(log)
    {
        @sub_init()
        if(log > 3)
            log_amx "init"
    }
}

@scan_monsters()
{
    // Monster Ham_TakeDamage hooks crash this HLDS/ReHLDS engine on map change.
    // Keep monster-kills-player (Ham_Killed on player) and breakable HP only.
    return
}

stock clear_alt_hooks()
{
    // Keep alt hooks registered/enabled across maps to avoid HamSandwich corruption.
}

@sub_init()
{
    new ent;new log = get_pcvar_num(g_getakill);if(log>4)log_amx "sub-init"
    if(g_AltHookCount == 0)
    {
        //Misc items that carry HP
        for(new list; list < sizeof ents_with_health_native; ++list)
        {
            ent = find_ent(charsmin,ents_with_health_native[list])

            if(ent > get_maxplayers() && g_AltHookCount < sizeof XhookDamage_alt)
            {
                log_amx "Found %s", ents_with_health_native[list]

                #if AMXX_VERSION_NUM == 182
                XhookDamage_alt[g_AltHookCount] = RegisterHam(Ham_TakeDamage,ents_with_health_native[list],"Ham_TakeDamage_player", 1)
                #else
                XhookDamage_alt[g_AltHookCount] = RegisterHamFromEntity(Ham_TakeDamage,ent,"Ham_TakeDamage_player", 1)
                #endif
                if(XhookDamage_alt[g_AltHookCount])
                    g_AltHookCount++
            }
        }
    }
    @scan_monsters()
}

@event_damage(id)
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        #if AMXX_VERSION_NUM == 182;
        new log = get_pcvar_num(g_getakill);if(log>3)log_amx "Damage call from %s", ClientName[id]

        #else
        new log = get_pcvar_num(g_getakill);if(log>3)log_amx "Damage call from %n", id
        #endif
        new victim = id;new killer = get_user_attacker(victim);
        new bool:busy = get_playersnum() > get_pcvar_num(g_busy);
        if(pev_valid(killer) && pev_valid(victim))
        {
            //new health = pev(victim,pev_health)
            entity_get_string(victim,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))

            if (killer == victim && is_user_alive(killer) && !is_user_bot(killer))
                client_print killer,print_center,"CAREFUL!"

            else
            {
                if(pev_valid(killer) || pev_valid(victim) && is_user_connected(killer))
                    entity_get_string(killer,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))

                if(equali(g_SzMonster_class, "player") && is_user_connected(victim))
                {
                    if(is_user_connected(killer) && is_user_connected(victim))
                    {
                        #if AMXX_VERSION_NUM == 182;

                        {
                            if(killer != victim)
                            {
                                if(busy)
                                {
                                    client_print( victim, print_center, "%s|%i^n^n is being hit by^n^n %s|%i", ClientName[victim], pev(victim,pev_health), ClientName[killer], pev(killer,pev_health) )
                                    if(is_user_connected(killer))
                                        client_print( killer, print_center, "%s|%i^n^n is being hit by^n^n %s|%i", ClientName[victim], pev(victim,pev_health), ClientName[killer], pev(killer,pev_health) )
                                }
                                else
                                    client_print( 0, print_center, "%s|%i^n^n is being hit by^n^n %s|%i", ClientName[victim], pev(victim,pev_health), ClientName[killer], pev(killer,pev_health) )
                            }
                            else
                                client_print( busy ? victim : 0, print_center, "%s|%i^n^nis doing it to themself!", ClientName[victim], pev(victim,pev_health) )
                        }
                        #else

                        {
                            if(killer != victim)
                            {
                                if(busy)
                                {
                                    client_print( victim, print_center, "%n|%i^n^n is being hit by^n^n%n|%i", victim, pev(victim,pev_health), killer, pev(killer,pev_health) )
                                    if(is_user_connected(killer))
                                        client_print( killer, print_center, "%n|%i^n^n is being hit by^n^n%n|%i", victim, pev(victim,pev_health), killer, pev(killer,pev_health) )
                                }
                                else
                                    client_print( 0, print_center, "%n|%i^n^n is being hit by^n^n%n|%i", victim, pev(victim,pev_health), killer, pev(killer,pev_health) )
                            }
                            else
                                client_print( busy ? victim : 0, print_center, "%n|%i^n^nis doing it to themself!", victim, pev(victim,pev_health) )
                        }
                        #endif
                    }
                    else
                    {
                        server_print "Attack trap caught!"
                        log_amx "Attack trap caught!"
                    }

                }
                else if(containi(g_SzMonster_class, "monster") > charsmin)
                {
                    if(pev_valid(victim))
                    {
                        #if AMXX_VERSION_NUM == 182;
                        client_print(busy ? victim : 0,print_center,"%s is being blasted^n^nby a %s with HP: %i^n^n %s HP:%i",ClientName[victim], g_SzMonster_class, pev(killer,pev_health), ClientName[victim], pev(victim,pev_health))
                        #else
                        client_print(busy ? victim : 0,print_center,"%n is being blasted^n^nby a %s with HP: %i^n^n%n HP:%i",victim, g_SzMonster_class, pev(killer,pev_health), victim, pev(victim,pev_health))
                        #endif
                    }

                    if(get_pcvar_num(g_getakill) > 2 && pev_valid(killer) && (!is_user_alive(victim) || get_user_health(victim) < 1))
                    {
                        static szName[MAX_NAME_LENGTH]
                        copy(szName, charsmax(szName), g_SzMonster_class)
                        for ( new MENT; MENT < sizeof REPLACE; ++MENT )
                            replace(szName, charsmax(szName), REPLACE[MENT], "");
                        new szRejectReason[128]
                        new fake = engfunc(EngFunc_CreateFakeClient, szName)
                        if(pev_valid(fake))
                        {
                            dllfunc(DLLFunc_ClientConnect, fake, szName, "127.0.0.1", szRejectReason)
                            dllfunc(DLLFunc_ClientPutInServer, fake)
                            set_pev(fake, pev_effects, pev(fake, pev_effects) | EF_NODRAW)
                            emessage_begin(MSG_BROADCAST, g_MsgTeamInfo)
                            ewrite_byte(fake)
                            ewrite_string("Monsters")
                            emessage_end()
                        }
                        if(fake && is_user_connected(fake))
                        {
                            fm_set_user_frags(fake, get_user_frags(fake) + 1)
                            emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
                            ewrite_byte(fake)
                            ewrite_short(get_user_frags(fake))
                            ewrite_short(get_user_deaths(fake))
                            if(cstrike_running())
                            {
                                ewrite_short(0)
                                ewrite_short(get_user_team(fake))
                            }
                            emessage_end()
                        }
                    }
                }

                else if(containi(g_SzMonster_class, "ammo") > charsmin ||containi(g_SzMonster_class, "item") > charsmin ||containi(g_SzMonster_class, "weapon") > charsmin)
                {
                    #if AMXX_VERSION_NUM == 182;
                    client_print( busy ? victim : 0,print_center,"%s is being given^n^n %s", ClientName[victim], g_SzMonster_class
                    #else
                    client_print( busy ? victim : 0,print_center,"%n is being given ^n^n %s", victim, g_SzMonster_class)
                    #endif
                }
                else
                {
                    new temp_local_buffer[32]
                    new Shooter = pev(killer,pev_owner)
                    if(pev_valid(Shooter))
                    {
                        entity_get_string(Shooter,EV_SZ_classname,temp_local_buffer,charsmax(temp_local_buffer))
                        #if AMXX_VERSION_NUM == 182;
                        client_print( busy ? victim : 0,print_center,"%s is being hit by^n^n %s^n^nfrom %s", ClientName[victim], g_SzMonster_class, temp_local_buffer)
                        #else
                        client_print( busy ? victim : 0,print_center,"%n is being hit by^n^n %s^n^nfrom %s", victim, g_SzMonster_class, temp_local_buffer)
                        #endif

                    }
                    else
                    {
                        new shootable = pev(killer,pev_health)
                        #if AMXX_VERSION_NUM == 182;
                        shootable != 0 ?
                        client_print( busy ? victim : 0,print_center,"%s is being hit by^n^n %s^n^nwith health %i", ClientName[victim], g_SzMonster_class, shootable)
                        :
                        client_print( busy ? victim : 0,print_center,"%s is being attacked by^n^n %s", ClientName[victim], g_SzMonster_class)
                        #else
                        shootable != 0 ?
                        client_print( busy ? victim : 0,print_center,"%n is being hit by^n^n %s^n^nwith health %i", victim, g_SzMonster_class, shootable)
                        :
                        client_print( busy ? victim : 0,print_center,"%n is being attacked by^n^n %s", victim, g_SzMonster_class)
                        #endif

                    }
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
#if AMXX_VERSION_NUM == 182;
    if(equal(ClientName[id],""))
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
#endif
    set_team_label(id)
}

stock get_monster_npc(const szName[])
{
    static name[MAX_NAME_LENGTH], szRejectReason[128]
    new maxp = get_maxplayers()
    for(new id = 1; id <= maxp; id++)
    {
        if(!is_user_connected(id))
            continue
        get_user_name(id, name, charsmax(name))
        if(equal(name, szName))
            return id
    }

    new fake = engfunc(EngFunc_CreateFakeClient, szName)
    if(!pev_valid(fake))
        return 0

    dllfunc(DLLFunc_ClientConnect, fake, szName, "127.0.0.1", szRejectReason)
    dllfunc(DLLFunc_ClientPutInServer, fake)
    if(!is_user_connected(fake))
        return 0

    set_pev(fake, pev_effects, pev(fake, pev_effects) | EF_NODRAW)
    emessage_begin(MSG_BROADCAST, g_MsgTeamInfo)
    ewrite_byte(fake)
    ewrite_string("Monsters")
    emessage_end()
    return fake
}

public fw_PlayerKilled_Pre(victim, attacker, shouldgib)
{
    if(!is_user_connected(victim))
        return HAM_IGNORED

    new iShowKills = get_pcvar_num(g_getakill)
    if(iShowKills < 3)
        return HAM_IGNORED

    if(!pev_valid(attacker))
        return HAM_IGNORED

    static cls[MAX_NAME_LENGTH]
    pev(attacker, pev_classname, cls, charsmax(cls))
    if(containi(cls, "monster_") <= charsmin && containi(cls, "mortar") == -1)
        return HAM_IGNORED

    static szName[MAX_NAME_LENGTH]
    copy(szName, charsmax(szName), cls)
    for (new MENT; MENT < sizeof REPLACE; ++MENT)
        replace(szName, charsmax(szName), REPLACE[MENT], "");

    new fake = get_monster_npc(szName)
    if(fake && is_user_connected(fake))
    {
        fm_set_user_frags(fake, get_user_frags(fake) + 1)

        // Block engine self-kill DeathMsg, send corrected one
        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
        message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
        write_byte(fake)
        write_byte(victim)
        write_string(szName)
        message_end()

        emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
        ewrite_byte(fake)
        ewrite_short(get_user_frags(fake))
        ewrite_short(get_user_deaths(fake))
        if(cstrike_running())
        {
            ewrite_short(0)
            ewrite_short(get_user_team(fake))
        }
        emessage_end()
    }
    return HAM_IGNORED
}

public Ham_TakeDamage_player(this_ent, ent, idattacker, Float:damage, damagebits)
{
    new iShowKills = get_pcvar_num(g_getakill)
    if(iShowKills)
    if(is_user_alive(idattacker) && idattacker != this_ent)
    {
    #if AMXX_VERSION_NUM == 182;
        if(equal(ClientName[idattacker],""))
            get_user_name(idattacker,ClientName[idattacker],charsmax(ClientName[]))
    #endif

        entity_get_string(this_ent,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))

        for ( new MENT; MENT < sizeof REPLACE; ++MENT )
            replace(g_SzMonster_class,charsmax(g_SzMonster_class), REPLACE[MENT], "");

        new Float:health = entity_get_float(this_ent,EV_FL_health)
        new killer = idattacker
        new victim = this_ent
        new temp_npc
        new weapon = get_user_weapon(killer)
        new iFlag = pev(victim, pev_deadflag)

        if(!iFlag && (health - damage) < -10.0 && !g_b_SzKilling_Monster[killer])
        {
            g_b_SzKilling_Monster[killer] = true

            if(iShowKills > 2)
            {
                /*
                if(!is_user_bot(this_ent))
                    SetHamParamInteger(5, DMG_ALWAYSGIB) //otherwise multi kills on corpse!*/
                temp_npc = engfunc(EngFunc_CreateFakeClient,g_SzMonster_class)
                if(pev_valid(temp_npc))
                {
                    static szRejectReason[128]
                    dllfunc(DLLFunc_ClientConnect,temp_npc,g_SzMonster_class,"127.0.0.1",szRejectReason)
                    dllfunc(DLLFunc_ClientPutInServer,temp_npc)
                    set_pev(temp_npc, pev_effects, pev(temp_npc, pev_effects) | EF_NODRAW)
                    emessage_begin(MSG_BROADCAST, g_MsgTeamInfo)
                    ewrite_byte(temp_npc)
                    ewrite_string("Monsters")
                    emessage_end()
                    victim = temp_npc
                    log_kill(killer, victim, weapon, 1)
                    @fake_death(victim,idattacker)
                    return
                }

            }
            if(iShowKills > 1)
            {
                log_kill(killer, victim, weapon, 1)
                set_task(1.0,"@ok",killer)
                return
            }

        }

    }

    GetHamReturnStatus() != HAM_SUPERCEDE
}


public pin_scoreboard(killer, victim)
{
    if(is_user_connected(killer) && get_pcvar_num(g_getakill) > 2)
    {
        //Scoring
        fm_set_user_frags(killer,get_user_frags(killer) +1);
        #define DEATHS 422 //OP4 CS
        new deaths = get_pdata_int(killer, DEATHS)
        new frags = get_user_frags(killer)

        emessage_begin(MSG_BROADCAST,get_user_msgid("ScoreInfo"))
        ewrite_byte(killer);
        ewrite_short(frags)
        ewrite_short(deaths)

        if(cstrike_running()) //if(is_running("cstrike") == 1) //missed CZ!
        {
            ewrite_short(0); //TFC CLASS
            ewrite_short(get_user_team(killer));
        }
        emessage_end();

        if(get_pcvar_num(g_getakill) > 3)
            client_print killer, print_chat, "monster kill counted!"
    }

}

@fake_death(this_ent,idattacker)
{
    static cls[MAX_NAME_LENGTH]
    entity_get_string(this_ent,EV_SZ_classname,cls,charsmax(cls))
    if(!equal(cls, "player"))
    {
        copy(g_SzMonster_class, charsmax(g_SzMonster_class), cls)
        for ( new MENT; MENT < sizeof REPLACE; ++MENT )
            replace(g_SzMonster_class,charsmax(g_SzMonster_class), REPLACE[MENT], "");
    }

    if( is_user_connected(idattacker) && is_user_alive(idattacker) && !is_user_bot(idattacker) && pev_valid(this_ent)>1)
    #if AMXX_VERSION_NUM == 182;
    client_print 0, print_center, "%s slayed a %s", ClientName[idattacker],g_SzMonster_class
    #else
    client_print 0, print_center, "%n slayed a %s", idattacker,g_SzMonster_class
    #endif

    set_task(1.0,"@ok",idattacker)
    set_task(0.5,"@disco",this_ent)
}

@disco(victim)
{
    // Keep fake player around so it can hold scoreboard frags.
    // It will be cleared on map change.
    if(is_user_connected(victim))
        return;
}


@ok(killer)
if(is_user_connected(killer))
{
    g_b_SzKilling_Monster[killer] = false
}

stock log_kill(killer, victim, weapon, headshot)
{
    new weapon_name[MAX_NAME_LENGTH]

    new killers_team[MAX_PLAYERS], victims_team[MAX_PLAYERS];
    get_user_team(killer, killers_team, charsmax(killers_team));
    get_user_team(victim, victims_team, charsmax(victims_team));

    if(is_user_connected(killer))
    {
        get_weaponname(weapon,weapon_name,charsmax(weapon_name))

        replace(weapon_name, charsmax(weapon_name), "weapon_", "")

        message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"));
        write_byte(killer);
        write_byte(victim);

        if(cstrike_running())
            write_byte(headshot);
        if( (get_pcvar_num(g_teams) == 1 || cstrike_running())
        &&
        equal(killers_team,victims_team))
            write_string("teammate");
        else
            write_string(weapon_name)
        message_end();

        //Logging the message as seen on console.
        new kname[MAX_PLAYERS+1], kauthid[MAX_PLAYERS+1]
        get_user_authid(killer, kauthid, charsmax(kauthid))
        get_user_name(killer, kname, charsmax(kname))
        log_message("^"%s<%d><%s>^" killed ^"%s^" with ^"%s^"", kname, get_user_userid(killer), kauthid, g_SzMonster_class, weapon_name)
        if(get_pcvar_num(g_getakill) > 1)
        {
            pin_scoreboard(killer, victim)

        }

    }

}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    go_ahead = false

    static szMap[32]
    get_mapname(szMap, charsmax(szMap))
    if(!equal(szMap, g_szLastMap))
    {
        clear_monster_hooks()
        copy(g_szLastMap, charsmax(g_szLastMap), szMap)
        if(containi(szMap, "boot") > charsmin)
        {
            server_print szMap
            pause("a")
        }
    }

    if(!bsetTrie)
    {
        g_getakill = register_cvar("monster_kill", "0")
        g_mnames = TrieCreate()
        bsetTrie = true
        if(get_pcvar_num(g_getakill) > 3)
            server_print "^n^n^n...Monster Trie made...^n^n"
    }

    if(containi(Classname,"monster") > charsmin || equali(key,"monstertype"))
        go_ahead = true
    else
        goto DIVERT

    if(go_ahead && get_pcvar_num(g_getakill) > 0)
    {
        equali(key,"monstertype") ? copy(The_Value_Copy, charsmax(The_Value_Copy), value) : copy(The_Value_Copy, charsmax(The_Value_Copy), Classname)

        if(equali(The_Value_Copy,"monstermaker") || equali(The_Value_Copy, The_Value_Copy_copywrite))
            goto DIVERT

        if(The_Value_Copy[0] != EOS && containi(The_Value_Copy,"monster_") > charsmin)
        {
            copy(The_Value_Copy_copywrite, charsmax(The_Value_Copy_copywrite), Classname)

            // Monster Ham_TakeDamage hooks disabled: unstable on this HLDS engine.
            if(!TrieKeyExists(g_mnames,The_Value_Copy))
            {
                TrieSetCell(g_mnames,The_Value_Copy,0)
                log_amx "Found %s (monster hook skipped).", The_Value_Copy
            }
        }
    }
    DIVERT:
}

stock clear_monster_hooks()
{
    // Keep monster hooks registered/enabled across maps to avoid HamSandwich
    // disable/re-enable corruption on this engine. Handler guards by cvar/state.
    clear_alt_hooks()
}

stock set_team_label(id)
{
    if(!get_pcvar_num(g_teamtype) || !is_user_connected(id))
        return

    static team[16]
    team[0] = 0
    if(is_user_bot(id)) { SetPlayerBit(g_AI, id); copy(team, charsmax(team), "Bots"); }
    else { ClearPlayerBit(g_AI, id); }

    if(is_user_admin(id)) { SetPlayerBit(g_Adm, id); copy(team, charsmax(team), "Admins"); }
    else { ClearPlayerBit(g_Adm, id); }

    if(pev(id, pev_flags) & FL_SPECTATOR)
        copy(team, charsmax(team), "Specs")

    if(team[0])
    {
        emessage_begin(MSG_BROADCAST, g_MsgTeamInfo)
        ewrite_byte(id)
        ewrite_string(team)
        emessage_end()
    }
}

public client_infochanged(id)
{
    if(is_user_connected(id))
        set_team_label(id)
}

public OnTraceLine_Post(const Float:v1[3], const Float:v2[3], noMonsters, pentToSkip, tr)
{
    if(get_pcvar_num(g_getakill) < 2)
        return FMRES_IGNORED

    new hit = get_tr2(tr, TR_pHit)
    if(hit < 1 || !pev_valid(hit))
        return FMRES_IGNORED

    static classname[MAX_NAME_LENGTH]
    pev(hit, pev_classname, classname, charsmax(classname))
    if(containi(classname, "monster_") <= charsmin && containi(classname, "mortar") == -1)
        return FMRES_IGNORED
    if(equali(classname, "monstermaker"))
        return FMRES_IGNORED

    new attacker = pentToSkip
    if(!(1 <= attacker <= get_maxplayers()))
    {
        if(pev_valid(attacker))
            attacker = pev(attacker, pev_owner)
    }
    if(1 <= attacker <= get_maxplayers() && is_user_connected(attacker))
        set_pev(hit, pev_iuser3, attacker)

    return FMRES_IGNORED
}

public monster_scan()
{
    new iShowKills = get_pcvar_num(g_getakill)
    if(iShowKills < 2)
        return

    static classname[MAX_NAME_LENGTH], szName[MAX_NAME_LENGTH]
    new maxents = get_global_int(GL_maxEntities)
    new maxp = get_maxplayers()

    for(new ent = 1; ent <= maxents; ent++)
    {
        if(!pev_valid(ent))
            continue

        new mark = pev(ent, pev_iuser4)
        if(mark == 4242)
            continue

        pev(ent, pev_classname, classname, charsmax(classname))
        if(containi(classname, "monster_") <= charsmin && containi(classname, "mortar") == -1)
            continue
        if(equali(classname, "monstermaker"))
            continue

        new deadflag = pev(ent, pev_deadflag)
        if(deadflag == DEAD_NO)
        {
            new inflictor = pev(ent, pev_dmg_inflictor)
            new cand = inflictor
            if(!(1 <= cand <= maxp))
            {
                if(pev_valid(inflictor))
                    cand = pev(inflictor, pev_owner)
            }
            if(!(1 <= cand <= maxp))
                cand = pev(ent, pev_enemy)
            if(1 <= cand <= maxp && is_user_connected(cand))
                set_pev(ent, pev_iuser3, cand)
            continue
        }

        new attacker = pev(ent, pev_iuser3)
        if(!is_user_connected(attacker))
        {
            attacker = pev(ent, pev_dmg_inflictor)
            if(!(1 <= attacker <= maxp))
            {
                if(pev_valid(attacker))
                    attacker = pev(attacker, pev_owner)
            }
        }
        if(!(1 <= attacker <= maxp))
            attacker = pev(ent, pev_enemy)
        if(!(1 <= attacker <= maxp))
            attacker = pev(ent, pev_owner)
        if(!is_user_connected(attacker))
        {
            if(mark != 4243 && get_pcvar_num(g_getakill) > 3)
            {
                new di = pev(ent, pev_dmg_inflictor)
                log_amx("monster_scan: no attacker for %s iuser3=%d inflictor=%d enemy=%d owner=%d", classname, pev(ent, pev_iuser3), di, pev(ent, pev_enemy), pev(ent, pev_owner))
                set_pev(ent, pev_iuser4, 4243)
            }
            continue
        }

        set_pev(ent, pev_iuser4, 4242)
        if(get_pcvar_num(g_getakill) > 3)
            log_amx("monster_scan: crediting %s to %d", classname, attacker)

        if(g_b_SzKilling_Monster[attacker])
            continue
        g_b_SzKilling_Monster[attacker] = true

        copy(szName, charsmax(szName), classname)
        for(new MENT; MENT < sizeof REPLACE; ++MENT)
            replace(szName, charsmax(szName), REPLACE[MENT], "")
        copy(g_SzMonster_class, charsmax(g_SzMonster_class), szName)

        new weapon = get_user_weapon(attacker)
        new victim = get_monster_npc(szName)
        if(victim && is_user_connected(victim))
        {
            log_kill(attacker, victim, weapon, 1)
            @fake_death(victim, attacker)
        }
        else
        {
            log_kill(attacker, ent, weapon, 1)
            set_task(1.0, "@ok", attacker)
        }
    }
}

public OnServerDeactivate_Post()
{
    clear_monster_hooks()
    clear_alt_hooks()
}

public plugin_pause()
{
    clear_monster_hooks()
    clear_alt_hooks()
}

public plugin_unpause()
{
    if(get_pcvar_num(g_getakill) > 0)
        @sub_init()
}

public plugin_end()
{
    clear_monster_hooks()
    if(bsetTrie)
    {
        TrieDestroy(g_mnames)
        bsetTrie = false
    }
    clear_alt_hooks()
    go_ahead = false
}

/*
public HamFilter(Ham:which, HamError:err, const reason[])
{
    if (which == Ham_TakeDamage && err == HAM_FUNC_NOT_CONFIGURED)
        return PLUGIN_HANDLED
    return HAM_IGNORED
}*/
