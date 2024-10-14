/*
 * Portions of this code were by CheesyPeteza & JHHG.
 *
 * Debugging/upkeep by spinx 2019.
 *
 * Testing by KleinMarquez <https://forums.alliedmods.net/member.php?u=271067>
 *
 * If you would like bunny jumping without everything else
 * go here:
 *
 * https://forums.alliedmods.net/showthread.php?t=1262
 *
 * Changelog.
 * *********
 *  **1.1***
 * Hostage follow bug fix.
 * Run-time errors resolved: When T moved hostage and when T started a vehicle.
 * Slowed down the plant from run to walk.
 * Brought speed back when holding a knife.
 * **1.2***
 * Customized plugin name and removed pause code.
 * **1.3***
 * Optimized knife speed.
 * Todo:
 * Provide your ideas!
 * https://forums.alliedmods.net/showthread.php?t=5723
 **/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
//#include <fun>
#include <cstrike>
#include <amxmisc>
#define MAXHOSSIEDISTANCE       80.0 // This isn't really used anymore. Plugin should now make use of the real max distance player <> hostage.

new bool:movespeed, bool:bIsBot[MAX_PLAYERS + 1], bool:bEnabled
new XiNopunch, XiHostageP, XiFreeze, XiHostageUse, XiWalk, XiEnable, XiJump, XiUsage,g_MAXPLAYERS, g_Speed, g_beta_think;
new g_hostage_speed

public plugin_init()
{
    register_message(get_user_msgid("HudText"),"hook_hudtext")
    register_event("CurWeapon","hook_curweapon","bef","1=1","1=3","1=5", "1=7","1=8","1=10","1=11","1=12", "1=13", "1=14", "1=15", "1=16", "1=17", "1=18", "1=19", "1=20", "1=21","1=22", "1=23", "1=24", "1=26", "1=27","1=28", "1=30" )
    register_plugin("Counter-Strike Beta","1.31","SPiNX/ts2do") //continuation from cs13 by ts2do
    register_event("ResetHUD","ResetHUD","bc")

    XiHostageP = register_cvar("hostage_push", "1")
    XiHostageUse =register_cvar("hostage_use", "1")
    XiWalk =register_cvar("c4_walk", "1")
    XiNopunch = register_cvar("no_punch", "1")

    register_cvar("sbhopper_version", "1.2", FCVAR_SERVER)

    XiEnable = register_cvar("bh_enabled", "1")
    XiJump = register_cvar("bh_autojump", "1")
    XiUsage = register_cvar("bh_showusage", "1")
    XiFreeze = get_cvar_pointer("mp_freezetime")

    register_touch("player","hostage_entity","hostage_push")
    register_touch("player","monster_scientist","hostage_push")

    ///register_forward(FM_EmitSound, "forward_emitsound", true)
    register_message(get_user_msgid("HudTextArgs"), "hook_hudtext")
    g_Speed = get_cvar_pointer("sv_maxspeed")
    set_pcvar_float(g_Speed, 450.0)
    g_MAXPLAYERS = get_maxplayers()
}

public forward_emitsound(const SPINX, const Onceuponatimetherewasaverysmall, noise[], const Float:codetheftmadeoutinamxxland, const Float:afterthatthesmalltheftgot, const veryveryverybig, const theend)
{
    if (SPINX < 1)
        return FMRES_IGNORED
    else if (SPINX >= 1 && SPINX <= g_MAXPLAYERS)
    {
        if (equal(noise, "common/wpn_select.wav"))
        return client_use(SPINX)
        return FMRES_IGNORED
    }
    return FMRES_IGNORED
}

client_use(id)
{
    if(get_pcvar_num(XiHostageUse))
    {
        if(is_user_alive(id))
        {
            static hitEnt, bodyPart, Float:distance
            distance = get_user_aiming(id, hitEnt, bodyPart)
            if (hitEnt == 0 || distance > MAXHOSSIEDISTANCE)
                return FMRES_IGNORED

            // Do different stuff depending on the entity in aim.
            static classname[MAX_NAME_LENGTH]
            entity_get_string(hitEnt, EV_SZ_classname, classname, charsmax(classname))
            if (equal(classname, "hostage_entity"))
            {
                return UsingHostage(id, hitEnt)
            }
        }
    }
    return FMRES_IGNORED
}

UsingHostage(id, hitEnt)
{
    if(is_user_alive(id))
    {
        cs_get_hostage_foll(hitEnt) != id ? cs_set_hostage_foll(hitEnt, id) : cs_set_hostage_foll(hitEnt, 0);
    }
    return FMRES_IGNORED
}

