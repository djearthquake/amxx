#include <amxmodx>
#include <fakemeta>
/*https://github.com/ValveSoftware/halflife/issues/3714*/

#define PLUGIN  "CD Audio Bugfix (Final Stability)"
#define VERSION "3.1"
#define AUTHOR  "sρiηX҉"

#define MAX_TRACKS 8
#define RADIUS     500.0
#define INTERVAL   1.0 // Slower interval to reduce network stress

new Float:g_EntOrigins[MAX_TRACKS][3];
new g_EntTracks[MAX_TRACKS];
new g_EntCount;

new g_CurrentTrack[MAX_PLAYERS + 1];
new bool:g_IsReady[MAX_PLAYERS + 1]; // Only send messages to "ready" players
new g_MaxPlayers;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	g_MaxPlayers = get_maxplayers();
	
	// Huge 5-second delay to ensure server buffers are fully initialized
	set_task(5.0, "SwapAndCache");
}

public SwapAndCache()
{
	g_EntCount = 0;
	new ent = -1;
	new Float:vMins[3], Float:vMaxs[3];

	// Convert brushes to points and cache them
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "trigger_cdaudio")) > 0)
	{
		if (g_EntCount >= MAX_TRACKS) break;

		pev(ent, pev_absmin, vMins);
		pev(ent, pev_absmax, vMaxs);
		
		// Move it to its center and change class to stop engine brush logic
		static Float:vCenter[3];
		vCenter[0] = (vMins[0] + vMaxs[0]) / 2.0;
		vCenter[1] = (vMins[1] + vMaxs[1]) / 2.0;
		vCenter[2] = (vMins[2] + vMaxs[2]) / 2.0;

		set_pev(ent, pev_origin, vCenter);
		set_pev(ent, pev_classname, "info_target"); // Neutralize the brush
		
		g_EntOrigins[g_EntCount] = vCenter;
		g_EntTracks[g_EntCount] = pev(ent, pev_health);
		g_EntCount++;
	}

	// Cache standard points
	ent = -1;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "target_cdaudio")) > 0)
	{
		if (g_EntCount >= MAX_TRACKS) break;
		pev(ent, pev_origin, g_EntOrigins[g_EntCount]);
		g_EntTracks[g_EntCount] = pev(ent, pev_health);
		g_EntCount++;
	}

	if (g_EntCount > 0)
	{
		set_task(INTERVAL, "CheckProximity", .flags="b");
	}
}

// Ensure player is fully in-game before sending any messages
public client_putinserver(id) 
{
	g_CurrentTrack[id] = 0;
	g_IsReady[id] = false;
	set_task(2.0, "MakePlayerReady", id);
}

public MakePlayerReady(id) 
{
	if (is_user_connected(id)) g_IsReady[id] = true;
}

public client_disconnected(id) 
{
	g_IsReady[id] = false;
}

public CheckProximity() 
{
	static Float:pOrigin[3];
	
	for (new i = 1; i <= g_MaxPlayers; i++) 
	{
		// Only check players who are alive, connected, AND passed the 2s ready timer
		if (!g_IsReady[i] || !is_user_alive(i)) continue;
		
		pev(i, pev_origin, pOrigin);
		
		new bool:foundZone = false;
		for (new j = 0; j < g_EntCount; j++) 
		{
			if (get_distance_f(pOrigin, g_EntOrigins[j]) <= RADIUS) 
			{
				if (g_CurrentTrack[i] != g_EntTracks[j]) 
				{
					play_track(i, g_EntTracks[j]);
					g_CurrentTrack[i] = g_EntTracks[j];
				}
				foundZone = true;
				break; 
			}
		}
		
		if (!foundZone) g_CurrentTrack[i] = 0;
	}
}

play_track(id, iTrack) 
{
	if (iTrack <= 0 || !g_IsReady[id]) return;
	
	// Final safety: check if the player is still connected right before the message
	message_begin(MSG_ONE_UNRELIABLE, SVC_CDTRACK, .player = id);
	write_byte(iTrack); 
	write_byte(0); 
	message_end();
}
