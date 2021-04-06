#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#define RAINBOW random_num(1,255)
new pPlugin,pXPosition,pYPosition,pHoldTime,iRed,iGreen,iBlue,Float:fXPos,Float:fYPos,Float:fHoldTime;

public plugin_init()
{
  {
	register_plugin("HitmarX","C",".sρiηX҉.");
	//This is my original 'Zombie-style' of spinner hitmarkers. Anks and crosses may appear.
	RegisterHam(Ham_TakeDamage, "player", "PostTakeDamage", 1);

	pPlugin =      		register_cvar("amx_hitmarkers", "1");
	pXPosition =        register_cvar("amx_hmxpos", "-1.0");
	pYPosition =        register_cvar("amx_hmypos", "-1.0");
	pHoldTime =  		register_cvar("amx_hmholdtime", "0.5");
  }
}
public PostTakeDamage(iVictim, iAttacker)
{
  {
	{
	new const SzZombie_hitmarkers[][] = {"-","\","|","*","+","X"};

	if( is_user_connected(iAttacker) && (get_pcvar_num(pPlugin)) || (cstrike_running()) && (get_user_team(iVictim)) != (get_user_team(iAttacker)) || !cstrike_running() )
	{
		iRed = RAINBOW;iGreen = RAINBOW; iBlue = RAINBOW;fXPos = get_pcvar_float(pXPosition);fYPos = get_pcvar_float(pYPosition);fHoldTime = get_pcvar_float(pHoldTime)
		set_hudmessage(iRed, iGreen, iBlue, fXPos, fYPos, 0, 2.0, fHoldTime, 0.0, 0.0, -1);
		#define HUD show_hudmessage
	
	HUD (iAttacker, "%s", SzZombie_hitmarkers[random(sizeof(SzZombie_hitmarkers))]);
   }
  }
 }
}
