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

/* Flying Crowbar for Half-Life DeathMatch
     by GordonFreeman and Gauss
     Bugfix/compatibility and more feats by SPiNX
*/

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <gearbox>
#include <xs>

#define CROW "fly_pipewrench"

//precache
static blood_drop, blood_spray,trail;

static m_pPlayer,m_flNextSecondaryAttack;
static pipewrench_render,damage_pipewrench,pipewrench_speed,pipewrench_trail,pipewrench_lifetime;

const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;

new const SzClass[][] =
{
    "func_breakable", "func_button", "momentary_door",
    "func_healthcharger", "func_recharge",
    "func_door", "func_door_rotating",
    "func_wall","func_wall_toggle",
    "func_pushable", "momentary_door", "monster_tentacle"
};

@bar_brk_touch(iAttacker, iVictim)
{
    static iAttackerOwner, szClass[MAX_NAME_LENGTH];
    if(pev_valid(iAttacker))
    {
        pev(iVictim, pev_classname, szClass, charsmax(szClass))

        if(is_user_alive(iAttacker))
        {
            if(get_user_weapon(iAttacker) != HLW_CROWBAR || get_user_weapon(iAttacker) != HLW_KNIFE || get_user_weapon(iAttacker) != HLW_PIPEWRENCH)
                return PLUGIN_HANDLED;
        }

        if(pev_valid(iAttacker>1) && !is_user_connected(iAttacker))
        {
            set_pev(iVictim, pev_takedamage, DAMAGE_AIM)
            iAttackerOwner = pev(iAttacker, pev_owner)
        }
        if(pev_valid(iVictim>1) && !is_user_connected(iVictim))
        {
            fm_set_kvd(iVictim, "explodemagnitude", "1")
            set_pev(iVictim, pev_health, 1.0)
            set_pev(iVictim, pev_takedamage, DAMAGE_AIM)
            fakedamage(iVictim, "Amxx_Alterations", 1.0, DMG_CRUSH)
        }
        if(is_user_connected(iAttackerOwner))
        {
            replace(szClass, charsmax(szClass), "func_", "")
            client_print 0, print_center, "%n took out a %s", iAttackerOwner, szClass
        }

    }
    return PLUGIN_HANDLED;
}
public plugin_init() {
    register_plugin("Flying Crowbar","0.4","SPiNX") //Below 0.4 developed by GordonFreeman//Gauss/

    /*Changelog
     * Jan 23rd 2024 SPiNX:::0.3 - 0.4 Stabilize
     */

    register_message(get_user_msgid("DeathMsg"),"DeathMsg")

    RegisterHam(Ham_Weapon_SecondaryAttack,"weapon_pipewrench","fw_CrowbarSecondaryAttack")
    RegisterHam(Ham_Item_AddToPlayer,"weapon_pipewrench","fw_CrowbarItemAdd")
    RegisterHam(Ham_Item_AddDuplicate,"weapon_pipewrench","fw_CrowbarItemAdd")

    register_think(CROW,"FlyCrowbar_Think")
    for(new list; list < sizeof SzClass; list++)
    register_touch(CROW, SzClass[list], "@bar_brk_touch");
    register_touch(CROW,"*","FlyCrowbar_Touch")

    pipewrench_lifetime = register_cvar("fly_pipewrench_time","15.0")
    pipewrench_speed = register_cvar("fly_pipewrench_speed","1300")
    pipewrench_render = register_cvar("fly_pipewrench_render","1")
    pipewrench_trail = register_cvar("fly_pipewrench_trail","1")
    damage_pipewrench = register_cvar("fly_pipewrench_damage","240.0")
    //Support both Windows and Linux this way.
    m_pPlayer = (find_ent_data_info("CBasePlayerItem", "m_pPlayer") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    m_flNextSecondaryAttack = (find_ent_data_info("CBasePlayerWeapon", "m_flNextSecondaryAttack") /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    
}

public plugin_precache(){
    blood_drop = precache_model("sprites/blood.spr")
    blood_spray = precache_model("sprites/bloodspray.spr")
    trail = precache_model("sprites/zbeam3.spr")
}

//Çàìåíà ñîîáùåíèÿ îá óáèéñòâå, ÷òî îíî ïðîèçîøëî èìåííî ìîíòèðîâêîé
public DeathMsg()
{
    static sWeapon[20]
    get_msg_arg_string(3,sWeapon,19)
    if(equal(sWeapon,CROW))
        set_msg_arg_string(3,"pipewrench")
}

//Âòîðè÷íàÿ àòàêà äëÿ ëîìà
public fw_CrowbarSecondaryAttack(ent)
{
    if(pev_valid(ent))
    {
        new id = get_pdata_cbase(ent,m_pPlayer,LINUX_OFFSET_WEAPONS)
        if(is_user_connected(id))
        {    
            if(!FlyCrowbar_Spawn(id))
                return HAM_IGNORED
        
            set_pdata_float(ent,m_flNextSecondaryAttack,0.5,LINUX_OFFSET_WEAPONS)
            ExecuteHam(Ham_RemovePlayerItem,id,ent)
            user_has_weapon(id,HLW_PIPEWRENCH,0)
            ExecuteHamB(Ham_Item_Kill,ent)
        }
    }
    return HAM_IGNORED
}

//Îòëîâ ñòîëêíîâåíèé ëåòÿùåãî ëîìà ñ äðóãèìè îáúåêòàìè
public FlyCrowbar_Touch(toucher,touched){
    new Float:origin[3],Float:angles[3]
    pev(toucher,pev_origin,origin)
    pev(toucher,pev_angles,angles)

    if(!is_user_connected(touched)){
        emit_sound(toucher,CHAN_WEAPON,"weapons/cbar_hit1.wav",0.9,ATTN_NORM,0,PITCH_NORM)

        engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
        write_byte(TE_SPARKS)
        engfunc(EngFunc_WriteCoord,origin[0])
        engfunc(EngFunc_WriteCoord,origin[1])
        engfunc(EngFunc_WriteCoord,origin[2])
        message_end()
    }else{
        ExecuteHamB(Ham_TakeDamage,touched,toucher,pev(toucher,pev_owner),get_pcvar_float(damage_pipewrench),DMG_CLUB)
        emit_sound(toucher,CHAN_WEAPON,"weapons/cbar_hitbod1.wav",0.9,ATTN_NORM,0,PITCH_NORM)

        engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
        write_byte(TE_BLOODSPRITE)
        engfunc(EngFunc_WriteCoord,origin[0]+random_num(-20,20))
        engfunc(EngFunc_WriteCoord,origin[1]+random_num(-20,20))
        engfunc(EngFunc_WriteCoord,origin[2]+random_num(-20,20))
        write_short(blood_spray)
        write_short(blood_drop)
        write_byte(248) // color index
        write_byte(15) // size
        message_end()
    }

    engfunc(EngFunc_RemoveEntity,toucher)// Óíè÷òîæèòü

    new crow = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"weapon_pipewrench"))

    DispatchSpawn(crow)
    set_pev(crow,pev_spawnflags,SF_NORESPAWN)

    angles[0] = 0.0
    angles[2] = 0.0

    set_pev(crow,pev_origin,origin)
    set_pev(crow,pev_angles,angles)

    if(get_pcvar_num(pipewrench_render))
        fm_set_rendering(crow, kRenderFxGlowShell,55+random(200),55+random(200),55+random(200),kRenderNormal)

    set_task(get_pcvar_float(pipewrench_lifetime),"Crowbar_Think",crow)
}

