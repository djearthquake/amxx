/***********************************************************************************\
*    Hook By SPiNX original by P34nut    *    Thanks to Joka69, Chaosphere for testing and stuff!     *
*************************************************************************************
* Commands/ bindings:
*   +hook to throw the hook
*   -hook to delete your hook
*
* Cvars:
*   sv_hook - Turns hook on or off
*   sv_hookthrowspeed - Throw speed (default: 1000)
*   sv_hookspeed - Speed to hook (default: 300)
*   sv_hookwidth - Width of the hook (default: 32)
*   sv_hooksound - Sounds of the hook on or off (default: 1)
*   sv_hookcolor - The color of the hook 0 is white and 1 is team color (default: 1)
*   sv_hookplayers - If set 1 you can hook on players (default: 0)
*   sv_hookinterrupt - Remove the hook when something comes in its line (default: 0)
*   sv_hookadminonly - Hook for admin only (default: 0)
*   sv_hooksky - If set 1 you can hook in the sky (default: 0)
*   sv_hookopendoors - If set 1 you can open doors with the hook (default: 1)
*   sv_hookbuttons - If set 1 you can use buttons with the hook (default: 0)
*   sv_hookpickweapons - If set 1 you can pickup weapons with the hook (default: 1)
*   sv_hookhostfollow - If set 1 you can make hostages follow you (default 1)
*   sv_hookinstant - Hook doesnt throw (default: 0)
*   sv_hooknoise - adds some noise to the hook line (default: 0)
*   sv_hookmax - Maximun numbers of hooks a player can use in 1 round
*          - 0 for infinitive hooks (default: 0)
*   sv_hookdelay - delay on the start of each round before a player can hook
*                - 0.0 for no delay (default: 0.0)
*
* ChangeLog:
*   1.0: Release
*   1.5: added cvars:
*       sv_hooknoise
*       sv_hookmax
*       sv_hookdelay
*       public cvar: sv_amxxhookmod
*        added commands:
*       amx_givehook <username>
*       amx_takehook <username>
*   1.6: All mod support. Switched to Ham on Spawns. -SPiNX 2021
*   1.7: Monster maker effects -SPiNX October 2021
*   1.8: Catch trains. Fix door opener.
*
\***********************************************************************************/

// Players admin level
#define ADMINLEVEL ADMIN_SLAY

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <engine_stocks>
#include <fakemeta>
#include <fakemeta_util>
#tryinclude gearbox
#define HLW_KNIFE           0x0019
#include <hamsandwich>
#include <xs>
#define message_begin_f(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord, %1)
#define MAX_NAME_LENGTH             32
#define MAX_MENU_LENGTH            512
#define charsmin                    -1
#define PENGUIN                    2022

#pragma dynamic 9600000
new bool:bToggled

//new const RPG[]         = "models/flag.mdl" //fun. makes the xbow sound effect seems more realistic. Need a decent harpoon model please.
new const RPG[]         = "models/hvr.mdl" //need to pin that to weapons pick up and dmg_crush to humans. Thanks Sierra, Valve, OLO DLEJ. Many names. From DJEQ!
new const HOOK_MODEL[]  = "sprites/zbeam4.spr"
new g_mapname[MAX_NAME_LENGTH]
new bool:bsatch_crash_fix, bool:bKnife[MAX_PLAYERS + 1]


//Cvars
new pHook, pThrowSpeed, pSpeed, pWidth, pSound, pColor
new pInterrupt, pAdmin, pHookSky, pOpenDoors, pPlayers
new pUseButtons, pHostage, pWeapons, pInstant, pHookNoise
new pMaxHooks, pRndStartDelay
new pHook_break, pHead,pSegments

// Sprite
new sprBeam

// Players hook entity
new Hook[MAX_NAME_LENGTH + 1]

// some booleans
new bool:gHooked[MAX_NAME_LENGTH + 1]
new bool:canThrowHook[MAX_NAME_LENGTH + 1]
new bool:rndStarted
new bool:bOF_run

// Player Spawn
new bool:gRestart[MAX_NAME_LENGTH + 1] = {false, ...}
new bool:gUpdate[MAX_NAME_LENGTH + 1] = {false, ...}

new gHooksUsed[MAX_NAME_LENGTH + 1] // Used with sv_hookmax
new bool:g_bHookAllowed[MAX_NAME_LENGTH + 1] // Used with sv_hookadminonly
new bool:bHOokUser[MAX_PLAYERS + 1]

static gCStrike, bool:bAllCached, g_safemode

/*
new const SzRope[][]={
    "models/hvr.mdl",
    "models/wire_copper32.mdl",
    "models/wire_red32.mdl",
    "models/rope16.mdl",
    "models/rope32.mdl"
}
*/

 /*
new const debris1[]  = "sound/debris/pushbox1.wav"
new const debris2[]  = "sound/debris/pushbox2.wav"
new const debris3[]  = "sound/debris/pushbox3.wav"
new const glass1[]   = "debris/bustglass1.wav"
new const glass2[]   = "debris/bustglass2.wav"
new const glass1a[]  = "sound/debris/bustglass1.wav"
new const glass2a[]  = "sound/debris/bustglass2.wav"

new const battery[]  = "models/w_battery.mdl"
*/

new const grabable_goodies[][]={"ammo","armoury_entity","item","weapon", "power", "tank", "train"}

new Xdebug
new g_Client
new bool:biHookFix[MAX_PLAYERS+1]

enum _:Client_hookgrab
{
    iHookcolor[MAX_PLAYERS+1],
    iHookhead[MAX_PLAYERS+1],
    bHookInstant[MAX_PLAYERS+1],
    bHookplayers[MAX_PLAYERS+1],
};

///new HookParameters[ Client_hookgrab ]

