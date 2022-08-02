/**
*                    GNU AFFERO GENERAL PUBLIC LICENSE
*                       Version 3, 19 November 2007
*
* Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
* Everyone is permitted to copy and distribute verbatim copies
* of this license document, but changing it is not allowed.
* 
* Remainder of agreement is past last line of code.
*/

/*Elements☀ ☁ ☂ ☃ ☉ ☼ ☽ ☾ ♁ ♨ ❄ ❅ ❆ ◐ ◑ ◒ ◓ ◔ ◕ ◖ ◗  ♘ ♞ ϟ THIS IS COPYLEFT!!◐	◖	◒	◕ 	◑	◔	◗	◓ 
 * 
   * 
	 * 
	 * 
      Macedonian Arts and Sciences https://www.history.com/topics/ancient-rome/macedonia
       Alexandria, an ancient Egyptian town thought to be founded by Alexander the Great, became a major hub of science during this period as well. 
        Greek mathematician Euclid, who taught in Alexandria, founded the study of geometry with his mathematical treatise
	    The Elements. https://www.history.com/topics/ancient-rome/macedonia
	 * 
  * Say climate, temp, or weather for conditions.

  * Humidity, Clouds, Sunrise/Sunset all effect visibility.

  * Welcome to the b-team

  * Welcome to Des Moines! Visibility is 1609'. Temperature is 9° while forecasted to be 5°

  * |||||||||||code 800||||||||||Element:  ..::DRY::.. ..fair.. | humidity: 72 | epoch♞dawn 1551876058 epoch♘dusk 1551917455

  * Skyname is 3dm_bikini

  * Sunrise hour 7

  * Sunset hour 19

  * PreDawn::Dawn is in 337 min. About 5 hours.  Time is 1:3
 
  * PLUGIN WAS A FORK FROM AUTOWEATHER. DAY 1 PORTED TO YAHOO. PLANNED ON WIND FACTOR FOR SNIPE AND AFTER YAHOO HACK I MADE IT HAPPEN WITH OPENWEATHER TOKEN API.
  * Just make an alias in server.cfg so you can swap cities by typing and name or loading as cs_italy to Italy or dod_charlie to France and so on etc.
  * 
  * alias az "region 5745656"
  * 
  * alias neutral "exec element.cfg"
		* neutral
	 * element.cfg 		
		 * time 0			
			 * lums 0					
				*	 * dark 18					
			* 
		* 
	 ☼
	◖ ◗
	 ϟ
CVARS:
dark	<0-25> D: 24| The higher the number, the darker after sunset.
lums	<0-25> D: 0	| The lower the number, the brighter it gets at noon.
time	<0-24> D: 0	| Manually sets timeOday 0 = off
region	<region>	| "region" is "4887398" Get from openweathermap.org by looking at weather in your city click a pager deeper on something and copy the ID from end of URL.
uplink	<GETdataURL>| "uplink" is "GET /data/2.5/weather?id="
day		<0-24> D: 0 | Override sunrise hour Y38K futureproof. Dark is unpopular smaller darktimeframe keeps 'most' players!
night	<0-24> D: 0 | Override sunset hour Y38K futureproof. Dark is unpopular smaller nighttimeframe keeps players!
To the old regular who used to use the NightVision in the days long before I encountered this source looking for StatsMe source ignorant to 
new stuffs like gamemonitor I found this broken, knew my HTTP 1.0 since I'm an old cat and fixed it then ported to no end.
 * 
 *
 * 
That guy who was odd always using night vision became one of the best players. When it would go dark he would smile and wreck havoc.
I put a vote_dark to reverse the process or to leet it out using other mod from amxx not here.
 * 
 * 
Admin only commands are dry, flash, feed, snow, wet. DRY ends all weather. FEED runs the sockets routine to acquire the weather manually now.
 * FLASH adds a nice touch when people are complaining it is too dark and you want some random storm light. MOST USERS PANICK AND DISCO! I love it. Not that part.
 * 
Feed is deprecated as feed is run if there is no data in the vault on client connects now instead of map change.
 * 
Extra care was put into the error system of the sockets. It is Cadillac now with LIB6 intelligence. 
 * 
 * 
 * 
Also ambient sound I will put back in or allow a noob to since I am pro team all the way. The idea I have is 3 sounds random to match the effect's meanness.
 * 
 * I can take care of adding LighteningϟStrike random damage to the worse of the storm codes. Ah to bring back 1999 CS with the random strikes using AMXX.
 Oh yes I can make rainbows and suspend them in the air quite easily with this built engine. Screenshots are welcome.

CL_COMMANDS

say temp, weather, or climate	- displays weather feed
say /mytemp for local temp
say /news for news*/

#include <amxmodx>		/*All plugins need*/
#include <amxmisc>		/*cstrike checks && task_ex*/
#include <sockets>		/*feed needs*/
#include <fakemeta>		/*PEV*/
#include <nvault>		/*feed storage Global*/

#define DEBUG
#define PFOG 85 //Percent over creates fog.
///#define _UNIT &units=imperial& ///feel free to use metric or imperial
///#define _TOKEN APPID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ///get 32-bit key from API sponser openweathermap.org
///#define CODE 4887398 ///des moines 
///#pragma codepage 
///#define LUM_DEBUG

#define VERSION "Fif" //5th Element(s) get it after all these years and updates which are too many to outline!!
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
#define fm_set_lights(%1)    engfunc(EngFunc_LightStyle, 0, %1)

#define Radian2Degree(%1) (%1 * 180.0 / M_PI)

new sprLightning, sprFlare6, g_F0g, g_Saturn; /*Half-Life Fog v.1 2019*/

new g_cvar_minlight, g_cvar_maxlight, g_cvar_region, g_cvar_uplink, g_cvar_time, g_cvar_day, g_cvar_night;
new g_sckelement, g_DeG, g_SpeeD, g_temp, g_curr_temp, g_temp_min, g_element, g_hum, g_heat, g_code, g_visi;
new g_Epoch, g_env, g_fog, g_sunrise, g_sunset, g_TimeH, g_Now, g_location[32];
new bird, g_figure, g_Nfig, g_Nn, g_Up, g_Dwn, g_Ti;
new g_LightLevel[][]=   { "z","y","x","w","v","u","t","s","r","q","p","o","n","m","l","k","j","i","h","g","f","e","d","c","b","a" };
new g_env_name[][]=     { ""," ..::DRY::.. "," ..::WET::.. "," ..::ICE::.. " }; // APPLIED SIM: (1-3)(no rain, rain, snow)
new g_element_name[][]= { "","..fair..","..cloud..","..partial.." };
new g_skysuf[6][3]=     { "up", "dn", "ft", "bk", "lf", "rt" };
new g_Pfog = PFOG
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/*			0	1	2	3	4						/
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/			normal	sunrise	noon	sunset	night					       */
/////////////////////////////////////////////////////////////////////////////////////////////////////////	
new g_skynames[][] =
		{
		"sunny","3dm_bikini","ava","sunset1","52h03",     /*X҉**☀**SUNNY**☀***X҉*/
		"52h05","nordawn","tornsky","blue","52h03",       /*X҉*PARTLY☂CLOUDED*X҉*/
		"sunbeams_","morningdew","cx","st","paris_night", /*X҉**ϟ*CLOUDED*ϟ***X҉*/
		"CCCP","CCCP","CCCP","dashnight256","CCCP"        /*X҉****☾FOGGY☽*****X҉*/
		}
