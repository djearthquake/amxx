/******************************************************************************/
#define PLUGIN "Parachute"
#define AUTHOR "SPiNX"
#define VERSION "1.8.2"
/*******************************************************************************
    Original AMX Author: KRoTaL
    Original AMXX Porter: JTP10181
    0.1    Release
    0.1.1  Players can't buy a parachute if they already own one
    0.1.2  Release for AMX MOD X
    0.1.3  Minor changes
    0.1.4  Players lose their parachute if they die
    0.1.5  Added amx_parachute cvar
    0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
    0.1.7  Added amx_parachute <name> | admins with admin level a get a free parachute
    0.1.8  JTP   - Cleaned up code, fixed runtime error
    1.0    JTP   - Should be final version, made it work on basically any mod
    1.1    JTP   - Added Changes from AMX Version 0.1.8
                   Added say give_parachute and parachute_fallspeed cvar
                   Plays the release animation when you touch the ground
                   Added chat responder for automatic help
    1.2    JTP   - Added cvar to disable the detach animation
                   Redid animation code to improve organization
                   Force "walk" animation on players when falling
                   Change users gravity when falling to avoid choppiness
    1.3    JTP   - Upgraded to pCVARs
    1.4    SPiNX - 10/22/19 17:59                  - Revised prethink per 'Invalid entity' run-time error.
           SPiNX - Sun Oct 27 10:24:39 CDT 2019    - Finished testing new install without model install. No crash!
    1.5    SPiNX - Sun 17 May 2020 01:21:55 PM CDT - Auto-parachute! Deployment has a depth CVAR.
    1.6    SPiNX - Sun 17 May 2020 11:41:39 PM CDT - Parachute can be blown up and user freefalls.
    1.7    SPiNX -                                 - Over last few months. Added 3 chutes. Bot or admin or not. Fixed stabily on mods outside of cstrike when chute is shot down.
    1.8    SPiNX - Mon Aug 22 2022 16:00:00 PM CDT - Updated to show admin speed and incorporate Arkshine's wind request properly. Optimize code. Fail-safe for jk_botti crashing servers from breakables.
    1.8.1 SPiNX - Tues Aug 23 2022 07:43:00 AM CDT - Worked on wind not colliding when firing weapon. Stable jk_botti tested.
    1.8.2 SPiNX - Sun 09 Apr 2023 11:12:08 AM CDT - Optimize some natives. Add a couple fail safes.
    1.9    What is it going to be?  Please comment.

  Commands:

    say buy_parachute   -   buys a parachute (CStrike ONLY)
    saw sell_parachute  -   sells your parachute (75% of the purchase price)
    say give_parachute <nick, #userid or @team>  -  gives your parachute to the player

    amx_parachute <nick, #userid or @team>  -  gives a player a free parachute (CStrike ONLY)
    amx_parachute @all  -  gives everyone a free parachute (CStrike ONLY)

    Press +use to slow down your fall.

  Cvars:

    sv_parachute        "1"         - 0: disables the plugin - 1: enables the plugin

    parachute_cost      "1000"      - cost of the parachute (CStrike ONLY)

    parachute_payback   "75"        - how many percent of the parachute cost you get when you sell your parachute
                                      (ie. (75/100) * 1000 = 750$)

    parachute_fallspeed "100"       - speed of the fall when you use the parachute

    parachute_autoadmin "2"         - Admins can automatically deploy chute or allow everybody. 0|off   1|admin     2|all.

    parachute_autorip   "500"       - Depth sensor for automatic deployment of parachute. 1-3150. Depends on map.

    parachute_debug     "0"         - Print out details about breakable chute and fall velocity if an admin.

  Setup (AMXX 1.x):

    Install the amxx file.
    Put the parachute.mdl file in the modname/models/ folder
    Set to free for POD bots to automatically deploy.
    Other bots may not work. Open to Amxx methods to interface such instances.

*******************************************************************************/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#define MAX_PLAYERS                32
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_MENU_LENGTH            512
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_IP_LENGTH              16
#define MAX_USER_INFO_LENGTH       256
#define charsmin                  -1

#define Parachute_size  0.1

new bool:has_parachute[ MAX_PLAYERS +1 ], bool:bIsBot[ MAX_PLAYERS + 1], bool:bIsAdmin[ MAX_PLAYERS + 1];
new para_ent[ MAX_PLAYERS +1 ]
new gCStrike = 0
new pDetach, pFallSpeed, pEnabled, pCost, pPayback, pAutoDeploy /*MAY2020*/,pAutoRules /*MAY2020*/;
new g_UnBreakable, g_debug