public plugin_init()
{
    register_plugin("Hook", "1.8", "SPINX") //1.5 and under was developed by P34nut for CS
    //This is more for OF the first mod. Env_rope is exclusivley in OF.

    Xdebug = register_cvar("hook_debug", "0")

    // Hook commands
    register_clcmd("+hook", "make_hook")
    register_clcmd("-hook", "del_hook")
    register_concmd("rope", "@rope_control", ADMINLEVEL, "- Re-Enable limp ropes.")
    register_concmd("wire", "@wire_control", ADMINLEVEL, "- Toggle electrical current.")

    register_concmd("amx_givehook", "give_hook", ADMINLEVEL, "<Username> - Give somebody access to the hook")
    register_concmd("amx_takehook", "take_hook", ADMINLEVEL, "<UserName> - Take away somebody his access to the hook")
    //assign to glock attack2

    if(gCStrike)
    {
        // Events for roundstart
        register_event("HLTV", "round_bstart", "a", "1=0", "2=0")
        register_logevent("round_estart", 2, "1=Round_Start")

        // Player spawn stuff
        register_event("TextMsg", "Restart", "a", "2=#Game_will_restart_in")
        RegisterHam(Ham_Spawn, "player", "ResetHUD", 1)
        //register_event("ResetHUD", "ResetHUD", "b")
    }
    else
    {
        //register_clcmd("fullupdate", "Update")
        register_event("ResetHUD", "ResetHUD", "b")
    }

    // Register cvars
    register_cvar("sv_spinxhookmod",  "V1.7", FCVAR_SERVER) // yay public cvar
    //bind_pcvar_num(register_cvar("sv_hook", "1"),pHook)

    pHook           =  register_cvar("sv_hook", "1")
    pThrowSpeed     =  register_cvar("sv_hookthrowspeed", "1500")
    pSpeed          =  register_cvar("sv_hookspeed", "600")
    pWidth          =  register_cvar("sv_hookwidth", "16")
    pSound          =  register_cvar("sv_hooksound", "1")
    pColor          =  register_cvar("sv_hookcolor", "1")
    pPlayers        =  register_cvar("sv_hookplayers", "1")
    pInterrupt      =  register_cvar("sv_hookinterrupt", "0")
    pAdmin          =  register_cvar("sv_hookadminonly",  "0")
    pHookSky        =  register_cvar("sv_hooksky", "1")
    pOpenDoors      =  register_cvar("sv_hookopendoors", "1")
    pUseButtons     =  register_cvar("sv_hookusebuttons", "1")
    pHostage        =  register_cvar("sv_hookhostfollow", "1")
    pWeapons        =  register_cvar("sv_hookpickweapons", "1")
    pInstant        =  register_cvar("sv_hookinstant", "1")
    pHookNoise      =  register_cvar("sv_hooknoise", "1")
    pMaxHooks       =  register_cvar("sv_hookmax", "100")
    pRndStartDelay  =  register_cvar("sv_hookrndstartdelay", "0.0")
    pHook_break     =  register_cvar("sv_hookbreak", "1") //break or use door
    pHead           =  register_cvar("sv_hookhead", "9")
    pSegments       =  register_cvar("sv_hooksegments", "1")

    // Touch forward
    register_forward(FM_Touch, "fwTouch", true)

    get_mapname(g_mapname, charsmax(g_mapname))

    if(equali(g_mapname,"beach_head"))bsatch_crash_fix=true

}


public _SecondaryAttack_Pre(const gun)
{
    g_Client = pev(gun, pev_owner)
    return HAM_SUPERCEDE
}

public _SecondaryAttack_Post(const gun)
{
    new iSafety
    new Client = g_Client
    if(is_user_connected(Client) && is_user_admin(Client))
    {
        iSafety = get_pcvar_num(pHead)
        if(iSafety != 9)
        {
            set_pcvar_num(pHead, 9)
            biHookFix[Client] = false
        }
        if(biHookFix[Client])
        {
            del_hook(Client)
            biHookFix[Client] = false
            return HAM_SUPERCEDE
        }
        else
        {
            make_hook(Client)
            biHookFix[Client] = true
            return HAM_SUPERCEDE
        }

    }
    return HAM_SUPERCEDE
}


@rope_control(id)
{
    #define TOGGLE "3"
    if(is_user_connected(id))
    {
        bToggled = bToggled ? false : true
        static iRope; iRope = find_ent_by_class(MaxClients, "env_rope")

        if(iRope && pev_valid(iRope))
        {
            client_print(id, print_chat, "Toggling rope.")
            bToggled ? fm_set_kvd(iRope, "disable", "1") :  fm_set_kvd(iRope, "disable", "0")
        }
        static iRope2; iRope2 = find_ent_by_class(iRope, "env_rope")
        if(iRope2 && pev_valid(iRope2))
        {
            client_print(id, print_chat, "Toggling 2nd wire.")
            bToggled ? fm_set_kvd(iRope, "disable", "1") :  fm_set_kvd(iRope, "disable", "0")
        }

        static iRope3; iRope3 = find_ent_by_class(iRope2, "env_rope")
        if(iRope3 != iRope && pev_valid(iRope3))
        {
            client_print(id, print_chat, "Toggling 3rd rope.")
            bToggled ? fm_set_kvd(iRope, "disable", "1") :  fm_set_kvd(iRope, "disable", "0")
        }

    }
    return PLUGIN_HANDLED
}

@wire_control(id)
{
    #define TOGGLE "3"
    if(is_user_connected(id))
    {

        static iWire; iWire = find_ent_by_class(MaxClients, "env_electrified_wire")

        if(iWire && pev_valid(iWire))
        {
            client_print(id, print_chat, "Toggling wire.")
            ExecuteHam(Ham_Use, iWire, id, 0, TOGGLE, 2.0)
        }
        static iWire2; iWire2 = find_ent_by_class(iWire, "env_electrified_wire")
        if(iWire2 && pev_valid(iWire2))
        {
            client_print(id, print_chat, "Toggling 2nd wire.")
            ExecuteHam(Ham_Use, iWire2, id, 0, TOGGLE, 2.0)
        }

        static iWire3; iWire3 = find_ent_by_class(iWire2, "env_electrified_wire")
        if(iWire3 != iWire && pev_valid(iWire3))
        {
            client_print(id, print_chat, "Toggling 3rd wire.")
            ExecuteHam(Ham_Use, iWire3, id, 0, TOGGLE, 2.0)
        }

    }
    return PLUGIN_HANDLED
}

