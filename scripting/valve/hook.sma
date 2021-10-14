/***********************************************************************************\
*    Hook By P34nut    *    Thanks to Joka69, Chaosphere for testing and stuff!     *
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
*   sv_hookhostflollow - If set 1 you can make hostages follow you (default 1)
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
*
\***********************************************************************************/

// Players admin level
#define ADMINLEVEL ADMIN_SLAY

#include <amxmodx>
#include <amxmisc>
#include engine
#include engine_stocks
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#define message_begin_f(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord, %1)
#define MAX_NAME_LENGTH             32
#define MAX_MENU_LENGTH            512
#define charsmin                    -1


//new const RPG[]         = "models/flag.mdl"
new const RPG[]         = "models/tool_box.mdl"

new const HOOK_MODEL[]  = "sprites/zbeam4.spr"
new g_mapname[MAX_NAME_LENGTH]
//new bool:bsatch_crash_fix


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

// MaxPlayers
new gMaxPlayers

// some booleans
new bool:gHooked[MAX_NAME_LENGTH + 1]
new bool:canThrowHook[MAX_NAME_LENGTH + 1]
new bool:rndStarted

// Player Spawn
new bool:gRestart[MAX_NAME_LENGTH + 1] = {false, ...}
new bool:gUpdate[MAX_NAME_LENGTH + 1] = {false, ...}

new gHooksUsed[MAX_NAME_LENGTH + 1] // Used with sv_hookmax
new bool:g_bHookAllowed[MAX_NAME_LENGTH + 1] // Used with sv_hookadminonly

new const debris1[]  = "sound/debris/pushbox1.wav"
new const debris2[]  = "sound/debris/pushbox2.wav"
new const debris3[]  = "sound/debris/pushbox3.wav"
new const glass1[]   = "debris/bustglass1.wav"
new const glass2[]   = "debris/bustglass2.wav"
new const glass1a[]   = "sound/debris/bustglass1.wav"
new const glass2a[]   = "sound/debris/bustglass2.wav"

new const battery[]  = "models/w_battery.mdl"


new const grabable_goodies[][]={"ammo","armoury_entity","item","weapon", "power", "train"}

public plugin_init()
{
    register_plugin("Hook", "1.6", "SPINX|P34nut")

    // Hook commands
    register_clcmd("+hook", "make_hook")
    register_clcmd("-hook", "del_hook")

    register_concmd("amx_givehook", "give_hook", ADMINLEVEL, "<Username> - Give somebody access to the hook")
    register_concmd("amx_takehook", "take_hook", ADMINLEVEL, "<UserName> - Take away somebody his access to the hook")

    if(cstrike_running())
    {
        // Events for roundstart
        register_event("HLTV", "round_bstart", "a", "1=0", "2=0")
        register_logevent("round_estart", 2, "1=Round_Start")

        // Player spawn stuff
        register_event("TextMsg", "Restart", "a", "2=#Game_will_restart_in")
    }
    else
    
    //register_clcmd("fullupdate", "Update")
    RegisterHam(Ham_Spawn, "player", "ResetHUD", 1);
    //register_event("ResetHUD", "ResetHUD", "b")

    // Register cvars
    register_cvar("sv_amxxhookmod",  "version 1.6", FCVAR_SERVER) // yay public cvar
    pHook           =  register_cvar("sv_hook", "1")
    pThrowSpeed     =  register_cvar("sv_hookthrowspeed", "2000")
    pSpeed          =  register_cvar("sv_hookspeed", "300")
    pWidth          =  register_cvar("sv_hookwidth", "32")
    pSound          =  register_cvar("sv_hooksound", "0")
    pColor          =  register_cvar("sv_hookcolor", "1")
    pPlayers        =  register_cvar("sv_hookplayers", "1")
    pInterrupt      =  register_cvar("sv_hookinterrupt", "0")
    pAdmin          =  register_cvar("sv_hookadminonly",  "0")
    pHookSky        =  register_cvar("sv_hooksky", "1")
    pOpenDoors      =  register_cvar("sv_hookopendoors", "1")
    pUseButtons     =  register_cvar("sv_hookusebuttons", "1")
    pHostage        =  register_cvar("sv_hookhostflollow", "1")
    pWeapons        =  register_cvar("sv_hookpickweapons", "1")
    pInstant        =  register_cvar("sv_hookinstant", "0")
    pHookNoise      =  register_cvar("sv_hooknoise", "0")
    pMaxHooks       =  register_cvar("sv_hookmax", "100")
    pRndStartDelay  =  register_cvar("sv_hookrndstartdelay", "0.0")
    pHook_break     =  register_cvar("sv_hookbreak", "1") //break or use door
    pHead           =  register_cvar("sv_hookhead", "4")
    pSegments       =  register_cvar("sv_hooksegments", "3")

    // Touch forward
    register_forward(FM_Touch, "fwTouch")

    // Get maxplayers
    gMaxPlayers = get_maxplayers()
    
    get_mapname(g_mapname, charsmax(g_mapname))

    if(equali(g_mapname,"beach_head"))bsatch_crash_fix=true
    
}

