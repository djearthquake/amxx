// Standard Includes
#include <amxmodx>
#include <amxmisc>

// Include for constants.
#include <engine>
#include <ham_const>
// Include for Ent manipulation
#include <fakemeta>
#include <fun>

// Debug mode
#define DEBUG
#define DEBUG_ADV
#define DEBUG_RAD
// Sprite storage ints

new Float:minbox[3] = { -20.1, -20.1, -20.1 }
new Float:maxbox[3] = { 20.1, 20.1, 20.1 }
new Float:angles[3] = { 0.0, 0.0, 0.0 }

new sprFlare6, sprLightning, white, sprSmoke, fire, g_Wtf0, g_Wtf1, g_Wtf2, g_Wtf3, g_Wtf4, g_Wtf5, g_Wtf6, g_Fun0, g_Fun1, g_Fun2, g_Fun3, g_Fun4, g_suicide; // g_Drama, g_Zunny
new const SOUND_KILL[] = "fans/fan1off.wav"
new const SOUND_SANI[] = "sound/misc/sani.mp3"
// Plugin Intilize
public plugin_init()
{
    register_plugin(".sρiηX҉.","A","ArKBom"); //based on Twlight's satellite rain!
    g_suicide = engfunc(EngFunc_PrecacheEvent, 1, "events/displacer.sc")
    // Test command for ArK.
    register_concmd("nuke","cmd_nuke",0,"Nuke - nuke <#> detonation seconds <#> toss magnitude> ")
    register_cvar("allow_nukes","0")
}

// Precache Stuff
public plugin_precache()
{
    // For ArK
    precache_model("models/w_isotopebox.mdl");

    precache_sound("x/nih_die2.wav");
    precache_sound("fvox/bell.wav");
    precache_sound("weapons/mortarhit.wav");
    precache_sound("ambience/warn2.wav");
    precache_sound("fvox/danger.wav");
    precache_sound("fvox/buzz.wav");
    precache_sound("fvox/boop.wav");
    precache_sound("fvox/powermove_overload.wav");
    precache_sound("fvox/atmospherics_on.wav");
    precache_model("models/glassgibs.mdl");
    precache_sound("vox/contamination.wav");
    precache_sound("debris/bustglass1.wav");
    precache_sound(SOUND_KILL);
    precache_generic(SOUND_SANI);

    // Explosion Models

    white = precache_model("sprites/white.spr")
    sprSmoke = precache_model("sprites/ballsmoke.spr")
    fire = precache_model("sprites/laserdot.spr")

    g_Wtf0 = precache_model("models/ark.mdl")
    g_Wtf1 = precache_model("models/hair.mdl")
    g_Wtf2 = precache_model("models/fungus(large).mdl")
    g_Wtf3 = precache_model("models/glassgibs.mdl")
    g_Wtf4 = precache_model("models/nihilanth.mdl")
    g_Wtf5 = precache_model("models/cindergibs.mdl")
    g_Wtf5 = precache_model("models/gasbag.mdl")
    g_Wtf6 = precache_model("models/chromegibs.mdl")


    g_Fun0 = precache_model("sprites/bubble.spr")
    g_Fun1 = precache_model("sprites/fexplo.spr")
    g_Fun2 = precache_model("sprites/rjet1.spr")
    g_Fun3 = precache_model("sprites/blast.spr")
    g_Fun4 = precache_model("sprites/explode1.spr")

    //ArK effects
    sprFlare6 = precache_model("sprites/Flare6.spr")
    sprLightning = precache_model("sprites/lgtning.spr")
    //ArK effect if human killed it before timer
    //g_Drama = precache_model("models/sat_globe.mdl");
    //g_Zunny = precache_model("sprites/smoke.spr");
}

