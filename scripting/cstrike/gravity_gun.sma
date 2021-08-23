/********************************************************************************************************
                             AMX Gravity Gun Deathmatch

  Version: 0.3.2
  Author: KRoTaL 
  Amxx port: DJEarthQuake BKA SPINX Sun 22 Aug 2021 06:15:00 AM CDT

  0.1   Release
  0.1.1 Bug fixes
  0.2   Now works like the real HL2 gravity gun with the real sounds :)
  0.2.1 Added Gauss gun model
  0.2.2 Bug fixes
  0.3   Added 2 new settings: ggdm_allweapons + ggdm_damage, + the possibility to grab and throw players
  0.3.1 Fewer objects should stay in the air
  0.3.1 Fewer objects should stay in the air


  Objects will be randomly created on the map (you can configure the models to be used).
  Grab them and throw them at your ennemies to kill them, or throw them directly if you are close to them.
  You cannot use any other weapons.
  To grab an object/player, press the +attack2 button.
  To throw an object/player, press the +attack button.

  IMPORTANT: If your server crashes, try reducing the ggdm_objects setting (especially on small maps).


  Cvars:

  ggdm_active 0   - 0: disables the plugin
                    1: enables the plugin (objects will be created next round)

  ggdm_allweapons 0   - 0: players can only use the gravity gun
                        1: players can use all the weapons, and the knife is replaced with the gravity gun

  ggdm_damage 20    - amount of damage done to a player when you throw him

  ggdm_grabforce 10   - sets the amount of force used when grabbing objects

  ggdm_throwforce 1400  - sets the power of your throws

  ggdm_objects 30   - sets how many objects to create on the map (between 1 and 80)

  ggdm_maxdist 140    - sets how close to an object you need to be to throw it without grabbing it

  ggdm_maxdist_grab 1500  - sets how close to an object you need to be to grab it


  Setup:

  Put these files on your server:

  addons/amx/plugins/gravitygun_dm.amx
  addons/amx/lang/ggdm.txt
  addons/amx/config/ggdm_objects.cfg
  sound/ggdm/ggdm_throw.mp3
  sound/ggdm/ggdm_grab.mp3
  sound/ggdm/ggdm_grabbing.mp3
  sound/ggdm/ggdm_denythrow.mp3
  sound/ggdm/ggdm_denygrab.mp3

  You can configure the models to be used for the objects in the ggdm_objects.cfg file.
  Format:

  path_of_the_model name_of_the_model MinBox(X_axis) MinBox(Y_axis) MinBox(Z_axis) MaxBox(X_axis) MaxBox(Y_axis) MaxBox(Z_axis)

  Examples:

  models/chick.mdl chicken -20 -20 -1 20 20 20
  models/w_weaponbox.mdl weaponbox -12 -12 -1 12 12 40
  models/filecabinet.mdl filecabinet -16 -16 -1 16 16 60
  models/houndeye.mdl houndeye -20 -20 -1 20 20 25
  models/w_flashbang.mdl flashbang -10 -10 -1 10 10 10
  models/w_smokegrenade.mdl smokegrenade -10 -10 -1 10 10 10
  models/w_hegrenade.mdl grenade -10 -10 -1 10 10 10

  The name of the model will be used in the death messages:
  KRoT@L killed T(+)rget with washbasin
  KRoT@L killed T(+)rget with chicken

  If you want to type a space in the name of the model, use quotes:
  models/big_thing.mdl "big thing" -20 -20 -20 20 20 20

  Do not forget to put the models on your server to allow people to download them.

  You need to enable VexdUM.

  Credits:
  SpaceDude for his Jedi Grab Plugin
  Kaddar for his Rune Mod Plugin


********************************************************************************************************/
#define CSTRIKE  //define by removing // in front or putting them back to use this for mods outside CS
#include <amxmodx>
#define strtonum str_to_num
#define is_entity is_valid_ent
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_USER_INFO_LENGTH       256

#include <amxmisc>

#if defined CSTRIKE
#include <cstrike>
#define get_user_money cs_get_user_money
#define set_user_money cs_set_user_money
#endif

#include <engine>
#include <engine_stocks>
#include <fun>
#include <hamsandwich>

//#include <ns2amx>

#define find_entity find_ent

#define KEY_THROW IN_ATTACK
#define KEY_GRAB IN_ATTACK2

#define RESET_OWNER 2.2
#define GRAB_SPEED 30

#define MAX_NAME_LENGTH 32
#define MAX_SPAWNS 81
#define BEHINDBASESIZE 1500

new gMsgDeathMsg

new SPAWN[MAX_SPAWNS][3]
new SPAWNS
new SPAWNS_ENABLED
new OBJECTS_ENABLED

new g_ObjectsNum
new g_Model[MAX_SPAWNS][MAX_RESOURCE_PATH_LENGTH], g_ModelName[MAX_SPAWNS][MAX_NAME_LENGTH]
new g_MinX[MAX_SPAWNS], g_MinY[MAX_SPAWNS], g_MinZ[MAX_SPAWNS]
new g_MaxX[MAX_SPAWNS], g_MaxY[MAX_SPAWNS], g_MaxZ[MAX_SPAWNS]

