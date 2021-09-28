/*Close menus that TSR*/
#include amxmodx

public plugin_init()
register_plugin("AMXX MENU CLEANER","1.0","SPiNX")

public client_putinserver(id)
if(is_user_connected(id) && !task_exists(id))
    set_task(1.0,"@clear_menu",id)

@clear_menu(id)
if(is_user_connected(id))
{
    set_task(5.0,"@clear",id)
    new menu = menu_create ("Menu cleaner", "@clear");
    menu_additem(menu, "Resetting this space from admin to game", "1");
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0 );
}
@clear(id, menu, item)
if(is_user_connected(id))
{
    client_print id, print_chat, "Automatically cleaning any dangling menus."
    client_cmd( id, "slot10" )
    menu_destroy(menu)
}
