/**
*    Bots hook. UFO style hook grab. Bind +hook and have fun with bots.
*    Copyleft (C) 2019 .s ^ai  X ^i.
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
#include <amxmodx>
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

new g_Money
new g_debug
new g_freq

new bool:bPlane_made[MAX_PLAYERS+1]
new grabbedorigin2[33][3]
new plane_origin[33][3]
new plane_angles[33][1]
new plane_ent[33]
new look2[33][3]
new grabbed[33]
new hook_motd[1300]
new tEnt[33]
new Float:grav[33][3]
new beamend[] = "models/terd.mdl"
new Float:maxspeed[33]

new const osprey_model[] = "models/mini_osprey.mdl"
new const apache_model[] = "models/mini_apache.mdl"

stock is_entity_brush(ent)
{
    new mdl[1]
    entity_get_string(ent,EV_SZ_model,mdl,0)
    if(equal(mdl,"*"))
        return 1
    return 0
}

public hookgrab(id)
if(is_user_alive(id)&&!grabbed[id])
    set_hookgrabbed(id);


public notify_hook_status()
{
    new players[32], playercount;
    get_players(players,playercount,"c");
    for (new m=0; m<playercount; ++m)
        client_print(players[m],print_chat,"[AMX] HookGrab mod is active!  say /hook for more info.");
    set_task(380.0,"notify_hook_status");
    return PLUGIN_CONTINUE;
}

public set_hookgrabbed(id)
{
    if(is_user_alive(id))
    {
        if(!get_cvar_num("sv_hook")) return PLUGIN_CONTINUE
        grabbed[id] = id
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
        irView = random_num(29, 150);
    
        if(!is_user_bot(id))
        {
            console_cmd(id, "default_fov %i", irView);
            set_view(id, CAMERA_3RDPERSON);
        }
    
    // add sound switch here
    #define BENDER random_num(45,180)
    #define VOLUMES random_float(0.1,0.5)
    
        new parm[3]
        num_to_str(id,parm,2)
        set_task(DELTA_T, "hookgrabtask", 101+id, parm, 1, "b")
        ///ufo(id)
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}
public simulatefollow(parm[])
{
    if(grabbed[parm[5]])
    {
        new Float:vector[3], neworigin[3]
        if(is_entity_brush(parm[1]))
            get_brush_entity_origin(parm[1],vector)
        else
            entity_get_vector(parm[1],EV_VEC_origin,vector)
        FVecIVec(vector,neworigin)
        for( new a; a<=2; a++) parm[a+2] = neworigin[a]
        set_task( DELTA_T, "simulatefollow", 101+parm[5], parm, 5)
        for( new a; a<=2; a++) neworigin[a]-=parm[a+2]
        new targorigin[3];entity_get_vector(parm[0],EV_VEC_origin,vector)
        FVecIVec(vector,targorigin)
        for( new a; a<=2; a++ ) targorigin[a]+=neworigin[a]
    }
    return PLUGIN_HANDLED
}
public beam_ent(id)
if(is_user_connected(id))
{
    new hooktarget, body
    get_user_aiming(grabbed[id],hooktarget,body)
    get_user_origin(grabbed[id], look2[id], 3)
    new Float:vector[3];IVecFVec(look2[id],vector)
    entity_set_origin(tEnt[id],vector)
    //set_entity_visibility(tEnt[id],1)
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

    message_begin(MSG_BROADCAST,23);
    write_byte(TE_BEAMFOLLOW);
    write_short(id);  //(entity:attachment to follow)
    write_short(g_Money);
    write_byte(random_num(2,10)); //(life in 0.1's) was 2-
    write_byte(random_num(5,30)); //(line width in 0.1's)
    write_byte(random_num(75,255));  //(red) 67     (67 25 67 are pink!) 255 150 1 nice afterburner
    write_byte(random_num(50,255)); //(green) 25    (129 109 111 wht)
    write_byte(random_num(11,255)); //(blue)  67
    write_byte(random_num(10,30)); //(brightness)
    message_end();
}

public hookgrabtask(parm[])
{
    new id = str_to_num(parm)
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
            new speed = get_cvar_num("sv_hookforce")
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
    return PLUGIN_HANDLED
}

public unhook(id)
{
    if(is_user_connected(id))
    {
    /*
        message_begin( MSG_PVS, SVC_TEMPENTITY )
        write_byte( TE_KILLBEAM )
        write_short( tEnt[id] )
        message_end()
        set_entity_visibility(tEnt[id],0)
    */
        grabbed[id] = 0
        remove_task(101+id)
    
    
        set_user_maxspeed(id,maxspeed[id])
        entity_set_vector(id,EV_FL_gravity,grav[id])
        if(!is_user_bot(id) && is_user_alive(id))
        {
            console_cmd(id, "default_fov 100");
            set_view(id, CAMERA_NONE);
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public new_round(id)
{
    if(is_user_connected(id) && grabbed[id])
        unhook(id)
}
public fw_PlayerPostThink2(id)
{
    //is_user_outside(id) ? set_pev(id, pev_effects, EF_NODRAW ) : set_pev(id, pev_effects, 0 )
    //is_user_outside(id) ? set_entity_visibility(plane_ent[id],1) :  set_entity_visibility(plane_ent[id],1)
    //set_entity_visibility(plane_ent[id], is_user_outside(id) ? 1 : 0)
}
/*
public client_PreThink(id)
{
    set_pev(id, pev_effects, is_user_outside(id) ? EF_NODRAW : 0 )

    if(pev_valid(plane_ent[id]))
        set_entity_visibility(plane_ent[id], is_user_outside(id) ? 1 : 0)
}
*/
public fw_PlayerPostThink(id,{Float,_}:...)
if(is_user_connected(id) && is_user_bot(id) || is_user_alive(id) && !is_user_bot(id)  )
{

    if( (plane_ent[id] > 0) && !pev_valid(plane_ent[id]) )
    {
        if(get_pcvar_num(g_debug))server_print"Attempting ent removal for %n",id
        remove_entity(plane_ent[id])
    }

    if (get_pcvar_float(g_freq))
    {
       // if(is_user_outside(id))
        {
            plane_ent[id] = create_entity("info_target")
            if(get_pcvar_num(g_debug))server_print"Created plane for %n",id
    
            pev(id, pev_angles, plane_angles[id]);
            pev(id, pev_origin, plane_origin[id]);
    
    
            if(is_user_outside(id))
            //if(pev_valid(plane_ent[id]) && plane_ent[id] > 0)
            {
                if(get_pcvar_num(g_debug))server_print"Trying add model for %n",id
                set_pev(plane_ent[id],pev_classname,"amx_bot_apache")
    
    
                is_user_bot(id) ? entity_set_model(plane_ent[id], osprey_model):entity_set_model(plane_ent[id], apache_model)
                //set_pev(id, pev_effects, EF_NODRAW ) //over the top
                //set_entity_visibility(plane_ent[id],1)
                set_pev(plane_ent[id],pev_origin,plane_origin[id])
                set_pev(plane_ent[id],pev_angles,plane_angles[id])
                //set_entity_visibility(plane_ent[id],1)
    
                if(!bPlane_made[id])
                {
                    bPlane_made[id] = true
                    dllfunc( DLLFunc_Spawn, plane_ent[id])
                }
    
            }

        }
       // else
        //set_pev(id, pev_effects,0)
        //if(pev_valid(plane_ent[id]))
        //    set_entity_visibility(plane_ent[id],0)

    }

}
/*
public client_PostThink(id)
    if(!is_user_outside(id))
        set_pev(id, pev_effects,0)
*/
public plugin_precache()
{
    precache_model(apache_model);
    precache_generic(apache_model);
    precache_model(osprey_model);
    precache_generic(apache_model);
        ///using generic saw FATAL ERROR (shutting down): Cache_TryAlloc: 421920 is greater then free hunk
        ///FATAL ERROR (shutting down): Too many resources on server.
    g_Money = precache_model("sprites/vp_parallel_oriented.spr");
    precache_generic("sprites/vp_parallel_oriented.spr")
    // precache_model(beamend)
}
public help_motd(id) show_motd(id,hook_motd,"Hook Help:")
public plugin_init()
{
    register_plugin("botshook","B","SPiNX") // Base bot hook grab by ts2do {W`C}Bludy
    //07-2021
    RegisterHam(Ham_Spawn, "player", "unhook", 1); //reset hook on humans so not immobilized if killed hooking!
    g_debug = register_cvar("hook_debug", "0")
    register_cvar("sv_hook","1")
    register_cvar("sv_hookforce","2000")
    register_clcmd("+hook","hookgrab")
    register_clcmd("-hook","unhook")
    register_clcmd("say /hook","help_motd")
    register_clcmd("say hook","help_motd")
    register_event("ResetHUD", "new_round", "b")

    register_forward(FM_PlayerPreThink, "fw_PlayerPostThink", 1)

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
    /*
    for( new id; id <= get_maxplayers(); id++)
    {
        tEnt[id]=create_entity("info_target")
        DispatchSpawn(tEnt[id])
        entity_set_model(tEnt[id],beamend)
        set_entity_visibility(tEnt[id],0)
    }
    * */
    g_freq = register_cvar("monster_plane_time", "0.1");
}
#if defined ALLOW_BOTS_TO_HOOK
#define HOLDTIME 3
#define SEED 10
#define FREQUENCY 20 //how many times a minute to call task
public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        tEnt[id]=create_entity("info_target")
        DispatchSpawn(tEnt[id])

        new sid[3]
        if(is_user_bot(id))
        {
            num_to_str(id,sid,2)
            set_task( 60/FREQUENCY+random_float(0.0,Float:SEED),"hook_loop",id,sid,2,"b")
        }
        ///set_task(get_pcvar_float(g_freq),"fw_PlayerPostThink2",id,.flags="b")
    }
}
public client_disconnected(id) 
{
    if(task_exists(101+id))
        remove_task(101+id)

    //apache

    if(task_exists(id))
        remove_task(id)
    if(pev_valid(tEnt[id] && tEnt[id] > 0))
        remove_entity(tEnt[id])
    if( (plane_ent[id] > 0) && pev_valid(plane_ent[id]) )
    {
        if(get_pcvar_num(g_debug))server_print"Attempting ent removal for %n post diso",id
        remove_entity(plane_ent[id])
        bPlane_made[id] = false
    }

}

