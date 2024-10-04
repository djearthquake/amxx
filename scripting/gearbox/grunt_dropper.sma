#include amxmodx
#include engine_stocks
#include hamsandwich
#include fakemeta

#define MAX_PLAYERS     32
#define charsmin       -1

#if !defined MaxClients
new MaxClients
#endif

#if !defined MaxClients
MaxClients = get_playersnum()
#endif

static const grunt_sounds[][]=
{
    "hgrunt/affirmative!.wav",
    "hgrunt/affirmative.wav",
    "hgrunt/alert!.wav",
    "hgrunt/alert.wav",
    "hgrunt/got.wav",
    "hgrunt/go!.wav",
    "hgrunt/go.wav",
    "hgrunt/gr_alert1.wav",
    "hgrunt/gr_die1.wav",
    "hgrunt/gr_die2.wav",
    "hgrunt/gr_die3.wav",
    "hgrunt/grenade!.wav",
    "hgrunt/gr_idle1.wav",
    "hgrunt/gr_idle2.wav",
    "hgrunt/gr_idle3.wav",
    "hgrunt/gr_loadtalk.wav",
    "hgrunt/gr_mgun1.wav",
    "hgrunt/gr_mgun2.wav",
    "hgrunt/gr_mgun3.wav",
    "hgrunt/gr_pain1.wav",
    "hgrunt/gr_pain2.wav",
    "hgrunt/gr_pain3.wav",
    "hgrunt/gr_pain4.wav",
    "hgrunt/gr_pain5.wav",
    "hgrunt/gr_reload1.wav",
    "hgrunt/gr_step1.wav",
    "hgrunt/gr_step2.wav",
    "hgrunt/gr_step3.wav",
    "hgrunt/gr_step4.wav",
    "zombie/claw_miss2.wav",
    "zombie/claw_miss1.wav"
};

static g_spot;
new bool:bRegistered;

public plugin_init()
{
    register_plugin("Grunt Dropper","0.2","SPiNX");
    RegisterHam(Ham_TakeDamage, "player", "Event_Damage", 1);
}

public Event_Damage(victim, inflictor, attacker, Float:damage, damagebits)
{
    if(attacker>MaxClients)
    {
        static szClass[MAX_PLAYERS]
        pev(inflictor, pev_classname, szClass, charsmax(szClass))
        if(contain(szClass, "weapon_"))
        {
            replace(szClass, charsmax(szClass), "weapon_", "")
        }
        if(is_user_connected(victim))
        {
            client_print(victim, print_center, "%s did %i",   szClass, floatround(damage))
        }
    }
}

public plugin_precache()
{
    precache_model("models/hgrunt.mdl")
    precache_model("models/gib_hgrunt.mdl")

    for (new list = 1;list < sizeof grunt_sounds;list++)
        precache_sound(grunt_sounds[list])
}

public plugin_cfg()
{
    g_spot = MaxClients;
    set_task(20.0, "@grunt_dropper", 2024, _, _, "b")
}

@grunt_dropper()
{
    if(!find_ent(MaxClients, "monster_human_grunt"))
    {
        static ent; ent = create_entity("monster_human_grunt")
        DispatchSpawn(ent);

        g_spot = find_ent(g_spot, "info_player_deathmatch")
        if(g_spot)
        {
            static Origin[3]
            pev(g_spot, pev_origin, Origin)
            set_pev(ent, pev_origin, Origin)
        }
        else
        {
            g_spot = MaxClients
        }
        if(!bRegistered)
        {
            bRegistered = true
            if(find_ent(MaxClients, "monster_human_grunt"))
            {
                RegisterHamFromEntity(Ham_TakeDamage,ent,"@Ham_TakeDamage", 1)
                RegisterHamFromEntity(Ham_Killed,ent,"@Ham_Died", 1)
                RegisterHamFromEntity(Ham_Spawn,ent,"@Ham_Born", 1)
            }
        }
    }
}

@Ham_TakeDamage(victim, ent, idattacker, Float:damage, damagebits)
{
    if(is_user_connected(idattacker))
    {
        static szClass[MAX_PLAYERS]
        pev(ent, pev_classname, szClass, charsmax(szClass))

        new weapon = get_user_weapon(idattacker)
        if(equal(szClass, "player"))
        {
            get_weaponname(weapon, szClass, charsmax(szClass))
        }

        if(contain(szClass, "weapon_")>charsmin)
        {
            replace(szClass, charsmax(szClass), "weapon_", "")
        }
        client_print(idattacker, print_center, "Grunt hit by %s for %i.", szClass, floatround(damage))
    }
}

@Ham_Died(index)
{
    client_print 0, print_chat, "Grunt died."
    set_pev(index, pev_flags, FL_KILLME)
}

@Ham_Born(index)
{
    client_print 0, print_chat, "Grunt born."
}
