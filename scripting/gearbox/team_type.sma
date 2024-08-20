#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUGIN  "OP4 Team Type"
#define VERSION "1.0"
#define AUTHOR  "SPiNX" //Inspired by C.ix Colored Names & Teams

static
g_MsgScoreInfo, g_MsgTeamInfo, g_MsgGameMode;
new
g_TeamName[MAX_NAME_LENGTH][MAX_PLAYERS +1],
bool: bMessagePush[MAX_PLAYERS+1];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_MsgGameMode  = get_user_msgid("GameMode");
    g_MsgScoreInfo = get_user_msgid("ScoreInfo");
    g_MsgTeamInfo  = get_user_msgid("TeamInfo");

    register_message(g_MsgScoreInfo, "fw_ScoreInfo_Msg");
    register_event("TeamInfo", "ev_TeamInfo", "a");
}

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        get_team(id);
        send_GameMode_msg();
        send_TeamInfo_msg(id);
    }
}

public client_command(id)
{
    if(!bMessagePush[id])
    {
       client_infochanged(id)
    }
}

public client_disconnected(id)
{
    bMessagePush[id] = false
}

public ev_TeamInfo()
{
    static id; id = read_data(1);
    if(is_user_connected(id))
    {
        static flags; flags = pev(id, pev_flags)

        if(flags & FL_SPECTATOR && !is_user_hltv(id))
        {
            g_TeamName[id] = "WATCHER";
            send_TeamInfo_msg(id);
        }
    }
    return PLUGIN_CONTINUE;
}

public fw_ScoreInfo_Msg()
{
    static id; id = get_msg_arg_int(1);
    if(is_user_connected(id))
    {
        get_team(id);
        send_TeamInfo_msg(id);
    }
    return PLUGIN_CONTINUE;
}

get_team(id)
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
        g_TeamName[id] = "ADMIN";
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

send_GameMode_msg()
{
    message_begin(MSG_BROADCAST, g_MsgGameMode);
    write_byte(1);
    message_end();
}

send_TeamInfo_msg(id)
{
    message_begin(MSG_BROADCAST, g_MsgTeamInfo);
    write_byte(id);
    write_string(g_TeamName[id]);
    message_end();
}
