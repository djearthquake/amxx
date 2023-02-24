#include amxmodx
public plugin_init()register_message(get_user_msgid("DeathMsg"), "@skulls")&&register_plugin("Skulls", "1.1", "SPiNX");
@skulls()set_msg_arg_string(4, "teammate");
