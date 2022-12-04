/*Proactive server refresh.*/
#tryinclude amxmodx

#define PLUGIN  "Daily Reload"
#define VERSION "1.0"
#define AUTHOR  "SPiNX"

#define BOOT_HOUR   2
#define BOOT_MIN    49
#define BOOT_SEC    30
#define MAP    "boot_camp"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    set_task( 1.0, "@check_time", 120422, .flags= "b")
}

@check_time()
{
    new hour,min,sec
    time(hour,min,sec)

    if(hour != BOOT_HOUR)
        change_task(120422, 1800.0)
    else
    {
        if(min == BOOT_MIN)
        {
            if( sec == BOOT_SEC )
                set_task( 0.5, "@reload_server", get_systime() )
            else if( sec < BOOT_SEC )
            {
                server_cmd "say Daily reboot in %i seconds",(BOOT_SEC-sec)
                client_cmd 0, "spk ../../valve/sound/UI/buttonrollover.wav"
            }

        }
        change_task(120422, min > BOOT_MIN ? 3600.0 : 1.0)
    }
}

@reload_server()
{
    log_amx "Reloading server..."
    server_cmd "map %s", MAP
}
