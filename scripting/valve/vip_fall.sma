#include <amxmodx>
#include <amxmisc>
#include <engine>
//#define cstrike
//#tryinclude <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define fNULL 0.0
#define charsmin -1

#define PLUGIN  "VIP-Fall-Guide"
#define VERSION "11-16-2021"
#define AUTHOR  "SPiNX"

#define VIP_FLAG ADMIN_LEVEL_H

new g_fall_dam, g_cvar_shake_iDelay
new bool:g_bis_fallen[ MAX_PLAYERS + 1]
new bool: b_Bot[MAX_PLAYERS+1]

public plugin_init()
{
    RegisterHam(Ham_TakeDamage, "player", "Fw_Damage")
    RegisterHam(Ham_Killed, "player", "check_fall");
    RegisterHam(Ham_Spawn, "player", "client_spawn", 1);
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_EmitSound, "fwd_EmitSound", true)
    g_fall_dam = register_cvar("vip_fall_damage", "0")
    g_cvar_shake_iDelay = register_cvar("vip_fall_damage_shake", "2.5");
}

public check_fall(victim)
{
    //new origin[3];
    /*Make it look like through the ground to hell*/
    if(is_user_connected(victim))
    {
        if(g_bis_fallen[victim])
        {
            if(!task_exists(victim))
            {
                //get_user_origin(victim,origin,0)
                //set_task(2.0,"@bury",victim,origin,charsmax(origin))
                console_cmd(victim, "default_fov 150")
                set_view(victim, CAMERA_3RDPERSON);
                set_task(0.5,"@bury",victim)
            }
        }
    }
}

public client_putinserver(id)
{
    //Some mods spawn (death) field-of-view.
    if(is_user_connected(id))
    {
        b_Bot[id] = is_user_bot(id) ? true : false
        if(!b_Bot[id] && !is_user_hltv(id))
        set_task(0.5,"client_spawn",id);
    }
}


public client_disconnected(id)
{
    console_cmd(id, "default_fov 100");
    if(task_exists(id))
        remove_task(id);
}
public client_spawn(id)
{
    /*if(is_user_bot(id) || is_user_hltv(id) )
        return PLUGIN_HANDLED_MAIN;*/

    if(!b_Bot[id] && is_user_alive(id))
    {
        g_bis_fallen[id] = false
        set_view(id, CAMERA_NONE);
        console_cmd(id, "default_fov 100");
    }

    return PLUGIN_CONTINUE;
}

public Fw_Damage(victim, inflictor, attacker, Float:damage, dmgbits)
{
    //if(attacker == 0 && is_user_connected(victim))
    if(is_user_connected(victim) && !b_Bot[victim])
    {
        if(dmgbits == DMG_FALL /*&& is_user_alive(victim)*/)
        {
            @shake(victim) //more realistic
            g_bis_fallen[victim] = true

            if(damage && !get_pcvar_num(g_fall_dam))
            {
                if(is_vip(victim))
                {
                    //client_print victim, print_chat, "%n fell with %s ", victim, PLUGIN
                    #define DAMAGE 4
                    SetHamParamFloat(DAMAGE,fNULL)

                    return HAM_SUPERCEDE
                }

            }
            else return HAM_IGNORED

        }
        else g_bis_fallen[victim] = false
        return HAM_HANDLED
    }
    return HAM_HANDLED
}

//Block fall sound
public fwd_EmitSound(entity, channel, const sample[])
{
    new const path[] = "player/pl_fallpain3.wav"
    new const splat[]="common/bodysplat.wav"
    //server_print "%s",sample
    //server_print "fwd_EmitSound ticking" //ok running
    if(is_user_connected(entity) && !get_pcvar_num(g_fall_dam))
    {
        //server_print "fwd_EmitSound %n is alive!!",entity
        if(is_vip(entity) && !b_Bot[entity])
        {
            //server_print "is a vip %n",entity
            //server_print "%s",path
            if(g_bis_fallen[entity]  && equali(sample,"common/bodysplat.wav"))
            if(equali(sample, path))
            {
                server_print "is %s",sample
                @bury(entity)
                return FMRES_SUPERCEDE
            }


        }
        if(equali(sample, splat) && !is_user_alive(entity) && !g_bis_fallen[entity])
            client_print 0, print_chat, "%n turned to mush!", entity
    }
    return FMRES_IGNORED
}
//Brain ajar from hitting ground
@bury( victim, {Float,_}:... )
if(is_user_connected(victim))
{
    client_print 0, print_chat, "%n must have fallen or something.", victim

    if(b_Bot[victim])
        return

    new origin[3];
    get_user_origin(victim,origin,0)

    ///client_cmd(victim, "spk holo/tr_holo_fallshort.wav")

    message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY, _, victim);
    write_byte(TE_FIREFIELD);
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2] +67)
    write_short(200); //write_short(radius) (fire is made in a square around origin. -radius, -radius to radius, radius)
    write_short(victim); //write_short(modelindex)
    write_byte(10); //write_byte(count)
    write_byte(2); //write_byte(flags)
    write_byte(30); //write_byte(duration (in seconds) * 10) (will be randomized a bit)
    message_end();
}
//Shock impact effect
@shake(victim)
if(is_user_connected(victim) && !b_Bot[victim])
{
    emessage_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenShake"),{0,0,0},victim)
    ewrite_short(25000) //amp
    ewrite_short(get_pcvar_num(g_cvar_shake_iDelay) * 4096) //dur //4096 is~1sec
    ewrite_short(30000) //freq
    emessage_end()
}

#if AMXX_VERSION_NUM == 182
public plugin_precache()
{
    precache_model("models/rpgrocket.mdl")
}
#endif

#if defined CSTRIKE
stock is_vip(victim)

    return cstrike_running() ? cs_get_user_vip(victim) | get_user_flags(victim) & VIP_FLAG
    : get_user_flags(victim) & VIP_FLAG
#else
stock is_vip(victim)return is_user_alive(victim) && get_user_flags(victim) & VIP_FLAG
#endif
/*Do not edit this line! 01010011 01010000 01101001 01001110 01011000*/