new grabbed[MAX_NAME_LENGTH + 1]
new grablength[MAX_PLAYERS + 1]
new grabbing_player[MAX_PLAYERS + 1]
new velocity_multiplier

new bool:wait_denygrab[MAX_NAME_LENGTH + 1]
new bool:wait_denythrow[MAX_NAME_LENGTH + 1]
new bool:active=false

new GRAVGUN_VMODEL[MAX_RESOURCE_PATH_LENGTH] = "models/v_gauss.mdl"
new GRAVGUN_PMODEL[MAX_RESOURCE_PATH_LENGTH] = "models/p_gauss.mdl"
new g_active,g_all,g_damage,g_grab,g_throw,g_objects,g_dist,g_dist_max

public plugin_init()
{
  register_library("ggdm") 
  register_plugin("Gravity Gun DeathMatch", "0.3.2", "KRoTaL")
  g_active   = register_cvar("ggdm_active","1")
  g_all      = register_cvar("ggdm_allweapons","1")
  g_damage   = register_cvar("ggdm_damage","20")
  g_grab     = register_cvar("ggdm_grabforce","10")
  g_throw    = register_cvar("ggdm_throwforce","1400")
  g_objects  = register_cvar("ggdm_objects","30")
  g_dist     = register_cvar("ggdm_maxdist","140")
  g_dist_max = register_cvar("ggdm_maxdist_grab","1500")
  register_clcmd("say","handle_say")
  register_clcmd("say_team","handle_say")

  register_event("CurWeapon","switchweapon","be","1=1")

  //register_event("ResetHUD","reset_hud","b")
  RegisterHam(Ham_Spawn, "player", "reset_hud", 1);
  
  register_event("DeathMsg","death_event","a")

  register_touch("player","*", "gg_gun_touch")

  if(cstrike_running())
  {
    register_logevent("roundstart", 2, "0=World triggered", "1=Round_Start")
    register_logevent("endround", 2, "0=World triggered", "1=Round_End")
  }
  else
    roundstart()

  gMsgDeathMsg = get_user_msgid("DeathMsg")
  set_task(0.5, "createSpawns", 0, "", 0)
}

//public plugin_cfg()
//  if(!cstrike_running())
//    roundstart()


public ggdm_help(id)
{
  set_hudmessage(255, 255, 255, -1.0, 0.67, 0, 0.01, 12.0, 0.01, 0.01, 2)
  show_hudmessage(id, "WELCOME TO GRAVITY GUN DEATHMATCH!^nPRESS +ATTACK2 BUTTON TO GRAB AN OBJECT.^nPRESS +ATTACK BUTTON TO THROW IT AT YOUR ENNEMIES AND KILL THEM.^nYou can throw an object without grabbing it if you are close to it.^nYou can also grab and throw players.") //setlang

  return PLUGIN_CONTINUE
}

public handle_say(id)
{
  if(active)
  {
    new said[192]
    read_args(said,192)
    remove_quotes(said)

    if( (containi(said, "ggdm") != -1) || (containi(said, "gravity") != -1) )
    {
      ggdm_help(id)
    }
  }

  return PLUGIN_CONTINUE
}

public reset_hud(id)
{
  if(active && is_user_alive(id))
  {
    if(task_exists(11111+id))
      remove_task(11111+id)
    if(task_exists(33333+id))
      remove_task(33333+id)
    client_cmd(id, "mp3 stop")
    //set_user_godmode(id, 0)
    entity_set_edict(id, EV_ENT_owner, 33)
  }

  if(!get_pcvar_num(g_active) || SPAWNS_ENABLED == 0 || OBJECTS_ENABLED == 0)
    return PLUGIN_CONTINUE

  grabbed[id]=0
  grabbing_player[id]=0
  wait_denygrab[id]=false
  wait_denythrow[id]=false
  entity_set_edict(id, EV_ENT_owner, 33)
  /*
  if(!get_pcvar_num(g_all))
    set_user_godmode(id, 0)*/
  new ids[1]
  ids[0]=id
  set_task(0.1, "detect_key", 11111+id, ids, 1, "b")

  return PLUGIN_CONTINUE
}

public death_event()
{
  if(active)
  {
    new id = read_data(2)
    if(task_exists(11111+id))
      remove_task(11111+id)
    if(task_exists(33333+id))
      remove_task(33333+id)
    if(grabbed[id])
      entity_set_edict(grabbed[id], EV_ENT_owner, 33)
    grabbed[id]=0
    grabbing_player[id]=0
    wait_denygrab[id]=false
    wait_denythrow[id]=false
    client_cmd(id, "mp3 stop")
  }

  return PLUGIN_CONTINUE
}

public client_kill(id)
{
  if(active)
  {
    if(task_exists(11111+id))
      remove_task(11111+id)
    if(task_exists(33333+id))
      remove_task(33333+id)
    if(grabbed[id])
      entity_set_edict(grabbed[id], EV_ENT_owner, 33)
    grabbed[id]=0
    grabbing_player[id]=0
    wait_denygrab[id]=false
    wait_denythrow[id]=false
    client_cmd(id, "mp3 stop")
  }

  return PLUGIN_CONTINUE
}

