#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util //kv

#define     PLUGIN         "HeadTump"
#define     VERSION      "1.0"
#define     AUTHOR      "Anonymous"

#define     HEAD_FIRST  30.0
#define     WRITEABLE_ENT   2

#define DELAY ewrite_short(/*get_pcvar_num(g_cvar_bsod_iDelay)*/ 5 *4096) //Remember 4096 is ~1-sec per 'spec unit'
//10+ works better on hpb wheres lower the better on JK and can crash if set too high whereby otherwise hpb bots wouldnt crash

#define FLAGS ewrite_short(0x0001)

#define ALPHA ewrite_byte(500)


//Screenfade color.

#define BLU ewrite_byte(0);ewrite_byte(0);ewrite_byte(random_num(200,255))

#define GRN ewrite_byte(0);ewrite_byte(random_num(200,255));ewrite_byte(0)

#define PNK ewrite_byte(255);ewrite_byte(random_num(170,200));ewrite_byte(203)

#define PUR ewrite_byte(118);ewrite_byte(random_num(25,75));ewrite_byte(137)

new bool:bSFX[ MAX_PLAYERS + 1]
new bool:bHeadButtedEnts[ 2048 ]
new g_ALL

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    g_ALL = register_touch("", "player", "@bump")
}

@bump(iWall, iBull)
{
    if(!is_user_connected(iBull) || pev_valid(iWall < WRITEABLE_ENT) || iWall == 0)
        return PLUGIN_HANDLED_MAIN

    if(is_user_connected(iBull) && is_user_alive(iBull) && !is_user_bot(iBull))
    {
        new Float:ViewAngles[2];
        pev(iBull, pev_v_angle, ViewAngles);

        if (ViewAngles[0] > HEAD_FIRST && !bSFX[iBull])
        {
            ///client_print iBull, print_center, "%f", ViewAngles[0]

            set_pev(iWall, pev_rendermode, kRenderFxStrobeFaster);
            set_pev(iWall, pev_rendermode, kRenderGlow);
            set_pev(iWall, pev_renderamt,  255.0);

            set_pev(iWall, pev_rendercolor, Float:{200.0, 75.0, 50.0})

            if(!task_exists(iWall))
            {
                new szBuffer[3]
                num_to_str(iBull, szBuffer, charsmax(szBuffer))

                set_task(0.5, "@damage", iWall, szBuffer, charsmax(szBuffer))
            }

            if(!bHeadButtedEnts[iWall] && !is_user_connected(iWall) && iWall > 32)
            {
                set_pev(iWall, pev_classname, "func_breakable")
                set_pev(iWall, pev_takedamage, 2.0)
                set_pev(iWall, pev_health, 50.0)
                fm_set_kvd(iWall, "spawnobject", "1") //battery
                fm_set_kvd(iWall, "material", "2"); //glass

                bSFX[iBull] = true

                bHeadButtedEnts[iWall] = true
            }
        }
        else
        {
            bSFX[iBull] = false
            /*
            iWall ? client_print( iBull, print_center,  "[PITCH: %f|YAW:%f]^n[ENT: %i]", ViewAngles[0], ViewAngles[1], iWall ) : client_print( iBull, print_center, "[PITCH: %f|YAW:%f]", ViewAngles[0], ViewAngles[1] )*/
        }

    }
    return PLUGIN_CONTINUE
}

@damage(szBuffer[], iWall)
{
    new head_down = str_to_num(szBuffer)
    fakedamage(iWall,"Head Bang",1.0, iWall < MAX_PLAYERS ? DMG_RADIATION : DMG_CRUSH)

    if(is_user_connected(iWall))
    {
        //if(!is_user_bot(head_down))
            //client_cmd head_down, random(2) == 1 ? "spk ^"in head^"" : "spk pain"
        ///client_cmd head_down, "spk exterminate"
        emessage_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),{0,0,0},iWall);
        DELAY;DELAY;FLAGS;PNK;ALPHA; //This is where one can change BLU to GRN.
        emessage_end();
    }
    else
    {
        if(is_user_alive(head_down))
        {
            new iSND = random_num(1,4)
            new szSpeak[64]
            format(szSpeak, charsmax(szSpeak), "spk debris/concrete%i.wav", iSND)
            client_cmd head_down, szSpeak
        }
    }
    
    if(is_user_connected(head_down) || is_user_connected(iWall) )
    {
        new ping, loss; get_user_ping(head_down ,ping,loss)
        loss > 1 ? unregister_touch(g_ALL) : client_print(head_down, print_center, "Head first %n!", head_down)
    }
}

public plugin_precache()
{
    precache_model("models/glassgibs.mdl");
    //keep func_breakable, random near untraceable crashes

    //if you bother to make a func_breakable out of thin air
    precache_model("models/hair.mdl")

    precache_sound("debris/bustglass2.wav");
    precache_sound("debris/bustglass1.wav");

    precache_sound("debris/bustmetal1.wav");
    precache_sound("debris/bustmetal2.wav");


    precache_sound("debris/metal1.wav");
    precache_sound("debris/metal2.wav");
    precache_sound("debris/metal3.wav");

    precache_sound("items/smallmedkit1.wav")
    precache_sound("items/smallmedkit2.wav")

    precache_model("sprites/fexplo.spr")


    precache_model("models/w_battery.mdl")
    precache_model("models/w_medkit.mdl")

    precache_model("models/hair.mdl")
}
