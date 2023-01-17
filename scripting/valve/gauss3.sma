#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new const PLUGIN[] = "Gauss Jumping"
new const VERSION[] = "3"
new const AUTHOR[] = "Drak/SPiNX2018"

new g_HasJump[33]

new p_Enable
new p_Force

#define FLOAT_ANGLE -20.0
#define FLOAT_DELAY 0.1

new g_Shockwave
new g_Wow
new g_How
new g_Funny
new g_Bug
new g_Tug
new g_Hug

public plugin_precache() 
{
	g_Shockwave = precache_model("sprites/smoke.spr");
	g_How	    = precache_model("sprites/zerogxplode.spr");
	g_Wow       = precache_model("sprites/lgtning.spr");
	g_Funny     = precache_model("sprites/tongue.spr");
	g_Bug       = precache_model("models/out_teleport.mdl");
///        g_Hug       = precache_model("models/floater.mdl"); 	
///        g_Tug       = precache_model("models/sat_globe.mdl");
 	
	// 1 = All Players 
	// 0 = Players can use Rocket Jump only if an admin gave them the power
	p_Enable = register_cvar("amx_gauss_jump","1");
	p_Force = register_cvar("amx_gauss_forceadd","0");
	
	register_forward(FM_PlayerPreThink,"forward_PreThink");
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("amx_give_gaussjump","CmdGive",ADMIN_BAN,"<target> <1/0> Enables/Disables gauss jumping for the specfic player");
}

public client_putinserver(id)
	g_HasJump[id] = 0

public forward_PreThink(id)
{
	if(!is_user_alive(id))
		return FMRES_HANDLED
	
	if(g_HasJump[id] != 1 && get_pcvar_num(p_Enable) == 0)
		return FMRES_HANDLED
	
	static Clip,Ammo,UserAmmo[33]
	if(get_user_weapon(id,Clip,Ammo) == HLW_GAUSS)
	{
		new Button = pev(id,pev_button),OldButton = pev(id,pev_oldbuttons);
		
		if(Button & IN_ATTACK2 && !(OldButton & IN_ATTACK2)) 
			UserAmmo[id] = Ammo
		
		if(!(Button & IN_ATTACK2) && (OldButton & IN_ATTACK2))
		{
			switch(UserAmmo[id] - Ammo)
			{
				case 10..13:
					DoJump(id,600);
				case 5..9:
					DoJump(id,500);
				default:
					DoJump(id,350);
			}
		}
	}
	return PLUGIN_HANDLED
}
DoJump(id,Power)
{

	new Float:Vector[3]
	pev(id,pev_angles,Vector);

	if(Vector[0] > FLOAT_ANGLE)
		return
	bolts(id);
        if (is_user_admin(id) == 1)Effect1(id);
        if (is_user_admin(id) == 0)Effect2(id);

	pev(id,pev_origin,Vector);

        if(pev(id,pev_flags) & FL_ONGROUND)
        {
                pev(id,pev_velocity,Vector);
                Vector[2] += get_pcvar_num(p_Force) + Power

                set_pev(id,pev_velocity,Vector);
                //set_pev(id,pev_health,pev(id,pev_health)+random_float(10.0,3.0))
        }
}

public bolts(id)
{
#define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters
	new Dector[3];
	get_user_origin(id,Dector,1);
	message_begin(MSG_PVS, SVC_TEMPENTITY);
	write_byte(TE_LIGHTNING)
	write_coord(Dector[0])       // start position
	write_coord(Dector[1])
	write_coord(Dector[2])
	write_coord(Dector[0])      // end position 
	write_coord(Dector[1]+10)
	write_coord(Dector[2]+random_num(1000,6000))
	write_byte(random_num(15,40))        // life in 0.1's 
	write_byte(random_num(300,700))        // width in 0.1's 
	write_byte(random_num(300,577)) // amplitude in 0.01's 
	write_short(g_Wow)     // sprite model index
	message_end()
}

