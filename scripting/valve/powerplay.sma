/*
* SOMETIMES UNSTABLE BOTS AND PINGBOOST! RESEARCHING...
* Powerplay for Half-Life and Opposing Force (Gearbox)
* Copyright 2019  <SPiNX>
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
* MA 02110-1301, USA.
*
* LAST UPDATE: Sun 01 Aug 2021 08:25:06 AM CDT
*/
#include <amxmodx>
#include <amxmisc> //admin check
#include <engine> //gravity belt, tennis shoes
#include <fakemeta> //give
#include <fakemeta_util> //teleport
#include <fun> //give
#include <Gearbox>
#include <hamsandwich> //register some events

#define VER "Sun 01 Aug 2021"

#define charsmin -1
#define PITCH (random_num (40,155))
static GraphicT;


///random powerup combos (1-4 on spawn)

#define RANDOM_POWER_UP (random_num(8,699)) // 700 possible crash?
//make cvar

#define BOT_POWER_UP 8
//make cvar

#define SHIELD 8
#define BULLET 16
#define SKULL 800
#define PACK1 300 //skull/shield/pak
#define PACK2 200 //health/shield
#define PACK3 400 //ammo/health
#define PACK4 500 //all except  shield
#define PACK5 600 //bullet/shield
#define ALL   700 //1006  is all w/ grn flag

//111 skull/shield/jump green
//499 all mp shield grn flag
//900 health jump
//888 skull/shield/pak green
//666  bullet/health/shield green
//1000 health shield skull
//6000 ammo skull
// 1006 all w/ green flag

#define OTHER 450  //health/ grn flag

new iGearbox_pdata_powerup = 317
new const g_szPowerup_sounds[][] = { "ctf/pow_armor_charge.wav","ctf/pow_backpack.wav","ctf/pow_health_charge.wav","turret/tu_ping.wav"}
new g_cvar_powerplay,g_cvar_powerbots;

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

new bool:g_bHasTeleport[MAX_PLAYERS + 1];

///HP and Armor | Lifeforce
static Float:g_fChi = 165.0

///Munitions
/*
*--------------------*
This sets all weapons.
*--------------------*
*/
new iAll_Weapons = -2015363106;
new iMagazine_Capacity = 255;

///Backpack inventory
new const g_szHalfLife_Large_Cap_Magazine_Crate[][] = {"311","312","313","314","315","316","317","318","319","320","321","322"}

///Old
#define iLarge_Cap_Magazine_Drop random_num(354,371)

///Pick whatever cartridge capacity you want and recompile. Meter is stuck on 255 on some games until ammo including grenades and hive, everything gets used up.
static g_iMagazine_Capacity = 255

///Use my Pik program to soften this line of code. Charts are available. Not an include yet. New program.
new const g_szGearbox_Large_Cap_Magazine_Crate[][] = {"354","355","356","357","358","359","360","361","362","363","364","365","366","367","368","369","370", "371"}; //71 is penguin 70 is sniper
///OP4


new const szOP4Weapons_Crate[][]={

"weapon_pipewrench",
"weapon_penguin",
"weapon_knife",
"weapon_shockrifle",
"weapon_sporelauncher",
"weapon_m249",
"weapon_grapple",
"weapon_eagle",
"weapon_sniperrifle",
"weapon_displacer"
}

new const szDMCWeapons_Crate[][]={

"item_longjump",
"weapon_357",
"weapon_9mmAR",
"weapon_crossbow",
"weapon_crowbar",
"weapon_egon",
"weapon_gauss",
"weapon_handgrenade",
"weapon_hornetgun",
"weapon_rpg",
"weapon_satchel",
"weapon_shotgun",
"weapon_snark",
"weapon_tripmine",
"weapon_9mmhandgun"
}

new const szBotsWeapon_Crate[][]={

"item_longjump",
"weapon_357",
"weapon_9mmAR",
"weapon_crossbow",
"weapon_crowbar",
"weapon_egon",
"weapon_gauss",
"weapon_hornetgun",
"weapon_shotgun",
"weapon_snark",
"weapon_9mmhandgun"
}

