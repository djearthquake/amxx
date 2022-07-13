#include amxmodx
#include engine
#include fakemeta
#define charsmin                      -1
#define MAX_CMD_LENGTH  128
#define WORLDSPAWN            0
#define echo                                server_print

new const Ent_of_interest[] = "ambient_generic"

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
    if(equali(Classname,Ent_of_interest) && equali(key,"message"))
        DispatchKeyValue("message", "") //kills sound
}

public plugin_cfg()
    register_plugin("Ambient Sound Remover", "1.0", ".sρiηX҉.")

public OnAutoConfigsBuffered()
    sweep_ents()

public sweep_ents()
{
    //cleanup ents
    new SzTarget[MAX_NAME_LENGTH]
    new SzTargetName[MAX_NAME_LENGTH]
    new iEnt
    echo "Checking for %s^nents to remove", Ent_of_interest
    echo "..........................................................."
    while ((iEnt = find_ent(charsmin, Ent_of_interest)) > WORLDSPAWN)
    {
        pev(iEnt, pev_targetname, SzTargetName, charsmax(SzTargetName))
        pev(iEnt, pev_targetname, SzTarget, charsmax(SzTarget))
        remove_entity(iEnt)
        server_print "Remove Ambient ent#%i^n%s %s", iEnt, SzTargetName, SzTarget

    }
}
