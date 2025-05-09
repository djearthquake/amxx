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

#define PLUGIN  "Command 'hide doors'"
#define VERSION "1.0.1"
#define AUTHOR  "SPiNX"

new g_Ability, g_Locked, g_Prop, g_pack, g_AI;

static const SzClass[][] =
{
    "momentary_door", "func_door_rotating",
    "func_door",  //if door 'skin' = ladder -> crash.
    "func_breakable", "func_pushable",
    "func_wall", "func_wall_toggle"
};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_clcmd("door_access","build_power",ADMIN_KICK,"Gives/takes user ability to run through doors.")
    register_clcmd("door_lock","build_lock",ADMIN_KICK,"Gives/takes ability to use doors.")
    register_clcmd("door_prop","build_prop",ADMIN_KICK,"Gives/takes ability to prop open doors.")

    g_pack = register_forward(FM_AddToFullPack, "AddToFullPack_Post", 1)
}

public plugin_cfg()
{
    static HasEnt; HasEnt = 0;
    for(new list; list < sizeof SzClass; list++)
    {
        register_touch("player", SzClass[list], "touched")
        if(has_map_ent_class(SzClass[list]))
        {
            server_print("%s|%s by %s FOUND %s", PLUGIN, VERSION, AUTHOR, SzClass[list])
            HasEnt++
        }
    }
    if(!HasEnt)
    {
        pause("a")
    }
}

public plugin_end()
{
    unregister_forward(FM_AddToFullPack, g_pack, 1)
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
}

public client_disconnected(id)
{
    ClearPlayerBit(g_Ability, id);
    ClearPlayerBit(g_Locked, id);
    ClearPlayerBit(g_Prop, id);
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
                SetPlayerBit(g_Locked, target)
                client_print id, print_chat, "Removed door access from %n.", target
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

public touched(id, ent)
{
    if(id<=MaxClients)
    {
        if(CheckPlayerBit(g_Ability, id))
        {
            set_pev(ent, pev_movetype, MOVETYPE_NONE)
            set_pev(ent, pev_solid, SOLID_NOT)
            set_pev(ent, pev_spawnflags, SF_DOOR_SILENT)
            set_task(0.3, "seal_door", ent)
        }
        if(CheckPlayerBit(g_Prop, id))
        {
            set_pev(ent, pev_spawnflags, PROP)
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public pfn_touch(touched, toucher)
{
    if(isDoor(touched))
    {
        if(CheckPlayerBit(g_Locked, toucher))
            return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
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
    if(ent>MaxClients && pev_valid(ent))
    {
        static szClassName[MAX_PLAYERS];
        pev(ent, pev_classname, szClassName, charsmax(szClassName));
        return contain(szClassName, "door") == charsmin ? false : true
    }
    return false;
}
