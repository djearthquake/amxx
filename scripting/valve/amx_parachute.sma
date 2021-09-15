

/*******************************************************************************
  Parachute

  Version: 1.6
  Author: SPiNX/KRoTaL/JTP10181
  0.1    Release
  0.1.1  Players can't buy a parachute if they already own one
  0.1.2  Release for AMX MOD X
  0.1.3  Minor changes
  0.1.4  Players lose their parachute if they die
  0.1.5  Added amx_parachute cvar
  0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
  0.1.7  Added amx_parachute <name> | admins with admin level a get a free parachute
  0.1.8  JTP - Cleaned up code, fixed runtime error
  1.0    JTP - Should be final version, made it work on basically any mod
  1.1    JTP - Added Changes from AMX Version 0.1.8
            Added say give_parachute and parachute_fallspeed cvar
            Plays the release animation when you touch the ground
            Added chat responder for automatic help
    1.2 JTP - Added cvar to disable the detach animation
            Redid animation code to improve organization
            Force "walk" animation on players when falling
            Change users gravity when falling to avoid choppiness
    1.3     JTP - Upgraded to pCVARs
    1.4     SPiNX 10/22/19 17:59 - Revised prethink per 'Invalid entity' run-time error.
            SPiNX Sun Oct 27 10:24:39 CDT 2019 - Finished testing new install without model install. No crash!
    1.5     SPiNX Sun 17 May 2020 01:21:55 PM CDT - Auto-parachute! Deployment has a depth CVAR.
    1.6     SPiNX Sun 17 May 2020 11:41:39 PM CDT - Parachute can be blown up and user freefalls.
    1.7     SPiNX over last few months. Added 3 chutes. Bot or admin or not. Fixed stabily on mods outside of cstrike when chute is shot down.

  Commands:

    say buy_parachute   -   buys a parachute (CStrike ONLY)
    saw sell_parachute  -   sells your parachute (75% of the purchase price)
    say give_parachute <nick, #userid or @team>  -  gives your parachute to the player

    amx_parachute <nick, #userid or @team>  -  gives a player a free parachute (CStrike ONLY)
    amx_parachute @all  -  gives everyone a free parachute (CStrike ONLY)

    Press +use to slow down your fall.

  Cvars:

    sv_parachute        "1"         - 0: disables the plugin - 1: enables the plugin

    parachute_cost      "1000"      - cost of the parachute (CStrike ONLY)

    parachute_payback   "75"        - how many percent of the parachute cost you get when you sell your parachute
                                      (ie. (75/100) * 1000 = 750$)

    parachute_fallspeed "100"       - speed of the fall when you use the parachute

    parachute_autoadmin "2"         - Admins can automatically deploy chute or allow everybody. 0|off   1|admin     2|all.

    parachute_autorip   "200"       - Depth sensor for automatic deployment of parachute. 1-450+. Depends on map.

  Setup (AMXX 1.x):

    Install the amxx file.
    Put the parachute.mdl file in the modname/models/ folder
    Set to free for POD bots to automatically deploy.
    Other bots may not work. Open to Amxx methods to interface such instances.

*******************************************************************************/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <fun>

new bool:has_parachute[ MAX_PLAYERS +1 ]
new para_ent[ MAX_PLAYERS +1 ]
new gCStrike = 0
new pDetach, pFallSpeed, pEnabled, pCost, pPayback, pAutoDeploy /*MAY2020*/,pAutoRules /*MAY2020*/;

new const LOST_CHUTE_SOUND[] = "misc/erriewind.wav"
new const PARA_MODELO[] = "models/parachute.mdl"
new const PARA_MODELW[] = "models/Parachute_wings.mdl"
new const PARA_MODEL[] = "models/parachute2.mdl"
//new const PARA_MODELV[] = "models/parachute_new.mdl" //future

new g_model, Float:g_fbox, g_packHP;
#define PITCH (random_num (90,111))
#define PARACHUTE_LEVEL ADMIN_LEVEL_A
#define g_fbox 35.0 //chute pack size. Can make into cvar.
#define g_packHP 35

