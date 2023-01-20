/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above
 *   copyright notice, this list of conditions and the following disclaimer
 *   in the documentation and/or other materials provided with the
 *   distribution.
 * * Neither the name of the  nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

/*SPiNX "DJ" EarthQuake's UNstick Pick for Amxx*/
/*--------------------------------------------------------------------*/
//Special thanks to Exolent[jNr] for Native help:
///https://forums.alliedmods.net/showpost.php?s=a713ea5425a87e7c6befbbf4c8d6181e&p=731211&postcount=10
//Arkshine's unstick code work:
///https://forums.alliedmods.net/showthread.php?t=80937

#include amxmodx
#include fakemeta
#include unstick

public plugin_init()
{
    register_plugin("UNstick", "1.0.0", "SPiNX");
}

public plugin_natives()
{
    register_library("unstick");
    register_native("unstick", "_unstick");
}

#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free space.
#define MAX_CLIENTS     32

// --| Macro.
#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )

public _unstick ( plugin, params )
{
    new id = get_param(1);
    new Float:fLambda = get_param_f(2);
    if( is_user_connected(id) )
    {
        new Float:gf_LastCmdTime[ MAX_CLIENTS + 1 ];
        new Float:f_MinFrequency = fLambda
        new Float:f_ElapsedCmdTime = get_gametime () - gf_LastCmdTime[ id ];
    
        if ( f_ElapsedCmdTime < fLambda )
        {
            client_print ( id, print_chat, "[AMXX] You must wait %.1f seconds before trying to free yourself.", f_MinFrequency - f_ElapsedCmdTime );
            return PLUGIN_HANDLED;
        }
    
        gf_LastCmdTime[ id ] = get_gametime ();
    
        new i_Value;
    
        if ( ( i_Value = UTIL_UnstickPlayer ( id, START_DISTANCE, MAX_ATTEMPTS ) ) != 1 )
        {
            switch ( i_Value )
            {
                case 0  : client_print ( id, print_chat, "[AMXX] Couldn't find a free spot to move you too" );
                case -1 : client_print ( id, print_chat, "[AMXX] You cannot free yourself as dead player" );
            }
        }
    }
    return PLUGIN_CONTINUE;
}

UTIL_UnstickPlayer ( const id, const i_StartDistance, const i_MaxAttempts )
{
    // --| Just for readability.
    enum Coord_e { Float:x, Float:y, Float:z };
    // --| Not alive, ignore.
    if ( !is_user_alive ( id ) )  return -1

    static Float:vf_OriginalOrigin[ Coord_e ], Float:vf_NewOrigin[ Coord_e ];
    static i_Attempts, i_Distance;

    // --| Get the current player's origin.
    pev ( id, pev_origin, vf_OriginalOrigin );

    i_Distance = i_StartDistance;

    while ( i_Distance < 1000 )
    {
        i_Attempts = i_MaxAttempts;

        while ( i_Attempts-- )
        {
            vf_NewOrigin[ x ] = random_float ( vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance );
            vf_NewOrigin[ y ] = random_float ( vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance );
            vf_NewOrigin[ z ] = random_float ( vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance );

            engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize ( id ), id, 0 );

            // --| Free space found.
            if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
            {
                // --| Set the new origin .
                engfunc ( EngFunc_SetOrigin, id, vf_NewOrigin );
                return 1;
            }
        }

        i_Distance += i_StartDistance;
    }

    // --| Could not be found.
    return 0;
}
