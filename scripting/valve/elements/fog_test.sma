#include amxmodx
static g_fog_msg;

public plugin_init()
{
    register_plugin("Fog Test", "1.0", "SPiNX")
    g_fog_msg = get_user_msgid( "Fog" )
}

public client_putinserver(id)
{
    if(is_user_connected(id) && !is_user_bot(id))
    {
        set_task 0.5, "@make_fog", id
    }

}

@make_fog(id)
{
    CreateFog( id, 255, 255, 255, 0.003 );
}

stock CreateFog ( const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false )
{
    if(!index || index && is_user_connected(index))
    {
        new density = _:floatclamp( density_f, 0.0001, 0.25 ) * _:!clear;
        
        message_begin( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_fog_msg, .player = index );
        write_byte( clamp( red  , 0, 255 ) );
        write_byte( clamp( green, 0, 255 ) );
        write_byte( clamp( blue , 0, 255 ) );
        write_long( _:density );
        message_end();
    }
}