/////////////////////////////////////////////////////////////////////////////////////////////////////////


public plugin_init()

{
	{
		{
		register_plugin("Elements", VERSION, ".sρiηX҉.");
		register_cvar("element_version", VERSION, FCVAR_SERVER);

		///native register_clcmd(const client_cmd[], const function[], flags = -1, const info[] = "", FlagManager = -1, bool:info_ml = false);

		register_clcmd("say /news", "ClCmd_NewS", 0, "<url>");
		register_clcmd("say /mytemp", "ClCmd_TemP", 0, "<url>");

		register_clcmd("snow", "ClCmd_hl_snow")  // , "test of hl1 weather")
		register_clcmd("dry", "ClCmd_hl_dry")   // , "test of hl1 weather")
		register_clcmd("wet", "ClCmd_hl_precip")   // , "test of hl1 weather")
		register_clcmd("fog", "ClCmd_hl_fog")   // , "test of hl1 weather")
		register_clcmd("flash", "ClCmd_FlasheS")   // , "test of hl1 weather")

		register_clcmd("feed", "ClCmd_get_element") /// "test of feed")

		g_cvar_minlight = register_cvar("dark", "23");  //not too dark
		g_cvar_uplink = register_cvar("uplink", "GET /data/2.5/weather?id=");
		g_cvar_maxlight = register_cvar("lums", "0");  //vivid at noon
		g_cvar_time = register_cvar("time", "0");      //auto light Time of Day
		g_cvar_day = register_cvar("day", "0");      //sunrise Hour
		g_cvar_night = register_cvar("night", "0");     //night fall Hour
		g_cvar_region = register_cvar("region", "4887398&units=imperial&APPID=04cfbf74c089b9d44e1a32ccb4e5cf83");
		AutoExecConfig(.autoCreate = true, .name = "Element")
		
		/*
		*
		* new num[3];
		* bird = nvault_open("element");
		* nvault_set(bird, "Pfog", num);
		* Pfog = str_to_num(num);
		*
		*/


		register_cvar("element_hud", "200");
		register_clcmd("say temp", "showinfo");
		register_clcmd("say weather", "showinfo");
		register_clcmd("say climate", "showinfo");

	        if (task_exists(167) ) return;
		set_task_ex(10.0, "get_element", 167, .flags = SetTask_AfterMapStart);

/*		get_element();*/
		daylight();
		set_task(15.0, "daylight", _, _, _, "b");
		}
	}
}
	
public ClCmd_NewS(id, level, cid)

{
		if ( cstrike_running() )
	{	
		{
		new motd[32];
		format(motd, 31, "<html><meta http-equiv='Refresh' content='0; URL=https://openweathermap.org/weather-conditions'><body BGCOLOR='#FFFFFF'><br><center>Loading</center></HTML>");
		show_motd(id, motd, "International and local news");
		}
	}
}

public ClCmd_TemP(id, level, cid)

{
		if ( cstrike_running() ) 
	{
		{
		new motd[32];
		format(motd, 31, "<html><meta http-equiv='Refresh' content='0; URL=https://google.com/search?q=weather'><body BGCOLOR='#FFFFFF'><br><center>If we can not determine your country off your IP then this will display generic weather page...</center></HTML>");
		show_motd(id, motd, "Weather Browser");
		}
	}
}

public plugin_end()

{
	{
		{
		nvault_close(bird);
		}
	}
}

public plugin_precache()

{
	{
		{

		g_F0g = precache_model("sprites/ballsmoke.spr"); 
		sprFlare6 = precache_model("sprites/Flare6.spr");
		g_Saturn = precache_model("sprites/zerogxplode.spr");

		sprLightning = precache_model("sprites/lgtning.spr");
		bird = nvault_open("element");
		
		g_sunrise = nvault_get(bird, "sunrise");
		g_sunset = nvault_get(bird, "sunset");
		g_visi = nvault_get(bird, "visi");
		g_heat = nvault_get(bird, "heat");
		g_temp = nvault_get(bird, "maxtemp");

		g_hum = nvault_get(bird, "humidity");
		g_code = nvault_get(bird, "code");
		nvault_get(bird, "location", g_location,31);
		

		nvault_get(bird, "env", g_env_name, 2);
		nvault_get(bird, "element", g_element_name, 8);

		
		nvault_prune(bird, 0, get_systime() - (60 * 60 * 2)); ///2 hr pruning
		makeelement();
		}
	}
}

public client_putinserver(id)

{
	{
		{
		client_cmd(id, "cl_element 1");
		set_task(10.0, "daylight");
		if (!is_user_bot(id)) set_task(45.0, "display_info", id);
		///g_code = nvault_get(bird, "code");
		////if (g_code == 0)
		set_task(random_float(0.1,1.0), "Et_Val", id);
		}
	}
}


public display_info(id)

{
	{
		{
		client_print(id, print_chat, "Say climate, temp, or weather for conditions.");
		client_print(id, print_chat, "Humidity, Clouds, Sunrise/Sunset all effect visibility.");
		}
	}
}

public showinfo(id)

