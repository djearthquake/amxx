#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

new const szDeath_symbol_spr[] = "models/bskull_template1.mdl";
new const szDeath_symbol_tr[]  = "sprites/smoke.spr";
new smoke, skull;

public plugin_init()
{
    register_plugin("Camera Changer", "3.0", "XunTric|SPiNX");
    register_menucmd(register_menuid("Choose Camera View"), 1023, "setview");
    RegisterHam(Ham_Spawn, "player", "client_spawn", 1);
    RegisterHam(Ham_Killed, "player", "client_death");
   // register_event("ScoreInfo", "plugin_log", "bcf", "1=committed suicide with", "2=trigger_hurt" );
    register_clcmd("say /cam", "chooseview", 0, "- displays camera menu");
    register_clcmd("say_team /cam", "chooseview", 0, "- displays camera menu");
}

public plugin_precache()
{
    skull = precache_model(szDeath_symbol_spr);
    precache_generic(szDeath_symbol_spr);
    smoke = precache_model(szDeath_symbol_tr);
    precache_generic(szDeath_symbol_spr);
    #if AMXX_VERSION_NUM != 11|19
    precache_model("models/rpgrocket.mdl");
    precache_generic("models/rpgrocket.mdl");
    #endif
}

public client_putinserver(id)
    //Some mods spawn (death) field-of-view.
    if(is_user_connected(id))
    set_task(0.5,"client_spawn",id);


public client_disconnected(id)
    if(task_exists(id))
        remove_task(id);


public client_spawn(id)
{
    if(is_user_bot(id) || is_user_hltv(id) )
        return PLUGIN_HANDLED_MAIN;

    if(is_user_connected(id) && is_user_alive(id) )

    {
        set_view(id, CAMERA_NONE);
        console_cmd(id, "default_fov 100");
    }

    return PLUGIN_CONTINUE;
}

/*
public plugin_log()

{
    new szDummy[ MAX_PLAYERS ];
    read_logargv(2,szDummy, charsmax(szDummy));

    if (containi(szDummy, "trigger_hurt") != -1)

}
*/

public client_death(victim,killer)
{
    if ( killer <= 0 || killer == victim || is_user_bot(victim)) return PLUGIN_HANDLED_MAIN
    if ( killer > 0 )
    if(is_user_connected(victim) && !is_user_alive(victim) && !is_user_bot(victim) && is_user_connected(killer))

    {
        set_view(victim, CAMERA_3RDPERSON);
        console_cmd(victim, "default_fov 150");
        new Deathcam[3];
        new Eye = 1;
        get_user_origin(victim,Deathcam,Eye);

        #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters

        new Korigin[3];
        get_user_origin(killer,Korigin,Eye);

        /*
        new Float:Vaim[3];
        new iVelocity;
        iVelocity = 1.0
        velocity_by_aim(killer, iVelocity, Vaim)

        emessage_begin( 0, SVC_TEMPENTITY, { 0, 0, 0 }, 0 );
        ewrite_byte(TE_PROJECTILE);
        ewrite_coord(Korigin[0]);       // start position
        ewrite_coord(Korigin[1]);
        ewrite_coord(Korigin[2]);
        ewrite_coord(floatround(Vaim[0]));      // end position
        ewrite_coord(floatround(Vaim[1]));
        ewrite_coord(floatround(Vaim[2]));
        ewrite_short(smoke)
        ewrite_byte(100)
        ewrite_byte(0)  //projectile won't collide with owner (if owner == 0, projectile will hit any client).
        emessage_end();
        */

        emessage_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, victim );
        ewrite_byte(TE_LIGHTNING);
        ewrite_coord(Korigin[0]);       // start position
        ewrite_coord(Korigin[1]);
        ewrite_coord(Korigin[2]);
        ewrite_coord(Deathcam[0]);      // end position
        ewrite_coord(Deathcam[1]);
        ewrite_coord(Deathcam[2]);
        ewrite_byte(65);        // life in 0.1's
        ewrite_byte(100);        // width in 0.1's
        ewrite_byte(15); // amplitude in 0.01's
        ewrite_short(smoke);     // sprite model index
        emessage_end();

        emessage_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, victim );
        ewrite_byte(TE_LINE);
        ewrite_coord(Korigin[0]);
        ewrite_coord(Korigin[1]);
        ewrite_coord(Korigin[2]);
        ewrite_coord(Deathcam[0]);
        ewrite_coord(Deathcam[1]);
        ewrite_coord(Deathcam[2]);
        ewrite_short(60); //life
        ewrite_byte(0); //r
        ewrite_byte(255); //g
        ewrite_byte(0);  //b
        emessage_end();

       //After Death effect
        emessage_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0}, victim );
        ewrite_byte(TE_FIREFIELD);

        ewrite_coord(Deathcam[0]);
        ewrite_coord(Deathcam[1]);
        ewrite_coord(Deathcam[2] + random_num(-500, 1000));

        ewrite_short(15)/*radius*/;

        switch(random_num(0,2)) {
            case 0: ewrite_short(skull)
            case 1: ewrite_short(killer)
            case 2: ewrite_short(victim)
        }
        ewrite_byte(1)/*count*/;
        ewrite_byte(2)/*flags*/;
        ewrite_byte(random_num(5,15))/*duration*/;
        emessage_end();

        return PLUGIN_HANDLED;

    }

    return PLUGIN_CONTINUE;
}

public chooseview(id)
{
    new menu[192]
    new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3
    format(menu, charsmax(menu), "Choose Camera View^n^n1. 3rd Person View^n2. Upside View^n3. Normal View^n^n0. Exit")
    show_menu(id, keys, menu)
    return PLUGIN_CONTINUE
}

public setview(id, key, menu)
{
    if(key == 0) {
         set_view(id, CAMERA_3RDPERSON)
         return PLUGIN_HANDLED
    }

    if(key == 1) {
         set_view(id, CAMERA_TOPDOWN)
         return PLUGIN_HANDLED
    }

    if(key == 2) {
         set_view(id, CAMERA_NONE)
         return PLUGIN_HANDLED
    }

    else {
         return PLUGIN_CONTINUE
    }
    #if AMXX_VERSION_NUM == 182;
    return PLUGIN_CONTINUE
    #endif
}
