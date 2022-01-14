#include amxmodx
#include engine
#include fakemeta
#define GYRO 3140
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
        task_exists(id) ? remove_task(id) : set_task(0.4,"view_mortar", id,"_",0,"b")
    }
    return PLUGIN_HANDLED
}

public view_mortar(id)
{
    if(is_user_connected(id))
    {
        new view_ent = find_ent(-1, "mortar_shell")
        if(view_ent && pev_valid(view_ent))
        {
            attach_view(id,view_ent)
            new SzViewEnt[3]
            num_to_str(view_ent, SzViewEnt, charsmax(SzViewEnt))
            is_user_alive(id) ? set_task(0.1,"@gyro", id+GYRO, SzViewEnt,charsmax(SzViewEnt),"a",2) : remove_task(id)
        }
        else
            attach_view(id,id)

    }

}
@gyro(SzViewEnt[3],Tsk)
{
    //new SzViewEnt[3]
    new Float:Angle[3]
    new id = Tsk - GYRO

    new view_ent = str_to_num(SzViewEnt)

    //if(!view_ent)
    view_ent = find_ent(-1, "mortar_shell")

    entity_get_vector(view_ent,EV_VEC_angles,Angle);
    is_user_alive(id) ? client_print(id, print_center, "%f|%f|%f", Angle[0], Angle[1], Angle[2]) : remove_task(id+GYRO)
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
    if(task_exists(id))
        remove_task(id)
    //Showing coords
    if(task_exists(id+GYRO))
        remove_task(id+GYRO)
}
