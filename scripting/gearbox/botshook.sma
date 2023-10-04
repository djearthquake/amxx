/**
*    Bots hook. UFO style hook grab. Bind +hook and have fun with bots.
*    Copyleft (C) 2019 .s ^ai  X ^i.
*
*    SPECIAL CREDIT AND ORIGINAL CODE BY ts2do {W`C}Bludy
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define ALLOW_BOTS_TO_HOOK

#define UFO_LEVEL  ADMIN_LEVEL_H

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <fakemeta> ///for ufo saucer fx
#include <hamsandwich>

#define TE_BEAMENTS 8
#define TE_SPARKS 9
#define TE_KILLBEAM 99
#define DELTA_T 0.1
#define TOSS_PREVENTION_LENGTH 20
#define SEND_MSG_ALLPLAYERS 0

#define IS_THERE (~(1<<IN_SCORE))
#define charsmin -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new g_Money
new g_debug
new g_freq

new g_Adm, g_AI, g_hookmod, g_force, g_planefun, g_Adm_highlander
new bool:bHaveHooked[MAX_PLAYERS +1]

new bool:bPlane_made[MAX_PLAYERS+1]
new grabbedorigin2[MAX_PLAYERS + 1][3]
new plane_origin[MAX_PLAYERS + 1][3]
new plane_angles[MAX_PLAYERS + 1][1]
new plane_ent[MAX_PLAYERS + 1]
new look2[MAX_PLAYERS + 1][3]
new grabbed[MAX_PLAYERS + 1]
new hook_motd[1300]
new tEnt[MAX_PLAYERS + 1]
new Float:grav[MAX_PLAYERS + 1][3]
new Float:maxspeed[MAX_PLAYERS + 1]

new const osprey_model[] = "models/mini_osprey.mdl"
new const apache_model[] = "models/mini_apache.mdl"

//better graphic
new const ent_type[]="env_sprite"
new const szSprite[]="sprites/FT/pyramid9.spr"

public plugin_init()
{
    register_plugin("botshook","B1","SPiNX")
    RegisterHam(Ham_Spawn, "player", "unhook", 1); //reset hook on humans so not immobilized if killed hooking!
    g_debug = register_cvar("hook_debug", "0")
    g_hookmod = register_cvar("sv_hook","1")
    g_planefun = register_cvar("sv_hookplane","0")
    g_force = register_cvar("sv_hookforce","2000")
    register_clcmd("+hook","hookgrab")
    register_clcmd("-hook","unhook")
    register_clcmd("say /hook","help_motd")
    register_clcmd("say hook","help_motd")
    register_event("ResetHUD", "new_round", "b")

    register_forward(FM_PlayerPreThink, "fw_PlayerPostThink", 1)
    register_forward(FM_PlayerPreThink, "client_PreThink", 1)

    set_task(180.0,"notify_hook_status")
    format(hook_motd,1299,"There are two different types of hooks, one lets you^n\
    swing (+hook), and the other will pull you directly towards the^n\
    location you hooked onto.^n^n\
    To bind the keys follow these directions:^n^n\
    - First open your console with the tilde ` key^n\
    - Choose the keys that you want to use for the hooks^n\
    - Type in bind ^"The key you chose^" ^"+hook^"^n\
    - Press enter to complete the bind, It should look like this^n^n\
    examples: bind ^"f^" ^"+hook^"^n^n\
    Have Fun!!")
    g_freq = register_cvar("monster_plane_time", "0.1");
}

public plugin_precache()
{
    precache_model(apache_model);
    precache_model(osprey_model);

    precache_model(szSprite)

    new ent = create_entity(ent_type)
    DispatchKeyValue( ent, "origin", "0 0 0" )
    DispatchKeyValue( ent, "scale", ".3" )
    DispatchKeyValue( ent, "renderamt", "255" )
    DispatchKeyValue( ent, "rendermode", "5" )
    DispatchKeyValue( ent, "model", szSprite )
    DispatchKeyValue( ent, "framerate", "10.0" )
    DispatchKeyValue( ent, "angles", "0 0 0" )
    DispatchKeyValue( ent, "rendercolor", "0 0 0" )
    DispatchKeyValue( ent, "spawnflags", "1" )
    DispatchKeyValue( ent, "targetname", "ufo_skin" )
    DispatchSpawn(ent);

    g_Money = precache_model("sprites/vp_parallel_oriented.spr");
}

#if defined ALLOW_BOTS_TO_HOOK
#define HOLDTIME random_num(1,2)
#define SEED 10
#define FREQUENCY random_num(20,40) //how many times a minute to call task

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? (SetPlayerBit(g_AI, id)) : (ClearPlayerBit(g_AI, id))
        get_user_flags(id) & UFO_LEVEL ? (SetPlayerBit(g_Adm, id)) : (ClearPlayerBit(g_Adm, id))
    }
}

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        bHaveHooked[id] = false
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id);
        get_user_flags(id) & UFO_LEVEL ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id);

        tEnt[id]=create_entity("info_target")
        DispatchSpawn(tEnt[id])
        if(get_pcvar_num(g_planefun))
        {
            plane_ent[id] = create_entity("info_target")
            if(get_pcvar_num(g_debug))server_print"Created plane for %n",id
        }
        if(CheckPlayerBit(g_AI, id))
        {
            new sid[3]
            num_to_str(id,sid,charsmax(sid))
            set_task( 60/FREQUENCY+random_float(0.0,Float:SEED),"hook_loop",id,sid,charsmax(sid),"b")
        }
    }
}

public client_disconnected(id)
{
    if(id == g_Adm_highlander)
        g_Adm_highlander = 0;

    ClearPlayerBit(g_AI, id);
    ClearPlayerBit(g_Adm, id);

    if(task_exists(101+id))
        remove_task(101+id)

    //apache

    if(task_exists(id))
        remove_task(id)
    if(pev_valid(tEnt[id] && tEnt[id] > 0))
        remove_entity(tEnt[id])
    if( (plane_ent[id] > 0) && pev_valid(plane_ent[id])> 1 )
    {
        if(get_pcvar_num(g_debug))server_print"Attempting ent removal for %n post diso",id
        remove_entity(plane_ent[id])
        bPlane_made[id] = false
    }

}

public hook_loop(sid[3])
{
    new id = str_to_num(sid);
    if(is_user_connected(id) && is_user_alive(id))
    {
        bHaveHooked[id] = true
        if(CheckPlayerBit(g_AI, id) && is_user_outside(id))
        {
            if(!grabbed[id])
                hook_bot(sid)
            if(get_pcvar_num(g_debug))
                server_print("Hooking %n", id)

            if(get_pcvar_num(g_planefun))
            {
                if(!bPlane_made[id])
                {
                    bPlane_made[id] = true
                    dllfunc( DLLFunc_Spawn, plane_ent[id])
                }
            }
        }
    }
}

public hook_bot(sid[3])
{
    new id = str_to_num(sid)

    if(!is_user_connected(id) && !is_user_alive(id) && !CheckPlayerBit(g_AI, id))
        return PLUGIN_CONTINUE
    if(is_user_alive(id))
    {
        if(get_pcvar_num(g_debug))server_print "Hooking %n", id
        hookgrab(id)
        set_task( float(HOLDTIME), "unhook_bot", id, sid,charsmax(sid));
    }
    return PLUGIN_CONTINUE
}

public unhook_bot(sid[])
{
    new id = str_to_num(sid)
    if(!is_user_connected(id) && !is_user_alive(id) &&  !CheckPlayerBit(g_AI, id))
    return PLUGIN_CONTINUE
    if(is_user_alive(id))
    {
        unhook(id)
        if(get_pcvar_num(g_debug))server_print "Un_Hooking %n", id
        set_pev(id, pev_effects,  0)
    }
    return PLUGIN_CONTINUE
}

#endif

public hookgrab(id)
{
    if(is_user_connected(id))
    {
        if(is_user_alive(id)&&!grabbed[id])
        {
            set_hookgrabbed(id);
            bHaveHooked[id] = true
        }

        if(get_pcvar_num(g_planefun))
        {
            if(!bPlane_made[id])
            {
                bPlane_made[id] = true
                dllfunc( DLLFunc_Spawn, plane_ent[id])
            }
            if(CheckPlayerBit(g_Adm, id))
            {
                if(!g_Adm_highlander)
                {
                    g_Adm_highlander = id
                    set_entity_visibility(plane_ent[id],0)
                }
            }
        }
    }
    return PLUGIN_HANDLED
}

public notify_hook_status()
{
    new players[MAX_PLAYERS], playercount;
    get_players(players,playercount,"c");
    for (new m=0; m<playercount; ++m)
    if(is_user_connected(players[m]) && !CheckPlayerBit(g_AI, players[m]))
    {
        client_print(players[m],print_chat,"[AMX] HookGrab mod is active!  say /hook for more info.");
    }
    set_task(180.0,"notify_hook_status");
    return PLUGIN_CONTINUE;
}

public set_hookgrabbed(id)
{
    if(is_user_alive(id))
    {
        if(!get_pcvar_num(g_hookmod)) return PLUGIN_CONTINUE

        grabbed[id] = id
        if(is_user_connected(grabbed[id]))
        {
            beam_ent(grabbed[id])
            new origin1[3], origin2[3]
            get_user_origin(grabbed[id], origin1)
            get_user_origin(grabbed[id], origin2,3)
            entity_get_vector(id,EV_FL_gravity,grav[id])
            new Float:nograv[3]
            IVecFVec({0,0,0},nograv)
            entity_set_vector(id,EV_FL_gravity,nograv)
            maxspeed[id] = get_user_maxspeed(id)
            set_user_maxspeed(id, 0.001)

            new irView;
            irView = stock_random()

            if(!CheckPlayerBit(g_AI, id))
            {
                console_cmd(id, "default_fov %i", irView);
                set_view(id, CAMERA_3RDPERSON);
            }

            static parm[3]
            num_to_str(id,parm,2)
            set_task(DELTA_T, "hookgrabtask", 101+id, parm, 1, "b")
            return PLUGIN_CONTINUE
        }
    }
    return PLUGIN_HANDLED
}
public simulatefollow(parm[])
{
    static id; id = parm[5]
    if(is_user_alive(id) && grabbed[id])
    {
        static Float:vector[3], neworigin[3]
        is_entity_brush(parm[1]) ? get_brush_entity_origin(parm[1],vector) : entity_get_vector(parm[1],EV_VEC_origin,vector)
        FVecIVec(vector,neworigin)
        for( new a; a<=2; a++) parm[a+2] = neworigin[a]
        set_task( DELTA_T, "simulatefollow", 101+id, parm, 5)
        for( new a; a<=2; a++) neworigin[a]-=parm[a+2]
        new targorigin[3];entity_get_vector(parm[0],EV_VEC_origin,vector)
        FVecIVec(vector,targorigin)
        for( new a; a<=2; a++ ) targorigin[a]+=neworigin[a]
    }
    return PLUGIN_HANDLED
}
public beam_ent(id)
if(is_user_connected(id)/* && is_user_alive(grabbed[id])*/ && pev_valid(tEnt[id])>1)
{
    new hooktarget, body
    get_user_aiming(grabbed[id],hooktarget,body)
    get_user_origin(grabbed[id], look2[id], 3)
    new Float:vector[3];IVecFVec(look2[id],vector)
    entity_set_origin(tEnt[id],vector)
    set_entity_visibility(tEnt[id],1)
    if(hooktarget){
        new parm[6]
        parm[0] = tEnt[id]
        parm[1] = hooktarget
        get_brush_entity_origin(hooktarget,vector)
        new origin[3]
        FVecIVec(vector,origin)
        for( new a; a<=2; a++) parm[a+2] = origin[a]
        parm[5] = id
        set_task( DELTA_T, "simulatefollow", 101+id, parm, 5)
    }
    entity_get_vector(id,EV_VEC_angles,vector)
    entity_set_vector(tEnt[id],EV_VEC_angles,vector)
    entity_get_vector(tEnt[id],EV_VEC_origin,vector)

    emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0}, 0);
    ewrite_byte(TE_BEAMFOLLOW);
    ewrite_short(id);  //(entity:attachment to follow)
    ewrite_short(g_Money);
    ewrite_byte(random_num(2,10)); //(life in 0.1's) was 2-
    ewrite_byte(random_num(5,30)); //(line width in 0.1's)
    ewrite_byte(random_num(75,255));  //(red) 67     (67 25 67 are pink!) 255 150 1 nice afterburner
    ewrite_byte(random_num(50,255)); //(green) 25    (129 109 111 wht)
    ewrite_byte(random_num(11,255)); //(blue)  67
    ewrite_byte(random_num(10,30)); //(brightness)
    emessage_end();
}

