/* Copyright (C) 2006-2008 Space Headed Productions

*

* WeaponMod is free software; you can redistribute it and/or

* modify it under the terms of the GNU General Public License

* as published by the Free Software Foundation.

*

* WeaponMod is distributed in the hope that it will be useful,

* but WITHOUT ANY WARRANTY; without even the implied warranty of

* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

* GNU General Public License for more details.

*

* You should have received a copy of the GNU General Public License

* along with WeaponMod; if not, write to the Free Software

* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/



// Uncomment this, to enable Condition Zero support

// #define CONDITION_ZERO



// Uncomment this, to enable UL Money support

// #define UL_MONEY_SUPPORT



#include <amxmodx>

#include <fakemeta>

#include <weaponmod>



#if defined UL_MONEY_SUPPORT

#include <money_ul>

#endif



// Plugin informations

#if defined UL_MONEY_SUPPORT



#if defined CONDITION_ZERO

new const PLUGIN[] = "WPN GameInfo CZ (UL)"

#else

new const PLUGIN[] = "WPN GameInfo CS (UL)"

#endif



#else



#if defined CONDITION_ZERO

new const PLUGIN[] = "WPN GameInfo CZ"

#else

new const PLUGIN[] = "WPN GameInfo CS"

#endif



#endif

new const VERSION[] = "0.9" // 0.8 - 0.9 fix broken plugin indefinate freezetime.

new const AUTHOR[] = "SPiNX|DevconeS"



// Tasks

#define TASK_ENABLE_FREEZE	1564

#define TASK_UPDATE_SPEED	1565



// Offsets

#define OFFSET_MONEY	115

#define OFFSET_DEATHS	444//449



// GameInfos

new const WEAPON_INDEX = 29					// Weapon Index of the weapon that should be replaced

new const Float:WEAPON_RUN_SPEED = 250.0		// Run speed of the replaced weapon

new const WEAPON_COMMAND[] = "weapon_knife"		// Command to take the weapon

new const WEAPON_V_MODEL[] = "models/v_knife.mdl"	// Viewmodel of the weapon that should be replaced

new const WEAPON_P_MODEL[] = "models/p_knife.mdl"	// Playermodel of the weapon that should be replaced

#if defined CONDITION_ZERO

new const GUNSHOT_DECALS[] = {53, 54, 55, 56, 57}	// Gunshot decal list

new const EXPLOSION_DECALS[] = {58, 59, 60}		// Explosion decal list

new const SMALL_EXPLOSION_DECALS[] = {40, 41, 42}	// Small Explosion decal list

new const LARGE_BLOOD_DECALS[] = {216, 217}		// Large blood decals

new const SMALL_BLOOD_DECALS[] = {202, 203, 204, 205, 206, 207, 208, 209}	// Small blood decals

#else

new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45}	// Gunshot decal list

new const EXPLOSION_DECALS[] = {46, 47, 48}		// Explosion decal list

new const SMALL_EXPLOSION_DECALS[] = {28, 29, 33}	// Small Explosion decal list

new const LARGE_BLOOD_DECALS[] = {204, 205}		// Large blood decals

new const SMALL_BLOOD_DECALS[] = {190, 191, 192, 193, 194, 196, 197, 198}	// Small blood decals

#endif



// User Messages

new g_msgCurWeapon

new g_msgAmmoX

new g_msgScoreInfo

new g_msgDeathMsg

new g_msgDamage

#if !defined UL_MONEY_SUPPORT

new g_msgMoney

#endif



// CVAR Pointers

new g_PlayerKillMoney

new g_MonsterKillMoney

new g_Enabled



// General information

new bool:g_FreezeTime

new g_MaxPlayers



// Register the plugin

public plugin_init()

{

	// Important informations :)

	register_plugin(PLUGIN, VERSION, AUTHOR)



	// Events

	register_event("CurWeapon", "eventCurWeapon", "be", "1=1")

	register_event("TextMsg", "eventRoundRestart", "a", "2=#Game_will_restart_in")

	register_logevent("logEventRoundStart", 2, "1=Round_Start")

	register_logevent("logEventRoundEnd", 2, "0=World triggered", "1=Round_End")



	// User Messages

	g_msgCurWeapon = get_user_msgid("CurWeapon")

	g_msgAmmoX = get_user_msgid("AmmoX")

	g_msgScoreInfo = get_user_msgid("ScoreInfo")

	g_msgDeathMsg = get_user_msgid("DeathMsg")

	g_msgDamage = get_user_msgid("Damage")

#if !defined UL_MONEY_SUPPORT

	g_msgMoney = get_user_msgid("Money")

#endif



	// CVARs

	g_PlayerKillMoney = register_cvar("wpn_playerkill_money", "300")

	g_MonsterKillMoney = register_cvar("wpn_monsterkill_money", "800")

	g_Enabled = get_cvar_pointer("wpn_enabled")



	// Forwards

	register_forward(FM_EmitSound, "fwd_EmitSound")



	wpn_gameinfo_init()

	g_MaxPlayers = get_maxplayers()

}



// Start sending some infos to WeaponMod :)

wpn_gameinfo_init()

{

	// Let WeaponMod know that a GameInfo file is installed

	wpn_set_gameinfo(gi_available, 1)



	// Is this a Teamplay game?

	wpn_set_gameinfo(gi_teamplay, 1)

}



// These natives are very important since they'll get called by WeaponMod and addons

public plugin_natives()

{

	register_native("wpn_gi_is_default_weapon", "native_gi_is_default_weapon")

	register_native("wpn_gi_set_offset_int", "native_gi_set_offset_int")

	register_native("wpn_gi_get_offset_int", "native_gi_get_offset_int")

	register_native("wpn_gi_in_freeze_time", "native_gi_in_freeze_time")

	register_native("wpn_gi_take_default_weapon", "native_gi_take_default_weapon")

	register_native("wpn_gi_get_gunshot_decal", "native_gi_get_gunshot_decal")

	register_native("wpn_gi_get_explosion_decal", "native_gi_get_explosion_decal")

	register_native("wpn_gi_get_smallexplosion_decal", "native_gi_get_smallexpl_decal")

	register_native("wpn_gi_get_blood_decal", "native_gi_get_blood_decal")

	register_native("wpn_gi_get_smallblood_decal", "native_gi_get_smallblood_decal")

}



// Checks if the selected weapon is the default weapon

public native_gi_is_default_weapon()

{

	if(get_param(1) == WEAPON_INDEX)

	{

		return 1

	}



	return 0

}



// Sets an offset value

public native_gi_set_offset_int()

{

	return set_offset_value(get_param(1), get_param(2), get_param(3))

}



// Gets an offset value

public native_gi_get_offset_int()

{

	return get_offset_value(get_param(1), get_param(2))

}



// Identifies if the game is currently in the freeze time

public native_gi_in_freeze_time()

{

	return g_FreezeTime

}



// Player has to take the default weapon (obviously picked up a new special weapon)

public native_gi_take_default_weapon()

{

	engclient_cmd(get_param(1), WEAPON_COMMAND)

}



// Returns a random gunshot decal

public native_gi_get_gunshot_decal()

{

	return GUNSHOT_DECALS[random_num(0, sizeof(GUNSHOT_DECALS) - 1)]

}



// Returns a random explosion decal

public native_gi_get_explosion_decal()

{

	return EXPLOSION_DECALS[random_num(0, sizeof(EXPLOSION_DECALS) - 1)]

}



// Returns a random small explosion decal

public native_gi_get_smallexpl_decal()

{

	return SMALL_EXPLOSION_DECALS[random_num(0, sizeof(SMALL_EXPLOSION_DECALS) - 1)]

}



// Returns a random large blood decal

public native_gi_get_blood_decal()

{

	return LARGE_BLOOD_DECALS[random_num(0, sizeof(LARGE_BLOOD_DECALS) - 1)]

}



// Returns a random small blood decal

public native_gi_get_smallblood_decal()

{

	return SMALL_BLOOD_DECALS[random_num(0, sizeof(SMALL_BLOOD_DECALS) - 1)]

}




// Called when round's restarted

public eventRoundRestart()
{
	if(!task_exists(TASK_ENABLE_FREEZE))

	{

		// No task has been created by now, create one

		set_task(float(read_data(3))-0.1, "enable_freeze", TASK_ENABLE_FREEZE)

	}

}





// Round started

public logEventRoundStart()

{

	g_FreezeTime = false



	// Create update speed task (delayed because of possibility to be overwritten by CS)

	set_task(0.1, "update_speed", TASK_UPDATE_SPEED)

}



// Delayed speed update

public update_speed()

{

	new usrwpn = -1

	new wpnid = -1

	new Float:maxspeed

	for(new id = 1; id < g_MaxPlayers; id++)

	{

		usrwpn = wpn_get_user_weapon(id)

		if(usrwpn != -1)

		{

			// User is using a WeaponMod weapon, set his maxspeed

			wpnid = wpn_get_userinfo(id, usr_wpn_index, usrwpn)

			maxspeed = wpn_get_float(wpnid, wpn_run_speed)

			set_pev(id, pev_maxspeed, maxspeed)

		}

	}

}



// Round end

public logEventRoundEnd()

{

	set_task(1.0, "enable_freeze", TASK_ENABLE_FREEZE)

}



// Removes special weapons on map

public enable_freeze()

{

	g_FreezeTime = true

}



// This function is used to update the players Ammo displayed on HUD

public wpn_gi_update_ammo(id, wpnid, pAmmo, sAmmo)

{

	if(wpnid > -1)	// -1 would be no special weapon

	{

		// Primary Ammo

		message_begin(MSG_ONE, g_msgCurWeapon, {0, 0, 0}, id)

		write_byte(1)

		write_byte(20)

		write_byte(pAmmo)

		message_end()



		// Secondary Ammo

		message_begin(MSG_ONE, g_msgAmmoX, {0, 0, 0}, id)

		write_byte(3)

		write_byte(sAmmo)

		message_end()



		return PLUGIN_CONTINUE

	}



	// Hide Ammo from HUD since user is using the knife

	message_begin(MSG_ONE, g_msgCurWeapon, {0, 0, 0}, id)

	write_byte(-1)

	write_byte(29)

	write_byte(-1)

	message_end()



	return PLUGIN_CONTINUE

}



// A player was killed by a special weapon

public wpn_gi_player_killed(id, killer, hitplace, wpnid, weapon[], bool:monster)

{

	// Update Scoreboard - Killer

	emessage_begin(MSG_BROADCAST, g_msgScoreInfo)

	ewrite_byte(killer)

	ewrite_short(get_user_frags(killer))

	ewrite_short(get_offset_value(killer, offset_deaths))

	ewrite_short(0)

	ewrite_short(get_user_team(killer))

	emessage_end()



	new moneyIncreasement = 0



	// Monster's can't be showed inside a death message and do not have a scoreboard :P

	if(!monster)

	{

		// Write death message

		emessage_begin(MSG_BROADCAST, g_msgDeathMsg)

		ewrite_byte(killer)

		ewrite_byte(id)

		ewrite_byte(hitplace == 1 ? 1 : 0)

		ewrite_string(weapon)

		emessage_end()



		if(id != killer)	// No need to update the scoreboard twice :)

		{

			// Update Scoreboard - Victim

			emessage_begin(MSG_BROADCAST, g_msgScoreInfo)

			ewrite_byte(id)

			ewrite_short(get_user_frags(id))

			ewrite_short(get_offset_value(id, offset_deaths))

			ewrite_short(0)

			ewrite_short(get_user_team(id))

			emessage_end()

		}



		moneyIncreasement = get_pcvar_num(g_PlayerKillMoney)

	} else {

		moneyIncreasement = get_pcvar_num(g_MonsterKillMoney)

	}



	if(moneyIncreasement != 0)

	{

		// Money of the killer changes, update it :)

		new newMoney = get_offset_value(killer, offset_money)+moneyIncreasement

		set_offset_value(killer, offset_money, newMoney)

	}

}



// Damage caused by a WeaponMod weapon

public wpn_attack_damage(victim, attacker, wpnid, damage, hitplace, damageType, bool:monster)

{

	if(monster || !pev_valid(victim))

	{

		// Damage was caused to a monster or the victim is not a valid entity, ignore

		return PLUGIN_CONTINUE

	}



	// Make sure it's definetely a player and make sure he's alive

	if(pev(victim, pev_flags) & (FL_CLIENT | FL_FAKECLIENT))

	{

		if(is_user_alive(victim))

		{

			// Get attacker's origin

			new origin[3]

			get_user_origin(attacker, origin)



			// Write damage message

			message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, victim)

			write_byte(0)	// Damage save not supported

			write_byte(damage)

			write_long(damageType)

			write_coord(origin[0])

			write_coord(origin[1])

			write_coord(origin[2])

			message_end()

		}

	}

	return PLUGIN_CONTINUE

}



// This forward is used to reset the replaced weapon to its default values

public wpn_gi_reset_weapon(id)

{

	// Models

	set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, WEAPON_V_MODEL))

	set_pev(id, pev_weaponmodel, engfunc(EngFunc_AllocString, WEAPON_P_MODEL))



	// Run speed

	if(!g_FreezeTime)

	{

		set_pev(id, pev_maxspeed, WEAPON_RUN_SPEED)

	}

}



// Handle weapon change

public eventCurWeapon(id)

{

	if(!get_pcvar_num(g_Enabled)) return PLUGIN_CONTINUE

	if(wpn_user_weapon_count(id) > 0)

	{

		if(read_data(2) == WEAPON_INDEX)

		{

			// Take the last used weapon

			wpn_change_user_weapon(id, wpn_get_user_weapon(id), false)

		}

	}



	return PLUGIN_CONTINUE

}



// Handle draw command

public client_command(id)

{

	if(!get_pcvar_num(g_Enabled)) return PLUGIN_CONTINUE



	new cmd[32]

	read_argv(0, cmd, 31)



	if(equal(cmd, WEAPON_COMMAND))	// Does he execute the knife command?

	{

		new wpnCount = wpn_user_weapon_count(id)

		if(wpnCount > 0)	// Does he even have a special weapon?

		{

			new clip, ammo

			new weapon = get_user_weapon(id, clip, ammo)

			if(weapon == WEAPON_INDEX)	// Is his current weapon the knife?

			{

				new actWeapon = wpn_get_user_weapon(id)+1

				if(actWeapon >= wpnCount)

				{

					// Weapon index got over the amount of weapons, set it back to the beginning

					actWeapon = -1

				}

				// Now send the changes back to weaponmod :)

				wpn_change_user_weapon(id, actWeapon)

			}

		}

	}



	return PLUGIN_CONTINUE

}



// Block knife sound

public fwd_EmitSound(entity, channel, const sample[])

{

	if(entity > 0 && entity < 33)

	{

		if(is_user_alive(entity))

		{

			if(wpn_get_user_weapon(entity) != -1)

			{

				// Player's using a weaponmod weapon, block any knife sounds emitted

				if(containi(sample, "weapons/knife_") != -1)

				{

					return FMRES_SUPERCEDE

				}

			}

		}

	}



	return FMRES_IGNORED

}



// Gets offset data

public get_offset_value(id, type)

{

	new key = -1

	switch(type)

	{

		case offset_money:

		{

#if defined UL_MONEY_SUPPORT

			return cs_get_user_money_ul(id)

#else

			key = OFFSET_MONEY

#endif

		}

		case offset_deaths: key = OFFSET_DEATHS

	}



	if(key != -1)

	{

		if(is_amd64_server()) key += 25

		return get_pdata_int(id, key)

	}



	return -1;

}



// Sets offset data

public set_offset_value(id, type, value)

{

	new key = -1

	switch(type)

	{

		case offset_money:

		{

#if defined UL_MONEY_SUPPORT

			return cs_set_user_money_ul(id, value)

#else

			key = OFFSET_MONEY



			// Send Money message to update player's HUD

			message_begin(MSG_ONE_UNRELIABLE, g_msgMoney, {0,0,0}, id)

			write_long(value)

			write_byte(1)	// Flash (difference between new and old money)

			message_end()

#endif

		}

		case offset_deaths: key = OFFSET_DEATHS

	}



	if(key != -1)

	{

		if(is_amd64_server()) key += 25

		set_pdata_int(id, key, value)

	}



	return PLUGIN_CONTINUE

}
