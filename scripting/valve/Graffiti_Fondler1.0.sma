/*
*
*   SSSSSSSSSSSSSSS PPPPPPPPPPPPPPPPP     iiii  NNNNNNNN        NNNNNNNNXXXXXXX       XXXXXXX
* SS:::::::::::::::SP::::::::::::::::P   i::::i N:::::::N       N::::::NX:::::X       X:::::X
*S:::::SSSSSS::::::SP::::::PPPPPP:::::P   iiii  N::::::::N      N::::::NX:::::X       X:::::X
*S:::::S     SSSSSSSPP:::::P     P:::::P        N:::::::::N     N::::::NX::::::X     X::::::X
*S:::::S              P::::P     P:::::Piiiiiii N::::::::::N    N::::::NXXX:::::X   X:::::XXX
*S:::::S              P::::P     P:::::Pi:::::i N:::::::::::N   N::::::N   X:::::X X:::::X   
* S::::SSSS           P::::PPPPPP:::::P  i::::i N:::::::N::::N  N::::::N    X:::::X:::::X    
*  SS::::::SSSSS      P:::::::::::::PP   i::::i N::::::N N::::N N::::::N     X:::::::::X     
*    SSS::::::::SS    P::::PPPPPPPPP     i::::i N::::::N  N::::N:::::::N     X:::::::::X     
*       SSSSSS::::S   P::::P             i::::i N::::::N   N:::::::::::N    X:::::X:::::X    
*            S:::::S  P::::P             i::::i N::::::N    N::::::::::N   X:::::X X:::::X   
*            S:::::S  P::::P             i::::i N::::::N     N:::::::::NXXX:::::X   X:::::XXX
*SSSSSSS     S:::::SPP::::::PP          i::::::iN::::::N      N::::::::NX::::::X     X::::::X
*S::::::SSSSSS:::::SP::::::::P          i::::::iN::::::N       N:::::::NX:::::X       X:::::X
*S:::::::::::::::SS P::::::::P          i::::::iN::::::N        N::::::NX:::::X       X:::::X
* SSSSSSSSSSSSSSS   PPPPPPPPPP          iiiiiiiiNNNNNNNN         NNNNNNNXXXXXXX       XXXXXXX
*
*──────────────────────────────▄▄
*──────────────────────▄▄▄▄▄▄▄▄▌▐▄
*─────────────────────█▄▄▄▄▄▄▄▄▌▐▄█
*────────────────────█▄▄▄▄▄▄▄█▌▌▐█▄█
*──────▄█▀▄─────────█▄▄▄▄▄▄▄▌░▀░░▀░▌
*────▄██▀▀▀▀▄──────▐▄▄▄▄▄▄▄▐ ▌█▐░▌█▐▌
*──▄███▀▀▀▀▀▀▀▄────▐▄▄▄▄▄▄▄▌░░░▄▄▌░▐
*▄████▀▀▀▀▀▀▀▀▀▀▄──▐▄▄▄▄▄▄▄▌░░▄▄▄▄░▐
*████▀▀▀▀▀▀▀▀▀▀▀▀▀▄▐▄▄▄▄▄▄▌░▄░░▀▀░░▌
*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▌░▐▀▄▄▄▄▀
*▒▒▒▒▄▄▀▀▀▀▀▀▀▀▄▄▄▄▀▀█▄▄▄▄▄▌░░░░░▌
*▒▄▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌
*▒▌░░░░░▀▄░░░░░░░░░░░░░░░▀▄▄▄▄▄▄░▀▄▄▄▄▄
*▒▌░░░░░░░▀▄░░░░░░░░░░░░░░░░░░░░▀▀▀▀▄░▀▀▀▄
*▒▌░░░░░░░▄▀▀▄░░░░░░░░░░░░░░░▀▄░▄░▄░▄▌░▄░▄▌
*▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
*
* __..__  .  .\  /
*(__ [__)*|\ | >< 
*.__)|   || \|/  \
*
*    Graffiti Fondler. Spray decal limiter with noxious emmission.
*    Copyleft (C) 2019 .sρiηX҉.
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

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
///#define COWARDLY
new Float:BlockTime[33];
new pcvar_spray_tolerance;
new Float:g_Time;

public plugin_init(){
	register_plugin("Graffiti Fondler", "1.0", "SPiNX")
	pcvar_spray_tolerance = register_cvar("spray_tolerance", "30.0")
	register_impulse(201, "SprayAppraiser");}

public SprayAppraiser(id){
	new Float:gametime = get_gametime()
	g_Time = get_pcvar_float(pcvar_spray_tolerance)
	if(BlockTime[id] <= gametime)
	{
	BlockTime[id] = gametime + g_Time;
	client_print(id, print_chat, "Spray blocked for %i seconds.",floatround(g_Time));
	aerosol(id);return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;}
public client_disconnected(id){BlockTime[id] = 0.0;}
public aerosol(id){
	#if defined COWARDLY
	if( (is_user_alive(id)) && (is_user_admin(id)))return;
	#endif
	fakedamage(id,"Decal aerosol vapors",1.0, DMG_POISON)
	new Float:Spray[3]
	pev(id,pev_origin,Spray);
	message_begin(MSG_PVS,SVC_TEMPENTITY);write_byte(TE_FIREFIELD);
	engfunc(EngFunc_WriteCoord,Spray[0]);engfunc(EngFunc_WriteCoord,Spray[1]);engfunc(EngFunc_WriteCoord,Spray[2] + 80);
	write_short(1);write_short(id);write_byte(1);write_byte(28);
	write_byte(floatround(g_Time)*100);message_end();}
