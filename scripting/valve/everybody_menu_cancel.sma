/*Close menus that TSR*/
#include amxmodx
new bool:bAlready_cleared[MAX_PLAYERS + 1]

@clr(id)
if(is_user_connected(id))
{
    client_cmd id, "slot10"
    bAlready_cleared[id] = true
}

public plugin_init()
    register_plugin("AMXX MENU CLEANER","1.0","SPiNX")

public client_putinserver(id)
    if(is_user_connected(id) && !is_user_bot(id) && !bAlready_cleared[id])
        set_task 0.2,"@clear_menu",id

public client_disconnected(id)
     bAlready_cleared[id] = false

@clear_menu(id)
{
    if(is_user_connected(id) && !bAlready_cleared[id])
    {
        new menu = menu_create ("Menu cleaner", "@menu");
        menu_additem(menu, "Server menu reset", "1");
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0);
        set_task 0.5,"@clr",id
    }
    else if(is_user_connecting(id))
    {
        server_print "%n^n is not ready to clear menu.", id
    }
}

@menu(id, menu, item)
{
    if(is_user_connected(id))
    {
        menu_destroy(menu)
    }
}
