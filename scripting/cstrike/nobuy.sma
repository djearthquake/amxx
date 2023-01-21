/*𝓼𝓹𝓲𝓷𝔁*/
#include <amxmodx>
#include <engine>
@freeze()pause "a"
/* Designed to sanitize maps that are not supposed to have BuyZone leaks. */
public plugin_precache()
{
    new SzMname[MAX_PLAYERS];
    register_plugin("BuyZone Comb","A","SPiNX|2019");
    get_mapname(SzMname, charsmax (SzMname) )
    new const ZONES[][]= {"aim_","awp_","fy_","he_","knife_"};
    for(new i;i < sizeof ZONES;++i)
    {
        if (containi(SzMname,ZONES[i]) != -1)
        {
            new Ent = create_entity( "info_map_parameters" );
            DispatchKeyValue( Ent, "buying", "3" )
            DispatchSpawn( Ent );
        }
        else if (containi(SzMname,ZONES[i]) == -1)
        {
            @freeze();
        }
    }
}