{	
	{
		{
		set_hudmessage(random_num(0,255),random_num(0,255),random_num(0,255), -1.0, 0.55, 1, 2.0, 3.0, 0.7, 0.8, 3);  //-1 auto makes flicker				

		client_print(id, print_console, "Welcome to %s! Visibility is %d'. Temperature is %d° while forecasted to be %d°", g_location, g_visi, g_heat, g_curr_temp);
		/*		https://www.amxmodx.org/api/amxmodx/set_hudmessage
		native set_hudmessage(red = 200, green = 100, blue = 0, Float:x = -1.0, Float:y = 0.35, effects = 0, Float:fxtime = 6.0, Float:holdtime = 12.0, Float:fadeintime = 0.1, Float:fadeouttime = 0.2, channel = -1);
		native random_num(a, b);
		https://www.amxmodx.org/api/amxmodx/random_num*/
		client_print(id, print_console, "|||||||||||code %d||||||||||Element: %s%s | humidity: %d | epoch♞dawn %d epoch♘dusk %d", g_code, g_env_name[g_env], g_element_name[g_element], g_hum, g_sunrise, g_sunset);

		if ( cstrike_running() ) 
		{
		show_hudmessage(id, "╚»★Welcome to %s★«╝^nThe temp is now %d° and was forecasted as %d°.^nSim:%s Sky: %s ^nHumidity %d.^nServer set fog to %d. ^n^n^nCS1.6|Say /news /mytemp for more.", g_location, g_curr_temp, g_heat, g_env_name[g_env], g_element_name[g_element], g_hum, g_Pfog);
		}
		else
		{
		show_hudmessage(id, "Welcome to %s.^nThe temp is %d and was forecasted as %d.^nSim:%s Sky: %s ^nHumidity %d.^nServer set fog to %d. ^n^n^nCS1.6|Say /news /mytemp for more.", g_location, g_curr_temp, g_heat, g_env_name[g_env], g_element_name[g_element], g_hum, g_Pfog);
		}
		epoch_clock();
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public epoch_clock() 
{
	{
		{
/////////////////////////////////////////
		g_Epoch = get_systime(0);
		new g_SkyNam[16];
		get_cvar_string("sv_skyname",g_SkyNam,15);
//////////////////////////////////////////native format_time(output[], len, const format[], time = -1);///////////
//      Time feed is in Epoch from sockets.        
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/// g_sunrise and g_sunset are global parameters from feed.
		
		//g_sunrise = nvault_get(bird, "sunrise");
		//g_sunset = nvault_get(bird, "sunset");
		
		new g_UpMin  =  ( g_sunrise - g_Epoch ) / 60 ;
		new g_DownMin =  ( g_sunset - g_Epoch ) / 60 ;
		///native floatround(Float:value, floatround_method:method=floatround_ceil);
		new g_Dusk = floatround((Float:g_DownMin / 60.0), floatround_round);
		
		
		new g_Hour[3], g_Minut[3], g_Now;

		get_time("%H", g_Hour, 2);
		new g_TimeH = str_to_num(g_Hour);

		get_time("%M", g_Minut, 2);
		new g_TimeM = str_to_num(g_Minut);
	
		g_Now = ( "%i %i", g_TimeH, g_TimeM ) ;

		new g_UoopHours  =  ( g_sunrise - g_Epoch ) / 3600 ; /*hrs until sunup*/
		new g_DownHours  =  ( g_sunset - g_Epoch ) / 3600 ; /*hrs until sundown*/

		new high, S_EeD1, S_EeD2, offset;
		new g_RisE = (g_TimeH + g_UoopHours)
		new g_SeeT = (g_TimeH + g_DownHours)
		new g_See2 = (g_TimeH + g_Dusk)
		
		high = 23;
		new low = 0;
		
		S_EeD1 = g_RisE;
		S_EeD2 = g_SeeT;
		offset = -23;

		g_figure = Set_Roll(high, low,S_EeD1, offset);
		//nvault_set(bird, "day", g_figure);
		g_Nfig = Set_Roll(high, low,S_EeD2, offset);
		new dark = Set_Roll(high, low,g_See2, offset);
		new tst[2];
		copy("tst", 2, "dark");
		nvault_set(bird, "night", tst);
				

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		new id;
		client_print(id, print_console, "Skyname is %s",g_SkyNam);
		client_print(id, print_console, "Sunrise hour %i",g_figure);
		client_print(id, print_console, "Sunset hour %i",g_Nfig);
		client_print(id, print_console, "Adjusted sunset hour %i",dark);

		if( (g_UpMin) < -1) 
		{ 
		server_print("Post Dawn");
		log_amx("Dusk is in %i min. About %i hours. Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);	
		client_print(id, print_console, "PreDusk::Dusk is in %i min. About %i hours.  Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);
		client_print(id, print_console, "PostDawn::Dawn was %i min ago. About %i hours ago.  Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		}	
		if( (g_UpMin) > 1) 
		{
		log_amx("Dawn is in %i min. About %i hours. Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		client_print(id, print_console, "PreDawn::Dawn is in %i min. About %i hours.  Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		}
		if( (g_DownMin) < -1 )
		{
		server_print("Post Dusk");
		log_amx("Dawn is in %i min. About %i hours. Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		}
///		new g_Dusk;
///		g_Dusk = clamp(g_DownMin, -400, -1);
		if( (g_DownMin == g_Dusk))
		{
		log_amx("Dusk was %i min ago. About %i hours. Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);
		client_print(id, print_console, "PostDusk::Dusk was %i min ago. About %i hours ago.  Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);
		}
		
		}
	}
}

public ClCmd_get_element(id, level, cid)

{
	{	
		if (is_user_admin(id) == 1)

		{
		#if defined DEBUG
		log_amx("Starting the sockets routine...");
		#endif
		//stock has_flag(id, const flags[])
		new Soc_O_ErroR, constring[512], uplink[25], region[63];
		get_pcvar_string(g_cvar_region, region, 63);
		get_pcvar_string(g_cvar_uplink, uplink, 25);
		g_sckelement = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
		format(constring, 512, "%s%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n", uplink, region);
		write_web(constring);

		#if defined DEBUG
		log_amx("This is where we are trying to get weather from");
		log_amx(constring);
		log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
		#endif

		read_web();
		}
	}
}


public Et_Val(id)

{
	
	{
	
		{
		
		if (is_user_admin(id) == 1) set_task(random_float(0.1,1.0), "get_element");
		set_task_ex(random_float(0.1,1.0), "ring_saturn", 223, .flags = SetTask_RepeatTimes, .repeat = 10);
		set_task_ex(random_float(0.1,1.0), "HellRain_Blizzard", 226, .flags = SetTask_RepeatTimes, .repeat = 5);
		if (g_code >= 0)finish_weather()
		set_task_ex(random_float(1.0, 2.0), "ring_saturn", 556, .flags = SetTask_RepeatTimes, .repeat = 10);
		
		}
 
	}
	
}

finish_weather()
{	
	{
		{
		if (task_exists(556)) remove_task(556);
		}
	}
}



public get_element()

{
	{
		{
		#if defined DEBUG
		log_amx("Starting the sockets routine...");
		#endif
		new Soc_O_ErroR2, constring[512], uplink[25], region[63];
		get_pcvar_string(g_cvar_region, region, 63);
		get_pcvar_string(g_cvar_uplink, uplink, 25);
		g_sckelement = socket_open("api.openweathermap.org", 80, SOCKET_TCP, Soc_O_ErroR2, SOCK_NON_BLOCKING|SOCK_LIBC_ERRORS);
		format(constring, 512, "%s%s&u=c HTTP/1.0^nHost: api.openweathermap.org^n^n", uplink, region);
		write_web(constring);
		#if defined DEBUG
		log_amx("This is where we are trying to get weather from");
		log_amx(constring);
		log_amx("Debugging enabled::telnet api.openweathermap.org 80 copy and paste link from above into session.");
		#endif
		read_web();
		}
	}
}

public write_web(text[512])

{
	{	server_print("soc writable");
		{
		if (socket_is_writable(g_sckelement, 100000))
		socket_send(g_sckelement, text,511);
		}
	}	server_print("writing the web");		
}


///native nvault_set(vault, const key[], value[], maxlen, &timestamp);

public read_web()

{
		server_print("reading the web")
		new buf[512];
		if (socket_is_readable(g_sckelement, 100000))
		socket_recv(g_sckelement, buf, 511);
		if (!equal(buf, ""))
	{
		if (containi(buf, "name") >= 0)
	{
		new out[32];
		copyc(out, 24, buf[containi(buf, "name") + 7], '"');
		server_print("writing the name")
		
		#if defined DEBUG
		log_amx("Location: %s", out);
		#endif
		
		nvault_set(bird, "location", out);
		g_location = out;

	}
		if (containi(buf, "temp") >= 0 && g_heat == 0)
	{
		server_print("Ck real temp time..")
		
		new out[32]
		copyc(out, 6, buf[containi(buf, "temp") + 6], '"');
		replace(out, 6, ":", "");
		replace(out, 6, ",", "");
		
		#if defined DEBUG
		log_amx("Temperature: %s", out);
		#endif
		
		nvault_set(bird, "heat", out);
		
		g_heat = str_to_num(out);
	}
		if (containi(buf, "temp_max") >= 0 && g_temp == 0)
	{
		new out[32];
		copyc(out, 4, buf[containi(buf, "temp_max") + 10], '"');
		replace(out, 4, ",", "");
		replace(out, 4, "}", "");
		
		#if defined DEBUG
		log_amx("High of: %s", out);
		#endif
		
		nvault_set(bird, "maxtemp", out);
		g_temp = str_to_num(out);
	}
		if (containi(buf, "temp_min") >= 0 && g_temp_min == 0) {
		new out[32];
		
		copyc(out, 4, buf[strfind(buf, "temp_min") + 10], '"');
		replace(out, 4, ",", "");

		#if defined DEBUG
		log_amx("Low of: %s", out);
		#endif
		
		nvault_set(bird, "mintemp", out);
		g_temp_min = str_to_num(out);
	}
		if (containi(buf, "visibility") >= 0) {
		new out[32];
		copyc(out, 6, buf[containi(buf, "visibility") + 12], '"');
		replace(out, 6, ",", "");
		replace(out, 6, ":", "");
		
		#if defined DEBUG
		log_amx("Visibility: %s", out);
		#endif
		
		nvault_set(bird, "visi", out);
		g_visi = str_to_num(out);
	}
		if (containi(buf, "humidity") >= 0 && g_hum == 0) {
		new out[32];
		copyc(out, 6, buf[containi(buf, "humidity") + 10], '"');
		replace(out, 6, ",", "");
		
		#if defined DEBUG
		log_amx("Humidity: %s", out);
		#endif
		
		nvault_set(bird, "humidity", out);
		g_hum = str_to_num(out);
	}
	
		if (containi(buf, "sunrise") >= 0 && g_sunrise == 0)
	{
		new out[32];
		copy(out, 10, buf[strfind(buf, "sunrise") + 9]);
		replace(out, 10, "&", "");
		
		#if defined DEBUG
		log_amx("Sunrise: %s", out);
		#endif

		nvault_set(bird, "sunrise", out);
		g_sunrise = str_to_num(out);
	}
		if (containi(buf, "deg") >= 0 && g_DeG == 0)
	{
		new out[32];
		copy(out, 3, buf[strfind(buf, "deg") + 5]);
		replace(out, 3, "&", "");
		replace(out, 3, "}", "");		
		
		#if defined DEBUG
		log_amx("Deg: %s", out);
		#endif

		nvault_set(bird, "deg", out);
		g_DeG = str_to_num(out);
	}
	
		if (containi(buf, "speed") >= 0 && g_SpeeD == 0)
	{
		new out[32];
		copy(out, 5, buf[strfind(buf, "speed") + 7]);
		replace(out, 5, ":", "");
		replace(out, 5, ",", "");
	
		#if defined DEBUG
		log_amx("Speed: %s", out);
		#endif

		nvault_set(bird, "speed", out);
		g_SpeeD = str_to_num(out);
	}
	
	///////////////////////////////
		if (containi(buf, "sunset") >= 0 && g_sunset == 0)
	{
		new out[32];
		copy(out, 10, buf[strfind(buf, "sunset") + 8]);
		replace(out, 10, "&", "");
		
		#if defined DEBUG
		log_amx("Sunset: %s", out);
		#endif
		
		nvault_set(bird, "sunset", out);
		g_sunset = str_to_num(out);
	
	}
		if (containi(buf, "[") >= 0) {
		new out[32];
		copy(out, 3, buf[strfind(buf, "[") + 7]);
		replace(out, 3, "&", "");
		replace(out, 3, "#", "");
		
		#if defined DEBUG
		log_amx("Code: %s", out);
		#endif
		
		nvault_set(bird, "code", out);
		g_code = str_to_num(out);
		
		if (g_code == 800)
	{
		g_env = 1;
		g_element = 1;
	}
		if (g_code >= 801 && g_code <= 803)
	{
		g_env = 1;
		g_element = 2;
	}
		if (g_code >= 701 && g_code <= 762)
	{
		g_env = 1;
		g_element = 2;
	}
		if (g_code == 804)
	{
		g_element = 3;
		g_env = 1;
	}
		if (g_code >= 200 && g_code <= 531)
	{
		g_env = 2;
		g_element = 3;
	}
		if (g_code >= 600 && g_code <= 602)
	{

		g_element = 2;
		g_env = 3;
	}
		if (g_code >= 611 && g_code <= 622)
	{
		g_element = 3;
		g_env = 3;
	}
		new num[1];
		num_to_str(g_env, num, 1);
		nvault_set(bird, "env", num);
		server_print("Finished reading code and checking sunrise time...")
		num_to_str(g_element, num, 1);
		nvault_set(bird, "element", num);
	}
		set_task(0.5, "read_web");
	}  
		else 
	{
		socket_close(g_sckelement);
                server_print("finished reading")

	}        
}

public makeelement()

{
	{	
		///HL_WeatheR();
		{
		new humi = nvault_get(bird, "humidity");
		new e = nvault_get(bird, "env");

		HL_WeatheR();
		if ( humi >  PFOG ) 
		makeFog(humi);
	
		if ( cstrike_running() )	
	
		switch (e)
		
		{
		case 2:
		{
		fm_create_entity("env_rain");
		}
		case 3:
		{
		fm_create_entity("env_snow");
		}
		case 4:
		{
		fm_create_entity("env_rain")
		fm_create_entity("env_snow")
		hl_precip()
		hl_snow();
		}
		
		}
		set_sky(humi);
		}
	}
		///HL_WeatheR();
}

		/*HL_WeatheR();*/

public HoS()
{
	{
		{
		get_element();
		}
	}
}

public HL_WeatheR()

{
		{
				{

				if ( cstrike_running() ) return;

				new humi = nvault_get(bird, "humidity");
				new e = nvault_get(bird, "env");
				if ( humi > PFOG )
				makeFog(humi);

				switch (e)
				{
				case 2:
				{
		hl_precip();
				}
				case 3:
				{
		hl_snow();
				}
				case 4:
				{
		hl_precip()
		hl_snow();

				}
		}
				set_sky(humi);
}

}

}



public ClCmd_hl_precip(id, level, cid)

{
	{
		{
		if (is_user_admin(id) == 1)
		set_task_ex(3.0, "hl1_effect", 999, .flags = SetTask_Repeat);
		set_task_ex(0.2, "FlasheS", 435, .flags = SetTask_Repeat);
		set_task_ex(0.1, "streak", 221, .flags = SetTask_Repeat);
		set_task_ex(0.1, "streak2", 776, .flags = SetTask_Repeat);
		set_task_ex(0.1, "streak3", 887, .flags = SetTask_Repeat);
		}
	}

}



public hl_precip()

{
	{
		{
		set_task_ex(5.0, "hl1_effect", 998, .flags = SetTask_Repeat);
		set_task_ex(random_float(7.0, 15.0), "ring_saturn", 111, .flags = SetTask_Repeat) ;
		set_task_ex(0.1, "streak", 222, .flags = SetTask_Repeat);
		set_task_ex(0.1, "streak2", 777, .flags = SetTask_Repeat);
		set_task_ex(0.1, "streak3", 888, .flags = SetTask_Repeat);
		}
	}
}

///future compass for windage and bullet torture

public hl1_effect(Float:Origin[3])

{
	{
		{
		message_begin(0,23);
		write_byte(20);                                         // TE_BEAMDISK
		write_coord(floatround(Origin[0]));                     // coord coord coord (center position)
		write_coord(floatround(Origin[1]));
		write_coord(floatround(Origin[2]+10.0));
		write_coord(floatround(Origin[0]));                     // coord coord coord (axis and radius)
		write_coord(floatround(Origin[1]));
		write_coord(floatround(Origin[2]+random_float(500.0,1000.0)));
		switch(random_num(0,1)) 
		{
		case 0: write_short(sprFlare6);                         // short (sprite index)
		case 1: write_short(sprLightning);                      // short (sprite index)
		}
		write_byte(random_num(0,255));                          // byte (starting frame)  //was 1
		write_byte(random_num(0,255));                          // byte (frame rate in 0.1's) //fog is slower like 20fps
		write_byte(random_num(5,1000));                         // byte (life in 0.1's) //500 zombie fog
		write_byte(random_num(5,255));                          // byte (line width in 0.1's) //was 24
		write_byte(random_num(0,255));				// byte (noise amplitude in 0.01's) //was 10
		write_byte(random_num(0,255));                          // byte,byte,byte (color) 255 119 255 pink
		write_byte(random_num(0,255));
		write_byte(random_num(0,255));
		write_byte(random_num(50,1000));                        // byte (brightness) //1000 zombie fog
		write_byte(random_num(7,128));                          // byte (scroll speed in 0.1's) // was 7
		message_end();
		}
	}
}


public ClCmd_hl_fog(id, level, cid)
{
	{
		{
		if (is_user_admin(id) == 1) 
		set_task_ex(0.1, "old_fog", 771, .flags = SetTask_Repeat);
		}
	}
}


public old_fog(Float:Vector[3])
{
	{
		{
		message_begin(0,23); 
		write_byte(21); 
		engfunc(EngFunc_WriteCoord,Vector[0]); 
		engfunc(EngFunc_WriteCoord,Vector[1]); 
		engfunc(EngFunc_WriteCoord,Vector[2] + 16); 
		engfunc(EngFunc_WriteCoord,Vector[0]); 
		engfunc(EngFunc_WriteCoord,Vector[1]); 
		engfunc(EngFunc_WriteCoord,Vector[2] + 200); 
		write_short(g_F0g); 
		write_byte(100); 
		write_byte(255); 
		write_byte(255); 
		write_byte(400);
		write_byte(500);
		write_byte(111);
		write_byte(255);
		write_byte(255);
		write_byte(100);
		write_byte(0);
		message_end();   
		}		
	}
}	


public hl_fog()
{ set_task_ex(0.6, "old_fog", 770, .flags = SetTask_Repeat); }


public PolaRVorteX(Float:Vector[3])

{
	{
		{
		message_begin(0,23); 
		write_byte(random_num(19,21));
		engfunc(EngFunc_WriteCoord,Vector[0]+ random_num(-10000,500)); 
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,500)); 
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,500)); 
		engfunc(EngFunc_WriteCoord,Vector[0]* power(random_num(-5,10),3)); 
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,-500)); 
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,-500)); 

		/*torisklin https://www.amxmodx.org/api/message_const*/

		/*19blizz*/
		/*polar vortex nightmare on X DIR * power(random_num(-5,10),3));*/
		/*engfunc(EngFunc_WriteCoord,Vector[0]+ random_num(-10000,500));
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,500));
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,500));
		engfunc(EngFunc_WriteCoord,Vector[0]+ random_num(-10000,-500));
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,-500));
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,-500));*/
		/*19blizz*/

		write_short(g_F0g); 
		write_byte(100); 
		write_byte(255); 
		write_byte(255); 
		write_byte(400); 
		write_byte(500); 
		write_byte(random_num(90,130)); /*RGB111255255trademarkFOG*/ 
		write_byte(random_num(200,255)); 
		write_byte(random_num(200,255)); 
		write_byte(random_num(75,125)); 
		write_byte(0); 
		message_end(); 
		}
	}
}

public HellRain_Blizzard(Float:Vector[3])

{
	{
		{
		message_begin(0,23); 
		write_byte(19);
		/*engfunc(EngFunc_WriteCoord,Vector[0]+ random_num(-10000,500)); 
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,500)); 
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,500)); 
		engfunc(EngFunc_WriteCoord,Vector[0]+ power(random_num(-5,10),3)); 
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,-500)); 
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,-500)); */

		/*torisklin https://www.amxmodx.org/api/message_const*/

		/*19blizz*/
		/*polar vortex nightmare on X DIR * power(random_num(-5,10),3));*/
		engfunc(EngFunc_WriteCoord,Vector[0]+ random_num(-10000,500));
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,500));
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,500));
		engfunc(EngFunc_WriteCoord,Vector[0]+ random_num(-10000,-500));
		engfunc(EngFunc_WriteCoord,Vector[1]+ random_num(-10000,-500));
		engfunc(EngFunc_WriteCoord,Vector[2]+ random_num(-10000,-500));
		/*19blizz*/

		write_short(g_F0g); 
		write_byte(100); 
		write_byte(255); 
		write_byte(255); 
		write_byte(400); 
		write_byte(500); 
		write_byte(random_num(90,130)); /*RGB111255255trademarkFOG*/ 
		write_byte(random_num(200,255)); 
		write_byte(random_num(200,255)); 
		write_byte(random_num(75,125)); 
		write_byte(0); 
		message_end(); 
		}
	}
}


