#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util
#include hamsandwich
#define OP4_OFFSET 43

#define charsmin -1

new npc_ent, g_npc_ent, npc_ent_bind[MAX_NAME_LENGTH]

new const ents_with_health[][]={"func_breakable", "func_pushable", "func_door", "func_door_rotating", "momentary_door"}

new const monster_list1[][]={
"monster_alien_controller",
"monster_alien_grunt",
"monster_alien_slave",
"monster_apache",
"monster_barnacle",
"monster_babycrab",
"monster_barney",
"monster_bigmomma",
"monster_bullchicken",
"monster_cockroach"}

new const monster_list2[][]={
"monster_gargantua",
"monster_gman",
"monster_grunt_repel",
"monster_human_grunt_ally",
"monster_headcrab",
"monster_houndeye",
"monster_human_assassin",
"monster_human_grunt",
"monster_human_grunt_ally",
"monster_human_medic_ally",
"monster_human_torch_ally",
"monster_ichthyosaur",
"monster_leech",
"monster_miniturret",
"monster_nihilanth",
"monster_osprey"
}


new const monster_list3[][]={
"monster_scientist",
"monster_sentry",
"monster_sitting_scientist",
"monster_tentacle",
"monster_turret",
"monster_zombie",

"monster_blkop_apache",
"monster_blkop_osprey",

"monster_shockroach",
"monster_shocktrooper",
"monster_pitdrone",
"monster_gonome"
}

new const REPLACE[][] = {"monster_", "func_"}


public plugin_init()

{
    register_plugin("monsters' hitpoints","1.0","SPiNX");
    g_npc_ent = register_cvar("npc_type", "parachute")

    bind_pcvar_string(g_npc_ent,npc_ent_bind, charsmax(npc_ent_bind))
    npc_ent = find_ent(charsmin,npc_ent_bind)
    RegisterHamFromEntity(Ham_TakeDamage,npc_ent,"Ham_TakeDamage_player", 0) //cvar to test random classes

    register_event("Damage","@event_damage","b") //standard player hp reading

    for(new list; list < sizeof ents_with_health; ++list)
        RegisterHam(Ham_TakeDamage,ents_with_health[list],"Ham_TakeDamage_player", 0) //array of breakables from skeleton key of destruction plugin
    for(new op4; op4 < sizeof monster_list1; op4++)
        RegisterHam(Ham_TakeDamage,monster_list1[op4],"Ham_TakeDamage_player", 0)
    for(new op4; op4 < sizeof monster_list2; op4++)
        RegisterHam(Ham_TakeDamage,monster_list2[op4],"Ham_TakeDamage_player", 0)
    for(new op4; op4 < sizeof monster_list3; op4++)
        RegisterHam(Ham_TakeDamage,monster_list3[op4],"Ham_TakeDamage_player", 0)

}


public Ham_TakeDamage_player(this_ent, ent, idattacker, Float:damage, damagebits)
{
    new SzMonster_class[MAX_NAME_LENGTH]
    entity_get_string(this_ent,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))

    for ( new MENT; MENT < sizeof REPLACE; ++MENT )
        replace(SzMonster_class,charsmax(SzMonster_class), REPLACE[MENT], " ");

    new Float:health = entity_get_float(this_ent,EV_FL_health)

    if ( is_user_connected(idattacker) && !is_user_bot(idattacker) )
    {
        client_print idattacker,print_center,"%s health:%i",SzMonster_class,floatround(health)
        if (health - damage < 1.0 )
        {
            @fake_death(this_ent,idattacker)

            new killer = idattacker
            new victim = this_ent
            new weapon = get_user_weapon(idattacker)
            new temp_npc

            temp_npc = engfunc(EngFunc_CreateFakeClient,SzMonster_class)
            if(temp_npc > 0)
            {
                static szRejectReason[128]
                new effects = pev(temp_npc, pev_effects)
                dllfunc(DLLFunc_ClientConnect,temp_npc,SzMonster_class,"::1",szRejectReason)
                set_pev(temp_npc, pev_effects, (effects | EF_NODRAW ));

                victim = temp_npc
                log_kill(killer,victim ,weapon)

            }

        }

    }

    GetHamReturnStatus() != HAM_SUPERCEDE 
}

public pin_scoreboard(killer)
{
    if(is_user_connected(killer))
    {
        //Scoring
        fm_set_user_frags(killer,get_user_frags(killer) +1);
        #define DEATHS 422
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
@event_damage(id)
{
    new killer = get_user_attacker(id);
    if( is_user_connected(killer) && is_user_alive(killer) && !is_user_bot(killer) )
        client_print(killer,print_center,"%n HP: %i",id, get_user_health(id));
    return PLUGIN_CONTINUE;
}

@fake_death(this_ent,idattacker)
{
    new SzMonster_class[MAX_NAME_LENGTH]
    entity_get_string(this_ent,EV_SZ_classname,SzMonster_class,charsmax(SzMonster_class))

    for ( new MENT; MENT < sizeof REPLACE; ++MENT )
        replace(SzMonster_class,charsmax(SzMonster_class), REPLACE[MENT], "");

    if( is_user_connected(idattacker) && is_user_alive(idattacker) && !is_user_bot(idattacker) && is_valid_ent(this_ent))

    client_print 0, print_center, "%n slayed a %s", idattacker,SzMonster_class
}

stock log_kill(killer, victim, weapon)
{
    new weapon_name[MAX_NAME_LENGTH]
    if(is_user_connected(killer))
    {

        get_weaponname(weapon,weapon_name,charsmax(weapon_name))

        emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0}, 0);
        ewrite_byte(killer);
        ewrite_byte(victim);
        ewrite_string(weapon_name)
        emessage_end();

        //Logging the message as seen on console.
        new kname[MAX_PLAYERS+1], kauthid[MAX_PLAYERS+1]

        get_user_name(killer, kname, charsmax(kname))

        get_user_authid(killer, kauthid, charsmax(kauthid))

        log_message("^"%s<%d><%s>^" killed ^"%s^" with ^"%s^"",
        kname, get_user_userid(killer), kauthid, victim, weapon)
        pin_scoreboard(killer)
        set_task(0.5,"@disco",victim)
        
    }

}

@disco(victim)
server_cmd( "kick #%d ^"temp_bot^"", get_user_userid(victim) );
