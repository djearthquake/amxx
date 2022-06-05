/* Last udpate 07/30/21 Update to all mods -SPiNX */
#include <amxmodx>
#include <amxmisc>
#define HLW_KNIFE           0x0019
#define PLUGIN "HL Weapon Icon"
#define VERSION "1.3"
#define AUTHOR "SPiNX" //CS VERSION 1.2 and lower "Weapon Icon" by hoboman313/Zenix"
#define is_valid_player(%1) (1 <= %1 <= g_MaxPlayers )

#define MAX_PLAYERS 32

new iconstatus, pcv_iloc
new sprite[MAX_PLAYERS]
new wname[MAX_PLAYERS], iwpn
new user_icons[MAX_PLAYERS+1][MAX_PLAYERS]
new Pgg, g_MaxPlayers
new const dont_draw[][]={"crowbar", "displacer", "egon", "grapple", "gauss", "knife", "pipe", "penguin", "shockroach", "snark"}
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_event("CurWeapon", "update_icon", "bef")
    register_event("AmmoX", "draw_icon", "bef")
    register_event("DeathMsg", "event_death", "a")

    pcv_iloc = register_cvar("amx_weapon_location", "1") //became on|off switch
    Pgg = get_cvar_pointer("gg_enabled")  ? get_cvar_pointer("gg_enabled")  :  register_cvar("gg_enabled", "0")
    if ( is_running("gearbox") == 1 )
        iconstatus = get_user_msgid("StatusIcon")
    if ( is_running("cstrike") == 1 )
        iconstatus = get_user_msgid("Scenario")
    if ( is_running("czero") == 1 )
    {
        log_amx("Stack errors with CZ bots. Pausing unitl this is fixed.")
        pause "a"
    }
    g_MaxPlayers = get_maxplayers()
}


public update_icon(id)
if(is_valid_player(id) && !is_user_bot(id) && get_pcvar_num(pcv_iloc))
{
    remove_weapon_icon(id)

    static clip, ammo
    iwpn = get_user_weapon(id, clip, ammo)
    if (iwpn)
    {
        get_weaponname(iwpn,wname,charsmax(wname))
        copy(sprite, charsmax(sprite), wname)
        replace(sprite, charsmax(sprite), "weapon", "d")
        user_icons[id] = sprite
        draw_icon(id)
    }
    return
}


public draw_icon(id)
if(Pgg && !get_pcvar_num(Pgg) &&  get_pcvar_num(pcv_iloc))
{
    if(is_user_alive(id) && !is_user_bot(id) )
    {
        new icon_color[3]
        new iwpn, clip, ammo
    
        iwpn = get_user_weapon(id, clip, ammo)
        if (iwpn)
        {
            get_weaponname(iwpn,wname,charsmax(wname))
            copy(sprite, charsmax(sprite), wname)
            //replace(sprite, charsmax(sprite), "CSW", "d")
            replace(sprite, charsmax(sprite), "weapon", "d")
            // ammo check, this is for the color of the icon
            if (clip < 1 && ammo < 3)
                icon_color = {255, 0, 0} // outta ammo!
            else if ( clip < 1 || ammo < 10 )
                icon_color = {255, 160, 0} // last clip!
            else
                icon_color = {0, 160, 0}//green icon...decent ammo
        
            // draw the sprite itself
            new checkpoint = get_pcvar_num(pcv_iloc)
            if(checkpoint == 1)
            {
                emessage_begin(MSG_ONE_UNRELIABLE,iconstatus,{0,0,0},id)
                ewrite_byte(1) // status (0=hide, 1=show, 2=flash)
                ewrite_string(user_icons[id]) // sprite name
                ewrite_byte(icon_color[0]) // red
                ewrite_byte(icon_color[1]) // green
                ewrite_byte(icon_color[2]) // blue
                emessage_end()
            }
            else if (checkpoint > 1)
            {
                emessage_begin(MSG_ONE_UNRELIABLE,iconstatus,{0,0,0},id)
                ewrite_byte(1) // status (0=hide, 1=show, 2=flash)
                ewrite_string(user_icons[id]) // sprite name
                ewrite_byte(icon_color[0]) // alpha
                ewrite_short(0) // FlashRate
                ewrite_short(0) // flashDelay
                emessage_end()
            }
            else
                remove_weapon_icon(id)
        }
    
        for(new these = 0;these < sizeof(dont_draw);these++)
        if (containi(sprite,dont_draw[these]) != -1)
        {
            remove_weapon_icon(id)
            return
        }
    }
}

public remove_weapon_icon(id)
if(is_valid_player(id) && !is_user_bot(id))
{
    //check_icon_loc()
    emessage_begin(MSG_ONE_UNRELIABLE,iconstatus,{0,0,0},id)
    ewrite_byte(0)
    ewrite_string(user_icons[id])
    emessage_end()
}


public event_death()
{
    new id = read_data(2) // the dead player's ID (1-32)

    if(!is_user_alive(id) && !is_user_bot(id))
        remove_weapon_icon(id)
}

/*
public check_icon_loc()
{
    new value = get_pcvar_num(pcv_iloc)

    if (value == 1)
        iconstatus = get_user_msgid("StatusIcon")
    else if (value == 2)
        iconstatus = get_user_msgid("Scenario")
    else
        iconstatus = 0

    return PLUGIN_CONTINUE
}
*/