public Crowbar_Think(ent)
    if(pev_valid(ent))
        engfunc(EngFunc_RemoveEntity,ent)   // ÇÄÎÕÍÈ!!!!

public fw_CrowbarItemAdd(ent,id)
    remove_task(ent)

//Êèäàåì ëîì
public FlyCrowbar_Spawn(id){
    new pipewrench = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))

    if(!pev_valid(pipewrench))
        return 0

    set_pev(pipewrench,pev_classname,CROW)
    engfunc(EngFunc_SetModel,pipewrench,"models/w_pipe_wrench.mdl")
    engfunc(EngFunc_SetSize,pipewrench,Float:{-4.0, -4.0, -4.0} , Float:{4.0, 4.0, 4.0})

    new Float:vec[3]
    get_projective_pos(id,vec)
    engfunc(EngFunc_SetOrigin,pipewrench,vec)


    pev(id,pev_v_angle,vec)
    vec[0] = 90.0
    vec[2] = floatadd(vec[2],-90.0)

    set_pev(pipewrench,pev_owner,id)
    set_pev(pipewrench,pev_angles,vec)

    velocity_by_aim(id,get_pcvar_num(pipewrench_speed)+get_speed(id),vec)
    set_pev(pipewrench,pev_velocity,vec)

    set_pev(pipewrench,pev_nextthink,get_gametime()+0.1)

    DispatchSpawn(pipewrench)

    if(get_pcvar_num(pipewrench_trail)){
        message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
        write_byte(TE_BEAMFOLLOW)
        write_short(pipewrench)
        write_short(trail)
        write_byte(15)
        write_byte(2)
        write_byte(55+random(200))
        write_byte(55+random(200))
        write_byte(55+random(200))
        write_byte(255)
        message_end()
    }

    set_pev(pipewrench,pev_movetype,MOVETYPE_TOSS)
    set_pev(pipewrench,pev_solid,SOLID_BBOX)

    emit_sound(id,CHAN_WEAPON,"weapons/cbar_miss1.wav",0.9,ATTN_NORM,0,PITCH_NORM)
    set_task(0.1,"FlyCrowbar_Whizz",pipewrench)

    return pipewrench
}