public switchweapon(id)
{
  if(is_user_alive(id) && is_user_bot(id) || !is_user_bot(id))
  {
      if(!get_pcvar_num(g_active) || SPAWNS_ENABLED == 0 || OBJECTS_ENABLED == 0)
        return PLUGIN_CONTINUE
      new weap[MAX_NAME_LENGTH]
    
      if(cstrike_running())
        weap = "weapon_knife"
      else
        weap = "weapon_crowbar"
    
      if(get_pcvar_num(g_all))
      {
        client_cmd(id, weap)
        entity_set_string(id, EV_SZ_viewmodel, GRAVGUN_VMODEL)
        entity_set_string(id, EV_SZ_weaponmodel, GRAVGUN_PMODEL)
      }
      else
      {
        new plrClip, plrAmmo, plrWeapId = get_user_weapon(id, plrClip, plrAmmo)
        if (cstrike_running() ? plrWeapId == CSW_KNIFE : plrWeapId == HLW_CROWBAR)
        {
          entity_set_string(id, EV_SZ_viewmodel, GRAVGUN_VMODEL)
          entity_set_string(id, EV_SZ_weaponmodel, GRAVGUN_PMODEL)
        }
        else
        {
          if(grabbed[id])
          {
            client_cmd(id, "mp3 stop")
            client_cmd(id, "mp3 play ^"sound\ggdm\ggdm_throw.mp3^"")
            if(task_exists(33333+id))
              remove_task(33333+id)
            wait_denythrow[id]=false
            new Float:pVelocity[3]
            VelocityByAim(id,get_pcvar_num(g_throw),pVelocity)
            entity_set_vector(grabbed[id],EV_VEC_velocity,pVelocity)
            new entity[1]
            entity[0]=grabbed[id]
            set_task(RESET_OWNER, "reset_owner", 22222+grabbed[id], entity, 1)
            grabbed[id]=0
          }
    
          return PLUGIN_CONTINUE
        }
      }
  }
  return PLUGIN_CONTINUE
}

public roundstart()
{
  if(!get_pcvar_num(g_active))
  {
    remove_objects()
    active=false
  }
  else
  {
    if(/*SPAWNS_ENABLED == 1 && */OBJECTS_ENABLED == 1)
    {
      //spawn_objects()
      set_hudmessage(255, 255, 255, -1.0, 0.67, 0, 0.01, 15.0, 0.01, 0.01, 2)
      show_hudmessage(0, "WELCOME TO GRAVITY GUN DEATHMATCH!^nPRESS +ATTACK2 BUTTON TO GRAB AN OBJECT.^nPRESS +ATTACK BUTTON TO THROW IT AT YOUR ENNEMIES AND KILL THEM.^nYou can throw an object without grabbing it if you are close to it.^nYou can also grab and throw players.")
      show_hudmessage(0, "WELCOME TO GRAVITY GUN DEATHMATCH!^nPRESS +ATTACK2 BUTTON TO GRAB AN OBJECT.^nPRESS +ATTACK BUTTON TO THROW IT AT YOUR ENNEMIES AND KILL THEM.^nYou can throw an object without grabbing it if you are close to it.^nYou can also grab and throw players.")
      active=true
    }
    else
    {
      //if(SPAWNS_ENABLED == 0)
      //  console_print(0, "[Gravity Gun DeathMatch] OBJECTS WILL NOT SPAWN.")
      if(OBJECTS_ENABLED == 0)
        console_print(0, "[Gravity Gun DeathMatch] YOU NEED TO CONFIGURE THE OBJECTS TO BE SPAWNED.")
      active=false
    }
  }

  return PLUGIN_CONTINUE
}

public endround()
{
  if(active)
  {
    set_task(4.0, "remove_objects", 99999, "", 0)
  }

  return PLUGIN_CONTINUE
}