public ClCmd_hl_snow(id, level, cid)

{
	{
		{

		if (is_user_admin(id) == 1) 

		set_task_ex(0.1, "snow_puff", 333, .flags = SetTask_Repeat);

		set_task_ex(random_float(1.0, 2.0), "snow_flake",444, .flags = SetTask_Repeat);

		set_task_ex(0.3, "streak2", 776, .flags = SetTask_Repeat);

		set_task_ex(1.0, "streak3", 887, .flags = SetTask_Repeat);

		set_task_ex(random_float(3.0, 5.5), "ring_saturn", 111, .flags = SetTask_Repeat);
		}
	}
}




public hl_snow()

{
	{
		{
		set_task_ex(0.1, "snow_puff", 332, .flags = SetTask_Repeat);
		set_task_ex(random_float(2.0, 5.0), "snow_flake",443, .flags = SetTask_Repeat);
		set_task_ex(0.5, "FlasheS", 435, .flags = SetTask_Repeat);
		set_task_ex(0.7, "streak2", 777, .flags = SetTask_Repeat);
		set_task_ex(1.0, "streak3", 888, .flags = SetTask_Repeat);
		set_task_ex(random_float(3.0, 5.5), "ring_saturn", 111, .flags = SetTask_Repeat) ;
		}
	}

}


