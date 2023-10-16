//Why not reload map since clients cannot stay connected once edict count breaches?
//The default edict limit is 900, but this can be raised to 2048 by editing the mod's liblist.gam to include edicts "2048".
//https://developer.valvesoftware.com/wiki/Entity_limit
#include amxmodx
#include fakemeta
#include engine
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
 * * Neither the name of the Amxx nor the names of its
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
new static stock bool:bChanged

public plugin_init()
{
    register_plugin("Max Edict map reloader","1.0",".sρiηX҉.");
}

public pfn_touch(a,b)
{
    #define OVERFLOW MAX_MOTD_LENGTH - MAX_PLAYERS
    static iEnts; iEnts = engfunc(EngFunc_NumberOfEntities)

    if(iEnts < OVERFLOW || bChanged)
        return

    bChanged = true

    static mapname[MAX_NAME_LENGTH];get_mapname(mapname, charsmax(mapname));
    log_amx("Reloading map due to ent limit %d reached.", iEnts)
    console_cmd 0,  "changelevel %s", mapname
}