public hook_loop(sid[])
{
    new id = str_to_num(sid);
    if(is_user_bot(id) && is_user_connected(id))
    {
        if(!grabbed[id])
            hook_bot(sid)
        //grabbed[id] ? unhook_bot(sid) : hook_bot(sid)
        ///!grabbed[id] ? hook_bot(sid) : unhook_bot(sid)
        /*
        if(is_user_bot(id))
        {
            new mname[MAX_NAME_LENGTH];
        
            get_mapname(mname, charsmax(mname) );
            if(containi(mname,"city_scope") > -1)
                hook_bot(sid)
        
            else if(is_user_outside(id) && get_cvar_num("sv_hook")&&is_user_bot(id)&&is_user_connected(id)&&!grabbed[id])
                hook_bot(sid)
        }*/
    }
}
public hook_bot(sid[])
{
    new id = str_to_num(sid)

    if(!is_user_connected(id) && !is_user_alive(id) && !is_user_bot(id))
        return PLUGIN_CONTINUE
    if(is_user_outside(id))
    {
        server_print "Hooking %n", id
        //set_pev(id, pev_effects,  EF_NODRAW)
        hookgrab(id)
        set_task( float(HOLDTIME), "unhook_bot", 0, sid, 2 );
    }
    return PLUGIN_HANDLED
}
public unhook_bot(sid[])
{
    new id = str_to_num(sid)
    if(!is_user_connected(id) && !is_user_alive(id) && !is_user_bot(id))
    return PLUGIN_CONTINUE

    unhook(id)
    server_print "Un_Hooking %n", id
    set_pev(id, pev_effects,  0)
/*
    if(task_exists(id))
        remove_task(id)
*/


    /*
    if(is_user_connected(id))
    {
        if( (plane_ent[id] > 0) && pev_valid(plane_ent[id]))
        {
            if(get_pcvar_num(g_debug))server_print"Attempting ent removal for %n post diso",id
            remove_entity(plane_ent[id])
        }
    
        return PLUGIN_CONTINUE
    }
    */
    return PLUGIN_HANDLED
}
#endif

stock bool:is_user_outside(id)
{
    if(is_user_connected(id) && pev_valid(plane_ent[id]))
    {
        new Float:vOrigin[3], Float:fDist;
        pev(id, pev_origin, vOrigin);
        fDist = vOrigin[2];
        while(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_EMPTY)
            vOrigin[2] += 5.0;
        if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
        {
            set_pev(id, pev_effects, EF_NODRAW )
            set_entity_visibility(plane_ent[id],0)
            return true;
        }
        else
        {
            set_entity_visibility(plane_ent[id],1)
            set_pev(id, pev_effects, 0 )
            return false;
        }
    }
    return false
}
