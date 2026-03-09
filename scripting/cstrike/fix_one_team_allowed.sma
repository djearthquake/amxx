#include amxmodx
#include fakemeta

const OFFSET_CSTEAMINFO = 125;
const FLAG_ALREADY_JOINED_TEAM = (1<<8);
const OFFSET_LINUX = 5;


public plugin_init()
{
    register_plugin("1 team change fix","1.1",".sρiηX҉.");
    register_clcmd("chooseteam", "UnBlockChangeTeam");
    register_clcmd("!spec", "@go_spec", 0, "-spectate");

}

public UnBlockChangeTeam(id)
{
    if(is_user_connected(id))
    {
        set_pdata_int(id, OFFSET_CSTEAMINFO, (get_pdata_int(id, OFFSET_CSTEAMINFO, OFFSET_LINUX) & ~FLAG_ALREADY_JOINED_TEAM), OFFSET_LINUX);
    }
}

@go_spec(id)
{
    if(is_user_alive(id))
    {
        user_kill(id, 1)
    }
    return PLUGIN_HANDLED
}
