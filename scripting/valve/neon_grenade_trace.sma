/*
*
*   SSSSSSSSSSSSSSS PPPPPPPPPPPPPPPPP     iiii  NNNNNNNN        NNNNNNNNXXXXXXX       XXXXXXX
* SS:::::::::::::::SP::::::::::::::::P   i::::i N:::::::N       N::::::NX:::::X       X:::::X
*S:::::SSSSSS::::::SP::::::PPPPPP:::::P   iiii  N::::::::N      N::::::NX:::::X       X:::::X
*S:::::S     SSSSSSSPP:::::P     P:::::P        N:::::::::N     N::::::NX::::::X     X::::::X
*S:::::S              P::::P     P:::::Piiiiiii N::::::::::N    N::::::NXXX:::::X   X:::::XXX
*S:::::S              P::::P     P:::::Pi:::::i N:::::::::::N   N::::::N   X:::::X X:::::X
* S::::SSSS           P::::PPPPPP:::::P  i::::i N:::::::N::::N  N::::::N    X:::::X:::::X
*  SS::::::SSSSS      P:::::::::::::PP   i::::i N::::::N N::::N N::::::N     X:::::::::X
*    SSS::::::::SS    P::::PPPPPPPPP     i::::i N::::::N  N::::N:::::::N     X:::::::::X
*       SSSSSS::::S   P::::P             i::::i N::::::N   N:::::::::::N    X:::::X:::::X
*            S:::::S  P::::P             i::::i N::::::N    N::::::::::N   X:::::X X:::::X
*            S:::::S  P::::P             i::::i N::::::N     N:::::::::NXXX:::::X   X:::::XXX
*SSSSSSS     S:::::SPP::::::PP          i::::::iN::::::N      N::::::::NX::::::X     X::::::X
*S::::::SSSSSS:::::SP::::::::P          i::::::iN::::::N       N:::::::NX:::::X       X:::::X
*S:::::::::::::::SS P::::::::P          i::::::iN::::::N        N::::::NX:::::X       X:::::X
* SSSSSSSSSSSSSSS   PPPPPPPPPP          iiiiiiiiNNNNNNNN         NNNNNNNXXXXXXX       XXXXXXX
*
*──────────────────────────────▄▄
*──────────────────────▄▄▄▄▄▄▄▄▌▐▄
*─────────────────────█▄▄▄▄▄▄▄▄▌▐▄█
*────────────────────█▄▄▄▄▄▄▄█▌▌▐█▄█
*──────▄█▀▄─────────█▄▄▄▄▄▄▄▌░▀░░▀░▌
*────▄██▀▀▀▀▄──────▐▄▄▄▄▄▄▄▐ ▌█▐░▌█▐▌
*──▄███▀▀▀▀▀▀▀▄────▐▄▄▄▄▄▄▄▌░░░▄▄▌░▐
*▄████▀▀▀▀▀▀▀▀▀▀▄──▐▄▄▄▄▄▄▄▌░░▄▄▄▄░▐
*████▀▀▀▀▀▀▀▀▀▀▀▀▀▄▐▄▄▄▄▄▄▌░▄░░▀▀░░▌
*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▌░▐▀▄▄▄▄▀
*▒▒▒▒▄▄▀▀▀▀▀▀▀▀▄▄▄▄▀▀█▄▄▄▄▄▌░░░░░▌
*▒▄▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌
*▒▌░░░░░▀▄░░░░░░░░░░░░░░░▀▄▄▄▄▄▄░▀▄▄▄▄▄
*▒▌░░░░░░░▀▄░░░░░░░░░░░░░░░░░░░░▀▀▀▀▄░▀▀▀▄
*▒▌░░░░░░░▄▀▀▄░░░░░░░░░░░░░░░▀▄░▄░▄░▄▌░▄░▄▌
*▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
*
*
*
*
*
* __..__  .  .\  /
*(__ [__)*|\ | >< Last edit date Mon Feb 20th, 2023.
*.__)|   || \|/  \
*    Radioactive Half-Life grenade trails.
*
*    Copyleft (C) 2018-2023 .sρiηX҉.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
#include <amxmodx>
 #include <amxmisc>
  #include <engine>
  #include <fakemeta>
   #include <fakemeta_util>
   #include <fun>
   #define MAX_NAME_LENGTH 32
   #define MAX_PLAYERS 32
   #define COLOR random(256)
   #define PITCH (random_num (10,250))
    #define SLOW change_task(g_model,random_float(1.5,2.0),0)

    #define DELAY ewrite_short(get_pcvar_num(g_cvar_bsod_iDelay)*4096) //Remember 4096 is ~1-sec per 'spec unit'

    #define FLAGS ewrite_short(0x0001)

    #define ALPHA ewrite_byte(500)


    //Screenfade color.

    #define BLU ewrite_byte(0);ewrite_byte(0);ewrite_byte(random_num(200,255))

    #define GRN ewrite_byte(0);ewrite_byte(random_num(200,255));ewrite_byte(0)

    #define PNK ewrite_byte(255);ewrite_byte(random_num(170,200));ewrite_byte(203)

    #define PUR ewrite_byte(118);ewrite_byte(random_num(25,75));ewrite_byte(137)

    #define get_user_model(%1,%2,%3) engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, %1 ), "model", %2, %3 )

    #pragma dynamic 32768

    #define charsmin                  -1

    #if !defined set_ent_rendering
    #define set_ent_rendering set_rendering
    #endif

    new g_teams, g_shake_msg;

    new const SOUND_HAWK[] = "sound/ambience/hawk1.wav";
    new const SOUND_SHIT[] = "sound/fvox/fuzz.wav";
    new const SOUND_MAN[]  = "sound/scientist/scream19.wav";

    new const SOUND_HAWK1[] = "ambience/hawk1.wav";
    new const SOUND_SHIT1[] = "fvox/fuzz.wav";
    new const SOUND_MAN1[]  = "scientist/scream19.wav";

    new Float:Axis[3];
    new g_model,sprite,g_ring;
    new g_cvar_neon_all,g_cvar_neon_hull,g_cvar_neon_toss,g_cvar_neon_rad,g_cvar_neon_wid;
    new gibs_models0, gibs_models1, gibs_models2;
    new g_energy0,g_energy1,g_energy2;

    new g_pickable, g_debug, g_cvar_neon_snd, g_proximity;
    new g_pickerton[MAX_PLAYERS];
    new g_cvar_bsod_iDelay;
    new g_iLoss,g_iPing;
    new g_hornet_think, g_bolt_think, g_rpg_think, g_mortar_think, g_tank_think, g_rocket_think;
    new bool: bRADead[MAX_PLAYERS + 1];
    new bool: bStrike;

public plugin_end()
{
    unregister_think(g_bolt_think);
    unregister_think(g_hornet_think);
    unregister_think(g_mortar_think);
    unregister_think(g_rocket_think);
    unregister_think(g_rpg_think);
    unregister_think(g_tank_think);
}
public plugin_init()
{
    register_event("CurWeapon", "CurentWeapon", "bce", "1=1");
    register_plugin("Neon Grenade Trace","A","SPiNX");
    bStrike = cstrike_running() == 1 ? true : false
    g_pickable = register_cvar("neon_pick", "func_button")

    get_pcvar_string(g_pickable, g_pickerton, charsmax(g_pickerton));

    //CUSTOM CVAR PICK

    ///register_touch(g_pickerton,"func_illusionary","Other_Attack_Touch");

    g_debug = register_cvar("neon_debug", "0")

    register_touch("grenade","","HandGrenade_Attack2_Touch") //engine method
    g_cvar_neon_all    = register_cvar("sv_neon_all",  "1");
    g_cvar_neon_hull   = register_cvar("sv_neon_hull", "1");
    g_cvar_neon_toss   = register_cvar("sv_neon_toss", "1");
    g_cvar_neon_rad    = register_cvar("sv_neon_rad",  "1");
    g_cvar_neon_snd    = register_cvar("sv_neon_snd",  "0");
    g_cvar_neon_wid    = register_cvar("sv_neon_wid",  "3"); //max width
    g_proximity             = register_cvar("sv_neon_range",  "500"); //max range
    g_teams            = !cstrike_running() ? get_cvar_pointer("mp_teamplay") : get_cvar_pointer("mp_friendlyfire")
    clamp(g_cvar_neon_wid,1,150);
    g_shake_msg = get_user_msgid("ScreenShake")
    g_cvar_bsod_iDelay = register_cvar("neon_flashbang_time", "2");


    //GRENADES

    register_think("grenade","@tracer");
    register_think("ARgrenade","@tracer");

    //HORNET
    if(get_pcvar_num(g_cvar_neon_all) > 4 || get_pcvar_num(g_cvar_neon_all) == -4)
    {
        register_touch("hornet", "*", "Other_Attack_Touch");
    }

    //BOW
    if(get_pcvar_num(g_cvar_neon_all) > 6 || get_pcvar_num(g_cvar_neon_all) == -6)
    {
        g_bolt_think = register_think("bolt","@tracer");

        register_touch("bolt", "*", "HandGrenade_Attack2_Touch");
    }

    if(get_pcvar_num(g_cvar_neon_all) > 9 )
    {
        //RPG

        g_rpg_think = register_think("rpg_rocket","@tracer");

        register_touch("rpg_rocket", "*", "HandGrenade_Attack2_Touch");


        //MORTAR

        g_mortar_think = register_think("mortar_shell", "@tracer");

        register_touch("mortar_shell", "*", "HandGrenade_Attack2_Touch");

        //TANK

        g_tank_think = register_think("func_tank", "@tracer");
        register_touch("func_tank", "*", "HandGrenade_Attack2_Touch");

        //MISSILES

        g_rocket_think = register_think("func_rocket", "@tracer");
        register_touch("func_rocket", "*", "HandGrenade_Attack2_Touch");
    }

    if(cstrike_running() )
        register_logevent("plugin_save", 3, "2=Planted_The_Bomb")
}

public plugin_precache()
{
    sprite       = precache_model("sprites/smoke.spr");
    precache_generic("sprites/smoke.spr");
    g_energy0    = precache_model("models/bleachbones.mdl");precache_generic("models/bleachbones.mdl");
    g_energy1    = precache_model("models/bskull_template1.mdl");precache_generic("models/bskull_template1.mdl");
    g_energy2    = precache_model("models/sphere.mdl");precache_generic("models/sphere.mdl");

    g_ring       = precache_model("sprites/ballsmoke.spr");precache_generic("sprites/ballsmoke.spr");
    gibs_models0 = precache_model("models/cindergibs.mdl");precache_generic("models/cindergibs.mdl")
    gibs_models1 = precache_model("models/chromegibs.mdl");precache_generic("models/chromegibs.mdl")
    //also needed for breakable randomly using them
    gibs_models2 = precache_model("models/glassgibs.mdl");precache_generic("models/glassgibs.mdl");
    precache_sound(SOUND_HAWK1);
    precache_sound(SOUND_MAN1);
    precache_sound(SOUND_SHIT1);
    precache_generic(SOUND_HAWK);
    precache_generic(SOUND_MAN);
    precache_generic(SOUND_SHIT);
}

public hull_glow(model)
{
    if(get_pcvar_num(g_cvar_neon_hull) !=1 && pev_valid(model) > 1)
    {
        switch(random_num(0,1))
        {
            case 0: set_ent_rendering(model, kRenderFxExplode, COLOR, COLOR, COLOR, kRenderGlow, power(model,1000));
            case 1: set_ent_rendering(model, kRenderFxGlowShell, COLOR, COLOR, COLOR, kRenderNormal, random_num(80,200));
        }
    }
    return PLUGIN_CONTINUE;
}

@tracer(s)
{
    if(pev_valid(s) && get_pcvar_num(g_cvar_neon_hull) == 1){

      switch(random_num(0,1))
       {
        case 0: set_ent_rendering(s, kRenderFxExplode, COLOR, COLOR, COLOR, kRenderGlow, power(s,1000));
        case 1: set_ent_rendering(s, kRenderFxGlowShell, COLOR, COLOR, COLOR, kRenderNormal, random_num(80,200));
       }

    }
    if(get_pcvar_num(g_cvar_neon_toss) == 1)
        Trail_me(s)
}

public CurentWeapon(id)
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        new temp_ent1, temp_ent2, temp_ent3, temp_ent4, temp_ent5, temp_ent6, temp_ent7, temp_ent8;
        //Standard
        temp_ent1 = find_ent(charsmin,"grenade");
        temp_ent2 = find_ent(charsmin,"ARgrenade");

        //Make hivehand into vorpal weapon.
        if(get_pcvar_num(g_cvar_neon_all) > 4 || get_pcvar_num(g_cvar_neon_all) == -4)
            temp_ent3 = find_ent(charsmin,"hornet");
        //Magic Missile variant.
        if(get_pcvar_num(g_cvar_neon_all) > 6 || get_pcvar_num(g_cvar_neon_all) == -6)
            temp_ent4 =  find_ent(charsmin,"bolt");
        //Baby nuke tipped RPG and alike.
        if(get_pcvar_num(g_cvar_neon_all) > 9)
        {
            temp_ent5 = find_ent(charsmin,"rpg_rocket");
            temp_ent6 = find_ent(charsmin,"mortar_shell");
            temp_ent7 = find_ent(charsmin,"func_tank");
            temp_ent8 = find_ent(charsmin,"func_rocket"); //spinx_missile fork of lud's
        }

        if(pev_valid(temp_ent1) )
            g_model = temp_ent1;

        if(pev_valid(temp_ent2) )
            g_model = temp_ent2;

        if(pev_valid(temp_ent3) )
            g_model = temp_ent3;

        if(pev_valid(temp_ent4) )
            g_model = temp_ent4;

        if(pev_valid(temp_ent5) )
            g_model = temp_ent5;

        if(pev_valid(temp_ent6) )
            g_model = temp_ent6;

        if(pev_valid(temp_ent7) )
            g_model = temp_ent7;

        if(pev_valid(temp_ent8) )
            g_model = temp_ent8;

        new s = g_model
        @tracer(s)
    }

}

public Trail_me(g_model)
{
    if(get_pcvar_num(g_cvar_neon_toss) !=1)return;
    new lums = random_num(100,2000);new time = random_num(18,40);new width = random_num(1,get_pcvar_num(g_cvar_neon_wid));
    emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
    ewrite_byte(TE_BEAMFOLLOW);
    ewrite_short(g_model);ewrite_short(sprite);
    ewrite_byte(time);ewrite_byte(width);
    ewrite_byte(COLOR);ewrite_byte(COLOR);ewrite_byte(COLOR);
    ewrite_byte(lums);emessage_end();
}

public plugin_save(g_model)
{
    if(task_exists(g_model))
        SLOW &&
        remove_task(g_model);

    if(task_exists(g_model))
        switch(0,1)
        {
          case 0: return PLUGIN_HANDLED_MAIN;
          case 1: plugin_save(g_model);
        }
    return PLUGIN_CONTINUE;
}

public glow(g_model)
{
    if(pev_valid(g_model)>1)
    {
        set_ent_rendering(g_model, kRenderFxGlowShell, COLOR, COLOR, COLOR, kRenderNormal, random_num(5,250));
    }
}

public HandGrenade_Attack2_Touch(ent, id)
{
    new nade_owner;
    nade_owner = pev(ent,pev_owner);
    if(get_pcvar_num(g_cvar_neon_rad) == 1)
    {
        ///Sound FX //make a cvar lags might be reason for overflows!
        if(get_pcvar_num(g_cvar_neon_snd))
        switch(random_num(0,3))
        {
            case 0:emit_sound(ent, CHAN_AUTO, SOUND_SHIT1, VOL_NORM, ATTN_NORM, 0, PITCH);
            case 1:emit_sound(ent, CHAN_AUTO, SOUND_HAWK1, VOL_NORM, ATTN_NORM, 0, PITCH);
            case 2:emit_sound(ent, CHAN_AUTO, SOUND_SHIT1, VOL_NORM, ATTN_NORM, SND_STOP, PITCH);
            case 3:emit_sound(ent, CHAN_AUTO, SOUND_HAWK1, VOL_NORM, ATTN_NORM, SND_STOP, PITCH);
        }

        new Float:End_Position[3];
        g_model = ent
        if(pev_valid(g_model))
        {
            entity_get_vector(g_model,EV_VEC_origin,End_Position);
            entity_get_vector(g_model,EV_VEC_angles,Axis);

            ///explode models on explode or touch.
            emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0); //players_who_see_effects() )
            ewrite_byte(TE_EXPLODEMODEL)
            ewrite_coord(floatround(End_Position[0]+random_float(-11.0,11.0)))      // XYZ (start)
            ewrite_coord(floatround(End_Position[1]-random_float(-11.0,11.0)))
            ewrite_coord(floatround(End_Position[2]+random_float(1.0,75.0)))
            ewrite_coord(random_num(-350,400))       // velocity
            switch(random_num(0,2))
            {
                case 0: ewrite_short(gibs_models0);
                case 1: ewrite_short(gibs_models1);
                case 2: ewrite_short(gibs_models2);
            }
            ewrite_short(random_num(5,15))               //(count)
            ewrite_byte(random_num(8,20))              //(life in 0.1's)
            emessage_end()

            emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0); //players_who_see_effects() );
            ewrite_byte(random_num(19,21));
            ewrite_coord(floatround(End_Position[0]));
            ewrite_coord(floatround(End_Position[1]));
            ewrite_coord(floatround(End_Position[2]));
            ewrite_coord(floatround(Axis[0]));
            ewrite_coord(floatround(Axis[1]));
            ewrite_coord(floatround(Axis[2]));
            ewrite_short(g_ring);
            ewrite_byte(100); //fr
            ewrite_byte(255); // fr rate
            ewrite_byte(random_num(8,15));  //life
            ewrite_byte(random_num(8,80));  //width
            ewrite_byte(random_num(0,50));   //amp
            ewrite_byte(random_num(30,255));  //r
            ewrite_byte(random_num(0,200));  //g
            ewrite_byte(random_num(40,190)); //b
            ewrite_byte(random_num(100,500)); //bright
            ewrite_byte(0);
            emessage_end();

            ///Actual damage
            new location[3]
            new Float:Vec[3]
            IVecFVec(location, Vec)
            FVecIVec(Vec, location)
            location[2] = location[2] + 20

            new players[ MAX_PLAYERS ]
            new playercount

            get_players(players,playercount,"h")
            for (new m=0; m<playercount; ++m)
            {
                new hp = get_user_health(players[m])
                new playerlocation[3]
                if(is_user_alive(players[m]))
                if(is_user_bot(players[m]) ||  !is_user_bot(players[m]) && m != nade_owner)
                {

                    get_user_origin(players[m], playerlocation)
                    new resultdance = get_entity_distance(g_model, players[m]);

                    if (resultdance < get_pcvar_num(g_proximity))
                    {

                        emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0); //players_who_see_effects() ) // 0 0 255 going for blue background to make better use of my sprites in amxx//Use 17 with a task!
                        ewrite_byte( TE_PLAYERSPRITES)
                        ewrite_short(players[m])//ewrite_short(m)  //(playernum)
                        switch(random_num(0,2))
                        {
                            case 0: ewrite_short(g_energy0);
                            case 1: ewrite_short(g_energy1);
                            case 2: ewrite_short(g_energy2);
                        }
                        ewrite_byte(5)     //(count)
                        ewrite_byte(75) // (variance) (0 = no variance in size) (10 = 10% variance in size)
                        emessage_end()


                        emessage_begin(MSG_ONE_UNRELIABLE,g_shake_msg,{0,0,0},players[m]);
                        ewrite_short(25000); //amp
                        ewrite_short(8000); //dur //4096 is~1sec
                        ewrite_short(30000); //freq
                        emessage_end();

                        if(hp >= 30.0)
                        {
                            fakedamage(players[m],"Grenade Radiation",15.0,DMG_RADIATION)


                            emessage_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),{0,0,0},players[m]);
                            DELAY;DELAY;FLAGS;PUR;ALPHA; //This is where one can change BLU to GRN.
                            emessage_end();

                            if(get_pcvar_num(g_debug) > 0)
                            {
                                #if AMXX_VERSION_NUM == 182
                                new throwers_name[ MAX_NAME_LENGTH ], victims_name[ MAX_NAME_LENGTH ];
                                get_user_name(nade_owner, throwers_name, charsmax(throwers_name) );
                                get_user_name(players[m], victims_name, charsmax(victims_name) );
                                client_print( 0, print_center,"%s blinded %s!", throwers_name, victims_name );
                                #endif


                                #if AMXX_VERSION_NUM != 182
                                    client_print( 0, print_center,"%n blinded %n!", nade_owner, players[m] );
                                #endif
                            }

                        }

                        else

                        if(hp < 30.0)
                        {


                            #if AMXX_VERSION_NUM == 182
                            new throwers_name[ MAX_NAME_LENGTH ], victims_name[ MAX_NAME_LENGTH ];
                            get_user_name(nade_owner, throwers_name, charsmax(throwers_name) );
                            get_user_name(players[m], victims_name, charsmax(victims_name) );
                            client_print( 0, print_chat,"%s melted %s!", throwers_name, victims_name );
                            #endif


                            #if AMXX_VERSION_NUM != 182
                            if( is_user_connected(nade_owner))
                            {
                                client_print( 0, print_chat,"%n melted %n!", nade_owner, players[m] );
                            }
                            #endif

                            if(cstrike_running())
                                set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);
                            if(!cstrike_running())
                            set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE);

                            fakedamage(players[m],"Grenade Radiation",300.0,DMG_RADIATION|DMG_NEVERGIB)

                            new Float:fExpOrigin[3];
                            fExpOrigin = End_Position;
                            new killer = entity_get_edict(ent,EV_ENT_owner);

                            log_kill(killer,players[m],"Grenade Radiation",1);
                        }
                    }
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}

public Other_Attack_Touch(ent, id)
{
    new Float:Axis[3], Float:End_Position[3];
    if(is_user_connected(id) && is_user_alive(id) && pev_valid(ent))
    {

        if(get_pcvar_num(g_cvar_neon_all))
        {

            ///Sound FX
            if(get_pcvar_num(g_cvar_neon_snd))
            {
                switch(random_num(0,5))
                {
                    case 0:emit_sound(ent, CHAN_AUTO, SOUND_SHIT1, VOL_NORM, ATTN_NORM, 0,PITCH);
                    case 1:emit_sound(ent, CHAN_AUTO, SOUND_HAWK1, VOL_NORM, ATTN_NORM, 0, PITCH);
                    case 2:emit_sound(ent, CHAN_AUTO, SOUND_SHIT1, VOL_NORM, ATTN_NORM, SND_STOP, PITCH);
                    case 3:emit_sound(ent, CHAN_AUTO, SOUND_MAN1,  VOL_NORM, ATTN_NORM, 0,PITCH);
                    case 4:emit_sound(ent, CHAN_AUTO, SOUND_HAWK1, VOL_NORM, ATTN_NORM, SND_STOP, PITCH);
                    case 5:emit_sound(ent, CHAN_AUTO, SOUND_MAN1,  VOL_NORM, ATTN_NORM, SND_STOP, PITCH);
                }
            }
            g_model = ent;

            entity_get_vector(g_model,EV_VEC_origin,End_Position);
            entity_get_vector(g_model,EV_VEC_angles,Axis);

            emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0}, 0); //players_who_see_effects() );
            ewrite_byte(random_num(19,21));
            ewrite_coord(floatround(End_Position[0]));
            ewrite_coord(floatround(End_Position[1]));
            ewrite_coord(floatround(End_Position[2]));
            ewrite_coord(floatround(Axis[0]));
            ewrite_coord(floatround(Axis[1]));
            ewrite_coord(floatround(Axis[2]));
            ewrite_short(g_ring);
            ewrite_byte(100); //fr
            ewrite_byte(255); // fr rate
            ewrite_byte(random_num(1,3));  //life
            ewrite_byte(random_num(8,80));  //width
            ewrite_byte(random_num(0,50));   //amp
            ewrite_byte(random_num(30,255));  //r
            ewrite_byte(random_num(0,200));  //g
            ewrite_byte(random_num(40,190)); //b
            ewrite_byte(random_num(100,500)); //bright
            ewrite_byte(0);
            emessage_end();

            ///Actual damage
            new location[3];
            new Float:Vec[3];
            IVecFVec(location, Vec)
            FVecIVec(Vec, location)
            location[2] = location[2] + 20

            new players[MAX_PLAYERS];
            new playercount, resultdance;

            get_players(players,playercount,"h")
            for (new m=0; m<playercount; ++m)
            {
                new playerlocation[3];
                if(is_user_connected(players[m]) && is_user_alive(players[m]))
                {
                    get_user_origin(players[m], playerlocation);
                    resultdance = get_entity_distance(g_model, players[m]);

                    if(resultdance < get_pcvar_num(g_proximity))
                    {
                        new hp = get_user_health(players[m])
                        if(hp > 15.0)
                        {
                            fakedamage(players[m],"Sonic Radiation",1.0,DMG_SONIC);
                            {
                                emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0); //players_who_see_effects() )
                                ewrite_byte( TE_PLAYERSPRITES);
                                ewrite_short(players[m])  //(playernum)
                                switch(random_num(0,2))
                                {
                                    case 0: ewrite_short(g_energy0);
                                    case 1: ewrite_short(g_energy1);
                                    case 2: ewrite_short(g_energy2);
                                }
                                ewrite_byte(random_num(1,5));     //(count)
                                ewrite_byte(random_num(5,15)); // (variance) (0 = no variance in size) (10 = 10% variance in size)
                                emessage_end();
                            }
                        }
                        else
                        {
                            set_msg_block(get_user_msgid("DeathMsg"), bStrike ? BLOCK_SET : BLOCK_ONCE);
                            entity_explosion_knockback(players[m], End_Position);
                            fakedamage(players[m],"Sonic Radiation",300.0,DMG_SONIC);

                            new killer = entity_get_edict(ent,EV_ENT_owner);

                            log_kill(killer,players[m],"Sonic Radiation",1);
                        }
                    }
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}

stock Fn_etwork(id) {get_user_ping(id, g_iPing, g_iLoss);return g_iLoss,g_iPing;}

stock log_kill(killer, victim, weapon[], headshot)
{

    if (containi(weapon,"Radiation") > -1)
        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);

    new killers_team[MAX_PLAYERS], victims_team[MAX_PLAYERS];
    get_user_team(killer, killers_team, charsmax(killers_team));
    get_user_team(victim, victims_team, charsmax(victims_team));

    if(is_user_connected(killer))
    {
       //Scoring
        if(get_pcvar_num(g_teams) == 1 || cstrike_running() )
        {

            if(!equal(killers_team,victims_team))
            {
                set_user_frags(killer,get_user_frags(killer) +1)
            }
            else //if(equal(killers_team,victims_team))
            {
                set_user_frags(killer,get_user_frags(killer) -1);
            }
        }

        else

        fm_set_user_frags(killer,get_user_frags(killer) +1);
        ///////////////////////////////////////////////////

        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);

        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT);


        emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0}, 0);
        ewrite_byte(killer);
        ewrite_byte(victim);

        if(cstrike_running())
            ewrite_byte(headshot);
        if( (get_pcvar_num(g_teams) == 1 || cstrike_running())
        &&
        equal(killers_team,victims_team))
            ewrite_string("teammate");
        else
            ewrite_string(weapon)
        emessage_end();

        //Logging the message as seen on console.
        new kname[MAX_PLAYERS+1], vname[MAX_PLAYERS+1], kauthid[MAX_PLAYERS+1], vauthid[MAX_PLAYERS+1], kteam[10], vteam[10]

        get_user_name(killer, kname, charsmax(kname))
        get_user_team(killer, kteam, charsmax(kteam))
        get_user_authid(killer, kauthid, charsmax(kauthid))

        get_user_name(victim, vname, charsmax(vname))
        get_user_team(victim, vteam, charsmax(vteam))
        get_user_authid(victim, vauthid, charsmax(vauthid))

        log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
        kname, get_user_userid(killer), kauthid, kteam,
        vname, get_user_userid(victim), vauthid, vteam, weapon)
        pin_scoreboard(killer);
    }

}

public pin_scoreboard(killer)
{
    if(is_user_connected(killer))
    {
        emessage_begin(MSG_BROADCAST,get_user_msgid("ScoreInfo"))
        ewrite_byte(killer);
        ewrite_short(get_user_frags(killer));
        //ewrite_short(get_user_deaths(killer));
        #define DEATHS 422
        new dead = get_pdata_int(killer, DEATHS)
        ewrite_short(dead);

        if(cstrike_running())
        {
            ewrite_short(0); //TFC CLASS
            ewrite_short(get_user_team(killer));
        }
        emessage_end();
    }

}

@spawn(id)
{
    bRADead[id] = false
}

stock players_who_see_effects()
{
    //CPU client safeguard attempt.
    new players[MAX_PLAYERS], playercount, SEE;
    get_players(players,playercount,"ch");

    for (SEE=0; SEE<playercount; SEE++)
        return SEE;

    return PLUGIN_CONTINUE;
}


#include <xs>
public entity_explosion_knockback(victim, Float:fExpOrigin[3])
{
    if(is_user_connected(victim))
    {
        new Float:fExpShockwaveRadius=300.0, Float:fExpShockwavePower=75.0;
        new Float:fOrigin[3], Float:fDistVec[3];
        pev(victim, pev_origin, fOrigin);

        xs_vec_sub(fOrigin, fExpOrigin, fDistVec);
        new Float:g_fTemp;

        if((g_fTemp=xs_vec_len(fDistVec)) <= fExpShockwaveRadius)
        {
            new Float:fPower = fExpShockwavePower * ( 1.0 - ( g_fTemp / floatmin(fExpShockwaveRadius, 1.0) ) ), Float:fVelo[3], Float:fKnockBackVelo[3];
            pev(victim, pev_velocity, fVelo);
            xs_vec_normalize(fDistVec, fKnockBackVelo);
            xs_vec_mul_scalar(fKnockBackVelo, fPower, fKnockBackVelo);
            xs_vec_add(fVelo, fKnockBackVelo, fVelo);
            if(fVelo[0] != 0.0 && fVelo[1] != 0.0 && fVelo[2] != 0.0)
            {
                set_pev(victim, pev_velocity, fVelo);
                server_print "%n | %f %f %f | neon_push", victim, fVelo[0], fVelo[1], fVelo[2]
            }
        }
    }
    return PLUGIN_HANDLED
}
