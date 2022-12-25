/*Simple way to RTV with the missing RTV on existing Amxx base system*/

#include amxmodx
#include amxmisc
new XFrags_needed

public plugin_init()
{
    register_plugin("Simpler RTV", "1.23", "SPiNX")
    register_clcmd("say rtv","handlesay")
    XFrags_needed = register_cvar("rtv_frags","4")
}
public handlesay(id)
{
    new iFrags_Needed = get_pcvar_num(XFrags_needed)
    new iFrags = get_user_frags(id)
    new rtv_minimum = iFrags_Needed - 1
    new Menu_DESIGN_privledges = iFrags_Needed

    if(is_user_admin(id) || iPlayers() < (iFrags_Needed / 2) || get_user_time(id) > 120) //People leave if alone on map and can't RTV.
        iFrags = (iFrags + 1) //Admin partial boost.*/
    if(iFrags >= rtv_minimum && iFrags < Menu_DESIGN_privledges)
    /*Standard*/
    {
        callfunc_begin("@rtv","mapchooser.amxx")
        callfunc_push_int(id)
        callfunc_end()
    }

    else if(iFrags >= Menu_DESIGN_privledges)
    /*Design a menu*/
    {
        @menu(id)
    }

    else
    /*Explain*/
        client_print id,print_chat,"Need %i more frags to RTV^n or %i more to votemap menu access!", (rtv_minimum - iFrags), (Menu_DESIGN_privledges - iFrags)
}

@menu(id)
{
    if(is_user_connected(id))
    {
        new menu = menu_create ("Rock The Vote!", "@rtv_menu");
        menu_additem(menu, "Rock the Vote now!^n", "1");
        menu_additem(menu, "Nominate maps first.", "2")
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0, 60);
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

@rtv_menu(id, menu, item)
{
    if(is_user_connected(id))
    {
        switch(item)
        {
            case 0:
            {
                callfunc_begin("@rtv","mapchooser.amxx")
                callfunc_push_int(id)
                callfunc_end();
            }
            case 1:
            {
                callfunc_begin("cmdVoteMapMenu","mapsmenu.amxx")
                callfunc_push_int(id)
                callfunc_end()
            }
        }
    }
    return PLUGIN_HANDLED
}

stock iPlayers()
{
    new players[ MAX_PLAYERS ],iHeadcount;get_players(players,iHeadcount,"ch")
    return iHeadcount
}
/*
changelog 
* 
1.0 - mapsmenu cmd free-for-all
1.1 - rtv call functions remade mapchooser and need to have frags to RTV and 11 to get admin-style menu again instead of standard
1.2 - Trying methods. Adding some get_players weighting as I finish.
1.3 - Cvar min frags.
* 
*/
