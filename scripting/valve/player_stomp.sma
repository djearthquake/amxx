/*Squash player from stamping them*/
#tryinclude amxmodx
#tryinclude amxmisc
#tryinclude engine
#tryinclude fakemeta
#tryinclude fakemeta_util
#tryinclude fun
#tryinclude hamsandwich
#define is_valid_player(%1) (1 <= %1 <= g_MaxPlayers )
#define SEND_MSG_ALLPLAYERS 0
enum _:authors_details
{
    plugin[MAX_NAME_LENGTH],
    version[MAX_IP_LENGTH],
    author[MAX_NAME_LENGTH]
}

new
plugin_registry[ authors_details ],
vbuffer[MAX_IP_LENGTH],
g_MaxPlayers,
g_coin, g_peak

new bool:g_bStomped[ MAX_PLAYERS + 1 ]
new Float:fExpOrigin[3]

new const SOUND_GOOMBA[] = "misc/goomba_stomp.wav",
MARIO_DEATH_SND[] = "sound/misc/super-mario-death-sound-sound-effect.mp3",
SPIN_COIN[] = "sprites/mario16/spinning_coin.spr"

public plugin_init()
{
    new hour,min,sec
    time(hour,min,sec)
    formatex(vbuffer,charsmax(vbuffer),"%i:%i:%i", hour, min, sec)
    plugin_registry[ plugin ] = "Squash player"
    plugin_registry[ version ] = vbuffer
    plugin_registry[ author ] = ".sρiηX҉."
    set_task( 1.0, "@register", 777, plugin_registry, authors_details )
    register_touch("","player", "@touch")
    register_touch("","player", "@touch_inquiry")
    RegisterHam(Ham_Spawn, "weaponbox", "FORWARD_SET_MODEL", 1)
    RegisterHam(Ham_Spawn, "player", "@client_spawn", 1);
    g_MaxPlayers = get_maxplayers()
}
@client_spawn(id)
    if(is_valid_player(id))
        g_bStomped[id] = false

@register()
{
    register_plugin
    (
        .plugin_name = plugin_registry[ plugin ],
        .version =  plugin_registry[ version ],
        .author = plugin_registry[ author ]
    )
}
public FORWARD_SET_MODEL(entid)
{
    new player = pev(entid, pev_owner)
    if(g_bStomped[player])
    {
        fm_entity_set_model(entid, SPIN_COIN)
        @burst_coin(entid)
    }
}

@touch_inquiry(victim, attacker)
if(is_valid_player(attacker) || is_valid_player(victim) )
{
    //if duck and use then show...
    new Button = pev(attacker,pev_button),OldButton = pev(attacker,pev_oldbuttons);
    if(Button & IN_USE && (OldButton & IN_DUCK) && pev(attacker, pev_flags) & FL_ONGROUND)
    {
        new SzVClassname[MAX_NAME_LENGTH], SzAClassname[MAX_NAME_LENGTH]
    
        if(pev_valid(victim))
            pev(victim, pev_classname, SzVClassname, charsmax(SzVClassname));
    
        if(pev_valid(attacker))
            pev(attacker, pev_classname, SzAClassname, charsmax(SzAClassname));
    
        if(is_valid_player(attacker))
            client_print attacker, print_center, SzVClassname
    
        if(is_valid_player(victim))
            client_print victim, print_center, SzAClassname

        set_task(0.1, "@show_stake", attacker)
    }
}

