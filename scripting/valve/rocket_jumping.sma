#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define MAX_PLAYERS                 32
#define MAX_RESOURCE_PATH_LENGTH    64
#define MSG_TYPE MSG_BROADCAST

#define ADMIN_CHECK ADMIN_KICK

new SpawnID[MAX_RESOURCE_PATH_LENGTH],
g_HasJump[MAX_PLAYERS + 1],
p_Enable,
p_Force,
g_Wow,
g_Blu,
g_recoil,
g_fun,
g_fire,
g_Pow,
maxplayers,
Float:plAngles[3],
Graphic;

new const TELEPORT_SOUND[] = "debris/beamstart4.wav";
new const VEST_SOUND[] = "player/pcv_vest.wav"

#define FLOAT_UFO 20.0
#define FLOAT_ANGLE -20.0
#define FLOAT_DELAY 0.3
#define PITCH (random_num (40,155))

new bool: rpg[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin("Rocket Jumping and nuke", "1.0", "SPiNX") //Basic jump from Drak

    RegisterHam(Ham_Spawn, "player", "Spawn", 1);
    RegisterHam(Ham_TakeDamage, "player", "Damage");

    register_concmd("amx_give_rocketjump","CmdGive",ADMIN_BAN,"<target> <1/0> Enables/Disables rocket jump for the specfic player");
    maxplayers = get_maxplayers()
    teleport_init_function()
}

public plugin_precache()
{
    // 1 = All Players
    // 0 = Players can use Rocket Jump only if an admin gave them the power
    p_Enable = register_cvar("amx_rocket_jump","1");
    p_Force = register_cvar("amx_rocket_force","5000");
    g_recoil = precache_model("sprites/zerogxplode.spr");
    g_Wow = precache_model("sprites/smoke.spr");
    g_Blu = precache_model("sprites/animglow01blue.spr");
    g_fun = precache_model("sprites/rain.spr");
    g_fire = precache_model("sprites/fire.spr");
    g_Pow = precache_model("models/shrapnel.mdl");
    precache_sound("ambience/alienflyby2.wav");
    precache_sound("weapons/mortarhit.wav");
    precache_sound("ctf/pow_big_jump.wav");
    precache_sound("player/pcv_vest.wav");
    precache_sound("fvox/automedic_on.wav");
    precache_sound("fvox/radiation_detected.wav");
    precache_sound("doors/aliendoor3.wav");///aqua lung
    precache_model("models/w_oxygen.mdl"); ///aqua lung will crash without
    precache_model("models/w_antidote.mdl");

    precache_sound(VEST_SOUND);
    precache_sound(TELEPORT_SOUND);

    precache_model("sprites/b-tele1.spr"); ///teleport model

    Graphic = precache_model("sprites/zbeam1.spr");
    register_forward(FM_PlayerPreThink,"forward_PreThink", true);
}

public teleport_init_function()
{
    static ent, i
    while((ent = engfunc(EngFunc_FindEntityByString,ent,"classname","info_player_deathmatch")))
    {
        SpawnID[i++] = ent
        if(i == sizeof SpawnID)
        break
    }
}

public Spawn(id)
{
    if(is_user_alive(id))
    {
        rpg[id] = false;
    }
}

public forward_PreThink(id)
{
    if(is_user_connecting(id) || !is_user_connected(id))
        return FMRES_HANDLED
    if(g_HasJump[id] == 1 || get_pcvar_num(p_Enable) == 1)
    {
        new clip,ammo
        if(get_user_weapon(id,clip,ammo) == HLW_RPG)
        {
            if(pev(id,pev_button) & IN_ATTACK && !(pev(id,pev_oldbuttons) & IN_ATTACK))
            {
                if(clip != 0)
                {
                    pev(id,pev_angles,plAngles);
                    if(plAngles[0] <= FLOAT_ANGLE)
                    {
                        set_user_godmode(id,1);
                        set_task(FLOAT_DELAY,"RocketJump",id);
                    }
                }
            }
        }
    }
    return FMRES_HANDLED
}

