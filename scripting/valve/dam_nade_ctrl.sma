#define AUTHOR  "SPiNX"

#define HE_IMMUNITY_ACCESS     ADMIN_RCON

#if !defined DMG_GRENADE
const DMG_GRENADE = (1<<24)
#endif

new XAdmin, Float:XMultipler, XPrintDamage, XBreakable
new const CvarXAdminDesc[]="Grenade admin immunity"
new const CvarXMultiplerDesc[]="Grenade damage multiplier"
new const CvarXPrintDesc[]="Grenade damage print"
new const CvarXBreakableDesc[]="Grenades/C4 destroys breakables."

new bool:bOF_run
new g_MOD_DMG

public plugin_init()
{   
    register_plugin(PLUGIN, VERSION, AUTHOR);

    bind_pcvar_num(get_cvar_pointer("mp_grenade_admin") ?
    get_cvar_pointer("mp_grenade_admin") :
    create_cvar("mp_grenade_admin", "0", FCVAR_SERVER, CvarXAdminDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), XAdmin)

    bind_pcvar_num(get_cvar_pointer("mp_grenade_advertise") ?
    get_cvar_pointer("mp_grenade_advertise") :
    create_cvar("mp_grenade_advertise", "0", FCVAR_SERVER, CvarXPrintDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), XPrintDamage)

    bind_pcvar_num(get_cvar_pointer("mp_grenade_expansion") ?
    get_cvar_pointer("mp_grenade_expansion") :
    create_cvar("mp_grenade_expansion", "0", FCVAR_SERVER, CvarXBreakableDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), XBreakable)

    bind_pcvar_float(get_cvar_pointer("mp_grenade_multiplier") ?
    get_cvar_pointer("mp_grenade_multiplier") :
    create_cvar("mp_grenade_multiplier", "5.0", FCVAR_SERVER, CvarXMultiplerDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 10.0), XMultipler)

    register_touch("grenade", "func_breakable", "@pop")
    register_touch("grenade", "func_pushable", "@pop")

    bOF_run =  is_running("gearbox") || is_running("valve")
    g_MOD_DMG = !bOF_run ? DMG_GRENADE : DMG_BLAST

    RegisterHam(Ham_TakeDamage, "player", "Fw_Damage");
    #if defined CZ
    if(is_running("czero"))
    {   
        RegisterHamBots(Ham_TakeDamage, "Fw_Damage")
    }
    #endif
}

@pop(grenade, breakable)
    if(XBreakable)
        ExecuteHam(Ham_TakeDamage,breakable,breakable,grenade,500.0,DMG_CRUSH)

public Fw_Damage(victim, inflictor, attacker, Float:fDamage, dmgbits)
{   
    if(is_user_connected(victim) && !is_user_bot(attacker))
    {   
        if( dmgbits == g_MOD_DMG)
        {   
            if(fDamage)
            {
                    #define DAMAGE       4
                    new Float:Damage_adj  = fDamage*XMultipler;

                    if(XAdmin && access(victim, HE_IMMUNITY_ACCESS) || !XMultipler)
                    {   
                        if(XPrintDamage)
                            client_print attacker, print_console, "%n hit %n with grenade.^n Damage is off!", attacker, victim
                        return HAM_SUPERCEDE
                    }
                    else
                    {   
                        SetHamParamFloat(DAMAGE, Damage_adj)

                        if(XPrintDamage)

                            if(is_user_connected(attacker))
                            {   
                                client_print attacker, print_center, "%d", Damage_adj
                                client_print attacker, print_console, "%n hit %n with %d grenade damage.", attacker, victim, Damage_adj
                            }


                    }


            }

        }
        else return HAM_IGNORED
    }
    return HAM_HANDLED
}
