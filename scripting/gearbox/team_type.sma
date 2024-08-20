#include amxmodx
#include amxmisc
#include fakemeta

static
g_MsgTeamInfo, g_MsgGameMode;
new
g_TeamName[MAX_NAME_LENGTH][MAX_PLAYERS +1];

public plugin_init()
{
    register_plugin("Admin Scoreboard","AUG-2024",".sρiηX҉."); //Inspired by C.ix Colored Names & Teams

    g_MsgGameMode  = get_user_msgid("GameMode");
    g_MsgTeamInfo  = get_user_msgid("TeamInfo");
}

public client_infochanged(id)
{
    @get_team(id);
}

@get_team(id)
{
    if(is_user_connected(id))
    {
        static flags; flags = pev(id, pev_flags);

        if(is_user_hltv(id))
        {
            g_TeamName[id] = "HLTV";
        }
        else if(flags & FL_SPECTATOR)
        {
            g_TeamName[id] = "WATCHER";
        }
        else if(is_user_admin(id))
        {
            g_TeamName[id] = flags & FL_SPECTATOR ? "WATCHER" : "ADMIN"
        }
        else if(is_user_bot(id))
        {
            g_TeamName[id] = "BOT";
        }
        else
        {
            g_TeamName[id] = "PLAYER";
        }
    }
    @message(id);
}

@message(id)
{
    emessage_begin(MSG_BROADCAST, g_MsgGameMode);
    ewrite_byte(1);
    emessage_end();

    if(is_user_connected(id))
    {
        emessage_begin(MSG_BROADCAST, g_MsgTeamInfo);
        ewrite_byte(id);
        ewrite_string(g_TeamName[id]);
        emessage_end();
    }
}
