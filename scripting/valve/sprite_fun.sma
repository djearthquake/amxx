#include amxmodx
#include engine
#include fakemeta

#define iRandomColor random(256)
static const ent_type[]="env_sprite"
static const szTargetname[]="pyr_spr"
//static const szSprite2[]="sprites/FT/pyramid9.spr"
new const szSprite[]="sprites/640_logo.spr" //models/teleporter_orange_rings.mdl" //models/teleporter_blue_sprites.mdl" //"sprites/640_logo.spr"  //zerogxplode.spr
//static const szSprite[]="sprites/logo.spr"
static const szModel[]="models/crystal.mdl" //models/crystal.mdl" //"models/crystal.mdl" //w_icon.mdl" //FT/egypt1.mdl" //antfarms/looker35.mdl" //w_antidote.mdl"
static g_ent, /*g_ent1, g_ent2,*/ g_ent3

new g_cvar_count, g_cvar_flag, g_cvar_life, g_cvar_velocity

public plugin_precache()
{
    g_ent = precache_model(szSprite)
    //g_ent2 = precache_model(szSprite2)
    g_ent3 = precache_model(szModel)
}

public plugin_init()
{
    register_plugin("New Sprite", "1.0", ".sρiηX҉.");
    g_cvar_count = register_cvar("sprite_count", "100")
    g_cvar_flag = register_cvar("sprite_flag", "8")
    g_cvar_life = register_cvar("sprite_life", "100")
    g_cvar_velocity = register_cvar("sprite_velocity", "100")
    @make_sprite()
}

public plugin_cfg()
{
    set_task(random_float(20.0,30.0), "@break_model", 8381, _,_, "b" )
    set_task(random_float(15.0,25.0), "@color_sprite", 7496, _,_, "b")
}

@make_sprite()
{
    new iColormap[3];
    new szColormap[16]

    iColormap[0] = iRandomColor
    iColormap[1] = iRandomColor
    iColormap[2] = iRandomColor

    new iRanColorR = iRandomColor
    new iRanColorG = iRandomColor
    new iRanColorB = iRandomColor

    formatex(szColormap, charsmax(szColormap), "^"%i %i %i^"",iRanColorR, iRanColorG, iRanColorB)
    server_print szColormap

    new ent = create_entity(ent_type)
    {
        DispatchKeyValue( ent, "origin", "0 0 0" )
        DispatchKeyValue( ent, "scale", "1" )
        DispatchKeyValue( ent, "renderamt", "255" )
        DispatchKeyValue( ent, "rendermode", "5" )
        DispatchKeyValue( ent, "model", szSprite )
        DispatchKeyValue( ent, "framerate", "10.0" )
        DispatchKeyValue( ent, "angles", "0 0 0" )
        DispatchKeyValue( ent, "rendercolor", szColormap )  ///"200 205 50"     /*gold*/
        DispatchKeyValue( ent, "spawnflags", "1" )
        DispatchKeyValue( ent, "targetname", szTargetname )
        DispatchSpawn(ent);
    }
}

@color_sprite()
{
    new iSprite = find_ent_by_tname(-1,  szTargetname)
    if(get_playersnum() && iSprite)
    {
        if(pev_valid(iSprite))
        {
            remove_entity(iSprite)
            server_print "Removed %i", iSprite
            if(pev_valid(iSprite))
            {
                remove_entity(iSprite)
                server_print "Removed %i", iSprite
            }
            if(pev_valid(iSprite))
            {
                remove_entity(iSprite)
                server_print "Removed %i", iSprite
            }
            set_task(random_float(6.0,12.0), "@make_sprite", 6337)
        }
    }
}

@break_model({Float,_}:...)
{
    static iPosition[3], iSize[3], iVelocity[3], iRanVelocity, iSprite, iCount, iLife, iFlags;
    static Vec3Coord[3] = {0,0,0}

    iRanVelocity = get_pcvar_num(g_cvar_velocity)
    iCount =get_pcvar_num(g_cvar_count)
    iLife = get_pcvar_num(g_cvar_life)
    iFlags = get_pcvar_num(g_cvar_flag)

    iSprite = find_ent_by_tname(-1,  szTargetname)
    if(get_playersnum() && iSprite)
    {
        iPosition = Vec3Coord
        iSize = {100,100,100}
        iVelocity ={100,100,100}

        emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY, Vec3Coord , 0)
        ewrite_byte(TE_BREAKMODEL)
        ewrite_coord(iPosition[0])
        ewrite_coord(iPosition[1])
        ewrite_coord(iPosition[2])

        ewrite_coord(iSize[0])
        ewrite_coord(iSize[1])
        ewrite_coord(iSize[2])
        ewrite_coord(iVelocity[0])
        ewrite_coord(iVelocity[1])
        ewrite_coord(iVelocity[2])

        ewrite_byte(iRanVelocity) //(random velocity in 10's)
/*
        switch(random(3))
        {
            case 0: ewrite_short(g_ent1)
            case 1: ewrite_short(g_ent2)
            case 2: ewrite_short(g_ent3)
        }
*/
        ewrite_short(g_ent3)
        ewrite_byte(iCount)
        ewrite_byte(iLife) //(life in 0.1 secs)
        ewrite_byte(iFlags)
        //ewrite_byte(15)  //ceases client
        emessage_end()
    }
}
