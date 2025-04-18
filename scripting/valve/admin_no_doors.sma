#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define ACCESS_LEVEL    "ADMIN_RESERVATION"
#define charsmin    -1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31)))

#define LOCK  256
#define UNLOCK 8
#define PROP 32

new g_Ability, g_Locked, g_Prop
new g_mod_car[MAX_PLAYERS + 1], bool:g_BotOpenDoor[MAX_PLAYERS + 1], g_AI, g_players_online;

static bool:bCS, bool:bHost, bool:bCar;
static const SzClass[][] =
{
    "momentary_door", "func_door_rotating",
    "func_door",  //if door 'skin' = ladder -> crash.
    "func_breakable", "func_pushable",
    "func_wall", "func_wall_toggle"
};

public plugin_precache()
{
    static SzModName[MAX_NAME_LENGTH]
    get_modname(SzModName, charsmax(SzModName));
    bCS = equal(SzModName, "cstrike") || equal(SzModName, "czero")  ? true : false   
}

public plugin_init()
{
    register_plugin("Command 'hide doors'", "0.0.1", "SPiNX")
    new HasEnt

    if(bCS)
    {
        bHost  = has_map_ent_class("hostage_entity") ? true : false;
        if(bHost)
            server_print "Hostage Found!"
        bCar  = has_map_ent_class("func_vehicle") ? true : false;
        if(bCar)
        {
            register_touch("player", "func_vehicle", "car_owner")
            server_print "Car Found!"
        }
    }
    
    register_forward(FM_AddToFullPack, "AddToFullPack_Post", 1)

    register_clcmd("door_access","build_power",ADMIN_KICK,"Gives/takes user ability to run through doors.")
    register_clcmd("door_lock","build_lock",ADMIN_KICK,"Gives/takes ability to use doors.")
    register_clcmd("door_prop","build_prop",ADMIN_KICK,"Gives/takes ability to prop open doors.")

    for(new list; list < sizeof SzClass; list++)
    {
        register_touch("player", SzClass[list], "touched")
        if(has_map_ent_class(SzClass[list]))
            HasEnt++
    }
    if(!HasEnt)
    {
        if(!bHost && !bCar)
        {
            pause("a")
        }
    }
}

public plugin_cfg()
{
    register_forward(FM_ShouldCollide, "FwdShouldCollide", 0)
}

public client_authorized(id, const authid[])
{
    if(is_user_connecting(id))
    {
        equal(authid, "BOT") ? SetPlayerBit(g_AI, id) : ClearPlayerBit(g_AI, id)
    }
}

public client_putinserver(id)
{
    ClearPlayerBit(g_Ability, id);
    ClearPlayerBit(g_Locked, id);
    ClearPlayerBit(g_Prop, id);
    g_players_online =get_playersnum()
}

public client_disconnected(id)
{
    ClearPlayerBit(g_Ability, id);
    ClearPlayerBit(g_Locked, id);
    ClearPlayerBit(g_Prop, id);
    g_players_online =get_playersnum()
}

public FwdShouldCollide( const iTouched, const iOther )
{
    if(g_players_online)
    {
        //Semi-Clip only after bot touches door otherwise they wallbang too easily.
        if(isDoor( iTouched ) && CheckPlayerBit(g_AI, iOther ) && g_BotOpenDoor[iOther])
        {
            forward_return( FMV_CELL, 0 );
            return FMRES_SUPERCEDE;
            
        }
        if(!bCS)return FMRES_IGNORED;
        {
            if(!bHost)return FMRES_IGNORED;
            {
                //Door Bot/Hostage Semi-clip
                if(isDoor( iTouched ) && is_hostage(iOther))
                {
                    forward_return( FMV_CELL, 0 );
                    return FMRES_SUPERCEDE;
                }
                //Bots can't shoot Hostage
                if(is_hostage(iTouched) && CheckPlayerBit(g_AI, iOther))
                {
                    forward_return( FMV_CELL, 0 );
                    return FMRES_SUPERCEDE;
                }
            }
            if(!bCar)return FMRES_IGNORED;
            {
                if(isCar(iTouched))
                {
                    //Car/Hostage Semi-clip
                    if(is_hostage(iOther))
                    {
                        forward_return( FMV_CELL, 0 );
                        return FMRES_SUPERCEDE;
                    }
                    new driver = pev(iTouched, pev_owner)-50
                    if(is_user_alive(driver) && is_user_alive(iOther))
                    {
                        //Vehicular Team Semi-clip 
                        if(get_user_team(driver) == get_user_team(iOther))
                        {
                            forward_return( FMV_CELL, 0 );
                            return FMRES_SUPERCEDE;
                        }
                    }
                }
            }
        }
    }
    return FMRES_IGNORED;
}

public touched(id, ent)
{
    if(is_user_alive(id))
    {
        if(CheckPlayerBit(g_Locked, id))
        {
            set_pev(ent, pev_spawnflags, LOCK)
        }
        else
        {
            set_pev(ent, pev_spawnflags, 0)
        }
        if(CheckPlayerBit(g_Ability, id))
        {
            set_pev(ent, pev_movetype, MOVETYPE_NONE)
            set_pev(ent, pev_solid, SOLID_NOT)
            set_pev(ent, pev_spawnflags, SF_DOOR_SILENT)
            set_task(0.3, "seal_door", ent)
        }
        //if(has_flag(id, ACCESS_LEVEL))
        if(CheckPlayerBit(g_Prop, id))
        {
            set_pev(ent, pev_spawnflags, PROP)
        }
        if(CheckPlayerBit(g_AI, id))
        {
            g_BotOpenDoor[id] = true
            set_task(1.5, "@bot_door", id)
        }
    }
}

@bot_door(iBot)
{
    g_BotOpenDoor[iBot] = false
}

