///JULY 11TH 2024 SPiNX

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define WEAPON_OFFSET 4

#define PLUGIN "HL Weaponbox Mod"
#define VERSION "1.21"
#define AUTHOR "SPiNX"

#define charsmin -1
#define HLW_PENGUIN         26

#if !defined set_ent_rendering
#define set_ent_rendering set_rendering
#endif

static const szWeapons[27][2][54] =
{
    {"              "      ,"                    "       },
    {"weapon_crowbar"      ,"models/w_crowbar.mdl"       },
    {"weapon_9mmhandgun"   ,"models/w_9mmhandgun.mdl"    },
    {"weapon_357"          ,"models/w_357.mdl"           },
    {"weapon_9mmAR"        ,"models/w_9mmar.mdl"         },
    {"weapon_m249"         ,"models/w_saw.mdl"           },
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
    {"weapon_grapple"      ,"models/w_bgrap.mdl"         },
    {"weapon_eagle"        ,"models/w_desert_eagle.mdl"  },
    {"weapon_pipewrench"   ,"models/w_pipe_wrench.mdl"   },
    {"weapon_m249"         ,"models/w_saw.mdl"           },
    {"weapon_displacer"    ,"models/w_displacer.mdl"     },
    {"              "      ,"                    "       },
    {"weapon_shockrifle"   ,"models/w_shock_rifle.mdl"   },
    {"weapon_sporelauncher","models/w_spore_launcher.mdl"},
    {"weapon_sniperrifle"  ,"models/w_m40a1.mdl"         },
    {"weapon_knife"        ,"models/w_knife.mdl"         }, 
    {"weapon_penguin"      ,"models/w_penguinnest.mdl"   }
};

new g_iGlow

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHam(Ham_Spawn, "weaponbox", "@_weaponbox", 1);
    g_iGlow = register_cvar("weaponbox_glow", "1");
}

@_weaponbox(iEnt)
{
    static iOwner; iOwner = pev(iEnt, pev_owner)
    static iGlow_cvar;iGlow_cvar = get_pcvar_num(g_iGlow);
    static wpn_id; wpn_id = get_user_weapon(iOwner)
    if(iGlow_cvar > charsmin && pev_valid(iEnt)>1)
    {
        if(HLW_CROWBAR <= wpn_id <= HLW_PENGUIN)
        {
            engfunc(EngFunc_SetModel, iEnt, szWeapons[wpn_id][1]);
        }
        if (wpn_id == HLW_TRIPMINE)
        {
            set_task(2.0, "@mine_adj", iEnt)
        }
        if(iGlow_cvar)
        {
            set_ent_rendering(iEnt, kRenderFxGlowShell, COLOR(), COLOR(), COLOR(), kRenderNormal, random_num(20,100));
        }
    }
}

@mine_adj(iEnt)
{
    if(pev_valid(iEnt)>1)
    {
        static Float:fOrigin[3];
        pev(iEnt, pev_origin, fOrigin)
        fOrigin[2] -= 40.0
    
        set_pev(iEnt, pev_origin, fOrigin)
    }
}

stock COLOR()
{
    return random(256);
}
