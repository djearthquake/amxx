#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define NotDeadorHLTV "ah"

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

new g_iPlayers[MAX_PLAYERS], g_iNum, g_iPlayer, g_iSemiclip, i;
new SzTeam[4], Players_team, Your_team, g_cvar_dist;


static Float:flDistance

public plugin_init()
{
    register_plugin("Semiclip", "1.12", "ConnorMcLeod|SPiNX")

    g_iSemiclip = register_cvar("sv_semiclip", "1");

    register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1)

    RegisterHam(Ham_Player_PreThink, "player", "Ham_CBasePlayer_PreThink_Post", 1)

    g_cvar_dist = register_cvar("sc_dist", "0.1")
}

public FM_client_AddToFullPack_Post(es, e, iEnt, id, hostflags, player, pSet)
{
    Players_team = get_user_team(iEnt, SzTeam, charsmax(SzTeam));
    Your_team = get_user_team(id, SzTeam, charsmax(SzTeam));
    if( player && id != iEnt && get_orig_retval() && is_user_alive(id) && Players_team == Your_team )
    {
        static Float:fDist; fDist = get_pcvar_num(g_cvar_dist)*1.0
        flDistance = entity_range(id, iEnt)
        if( flDistance < fDist )
        {
            set_es(es, ES_RenderMode, kRenderTransAlpha)
            set_es(es, ES_RenderAmt, floatround(flDistance)/2)
        }
    }
}

public Ham_CBasePlayer_PreThink_Post(id)
{
    if(!is_user_alive(id) || get_pcvar_num(g_iSemiclip) == 0)
    {
        return
    }

    if( is_user_bot(id) && is_user_connected(id) || !is_user_bot(id) && is_user_connected(id) ){
    //'Some' bots are knife proof otherwise.

    get_players(g_iPlayers, g_iNum, NotDeadorHLTV)

    for(i = 0; i<g_iNum; i++)
    {
        g_iPlayer = g_iPlayers[i]
        Players_team = get_user_team(g_iPlayer, SzTeam, charsmax(SzTeam));
        Your_team = get_user_team(id, SzTeam, charsmax(SzTeam));

        if( id != g_iPlayer && Your_team == Players_team  )

        {
            set_pev(g_iPlayer, pev_solid, SOLID_NOT)
        }

      }

   }

}

public client_PostThink(id)
{
    if( !is_user_connected(id) )
    {
        return
    }

    get_players(g_iPlayers, g_iNum, NotDeadorHLTV)

    for(i = 0; i<g_iNum; i++)
    {
        g_iPlayer = g_iPlayers[i]
        if( g_iPlayer != id )
        {
            set_pev(g_iPlayer, pev_solid, SOLID_SLIDEBOX)
        }
    }
}