public ClCmd_hl_dry(id, level, cid)

{
	{

		{
		if (is_user_admin(id) == 1)

		if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

		if (task_exists(111)) remove_task(111);
		if (task_exists(222)) remove_task(222);
		if (task_exists(221)) remove_task(221);

		// kill snow flaking (sky)
		if (task_exists(332)) remove_task(332);
		if (task_exists(333)) remove_task(333);
	
		//kill FlasheS
		if (task_exists(435)) remove_task(435);

		// kill snow puffing (falling)
		if (task_exists(443)) remove_task(443);
		if (task_exists(444)) remove_task(444);

		// kill fog lurching
		if (task_exists(770)) remove_task(770);
		if (task_exists(771)) remove_task(771);

		// rain drops streak 1-3 both from auto and user calls
		// streak2
		if (task_exists(777)) remove_task(777);
		if (task_exists(776)) remove_task(776);
		// streak3
		if (task_exists(888)) remove_task(888);
		if (task_exists(887)) remove_task(887);
		// hl effect
		if (task_exists(999)) remove_task(999);
		if (task_exists(998)) remove_task(998);
		}
		
		return PLUGIN_HANDLED
	}
}


public no_snow()

{
	{
		{
		if (task_exists(111)) remove_task(111);
		if (task_exists(222)) remove_task(222);
		if (task_exists(333)) remove_task(333);
		if (task_exists(444)) remove_task(444);
		if (task_exists(777)) remove_task(777);
		if (task_exists(888)) remove_task(888);
		}
	}
}