public plugin_precache()
{
    g_safemode = get_cvar_pointer("safe_mode")
    static mod_name[MAX_NAME_LENGTH]
    get_modname(mod_name, charsmax(mod_name))

    if(equal(mod_name, "cstrike") || equal(mod_name, "czero"))
    {
        gCStrike = true
    }

    bOF_run  = equal(mod_name, "gearbox") ? true : false
    if(bOF_run)
    {
        RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_knife", "_SecondaryAttack_Pre" , 0 );
        RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_knife", "_SecondaryAttack_Post", 1 );
    }
    // Hook Model
    precache_model(RPG)

    // Hook Beam
    sprBeam = precache_model(HOOK_MODEL)
    precache_generic(HOOK_MODEL)
    // Hook Sounds
    precache_sound("weapons/xbow_hit1.wav")
    precache_sound("weapons/xbow_hit2.wav")
    precache_sound("weapons/xbow_hitbod1.wav")
    precache_sound("weapons/xbow_fire1.wav")

    if(bOF_run && !g_safemode)
    {
        precache_model("models/barnacle.mdl")

        precache_model("models/barnaclet.mdl")

        precache_model("models/headcrab.mdl")

        precache_model("models/headcrabt.mdl")

        precache_sound("headcrab/hc_alert1.wav")
        precache_sound("headcrab/hc_alert2.wav")
        precache_sound("headcrab/hc_attack1.wav")
        precache_sound("headcrab/hc_attack2.wav")
        precache_sound("headcrab/hc_attack3.wav")
        precache_sound("headcrab/hc_die1.wav")
        precache_sound("headcrab/hc_die2.wav")
        precache_sound("headcrab/hc_headbite.wav")
        precache_sound("headcrab/hc_idle1.wav")
        precache_sound("headcrab/hc_idle2.wav")
        precache_sound("headcrab/hc_idle3.wav")
        precache_sound("headcrab/hc_idle4.wav")
        precache_sound("headcrab/hc_idle5.wav")
        precache_sound("headcrab/hc_pain1.wav")
        precache_sound("headcrab/hc_pain2.wav")
        precache_sound("headcrab/hc_pain3.wav")

        precache_model("models/rope32.mdl")
        precache_model("models/rope16.mdl")

        precache_model("models/wire_copper32.mdl")
        precache_model("models/wire_red32.mdl")

        precache_sound("items/grab_rope.wav")
        precache_sound("items/rope1.wav")
        precache_sound("items/rope2.wav")
        precache_sound("items/rope3.wav")
        precache_model("models/leech.mdl")
        precache_sound("leech/leech_bite1.wav")
        precache_sound("leech/leech_bite2.wav")
        precache_sound("leech/leech_bite3.wav")
        precache_sound("leech/leech_alert1.wav")
        precache_sound("leech/leech_alert2.wav")
        precache_sound("barnacle/bcl_alert2.wav")
        precache_sound("barnacle/bcl_bite3.wav")
        precache_sound("barnacle/bcl_chew1.wav")
        precache_sound("barnacle/bcl_chew2.wav")
        precache_sound("barnacle/bcl_chew3.wav")
        precache_sound("barnacle/bcl_die1.wav")
        precache_sound("barnacle/bcl_die3.wav")
        precache_sound("barnacle/bcl_tongue1.wav")
        bAllCached = true
    }
}


public make_hook(id)
{
    if (pHook && get_pcvar_num(pHook) && is_user_connected(id) && is_user_alive(id) && canThrowHook[id] && !gHooked[id] && !is_user_bot(id)) {
        if(get_pcvar_num(pAdmin))
        {
            if (!(get_user_flags(id) & ADMINLEVEL) && !g_bHookAllowed[id])
            {
                // Show a message
                client_print(id, print_chat, "[Hook] %L",id,"NO_ACC_COM")
                console_print(id, "[Hook] %L",id,"NO_ACC_COM")

                return PLUGIN_HANDLED
            }
        }
        bHOokUser[id] = true
        new iMaxHooks = get_pcvar_num(pMaxHooks)
        if (iMaxHooks > 0)
        {
            if (gHooksUsed[id] >= iMaxHooks)
            {
                client_print(id, print_chat, "[Hook] You already used your maximum amount of hooks")
                statusMsg(id, "[Hook] %d of %d hooks used.", gHooksUsed[id], get_pcvar_num(pMaxHooks))

                return PLUGIN_HANDLED
            }
            else
            {
                gHooksUsed[id]++
                statusMsg(id, "[Hook] %d of %d hooks used.", gHooksUsed[id], get_pcvar_num(pMaxHooks))
            }
        }
        new Float:fDelay = get_pcvar_float(pRndStartDelay)
        if (fDelay > 0 && !rndStarted)
            client_print(id, print_chat, "[Hook] You cannot use the hook in the first %0.0f seconds of the round", fDelay)

        if(pev_valid(id)>1)throw_hook(id)
        new check_head = get_pcvar_num(pHead)
        if(check_head == 5 || check_head == 10 )
            set_task(1.0, "@penguin_think", id+PENGUIN, _, _, "b")
    }
    return PLUGIN_HANDLED
}
public plugin_cfg()
{
    round_bstart()
    round_estart()
    Restart()
}
public del_hook(id)
{
    if(is_user_connected(id) && pHead)
    {
        //need keep trigger_push, barnacle, env_rope intact for now
        if(get_pcvar_num(pHead) > 2 && get_pcvar_num(pHead) <= 9) //tested works can detach hook from monsters 'unleashed'
        {
            // Remove players hook
            if(pev_valid(Hook[id] > 1) && !canThrowHook[id])
                remove_hook(id)
            if(is_user_connected(id))
            {
                emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id) //leashed monsters/pets
                ewrite_byte(99) // TE_KILLBEAM
                ewrite_short(id) // entity
                emessage_end()
            }
            return PLUGIN_HANDLED
            //return PLUGIN_CONTINUE
        }
        else if (get_pcvar_num(pHead) <=4 || get_pcvar_num(pHead) == 9)
        {
            if(!canThrowHook[id])
                canThrowHook[id] = true

            if(is_user_connected(id))
            {
                message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, id)
                write_byte(99) // TE_KILLBEAM
                write_short(id) // entity
                message_end()
            }
        }
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

public round_bstart()
{
    // Round is not started anymore
    if (rndStarted)
        rndStarted = false

    // Remove all hooks
    for (new i = 1; i <= MaxClients; ++i)
    {
        if(is_user_connected(i))
        {
            if(!canThrowHook[i])
                remove_hook(i)
        }
    }
}