public RocketJump(id)
{
    if(is_user_connected(id) && is_user_alive(id))
    {
        new Float:vecForce[3];
        pev(id,pev_velocity,vecForce);

        vecForce[2] += get_pcvar_num(p_Force);

        set_pev(id,pev_velocity,vecForce);
        set_user_godmode(id,0);

        give_item ( id , "item_antidote" )
        give_item ( id , "ammo_rpgclip" )

        new Float:Origin[3]
        pev(id,pev_origin,Origin)
        Origin[2] += 10

        new origin2[3]
        for(new i=0;i<3;i++) origin2[i] = floatround(Origin[i]);

        if ( get_user_health(id) < 25.0 )Nuke(id);
        if ( get_user_health(id) < 75.0 )Regular(id);

        if ( get_user_health(id) < 18.0 )
        {
            set_pev(id, pev_health, pev(id,pev_health) + random_float(10.0, 20.0));
            set_pev(id, pev_armorvalue, pev(id,pev_armorvalue) +random_float(10.0, 20.0))
        }

        if ( get_user_health(id) > 101.0 )
        {
            set_user_health(id, 100)
            overhear(1000, origin2, "player/pcv_vest.wav");
        }
        if ( get_user_health(id) < 80.0 )
        {
            give_item(id, "item_longjump")
        }

    }
    fm_set_user_godmode(id,0);
}

public philiadelphia(id)
{
    if(is_user_connected(id))
    {
        new coord[3];
        new Eye = 1;
        get_user_origin(id,coord,Eye);
    
        //Philadephia exp effects
        emessage_begin( MSG_ALL, SVC_TEMPENTITY,{0,0,0}, 0 );
        ewrite_byte(TE_FIREFIELD);
    
        ewrite_coord(coord[0]);
        ewrite_coord(coord[1]);
        ewrite_coord(coord[2] + random_num(-50, 100));
    
        ewrite_short(1)/*radius*/;
    
        ewrite_short(id)
    
        ewrite_byte(1)/*count*/;
        ewrite_byte(2)/*flags*/;
        ewrite_byte(random_num(10,20))/*duration*/;
        emessage_end();
    }
}

