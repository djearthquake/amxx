#include amxmodx
#include engine
#include fakemeta
#define SEND_MSG_ALLPLAYERS 0
new g_breath, g_face, g_pant;

public plugin_init()
{
    register_plugin("Winter breath", "0.2", "SPiNX|2021");

    g_face = register_cvar("chin_level", "37"); //Chin 37 was tested on OP4. 15 was former starting number.
    //Where steam comes off player. Higher the number the higher the breath

    g_pant = register_cvar("winter_breath", "1.5");
    //How frequent puffs
}

public plugin_precache()
{
   g_breath = precache_model("sprites/steam1.spr");
   //Switch over to generic. Allegedly easier on the server.
   precache_generic("sprites/steam1.spr"); //from valve folder
}

public client_putinserver(id)
    set_task(1.5,"fw_PlayerPostThink",id,.flags="b")

public client_disconnected(id)
    if(task_exists(id))
        remove_task(id)

public fw_PlayerPostThink(id,{Float,_}:...)
{

    if (is_user_alive(id) && is_user_outside(id) && get_pcvar_float(g_pant))
    {
        emessage_begin( MSG_PVS, SVC_TEMPENTITY , _, SEND_MSG_ALLPLAYERS );
        ewrite_byte(TE_PLAYERATTACHMENT);
        ewrite_byte(id); //who
        ewrite_coord(get_pcvar_num(g_face)); //where
        ewrite_short(g_breath); //what
        ewrite_short(1) //life
        emessage_end();

        if(task_exists(id))
            change_task(id, get_pcvar_float(g_pant))
    }

}

stock bool:is_user_outside(id)
{
    new Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);

    while(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_EMPTY)
        vOrigin[2] += 5.0;

    if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
        return true;

    return false;
}  