public round_estart()
{
    new Float:fDelay = get_pcvar_float(pRndStartDelay)
    if (fDelay > 0.0)
        set_task(fDelay, "rndStartDelay")
    else
    {
        // Round is started...
        if (!rndStarted)
            rndStarted = true
    }
}

public rndStartDelay()
{
    if (!rndStarted)
        rndStarted = true
}

public Restart()
{
    for (new id = 1; id <= MaxClients; ++id)
    {
        if (is_user_connected(id))
            gRestart[id] = true
    }
}

public Update(id)
{
    if (!gUpdate[id])
        gUpdate[id] = true

    return PLUGIN_CONTINUE
}

@penguin_think(beak)
{
    new id = beak - PENGUIN
    new check_head = get_pcvar_num(pHead)
    if( check_head == 5 || check_head == 10 )

/*  if(!canThrowHook[id])
        canThrowHook[id] = true
*/
    if(is_user_connected(id))
    {
        if( check_head == 5 )
            !Hook[id] ? ResetHUD(id)/*remove_hook(id)*/ : change_task(id+PENGUIN, 3.0)
        else
            Hook[id] ? ResetHUD(id)/*remove_hook(id)*/ : change_task(id+PENGUIN, 3.0)
    }
    else
        remove_task(id+PENGUIN)
}

public ResetHUD(id)
{
    if(is_user_connected(id) && !is_user_bot(id) || gHooksUsed[id]>0)
    {
        if (gRestart[id])
        {
            gRestart[id] = false
            return
        }
        if (gUpdate[id])
        {
            gUpdate[id] = false
            return
        }

        if (gHooked[id] && !find_ent(charsmin,"env_rope") || !find_ent(charsmin,"env_electrified_wire") || !find_ent(charsmin,"monster_barnacle") )
            remove_hook(id)

        if (get_pcvar_num(pMaxHooks) > 0)
        {
            bHOokUser[id] = false
            gHooksUsed[id] = 0
            statusMsg(id, "[Hook] 0 of %d hooks used.", get_pcvar_num(pMaxHooks))
        }
    }
}

public fwTouch(ptr, ptd)
{
    static szPtdClass[MAX_NAME_LENGTH],
    ent, Float:fOrigin[3], szentClass[MAX_NAME_LENGTH];
    ent = MaxClients

    if(!pev_valid(ptr))
        return FMRES_IGNORED

    static id; id = pev(ptr, pev_owner)
    if(is_user_alive(id))
    {
        // Get classname
        static szPtrClass[MAX_NAME_LENGTH]
        pev(ptr, pev_classname, szPtrClass, charsmax(szPtrClass))

        if (containi(szPtrClass, "Hook")> charsmin || get_pcvar_num(pPlayers) > 2 && containi(szPtrClass, "grapple") > charsmin)
        {
            //potential filter
            {
                pev(ptr, pev_origin, fOrigin)

                while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, fOrigin, 128.0/*256.0*/)) > 0 && pev_valid(ent))
                {
                    pev(ent, pev_classname, szentClass, charsmax(szentClass))
                    if(containi(szentClass, "door") > charsmin || containi(szentClass,"illusionary") > charsmin || containi(szentClass,"wall") > charsmin)
                    {
                        goto DOORS
                    }
                    else if(equali(szentClass, "trigger_teleport"))
                    {
                        set_pev(id, pev_takedamage, DAMAGE_NO)
                        dllfunc(DLLFunc_Touch, ent, id)
                        client_print 0, print_center, "%n|Humanoid teleported via Hookgrab", id
                    }
                    // Pick up weapons..
                    else if(get_pcvar_num(pWeapons))
                    {
                        for (new toget; toget < sizeof grabable_goodies;++toget)

                        if(containi(szentClass, grabable_goodies[toget]) != charsmin || bsatch_crash_fix && containi(szentClass, "satchel") == charsmin)
                        {
                            if(get_pcvar_num(Xdebug))
                            {
                                server_print "Scanning Sphere: %n found %s.", id, szentClass
                            }
                            dllfunc(DLLFunc_Touch, ent, id)
                        }
                    }
                }
                if(pev_valid(ptd))
                {
                    pev(ptd, pev_classname, szPtdClass, charsmax(szPtdClass))

                    if(get_pcvar_num(pPlayers) && containi(szPtdClass, "monster") > charsmin || get_pcvar_num(pPlayers) && equali(szPtdClass,"hostage_entity") )
                    {
                        if (containi(szPtdClass, "ally") > charsmin || containi(szPtdClass, "human") > charsmin || containi(szPtdClass, "turret") > charsmin || containi(szPtdClass, "sentry") > charsmin ||  equali(szPtdClass, "monster_barney")
                        ||  equali(szPtdClass, "monster_otis") || containi(szPtdClass, "nuke") >  charsmin || containi(szPtdClass,"scientist") > charsmin)
                        {
                            dllfunc(DLLFunc_Use, ptd, id)
                            // Makes an hostage follow
                            if(containi(szPtdClass,"scientist") > charsmin || containi(szPtdClass,"hostage") > charsmin && pHostage & get_pcvar_num(pHostage) == 1)
                            {
                                dllfunc(DLLFunc_Use, ptd, id)
                            }
                        }
                        else goto damage
                    }
                    if (containi(szPtdClass, "able") > charsmin && get_pcvar_num(pHook_break))
                    {
                        damage:
                        /*          */
                       //if(ptd != Hook[id] && id != ptd)
                        is_user_alive(ptd)/* && !is_user_bot(ptd)*/ ?
                        ExecuteHam(Ham_TakeDamage,ptd,ptr,id,random_num(60,100)*1.0,DMG_PARALYZE) //bot or human
                        :
                        ExecuteHam(Ham_TakeDamage,ptd,ptr,id,random_num(60,100)*1.0,DMG_CRUSH) //Box or pushable ... monster

                        remove_hook(id)
                        return FMRES_HANDLED
                    }
                    if(!get_pcvar_num(pPlayers) && equali(szPtdClass, "player") && is_user_alive(ptd))
                    {
                        // Hit a player
                        if (get_pcvar_num(pSound))
                        {
                            emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                            remove_hook(id)
                        }
                        return FMRES_HANDLED
                    }
                    else if (get_pcvar_num(pPlayers) && equali(szPtdClass, "player"))  goto damage
                    if (get_pcvar_num(pOpenDoors) && containi(szPtdClass, "door") > charsmin)
                    {
                        DOORS:
                        dllfunc(DLLFunc_Use, ptd, ptr) //ok for grap
                        dllfunc(DLLFunc_Touch, ptd, ptr) //ok for grap
                        if(!get_pcvar_num(pHook_break) && get_pcvar_num(pColor) > 2 && ptd > MaxClients)
                        {
                            set_pev(ptd, pev_rendermode, kRenderTransColor);
                            set_pev(ptd, pev_renderamt, random_float(15.0,200.0))
                            switch(random(5))
                            {
                                case 1:set_pev(ptd, pev_rendercolor, Float:{255.0, 207.0, 0.0});
                                case 2:set_pev(ptd, pev_rendercolor, Float:{0.0, 255.0, 0.0});
                                case 3:set_pev(ptd, pev_rendercolor, Float:{0.0, 0.0, 255.0});
                                case 4:set_pev(ptd, pev_rendercolor, Float:{255.0, 0.0, 0.0});
                            }
                            set_task(15.0, "@fix_color_ent", ptd)
                        }
                    }
                    else
                    {
                        if(get_pcvar_num(pHook_break))
                        {
                            ExecuteHam(Ham_TakeDamage,ptd,ptr,id,100.0,DMG_CRUSH|DMG_ALWAYSGIB) //Attacker killed Victim w/ Hook
                        }
                    }
                    if (containi(szPtdClass, "train") > charsmin )
                    {
                        dllfunc(DLLFunc_Use, ptd, id)
                    }
                    if (containi(szPtdClass, "tank") > charsmin )
                    {
                        dllfunc(DLLFunc_Use, ptd, id)
                    }
                    if (get_pcvar_num(pUseButtons) && (containi(szPtdClass, "button") > charsmin || containi(szPtdClass, "charger") > charsmin || containi(szPtdClass, "recharge") > charsmin))
                    //dont reduce to "charge" on containi satchels crash when picking them up with hook otherwise
                    {
                        dllfunc(DLLFunc_Use, ptd, id) // Use Buttons
                        dllfunc(DLLFunc_Touch, ptd, id) // Use Buttons
                    }
                }
                // If cvar sv_hooksky is 0 and hook is in the sky remove it!
                new iContents = engfunc(EngFunc_PointContents, fOrigin)
                if (!get_pcvar_num(pHookSky) && iContents == CONTENTS_SKY)
                {
                    if(get_pcvar_num(pSound))
                    {
                        emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                    }
                    remove_hook(id)
                    return FMRES_HANDLED
                }
                // Player is now hooked
                gHooked[id] = true
                // Play sound
                if (get_pcvar_num(pSound) && !bKnife[id])
                {
                    emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                }
                // Make some sparks :D
                if(!bKnife[id])
                {
                    emessage_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
                    ewrite_byte(9) // TE_SPARKS
                    ewrite_coord_f(fOrigin[0]) // Origin
                    ewrite_coord_f(fOrigin[1])
                    ewrite_coord_f(fOrigin[2])
                    emessage_end()
                }
                // Stop the hook from moving
                set_pev(ptr, pev_velocity, Float:{0.0, 0.0, 0.0})
                set_pev(ptr, pev_movetype, MOVETYPE_NONE)

                //Task
                if (!task_exists(id + 856))
                {
                    static TaskData[2]
                    TaskData[0] = id
                    TaskData[1] = ptr
                    gotohook(TaskData)

                    set_task(0.1, "gotohook", id + 856, TaskData, 2, "b")
                }
            }
        }
    }
    return FMRES_HANDLED
}

