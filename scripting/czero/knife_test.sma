#include amxmodx
#include cstrike
#include fakemeta
#include hamsandwich

#define PLUGIN   "Blade make Terrorist"
#define VERSION  "1.0.4"
#define AUTHOR   "SPiNX"
#define URL      "github.com/djearthquake"
#define MAX_PLAYERS 32

new HamHook:XDamage, Xcvar

new bool:bRegistered;
#if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
new ClientName[MAX_PLAYERS][MAX_PLAYERS+1]
#endif

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_forward(FM_ClientUserInfoChanged, "fwFmClientUserInfoChanged", 1)
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
        #if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
        server_print("%s|%s|%s hambot from %s", PLUGIN, VERSION, AUTHOR, ClientName[ham_bot])
        #else
        server_print("%s|%s|%s hambot from %N", PLUGIN, VERSION, AUTHOR, ham_bot)
        #endif
    }
}
#if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
public client_connect(id)
{
    if(is_user_connecting(id))
    {
        if(is_user_bot(id) && !bRegistered)
        {
            bRegistered = true;
            set_task(0.1, "@register", id);
        }
    }
}
public fwFmClientUserInfoChanged(const id)
{
    if (!is_user_connected(id))
        return;

    get_user_name(id, ClientName[id], charsmax(ClientName[]))
}
#else
public client_authorized(id, const authid[])
{
    if(equal(authid, "BOT")  && !bRegistered)
    {
        set_task(0.1, "@register", id);
    }
}
#endif

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
            #if AMXX_VERSION_NUM >= 179 && AMXX_VERSION_NUM <= 190
            client_print 0, print_chat, "%s was struck by %s's knife %i times!", ClientName[iVictim], ClientName[iAttacker], iKnife[iVictim]
            #else
            client_print 0, print_chat, "%n was struck by %n's knife %i times!", iVictim, iAttacker, iKnife[iVictim]
            #endif
            if(iKnife[iVictim] == 2)
            {
                iKnife[iVictim] = 0
                cs_set_user_team(iVictim, 1)

                static Float:fOrigin[3]
                pev(iVictim, pev_origin, fOrigin)
                ExecuteHamB(Ham_CS_RoundRespawn, iVictim);
                set_pev(iVictim, pev_origin, fOrigin)
            }
        }
    }
}
