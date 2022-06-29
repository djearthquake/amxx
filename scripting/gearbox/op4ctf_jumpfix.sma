#include amxmodx
#include fakemeta_util
#include hamsandwich

#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_PLAYERS                                   32
#define MAX_IP_LENGTH                              16

#define charsmin                                             -1

new bool:g_bHasJump[MAX_PLAYERS + 1],
szPowerup[ MAX_PLAYERS ], g_snd;

new const SzTakeJump[] = "take_Jump_Powerup",
SzJump[]     = "ctf/pow_big_jump.wav";

public plugin_precache()
    precache_sound(SzJump);

public plugin_init()
{
    register_plugin("op4ctf_jumpfix","2.3","SPiNX");
    g_snd = get_cvar_pointer("sv_dmjumpsound");
    if(g_snd > 1)
    {
        new mname[MAX_PLAYERS];
        get_mapname(mname, charsmax(mname));
    
        if (containi(mname,"op4c") == charsmin)
            pause "a";
    }
    register_event("CustomIcon", "plugin_log", "bcf", "2=take_Jump_Powerup", "2=drop_Jump_Powerup");
    RegisterHam( Ham_Player_Jump, "player", "snd_effect" );

}

public client_putinserver(target)
    if(is_user_connected(target))
        set_task(0.5, "@no_jump", target)

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

public client_disconnected(target)
    g_bHasJump[target] = false;

public plugin_log()
{
    read_logargv(2,szPowerup, charsmax(szPowerup));

    if(containi(szPowerup, "_Jump_Powerup") != charsmin)

    {

        new target = get_loguser_index()

        if (is_user_connected(target))

        containi(szPowerup, SzTakeJump) == charsmin ?
            set_task(0.4, "@no_jump", target) :

                fm_set_user_longjump(target, true, true),
                g_bHasJump[target] = true

    }

}

@no_jump(target)
if(is_user_connected(target))
{
    g_bHasJump[target] = false;
    fm_set_user_longjump(target, false, false);
}

public snd_effect(target)
{
    new Button = pev(target,pev_button),OldButton = pev(target,pev_oldbuttons);

    if(Button & IN_JUMP && (OldButton & IN_FORWARD) && pev(target, pev_flags) & FL_ONGROUND)
    snd_play(target)
}

public snd_play(target)
{
    new Button = pev(target,pev_button),OldButton = pev(target,pev_oldbuttons);

    if(Button & IN_DUCK && (OldButton & IN_DUCK))
        return
    if(g_bHasJump[target] && is_user_alive(target) && get_pcvar_num(g_snd))
    emit_sound(target, CHAN_WEAPON, SzJump, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

stock get_loguser_index()
{
    new log_user[MAX_RESOURCE_PATH_LENGTH + MAX_IP_LENGTH], name[MAX_PLAYERS];
    read_logargv(0, log_user, charsmax(log_user));

    parse_loguser(log_user, name, charsmax(name));

    return get_user_index(name);
}