//The effect when times runs out.
public explode_effect(Float:Origin[3]){

    #if defined(DEBUG)
    server_print("Time up boom time!!")
    #endif

    message_begin(0,23)
    write_byte( 21 ) //TE_BEAMCYLINDER
    write_coord(floatround(Origin[0]))          // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]-70))
    write_coord(floatround(Origin[0]))          // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]+136))
    write_short( g_Fun2 )
    write_byte( random_num(3,99) ) // startframe
    write_byte( random_num(2,100)) // framerate
    write_byte( random_num(20,3000 )) // life 2
    write_byte( random_num(20,1500 )) // width 16
    write_byte( random_num(2,600) ) // noise
    write_byte( random_num(0,255)) // r // 200 255 0
    write_byte( random_num(0,255)) // g
    write_byte( random_num(0,255)) // b
    write_byte( random_num(100,2000 )) //brightness
    write_byte( random_num(5,90 )) // speed
    message_end()

    #if defined(DEBUG)
    server_print("lava for flash.., loaded!")
    #endif

    message_begin(0,23)
    write_byte(TE_LAVASPLASH)
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))
    message_end();

    #if defined(DEBUG)
    server_print("sparks called")
    #endif
    message_begin(0,23)
    write_byte(TE_SPARKS)
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))

    message_end()
    //teleport-sparks
    message_begin(0,23)
    write_byte(TE_TELEPORT)
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))
    message_end();

    #if defined(DEBUG)
    server_print("smoke ring called")
    #endif

    //smoke ring
    message_begin(0,23); //needs 6 lines coords
    write_byte(TE_BEAMCYLINDER);
    write_coord(floatround(Origin[0]))                      // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]-111))
    write_coord(floatround(Origin[0]))                      // coord, coord, coord (start)

    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]+200))
    write_short( white )
    write_byte(3) //start frame
    write_byte(65) //frame rate
    write_byte(3000) //life in .1
    write_byte(500) //line Width .1
    write_byte(3) //noise amp .1
    write_byte(129)  //r
    write_byte(109)  //g
    write_byte(111)  //b
    write_byte(255)  //brightness
    write_byte(2) //scroll speed
    message_end()

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Explosion2
    message_begin(0,23)
    write_byte( 12 ) //TE_EXPLOSION2
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))
    write_byte( random_num(2,1000)) // byte (scale in 0.1's) 188
    write_byte( random_num(2,100) ) // byte (framerate)
    message_end()

    #if defined(DEBUG)
    server_print("TE called")
    #endif

    /*
    *       #define TE_SMOKE                    5
    */
    message_begin(0,23)
    write_byte( 5 )
    write_coord(floatround(Origin[0]))
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]))
    write_short( white ) //index
    write_byte( random_num(5,1000)) // byte (scale in 0.1's) 188
    write_byte( random_num(1,60)) // byte (framerate)
    message_end()

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    #if defined(DEBUG)
    server_print("TE_BEAMSPRITE 18 new")
    #endif
    message_begin(0,23)
    write_byte(TE_BEAMSPRITE) //18
    write_coord(floatround(Origin[0]+random_float(-5.0,5.0)))                      // XYZ (start)
    write_coord(floatround(Origin[1]+random_float(-5.0,5.0)))
    write_coord(floatround(Origin[2]+random_float(-5.0,5.0)))
    write_coord(floatround(Origin[0]+random_float(-5.0,5.0)))                      // XYZ (end)
    write_coord(floatround(Origin[1]+random_float(-5.0,5.0)))
    write_coord(floatround(Origin[2]+random_float(-5.0,5.0)))
    write_short(sprSmoke) //(beam sprite index)
    write_short(sprFlare6) //(end sprite index)
    message_end()

    #if defined(DEBUG)
    server_print("TE_EXPLODEMODEL NEW")
    #endif
    message_begin(0,23)
    write_byte(TE_EXPLODEMODEL)
    write_coord(floatround(Origin[0]+random_float(-11.0,11.0)))                      // XYZ (start)
    write_coord(floatround(Origin[1]-random_float(-11.0,11.0)))
    write_coord(floatround(Origin[2]+random_float(1.0,75.0)))
    write_coord(random_num(-1500,10000))                      // velocity


    switch(random_num(0,6)) {
    
    case 0: write_short(g_Wtf0)              //(model index)
    case 1: write_short(g_Wtf1)              //(model index)
    case 2: write_short(g_Wtf2)
    case 3: write_short(g_Wtf3)
    case 4: write_short(g_Wtf4)
    case 5: write_short(g_Wtf5)
    case 6: write_short(g_Wtf6)
    }

    write_short(random_num(10,200))               //(count)
    write_byte(random_num(20,1000))              //(life in 0.1's)
    message_end()
    #define TE_EXPLODEMODEL             107


    #if defined(DEBUG)
    server_print("smoke called on time up...")
    #endif

    //Smoke
    message_begin(0,23)
    write_byte( 5 ) // 5
    write_coord(floatround(Origin[0]))          // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]))
    write_short( sprSmoke )
    write_byte( random_num(2,100) ) // 2
    write_byte( random_num(2,100) ) // 10
    message_end()

    message_begin(0,23)
    write_byte(TE_EXPLOSION2) //needs desc as emglish or # check man
    write_coord(floatround(Origin[0]))                      // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]))
    write_byte(random_num(2,100) ) //start color
    write_byte(random_num(1,110)); //num colors
    message_end()

    //teleport
    message_begin(0,23)
    write_byte(TE_TELEPORT)
    write_coord(floatround(Origin[0]-50))                      // coord, coord, coord (start)
    write_coord(floatround(Origin[1]-30))
    write_coord(floatround(Origin[2]+40))
    message_end();

    message_begin(0,23)
    write_byte(TE_TEXTMESSAGE)
    write_byte(0)      //(channel)
    write_short(random_num(2000,4000))  //(x) -1 = center)
    write_short(random_num(2000,4000))  //(y) -1 = center)
    write_byte(1)  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    write_byte(random_num(0,255))  //(red) - text color
    write_byte(random_num(0,255))  //(green)
    write_byte(random_num(0,255))  //(blue)
    write_byte(random_num(25,255))  //(alpha)
    write_byte(random_num(0,255))  //(red) - effect color
    write_byte(random_num(0,255))  //(green)
    write_byte(random_num(0,255))  //(blue)
    write_byte(random_num(25,255))  //(alpha)
    write_short(300)  //(fadein time)
    write_short(300)  //(fadeout time)
    write_short(800)  //(hold time)
    write_short(999) //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
    write_string("Nuke exploded...") //(text message) 512 chars max string size
    message_end()

    #if defined(DEBUG)
    server_print("purplelike called")
    #endif

    //purple poof like gauss
    message_begin(0,23)
    write_byte(TE_BEAMDISK)
    write_coord(floatround(Origin[0]))                      // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]-111))
    write_coord(floatround(Origin[0]))                      // coord, coord, coord (start)
    write_coord(floatround(Origin[1]))
    write_coord(floatround(Origin[2]+200))
    write_short( sprSmoke ) //sprSmoke
    write_byte(random_num(3,99)) //start framing
    write_byte(random_num(2,100)) //frame rate
    write_byte(random_num(50,2000)) //life
    write_byte(random_num(60,7000)) //line W
    write_byte(random_num(1,1200)) //noise amp
    write_byte(random_num(0,255))  //R  57-225-20 is lime
    write_byte(random_num(0,255))  //G  //was 128
    write_byte(random_num(0,255)) //blu
    write_byte(random_num(5,3000)) //bright
    write_byte(random_num(1,90)) //scrool spped
    message_end()
    return 1;
}

