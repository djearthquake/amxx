/*
 * entity_health.sma
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

#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta
#include fakemeta_util
#include hamsandwich

#define charsmin        -1
#define MAX_CMD_LENGTH 128


new g_value[ MAX_CMD_LENGTH ],g_value_copywrite[ MAX_CMD_LENGTH ]


new const ents_with_health[][]={"func_breakable", "func_pushable", "item_airtank"} //misc items with HP
new const REPLACE[][] = {"monster_", "func_", "item_"} //for printing announcments

new g_getakill;
new g_SzMonster_class[MAX_NAME_LENGTH]
new bool:g_b_SzKilling_Monster[MAX_NAME_LENGTH]

public plugin_init()
{
    register_plugin("Entity Health","1.2","SPiNX");

    //Hook for clients standard player hp reading
    register_event("Damage","@event_damage","b")
    g_getakill = register_cvar("monster_kill", "3") //1 show hp/kill | 2 show death messages, what weapon | 3 get frags
    @sub_init()

}

@sub_init()
{
    //Misc items that carry HP
    for(new list; list < sizeof ents_with_health; ++list)
    if(find_ent(charsmin,ents_with_health[list]))
    {
        server_print "Entities with HP on map:^n^n%s", ents_with_health[list]
        log_amx "Found %s", ents_with_health[list]

        #if AMXX_VERSION_NUM == 182
        RegisterHam(Ham_TakeDamage,ents_with_health[list],"Ham_TakeDamage_player", 1)
        #else
        RegisterHam(Ham_TakeDamage,ents_with_health[list],"Ham_TakeDamage_player", 1, true)
        #endif
    }
}

@event_damage(id)
{
    new victim = id;new killer = get_user_attacker(victim);
    new health = get_user_health(victim)
    if( is_user_alive(killer) && !is_user_bot(killer) &&  killer != victim && health < 100)
        client_print killer,print_center,"%n HP: %i",victim, health

    else if (killer == victim && is_user_alive(killer) && !is_user_bot(killer))
        client_print killer,print_center,"CAREFUL!"

    return PLUGIN_CONTINUE;
}


public Ham_TakeDamage_player(this_ent, ent, idattacker, Float:damage, damagebits)
{
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

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    /*Copy the monsters*/
    if(containi(Classname,"monster_") > charsmin || equali(key,"monstertype"))
    {

        equali(key,"monstertype") ? copy(g_value, charsmax(g_value), value) : copy(g_value, charsmax(g_value), Classname)

        if(equali(g_value,"monstermaker") || equali(g_value, g_value_copywrite))
            return //Minimize multiple entries

        if(containi(g_value,"monster_") > charsmin)
            copy(g_value_copywrite, charsmax(g_value_copywrite), Classname)

        server_print "Monsters on map are:^n^n%s", g_value
        log_amx "Found %s", g_value

        //register map specific monsters to show HP, announce frags, show deaths, account for frags
        #if AMXX_VERSION_NUM == 182
        RegisterHam(Ham_TakeDamage,g_value,"Ham_TakeDamage_player", 1)
        #else
        RegisterHam(Ham_TakeDamage,g_value,"Ham_TakeDamage_player", 1, true)
        #endif
    }


}
