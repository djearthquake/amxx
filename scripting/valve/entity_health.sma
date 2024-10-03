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

#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util
#include hamsandwich

#define charsmin        -1
#define MAX_PLAYERS     32
#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128

#if !defined MaxClients
new MaxClients
#endif

#if AMXX_VERSION_NUM == 182;
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH]//, buffer[MAX_CMD_LENGTH], SzClass[MAX_CMD_LENGTH]
#endif

new The_Value_Copy[ MAX_CMD_LENGTH ],The_Value_Copy_copywrite[ MAX_CMD_LENGTH ]
#define client_disconnect client_disconnected

new HamHook:XhookDamage,HamHook:XhookDamage_alt
new bool:go_ahead, bool:break_away

new const ents_with_health_native[][]={"func_breakable", "func_pushable"} // "item_airtank"

//new const ents_given_health_or_acct[][]={"func_door", "momentary_door", "func_door_rotating"}

new const REPLACE[][] = {"monster_", "func_", "item_"} //for printing announcments

new g_getakill
new g_teams
new g_SzMonster_class[MAX_NAME_LENGTH];

new bool:g_b_SzKilling_Monster[MAX_PLAYERS + 1]
new bool:bsetTrie

new Trie:g_mnames;

public plugin_init()
{
    #if !defined MaxClients
    MaxClients = get_playersnum()
    #endif

    register_plugin("Entity Health","1.22","SPiNX");
    register_event("Damage","@event_damage","be")
    g_teams            = !cstrike_running() ? get_cvar_pointer("mp_teamplay") : get_cvar_pointer("mp_friendlyfire")

    new log = get_pcvar_num(g_getakill)

    if(log)
    {
        @sub_init()

        if(log > 3)
            log_amx "init"
    }

}

@sub_init()
{
    new ent;new log = get_pcvar_num(g_getakill);if(log>4)log_amx "sub-init"
    //Misc items that carry HP
    for(new list; list < sizeof ents_with_health_native; ++list)
    {
        ent = find_ent(MaxClients,ents_with_health_native[list])

        if(ent > get_maxplayers())
        {
            break_away = true
            static szClass[MAX_NAME_LENGTH]
            pev(ent, pev_classname, szClass, charsmax(szClass))
            log_amx "Found %s", szClass

            XhookDamage_alt = RegisterHamFromEntity(Ham_TakeDamage,ent,"Ham_TakeDamage_player", 1)

            if (!get_pcvar_num(g_getakill))
               DisableHamForward(XhookDamage_alt)

        }
    }
}

