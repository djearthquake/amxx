#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta

new const medkit[]   = "models/w_medkit.mdl"
new const smallkit1[] = "items/smallmedkit1.wav"
new const smallkit2[] = "items/smallmedkit2.wav"
new const ent_type[] = "item_healthkit"

new g_ent;
new bool:bDust

public plugin_init()
{
    register_plugin("Breakable Medical", "1.5", ".sρiηX҉.")
}

public plugin_cfg()
{
    static modname[MAX_PLAYERS], bool:bStrike;get_modname(modname, charsmax(modname))
    bStrike = equali(modname, "cstrike") || equali(modname, "czero") ? true : false
    if(bStrike)
    {
        register_logevent("@round_end", 2, "1=Round_End")
    }

    register_touch("player", "func_breakable", "@ent_changing_function")
    register_touch("Hook_illuminati", "func_breakable", "@ent_changing_function")

    register_clcmd("clear_kits","@clear_medkits",ADMIN_SLAY,"- removes all medikits.");
    register_clcmd("fix_boxes","@fix_boxes",ADMIN_SLAY,"- break on trigger not melee.");
    static mname[MAX_PLAYERS];
    get_mapname(mname, charsmax(mname) )
    bDust = containi(mname, "dust") != -1 ? true:false
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

@feedback(id)
{
    if(is_user_connected(id))
    {
        client_print(id, print_chat, "%i jobs taken care of for you %n!", g_ent, id)
    }
}

@round_end()
{
    if(bDust)
    {
        @ent_fixer()
    }
    @ent_remover()
}

@clear_medkits(id)
{
    g_ent = 0;
    if(is_user_connected(id))
    {
        set_task(0.5, "@ent_remover", id)
        set_task(1.0, "@feedback", id)
    }
    return PLUGIN_HANDLED
}

@fix_boxes(id)
{
    g_ent = 0;
    if(is_user_connected(id))
    {
        set_task(0.5, "@ent_fixer", id)
        set_task(1.0, "@feedback", id)
    }
    return PLUGIN_HANDLED
}

@ent_fixer()
{
    new  ent = MaxClients; while( (ent = find_ent(ent, "func_breakable") ) > MaxClients && pev_valid(ent)>1)
    {
        set_pev(ent, pev_spawnflags, SF_BREAK_TRIGGER_ONLY)
        DispatchSpawn(ent); //make trigger only work
        g_ent++
    }
}

@ent_remover()
{
    new  ent = MaxClients; while( (ent = find_ent(ent, ent_type) ) > MaxClients && pev_valid(ent))
    {
        set_pev(ent, pev_flags, FL_KILLME)
    }
}

public plugin_precache()
{
    precache_model(medkit);
    precache_sound(smallkit1);
    precache_sound(smallkit2);
    precache_sound("debris/metal1.wav")
    precache_sound("debris/metal3.wav")
}
