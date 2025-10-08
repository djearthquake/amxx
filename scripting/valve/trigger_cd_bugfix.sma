#include amxmodx
#include engine_stocks
#include fakemeta

/*https://github.com/ValveSoftware/halflife/issues/3714*/

static const ent_type1[]= "trigger_cdaudio"
static const ent_type2[]= "target_cdaudio"

static Loop

public plugin_init()
{
    register_plugin("trigger_cd_bugfix","1.0.2",".sρiηX҉.");
    if(!has_map_ent_class(ent_type1))pause "a"
}


public client_command(id)
{
    static szentClass[MAX_PLAYERS], iTrack;
    new ent = MaxClients;
    new fOrigin[3];

    if(is_user_alive(id))
    {
        pev(id, pev_origin, fOrigin)
        while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, fOrigin, 500.0)) >MaxClients) //TO DO: cache radius and origin on map changes 
        {
            pev(ent, pev_classname, szentClass, charsmax(szentClass))
            if(equal(szentClass,ent_type2))
            {
                iTrack = pev(ent, pev_health)
                @play_track(id, iTrack)
            }
        }
    }
}

@play_track(id, iTrack)
{
    if(is_user_connected(id))
    {
        emessage_begin(MSG_ONE_UNRELIABLE,SVC_CDTRACK,{0,0,0},id);
        ewrite_byte(iTrack);
        ewrite_byte(Loop);
        emessage_end();
    }
}

/*
Server tried to send invalid command:"cd play  21
{
"origin" "-1660 -885 -4043"
"radius" "500"
"health" "21"
"classname" "target_cdaudio"
}
*/
