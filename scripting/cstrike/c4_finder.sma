#include amxmodx
#include amxmisc
#include engine
#include fakemeta
#include fakemeta_util

#if !defined set_ent_rendering
#define set_ent_rendering set_rendering
#endif

new g_IS_PLANTING

public plugin_init()
{
    register_plugin ( "C4 Finder", "0.1", "spinx" )
    register_logevent("@bomb_dropped", 3, "2=Dropped_The_Bomb");
    register_event("BarTime", "@PLANTING", "be", "1=3")
    register_event("HLTV", "@event_new_round", "a", "1=0", "2=0");
}

@c4_model()
{
    new iC4 = fm_find_ent_by_model(MaxClients, "weaponbox", "models/w_backpack.mdl")
    if(iC4)
    {
        set_task(0.3, "@render", iC4,_,_,"b")
    }
}

@render(index)
{
    pev_valid(index) ? set_ent_rendering(index, kRenderFxGlowShell, COLOR(), COLOR(), COLOR(), kRenderTransColor, random_num(15,100)) : remove_task(index)
}

public bomb_planted(){set_task 1.0, "@check_doubles";}


@check_doubles(id)
{
    new iCheck = find_ent(MaxClients, "weapon_c4")
    if(iCheck)
    {
        new iOwner = pev(iCheck, pev_owner)
        if(iOwner != g_IS_PLANTING)
        if(is_user_connected(iOwner))
        {
            log_amx("%N had an extra C4!", iOwner)
            if(pev_valid(iCheck))
            {
                engclient_cmd(iOwner, "drop", "weapon_c4")
            }
            for(new id = 1; id <= MaxClients; id++)
            {
                if(is_user_admin(id))
                {
                    client_print(id, print_chat, "%N had an extra C4!", iOwner)
                }
            }
        }
    }
}

@PLANTING( id )
{
    g_IS_PLANTING = id
    if(is_user_alive(id))
    {
        for (new iCrew = 1; iCrew <= MaxClients; iCrew++)
        {
            if(is_user_connected(iCrew))
            {
                if(get_user_team(iCrew) ==1)
                client_print iCrew, print_chat ,"%n is planting!", g_IS_PLANTING
            }
        }
    }
}
@bomb_dropped()
{
    new id = get_loguser_index();

    if(is_user_connected(id))
    {
        server_print("%N dropped C4...", id)
    }
    if(!is_user_alive(id))
    {
        new iC4 = find_ent(MaxClients, "weapon_c4")
        if(iC4)
        {
            server_print("We found the dropped C4!")

            if(pev_valid(iC4))
            {
                set_task(0.4, "@c4_model", iC4)
            }
        }
    }
}

stock get_loguser_index()
{
    static loguser[80], name[MAX_NAME_LENGTH];
    read_logargv(0, loguser, charsmax(loguser));
    parse_loguser(loguser, name, charsmax(loguser));

    return get_user_index(name);
}

@event_new_round(){g_IS_PLANTING = 0;}

stock COLOR()
{
    return random(256)
}
