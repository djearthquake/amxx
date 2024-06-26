#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta

new const medkit[]   = "models/w_medkit.mdl"
new const smallkit1[] = "items/smallmedkit1.wav"
new const smallkit2[] = "items/smallmedkit2.wav"
new const ent_type[] = "item_healthkit"


public plugin_init()
{
    register_plugin("Breakable Medical", "1.2", ".sρiηX҉.")
}

public plugin_cfg()
{
    static modname[MAX_PLAYERS], bool:bStrike;get_modname(modname, charsmax(modname))
    bStrike = equali(modname, "cstrike") || equali(modname, "czero") ? true : false
    if(bStrike)
    {
        register_event("SendAudio", "@clear_medkits", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
    }
    register_touch("player", "func_breakable", "@ent_changing_function")
    register_touch("Hook_illuminati", "func_breakable", "@ent_changing_function")
}

@ent_changing_function(player, entity_we_touched)
{
    if(pev_valid(entity_we_touched) ==2)
    {
        DispatchKeyValue(entity_we_touched, "explodemagnitude", "10") //make it hurt
        DispatchKeyValue(entity_we_touched, "spawnobject", "2") //make medkit
        DispatchKeyValue(entity_we_touched,"gibmodel", medkit)
        DispatchKeyValue(entity_we_touched,"spawnflags", "256")
        DispatchSpawn(entity_we_touched); //make gib work
    }
}

@clear_medkits()
{
    static ent, iThink; ent = MaxClients; while( (ent = find_ent(ent, ent_type) ) > MaxClients && pev_valid(ent))
    {
        iThink = pev(ent, pev_nextthink); iThink == 0 ? (remove_entity(ent)&server_print("%d is removed", ent)) : (set_pev(ent, pev_flags, FL_KILLME)&server_print("%d's flagged next_think %i", ent, iThink))
        server_print("%d's flagged next_think %i", ent, iThink)
    }
}

public plugin_precache()
{
    precache_model(medkit);
    precache_sound(smallkit1);
    precache_sound(smallkit2);
}