public plugin_init()
{
    register_plugin("Parachute", "1.7", "SPiNX/KRoT@L/JTP")
    pEnabled    = register_cvar("sv_parachute", "1" )
    pFallSpeed  = register_cvar("parachute_fallspeed", "100")
    pDetach     = register_cvar("parachute_detach", "1")
    pAutoDeploy = register_cvar("parachute_autorip", "200")
    pAutoRules  = register_cvar("parachute_autoadmin", "2") //0|off 1|admin 2|all
    if (cstrike_running()) gCStrike = true

    if (gCStrike) {

        pCost = register_cvar("parachute_cost", "1000")
        pPayback = register_cvar("parachute_payback", "75")

        register_concmd("amx_parachute", "admin_give_parachute", PARACHUTE_LEVEL, "<nick, #userid or @team>" )
    }

    register_clcmd("say", "HandleSay")
    register_clcmd("say_team", "HandleSay")

    register_event("ResetHUD", "newSpawn", "be")
    register_event("DeathMsg", "death_event", "a")
    register_forward(FM_PlayerPreThink, "client_prethink")

    //Setup jtp10181 CVAR
    new cvarString[MAX_USER_INFO_LENGTH], shortName[MAX_IP_LENGTH]
    copy(shortName,charsmax(shortName),"chute")

    register_cvar("jtp10181","",FCVAR_SERVER|FCVAR_SPONLY)
    get_cvar_string("jtp10181",cvarString,charsmax(cvarString))

    if (strlen(cvarString) == 0) {
        formatex(cvarString,charsmax(cvarString),shortName)
        set_cvar_string("jtp10181",cvarString)
    }
    else if (contain(cvarString,shortName) == -1) {
        format(cvarString,charsmax(cvarString),"%s,%s",cvarString, shortName)
        set_cvar_string("jtp10181",cvarString)
    }
}

public plugin_natives()
{
    set_module_filter("module_filter")
    set_native_filter("native_filter")
}

