#include amxmodx
#include engine
#include fakemeta
#include fakemeta_util

new g_time_jump[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin("Trigger_hurt teleporter", "1.0.1", "SPiNX")
    register_touch("trigger_hurt","player", "@respawn")
}

@respawn(hurt, id)
{
    //new Float:fOrigin[3];
    if(is_user_connected(id) && is_user_bot(id) || is_user_alive(id) && !is_user_bot(id))
    {
        g_time_jump[id]++
        //g_time_jump[id] % 5 == 0 ?/*every 5th accident is a time jump.*/fm_strip_user_weapons(id)&dllfunc(DLLFunc_ClientPutInServer, id)&fake_burial(id) : entity_explosion_knockback(id);
        if(g_time_jump[id] % 5 == 0)
        {/*every 5th accident is a time jump.*/
            fm_strip_user_weapons(id)
            dllfunc(DLLFunc_ClientPutInServer, id)
            fake_burial(id)
        }
         else
        {
            //pev(id,pev_origin, fOrigin)
            entity_explosion_knockback(id);
        }
    }
    return PLUGIN_HANDLED;
}

#include <xs>
public entity_explosion_knockback(victim)
//Natsheh knockback stock. Something about never worked until I fed it floats.
{
    if(is_user_alive(victim))
    {
        new Float:fExpOrigin[3];
        new Float:fVelo[3], Float:fKnockBackVelo[3];

        new Float:fExpShockwaveRadius=500.0, Float:fExpShockwavePower=300.0;

        new Float:fOrigin[3];
        pev(victim, pev_origin, fOrigin);

        new Float:fDistVec[3];
        xs_vec_sub(fOrigin, fExpOrigin, fDistVec);

        new Float:g_fTemp;
        // victim is in the range of the shockwave explosion!
        if((g_fTemp=xs_vec_len(fDistVec)) <= fExpShockwaveRadius)
        {
            new Float:fPower = fExpShockwavePower * ( 1.0 -( g_fTemp / floatmin(fExpShockwaveRadius, 1.0) ) )

            /*new Validate_math[8];
            float_to_str(fPower, Validate_math, charsmax(Validate_math))
            if(is_str_num(Validate_math)){*/
            server_print "Fpower is %f", fPower
            pev(victim, pev_velocity, fVelo);
            xs_vec_normalize(fDistVec, fKnockBackVelo);
            xs_vec_mul_scalar(fKnockBackVelo, fPower, fKnockBackVelo);
            xs_vec_add(fVelo, fKnockBackVelo, fVelo);
            //}
            if(fVelo[0] != 0.0 && fVelo[1] != 0.0 && fVelo[2] != 0.0)
            {
                set_pev(victim, pev_velocity, fVelo);
                server_print "%n | %f %f %f | neon_push", victim, fVelo[0], fVelo[1], fVelo[2]
            }
            else
            {
                  log_amx "CAN'T DIVIDE BY NaN!"
            }

        }
        else
        {
            server_print "Out of punt radius!"
        }
    }
    return PLUGIN_CONTINUE;
}

public plugin_precache()
precache_sound("weapons/pwach.wav")

public fake_burial(id)
{
    if(is_user_connected(id))
    {
        if(!is_user_bot(id))
        {
            emit_sound(id, CHAN_AUTO, "weapons/pwach.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
            new Float:Wector[3];
            pev(id,pev_origin,Wector);

            emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id )
            ewrite_byte( TE_FIREFIELD );
            ewrite_coord_f( Wector[0] );
            ewrite_coord_f( Wector[1] );
            ewrite_coord_f( Wector[2] );
            ewrite_short( 25 );            /*(radius)*/
            ewrite_short( id );
            ewrite_byte( 5 );              /*(count)*/
            ewrite_byte( 2 );
            ewrite_byte( 500 );
            emessage_end();
            return PLUGIN_CONTINUE;
        }

    }
    return PLUGIN_HANDLED;
}