// The ArK around bomb (ArK)
public ArK_effect(Float:Origin[3])
{
    #if defined(DEBUG)
    server_print("the ArK is luminating")
    #endif
    
    message_begin(0,23)
    write_byte(100)  //#define TE_LARGEFUNNEL              100
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))
    switch(random_num(0,7))
    {
        case 0: write_short(white) //spr ind
        case 1: write_short(sprSmoke) //spr ind
        case 2: write_short(fire) //spr ind
        case 3: write_short(g_Fun0) //spr ind
        case 4: write_short(g_Fun1)
        case 5: write_short(g_Fun2)
        case 6: write_short(g_Fun3)
        case 7: write_short(g_Fun4)
    }
    write_short(0) //flags
    message_end();
    
    #if defined(DEBUG)
    server_print("sparks called")
    #endif
    message_begin(0,23)
    write_byte(TE_SPARKS)
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))
    
    message_end()
    //teleport-sparks
    message_begin(0,23)
    write_byte(TE_TELEPORT)
    write_coord(floatround(Origin[0]+random_num(-11,11)))
    write_coord(floatround(Origin[1]+random_num(-11,11)))
    write_coord(floatround(Origin[2]+random_num(-11,11)))
    message_end();
    #if defined(DEBUG)
     server_print("switch flare to lightening called")
    #endif
    
    message_begin(0,23)
    write_byte(21) //was 20
    write_coord(floatround(Origin[0])) //random_float(-0.5,0.5)))           // coord coord coord (center position)
    write_coord(floatround(Origin[1])) //random_float(-3.0,3.0)))
    write_coord(floatround(Origin[2]+random_float(1.0,5.0)))
    write_coord(floatround(Origin[0])) //random_float(-0.5,0.5)))           // coord coord coord (axis and radius)
    write_coord(floatround(Origin[1])) //random_float(-3.0,3.0)))
    write_coord(floatround(Origin[2]+random_float(500.0,1000.0)))
    switch(random_num(0,1)) {
    case 0: write_short(sprFlare6)          // short (sprite index)
    case 1: write_short(sprLightning);}
    write_byte(random_num(4,10))                // byte (starting frame)  //was 1
    write_byte(random_num(3,30));   //(frame rate in 0.1's)
    write_byte(random_num(200,1100));   //(life in 0.1's)
    write_byte(random_num(500,500000));    //(line width in 0.1's)
    write_byte(random_num(200,6000));                       // byte (noise amplitude in 0.01's) //was 10
    write_byte(random_num(0,255))               // byte,byte,byte (color) 255 119 255 pink
    write_byte(random_num(0,255))
    write_byte(random_num(0,255))
    write_byte(random_num(200,2000))            // byte (brightness) //1000 zombie fog
    write_byte(random_num(5,30))                // byte (scroll speed in 0.1's) // was 7
    message_end()
    #if defined(DEBUG)
     server_print("switch flare to lightening end")
    #endif

}