//Ëîì âåðòèòñÿ â ïîë¸òå
public FlyCrowbar_Think(ent){
    new Float:vec[3]
    pev(ent,pev_angles,vec)
    vec[0] = floatadd(vec[0],-15.0)
    set_pev(ent,pev_angles,vec)

    set_pev(ent,pev_nextthink,get_gametime()+0.01)
}

//Çâóêè îò ëåòÿùåãî ëîìà
public FlyCrowbar_Whizz(pipewrench){
    if(pev_valid(pipewrench)){
        emit_sound(pipewrench,CHAN_WEAPON,"weapons/cbar_miss1.wav",0.9,ATTN_NORM,0,PITCH_NORM)

        set_task(0.2,"FlyCrowbar_Whizz",pipewrench)
    }
}

//Âû÷èñëåíèå ïîçèöèè ïîÿâëåíèÿ ëîìà
get_projective_pos(player,Float:oridjin[3]){
    new Float:v_forward[3]
    new Float:v_right[3]
    new Float:v_up[3]

    GetGunPosition(player,oridjin)

    global_get(glb_v_forward,v_forward)
    global_get(glb_v_right,v_right)
    global_get(glb_v_up,v_up)

    xs_vec_mul_scalar(v_forward,6.0,v_forward)
    xs_vec_mul_scalar(v_right,2.0,v_right)
    xs_vec_mul_scalar(v_up,-2.0,v_up)

    xs_vec_add(oridjin,v_forward,oridjin)
    xs_vec_add(oridjin,v_right,oridjin)
    xs_vec_add(oridjin,v_up,oridjin)
}

//Ïîëó÷èòü ïîëîæåíèå îðóæèÿ
stock GetGunPosition(const player,Float:origin[3]){
    new Float:viewOfs[3]

    pev(player,pev_origin,origin)
    pev(player,pev_view_ofs,viewOfs)

    xs_vec_add(origin,viewOfs,origin)
}

/* all non-English comments made by Gauss */