@fix_color_ent(hook_painted_ent)
{
    if(pev_valid(hook_painted_ent)>1)
    {
        set_pev(hook_painted_ent, pev_rendermode, kRenderNormal);
    }
}


public hookthink(param[])
{
    new id = param[0]
    new HookEnt = param[1]

    if (!is_user_alive(id) || !pev_valid(HookEnt))
    {
        remove_task(id + 890)
        return PLUGIN_HANDLED
    }


    static Float:entOrigin[3]
    pev(HookEnt, pev_origin, entOrigin)

    // If user is behind a box or something.. remove it
    // only works if sv_interrupt 1 or higher is
    if (get_pcvar_num(pInterrupt) && rndStarted)
    {
        static Float:usrOrigin[3]
        pev(id, pev_origin, usrOrigin)

        static tr
        engfunc(EngFunc_TraceLine, usrOrigin, entOrigin, 1, charsmin, tr)

        static Float:fFraction
        get_tr2(tr, TR_flFraction, fFraction)

        if (fFraction != 1.0)
            remove_hook(id)
    }

    // If cvar sv_hooksky is 0 and hook is in the sky remove it!
    new iContents = engfunc(EngFunc_PointContents, entOrigin)
    if(!get_pcvar_num(pHookSky) && iContents == CONTENTS_SKY)
    {
        if(get_pcvar_num(pSound) && !bKnife[id])
        {
            emit_sound(HookEnt, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        }
        remove_hook(id)
    }

    return PLUGIN_HANDLED
}

public gotohook(param[])
{
    new id = param[0]
    new HookEnt = param[1]

    if (!is_user_connected(id) || !pev_valid(HookEnt))
    {
        remove_task(id + 856)
        return PLUGIN_HANDLED
    }
    // If the round isnt started velocity is just 0
    static Float:fVelocity[3]
    fVelocity = Float:{0.0, 0.0, 1.0}

    // If the round is started and player is hooked we can set the user velocity!
    if (rndStarted && gHooked[id])
    {
        static Float:fHookOrigin[3], Float:fUsrOrigin[3], Float:fDist
        pev(HookEnt, pev_origin, fHookOrigin)
        pev(id, pev_origin, fUsrOrigin)

        fDist = vector_distance(fHookOrigin, fUsrOrigin)

        if (fDist >= 30.0)
        {
            new Float:fSpeed = get_pcvar_float(pSpeed)

            fSpeed *= 0.52

            fVelocity[0] = (fHookOrigin[0] - fUsrOrigin[0]) * (2.0 * fSpeed) / fDist
            fVelocity[1] = (fHookOrigin[1] - fUsrOrigin[1]) * (2.0 * fSpeed) / fDist
            fVelocity[2] = (fHookOrigin[2] - fUsrOrigin[2]) * (2.0 * fSpeed) / fDist
        }
    }
    // Set the velocity
    set_pev(id, pev_velocity, fVelocity)

    return PLUGIN_HANDLED
}

public throw_hook(id)
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        bKnife[id] = get_user_weapon(id) == HLW_KNIFE ? true:false
        // Get origin and angle for the hook
        static Float:fOrigin[3], Float:fAngle[3],Float:fvAngle[3]
        static Float:fStart[3]
        pev(id, pev_origin, fOrigin)

        pev(id, pev_angles, fAngle)
        pev(id, pev_v_angle, fvAngle)

        ///if(get_pcvar_num(pInstant))
        {
            get_user_hitpoint(id, fStart)

            if (engfunc(EngFunc_PointContents, fStart) != CONTENTS_SKY)
            {
                static Float:fSize[3]
                pev(id, pev_size, fSize)

                fOrigin[0] = fStart[0] + floatcos(fvAngle[1], degrees) * (-10.0 + fSize[0])
                fOrigin[1] = fStart[1] + floatsin(fvAngle[1], degrees) * (-10.0 + fSize[1])
                fOrigin[2] = fStart[2]
            }
            else
                xs_vec_copy(fStart, fOrigin)
        }


        // Make the hook!
        //Hook[id] = create_entity("env_smoker")
        //////////////////////////HOOKHEADS/////////////////////////////////////////////////////////////////////
        if(bAllCached)
        {
            switch(get_pcvar_num(pHead))
            {
                case  0: Hook[id] = create_entity("env_rope")
                case  1: Hook[id] = create_entity("env_electrified_wire")
                case  2: Hook[id] = create_entity("monster_barnacle")
                case  3: Hook[id] = create_entity("trigger_push")
                case  4: Hook[id] = create_entity("monster_tripmine")
                case  5: Hook[id] = create_entity("monster_penguin")
                case  6: Hook[id] = create_entity("monster_leech")
                case  7: Hook[id] = create_entity("monster_headcrab")
                case  8: Hook[id] = create_entity("monster_snark")
                case  9: Hook[id] = create_entity("light") ///"light" "cycler_prdroid"
                case 10: Hook[id] = create_entity("displacer_ball")
            }
        }
        else
        {
            set_pcvar_num(pHead, 9)
            Hook[id] = create_entity("light")
        }

        //if using certain hooks they need set up just so to work as expected
        if(get_pcvar_num(pHead) <= 5)
        {
            if(!get_pcvar_num(pInstant))
                set_pcvar_num(pInstant, 1)
            //only admins should be making ropes at this time. Hard on the network resources.
            !get_pcvar_num(pAdmin) ?
            set_pcvar_num(pAdmin, 1) & set_pcvar_num(pInstant, 1) : set_pcvar_num(pAdmin, 0)
        }


        if(pev_valid(Hook[id]) > 1)
        {
            // Player cant throw hook now
            canThrowHook[id] = false

            static const Float:fMins[3] = {-2.840000, -14.180000, -2.840000}
            static const Float:fMaxs[3] = {2.840000, 0.020000, 2.840000}

            //Set some Data

            switch(get_pcvar_num(pHead))
            {
                case 0: set_pev(Hook[id], pev_classname, "Hook_rope")
                case 1: set_pev(Hook[id], pev_classname, "Hook_wire")
                case 2: set_pev(Hook[id], pev_classname, "Hook_rope_barnacle")
                case 3: set_pev(Hook[id], pev_classname, "Hook_rope_push")
                case 4: set_pev(Hook[id], pev_classname, "Hook_rope_mine")
                case 5: set_pev(Hook[id], pev_classname, "Hook_rope_guin")
                case 6: set_pev(Hook[id], pev_classname, "Hook_rope_leech")
                case 7: set_pev(Hook[id], pev_classname, "Hook_rope_crab")
                case 8: set_pev(Hook[id], pev_classname, "Hook_rope_snark")
                case 9: set_pev(Hook[id], pev_classname, "Hook_illuminati")
                case 10: set_pev(Hook[id], pev_classname, "Hook_displacer")
            }
            ////VARIOUS ENT PARAMETERS
            /*
            env_electrified_wire spawnflags 1
            env_electrified_wire angles 0 0 0
            env_electrified_wire targetname pc_wire
            env_electrified_wire segments 3
            env_electrified_wire sparkfrequency 7
            env_electrified_wire bodysparkfrequency 3
            env_electrified_wire lightningfrequency 3
            env_electrified_wire xforce 40000
            env_electrified_wire yforce 30000
            env_electrified_wire zforce 10000
            env_electrified_wire disable 1
            env_electrified_wire bodymodel models/wire_copper32.mdl
            env_electrified_wire endingmodel models/wire_red32.mdl
            */
            ///classname env_rope
            if(get_pcvar_num(pHead) == 0)
            {
                //fm_set_kvd(Hook[id], "spawnflags", "1");
                fm_set_kvd(Hook[id], "disable", "0");
            }
            ///classname env_electrified_wire
            if(get_pcvar_num(pHead) == 1)
            {
                fm_set_kvd(Hook[id], "sparkfrequency", "15");
                fm_set_kvd(Hook[id], "bodysparkfrequency", "20");
                fm_set_kvd(Hook[id], "lightningfrequency", "10");
                fm_set_kvd(Hook[id], "spawnflags", "1");
                fm_set_kvd(Hook[id], "xforce", "40000");
                fm_set_kvd(Hook[id], "yforce", "30000");
                fm_set_kvd(Hook[id], "zforce", "10000");
                fm_set_kvd(Hook[id], "disable", "1");
                //fm_set_kvd(Hook[id], "targetname", "rope_wire") //over-write later
            }

            engfunc(EngFunc_SetModel, Hook[id], RPG)
            engfunc(EngFunc_SetOrigin, Hook[id], fOrigin)
            engfunc(EngFunc_SetSize, Hook[id], fMins, fMaxs)
            //env_explosion/breakable
            //set_pev(Hook[id], pev_flags, SF_BREAK_TOUCH) //need this to break things with hook later
            //env_smoker
            //fm_set_kvd(Hook[id], "scale" , "1000"); //smoker
            //fm_set_kvd(Hook[id], "explodemagnitude", "350") //like the C4 on CS. Exactly

            //fm_set_kvd(Hook[id], "angles", "0 0 0");
            //fm_set_kvd(Hook[id], "spawnflags", "0");
            //fm_set_kvd(Hook[id], "speed", "1000");
           // fm_set_kvd(Hook[id], "sounds", "1");
            //fm_set_kvd(Hook[id], "style", "32");
            //fm_set_kvd(Hook[id], "model", "*228"); // Host_Error: no precache: 32

            //fm_set_kvd(Hook[id], "height", "9000");

            //trigger_hurt


            if(get_pcvar_num(pHead) == 10)
            {
                fm_set_kvd(Hook[id], "Radius", "128");
                fm_set_kvd(Hook[id], "Targetname", "HookBall");
                fm_set_kvd(Hook[id], "Target", "blk_apache_way_point");
                fm_set_kvd(Hook[id], "Warp_Target", "apache_way_point");
                fm_set_kvd(Hook[id], "spawnflags", "3");

            }
            if(get_pcvar_num(pHead) == 11)
            {
                fm_set_kvd(Hook[id], "dmg ", "-20");
                fm_set_kvd(Hook[id], "delay", "0");
                fm_set_kvd(Hook[id], "damagetype", "0");
            }
            //end hurt spec

            //env_rope
            if(!get_pcvar_num(pHead))
            {
                fm_set_kvd(Hook[id], "bodymodel", "models/rope32.mdl")
                fm_set_kvd(Hook[id], "endingmodel", "models/rope16.mdl")
            }
            else
            {
                fm_set_kvd(Hook[id], "bodymodel", "models/wire_copper32.mdl")
                fm_set_kvd(Hook[id], "endingmodel", "models/wire_red32.mdl")
            }

            //give env_rope spec target name so penguins don't explode and disable the ropes. use that later to cancel out ropes we do not need/want.
            //long segmented ropes are hard on the processor.
            ///!get_pcvar_num(pHead) ? fm_set_kvd(Hook[id], "targetname", "hooks_rope") : fm_set_kvd(Hook[id], "targetname", "hooks_head")
            switch(get_pcvar_num(pHead))
            {
                case 0: fm_set_kvd(Hook[id], "targetname", "rope_wire")
                case 1: fm_set_kvd(Hook[id], "targetname", "rope_wire")
                default :fm_set_kvd(Hook[id], "targetname", "hooks_head")
            }

            switch(get_pcvar_num(pSegments))
            {
                case   1..2: fm_set_kvd(Hook[id], "segments", "2")
                case   3..6: fm_set_kvd(Hook[id], "segments", "4")
                case  7..16: fm_set_kvd(Hook[id], "segments", "12")
                case 17..36: fm_set_kvd(Hook[id], "segments", "18")
                case 37..100: fm_set_kvd(Hook[id], "segments", "24")
            }
            //end rope

            //set_pev(Hook[id], pev_mins, fMins)
            //set_pev(Hook[id], pev_maxs, fMaxs)

            set_pev(Hook[id], pev_angles, fAngle)

            set_pev(Hook[id], pev_solid, SOLID_BBOX)

            set_pev(Hook[id], pev_movetype, 5)
            get_pcvar_num(pHead) == 5 ? set_pev(Hook[id], pev_owner, 0) : set_pev(Hook[id], pev_owner, id) //jk_botti crash when penguin explodes

            //detach pengin other unstable when they explode
            get_pcvar_num(pHead) == 5 && get_pcvar_num(pUseButtons) < 2 ? set_pcvar_num(pUseButtons, 2) : set_pcvar_num(pUseButtons, 1)

            set_pev(Hook[id], pev_owner, id)
            set_pev(Hook[id], pev_flags, SF_BREAK_TOUCH) //need to make it useful
            //set_pev(Hook[id], pev_health, 100.0) //for smoker

            //Set hook velocity
            static Float:fForward[3], Float:Velocity[3]
            new Float:fSpeed = get_pcvar_float(pThrowSpeed)

            engfunc(EngFunc_MakeVectors, fvAngle)
            global_get(glb_v_forward, fForward)

            Velocity[0] = fForward[0] * fSpeed
            Velocity[1] = fForward[1] * fSpeed
            Velocity[2] = fForward[2] * fSpeed

            set_pev(Hook[id], pev_velocity, Velocity)


            if(pev_valid(Hook[id]>1))
                dllfunc( DLLFunc_Spawn, Hook[id] )

            // Make the line between Hook and Player
            message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, Float:{0.0, 0.0, 0.0}, 0)
            if (get_pcvar_num(pInstant))
            {
                write_byte(1) // TE_BEAMPOINT
                write_short(id) // Startent
                write_coord_f(fStart[0]) // End pos
                write_coord_f(fStart[1])
                write_coord_f(fStart[2])
            }
            else
            {
                write_byte(8) // TE_BEAMENTS
                write_short(id) // Start Ent
                write_short(Hook[id]) // End Ent
            }
            write_short(sprBeam) // Sprite
            write_byte(1) // StartFrame
            write_byte(1) // FrameRate
            write_byte(600) // Life
            write_byte(get_pcvar_num(pWidth)) // Width
            write_byte(get_pcvar_num(pHookNoise)) // Noise
            // Colors now
            new ipColor = get_pcvar_num(pColor)
            if (ipColor && gCStrike )
            {
                if (get_user_team(id) == 1) // Terrorist
                {
                    write_byte(255) // R
                    write_byte(0)   // G
                    write_byte(0)   // B
                }
                #if defined _cstrike_included
                else if(cs_get_user_vip(id)) // vip for cstrike
                {
                    write_byte(0)   // R
                    write_byte(255) // G
                    write_byte(0)   // B
                }
                #endif // _cstrike_included
                else if(get_user_team(id) == 2) // CT
                {
                    write_byte(0)   // R
                    write_byte(0)   // G
                    write_byte(255) // B
                }
                else
                {
                    write_byte(255) // R
                    write_byte(255) // G
                    write_byte(255) // B
                }
            }
            else if (ipColor>2 && !bKnife[id])
            {
                write_byte(random(256)) // R
                write_byte(random(256)) // G
                write_byte(random(256)) // B
            }
            else if(bKnife[id])
            {
                write_byte(0) // R
                write_byte(0) // G
                write_byte(0) // B
            }

            else
            {
                write_byte(255) // R
                write_byte(255) // G
                write_byte(255) // B
            }
            write_byte(192) // Brightness
            write_byte(0) // Scroll speed
            message_end()

            if (get_pcvar_num(pSound) && !get_pcvar_num(pInstant) && !bKnife[id])
                emit_sound(id, CHAN_BODY, "weapons/xbow_fire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH) //make pitch dynamic

            static TaskData[2]
            TaskData[0] = id
            TaskData[1] = Hook[id]

            set_task(0.2, "hookthink", id + 890, TaskData, 2, "b")
        }
        else
            client_print(id, print_chat, "Can't create hook")
    }

}


