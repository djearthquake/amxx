/*Simple way to RTV with the missing RTV on existing Amxx base system*/

#include amxmodx
#include fakemeta
#include amxmisc
new XFrags_needed

public plugin_init()
{
    register_plugin("Simpler RTV", "1.4", "SPiNX")
    register_clcmd("say rtv","handlesay")
    XFrags_needed = register_cvar("rtv_frags","5")
}
public handlesay(id)
{
    new iFrags_Needed = get_pcvar_num(XFrags_needed)
    new iFrags = get_user_frags(id)
    new rtv_minimum = iFrags_Needed - 1
    new Menu_DESIGN_privledges = iFrags_Needed

    if(is_user_admin(id) || iPlayers() < (iFrags_Needed / 2) || get_user_time(id) > 120) //People leave if alone on map and can't RTV.
        iFrags = (iFrags++) //Admin partial boost.
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
    {
        client_print id,print_chat,"Need %i more frags to RTV or %i more to votemap menu access!", (rtv_minimum - iFrags), (Menu_DESIGN_privledges - iFrags)
        set_task(2.0, "displayHud", id , .flags = "b");
    }

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

public displayHud(id)
if(is_user_connected(id))
{
    new SzClientFragHUDMessage[ MAX_RESOURCE_PATH_LENGTH ];

    id = is_user_alive(id) ? id : pev(id, pev_iuser2)
    formatex(SzClientFragHUDMessage, charsmax(SzClientFragHUDMessage), "Player: %n^n", id);

    new iFrags_Needed = get_pcvar_num(XFrags_needed)
    new iFrags = get_user_frags(id)

    new rtv_minimum = iFrags_Needed - 1

    if(is_user_admin(id) || iPlayers() < (iFrags_Needed / 2) || get_user_time(id) > 120) //People leave if alone on map and can't RTV.
        iFrags = (iFrags + 3) //Admin partial boost.

    if(rtv_minimum - iFrags < 1)
    {
        remove_task(id);
        @menu(id)
    }

    //new Menu_DESIGN_privledges = iFrags_Needed
    format(SzClientFragHUDMessage, charsmax(SzClientFragHUDMessage), "%i frags until RTV.", rtv_minimum - iFrags);
    set_hudmessage(random_num(0,255),random_num(0,255),random_num(0,255), -1.0, 0.55, 1, 2.0, 3.0, 0.7, 0.8, 3);  //charsmin auto makes flicker
    show_hudmessage(id, SzClientFragHUDMessage)

}

public client_disconnected(id)
{
    if(task_exists(id))
        remove_task(id);
}

/*
changelog
*
1.0 - mapsmenu cmd free-for-all
1.1 - rtv call functions remade mapchooser and need to have frags to RTV and 11 to get admin-style menu again instead of standard
1.2 - Trying methods. Adding some get_players weighting as I finish.
1.3 - Cvar min frags.
1.4 - Menu.
*
*/
