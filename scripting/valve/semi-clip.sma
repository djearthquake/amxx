#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define NotDeadorHLTV "ah"

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

new g_iSemiclip, g_cvar_dist, bool:bRegistered;

public plugin_init()
{
    register_plugin("Semiclip", "1.15", "ConnorMcLeod|SPiNX")

    g_iSemiclip = register_cvar("sv_semiclip", "1");

    register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1)

    RegisterHam(Ham_Player_PreThink, "player", "Ham_CBasePlayer_PreThink_Pre", 0)
    RegisterHam(Ham_Player_PostThink, "player", "Ham_CBasePlayer_PreThink_Post", 1)

    g_cvar_dist = register_cvar("sc_dist", "0.1")
}

public FM_client_AddToFullPack_Post(es, e, iEnt, id, hostflags, player, pSet)
{
    if(is_user_alive(id) && is_user_alive(player))
    {
        new SzTeam[MAX_PLAYERS], SzOtherTeam[MAX_PLAYERS];
        get_user_team(iEnt, SzTeam, charsmax(SzTeam));
        get_user_team(id, SzOtherTeam, charsmax(SzOtherTeam));
        if(pev(player, pev_movetype) != MOVETYPE_FLY)
        if( player && id != iEnt && get_orig_retval() && is_user_alive(id) && equali(SzTeam, SzOtherTeam))
        {
            new Float:fDist; fDist = get_pcvar_num(g_cvar_dist)*1.0
            new Float:flDistance; flDistance = entity_range(id, iEnt)
            if( flDistance < fDist )
            {
                set_es(es, ES_RenderMode, kRenderTransAlpha)
                set_es(es, ES_RenderAmt, floatround(flDistance)/2)
            }
        }
    }
}

@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity( Ham_Player_PreThink, ham_bot, "Ham_CBasePlayer_PreThink_Pre", 0)
        RegisterHamFromEntity( Ham_Player_PostThink, ham_bot, "Ham_CBasePlayer_PreThink_Post", 1)
        bRegistered = true;
        server_print("Semi-clip bot from %N", ham_bot)
    }
}

public client_putinserver(id)
{
    if(is_user_bot(id) && !bRegistered)
    {
        set_task(0.2, "@register", id);
    }
}
/*
public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT") && !bRegistered)
    {
        set_task(0.1, "@register", id);
    }
}*/

public Ham_CBasePlayer_PreThink_Pre(id)
{
    if(!get_pcvar_num(g_iSemiclip))
    {
        return
    }
    new iNum, iPlayers[MAX_PLAYERS], iPlayer
    if(is_user_alive(id)){
    get_players(iPlayers, iNum, NotDeadorHLTV)

    for(new i = 0; i<iNum; i++)
    {
        iPlayer = iPlayers[i]

        if(is_user_alive(iPlayer))
        {
            static SzTeam[MAX_PLAYERS], SzOtherTeam[MAX_PLAYERS];
            get_user_team(iPlayer, SzTeam, charsmax(SzTeam));
            get_user_team(id, SzOtherTeam, charsmax(SzOtherTeam));

            if( id != iPlayer && equali(SzTeam, SzOtherTeam))
            {
                set_pev(iPlayer, pev_solid, SOLID_NOT)
            }

        }

      }

   }

}

public Ham_CBasePlayer_PreThink_Post(id)
{
    if(is_user_alive(id) )
    {
        new iNum, iPlayers[MAX_PLAYERS], iPlayer
        get_players(iPlayers, iNum, NotDeadorHLTV)

        for(new i = 0; i<iNum; i++)
        {
            iPlayer = iPlayers[i]
            if( iPlayer != id )
            {
                set_pev(iPlayer, pev_solid, SOLID_SLIDEBOX)
            }
        }
    }
}