public remove_hook(id)
{
    if(is_user_connected(id) && pHook && get_pcvar_num(pHook) )
    {
        if(get_pcvar_num(Xdebug))
            server_print "remove %n's Hook", id
        new szClass[MAX_NAME_LENGTH]
        if (pev_valid(Hook[id]) >1)
        {
            //Player can now throw hooks
            canThrowHook[id] = true
            REM:
            pev(Hook[id], pev_classname, szClass, charsmax(szClass))
            if (containi(szClass, "rope") > charsmin || containi(szClass, "wire") > charsmin || containi(szClass, "barnacle") != charsmin || containi(szClass, "penguin") != charsmin )    //equali(szClass, "monster_barnacle"))
            {
                //prevents rope crashing
                //set_pev(Hook[id], pev_owner, 0) //little effect
                return PLUGIN_HANDLED_MAIN //will crash otherwise
            }

            set_pev(id, pev_takedamage, DAMAGE_YES)

            // Remove the hook if it is valid
            if(pev_valid(Hook[id]))
            {
                if(get_pcvar_num(Xdebug))
                    server_print "Removing hook for %n", id
                engfunc(EngFunc_RemoveEntity, Hook[id])
                Hook[id] = 0
            }

            // Remove the line between user and hook
            {
                if(get_pcvar_num(Xdebug))
                    server_print "Removing beam for %n", id
                message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, id)
                write_byte(99) // TE_KILLBEAM
                write_short(id) // entity
                message_end()
            }

            // Player is not hooked anymore
            gHooked[id] = false
            //return 1
        }
        else
        {
            if(get_pcvar_num(Xdebug))
                server_print "There wasn't a hook to remove for %n.", id
            canThrowHook[id] = true
            Hook[id] = 0
            gHooked[id] = false
            goto REM
        }
        if(get_pcvar_num(Xdebug))
            server_print "Hook removal for %n successful", id

    }

    return PLUGIN_HANDLED_MAIN //investigating apache crashy, doesnt need hook but hook can make it worse in Multplayer

}