//end ArKed! the heartbeat ArK with a pulse visual

public cmd_nuke(id,level,cid)
{
    new g_ArK = spawn_ArK(id)
    if( (!cmd_access ( id, level, cid, 1 )) && !(get_cvar_num("allow_nukes")) ) return PLUGIN_HANDLED;
    new Float:playerorigin[3], Float:velocity[3]
    if( (!g_ArK)){
    console_print(id,"Somethin's wrong!")
    return PLUGIN_HANDLED;
    }
    
    new arg[32]
    read_argv(1,arg,31)
    set_task_ex(floatstr(arg),"kill_ArK",g_ArK, .flags = SetTask_Once);
    set_task_ex(floatstr(arg),"ArK_watch",424, .flags = SetTask_Once);
    read_argv(2,arg,31)
    VelocityByAim(id,str_to_num(arg),velocity)
    pev(id,pev_origin,playerorigin)
    playerorigin[2] += 20
    
    shoot_ArK(g_ArK,playerorigin,velocity);
    //native give_item(index, const item[]);
    if(is_user_alive(id) && is_user_connected(id))
    {give_item(id, "weapon_penguin");}
    new trail;
    engfunc(EngFunc_TraceToss, g_ArK, id, trail)
    server_print("ArK Deployed!")
    
    
    //the rocket exhaust now player follower ArK!
    message_begin(0,23)
    write_byte(TE_BEAMFOLLOW)
    write_short(g_ArK)  //(entity:attachment to follow)
    write_short(sprFlare6)
    write_byte(random_num(100,2000)) //(life in 0.1's)
    write_byte(random_num(500,10000)) //(line width in 0.1's)
    write_byte(random_num(0,255))  //(red) 67     (67 25 67 are pink!) //was 255 150 1 ---nice yellow
    write_byte(random_num(0,255)) //(green) 25    (129 109 111 wht)
    write_byte(random_num(0,255)) //(blue)  67
    write_byte(random_num(200,7500)) //(brightness) //was 2000
    message_end()
    
    #if defined(DEBUG)
    server_print("Ready to text")
    #endif
    
    //text
    message_begin(0,23)
    write_byte(TE_TEXTMESSAGE)
    write_byte(0)      //(channel)
    write_short(5000)  //(x) -1 = center)
    write_short(2000)  //(y) -1 = center)
    write_byte(2)  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    write_byte(0)  //(red) - text color
    write_byte(255)  //(green)
    write_byte(64)  //(blue)
    write_byte(200)  //(alpha)
    write_byte(255)  //(red) - effect color
    write_byte(0)  //(green)
    write_byte(0)  //(blue)
    write_byte(25)  //(alpha)
    write_short(300)  //(fadein time)
    write_short(500)  //(fadeout time)
    write_short(300)  //(hold time)
    write_short(366) //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
    write_string("Explode the device!") //(text message) 512 chars max string size
    message_end()
    
    // End the message and return.
    return 1;
}

