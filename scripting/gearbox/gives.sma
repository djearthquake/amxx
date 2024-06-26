#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <engine_stocks>
#include <fakemeta>
#include <fun>

#define MAX_NAME_LENGTH 32
#define MAX_CMD_LENGTH 128
#define charsmin        -1

//Comment out for regular HL. Define for OP4 to include powerups.
#define OP4
#if defined OP4

new
    bool:bBackpack,
    bool:bRegeneration,
    bool:bPortablehev,
    bool:bLongjump,
    bool:bAccelerator;

new g_cvar, g_cvar_gg;

new const g_szPowerup_sounds[][] = { "items/ammopickup1.wav", "ctf/itemthrow.wav","ctf/pow_armor_charge.wav","ctf/pow_backpack.wav","ctf/pow_health_charge.wav","turret/tu_ping.wav"};

public plugin_precache()
{
    precache_model("models/can.mdl")
    precache_model("models/w_accelerator.mdl")
    precache_model("models/w_backpack.mdl")
    precache_model("models/w_porthev.mdl")
    precache_model("models/w_jumppack.mdl")
    precache_model("models/w_health.mdl")

    precache_sound("doors/aliendoor3.wav");
    precache_model("models/w_oxygen.mdl");

    for(new szSounds;szSounds < sizeof g_szPowerup_sounds;++szSounds)
        precache_sound(g_szPowerup_sounds[szSounds]);
}
#endif

new const GIVES[][]=
{
    #if defined OP4
    "item_ctfbackpack",
    "item_ctfregeneration",
    "item_ctfportablehev",
    "item_ctflongjump",
    "item_ctfaccelerator",
    /*"item_airtank",*/
    "weapon_pipewrench",
    "weapon_penguin",
    "weapon_knife",
    "weapon_shockrifle",
    "weapon_sporelauncher",
    "weapon_m249",
    "weapon_grapple",
    "weapon_eagle",
    "weapon_sniperrifle",
    "weapon_displacer",
    #endif
    "weapon_rpg",
    "ammo_9mmbox",
    "ammo_9mmAR",
    "ammo_ARgrenades",
    "ammo_crossbow",
    "ammo_gaussclip",
    "ammo_rpgclip",
    "ammo_buckshot",
    "item_longjump",
    "weapon_357",
    "weapon_9mmAR",
    /*"weapon_crossbow",*/
    "weapon_crowbar",
    "weapon_egon",
    "weapon_gauss",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
    "weapon_9mmhandgun"
};

new const szWeapons[][]=
{
    "item_ctfbackpack",
    "item_ctfregeneration",
    "item_ctfportablehev",
    "item_ctflongjump",
    "item_ctfaccelerator",
    "item_airtank",
    "item_longjump",
    "weapon_pipewrench",
    "weapon_penguin",
    "weapon_knife",
    "weapon_shockrifle",
    "weapon_sporelauncher",
    "weapon_m249",
    "weapon_grapple",
    "weapon_eagle",
    "weapon_sniperrifle",
    "weapon_displacer",
    "weapon_rpg",
    "ammo_556",
    "ammo_762",
    "ammo_357",
    "ammo_9mmclip",
    "ammo_9mmbox",
    "ammo_9mmAR",
    "ammo_ARgrenades",
    "ammo_crossbow",
    "ammo_gaussclip",
    "ammo_rpgclip",
    "ammo_buckshot",
    "ammo_spore",
    "item_longjump",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_crossbow",
    "weapon_crowbar",
    "weapon_egon",
    "weapon_gauss",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
    "weapon_9mmhandgun"
};

new const REPLACE[][] = {"ammo_", "weapon_", "item_"};
new const tracer[]= "func_recharge"; //armour

new g_event

public plugin_init()
{
    register_plugin("Gives random weapon(s) on spawn.", "B1", ".sρiηX҉.");
    g_event = register_event_ex ( "ResetHUD" , "client_getfreestuff", RegisterEventFlags: RegisterEvent_Single|RegisterEvent_OnlyAlive)
    g_cvar = register_cvar("gives_mapclean", "1")
}

public plugin_cfg()
{
    static mname[MAX_NAME_LENGTH];
    get_mapname(mname,charsmax(mname));

    if(get_pcvar_num(g_cvar))
        set_task(0.1,"@remove")
    else
        containi(mname,"op4c") > charsmin || find_ent(charsmin,tracer) ?  disable_event(g_event) : enable_event(g_event)
}

public client_getfreestuff(id)
{
    g_cvar_gg = get_cvar_num("gg_enabled")
    if(is_user_connected(id) && !g_cvar_gg)
    {
        if(is_user_admin(id))
        {
            #if !defined set_task_ex
            set_task(5.0, "reward", id, _, _, "a", 4);
            #else
            set_task_ex(5.0, "reward", id, .flags = SetTask_RepeatTimes, .repeat = 4);
            #endif
        }
        else
            #if !defined set_task_ex
            set_task(10.0, "reward", id, _, _, "a", 2);
            #else
            set_task_ex(10.0, "reward", id, .flags = SetTask_RepeatTimes, .repeat = 2);
            #endif

        if(!is_user_bot(id))
            client_print id, print_chat, "Free random items on spawn!"
    }
}

stock truer_random(x)
	return random(x);
	
public reward(needy)
{
    if(is_user_alive(needy))
    {
        static flags; flags = pev(needy, pev_flags)
        if(flags & FL_SPECTATOR)
        {
            server_print("Spec, %n does not need weaponry!", needy)
            remove_task(needy)
            return
        }
        static charity[MAX_NAME_LENGTH];
        formatex(charity, charsmax(charity), GIVES[truer_random(sizeof(GIVES))]);
        {
            #if defined OP4
            //power-up control
            if(containi(charity, "ctf") > charsmin)
            {
                if(equali(charity,"item_ctfbackpack"))
                {
                    if(bBackpack)
                        goto END
                    else
                        bBackpack = true
                }
                if(equali(charity,"item_ctfregeneration"))
                {
                    if(bRegeneration)
                        goto END
                    else
                        bRegeneration = true
                }

                if(equali(charity,"item_ctfportablehev"))
                {
                    if(bPortablehev)
                        goto END
                    else
                        bPortablehev = true
                }
                if(equali(charity,"item_ctflongjump"))
                {
                    if(bLongjump)
                        goto END
                    else
                        bLongjump = true
                }

                if(equali(charity,"item_ctfaccelerator"))
                {
                    if(bAccelerator)
                        goto END
                    else
                        bAccelerator = true
                }
            }
            #endif
            give_item(needy, charity);
            for ( new MENT; MENT < sizeof REPLACE; ++MENT )
                replace(charity, charsmax(charity), REPLACE[MENT], " ");

            if(!is_user_bot(needy))
                client_print(needy, print_chat,"^n Free%s!", charity);
        }
        END:
    }

}

@remove()
{
    enable_event(g_event) //weapons given instead on spawn as trade-off.
    server_print "Scanning new map to remove weapons..."
    for(new ent; ent < sizeof szWeapons;++ent)
    if(has_map_ent_class(szWeapons[ent]))
    {
        server_print "Attempting to remove: %s.", szWeapons[ent]
        remove_entity_name(szWeapons[ent])
    }
}