spawn_objects()
{
  for(new i = 0;i < SPAWNS; i++ )
  {
    new randomizer = random(SPAWNS)
    if(randomizer != i)
    {
      new temp[3]
      temp[0] = SPAWN[i][0]
      temp[1] = SPAWN[i][1]
      temp[2] = SPAWN[i][2]
      SPAWN[i][0] = SPAWN[randomizer][0]
      SPAWN[i][1] = SPAWN[randomizer][1]
      SPAWN[i][2] = SPAWN[randomizer][2]
      SPAWN[randomizer][0] = temp[0]
      SPAWN[randomizer][1] = temp[1]
      SPAWN[randomizer][2] = temp[2]
    }
  }

  remove_objects()

  new objects=get_pcvar_num(g_objects)
  if(objects<1)
    objects=1
  if(objects>80)
    objects=80

  for(new i = 0; i < objects; i++)
  {
    new NewObject = create_entity("info_target")
    if(NewObject <= 0) {
      console_print(0,"[Gravity Gun DeathMatch] OBJECT GENERATION FAILED.")
      return PLUGIN_HANDLED_MAIN
    }

    new Float:temporg[3]
    temporg[0] = float(SPAWN[i][0])
    temporg[1] = float(SPAWN[i][1])
    temporg[2] = float(SPAWN[i][2] + MAX_NAME_LENGTH)

    new randObject = random_num(0, g_ObjectsNum)

    entity_set_string(NewObject, EV_SZ_classname, "entObject")
    entity_set_model(NewObject, g_Model[randObject])
    entity_set_origin(NewObject, temporg)
    entity_set_edict(NewObject, EV_ENT_owner, 33)
    entity_set_int(NewObject, EV_INT_iuser4, randObject)
    entity_set_int(NewObject, EV_INT_solid, 2)
    entity_set_int(NewObject, EV_INT_movetype, 10)
    entity_set_float(NewObject, EV_FL_gravity, 1.0)
    entity_set_float(NewObject, EV_FL_friction, 0.66)

    new Float:MinBox[3], Float:MaxBox[3]
    MinBox[0]=float(g_MinX[randObject])
    MinBox[1]=float(g_MinY[randObject])
    MinBox[2]=float(g_MinZ[randObject])
    MaxBox[0]=float(g_MaxX[randObject])
    MaxBox[1]=float(g_MaxY[randObject])
    MaxBox[2]=float(g_MaxZ[randObject])

    entity_set_size(NewObject, MinBox, MaxBox)

    new Float:velocity[3]
    velocity[0] = float(random(256)-128)
    velocity[1] = float(random(256)-128)
    velocity[2] = float(random(300)+75)
    entity_set_vector(NewObject, EV_VEC_velocity,velocity)
  }

  return PLUGIN_CONTINUE
}

public remove_objects()
{
  new nextitem  = find_entity(-1,"entObject")
  while(nextitem > 0)
  {
    remove_entity(nextitem)
    nextitem = find_entity(-1,"entObject")
  }

  return PLUGIN_CONTINUE
}

public gg_gun_touch(ptr, ptd)
{
  new entity1, entity2
  ptr = entity1
  ptd = entity2
  if(active)
    return PLUGIN_CONTINUE

  if(entity1 > 0 && is_entity(entity1) && entity2 > 0 && is_entity(entity2))
  {
    new itemClassName[MAX_NAME_LENGTH]
    new playerClassname[MAX_NAME_LENGTH]
    entity_get_string(entity1, EV_SZ_classname, itemClassName, MAX_NAME_LENGTH-1)
    entity_get_string(entity2, EV_SZ_classname, playerClassname, MAX_NAME_LENGTH-1)
    if(equal(itemClassName,"entObject") && equal(playerClassname,"player"))
    {
      new killer=entity_get_edict(entity1, EV_ENT_owner)-33
      if(!killer || killer==entity2 || grabbed[killer])
        return PLUGIN_CONTINUE

      if(get_cvar_num("mp_friendlyfire") == 0 && get_user_team(killer) == get_user_team(entity2))
        return PLUGIN_CONTINUE

      //set_user_godmode(entity2, 1)
      emit_sound(entity2, CHAN_BODY, "player/headshot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
      set_msg_block(gMsgDeathMsg, BLOCK_SET)
      set_user_health(entity2, 0)
      set_msg_block(gMsgDeathMsg, BLOCK_NOT)
      log_kill(killer, entity2, g_ModelName[entity_get_int(entity1, EV_INT_iuser4)])
#if defined CSTRIKE
      if(get_user_team(killer) != get_user_team(entity2))
      {
        set_user_frags(entity2, get_user_frags(entity2) + 1)
        set_user_frags(killer, get_user_frags(killer) + 1)
        new money = get_user_money(killer)
        if(money < 16000)
          set_user_money(killer, money + 300)
      }
      else
      {
        set_user_frags(entity2, get_user_frags(entity2) + 1)
        set_user_frags(killer, get_user_frags(killer) - 2)
        new money = get_user_money(killer)
        if (money != 0)
          set_user_money(killer, money - 150)
      }
#endif
      message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0}, 0)
      write_byte(killer)
      write_byte(entity2)
      write_byte(0)
      write_string(g_ModelName[entity_get_int(entity1, EV_INT_iuser4)])
      message_end()

      entity_set_edict(entity1, EV_ENT_owner, 33)
      entity_set_vector(entity1, EV_VEC_velocity, Float:{0,0,0})
    }
  }

  return PLUGIN_CONTINUE
}

public log_kill(killer, victim, weapon[])
{
  new kname[MAX_NAME_LENGTH], vname[MAX_NAME_LENGTH], kauthid[MAX_NAME_LENGTH], vauthid[MAX_NAME_LENGTH], kteam[10], vteam[10]

  get_user_name(killer, kname, 31)
  get_user_team(killer, kteam, 9)
  get_user_authid(killer, kauthid, 31)

  get_user_name(victim, vname, 31)
  get_user_team(victim, vteam, 9)
  get_user_authid(victim, vauthid, 31)

  log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
  kname, get_user_userid(killer), kauthid, kteam,
  vname, get_user_userid(victim), vauthid, vteam, weapon)
}

