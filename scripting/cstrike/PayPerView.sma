/*Novelty code to charge any player willing to pay-per-view for the built-in map cameras*/

#include amxmodx
#include cstrike
#include engine
#include fakemeta
#include hamsandwich
#define  charsmin -1
#define NEWID Tsk - 777

new const cam[] = "trigger_camera"

new g_ent_name[MAX_NAME_LENGTH]
new bool:g_bIsinppv[MAX_PLAYERS + 1]
new g_show_cost

new ent, next_camera, three_cam, four_cam, five_cam;

public plugin_init()
{
    register_plugin("Pay-per-view", "7-5-2021", "SPiNX");
    g_show_cost = register_cvar("cam_cost", "500")

    register_clcmd("PPV"          , "@CmdCam"    , 0, ": Order|Cancel Pay-per-view[camera_view]");
    register_clcmd("say /PPV"     , "@CmdCam"    , 0, ": Order|Cancel Pay-per-view[camera_view]");
}

@CmdCamBrk(id)
{
    client_print(id, print_center, "Pay per view CANCELLED!");
    g_bIsinppv[id] = false;

    if(task_exists(id+777))
    {
        remove_task(id+777)
    }
}

public client_disconnected(id)
    @cancel_ppv(id)

public client_connect(id)
{
    if(is_user_connected(id) && !task_exists(id))
        set_task(1.0, "@cancel_ppv", id)
}

@cancel_ppv(id)
{
    g_bIsinppv[id] = false
}

@CmdCam(id)
{
    new tmp_money = cs_get_user_money(id)
    new cost = get_pcvar_num(g_show_cost)
    camera_finder();

    if(g_bIsinppv[id] == true)
        @CmdCamBrk(id)

    else

    if (ent > 0 && !g_bIsinppv[id])

    {
    
        if (tmp_money > cost && is_user_alive(id))
        {
            @peek_cam(id)
            cs_set_user_money( id, (tmp_money - cost) )
            g_bIsinppv[id] = true
        }
        else
        {
            client_print(id, print_center, "You CAN'T AFFORD a smart cam...");
            client_print(0, print_chat, "Hey guys %n keeps trying to buy payperview they cannot afford!", id);
        }

    }

    return PLUGIN_HANDLED;
}

@peek_cam(id)
{
        new ent_name[MAX_NAME_LENGTH]
        camera_finder();
        
        pev(ent, pev_targetname, ent_name, charsmax(ent_name))
        server_print ("%s", ent_name)
    
        client_print(id, print_center, "Pay per view!");
        ExecuteHam(Ham_Use, ent, id, id, 1, 1.0);
    
        //cam2 check
        if(next_camera != ent)
        
        {
            pev(next_camera, pev_targetname, g_ent_name, charsmax(g_ent_name))
    
            if (!equal(g_ent_name,""))
                set_task(7.0,"@peek_cam_next",id+777)
        }
    return PLUGIN_CONTINUE;
}

@peek_cam_next(Tsk)
{
    new id = NEWID
    server_print ("%s", g_ent_name)

    camera_finder();

    client_print(id, print_center, "Free Trailer viewing...");
    ExecuteHam(Ham_Use, next_camera, id, id, 1, 1.0);

    //cam3 check
    if(ent != next_camera && ent != three_cam && three_cam != next_camera)

        set_task(7.0,"@peek_cam_3",id+777)

    return PLUGIN_CONTINUE;


}

@peek_cam_3(Tsk)
{
    new id = NEWID
    server_print ("%s", g_ent_name)

    camera_finder();

    client_print(id, print_center, "Sneak Preview found!");
    ExecuteHam(Ham_Use, three_cam, id, id, 1, 1.0);

    //cam4 check
    if(ent != next_camera && ent != three_cam && three_cam != next_camera &&
    four_cam != ent && four_cam != three_cam && four_cam != next_camera && four_cam > 0)
        set_task(7.0,"@peek_cam_4",id+777)

    return PLUGIN_CONTINUE;
}

@peek_cam_4(Tsk)
{
    new id = NEWID
    server_print ("%s", g_ent_name)

    camera_finder();

    client_print(id, print_center, "Extra feed found!");
    ExecuteHam(Ham_Use, four_cam, id, id, 1, 1.0);

    //cam5 check
    if(four_cam != ent && four_cam != three_cam && four_cam != next_camera &&
    five_cam != ent && five_cam != next_camera && five_cam != three_cam && five_cam != four_cam && five_cam > 0)
        set_task(7.0,"@peek_cam_5",id+777)

    return PLUGIN_CONTINUE;
}

@peek_cam_5(Tsk)
{
    new id = NEWID
    server_print ("%s", g_ent_name)

    camera_finder();
    
    client_print(id, print_center, "Hidden cam found!");
    ExecuteHam(Ham_Use, five_cam, id, id, 1, 1.0);
}

stock camera_finder()
{
    ent         = find_ent_by_class( charsmin    , cam)
    next_camera = find_ent_by_class( ent         , cam)
    three_cam   = find_ent_by_class( next_camera , cam)
    four_cam    = find_ent_by_class( three_cam   , cam)
    five_cam    = find_ent_by_class( four_cam    , cam)
    
    if(ent > 0)
        return ent;
    if(next_camera > 0 && next_camera != ent)
        return next_camera;
    if(three_cam > 0 )
        return three_cam;
    if(four_cam > 0 )
        return four_cam;
    if(five_cam > 0 )
        return five_cam;

    return PLUGIN_CONTINUE;
}