public hook_hudtext()
{
    if (get_msg_args() < 1 || get_msg_argtype(1) != ARG_STRING)
        return PLUGIN_CONTINUE

    new buffer[128]
    get_msg_arg_string(1, buffer, charsmax(buffer))

    if (equal(buffer, "#Only_CT_Can_Move_Hostages")) // supercede this message
        return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public hook_curweapon(id)
{
    if(get_pcvar_num(XiNopunch))
    {
        if(is_user_alive(id))
        {
            static Float:fPunch[3];
            fPunch[0] = random_float(-0.1,0.1);
            fPunch[1] = random_float(-0.1,0.1);
            fPunch[2] = random_float(-0.1,0.1);
            entity_set_vector (id,EV_VEC_punchangle,fPunch);
        }
    }
}


public ResetHUD()
{
    if(get_pcvar_num(XiWalk))
    {
        movespeed=false
        new Float:FreezeTime = get_pcvar_float(XiFreeze)
        FreezeTime?set_task(FreezeTime,"bombSpeed"):bombSpeed()
    }
    else
    {
        movespeed=false
    }
}

public bombSpeed()
{
    movespeed=true
}
public cs_beta_think(id)
{
    if(is_user_alive(id))
    {
        set_pev(id, pev_maxspeed, get_user_weapon(id) == CSW_KNIFE ? 450.0 : 272.0)
        if(pev_valid(g_hostage_speed)>1)
        {
            set_pev(g_hostage_speed, pev_speed, 650.0)
            set_pev(g_hostage_speed, pev_maxspeed, 700.0)
        }
        static buttons; buttons = get_user_button ( id )
        if(movespeed)
        {
            if(buttons&IN_ATTACK)
            {
                static temp[2]
                if(get_user_weapon(id,temp[0],temp[1])==CSW_C4)
                {
                    set_pev(id, pev_maxspeed, 115.0)
                }
                if(get_user_weapon(id,temp[0],temp[1])!=CSW_C4)
                {
                    set_pev(id, pev_maxspeed, 272.0)
                }
            }
        }
        if(get_pcvar_num(XiEnable))// Disable slow down after jumping
        {
            entity_set_float(id, EV_FL_fuser2, 0.0)
        }
        if(get_pcvar_num(XiJump))
        {
            if (buttons & IN_JUMP)// If holding jump
            {
                new flags = entity_get_int(id, EV_INT_flags)
                if(flags|FL_WATERJUMP&&entity_get_int(id,EV_INT_waterlevel)<2&&flags&FL_ONGROUND)
                {
                    new Float:velocity[3]
                    entity_get_vector(id, EV_VEC_velocity, velocity)
                    velocity[2] += 250.0
                    entity_set_vector(id, EV_VEC_velocity, velocity)
                    entity_set_int(id, EV_INT_gaitsequence, 6)  // Play the Jump Animation
                }
            }
        }
    }
    return PLUGIN_HANDLED
}

public is_hostage(id)
{
    if(pev_valid(id))
    {
        static szClassname[MAX_NAME_LENGTH]
        entity_get_string(id,EV_SZ_classname,szClassname,charsmax(szClassname))
        return (equali(szClassname,"monster_scientist")||
        equali(szClassname,"hostage_entity"))
    }
    return 0
}

public hostage_push ( ptr, ptd )
{
    if(get_pcvar_num(XiHostageP))
    {
        if(is_user_alive(ptr))
        {
            if( is_hostage ( ptd ) )
            {
                g_hostage_speed = ptd
                if ( get_user_team ( ptr ) == 1)
                {
                    static Float:origin[2][3]
                    entity_get_vector ( ptr, EV_VEC_origin, origin[0] )
                    entity_get_vector ( ptd, EV_VEC_origin, origin[1] )
                    new x
                    for ( x = 0;x <= 2;x++ )
                    {
                        origin[1][x] -= origin[0][x]
                        origin[1][x] *= 6
                    }
                    entity_set_vector ( ptd, EV_VEC_velocity, origin[1] )
                }
            }
        }
    }
}

public client_authorized(id, const authid[])
{
    bIsBot[id] = equal(authid, "BOT") ? true : false
}

public client_putinserver(id)
{
    if(!bIsBot[id])
    {
        set_task(30.0, "showUsage", id)
    }
    if(!bEnabled)
    {
        bEnabled = true
        g_beta_think = register_forward(FM_PlayerPreThink, "cs_beta_think", true)
        server_print "Enabling cs_beta..."
    }
}

public client_disconnected(id)
{
    if(!get_playersnum())
    {
        unregister_forward(FM_PlayerPreThink, g_beta_think, true)
        bEnabled = false
    }
}
public showUsage(id)
{
    if(get_pcvar_num(XiEnable) && get_pcvar_num(XiUsage))
    if(is_user_connected(id))
    {
        client_print(id, print_chat, get_pcvar_num(XiJump) ?
            "[AMX] Auto bunny hopping is enabled on this server. Just hold down jump to bunny hop.":
            "[AMX] Bunny hopping is enabled on this server. You will not slow down after jumping.")
    }
    return PLUGIN_HANDLED
}
