//m_iSuicides
#include <amxmodx>
#include <engine_stocks>
#include <fakemeta>

#define MAX_NAME_LENGTH 32
#define TIMER 1995
#define WTF (1<<random(23))
#define WOW random_float(500.0,1000.0)
#define charsmin                  -1

new iSuicideTimer[MAX_PLAYERS+1]

static m_fNextSuicideTime
const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;

public plugin_init()
{
    register_plugin("OP4 Suicide", "1.2","SPiNX");
    m_fNextSuicideTime = (find_ent_data_info("CBasePlayer", "m_fNextSuicideTime") / LINUX_OFFSET_WEAPONS) - LINUX_DIFF
    //Flag maps kill command works so we pause the plugin
    if(find_ent(charsmin,"info_ctfdetect"))
        pause "a";
}

public client_putinserver(id)
{
    if(is_user_connected(id) && !is_user_bot(id))
        set_pdata_float(id, m_fNextSuicideTime, 0.0)
}

public client_kill(id)
if(is_user_connected(id))
{
    {
        is_user_alive(id) && !task_exists(id+TIMER) //!get_pdata_float(id, m_fNextSuicideTime)
        ?
            @kill(id)
            :
            client_print(id, print_chat, "Can't smoke yourself for another minute.")
    }
}

@kill(id)
{
    if(is_user_connected(id))
    {
        new Float: fOK_Suicide = get_pdata_float(id, m_fNextSuicideTime)

        fakedamage(id,"Suicide",WOW,WTF);
        is_user_alive(id) ? set_task(5.0, "client_kill", id) : remove_task(id)
        @advert(id)
    }
}

@Timer(chk)
{
    new id = chk - TIMER
    if(is_user_connected(id))
        set_pdata_float(id, m_fNextSuicideTime, 0.0)
}

@advert(id)
{
    set_task(60.0, "@Timer", id+TIMER) //instead of //set_pdata_float(id, m_fNextSuicideTime, 60.0)
    static name[MAX_NAME_LENGTH];
    get_user_name(id,name,charsmax(name))
    client_print(0,print_chat,"%s is trying to kill themself!",name);
}
