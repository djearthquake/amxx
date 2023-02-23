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
    new mod_name[MAX_NAME_LENGTH];
    get_modname(mod_name, charsmax(mod_name));

    if(equal(mod_name,"gearbox"))
    {
        precache_model("models/w_accelerator.mdl")
        precache_model("models/w_backpack.mdl")
        precache_model("models/w_porthev.mdl")
        for(new szSounds;szSounds < sizeof g_szPowerup_sounds;++szSounds)
            precache_sound(g_szPowerup_sounds[szSounds]);
    }
    else if(equal(mod_name,"tfc"))
    {
        precache_model("models/v_crowbar.mdl")
        precache_model("models/w_crowbar.mdl")
        precache_model("models/p_crowbar.mdl")
    }
    precache_model("models/can.mdl")
    precache_model("models/w_jumppack.mdl")
    precache_model("models/w_health.mdl")
    precache_sound("doors/aliendoor3.wav")
    precache_model("models/w_oxygen.mdl")
}
public plugin_init()
{
    register_plugin("wep intrcp","1.0","SPiNX")
    is_running("dod") ? (IsDodRun = 1) : server_print("dod not running")
}

public client_command(id)
if(is_user_connected(id) && is_user_admin(id))
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
            client_cmd id, give_item(id,said) ? "spk buttons/bell1.wav" : "spk buttons/latchlocked2.wav"

        }

    }

}