public plugin_precache()
{
    // Hook Model
    precache_model(RPG)
    precache_generic(RPG)

    precache_model("models/barnacle.mdl")
    precache_generic("models/barnacle.mdl")


    precache_model("models/barnaclet.mdl")
    precache_generic("models/barnaclet.mdl")


    // Hook Beam
    sprBeam = precache_model(HOOK_MODEL)
    precache_generic(HOOK_MODEL)
    // Hook Sounds
    precache_sound("weapons/xbow_hit1.wav")
    precache_generic("sound/weapons/xbow_hit1.wav")

    
    precache_generic("sound/weapons/xbow_hit2.wav")
    precache_sound("weapons/xbow_hit2.wav")
    
    precache_sound("weapons/xbow_hitbod1.wav")
    precache_generic("sound/weapons/xbow_hitbod1.wav")
    
    precache_sound("weapons/xbow_fire1.wav")
    precache_generic("sound/weapons/xbow_fire1.wav")

    precache_generic(battery); //func_pushable
    precache_generic(debris1); //func_pushable
    precache_generic(debris2); //func_pushable
    precache_generic(debris3); //func_pushable

    //breakable ent properties
    precache_sound(glass1);   //func_pushable
    precache_sound(glass2);   //func_pushable

    precache_generic(glass1a);   //func_pushable
    precache_generic(glass2a);   //func_pushable
    
    precache_sound("debris/bustmetal1.wav");
    precache_generic("sound/debris/bustmetal1.wav");

    precache_sound("debris/bustmetal2.wav");
    precache_generic("sound/debris/bustmetal2.wav");

    precache_sound("debris/metal1.wav");
    precache_generic("sound/debris/metal1.wav");

    precache_sound("debris/metal2.wav");
    precache_generic("sound/debris/metal2.wav");

    precache_sound("debris/metal3.wav");
    precache_generic("sound/debris/metal3.wav");

    precache_model("sprites/fexplo.spr")
    precache_generic("sprites/fexplo.spr")

    precache_model("models/w_battery.mdl")
    precache_generic("models/w_battery.mdl")
    
    precache_model("models/hair.mdl")
    precache_generic("models/hair.mdl")

    precache_model("models/rope32.mdl")
    precache_generic("models/rope32.mdl")

    precache_model("models/rope16.mdl")
    precache_generic("models/rope16.mdl")
    
    precache_sound("items/grab_rope.wav")
    precache_generic("sound/items/grab_rope.wav")
    
    precache_sound("items/rope1.wav")
    precache_generic("sound/items/rope1.wav")
    
    precache_sound("items/rope2.wav")
    precache_generic("sound/items/rope2.wav")

    precache_sound("items/rope3.wav")
    precache_generic("sound/items/rope3.wav")

    precache_model("models/leech.mdl")
    precache_generic("models/leech.mdl")
    
    precache_sound("leech/leech_bite1.wav");
    precache_generic("sound/leech/leech_bite1.wav");

    precache_sound("leech/leech_bite2.wav");
    precache_generic("sound/leech/leech_bite2.wav");

    precache_sound("leech/leech_bite3.wav");
    precache_generic("sound/leech/leech_bite3.wav");


    precache_sound("leech/leech_alert1.wav");
    precache_generic("sound/leech/leech_alert1.wav");

    precache_sound("leech/leech_alert2.wav");
    precache_generic("sound/leech/leech_alert2.wav");

    precache_sound("barnacle/bcl_alert2.wav")
    precache_sound("barnacle/bcl_bite3.wav")
    precache_sound("barnacle/bcl_chew1.wav")
    precache_sound("barnacle/bcl_chew2.wav")
    precache_sound("barnacle/bcl_chew3.wav")
    precache_sound("barnacle/bcl_die1.wav")
    precache_sound("barnacle/bcl_die3.wav")
    precache_sound("barnacle/bcl_tongue1.wav")

    precache_generic("sound/barnacle/bcl_alert2.wav")
    precache_generic("sound/barnacle/bcl_bite3.wav")
    precache_generic("sound/barnacle/bcl_chew1.wav")
    precache_generic("sound/barnacle/bcl_chew2.wav")
    precache_generic("sound/barnacle/bcl_chew3.wav")
    precache_generic("sound/barnacle/bcl_die1.wav")
    precache_generic("sound/barnacle/bcl_die3.wav")
    precache_generic("sound/barnacle/bcl_tongue1.wav")

}


