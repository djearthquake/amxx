#include <amxmodx>
#include <engine_stocks>

#define MAX_NAME_LENGTH 32
#define WTF (1<<random(23))
#define WOW random_float(200.0,300.0)

public plugin_init()
{
    register_plugin("OP4 Suicide", "1.1","SPiNX");
    new mname[MAX_NAME_LENGTH];
    get_mapname(mname,charsmax(mname));
    if (containi(mname,"op4c") > -1)pause "a";
}

public client_kill(id)
if(is_user_connected(id))
{
    static name[MAX_NAME_LENGTH];
    get_user_name(id,name,charsmax(name))
    fakedamage(id,"Suicide",WOW,WTF);
    client_print(0,print_chat,"%s is trying to kill themself!",name);
    is_user_alive(id) ? set_task(5.0, "client_kill", id) : remove_task(id)
}
