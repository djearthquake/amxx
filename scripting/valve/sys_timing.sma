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
 * Changelog November 25th 2021: SPINX
 * Version A to B: env_electrified_wire and env_rope consideration.
 * -Only OF has rope or wire, not CS/CZ/DOD/HL/TFC.
 */

#include amxmodx
#include amxmisc
#include engine_stocks
#define MAX_PLAYERS 32

#if !defined client_disconnect
#define client_disconnected client_disconnect
#endif

new const SzRope_msg[]="Plugin paused due to env_rope would be invisible."
new g_timing, g_iTic_quota, g_iTic_sleep, g_iTic;

public plugin_init()
{
    register_plugin("Variable sys_ticrate", "C", ".sρiηX҉.");
    g_timing     = register_cvar("sys_timing",  "1"); //0|1 disables|enables plugin.
    g_iTic_sleep = register_cvar("sys_sleep",  "32"); //Tic hibernation rate.
    g_iTic_quota = register_cvar("sys_quota", "32"); //Tic rate quota.
    g_iTic       = get_cvar_pointer("sys_ticrate"); //Base tic rate. Only used to launch server with.
    set_task(7.5, "@Cpu_saver", 1541,_,_,"b")

    if ( is_running("gearbox") == 1 )
        set_task(3.5, "@check_map", 2022)
}

@check_map()
{
    new mname[MAX_NAME_LENGTH];
    server_print "Found Gearbox running."
    get_mapname(mname,charsmax(mname));

    if(containi(mname, "op4c") > -1 )
    {
        set_pcvar_num(g_iTic,35) //per HPB bots will speedhack otherwise 
        pause("a")
    }
}

public client_putinserver(id)
if (get_pcvar_num(g_timing) == 1)
{
    remove_task(1541)
    if( find_ent(-1,"env_rope") || find_ent(-1,"env_electrified_wire") ) //Rope can disappear over 70fps. My hook mod can shoot various lengths of it.
    {
        set_pcvar_num(g_iTic,70)
        log_amx SzRope_msg
        server_print "Tic_setting:%i",get_pcvar_num(g_iTic)
        pause("a")
    }

    else if(is_user_connected(id) && !is_user_bot(id))
    {
        @set_tic()
    }
    else server_print "bot detected!"
    set_task(7.5, "@Cpu_saver", 1541,_,_,"b")

}

public client_remove(id)
{
    (get_pcvar_num(g_timing) && iPlayers() < 2) ? set_pcvar_num(g_iTic,get_pcvar_num(g_iTic_sleep)) : @set_tic()
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
    set_pcvar_num(g_iTic, iAlloted_Tic ? iAlloted_Tic : g_iTic_sleep)
    server_print "Tic_setting:%i",get_pcvar_num(g_iTic)
}

@Cpu_saver()
{
    new iPing,iLoss
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"i")

    for(new lot;lot < sizeof players;lot++)
        get_user_ping(players[lot],iPing,iLoss)

    if(iLoss)
    if(iLoss > 2)
    {
        server_print "%i|%i",iPing,iLoss
        set_pcvar_num g_iTic,iLoss > 1 ? 35 : 70
        server_print "Tic_setting:%i",get_pcvar_num(g_iTic)
        log_amx "Adjusting tic based on turbulence."
    }
    else
    @set_tic()
}