public Nuke(id)
{
    if(is_user_connected(id))
    {
        rocketsound();

        new Float:Vector[3];
        pev(id,pev_origin,Vector);
        #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters
        new Float:Wector[3];

        pev(id, pev_origin, Wector)
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_LIGHTNING)
        ewrite_coord_f(Wector[0])       // start position
        ewrite_coord_f(Wector[1])
        ewrite_coord_f(Wector[2]-10)
        ewrite_coord_f(Wector[0]+random_num(300,700))    // end position
        ewrite_coord_f(Wector[1]+random_num(750,2000))
        ewrite_coord_f(Wector[2]+random_num(2500,9000))
        ewrite_byte(random_num(15,50))        // life in 0.1's
        ewrite_byte(random_num(5,10000))        // width in 0.1's
        ewrite_byte(random_num(100,1000)) // amplitude in 0.01's
        ewrite_short(g_fire)     // sprite model index
        emessage_end()


        //mapsize smoke ring cloud
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_BEAMCYLINDER);
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 16);
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 200);
        ewrite_short(g_recoil);
        ewrite_byte(2); //start frame
        ewrite_byte(11); //frame rate
        ewrite_byte(3000); //life in .1
        ewrite_byte(500); //line Width .1
        ewrite_byte(3); //noise amp .1
        ewrite_byte(129);  //r
        ewrite_byte(109);  //g
        ewrite_byte(111);  //b
        ewrite_byte(255);  //brightness
        ewrite_byte(2); //scroll speed
        emessage_end();
        //end smoke ring

        //fire
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_FIREFIELD);
        //ewrite_coord_f(origin)
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 80);
        ewrite_short(200); //ewrite_short(radius) (fire is made in a square around origin. -radius, -radius to radius, radius)
        ewrite_short(g_Pow); //ewrite_short(modelindex)
        ewrite_byte(10); //ewrite_byte(count)
        ewrite_byte(2); //ewrite_byte(flags)
        ewrite_byte(30); //ewrite_byte(duration (in seconds) * 10) (will be randomized a bit)
        emessage_end();
        //end fire

        //the mushroom
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_BEAMCYLINDER);
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 16);
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 200);
        ewrite_short(g_recoil);
        ewrite_byte(1); //start frame
        ewrite_byte(7); //frame rate
        ewrite_byte(35); //life in .1
        ewrite_byte(200); //line Width .1
        ewrite_byte(100); //noise amp .1
        ewrite_byte(170);  //r // 120 109 111 odd orange
        ewrite_byte(130);  //g
        ewrite_byte(30);  //b
        ewrite_byte(254);  //brightness
        ewrite_byte(3); //scroll speed
        emessage_end();

        //sparks!
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_SPARKS);
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 30);
        emessage_end();

        //teleport
        emessage_begin(MSG_TYPE, SVC_TEMPENTITY)
        ewrite_byte(TE_TELEPORT);
        ewrite_coord_f(Vector[0]);
        ewrite_coord_f(Vector[1]);
        ewrite_coord_f(Vector[2] + 255);
        emessage_end();


        //the rocket exhaust
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_BEAMFOLLOW);
        ewrite_short(id);  //(entity:attachment to follow)
        ewrite_short(g_Wow);
        ewrite_byte(5); //(life in 0.1's)
        ewrite_byte(5); //(line width in 0.1's)
        ewrite_byte(255);  //(red) 67     (67 25 67 are pink!)
        ewrite_byte(150); //(green) 25    (129 109 111 wht)
        ewrite_byte(1); //(blue)  67
        ewrite_byte(500); //(brightness)
        emessage_end();

        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_BEAMFOLLOW);
        ewrite_short(id);  //(entity:attachment to follow)
        ewrite_short(g_fun);
        ewrite_byte(10); //(life in 0.1's)
        ewrite_byte(5); //(line width in 0.1's)
        ewrite_byte(255);  //(red) 67     (67 25 67 are pink!)
        ewrite_byte(150); //(green) 25    (129 109 111 wht)
        ewrite_byte(1); //(blue)  67
        ewrite_byte(500); //(brightness)
        emessage_end();

        #if defined(DEBUG)
        server_print("Blue in exhaust")
        #endif

        //the blue part in exhaust just like my blow torch
        emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
        ewrite_byte(TE_BEAMFOLLOW);
        ewrite_short(id);  //(entity:attachment to follow)
        ewrite_short(g_Blu);
        ewrite_byte(5); //(life in 0.1's)
        ewrite_byte(20); //(line width in 0.1's)
        ewrite_byte(0);  //(red)
        ewrite_byte(255); //(green)
        ewrite_byte(67); //(blue)
        ewrite_byte(500); //(brightness)
        emessage_end();

        x5_dam();

        #if defined(DEBUG)
        server_print("Ready to text")
        #endif

        if(!is_user_bot(id))
        {
            new Float:xTex
            xTex = -0.4
            new Float:yTex
            yTex = -0.9
            new Float:fadeInTime = 0.5;
            new Float:fadeOutTime = 0.5;
            new Float:holdTime = 1.0;
            new Float:scanTime = 1.2;
            new effect = 2;

            emessage_begin ( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id )
            ewrite_byte(TE_TEXTMESSAGE);
            ewrite_byte(0);      //(channel)
            ewrite_short(FixedSigned16(xTex,1<<13));  //(x) -1 = center)
            ewrite_short(FixedSigned16(yTex,1<<13));  //(y) -1 = center)
            ewrite_byte(effect);  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is ewrite out (training room)
            ewrite_byte(0);  //(red) - text color 255 100 75 20 25 200 175 30
            ewrite_byte(255);  //(GRN)
            ewrite_byte(64);  //(BLU)
            ewrite_byte(200);  //(alpha)
            ewrite_byte(255);  //(red) - effect color
            ewrite_byte(0);  //(GRN)
            ewrite_byte(0);  //(BLU)
            ewrite_byte(25);  //(alpha)
            ewrite_short(FixedUnsigned16(fadeInTime,1<<8));
            ewrite_short(FixedUnsigned16(fadeOutTime,1<<8));
            ewrite_short(FixedUnsigned16(holdTime,1<<8));
            if (effect == 2)
            {
                ewrite_short(FixedUnsigned16(scanTime,1<<8));
            }
            ewrite_string("Rocket Jump!");
            emessage_end();
        }
        philiadelphia(id); //October 28, 1943 USA.
        if(get_user_flags(id) & ADMIN_CHECK)
        {
            TelePort(id);
        }
    }
}

