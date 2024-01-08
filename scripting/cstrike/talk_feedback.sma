#include amxmodx

new const SzTalkSnd[] = "misc/talk.wav"
new const CvarDesc[]  = "Control talk feedback"

new g_say, g_hud, g_txt, g_arg, g_cvar_con

public plugin_init()
{
    register_plugin("Talk feedback","1.1",".sρiηX҉.");

    g_say  = register_event_ex ( "SayText"     , "@hud_saytext_time" , RegisterEventFlags: RegisterEvent_Single|RegisterEvent_OnceForMultiple );
    g_hud  = register_event_ex ( "HudText"     , "@hud_saytext_time2", RegisterEventFlags: RegisterEvent_Single|RegisterEvent_OnceForMultiple );
    g_txt  = register_event_ex ( "TextMsg"     , "@hud_saytext_time3", RegisterEventFlags: RegisterEvent_Single|RegisterEvent_OnceForMultiple );
    g_arg  = register_event_ex ( "HudTextArgs" , "@hud_saytext_time4", RegisterEventFlags: RegisterEvent_Single|RegisterEvent_OnceForMultiple );

    bind_pcvar_num(create_cvar("talk_feedback" , "0", FCVAR_SERVER, CvarDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 5.0), g_cvar_con);
}

public plugin_precache()
{
    precache_sound(SzTalkSnd);
}

public plugin_cfg()
{
    if(g_cvar_con > 4)
    {
        enable_event(g_say)
        enable_event(g_hud)
        enable_event(g_txt)
        enable_event(g_arg)
    }
}

public plugin_end()
{
    if(!g_cvar_con)
    {
        disable_event(g_say)
        disable_event(g_hud)
        disable_event(g_txt)
        disable_event(g_arg)
    }
}

@hud_saytext_time()
{
    if(g_cvar_con)
    {
        static SzMsg[2];read_args(SzMsg, charsmax(SzMsg));
        ///if(contain(SzMsg, "/") < 0
        if(SzMsg[0] != '/')
        {
            if(SzMsg[1] != '/')
            {
                client_cmd 0, "spk %s", SzTalkSnd
            }
        }
    }
}

@hud_saytext_time2(id)
{
    if(g_cvar_con>1)
    {
        sfx(id)
    }
}

@hud_saytext_time3(id)
{
    if(g_cvar_con>2)
    {
        sfx(id)
    }
}

@hud_saytext_time4(id)
{
    if(g_cvar_con>3)
    {
        sfx(id)
    }
}

@hud_saytext_time5(id)
{
    if(g_cvar_con>4)
    {
        sfx(id)
    }
}

stock sfx(id)
{
    if(is_user_connected(id))
    {
        client_cmd id, "spk %s", SzTalkSnd
    }
}
