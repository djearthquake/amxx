#include amxmodx
#include amxmisc
#include fakemeta
//#include cstrike
#include fun

#define PLUGIN  "Random Player Test"
#define VERSION "1.0.0"
#define AUTHOR  "SPiNX"

#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/"

static const szTreat[] = "weapon_awp"
static const szWon[] = "%n won roll of kevlar tape!"
static bool:bGiven
new iGlowing

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
        register_plugin(PLUGIN, VERSION, AUTHOR)
    #else
        register_plugin(PLUGIN, VERSION, AUTHOR, URL)
    #endif
    /*
    static mname[MAX_PLAYERS];
    get_mapname(mname, charsmax(mname) )
    if(containi(mname, "aim_") != -1 )
        pause("a")
    */
    register_logevent("@giveaway", 2, "1=Round_Start");

    ///register_logevent("@test", 2, "1=Round_End");
}

@giveaway()
{
    static iLucky; iLucky = random_player()
    if(!bGiven && is_user_alive(iLucky) && CSW_AWP != get_user_weapon(iLucky))
    {
        bGiven = true
        server_print("LUCKY CLIENT IS %i|%n", iLucky, iLucky);
        client_print 0, print_chat, szWon, iLucky
        //give_item(iLucky, szTreat)
        set_pev(iLucky, pev_armorvalue, pev(iLucky,pev_armorvalue) +random_float(50.0, 100.0))
    }
    else
    {
        set_task(0.1, "@giveaway")
    }
    ///set_task(45.0, "@stop_glow", iGlowing)
}


@stop_glow(iTester)
{
    if(is_user_connected(iTester))
        set_user_rendering(iTester, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
}

stock random_player()
{
    return random_num(1, MaxClients)
}


@test()
{
    static team_players, random_players[MAX_PLAYERS+2];
    bGiven = false

    for(new iPlayer = 1; iPlayer <= MaxClients; ++iPlayer)
    if(is_user_connected(iPlayer) && get_user_team(iPlayer) == 1)
    {
        team_players++
        random_players[team_players] = iPlayer
    }

    static iPick;
    iPick = random_num(1, team_players)
    ///iPick = random(team_players+1);

    if(random_players[iPick] && is_user_connected(random_players[iPick]))
    {
        iGlowing=random_players[iPick]

        ///set_user_rendering(random_players[iPick], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 75)

        server_print ("%i|%n........was selected in random test.", random_players[iPick], random_players[iPick])

        for(new iPlayer = 1; iPlayer <= MaxClients; ++iPlayer)
        if(is_user_connected(iPlayer) && is_user_admin(iPlayer))
            client_print iPlayer, print_chat, "%i|%n........was selected in random test.", random_players[iPick], random_players[iPick]
    }

}