new const szBotsOP4Weapon_Crate[][]={

"weapon_pipewrench",
"weapon_knife",
"weapon_sporelauncher",
"weapon_m249",
"weapon_grapple",
"weapon_eagle",
"weapon_sniperrifle",
"weapon_displacer"
}

new const szTeleport_Enabled_Weapons[][]={"weapon_tripmine","weapon_snark","weapon_knife","weapon_shockrifle"}

new const TELEPORT_SOUND[] = "debris/beamstart4.wav";

new SpawnID[MAX_AUTHID_LENGTH];
@freeze(){pause( "a" );return;}

public plugin_init()
{
    if ( !is_running("valve"))
    if ( !is_running("gearbox"))

        pause("a") &&
        log_amx("Powerplay is designed for Half-Life and Opposing Force.");


    ///credits and identification
    register_plugin("Powerplay", VER, "SPiNX")
    g_cvar_powerplay = register_cvar("powerplay", "0");
    g_cvar_powerbots = register_cvar("powerplaybots", "0");
    
    ///HL version intergration
    if ( is_running("valve") == 1 )
    register_message(get_user_msgid("Health"), "@Fn_Message_Health");
    
    ///Ammo and Damage Icon Trigger
    register_event("CurWeapon", "@CurentWeapon", "b", "1=1");
    
    ///Spawn with nice backpack
    RegisterHam(Ham_Spawn, "player", "client_putinpowerplay", 1);
    
    //dont litter!
    RegisterHam(Ham_Spawn, "weaponbox", "kill_weaponbox", 1)
    ///backpack
    for(new dmc;dmc < sizeof szDMCWeapons_Crate;++dmc)
    RegisterHam(Ham_Weapon_PrimaryAttack, szDMCWeapons_Crate[dmc], "@fwd_AttackSpeed" , 1)
    
    if ( is_running("gearbox") == 1 )
    
    {
        for(new op4;op4 < sizeof szOP4Weapons_Crate;++op4)
        RegisterHam(Ham_Weapon_PrimaryAttack, szOP4Weapons_Crate[op4], "@fwd_AttackSpeed" , 1)
    }
    
    register_event("Damage","@event_damage","b","2!0","3=0","4!0")
    ///Godmode and NoClip Hacks
    register_clcmd("cheat_godmodee","@godmode")
    register_clcmd("cheat_noclipp","@noclip")
    
    ///Teleport Trigger
    
    for(new iGroup = 0; iGroup < sizeof szTeleport_Enabled_Weapons; iGroup++)
    RegisterHam(Ham_Weapon_SecondaryAttack, szTeleport_Enabled_Weapons[iGroup], "@TelePort",1);
    @teleport_init_function()
    
    new mname[8];
    get_mapname(mname, charsmax(mname));
    
    ///Stopping on capture the flag
    if (containi(mname,"op4c") > -1 && get_pcvar_num(g_cvar_powerplay) < 3)
        @freeze();

}

