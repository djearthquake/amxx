#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>

new const PLUGIN[] = "Bealer" //short for Bee Healer. 
new const VERSION[] = "B"
new const AUTHOR[] = "SPiNX"

new g_HasBealer[MAX_PLAYERS + 1]

new p_Enable, p_Force, p_Effects;

#define FLOAT_ANGLE -20.0
#define FLOAT_DELAY 0.1

new g_recoil

public plugin_precache()
{
    g_recoil = precache_model("sprites/ballsmoke.spr");

    // 1 = Everyody has bee healer.
    // 0 = Admin control bee healer.
    p_Enable = register_cvar("amx_bealer","1");
    p_Force = register_cvar("amx_bealer_forceadd","500");
    p_Effects = register_cvar("amx_bealer_effects","4");

    register_forward(FM_PlayerPreThink,"forward_PreThink");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_concmd("amx_give_healingbee","CmdGive",ADMIN_BAN,"<target> <1/0> Enables/Disables healer bees for a player");
}

public client_connect(iJumpMan)
    g_HasBealer[iJumpMan] = 0

public forward_PreThink(iJumpMan)
{
    if(!is_user_connected(iJumpMan) || !is_user_alive(iJumpMan) || is_user_connecting(iJumpMan) || is_user_hltv(iJumpMan))
        return FMRES_HANDLED

    if(g_HasBealer[iJumpMan] != 1 && get_pcvar_num(p_Enable) == 0)
        return FMRES_HANDLED

    static Clip,Ammo,UserAmmo[MAX_PLAYERS + 1]
    if(get_user_weapon(iJumpMan,Clip,Ammo) == HLW_HORNETGUN)
    {
        new Button = pev(iJumpMan,pev_button),OldButton = pev(iJumpMan,pev_oldbuttons);

        if(Button & IN_ATTACK && !(OldButton & IN_ATTACK2))
        UserAmmo[iJumpMan] = Ammo

        if(!(Button & IN_ATTACK) && (OldButton & IN_ATTACK2))
        {
            //Based on Drak rocket jumping.
            switch(UserAmmo[iJumpMan] - Ammo)
            {
                case 10..13: @leap(iJumpMan,1000);
                case 5..9: @leap(iJumpMan,2000);
                default: @leap(iJumpMan,1000);
            }
        }
    }
    return PLUGIN_HANDLED
}

@leap(iJumpMan,Power)
{
    new Float:Vector[3]
    pev(iJumpMan,pev_angles,Vector);

    if(Vector[0] > FLOAT_ANGLE)
        return

    if(get_pcvar_num(p_Effects))
    {
        @effects_hornet(iJumpMan)
    }

    if(pev(iJumpMan,pev_flags) & FL_ONGROUND)
    {
        pev(iJumpMan,pev_velocity,Vector);
        Vector[2] += get_pcvar_num(p_Force) + Power

        set_pev(iJumpMan,pev_velocity,Vector);
        set_pev(iJumpMan,pev_armorvalue,pev(iJumpMan,pev_armorvalue)+random_float(3.0,5.0))

        if ( get_user_armor(iJumpMan) > 100.0 )
        {
            set_user_armor(iJumpMan, 100);
        }
    }
}

public CmdGive(iJumpMan,level,cid)
{
    if(!cmd_access(iJumpMan,level,cid,2))
        return PLUGIN_HANDLED

    @advert()

    if(get_pcvar_num(p_Enable) == 1)
    {
        client_print(iJumpMan,print_chat,"[AMXX] Bee Armory works for everybody now.");
        return PLUGIN_HANDLED;
    }

    new Arg[MAX_PLAYERS + 1]
    read_argv(1,Arg, charsmax(Arg));

    new Target = cmd_target(iJumpMan,Arg,CMDTARGET_ALLOW_SELF);

    if(!Target)
        return PLUGIN_HANDLED

    read_argv(2,Arg,charsmax(Arg));

    new plName[MAX_PLAYERS + 1]
    get_user_name(iJumpMan,plName, charsmax(plName));

    if(str_to_num(Arg) == 1)
    {
        client_print(iJumpMan,print_chat,"[AMXX] Bee Armory enabled for: %s", plName);
        g_HasBealer[Target] = 1
    }
    else
    {
        client_print(iJumpMan,print_chat,"[AMXX] Bee Armory disabled for: %s", plName);
        g_HasBealer[Target] = 0
    }
    return PLUGIN_HANDLED
}