public snow_flake(Float:Vector[3])

{
	{
		{
		message_begin(0,23);
		write_byte(20);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(10000,15000));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(10000,15000));
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(10000,15000));
		engfunc(EngFunc_WriteCoord,Vector[0] * random_num(1000,5000));
		engfunc(EngFunc_WriteCoord,Vector[1] / random_num(1000,5000));
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(-1000,15000));
		switch(random_num(0,2))
		{
		case 0: write_short(g_F0g)
		case 1: write_short(sprLightning)
		case 2: write_short(g_Saturn)
		}
		write_byte(random_num(1,25));
		write_byte(random_num(1,255)); 
		write_byte(random_num(2,13));
		write_byte(random_num(1,20000));
		write_byte(random_num(50,12000));
		write_byte(random_num(90,150));
		write_byte(random_num(90,150));
		write_byte(random_num(199,255));
		write_byte(random_num(50,500));
		write_byte(0);
		message_end();
		}
	}
}


public snow_puff(Float:Vector[3])

{
	{
		{
		message_begin(0,23);
		write_byte(100)
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(-100000,180000));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(-100000,180000));
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(-100000,180000));
		write_short(g_F0g)
		write_short(0) /*snow*/
		message_end()
		}
	}
}

public ring_saturn(Float:bOrigin[3])

{
	{
		{
		message_begin(0,23)
		write_byte(19) /*(TE_BEAMTORUS)*/
		write_coord(floatround(bOrigin[0]+random_num(-11,11)));  /*X*/
		write_coord(floatround(bOrigin[1]-random_num(-11,11)));
		write_coord(floatround(bOrigin[2]+random_num(-11,18000)));
		write_coord(floatround(bOrigin[0]/random_num(-11,11)));
		write_coord(floatround(bOrigin[1]*random_num(-11,11)));
		write_coord(floatround(bOrigin[2]+random_num(-11,11)));
		write_short(g_Saturn)
		write_byte(random_num(3,450));
		write_byte(random_num(2,500));
		write_byte(random_num(30,1000));
		write_byte(random_num(50,800));
		write_byte(random_num(40,3000));
		write_byte(random_num(0,255));
		write_byte(random_num(0,255));
		write_byte(random_num(0,255));
		write_byte(random_num(100,2000));
		write_byte(random_num(2,200));
		message_end()
		}
	}
}

public streak(Float:Vector[3])

{

	{
		{
		message_begin(0,23);
		write_byte(25);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(1000,15000));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(1000,15000));
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(1000,15000));
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(1,2000));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(1,2000));
		engfunc(EngFunc_WriteCoord,Vector[2] - random_num(500,1000));
		write_byte(random_num(0, 11));	/*0 wht  3 blu  7 blu*/
		write_short(random_num(2000, 10000));
		write_short(random_num(2, 5));
		write_short(120);
		message_end();
		
		message_begin(0,23);
		write_byte(100)
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(-1000,-18000) );
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(-1000,-18000) );
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(50,300) );
		write_short(g_F0g)
		write_short(2)
		message_end()
		}
	}

}



public ClCmd_FlasheS(id, level, cid)

{
		{
				{
						if (is_user_admin(id) == 1)

				set_task_ex(0.5, "FlasheS", 435, .flags = SetTask_Repeat);
				}
		}
}




public FlasheS(Float:sorigin[3])

{
	{
		{
		message_begin(0,23);
		write_byte(27);
		engfunc(EngFunc_WriteCoord,sorigin[0] + random_num(1000,18000)) /*position.x*/
		engfunc(EngFunc_WriteCoord,sorigin[1] + random_num(1000,18000))
		engfunc(EngFunc_WriteCoord,sorigin[2] + random_num(500,3000))
		write_byte(random_num(-1000,18000)); /*(radius in 10's)*/
		write_byte(random_num(0,255)); /*rgb*/
		write_byte(random_num(0,255));
		write_byte(random_num(0,255));
		write_byte(random_num(50,555)); /*bright*/
		write_byte(random_num(2,128));  /*(decay rate in 10's)*/
		message_end();
		}
	}
}


public streak2(Float:Vector[3])
		
