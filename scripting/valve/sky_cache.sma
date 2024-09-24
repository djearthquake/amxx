/*Map world sky_cache*/
#include amxmodx

static const SzSkySides[][]={
    "up.tga",
    "ft.tga",
    "bk.tga",
    "lf.tga",
    "dn.tga",
    "rt.tga"
}

public plugin_init()
{
    register_plugin( "SkyyCacher", "0.2", "SPiNX" );
}

public plugin_precache()
{
    static szSky[MAX_PLAYERS], szSkyfile[MAX_RESOURCE_PATH_LENGTH];

    get_cvar_string("sv_skyname", szSky, charsmax(szSky))

    for(new plane;plane < sizeof SzSkySides;plane++)
    {
        formatex(szSkyfile, charsmax(szSkyfile), "gfx/env/%s%s", szSky, SzSkySides[plane])
        server_print "%s", szSkyfile

        file_exists(szSkyfile) ? precache_generic(szSkyfile) : log_amx("Missing: %s", szSkyfile)
    }
}
