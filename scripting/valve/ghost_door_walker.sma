#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_stocks>
#include fakemeta_util //kv
#include <fun>
#include <engine>
#include <hamsandwich>
#include <xs>
#define PLUGIN "Ghost Door Walker"
#define VERSION "1.1"
#define AUTHOR "SPiNX"

#define g_fbox 100.0 //security key hitbox
#define g_packHP                   15
#define MAX_IP_LENGTH              16
#define MAX_PLAYERS                32
//Base plugin is from Xalus Walk through walls. Interchangeable cvars.
///Idea from Castlewolfenstein on Apple II.
new bool:g_bHasKey[ MAX_PLAYERS + 1 ], bool:g_bHasKey2[ MAX_PLAYERS + 1 ], g_key;
new g_target_name
new Float:g_flDelay[ MAX_PLAYERS + 1 ];
new /*g_model,*/ g_model2;
new g_cvarDistance, g_cvarFalldistance, g_cvarButton, g_cvarDelay, g_cvarMessages;
//new g_Ent, g_Ent1, g_Ent2, g_Ent3, g_Ent4, g_Ent5;
new const SzClass[][] =
{
    "player", "func_breakable", "momentary_door",
    "func_healthcharger", "func_recharge",
    "func_door", "func_door_rotating",
    "func_wall","func_wall_toggle",
    "worldspawn", "func_pushable", "momentary_door"
}; //"worldspawn" crash-related but damn it's fun
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_impulse(204, "impulse_handler");
    RegisterHam(Ham_Spawn,"player", "client_putinserver",1)
    register_clcmd("say !key", "handlesay");
    g_cvarDistance       = register_cvar("wtw_distance", "200");        // Maximum wall wiPlayers_indexth wich player can go through.
    g_cvarFalldistance   = register_cvar("wtw_fall_distance", "500");   // Maximum Fall distance behind the wall. (So you don't end up dead).
    g_cvarButton         = register_cvar("wtw_button", "1");            // Button (USE) needed to go through walls (1) or automatically (0)
    g_cvarDelay          = register_cvar("wtw_delay", "0.7");           // Delay after going through a wall, to go through the next one.
    g_cvarMessages       = register_cvar("wtw_message", "1");           // Show a message to player if walking through wall failed.