public give_hook(id, level, cid)
{
    if (!cmd_access(id ,level, cid, 1))
        return PLUGIN_HANDLED

    if (!get_pcvar_num(pAdmin))
    {
        console_print(id, "[Hook] Admin only mode is currently disabled")
        return PLUGIN_HANDLED
    }

    static szTarget[MAX_NAME_LENGTH]
    read_argv(1, szTarget, charsmax(szTarget))

    new iUsrId = cmd_target(id, szTarget)

    if (!iUsrId)
        return PLUGIN_HANDLED

    static szName[MAX_NAME_LENGTH]
    get_user_name(iUsrId, szName, charsmax(szName))

    if (!g_bHookAllowed[iUsrId])
    {
        g_bHookAllowed[iUsrId] = true

        console_print(id, "[Hook] You gave %s access to the hook", szName)
    }
    else
        console_print(id, "[Hook] %s already have access to the hook", szName)

    return PLUGIN_HANDLED
}

public take_hook(id, level, cid)
{
    if (!cmd_access(id ,level, cid, 1))
        return PLUGIN_HANDLED

    if (!get_pcvar_num(pAdmin))
    {
        console_print(id, "[Hook] Admin only mode is currently disabled")
        return PLUGIN_HANDLED
    }

    static szTarget[MAX_NAME_LENGTH]
    read_argv(1, szTarget, charsmax(szTarget))

    new iUsrId = cmd_target(id, szTarget)

    if (!iUsrId)
        return PLUGIN_HANDLED

    static szName[MAX_NAME_LENGTH]
    get_user_name(iUsrId, szName, charsmax(szName))

    if (g_bHookAllowed[iUsrId])
    {
        g_bHookAllowed[iUsrId] = false

        console_print(id, "[Hook] You took away %s his access to the hook", szName)
    }
    else
        console_print(id, "[Hook] %s does not have access to the hook", szName)

    return PLUGIN_HANDLED
}