new const LOST_CHUTE_SOUND[] = "misc/erriewind.wav"
new const PARA_MODELO[] = "models/parachute.mdl"
new const PARA_MODELW[] = "models/Parachute_wings.mdl"
new const PARA_MODEL[] = "models/parachute2.mdl"

new g_model, g_packHP
new bool:bOF_run
new bool:bFirstAuto[MAX_PLAYERS+1]

#define PITCH (random_num (90,111))
#define PARACHUTE_LEVEL ADMIN_LEVEL_A
public plugin_init()
{
    register_plugin(PLUGIN,VERSION,AUTHOR)
    register_touch("parachute", "", "@chute_touch")
    pEnabled    = register_cvar("sv_parachute", "1" )
    pFallSpeed  = register_cvar("parachute_fallspeed", "100")
    pDetach     = register_cvar("parachute_detach", "1")
    pAutoDeploy = register_cvar("parachute_autorip", "1200")
    pAutoRules  = register_cvar("parachute_autoadmin", "2") //0|off 1|admin 2|all
    bind_pcvar_num(register_cvar("parachute_safemode", "0"),g_UnBreakable)
    g_packHP    = register_cvar("parachute_health", "75")
    g_debug     = register_cvar("parachute_debug", "0")

    new mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name))
    if(equal(mod_name, "cstrike"))
    {
        gCStrike = true
    }
    else if(equal(mod_name, "czero"))
    {
        log_amx "Hambot required for this mod!"
        pause("a")
    }

    if (gCStrike)
    {
        pCost = register_cvar("parachute_cost", "1000")
        pPayback = register_cvar("parachute_payback", "75") //percentage

        register_concmd("amx_parachute", "admin_give_parachute", PARACHUTE_LEVEL, "<nick, #userid or @team>" )
    }
    bOF_run  = equal(mod_name, "gearbox") || equal(mod_name, "valve") ? true : false
    register_clcmd("say", "HandleSay")
    register_clcmd("say_team", "HandleSay")

    bOF_run ? (register_event_ex ( "ResetHUD" , "newSpawn", RegisterEventFlags: RegisterEvent_Single|RegisterEvent_OnlyAlive )) : RegisterHam(Ham_Spawn, "player", "newSpawn", 1);

    RegisterHam(Ham_Killed, "player", "death_event", 1);

    register_forward(FM_PlayerPreThink, "parachute_prethink", 1)
}

public plugin_natives()
{
    set_module_filter("module_filter")
    set_native_filter("native_filter")
}

public module_filter(const module[])
{
    if (!cstrike_running() && equali(module, "cstrike")) {
        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
    if (!trap) return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public plugin_precache()
{
    if (file_exists("sound/misc/erriewind.wav"))
    {
        precache_sound(LOST_CHUTE_SOUND);
    }
    else
    {
        log_amx("Your parachute sound, ^"%s^", is not correct!", LOST_CHUTE_SOUND);
        pause "a";
    }

    g_model = precache_model("models/glassgibs.mdl");

    //for func_breakable
    precache_sound("debris/bustglass2.wav");
    precache_sound("debris/bustglass1.wav");
    precache_sound("debris/metal1.wav");
    precache_sound("debris/metal2.wav");
    precache_model("sprites/fexplo.spr")

    if (file_exists(PARA_MODEL))
    {
        precache_model(PARA_MODEL)
    }
    else
    {
        log_amx("Your parachute model, ^"%s^", is not correct!", PARA_MODEL);
        pause "a";
    }

    if (file_exists(PARA_MODELO))
    {
        precache_model(PARA_MODELO)
    }
    else
    {
        log_amx("Your parachute model, ^"%s^", is not correct!", PARA_MODELO);
        pause "a";
    }
    if (file_exists(PARA_MODELW))
    {
        precache_model(PARA_MODELW)
    }
    else
    {
        log_amx("Your parachute model, ^"%s^", is not correct!", PARA_MODELW);
        pause "a";
    }

}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bIsBot[id] = is_user_bot(id) ? true : false
        bIsAdmin[id] = is_user_admin(id) ? true : false
    }
}

