///JULY 11TH 2024 SPiNX

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define WEAPON_OFFSET 4

#define PLUGIN "HL Weaponbox Mod"
#define VERSION "1.0"
#define AUTHOR "SPiNX"

#if !defined set_ent_rendering
#define set_ent_rendering set_rendering
#endif

static const szWeapons[24][2][48] =
{
    {"weapon_crowbar"      ,"models/w_crowbar.mdl"       },
    {"weapon_9mmhandgun"   ,"models/w_9mmhandgun.mdl"    },
    {"weapon_357"          ,"models/w_357.mdl"           },
    {"weapon_9mmAR"        ,"models/w_9mmar.mdl"         },
    {"weapon_crossbow"     ,"models/w_crossbow.mdl"      },
    {"weapon_shotgun"      ,"models/w_shotgun.mdl"       },
    {"weapon_rpg"          ,"models/w_rpg.mdl"           },
    {"weapon_gauss"        ,"models/w_gauss.mdl"         },
    {"weapon_egon"         ,"models/w_egon.mdl"          },
    {"weapon_hornetgun"    ,"models/w_hgun.mdl"          },
    {"weapon_handgrenade"  ,"models/w_grenade.mdl"       },
    {"weapon_tripmine"     ,"models/p_tripmine.mdl"      },
    {"weapon_satchel"      ,"models/w_satchel.mdl"       },
    {"weapon_snark"        ,"models/w_sqknest.mdl"       },
    ///OP4
    {"weapon_penguin"      ,"models/w_penguinnest.mdl"   },
    {"weapon_grapple"      ,"models/w_bgrap.mdl"         },
    {"weapon_displacer"    ,"models/w_displacer.mdl"     },
    {"weapon_m249"         ,"models/w_saw.mdl"           },
    {"weapon_sporelauncher","models/w_spore_launcher.mdl"},
    {"weapon_shockrifle"   ,"models/w_shock_rifle.mdl"   },
    {"weapon_eagle"        ,"models/w_desert_eagle.mdl"  },
    {"weapon_knife"        ,"models/w_knife.mdl"         },
    {"weapon_pipewrench"   ,"models/w_pipe_wrench.mdl"   },
    {"weapon_sniperrifle"  ,"models/w_m40a1.mdl"         }
};

new g_iGlow

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHam(Ham_Spawn, "weaponbox", "@_weaponbox", 1);
    g_iGlow = register_cvar("weaponbox_glow", "1");
}

public plugin_precache()
{
    for(new a; a < sizeof szWeapons; a++)
    {
        for(new b; b < sizeof szWeapons[]; b++)
        {
            precache_model(szWeapons[a][1]);
        }
    }
}

@_weaponbox(iEnt)
{
    static iGlow_cvar;
    iGlow_cvar = get_pcvar_num(g_iGlow);

    if(iGlow_cvar)
    {
        set_task(0.1, "@box_to_modify", iEnt);
    }
    set_task(0.1, "CheckOffsets", iEnt);
}

@box_to_modify(iEnt)
{
    if(pev_valid(iEnt)>1)
    {
        set_ent_rendering(iEnt, kRenderFxGlowShell, COLOR(), COLOR(), COLOR(), kRenderNormal, random_num(20,100));
    }
}

public CheckOffsets( iEnt )
{
    static iWeapon, szClass[MAX_NAME_LENGTH];
    for(new i=HLW_NONE; i<=MAX_PLAYERS+WEAPON_OFFSET; i++)
    {
        iWeapon = get_pdata_cbase_safe(iEnt, i, WEAPON_OFFSET);
        if( pev_valid(iWeapon) )
        {
            pev(iWeapon, pev_classname, szClass, charsmax(szClass));
            for(new a; a < sizeof szWeapons; a++)
            {
                for(new b; b < sizeof szWeapons[]; b++)
                {
                    //for(new c; c < sizeof szWeapons[][];c++)
                    {
                        if(equal(szClass, szWeapons[a][0]))
                        {
                            engfunc(EngFunc_SetModel, iEnt, szWeapons[a][1]);
                        }
                    }
                }
            }
        }
    }
}

stock COLOR()
{
    return random(256);
}