public client_telecheck(id)
{

    if(!is_user_bot(id)
    
    && is_user_connected(id)
    && is_user_alive(id)
    && get_user_frags(id) > 8)
    
    {
        g_bHasTeleport[id] = true
        client_print(id, print_center,"Teleport powerup given!");
    }
    
    else
    
    {
        g_bHasTeleport[id] = false
        if(!is_user_bot(id))
        client_print(id, print_center,"You were not granted a teleport!");
        new X = ( 9 - get_user_frags(id) )
        if(!is_user_bot(id))
        client_print(id,print_chat,"%i more frag(s) are needed to teleport.", X);
    }

}
public client_putinserver(id)client_putinpowerplay(id)
public client_putinpowerplay(id)
{
    if(get_pcvar_num(g_cvar_powerplay) > 0 && is_plugin_loaded("testing/gives.amxx", true) != charsmin)
    pause("ac", "testing/gives.amxx");
    
    if(get_pcvar_num(g_cvar_powerbots) == 0 && is_user_bot(id))
        return PLUGIN_HANDLED_MAIN;
    
    if(get_pcvar_num(g_cvar_powerplay) > 0 )
    
    if( is_user_connected(id) && is_user_alive(id) && is_user_bot(id) && get_pcvar_num(g_cvar_powerbots) == 1 || is_user_connected(id) && is_user_alive(id) && !is_user_bot(id) )
    {
        //@Fn_Reward(id);
        set_task(0.5,"@Fn_Reward",id);
        if ( is_running("valve") == 1 )
    
        {
            for(new szAll_Arms;szAll_Arms < sizeof g_szHalfLife_Large_Cap_Magazine_Crate;++szAll_Arms)
            set_pdata_int(id,str_to_num(g_szHalfLife_Large_Cap_Magazine_Crate[szAll_Arms]),iMagazine_Capacity);
        }
    
        entity_set_float(id, EV_FL_max_health, g_fChi);
        entity_set_float(id, EV_FL_health, g_fChi);
    
        static Float:fGravity_Belt = 0.1
        static Float:fTennis_Shoes = 1000.0
    
        entity_set_float(id, EV_FL_armorvalue, g_fChi);
        if(get_pcvar_num(g_cvar_powerplay) > 3) {
        entity_set_float(id, EV_FL_gravity, fGravity_Belt);
        entity_set_float(id, EV_FL_maxspeed, fTennis_Shoes);
        }
    
        if( !is_user_bot(id) )
        {
            entity_set_int(id, EV_INT_weapons, iAll_Weapons)
    
            client_telecheck(id)
    
    
            if(is_user_admin(id))
    
            {
                @secret_doors(id);
            }
    
        }
    
    }
    return PLUGIN_CONTINUE;
}
//Admins open secret doors!


public kill_weaponbox(ent)
{
    //map must be reloaded for this to be safe
    
    if (get_pcvar_num(g_cvar_powerplay) > 3)
        set_pev(ent, pev_flags, FL_KILLME)
}

@display_info(id)

if (get_pcvar_num(g_cvar_powerplay) > 0 && !is_user_bot(id) )
    client_print(id, print_chat, "Powerplay demo active. Random Powerups are given at spawn.");


@event_damage(id)
{
new killer = get_user_attacker(id);

if( get_pcvar_num(g_cvar_powerplay) > 0)

    if( is_user_connected(killer) && is_user_alive(killer) && !is_user_bot(killer) )

    {
        client_print(killer,print_center,"HP: %i",get_user_health(id));
    }

return PLUGIN_CONTINUE;
}

@Fn_Reward(id)
{
    set_task_ex(random_float(7.0,15.0), "@display_info", id, .flags = SetTask_RepeatTimes, .repeat = 2);

    if( is_user_alive(id) )
    {
        if( is_user_bot(id) && get_pcvar_num(g_cvar_powerbots) > 1 )
    
    
            for(new goodies;goodies < sizeof szBotsWeapon_Crate;++goodies)
    
                give_item(id,szBotsWeapon_Crate[goodies]);
    
    
        if( !is_user_bot(id) && get_pcvar_num(g_cvar_powerplay) == 1 )
    
            for(new goodies1;goodies1 < sizeof szDMCWeapons_Crate;++goodies1)
    
                give_item(id,szDMCWeapons_Crate[goodies1]);
    
    
        if ( is_running("gearbox") == 1)
    
        {
            if( is_user_bot(id) && get_pcvar_num(g_cvar_powerbots) > 2 )
    
            {
    
                for(new goodies2;goodies2 < sizeof szBotsOP4Weapon_Crate;++goodies2)
    
                    give_item(id,szBotsOP4Weapon_Crate[goodies2]);
            }
    
            if ( !is_user_bot(id) && get_pcvar_num(g_cvar_powerplay) == 1 )
    
                for(new goodies3;goodies3 < sizeof szOP4Weapons_Crate;++goodies3)
    
                {
                    give_item(id,szOP4Weapons_Crate[goodies3]);
                }
    
            @SpawnGearboxPowerups(id);

        }

    }

}

