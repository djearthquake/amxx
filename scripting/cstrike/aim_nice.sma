#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta_util
#include fakemeta

#define MAX_NAME_LENGTH 32
#define SHOT   "+attack;wait;-attack"
#define SPRAY  "+attack;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;-attack;wait"
#define BURST  "+attack;wait;wait;wait;wait;wait;wait;wait;-attack;wait"

new g_aim
new const CvarDesc[]="Auto Aim test."

public client_disconnected(id)
    remove_task(id)

public plugin_init()
{
     register_plugin( "Auto Aim", "1.1", "SPiNX" );
     register_clcmd("shoot","cmd_aim",ADMIN_KICK,"Aiming test.")
     bind_pcvar_num(create_cvar("amx_auto_aim", "0",FCVAR_SERVER, CvarDesc,.has_min = true, .min_val = 0.0, .has_max = true, .max_val = 2.0), g_aim)
}

public cmd_aim(id,level,cid)
{
    if(g_aim)
    {
        if(is_user_connected(id))
        {
            if( !cmd_access ( id, level, cid, 1 ) )
                return PLUGIN_HANDLED;
            task_exists(id) ? remove_task(id)&client_print(id,print_chat,"Aim ended...") : set_task(0.1,"@afk_aim", id, _, _, "b")&client_print(id,print_chat,"Aim begin...")
        }
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

@afk_aim(id)
{
    if(g_aim)
    if(is_user_alive(id))
    {
        static button, oldbutton;
        button = (pev(id, pev_button) & IN_ATTACK);
        oldbutton = (pev(id, pev_oldbuttons) & IN_ATTACK);
        if(button | oldbutton)
            return PLUGIN_HANDLED
        else
        {
            static iEntity,iBodyPart, iTeamA, iTeamB
            get_user_aiming(id,iEntity,iBodyPart)

            iTeamA = get_user_team(id)
            iTeamB = get_user_team(iEntity)
            static health; health = pev(iEntity,pev_health)
            if(iEntity && is_user_connected(iEntity))
            {
                if(iBodyPart && iTeamA != iTeamB)
                {
                    static Float:fRange; fRange = entity_range(id, iEntity)
                    if(fRange < 200.0)
                    {
                        switch(iBodyPart)
                        {
                            case 1..2  :  client_cmd(id, BURST)
                            case 3     :  client_cmd(id, SPRAY)
                            default    :  client_cmd(id, SHOT)
                        }
                    }
                    else
                    {
                        client_cmd(id, SHOT)
                    }
                    if(health < 20)
                    {
                        log_anal(id, iEntity, iBodyPart)
                    }
                }
            }
            else if(health)
            {
                client_print( id, print_center, "%i", health )
            }

        }

    }
    return PLUGIN_HANDLED
}

stock log_anal(id, iEntity, iBodyPart)
{
    static szPart[12]
    switch(iBodyPart)
    {
        case 0: copy(szPart,charsmax(szPart),"none")
        case 1: copy(szPart,charsmax(szPart),"head")
        case 2: copy(szPart,charsmax(szPart),"chest")
        case 3: copy(szPart,charsmax(szPart),"stomach")
        case 4: copy(szPart,charsmax(szPart),"left arm")
        case 5: copy(szPart,charsmax(szPart),"right arm")
        case 6: copy(szPart,charsmax(szPart),"left leg")
        case 7: copy(szPart,charsmax(szPart),"right leg")
        case 8: copy(szPart,charsmax(szPart),"body/shield")
    }
    return client_print( id, print_center, "%n's %s", iEntity, szPart)
}
