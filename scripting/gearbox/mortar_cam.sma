#include amxmodx
#include engine
#include fakemeta
#include fakemeta_stocks
#include fakemeta_util
//#include fun
#define CMD 1027
#define SHOW_COORDS 3140
#define MAX_NUMBER_MORTARS 4

#define EAGLE 358
#define MAX_BOX 200
#define MAX_MAG 16

new bool:bMorView[MAX_PLAYERS+1]
//new Float:g_Angle[MAX_NUMBER_MORTARS][3]
new Float:g_Angle[3]

new g_view_ent

public plugin_init()
{
    register_clcmd("mortar_cam","function", 0, "- toggle mortar cam")
    register_clcmd("mortar_view","function", 0, "- toggle view mortar")
    register_plugin("Mortar-view", "A", ".sρiηX҉.")
}

public function(id)
{
    if(is_user_connected(id))
    {

        bMorView[id] =  bMorView[id]  ?  false : true

        if(!bMorView[id])
        {
            attach_view(id,id)
            @task_cleanup(id)

            set_pev(id, pev_takedamage, DAMAGE_YES);
            //insert weapons giving here
            set_pdata_int(id, EAGLE, MAX_BOX)
            client_cmd id, "spk ^"tank deactivated^""
        }
        else
        {
            set_view(id, CAMERA_NONE)
            set_pev(id, pev_takedamage, DAMAGE_NO);
            fm_strip_user_weapons(id)
            client_cmd id, "spk ^"tank on^""
            task_exists(id) ? remove_task(id) : set_task(0.3,"view_mortar", id + CMD,"_",0,"b")
        }
    }
    return PLUGIN_HANDLED
}

public view_mortar(iWatcher)
{
    new id = iWatcher - CMD
    new effects = pev(id, pev_effects)

    g_view_ent = find_ent(-1, "mortar_shell")
    if(pev_valid(g_view_ent))
    {
        attach_view(id, g_view_ent)
    }

    if(is_user_connected(id) && bMorView[id])
    {
        set_pev(id, pev_effects, (effects | EF_NODRAW | FL_SPECTATOR | FL_NOTARGET))
        if(is_valid_ent(g_view_ent))
        {
            entity_get_vector(g_view_ent,EV_VEC_angles,g_Angle);

            is_user_alive(id) ? set_task(0.1,"@gyro", id+SHOW_COORDS) : remove_task(id + CMD)

            if(g_Angle[0] > 215.0 && g_Angle[0] < 300.0)
            {
                //set_view(id, CAMERA_UPLEFT)
                set_view(id, CAMERA_TOPDOWN)
                //attach_view(id, g_view_ent)
            }
            else if(g_Angle[0] < -50.0)
            {
                set_view(id, CAMERA_UPLEFT)
            }
            else
            {
                //set_view(id, CAMERA_TOPDOWN)
                //set_view(id, CAMERA_3RDPERSON)
                set_view(id, CAMERA_NONE)
                attach_view(id, g_view_ent)
            }
            /*
            if(g_Angle[0] > 250.0)
            {
                server_print("%n %i", id, EF_ChangePitch(g_view_ent));
                //entity_set_vector(id, EV_VEC_angles, {0.0,0.0,0.0});
            }
            */

        }
        /*
        else
        {
            set_view(id, CAMERA_NONE)
        }
        * */

    }

    //attach_view(id,id)

}
@gyro(Tsk)
{
    new id = Tsk - SHOW_COORDS
    is_user_alive(id) ? client_print(id, print_center, "%f|%f|%f", g_Angle[0], g_Angle[1], g_Angle[2]) : remove_task(id+SHOW_COORDS)
}

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

public client_disconnected(id)
{
    if(!is_user_connected(id))
        return PLUGIN_CONTINUE;
    @task_cleanup(id)
    return PLUGIN_HANDLED
}

public client_putinserver(id)
if(is_user_connected(id))
{
    @task_cleanup(id)
}

@task_cleanup(id)
{
    //Viewing mortar
    if(task_exists(id + CMD))
        remove_task(id + CMD)
    //Showing coords
    if(task_exists(id+SHOW_COORDS))
        remove_task(id+SHOW_COORDS)
    bMorView[id] = false
}