public seal_door(ent)
{
    if(pev_valid(ent)>1)
    {
        set_pev(ent, pev_movetype, MOVETYPE_PUSH)
        set_pev(ent, pev_solid, SOLID_BSP)
    }
}

public build_lock(id,level,cid)
{
    if(!cmd_access ( id, level, cid, 1 ))
        return PLUGIN_HANDLED;

    static Szbuffer[MAX_NAME_LENGTH]
    read_argv(1,Szbuffer,charsmax(Szbuffer))

    new target = get_user_index(Szbuffer)

    if(is_user_connected(id))
    {
        if(equal(Szbuffer, ""))
        {
            if(CheckPlayerBit(g_Locked, id))
            {
                ClearPlayerBit(g_Locked, id)
                client_print id, print_chat, "Added door access to %n.", id
            }
            else
            {
                SetPlayerBit(g_Locked, id)
                client_print id, print_chat, "Removed door access from %n.", id
            }
        }
        else if(is_user_connected(target))
        {
            if(CheckPlayerBit(g_Locked, target))
            {
                ClearPlayerBit(g_Locked, target)
                client_print id, print_chat, "Added door access to %n.", target
            }
            else
            {
                SetPlayerBit(g_Ability, target)
                client_print id, print_chat, "Removed door access from %n.", target
            }
        }
    }
    return PLUGIN_HANDLED;
}

public build_prop(id,level,cid)
{
    if(!cmd_access ( id, level, cid, 1 ))
        return PLUGIN_HANDLED;

    static Szbuffer[MAX_NAME_LENGTH]
    read_argv(1,Szbuffer,charsmax(Szbuffer))

    new target = get_user_index(Szbuffer)

    if(is_user_connected(id))
    {
        if(equal(Szbuffer, ""))
        {
            if(CheckPlayerBit(g_Prop, id))
            {
                ClearPlayerBit(g_Ability, id)
                client_print id, print_chat, "Removed door prop from %n.", id
            }
            else
            {
                SetPlayerBit(g_Prop, id)
                client_print id, print_chat, "Added door prop to %n.", id
            }
        }
        else if(is_user_connected(target))
        {
            if(CheckPlayerBit(g_Prop, target))
            {
                ClearPlayerBit(g_Prop, target)
                client_print id, print_chat, "Removed 'door prop' tool from %n.", target
            }
            else
            {
                SetPlayerBit(g_Prop, target)
                client_print id, print_chat, "Added 'door prop' to %n.", target
            }
        }
    }
    return PLUGIN_HANDLED;
}

public build_power(id,level,cid)
{
    if(!cmd_access ( id, level, cid, 1 ))
        return PLUGIN_HANDLED;

    static Szbuffer[MAX_NAME_LENGTH]
    read_argv(1,Szbuffer,charsmax(Szbuffer))

    new target = get_user_index(Szbuffer)

    if(is_user_connected(id))
    {
        if(equal(Szbuffer, ""))
        {
            if(CheckPlayerBit(g_Ability, id))
            {
                ClearPlayerBit(g_Ability, id)
                client_print id, print_chat, "Removed door traversal from %n.", id
            }
            else
            {
                SetPlayerBit(g_Ability, id)
                client_print id, print_chat, "Added door traversal to %n.", id
            }
        }
        else if(is_user_connected(target))
        {
            if(CheckPlayerBit(g_Ability, target))
            {
                ClearPlayerBit(g_Ability, target)
                client_print id, print_chat, "Removed 'door walk-through' ability from %n.", target
            }
            else
            {
                SetPlayerBit(g_Ability, target)
                client_print id, print_chat, "Added 'door walk-through' to %n.", target
            }
        }
    }
    return PLUGIN_HANDLED;
}

public AddToFullPack_Post(es_handle,e,ent,host,hostflags,player,pSet)
{
    if(player) return FMRES_IGNORED

    if(!is_user_alive(host)) return FMRES_IGNORED

    if(!isDoor(ent)) return FMRES_IGNORED

    if(CheckPlayerBit(g_Ability, host))
        set_es(es_handle, ES_Effects, EF_NODRAW );

    return FMRES_IGNORED
}

stock bool:isDoor(ent)
{
    if(pev_valid(ent))
    {
        static szClassName[MAX_PLAYERS];
        pev(ent, pev_classname, szClassName, charsmax(szClassName));
        return contain(szClassName, "door") == charsmin ? false : true
    }
    return false;
}

stock bool:is_hostage(ent)
{
    if(pev_valid(ent))
    {
        static szClassname[MAX_NAME_LENGTH]
        entity_get_string(ent,EV_SZ_classname,szClassname,charsmax(szClassname))
        return equali(szClassname,"monster_scientist") ||
        equali(szClassname,"hostage_entity") ? true : false
    }
    return false
}

stock bool:isCar(ent)
{
    if(pev_valid(ent))
    {
        static szClassName[MAX_PLAYERS];
        pev(ent, pev_classname, szClassName, charsmax(szClassName));
        return equali(szClassName, "func_vehicle") ? true : false
    }
    return false;
}

stock bool:is_driving(iPlayer)
{
    if(is_user_connected(iPlayer))
    {
        return pev(iPlayer,pev_flags) & FL_ONTRAIN ? true : false
    }
    return false;
}

public car_owner(ptr, ptd)
{
    {
        if(is_user_alive(ptr) && pev_valid(ptd) > 1)
        {
            static iPlayer;iPlayer = ptr
            if(is_driving(iPlayer))
            {
                g_mod_car[iPlayer] = ptd
                set_pev(g_mod_car[iPlayer], pev_owner, iPlayer + 50)
            }
            else
                set_pev(g_mod_car[iPlayer], pev_owner, 0)
        }
    }
}