public ArK_watch(){server_print("Luckily there's control.");}

// Spawn a ArK, and return its index.
public spawn_ArK(id){
    
    #if defined(DEBUG)
    server_print("Spawn Called")
    #endif
    // Make the ent and check it.
    new g_ArK = create_entity("func_breakable");    //trigger_changelevel  teleport
    
    if(!g_ArK) return 0;
    
    //  new ArK
    //        entity_set_model g_ArK,"models/hair.mdl"
    //        entity_set_model(g_ArK,"models/w_isotopebox.mdl")
    
    // Set it to bounce on its solid box, and have classname "ArK"
    set_pev(g_ArK,pev_movetype, MOVETYPE_BOUNCE)  //bounce is 10
    
    set_pev(g_ArK,pev_classname, "func_breakable");  //was ArK
    //new ptr = pev(entid, pev_classname)
    
    //   2: The pointer will be stored in ptr AND the actual string is retrieved.
    //   new ptr, classname[32]
    //   pev(entid, pev_classname, ptr, classname, 31)
    
    set_pev(g_ArK,pev_solid,SOLID_TRIGGER) // 1 trigger btw  solid_bsp needs MOVETYPE_PUSH  //3 slidebox fn box!
    
    set_pev(g_ArK,pev_effects, 4 ) //dwight center
    //  set_pev(g_ArK,pev_effects, 1 ) // 1 particles cloud 16 is from above
    set_pev(g_ArK,pev_effects,random_num(1,64))  // 16 from above
    set_pev(g_ArK, pev_effects, 64) //  EF_LIGHT rocketflare // sic but cant see the model!
    
    //Set its model, its health, its owner, and the fact it can take 'damage.
    entity_set_model(g_ArK,"models/gasbag.mdl") //w_isotopebox.mdl
    //new Float:takedamage, pev(entity, pev_takedamage, takedamage) values
    set_pev(g_ArK,pev_takedamage,DAMAGE_YES); //theres 0.0 1.0 2.0 nade only is 2.0 or opposite testing  ///note aim is crashing!!!
    set_pev(g_ArK,pev_health,500.0);
    set_pev(g_ArK,pev_owner,id);
    
    
    // Return its index.
    return g_ArK;
}

// Shoot the ArK around.
public shoot_ArK(g_ArK,Float:origin[3],Float:velocity[3]){
#if defined(DEBUG)
        server_print("Shoot Called")
#endif
    // Give the ArK a home.
    entity_set_origin(g_ArK,origin)

    // Set its various specifications.
    set_pev(g_ArK,pev_sequence,1)  //0
    set_pev(g_ArK,pev_framerate,random_num(5,300))
    set_pev(g_ArK,pev_gravity,0.1) //0.3
    set_pev(g_ArK,pev_friction,0.1)
    // Set its velocity
    set_pev(g_ArK,pev_velocity,velocity)

    // make sure its got a box around it, to bounce off of.
    entity_set_model(g_ArK,"models/gasbag.mdl") //this is where it really sticks it!
    entity_set_size(g_ArK, minbox, maxbox )
    set_pev(g_ArK,pev_angles,angles)

    // Make sure the think's are called.

    ArKThink(g_ArK)
    ArKSound(g_ArK)
    SlowArK(g_ArK)
    // return its index.
    return g_ArK;
}