public parachute_reset(id)
{
    new print = get_pcvar_num(g_debug)
    if(is_user_connected(id))
    {
        set_user_gravity(id, 1.0)

        if(print)
            server_print "Resetting chute for %n", id

        if(task_exists(id))remove_task(id);
        if(print)
        {
            server_print "Removed chute task for %n", id
            server_print "reset task for %n", id

            server_print "Set ent to 0 for %n", id
        }
        para_ent[id] = 0
        if(pev_valid(para_ent[id]))
        {
            if(print)
                server_print "PAST Set ent to 0 for %n", id
            if (pev_valid(para_ent[id]) > 1)
            {
                if(print)
                    server_print "Removing para_ent for %n", id
                remove_entity(para_ent[id])
            }
        }
    }
}

@chute_touch(chute,whatever)
{
    new id = pev(chute, pev_owner)
    if(is_user_connected(id))
    {
        server_print "Adjusting %n parachute", id

        if( para_ent[id] > 0 && pev_valid(para_ent[id]) > 1 )
        {
            if(!is_user_alive(id))/*Spec interference*/
                set_pev(para_ent[id], pev_solid, SOLID_NOT)

            remove_entity(para_ent[id])
            para_ent[id] = 0
        }
    }
}

public newSpawn(id)
if(is_user_connected(id))
{
    if (!gCStrike || access(id,PARACHUTE_LEVEL) || get_pcvar_num(pCost) <= 0)
        has_parachute[id] = true

    if( para_ent[id] > 0 && pev_valid(para_ent[id]) > 1 )
    {
        set_user_gravity(id, 1.0)

        if(bOF_run && bIsBot[id])
        {
            if(g_UnBreakable)
            {
                remove_entity(para_ent[id])
                para_ent[id] = 0
            }
            else
            {
                set_task(20.0, "parachute_reset", id)
            }
        }
        else
        {
            remove_entity(para_ent[id])
            para_ent[id] = 0
        }

    }
}

public parachute_prethink(id)
{
    if(!get_pcvar_num(pEnabled)) return
    if(is_user_connected(id) && is_user_alive(id))
    {
        new flags = get_entity_flags(id)
        new button = get_user_button(id)
        new oldbutton = get_user_oldbutton(id)

        parachute_think(flags, id, button, oldbutton)
    }
}

