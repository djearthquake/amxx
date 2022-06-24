#include amxmodx
#include amxmisc
#include fun

#define charsmin                  -1
#define MAX_RESOURCE_PATH_LENGTH   64
new const g_szPowerup_sounds[][] = { "items/ammopickup1.wav", "ctf/itemthrow.wav","ctf/pow_armor_charge.wav","ctf/pow_backpack.wav","ctf/pow_health_charge.wav","turret/tu_ping.wav"}

new const SzMunition[][]={"ammo_", "item_", "weapon_"}

new IsDodRun

public plugin_precache()
{
    precache_model("models/can.mdl")
    precache_model("models/w_accelerator.mdl")
    precache_model("models/w_backpack.mdl")
    precache_model("models/w_porthev.mdl")
    precache_model("models/w_jumppack.mdl")
    precache_model("models/w_health.mdl")
    precache_sound("doors/aliendoor3.wav");
    precache_model("models/w_oxygen.mdl");
    for(new szSounds;szSounds < sizeof g_szPowerup_sounds;++szSounds)
        precache_sound(g_szPowerup_sounds[szSounds]);
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