public Regular(id)
{
    new Float:Hector[3];
    pev(id,pev_origin,Hector);
    //the mushroom
    emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
    ewrite_byte(TE_BEAMCYLINDER);
    ewrite_coord_f(Hector[0]);
    ewrite_coord_f(Hector[1]);
    ewrite_coord_f(Hector[2] + 16);
    ewrite_coord_f(Hector[0]);
    ewrite_coord_f(Hector[1]);
    ewrite_coord_f(Hector[2] + 200);
    ewrite_short(g_recoil);
    ewrite_byte(1); //start frame
    ewrite_byte(7); //frame rate
    ewrite_byte(35); //life in .1
    ewrite_byte(200); //line Width .1
    ewrite_byte(100); //noise amp .1
    ewrite_byte(170);  //r // 120 109 111 odd orange
    ewrite_byte(130);  //g
    ewrite_byte(30);  //b
    ewrite_byte(254);  //brightness
    ewrite_byte(3); //scroll speed
    emessage_end();
    x6_dam();


        //sparks//
    emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
    ewrite_byte(TE_SPARKS);
    ewrite_coord_f(Hector[0]);
    ewrite_coord_f(Hector[1]);
    ewrite_coord_f(Hector[2] + 200);
    emessage_end();

    //teleport
    emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() ) //(0,SVC_TEMPENTITY)
    ewrite_byte(TE_TELEPORT);
    ewrite_coord_f(Hector[0]);
    ewrite_coord_f(Hector[1]);
    ewrite_coord_f(Hector[2] + 255);
    emessage_end();

    //the rocket exhaust
    emessage_begin ( MSG_TYPE, SVC_TEMPENTITY, { 0, 0, 0 }, players_who_see_effects() )
    ewrite_byte(TE_BEAMFOLLOW);
    ewrite_short(id);  //(entity:attachment to follow)
    ewrite_short(g_Wow);
    ewrite_byte(5); //(life in 0.1's)
    ewrite_byte(5); //(line width in 0.1's)
    ewrite_byte(255);  //(red) 67     (67 25 67 are pink!)
    ewrite_byte(150); //(green) 25    (129 109 111 wht)
    ewrite_byte(1); //(blue)  67
    ewrite_byte(500); //(brightness)
    emessage_end();
}

