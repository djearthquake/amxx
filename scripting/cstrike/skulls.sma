#include amxmodx
#define MAX_PLAYERS 32
static szArgs[MAX_PLAYERS]
public plugin_init()register_plugin("Skulls", "1.0", "SPiNX") && register_message(get_user_msgid("DeathMsg"), "@skulls")  && get_msg_arg_string(3, szArgs, charsmax(szArgs))
@skulls()set_msg_arg_string(4, "teammate")