@Fn_Message_Health(msgid, dest, id)
{
    if(!is_user_bot(id))
    {
        if(!is_user_alive(id))
            return PLUGIN_CONTINUE;
        static hp;

        hp = get_msg_arg_int(1);
        if(hp < g_fChi )
            set_msg_arg_int(1, ARG_BYTE, floatround(hp*1.25));
    }
    return PLUGIN_CONTINUE;
}
/*
*------------------------------------------------------------------*
name: @SpawnGearboxPowerups
@param set_pdata_int(key,value);
@returns Spawns Gearbox Powerups, alters weapon backpacks.
*------------------------------------------------------------------*
*/
@SpawnGearboxPowerups(id)
{
    if(is_user_bot(id))
    {
        switch(random_num(0,2))
        {
            case 0: set_pdata_int(id,iGearbox_pdata_powerup,PACK1);
            case 1: set_pdata_int(id,iGearbox_pdata_powerup,PACK2);
            case 2: set_pdata_int(id,iGearbox_pdata_powerup,PACK3);
        }
    }

    else

    {
        set_pdata_int(id,iGearbox_pdata_powerup,RANDOM_POWER_UP);
        server_print "Trying %i",RANDOM_POWER_UP
        @Unload_crate(id);
    }

}

@Unload_crate(id)
    for(new s;s < sizeof g_szGearbox_Large_Cap_Magazine_Crate;s++)
        set_pdata_int(id,str_to_num(g_szGearbox_Large_Cap_Magazine_Crate[s]),g_iMagazine_Capacity);

@fwd_AttackSpeed( const ent, id )
{
    if(!is_user_bot(id)){

    new Float:g_fDelay = 0.00001
    #define m_flNextPrimaryAttack 46
    #define m_flNextSecondaryAttack 47

    if (get_pcvar_num(g_cvar_powerplay) > 1 && is_valid_ent(ent) )

        {
            set_pdata_float(ent, m_flNextPrimaryAttack, g_fDelay, 4)
            set_pdata_float(ent, m_flNextSecondaryAttack, g_fDelay, 4)
        }
    }
}

@CurentWeapon(id)
{
    if(is_user_bot(id))
        return PLUGIN_HANDLED_MAIN;
    if(!is_user_bot(id))
    if ( get_pcvar_num(g_cvar_powerplay) > 0 )
    {

        new iOFFSET;
    
        if ( is_running("valve") == 1 )
        iOFFSET = -43
    
        if ( is_running("gearbox") == 1 )
        iOFFSET = 1
    
        new iModified_Grenade = (363 + iOFFSET)
        new iModified_Penguin = (370 + iOFFSET)
        new iModified_Tripmine = (361 + iOFFSET)
        new iModified_Satchel = (362 + iOFFSET)
    
        #define iAdmin_backpack 5
        #define iUsers_backpack 2
    
        #define GRENADE_FIX_ADM iModified_Grenade,iAdmin_backpack
        #define GRENADE_FIX_USR iModified_Grenade,iUsers_backpack
    
        #define PENGUIN_FIX_ADM iModified_Penguin,iAdmin_backpack
        #define PENGUIN_FIX_USR iModified_Penguin,iUsers_backpack
    
        #define MINE_FIX_ADM iModified_Tripmine,iAdmin_backpack
        #define MINE_FIX_USR iModified_Tripmine,iUsers_backpack
    
        #define SATCHEL_FIX_ADM iModified_Satchel,iAdmin_backpack
        #define SATCHEL_FIX_USR iModified_Satchel,iUsers_backpack
    
    
    
        if( is_user_admin(id) && is_user_connected(id) && is_user_alive(id) && get_user_weapon(id) == HLW_HANDGRENADE )
            set_pdata_int(id,GRENADE_FIX_ADM);
    
            else
                set_pdata_int(id,GRENADE_FIX_USR);
    
    
    
        if( is_user_admin(id) && is_user_connected(id) && is_user_alive(id) && get_user_weapon(id) == HLW_PENGUIN )
            set_pdata_int(id,PENGUIN_FIX_ADM);
    
            else
                set_pdata_int(id,PENGUIN_FIX_USR);
    
    
    
        if( is_user_admin(id) && is_user_connected(id) && is_user_alive(id) && get_user_weapon(id) == HLW_TRIPMINE )
            set_pdata_int(id,MINE_FIX_ADM);
    
            else
                set_pdata_int(id,MINE_FIX_USR);
    
    
        if( is_user_admin(id) && is_user_connected(id) && is_user_alive(id) && get_user_weapon(id) == HLW_SATCHEL )
            set_pdata_int(id,SATCHEL_FIX_ADM);
    
            else
                set_pdata_int(id,SATCHEL_FIX_USR);
    
    
    
        //pev_waterlevel 3 - head is underwater
        #define UNDERWATER 3
    
        if( is_user_connected(id) && is_user_alive(id) && get_user_weapon(id) == HLW_SPORE  && pev(id,pev_waterlevel) == UNDERWATER )
            give_item ( id , "item_airtank" )


    }

    return PLUGIN_CONTINUE;

}