public extra_damage(killer, victim)
{
  if(get_cvar_num("mp_friendlyfire") == 0 && get_user_team(killer) == get_user_team(victim))
    return PLUGIN_CONTINUE

  new health = get_user_health(victim) - get_pcvar_num(g_damage)

  if(health > 0)
  {
    //set_user_godmode(victim, 1)
    set_user_health(victim, health)
    /*if(!get_pcvar_num(g_all))
      set_user_godmode(victim, 1)*/
  }
  else
  {
    //set_user_godmode(victim, 0)
    emit_sound(victim, CHAN_BODY, "player/headshot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_msg_block(gMsgDeathMsg, BLOCK_SET)
    set_user_health(victim, 0)
    set_msg_block(gMsgDeathMsg, BLOCK_NOT)
    log_kill(killer, victim, "throw")
#if defined CSTRIKE
    if(get_user_team(killer) != get_user_team(victim))
    {
      set_user_frags(victim, get_user_frags(victim) + 1)
      set_user_frags(killer, get_user_frags(killer) + 1)
      new money = get_user_money(killer)
      if(money < 16000)
        set_user_money(killer, money + 300)
    }
    else
    {
      set_user_frags(victim, get_user_frags(victim) + 1)
      set_user_frags(killer, get_user_frags(killer) - 2)
      new money = get_user_money(killer)
      if (money != 0)
        set_user_money(killer, money - 150)
    }
#endif
    message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0}, 0)
    write_byte(killer)
    write_byte(victim)
    write_byte(0)
    write_string("throw")
    message_end()
  }

  return PLUGIN_CONTINUE
}

