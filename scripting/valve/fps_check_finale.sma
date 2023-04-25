#include amxmodx
#define SPINX
/*#define JOCANIS*/

#if defined SPINX

#define charsmin    -1

new const svMessage[]="Invalid fps_max hacking."
new iFps_kick, iFps_kick2;
public plugin_init()
{
    register_plugin("FPS kick", "1.3", "SPiNX");
    iFps_kick = register_cvar("fps_kick","200");
    iFps_kick2 = register_cvar("fps_drop","20");
}
public client_command(id)
    if(is_user_connected(id) && !is_user_bot(id) )

        query_client_cvar(id, "fps_max", "cvar_result_func");

public cvar_result_func(id, const cvar[], const value[])


    if( equali(cvar,"fps_max") && !is_str_num(value) && containi(value, ".") == charsmin && get_user_userid(id))
        server_cmd("banid 5.0 #%d", get_user_userid(id), str_to_num(value)) && server_cmd("writeid") &&
        server_cmd("kick #%d Your %s is %s. That is not a number! %s", get_user_userid(id), cvar, value, svMessage);

    else

    if(equali(cvar,"fps_max") && str_to_num(value) >= get_pcvar_num(iFps_kick) || (equali(cvar,"fps_max") && str_to_num(value) <=  get_pcvar_num(iFps_kick2)) )

        server_cmd("kick #%d Your %s is %s. Do not use over %i or under %i", get_user_userid(id), cvar, value, get_pcvar_num(iFps_kick), get_pcvar_num(iFps_kick2));
#endif

#if !defined SPINX
    #if !defined JOCANIS
        #error Go make a new script or post and wait on forums/Discord.
    #endif
#include fakemeta
#if defined JOCANIS
new iFps_kick
public plugin_init()
{
    iFps_kick = register_cvar("fps_kick","200");
    register_forward(FM_CmdStart, "CmdStart");
}
#endif

#define MAX_PLAYERS 32
#define CALC (fps_info[id][num_cmds] * 1000.0)
/*Dev-CS.ru*/
enum fps_s {
    warnings,
    num_cmds,
    msec_sum,
    Float:next_check,
    Float:fps
}; new fps_info[MAX_PLAYERS+1][fps_s];

public client_connected(id)
    arrayset(fps_info[id], 0, sizeof(fps_info[]));

public CmdStart(id, uc_handle)
{
    if( get_pcvar_num(iFps_kick) && id > 0 && is_user_connected(id) && !is_user_bot(id))

    {

        if (fps_info[id][next_check] <= get_gametime())
        {

            //if (CALC > 0 && fps_info[id][msec_sum] > 0) //fixes errors
            fps_info[id][fps] = (CALC / fps_info[id][msec_sum])

            if (fps_info[id][fps] > get_pcvar_num(iFps_kick))

            if (++fps_info[id][warnings] > 3)

                server_cmd("kick #%d Your FPS is %i. Do not use over %i", get_user_userid(id), floatround(fps_info[id][fps]), get_pcvar_num(iFps_kick));

            fps_info[id][num_cmds] = 0;
            fps_info[id][msec_sum] = 0;
            fps_info[id][next_check] = get_gametime() + 1.0;
        }

        fps_info[id][num_cmds]++;

        fps_info[id][msec_sum] += get_uc(uc_handle, UC_Msec);
    }

}
#endif
