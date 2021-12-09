#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <engine_stocks>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

new g_Trail, g_protecton
new g_shell, g_time, g_msg
new HamHook:XhookDamage_spawn
new spawn_sync_msg
new g_spawn_time[MAX_PLAYERS]

public plugin_init()
{
    register_plugin("Spawn Protection", "8.2", "SPiNX|Peli") // Peli maintained up until 7.0. Profile:https://forums.alliedmods.net/member.php?u=86
    //Peli's plugin https://forums.alliedmods.net/showthread.php?t=1886
    
    register_concmd("amx_spawn_time", "cmd_sptime", ADMIN_CVAR, "1 through 10 to set Spawn Protection time") // Concmd (Console Command) for the CVAR time
    register_concmd("amx_spawn_msg", "cmd_spmessage", ADMIN_CVAR, "1 = Turn Spawn Protection Message on , 0 = Turn Spawn Protection message off") // Concmd for the CVAR message
    register_concmd("amx_spawn_shell", "cmd_spshellthickness", ADMIN_CVAR, "1 through 100 to set Glow Shellthickness") // Concmd for the shellthickness
    
    g_protecton  = register_cvar("sv_sp", "1"); // Cvar (Command Variable) for the plugin on/off
    g_time       = register_cvar("sv_sptime", "7") // Cvar for controlling the message time (1-10 seconds)
    g_msg        = register_cvar("sv_spmessage", "1") // Cvar for controlling the message on/off
    g_shell      = register_cvar("sv_spshellthick", "75") // Cvar for controlling the glow shell thickness
    
    RegisterHam(Ham_Spawn, "player", "sp_on", 1);
    XhookDamage_spawn = RegisterHam(Ham_TakeDamage, "player", "Event_Damage", 1)
    spawn_sync_msg   = CreateHudSyncObj( )
}

public plugin_precache()
{
    g_Trail = precache_model("sprites/smoke.spr")
    precache_generic("sprites/smoke.spr")
}

public client_disconnected(id)
    remove_task(id)

public Event_Damage(victim, ent, attacker, Float:damage, damagebits)
{
    if(is_user_alive(attacker))
    {
        if (!get_pcvar_num(g_protecton))
            DisableHamForward(XhookDamage_spawn)
    
    
        if(get_user_team(victim) == get_user_team(attacker) && victim != attacker && task_exists(attacker) || task_exists(attacker))
        {
            set_user_godmode(attacker, 0)
            fakedamage(attacker,"Spawn Hacking",damage*1.0,DMG_TIMEBASED)
            if(damage > 99.0 || pev(victim,pev_health) - damage <= 1.0 )
            {
                client_print(0,print_chat,"Killing %n for spawn violation",attacker);
                fakedamage(attacker,"Spawn kill in godmode.",1000.0,DMG_RADIATION)
            }
            new VictimN[MAX_NAME_LENGTH]
            get_user_name(victim,VictimN,charsmax(VictimN))

            if(!is_user_bot(attacker))
                client_print(attacker,print_chat,"[AMXX] Attacking %s when under 'Spawn Protection' mirrors damage! %d|HP ",VictimN,floatround(damage))
    
            new shell = get_pcvar_num(g_shell)
            if(is_user_connected(attacker))
            {
                set_user_rendering(attacker, kRenderFxGlowShell, 0, random_num(90,255), 0, kRenderNormal, shell)
                if(!is_user_bot(attacker))
                client_print(attacker,print_chat,"Spawn protection broken ring! You glow green.");
                Trail_me(attacker);
            }
        }
    }
}

public Trail_me(attacker)
{
    if( get_pcvar_num(g_protecton) == 1 && is_user_connected(attacker) )
    {

        #define COLOR random_num(0,255)

        new l = 200; //lums
        new t = 10; //time
        new w = 5; //width

        new r, g, b;

        r = COLOR;
        g = COLOR;
        b = COLOR;

        emessage_begin(MSG_BROADCAST,23)
        ewrite_byte(TE_BEAMFOLLOW);
        ewrite_short(attacker);
        ewrite_short(g_Trail);
        ewrite_byte(t);
        ewrite_byte(w);
        ewrite_byte(r);
        ewrite_byte(g);
        ewrite_byte(b);
        ewrite_byte(l);
        emessage_end();
    }

}

