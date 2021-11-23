///////////////////////////////////////////////////////////////////////////////////////
//
//	AMX Mod (X)
//
//	Developed by:
//	The Amxmodx DoD Community
//	|BW|.Zor Editor (zor@blackwatch.recongamer.com)
//	http://www.dodcommunity.net
//
//	This program is free software; you can redistribute it and/or modify it
//	under the terms of the GNU General Public License as published by the
//	Free Software Foundation; either version 2 of the License, or (at
//	your option) any later version.
//
//	This program is distributed in the hope that it will be useful, but
//	WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//	General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software Foundation,
//	Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
//
//	In addition, as a special exception, the author gives permission to
//	link the code of this program with the Half-Life Game Engine ("HL
//	Engine") and Modified Game Libraries ("MODs") developed by Valve,
//	L.L.C ("Valve"). You must obey the GNU General Public License in all
//	respects for all of the code used other than the HL Engine and MODs
//	from Valve. If you modify this file, you may extend this exception
//	to your version of the file, but you are not obligated to do so. If
//	you do not wish to do so, delete this exception statement from your
//	version.
//
//	Name:
//	Author:		|BW|.Zor
//	Description:	These are things that are in adminmod that I thought should be
//			be in amx so we can convert to amxx
//	Reference:	http://www.amxmodx.org/forums/viewtopic.php?t=5857
//
//	CVARS To edit in the adminmodx.cfg
//	adminmodx_sounds		<0|1> 			- Off or On for the sounds
//	adminmodx_llama_chat_warnings	3			- Amount of times to warn a chatting llama not to talk too much
//	adminmodx_llama_chat_delay	10.0			- Amount of time in FLOAT between chats for a llama
//	adminmodx_burydepth		10			- The depth to bury people
//	adminmodx_team_1		Allies			- The team name for team 1 DoD=Allies, CS=Counter Terrorists, etc
//	adminmodx_team_2		Axis			- The team name for team 2 DoD=Axis, CS=Terrorists, etc
//	slappower			0			- The default power of slaps
//	adminmodx_items_team_1		""			- The default weapons to give somone upon respawning them
//	adminmodx_items_team_2		""			- The default weapons to give somone upon respawning them
//	adminmodx_show_activity		2			- The default message level
//								0: print to callers console only
//								1: print to global chat
//								2: standard hud message as was for all previous versions

//
//	v0.1	- Be!
//	v0.3	- Borrowed some code from Nick, thanks for your AIOS
//	v0.4	- Ok did some minor repairs
//	v0.5	- Repaired how the why works
//		- Repaired hostname
//		- Reworked the exec method to work better
//		- Changed listmaps to MOTD window
//		- Made the plugin more generic and not DoD orientated
//	v0.6	- Added noclip and god mode
//	v0.6a	- Replaced trim with a replace
//	v0.6b	- Fixed the problem with the exec commands
//	v0.7	- Did some repairs that I notices with the why, and added 3 new functions
//	v0.7a	- Minor Fixes.  Repaired some small errors found in logs.
//		- Fixed the server commands to call the functions not the amx calls
//		- Fixed the check against admins
//	v0.7b	- Fixed the way I do the actual work.  All thanks to speedy!  The llama gag and shutup
//		were being done but not undone.  So fixed it!
//	v0.7c	- Fixed the non checking error in the exec stuff, thanks to Lasershock
//	v0.7d	- Fixed the Llama bug because of death as well as a few mods also removed the why as its a
//		pain and most users are too dumb to look at the console nor even the chat.
//	v0.7e	- Reworked the team commands so that they use numbers instead of team names as this
//		is always different for each mod
//	v0.8	- Did a major overhaul on the whole plugin to fix up errors and so some patching
//		- Most of the commands have been modified and help stuff is more detailed...as well
//		its a new file not the old one although alot of functions were ported over the
//		client / team / all commands have been modified to a new function for all 3
//		commands, such as amx_exec / amx_execteam / amx_execall call upon adminexec
//	v0.8a	- Added alltalk done a complete overhaul on the code and made sure it ALL works!
//	v0.8b	- Fixed pileoshit.wav thx to MrGardenHoseMan
//	v0.8c	- Fixed problem with wrong sound being played for alltalk
//		- Added a cvar to turn the sounds off
//		- Removed some debug code that I missed
//		- Added the use of fakemeta commands for team selection all thanks to the following:
//			depot - For finding the help
//			White Panther (karlos) - For giving depot the code needed
//	v0.8d	- Added the require_module("FAKEMETA")
//		- Worked on some errors that I noticed in the log files
//		- Fixed an error in the amx_shutup in that it turns voice stuff off on the person who calls it
//		- Removed yet another piece of debug code in Llama check
//		- Added 2 new cvars that will help with the Llama chatting
//		- Fixed the gag error
//	v0.9	- Fixed up the llama timeing so that it uses user_time instead of game time, this allows us to use int's
//		instead of floats, easier, we are not trying to be that precice
//		- Added some features:
//			amx_heal
//			amx_revive
//			amx_bury / amx_buryteam / amx_buryall
//	v0.9a	- Added amx_unbury / amx_unburyteam / amx_unburyall
//		- Small error with bashing...didn't check to see how many slaps to give...fixed it to give only up to 100
//		- Fixed error with the nameAgainst and steamAgainst, this was why it was saying caller was calling it against
//		himself
//		- Added way to block the stuck / unstuck that some mods use, such as NS, all thanks to White Panther and depot
//		- Did some checking on the beat and the bury
//	v0.9b	- Added a config file for the cvars
//		- Added amx_clanpractice, amx_scrim
//	v0.9c	- The set task in slaparound has been set to a player id + 1000 so that I can track and kill off the task
//		if they die
//		- In slaptarget recuring function I changed user_slap(param[0], 1, 1) to use get_cvar_num("slappower")
//		instead of 1 dmg point
//		- In setslappower I changed the level that you can change the values, from 1 - 9 power to 0 - 10 power
//		- Put in a test to see if a task exists upon death so that it will kill off the beat around on death
//	v0.9d	- Did a rework on the Stuck as it wasn't working on NS, thx to depot
//		- Added adminmodx_burydepth 50 This can be changed in the custom.cfg
//		- Moved the checks for /stuck to the single function say_type_blocks NOW WORKS
//		- Redid the function bury so that it is a single function.
//			Thanks to Panther, your coding is sloppy though ;-)
//	v0.9e	- Fixed problem with team calls not affecting bots
//	V0.9f	- Fixed immunity in bury
//		- Inserted SLAY data in Dictionary file
//		- Fixed No-Clip sayying problem
//		- Fixed God Mode sayying problem
//		- Fixed Slap Power not having a CVAR
//		- These were all detected by depot, thanks again!
//	v0.9g	- Added Public War
//		- Added a timeleft for when a scrim is ongoing
//		- Commented out revive as it isnt specific to all mods, when able to get it to work will reinstall it
//			Thanks for this one goes out to XxKpAznGuyxX for finding one that works, but in CS
//		- Changed some task numbers around
//		- Added a capture screen feature to the scrim
//		- Fixed the problem with the set slap power
//			Thanks for this one goes out to someone...cant remember who!
//	v0.9h	- Added console commands as well as client commands for the overides
//			Thanks for this one goes out to XxKpAznGuyxX
//		- Added a password command
//	v0.9i	- Redid the Voice Com code to use a better way
//		- Worked on the gag and llama
//		- Rearanged the Gag and Llama say checks so that if user is gaged and llama ( Shouldnt realy be but wtf )
//		it would check the gag first and if they are gaged who cares if they are llamad, just skip it
//		- Changed the times for name checks, in some mods you cant change your name when your dead, so I
//		increased the check times so that ppl cant fiddle around with their names
//		- Set the Llama asses to hear their own gurgles in VERY HIGH AND INTENSENESS, and not the rest of the
//		server!
//		- Fixed a string formation incorrect for some of the loggin features
//	v0.9j	- Did some work on Llama name changes
//		- Fixed up team actions
//		- Consolodated the Say functions
//	v0.9h	- Removed the Clan Practice / Public War / Scrim
//		- Added cvar adminmodx_show_activity for messages to the screen
//			0: print to callers console only
//			1: print to global chat
//			2: standard hud message as was for all previous versions
//		- Removed all server_print
//		- Fixed an error in Llama
//
///////////////////////////////////////////////////////////////////////////////////////

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>
#include <lang>