/*
    register_touch("func_door_rotating","player","Color");
    register_touch("func_door","player","Color");
*/
    for(new list; list < sizeof SzClass; list++)
        register_touch(SzClass[list],"player","Touch_Wall");/* &&
        register_touch(SzClass[list],"player","Color");*/
}
public Touch_Wall(entity, iPlayers_index)
{
    if(is_user_connected(iPlayers_index) && is_user_alive(iPlayers_index) && !is_user_bot(iPlayers_index) )
    {
        if(g_flDelay[iPlayers_index] < get_gametime())
        {
            new intCvarButton;
            intCvarButton = get_pcvar_num(g_cvarButton);
            if(!intCvarButton || (intCvarButton && pev(iPlayers_index, pev_button) & IN_USE))
            if(g_bHasKey[iPlayers_index])
            {
                set_player_behindwall(entity, iPlayers_index);
                if(g_bHasKey2[iPlayers_index])
                    Restore_door2(entity, iPlayers_index);
            }
        }
    }
}
public Color(entity, iPlayers_index)
{
   // const SPAWNFLAGS = 768
    set_pev(entity, pev_rendermode, kRenderTransColor);
    set_pev(entity, pev_rendercolor, Float:{255.0, 207.0, 148.0});
    set_pev(entity, pev_renderamt, 150.0);
    set_task(random_float(2.0,5.0),"Restore_door", entity);
}
public light_up(entity, iPlayers_index)
{
    if(pev_valid(entity)>1)
    {
        set_pev(entity, pev_rendercolor, Float:{255.0, 207.0, 148.0});
        /*
        if(is_user_admin(iPlayers_index))
            client_print(iPlayers_index, print_console, "Attempting to alter ent for you..");
        ****/
        set_task(random_float(2.0,5.0),"Restore_door", entity);
    }
}
public Restore_door(entity, iPlayers_index)
{
   if(pev_valid(entity)>1)
    {
        new Float:f_trans_amt;
        f_trans_amt = random_float(75.0, 200.0)
        set_pev(entity, pev_renderamt,  f_trans_amt);
        set_pev(entity, pev_rendercolor, Float:{255.0, 192.0, 203.0});
        /*
        if(find_ent_by_class(-1, "worldspawn"))
            return; //unstable breakable
        else
        */
        set_task(random_float(5.0,9.0),"Restore_door2", entity);
    }
}
public Restore_door2(entity, iPlayers_index)
{
   if(pev_valid(entity)>1)
    {
        set_pev(entity, pev_rendermode, kRenderFxStrobeFaster);
        set_pev(entity, pev_rendermode, kRenderGlow);
        set_pev(entity, pev_renderamt,  255.0);
        new SzEntCheck[MAX_PLAYERS]
        entity_get_string(entity, EV_SZ_target, SzEntCheck, charsmax(SzEntCheck))
        if(g_bHasKey2[iPlayers_index] && containi(SzEntCheck, "door_blast") == -1)
        {
            g_target_name++
            entity_set_string(entity, EV_SZ_classname,"func_breakable")
            new SzTargetIncrem[MAX_IP_LENGTH]
            formatex(SzTargetIncrem,charsmax(SzTargetIncrem), "door_blast%d", g_target_name )
            entity_set_string(entity, EV_SZ_target, SzTargetIncrem) //trigger
            entity_set_float(entity, EV_FL_takedamage, 2.0);
            entity_set_float(entity, EV_FL_health, 200.0);

            set_pev(entity, pev_rendermode, kRenderNormal);

            set_pev(entity, pev_flags, SF_BREAK_PRESSURE) //testing if it does rework obj

            //new ent = create_entity("env_explosion")
            new ent = create_entity("func_breakable")

            fm_set_kvd(ent, "explodemagnitude", "250"); //breakable
            set_pev(ent, pev_flags, SF_BREAK_TOUCH)
            //fm_set_kvd(ent, "iMagnitude", "250"); //env
            /*
            new SzDrop[4]
            formatex(SzDrop, charsmax(SzDrop), "^"%d^"", random_num(1,21) )
            trim(SzDrop)
            fm_set_kvd(ent, "spawnobject", SzDrop)
            */


/*
            new rNum = random(211)
            switch(rNum)
            {
                case 0..10: fm_set_kvd(ent, "spawnobject", "1") //Battery
                case 11..20: fm_set_kvd(ent, "spawnobject", "2") //Health Kit
                case 21..30: fm_set_kvd(ent, "spawnobject", "3") //9mm Handgun
                case 31..40: fm_set_kvd(ent, "spawnobject", "4") //9mm Clip
                case 41..50: fm_set_kvd(ent, "spawnobject", "5") //Machine Gun
                case 51..60: fm_set_kvd(ent, "spawnobject", "6") //Machine Gun Clip
                case 61..70: fm_set_kvd(ent, "spawnobject", "7") //Machine Gun Grenades
                case 71..80: fm_set_kvd(ent, "spawnobject", "8") //Shotgun
                case 81..90: fm_set_kvd(ent, "spawnobject", "9") //Shotgun Shells
                case 91..100: fm_set_kvd(ent, "spawnobject", "10")//Crossbow
                case 101..110: fm_set_kvd(ent, "spawnobject", "11")//Crossbow Bolts
                case 111..120: fm_set_kvd(ent, "spawnobject", "12")//357
                case 121..130: fm_set_kvd(ent, "spawnobject", "13")//357 Clip
                case 131..140: fm_set_kvd(ent, "spawnobject", "14")//RPG
                case 141..150: fm_set_kvd(ent, "spawnobject", "15")//RPG Clip
                case 151..160: fm_set_kvd(ent, "spawnobject", "16")//Gauss Clip
                case 161..170: fm_set_kvd(ent, "spawnobject", "17")//Hand Grenade
                case 171..180: fm_set_kvd(ent, "spawnobject", "18")//Tripmine
                case 181..190: fm_set_kvd(ent, "spawnobject", "19")//Satchel Charge
                case 191..200: fm_set_kvd(ent, "spawnobject", "20")//Snark
                case 201..210: fm_set_kvd(ent, "spawnobject", "21")//Hornet Gun
            }
*/
            fm_set_kvd(ent, "material", "2");
            fm_set_kvd(ent, "explosion", "1"); //0- random 1- rel attack
            fm_set_kvd(ent, "gibmodel", "models/hair.mdl");

            fm_set_kvd(ent, "targetname", SzTargetIncrem)

            entity_set_float(ent, EV_FL_takedamage, 2.0);
            entity_set_float(ent, EV_FL_health, 2.0);
            set_pev(ent, pev_rendermode, kRenderNormal);

            new Origin[3];
            pev(iPlayers_index, pev_origin, Origin);
            set_pev(ent, pev_origin, Origin);
            dllfunc( DLLFunc_Spawn, ent)
            entity_set_string(ent, EV_SZ_classname,"func_breakable")


            if(is_user_connected(iPlayers_index))
                client_print(iPlayers_index, print_center,"Item^n^n^n~~is~~^n^n^nbreakable now!");
        }
    }
}
set_player_behindwall(entity, iPlayers_index)
{
    new Float:flOrigin[4][3], Float:flAngle[3]
    new Origin[3];
    get_user_origin(iPlayers_index, Origin);
    pev(iPlayers_index, pev_origin, flOrigin[0])
    pev(iPlayers_index, pev_v_angle, flAngle)
    flAngle[0] = -10.0
    origin_infront(flAngle, flOrigin[0], (get_pcvar_float(g_cvarDistance) + 40.0), flOrigin[1]);
    new iTraceHandle = create_tr2();
    engfunc(EngFunc_TraceLine, flOrigin[0], flOrigin[1], DONT_IGNORE_MONSTERS, iPlayers_index, iTraceHandle);
    get_tr2(iTraceHandle, TR_vecEndPos, flOrigin[2]);
    if(get_distance_f(flOrigin[0], flOrigin[2]) > 17.0)
    {
        free_tr2(iTraceHandle);
        return 0;
    }
    g_flDelay[iPlayers_index] = (get_gametime() + get_pcvar_float(g_cvarDelay));
    engfunc(EngFunc_TraceLine, flOrigin[1], flOrigin[0], DONT_IGNORE_MONSTERS, iPlayers_index, iTraceHandle);
    get_tr2(iTraceHandle, TR_vecEndPos, flOrigin[3]);
    origin_infront(flAngle, flOrigin[3], 16.55, flOrigin[3]);
    if(is_hull_vacant(flOrigin[3], pev(iPlayers_index, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN))
    {
        xs_vec_copy(flOrigin[3], flOrigin[1]);
        flOrigin[1][2] -= 1000.0;
        engfunc(EngFunc_TraceLine, flOrigin[3], flOrigin[1], IGNORE_MONSTERS, iPlayers_index, iTraceHandle);
        get_tr2(iTraceHandle, TR_vecEndPos, flOrigin[1]);
        if(get_distance_f(flOrigin[3], flOrigin[1]) > get_pcvar_float(g_cvarFalldistance))
        {
            if(get_pcvar_num(g_cvarMessages) /*&& is_user_connected(iPlayers_index)*/ )
            {
                client_print(iPlayers_index, print_center, "Walking through failed, ^n^nfall risk");
                Color(entity, iPlayers_index);
                Lights(iPlayers_index, Origin);
            }
            free_tr2(iTraceHandle);
            return 0;
        }
        engfunc(EngFunc_SetOrigin, iPlayers_index, flOrigin[3]);
    }
    else if(get_pcvar_num(g_cvarMessages) )
    {
        client_print(iPlayers_index, print_center, "Walking through failed, ^n^narea too big.");
        Color(entity, iPlayers_index);
        Lights(iPlayers_index, Origin);
    }
    free_tr2(iTraceHandle);
    return 1;
}
public Lights(iPlayers_index,Origin[3])
{
    emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},iPlayers_index);
    ewrite_byte(TE_DLIGHT);
    ewrite_coord(Origin[0])
    ewrite_coord(Origin[1])
    ewrite_coord(Origin[2])
    ewrite_byte(random_num(20,35)); /*(radius in 10's)*/   ///was -1000 now -18K
    ewrite_byte(random_num(0,255)); /*rgb*/
    ewrite_byte(random_num(0,255));
    ewrite_byte(random_num(0,255));
    ewrite_byte(random_num(50,100)); /*life*/
    ewrite_byte(random_num(40,100));  /*(decay rate in 10's)*/
    emessage_end();
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY,{0,0,0},0);
    ewrite_byte(TE_ELIGHT);
    ewrite_short(iPlayers_index)
    ewrite_coord(Origin[0])
    ewrite_coord(Origin[1])
    ewrite_coord(Origin[2])
    ewrite_coord(random_num(20,50)); /*(radius in 10's)*/   ///was -1000 now -18K
    ewrite_byte(random_num(0,255)); /*rgb*/
    ewrite_byte(random_num(0,255));
    ewrite_byte(random_num(0,255));
    ewrite_byte(random_num(15,50)); /*life*/
    ewrite_coord(random_num(50,100));  /*(decay rate in 10's)*/
    emessage_end();
}
origin_infront( Float:vAngles[3], Float:vecOrigin[ 3 ], Float:flDistance, Float:vecOutput[ 3 ] ) // By Exolent
{
    new Float:vecAngles[3];
    xs_vec_copy(vAngles, vecAngles);
    engfunc(EngFunc_MakeVectors, vecAngles);
    global_get(glb_v_forward, vecAngles);
    xs_vec_mul_scalar(vecAngles, flDistance, vecAngles);
    xs_vec_add(vecOrigin, vecAngles, vecOutput);
}
bool:is_hull_vacant(const Float:origin[3], hull)
{
    new tr;
    engfunc(EngFunc_TraceHull, origin, origin, IGNORE_MONSTERS, hull, 0, tr);
    return bool:(!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen))
}
public plugin_precache()
{
    precache_model("models/w_security.mdl");
    g_model2 = precache_model("sprites/steam1.spr");
    precache_model("models/w_securityt.mdl"); //need prevent crash
    precache_model("models/glassgibs.mdl");
    //keep func_breakable, random near untraceable crashes

    //if you bother to make a func_breakable out of thin air
    precache_model("models/hair.mdl")

    precache_sound("debris/bustglass2.wav");
    precache_sound("debris/bustglass1.wav");

    precache_sound("debris/bustmetal1.wav");
    precache_sound("debris/bustmetal2.wav");


    precache_sound("debris/metal1.wav");
    precache_sound("debris/metal2.wav");
    precache_sound("debris/metal3.wav");

    precache_sound("items/smallmedkit1.wav")
    precache_sound("items/smallmedkit2.wav")

    precache_model("sprites/fexplo.spr")


    precache_model("models/w_battery.mdl")
    precache_model("models/w_medkit.mdl")

    precache_model("models/hair.mdl")


    ////////////////fun C  breakable!!///////////////

}
public handlesay(iPlayers_index)
{
    if(is_user_connected(iPlayers_index))
        client_putinserver(iPlayers_index)
}
public client_putinserver(iPlayers_index)
{
    if(is_user_bot(iPlayers_index))
        return PLUGIN_HANDLED_MAIN;
/*
    new Float:minbox[3] = { -g_fbox, -g_fbox, -g_fbox }
    new Float:maxbox[3] = { g_fbox, g_fbox, g_fbox }
    new Float:angles[3] = { 0.0, 0.0, 0.0 }
*/
    if( !is_user_bot(iPlayers_index) && is_user_alive(iPlayers_index) && get_user_frags(iPlayers_index) > 4 || is_user_alive(iPlayers_index) && is_user_admin(iPlayers_index))
    {
        give_item(iPlayers_index,"item_security");
        g_bHasKey[iPlayers_index] = true
        client_print(iPlayers_index, print_center,"Skeleton Key given!");
/*
        g_key = create_entity("func_breakable")
        entity_set_string(g_key, EV_SZ_targetname,"skeleton_key")
        entity_set_edict(g_key, EV_ENT_aiment, iPlayers_index)
        entity_set_edict(g_key, EV_ENT_owner, iPlayers_index)
        entity_set_float(g_key, EV_FL_health, g_packHP*1.0) //Cvar later?
        entity_set_size(g_key, minbox, maxbox )
        set_pev(g_key,pev_angles,angles)
        entity_set_int(g_key, EV_INT_movetype, MOVETYPE_BOUNCE)
        set_pev(g_key,pev_solid,SOLID_BBOX)
        set_pev(g_key,pev_takedamage, DAMAGE_AIM)
*/
        if(get_user_frags(iPlayers_index) > 9)
            g_bHasKey2[iPlayers_index] = true && client_print(iPlayers_index, print_chat,"impulse 204 (~ console) drops key of destruction!");
        //if(is_user_connected(iPlayers_index) && g_bHasKey2[iPlayers_index])
//            entity_set_model(g_key, "models/w_security.mdl")
    }
    else
    {
        g_bHasKey[iPlayers_index] = false
        client_print(iPlayers_index, print_center,"You were not granted a key!");
        new X = ( 5 - get_user_frags(iPlayers_index) )
        client_print(iPlayers_index,print_chat,"%i more frag(s) are needed.", X);
    }
    return PLUGIN_CONTINUE;
}
public client_disconnected(iPlayers_index)
{
    g_bHasKey[iPlayers_index] = false
    g_bHasKey2[iPlayers_index] = false
}
public impulse_handler(iPlayers_index)
{
    if(g_bHasKey[iPlayers_index])
    {
        client_print(iPlayers_index, print_chat,"Skeleton Key dropped.");
        drop(iPlayers_index);
    }
    else
        client_print(iPlayers_index, print_chat,"You have no keys to drop!");
}

