#include <amxmodx>
#include <engine>
new Float:BlockTime[33];
new pcvar_spray_tolerance;
new Float:g_Time;

public plugin_init(){
	pcvar_spray_tolerance = register_cvar("spray_tolerance", "30.0")
	register_impulse(201, "SprayAppraiser");}

public SprayAppraiser(id){
	new Float:gametime = get_gametime()
	g_Time = get_pcvar_float(pcvar_spray_tolerance)
	if(BlockTime[id] <= gametime)
	{
	BlockTime[id] = gametime + g_Time;
	client_print(id, print_chat, "Spray blocked for %i seconds.",floatround(g_Time));
	}
	return PLUGIN_HANDLED;}
public client_disconnected(id){BlockTime[id] = 0.0;}