//////////////////////////////////////////////
// Version Control
//
new AUTH[] = "AMXX DoD Community"
new PLUGIN_NAME[] = "AdminModX"
new VERSION[] = "0.9h"
//
//////////////////////////////////////////////

//////////////////////////////////////////////
// Globals

// Define Levels for Access
#define EXEC ADMIN_LEVEL_D
#define SLAY ADMIN_LEVEL_H
#define IMMUNE ADMIN_LEVEL_H

new g_buried[33]		// Bit switch to ident who is burried
new g_gaged[33]			// Bit switch to ident who is gaged
new g_lamaed[33]		// Bit switch to ident who is llamaed
new g_oldName[33][32]		// Keeps track of a llamed old name for when they are unllamaed
new g_llamasaying[3][] =	// Holds the values of what the llama says
{
	"Ooorgglee!!",
	"Bleeeeat!!",
	"Brawwrr!!!"
}
new g_llamaLastSay[33]		// This will grab the last time llama tried to talk
new g_llamaLastSayWarning[33]	// This will track the last time llama said stuff
//
// End Globals
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// Files that will be used
//
#define FILES 2
new fileName[FILES][64] =
{
	"custom.cfg",
	"maps.ini"		// Maps
}

enum
{
	config = 0,
	maps
}
//
// End of Files that will be used
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// Sounds used
//
#define SOUNDFILES 11
new soundName[SOUNDFILES][] =
{
	"misc/ooorgle.wav",		// The sound a Lama makes while having sex!
	"misc/bleeeat.wav",
	"misc/brawwrr.wav",
	"ambience/thunder_clap.wav",	// For slays and when something is done to someone
	"misc/slap.wav",		// Slap Sound
	"misc/bitchslap.wav",		// The bitch slap you to bancock
	"misc/who.wav",			// Sound to open Alltalk
	"misc/stfu.wav",		// Sound to close Alltalk
	"misc/pray.wav",		// Sound for god mode
	"misc/pileoshit.wav",		// Sound for noclip
	"misc/choke.wav"		// Choking sound
}

enum
{
	oorgle = 0,
	bleet,
	braww,
	thunder,
	slap,
	biatch,
	alltalk_off,
	alltalk_on,
	pray,
	pileoshit,
	choke
}

