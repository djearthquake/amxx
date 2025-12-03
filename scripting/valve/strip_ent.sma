#include amxmodx
#include engine
#include hamsandwich

#if !defined USE_ON
#define USE_ON 1.0
#endif

static const ent_type[]="player_weaponstrip"

public plugin_precache()
{
    static ent; ent = create_entity(ent_type)
    DispatchKeyValue( ent, "targetname", "stripper" )
    DispatchSpawn(ent);
}

public plugin_init()
{
    register_plugin( "Startup Strip", "0.2", "SPiNX" );
    register_concmd("strip", "@strip", 0, "- strips weapons")
}

@strip(id)
{
    if(is_user_alive(id))
    {
        static iStrip; iStrip = find_ent_by_tname(MaxClients, "stripper")
        if(iStrip)
        {
            ExecuteHam(Ham_Use,iStrip,id,id,USE_ON,0.0)
        }
        else
        {
            static ent; ent = create_entity(ent_type)
            DispatchKeyValue( ent, "targetname", "stripper" )
            DispatchSpawn(ent);
            @strip(id)
        }
    }
    return PLUGIN_HANDLED
}