@effects_hornet(iJumpMan)
{
    new Vector[3];
    if(is_user_connected(iJumpMan))
    {
        new iCvar = get_pcvar_num(p_Effects)
        pev(iJumpMan,pev_origin,Vector);
        if(iCvar > 1)
        {
            message_begin( iCvar ? MSG_PVS : MSG_BROADCAST, SVC_TEMPENTITY,  Vector, 0 );
            write_byte(20);  //was 21  19-21 works
            engfunc(EngFunc_WriteCoord,Vector[0]);
            engfunc(EngFunc_WriteCoord,Vector[1]);
            engfunc(EngFunc_WriteCoord,Vector[2] + 16);
            engfunc(EngFunc_WriteCoord,Vector[0]);
            engfunc(EngFunc_WriteCoord,Vector[1]);
            engfunc(EngFunc_WriteCoord,Vector[2] + 200);
            write_short(g_recoil);
            write_byte(100);
            write_byte(255);
            write_byte(10); //life
            write_byte(400); //400  //line  //255 wow
            write_byte(10000); //500  //noise //500 wow
            write_byte(111);   // 111 255 255
            write_byte(111);
            write_byte(255);
            write_byte(50); //100  //bright
            write_byte(0);
            message_end();
        }

        if(iCvar > 2)
        {
            message_begin( iCvar ? MSG_PVS : MSG_BROADCAST, SVC_TEMPENTITY,  Vector, 0 );
            write_byte(TE_LARGEFUNNEL)
            engfunc(EngFunc_WriteCoord,Vector[0]);
            engfunc(EngFunc_WriteCoord,Vector[1]);
            engfunc(EngFunc_WriteCoord,Vector[2] - 200);
            write_short(g_recoil)
            write_short(0)  //flags
            message_end()
        }

        if(iCvar > 3)
        {
            message_begin( iCvar ? MSG_PVS : MSG_BROADCAST, SVC_TEMPENTITY,  Vector, 0 );
            write_byte(TE_STREAK_SPLASH);
            engfunc(EngFunc_WriteCoord,Vector[0]);
            engfunc(EngFunc_WriteCoord,Vector[1]);
            engfunc(EngFunc_WriteCoord,Vector[2] - 200);
            engfunc(EngFunc_WriteCoord,Vector[0]);
            engfunc(EngFunc_WriteCoord,Vector[1]);
            engfunc(EngFunc_WriteCoord,Vector[2] + 100);
            write_byte(200)
            write_short(10)
            write_short(10000)
            write_short(2000)
            message_end()
        }
    }
}

@advert()
{
    if(get_pcvar_num(p_Effects))
    {
        emessage_begin(MSG_BROADCAST,  SVC_TEMPENTITY,  { 0, 0, 0 }, 0 );
        ewrite_byte(TE_TEXTMESSAGE)
        ewrite_byte(0)      //(channel)
        ewrite_short(1450)  //(x) -1 = center)  //1200
        ewrite_short(8500)  //(y) -1 = center) //8500
        ewrite_byte(2)  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
        ewrite_byte(255)  //(red) - text color
        ewrite_byte(255)  //(green)
        ewrite_byte(0)  //(blue)
        ewrite_byte(2000)  //(alpha)
        ewrite_byte(0)  //(red) - effect color
        ewrite_byte(255)  //(green)
        ewrite_byte(255)  //(blue)
        ewrite_byte(2000)  //(alpha)
        ewrite_short(100)  //(fadein time)
        ewrite_short(100)  //(fadeout time)
        ewrite_short(100)  //(hold time)
        ewrite_short(150) //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
        ewrite_string("Bee Healer") //(text message) 512 chars max string size
        emessage_end()
    }
}
