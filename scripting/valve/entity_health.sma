/*
 * entity_health.sma
 * CVAR: monster_kills 0|1|2|3
 *  //1 show hp/kill | 2 show death messages, what weapon | 3 get frags
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
 *
 */

/*
2021-11-09  SPiNX  <>

 *V1.2 Optimize. Register ents based off map contents.
 *V1.1 Add monsters and frags.
 *V1.0 Merge breakable HP with player HP script.
*/


new HamHook:hookDamage,HamHook:XhookDamage_alt
new bool:go_ahead

#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util
#include hamsandwich

#define charsmin        -1
#define MAX_CMD_LENGTH 128


new The_Value_Copy[ MAX_CMD_LENGTH ],The_Value_Copy_copywrite[ MAX_CMD_LENGTH ]


new const ents_with_health[][]={"func_breakable", "func_pushable", "item_airtank", "func_door", "momentary_door", "func_door_rotating"} //misc parishables
new const REPLACE[][] = {"monster_", "func_", "item_"} //for printing announcments

new g_getakill;
new g_SzMonster_class[MAX_NAME_LENGTH]
new bool:g_b_SzKilling_Monster[MAX_NAME_LENGTH]

public plugin_init()
{
    register_plugin("Entity Health","1.2","SPiNX");
    register_event("Damage","@event_damage","be")
    log_amx "init"

    if (get_pcvar_num(g_getakill))
        @sub_init()

}

@sub_init()
{
    new ent;
    log_amx "sub-init"
    //Misc items that carry HP
    for(new list; list < sizeof ents_with_health; ++list)
    {
        ent = find_ent(charsmin,ents_with_health[list])

        if(ent > 0)
        {
            log_amx "Found %s", ents_with_health[list]

            #if AMXX_VERSION_NUM == 182
            XhookDamage_alt = RegisterHam(Ham_TakeDamage,ents_with_health[list],"Ham_TakeDamage_player", 1)

            #else
            XhookDamage_alt = RegisterHamFromEntity(Ham_TakeDamage,ent,"Ham_TakeDamage_player", 1)
            #endif

            DisableHamForward(XhookDamage_alt)


        }
    }
}

@event_damage(id)
{
    log_amx "Damage call from %n", id
    if(is_user_alive(id) && id > 0)
    {
        new victim = id;new killer = get_user_attacker(victim);
        if(is_user_connected(killer) || pev_valid(victim) || pev_valid(killer))
        {
            new health = pev(victim,pev_health)
    
            entity_get_string(victim,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))
    
            if( is_user_alive(killer) && !is_user_bot(killer) &&  killer != victim && health < 100)
                client_print killer,print_center,"%n HP: %i",victim, health
    
            else if (killer == victim && is_user_alive(killer) && !is_user_bot(killer))
                client_print killer,print_center,"CAREFUL!"
    
            else
            {
                if(pev_valid(killer) || pev_valid(victim) && is_user_connected(killer))
                    entity_get_string(killer,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))
    
                if(equali(g_SzMonster_class, "player") && is_user_connected(victim))
                {
                    killer != victim ?
                        client_print( 0,print_center,"%n is being hit by %n", victim, killer)
                        :
                        client_print( 0,print_center,"%n is doing it to themself!", victim)
                }
                else if(containi(g_SzMonster_class, "monster") >> charsmin == victim)
                {
                    if(pev_valid(victim))
                        client_print 0,print_center,"%n is being blasted^n^nby a %s with HP: %i",victim, g_SzMonster_class, pev(victim,pev_health)
                }
    
                else
                {
                    new temp_local_buffer[32]
                    new Shooter = pev(killer,pev_owner)
                    if(pev_valid(Shooter))
                    {
                        entity_get_string(Shooter,EV_SZ_classname,temp_local_buffer,charsmax(temp_local_buffer))
                        client_print( 0,print_center,"%n is being hit by^n^n %s^n^nfrom %s", victim, g_SzMonster_class, temp_local_buffer)
                    }
                    else
                    {
                        new shootable = pev(killer,pev_health)
                        shootable != 0 ?
                        client_print( 0,print_center,"%n is being hit by^n^n %s^n^nwith health %i", victim, g_SzMonster_class, shootable)
                        :
                        client_print( 0,print_center,"%n is being attacked by^n^n %s", victim, g_SzMonster_class)
    
                    }
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}


public Ham_TakeDamage_player(this_ent, ent, idattacker, Float:damage, damagebits)
{
    if(hookDamage)
    {
        if (get_pcvar_num(g_getakill))
        {
            server_print "Enabling hook damage"
            EnableHamForward(hookDamage)
        }

        else 
            DisableHamForward(hookDamage)
    }

    if(XhookDamage_alt)
    {
        if (XhookDamage_alt && get_pcvar_num(g_getakill) > 1)
        {
            server_print "Enabling hook alt damage"
            EnableHamForward(XhookDamage_alt)
        }
        else
            DisableHamForward(XhookDamage_alt)
    }

    if(is_user_alive(idattacker) && idattacker != this_ent)
    {
    #if AMXX_VERSION_NUM == 182;
        if(equal(ClientName[idattacker],""))
            get_user_name(idattacker,ClientName[idattacker],charsmax(ClientName[]))
            //attempt fix blank names amxx182. Establish when they shoot not connect/putinserver bug avoidance.
    #endif

        entity_get_string(this_ent,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))

        for ( new MENT; MENT < sizeof REPLACE; ++MENT )
            replace(g_SzMonster_class,charsmax(g_SzMonster_class), REPLACE[MENT], " ");

        new Float:health = entity_get_float(this_ent,EV_FL_health)
        new killer = idattacker
        new victim = this_ent
        new temp_npc
        new weapon = get_user_weapon(killer)
        if(is_user_connected(killer) && !is_user_bot(killer) && victim != killer && health > 0.0 )
            client_print killer,print_center,"%s health:%i",g_SzMonster_class, floatround(health)

        if (health - damage < -2.0 && !g_b_SzKilling_Monster[killer])
        {
            g_b_SzKilling_Monster[killer] = true

            if(get_pcvar_num(g_getakill) > 0)
            {
                @fake_death(this_ent,idattacker)
            }


            if (get_pcvar_num(g_getakill) > 1)
            {
                @fake_death(this_ent,idattacker)
                if(!is_user_bot(this_ent))
                    SetHamParamInteger(5, DMG_ALWAYSGIB) //otherwise multi kills on corpse!
                temp_npc = engfunc(EngFunc_CreateFakeClient,g_SzMonster_class)
                if(temp_npc > 0)
                {
                    static szRejectReason[128]
                    new effects = pev(temp_npc, pev_effects)
                    dllfunc(DLLFunc_ClientConnect,temp_npc,g_SzMonster_class,"::1",szRejectReason)
                    set_pev(temp_npc, pev_effects, (effects | EF_NODRAW ));

                    victim = temp_npc
                    log_kill(killer,victim ,weapon)

                }

            }

        }

    }

    GetHamReturnStatus() != HAM_SUPERCEDE
}


public pin_scoreboard(killer)
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

        if(is_running("cstrike") == 1)
        {
            ewrite_short(0); //TFC CLASS
            ewrite_short(get_user_team(killer));
        }
        emessage_end();
    }

}