public parachute_think(flags, id, button, oldbutton)
{
    /*
     * parachute.mdl animation information
     * 0 - deploy - 84 frames
     * 1 - idle - 39 frames
     * 2 - detach - 29 frames
     */
    if(flags)
    {
        new AUTO;
        new Rip_Cord = get_pcvar_num(pAutoDeploy);
        new iDrop = pev(id,pev_flFallVelocity)
        new print = get_pcvar_num(g_debug)
        new fParachuteSpeed = get_pcvar_num(pFallSpeed)

        if (get_pcvar_num(pAutoRules) == 1 && bIsAdmin[id] || get_pcvar_num(pAutoRules) == 2)
        {
            AUTO = !bFirstAuto[id] ? iDrop >= Rip_Cord : iDrop > fParachuteSpeed
        }

        if(bIsAdmin[id] && print && iDrop != 0)
            client_print id, print_center, "Fall Velocity:%d", iDrop

        if(button & IN_ATTACK)/*Sniper first shot sound is still clipped*/
            emit_sound(id, CHAN_AUTO, LOST_CHUTE_SOUND, VOL_NORM, ATTN_IDLE, SND_STOP, PITCH)

        else if(flags & ~FL_ONGROUND)
            emit_sound(id, CHAN_AUTO, LOST_CHUTE_SOUND, VOL_NORM, ATTN_IDLE, iDrop > 999 ? 0 : SND_STOP, PITCH)

        if(has_parachute[id])
        {
            new Float:frame

            new Float:fallspeed = fParachuteSpeed * -1.0

            if( (pev_valid(para_ent[id]) > 1) && (para_ent[id] > 0 && (flags & FL_ONGROUND)) )
            {
                if (get_pcvar_num(pDetach))
                {
                    bFirstAuto[id] = false

                    if (get_user_gravity(id) == 0.1)
                        set_user_gravity(id, 1.0)

                    if( (pev_valid(para_ent[id]) > 1))
                    {
                        entity_set_int(para_ent[id], EV_INT_sequence, 2)
                        entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
                        entity_set_float(para_ent[id], EV_FL_frame, 0.0)
                        entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
                        entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
                        entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
                        return
                    }

                    frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
                    entity_set_float(para_ent[id],EV_FL_fuser1,frame)
                    entity_set_float(para_ent[id],EV_FL_frame,frame)

                    if (frame > 254.0)
                    {
                        remove_entity(para_ent[id])
                        para_ent[id] = 0
                    }

                }
                else
                {
                    remove_entity(para_ent[id])
                    set_user_gravity(id, 1.0)
                    para_ent[id] = 0
                }

                return
            }
            if(button & IN_USE|AUTO)
            {
                if(AUTO && !bFirstAuto[id])
                    bFirstAuto[id] = true
                else if(button & IN_USE)
                bFirstAuto[id] = false

                new Float:velocity[3]
                entity_get_vector(id, EV_VEC_velocity, velocity)

                if (velocity[2] < 0.0)
                {
                    if(para_ent[id] <= 0)
                    {
                        new Float:minbox[3] = { -Parachute_size, -Parachute_size, -Parachute_size }
                        new Float:maxbox[3] = { Parachute_size, Parachute_size, Parachute_size }
                        new Float:angles[3] = { 0.0, 0.0, 0.0 }
                        set_pev(para_ent[id], pev_spawnflags, 6)

                        para_ent[id] = g_UnBreakable ?create_entity("info_target") : create_entity("func_breakable")
                        set_pev(para_ent[id], pev_solid, g_UnBreakable  ? SOLID_NOT : SOLID_BBOX)

                        new SzChuteName[MAX_RESOURCE_PATH_LENGTH]
                        formatex( SzChuteName, charsmax( SzChuteName), "%n's parachute",id )
                        set_pev(para_ent[id], pev_classname, "parachute")

                        if(pev_valid(para_ent[id]) > 1)
                        {
                            entity_set_string(para_ent[id], EV_SZ_targetname, SzChuteName)
                            entity_set_edict(para_ent[id], EV_ENT_aiment, id)
                            entity_set_edict(para_ent[id], EV_ENT_owner, id)
                            entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)

                            if( bIsBot[id] )
                            {
                                entity_set_model(para_ent[id], PARA_MODELW);
                            }
                            else if( bIsAdmin[id] )
                            {
                                entity_set_model(para_ent[id], PARA_MODEL);
                            }
                            else
                            {
                                entity_set_model(para_ent[id], PARA_MODELO);
                            }

                            entity_set_size(para_ent[id], minbox, maxbox )
                            set_pev(para_ent[id],pev_angles,angles)

                            set_pev(para_ent[id],pev_takedamage,  g_UnBreakable || bIsBot[id] && bOF_run ? DAMAGE_NO : DAMAGE_YES)

                            //Give the parachute health so we can destroy it later in a fight.
                            if(!g_UnBreakable)
                            {
                                DispatchKeyValue(para_ent[id], "explodemagnitude", "15")
                                entity_set_float(para_ent[id], EV_FL_health, get_pcvar_float(g_packHP))
                            }

                            entity_set_int(para_ent[id], EV_INT_sequence, 0)
                            entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
                            entity_set_float(para_ent[id], EV_FL_frame, 0.0)
                            entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
                        }
                    }
                    if (pev_valid(para_ent[id]) > 1 && para_ent[id] > 0)
                    {
                        entity_set_int(id, EV_INT_sequence, 3)
                        entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
                        entity_set_int(id, EV_INT_gaitsequence, 1)
                        entity_set_float(id, EV_FL_frame, 1.0)
                        entity_set_float(id, EV_FL_framerate, 1.0)
                        set_user_gravity(id, 0.1)

                        velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
                        entity_set_vector(id, EV_VEC_velocity, velocity)

                        if( (pev_valid(para_ent[id]) > 1) && (entity_get_int(para_ent[id],EV_INT_sequence) == 0) )
                        {

                            frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
                            entity_set_float(para_ent[id],EV_FL_fuser1,frame)
                            entity_set_float(para_ent[id],EV_FL_frame,frame)

                            if (frame > 100.0 && pev_valid(para_ent[id]) > 1)
                            {
                                entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
                                entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
                                entity_set_int(para_ent[id], EV_INT_sequence, 1)
                                entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
                                entity_set_float(para_ent[id], EV_FL_frame, 0.0)
                                entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
                            }
                        }
                    }
                    if ( para_ent[id] < 1 || !pev_valid(para_ent[id]) || !g_UnBreakable && pev(para_ent[id],pev_health) <  get_pcvar_float(g_packHP)*0.1)
                    {
                        emit_sound(id, CHAN_AUTO, LOST_CHUTE_SOUND, VOL_NORM, ATTN_IDLE, 0, PITCH)
                        colorize(id)
                        set_user_gravity(id, 1.0)

                        //Let player know they shot the chute not the player.
                        set_task(0.2,"chute_pop",id)
                        if(print)
                        {
                            server_print "%n parachute destroyed!", id
                            client_print 0, print_chat, "%n parachute destroyed!", id
                        }
                        return;
                    }
                }
                else if (para_ent[id] > 0 && pev_valid(para_ent[id]) > 1)
                {
                    remove_entity(para_ent[id])
                    set_user_gravity(id, 1.0)
                    para_ent[id] = 0
                }
            }
            else if ((oldbutton & IN_USE) && para_ent[id] > 0 && pev_valid(para_ent[id]) > 1)
            {
                remove_entity(para_ent[id])
                set_user_gravity(id, 1.0)
                para_ent[id] = 0
            }
        }
    }
    if(flags & FL_ONGROUND)
    {
        emit_sound(id, CHAN_AUTO, LOST_CHUTE_SOUND, VOL_NORM, ATTN_IDLE, SND_STOP, PITCH)
    }
}