public plugin_precache()

{
    ///'OP4 Capture the flag sound' effects that MUST be precached from Powerups.

    if ( is_running("gearbox") == 1 )

    {
        for(new szSounds;szSounds < sizeof g_szPowerup_sounds;++szSounds)
            precache_sound(g_szPowerup_sounds[szSounds]);
    }

    precache_sound(TELEPORT_SOUND);


    precache_sound("doors/aliendoor3.wav");
    precache_model("models/w_oxygen.mdl");


    ///teleport model
    GraphicT = precache_model("sprites/b-tele1.spr");

    ///teleport beam
    precache_model("sprites/zbeam1.spr");
}

@godmode(id)

{
if( get_pcvar_num(g_cvar_powerplay) > 0)

    if( is_user_admin(id) && !get_user_godmode(id) )

        set_user_godmode(id,true)

    else

        set_user_godmode(id,false)

return PLUGIN_HANDLED;
}

@noclip(id)

{
    if( get_pcvar_num(g_cvar_powerplay) > 0)

    if( is_user_admin(id) && !get_user_noclip(id) )


        set_user_noclip(id,true)

    else

        set_user_noclip(id,false)


    return PLUGIN_HANDLED;
}

@secret_doors(id)
{
    if( get_pcvar_num(g_cvar_powerplay) > 0)
    {
        new eEnt = engfunc(EngFunc_FindEntityByString, eEnt, "targetname", "secret_door")
        const SPAWNFLAGS = 768
        if(is_valid_ent(eEnt))
        {
            set_pev(eEnt, pev_spawnflags, SPAWNFLAGS);
            set_pev(eEnt, pev_rendermode, kRenderTransColor);
            set_pev(eEnt, pev_rendercolor, Float:{0.0, 255.0, 0.0});
            set_pev(eEnt, pev_renderamt, 150.0);
            set_pev(eEnt, pev_rendermode, kRenderGlow);

            entity_set_string(eEnt,EV_SZ_classname,"func_breakable")
            entity_set_float(eEnt, EV_FL_takedamage, 2.0);
            entity_set_float(eEnt, EV_FL_health, 50.0);
        }

    }
    return PLUGIN_HANDLED;
}

@teleport_init_function()
{
    static ent, i
    while((ent = engfunc(EngFunc_FindEntityByString,ent,"classname","info_player_deathmatch")))
    {
        SpawnID[i++] = ent
        if(i == sizeof SpawnID)
        break
    }
}