// When the ArK thinks, this is what we want it to think.
public ArKThink(g_ArK){
#if defined(DEBUG_ADV)
        server_print("Think Called")
#endif
    // Make sure it remembers to pickapushtype pev(entity, pev_movetype) values.
    //if (pev_valid(g_ArK))set_pev(g_ArK,pev_movetype,random_num(10,11)); //pushtype
/// if (pev_valid(g_ArK))entity_set_size(g_ArK, minbox, maxbox )
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_movetype,MOVETYPE_BOUNCE);
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_framerate,random_num(5,1000))
    // Set gravity to normal.
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_gravity,0.1);
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_friction,0.7);
    // Run the think again
    set_task_ex(0.42,"ArKThink", g_ArK, .flags = SetTask_Once);
     // if its health is low, kill it.
    if( (pev_valid(g_ArK)) && (pev(g_ArK,pev_health)) < 300.0) { //was 50.0
    if(pev_valid(g_ArK))ArK_shot(g_ArK);
    return;
        }

}

// Slow down the ArK
public SlowArK(g_ArK){
#if defined(DEBUG_ADV)
        server_print("Slow Down Called")
#endif
    // Get the velocities.
    new Float:velo[3], Float:avelo[3]
    if (pev_valid(g_ArK))pev(g_ArK,pev_avelocity,avelo) //invalid ent runtime
    if (pev_valid(g_ArK))pev(g_ArK,pev_velocity,velo)

    // Slow em down.
    for(new i=0; i<3; i++){
    if(velo[i] > 1 || velo[i] < -1) velo[i] = velo[i] * 0.8
    if(avelo[i] > 1 || avelo[i] < -1) avelo[i] = avelo[i] * 0.8
    }

    // Reset them
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_velocity,velo)
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_avelocity,avelo)

    // Run this again soon
    set_task_ex(0.7,"SlowArK", g_ArK, .flags = SetTask_Once);

    return;
}

public health_wreck(){
    new Float:Origin[3]
    RadiusDamage(Float:Origin, random_num(2,5), random_num(150,2000));
}

public x4_dam()

{
    new players[32]
    new mob

    get_players(players, mob, "a")

    for (new m=0; m<mob; m++)
    {
    new home[3]



    new Float:xforigin[3]
    new g_ArK

    if (pev_valid(g_ArK))
    pev(g_ArK,pev_origin,xforigin)

    new xforigin2[3]
    xforigin[2] += 10

    for(new i=0;i<3;i++) xforigin2[i] = floatround(xforigin[i]);

    get_user_origin(players[m], home);
    new Float:g_Rad = Float:get_distance_f(Float:xforigin,Float:home);

    new name[33]
    new uorigin[3]
    new id
    if(is_user_bot(id) && is_user_alive(id) && is_user_connected(id))
    get_user_origin(id, uorigin)
    get_user_name(players[m],name,32)

    new g_Trinity = get_entity_distance(g_ArK, players[m])
    server_print("..::%i::.. %i and %i is %i from %s at %i or %i", g_Trinity, Float:xforigin, Float:xforigin2, g_Rad, name, home, uorigin) //%i

    client_print(0, print_chat,"%s was %i from center", name, g_Trinity)


    if( is_user_admin(players[m]))
    client_print(0, print_chat,"VIP %s was %i", name, g_Trinity)

    if ( g_Trinity < 1000 )
    fakedamage(players[m],"Ark Proximity",50.0,DMG_RADIATION) //hlsdk_const

#if defined(DEBUG_RAD)
        server_print("%s was @{close range}", name)
#endif
    //client_print(0, print_chat,"%s was @{close range}", name)


    //native is_in_viewcone(entity, const Float:origin[3], use3d = 0);

    if (players[m]) is_in_viewcone(g_ArK, Float:home, 1)
    fakedamage(players[m],"Ark Sight",20.0,DMG_TIMEBASED) //hlsdk_const  //players[m]

    if ( g_Trinity > 3000 && g_Trinity < 5000)
    fakedamage(players[m],"Trinity",35.0,DMG_TIMEBASED) //hlsdk_const  //players[m]


#if defined(DEBUG_RAD)
        server_print("%s was @{Nuke's Viewpoint}", name)
#endif
    //client_print(0, print_chat,"%s was @{Nuke's Viewpoint}", name)



        {
    if ( g_Trinity > 1000 && g_Trinity < 3000)
    fakedamage(players[m],"Ark Fall-out",5.0,DMG_POISON) //hlsdk_const


#if defined(DEBUG_RAD)
    server_print("%s was @{long range}", name)
#endif
    //client_print(0, print_chat,"%s was @{long range}", name)

    {
    //new id
    //user_slap(id, 7, 0);
    //fakedamage(players[m],"Ark Fall-out",35.0,DMG_POISON) //hlsdk_const
    }
    }
    }

//        server_print("..::%i::.. %i and %i is %i from %s at %i or %i", g_Trinity, Float:xforigin, Float:xforigin2, g_Rad, name, home, uorigin) //%i

}



