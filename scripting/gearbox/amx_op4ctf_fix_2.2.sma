#include amxmodx
#include fakemeta_util

#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_PLAYERS                32
#define MAX_IP_LENGTH              16

#define charsmin                   -1

new szPowerup[ MAX_PLAYERS ];

new const SzTakeJump[] = "take_Jump_Powerup"
new const SzJump[]     = "ctf/pow_big_jump.wav"
new g_snd;

public plugin_precache()
    precache_sound(SzJump)

public plugin_init()
{
    register_plugin("op4ctf_jumpfix","2.2","SPiNX");
    register_event("CustomIcon", "plugin_log", "bcf", "2=take_Jump_Powerup", "2=drop_Jump_Powerup");
    g_snd = get_cvar_pointer("sv_dmjumpsound");
}

public plugin_log()
{
    read_logargv(2,szPowerup, charsmax(szPowerup));

    if(containi(szPowerup, "_Jump_Powerup") != charsmin)

    {

        new target = get_loguser_index()

        if (is_user_alive(target))
        
        (containi(szPowerup, SzTakeJump) == charsmin ?

            fm_set_user_longjump(target, false, false):

                fm_set_user_longjump(target, true, true),
                snd_effect(target));
    

    }

}

public snd_effect(target)

    if(is_user_alive(target) && get_pcvar_num(g_snd))
    emit_sound(target, CHAN_WEAPON, SzJump, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

stock get_loguser_index()
{
    new log_user[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_PLAYERS];
    read_logargv(0, log_user, charsmax(log_user));

    parse_loguser(log_user, name, charsmax(name));

    return get_user_index(name);
}