@fake_death(this_ent,idattacker)
{
    entity_get_string(this_ent,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))

    for ( new MENT; MENT < sizeof REPLACE; ++MENT )
        replace(g_SzMonster_class,charsmax(g_SzMonster_class), REPLACE[MENT], "");

    if( is_user_connected(idattacker) && is_user_alive(idattacker) && !is_user_bot(idattacker) && is_valid_ent(this_ent))
    #if AMXX_VERSION_NUM == 182;
    client_print 0, print_center, "%s slayed a %s", ClientName[idattacker],g_SzMonster_class //amxx182 code
    #else
    client_print 0, print_center, "%n slayed a %s", idattacker,g_SzMonster_class
    #endif

}

@disco(victim)
    server_cmd( "kick #%d ^"temp_bot^"", get_user_userid(victim) );

@ok(killer)
    if (is_user_connected(killer))
        g_b_SzKilling_Monster[killer] = false

stock log_kill(killer, victim, weapon)
{
    new weapon_name[MAX_NAME_LENGTH]

    if(is_user_connected(killer))
    {

        get_weaponname(weapon,weapon_name,charsmax(weapon_name))

        replace(weapon_name, charsmax(weapon_name), "weapon_", "")

        emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0}, 0);
        ewrite_byte(killer);
        ewrite_byte(victim);
        ewrite_string(weapon_name)
        emessage_end();

        //Logging the message as seen on console.
        new kname[MAX_PLAYERS+1], kauthid[MAX_PLAYERS+1]
        get_user_authid(killer, kauthid, charsmax(kauthid))
        get_user_name(killer, kname, charsmax(kname))

        log_message("^"%s<%d><%s>^" killed ^"%s^" with ^"%s^"", kname, get_user_userid(killer), kauthid, g_SzMonster_class, weapon_name)
        if(get_pcvar_num(g_getakill) > 1)
        {
            pin_scoreboard(killer)
            set_task(0.5,"@disco",victim)
            set_task(0.5,"@ok",killer)
        }

    }

}


//Prior to init
public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    if(containi(Classname,"monster") > charsmin) go_ahead=true

    g_getakill = register_cvar("monster_kill", "0")

    if (get_pcvar_num(g_getakill) && go_ahead)
    {


        if(containi(Classname,"monster_") > charsmin || equali(key,"monstertype"))

        {

            equali(key,"monstertype") ? copy(The_Value_Copy, charsmax(The_Value_Copy), value) : copy(The_Value_Copy, charsmax(The_Value_Copy), Classname)

            if(equali(The_Value_Copy,"monstermaker") || equali(The_Value_Copy, The_Value_Copy_copywrite))
            goto DIVERT

            if(containi(The_Value_Copy,"monster_") > charsmin)
                copy(The_Value_Copy_copywrite, charsmax(The_Value_Copy_copywrite), Classname)
            log_amx("Found %s", The_Value_Copy)
                
            //////////////////////KEEPS BOOT_CAMP ETC FROM CRASH LOADING////////////////////////////
            if(containi(Classname,"monster_") == charsmin || !equali(key,"monstertype")) goto DIVERT
            ////////////////////////////////////////////////////////////////////////////////////////
            hookDamage = RegisterHam(Ham_TakeDamage,The_Value_Copy,"Ham_TakeDamage_player", 1)
            DisableHamForward(hookDamage)



        }
        return PLUGIN_CONTINUE  


    }
    DIVERT: 

    return PLUGIN_CONTINUE  

}

public plugin_end()
{
    if(hookDamage)
        DisableHamForward(hookDamage)

    if(XhookDamage_alt)
        DisableHamForward(XhookDamage_alt)
}


public HamFilter(Ham:which, HamError:err, const reason[])
/*FUTURESTATE:https://wiki.alliedmods.net/HamSandwich_General_Usage_(AMX_Mod_X)#Config_File_Requirements*/
return PLUGIN_HANDLED