//effects
public colorize(id)
{
    if(is_user_alive(id) && para_ent[id] == 0)
        set_user_rendering(id,kRenderFxGlowShell,random_num(0,255),random_num(0,255),random_num(0,255),kRenderNormal,25);
}

public chute_pop(id)
{
    if(is_user_connected(id) && has_parachute[id])
    {
        has_parachute[id] = false
        new print = get_pcvar_num(g_debug)
        if(print)
            server_print("%n chute pop effect start", id);

        #define TE_EXPLODEMODEL 107
        new Origin[3];

        pev(id, pev_origin, Origin)

        emessage_begin(MSG_PVS, SVC_TEMPENTITY);
        ewrite_byte(TE_EXPLODEMODEL);
        ewrite_coord(floatround(Origin[0]+random_float(-11.0,11.0)));
        ewrite_coord(floatround(Origin[1]-random_float(-11.0,11.0)));
        ewrite_coord(floatround(Origin[2]+random_float(1.0,75.0)));
        ewrite_coord(random_num(-150,1000));  //vel
        ewrite_short(g_model); //model
        ewrite_short(5); //quantity
        ewrite_byte(random_num(20,100)); //size
        emessage_end();

        if(print)
            server_print("%n chute pop effect ended", id);
    }
}

//administrative code/////////////////////////////////
public client_connect(id)
if(is_user_connected(id))
    parachute_reset(id)

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

public client_disconnected(id)
    parachute_reset(id)

public death_event()
{
    new id = read_data(2)

    //otherwise the dead become a stepping stone for the living
    if(pev_valid(para_ent[id]))
        set_pev(para_ent[id],pev_solid,SOLID_NOT)

    parachute_reset(id)

}

public HandleSay(id)
{
    if(!is_user_connected(id)) return PLUGIN_CONTINUE

    new args[ MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH ]
    read_args(args, charsmax(args))
    remove_quotes(args)

    if (gCStrike) {
        if (equali(args, "buy_parachute")) {
            buy_parachute(id)
            return PLUGIN_HANDLED
        }
        else if (equali(args, "sell_parachute")) {
            sell_parachute(id)
            return PLUGIN_HANDLED
        }
        else if (containi(args, "give_parachute") == 0) {
            give_parachute(id,args[15])
            return PLUGIN_HANDLED
        }
    }

    if (containi(args, "parachute") != -1) {
        if (gCStrike) client_print(id, print_chat, "[AMXX] Parachute commands: buy_parachute, sell_parachute, give_parachute")
        client_print(id, print_chat, "[AMXX] To use your parachute press and hold your +use button while falling")
    }

    return PLUGIN_CONTINUE
}

public buy_parachute(id)
{
    if (!gCStrike) return PLUGIN_CONTINUE
    if (!is_user_connected(id)) return PLUGIN_CONTINUE

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    if (has_parachute[id]) {
        client_print(id, print_chat, "[AMXX] You already have a parachute")
        return PLUGIN_HANDLED
    }

    new money = cs_get_user_money(id)
    new cost = get_pcvar_num(pCost)

    if (money < cost) {
        client_print(id, print_chat, "[AMXX] You don't have enough moneyfor a parachute - Costs $%i", cost)
        return PLUGIN_HANDLED
    }

    cs_set_user_money(id, money - cost)
    client_print(id, print_chat, "[AMXX] You have bought a parachute. To use it, press +use while falling.")
    has_parachute[id] = true

    return PLUGIN_HANDLED
}

