/*Simple way to RTV with the missing RTV on existing Amxx base system*/

#include amxmodx
#include amxmisc

public plugin_init()
{
    register_plugin("Simpler RTV", "1.22", "SPiNX")
    register_clcmd("say rtv","handlesay")
}
public handlesay(id)
{
    new iFrags = get_user_frags(id)
    new rtv_minimum = 4
    new Menu_DESIGN_privledges = 5
    if(is_user_admin(id))
        iFrags = (iFrags + 3)
    if(iFrags >= rtv_minimum && iFrags <=Menu_DESIGN_privledges)
    /*Standard*/
    {
        callfunc_begin("@rtv","mapchooser.amxx")
        callfunc_push_int(id)
        callfunc_end()
    }

    else if(iFrags > Menu_DESIGN_privledges)
    /*Design a menu*/
    {
        callfunc_begin("cmdVoteMapMenu","mapsmenu.amxx")
        callfunc_end()
    }

    else
    /*Explain*/
        client_print id,print_chat,"Need %i more frags to RTV^n or %i more to votemap menu access!", (rtv_minimum - iFrags), (Menu_DESIGN_privledges - iFrags)

}

/*
changelog 
* 
1.0 - mapsmenu cmd free-for-all
1.1 - rtv call functions remade mapchooser and need to have frags to RTV and 11 to get admin-style menu again instead of standard
1.2 - Trying methods. Adding some get_players weighting as I finish.
* 
*/

