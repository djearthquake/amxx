#include amxmodx
new const grunt_sounds[][]=
{
    "hgrunt/affirmative!.wav",
    "hgrunt/affirmative.wav",
    "hgrunt/alert!.wav",
    "hgrunt/alert.wav",
    "hgrunt/got.wav",
    "hgrunt/go!.wav",
    "hgrunt/go.wav",
    "hgrunt/gr_alert1.wav",
    "hgrunt/gr_die1.wav",
    "hgrunt/gr_die2.wav",
    "hgrunt/gr_die3.wav",
    "hgrunt/grenade!.wav",
    "hgrunt/gr_idle1.wav",
    "hgrunt/gr_idle2.wav",
    "hgrunt/gr_idle3.wav",
    "hgrunt/gr_loadtalk.wav",
    "hgrunt/gr_mgun1.wav",
    "hgrunt/gr_mgun2.wav",
    "hgrunt/gr_mgun3.wav",
    "hgrunt/gr_pain1.wav",
    "hgrunt/gr_pain2.wav",
    "hgrunt/gr_pain3.wav",
    "hgrunt/gr_pain4.wav",
    "hgrunt/gr_pain5.wav",
    "hgrunt/gr_reload1.wav",
    "hgrunt/gr_step1.wav",
    "hgrunt/gr_step2.wav",
    "hgrunt/gr_step3.wav",
    "hgrunt/gr_step4.wav",
    "zombie/claw_miss2.wav",
    "zombie/claw_miss1.wav"

}

public plugin_precache()
{
    register_plugin("Impulse 76|Make a marine","1.0","SPiNX");
    precache_model("models/hgrunt.mdl")
    precache_model("models/gib_hgrunt.mdl")

    for (new list = 1;list < sizeof grunt_sounds;list++)
        precache_sound(grunt_sounds[list])
}