public sell_parachute(id)
{
    if (!gCStrike) return PLUGIN_CONTINUE
    if (!is_user_connected(id)) return PLUGIN_CONTINUE

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    if (!has_parachute[id]) {
        client_print(id, print_chat, "[AMXX] You don't have a parachute to sell")
        return PLUGIN_HANDLED
    }

    if (access(id,PARACHUTE_LEVEL)) {
        client_print(id, print_chat, "[AMXX] You cannot sell your free admin parachute")
        return PLUGIN_HANDLED
    }

    parachute_reset(id)

    new money = cs_get_user_money(id)
    new cost = get_pcvar_num(pCost)

    new sellamt = floatround(cost * (get_pcvar_num(pPayback) / 100.0))
    cs_set_user_money(id, money + sellamt)

    client_print(id, print_chat, "[AMX] You have sold your used parachute for $%d", sellamt)

    return PLUGIN_CONTINUE
}

public give_parachute(id,args[])
{
    if (!gCStrike) return PLUGIN_CONTINUE
    if (!is_user_connected(id)) return PLUGIN_CONTINUE

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    if (!has_parachute[id]) {
        client_print(id, print_chat, "[AMXX] You don't have a parachute to give")
        return PLUGIN_HANDLED
    }

    new player = cmd_target(id, args, 4)
    if (!player) return PLUGIN_HANDLED

    new id_name[MAX_NAME_LENGTH], pl_name[MAX_NAME_LENGTH]
    get_user_name(id, id_name, charsmax(id_name))
    get_user_name(player, pl_name, charsmax(pl_name))

    if(has_parachute[player]) {
        client_print(id, print_chat, "[AMXX] %s already has a parachute.", pl_name)
        return PLUGIN_HANDLED
    }

    parachute_reset(id)
    has_parachute[player] = true

    client_print(id, print_chat, "[AMXX] You have given your parachute to %s.", pl_name)
    client_print(player, print_chat, "[AMXX] %s has given thier parachute to you.", id_name)

    return PLUGIN_HANDLED
}

public admin_give_parachute(id, level, cid)
{
    if (!gCStrike) return PLUGIN_CONTINUE

    if(!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    new arg[MAX_PLAYERS], name[MAX_NAME_LENGTH], name2[MAX_NAME_LENGTH], authid[MAX_AUTHID_LENGTH], authid2[MAX_AUTHID_LENGTH]
    read_argv(1,arg,charsmax(arg))
    get_user_name(id,name,charsmax(name))
    get_user_authid(id,authid, charsmax(authid))

    if (arg[0]=='@')
    {
        new players[32], inum
        if (equali("T",arg[1])) copy(arg[1],31,"TERRORIST")
        equali("ALL",arg[1]) ? get_players(players,inum) : get_players(players,inum,"e",arg[1])

        if (inum == 0) {
            console_print(id,"No clients in such team")
            return PLUGIN_HANDLED
        }

        for(new a = 0; a < inum; a++) {
            has_parachute[players[a]] = true
        }

        switch(get_cvar_num("amx_show_activity"))   {
            case 2: client_print(0,print_chat,"ADMIN %s: gave a parachute to ^"%s^" players",name,arg[1])
            case 1: client_print(0,print_chat,"ADMIN: gave a parachute to ^"%s^" players",arg[1])
        }
        console_print(id,"[AMXX] You gave a parachute to ^"%s^" players",arg[1])
        log_amx("^"%s<%d><%s><>^" gave a parachute to ^"%s^"", name,get_user_userid(id),authid,arg[1])
    }
    else
    {
        new player = cmd_target(id,arg,6)
        if (!player) return PLUGIN_HANDLED

        has_parachute[player] = true

        get_user_name(player,name2,charsmax(name2))
        get_user_authid(player,authid2,charsmax(authid2))

        switch(get_cvar_num("amx_show_activity")) {
            case 2: client_print(0,print_chat,"ADMIN %s: gave a parachute to ^"%s^"",name,name2)
            case 1: client_print(0,print_chat,"ADMIN: gave a parachute to ^"%s^"",name2)
        }
        console_print(id,"[AMXX] You gave a parachute to ^"%s^"", name2)
        log_amx("^"%s<%d><%s><>^" gave a parachute to ^"%s<%d><%s><>^"", name,get_user_userid(id),authid,name2,get_user_userid(player),authid2)
    }
    return PLUGIN_HANDLED
}
