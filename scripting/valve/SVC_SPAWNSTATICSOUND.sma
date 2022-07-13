#include <amxmodx>
#include <engine_stocks>
#include <fakemeta>

new const SzSND[]="ambience/thunder_clap.wav"
static g_snd

public plugin_init()
{
    register_clcmd("say /emit2","cmdSound");
}
public plugin_precache()
{
    precache_sound(SzSND)
    g_snd = precache_sound(SzSND)
}
//https://wiki.alliedmods.net/Half-Life_1_Engine_Messages#SVC_SPAWNSTATICSOUND
public cmdSound(id)
{
    if(is_user_connected(id))
    {
        new origin[3];
        pev(id, pev_origin, origin);
        
        message_begin(MSG_ONE_UNRELIABLE, SVC_SPAWNSTATICSOUND, {0, 0, 0}, id)
        
        //follow with null
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2])

        write_short(g_snd) //sndindex
        write_byte(150) //vol *255
        write_byte(32) //attenu *64
        
        write_short(id) //ent index -- follow the player
        write_byte(80) //pitch
        write_byte(0) //flags
        message_end;
        
    }

}
