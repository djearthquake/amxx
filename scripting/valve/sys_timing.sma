/*                          SYS-TIMING BY SPiNX
 * Experimental for any OS. Linux gets the higher numbers with pingboost.
 * DO NOT put sys_ticrate anywhere as a parameter on the server launch code.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above
 *   copyright notice, this list of conditions and the following disclaimer
 *   in the documentation and/or other materials provided with the
 *   distribution.
 * * Neither the name of the  nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Changelog::
 *
 * November 25th 2021: SPINX
 * Version A to B: env_electrified_wire and env_rope consideration.
 * -Only OF has rope or wire, not CS/CZ/DOD/HL/TFC.
 *
 * Febuary 6th 2023: SPiNX
 * Version B to C: Remove hbp reference. Update lag handler. Reinstate sleep.
 *
 * Febuary 5th 2026 SPiNX
 * Version D to E: Pause on capture maps.
 */

#include amxmodx
#include amxmisc
#include engine_stocks
#define MAX_PLAYERS 32
#define MINUTE 60.0
#define TIMING_TASK 1541
#define charsmin -1

#if !defined client_disconnect
#define client_disconnected client_disconnect
#endif

#if !defined get_pcvar_float
#define get_pcvar_num get_pcvar_float
#endif

#define PLUGIN "Variable sys_ticrate"
new const SzRope_msg[]="Plugin paused due to env_rope would be invisible."
new const SzRopeBadEnts[][]={"env_rope", "env_electrified_wire"}



new g_timing, g_iTic_quota, g_iTic_sleep, g_iTic;
static iRopeTiming = 50   //Single env_rope ent can disappear over 50 tic
static iWaterTiming = 60  //Water under 50 tic is choppy.
static iTiming_Threshold = 32 //Less than this is a drunken effect.
static const ent_type[]="info_ctfdetect"

public plugin_init()
{
    register_plugin(PLUGIN, "E", ".sρiηX҉."); //D figuring in softer changes when loss is detected on the line.

    g_timing       = register_cvar("sys_timing",  "1"); //0|1 disables|enables plugin.
    g_iTic_sleep = register_cvar("sys_sleep",  "32"); //Tic hibernation rate.
    g_iTic_quota = register_cvar("sys_quota", "32"); //Tic rate quota.
    g_iTic            = get_cvar_pointer("sys_ticrate"); //Base tic rate. Only used to launch server with.

    new info_detect = find_ent(charsmin, ent_type)
    if(info_detect)
    {
        console_cmd 0, "sys_ticrate 60.0"
        log_amx "Pausing plugin due to potentional problems."
        pause("a")
    }

    if(find_ent(charsmin, "func_water"))
    {
        server_print "[%s]Water ent found", PLUGIN
        set_pcvar_num g_iTic_quota, iWaterTiming
    }
    if ( is_running("gearbox") == 1 )
        set_task(3.5, "@check_map", 2022)
}

@check_map()
{
    for(new list;list < sizeof(SzRopeBadEnts);++list)
    if( find_ent(-1,SzRopeBadEnts[list]) )
    {
        set_pcvar_num(g_iTic, iRopeTiming)
        log_amx SzRope_msg
        server_print "Tic_setting:%i",get_pcvar_num(g_iTic)
        pause("a")
    }

}

public plugin_cfg()
    set_task(25.0, "@Cpu_saver", TIMING_TASK,_,_,"b")

public client_putinserver(id)
    @Set_tic(id)

@Set_tic(id)if(get_pcvar_num(g_timing))
{
    remove_task(TIMING_TASK)
    for(new list;list < sizeof(SzRopeBadEnts);++list)
    if( find_ent(-1,SzRopeBadEnts[list]) )
    {
        set_pcvar_num(g_iTic, iRopeTiming)
        log_amx SzRope_msg
        server_print "Tic_setting:%i",get_pcvar_num(g_iTic)
        pause("a")
    }

    else if(is_user_connected(id) || is_user_connecting(id) && !is_user_bot(id))
    {
        @set_tic()
    }

    if(!task_exists(TIMING_TASK))
        set_task(7.5, "@Cpu_saver", TIMING_TASK,_,_,"b")

}

public client_remove(id)
{
    get_pcvar_num(g_timing) && !iPlayers() ? set_pcvar_num(g_iTic,get_pcvar_num(g_iTic_sleep)) : @set_tic()
    server_print "Tic_setting:%i",get_pcvar_num(g_iTic)
}

stock iPlayers()
{
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"ch")
    return iHeadcount
}

@set_tic()
{
    new iAlloted_Tic = iPlayers() ? get_pcvar_num(g_iTic_quota)*iPlayers() : get_pcvar_num(g_iTic_sleep)
    set_pcvar_num(g_iTic, iAlloted_Tic)
    server_print "Tic_setting:%i", get_pcvar_num(g_iTic)
}

@Cpu_saver()
{
    if(!iPlayers()) set_pcvar_num(g_iTic, get_pcvar_num(g_iTic_sleep)) & change_task(TIMING_TASK, MINUTE);
    new iPing,iLoss, players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"i")

    for(new lot=0;lot < iHeadcount;lot++)get_user_ping(players[lot],iPing,iLoss)
    if(iLoss)
    {
        if(iLoss > 1)
        {
            server_print "%i|%i", iPing, iLoss
            new iTic = get_pcvar_num(g_iTic)
            if(iTic > iTiming_Threshold)
            {
                new iFakeSleep = sqroot(iTic*2)*2+12
                new iSofterLag = floatround(iTic * 0.7)
                new iSleepTime = get_pcvar_num(g_iTic_sleep)

                if(iSleepTime < 1.0 || iSofterLag  < 1.0 )
                {
                    if(iSleepTime)
                    {
                        iSofterLag = iRopeTiming
                        log_amx "Saved a crash. Get your CPU SAVER iSleepTime math straight!"
                    }

                    iSofterLag = iRopeTiming

                    log_amx "Saved a crash. Get your CPU SAVER iSofterLag math straight!"
                }

                set_pcvar_num( g_iTic, iSofterLag ? iSofterLag : iFakeSleep ? iFakeSleep : iSleepTime)
                server_print "Tic_setting:%i", get_pcvar_num(g_iTic)
                server_print "Adjusting tic based on turbulence."
            }
        }  else @set_tic()
    }
}
