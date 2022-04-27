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

public plugin_init()
{
    register_plugin("Remote entity use", "6-12-2021", "SPiNX");
    g_use_type    = register_cvar("use_type", TOGGLE)
    g_use_entity  = register_cvar("use_entity", SHOOT-OPEN)
    g_use_float   = register_cvar("use_float", TWO)

    register_clcmd("useful_pick" , "@useful_pick_scanner"    , 0, ": Remotely USE things.");
}

@useful_pick_scanner(id)
{
    get_pcvar_string(g_use_entity, SzEntityClass, charsmax(SzEntityClass))
    new ent = find_ent_by_class( charsmin    , SzEntityClass)
    if (ent > 0)
        @open_sesame(ent,id)

    return PLUGIN_HANDLED;
}

@open_sesame(ent,id)
{
    new ent_name[MAX_NAME_LENGTH];
    new Float:use_float = get_pcvar_float(g_use_float);
    new use_type  = get_pcvar_num(g_use_type);

    pev(ent, pev_targetname, ent_name, charsmax(ent_name))

    server_print ("%s", ent_name)

    client_print(id, print_center, "Open sesame");

    ExecuteHam(Ham_Use, ent, id, 0, use_type, use_float);

    get_pcvar_string(g_use_entity, SzEntityClass, charsmax(SzEntityClass))

    if(equal(SzEntityClass, "momentary_door"))
        set_pcvar_string(g_use_entity, "momentary_rot_button" )

    return PLUGIN_CONTINUE;
}