public Effect1(id)
{
        new Float:Vector[3]
        pev(id,pev_origin,Vector);

        message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(id);  //(entity:attachment to follow)
	write_short(g_Wow);
	write_byte(4); //(life in 0.1's)
	write_byte(20); //(line width in 0.1's)
	write_byte(0);  //(red)
	write_byte(255); //(green)
        write_byte(67); //(blue)
        write_byte(333); //(brightness)
        message_end();
	
	gas(id);

        message_begin(MSG_PVS, SVC_TEMPENTITY)
        write_byte(TE_TEXTMESSAGE)
        write_byte(0)      //(channel)
        write_short(100)  //(x) -1 = center)
        write_short(10000)  //(y) -1 = center)
        write_byte(2)  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
        write_byte(15)  //(red) - text color
        write_byte(40)  //(green)
        write_byte(255)  //(blue)
        write_byte(2000)  //(alpha)
        write_byte(255)  //(red) - effect color
        write_byte(40)  //(green)
        write_byte(12)  //(blue)
        write_byte(2000)  //(alpha)
        write_short(100)  //(fadein time)
        write_short(100)  //(fadeout time)
        write_short(100)  //(hold time)
        write_short(150) //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
        write_string("Gauss made in [USA]") //(text message) 512 chars max string size
        message_end()
        
	bom(id);
}

public bom(id)
{
	 new Float:Sector[3];
         pev(id,pev_origin,Float:Sector);
         message_begin(MSG_PVS, SVC_TEMPENTITY);
         write_byte(TE_EXPLOSION)
         write_coord(floatround(Sector[0])); //xyz
         write_coord(floatround(Sector[1]));
         write_coord(floatround(Sector[2]));
         write_short(g_How);
         write_byte(random_num(100,1000)); //scal
         write_byte(random_num(5,200)); //framrate
         write_byte(TE_EXPLFLAG_NONE); //flags
         message_end();
}

public Effect2(id)
{
        new Float:Vector[3]
        pev(id,pev_origin,Vector);

	gas(id);

        message_begin(MSG_PVS, SVC_TEMPENTITY);
        write_byte(100);  //#define TE_LARGEFUNNEL              100
        write_coord(floatround(Vector[0]+random_num(-11,11)));
        write_coord(floatround(Vector[1]+random_num(-11,11)));
        write_coord(floatround(Vector[2]+random_num(-11,11)));
        write_short(g_Bug);
 //       switch(random_num(0,2)) {

///        case 0: write_short(g_Bug); //spr ind
//        case 1: write_short(g_Hug); //spr ind
//        case 2: write_short(g_Tug); //spr ind
/*                case 3: write_short(g_Fun0) //spr ind
                case 4: write_short(g_Fun1)
                case 5: write_short(g_Fun2)
                case 6: write_short(g_Fun3)
                case 7: write_short(g_Fun4)
*/
///        }
        write_short(0); //flags
        message_end();

}

public gas(id)
{
	new Fector[3];
	get_user_origin(id,Fector,1);
        message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
        write_byte(random_num(19,21));

        write_coord(Fector[0]);  //pos x
        write_coord(Fector[1]);
        write_coord(Fector[2] + 16);  //pos z
        write_coord(Fector[0]);
        write_coord(Fector[1]);
        write_coord(Fector[2]+random_num(100,200)); //axis z
        switch(random_num(0,3)) {

        case 0: write_short(g_Shockwave); //spr ind
	///server_print("case 0")
        case 1: write_short(g_Wow); //spr ind
	///server_print("case 1")
        case 2: write_short(g_How); //spr ind
	///server_print("case 2")
        case 3: write_short(g_Funny); //spr ind
	///server_print("case 3")
	}
	server_print("gas past cases")
        write_byte(random_num(1,5)); //start framing
        write_byte(random_num(7,80)); //frame rate
        write_byte(random_num(20,50)); //life
        write_byte(random_num(20,150)); //line W
        write_byte(random_num(20,300)); //noise amp

        write_byte(random_num(20,255));  //R
        write_byte(random_num(11,255));  //G  //was 128
        write_byte(random_num(0,255)); //blu
        write_byte(random_num(100,1000)); //bright

        write_byte(random_num(1,33)); //scrool spped
        message_end();
}


public CmdGive(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
		
	if(get_pcvar_num(p_Enable) == 1) 
	{
		client_print(id,print_console,"[AMXX] Gauss Jumping is currently set to be enabled on all players.");
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
	
	if(str_to_num(Arg) == 1) {
		client_print(id,print_console,"[AMXX] GaussJump enabled for: %s",plName);
		g_HasJump[Target] = 1
	} else {
		client_print(id,print_console,"[AMXX] GaussJump disabled for: %s",plName);
		g_HasJump[Target] = 0
	}
	return PLUGIN_HANDLED
}
