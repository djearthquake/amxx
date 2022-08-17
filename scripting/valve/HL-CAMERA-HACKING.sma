#include amxmodx
#include engine
#include hamsandwich
#define charsmin -1

new cam1, next_cam, third_eye, g_slide_show;

public plugin_init()
{
    register_plugin("2 cam views", "1.0", "SPiNX")
    register_clcmd("check_camera", "@CmdCam", 0, "check cameras")
    g_slide_show = register_cvar("camera_slideshow", "0")
}

@CmdCam(id)
{
    camafind();
    ExecuteHam(Ham_Use, cam1, id, id, 3, 1.0);
    if (next_cam && get_pcvar_float(g_slide_show))
        set_task(5.0,"@2ndCam", id);
    return PLUGIN_HANDLED;
}

@2ndCam(id)
{
    ExecuteHam(Ham_Use, next_cam, id, id, 3, 1.0);
    if (third_eye && get_pcvar_float(g_slide_show))set_task(5.0,"@3rdCam", id);
}

@3rdCam(id)
    ExecuteHam(Ham_Use, third_eye, id, id, 3, 1.0);

stock camafind()
{
    cam1 = find_ent_by_class(charsmin, "trigger_camera");
    next_cam = find_ent_by_class(cam1, "trigger_camera");
    third_eye = find_ent_by_class(next_cam, "trigger_camera");

    if (cam1 > 0) return cam1;
    if (next_cam > cam1 && next_cam != cam1) return next_cam;
    if (next_cam > cam1 && next_cam != cam1 && third_eye != cam1 && third_eye != next_cam) return third_eye;
    return PLUGIN_CONTINUE;
}