@event_damage(id)
{
    #if AMXX_VERSION_NUM == 182;
    new log = get_pcvar_num(g_getakill);if(log>3)log_amx "Damage call from %s", ClientName[id]

    #else
    new log = get_pcvar_num(g_getakill);if(log>3)log_amx "Damage call from %n", id
    #endif

    if(is_user_alive(id))
    {
        new victim = id;new killer = get_user_attacker(victim);
        if(pev_valid(killer) && pev_valid(victim))
        {
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

                        killer != victim ?
                            client_print( 0, print_center, "%s|%i^n^n is being hit by^n^n %s|%i", ClientName[victim], pev(victim,pev_health), ClientName[killer], pev(killer,pev_health) )
                            :
                            client_print( 0, print_center, "%s|%i^n^nis doing it to themself!", ClientName[victim], pev(victim,pev_health) )
                        #else

                        killer != victim ?
                            client_print( 0, print_center, "%n|%i^n^n is being hit by^n^n%n|%i", victim, pev(victim,pev_health), killer, pev(killer,pev_health) )
                            :
                            client_print( 0, print_center, "%n|%i^n^nis doing it to themself!", victim, pev(victim,pev_health) )
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
                        #if AMXX_VERSION_NUM == 182;
                        client_print 0,print_center,"%s is being blasted^n^nby a %s with HP: %i^n^n %s HP:%i",ClientName[victim], g_SzMonster_class, pev(killer,pev_health), ClientName[victim], pev(victim,pev_health)
                        #else
                        client_print 0,print_center,"%n is being blasted^n^nby a %s with HP: %i^n^n%n HP:%i",victim, g_SzMonster_class, pev(killer,pev_health), victim, pev(victim,pev_health)
                        #endif
                }

                else if(containi(g_SzMonster_class, "ammo") > charsmin ||containi(g_SzMonster_class, "item") > charsmin ||containi(g_SzMonster_class, "weapon") > charsmin)
                {
                    #if AMXX_VERSION_NUM == 182;
                    client_print( 0,print_center,"%s is being given^n^n %s", ClientName[victim], g_SzMonster_class)
                    #else
                    client_print( 0,print_center,"%n is being given ^n^n %s", victim, g_SzMonster_class)
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
                        client_print( 0,print_center,"%s is being hit by^n^n %s^n^nfrom %s", ClientName[victim], g_SzMonster_class, temp_local_buffer)
                        #else
                        client_print( 0,print_center,"%n is being hit by^n^n %s^n^nfrom %s", victim, g_SzMonster_class, temp_local_buffer)
                        #endif

                    }
                    else
                    {
                        new shootable = pev(killer,pev_health)
                        #if AMXX_VERSION_NUM == 182;
                        shootable != 0 ?
                        client_print( 0,print_center,"%s is being hit by^n^n %s^n^nwith health %i", ClientName[victim], g_SzMonster_class, shootable)
                        :
                        client_print( 0,print_center,"%s is being attacked by^n^n %s", ClientName[victim], g_SzMonster_class)
                        #else
                        shootable != 0 ?
                        client_print( 0,print_center,"%n is being hit by^n^n %s^n^nwith health %i", victim, g_SzMonster_class, shootable)
                        :
                        client_print( 0,print_center,"%n is being attacked by^n^n %s", victim, g_SzMonster_class)
                        #endif

                    }
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}
#if AMXX_VERSION_NUM == 182;
public client_putinserver(id)
    if(equal(ClientName[id],""))
        get_user_name(id,ClientName[id],charsmax(ClientName[]))
#endif

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

        if((iFlag  || (health - damage) < -10.0) && !g_b_SzKilling_Monster[killer])
        {
            if(pev_valid(this_ent))
                set_pev(this_ent, pev_deadflag, DEAD_DEAD)
            g_b_SzKilling_Monster[killer] = true

            if(iShowKills > 2)
            {

                if(!is_user_bot(this_ent))
                    SetHamParamInteger(5, DMG_ALWAYSGIB) //otherwise multi kills on corpse!
                temp_npc = engfunc(EngFunc_CreateFakeClient,g_SzMonster_class)
                //if(pev_valid(temp_npc)>1) //failing amxx 182
                if(pev_valid(temp_npc))
                {
                    static szRejectReason[128]
                    new effects = pev(temp_npc, pev_effects)
                    dllfunc(DLLFunc_ClientConnect,temp_npc,g_SzMonster_class,"127.0.0.1",szRejectReason)
                    if(is_user_connected(temp_npc))
                    {
                        set_pev(temp_npc, pev_effects, (effects | EF_NODRAW ));
                    }
                    victim = temp_npc
                    log_kill(killer, victim, weapon, 1)
                    pev(this_ent, pev_classname, g_SzMonster_class,charsmax(g_SzMonster_class))
                    @fake_death(victim,idattacker, g_SzMonster_class)

                    if(iShowKills > 3)
                        client_print killer, print_chat, "made a fake player!"

                    return
                }

            }
            if(iShowKills > 1)
            {
                log_kill(killer, victim, weapon, 1)
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

@fake_death(this_ent,idattacker, g_SzMonster_class[MAX_NAME_LENGTH])
{
    for ( new MENT; MENT < sizeof REPLACE; ++MENT )
        replace(g_SzMonster_class,charsmax(g_SzMonster_class), REPLACE[MENT], "");

    if(is_user_alive(idattacker) && !is_user_bot(idattacker) && pev_valid(this_ent))
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
    if(is_user_connected(victim))
    server_cmd( "kick #%d ^"temp_bot^"", get_user_userid(victim) );
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

        emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0}, 0);
        ewrite_byte(killer);
        ewrite_byte(victim);

        if(cstrike_running())
            ewrite_byte(headshot);
        if( (get_pcvar_num(g_teams) == 1 || cstrike_running())
        &&
        equal(killers_team,victims_team))
            ewrite_string("teammate");
        else
            ewrite_string(weapon_name)
        emessage_end();

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
    go_ahead = false

    if(!bsetTrie)
    {
        g_mnames = TrieCreate()
        bsetTrie = true
        g_getakill = register_cvar("monster_kill", "0")

        if(get_pcvar_num(g_getakill) > 3)
        {
            server_print "^n^n^n...Monster Trie made...^n^n"
        }

    }

    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(containi(Classname,"monster") > charsmin || equali(key,"monstertype") || containi(Classname,"monster") > charsmin)
    go_ahead = true

    else
    {
        goto DIVERT
    }
    if(get_pcvar_num(g_getakill) && go_ahead)
    {

        if(containi(Classname,"monster_") > charsmin || equali(key,"monstertype") && go_ahead)
        {
            equali(key,"monstertype") && go_ahead ? copy(The_Value_Copy, charsmax(The_Value_Copy), value) : copy(The_Value_Copy, charsmax(The_Value_Copy), Classname)

            if(equali(The_Value_Copy,"monstermaker") || equali(The_Value_Copy, The_Value_Copy_copywrite))
            goto DIVERT

            if(The_Value_Copy[0] != EOS && containi(The_Value_Copy,"monster_") > charsmin)
            {
                copy(The_Value_Copy_copywrite, charsmax(The_Value_Copy_copywrite), Classname)

                if(TrieKeyExists(g_mnames,The_Value_Copy))
                {
                    log_amx "%s is already in the table.", The_Value_Copy
                    return
                }
                else if(!TrieKeyExists(g_mnames,The_Value_Copy))
                {
                    TrieSetCell(g_mnames,The_Value_Copy,1)
                    log_amx "Found %s.", The_Value_Copy
                }
                new iTemp = 1
                if(TrieGetCell(g_mnames,The_Value_Copy, iTemp) == true)
                {
                    TrieSetCell(g_mnames,The_Value_Copy,2)
                    XhookDamage = RegisterHam(Ham_TakeDamage,The_Value_Copy,"Ham_TakeDamage_player", 1)

                    if(equali(The_Value_Copy,"monster_bigmomma"))
                    {
                        TrieSetCell(g_mnames, "monster_babycrab",2)
                        XhookDamage = RegisterHam(Ham_TakeDamage,"monster_babycrab","Ham_TakeDamage_player", 1)

                        log_amx "Added babycrab!"
                    }
                }
            }
       }
    }
    DIVERT:
}

public plugin_end()
{

    if(bsetTrie)
    {
        if(XhookDamage)
        {
            TrieDestroy(g_mnames)
            DisableHamForward(XhookDamage)
            log_amx "Disabling monster HP"
        }
    }
    if(break_away)
    {
        if(XhookDamage_alt)
        {
            DisableHamForward(XhookDamage_alt)
            log_amx "Disabling breakable HP"
            break_away=false
        }
    }
    go_ahead = false
}

public HamFilter(Ham:which, HamError:err, const reason[])
{
    if (which == Ham_TakeDamage && err == HAM_FUNC_NOT_CONFIGURED)
        return PLUGIN_HANDLED
    return HAM_IGNORED
}