@burst_coin(entid,{Float,_}:...)
if(pev_valid(entid))
{
    new Float:End_Position[3]
    new Float:Axis[3];

    entity_get_vector(entid,EV_VEC_origin,End_Position);
    entity_get_vector(entid,EV_VEC_angles,Axis);

    ///explode models on explode or touch.
    emessage_begin( MSG_PVS, SVC_TEMPENTITY, _, SEND_MSG_ALLPLAYERS);
    ewrite_byte(TE_EXPLODEMODEL)
    ewrite_coord(floatround(End_Position[0]+random_float(-11.0,11.0)))      // XYZ (start)
    ewrite_coord(floatround(End_Position[1]-random_float(-11.0,11.0)))
    ewrite_coord(floatround(End_Position[2]+random_float(1.0,75.0)))
    ewrite_coord(random_num(-350,400))       // velocity
    ewrite_short(g_coin);
    ewrite_short(random_num(5,15))               //(count)
    ewrite_byte(random_num(8,20))              //(life in 0.1's)
    emessage_end()
}
@touch(victim, attacker)
{
    #define PITCH (random_num(85,140))
    new Vhealth = pev(victim,pev_health)
    new Ahealth = pev(attacker,pev_health)
    new health_max = pev(victim,pev_max_health)
    new aOrigin[3], vOrigin[3]
    new SzAClassname[MAX_NAME_LENGTH], SzVClassname[MAX_NAME_LENGTH]

    new Button = pev(attacker,pev_button),OldButton = pev(attacker,pev_oldbuttons);
    if(Button & IN_JUMP && (OldButton & IN_JUMP) && pev(attacker, pev_flags) /*&& (is_valid_player(victim) && !get_user_godmode(victim) && is_valid_player(attacker) && !get_user_godmode(attacker))*/)

    if(Vhealth > 1  && Ahealth > 1 && health_max > 1/* && is_user_alive(attacker)*/)
    {
        if(pev_valid(victim) || is_valid_player(victim) )
        {
            pev(victim, pev_classname, SzVClassname, charsmax(SzVClassname));
            pev(victim, pev_origin, vOrigin);
        }
        if(pev_valid(attacker) || is_valid_player(attacker) )
        {
            pev(attacker, pev_classname, SzAClassname, charsmax(SzAClassname));
            pev(attacker, pev_origin, aOrigin);
        }
                            
        if( aOrigin[2] - vOrigin[2] > 50/* && !is_user_bot(victim)*/)
        {
            {
                if(is_valid_player(attacker))
                {
                    new id = victim
                    fExpOrigin = vOrigin
                    if(get_user_godmode(victim))
                    {
                        entity_explosion_knockback(id, fExpOrigin)
                    }
                    else
                    {
                        ExecuteHam(Ham_TakeDamage, attacker, get_weaponid(""), victim, 500.0, DMG_CRUSH|DMG_ALWAYSGIB)
    
                        emit_sound(attacker, CHAN_STATIC, SOUND_GOOMBA, 5.0, ATTN_NORM, 0, PITCH);
    
                        g_bStomped[attacker] = true
                        if(is_user_admin(attacker))
                           // emit_sound(attacker, CHAN_STATIC, MARIO_DEATH_SND, 5.0, ATTN_NORM, 0, PITCH);
                            client_cmd(attacker,"mp3 play ^"%s^"",MARIO_DEATH_SND)
                    }

                }

            }
            if(is_valid_player(victim))
                client_print victim, print_center, "%n stamped %n | %s", victim, attacker,  SzAClassname
        }

        //else if(vOrigin[2] - aOrigin[2] > 50 && (victim, EV_FL_takedamage) > 0.0/*non-breakable*/)
        else if(aOrigin[2] - vOrigin[2] < -50 && (victim, EV_FL_takedamage) > 0.0/*non-breakable*/)
        {

            {
                ExecuteHam(Ham_TakeDamage, victim, get_weaponid("")/*attacker*/, attacker, 500.0, DMG_CRUSH|DMG_ALWAYSGIB)
                //player killing bot
                emit_sound(attacker, CHAN_STATIC, SOUND_GOOMBA, 5.0, ATTN_NORM, 0, PITCH);
                if(is_valid_player(victim))
                    g_bStomped[victim] = true
    
                if(is_valid_player(attacker) && is_valid_player(victim) )
                    client_print attacker, print_center, "%n stamped %n | %s", attacker, victim, SzVClassname
                else if(is_valid_player(attacker) && pev_valid(victim) )
                    client_print attacker, print_center, "%n stamped %s", attacker, SzVClassname
            }
        }
    }
}


@show_stake(id,{Float,_}:...)
if(is_valid_player(id))
{
    emessage_begin( MSG_PVS, SVC_TEMPENTITY, _, SEND_MSG_ALLPLAYERS );
    ewrite_byte(TE_PLAYERATTACHMENT);
    ewrite_byte(id); //who
    ewrite_coord(0); //where
    ewrite_short(g_peak); //what
    ewrite_short(1) //life
    emessage_end();
}

public plugin_precache()
{
    if(file_exists("sound/misc/goomba_stomp.wav")){
        precache_sound(SOUND_GOOMBA);
        precache_generic("sound/misc/goomba_stomp.wav")

    }
    else
    {
        log_amx("Paused to prevent crash from missing %s.",SOUND_GOOMBA);
        pause "a";
    }
    if(file_exists(MARIO_DEATH_SND)){
        precache_generic(MARIO_DEATH_SND)
    }
    else
    {
        log_amx("Paused to prevent crash from missing %s.", MARIO_DEATH_SND);
        pause "a";
    }
    if(file_exists(SPIN_COIN)){
        g_peak = precache_model("models/w_flare.mdl")
        g_coin = precache_model(SPIN_COIN)
        precache_generic(SPIN_COIN)
    }
    else
    {
        log_amx("Paused to prevent crash from missing %s.", SPIN_COIN);
        pause "a";
    }
}

#include <xs>
public entity_explosion_knockback(id, Float:fExpOrigin[3])
//Natsheh was here!
{
    server_print("%n knockback", id)
    new Float:fExpShockwaveRadius=100.0, Float:fExpShockwavePower=20.0;
    new Float:fOrigin[3], Float:fDistVec[3];
    pev(id, pev_origin, fOrigin);

    xs_vec_sub(fOrigin, fExpOrigin, fDistVec);

    new Float:g_fTemp;
    // victim is in the range of the shockwave explosion!
    if((g_fTemp=xs_vec_len(fDistVec)) <= fExpShockwaveRadius)
    {
        new Float:fPower = fExpShockwavePower * ( 1.0 - ( g_fTemp / floatmin(fExpShockwaveRadius, 1.0) ) ), Float:fVelo[3], Float:fKnockBackVelo[3];

        pev(id, pev_velocity, fVelo);
        xs_vec_normalize(fDistVec, fKnockBackVelo);
        xs_vec_mul_scalar(fKnockBackVelo, fPower, fKnockBackVelo);
        xs_vec_add(fVelo, fKnockBackVelo, fVelo);
        set_pev(id, pev_velocity, fVelo);
    }
}
/*
 //https://forums.alliedmods.net/showpost.php?p=2780153&postcount=9
 //OciXCrom was here!
 bool:is_ent_breakable(iEnt)
{
    if((entity_get_float(iEnt, EV_FL_health) > 0.0) && (entity_get_float(iEnt, EV_FL_takedamage) > 0.0) && !(entity_get_int(iEnt, EV_INT_spawnflags) & SF_BREAK_TRIGGER_ONLY))
    {
        return true
    }
    return false
}
*/