// Stock by Chaosphere
stock get_user_hitpoint(id, Float:hOrigin[3])
{
    if (!is_user_connected(id))
        return 0

    static Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3]
    static Float:fTemp[3]

    pev(id, pev_origin, fOrigin)
    pev(id, pev_v_angle, fvAngle)
    pev(id, pev_view_ofs, fvOffset)

    xs_vec_add(fOrigin, fvOffset, fvOrigin)

    engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp)

    xs_vec_mul_scalar(feOrigin, 8192.0, feOrigin)
    xs_vec_add(fvOrigin, feOrigin, feOrigin)

    static tr
    engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id, tr)
    get_tr2(tr, TR_vecEndPos, hOrigin)
    //global_get(glb_trace_endpos, hOrigin)

    return 1
}

stock statusMsg(id, szMsg[], {Float,_}:...)
{
    if(is_user_connected(id) && is_user_alive(id) && bHOokUser[id] )
    {
        static iStatusText
        iStatusText = gCStrike ? get_user_msgid("StatusText") : get_user_msgid("HudText")

        static szBuffer[MAX_MENU_LENGTH]
        vformat(szBuffer, charsmax(szBuffer), szMsg, 3)

        if(id == 0)
            emessage_begin(MSG_BROADCAST, iStatusText, _, 0)
        else if(id != 0)
            emessage_begin(MSG_ONE_UNRELIABLE, iStatusText, _, id)
        if(gCStrike)
        {
            ewrite_byte(0) //InitHUDstyle
            ewrite_string(szBuffer) // Message
        }
        else
        {
            ewrite_string(szBuffer) // Message
            ewrite_byte(1) //InitHUDstyle
        }
        emessage_end()

        return 1
    }
    return PLUGIN_HANDLED
}