public hookgrabtask(parm[])
{
    static id; id = str_to_num(parm)
    if(is_user_connected(id) && is_user_alive(id))
    {
        if(!grabbed[id]) return PLUGIN_CONTINUE

        if(!is_user_alive(grabbed[id]))
            unhook(id)
        else
        {
            new Float:vector[3]
            if(is_valid_ent(tEnt[id]))
            {
                call_think(tEnt[id])
                entity_get_vector(tEnt[id],EV_VEC_origin,vector)
                FVecIVec(vector,look2[id])
                new origin[3], velocity[3], length
                get_user_origin(grabbed[id], origin, 1)
                get_user_origin(grabbed[id], grabbedorigin2[id])
                length = get_distance(look2[id],origin)
                //avoid division by zero and possible tossing
                if( length <= TOSS_PREVENTION_LENGTH  )
                    return PLUGIN_CONTINUE
                new speed = get_pcvar_num(g_force)
                for( new a; a<=2; a++ ) velocity[a]=(origin[a]+look2[id][a]-origin[a]\
                            *speed/length-grabbedorigin2[id][a])
                if(  length <= 7*TOSS_PREVENTION_LENGTH  )
                    for( new a; a <= 2; a++) velocity[a]/=2
                else if(  length <= 6*TOSS_PREVENTION_LENGTH  )
                    for( new a; a <= 2; a++) velocity[a]/=4
                else if(  length <= 5*TOSS_PREVENTION_LENGTH  )
                    for( new a; a <= 2; a++) velocity[a]/=6
                else if(  length <= 3*TOSS_PREVENTION_LENGTH  )
                    for( new a; a <= 2; a++) velocity[a]/=8
                else if(  length <= 2*TOSS_PREVENTION_LENGTH  )
                    for( new a; a <= 2; a++) velocity[a]/=10
                IVecFVec(velocity,vector)
                entity_set_vector(grabbed[id], EV_VEC_velocity, vector)
                return PLUGIN_CONTINUE
            }
        }
    }
    return PLUGIN_HANDLED
}