{
	{
		{
		message_begin(0,23);
		write_byte(25);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(-5,8000));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(-5,8000));
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(3000,11000));
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[2] - random_num(50,2000));
		write_byte(0);
		write_short(random_num(30,200));
		write_short(random_num(1,5));
		write_short(random_num(3,15));
		message_end();
		}
	}
}

public streak3(Float:Vector[3])

{
	{
		{

		message_begin(0,23);
		write_byte(25);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[2] - random_num(100,500));
		write_byte(7);
		write_short(2048);
		write_short(random_num(1,3)); 
		write_short(random_num(1,5));
		message_end();
		
		message_begin(0,23);
		write_byte(25);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[2] - random_num(100,500));
		write_byte(7);
		write_short(20);
		write_short(random_num(1,5));
		write_short(random_num(1,7));
		message_end();
		
		message_begin(0,23);
		write_byte(25);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(1000,1000) );
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[2] - random_num(100,500));
		write_byte(7);
		write_short(50);
		write_short(random_num(1,31));
		write_short(random_num(1,21));
		message_end();
		
		message_begin(0,23);
		write_byte(25);
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(-100,1800) );
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(-100,1800) );
		engfunc(EngFunc_WriteCoord,Vector[2] + random_num(-100,1800) );
		engfunc(EngFunc_WriteCoord,Vector[0] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[1] + random_num(10,200));
		engfunc(EngFunc_WriteCoord,Vector[2] - random_num(100,500));
		write_byte(7);
		write_short(50);
		write_short(random_num(1,31));
		write_short(random_num(1,21));
		message_end();

		}
	}
}



/*
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public epoch_clock() 
{
	{
		{
/////////////////////////////////////////
		new g_Epoch = get_systime(0);
		new id;
		new g_SkyNam[16];
		get_cvar_string("sv_skyname",g_SkyNam,15);
//////////////////////////////////////////native format_time(output[], len, const format[], time = -1);///////////
//      Time feed is in Epoch from sockets.        
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/// g_sunrise and g_sunset are global parameters from feed.
		new g_UpMin  =  ( g_sunrise - g_Epoch ) / 60 ;
		new g_DownMin =  ( g_sunset - g_Epoch ) / 60 ;
		
		new g_Hour[3], g_Minut[3], g_Now;

		get_time("%H", g_Hour, 2);
		new g_TimeH = str_to_num(g_Hour);

		get_time("%M", g_Minut, 2);
		new g_TimeM = str_to_num(g_Minut);
	
		g_Now = ( "%i %i", g_TimeH, g_TimeM ) ;

		new g_UoopHours  =  ( g_sunrise - g_Epoch ) / 3600 ; ///hrs until sunup
		new g_DownHours  =  ( g_sunset - g_Epoch ) / 3600 ; ///hrs until sundown

		new high, S_EeD1, S_EeD2, offset;
		new g_RisE = (g_TimeH + g_UoopHours)
		new g_SeeT = (g_TimeH + g_DownHours)
		
		high = 23;
		new low = 0
		S_EeD1 = g_RisE;
		S_EeD2 = g_SeeT;
		offset = -21;

		g_figure = Set_Roll(high, low,S_EeD1, offset);
		g_Nfig = Set_Roll(high, low,S_EeD2, offset);
		
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		client_print(id, print_console, "Skyname is %s",g_SkyNam);
		client_print(id, print_console, "Sunrise hour %i",g_figure);
		client_print(id, print_console, "Sunset hour %i",g_Nfig);

		if( (g_UpMin) < -1) 
		{ 
		server_print("Post Dawn");
		log_amx("Dusk is in %i min. About %i hours. Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);	
		client_print(id, print_console, "PreDusk::Dusk is in %i min. About %i hours.  Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);
		client_print(id, print_console, "PostDawn::Dawn was %i min ago. About %i hours ago.  Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		}	
		if( (g_UpMin) > 1) 
		{
		log_amx("Dawn is in %i min. About %i hours. Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		client_print(id, print_console, "PreDawn::Dawn is in %i min. About %i hours.  Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		}
		if( (g_DownMin) < -1 )
		{
		server_print("Post Dusk");
		log_amx("Dawn is in %i min. About %i hours. Time is %i:%i",g_UpMin, g_UoopHours, g_TimeH, g_Now);
		}
		new g_Dusk;
		g_Dusk = clamp(g_DownMin, -400, -1);
		if( (g_DownMin == g_Dusk))
		{
		log_amx("Dusk was %i min ago. About %i hours. Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);
		client_print(id, print_console, "PostDusk::Dusk was %i min ago. About %i hours ago.  Time is %i:%i",g_DownMin, g_DownHours, g_TimeH, g_Now);
		}
		
		}
	}
}*/


public set_sky(humi)

{

	{	

		{
		new phase;
		new temp[3];
		get_time("%H", temp, 2);
		g_Ti = str_to_num(temp);
		
		g_Up = get_cvar_num("day");
		g_Dwn = get_cvar_num("night");
		
		g_Nn = 12; ///noon
		
		if (g_Ti == g_Nn - 1 || g_Ti == g_Nn)
				phase = 2; //NOON
		else if (g_Ti == g_Up - 1 || g_Ti == g_Up)
				phase = 1; //SUNRISE
		else if (g_Ti == g_Dwn - 1 || g_Ti == g_Dwn)
				phase = 3; //SUNSET
		else if (g_Ti < g_Up - 1 || g_Ti >= g_Dwn + 1)
				phase = 4; //NIGHT
		else if (g_Ti > g_Up + 1 && g_Ti < g_Nn - 1)
				phase = 0; //DAY
		else if (g_Ti > g_Nn + 1 && g_Ti < g_Dwn - 1)
				phase = 0; //DAY
				
		if (humi <= PFOG) {
			
				precache_sky(g_skynames[((nvault_get(bird, "element") - 1) * 5) + phase]);
		} else
				precache_sky(g_skynames[(3 * 5) + phase]);     
		} 
		
///		new bird = 
		g_SpeeD = nvault_get(bird, "speed");
		g_DeG = nvault_get(bird, "deg");
		g_heat = nvault_get(bird, "heat"); //actual temp g_temp is high
		nvault_get(bird, "location", g_location,31);

		server_print("%s where the temp is %i... Wind speed is %i at %i deg. Fog is set to %i Rise is %i Set is %i...now is %i", g_location, g_heat, g_SpeeD, g_DeG, g_Pfog, g_Up, g_Dwn, g_Ti);
	}


}

public precache_sky(const skyname[])

{
	{
		
		{
		new bool: pres = true;
		static file[35];
		for (new i = 0; i < 6; ++i)
		{
		formatex(file, 34, "gfx/env/%s%s.tga", skyname, g_skysuf[i]);
		if (file_exists(file))
		{
		precache_generic(file);
		}else{
		pres = false;
		break;
		}
		}		
		if (pres)
		set_cvar_string("sv_skyname", skyname);
			
		new g_SkyNam[16];
		get_cvar_string("sv_skyname",g_SkyNam,15);
		server_print("Map using sky of %s, enjoy.", g_SkyNam);
		}
	}
}		


