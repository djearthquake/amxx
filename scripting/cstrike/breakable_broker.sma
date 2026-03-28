#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN "Insurance Broker"
#define VERSION "1.0"
#define AUTHOR "SPiNX"

static const szEnt[] = "func_breakable";

new bool:g_insured[MAX_PLAYERS + 1];
new bool:g_saw_intro[MAX_PLAYERS + 1];
new Float:g_last_harass[MAX_PLAYERS + 1];

new g_broker_ent;
new g_pcvar_cost;
new g_pcvar_ins;
new g_msgScreenShake;
new g_msgStatusIcon;

static const g_szSciScreams[][] = 
{
    "scientist/sci_pain1.wav",
    "scientist/sci_pain2.wav",
    "scientist/sci_pain3.wav",
    "scientist/sci_pain4.wav",
    "scientist/sci_pain5.wav",
    "scientist/scream01.wav",
    "scientist/scream21.wav"
};

public plugin_precache()
{
    precache_model("models/hostage.mdl");
    precache_sound("buttons/bell1.wav");
    precache_sound("buttons/button11.wav");
    precache_sound("buttons/button2.wav");
    
    for (new i = 0; i < sizeof(g_szSciScreams); i++)
    {
        precache_sound(g_szSciScreams[i]);
    }
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    static iEnt;
    iEnt = MaxClients;
    iEnt = find_ent(iEnt, szEnt);

    if (iEnt)
    {
        RegisterHamFromEntity(Ham_TakeDamage, iEnt, "Ham_Killed_Post", 1);
    }
    else
    {
        pause("a");
    }

    RegisterHam(Ham_TakeDamage, "info_target", "OnBrokerDamage", 0);
    RegisterHam(Ham_ObjectCaps, "info_target", "OnObjectCaps", 1);
    RegisterHam(Ham_Use, "info_target", "OnBrokerUsed", 1);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1);
    
    register_forward(FM_Think, "OnBrokerThink");
    register_event("ResetHUD", "OnResetHUD", "be");

    g_pcvar_cost = register_cvar("break_cost", "100");
    g_pcvar_ins = register_cvar("ins_price", "1000");
    
    g_msgScreenShake = get_user_msgid("ScreenShake");
    g_msgStatusIcon = get_user_msgid("StatusIcon");

    register_concmd("amx_place_broker", "AdminPlaceBroker", ADMIN_RCON);

    set_task(5.0, "SpawnTheOracle");
}

public client_putinserver(id)
{
    g_insured[id] = false;
    g_saw_intro[id] = false;
    g_last_harass[id] = 0.0;
}

public OnPlayerSpawn(id)
{
    if (!is_user_alive(id) || g_saw_intro[id])
    {
        return;
    }

    client_print(id, print_chat, "* [Oracle] Business is war. Vandalism will be fined.");
    client_print(id, print_chat, "* [Oracle] Locate the Broker at spawn for Insurance.");
    g_saw_intro[id] = true;
}

public OnResetHUD(id)
{
    if (g_insured[id])
    {
        set_task(0.1, "ShowInsuranceIcon", id);
    }
}

public ShowInsuranceIcon(id)
{
    if (!is_user_connected(id) || !g_insured[id])
    {
        return;
    }

    message_begin(MSG_ONE, g_msgStatusIcon, {0,0,0}, id);
    write_byte(1); 
    write_string("dollar");
    write_byte(0); 
    write_byte(255); 
    write_byte(0); 
    message_end();
}

public OnBrokerDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
    if (victim != g_broker_ent)
    {
        return HAM_IGNORED;
    }

    if (1 <= attacker <= MaxClients && is_user_alive(attacker))
    {
        ExecuteHamB(Ham_TakeDamage, attacker, victim, victim, damage, damagebits);
        emit_sound(victim, CHAN_VOICE, g_szSciScreams[random(sizeof(g_szSciScreams))], 1.0, ATTN_NORM, 0, PITCH_NORM);
        client_print(attacker, print_center, "THE ORACLE REJECTS YOUR VIOLENCE");
    }
    return HAM_SUPERCEDE; 
}