public detect_key(player[])
{
  new id=player[0]

  new plrClip, plrAmmo, plrWeapId = get_user_weapon(id, plrClip, plrAmmo)
  if (plrWeapId != CSW_KNIFE)
    return PLUGIN_CONTINUE

  new button = entity_get_int(id, EV_INT_button)
  if(grabbed[id])
  {
    if(button & KEY_THROW)
    {
      client_cmd(id, "mp3 stop")
      client_cmd(id, "mp3 play ^"sound\ggdm\ggdm_throw.mp3^"")
      if(task_exists(33333+id))
        remove_task(33333+id)
      wait_denythrow[id]=true
      new ids[1]
      ids[0]=id
      set_task(1.5, "reset_denythrow", 55555+id, ids, 1)
      new Float:pVelocity[3]
      VelocityByAim(id,get_pcvar_num(g_throw),pVelocity)
      entity_set_vector(grabbed[id],EV_VEC_velocity,pVelocity)
      new entity[1]
      entity[0]=grabbed[id]
      set_task(RESET_OWNER, "reset_owner", 22222+grabbed[id], entity, 1)
      if(grabbed[id] > 0 && grabbed[id] < 33)
        extra_damage(id, grabbed[id])
      grabbed[id]=0

      return PLUGIN_CONTINUE
    }
    new origin[3], look[3], direction[3], moveto[3], Float:grabbedorigin[3], Float:velocity[3], length
    get_user_origin(id, origin, 1)
    get_user_origin(id, look, 3)
    entity_get_vector(grabbed[id], EV_VEC_origin, grabbedorigin)

    direction[0]=look[0]-origin[0]
    direction[1]=look[1]-origin[1]
    direction[2]=look[2]-origin[2]
    length = get_distance(look,origin)
    if (!length) length=1 // avoid division by 0

    moveto[0]=origin[0]+direction[0]*grablength[id]/length
    moveto[1]=origin[1]+direction[1]*grablength[id]/length
    moveto[2]=origin[2]+direction[2]*grablength[id]/length

    velocity[0]=(moveto[0]-grabbedorigin[0])*velocity_multiplier
    velocity[1]=(moveto[1]-grabbedorigin[1])*velocity_multiplier
    velocity[2]=(moveto[2]-grabbedorigin[2])*velocity_multiplier

    entity_set_vector(grabbed[id], EV_VEC_velocity, velocity)
  }
  else
  {
    if(button & KEY_GRAB)
    {
      new targetid, body
      get_user_aiming(id, targetid, body)
      if (targetid)
      {
        new itemClassName[MAX_NAME_LENGTH]
        entity_get_string(targetid, EV_SZ_classname, itemClassName, MAX_NAME_LENGTH-1)
        if(equal(itemClassName,"entObject") || equal(itemClassName,"player"))
        {
          new owner=entity_get_edict(targetid, EV_ENT_owner)-33
          if(owner>0 && grabbed[owner]==targetid)
            return PLUGIN_CONTINUE
          if(equal(itemClassName,"player"))
          {
            if(grabbing_player[targetid]==id || grabbed[targetid]==id)
              return PLUGIN_CONTINUE
          }
          new origin1[3], origin2[3], Float:forigin2[3]
          get_user_origin(id, origin1)
          entity_get_vector(targetid, EV_VEC_origin, forigin2)
          FVecIVec(forigin2, origin2)
          new length = get_distance(origin1,origin2)
          if(length < get_pcvar_num(g_dist_max))
          {
            if(length < get_pcvar_num(g_dist))
            {
              set_grabbed(id, targetid)
            }
            else
            {
              new origin[3], look[3], direction[3], moveto[3], Float:grabbedorigin[3], Float:velocity[3]
              get_user_origin(id, origin, 1)
              get_user_origin(id, look, 3)
              entity_get_vector(targetid, EV_VEC_origin, grabbedorigin)

              direction[0]=look[0]-origin[0]
              direction[1]=look[1]-origin[1]
              length = get_distance(look,origin)
              if (!length) length=1 // avoid division by 0

              grablength[id] = length - GRAB_SPEED
              velocity_multiplier = get_pcvar_num(g_grab)

              moveto[0]=origin[0]+direction[0]*grablength[id]/length
              moveto[1]=origin[1]+direction[1]*grablength[id]/length

              velocity[0]=(moveto[0]-grabbedorigin[0])*velocity_multiplier
              velocity[1]=(moveto[1]-grabbedorigin[1])*velocity_multiplier
              velocity[2]=4.0

              entity_set_vector(targetid, EV_VEC_velocity, velocity)
            }
          }
        }
      }
      else if(!wait_denygrab[id])
      {
        //client_cmd(id, "mp3 stop")
        client_cmd(id, "mp3 play ^"sound\ggdm\ggdm_denygrab.mp3^"")
        wait_denygrab[id]=true
        new ids[1]
        ids[0]=id
        set_task(1.4, "reset_denygrab", 44444+id, ids, 1)
      }
      return PLUGIN_CONTINUE
    }
    else
    {
      grabbing_player[id]=0
    }
    if(button & KEY_THROW)
    {
      new targetid, body
      get_user_aiming(id, targetid, body)
      if (targetid)
      {
        new itemClassName[MAX_NAME_LENGTH]
        entity_get_string(targetid, EV_SZ_classname, itemClassName, MAX_NAME_LENGTH-1)
        if(equal(itemClassName,"entObject") || equal(itemClassName,"player"))
        {
          new owner=entity_get_edict(targetid, EV_ENT_owner)-33
          if(owner>0 && grabbed[owner]==targetid)
            return PLUGIN_CONTINUE
          if(equal(itemClassName,"player"))
          {
            if(grabbing_player[targetid]==id || grabbed[targetid]==id)
              return PLUGIN_CONTINUE
          }
          new origin1[3], origin2[3], Float:forigin2[3]
          get_user_origin(id, origin1)
          entity_get_vector(targetid, EV_VEC_origin, forigin2)
          FVecIVec(forigin2, origin2)
          new length = get_distance(origin1,origin2)
          if(length < get_pcvar_num(g_dist))
          {
            client_cmd(id, "mp3 stop")
            client_cmd(id, "mp3 play ^"sound\ggdm\ggdm_throw.mp3^"")
            wait_denythrow[id]=true
            new ids[1]
            ids[0]=id
            set_task(1.4, "reset_denythrow", 55555+id, ids, 1)
            new Float:pVelocity[3]
            VelocityByAim(id,get_pcvar_num(g_throw),pVelocity)
            entity_set_vector(targetid,EV_VEC_velocity,pVelocity)
            entity_set_edict(targetid, EV_ENT_owner, id+33)
            new entity[1]
            entity[0]=targetid
            if(task_exists(22222+targetid))
              remove_task(22222+targetid)
            set_task(RESET_OWNER, "reset_owner", 22222+targetid, entity, 1)
            if(targetid > 0 && targetid < 33)
              extra_damage(id, targetid)
          }
        }
      }
      else if(!wait_denythrow[id])
      {
        //client_cmd(id, "mp3 stop")
        client_cmd(id, "mp3 play ^"sound\ggdm\ggdm_denythrow.mp3^"")
        wait_denythrow[id]=true
        new ids[1]
        ids[0]=id
        set_task(1.0, "reset_denythrow", 55555+id, ids, 1)
      }
      return PLUGIN_CONTINUE
    }
  }

  return PLUGIN_CONTINUE
}

public set_grabbed(id, targetid)
{
  //client_cmd(id, "mp3 stop")
  client_cmd(id, "mp3 play ^"sound\ggdm\ggdm_grab.mp3^"")
  if(task_exists(22222+targetid))
    remove_task(22222+targetid)
  grabbed[id]=targetid
  grablength[id]=80
  entity_set_edict(targetid, EV_ENT_owner, id+33)
  new ids[1]
  ids[0]=id
  set_task(2.0, "loop_grabbing_sound", 33333+id, ids, 1)
}

public loop_grabbing_sound(ids[])
{
  client_cmd(ids[0], "mp3 loop ^"sound\ggdm\ggdm_grabbing.mp3^"")
}

public reset_denythrow(ids[])
{
  wait_denythrow[ids[0]]=false
}