@TelePort(id)
{
    static spawnId, Float:origin[3], Float:angles[3], player, ent;

    player = pev(id, pev_owner);
    if(get_pcvar_num(g_cvar_powerplay) > 2 && g_bHasTeleport[player])
    {
        ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"));

        set_pev(ent, pev_rendermode, kRenderTransAdd);
        engfunc(EngFunc_SetModel, ent, "sprites/zbeam1.spr");

        set_pev(ent, pev_renderamt, 255.0);
        set_pev(ent, pev_animtime, 1.0);
        set_pev(ent, pev_framerate, 50.0);
        set_pev(ent, pev_frame, 10);

        pev(player, pev_origin, origin);

        set_pev(ent,  pev_origin, origin);
        dllfunc(DLLFunc_Spawn, ent);

        set_pev(ent, pev_solid, SOLID_NOT);

        #define TO_ALL_PLAYERS           0
        #define IF_IS_IN_EYESIGHT     MSG_PVS
        #define MAKE_ENT_APPEAR       SVC_TEMPENTITY

        emessage_begin(IF_IS_IN_EYESIGHT,MAKE_ENT_APPEAR, {0,0,0}, TO_ALL_PLAYERS);
        ewrite_byte(TE_DLIGHT);
        ewrite_coord(floatround(origin[0]));
        ewrite_coord(floatround(origin[1]));
        ewrite_coord(floatround(origin[2]));
        ewrite_byte(35);
        ewrite_byte(80);
        ewrite_byte(255);
        ewrite_byte(100);
        ewrite_byte(80);
        ewrite_byte(60);
        emessage_end();

        spawnId = SpawnID[random_num(0,strlen(SpawnID) - 1)]

        pev(spawnId, pev_origin, origin);
        pev(spawnId, pev_angles, angles);

        set_pev(player, pev_origin, origin);
        set_pev(player, pev_angles, angles);
        set_pev(player, pev_fixangle, 1);
        set_pev(player, pev_velocity, {0.0, 0.0, 0.0});

        emessage_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, player);
        ewrite_short(1<<10);
        ewrite_short(1<<3);
        ewrite_short(0);
        ewrite_byte(100);
        ewrite_byte(255);
        ewrite_byte(100);
        ewrite_byte(150);
        emessage_end();

        set_task(0.5, "@remove_telesprite_task", ent + 33453);
        switch(random(1))
        {
            case 0:emit_sound(id, CHAN_AUTO, TELEPORT_SOUND, 0.8, ATTN_NORM, 0, PITCH);
            case 1:emit_sound(id, CHAN_AUTO, TELEPORT_SOUND, 0.8, ATTN_NORM, SND_STOP, PITCH);
        }
        //@react_function(id,origin); //if land same place crash!
    }

}

@remove_telesprite_task(ent){
ent -= 33453
if(pev_valid(ent))
engfunc(EngFunc_RemoveEntity, ent);
return PLUGIN_HANDLED;
}

//Factor Chi off ping.
@Armour_Set(id)
{
    if(is_user_bot(id))return;
    new ping, loss;
    get_user_ping(id,ping,loss)
    fm_set_user_armor(id, get_user_health(id)+ping)
    if( (is_user_connected(id)) && (is_user_admin(id)) )
    {
        fm_set_user_health(id, get_user_health(id)+ping);
        if ( get_user_health(id) > 200)
            fm_set_user_health(id,power(ping,1)+75);

    }
}


@react_function(id, Float:origin[3])
{
    if(get_pcvar_num(g_cvar_powerplay) == 3)
    {
    static tr;
    new Float:End[3];
    engfunc(EngFunc_TraceLine,id,IGNORE_MONSTERS,tr);
    get_tr2(tr,TR_vecEndPos,End)
    ///if (origin[0] == End[0] || origin[1] == End[1] || origin[2] == End[2])return; //essential!!
    ///
    /////////////////////////////////////////////////////////////////////////////////
    new Start,Rate,Life,Width,Noise,Red,Grn,Blu,Bright,Scroll;
    /////////////////////////////////////////////////////////////////////////////////
    Start = 1;
    Rate = 5;
    Life = random_num(5,20);
    Width = random_num(1,50);
    Noise = random_num(0,50);
    Red = random_num(0,255);
    Grn = random_num(0,255);
    Blu = random_num(0,255);
    Bright = random_num(500,1000);
    Scroll = 1;

    if(is_user_connected(id))

        {
            emessage_begin(id ? MSG_PVS : MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0)
            ewrite_byte(TE_BEAMPOINTS);
            ewrite_coord_f(origin[0]);
            ewrite_coord_f(origin[1]);
            ewrite_coord_f(origin[2]);
            ewrite_coord_f(End[0]);
            ewrite_coord_f(End[1]);
            ewrite_coord_f(End[2]);
            ewrite_short(GraphicT);
            ewrite_byte(Start);
            ewrite_byte(Rate);
            ewrite_byte(Life);
            ewrite_byte(Width);
            ewrite_byte(Noise);
            ewrite_byte(Red);
            ewrite_byte(Grn);
            ewrite_byte(Blu);
            ewrite_byte(Bright);
            ewrite_byte(Scroll);
            emessage_end();

            free_tr2(tr);
        }
    }
}
