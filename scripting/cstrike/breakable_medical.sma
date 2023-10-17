#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta

new const medkit[]   = "models/w_medkit.mdl"
new const smallkit1[] = "items/smallmedkit1.wav"
new const smallkit2[] = "items/smallmedkit2.wav"

public plugin_init()
{
        register_plugin("Breakable Medical", "1.0", ".sρiηX҉.")
        //register_touch("player", "func_breakable", "@ent_changing_function")
        register_touch("", "func_breakable", "@ent_changing_function")

        if(is_running("cstrike_running"))
            register_event("SendAudio", "@clear_medkits", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
}

@ent_changing_function(player, entity_we_touched)
{
    if(pev_valid(entity_we_touched) ==2)
    {
        DispatchKeyValue(entity_we_touched, "explodemagnitude", "10") //make it hurt
        DispatchKeyValue(entity_we_touched, "spawnobject", "2") //make medkit
        //DispatchKeyValue(entity_we_touched, "classname", "Explodable")
        DispatchKeyValue(entity_we_touched,"gibmodel", medkit)
        DispatchKeyValue(entity_we_touched,"spawnflags", "256")
        DispatchSpawn(entity_we_touched); //make gib work
    }
}

@clear_medkits()
{
    static med; med = MaxClients
    while ((med = find_ent(med, "item_healthkit")) > MaxClients)
        remove_entity(med)
}

public plugin_precache()
{
    precache_model(medkit);
    precache_sound(smallkit1);
    precache_sound(smallkit2);
}