public make_hook(id)
{
    if (get_pcvar_num(pHook) && is_user_alive(id) && canThrowHook[id] && !gHooked[id]) {
        if (get_pcvar_num(pAdmin))
        {
            if (!(get_user_flags(id) & ADMINLEVEL) && !g_bHookAllowed[id])
            {
                // Show a message
                client_print(id, print_chat, "[Hook] %L",id,"NO_ACC_COM")
                console_print(id, "[Hook] %L",id,"NO_ACC_COM")

                return PLUGIN_HANDLED
            }
        }

        new iMaxHooks = get_pcvar_num(pMaxHooks)
        if (iMaxHooks > 0)
        {
            if (gHooksUsed[id] >= iMaxHooks)
            {
                client_print(id, print_chat, "[Hook] You already used your maximum ammount of hooks")
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

        throw_hook(id)
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
    //need keep trigger_push, barnacle, env_rope intact for now
    if (get_pcvar_num(pHead) > 2) //tested works
    {
        // Remove players hook
        if (!canThrowHook[id])
            remove_hook(id)
    
        return PLUGIN_CONTINUE
    }
    else
        canThrowHook[id] = true

    return PLUGIN_HANDLED

}

public round_bstart()
{
    // Round is not started anymore
    if (rndStarted)
        rndStarted = false

    // Remove all hooks
    for (new i = 1; i <= gMaxPlayers; i++)
    {
        if (is_user_connected(i))
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
    for (new id = 0; id < gMaxPlayers; id++)
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

public ResetHUD(id)
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

    if (gHooked[id] && !find_ent(charsmin,"env_rope") || !find_ent(charsmin,"monster_barnacle") )
        remove_hook(id)

    if (get_pcvar_num(pMaxHooks) > 0)
    {
        gHooksUsed[id] = 0
        statusMsg(id, "[Hook] 0 of %d hooks used.", get_pcvar_num(pMaxHooks))
    }
}

public fwTouch(ptr, ptd)
{
    //if (!pev_valid(ptr) || !pev_valid(ptd) ) //nerfs
    if (!pev_valid(ptr) )
        return FMRES_IGNORED

    new id = pev(ptr, pev_owner)

    // Get classname
    new szPtrClass[MAX_NAME_LENGTH]
    pev(ptr, pev_classname, szPtrClass, charsmax(szPtrClass))

    if (equali(szPtrClass, "Hook") || (containi(szPtrClass, "grapple") > charsmin && get_pcvar_num(pPlayers) > 2) )
    {
    
        static Float:fOrigin[3]
        pev(ptr, pev_origin, fOrigin)
        new szPtdClass[MAX_NAME_LENGTH]

        if (pev_valid(ptd))
        {

            pev(ptd, pev_classname, szPtdClass, charsmax(szPtdClass))

            if(equali(szPtrClass, "env_hook")) 

                return FMRES_IGNORED

            if (!get_pcvar_num(pPlayers) && equali(szPtdClass, "player") && is_user_alive(ptd))
            {
                // Hit a player
                if (get_pcvar_num(pSound))
                    emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                remove_hook(id)

                return FMRES_HANDLED
            }
            else if (containi(szPtdClass, "monster") > charsmin && get_pcvar_num(pPlayers) > 1)
            {
                if (containi(szPtdClass, "ally") > charsmin || containi(szPtdClass, "human") > charsmin || containi(szPtdClass, "turret") > charsmin || 
                containi(szPtdClass, "sentry") > charsmin || containi(szPtdClass, "nuke") > charsmin || containi(szPtdClass, "scientist") > charsmin )
                {
                    // Makes an hostage follow
                    if (get_pcvar_num(pHostage))
                    {

                        dllfunc(DLLFunc_Use, ptd, id)
                    }

                }
                else
                goto damage
            }
            else if (containi(szPtdClass, "breakable") > charsmin || containi(szPtdClass, "pushable") > charsmin || 
            containi(szPtdClass,"illusionary") > charsmin || containi(szPtdClass,"wall") > charsmin)
            {
damage:               
                ExecuteHam(Ham_TakeDamage,ptd,ptd,ptr,100.0,DMG_CRUSH|DMG_ALWAYSGIB) //no hurt barnacles
                ExecuteHam(Ham_TakeDamage,ptd,ptd,id,100.0,DMG_CRUSH|DMG_ALWAYSGIB) //not hurting big momma directly

                remove_hook(id)
                return FMRES_HANDLED
            }

            else if (get_pcvar_num(pOpenDoors) && containi(szPtdClass, "door") > charsmin)
            {                
                if(!get_pcvar_num(pHook_break))
                {
                    dllfunc(DLLFunc_Use, ptd, id) //ok for grap
                    dllfunc(DLLFunc_Touch, ptd, id) //ok for grap
                }
                else
                {
                    entity_set_string(ptd, EV_SZ_classname,"func_breakable")
                    entity_set_float(ptd, EV_FL_takedamage, 2.0);
                    set_pev(ptd,pev_solid, SOLID_BBOX)
                    set_pev(ptd, pev_flags, SF_BREAK_TOUCH)
                    entity_set_float(ptd, EV_FL_health, 10.0)
                    dllfunc(DLLFunc_Touch, ptd, id) //ok for grap
                }
                
///stopdoors:
            }
            else if (get_pcvar_num(pUseButtons) && (containi(szPtdClass, "button") > charsmin || containi(szPtdClass, "charger") > charsmin || containi(szPtdClass, "recharge") > charsmin))
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
                emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            remove_hook(id)
            return FMRES_HANDLED
        }

        // Pick up weapons..
        if (get_pcvar_num(pWeapons))
        {
            static ent
            while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, fOrigin, 125.0)) > 0)
            {
                static szentClass[MAX_NAME_LENGTH]
                pev(ent, pev_classname, szentClass, charsmax(szentClass))

                for (new toget; toget < sizeof grabable_goodies;toget++)

                if (containi(szentClass, grabable_goodies[toget]) != charsmin && containi(szentClass, "satchel") == charsmin)
                dllfunc(DLLFunc_Touch, ent, id)
            }
        }

        // Player is now hooked
        gHooked[id] = true
        // Play sound
        if (get_pcvar_num(pSound))
            emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

        // Make some sparks :D
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
        write_byte(9) // TE_SPARKS
        write_coord_f(fOrigin[0]) // Origin
        write_coord_f(fOrigin[1])
        write_coord_f(fOrigin[2])
        message_end()

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
    return FMRES_HANDLED
}

public hookthink(param[])
{
    new id = param[0]
    new HookEnt = param[1]

    if (!is_user_alive(id) || !pev_valid(HookEnt) || !pev_valid(id))
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
    if (!get_pcvar_num(pHookSky) && iContents == CONTENTS_SKY)
    {
        if(get_pcvar_num(pSound))
            emit_sound(HookEnt, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        remove_hook(id)
    }

    return PLUGIN_HANDLED
}

public gotohook(param[])
{
    new id = param[0]
    new HookEnt = param[1]

    if (!is_user_alive(id) || !pev_valid(HookEnt) || !pev_valid(id))
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
    // Get origin and angle for the hook
    static Float:fOrigin[3], Float:fAngle[3],Float:fvAngle[3]
    static Float:fStart[3]
    pev(id, pev_origin, fOrigin)

    pev(id, pev_angles, fAngle)
    pev(id, pev_v_angle, fvAngle)

    if (get_pcvar_num(pInstant))
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
    //Hook[id] = create_entity("env_smoker")  // like a mag glass
    switch(get_pcvar_num(pHead))
    {
        case 0: Hook[id] = create_entity("env_rope") //hook needs to be instant for roping otherwise makes a web
        //case 1: Hook[id] = create_entity("monster_tripmine") //fun stable needs refinements limp no pull hook no blowup
        case 1: Hook[id] = create_entity("monster_barnacle") //fun stable needs to be dettached like env_rope
        case 2: Hook[id] = create_entity("trigger_push") /// Next work in progress
        case 3: Hook[id] = create_entity("monster_snark")
        case 4: Hook[id] = create_entity("monster_penguin") //chaos expected //better without instanthook on
        case 5: Hook[id] = create_entity("monster_leech") //novelty. works fine underwater. Decent limp mode for hook.
        case 6: Hook[id] = create_entity("light")
    }
    //if using certain hooks they need set up just so to work as expected
    if(get_pcvar_num(pHead) == 1 && !get_pcvar_num(pInstant))
        set_pcvar_num(pInstant, 1)
    //only admins should be making ropes at this time. Hard on the network resources.
    if(!get_pcvar_num(pHead) && !get_pcvar_num(pAdmin) ?
    set_pcvar_num(pAdmin, 1) & set_pcvar_num(pInstant, 1) : set_pcvar_num(pAdmin, 0))
    

    if (Hook[id])
    {
        // Player cant throw hook now
        canThrowHook[id] = false

        static const Float:fMins[3] = {-2.840000, -14.180000, -2.840000}
        static const Float:fMaxs[3] = {2.840000, 0.020000, 2.840000}

        //Set some Data
        
        get_pcvar_num(pHead) <= 1 ? set_pev(Hook[id], pev_classname, "Hook") : set_pev(Hook[id], pev_classname, "Hook_rope")

        engfunc(EngFunc_SetModel, Hook[id], RPG)
        engfunc(EngFunc_SetOrigin, Hook[id], fOrigin)
        engfunc(EngFunc_SetSize, Hook[id], fMins, fMaxs)
        //env_explosion/breakable
        //set_pev(Hook[id], pev_flags, SF_BREAK_TOUCH)
        //env_smoker
        fm_set_kvd(Hook[id], "scale" , "1000"); //smoker

        //fm_set_kvd(Hook[id], "explodemagnitude", "350") //like the C4 on CS. Exactly
        
        
        
        /*
         classname trigger_push
        trigger_push model *228
        trigger_push style 32
        trigger_push sounds 0*
        trigger_push delay 0*
        trigger_push spawnflags 0*
        trigger_push angles 0 -90 0*
        trigger_push speed 1000*
        */
        fm_set_kvd(Hook[id], "angles", "0 0 0");
        //fm_set_kvd(Hook[id], "spawnflags", "0");
        fm_set_kvd(Hook[id], "speed", "1000");
        //fm_set_kvd(Hook[id], "sounds", "0");
        //fm_set_kvd(Hook[id], "style", "32");
        //fm_set_kvd(Hook[id], "model", "*228"); // Host_Error: no precache: 32

        fm_set_kvd(Hook[id], "height", "9000");

        //trigger_hurt
        fm_set_kvd(Hook[id], "dmg ", "-20");
        fm_set_kvd(Hook[id], "delay", "0");
        fm_set_kvd(Hook[id], "damagetype", "0");
        //end hurt spec

        //env_rope
        fm_set_kvd(Hook[id], "bodymodel", "models/rope32.mdl")
        //give env_rope spec target name so penguins don't explode and disable the ropes. use that later to cancel out ropes we do not need/want.
        //long segmented ropes are hard on the processor.
        !get_pcvar_num(pHead) ? fm_set_kvd(Hook[id], "targetname", "hooks_rope") : fm_set_kvd(Hook[id], "targetname", "hooks_head")

        switch(get_pcvar_num(pSegments))
        {
            case   1..6: fm_set_kvd(Hook[id], "segments", "6")
            case  7..16: fm_set_kvd(Hook[id], "segments", "14")
            case 17..36: fm_set_kvd(Hook[id], "segments", "24")
            case 37..50: fm_set_kvd(Hook[id], "segments", "36")
        }


        fm_set_kvd(Hook[id], "endingmodel", "models/rope16.mdl")
        //end rope

        //set_pev(Hook[id], pev_mins, fMins)
        //set_pev(Hook[id], pev_maxs, fMaxs)

        set_pev(Hook[id], pev_angles, fAngle)

        set_pev(Hook[id], pev_solid, 2)
        set_pev(Hook[id], pev_movetype, 5)
        set_pev(Hook[id], pev_owner, id)
        
      //  set_pev(Hook[id], pev_flags, SF_BREAK_TOUCH) //need to make it useful
      //  set_pev(Hook[id], pev_health, 100.0) //for smoker

        //Set hook velocity
        static Float:fForward[3], Float:Velocity[3]
        new Float:fSpeed = get_pcvar_float(pThrowSpeed)

        engfunc(EngFunc_MakeVectors, fvAngle)
        global_get(glb_v_forward, fForward)

        Velocity[0] = fForward[0] * fSpeed
        Velocity[1] = fForward[1] * fSpeed
        Velocity[2] = fForward[2] * fSpeed

        set_pev(Hook[id], pev_velocity, Velocity)
        
        
        
        dllfunc( DLLFunc_Spawn, Hook[id] )

        // Make the line between Hook and Player
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, Float:{0.0, 0.0, 0.0}, 0)
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
        if (get_pcvar_num(pColor) && cstrike_running())
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
        else
        {
            write_byte(255) // R
            write_byte(255) // G
            write_byte(255) // B
        }
        write_byte(192) // Brightness
        write_byte(0) // Scroll speed
        message_end()

        if (get_pcvar_num(pSound) && !get_pcvar_num(pInstant))
            emit_sound(id, CHAN_BODY, "weapons/xbow_fire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)

        static TaskData[2]
        TaskData[0] = id
        TaskData[1] = Hook[id]

        set_task(0.2, "hookthink", id + 890, TaskData, 2, "b")
    }
    else
        client_print(id, print_chat, "Can't create hook")
}


public remove_hook(id)
{
    if(is_user_connected(id))

    server_print "remove_Hook call"
    //Player can now throw hooks
    canThrowHook[id] = true
    new szClass[MAX_NAME_LENGTH]
    if (pev_valid(Hook[id]))
        pev(Hook[id], pev_classname, szClass, charsmax(szClass))
    if (containi(szClass, "rope") > charsmin || containi(szClass, "barnacle") != charsmin)    //equali(szClass, "monster_barnacle"))
    {
        //prevents rope crashing
        set_pev(Hook[id], pev_owner, 0)
        return PLUGIN_HANDLED_MAIN//will crash otherwise fn guarantee it!
    }

    // Remove the hook if it is valid
    if (pev_valid(Hook[id]))
    {
        engfunc(EngFunc_RemoveEntity, Hook[id])
        Hook[id] = 0
    }

    // Remove the line between user and hook

    if(is_user_connected(id))
    {
        message_begin(MSG_PVS, SVC_TEMPENTITY, {0,0,0}, id)
        write_byte(99) // TE_KILLBEAM
        write_short(id) // entity
        message_end()
    }

    // Player is not hooked anymore
    gHooked[id] = false
    //return 1

    return PLUGIN_CONTINUE
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
    if (!is_user_alive(id))
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
    static iStatusText

    iStatusText = get_user_msgid("HudText")

    static szBuffer[MAX_MENU_LENGTH]
    vformat(szBuffer, charsmax(szBuffer), szMsg, 3)

    if(id == 0)
        emessage_begin(MSG_BROADCAST, iStatusText, _, 0)
    else if(id != 0)
        emessage_begin(MSG_ONE_UNRELIABLE, iStatusText, _, id)

    ewrite_string(szBuffer) // Message
    ewrite_byte(1) //InitHUDstyle 
    emessage_end()

    return 1
}
