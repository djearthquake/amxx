#include <amxmodx>
#include <amxmisc>

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

new pPlugin,pXPosition,pYPosition,pHoldTime;
new g_AI, g_teams
static bool:bStrike;

public plugin_init()
{
    register_plugin("HitmarX","D",".sρiηX҉.");

    static modname[MAX_PLAYERS];
    get_modname(modname, charsmax(modname))
    bStrike = equali(modname, "cstrike") || equali(modname, "czero") ? true : false
    g_teams            =  bStrike ? get_cvar_pointer("mp_friendlyfire") : get_cvar_pointer("mp_teamplay")
    register_event("Damage", "PostTakeDamage", "b", "2!0", "3=0", "4!0")

    pPlugin =           register_cvar("amx_hitmarkers", "1");
    pXPosition =        register_cvar("amx_hmxpos", "-1.0");
    pYPosition =        register_cvar("amx_hmypos", "-1.0");
    pHoldTime =         register_cvar("amx_hmholdtime", "0.5");
}
public PostTakeDamage(iVictim)
{
    static const SzZombie_hitmarkers[][] = {"-", "\", "*", "+", "X"};
    static Active_plugin; Active_plugin = get_pcvar_num(pPlugin);
    static iRed,iGreen,iBlue,Float:fXPos,Float:fYPos,Float:fHoldTime;
    iRed = iRainbow();iGreen = iRainbow(); iBlue = iRainbow();fXPos = get_pcvar_float(pXPosition);fYPos = get_pcvar_float(pYPosition);fHoldTime = get_pcvar_float(pHoldTime);

    if(Active_plugin)
    {
        if(is_user_connected(iVictim))
        {
            static iAttacker;
            iAttacker = get_user_attacker(iVictim);
            if(~CheckPlayerBit(g_AI, iAttacker))
            {
                static Cvar; Cvar = get_pcvar_num(g_teams)
                if(Cvar || bStrike)
                {
                    if(bStrike)
                    {
                        if(!Cvar && get_user_team(iAttacker) == get_user_team(iVictim))
                            return PLUGIN_HANDLED
                    }
                    else
                    {
                        static killers_team[MAX_PLAYERS], victims_team[MAX_PLAYERS];
                        get_user_team(iAttacker, killers_team, charsmax(killers_team));
                        get_user_team(iVictim, victims_team, charsmax(victims_team))

                        if(Cvar && !equal(killers_team,victims_team))
                            return PLUGIN_CONTINUE
                    }

                }
                set_hudmessage(iRed, iGreen, iBlue, fXPos, fYPos, 0, 2.0, fHoldTime, 0.0, 0.0, -1);
                show_hudmessage (iAttacker, "%s", SzZombie_hitmarkers[random(sizeof(SzZombie_hitmarkers))]);
            }
        }
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
    if(is_user_connected(id))
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
}

stock iRainbow() return random(256)
