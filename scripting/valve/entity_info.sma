#include <amxmodx>
#include <amxmisc>
#include <engine>

#define MAX_PLAYERS 32

new bool:g_bOnline[ MAX_PLAYERS + 1 ];

new EV_INT_NAME[][] = {
"EV_INT_gamestate",
"EV_INT_oldbuttons",
"EV_INT_groupinfo",
"EV_INT_iuser1",
"EV_INT_iuser2",
"EV_INT_iuser3",
"EV_INT_iuser4",
"EV_INT_weaponanim",
"EV_INT_pushmsec",
"EV_INT_bInDuck",
"EV_INT_flTimeStepSound",
"EV_INT_flSwimTime",
"EV_INT_flDuckTime",
"EV_INT_iStepLeft",
"EV_INT_movetype",
"EV_INT_solid",
"EV_INT_skin",
"EV_INT_body",
"EV_INT_effects",
"EV_INT_light_level",
"EV_INT_sequence",
"EV_INT_gaitsequence",
"EV_INT_modelindex",
"EV_INT_playerclass",
"EV_INT_waterlevel",
"EV_INT_watertype",
"EV_INT_spawnflags",
"EV_INT_flags",
"EV_INT_colormap",
"EV_INT_team",
"EV_INT_fixangle",
"EV_INT_weapons",
"EV_INT_rendermode",
"EV_INT_renderfx",
"EV_INT_button",
"EV_INT_impulse",
"EV_INT_deadflag" }

new EV_FL_NAME[][] = {
"EV_FL_impacttime",
"EV_FL_starttime",
"EV_FL_idealpitch",
"EV_FL_pitch_speed",
"EV_FL_ideal_yaw",
"EV_FL_yaw_speed",
"EV_FL_ltime",
"EV_FL_nextthink",
"EV_FL_gravity",
"EV_FL_friction",
"EV_FL_frame",
"EV_FL_animtime",
"EV_FL_framerate",
"EV_FL_health",
"EV_FL_frags",
"EV_FL_takedamage",
"EV_FL_max_health",
"EV_FL_teleport_time",
"EV_FL_armortype",
"EV_FL_armorvalue",
"EV_FL_dmg_take",
"EV_FL_dmg_save",
"EV_FL_dmg",
"EV_FL_dmgtime",
"EV_FL_speed",
"EV_FL_air_finished",
"EV_FL_pain_finished",
"EV_FL_radsuit_finished",
"EV_FL_scale",
"EV_FL_renderamt",
"EV_FL_maxspeed",
"EV_FL_fov",
"EV_FL_flFallVelocity",
"EV_FL_fuser1",
"EV_FL_fuser2",
"EV_FL_fuser3",
"EV_FL_fuser4" }

new EV_VEC_NAME[][] = {
"EV_VEC_origin",
"EV_VEC_oldorigin",
"EV_VEC_velocity",
"EV_VEC_basevelocity",
"EV_VEC_clbasevelocity",
"EV_VEC_movedir",
"EV_VEC_angles",
"EV_VEC_avelocity",
"EV_VEC_punchangle",
"EV_VEC_v_angle",
"EV_VEC_endpos",
"EV_VEC_startpos",
"EV_VEC_absmin",
"EV_VEC_absmax",
"EV_VEC_mins",
"EV_VEC_maxs",
"EV_VEC_size",
"EV_VEC_rendercolor",
"EV_VEC_view_ofs",
"EV_VEC_vuser1",
"EV_VEC_vuser2",
"EV_VEC_vuser3",
"EV_VEC_vuser4" }

new EV_ENT_NAME[][] = {
"EV_ENT_chain",
"EV_ENT_dmg_inflictor",
"EV_ENT_enemy",
"EV_ENT_aiment",
"EV_ENT_owner",
"EV_ENT_groundentity",
"EV_ENT_pContainingEntity",
"EV_ENT_euser1",
"EV_ENT_euser2",
"EV_ENT_euser3",
"EV_ENT_euser4" }