public unhook(id)
{
    if(is_user_connected(id))
    {

        grabbed[id] = 0
        remove_task(101+id)

        set_user_maxspeed(id,maxspeed[id])
        entity_set_vector(id,EV_FL_gravity,grav[id])
        if(!CheckPlayerBit(g_AI, id))
        {
            console_cmd(id, "default_fov 100");
            set_view(id, CAMERA_NONE);
        }
    }
    return PLUGIN_HANDLED
}

public new_round(id)
{
    if(is_user_connected(id) && grabbed[id])
        unhook(id)
}

public fw_PlayerPostThink(id,{Float,_}:...)
if(get_pcvar_num( g_planefun ))
if(is_user_alive(id) && bHaveHooked[id])
{
    new flags = get_entity_flags(id)
    if(flags & FL_SPECTATOR)
        return

    pev(id, pev_angles, plane_angles[id]);
    pev(id, pev_origin, plane_origin[id]);

    if(get_pcvar_float(g_freq))
    {
        if(is_user_outside(id))
        {
            if(pev_valid(plane_ent[id]) && plane_ent[id] > 0)
            {
                if(get_pcvar_num(g_debug))server_print"Trying add model for %n",id
                set_pev(plane_ent[id],pev_classname,"amx_bot_apache")

                CheckPlayerBit(g_AI, id) ? entity_set_model(plane_ent[id], osprey_model):entity_set_model(plane_ent[id], apache_model)

                set_pev(plane_ent[id],pev_origin,plane_origin[id])
                set_pev(plane_ent[id],pev_angles,plane_angles[id])

                if(id != g_Adm_highlander)
                    set_entity_visibility(plane_ent[id],1)
            }

        }

        if(plane_ent[id])
        {
            //fail safe
            new iEnts; iEnts = engfunc(EngFunc_NumberOfEntities)
            if(iEnts > 1541)
            {
                if(get_pcvar_num(g_debug))
                    server_print"Attempting ent removal for %n", id
                remove_entity(plane_ent[id])
            }
        }
    }
    if(id == g_Adm_highlander && is_user_outside(id))
    {
        new ent
        ent = find_ent_by_tname(charsmin, "ufo_skin")
        if(ent)
        {
            new Float:uOrigin[3]; pev(id,pev_origin, uOrigin)
            set_pev(ent, pev_origin, uOrigin)
        }
    }
}

public help_motd(id) show_motd(id,hook_motd,"Hook Help:")

stock bool:is_user_outside(id)
{
    if(is_user_connected(id) && pev_valid(plane_ent[id]))
    {
        static Float:vOrigin[3];
        pev(id, pev_origin, vOrigin);

        while(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_EMPTY)
            vOrigin[2] += 5.0;
        if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
        {
            set_pev(id, pev_effects, EF_NODRAW )

            if(CheckPlayerBit(g_AI, id) || !CheckPlayerBit(g_Adm, id))
                set_entity_visibility(plane_ent[id],1)

            return true;
        }
        else
        {
            set_entity_visibility(plane_ent[id],0)
            set_pev(id, pev_effects, 0 )
            return false;
        }
    }
    return false
}

stock is_entity_brush(ent)
{
    static mdl[1]
    entity_get_string(ent,EV_SZ_model,mdl,0)
    if(equal(mdl,"*"))
        return 1
    return 0
}

stock stock_random()
{
    return random_num(29, 150);
}
