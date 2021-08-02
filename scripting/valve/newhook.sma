    /* AMX Mod X script.
    *
    *   SpaceDudes Hook Grab (amx_ejl_spacedudehook.sma)
    *   Copyright (C) 2003-2004  SpaceDude / Eric Lidman / jtp10181
    *
    *   This program is free software; you can redistribute it and/or
    *   modify it under the terms of the GNU General Public License
    *   as published by the Free Software Foundation; either version 2
    *   of the License, or (at your option) any later version.
    *
    *   This program is distributed in the hope that it will be useful,
    *   but WITHOUT ANY WARRANTY; without even the implied warranty of
    *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    *   GNU General Public License for more details.
    *
    *   You should have received a copy of the GNU General Public License
    *   along with this program; if not, write to the Free Software
    *   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
    *
    *   In addition, as a special exception, the author gives permission to
    *   link the code of this program with the Half-Life Game Engine ("HL
    *   Engine") and Modified Game Libraries ("MODs") developed by Valve,
    *   L.L.C ("Valve"). You must obey the GNU General Public License in all
    *   respects for all of the code used other than the HL Engine and MODs
    *   from Valve. If you modify this file, you may extend this exception
    *   to your version of the file, but you are not obligated to do so. If
    *   you do not wish to do so, delete this exception statement from your
    *   version.
    *
    ****************************************************************************
    *   Version 1.3.2 - Date: 07/12/2019 - bteam SPiNX
    *   Original with GoldSrc I played was metamod DrunkenF00l.
    *   Homepage: https://github.com/djearthquake/amxx/tree/main/scripting/
    *
    *   Version 1.3.1 - Date: 10/16/2004
    *
    *   Original by SpaceDude and Eric Lidman aka "Ludwig van" <ejlmozart@hotmail.com>
    *   Homepage: http://lidmanmusic.com/cs/plugins.html
    *
    *   Upgraded to STEAM and ported to AMXx by: jtp10181 <jtp@jtpage.net>
    *   Homepage: http://www.jtpage.net
    *
    ****************************************************************************
    *
    *  The AMXModX equivalent of HookMod written by SpaceDude. Packaged with admin
    *  comamnds, and hooking limitations by Ludwig van.  Ported to Steam and AMXx
    *  and also Currently being maintained by JTP10181.
    *
    *
    *  Admin Commands:
    *
    *  amx_hook     - toggles hook on and off. Also if cvar mentioned
    *                         below is set to 1, it also activates/deactivates
    *                         plugin "out_of_bounds.amx" if you are using it
    *                         so that bounds limits are off when hook is on and
    *                         vice versa
    *
    *  amx_hook_count       - <# of hooks allowed per player round>
    *
    *
    *  Client Command:
    *
    *    +hook - bind a key to +hook like this: bind <key> +hook, once you
    *            have done that look in the direction where you want to fire
    *            the hook and press the button.
    *
    *    say /hook      - show window with info about use of hook
    *
    *  CVARs: Paste the following into your amxx.cfg to change defaults.
    *       must uncomment cvar lines for them to take effect
    *
    ****************************************************************************
    *  CVAR CONFIG BEGIN
    ****************************************************************************

    // ******************  Hook Grab Settings  ******************

    //0 to disable hooking, 1 to enable hooking
    //sv_hook 1

    //If you are running my "out_of_bounds" plugin you may want it disabled when
    //you have the hook fully enabled. If you want this plugin to leave
    //"out_of_bounds" alone, then set this cvar to 0.
    //amx_hb_pl_kill 1

    //Default is 0, to enforce a 15 second delay on hooking
    //at round start so as to prevent spawn massacres set to 1.
    //amx_hook_spawndelay 0

    //Set to 1 to not allow vip to use hook. Set cvar to 0 to allow free vip roping
    //amx_hook_no_vip 1

    //This is number of times a player may use the hook each round. Default is
    //100. I would suggest setting to 2 or 3 per round to encourage strategic
    //usage of the hook rather than just having it be total craziness.
    //amx_hook_round 100

    //Switch to report number of hooks remaining in a round to a player if
    //that number drops to 10 or less. By default its on 1, set to 0 to turn off this report.
    //amx_rep_hcount 1

    //Hook Style - changes the style of the hook used
    //    0 - Classic hook style from orginal plugin
    //    1 - SpaceDudes Reel Hook
    //    2 - SpaceDudes AutoReel Hook
    //    3 - Cheap Kids AutoReel
    //amx_hook_style 0

    //Move accelaration is only used in hook styles 1 and 2
    //It is the rate at which you can move in the air while on the hook line
    //amx_hook_moveacc 150

    //Reel Speed is only used in hook styles 1 and 2
    //It is the rate at which you can reel in the hook line
    //amx_hook_reelspeed 400

    //Cheap Reel Speed is only used in hook style 3
    //It is the rate at which the hook line reels in
    //amx_hook_creelspeed 800

    ****************************************************************************
    *  CVAR CONFIG END
    ****************************************************************************
    *
    *                 ******** Engine Module REQUIRED ********
    *                   ******** FUN Module REQUIRED ********
    *
    *  Changelog:
    *  v1.3.2 -SPiNX - 07/12/2019
    *   - Wanted a different hook without rope and crowbow sounds. Made a cloud.
    *
    *  v1.3.1 - JTP10181 - 10/16/04
    *   - Updated for AMXModX 0.20
    *
    *  v1.3 - JTP10181 - 07/10/04
    *   - Converted MOTD boxes to work with steam and possibly with WON still (untested)
    *   - Added new hook modes that are seen in two of the superheros from superhero mod
    *   - Made it so the hook cannot be used before the freezetime has ended
    *   - Fixed all authid variables to be 32 chars to STEAMIDs are handled properly
    *   - Ported functions to AMXX and replaced AMX tags with AMXX
    *   - Fixed logging to admin log for AMXx
    *   - Removed all voting code, use amx_customvotes instead
    *   - Rearranged a lot of code and removed some useless events
    *
    *  Below v1.3 was maintained by Eric Lidman / SpaceDude
    *
    *  Thanks to whoever wrote the autoreel and cheep reel code, it works great
    *
    **************************************************************************/

    #include <amxmodx>
    #include <amxmisc>
    #include <engine>
    #include <fakemeta>
    #include <fun>

    #define HOOK_DELAY 0.5
    #define TE_BEAMENTPOINT 1
    #define TE_KILLBEAM 99
    #define DELTA_T 0.1
    #define BEAMLIFE random_num(1,11)
    #define BOOSTPOWER 500

    #define COLOR random_num(0,255)
    #define PITCH (random_num (50,155))
    new Float:Axis[3], Graphic;
    new const HOOK_SOUNDS[][] = {"common/menu1.wav","common/menu2.wav","common/menu3.wav"}
     // "ambience/hawk1.wav" "buttons/blip2.wav"    "buttons/blip1.wav" yup

    new ob_pl1,ob_pl2
    new round_delay
    new IsVip[33]
    new HookCount[33]
    new Float:HkDelay[33]
    new hooklocation[33][3]
    new hooklength[33]
    new bool:hooked[33]
    new bool:roundfreeze
    new bool:mapbounds_checked
    new Float:beamcreated[33]
    new global_gravity
    new beam, sprite, g_model2

    public plugin_init(){
    register_plugin("New Hook","1.3.2","SPiNX/EJL/JTP10181")
    register_concmd("amx_hook","amx_hc",ADMIN_LEVEL_H,": toggles hook on and off")
    register_concmd("amx_hook_count","admin_hook_count",ADMIN_LEVEL_H,": <# of hooks allowed to each player per round>")
    register_clcmd("say","HandleSay")
    register_clcmd("say /hook","hook_motd")
    register_clcmd("+hook", "hook_on")
    register_clcmd("-hook", "hook_off")
    register_cvar("sv_hook","1",FCVAR_SERVER)
    register_cvar("amx_hook_spawndelay","0")
    register_cvar("amx_hook_no_vip","1")
    register_cvar("amx_hooks_round","100")
    register_cvar("amx_rep_hcount","1")
    register_cvar("amx_hook_style","0")
    register_cvar("amx_hook_moveacc", "150" )
    register_cvar("amx_hook_reelspeed", "400" )
    register_cvar("amx_hook_creelspeed", "800" )
    if(cstrike_running())
    register_event("Battery","vip_spawn","b","1=200")
    register_event("ResetHUD", "new_round", "b")
/// register_think("beam","Trail_me")

    register_logevent("round_start", 2, "1=Round_Start")
    register_logevent("round_end", 2, "1=Round_End")

    register_cvar("amx_hb_pl_kill","1")
    set_task(4.0,"mapbounds_killer")
    }

    public plugin_precache()
    {

    beam = precache_model("sprites/zbeam4.spr");
    sprite = precache_model("sprites/smoke.spr");
    
    Graphic = precache_model("sprites/zbeam1.spr");
    g_model2 = precache_model("sprites/steam1.spr");
    for ( new index = 0; index < sizeof HOOK_SOUNDS; index++ ) {
    precache_sound(HOOK_SOUNDS[index]);
    }

    }

    public hooktask(parm[])
    {
    new id = parm[0]
    new style = parm[1]

    if (style == 0) hookstyle_classic(id)
    else if (style == 1) hookstyle_reel(id,false)
    else if (style == 2) hookstyle_reel(id,true)
    else if (style == 3) hookstyle_cheapreel(id)
    }

    //Classic hooking function from orginal plugin
    hookstyle_classic(id) {

    if ( !hooked[id] ) return

    if (!is_user_alive(id)) {
    release(id)
    return
    }

    new user_origin[3]
    new A[3], D[3]
    new acceleration, velocity_TA, desired_velocity_TA, distance
    new velocity[3], null[3]

    if (beamcreated[id] + BEAMLIFE/10 <= get_gametime()) {
    beamentpoint(id)
    }

    null[0] = 0
    null[1] = 0
    null[2] = 0

    get_user_origin(id, user_origin)
    get_entity_velocity(id, velocity)

    if (get_distance(user_origin,hooklocation[id]) <= hooklength[id]) {
    hooklength[id] = get_distance(user_origin,hooklocation[id])
    velocity[2] -= floatround(global_gravity * DELTA_T)
    }
    else {
    A[0] = hooklocation[id][0] - user_origin[0]
    A[1] = hooklocation[id][1] - user_origin[1]
    A[2] = hooklocation[id][2] - user_origin[2]

    D[0] = A[0]*A[2] / get_distance(null,A)
    D[1] = A[1]*A[2] / get_distance(null,A)
    D[2] = -(A[1]*A[1] + A[0]*A[0]) / get_distance(null,A)

    //Fixed Below for runtime error
    //acceleration = - global_gravity * D[2] / get_distance(null,D)

    distance = get_distance(null,D) ? get_distance(null,D) : 1
    acceleration = - global_gravity * D[2] / distance

    velocity_TA = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / get_distance(null,A)
    desired_velocity_TA = get_distance(hooklocation[id],user_origin) - hooklength[id]

    velocity[0] += floatround((acceleration * DELTA_T * D[0]) / get_distance(null,D))
    velocity[1] += floatround((acceleration * DELTA_T * D[1]) / get_distance(null,D))
    velocity[2] += floatround((acceleration * DELTA_T * D[2]) / get_distance(null,D))

    velocity[0] += ((desired_velocity_TA - velocity_TA) * A[0]) / get_distance(null,A)
    velocity[1] += ((desired_velocity_TA - velocity_TA) * A[1]) / get_distance(null,A)
    velocity[2] += ((desired_velocity_TA - velocity_TA) * A[2]) / get_distance(null,A)
    }
    set_entity_velocity(id, velocity)
    }

    //Modes 1 and 2 hook style from spiderman/batgirl on shero
    //SpaceDudes reel and SpaceDudes autoreel
    public hookstyle_reel(id, bool:autoReel)
    {

    if ( !hooked[id] ) return

    if (!is_user_alive(id)) {
    release(id)
    return
    }

    new user_origin[3], user_look[3], user_direction[3], move_direction[3];
    new A[3], D[3], buttonadjust[3];
    new acceleration, velocity_TA, desired_velocity_TA,distance;
    new velocity[3], null[3];

    if ( beamcreated[id] + BEAMLIFE/10 <= get_gametime() ) {
    beamentpoint(id);
    }

    null[0] = 0;
    null[1] = 0;
    null[2] = 0;

    get_user_origin(id, user_origin);
    get_user_origin(id, user_look,2);
    get_entity_velocity(id, velocity);

    buttonadjust[0]=0
    buttonadjust[1]=0

    if (get_user_button(id)&IN_FORWARD) {
    buttonadjust[0]+=1
    }
    if (get_user_button(id)&IN_BACK) {
    buttonadjust[0]-=1
    }
    if (get_user_button(id)&IN_MOVERIGHT) {
    buttonadjust[1]+=1
    }
    if (get_user_button(id)&IN_MOVELEFT) {
    buttonadjust[1]-=1
    }
    if (get_user_button(id)&IN_JUMP || (autoReel && !(get_user_button(id) & IN_DUCK) ) ){
    buttonadjust[2]+=1
    }
    if (get_user_button(id)&IN_DUCK) {
    buttonadjust[2]-=1
    }

    if (buttonadjust[0] || buttonadjust[1]) {
    user_direction[0] = user_look[0] - user_origin[0]
    user_direction[1] = user_look[1] - user_origin[1]

    move_direction[0] = buttonadjust[0]*user_direction[0] + user_direction[1]*buttonadjust[1]
    move_direction[1] = buttonadjust[0]*user_direction[1] - user_direction[0]*buttonadjust[1]
    move_direction[2] = 0

    velocity[0] += floatround(move_direction[0] * (1.0 * get_cvar_num("amx_hook_moveacc")) * DELTA_T / get_distance(null,move_direction))
    velocity[1] += floatround(move_direction[1] * (1.0 * get_cvar_num("amx_hook_moveacc")) * DELTA_T / get_distance(null,move_direction))
    }
    if (buttonadjust[2] ) {
    hooklength[id] -= floatround(buttonadjust[2] * get_cvar_num("amx_hook_reelspeed") * DELTA_T)
    }
    if (hooklength[id] < 100) {
    (hooklength[id]) = 100 // Minimum (rope) size...
    }

    A[0] = hooklocation[id][0] - user_origin[0]
    A[1] = hooklocation[id][1] - user_origin[1]
    A[2] = hooklocation[id][2] - user_origin[2]

    D[0] = A[0]*A[2] / get_distance(null,A)
    D[1] = A[1]*A[2] / get_distance(null,A)
    D[2] = -(A[1]*A[1] + A[0]*A[0]) / get_distance(null,A)

    //Fixed Below for runtime error
    //acceleration = - get_cvar_num("sv_gravity") * D[2] / get_distance(null,D)

    distance = get_distance(null,D) ? get_distance(null,D) : 1
    acceleration = - global_gravity * D[2] / distance

    velocity_TA = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / get_distance(null,A)
    desired_velocity_TA = (get_distance(user_origin,hooklocation[id]) - hooklength[id] /*- 10*/) * 4

    if (get_distance(null,D)>10) {
    velocity[0] += floatround((acceleration * DELTA_T * D[0]) / get_distance(null,D))
    velocity[1] += floatround((acceleration * DELTA_T * D[1]) / get_distance(null,D))
    velocity[2] += floatround((acceleration * DELTA_T * D[2]) / get_distance(null,D))
    }

    velocity[0] += ((desired_velocity_TA - velocity_TA) * A[0]) / get_distance(null,A)
    velocity[1] += ((desired_velocity_TA - velocity_TA) * A[1]) / get_distance(null,A)
    velocity[2] += ((desired_velocity_TA - velocity_TA) * A[2]) / get_distance(null,A)

    set_entity_velocity(id, velocity)
    }

    //Cheap kids reel from batgirl on shero
    //Cheat Web - just drags you where you shoot it...
    public hookstyle_cheapreel(id) {

    if ( !hooked[id] ) return

    if (!is_user_alive(id)) {
    release(id)
    return
    }

    new velocity[3]
    new user_origin[3]
    new oldvelocity[3]

    get_user_origin(id, user_origin)
    get_entity_velocity(id, oldvelocity)
    new distance = get_distance( hooklocation[id], user_origin )
    if ( distance > 10 ) {
    velocity[0] = floatround( (hooklocation[id][0] - user_origin[0]) * ( 1.0 * get_cvar_num("amx_hook_creelspeed") / distance ) )
    velocity[1] = floatround( (hooklocation[id][1] - user_origin[1]) * ( 1.0 * get_cvar_num("amx_hook_creelspeed") / distance ) )
    velocity[2] = floatround( (hooklocation[id][2] - user_origin[2]) * ( 1.0 * get_cvar_num("amx_hook_creelspeed") / distance ) )
    }
    else {
    velocity[0]=0
    velocity[1]=0
    velocity[2]=0
    }

    set_entity_velocity(id, velocity)
    }

    public hook_on(id){
    if (!get_cvar_num("sv_hook") || hooked[id] || !is_user_alive(id) || roundfreeze || get_user_health(id) < 10)
    return PLUGIN_HANDLED

    new hooks_round_cvar

    if(IsVip[id]) {
    client_print(id,print_chat, "[AMXX] Hooking by the VIP is prohibited.")
    return PLUGIN_HANDLED
    }
    else if(round_delay == 1){
    client_print(id,print_chat, "[AMXX] Hooking during the first 15 seconds of a round is prohibited.")
    return PLUGIN_HANDLED
    }
    if(HkDelay[id] > get_gametime() - HOOK_DELAY)
    return PLUGIN_HANDLED

    HkDelay[id] = get_gametime()
    HookCount[id] +=1
    hooks_round_cvar = get_cvar_num("amx_hooks_round")
    if(HookCount[id] > hooks_round_cvar){
    client_print(id,print_chat, "[AMXX] You are all out of hooks. Wait until next round.")
    return PLUGIN_HANDLED
    }
    else {
    if ((get_cvar_num("amx_rep_hcount") == 1) && (hooks_round_cvar-HookCount[id] < 10)) {
    if(hooks_round_cvar - HookCount[id] == 0)
    client_print(id,print_chat, "[AMXX] That was your last hook for this round.")
    else
    client_print(id,print_chat, "[AMXX] You have %d hooks left, use them wisely.",hooks_round_cvar-HookCount[id])
    }
    }
    attach(id)
    return PLUGIN_HANDLED
    }

    public hook_off(id)
    {
    if (get_cvar_num("sv_hook") && hooked[id])
    release(id)

    return PLUGIN_HANDLED
    }

    public attach(id)
    {
    new parm[2], user_origin[3]
    parm[0] = id
    parm[1] = get_cvar_num("amx_hook_style")
    hooked[id] = true
    get_user_origin(id, user_origin)
    get_user_origin(id, hooklocation[id], 3)
    hooklength[id] = get_distance(hooklocation[id],user_origin)
    global_gravity = get_cvar_num("sv_gravity")
    set_user_gravity(id,0.001)
    beamentpoint(id);
    hookgrab_sound(id);
    set_task(DELTA_T, "hooktask", 200+id, parm, 2, "b")
    boost(id)
    }

    public hookgrab_sound(id){
    emit_sound(id, CHAN_AUTO, HOOK_SOUNDS[random(sizeof(HOOK_SOUNDS))] , VOL_NORM, ATTN_IDLE, 0, PITCH);
    }

    public boost(id)
    {
    new user_origin[3], velocity[3], null[3], A[3]
    get_user_origin(id, user_origin)
    get_entity_velocity(id, velocity)

    null[0] = 0
    null[1] = 0
    null[2] = 0

    A[0] = hooklocation[id][0] - user_origin[0]
    A[1] = hooklocation[id][1] - user_origin[1]
    A[2] = hooklocation[id][2] - user_origin[2]

    velocity[0] += A[0] * BOOSTPOWER / get_distance(null,A)
    velocity[1] += A[1] * BOOSTPOWER / get_distance(null,A)
    velocity[2] += A[2] * BOOSTPOWER / get_distance(null,A)

    set_entity_velocity(id, velocity)
    }

    public release(id)
    {
    hooked[id] = false
    //killbeam(id)
    set_user_gravity(id)
    remove_task(200+id)
    }

    public beamentpoint(id)
    {
    //react_function(id, hooklocation)
    /*
    new lums = random_num(30,400);new time = random_num(3,7);new width = random_num(3,5);
    //HL neon grenade-like trail
    message_begin(0,23);write_byte(TE_BEAMFOLLOW);
    write_short(id);write_short(sprite);
    write_byte(time);write_byte(width);
    write_byte(COLOR);write_byte(COLOR);write_byte(COLOR);
    write_byte(lums);message_end();
    */
    beamcreated[id] = get_gametime()
    set_task_ex(0.1, "Trail_me", id, .flags = SetTask_RepeatTimes, .repeat = 25);
    ///set_task_ex(0.01, "Trail_me", id, .flags = SetTask_RepeatTimes, .repeat = 3); ///.flags = SetTask_Once
    }

    public Trail_me(id){
    /*
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
    write_byte( TE_BEAMENTPOINT )
    write_short( id )
    write_coord( hooklocation[id][0] )
    write_coord( hooklocation[id][1] )
    write_coord( hooklocation[id][2] )
    write_short( beam )   // sprite index
    write_byte( 0 )      // start frame
    write_byte( 0 )      // framerate
    write_byte( BEAMLIFE )   // life
    write_byte( random_num(1,20) )   // width
    if(is_user_admin(id))
    write_byte( random_num(300,3000) )      // noise
    else
    write_byte( 0 )
    write_byte( random_num(20,220) )   // r, g, b
    write_byte( random_num(20,220) )   // r, g, b
    write_byte( random_num(20,235) )   // r, g, b
    write_byte( random_num(50,50) )   // brightness
    write_byte( 0 )      // speed
    message_end( )


    new lums = random_num(3,30);new time = random_num(1,2);new width = random_num(1,2);
    //HL neon grenade-like trail
    message_begin(0,23);write_byte(TE_BEAMFOLLOW);
    write_short(id);write_short(sprite);
    write_byte(time);write_byte(width);
    write_byte(COLOR);write_byte(COLOR);write_byte(COLOR);
    write_byte(lums);message_end();
*/

    emessage_begin( MSG_PVS, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
    ewrite_byte(TE_PLAYERATTACHMENT)
    ewrite_byte(id)
    ewrite_coord(-MAX_AUTHID_LENGTH) //(attachment origin.z = player origin.z + vertical offset)
    ewrite_short(g_model2)   //mdl
    ewrite_short(MAX_IP_LENGTH) //life * 10
    emessage_end();

    new Float:Position[3];

    if(pev_valid(id)){
    ///set_task_ex(0.2, "beamentpoint", id, .flags = SetTask_RepeatTimes, .repeat = 2);
    entity_get_vector(id,EV_VEC_origin,Position);
    entity_get_vector(id,EV_VEC_angles,Axis);
    }

    engfunc(EngFunc_ParticleEffect, Position, Axis, random_float(0.0,255.0),random_float(50.0,1000.0));


    if(!is_valid_ent(id)){
    remove_task(id);
    killbeam(id);
    }
    }

    public killbeam(id)
    {
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
    write_byte( TE_KILLBEAM )
    write_short( id )
    message_end()
    }

    public new_round(id){
    if (hooked[id]) release(id)
    }

    public round_start() {
    if(get_cvar_num("amx_hook_spawndelay") && !round_delay) {
    round_delay = 1
    set_task(15.0,"roundstart_delay")
    }
    roundfreeze = false
    mapbounds_killer()
    }
    public round_end() {
    roundfreeze = true
    for (new i=1; i <= get_maxplayers(); i++) {
    HookCount[i] = 0
    IsVip[i] = 0
    }
    }

    public amx_hc(id,level,cid){
    if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED

    new command[60]
    new variable[6]
    new name[32]
    get_user_name(id,name,31)
    read_argv(0,command,59)
    read_argv(1,variable,5)

    if(get_cvar_num("sv_hook") == 1){
    set_cvar_string("sv_hook","0")
    client_print(id,print_console,"[AMXX] %s has been set turned OFF",command)
    server_print("[AMXX] %s has been set turned OFF",command)
    switch(get_cvar_num("amx_show_activity"))   {
    case 2: client_print(0,print_chat,"ADMIN %s: Executed %s OFF",name,command)
    case 1: client_print(0,print_chat,"ADMIN: Executed %s OFF",command)
    }
    mapbounds_killer()
    }
    else {
    set_cvar_string("sv_hook","1")
    client_print(id,print_console,"[AMXX] %s has been set turned ON.",command)
    server_print("[AMXX] %s has been set turned ON.",command)
    switch(get_cvar_num("amx_show_activity"))   {
    case 2: client_print(0,print_chat,"ADMIN %s: Executed %s ON",name,command)
    case 1: client_print(0,print_chat,"ADMIN: Executed %s ON",command)
    }
    mapbounds_killer()
    }
    return PLUGIN_HANDLED
    }

    public admin_hook_count(id,level,cid){
    if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED

    new arg[8]
    read_argv(1,arg,7)
    if ((str_to_num(arg) > 10000) || (str_to_num(arg) < 1)){
    console_print(id,"[AMXX] Invalid parameter. Must be a number between 1 and 10000")
    return PLUGIN_HANDLED
    }
    new name[32]
    get_user_name(id,name,31)
    console_print(id,"[AMXX] Hook count per round is now %s",arg)
    switch(get_cvar_num("amx_show_activity"))   {
    case 2: client_print(0,print_chat,"ADMIN %s: Executed amx_hook_count %s",name,arg)
    case 1: client_print(0,print_chat,"ADMIN: Executed amx_hook_count %s",arg)
    }
    set_cvar_string("amx_hooks_round",arg)
    return PLUGIN_HANDLED
    }

    public HandleSay(id) {
    new Speech[64]
    read_args(Speech,64)
    remove_quotes(Speech)

    if( (containi(Speech, "vote") == -1) && ((containi(Speech, "hook") != -1) || (containi(Speech, "spider") != -1) || (containi(Speech, "cheat") != -1) || (containi(Speech, "hack") != -1) || (containi(Speech, "swing") != -1) || (containi(Speech, "grap") != -1)))
    {
    if (get_cvar_num("sv_hook"))
    client_print(id,print_chat, "[AMXX] Hook Grab is enabled - For help say /hook")
    else
    client_print(id,print_chat, "[AMXX] Hook Grab is disabled")
    }
    return PLUGIN_CONTINUE
    }

    public roundstart_delay(){
    round_delay = 0
    }

    public client_connect(id){
    HkDelay[id] = 0.0
    HookCount[id] = 0
    hooked[id] = false
    }

    public client_disconnected(id){
    HkDelay[id] = 0.0
    HookCount[id] = 0
    hooked[id] = false

    }

    public mapbounds_killer(){
    if(get_cvar_num("amx_hb_pl_kill") == 0)
    return PLUGIN_CONTINUE

    if (!mapbounds_checked) {
    new nump = get_pluginsnum()
    new filename[64],temp[5]
    for(new i=0;i<nump;++i){
    get_plugin(i,filename,63,temp,4,temp,4,temp,4,temp,4)

    if (equali(filename,"amx_ejl_outofbounds.amx"))
    ob_pl1 = 1
    else if (equali(filename,"out_of_bounds.amx"))
    ob_pl2 = 1
    }
    mapbounds_checked = true
    }

    if (get_cvar_num("sv_hook") == 1) {
    if(ob_pl1 == 1)
    pause("ac","amx_ejl_outofbounds.amx")
    if(ob_pl2 == 1)
    pause("ac","out_of_bounds.amx")
    }
    else {
    if(ob_pl1 == 1)
    unpause("ac","amx_ejl_outofbounds.amx")
    if(ob_pl2 == 1)
    unpause("ac","out_of_bounds.amx")
    }

    return PLUGIN_CONTINUE
    }

    public vip_spawn(id){

    if (get_cvar_num("amx_hook_no_vip")) {
    new inum
    new players[32]
    get_players(players, inum ,"c")
    if(inum > 1){
    IsVip[id] = 1
    }
    }
    return PLUGIN_CONTINUE
    }

    public hook_motd(id){

    new len = 1300
    new buffer[1301]
    new n = 0

    #if !defined NO_STEAM
    if ( cstrike_running() || (is_running("dod") == 1)  )
    n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>")
    #endif
    n += copy( buffer[n],len-n,"To use your hook have to bind a key to: +hook^n^n")

    n += copy( buffer[n],len-n,"In order to bind a key you must open your console and use the bind command: ^n^n")
    n += copy( buffer[n],len-n,"bind ^"key^" ^"command^" ^n^n")

    n += copy( buffer[n],len-n,"In this case the command is ^"+hook^".  Here are some examples:^n^n")
    n += copy( buffer[n],len-n,"    bind f +hook        bind MOUSE3 +hook^n^n")

    n += copy( buffer[n],len-n,"Now whenever you press the that button, it launches your hook.^n")
    n += copy( buffer[n],len-n,"Make sure to hold the key down as long as you want to be on the hook.^n")
    n += copy( buffer[n],len-n,"Release the key when you want to get off of the hook.^n")
    n += copy( buffer[n],len-n,"To make the hook shorter, press your jump button while using the hook.^n")
    n += copy( buffer[n],len-n,"To make the hook longer, press duck while on the hook.^n^n")

    n += copy( buffer[n],len-n,"Hooking has to be enabled for you to use the hook.^n")
    n += copy( buffer[n],len-n,"Under normal circumstances when hook is enabled, vip's in CS cannot use the hook.^n")
    n += copy( buffer[n],len-n,"Also the hook may not be used for the first 15 seconds of a round in CS.^n")

    #if !defined NO_STEAM
    if ( cstrike_running() || (is_running("dod") == 1)  )
    n += copy( buffer[n],len-n,"</pre></body></html>")
    #endif

    show_motd(id,buffer,"Hook Grab Help")
    return PLUGIN_CONTINUE
    }

    //
    //Stocks ripped from xtrafun.inc for AMXx
    //
    //Gets the velocity of an entity */
    stock get_entity_velocity(index, velocity[3]) {
    new Float:vector[3]
    entity_get_vector(index, EV_VEC_velocity, vector)
    FVecIVec(vector, velocity)
    }

    //Sets the velocity of an entity
    stock set_entity_velocity(index, velocity[3]) {
    new Float:vector[3]
    IVecFVec(velocity, vector)
    entity_set_vector(index, EV_VEC_velocity, vector)
    //was sound here
    }

    public react_function(id,hooklocation[][]){
    //emit_sound(id, CHAN_AUTO, "misc/erriewind.wav", VOL_NORM, ATTN_NORM, 0, PITCH);
    ///
    /////////////////////////////////////////////////////////////////////////////////
    new tr;
    new Float:End[3];
    new Origin[3];

    if (is_user_connected(id))
    //pev(id,pev_origin,Origin);
    get_user_origin(id,Origin)
    //if (is_user_connected(id)){get_user_origin(id,Origin,0);}
    //engfunc(EngFunc_TraceToss,hooklocation[id][3],IGNORE_MONSTERS,tr);
    //get_tr2(tr,TR_flPlaneDist,End)
    ///

    new Float:Position[3];

    //if(pev_valid(id)){
    entity_get_vector(id,EV_VEC_origin,Position);
    //entity_get_vector(id,EV_VEC_endpos,Axis);
    //}

    /////////////////////////////////////////////////////////////////////////////////
    new Start,Rate,Life,Width,Noise,Red,Grn,Blu,Bright,Scroll;
    /////////////////////////////////////////////////////////////////////////////////
    Start = 1;
    Rate = 5;
    Life = random_num(5,10);
    Width = random_num(1000,5000);
    Noise = random_num(0,5000);
    Red = random_num(150,255);
    Grn = random_num(100,255);
    Blu = random_num(100,255);
    Bright = random_num(5000,10000);
    Scroll = 1;
    //////////////////////////////////////////////////////////////////////////////////
    message_begin(0, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
/*
    write_coord(floatround(Origin[0]));
    write_coord(floatround(Origin[1]));
    write_coord(floatround(Origin[2]));
*/
    write_coord(floatround(Position[0]));
    write_coord(floatround(Position[1]));
    write_coord(floatround(Position[2]));


    write_coord(hooklocation[id][0]);
    write_coord(hooklocation[id][1]);
    write_coord(hooklocation[id][2]);
/*
    write_coord(floatround(End[0]));
    write_coord(floatround(End[1]));
    write_coord(floatround(End[2]));

    write_coord(floatround(Axis[0]));
    write_coord(floatround(Axis[1]));
    write_coord(floatround(Axis[2]));

    write_coord(floatround(Position[0]));
    write_coord(floatround(Position[1]));
    write_coord(floatround(Position[2]));
*/
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
    ///////////////////////////////////////////////////////////////////////////////////
    //free_tr2(tr)
    //emit_sound(id, CHAN_AUTO, "misc/erriewind.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH);
    return;
    }