public daylight()

{
	{
		{
			
		g_temp_min = nvault_get(bird, "mintemp");
		g_temp = nvault_get(bird, "heat");

		//g_sunrise = nvault_get(bird, "sunrise");
		//g_sunset = nvault_get(bird, "sunset");
		
			
		new sunrise = 6 - 1; ///vault_get

		if (get_pcvar_num(g_cvar_day) > 0)
		sunrise = get_cvar_num("day");
		
		new sunset = 21 + 1; ///vault_get
		
		if (get_pcvar_num(g_cvar_night) > 0)
		sunset = get_cvar_num("night");
				

/////////////////////////////////////////////////////////////////////////////////////////////////////////		
		new totalDayLight = (sunset) - sunrise;
		new serv_time[3];
		get_time("%H", serv_time, 2);

		new now = str_to_num(serv_time);

		if (get_pcvar_num(g_cvar_time) > 0)

		now = get_cvar_num("time");

		new light, lightspan = get_pcvar_num(g_cvar_minlight) + 1 - get_pcvar_num(g_cvar_maxlight);
		new tempspan = g_temp - g_temp_min;
		new noon = (totalDayLight / 2) + sunrise;
		if (now < noon)
		{
		if (now < sunrise) 
		{
		light = get_pcvar_num(g_cvar_minlight);
		g_curr_temp = g_temp_min;
		}
		else  
		{
		new prenoon = noon - sunrise;
		light = get_pcvar_num(g_cvar_minlight) - (now - sunrise) * (lightspan / prenoon);
		g_curr_temp = g_temp - (now - sunrise) * (tempspan / prenoon);
		}
		}
		if (now == noon)
		{
		light = get_pcvar_num(g_cvar_maxlight);
		g_curr_temp = g_temp;
		}
		if (now > noon)	
		{
		if (now > sunset)
		{
		light = get_pcvar_num(g_cvar_minlight);
		g_curr_temp = g_temp_min;
		} 
		else	
		{
		new postnoon = noon - sunrise;
		light = (now - noon) * (lightspan / postnoon) + get_pcvar_num(g_cvar_maxlight);
		g_curr_temp = (now - sunrise) * (tempspan / postnoon) + g_temp_min;
		if (light > get_pcvar_num(g_cvar_minlight))
		{
		light = get_pcvar_num(g_cvar_minlight);
		}
		}
		}
		#if defined LUM_DEBUG
		log_amx("darkness %d", light);
		log_amx("dark %d phase %d lums %d", get_cvar_num("dark"), light, get_cvar_num("lums"));
		log_amx("darkness added to max light is %d out of 25 total darkness", light);
		#endif
		fm_set_lights(g_LightLevel[light]);
		new fogcolor = (get_pcvar_num(g_cvar_minlight) - light) * 10 + 20;
		new form[12];
		/*model illumination*/
		set_cvar_num("sv_skycolor_r", fogcolor);
		set_cvar_num("sv_skycolor_g", fogcolor);
		set_cvar_num("sv_skycolor_b", fogcolor);
		format(form, 12, "%d %d %d", fogcolor, fogcolor, fogcolor);
		fm_set_kvd(g_fog, "rendercolor", form);
		}
	}
}

public makeFog(amount)
{
	{
		{
		if ( cstrike_running() )
			{
		g_fog = fm_create_entity("env_fog");
		new Float: density = ( 0.0002 * ( amount - PFOG )) + 0.001;
		new dens[7];
		float_to_str(density, dens, 6);
		fm_set_kvd(g_fog, "density", dens);
		fm_set_kvd(g_fog, "rendercolor", "200 200 200");
		}else{
		hl_fog();
		new Zoo = nvault_get(bird, "humidity");
		if ( Zoo < PFOG )
		no_snow(); 
			} 
		return;
		}
	}	
}
		/*DispatchKeyValue*/
		stock fm_set_kvd(entity,
		const key[],
		const value[],
		const classname[] = "") 
{
	{
		{
		if (classname[0])
		set_kvd(0, KV_ClassName, classname);
		else
		{
		new class[32];
		pev(entity, pev_classname, class, sizeof class - 1);
		set_kvd(0, KV_ClassName, class);
		}
		set_kvd(0, KV_KeyName, key);
		set_kvd(0, KV_Value, value);
		set_kvd(0, KV_fHandled, 0);
		return dllfunc(DLLFunc_KeyValue, entity, 0);
		}
	}
}
/*                    GNU AFFERO GENERAL PUBLIC LICENSE
                       Version 3, 19 November 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU Affero General Public License is a free, copyleft license for
software and other kinds of works, specifically designed to ensure
cooperation with the community in the case of network server software.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
our General Public Licenses are intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  Developers that use our General Public Licenses protect your rights
with two steps: (1) assert copyright on the software, and (2) offer
you this License which gives you legal permission to copy, distribute
and/or modify the software.

  A secondary benefit of defending all users' freedom is that
improvements made in alternate versions of the program, if they
receive widespread use, become available for other developers to
incorporate.  Many developers of free software are heartened and
encouraged by the resulting cooperation.  However, in the case of
software used on network servers, this result may fail to come about.
The GNU General Public License permits making a modified version and
letting the public access it on a server without ever releasing its
source code to the public.

  The GNU Affero General Public License is designed specifically to
ensure that, in such cases, the modified source code becomes available
to the community.  It requires the operator of a network server to
provide the source code of the modified version running there to the
users of that server.  Therefore, public use of a modified version, on
a publicly accessible server, gives the public access to the source
code of the modified version.

  An older license, called the Affero General Public License and
published by Affero, was designed to accomplish similar goals.  This is
a different license, not a version of the Affero GPL, but Affero has
released a new version of the Affero GPL which permits relicensing under
this license.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU Affero General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Remote Network Interaction; Use with the GNU General Public License.

  Notwithstanding any other provision of this License, if you modify the
Program, your modified version must prominently offer all users
interacting with it remotely through a computer network (if your version
supports such interaction) an opportunity to receive the Corresponding
Source of your version by providing access to the Corresponding Source
from a network server at no charge, through some standard or customary
means of facilitating copying of software.  This Corresponding Source
shall include the Corresponding Source for any work covered by version 3
of the GNU General Public License that is incorporated pursuant to the
following paragraph.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the work with which it is combined will remain governed by version
3 of the GNU General Public License.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU Affero General Public License from time to time.  Such new versions
will be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU Affero General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU Affero General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU Affero General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If your software can interact with users remotely through a computer
network, you should also make sure that it provides a way for users to
get its source.  For example, if your program is a web application, its
interface could display a "Source" link that leads users to an archive
of the code.  There are many ways you could offer source, and different
solutions will be better for different programs; see section 13 for the
specific requirements.

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU AGPL, see
<https://www.gnu.org/licenses/>.*/
