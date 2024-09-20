#include amxmodx
#include cstrike
#include hamsandwich

#define PLUGIN   "Blade make Terrorist"
#define VERSION  "1.0.2"
#define AUTHOR   "SPiNX"
#define URL      "github.com/djearthquake"
#define MAX_PLAYERS 32

new HamHook:XDamage, Xcvar

new bool:bRegistered;

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR)
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL)
    #endif

    XDamage = RegisterHam(Ham_TakeDamage, "player", "@PostTakeDamage", 1);
    Xcvar = register_cvar("enable_knife_infection", "1")
}

@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        bRegistered = true;
        RegisterHamFromEntity(Ham_TakeDamage, ham_bot, "@PostTakeDamage", 1 );
        server_print("%s|%s|%s hambot from %N", PLUGIN, VERSION, AUTHOR, ham_bot)
    }
}

public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT")  && !bRegistered)
    {
        set_task(0.1, "@register", id);
    }
}

public plugin_end()
{
    DisableHamForward(XDamage)
}

@PostTakeDamage(iVictim, iInflictor, iAttacker, Float:iDamage, iDamagebits)
{

    static iCvar; iCvar = get_pcvar_num(Xcvar)
    iCvar ?  EnableHamForward(XDamage)    :  DisableHamForward(XDamage)
    static iKnife[MAX_PLAYERS]
    if(is_user_connected(iAttacker) && is_user_connected(iVictim))
    {
        static iGat;iGat = get_user_weapon(iAttacker)
        static iTeam; iTeam = get_user_team(iVictim)
        if(iTeam == 2)
        if(iGat == CSW_KNIFE)
        {
            iKnife[iVictim]++
            client_print 0, print_chat, "%n was struck by %n's knife %i times!", iVictim, iAttacker, iKnife[iVictim]
            if(iKnife[iVictim] == 2)
            {
                iKnife[iVictim] = 0
                cs_set_user_team(iVictim, 1)
            }
        }
    }
}