public cmd_sptime(id, level, cid) // This is the function for the cvar time control
{
    if(!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED
    
    new arg_str[3]
    read_argv(1, arg_str, 3)
    new arg = str_to_num(arg_str)
    
    if(arg > 10 || arg < 1)
    {
        client_print(id, print_chat, "You have to set the Spawn Protection time between 1 and 10 seconds")
        return PLUGIN_HANDLED
    }
    
    else if (arg > 0 || arg < 11)
    {
        set_pcvar_num(g_time, arg)
        client_print(id, print_chat, "You have set the Spawn Protection time to %d second(s)", arg)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

public cmd_spmessage(id, level, cid) // This is the function for the cvar message control
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED

    new sp[3]
    read_argv(1, sp, 2)

    if (sp[0] == '1')
        set_pcvar_num(g_msg, 1)

    else if (sp[0] == '0')
        set_pcvar_num(g_msg, 0)

    else if (sp[0] != '1' || sp[0] != '0')
    {
        console_print(id, "Usage : amx_spmessage 1 = Messages ON | 0 = Messages OFF")
        return PLUGIN_HANDLED
    }

    return PLUGIN_HANDLED
}

public cmd_spshellthickness(id, level, cid)
{
    if(!cmd_access(id, level, cid, 2) && !is_user_bot(id))
    return PLUGIN_CONTINUE

    new arg_str[3]
    read_argv(1, arg_str, 3)
    new arg = str_to_num(arg_str)

    if(arg > 100 || arg < 1)
    {
        client_print(id, print_chat, "You have to set the Glow Shellthickness between 1 and 100")
        return PLUGIN_HANDLED
    }

    else if (arg > 0 || arg < 101)
    {
        set_pcvar_num(g_shell, arg )
        client_print(id, print_chat, "You have set the Glow Shellthickness to %d", arg)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

public sp_on(id) // This is the function for the event godmode
if(is_user_alive(id) && get_pcvar_num(g_protecton))
    set_task(0.1, "protect", id)

public protect(id) // This is the function for the task_on godmode
{
    new new_time
    if(is_user_alive(id) && get_pcvar_num(g_protecton))
    {
        new SPSecs  = get_pcvar_num(g_time)
        new Float:SPTime = float(SPSecs)

        new shell = get_pcvar_num(g_shell)
        new FTime = get_cvar_pointer("mp_freezetime")

        new_time = floatround(SPTime+FTime)

        if(get_pcvar_num(g_msg) && !is_user_bot(id))
        {
            set_task(1.0,"@hud_timer", id, _, _, "a", new_time+1)
            g_spawn_time[id] = new_time
        }

        set_user_godmode(id, 1)

        if( cstrike_running() )
            get_user_team(id) == 1 ? set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, shell) : set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, shell)
        else
            is_user_bot(id) ? set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, shell) : set_user_rendering(id, kRenderFxGlowShell, 255, 255, 25, kRenderNormal, shell)
        set_task(SPTime+FTime, "sp_off", id)
    }
    return PLUGIN_HANDLED
}

@hud_timer(id)
{
    set_hudmessage(255, 1, 1, -1.0, -1.0, 0, 6.0, 1.0, 0.1, 1.0, 1)
    switch(g_spawn_time[id])
    {
        case 6..300: ShowSyncHudMsg id, spawn_sync_msg, "Spawn Protection is enabled.^n^n Attacks are mirrored back: %i seconds!",--g_spawn_time[id]+1
        case 3..5: set_hudmessage(255, 165, 0, -1.0, -1.0, 0, 6.0, 1.0, 0.1, 1.0, 1), ShowSyncHudMsg( id,spawn_sync_msg, "Spawn Protection is enabled.^n^n Attacks are mirrored back: %i seconds!",--g_spawn_time[id]+1)
        case 1..2: set_hudmessage(221, 228, 27, -1.0, -1.0, 0, 6.0, 1.0, 0.1, 1.0, 1), ShowSyncHudMsg( id,spawn_sync_msg, "Spawn Protection is enabled.^n^n Attacks are mirrored back: %i seconds!",--g_spawn_time[id]+1)
        default: set_hudmessage(0, 255, 50, -1.0, -1.0, 0, 6.0, 1.0, 0.1, 1.0, 1), ShowSyncHudMsg( id, spawn_sync_msg,"Spawn protection and godmode over^n^nSHOOT!")
    }

}

public sp_off(id) // This is the function for the task_off godmode
{
    new shell = get_pcvar_num(g_shell)
    if(!is_user_connected(id))
        return PLUGIN_HANDLED
    else
    {
        if(is_user_connected(id))
        {
            set_user_godmode(id, 0)
            set_user_rendering(id, kRenderFxGlowShell, 0, 0,0, kRenderNormal, shell);
            if(!is_user_bot(id) && is_user_alive(id))
            {
                client_cmd(id,"spk fvox/safe_day.wav");
            }

        }
        return PLUGIN_HANDLED
    }

}

public clcmd_fullupdate(id)
    return PLUGIN_HANDLED
/*
Change log 7.0 to 8.0. HL and bot glow support, Mirror damage, easier part name search commands, Synced spawn message with spawn time, Attackers lose protection and turn green and trail!
Change log 8.0 to 8.1. Optimize script to ham and pcvars.
Change log 8.1 to 8.2. More descriptive and syncronized messaging including object for hud.
*/