public Ham_Killed_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
    if (!is_user_connected(attacker) || g_insured[attacker])
    {
        return HAM_IGNORED;
    }

    static iHp, iCost;
    iCost = get_pcvar_num(g_pcvar_cost);
    if (victim)
    {
        iHp = pev(victim, pev_health);
    }

    if (iHp < 2)
    {
        static tmp_money;
        tmp_money = cs_get_user_money(attacker);
        client_print(0, print_chat, "%n charged $%i for property damage! Find the Broker.", attacker, iCost);
        cs_set_user_money(attacker, tmp_money - iCost);
        client_cmd(attacker, "spk buttons/button2.wav");
    }
    return HAM_IGNORED;
}

public SpawnTheOracle()
{
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(ent))
    {
        return;
    }

    set_pev(ent, pev_classname, "insurance_broker");
    engfunc(EngFunc_SetModel, ent, "models/hostage.mdl");
    dllfunc(DLLFunc_Spawn, ent);

    set_pev(ent, pev_solid, SOLID_BBOX);
    set_pev(ent, pev_movetype, MOVETYPE_TOSS);
    set_pev(ent, pev_takedamage, DAMAGE_AIM);
    set_pev(ent, pev_health, 999999.0);

    set_pev(ent, pev_sequence, 1);
    set_pev(ent, pev_framerate, 0.1); 
    
    engfunc(EngFunc_SetSize, ent, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 72.0});
    set_pev(ent, pev_nextthink, get_gametime() + 0.1);
    g_broker_ent = ent;
}

public OnBrokerThink(ent)
{
    if (ent != g_broker_ent)
    {
        return;
    }

    new Float:vOrigin[3], Float:pOrigin[3], Float:vAngles[3];
    pev(ent, pev_origin, vOrigin);

    for (new i = 1; i <= MaxClients; i++)
    {
        if (!is_user_alive(i))
        {
            continue;
        }

        pev(i, pev_origin, pOrigin);
        if (get_distance_f(vOrigin, pOrigin) < 180.0)
        {
            // Face the target properly
            new Float:x = pOrigin[0] - vOrigin[0];
            new Float:y = pOrigin[1] - vOrigin[1];
            new Float:angle = floatatan2(y, x, degrees);
            
            vAngles[0] = 0.0;
            vAngles[1] = angle;
            vAngles[2] = 0.0;
            set_pev(ent, pev_angles, vAngles);

            if (!g_insured[i] && get_gametime() > g_last_harass[i])
            {
                message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, i);
                write_short(1<<14); 
                write_short(1<<13); 
                write_short(1<<14);
                message_end();

                set_dhudmessage(0, 140, 255, -1.0, 0.2, 0, 0.1, 2.0, 0.1);
                show_dhudmessage(i, "UNPROTECTED^nUSE TO SECURE");
                g_last_harass[i] = get_gametime() + 5.0;
            }
        }
    }
    set_pev(ent, pev_nextthink, get_gametime() + 0.1);
}

public OnBrokerUsed(ent, id)
{
    if (ent != g_broker_ent || !is_user_alive(id) || g_insured[id])
    {
        return;
    }

    new iMoney = cs_get_user_money(id);
    new iPrice = get_pcvar_num(g_pcvar_ins);

    if (iMoney >= iPrice)
    {
        cs_set_user_money(id, iMoney - iPrice);
        g_insured[id] = true;
        ShowInsuranceIcon(id);
        client_cmd(id, "spk buttons/bell1.wav");
        set_dhudmessage(0, 140, 255, -1.0, 0.3, 0, 0.1, 5.0, 0.1);
        show_dhudmessage(id, "READY.^nPOLICY SECURED");
    }
}

public OnObjectCaps(ent)
{
    if (ent == g_broker_ent)
    {
        SetHamReturnInteger(FCAP_IMPULSE_USE);
        return HAM_OVERRIDE;
    }
    return HAM_IGNORED;
}

public AdminPlaceBroker(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
    {
        return PLUGIN_HANDLED;
    }

    if (pev_valid(g_broker_ent))
    {
        engfunc(EngFunc_RemoveEntity, g_broker_ent);
    }

    new Float:origin[3], Float:view_ofs[3];
    pev(id, pev_origin, origin);
    velocity_by_aim(id, 64, view_ofs);
    
    origin[0] += view_ofs[0] * 3.0; 
    origin[1] += view_ofs[1] * 3.0;
    origin[2] += view_ofs[2] * 3.0;

    SpawnTheOracle();
    set_pev(g_broker_ent, pev_origin, origin);
    
    return PLUGIN_HANDLED;
}
