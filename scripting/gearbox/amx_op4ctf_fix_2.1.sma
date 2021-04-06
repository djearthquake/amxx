#include amxmodx
#include fakemeta_util

#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_PLAYERS                32
#define MAX_IP_LENGTH              16

#define charsmin                   -1

new szPowerup[ MAX_PLAYERS ];

new const SzTakeJump[] = "take_Jump_Powerup"
new const SzDropJump[] = "drop_Jump_Powerup"

stock get_loguser_index()
{
    new log_user[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_PLAYERS];
    read_logargv(0, log_user, charsmax(log_user));
    parse_loguser(log_user, name, charsmax(name));
    return get_user_index(name);
}

public plugin_init()

    register_plugin("op4ctf_jumpfix","2.1","SPiNX") &&
    register_event("CustomIcon", "plugin_log", "bcf", "2=take_Jump_Powerup", "2=drop_Jump_Powerup");


public plugin_log()
{

    new target = get_loguser_index()

    read_logargv(2,szPowerup, charsmax(szPowerup))
    if(containi(szPowerup, SzDropJump) != charsmin)
    {
        fm_set_user_longjump(target, false, false);
    }

    read_logargv(2,szPowerup, charsmax(szPowerup))
    if(containi(szPowerup, SzTakeJump) != charsmin)
    {
        fm_set_user_longjump(target, true, true);
    }

}
