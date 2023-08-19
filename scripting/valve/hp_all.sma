#include amxmodx
#include amxmisc
#include fakemeta
#define get_user_model(%1,%2,%3) engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, %1 ), "model", %2, %3 )

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

static sModel[MAX_PLAYERS];

public plugin_init()
    register_plugin("All HP","1.1","SPiNX");

new g_Adm, g_AI

public client_putinserver(id)
{
    if(is_user_connected(id))
    {
        is_user_bot(id) ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
        is_user_admin(id) ? SetPlayerBit(g_Adm, id) : ClearPlayerBit(g_Adm, id)
        if(CheckPlayerBit(g_AI, id))
            return
        set_task(0.1,"fw_PlayerPostThink",id,.flags="b")
    }
}

public client_disconnected(id)
    remove_task(id)

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

        is_user_connected(ent) ?
            get_user_name(ent,classname,charsmax(classname)) :
            pev(ent,pev_classname,classname,charsmax(classname))

        static reclass[MAX_NAME_LENGTH], armor; armor = pev(ent,pev_armorvalue)
        if(health)
        {
            if(is_user_alive(ent) )
            {
                reclass = CheckPlayerBit(g_AI, ent) ? "^n^n(bot)" : "^n^n(human)"
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