// End Sounds used
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// This is where the plugin is initialized
//
public plugin_init()
{
	// Register this plugin
	register_plugin(PLUGIN_NAME, VERSION, AUTH)

	// Register the dictionary file
	register_dictionary("adminmodx.txt")

	// Register Console Commands
	// The following are for execution of client commands
	register_concmd("amx_exec", "adminexec", EXEC, "<nick | steam> <command> - This will execute a command on the clients machine")
	register_concmd("amx_execteam", "adminexec", EXEC, "<team number | name> <command> - This will execute a command on all the clients machine of team")
	register_concmd("amx_execall", "adminexec", EXEC, "<command> - This will execute a command on all the clients machine")

	// The following are to slap bad ppl around
	register_concmd("amx_slap", "adminslap", SLAY, "<nick | steam> - Slaps one client")
	register_concmd("amx_slapteam", "adminslap", SLAY, "<team number | name> - Slaps everyone on a team")
	register_concmd("amx_slapall", "adminslap", SLAY, "Slaps everyone on map")

	// Slaps the player around so many times at the slap damage going on
	register_concmd("amx_beat", "slaparound", SLAY, "<nick | steam> <number of slaps> - Slaps person that many times!")
	register_concmd("amx_beatteam", "slaparound", SLAY, "<team number | name> <number of slaps> - Slaps team that many times!")
	register_concmd("amx_beatall", "slaparound", SLAY, "<number of slaps> - Slaps everyone that many times!")

	// Slays the players that you want
	register_concmd("amx_slay", "slay", SLAY, "<nick | steam> - Slays an individual")
	register_concmd("amx_slayteam", "slay", SLAY, "<team number | name> - Slays the whole team")
	register_concmd("amx_slayall", "slay", SLAY, "Slays everyone on the server including admins and caller")

	// This will set god mode on ppl
	register_concmd("amx_god", "godmode", SLAY, "<nick | steam> - Sets a player to god mode")
	register_concmd("amx_godteam", "godmode", SLAY, "<team number | name> - Sets player on team to god mode")
	register_concmd("amx_godall", "godmode", SLAY, "- Sets all players to god mode")

	// Sets no clip on ppl
	register_concmd("amx_noclip", "noclip", SLAY, "<nick | steam> - Sets a player to no clip mode")
	register_concmd("amx_noclipteam", "noclip", SLAY, "<team number | name> - Sets team to no clip mode")
	register_concmd("amx_noclipall", "noclip", SLAY, "- Sets all players to no clip mode")

	// Some punishments for people like Llama
	register_concmd("amx_llama", "lama", SLAY, "<nick | steam> - We can make a lama out of a player using this command")
	register_concmd("amx_unllama", "lama", SLAY, "<nick | steam> - We can unlama a player using this command")

	// Gag
	register_concmd("amx_gag", "gag", SLAY, "<nick | steam> - We can gag a player using this command")
	register_concmd("amx_ungag", "gag", SLAY, "<nick | steam> - We can ungag a player using this command")

	// Shut up
	register_concmd("amx_shutup", "shutup", SLAY, "<nick | steam> - Will shut up loudmouth ppl")
	register_concmd("amx_unshutup", "shutup", SLAY, "<nick | steam> - Will un-shut up loudmouth ppl")

	// Pig
	register_concmd("amx_pig", "pig", SLAY, "<nick | steam> - Screw up bad people")
	register_concmd("amx_unpig", "pig", SLAY, "<nick | steam> - Un screw bad people")

	// Quit to desktop
	register_concmd("amx_quit", "quit", SLAY, "<nick | steam> - Will quit assholes to the desktop")

	// Server commands
	register_concmd("amx_alltalk", "alltalk", EXEC, "(1|0) - Turns alltalk on or off, if no arg passed tells if on or off")
	register_concmd("amx_hostname", "hostname", EXEC, "<hostname> - This will let an admin change the name of the server")
	register_concmd("amx_status", "status", EXEC, "- This will show you a list of info on each person kinda like the status but more detailed")
	register_concmd("amx_timelimit", "timelimit", EXEC, "<time> - Resets the time limit, it must be more than we have been playing for")
	register_concmd("amx_listmaps", "listmaps", EXEC, "This will list all the maps in the map ini")
	register_concmd("amx_password", "password_func", EXEC, "(password) - Will set the password on the server, to remove call with no arguments.")
	register_concmd("amx_slapdmg", "setslappower", EXEC, "<value> - Sets slap damage")

	// New when Im done one I will put it in repos and move over
	register_concmd("amx_heal", "heal", EXEC, "<nick | steam> (amount) - Heals a player to the amount or fully")
	
	// Still not working, but Im closer
	//register_concmd("amx_revive", "revive", EXEC, "<nick | steam> - Revives a player if he is dead")

	// The following are to bury bad ppl
	register_concmd("amx_bury", "bury", SLAY, "<nick | steam> - Burys one client")
	register_concmd("amx_buryteam", "bury", SLAY, "<team number | name> - Burys everyone on a team")
	register_concmd("amx_buryall", "bury", SLAY, "Burys everyone on server")

	// The following are to un-bury ppl
	register_concmd("amx_unbury", "bury", SLAY, "<nick | steam> - Un-Burys one client")
	register_concmd("amx_unburyteam", "bury", SLAY, "<team number | name> -Un- Burys everyone on a team")
	register_concmd("amx_unburyall", "bury", SLAY, "Un-Burys everyone on server")

	// These ones are specifically for the buried
	register_event("DeathMsg", "eDeath", "a")

	/////////////////////////////////////////////////////////////////////////////
	// Client Command Overides
	//
	// Redundant, but unsure of it at the moment

	//register_clcmd("say", "say_type_blocks")
	//register_clcmd("say_team", "say_type_blocks")
	
	register_concmd("say", "say_type_blocks")
	register_concmd("say_team", "say_type_blocks")
	
	// Register CVARS for control
	register_cvar("adminmodx_sounds", "1")
	register_cvar("adminmodx_show_activity", "2")
	register_cvar("adminmodx_llama_chat_warnings", "3")
	register_cvar("adminmodx_llama_chat_delay", "10")
	register_cvar("adminmodx_burydepth", "50")
	register_cvar("adminmodx_team_1", "Allies")
	register_cvar("adminmodx_team_2", "Axis")
	register_cvar("adminmodx_items_team_1", "")
	register_cvar("adminmodx_items_team_2", "")
	register_cvar("adminmodx_obey_immunities", "1")
	register_cvar("slappower", "1")
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Configs the plugin
//
public plugin_cfg()
{
	// Get the placement of the joinleave file
	new folderName[32]

	get_configsdir(folderName, 32)

	for(new i = 0; i < FILES; i++)
	{
		format(fileName[i], 64, "%s/%s", folderName, fileName[i])
	}

	server_cmd("exec %s", fileName[config])
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Required modules for this plugin
//
public plugin_modules()
{
	require_module("FUN")
	require_module("FAKEMETA")
	require_module("ENGINE")

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Precaches sounds and models
//
public plugin_precache()
{
	if(get_cvar_num("adminmodx_sounds"))
	{
		for(new x = 0; x < SOUNDFILES; x++)
			precache_sound(soundName[x])
	}

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
// When a player is auth and the Steam ID is set
//
public client_authorized(id)
{
	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
// When a player is put into the server
//
public client_putinserver(id)
{
	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Command Overides
//
public client_infochanged(id)
{
    	new cmd[32]
	read_argv(1, cmd, 32)
	new nick[32], steam[32]
	read_argv(2, nick, 32)

	if(equali(cmd, "name") && g_lamaed[id] == 1)
	{
		if(equali(nick, "Llama"))
			return PLUGIN_CONTINUE

		new param[1]
		param[0] = id

		set_task(1.0, "checkName", id, param, 1)

		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_LLAMA_SET")
		log_amx("%L", LANG_SERVER, "ADMINMODX_LLAMA_TRIED", nick, steam)

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
// When a player disconnects from the server
//
public client_disconnect(id)
{
	g_gaged[id] = 0
	g_buried[id] = 0

	if(g_lamaed[id] == 1)
	{
		g_lamaed[id] = 0
		set_user_info(id, "name", g_oldName[id])
		client_cmd(id, "name %s", g_oldName[id])
		g_oldName[id] = ""
		g_llamaLastSay[id] = 0
		g_llamaLastSayWarning[id] = 0
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Execute
//
public adminexec(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], toexec[128], counter, players[32], totalPlayers
	read_argv(0, cmd, 32)
	read_args(toexec, 128)

	replace(toexec, 128, cmd, "")
	replace(cmd, 32, "amx_exec", "")

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	
	if(equal(cmd, "all"))
	{
		client_cmd(0, toexec)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Exec All", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Exec All")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_EXECALL_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_EXECALL", nameCalled, steamCalled, toexec)

	}

	else if(equal(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		replace(toexec, 128, steam_nick_team, "")

		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if(is_client(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

			return PLUGIN_CONTINUE
		}

		client_cmd(player_id, toexec)

		// Get the info on the caller
		new nameAgainst[32], steamAgainst[32]
		get_user_name(player_id, nameAgainst, 31)
		get_user_authid(player_id, steamAgainst, 31)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Exec against: ", nameAgainst)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Exec against:", nameAgainst)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_EXEC_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_EXEC", nameCalled, steamCalled, toexec, nameAgainst, steamAgainst)
	}

	else if(equal(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		replace(toexec, 128, steam_nick_team, "")

		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)
		
		for(counter = 0; counter < totalPlayers; counter++)
		{
			client_cmd(players[counter], toexec)
		}

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Exec Against Team: ", teamname)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Exec Against Team: ", teamname)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_EXECTEAM_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_EXETEAM", nameCalled, steamCalled, toexec, teamname)
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Slaps people
//
public adminslap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], counter, players[32], totalPlayers
	read_argv(0, cmd, 32)
	replace(cmd, 32, "amx_slap", "")

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)

	new Red = random(256)
	new Green = random(256)
	new Blue = random(256)
	set_hudmessage(Red, Green, Blue, 0.05, 0.4)

	if(equal(cmd, "all"))
	{
		get_players(players, totalPlayers, "a")

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(is_user_alive(players[counter]) == 1 && !(get_user_flags(players[counter])&IMMUNE))
			{
				user_slap(players[counter], get_cvar_num("slappower"), 1)
			}
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_ALLSLAPPED")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_ALLSLAPPED")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_ALLSLAPPED")
		}
		
		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[slap], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Slap All", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Slap All")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SLAPALL_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_SLAPALL", nameCalled, steamCalled)

	}

	else if(equal(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 2))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)

		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if(is_client(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

			return PLUGIN_CONTINUE
		}

		if(is_user_alive(player_id) == 1 && !(get_user_flags(player_id)&IMMUNE))
		{
			user_slap(player_id, get_cvar_num("slappower"), 1)
		}

		// Get the info on the caller
		new nameAgainst[32], steamAgainst[32]
		get_user_name(player_id, nameAgainst, 31)
		get_user_authid(player_id, steamAgainst, 31)

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_SLAPPED", nameAgainst)
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_SLAPPED", nameAgainst)
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_SLAPPED", nameAgainst)
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[slap], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Slap against: ", nameAgainst)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Slap against:", nameAgainst)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SLAP_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_SLAP", nameCalled, steamCalled, nameAgainst, steamAgainst)
	}

	else if(equal(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 2))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)

		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(is_user_alive(players[counter]) == 1 && !(get_user_flags(players[counter])&IMMUNE))
			{
				user_slap(players[counter], get_cvar_num("slappower"), 1)
			}
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_TEAMSLAPPED", teamname)
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_TEAMSLAPPED", teamname)
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_TEAMSLAPPED", teamname)
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[slap], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Slap Against Team: ", teamname)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Slap Against Team: ", teamname)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SLAPTEAM_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_SLAPTEAM", nameCalled, steamCalled, teamname)
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Slaps around people
//
public slaparound(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], counter, players[32], totalPlayers, param[1], numberofslaps[8], number_of_slaps
	read_argv(0, cmd, 32)
	replace(cmd, 32, "amx_beat", "")

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)

	new Red = random(256)
	new Green = random(256)
	new Blue = random(256)
	set_hudmessage(Red, Green, Blue, 0.05, 0.4)

	if(equal(cmd, "all"))
	{
		read_argv(1, numberofslaps, 7)
		get_players(players, totalPlayers, "a")
		number_of_slaps = str_to_num(numberofslaps)
		if(number_of_slaps > 100)
			number_of_slaps = 100

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(!(get_user_flags(players[counter])&IMMUNE))
			{
				param[0] = players[counter]
				set_task(0.1, "slaptarget", (players[counter]+1000), param, 1, "a", number_of_slaps)
			}
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_ALLBEAT")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_ALLBEAT")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_ALLBEAT")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[biatch], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Beat Everyone Around", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Beat Everyone Around")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_BEATALL_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_BEATALL", nameCalled, steamCalled)

	}

	else if(equal(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		read_argv(2, numberofslaps, 7)

		number_of_slaps = str_to_num(numberofslaps)
		if(number_of_slaps > 100)
			number_of_slaps = 100

		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if(is_client(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

			return PLUGIN_CONTINUE
		}

		if(!(get_user_flags(player_id)&IMMUNE))
		{
			param[0] = player_id
			set_task(0.1, "slaptarget", (player_id+1000), param, 1, "a", number_of_slaps)
		}

		// Get the info on the caller
		new nameAgainst[32], steamAgainst[32]
		get_user_name(player_id, nameAgainst, 31)
		get_user_authid(player_id, steamAgainst, 31)
		
		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_BEATED", nameAgainst)
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_BEATED", nameAgainst)
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_BEATED", nameAgainst)
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[biatch], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Beat against: ", nameAgainst)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Beat against:", nameAgainst)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_BEAT_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_BEAT", nameCalled, steamCalled, nameAgainst, steamAgainst)
	}

	else if(equal(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		read_argv(2, numberofslaps, 7)

		number_of_slaps = str_to_num(numberofslaps)
		if(number_of_slaps > 100)
			number_of_slaps = 100

		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(!(get_user_flags(players[counter])&IMMUNE))
			{
				param[0] = players[counter]
				set_task(0.1, "slaptarget", (players[counter]+1000), param, 1, "a", number_of_slaps)
			}
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_TEAMBEAT", teamname)
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_TEAMBEAT", teamname)
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_TEAMBEAT", teamname)
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[biatch], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Beat Against Team: ", teamname)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Beat Against Team: ", teamname)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_BEATTEAM_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_BEATTEAM", nameCalled, steamCalled, teamname)
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Slays people
//
public slay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], counter, players[32], totalPlayers
	read_argv(0, cmd, 32)
	replace(cmd, 32, "amx_slay", "")

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)

	new Red = random(256)
	new Green = random(256)
	new Blue = random(256)
	set_hudmessage(Red, Green, Blue, 0.05, 0.4)

	if(equal(cmd, "all"))
	{
		get_players(players, totalPlayers, "a")

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(is_user_alive(players[counter]) == 1 && !(get_user_flags(players[counter])&IMMUNE))
			{
				user_kill(players[counter], 1)
			}
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_ALLSLAYED")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_ALLSLAYED")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_ALLSLAYED")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Slay All", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Slay All")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SLAYALL_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_SLAYALL", nameCalled, steamCalled)

	}

	else if(equal(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 2))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)

		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if(is_client(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")
				
			return PLUGIN_CONTINUE
		}

		if(is_user_alive(player_id) == 1 && !(get_user_flags(player_id)&IMMUNE))
		{
			user_kill(player_id, 1)
		}

		// Get the info on the caller
		new nameAgainst[32], steamAgainst[32]
		get_user_name(player_id, nameAgainst, 31)
		get_user_authid(player_id, steamAgainst, 31)

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_SLAYED", nameAgainst)
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_SLAYED", nameAgainst)
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_SLAYED", nameAgainst)
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Slay against: ", nameAgainst)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Slay against:", nameAgainst)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SLAY_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_SLAY", nameCalled, steamCalled, nameAgainst, steamAgainst)
	}

	else if(equal(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 2))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)

		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(is_user_alive(players[counter]) == 1 && !(get_user_flags(players[counter])&IMMUNE))
			{
				user_kill(players[counter], 1)
			}
		}
		
		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_TEAMSLAYED", teamname)
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_TEAMSLAYED", teamname)
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_TEAMSLAYED", teamname)
		}
		
		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Slay Against Team: ", teamname)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Slay Against Team: ", teamname)
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SLAYTEAM_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_SLAYTEAM", nameCalled, steamCalled, teamname)
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Sets godmode on people
//
public godmode(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], counter, players[32], totalPlayers
	read_argv(0, cmd, 32)
	replace(cmd, 32, "amx_god", "")

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)

	new Red = random(256)
	new Green = random(256)
	new Blue = random(256)
	set_hudmessage(Red, Green, Blue, 0.05, 0.4)

	if(equal(cmd, "all"))
	{
		get_players(players, totalPlayers, "a")

		for(counter = 0; counter < totalPlayers; counter++)
		{
			set_user_godmode(players[counter], 1 - get_user_godmode(players[counter]))
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_ALLGODED", "On/Off")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_ALLGODED", "On/Off")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_ALLGODED", "On/Off")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[pray], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Everyone a GOD", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Everyone a GOD")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_GODALL_SUC")
			
		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_GODALL", nameCalled, steamCalled)

	}

	else if(equal(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		
		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if(is_client(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

			return PLUGIN_CONTINUE
		}

		set_user_godmode(player_id, 1 - get_user_godmode(player_id))

		// Get the info on the caller
		new nameAgainst[32], steamAgainst[32]
		get_user_name(player_id, nameAgainst, 31)
		get_user_authid(player_id, steamAgainst, 31)

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_GODED", nameAgainst, "On/Off")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_GODED", nameAgainst, "On/Off")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_GODED", nameAgainst, "On/Off")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[pray], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, nameAgainst, "a GOD!")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", nameAgainst, "a GOD!")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_GOD_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_GODMODE", nameCalled, steamCalled, nameAgainst, steamAgainst)
	}

	else if(equal(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		
		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)

		for(counter = 0; counter < totalPlayers; counter++)
		{
			set_user_godmode(players[counter], 1 - get_user_godmode(players[counter]))
		}
		
		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_TEAMGODED", teamname, "On/Off")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_TEAMGODED", teamname, "On/Off")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_TEAMGODED", teamname, "On/Off")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[pray], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, teamname, "GODS!")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", teamname, "GODS!")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_GODTEAM_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_GODTEAM", nameCalled, steamCalled, teamname)
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Sets noclip on people
//
public noclip(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], counter, players[32], totalPlayers
	read_argv(0, cmd, 32)
	replace(cmd, 32, "amx_noclip", "")

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)

	new Red = random(256)
	new Green = random(256)
	new Blue = random(256)
	set_hudmessage(Red, Green, Blue, 0.05, 0.4)

	if(equal(cmd, "all"))
	{
		get_players(players, totalPlayers, "a")

		for(counter = 0; counter < totalPlayers; counter++)
		{
			set_user_noclip(players[counter], 1 - get_user_noclip(players[counter]))
		}
		
		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_ALLNOCLIPED", "On/Off")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_ALLNOCLIPED", "On/Off")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_ALLNOCLIPED", "On/Off")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Everyone No-Clipped", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Everyone No-Clipped")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_NOCLIPALL_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_NOCLIPALL", nameCalled, steamCalled)

	}

	else if(equal(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		
		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if(is_client(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

			return PLUGIN_CONTINUE
		}

		set_user_noclip(player_id, 1 - get_user_noclip(player_id))

		// Get the info on the caller
		new nameAgainst[32], steamAgainst[32]
		get_user_name(player_id, nameAgainst, 31)
		get_user_authid(player_id, steamAgainst, 31)

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_NOCLIPED", nameAgainst, "On/Off")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_NOCLIPED", nameAgainst, "On/Off")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_NOCLIPED", nameAgainst, "On/Off")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, nameAgainst, "them No-Clipped!")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", nameAgainst, "them No-Clipped!")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_NOCLIP_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_NOCLIP", nameCalled, steamCalled, nameAgainst, steamAgainst)
	}

	else if(equal(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 3))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)
		
		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)

		for(counter = 0; counter < totalPlayers; counter++)
		{
			set_user_noclip(players[counter], 1 - get_user_noclip(players[counter]))
		}

		switch(get_cvar_num("adminmodx_show_activity"))
		{
			case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_TEAMNOCLIPED", teamname, "On/Off")
			case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_TEAMNOCLIPED", teamname, "On/Off")
			case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_TEAMNOCLIPED", teamname, "On/Off")
		}

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		// Show it if needed
		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, teamname, "is No-Clipped!")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", teamname, "is No-Clipped!")
		}

		// Tell them it succeded
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_NOCLIPTEAM_SUC")

		// Now Log it
		log_amx("%L", LANG_SERVER, "ADMINMODX_NOCLIPTEAM", nameCalled, steamCalled, teamname)
	}

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Llama
//
public lama(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], playerName[32]
	read_argv(0, cmd, 31)
	read_argv(1, playerName, 31)

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

		return PLUGIN_CONTINUE
	}

	if(get_user_flags(player_id) & IMMUNE)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PLAYER_IMMUNE")
		return PLUGIN_HANDLED
	}

	new param[2]

	if(equal(cmd, "amx_llama"))
	{
		param[0] = player_id
		param[1] = 1

		doLama(param)
	}

	else if(equal(cmd, "amx_unllama"))
	{
		param[0] = player_id
		param[1] = 0

		doLama(param)
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Llama/UnLlama", "")
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Llama/UnLlama")
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_LLAMA_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_LLAMA", nameCalled, steamCalled, ((equal(cmd, "amx_llama")) ? "" : "Un-"), nameAgainst, steamAgainst)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Turns Llama on or off
//
public doLama(param[])
{
	new player_id = param[0]
	new onOff = param[1]

	if(is_user_alive(player_id))
	{
		// UnLLama
		if(onOff == 0)
		{
			set_user_info(player_id, "name", g_oldName[player_id])
			client_cmd(player_id, "name %s", g_oldName[player_id])
			g_oldName[player_id] = ""
			g_lamaed[player_id] = 0
			g_llamaLastSay[player_id] = 0
			g_llamaLastSayWarning[player_id] = 0

			client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_LLAMAOFF", g_oldName[player_id])
		}

		// LLama the guy
		else if(onOff == 1)
		{
			get_user_name(player_id, g_oldName[player_id], 31)

			if(get_cvar_num("adminmodx_sounds"))
				emit_sound(0, CHAN_VOICE, soundName[pileoshit], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

			client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_LLAMAON", g_oldName[player_id])
			set_user_info(player_id, "name", "Llama")
			client_cmd(player_id, "name %s", "Llama")
			g_lamaed[player_id] = 1
			g_llamaLastSay[player_id] = get_user_time(player_id) - 20
		}
	}

	else
	{
		set_task(1.0, "doLama", 0, param, 2)
	}
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Gags ppl
//
public gag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], playerName[32]
	read_argv(0, cmd, 31)
	read_argv(1, playerName, 31)

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

		return PLUGIN_CONTINUE
	}

	if(get_user_flags(player_id) & IMMUNE)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PLAYER_IMMUNE")
		return PLUGIN_HANDLED
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	if(equal(cmd, "amx_gag"))
	{
		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[choke], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		client_print(0,print_chat, "%L", LANG_SERVER, "ADMINMODX_GAGON", nameAgainst)
		g_gaged[player_id] = 1
	}

	else if(equal(cmd, "amx_ungag"))
	{
		client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_GAGOFF", nameAgainst)
		g_gaged[player_id] = 0

	}

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Gaged/UnGaged", "")
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Gaged/UnGaged")
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_GAG_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_GAG", nameCalled, steamCalled, ((equal(cmd, "amx_gag")) ? "" : "Un-"), nameAgainst, steamAgainst)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Shuts up ppl
//
public shutup(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], playerName[32]
	read_argv(0, cmd, 31)
	read_argv(1, playerName, 31)

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

		return PLUGIN_CONTINUE
	}

	if(get_user_flags(player_id) & IMMUNE)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PLAYER_IMMUNE")
		return PLUGIN_HANDLED
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	if(equal(cmd, "amx_shutup"))
	{
		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[choke], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		client_print(0,print_chat, "%L", LANG_SERVER, "ADMINMODX_SHUTUPON", nameAgainst)
		set_speak(player_id, SPEAK_MUTED)
	}

	else if(equal(cmd, "amx_unshutup"))
	{
		client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_SHUTUPOFF", nameAgainst)
		set_speak(player_id, SPEAK_NORMAL)
	}

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Shutup/UnShutup", "")
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Shutup/UnShutup")
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SHUTUP_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_SHUTUP", nameCalled, steamCalled, ((equal(cmd, "amx_shutup")) ? "" : "Un-"), nameAgainst, steamAgainst)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Pigs ppl
//
public pig(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], playerName[32]
	read_argv(0, cmd, 31)
	read_argv(1, playerName, 31)

	replace(cmd, 31, "amx_", "")

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

		return PLUGIN_CONTINUE
	}

	if(get_user_flags(player_id) & IMMUNE)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PLAYER_IMMUNE")
		return PLUGIN_HANDLED
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	if(equali(cmd, "pig"))
	{
		client_cmd(player_id, "bind mouse1 kill")
		client_cmd(player_id, "bind mouse2 kill")

		client_print(0, print_center, "%L", LANG_SERVER, "ADMINMODX_PIGON", nameAgainst)

		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	else if(equali(cmd, "unpig"))
	{
		client_cmd(player_id, "bind mouse1 +attack")
		client_cmd(player_id, "bind mouse2 +attack2")

		client_print(0, print_center, "%L", LANG_SERVER, "ADMINMODX_PIGOFF", nameAgainst)
	}

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Pig/UnPig", "")
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Pig/UnPig")
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PIG_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_PIG", nameCalled, steamCalled, ((equali(cmd, "pig")) ? "Pig" : "Un-Pig"), nameAgainst, steamAgainst)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Quits ppl
//
public quit(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new playerName[32]
	read_argv(1, playerName, 31)

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")
			
		return PLUGIN_CONTINUE
	}

	if(get_user_flags(player_id) & IMMUNE)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PLAYER_IMMUNE")
		return PLUGIN_HANDLED
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	client_cmd(player_id, "quit")
	client_print(0, print_center, "%L", LANG_SERVER, "ADMINMODX_QUITTED", nameAgainst)

	if(get_cvar_num("adminmodx_sounds"))
		emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Removed", "")
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Removed")
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_QUIT_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_QUIT", nameCalled, steamCalled, nameAgainst, steamAgainst)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Turns Alltalk on or off
//
public alltalk(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new arg[8], on_off, setvar, nick[32], steamid[32]
	read_argv(1, arg, 7)

	get_user_name(id, nick, 31)
	get_user_authid(id, steamid, 31)

	if(strlen(arg) > 0)
	{
		on_off = str_to_num(arg)
		setvar = 1
	}

	if(setvar)
	{
		if(get_cvar_num("adminmodx_sounds"))
			emit_sound(0, CHAN_VOICE, soundName[((on_off == 0) ? alltalk_on : alltalk_off)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		set_cvar_num("sv_alltalk", on_off)

		new Red = random(256)
		new Green = random(256)
		new Blue = random(256)
		set_hudmessage(Red, Green, Blue, 0.05, 0.4)
		show_hudmessage(0, "%L", LANG_SERVER, "ALLTALK_STATUS", ((get_cvar_num("sv_alltalk") == 0) ? "Disabled" : "Enabled"))

		switch(get_cvar_num("amx_show_activity"))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nick, "Alltalk", "")
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Alltalk")
		}
	}

	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ALLTALK_STATUS", ((get_cvar_num("sv_alltalk") == 0) ? "Disabled" : "Enabled"))
	
	// Do Some Logging
	log_amx("%L", LANG_SERVER, "ALLTALK_LOGGING", nick, steamid, ((setvar) ? ((get_cvar_num("sv_alltalk") == 0) ? "Disabled Alltalk" : "Enabled Alltalk") : "View Alltalk Status"))

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Hostname
//
public hostname(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new cmd[32], name[128], nameCalled[32], steamCalled[32]

	read_argv(0, cmd, 31)
	read_args(name, 127)
	replace(name, 127, cmd, "")
	format(name, 127, "^"%s^"", name)

	server_cmd("hostname %s", name)

	get_user_name(id, nameCalled,31)
	get_user_authid(id,steamCalled,31)

	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_HOSTNAME_SET", name)
	
	log_amx("%L", LANG_SERVER, "ADMINMODX_HOSTNAME", nameCalled, steamCalled)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Status
//	
//
public status(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	new len = 0, message[1024], temp[32]
	
	len += format(message[len], (1023-len), "<table>")
	
	new player_id[32], player_num, player_time = 0, ping = 0, loss = 0
	
	get_players(player_id, player_num, "c")
	
	for(new i = 0; i < player_num; i++)
	{
		// ID
		len += format(message[len], (1023-len), "<tr><td>#</td><td>%d</td></tr>", get_user_userid(player_id[i]))
		len += format(message[len], (1023-len), "<tr><td>Edict</td><td>%d</td>", id)

		// Name
		get_user_name(player_id[i], temp, 31)
		len += format(message[len], (1023-len), "<tr><td>Nick</td><td>%s</td>", temp)

		// Steam ID
		get_user_authid(player_id[i], temp, 31)
		len += format(message[len], (1023-len), "<tr><td>Steam</td><td>%s</td>", temp)

		// Ip
		get_user_ip(player_id[i], temp, 31)
		len += format(message[len], (1023-len), "<tr><td>IP</td><td>%s</td>", temp)

		// Flags
		get_flags(get_user_flags(player_id[i]), temp, 31)
		len += format(message[len], (1023-len), "<tr><td>Flags</td><td>%s</td>", temp)

		// Frags
		len += format(message[len], (1023-len), "<tr><td>Frags</td><td>%d</td>", get_user_frags(player_id[i]))

		// Death
		len += format(message[len], (1023-len), "<tr><td>Deaths</td><td>%d</td>", get_user_deaths(player_id[i]))

		// Health
		len += format(message[len], (1023-len), "<tr><td>Health</td><td>%d</td>", get_user_health(player_id[i]))

		// Ping
		get_user_ping(player_id[i], ping, loss)
		len += format(message[len], (1023-len), "<tr><td>Ping</td><td>%d</td>", ping)
		len += format(message[len], (1023-len), "<tr><td>Loss</td><td>%d</td>", loss)

		// Team
		get_user_team(player_id[i], temp, 31)
		len += format(message[len], (1023-len), "<tr><td>Team</td><td>%s</td>", temp)

		// Time in Seconds Playing
		player_time = get_user_time(player_id[i])
		len += format(message[len], (1023-len), "<tr><td>Time On</td><td>%d:%d:%d</td>", ((player_time / 60) / 12), (player_time / 60), (player_time % 60))
	}
	
	len += format(message[len], (1023-len), "</table>")
	
	show_motd(id, message, "Status")
	
	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Timelimit
//
public timelimit(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new srvTimeLimit = get_cvar_num("mp_timelimit")
	new srvTimeLeft = (get_timeleft() / 60)
	new calledTimeLimit
	new command[8]
	new nameCalled[50]
	new steamCalled[50]

	read_argv(1, command, 7)
	calledTimeLimit = str_to_num(command)

	if(calledTimeLimit > srvTimeLimit)
	{
		set_cvar_num("mp_timelimit", calledTimeLimit)

		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_TIME_SET", calledTimeLimit)
	}

	else if(calledTimeLimit < srvTimeLimit && calledTimeLimit > (srvTimeLimit - srvTimeLeft))
	{
		set_cvar_num("mp_timelimit", calledTimeLimit)

		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_TIME_SET", calledTimeLimit)
	}

	else if(calledTimeLimit < srvTimeLimit && calledTimeLimit < (srvTimeLimit - srvTimeLeft))
	{
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_TIME_NOTSET", calledTimeLimit, srvTimeLimit)
	}

	get_user_name(id, nameCalled, 49)
	get_user_authid(id, steamCalled, 49)
	log_amx("%L", LANG_SERVER, "ADMINMODX_TIME_LIMIT", nameCalled, steamCalled)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Listmaps
//
public listmaps(id)
{
	if(!file_exists(fileName[maps]))
	{
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_NO_MAPFILE")
		
		log_amx("%L", LANG_SERVER, "ADMINMODX_NO_MAPFILE")
		return PLUGIN_HANDLED
	}

	new text[256], mapname[50], about[128]
	new a, pos = 0
	new nameCalled[50]
	new steamCalled[50]

	while(read_file(fileName[maps], pos, text, 255, a) > 0)
	{
		if(text[0] != ';')
		{
			parse(text, mapname, 49, about, 127)
			client_print(id, print_console, "%s    %s^n", mapname, about)
		}

		pos++
	}

	get_user_name(id,nameCalled,49)
	get_user_authid(id,steamCalled,49)
	log_amx("%L", LANG_SERVER, "ADMINMODX_MAP_LIST", nameCalled, steamCalled)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Sets a password on the server
//
public password_func(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new cmd[32], pass[128], nameCalled[32], steamCalled[32]

	read_argv(0, cmd, 31)
	read_args(pass, 127)
	replace(pass, 127, cmd, "")
	format(pass, 127, "^"%s^"", pass)

	set_cvar_string("sv_password", pass)

	get_user_name(id, nameCalled, 31)
	get_user_authid(id,steamCalled, 31)

	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_PASSWORD_SET", pass)

	log_amx("%L", LANG_SERVER, "ADMINMODX_PASSWORD", nameCalled, steamCalled)

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Heals ppl
//
public heal(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new playerName[32], heal_str[32], heal_num
	read_argv(1, playerName, 31)

	if(read_argc() > 1)
	{
		read_argv(2, heal_str, 31)
		heal_num = str_to_num(heal_str)
	}

	else
		heal_num = 100

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")
		
		return PLUGIN_CONTINUE
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	if(heal_num + get_user_health(player_id) >= 100)
		heal_num = 100

	set_user_health(player_id, heal_num)
	client_print(0, print_center, "%L", LANG_SERVER, "ADMINMODX_HEAL", nameAgainst, heal_num)

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Heal on ", nameAgainst)
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Heal on ", nameAgainst)
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_HEAL_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_HEALED", nameCalled, steamCalled, nameAgainst, steamAgainst, heal_num)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Revives ppl
//
public revive(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new playerName[32]
	read_argv(1, playerName, 31)

	remove_quotes(playerName)

	// Search for the Player
	new player_id = get_player(playerName)

	if(player_id == -1)
	{
		// Give out error message
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

		return PLUGIN_CONTINUE
	}

	new nameCalled[32], nameAgainst[32]
	new steamCalled[32], steamAgainst[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)
	get_user_name(player_id, nameAgainst, 31)
	get_user_authid(player_id, steamAgainst, 31)

	if(!is_user_alive(player_id))
	{
		new origin[3], cvar_name[32], items_string[256], output[10][32], count = 0
				
		format(cvar_name, 31, "adminmodx_items_team_%d", get_user_team(player_id))
		get_cvar_string(cvar_name, items_string, 254)

		if(strlen(items_string) > 0)
			string_break(output, 6, 32, items_string, ' ')

		else
		{
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_REVIVE_NOWPNS")
			return PLUGIN_CONTINUE
		}
		
		// I dont know if this will work
		DispatchSpawn(find_ent_by_owner(-1, "player", player_id, 1))
		
		//else
		//spawn(player_id)
		//spawn(player_id)

		get_user_origin(id, origin, 0)
		origin[1] += 10
		origin[2] += 10
		set_user_origin(player_id, origin)
		
		for(new x = 0; x < count; x++)
			give_item(player_id, output[x])

		client_print(0, print_center, "%L", LANG_SERVER, "ADMINMODX_REVIVE", nameAgainst)
	}

	// Show it if needed
	switch(get_cvar_num("amx_show_activity"))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Revive on ", nameAgainst)
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Revive on ", nameAgainst)
	}

	// Tell them it succeded
	if(is_client(id))
		client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_REVIVE_SUC")

	// Now Log it
	log_amx("%L", LANG_SERVER, "ADMINMODX_REVIVED", nameCalled, steamCalled, nameAgainst, steamAgainst)

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Buries people
//
public bury(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new cmd[32], steam_nick_team[32], counter, players[32], totalPlayers, origin[3]
	new unbury
	read_argv(0, cmd, 32)


	if(containi(cmd,"amx_bury") != -1)
	{
		replace(cmd, 32, "amx_bury", "")
	}

	else if(containi(cmd,"amx_unbury") != -1)
	{
		replace(cmd, 32, "amx_unbury", "")
		unbury = 1
	}

	// Get the info on the caller
	new nameCalled[32], steamCalled[32]
	get_user_name(id, nameCalled, 31)
	get_user_authid(id, steamCalled, 31)

	new Red = random(256)
	new Green = random(256)
	new Blue = random(256)
	set_hudmessage(Red, Green, Blue, 0.03, 0.62, 2, 0.02, 2.0, 0.01, 0.1, 1)

	if(equali(cmd, "all"))
	{
		get_players(players, totalPlayers, "a")

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if((unbury && g_buried[players[counter]]) || (is_user_alive(players[counter]) == 1) && !(get_user_flags(players[counter])&IMMUNE))
			{
				get_user_origin(players[counter], origin)

				if(unbury)
					origin[2] += get_cvar_num("adminmodx_burydepth") + 10
				else
					origin[2] -= get_cvar_num("adminmodx_burydepth")

				set_user_origin(players[counter], origin)
				g_buried[players[counter]] = !unbury
			}
		}

		if(!unbury)
		{
			switch(get_cvar_num("adminmodx_show_activity"))
			{
				case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_ALLBURRIED")
				case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_ALLBURRIED")
				case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_ALLBURRIED")
			}

			if(get_cvar_num("adminmodx_sounds"))
				emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

			// Show it if needed
			switch(get_cvar_num("amx_show_activity"))
			{
				case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Bury All", "")
				case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Bury All")
			}

			// Tell them it succeded
			if(is_user_connected(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_BURYALL_SUC")

			// Now Log it
			log_amx("%L", LANG_SERVER, "ADMINMODX_BURYALL", nameCalled, steamCalled)
		}
	}


	else if(equali(cmd, ""))
	{
		if(!cmd_access(id, level, cid, 2))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)

		// Search for the Player
		new player_id = get_player(steam_nick_team)

		if(player_id == -1)
		{
			// Give out error message
			if ( is_user_connected(id) )
				client_print(id, print_console, "%L", LANG_PLAYER, "NICK_NOT_FOUND")

			return PLUGIN_CONTINUE
		}

		if((unbury && g_buried[player_id]) || (is_user_alive(player_id) == 1) && !(get_user_flags(player_id)&IMMUNE))
		{
			get_user_origin(player_id, origin)

			if(unbury)
				origin[2] += get_cvar_num("adminmodx_burydepth") + 10
			else
				origin[2] -= get_cvar_num("adminmodx_burydepth")

			set_user_origin(player_id, origin)
			g_buried[player_id] = !unbury
		}

		if(!unbury)
		{
			// Get the info on the caller
			new nameAgainst[32], steamAgainst[32]
			get_user_name(player_id, nameAgainst, 31)
			get_user_authid(player_id, steamAgainst, 31)
			
			switch(get_cvar_num("adminmodx_show_activity"))
			{
				case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_BURRIED", nameAgainst)
				case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_BURRIED", nameAgainst)
				case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_BURRIED", nameAgainst)
			}

			if(get_cvar_num("adminmodx_sounds"))
				emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

			// Show it if needed
			switch(get_cvar_num("amx_show_activity"))
			{
				case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Bury against: ", nameAgainst)
				case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Bury against:", nameAgainst)
			}

			// Tell them it succeded
			if(is_user_connected(id))
				client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_BURY_SUC")

			// Now Log it
			log_amx("%L", LANG_SERVER, "ADMINMODX_BURY", nameCalled, steamCalled, nameAgainst, steamAgainst)
		}
	}


	else if(equali(cmd, "team"))
	{
		if(!cmd_access(id, level, cid, 2))
			return PLUGIN_HANDLED

		read_argv(1, steam_nick_team, 32)

		new teamname[16]
		get_players_team(players, totalPlayers, str_to_num(steam_nick_team), teamname)

		for(counter = 0; counter < totalPlayers; counter++)
		{
			if(is_user_alive(players[counter]) == 1 && !(get_user_flags(players[counter])&IMMUNE))
			{
				get_user_origin(players[counter], origin)

				if ( unbury )
					origin[2] += get_cvar_num("adminmodx_burydepth") + 10

				else
					origin[2] -= get_cvar_num("adminmodx_burydepth")

				set_user_origin(players[counter], origin)
				g_buried[players[counter]] = !unbury
			}
		}

		if(!unbury)
		{
			switch(get_cvar_num("adminmodx_show_activity"))
			{
				case 0: client_print(id, print_console, "%L", LANG_SERVER, "ADMINMODX_TEAMBURRIED", teamname)
				case 1: client_print(0, print_chat, "%L", LANG_SERVER, "ADMINMODX_TEAMBURRIED", teamname)
				case 2: show_hudmessage(0, "%L", LANG_SERVER, "ADMINMODX_TEAMBURRIED", teamname)
			}

			if(get_cvar_num("adminmodx_sounds"))
				emit_sound(0, CHAN_VOICE, soundName[thunder], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

			// Show it if needed
			switch(get_cvar_num("amx_show_activity"))
			{
				case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_NAMED", nameCalled, "Bury Against Team: ", teamname)
				case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMXX_LOGGING_UNNAMED", "Bury Against Team: ", teamname)
			}

			// Tell them it succeded
			if ( is_user_connected(id) )
				client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_BURYTEAM_SUC")

			// Now Log it
			log_amx("%L", LANG_SERVER, "ADMINMODX_BURYTEAM", nameCalled, steamCalled, teamname)
		}
	}

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Searches for a player given search
//
// @param string - The player search criteria
// @return int - The players id or -1 if not found
//
get_player(search[])
{
	// See if they are there by exact nick
	new player_id = find_player("ahjl", search)

	// Try to find them by portion of nick
	if(!player_id)
		player_id = find_player("bhjl", search)

	// Try to find them by steam id
	if(!player_id)
		player_id = find_player("chj", search)

	// Try to find them by ip
	if(!player_id)
		player_id = find_player("dhj", search)

	// Try to find them by userid
	if(!player_id)
		player_id = find_player("khj", search)

	if(!player_id)
		return -1

	return player_id
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Gets the players on a team given the team number, and gives back the team name
//
get_players_team(players[32], &totalPlayers, team, teamname[16])
{
	new list[32], total, temp[2][16]
	
	get_players(list, total)

	totalPlayers = 0
	
	if(team == 0 && strlen(teamname) > 0)
	{
		get_cvar_string("adminmodx_team_1", temp[0], 15)	
		get_cvar_string("adminmodx_team_2", temp[1], 15)
		
		if(equali(temp[0], teamname))
			team = 1
			
		else if(equali(temp[1], teamname))
			team = 2
	}

	for(new counter = 0; counter < total; counter++)
	{
		if(get_user_team(list[counter]) == team)
		{
			players[totalPlayers] = list[counter]
			totalPlayers++
		}
	}

	if(players[0])
		get_user_team(players[0], teamname, 31)
	else
		teamname = "Unknown"
	
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	log_amx("Total: %d Team Num: %d Team Name: %s", totalPlayers, team, teamname)
	for(new i = 0; i < totalPlayers; i++)
		log_amx("%d", players[i])
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Checks to see if its a client or else it was the server
//
is_client(id)
{
	return (id > 0 && id < 33) ? 1 : 0
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Slaps a target at intervals
//
public slaptarget(param[])
{
	if(is_user_alive(param[0]) == 1)
	{
		user_slap(param[0], get_cvar_num("slappower"), 1)
	}

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Sets the slap power on the server
//
public setslappower(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[8]
	read_argv(1,arg,7)
	new slappower = str_to_num(arg)

	// Between 0 - 10
	if((slappower > -1) && (slappower < 11))
	{
		if(is_client(id))
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMINMODX_SET_SLAPWRONG")

		return PLUGIN_HANDLED
	}

	set_cvar_num("slappower", slappower)

	new nameCalled[50]
	new steamCalled[50]
	get_user_name(id,nameCalled,49)
	get_user_authid(id,steamCalled,49)
	log_amx("%L", LANG_SERVER, "ADMINMODX_SET_SLAP", nameCalled, steamCalled)

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Checks to see if Llama tried to change names
//
public checkName(param[])
{
	if(is_user_alive(param[0]))
	{
		set_user_info(param[0], "name", "Llama")
		client_cmd(param[0], "name Llama")
	}
	else
		set_task(1.0, "checkName", param[0], param, 1)

	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Will reset the things upon death
//
public eDeath()
{
	g_buried[read_data(2)] = 0

	if(task_exists((read_data(2)+1000)))
	{
		remove_task((read_data(2)+1000))
	}
}

///////////////////////////////////////////////////////////////////////////////////////
//
// Splits a string up into parts (Thanks to the developer of this function)
//
string_break( Output[][], nMax, nSize, Input[], Delimiter )
{
	new nIdx = 0, l = strlen(Input)
	new nLen = (1 + copyc( Output[nIdx], nSize, Input, Delimiter ))

	while( (nLen < l) && (++nIdx < nMax) )
	{
		nLen += (1 + copyc( Output[nIdx], nSize, Input[nLen], Delimiter ))
	}

	return nIdx
}

///////////////////////////////////////////////////////////////////////////////////////
//
//	Checks to see if they are llama or gaged
//
public say_type_blocks(id)
{
	// We check gag first to see if he is gaged, if so then who cares if he is llamad, he cant talk anyway!
	if(g_gaged[id] == 1)
	{
		// Eat the message
		return PLUGIN_HANDLED
	}

	// Is this client Llamad
	if(g_lamaed[id] == 1)
	{
		// Check the last time he said something
		if(get_user_time(id) > (g_llamaLastSay[id] + get_cvar_num("adminmodx_llama_chat_delay")))
		{
			g_llamaLastSay[id] = get_user_time(id)
			new LlamaMsg = random(3)

			client_print(0, print_chat, "Llama: %s", g_llamasaying[LlamaMsg])
			emit_sound(id, CHAN_VOICE, soundName[LlamaMsg], VOL_NORM, ATTN_NONE, 0, PITCH_HIGH)

			return PLUGIN_CONTINUE
		}

		// If it has been too quickly then we need to increment and warn him
		else
		{
			// Increment the tracking count
			g_llamaLastSayWarning[id]++

			// Check to see if this is the last time, and  if so then we need to kick him off
			if(g_llamaLastSayWarning[id] > get_cvar_num("adminmodx_llama_chat_warnings"))
			{
				// BYEEE!!!!
				client_cmd(id, "quit")
				return PLUGIN_HANDLED
			}

			else
			{
				// Ok so it wasn't but we dont want him to get himself kicked off so lets warn his ass
				client_print(id, print_chat, "%L", LANG_PLAYER, "ADMINMODX_LLAMA_WARN", g_llamaLastSayWarning[id], get_cvar_num("adminmodx_llama_chat_warnings"))
				client_print(id, print_chat, "%L", LANG_PLAYER, "ADMINMODX_LLAMA_NEXT", (g_llamaLastSay[id] + get_cvar_num("adminmodx_llama_chat_delay")) - get_user_time(id))
			}
		}
	}
	
	// First get the message
	new cmd[32], message[128]
	read_args(message, 127)
	read_argv(0, cmd, 31)

	replace(message, 127, cmd, "")
	remove_quotes(message)
	
	if((contain(message, "/stuck") != -1 || contain(message, "/unstuck") != -1) && g_buried[id] == 1)
	{
		client_print(id, print_chat, "Sorry but your burried not stuck!")
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}
