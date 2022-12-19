#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util
#include hamsandwich

#define charsmin -1

#define     PLUGIN         "HeadTump"
#define     VERSION      "1.0"
#define     AUTHOR      "Anonymous"

#define     HEAD_FIRST  30.0
#define     WRITEABLE_ENT   2

#define DELAY ewrite_short(/*get_pcvar_num(g_cvar_bsod_iDelay)*/ 20 *4096) //Remember 4096 is ~1-sec per 'spec unit'

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
    //g_ALL = register_touch("", "player", "@bump")
    register_touch("func_breakable", "player", "@bump")
    register_touch("func_wall", "player", "@bump")
    register_touch("player", "player", "@bump")
    register_touch(cstrike_running() ? "func_vehicle" : "item_battery", "player", "@bump")
    register_touch("weapon_egon", "player", "@bump")
    RegisterHam(Ham_Spawn, "player", "@client_spawn", 1)
    
}

@client_spawn(iBull)
{
    if(is_user_connected(iBull) && bHeadButtedEnts[iBull])
    {
        fm_set_kvd(iBull, "zhlt_lightflags", "0")
        fm_set_kvd(iBull, "renderfx", "0")
        //fm_set_kvd(iBull, "rendermode", "0")
        bHeadButtedEnts[iBull] = false
        //bSFX[iBull] = true
    }
}

@bump(iWall, iBull)
{
    if(!is_user_connected(iBull) || pev_valid(iWall) != 2 ||pev_valid(iBull) != 2 || iWall == 0 || iBull == 0 || is_user_bot(iBull) || !is_user_admin(iBull)/* get_user_time(iBull) < 300)*/)
        return PLUGIN_HANDLED_MAIN

    if(is_user_alive(iBull))
    {
        new Float:ViewAngles[2];
        pev(iBull, pev_v_angle, ViewAngles);

        if (ViewAngles[0] > HEAD_FIRST && !bSFX[iBull])
        {
            //client_print iBull, print_center, "%f", ViewAngles[0]

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
            if(!bHeadButtedEnts[iWall])
            {
                client_print iBull, print_console, "Ent %i", iWall
                set_pev(iWall, pev_classname, "func_breakable")

                set_pev(iWall, pev_takedamage, 2.0)
                set_pev(iWall, pev_health, 200.0)
                fm_set_kvd(iWall, "spawnobject", "0") //1-battery, 5=mp5
                fm_set_kvd(iWall, "material", "2");
                //fm_set_kvd(iWall, "gibmodel", "models/hair.mdl")
                fm_set_kvd(iWall, "explosion", "0")
                fm_set_kvd(iWall, "zhlt_lightflags", "1")
                fm_set_kvd(iWall,"renderfx", "16")
                fm_set_kvd(iWall,"explodemagnitude", "0")
                fm_set_kvd(iWall,"rendermode", "2")
                bSFX[iBull] = true

                bHeadButtedEnts[iWall] = true
            }

        }
        else
        {
            //fm_set_kvd(iWall,"texture", "PINUPXENA4") //precache?
            //set_pev(iWall, pev_classname, "infodecal")
            set_pev(iWall, pev_rendercolor, Float:{60.0, 5.0, 215.0})
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
    new bool:bIsBot[MAX_PLAYERS+1]
    if(is_user_bot(iWall))
    {
        bIsBot[iWall] = true
    }
    else if(is_user_bot(head_down))
    {
        bIsBot[head_down] = true
    }

    if(iWall > 0 && pev_valid(iWall))
    {
        //fakedamage(iWall,"Head Bang",1.0, is_user_alive(iWall) ? DMG_RADIATION : DMG_CRUSH)
        if(is_user_alive(iWall))
        {
            fakedamage(iWall,"Head Bang",1.0, DMG_RADIATION)
            if(!bIsBot[head_down])
            {
                //client_cmd head_down, random(2) == 1 ? "spk ^"in head^"" : "spk pain"
            }
            else if(bIsBot[iWall])
            {
                client_cmd head_down, "spk exterminate"
            }
        }
        else
        {
            fakedamage(iWall,"Smashing",2.0, DMG_CRUSH)
            //client_cmd head_down, random(2) == 1 ? "spk ^"break this^"" : "spk area"
        }
    }

    if(is_user_connected(iWall) && is_user_bot(iWall))
    {
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
    @kill_switch(head_down, iWall)
}

@kill_switch(iBull, iWall)
{
    new ping, loss;

    if(is_user_connected(iBull))
    {
        get_user_ping(iBull,ping,loss)
        loss > 1.5 ? unregister_touch(g_ALL) : client_print(iBull, print_center, "Head bump %n!", iBull)
    }
    if(is_user_connected(iWall))
    {
        get_user_ping(iWall,ping,loss)
        loss > 1.5 ? unregister_touch(g_ALL) : client_print(iWall, print_center, "Head bump %n!", iWall)
    }
}

public plugin_precache()
{
    precache_model("models/glassgibs.mdl");

    precache_model("models/w_9mmar.mdl")

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

}
