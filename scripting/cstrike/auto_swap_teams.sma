/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */

#include amxmodx
#include amxmisc
#include cstrike
#include hamsandwich
#define MAX_PLAYERS                 32
#define MAX_USER_INFO_LENGTH       256
#define TASKID 5007

#define PLUGIN "Auto-Team swap"
#define VERSION "1.0"
#define AUTHOR ".sρiηX҉."
#define VOTE_ACCESS     ADMIN_CFG
new vote_count[2]

new counter, pfTime, pMrounds, pRestart
new bool:TERR[MAX_PLAYERS+1],bool:AFK[MAX_PLAYERS+1]


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_logevent("@OnRoundStart", 2, "1=Round_Start")
    register_logevent("@OnRoundEnd", 2, "1=Round_End")
    register_concmd("swap_vote","cmdVote",VOTE_ACCESS,": Vote for autoswapping teams")


    pfTime   = register_cvar("amx_hud_time", "5.0")
    pMrounds = register_cvar("amx_max_rounds", "2")
    pRestart = get_cvar_pointer("sv_restartround")

    register_menucmd(register_menuid("Autoswap teams?"),(1<<0)|(1<<1),"voteTeamSwitch")

}

@OnRoundStart()
    if(!get_pcvar_num(pRestart) && get_gametime() > get_pcvar_float(pfTime) * 2.0 )
        counter++

@OnRoundEnd()
if(get_pcvar_num(pfTime))
    @hud_task()

@hud_task()
{
    if(!get_pcvar_num(pRestart) && get_gametime() > get_pcvar_float(pfTime) * 2.0 )
        if(!task_exists(TASKID ))
            set_task(get_pcvar_float(pfTime)/4,"@New_Hud",TASKID )
}

@New_Hud()
{
    new switch_sound[MAX_PLAYERS]
    set_dhudmessage(100, 255, 0, -1.0, 0.50, 1, get_pcvar_float(pfTime)/4, get_pcvar_float(pfTime));
    if(counter >= get_pcvar_num(pMrounds))
    {
        show_dhudmessage(0, "Switching Teams!");counter = 0

        for (new player=1; player<=32; player++)
        {
            if(is_user_connected(player))

            {

                if(get_user_team(player) == 1)
                    TERR[player] = true
                else if(get_user_team(player) == 2)
                    TERR[player] = false
                else
                    AFK[player] = true

                if(cs_get_user_vip(player))
                    cs_set_user_vip(player,0,0,0)

                if(!AFK[player])
                {
                    cs_set_user_team(player,TERR[player] ? CS_TEAM_CT : CS_TEAM_T,CS_DONTCHANGE, false)

                    if(cs_get_user_vip(player))
                    {
                        cs_set_user_vip(player,0,0,0)
                        ExecuteHamB(Ham_CS_RoundRespawn, player)
                        set_pcvar_num(pRestart,1)
                    }

                    new iNum = random_num(1,5)
                    formatex(switch_sound,charsmax(switch_sound),"spk sound/hostage/hos%i.wav",iNum)

                    switch(random_num(0,1))
                    {
                        case 0: client_cmd(player,"%s",switch_sound)
                        case 1: client_cmd(player,"spk ^"team switch^"")
                    }
                }
            }
        }
    }
    else
    {
        new switch_time[16]
        new bottom_line = get_pcvar_num(pMrounds) - counter
        num_to_word(bottom_line, switch_time, charsmax(switch_time))
        client_cmd(0,"spk ^"%s round until switch^"",switch_time)
        show_dhudmessage(0, "Rounds Until Switching: %i", bottom_line);
    }


}

public cmdVote(id,level,cid) {
    if(!cmd_access(id,level,cid,1) || task_exists(3517)) return PLUGIN_HANDLED

    new keys = (1<<0|1<<1)
    for(new i = 0; i < 2; i++)
        vote_count[i] = 0

    new menu[MAX_USER_INFO_LENGTH]
    new len = format(menu,charsmax(menu),"[AMX] %s Autoswap teams?^n", get_pcvar_float(pfTime) ? "Disable" : "Enable")
    len += format(menu[len],charsmax(menu),"^n1. Yes")
    len += format(menu[len],charsmax(menu),"^n2. No")

    show_menu(0,keys,menu,10)
    set_task(10.0,"vote_results",3517)
    return PLUGIN_HANDLED
}

public voteTeamSwitch(id, key)
    vote_count[key]++

public vote_results()
{
    if(vote_count[0] > vote_count[1])
    {
        client_print(0,print_chat,"[%s %s] Voting successfully (yes ^"%d^") (no ^"%d^") %s is now %s", PLUGIN, VERSION, vote_count[0], vote_count[1], PLUGIN, get_pcvar_float(pfTime) ? "disabled" : "enabled")
        set_pcvar_float(pfTime,get_pcvar_float(pfTime) ? 0.0 : 5.0)
    }else{
        client_print(0,print_chat,"[%s %s] Voting failed (yes ^"%d^") (no ^"%d^")", PLUGIN, VERSION, vote_count[0], vote_count[1])
    }

}