public x5_dam()
{
    emit_sound(0, CHAN_AUTO, "fvox/radiation_detected.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    new location[3]
    new Float:Vec[3]
    IVecFVec(location, Vec)
    FVecIVec(Vec, location)
    location[2] = location[2] + 20

    new players[MAX_PLAYERS]
    new playercount

    get_players(players,playercount,"ah")

    for (new m; m<playercount; m++)
    {
        new bid
        pev(bid,pev_origin,location)
        new playerlocation[3]

        get_user_origin(players[m], playerlocation)

        new quasidistance = get_distance(playerlocation,location)
        new resultdance = get_entity_distance(bid, players[m])

        if(resultdance < 1000)
        fakedamage(players[m],"Radiation",3.0,DMG_RADIATION)


        if(resultdance > 999)
        fakedamage(players[m],"Fall-out",1.0,DMG_TIMEBASED)

        new name[MAX_PLAYERS]
        get_user_name(players[m],name,charsmax(name))
        server_print("%s was %i",name , quasidistance)
    }
}

public x6_dam()
{
    new location[3]
    new Float:Vec[3]
    IVecFVec(location, Vec)
    FVecIVec(Vec, location)
    location[2] = location[2] + 20

    new players[MAX_PLAYERS]
    new playercount

    get_players(players,playercount,"ah")

    for (new m; m < playercount; ++m)
    {
        new bid
        pev(bid,pev_origin,location)
        new playerlocation[3]

        get_user_origin(players[m], playerlocation)

        new quasidistance = get_distance(playerlocation,location)
        new resultdance = get_entity_distance(bid, players[m])

        if(resultdance < 1000)
        {
            fakedamage(players[m],"Rocket flame",7.0,DMG_DROWN)
        }

        #define DMG_IGNITE      (1 << 24)
        if(resultdance > 999)
        {
            fakedamage(players[m],"Rocket exhaust",4.0,DMG_RADIATION)
        }

        new name[MAX_PLAYERS + 1]
        get_user_name(players[m],name,charsmax(name))
        server_print("%s was %i",name , quasidistance)
    }
}

public  Damage ( Victim, Inflictor, Attacker, Float:fDamage )
{
    if(is_user_connected(Attacker) && Attacker != Victim)
    {
        if(get_user_weapon(Attacker) == HLW_RPG)
        {
            pev(Attacker,pev_angles,plAngles);
            if(plAngles[0] <= FLOAT_ANGLE)
            {
                SetHamParamFloat(4, fDamage * 2.5);
            }
            if (plAngles[0] >= FLOAT_UFO)
            {
                ufo_sky_damage( Victim, Inflictor, Attacker, Float:fDamage );
            }
        }
    }
}

public  ufo_sky_damage ( Victim, Inflictor, Attacker, Float:fDamage )
{
    if(is_user_connected(Attacker) && Attacker != Victim)
    {
        if(get_user_weapon(Attacker) == HLW_RPG)
        {
            SetHamParamFloat(4, fDamage * 6.0);
        }
    }
}

public CmdGive(id,level,cid)
{
    if(!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED

    if(get_pcvar_num(p_Enable) == 1)
    {
        client_print(id,print_console,"[AMXX] RocketJump is currently set to be enabled on all players.");
        return PLUGIN_HANDLED;
    }

    new arg[MAX_PLAYERS + 1],arg2[MAX_PLAYERS + 1]

    read_argv(1,arg,charsmax(arg));
    read_argv(2,arg2,charsmax(arg2));

    new target = cmd_target(id,arg);

    if(!target) return PLUGIN_HANDLED

    new plName[MAX_NAME_LENGTH]
    get_user_name(id,plName,charsmax(plName));

    if(str_to_num(arg2) == 1)
    {
        client_print(id,print_console,"[AMXX] RocketJump enabled for: %s",plName);
        g_HasJump[target] = 1
    }
    else
    {
        client_print(id,print_console,"[AMXX] RocketJump disabled for: %s",plName);
        g_HasJump[target] = 0
    }

    return PLUGIN_HANDLED
}

public client_putinserver(id) g_HasJump[id] = 0;

stock fm_set_user_godmode(index, godmode = 0)
    return set_pev(index, pev_takedamage, godmode ? DAMAGE_NO : DAMAGE_YES);

// Shoot the sound around the origin.
public overhear(dist,origin2[3],Sound[])
{
    for(new b = 1; b <= maxplayers; b++)
    {
        if(is_user_connected(b))
        {
            new bOrigin[3]
            get_user_origin(b,bOrigin)
            if (dist==-1) emit_sound(b,CHAN_VOICE, Sound, 0.0, ATTN_NORM, 0, PITCH_NORM);
            else if (get_distance(origin2,bOrigin) <= dist) emit_sound(b,CHAN_VOICE, Sound, 0.0, ATTN_NORM,0, PITCH_NORM);
        }
    }
}

public rocketsound()
{
    new id, Float:Origin[3];
    pev(id,pev_origin,Origin)
    Origin[2] += 10

    new origin2[3]
    for(new i=0;i<3;i++) origin2[i] = floatround(Origin[i]);

    overhear(2000,origin2, "ambience/alienflyby2.wav")
    overhear(1000,origin2, "weapons/mortarhit.wav")
}

stock FixedSigned16( Float:value, scale )
// Converts floating-point number to signed 16-bit fixed-point representation
{
    new Output;
    Output = floatround( value * scale )

    if ( Output > 3276 )
        Output = 32767
    if ( Output < -32768 )
        Output = -32768;

    return  Output;
}
stock FixedUnsigned16( Float:value, scale )
// Converts floating-point number to unsigned 16-bit fixed-point representation
{
    new Output;
    Output = floatround( value * scale )

    if ( Output < 0 )
        Output = 0;
    if ( Output > 0xFFFF )
        Output = 0xFFFF;

    return  Output;
}

stock players_who_see_effects()
{
    new players[MAX_PLAYERS], playercount, SEE;
    get_players(players,playercount,"ch");
    for (SEE=0; SEE<playercount; SEE++)
    return SEE;
    return PLUGIN_CONTINUE;
}

public remove_telesprite_task(ent)
{
    ent -= 33453
    if(pev_valid(ent))
    engfunc(EngFunc_RemoveEntity, ent);
    return PLUGIN_HANDLED;
}

public react_function(id, Float:origin[3])
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
    message_begin(0, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    write_coord(floatround(origin[0]));
    write_coord(floatround(origin[1]));
    write_coord(floatround(origin[2]));
    write_coord(floatround(End[0]));
    write_coord(floatround(End[1]));
    write_coord(floatround(End[2]));
    write_short(Graphic);
    write_byte(Start);
    write_byte(Rate);
    write_byte(Life);
    write_byte(Width);
    write_byte(Noise);
    write_byte(Red);
    write_byte(Grn);
    write_byte(Blu);
    write_byte(Bright);
    write_byte(Scroll);
    message_end();

    free_tr2(tr);
}

public TelePort(id)
{
    static spawnId, Float:origin[3], Float:angles[3], player, ent;

    player = id;
    ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"));

    set_pev(ent, pev_rendermode, kRenderTransAdd);
    engfunc(EngFunc_SetModel, ent, "sprites/b-tele1.spr");

    set_pev(ent, pev_renderamt, 255.0);
    set_pev(ent, pev_animtime, 1.0);
    set_pev(ent, pev_framerate, 50.0);
    set_pev(ent, pev_frame, 10);

    pev(player, pev_origin, origin);

    set_pev(ent, pev_origin, origin);
    dllfunc(DLLFunc_Spawn, ent);

    set_pev(ent, pev_solid, SOLID_NOT);
    emit_sound(ent, CHAN_AUTO, TELEPORT_SOUND, 0.8, ATTN_NORM, 0, PITCH);

    message_begin(MSG_PVS,SVC_TEMPENTITY);
    write_byte(TE_DLIGHT);
    write_coord(floatround(origin[0]));
    write_coord(floatround(origin[1]));
    write_coord(floatround(origin[2]));
    write_byte(35);
    write_byte(80);
    write_byte(255);
    write_byte(100);
    write_byte(80);
    write_byte(60);
    message_end();

    spawnId = SpawnID[random_num(0,strlen(SpawnID) - 1)]

    pev(spawnId, pev_origin, origin);
    pev(spawnId, pev_angles, angles);

    set_pev(player, pev_origin, origin);
    set_pev(player, pev_angles, angles);
    set_pev(player, pev_fixangle, 1);
    set_pev(player, pev_velocity, {0.0, 0.0, 0.0});

    message_begin(MSG_BROADCAST, get_user_msgid("ScreenFade"), {0,0,0}, player);
    write_short(1<<10);
    write_short(1<<3);
    write_short(0);
    write_byte(100);
    write_byte(255);
    write_byte(100);
    write_byte(150);
    message_end();

    set_task(0.3, "remove_telesprite_task", ent + 33453);

    emit_sound(id, CHAN_AUTO, TELEPORT_SOUND, 0.8, ATTN_NORM, 0, PITCH);

    react_function(id,origin);
}
