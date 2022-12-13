#include amxmodx
#include amxmisc
#include engine
#include fakemeta

new const medkit[]   = "models/w_medkit.mdl"
new const smallkit1[] = "items/smallmedkit1.wav"
new const smallkit2[] = "items/smallmedkit2.wav"

public plugin_init()
{
        register_plugin("Breakable Medical", "1.0", ".sρiηX҉.")
        register_touch("player", "func_breakable", "@ent_changing_function")

        if(is_running("cstrike_running"))
            register_event("SendAudio", "@clear_medkits", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
}

@ent_changing_function(player, entity_we_touched)
{
    if(pev_valid(entity_we_touched) ==2)
    {
        DispatchKeyValue(entity_we_touched, "explodemagnitude", "100") //make it hurt
        DispatchKeyValue(entity_we_touched, "spawnobject", "2") //make medkit
        //DispatchKeyValue(entity_we_touched, "classname", "Explodable")
        DispatchKeyValue(entity_we_touched,"gibmodel", medkit)
        DispatchSpawn(entity_we_touched); //make gib work
    }
}

@clear_medkits()
{
    new med;
    while ((med = find_ent_by_class(-1, "item_healthkit")) > 0)
        remove_entity(med)
}

public plugin_precache()
{
    precache_model(medkit);
    precache_sound(smallkit1);
    precache_sound(smallkit2);
}
