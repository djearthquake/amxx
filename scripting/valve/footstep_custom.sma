/*
 * footstep_custom.sma
 *
 * Copyright 2020 SPiNX
 *
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
 *
*/

#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Footsteps, custom"
#define VERSION "1.5"
#define AUTHOR "Alka|SPiNX"

#define STEP_DELAY 0.5

new Float:g_fNextStep[33];

#define MAX_SOUNDS 6 //Max num of sound for list below

new const g_szStepSound[MAX_SOUNDS][] =
{

	"player/pl_snow1.wav",
	"player/pl_snow2.wav",
	"player/pl_snow3.wav",
	"player/pl_snow4.wav",
	"player/pl_snow5.wav",
	"player/pl_snow6.wav"
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink", 0);
}

public plugin_precache()
{
	new i;
	for(i = 0; i < MAX_SOUNDS ; i++)
		precache_sound(g_szStepSound[i]);
}

public fwd_PlayerPreThink(id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	if(!is_user_outside(id))
		return FMRES_IGNORED;

	set_pev(id, pev_flTimeStepSound, 999);

	#define STOP_SOUND emit_sound(id, CHAN_BODY, g_szStepSound[random(MAX_SOUNDS)], VOL_NORM, ATTN_STATIC, SND_STOP, PITCH_NORM)
	if(fm_get_ent_speed(id) < 175.0 ) {
		STOP_SOUND; }

	if(g_fNextStep[id] < get_gametime())
	{
		if(fm_get_ent_speed(id) && (pev(id, pev_flags) & FL_ONGROUND) && is_user_outside(id))
			emit_sound(id, CHAN_BODY, g_szStepSound[random(MAX_SOUNDS)], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);

		g_fNextStep[id] = get_gametime() + STEP_DELAY;
	}
	return FMRES_IGNORED;
}


stock Float:fm_get_ent_speed(id)
{
	if(!pev_valid(id))
		return 0.0;

	static Float:vVelocity[3];
	pev(id, pev_velocity, vVelocity);

	vVelocity[2] = 0.0;

	return vector_length(vVelocity);
}

stock Float:is_user_outside(id)
{
	new Float:vOrigin[3], Float:fDist;
	pev(id, pev_origin, vOrigin);
	fDist = vOrigin[2];
	while(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_EMPTY)
		vOrigin[2] += 5.0;
	if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
		return (vOrigin[2] - fDist);
	return 0.0;
}