public x5_dam()
{
    #if defined(DEBUG)
    server_print("X5 dam called")
    #endif

    new location[3]
    new Float:Vec[3]
    IVecFVec(location, Vec)
    FVecIVec(Vec, location)
    location[2] = location[2] + 20

    new players[32]
    new playercount

    get_players(players,playercount,"a")
    
    for (new m=0; m<playercount; m++)
    {
        new g_ArK
        pev(g_ArK,pev_origin,location)
        new playerlocation[3]

        get_user_origin(players[m], playerlocation)
    
        new quasidistance = get_distance(playerlocation,location)
        new resultdance = get_entity_distance(g_ArK, players[m])

        if(resultdance < 1000)
        fakedamage(players[m],"Radiation",20.0,DMG_RADIATION)
        {
            if(resultdance > 1000)
            fakedamage(players[m],"Fall-out",10.0,DMG_TIMEBASED)
            
            new name[33]
            get_user_name(players[m],name,32)
            server_print("%s was %i",name , quasidistance)
        }
    }
}

public ArK_shot(g_ArK){
    #if defined(DEBUG)
    server_print("Ark was shot dead!")
    #endif
    new Float:DeathZone[3];
    if (pev_valid(g_ArK))
    pev(g_ArK,pev_oldorigin,DeathZone)
    #define PITCH (random_num (30,120))

    emit_sound(0, CHAN_AUTO, SOUND_KILL, VOL_NORM, ATTN_NORM, 0, PITCH); //do not use ent casting aawy bc it will never go away then
    new Owner, id;
    if (pev_valid(g_ArK)){Owner = pev(g_ArK,pev_owner);}
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_takedamage, DAMAGE_NO)
    if (task_exists(g_ArK))remove_task(g_ArK);
    if (task_exists(g_ArK))remove_task(g_ArK);
    if (task_exists(g_ArK))remove_task(g_ArK);
    if (pev_valid(g_ArK))remove_entity(g_ArK);
    #if defined(DEBUG)
    server_print("Ark kill smoke")
    #endif
    //smoke ring
    message_begin(0,23); //needs 6 lines coords
    write_byte(TE_BEAMCYLINDER);
    write_coord(floatround(DeathZone[0]))                      // coord, coord, coord (start)
    write_coord(floatround(DeathZone[1]))
    write_coord(floatround(DeathZone[2]-111))
    write_coord(floatround(DeathZone[0]))                      // coord, coord, coord (start)
    write_coord(floatround(DeathZone[1]))
    write_coord(floatround(DeathZone[2]+200))
    write_short( white )
    write_byte(3) //start frame
    write_byte(65) //frame rate
    write_byte(3000) //life in .1
    write_byte(500) //line Width .1
    write_byte(3) //noise amp .1
    write_byte(129)  //r
    write_byte(109)  //g
    write_byte(111)  //b
    write_byte(255)  //brightness
    write_byte(2) //scroll speed
    message_end()

    #if defined(DEBUG)
    server_print("Ark kill text")
    #endif
    server_cmd("allow_nukes 0")

    message_begin(0,23)
    write_byte(TE_TEXTMESSAGE)
    write_byte(0)      //(channel)
    write_short(5000)  //(x) -1 = center)
    write_short(2000)  //(y) -1 = center)
    write_byte(2)  //(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
    write_byte(57)  //(red) - text color
    write_byte(255)  //(green)
    write_byte(20)  //(blue)
    write_byte(200)  //(alpha)
    write_byte(255)  //(red) - effect color
    write_byte(51)  //(green)
    write_byte(255)  //(blue)
    write_byte(25)  //(alpha)
    write_short(300)  //(fadein time)
    write_short(500)  //(fadeout time)
    write_short(300)  //(hold time)
    write_short(366) //[optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
    write_string("ArK destroyed!!") //(text message) 512 chars max string size
    message_end()
    #if defined(DEBUG)
    server_print("Ark kill Event")
    #endif
    engfunc(EngFunc_PlaybackEvent, FEV_NOTHOST, 0, g_suicide, 0.0, Float:DeathZone, Float:{0.0, 0.0, 0.0}, 0.0, 0.0, 0, 0, 0, 0)
    if(Owner != id)return

}

