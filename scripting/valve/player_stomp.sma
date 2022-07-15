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
SPIN_COIN[] = "sprites/mario16/spinning_coin.spr",
FART_SND[] = "misc/poot.wav"/*,
SHIT[] = "models/terd.mdl"
*/

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
        //looks better as env_sprite
        @burst_coin(entid)
    }
}

@touch_inquiry(victim, attacker)
{
    if(pev_valid(victim) &&  pev_valid(attacker))
    if(is_valid_player(attacker)/*limits to player only*/ || is_valid_player(victim) )
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
}

@burst_coin(entid,{Float,_}:...)
if(pev_valid(entid))
{
    new Float:End_Position[3]
    new Float:Axis[3];

    entity_get_vector(entid,EV_VEC_origin,End_Position);
    entity_get_vector(entid,EV_VEC_angles,Axis);

    ///explode models on explode or touch.
    emessage_begin( MSG_ALL, SVC_TEMPENTITY, _, SEND_MSG_ALLPLAYERS);
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
    if(pev_valid(victim) && pev_valid(attacker))
    {
        new Vhealth = pev(victim,pev_health)
        new Ahealth = pev(attacker,pev_health)
        new health_max = pev(victim,pev_max_health)
        new Float:aOrigin[3], vOrigin[3]
        new SzAClassname[MAX_NAME_LENGTH], SzVClassname[MAX_NAME_LENGTH]

        new Button = pev(attacker,pev_button),OldButton = pev(attacker,pev_oldbuttons);
        if(Button & IN_JUMP && (OldButton & IN_JUMP) && pev(attacker, pev_flags) /*&& (is_valid_player(victim) && !get_user_godmode(victim) && is_valid_player(attacker) && !get_user_godmode(attacker))*/)
        //also check if off ground
        if(Vhealth > 1  && Ahealth > 1 && health_max > 1/* && is_user_alive(attacker)*/)
        {

            Vhealth = pev(victim,pev_health)
            pev(victim, pev_classname, SzVClassname, charsmax(SzVClassname));
            pev(victim, pev_origin, vOrigin);

            pev(attacker, pev_classname, SzAClassname, charsmax(SzAClassname));
            pev(attacker, pev_origin, aOrigin);

            if( aOrigin[2] - vOrigin[2] > 50/* && !is_user_bot(victim)*/)
            {

                new id;
                fExpOrigin = aOrigin
                if(is_valid_player(attacker)  && get_user_godmode(attacker) || is_valid_player(victim) && get_user_godmode(victim) )
                {
                    if(get_user_godmode(attacker))
                        id = attacker
                    if(get_user_godmode(victim))
                        id = victim
    
                    //If either player is in Godmode like from Spawn Protection script I want it to be like magnets repelling with some force.
                    fExpOrigin[2] += 500.0
                    new origin[3]
                    origin[0] = floatround(fExpOrigin[0])
                    origin[1] = floatround(fExpOrigin[1])
                    origin[2] = floatround(fExpOrigin[2])
                    ///entity_explosion_knockback(id, origin
                    emit_sound(id, CHAN_WEAPON, FART_SND, 5.0, ATTN_NORM, 0, PITCH);
                }
                else
                {
                    //Otherwise whatever player is a neck higher and in jump to squash other player and do effects both sound and coins
                    ExecuteHam(Ham_TakeDamage, victim, get_weaponid(""), attacker, 500.0, DMG_CRUSH|DMG_ALWAYSGIB)
    
                    emit_sound(attacker, CHAN_STATIC, SOUND_GOOMBA, 5.0, ATTN_NORM, 0, PITCH);
    
                    if(is_user_connected(victim))
                        g_bStomped[victim] = true
    
                    if(is_user_connected(victim) && !is_user_bot(victim) && !is_user_alive(victim))
                       // emit_sound(attacker, CHAN_STATIC, MARIO_DEATH_SND, 5.0, ATTN_NORM, 0, PITCH);
                        client_cmd(victim,"mp3 play ^"%s^"",MARIO_DEATH_SND)
                }

                if(!is_user_bot(attacker) &&  is_user_connected(attacker) &&  victim < 33 && pev(victim, pev_deadflag) != DEAD_NO)
                    client_print attacker, print_center, "%n stamped %n | %s", attacker, victim, SzVClassname

                else if(!is_user_bot(attacker) &&  is_user_connected(attacker) && pev(victim, pev_deadflag) != DEAD_NO )
                {
                    client_print attacker, print_center, "%n stamped %s", attacker, SzVClassname
                    if(!is_valid_player(victim) && pev_valid(victim))
                        @burst_coin(victim) //monster needs coin too!
                }
            }

            else if(vOrigin[2] - aOrigin[2] > 50 && (victim, EV_FL_takedamage) > 0.0/*non-breakable*/)
            //else if(aOrigin[2] - vOrigin[2] < -50 && (victim, EV_FL_takedamage) > 0.0/*non-breakable*/)
            {

                {
                    ExecuteHam(Ham_TakeDamage, attacker, get_weaponid("")/*attacker*/, victim, 500.0, DMG_CRUSH|DMG_ALWAYSGIB)
                    //player killing bot
                    emit_sound(victim, CHAN_STATIC, SOUND_GOOMBA, 5.0, ATTN_NORM, 0, PITCH);
                    if(is_user_connected(attacker))
                        g_bStomped[attacker] = true

                    if(!is_user_bot(attacker) && !is_user_alive(attacker))
                       // emit_sound(attacker, CHAN_STATIC, MARIO_DEATH_SND, 5.0, ATTN_NORM, 0, PITCH);
                        client_cmd(attacker,"mp3 play ^"%s^"",MARIO_DEATH_SND)

                    if(!is_user_bot(victim) && !is_user_alive(attacker) )
                        client_print victim, print_center, "%n stomped %n | %s", victim, attacker, SzAClassname

                    else if(is_user_bot(victim) && pev_valid(attacker) )
                        client_print victim, print_center, "%n stomped %s", attacker, SzAClassname
                }
            }
        }
    }
}


@show_stake(id,{Float,_}:...)
if(is_valid_player(id))
{
    emessage_begin( MSG_ALL, SVC_TEMPENTITY, _, SEND_MSG_ALLPLAYERS );
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
    if(file_exists("sound/misc/poot.wav")){
        precache_sound(FART_SND)

    }
    else
    {
        log_amx("Paused to prevent crash from missing %s.", FART_SND);
        pause "a";
    }
}