public reset_denygrab(ids[])
{
  wait_denygrab[ids[0]]=false
}

public reset_owner(entity[])
{
  entity_set_edict(entity[0], EV_ENT_owner, 33)
}

public createSpawns() //taken from Bail's Root Plugin
{
  SPAWNS = 0
  new ctbase_id
  new tbase_id
  new Float:base_origin_temp[3]
  new Float:ctbase_origin[3] = {0.0,...}
  new Float:tbase_origin[3] = {0.0,...}
  new Float:pspawncounter

  pspawncounter = 0.0
  //ctbase_id = find_entity(-1,"info_player_start")
  ctbase_id = find_ent_by_class(-1,"info_player_start")
  while (ctbase_id > 0)
  {
    pspawncounter +=1.0
    entity_get_vector (ctbase_id,EV_VEC_origin,base_origin_temp)
    ctbase_origin[0] += base_origin_temp[0]
    ctbase_origin[1] += base_origin_temp[1]
    ctbase_origin[2] += base_origin_temp[2]
    //ctbase_id = find_entity(ctbase_id,"info_player_start")
    ctbase_id = find_ent_by_class(ctbase_id,"info_player_start")
  }

  ctbase_origin[0] = ctbase_origin[0] / pspawncounter
  ctbase_origin[1] = ctbase_origin[1] / pspawncounter
  ctbase_origin[2] = ctbase_origin[2] / pspawncounter

  pspawncounter = 0.0
 //tbase_id = find_entity(-1,"info_player_deathmatch")
  tbase_id = find_ent_by_class(-1,"info_player_deathmatch")
  while (tbase_id > 0)
  {
    pspawncounter +=1.0
    entity_get_vector (tbase_id,EV_VEC_origin,base_origin_temp)
    tbase_origin[0] += base_origin_temp[0]
    tbase_origin[1] += base_origin_temp[1]
    tbase_origin[2] += base_origin_temp[2]
    //tbase_id = find_entity(tbase_id,"info_player_deathmatch")
    tbase_id = find_ent_by_class(tbase_id,"info_player_deathmatch")
  }

  tbase_origin[0] = tbase_origin[0] / pspawncounter
  tbase_origin[1] = tbase_origin[1] / pspawncounter
  tbase_origin[2] = tbase_origin[2] / pspawncounter


  new Float:ia[3]
  new Float:square_o1[3]
  new Float:square_o2[3]
  if(tbase_origin[0]>ctbase_origin[0])
  {
    square_o1[0] = tbase_origin[0]+BEHINDBASESIZE
    square_o2[0] = ctbase_origin[0]-BEHINDBASESIZE
  }
  else
  {
    square_o1[0] = ctbase_origin[0]+BEHINDBASESIZE
    square_o2[0] = tbase_origin[0]-BEHINDBASESIZE
  }
  if(tbase_origin[1]>ctbase_origin[1])
  {
    square_o1[1] = tbase_origin[1]+BEHINDBASESIZE
    square_o2[1] = ctbase_origin[1]-BEHINDBASESIZE
  }
  else
  {
    square_o1[1] = ctbase_origin[1]+BEHINDBASESIZE
    square_o2[1] = tbase_origin[1]-BEHINDBASESIZE
  }
  if(tbase_origin[2]>ctbase_origin[2])
  {
    square_o1[2] = tbase_origin[2]+1000
    square_o2[2] = ctbase_origin[2]-1000
  }
  else
  {
    square_o1[2] = ctbase_origin[2]+1000
    square_o2[2] = tbase_origin[2]-1000
  }


  new bool:xyused[11][11]
  new Float:xadd = (square_o1[0]-square_o2[0]) / 9.0
  new Float:yadd = (square_o1[1]-square_o2[1]) / 9.0
  new Float:zadd = (square_o1[2]-square_o2[2]) / 9.0

  new bool:baseswitcher = true
  new countery = 0
  for(ia[1]=square_o2[1];ia[1] <=square_o1[1] && SPAWNS<MAX_SPAWNS;ia[1]+=yadd)
  {
    new counterx = 0
    countery++
    for(ia[0]=square_o2[0];ia[0] <=square_o1[0] && SPAWNS<MAX_SPAWNS;ia[0]+=xadd)
    {
      counterx++
      if(baseswitcher)
      {
        ia[2] = ctbase_origin[2]+16.0
        baseswitcher = false
      }
      else
      {
        ia[2] = tbase_origin[2]+16.0
        baseswitcher = true
      }
      ia[0] = float(floatround(ia[0]) + random(130)-65)
      ia[1] = float(floatround(ia[1]) + random(130)-65)
      ia[2] = float(floatround(ia[2]))
      if( PointContents(ia) == CONTENTS_EMPTY && !xyused[counterx][countery])
      {
        xyused[counterx][countery] = true
        SPAWNS++
        SPAWN[SPAWNS][0] = floatround(ia[0])
        SPAWN[SPAWNS][1] = floatround(ia[1])
        SPAWN[SPAWNS][2] = floatround(ia[2])
      }
    }
  }


  for(ia[2]=(ctbase_origin[2] + tbase_origin[2] ) /2.0;ia[2] <=square_o1[2] && SPAWNS<MAX_SPAWNS;ia[2]+=zadd)
  {

    countery = 0
    for(ia[1]=square_o2[1];ia[1] <=square_o1[1] && SPAWNS<MAX_SPAWNS;ia[1]+=yadd)
    {
      new counterx = 0
      countery++
      for(ia[0]=square_o2[0];ia[0] <=square_o1[0] && SPAWNS<MAX_SPAWNS;ia[0]+=xadd)
      {
        counterx++
        ia[0] = float(floatround(ia[0]) + random(130)-65)
        ia[1] = float(floatround(ia[1]) + random(130)-65)
        ia[2] = float(floatround(ia[2]))

        if( PointContents(ia) == CONTENTS_EMPTY && !xyused[counterx][countery])
        {
          xyused[counterx][countery] = true
          SPAWNS++
          SPAWN[SPAWNS][0] = floatround(ia[0])
          SPAWN[SPAWNS][1] = floatround(ia[1])
          SPAWN[SPAWNS][2] = floatround(ia[2])
        }

      }
    }
  }

  for(ia[2]=(ctbase_origin[2] + tbase_origin[2] ) /2.0;ia[2] >=square_o2[1] && SPAWNS<MAX_SPAWNS;ia[2]-=zadd)
  {

    countery = 0
    for(ia[1]=square_o2[1];ia[1] <=square_o1[1] && SPAWNS<MAX_SPAWNS;ia[1]+=yadd)
    {
      new counterx = 0
      countery++
      for(ia[0]=square_o2[0];ia[0] <=square_o1[0] && SPAWNS<MAX_SPAWNS;ia[0]+=xadd)
      {
        counterx++
        ia[0] = float(floatround(ia[0]) + random(130)-65)
        ia[1] = float(floatround(ia[1]) + random(130)-65)
        ia[2] = float(floatround(ia[2]))

        if( PointContents(ia) != 0.0 && PointContents(ia) == CONTENTS_EMPTY && !xyused[counterx][countery])
        {
          xyused[counterx][countery] = true
          SPAWNS++
          SPAWN[SPAWNS][0] = floatround(ia[0])
          SPAWN[SPAWNS][1] = floatround(ia[1])
          SPAWN[SPAWNS][2] = floatround(ia[2])
        }

      }
    }
  }

  if(SPAWNS > 0)
    SPAWNS_ENABLED = 1
  else
    SPAWNS_ENABLED = 0

  return PLUGIN_CONTINUE
}