public module_filter(const module[])
{
    if (!cstrike_running() && equali(module, "cstrike")) {
        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
    if (!trap) return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public plugin_precache()
{
    precache_sound(LOST_CHUTE_SOUND);
    precache_generic("sound/debris/bustglass1.wav");
    precache_model("models/glassgibs.mdl");
    precache_generic("sound/debris/bustglass2.wav");

    if (file_exists(PARA_MODEL))
        precache_model(PARA_MODEL);

    else

        {
            log_amx("Your parachute model, ^"%s^", is not correct!", PARA_MODEL);
            pause "a";
        }

    if (file_exists(PARA_MODELO))
        precache_model(PARA_MODELO);

    else

        {
            log_amx("Your parachute model, ^"%s^", is not correct!", PARA_MODELO);
            pause "a";
        }

    if (file_exists(PARA_MODELW))
        g_model = precache_model(PARA_MODELW);

    else

        {
            log_amx("Your parachute model, ^"%s^", is not correct!", PARA_MODELW);
            pause "a";
        }
}

public client_connect(id)
{
    parachute_reset(id)
}

    #if AMXX_VERSION_NUM == 182;

public client_disconnect(id)

    #else

public client_disconnected(id)

    #endif
{
    parachute_reset(id)
}

public death_event()
{
    new id = read_data(2)
    parachute_reset(id)
}

parachute_reset(id)
{
    if(para_ent[id] > 0) {
        if (is_valid_ent(para_ent[id])) {
            remove_entity(para_ent[id])
        }
    }

    if (is_user_connected(id))

        {
            set_user_gravity(id, 1.0)
            if(task_exists(id))remove_task(id);
            has_parachute[id] = false
            para_ent[id] = 0
        }
}

public newSpawn(id)
{
    if( (para_ent[id] > 0) && is_valid_ent(para_ent[id]) ) {
        remove_entity(para_ent[id])
        set_user_gravity(id, 1.0)
        para_ent[id] = 0
    }

    if (!gCStrike || access(id,PARACHUTE_LEVEL) || get_pcvar_num(pCost) <= 0) {
        has_parachute[id] = true
        //set_view(id, CAMERA_3RDPERSON)
    }
}

public HandleSay(id)
{
    if(!is_user_connected(id)) return PLUGIN_CONTINUE

    new args[ MAX_RESOURCE_PATH_LENGTH + MAX_RESOURCE_PATH_LENGTH ]
    read_args(args, charsmax(args))
    remove_quotes(args)

    if (gCStrike) {
        if (equali(args, "buy_parachute")) {
            buy_parachute(id)
            return PLUGIN_HANDLED
        }
        else if (equali(args, "sell_parachute")) {
            sell_parachute(id)
            return PLUGIN_HANDLED
        }
        else if (containi(args, "give_parachute") == 0) {
            give_parachute(id,args[15])
            return PLUGIN_HANDLED
        }
    }

    if (containi(args, "parachute") != -1) {
        if (gCStrike) client_print(id, print_chat, "[AMXX] Parachute commands: buy_parachute, sell_parachute, give_parachute")
        client_print(id, print_chat, "[AMXX] To use your parachute press and hold your +use button while falling")
    }

    return PLUGIN_CONTINUE
}

public buy_parachute(id)
{
    if (!gCStrike) return PLUGIN_CONTINUE
    if (!is_user_connected(id)) return PLUGIN_CONTINUE

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    if (has_parachute[id]) {
        client_print(id, print_chat, "[AMXX] You already have a parachute")
        return PLUGIN_HANDLED
    }

    new money = cs_get_user_money(id)
    new cost = get_pcvar_num(pCost)

    if (money < cost) {
        client_print(id, print_chat, "[AMXX] You don't have enough moneyfor a parachute - Costs $%i", cost)
        return PLUGIN_HANDLED
    }

    cs_set_user_money(id, money - cost)
    client_print(id, print_chat, "[AMXX] You have bought a parachute. To use it, press +use while falling.")
    has_parachute[id] = true

    return PLUGIN_HANDLED
}

public sell_parachute(id)
{
    if (!gCStrike) return PLUGIN_CONTINUE
    if (!is_user_connected(id)) return PLUGIN_CONTINUE

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    if (!has_parachute[id]) {
        client_print(id, print_chat, "[AMXX] You don't have a parachute to sell")
        return PLUGIN_HANDLED
    }

    if (access(id,PARACHUTE_LEVEL)) {
        client_print(id, print_chat, "[AMXX] You cannot sell your free admin parachute")
        return PLUGIN_HANDLED
    }

    parachute_reset(id)

    new money = cs_get_user_money(id)
    new cost = get_pcvar_num(pCost)

    new sellamt = floatround(cost * (get_pcvar_num(pPayback) / 100.0))
    cs_set_user_money(id, money + sellamt)

    client_print(id, print_chat, "[AMX] You have sold your used parachute for $%d", sellamt)

    return PLUGIN_CONTINUE
}

public give_parachute(id,args[])
{
    if (!gCStrike) return PLUGIN_CONTINUE
    if (!is_user_connected(id)) return PLUGIN_CONTINUE

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    if (!has_parachute[id]) {
        client_print(id, print_chat, "[AMXX] You don't have a parachute to give")
        return PLUGIN_HANDLED
    }

    new player = cmd_target(id, args, 4)
    if (!player) return PLUGIN_HANDLED

    new id_name[MAX_NAME_LENGTH], pl_name[MAX_NAME_LENGTH]
    get_user_name(id, id_name, charsmax(id_name))
    get_user_name(player, pl_name, charsmax(pl_name))

    if(has_parachute[player]) {
        client_print(id, print_chat, "[AMXX] %s already has a parachute.", pl_name)
        return PLUGIN_HANDLED
    }

    parachute_reset(id)
    has_parachute[player] = true

    client_print(id, print_chat, "[AMXX] You have given your parachute to %s.", pl_name)
    client_print(player, print_chat, "[AMXX] %s has given thier parachute to you.", id_name)

    return PLUGIN_HANDLED
}

public admin_give_parachute(id, level, cid) {

    if (!gCStrike) return PLUGIN_CONTINUE

    if(!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

    if (!get_pcvar_num(pEnabled)) {
        client_print(id, print_chat, "[AMXX] Parachute plugin is disabled")
        return PLUGIN_HANDLED
    }

    new arg[MAX_PLAYERS], name[MAX_NAME_LENGTH], name2[MAX_NAME_LENGTH], authid[MAX_AUTHID_LENGTH], authid2[MAX_AUTHID_LENGTH]
    read_argv(1,arg,charsmax(arg))
    get_user_name(id,name,charsmax(name))
    get_user_authid(id,authid, charsmax(authid))

    if (arg[0]=='@'){
        new players[32], inum
        if (equali("T",arg[1]))     copy(arg[1],31,"TERRORIST")
        if (equali("ALL",arg[1]))   get_players(players,inum)
        else                        get_players(players,inum,"e",arg[1])

        if (inum == 0) {
            console_print(id,"No clients in such team")
            return PLUGIN_HANDLED
        }

        for(new a = 0; a < inum; a++) {
            has_parachute[players[a]] = true
        }

        switch(get_cvar_num("amx_show_activity"))   {
            case 2: client_print(0,print_chat,"ADMIN %s: gave a parachute to ^"%s^" players",name,arg[1])
            case 1: client_print(0,print_chat,"ADMIN: gave a parachute to ^"%s^" players",arg[1])
        }

        console_print(id,"[AMXX] You gave a parachute to ^"%s^" players",arg[1])
        log_amx("^"%s<%d><%s><>^" gave a parachute to ^"%s^"", name,get_user_userid(id),authid,arg[1])
    }
    else {

        new player = cmd_target(id,arg,6)
        if (!player) return PLUGIN_HANDLED

        has_parachute[player] = true

        get_user_name(player,name2,charsmax(name2))
        get_user_authid(player,authid2,charsmax(authid2))

        switch(get_cvar_num("amx_show_activity")) {
            case 2: client_print(0,print_chat,"ADMIN %s: gave a parachute to ^"%s^"",name,name2)
            case 1: client_print(0,print_chat,"ADMIN: gave a parachute to ^"%s^"",name2)
        }

        console_print(id,"[AMXX] You gave a parachute to ^"%s^"", name2)
        log_amx("^"%s<%d><%s><>^" gave a parachute to ^"%s<%d><%s><>^"", name,get_user_userid(id),authid,name2,get_user_userid(player),authid2)
    }
    return PLUGIN_HANDLED
}

public client_prethink(id)
{
    /*
     * parachute.mdl animation information
     * 0 - deploy - 84 frames
     * 1 - idle - 39 frames
     * 2 - detach - 29 frames
     */

    new Rip_Cord = get_pcvar_num(pAutoDeploy);
    new AUTO;

    if (get_pcvar_num(pAutoRules) == 1 && is_user_admin(id) || get_pcvar_num(pAutoRules) == 2){
    AUTO = (pev(id,pev_flFallVelocity) >= (get_pcvar_num(pFallSpeed) + Rip_Cord) );}

    if (pev(id,pev_flFallVelocity) < (get_pcvar_num(pFallSpeed)) ) //Destroyed chute whirlwind sound stop
    emit_sound(id, CHAN_AUTO, LOST_CHUTE_SOUND, VOL_NORM, ATTN_NORM, SND_STOP, PITCH);

    if (!get_pcvar_num(pEnabled)) return

    //if (!is_user_alive(id) || !is_user_connected(id)/*fix jkbotti*/|| !has_parachute[id]) return //possible postthink

    if (is_user_alive(id) && has_parachute[id])

    {


    new Float:frame

    new button = get_user_button(id)
    new oldbutton = get_user_oldbutton(id)

    new flags = get_entity_flags(id)
    new Float:fallspeed = get_pcvar_float(pFallSpeed) * -1.0

    if( (is_valid_ent(para_ent[id])) && (para_ent[id] > 0 && (flags & FL_ONGROUND)) ){

        if (get_pcvar_num(pDetach)) {
            if (is_user_alive(id))
            if (get_user_gravity(id) == 0.1)
            set_user_gravity(id, 1.0)
            if( (is_valid_ent(para_ent[id]))(entity_get_int(para_ent[id],EV_INT_sequence) != 2) ) {
                if(is_valid_ent(para_ent[id]))entity_set_int(para_ent[id], EV_INT_sequence, 2)
                if(is_valid_ent(para_ent[id]))entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
                if(is_valid_ent(para_ent[id]))entity_set_float(para_ent[id], EV_FL_frame, 0.0)
                if(is_valid_ent(para_ent[id]))entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
                if(is_valid_ent(para_ent[id]))entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
                if(is_valid_ent(para_ent[id]))entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
                return
            }

            frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
            entity_set_float(para_ent[id],EV_FL_fuser1,frame)
            entity_set_float(para_ent[id],EV_FL_frame,frame)

            if (frame > 254.0) {
                remove_entity(para_ent[id])
                para_ent[id] = 0
                set_user_rendering(id, kRenderFxGlowShell,0,0,0,kRenderNormal,25);
                if(task_exists(id))remove_task(id);
            }
        }
        else {
            remove_entity(para_ent[id])
            set_user_gravity(id, 1.0)
            para_ent[id] = 0
        }

        return
        }


    if(button & IN_USE|AUTO) {
        new Float:velocity[3]
        entity_get_vector(id, EV_VEC_velocity, velocity)

        if (velocity[2] < 0.0) {

            if(para_ent[id] <= 0) {

                new Float:minbox[3] = { -g_fbox, -g_fbox, -g_fbox }
                new Float:maxbox[3] = { g_fbox, g_fbox, g_fbox }
                new Float:angles[3] = { 0.0, 0.0, 0.0 }

                if ( cstrike_running() ||  is_running("dod") == 1 ) //update mod list at your own risk. DoD should be fine.

                para_ent[id] = create_entity("func_breakable") //take off clipper list!!!

                else
                para_ent[id] = create_entity("info_target")

                if(para_ent[id] > 0)

                {
                    entity_set_string(para_ent[id],EV_SZ_targetname,"parachute")
                    entity_set_edict(para_ent[id], EV_ENT_aiment, id)
                    entity_set_edict(para_ent[id], EV_ENT_owner, id)
                    entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)

                    if( is_user_bot(id) )
                        entity_set_model(para_ent[id], PARA_MODELW);

                    if( is_user_admin(id) )
                        entity_set_model(para_ent[id], PARA_MODEL);

                    if( !is_user_bot(id) && !is_user_admin(id) )

                        {
                            entity_set_model(para_ent[id], PARA_MODELO);
                            //set_task(0.1, "colorize", id, "", 0, "b");
                        }

                    entity_set_size(para_ent[id], minbox, maxbox )
                    set_pev(para_ent[id],pev_angles,angles)
                    set_pev(para_ent[id],pev_solid,SOLID_BBOX)

                    if ( is_running("gearbox") == 1 )
                        set_pev(para_ent[id],pev_takedamage, DAMAGE_NO) //unstable could cause crash

                    if(cstrike_running() && is_user_alive(id) )
                        set_pev(para_ent[id],pev_takedamage, DAMAGE_YES)  //DAMAGE_AIM

                    //Give the parachute health so we can destory it later in a fight.
                    entity_set_float(para_ent[id], EV_FL_health, g_packHP*1.0) //Cvar later?

                    entity_set_int(para_ent[id], EV_INT_sequence, 0)
                    entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
                    entity_set_float(para_ent[id], EV_FL_frame, 0.0)
                    entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
                }
            }
            if (is_valid_ent(para_ent[id]))
            if(para_ent[id] > 0) {
                entity_set_int(id, EV_INT_sequence, 3)
                entity_set_int(id, EV_INT_gaitsequence, 1)
                entity_set_float(id, EV_FL_frame, 1.0)
                entity_set_float(id, EV_FL_framerate, 1.0)
                set_user_gravity(id, 0.1)



                if ( is_valid_ent(para_ent[id]) && (pev(para_ent[id],pev_health)) < 5.0 )
                {
                    emit_sound(id, CHAN_AUTO, LOST_CHUTE_SOUND, VOL_NORM, ATTN_IDLE, 0, PITCH);
                    //Let player know they shot the chute not the player.
                    chute_pop(id);
                    server_print("Parachute destroyed!");
                    parachute_reset(id);
                    return;

                }

                velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
                entity_set_vector(id, EV_VEC_velocity, velocity)

                if( (is_valid_ent(para_ent[id])) && (entity_get_int(para_ent[id],EV_INT_sequence) == 0) ){

                    frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
                    entity_set_float(para_ent[id],EV_FL_fuser1,frame)
                    entity_set_float(para_ent[id],EV_FL_frame,frame)

                    if (frame > 100.0) {
                        entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
                        entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
                        entity_set_int(para_ent[id], EV_INT_sequence, 1)
                        entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
                        entity_set_float(para_ent[id], EV_FL_frame, 0.0)
                        entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
                    }
                }
            }
        }
        else if (para_ent[id] > 0 ) {
            remove_entity(para_ent[id])
            set_user_gravity(id, 1.0)
            para_ent[id] = 0
        }
    }
    else if ((oldbutton & IN_USE) && para_ent[id] > 0 ) {
        remove_entity(para_ent[id])
        set_user_gravity(id, 1.0)
        para_ent[id] = 0
    }

    }


}

public colorize(id)
{
    if(is_user_connected(id))
        set_user_rendering(id,kRenderFxGlowShell,random_num(0,255),random_num(0,255),random_num(0,255),kRenderNormal,25);
}

public chute_pop(id)
{

    if(is_user_connected(id) && !is_user_bot(id) && cstrike_running())

    {
        server_print("chute pop effect start");
        #define TE_EXPLODEMODEL 107
        new Origin[3];

        pev(id, pev_origin, Origin)

        emessage_begin(MSG_BROADCAST,23);

        ewrite_byte(TE_EXPLODEMODEL);
        ewrite_coord(floatround(Origin[0]+random_float(-11.0,11.0)));
        ewrite_coord(floatround(Origin[1]-random_float(-11.0,11.0)));
        ewrite_coord(floatround(Origin[2]+random_float(1.0,75.0)));
        ewrite_coord(random_num(-150,1000)); 
        ewrite_short(g_model);
        ewrite_short(1);
        ewrite_byte(random_num(20,100));

        emessage_end();

        server_print("chute pop effect ended");
    }
    else
        server_print("Stopped possible chute bug...");
}
