#include <amxmodx>

#define PLUGIN  "Exit Sound & Reason Blip"
#define VERSION "0.1"
#define AUTHOR  "SPiNX"

new g_cvar_sound

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
    g_cvar_sound = register_cvar("amx_exit_sound", "buttons/blip1.wav")

    static cvar_buffer[128]
    get_pcvar_string(g_cvar_sound, cvar_buffer, charsmax(cvar_buffer))

    static current_sound[128]
    formatex(current_sound, charsmax(current_sound), "sound/%s", cvar_buffer)

    static valve_sound[128]
    formatex(valve_sound, charsmax(valve_sound), "../valve/sound/%s", cvar_buffer)

    if (file_exists(current_sound) || file_exists(valve_sound))
    {
        precache_sound(cvar_buffer)
    }
    else
    {
        log_amx("Paused to prevent crash from missing %s.", cvar_buffer)
        pause("a")
    }
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
    static name[MAX_PLAYERS]
    get_user_name(id, name, charsmax(name))

    if (equal(message, ""))
    {
        copy(message, maxlen, "Connection closed")
    }

    client_print(0, print_chat, "[Server] %s has left the game (%s)", name, message)

    static players[MAX_PLAYERS]
    new num, player
    get_players(players, num, "ch")

    static cvar_buffer[128]
    get_pcvar_string(g_cvar_sound, cvar_buffer, charsmax(cvar_buffer))

    for (new i = 0; i < num; i++)
    {
        player = players[i]
        client_cmd(player, "spk %s", cvar_buffer)
    }
}
