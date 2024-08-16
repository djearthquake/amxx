/*Show details of aiment*/

#define COUNTRY
//Comment out COUNTRY with // in front to disable country tagging feature.

#include amxmodx
#include amxmisc
#include fakemeta

#if defined COUNTRY
#include geoip
#endif

#define get_user_model(%1,%2,%3) engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, %1 ), "model", %2, %3 )

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

#define local                  "127.0.0.1"
#define charsmin           -1

#if defined COUNTRY
new ClientIP[MAX_PLAYERS+1][MAX_IP_LENGTH]
new ClientCountry[MAX_PLAYERS+1][MAX_NAME_LENGTH]
new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH]
#endif

static sModel[MAX_PLAYERS];

public plugin_init()
    register_plugin("All HP","1.22","SPiNX");

new g_Adm, g_AI

#if defined COUNTRY
public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        static szBuffer[MAX_NAME_LENGTH]
        get_user_name(id, szBuffer, charsmax(szBuffer))

        copy(ClientName[id], charsmax(ClientName[]), szBuffer)
        is_user_admin(id) ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id)
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public client_connectex(id, const name[], const ip[], reason[128])
{
    copyc(ClientIP[id], charsmax(ClientIP[]), ip, ':')
    reason = (containi(ip, local) > charsmin) ? "IP address misread!" : "Bad STEAMID!"
    copy(ClientName[id],charsmax(ClientName[]), name)
    //ClientCountry[id] = ""
    return PLUGIN_CONTINUE
}
#endif

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
        is_user_admin(id) ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id)

        if(CheckPlayerBit(g_AI, id))
            return

#if defined COUNTRY
        if(!equal(ClientIP[id], ""))
        {
            #if AMXX_VERSION_NUM == 182
                geoip_country( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]) );
            #else
                geoip_country_ex( ClientIP[id], ClientCountry[id], charsmax(ClientCountry[]), LANG_SERVER ); //tried all indexes from -1 to 1, all lead to client lang
            #endif
        }
#endif
        set_task(0.1,"fw_PlayerPostThink",id,.flags="b")
    }
}

public client_disconnected(id)
{
    remove_task(id)
    //ClientCountry[id] = ""
}

public fw_PlayerPostThink(id)
{

    if(is_user_connected(id))
    {

        static ent,bh
        static classname[MAX_RESOURCE_PATH_LENGTH],color[3]

        get_user_aiming(id,ent,bh)

        if(!ent)
            return

        static health; health = pev(ent,pev_health)
        static health_max; health_max = pev(ent,pev_max_health)

        if(is_user_connected(ent))
        {
            #if defined COUNTRY
            CheckPlayerBit(g_AI, ent) ?
            (classname = ClientName[ent]) :
            formatex(classname,charsmax(classname),"%s from %s", ClientName[ent], ClientCountry[ent])
            #else
            get_user_name(ent,classname,charsmax(classname))
            #endif
        }
        else
        {
            pev(ent,pev_classname,classname,charsmax(classname))
            if(contain(classname, "func_")>charsmin)
            {
                replace(classname, charsmax(classname), "func_", "")
            }
        }

        static reclass[MAX_NAME_LENGTH], armor; armor = pev(ent,pev_armorvalue)
        if(health)
        {
            if(is_user_alive(ent) )
            {
                reclass = !CheckPlayerBit(g_AI, ent) ? "^n^n(human)" : "^n^n(bot)"
                if(CheckPlayerBit(g_Adm, ent))
                {
                    reclass =  "^n^n(admin)"
                }
            }

            get_user_model(ent, sModel, charsmax( sModel ) );
            equal(sModel,"") ? pev(ent,pev_message,sModel,charsmax(sModel)) : formatex(classname,charsmax(classname), "%s%s%s" ,classname,reclass,sModel)

            switch(health)
            {
                case 1..10:   color = {255,0,0}    //red
                case 11..25:  color = {255,255,0}  //yellow
                case 26..50:  color = {255,165,0}  //orange
                case 51..100: color = {0,255,0}    //green
                case 101..1000:color = {120,0,128} //purple
                default: return
            }

            set_hudmessage(color[0], color[1], color[2], -1.0, 0.60, 1, 1.0, 0.4, 0.01, 0.01, -1)
            if(health_max)
            {
                armor ? show_hudmessage(id,"%s^n^nhealth %i/%i^n^narmor %i",classname, health, health_max, armor)
                :
                show_hudmessage(id,"%s^n^nhealth %i/%i",classname, health, health_max)
            }
            else
            {
                armor ? show_hudmessage(id,"%s^n^nhealth %i^n^narmor %i",classname, health, armor)
                :
                show_hudmessage(id,"%s^n^nhealth %i",classname, health)
            }
        }
        else
        {
            color = {120,0,128}
            set_hudmessage(color[0], color[1], color[2], -1.0, 0.60, 1, 1.0, 0.4, 0.01, 0.01, -1)
            static iTos; iTos = get_user_time(id);
            if(CheckPlayerBit(g_Adm, id) || iTos > 120)
                show_hudmessage(id,"%s",classname)
        }

    }


}