new EV_SZ_NAME[][] = {
"EV_SZ_classname",
"EV_SZ_globalname",
"EV_SZ_model",
"EV_SZ_target",
"EV_SZ_targetname",
"EV_SZ_netname",
"EV_SZ_message",
"EV_SZ_noise",
"EV_SZ_noise1",
"EV_SZ_noise2",
"EV_SZ_noise3",
"EV_SZ_viewmodel",
"EV_SZ_weaponmodel" }

new EV_BYTE_NAME[][] = {
"EV_BYTE_controller1",
"EV_BYTE_controller2",
"EV_BYTE_controller3",
"EV_BYTE_controller4",
"EV_BYTE_blending1",
"EV_BYTE_blending2" }

new i, EV_INT_VALUE, Float:EV_FL_VALUE, Float:EV_VEC_VALUE[3], EV_ENT_VALUE, EV_SZ_VALUE[MAX_PLAYERS], EV_BYTE_VALUE
new is_attack, was_attack,victim, bodypart;
new g_entity_think_on;

public plugin_init()
{
  register_plugin("Entity Info", "0.5", "Pizzahut|SPiNX") //99% of code is pizzahut.
  g_entity_think_on = register_cvar("entity_info", "1");
}


public client_PreThink(id)
{
  g_bOnline[id] = bool:is_user_connected(id) && is_user_alive(id) && !is_user_bot(id) && is_user_admin(id)
  if(g_bOnline[id] && get_pcvar_num(g_entity_think_on) == 1){

  is_attack = entity_get_int(id, EV_INT_button) & IN_ATTACK
  was_attack = entity_get_int(id, EV_INT_oldbuttons) & IN_ATTACK
  if (!is_attack || was_attack)
    return PLUGIN_CONTINUE

  get_user_aiming(id, victim, bodypart)
  if (victim == 0)
    return PLUGIN_CONTINUE
  set_hudmessage(255, 0, 0, -1.0, -1.0)
  show_hudmessage(id, "Entity %d^nSee console for more info.", victim)
  console_print(id, "Entity %d", victim)

  for(i=EV_INT_gamestate ; i<=EV_INT_deadflag ; i++)
    if((EV_INT_VALUE = entity_get_int(victim, i)) != 0)
      console_print(id, "%s = %d", EV_INT_NAME[i], EV_INT_VALUE)

  for(i=EV_FL_impacttime ; i<=EV_FL_fuser4 ; i++)
    if((EV_FL_VALUE = entity_get_float(victim, i)) != 0.0)
      console_print(id, "%s = %f", EV_FL_NAME[i], EV_FL_VALUE)

  for(i=EV_VEC_origin ; i<=EV_VEC_vuser4 ; i++)
  {
    entity_get_vector(victim, i, EV_VEC_VALUE)
    if((EV_VEC_VALUE[0] != 0) || (EV_VEC_VALUE[1] != 0) || (EV_VEC_VALUE[2] != 0))
      console_print(id, "%s = (%f,%f,%f)", EV_VEC_NAME[i], EV_VEC_VALUE[0], EV_VEC_VALUE[1], EV_VEC_VALUE[2])
  }

  for(i=EV_ENT_chain ; i<=EV_ENT_euser4 ; i++)
    if((EV_ENT_VALUE = entity_get_edict(victim, i)) != 0)
      console_print(id, "%s = %d", EV_ENT_NAME[i], EV_ENT_VALUE)

  for(i=EV_SZ_classname ; i<=EV_SZ_weaponmodel ; i++)
  {
    entity_get_string(victim, i, EV_SZ_VALUE, 32)
    if(strlen(EV_SZ_VALUE) != 0)
      console_print(id, "%s = %s", EV_SZ_NAME[i], EV_SZ_VALUE)
  }

  for(i=EV_BYTE_controller1 ; i<=EV_BYTE_blending2 ; i++)
    if((EV_BYTE_VALUE = entity_get_byte(victim, i)) != 0)
      console_print(id, "%s = %d", EV_BYTE_NAME[i], EV_BYTE_VALUE)
  }
  return PLUGIN_CONTINUE
}