public plugin_precache()
{
  g_ObjectsNum = 0
  new ggdm_config[MAX_RESOURCE_PATH_LENGTH]
  get_basedir(ggdm_config, charsmax(ggdm_config))
  format(ggdm_config, charsmax(ggdm_config), "%s/configs/ggdm_objects.cfg", ggdm_config)

  if(file_exists(ggdm_config))
  {
    new text[MAX_USER_INFO_LENGTH], Xmin[12], Ymin[12], Zmin[12], Xmax[12], Ymax[12], Zmax[12]
    new len, pos=0

    while(g_ObjectsNum < MAX_SPAWNS && read_file(ggdm_config,pos++,text,charsmax(text),len))
    {
      if(text[0] == ';') continue
      if(parse(text, g_Model[g_ObjectsNum], charsmax(g_Model[]), g_ModelName[g_ObjectsNum], charsmax(g_ModelName[]),
      Xmin, charsmax(Xmin), Ymin, charsmax(Ymin), Zmin, charsmax(Zmin), Xmax, charsmax(Xmax), Ymax, charsmax(Ymax), Zmax, charsmax(Zmax)) < 8 ) continue
      g_MinX[g_ObjectsNum]=strtonum(Xmin)
      g_MinY[g_ObjectsNum]=strtonum(Ymin)
      g_MinZ[g_ObjectsNum]=strtonum(Zmin)
      g_MaxX[g_ObjectsNum]=strtonum(Xmax)
      g_MaxY[g_ObjectsNum]=strtonum(Ymax)
      g_MaxZ[g_ObjectsNum]=strtonum(Zmax)
      format(g_Model[g_ObjectsNum], charsmax(g_Model[]), "%s", g_Model[g_ObjectsNum])
      precache_model(g_Model[g_ObjectsNum])
      ++g_ObjectsNum
    }
  }

  if(g_ObjectsNum > 0)
    OBJECTS_ENABLED = 1
  else
    OBJECTS_ENABLED = 0

  precache_model(GRAVGUN_VMODEL)
  precache_model(GRAVGUN_PMODEL)
  precache_sound("player/headshot1.wav")

  precache_generic("sound/ggdm/ggdm_throw.mp3")
  precache_generic("sound/ggdm/ggdm_grab.mp3")
  precache_generic("sound/ggdm/ggdm_grabbing.mp3")
  precache_generic("sound/ggdm/ggdm_denythrow.mp3")
  precache_generic("sound/ggdm/ggdm_denygrab.mp3")
}
