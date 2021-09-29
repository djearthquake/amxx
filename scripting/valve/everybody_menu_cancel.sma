/*Close menus that TSR*/

#include amxmodx
/*Borderline slowhacking*/
@clr(id)client_cmd id, "slot10"

public plugin_init()
register_plugin("AMXX MENU CLEANER","1.0","SPiNX")

public client_putinserver(id)
if(is_user_connected(id) && !task_exists(id))
    set_task(0.5,"@clear_menu",id) && set_task(0.8,"@clr",id)

@clear_menu(id)
if(is_user_connected(id))
{
    new menu = menu_create ("Menu cleaner", "@menu");
    menu_additem(menu, "Server menu reset", "1");
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
}
@menu(id, menu, item)
if(is_user_connected(id))
    menu_destroy(menu)
