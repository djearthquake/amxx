/* AMX Jetpack
* 
* (c) Copyright 2020, SPiNX ported to DoD, HLDM, and Opposing Force.
* This file is provided as is (no warranties). 
* 
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <fakemeta>

#define PLUGINNAME		"Jetpack"
#define VERSION			"1.5"
#define AUTHOR			"KleeneX|SPINX"

#define ACCESS_LEVEL	ADMIN_LEVEL_A
#define VOTE_ACCESS		ADMIN_CFG

#define HLW_KNIFE           0x0019

#define TE_EXPLOSION	3
#define TE_BEAMFOLLOW	22
#define TE_BEAMCYLINDER	21

new ROCKET_MDL[64] = "models/rpgrocket.mdl"
new ROCKET_SOUND[64] = "weapons/rocketfire1.wav"

new hasjet[33]
new Float:last_Rocket[33]
new flame, explosion, trail, white

new vote_count[2]

enum {
    DODW_SPADE
};

public plugin_precache() {
	precache_model("models/p_egon.mdl")
	precache_model("models/v_egon.mdl")
	///precache_model("models/w_egon.mdl")
	precache_model("models/w_oxygent.mdl")
	precache_model("models/w_oxygen.mdl")
	
	precache_model(ROCKET_MDL)
	precache_sound(ROCKET_SOUND)
	
	explosion = precache_model("sprites/zerogxplode.spr")
	trail = precache_model("sprites/smoke.spr")
	flame = precache_model("sprites/xfireball3.spr")
	white = precache_model("sprites/white.spr")
}

public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)
	
	register_clcmd("buyjet","cmdBuyJet",0,": Buy a Jetpack")
	register_clcmd("drop","cmdDrop")
	register_clcmd("say /jphelp","cmdHelp",0,": Displays Jetpack help")
	register_concmd("jp_vote","cmdVote",VOTE_ACCESS,": Vote Jetpack on or off")
	
	new ver[64]
	format(ver,63,"%s v%s",PLUGINNAME,VERSION)
	register_cvar("jp_version",ver,FCVAR_SERVER)
	register_cvar("jp_arena","0")
	
	register_cvar("jp_cost","0")
	register_cvar("jp_active","1")
	register_cvar("jp_noweapons","0")
	register_cvar("jp_limit","0")
	
	register_cvar("jp_speed","32")
	register_cvar("jp_rocket_delay","2.0")
	register_cvar("jp_rocket_speed","600")
	register_cvar("jp_rocket_damage","200")
	register_cvar("jp_damage_radius","500")
	register_cvar("jp_admin_only","1")
	
	register_event("DeathMsg", "player_die", "a")
	register_menucmd(register_menuid("Jetpack?"),(1<<0)|(1<<1),"voteJetpack")
	
	register_forward(FM_EmitSound, "emitsound")
}

public client_connect(id) {
	hasjet[id] = 0
}

    #if AMXX_VERSION_NUM < 183;

public client_disconnect(id)

    #else

public client_disconnected(id)

    #endif

{
	hasjet[id] = 0
}

public server_frame() {
	if(get_cvar_num("jp_active") == 1) {
		for(new id = 1; id < 33; id++) {
			if(is_user_alive(id)) {
				check_attack(id)
			}
		}
	}
}

public check_attack(id) {
	if(hasjet[id]) {
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		if ( wpnid == HLW_KNIFE || wpnid == HLW_CROWBAR || wpnid == DODW_SPADE ){
			if (get_user_button(id) & IN_ATTACK) {
				attack(id)
			}
			if (get_user_button(id) & IN_ATTACK2) {
				attack2(id)
			}
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public attack(id){
	new Float:Aim[3],Float:velocity[3]
	VelocityByAim(id, get_cvar_num("jp_speed"), Aim)
	entity_get_vector(id,EV_VEC_velocity,velocity)
	
	velocity[0] += Aim[0]
	velocity[1] += Aim[1]
	velocity[2] += Aim[2]
	
	entity_set_vector(id,EV_VEC_velocity,velocity)
	
	new fOrigin[3]
	VelocityByAim(id, 10, Aim)
	get_user_origin(id,fOrigin)
	fOrigin[0] -= floatround(Aim[0])
	fOrigin[1] -= floatround(Aim[1])
	fOrigin[2] -= floatround(Aim[2])
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(17) 
	write_coord(fOrigin[0])
	write_coord(fOrigin[1])
	write_coord(fOrigin[2])
	write_short(flame)
	write_byte(10)
	write_byte(255)
	message_end()
	
	entity_set_int(id, EV_INT_gaitsequence, 8)
}

public attack2(id){
	new Float:nexTime = get_gametime()
	if (last_Rocket[id] > nexTime) {
    	return PLUGIN_CONTINUE
	}else{
		new rocket = create_entity("info_target")
		if(rocket == 0) return PLUGIN_CONTINUE
		
		entity_set_string(rocket, EV_SZ_classname, "jp_rocket")
		entity_set_model(rocket, ROCKET_MDL)
		
		entity_set_size(rocket, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
		entity_set_int(rocket, EV_INT_movetype, MOVETYPE_FLY)
		entity_set_int(rocket, EV_INT_solid, SOLID_BBOX)
		
		new Float:vSrc[3]
		entity_get_vector(id, EV_VEC_origin, vSrc)
		
		new Float:Aim[3],Float:origin[3]
		VelocityByAim(id, 64, Aim)
		entity_get_vector(id,EV_VEC_origin,origin)
		
		vSrc[0] += Aim[0]
		vSrc[1] += Aim[1]
		entity_set_origin(rocket, vSrc)
		
		new Float:velocity[3], Float:angles[3]
		VelocityByAim(id, get_cvar_num("jp_rocket_speed"), velocity)
		
		entity_set_vector(rocket, EV_VEC_velocity, velocity)
		vector_to_angle(velocity, angles)
		entity_set_vector(rocket, EV_VEC_angles, angles)
		entity_set_edict(rocket,EV_ENT_owner,id)
		entity_set_float(rocket, EV_FL_takedamage, 1.0)
		
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(rocket)
		write_short(trail)
		write_byte(25)
		write_byte(5)
		write_byte(224)
		write_byte(224)
		write_byte(255)
		write_byte(255)
		message_end()

		emit_sound(rocket, CHAN_WEAPON, ROCKET_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		last_Rocket[id] = nexTime + get_cvar_float("jp_rocket_delay")
	}
	return PLUGIN_CONTINUE
}

public switchmodel(id) {
	entity_set_string(id,EV_SZ_viewmodel,"models/v_egon.mdl")
	entity_set_string(id,EV_SZ_weaponmodel,"models/p_egon.mdl")
}

public remove_jetpacks() {
	new nextitem  = find_ent_by_class(-1,"jp_jetpack")
	while(nextitem) {
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1,"jp_jetpack")
	}
	return PLUGIN_CONTINUE
}

public cmdBuyJet(id) {
hasjet[id] = 1
return PLUGIN_HANDLED
}

public emitsound(entity, channel, const sample[]) {
	if(is_user_alive(entity)) {
		new clip,ammo
		new weapon = get_user_weapon(entity,clip,ammo)
		
		if(hasjet[entity] && weapon == HLW_KNIFE || weapon == HLW_CROWBAR || weapon == DODW_SPADE) {
			if(equal(sample,"weapons/knife_slash1.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_slash2.wav")) return FMRES_SUPERCEDE
			
			if(equal(sample,"weapons/knife_deploy1.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hitwall1.wav")) return FMRES_SUPERCEDE
			
			if(equal(sample,"weapons/knife_hit1.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hit2.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hit3.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hit4.wav")) return FMRES_SUPERCEDE
			
			if(equal(sample,"weapons/knife_stab.wav")) return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public cmdHelp(id) {
	new jpmotd[2048], title[64], dpos = 0
	format(title,63,"AMX %s v%s",PLUGINNAME,VERSION)
	
	new limit[32]
	if(get_cvar_num("jp_limit") == 0)
		limit = "unlimited"
	else
		format(limit,31,"%d",get_cvar_num("jp_limit"))
	
	dpos += format(jpmotd[dpos],2047-dpos,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body>")
	dpos += format(jpmotd[dpos],2047-dpos,"<b>%s</b>^n^n",title)
	dpos += format(jpmotd[dpos],2047-dpos,"%-20s <b>%s</b>^n","Jetpack:",get_cvar_num("jp_active") ? "active" : "inactive")
	dpos += format(jpmotd[dpos],2047-dpos,"%-20s <b>%s</b>^n","Arena:",get_cvar_num("jp_arena") ? "<b>enabled!</b>" : "disabled")
	dpos += format(jpmotd[dpos],2047-dpos,"%-20s %s^n","Command:","buyjet")
	dpos += format(jpmotd[dpos],2047-dpos,"%-20s %d$^n","Cost:",get_cvar_num("jp_cost"))
	dpos += format(jpmotd[dpos],2047-dpos,"%-20s %s^n","Noweapons:",get_cvar_num("jp_noweapons") ? "on" : "off")
	dpos += format(jpmotd[dpos],2047-dpos,"%-20s %s^n^n","Limit (for Team):",limit)
	
	dpos += format(jpmotd[dpos],2047-dpos,"=============^n")
	dpos += format(jpmotd[dpos],2047-dpos,"How to use:^n")
	if(get_cvar_num("jp_arena") == 1)
		dpos += format(jpmotd[dpos],2047-dpos,"-You get free a jetpack every new round^n")
	else
		dpos += format(jpmotd[dpos],2047-dpos,"-Buy a new Jetpack (Type ^"buyjet^" in console) if you haven't already one^n")
	dpos += format(jpmotd[dpos],2047-dpos,"-Press 3 (knife) to use the Jetpack^n")
	dpos += format(jpmotd[dpos],2047-dpos,"-Use it with attack1 (where you shoot)^n")
	dpos += format(jpmotd[dpos],2047-dpos,"-Shoot rockets with attack2 (where's alternate shoot)^n^n")
	dpos += format(jpmotd[dpos],2047-dpos,"-Have Fun!^n^n")
	
	if(get_user_flags(id) & ADMIN_CVAR) {
		dpos += format(jpmotd[dpos],2047-dpos,"=============^n")
		dpos += format(jpmotd[dpos],2047-dpos,"CVAR's:^n")
		dpos += format(jpmotd[dpos],2047-dpos,"jp_active %d - Enable/Disable Jetpack^n",get_cvar_num("jp_active"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_arena %d - Everyone gets a free jetpack every new round^n",get_cvar_num("jp_arena"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_admin_only %d - Only admins can buy a Jetpack^n",get_cvar_num("jp_admin_only"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_cost %d - Cost of a Jetpack^n",get_cvar_num("jp_cost"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_noweapons %d - turns no weapons on/off^n",get_cvar_num("jp_noweapons"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_limit %d - Sets a limit of jetpacks for each team [0 = unl.]^n^n",get_cvar_num("jp_limit"))
		
		dpos += format(jpmotd[dpos],2047-dpos,"jp_speed %d - Speed of a Jetpack^n",get_cvar_num("jp_speed"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_rocket_delay %.0f - how long you got to wait to shoot the next rocket^n",get_cvar_float("jp_rocket_delay"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_rocket_speed %d - The speed of a Jetpack Rocket^n",get_cvar_num("jp_rocket_speed"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_rocket_damage %d - Damage of a Jetpack rocket (damage in the center of explosion)^n",get_cvar_num("jp_rocket_damage"))
		dpos += format(jpmotd[dpos],2047-dpos,"jp_damage_radius %d - The radius of a rocket explosion.^n",get_cvar_num("jp_damage_radius"))
	}
	
	show_motd(id,jpmotd,title)
}

public cmdVote(id,level,cid) {
	if(!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
	
	new keys = (1<<0|1<<1)
	for(new i = 0; i < 2; i++)
		vote_count[i] = 0
	
	new menu[256]
	new len = format(menu,255,"\r[AMX] %s Jetpack?\w^n",get_cvar_num("jp_active") ? "disable" : "enable")
	len += format(menu[len],255-len,"^n1. Yes")
	len += format(menu[len],255-len,"^n2. No")
	
	show_menu(0,keys,menu,10)
	set_task(10.0,"vote_results",4561)
	return PLUGIN_HANDLED
}

public voteJetpack(id, key) {
	vote_count[key]++
}

public vote_results() {
	if(vote_count[0] > vote_count[1]) {
		client_print(0,print_chat,"[JP] Voting successfully (yes ^"%d^") (no ^"%d^") Jetpack is now %s",vote_count[0],vote_count[1],get_cvar_num("jp_active") ? "disabled" : "enabled")
		set_cvar_num("jp_active",get_cvar_num("jp_active") ? 0 : 1)
	}else{
		client_print(0,print_chat,"[JP] Voting failed (yes ^"%d^") (no ^"%d^")",vote_count[0],vote_count[1])
	}
}

public player_die() {
	if(get_cvar_num("jp_active")) {
		new id = read_data(2)
		if(hasjet[id]) {
			drop_jetpack(id)
			hasjet[id] = 0
		}
	}
	return PLUGIN_CONTINUE
}

public cmdDrop(id) {
	if(get_cvar_num("jp_active") == 1) {
		if(hasjet[id]) {
			new clip,ammo
			new weapon = get_user_weapon(id,clip,ammo)
			if(weapon == HLW_KNIFE || 
			weapon == HLW_CROWBAR || weapon == DODW_SPADE) {
				drop_jetpack(id)
				
				entity_set_string(id,EV_SZ_viewmodel,"models/v_knife.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/p_knife.mdl")
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

public drop_jetpack(id) {
	if(hasjet[id]) {
		new Float:Aim[3],Float:origin[3]
		VelocityByAim(id, 64, Aim)
		entity_get_vector(id,EV_VEC_origin,origin)
		
		origin[0] += Aim[0]
		origin[1] += Aim[1]
		
		new jetpack = create_entity("info_target")
		entity_set_string(jetpack,EV_SZ_classname,"jp_jetpack")
		//entity_set_model(jetpack,"models/w_egon.mdl")
		entity_set_model(jetpack,"models/w_oxygen.mdl")
		
		entity_set_size(jetpack,Float:{-16.0,-16.0,-16.0},Float:{16.0,16.0,16.0})
		entity_set_int(jetpack,EV_INT_solid,1)
		
		entity_set_int(jetpack,EV_INT_movetype,6)
		
		entity_set_vector(jetpack,EV_VEC_origin,origin)
		hasjet[id] = 0
	}	
}

public pfn_touch(ptr, ptd) {
	if(is_valid_ent(ptr)) {
		new classname[32]
		entity_get_string(ptr,EV_SZ_classname,classname,31)
		
		if(equal(classname, "jp_jetpack")) {
			if(is_valid_ent(ptd)) {
				new id = ptd
				if(id > 0 && id < 34) {
					if(!hasjet[id] && is_user_alive(id)) {
						if(get_cvar_num("jp_limit") != 0) {
							new count = 0
							for(new i = 1; i < 33; i++) {
								if(get_user_team(id) == get_user_team(i)) {
									if(hasjet[id]) ++count
								}
							}
							if(count >= get_cvar_num("jp_limit")) {
								client_print(id,print_center,"[JP] Sorry, Limit of Jetpacks for each team is '%d'",get_cvar_num("jp_limit"))
								return PLUGIN_CONTINUE
							}
						}
						hasjet[id] = 1
						client_cmd(id,"spk items/gunpickup2.wav")
						engclient_cmd(id,"weapon_knife")
						switchmodel(id)
						remove_entity(ptr)
					}
				}
			}
		}else if(equal(classname, "jp_rocket")) {
			new Float:fOrigin[3]
			new iOrigin[3]
			entity_get_vector(ptr, EV_VEC_origin, fOrigin)
			FVecIVec(fOrigin,iOrigin)
			jp_radius_damage(ptr)
				
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_EXPLOSION)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_short(explosion)
			write_byte(30)
			write_byte(15)
			write_byte(0)
			message_end()
				
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_BEAMCYLINDER)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2]+200)
			write_short(white)
			write_byte(0)
			write_byte(1)
			write_byte(6)
			write_byte(8)
			write_byte(1)
			write_byte(255)
			write_byte(255)
			write_byte(192)
			write_byte(128)
			write_byte(5)
			message_end()
			
			if(is_valid_ent(ptd)) {
				new classname2[32]
				entity_get_string(ptd,EV_SZ_classname,classname2,31)
				
				if(equal(classname2,"func_breakable"))
					force_use(ptr,ptd)
			}
			
			remove_entity(ptr)
		}
	}
	return PLUGIN_CONTINUE
}

stock jp_radius_damage(entity) {
	new id = entity_get_edict(entity,EV_ENT_owner)
	for(new i = 1; i < 33; i++) {
		if(is_user_alive(i)) {
			new dist = floatround(entity_range(entity,i))
			
			if(dist <= get_cvar_num("jp_damage_radius")) {
				new hp = get_user_health(i)
				new Float:damage = get_cvar_float("jp_rocket_damage")-(get_cvar_float("jp_rocket_damage")/get_cvar_float("jp_damage_radius"))*float(dist)
				
				new Origin[3]
				get_user_origin(i,Origin)
				
				if(!get_cvar_num("mp_friendlyfire")) {
					if(get_user_team(id) != get_user_team(i)) {
						if(hp > damage)
							jp_take_damage(i,floatround(damage),Origin,DMG_BLAST)
						else
							log_kill(id,i,"Jetpack Rocket",0)
					}
				}else{
					if(hp > damage)
						jp_take_damage(i,floatround(damage),Origin,DMG_BLAST)
					else
						log_kill(id,i,"Jetpack Rocket",0)
				}
			}
		}
	}
}

stock log_kill(killer, victim, weapon[],headshot) {
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	user_kill(victim,1)
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
	
	message_begin(MSG_ALL, get_user_msgid("DeathMsg"), {0,0,0}, 0)
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()
	
	if(get_user_team(killer)!=get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) +1)
	if(get_user_team(killer)==get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) -1)
		
	new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10]

	get_user_name(killer, kname, 31)
	get_user_team(killer, kteam, 9)
	get_user_authid(killer, kauthid, 31)
 
	get_user_name(victim, vname, 31)
	get_user_team(victim, vteam, 9)
	get_user_authid(victim, vauthid, 31)
		
	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
	kname, get_user_userid(killer), kauthid, kteam, 
 	vname, get_user_userid(victim), vauthid, vteam, weapon)

 	return PLUGIN_CONTINUE
}

stock jp_take_damage(victim,damage,origin[3],bit) {
	message_begin(MSG_ALL,get_user_msgid("Damage"),{0,0,0},victim)
	write_byte(21)
	write_byte(20)
	write_long(bit)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	message_end()
	
	set_user_health(victim,get_user_health(victim)-damage)
}
