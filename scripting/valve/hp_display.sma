/*Intended for Windowed-mode*/

#include amxmodx
#include amxmisc
#include fakemeta

#define PLUGIN  "HP Display"
#define VERSION "0.0.4"
#define AUTHOR  "SPiNX"

#define URL              "https://github.com/djearthquake/amxx/tree/main/scripting/"

new g_x, g_y;
new g_txt[MAX_PLAYERS +1]
static iHudtype

public plugin_init()
{
    #if AMXX_VERSION_NUM >= 179 || AMXX_VERSION_NUM <= 190
    register_plugin(PLUGIN, VERSION, AUTHOR);
    #else
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);
    #endif

    register_concmd("show_hp","cmdHP",0,": Show your HP in windowed-mode.");
    iHudtype = get_user_msgid("HudTextPro")
    g_x = register_cvar("txt_x", "20")
    g_y = register_cvar("txt_y", "-500")

}

public cmdHP(id,level,cid)
{
    if(!is_user_connected(id))
        return PLUGIN_HANDLED

    if(!cmd_access(id,level,cid,1))
    {
        client_print(id,print_chat,"You do not have access to %s %s by %s!",PLUGIN, VERSION, AUTHOR)
        return PLUGIN_HANDLED
    }

    task_exists(id) ? remove_task(id) : @task_hp(id);

    return PLUGIN_HANDLED
}

@task_hp(id)
{
    if(is_user_connected(id))
    {
        set_task 1.0, "@show_hp",id,_,_,"b"
    }
}

@show_hp(id)
{
    static str[MAX_PLAYERS]
    if(is_user_alive(id))
    {
        g_txt[id]++
        static hp; hp = pev(id, pev_health);
        static arm; arm = pev(id, pev_armorvalue);
        formatex(str, charsmax(str), arm ? "%i|%i" : "%i", hp, arm)
        set_hudmessage(255, 255, 255, 0.02, 0.89, .effects= 0 , .holdtime= 5.0)
        switch(g_txt[id])
        {
            case 1: client_print id, print_center, arm ? "%i|%i" : "%i", hp, arm ;
            case 2: iHudtype ? show_dhudmessage( id, arm ? "%i|%i" : "%i", hp, arm) : pretty_txt(str, id)
            case 3: pretty_txt(str, id)
            case 4: remove_task(id)
        }

    }

}

public client_disconnected(id)
{
    if(task_exists(id))
    {
        remove_task(id)
        g_txt[id] = 0;
    }

}
 //20:100= TOP LEFT
public pretty_txt(str[], id)
{
    new x = get_pcvar_num(g_x)
    new y = get_pcvar_num(g_y)
    emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id)
    ewrite_byte(TE_TEXTMESSAGE);
    ewrite_byte(0);      //(channel)
    ewrite_short(x);  //(x) -1 = center)
    ewrite_short(y);  //(y) -1 = center)
    ewrite_byte(2);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    ewrite_byte(0);  //(red) - text color
    ewrite_byte(255);  //(green)
    ewrite_byte(64);  //(blue)
    ewrite_byte(200);  //(alpha)
    ewrite_byte(255);  //(red) - effect color
    ewrite_byte(0);  //(green)
    ewrite_byte(0);  //(blue)
    ewrite_byte(25);  //(alpha)
    ewrite_short(100);  //(fadein time)
    ewrite_short(300);  //(fadeout time)
    ewrite_short(300);  //(hold time)
    ewrite_short(250); //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
    ewrite_string(str); //(text message) 512 chars max string size
    emessage_end();
}