// When the ArK dies, it goes with lots of effects.
public kill_ArK(g_ArK)
{
    new Owner;
    if (pev_valid(g_ArK)){Owner = pev(g_ArK,pev_owner);}
    new id;
    #if defined(DEBUG)
    server_print("Kill Called")
    #endif
    // Make it not take damage anymore.
    if (pev_valid(g_ArK))set_pev(g_ArK,pev_takedamage, DAMAGE_NO)
    #if defined(DEBUG)
    server_print("Past damage no...")
    #endif

    // Make a sound, to honor it.

    // Get its origin.
    new Float:Origin[3]
    if (pev_valid(g_ArK))
    {
        pev(g_ArK,pev_origin,Origin)  //was just pev not set_pev damge is messed up so trying stuff
        Origin[2] += 10
    
        new origin2[3]
        for(new i=0;i<3;i++) origin2[i] = floatround(Origin[i]);
        overhear(5000,origin2,"weapons/mortarhit.wav")
        overhear(1000,origin2, "fvox/powermove_overload.wav")
        #if defined(DEBUG)
        server_print("Boom sound call")
        #endif
        // Explode there. Flash visuals.
        explode_effect(Origin)
    }

    //Explode there. Bang damage.
    x4_dam();
    // Remove the ArK
    if (task_exists(g_ArK))remove_task(g_ArK);
    if (pev_valid(g_ArK))remove_entity(g_ArK);
    if( (pev_valid(g_ArK)) && (Owner != id) )return
    server_cmd("allow_nukes 0") //testing primal limit or clamp
    #if defined(DEBUG)
    server_print("X4 dam call end")
    #endif
}

// Makes a random bounce sound.
public ArKSound(g_ArK)
{

    #if defined(DEBUG_ADV)
    server_print("Sound random b Called")
    #endif
    new Float:origin2[3]
    if (pev_valid(g_ArK)){pev(g_ArK,pev_origin,origin2);} //invalid ent? runterr 10?
    new origin[3]

    for(new i=0;i<3;i++) origin[i] = floatround(origin2[i]);

    new Float:ran = random_float(-5000.0,5000.0)
    new Float:avelo[3]
    avelo[0] = 0.0
    avelo[1] = ran
    avelo[2] = 0.0

    if (pev_valid(g_ArK)){set_pev(g_ArK,pev_avelocity,avelo);}
    overhear(1000,origin,"fvox/atmospherics_on.wav")

    switch(random_num(0,7))
    {
         case 0: overhear(3000,origin,"ambience/warn2.wav")
         case 1: overhear(3000,origin,"vox/contamination.wav")
         case 2: overhear(3000,origin,"fvox/bell.wav")
         case 3: overhear(3000,origin,"fvox/boop.wav")
         case 4: overhear(3000,origin,"fvox/buzz.wav")
         case 5: overhear(3000,origin,"fvox/danger.wav")
         case 6: overhear(3000,origin,"x/nih_die2.wav")
         case 7: client_cmd(0, "mp3 play sound/misc/sani.mp3")
    }

    for(new i=0;i<10;i++) ArK_effect( origin2 );
    set_task_ex(2.5,"ArKSound", g_ArK, .flags = SetTask_Once);
}

// Shoot the sound around the origin.
public overhear(dist,origin2[3],Sound[]) {
#if defined(DEBUG)
                 server_print("overhear called")
#endif
    for(new b = 0; b < 33; b++) {   //was 33

        if(is_user_connected(b)) {
            new bOrigin[3]
            get_user_origin(b,bOrigin)
            if (dist==-1) emit_sound(b,CHAN_VOICE, Sound, 1.0, ATTN_NORM,0, PITCH_NORM);
            else if (get_distance(origin2,bOrigin) <= dist) emit_sound(b,CHAN_VOICE, Sound, 1.0, ATTN_NORM,0, PITCH_NORM);
            }
       }
}