//Back when this was a key that could be dropped. Now frag based at least for starters.
///Remake to have other player pick up. Make a sound etc. Make this fun.
public drop(iPlayers_index)
{
    //remove_entity(g_key)
    new count, variance;
    count = 1;
    variance = 0;
    #define TE_PLAYERATTACHMENT         124
    emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
    ewrite_byte(TE_PLAYERSPRITES)
    ewrite_short(iPlayers_index)
    ewrite_short(g_model2)
    ewrite_byte(count)
    ewrite_byte(variance) //(0 = no variance in size) (10 = 10% variance in size)
    emessage_end();
    emessage_begin( MSG_BROADCAST, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
    ewrite_byte(TE_PLAYERATTACHMENT)
    ewrite_byte(iPlayers_index)
    ewrite_coord(-75) //(attachment origin.z = player origin.z + vertical offset)
    ewrite_short(g_model2)   //mdl
    ewrite_short(160 ) //life * 10
    emessage_end();
    g_bHasKey[iPlayers_index] = false;
    if(pev_valid(g_key) > 1)
        remove_entity(g_key)
}

/*
 * References:
 * https://twhl.info/wiki/page/func_breakable
 * https://www.amxmodx.org/api/
 * https://forums.alliedmods.net/showthread.php?p=2197107 // Walk through walls --Xalus ...method I picked over pfn_touch.
*/
