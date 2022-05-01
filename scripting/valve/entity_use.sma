/*
 * Used to test activtating targets embedded within ents.
 *
 * For example set "amx_cvar use_entity" to "multi_manager" and it triggers the HL map "undertow" flood.
 *
 * Stock script is set to "button_target" defined as SHOOT-OPEN since that's is how players know them.
 *
 * If there are multiple ents with that func, it grabs the first one as roughly scripted initially.
 *
 * console command ::: useful_pick
 *
 * To make it more useful:
 * ----------------------
 * bind f useful_pick
 *
 * Tested on func_recharge and got armour from afar!
 *
 *
 *  map subtransit or any map with a train like de_railroad for cstrike.
 *
 *
 *
  *
   *
    amx_cvar use_entity func_tracktrain
    *
    *
    amx_cvar use_type 0   //stop train / release USE remotely
    amx_cvar use_type 1-2 //start train remotely at float speed increment
    amx_cvar use_type 3   //toggle train remotely at 100% speed
    *
    amx_cvar use_float 0.1 //slow
    amx_cvar use_float 1.0 //normal incrementing keep pressing key used to bind useful_pick
    amx_cvar use_float 3.0 //full blast
    *
    *
    when float is -1.0
    *
    type 2 is backwards albeit still incremential speed starting slow and no toggle
    type 3 is forwards with toggle
    *
    *
    Positive float +forward and has intensity. Adjusting negative is same as pressing +back.
   *
 *
*
*/

#include amxmodx
#include engine
#include fakemeta
#include hamsandwich

#define ONE "1.0"
#define TWO "2.0"
#define OFF    "0"
#define ONEWAY "1"
#define TWOWAY "2"
#define TOGGLE "3"

#define SHOOT-OPEN "button_target"

#define  charsmin -1
new SzEntityClass[MAX_NAME_LENGTH];
new g_use_entity, g_use_float, g_use_type;
new g_ent_pick_cycle
new ent1, next_ent, third_ent, fourth_ent, fifth_ent

public plugin_init()
{
    register_plugin("Remote entity use", "6-12-2021", "SPiNX");
    g_use_type    = register_cvar("use_type", TOGGLE)
    g_use_entity  = register_cvar("use_entity", SHOOT-OPEN)
    g_use_float   = register_cvar("use_float", TWO)
    g_ent_pick_cycle = register_cvar("use_pick", "1")

    register_clcmd("useful_pick" , "@useful_pick_scanner"    , 0, ": Remotely USE things.");
}

@useful_pick_scanner(id)
{
    get_pcvar_string(g_use_entity, SzEntityClass, charsmax(SzEntityClass))
    ent_finder()
    //new ent = find_ent_by_class( charsmin    , SzEntityClass)
    if (ent1 > 0)
        @open_sesame(ent1,id)

    return PLUGIN_HANDLED;
}

@open_sesame(ent1,id)
{
    new ent_name[MAX_NAME_LENGTH];
    new Float:use_float = get_pcvar_float(g_use_float);
    new use_type  = get_pcvar_num(g_use_type);

    pev(ent1, pev_targetname, ent_name, charsmax(ent_name))

    server_print ("%s", ent_name)

    client_print(id, print_center, "Open sesame");

    ExecuteHam(Ham_Use, ent1, id, 0, use_type, use_float);

    get_pcvar_string(g_use_entity, SzEntityClass, charsmax(SzEntityClass))

    if(equal(SzEntityClass, "momentary_door"))
        set_pcvar_string(g_use_entity, "momentary_rot_button" )

    if (next_ent && get_pcvar_num(g_ent_pick_cycle))
        set_task(1.0, "@2nd_ent", id)

    return PLUGIN_CONTINUE;
}


@2nd_ent(id)
{
    server_print "Found 2nd ent"
    client_print(id, print_center, "Open sesame #2");
    new Float:use_float = get_pcvar_float(g_use_float);
    new use_type  = get_pcvar_num(g_use_type);
    ExecuteHam(Ham_Use, next_ent, id, 0, use_type, use_float);
    if (third_ent) set_task(1.0,"@3rdEnt", id);
}

@3rdEnt(id)
{
    server_print "Found 3rd ent"
    client_print(id, print_center, "Open sesame #3");
    new Float:use_float = get_pcvar_float(g_use_float);
    new use_type  = get_pcvar_num(g_use_type);
    ExecuteHam(Ham_Use, third_ent, id, 0, use_type, use_float);
    if (fourth_ent) set_task(1.0,"@4thEnt", id);
}

@4thEnt(id)
{
    server_print "Found 4th ent"
    client_print(id, print_center, "Open sesame #4");
    new Float:use_float = get_pcvar_float(g_use_float);
    new use_type  = get_pcvar_num(g_use_type);
    ExecuteHam(Ham_Use, fourth_ent, id, 0, use_type, use_float);
    if (fifth_ent) set_task(1.0,"@5thEnt", id);
}

@5thEnt(id)
{
    server_print "Found 5th ent"
    client_print(id, print_center, "Open sesame #5");
    new Float:use_float = get_pcvar_float(g_use_float);
    new use_type  = get_pcvar_num(g_use_type);
    ExecuteHam(Ham_Use, fifth_ent, id, 0, use_type, use_float);
}

stock ent_finder()
{
    
    get_pcvar_string(g_use_entity, SzEntityClass, charsmax(SzEntityClass))
    ent1 = find_ent_by_class(charsmin, SzEntityClass);
    next_ent = find_ent_by_class(ent1, SzEntityClass);
    third_ent = find_ent_by_class(next_ent, SzEntityClass);
    fourth_ent = find_ent_by_class(third_ent, SzEntityClass);
    fifth_ent = find_ent_by_class(fourth_ent, SzEntityClass);

    if (ent1 > 0) return ent1;
    if (next_ent > ent1 && next_ent != ent1) return next_ent;
    if (next_ent > ent1 && next_ent != ent1 && third_ent != ent1 && third_ent != next_ent) return third_ent;
    if (fourth_ent > third_ent)
        return fourth_ent
    if (fifth_ent > fourth_ent)
        return fifth_ent
    return PLUGIN_CONTINUE;
}
