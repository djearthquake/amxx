#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>

new const PLUGIN[] = "Magic_Missile"
new const VERSION[] = "B"
new const AUTHOR[] = "SPiNX"

new g_HasMagic[33]

new p_Enable
new p_Force

#define FLOAT_ANGLE -20.0
#define FLOAT_DELAY 0.1

new g_recoil

public plugin_precache()
{
    g_recoil = precache_model("sprites/redflare1.spr");

    // 1 = Everyody has magic missile when using bow.
    // 0 = Admin control magic missiles.
    p_Enable = register_cvar("amx_magic_missile","1");
    p_Force = register_cvar("amx_magic_forceadd","5000");

    register_forward(FM_PlayerPreThink,"forward_PreThink");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_concmd("amx_give_magicmissile","CmdGive",ADMIN_BAN,"<target> <1/0> Enables/Disables magic missile for a player");
}

public client_putinserver(id)
    g_HasMagic[id] = 0

public forward_PreThink(id)
{
    if(!is_user_alive(id))
    return FMRES_HANDLED

    if(g_HasMagic[id] != 1 && get_pcvar_num(p_Enable) == 0)
    return FMRES_HANDLED

    static Clip,Ammo,UserAmmo[33]
    if(get_user_weapon(id,Clip,Ammo) == HLW_CROSSBOW)
    {
        new Button = pev(id,pev_button),OldButton = pev(id,pev_oldbuttons);

        if(Button & IN_ATTACK && !(OldButton & IN_ATTACK))
        UserAmmo[id] = Ammo

        if(!(Button & IN_ATTACK) && (OldButton & IN_ATTACK))
        {
            switch(UserAmmo[id] - Ammo)
            {
                case 10..13:
                DoMM(id,5000);
                case 5..9:
                DoMM(id,3000);
                default:
                DoMM(id,2000);
            }
        }
    }
    return PLUGIN_HANDLED
}

DoMM(id,Power)
{
    new Float:Vector[3]
    pev(id,pev_angles,Vector);

    if(Vector[0] > FLOAT_ANGLE)
    return

    pev(id,pev_origin,Vector);

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
    write_byte(random_num(19,21));

    engfunc(EngFunc_WriteCoord,Vector[0]);
    engfunc(EngFunc_WriteCoord,Vector[1]);
    engfunc(EngFunc_WriteCoord,Vector[2] + 16);
    engfunc(EngFunc_WriteCoord,Vector[0]);
    engfunc(EngFunc_WriteCoord,Vector[1]);
    engfunc(EngFunc_WriteCoord,Vector[2] + 200);

    write_short(g_recoil);
    write_byte(0);
    write_byte(0);
    write_byte(2);
    write_byte(111);
    write_byte(100);

    write_byte(random_num(0,255)); //RGB  111 255 255
    write_byte(random_num(0,255));
    write_byte(random_num(0,255));

    write_byte(100);

    write_byte(0);
    message_end();

    #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters
    new Dector[3];
    get_user_origin(id,Dector,1);
    message_begin(0,23);
    write_byte(TE_LIGHTNING)
    write_coord(Dector[0])       // start position
    write_coord(Dector[1])
    write_coord(Dector[2]-30)
    write_coord(Dector[0])      // end position
    write_coord(Dector[1]+10)
    write_coord(Dector[2]+random_num(300,6000))
    write_byte(random_num(15,50))        // life in 0.1's
    write_byte(random_num(300,700))        // width in 0.1's
    write_byte(random_num(100,300)) // amplitude in 0.01's
    write_short(g_recoil)     // sprite model ind
    message_end()

    message_begin(0,23);
    write_byte(TE_TEXTMESSAGE);
    write_byte(0);      //(channel)
    write_short(7000);  //(x) -1 = center)
    write_short(7000);  //(y) -1 = center)
    write_byte(2);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    write_byte(0);  //(red) - text color
    write_byte(255);  //(green)
    write_byte(64);  //(blue)
    write_byte(200);  //(alpha)
    write_byte(255);  //(red) - effect color
    write_byte(0);  //(green)
    write_byte(0);  //(blue)
    write_byte(25);  //(alpha)
    write_short(100);  //(fadein time)
    write_short(300);  //(fadeout time)
    write_short(300);  //(hold time)
    write_short(250); //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
    write_string("Magic Missile"); //(text message) 512 chars max string size
    message_end();

    if(pev(id,pev_flags) & FL_ONGROUND)
    {
        pev(id,pev_velocity,Vector);
        Vector[2] += get_pcvar_num(p_Force) + Power

        set_pev(id,pev_velocity,Vector);
        set_pev(id,pev_health,pev(id,pev_health)+random_float(50.0,70.0))
        if ( get_user_health(id) > 101.0 )set_user_health(id, 100);

    }
}

public CmdGive(id,level,cid)
{
    if(!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED

    if(get_pcvar_num(p_Enable) == 1)
    {
        client_print(id,print_console,"[AMXX] Magic Missile works for everybody now.");
        return PLUGIN_HANDLED;
    }
    new Arg[33]
    read_argv(1,Arg,32);

    new Target = cmd_target(id,Arg,CMDTARGET_ALLOW_SELF);
    if(!Target)
    return PLUGIN_HANDLED

    read_argv(2,Arg,32);

    new plName[33]
    get_user_name(id,plName,32);

    if(str_to_num(Arg) == 1)
    {
        client_print(id,print_console,"[AMXX] Magic Missile enabled for: %s",plName);
        g_HasMagic[Target] = 1
    } 
    else 
    {
        client_print(id,print_console,"[AMXX] Magic Missile disabled for: %s",plName);
        g_HasMagic[Target] = 0
    }
    return PLUGIN_HANDLED
}
