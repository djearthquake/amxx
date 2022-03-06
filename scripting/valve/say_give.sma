#include amxmodx
#include amxmisc
#include fun

#define charsmin                  -1
#define MAX_RESOURCE_PATH_LENGTH   64

new const SzMunition[][]={"ammo_", "item_", "weapon_"}

new IsDodRun

public plugin_precache()
{
    precache_model("models/can.mdl")
}
public plugin_init()
{
    register_plugin("wep intrcp","1.0","SPiNX")
    is_running("dod") ? (IsDodRun = 1) : server_print("dod not running")
}

public client_command(id)
if(is_user_connected(id))
{
    new said[MAX_RESOURCE_PATH_LENGTH]
    read_args(said,charsmax(said))

    for( new s;s<sizeof SzMunition;++s)
    {

        if( containi(said, SzMunition[s]) != charsmin )
        {
            client_print id, print_console, "%s", said

            if(IsDodRun)
            {
                strip_user_weapons(id)
                give_item(id,"weapon_colt")
                give_item(id,"weapon_amerknife")
                give_item(id,"weapon_handgrenade")
                give_item(id,"weapon_stickgrenade")

            }
            give_item(id,said) ? client_cmd(id,"spk buttons/bell1.wav") : client_cmd(id,"spk buttons/latchlocked2.wav")

        }

    }

}
