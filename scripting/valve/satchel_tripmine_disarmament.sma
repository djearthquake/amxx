/*Attempting disarm of several HL/OF explosives including snarks and penguins!*/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Disarmable Satchel Mine"
#define VERSION "1.9"
#define AUTHOR "SPiNX"
#define MAX_PLAYERS         32
#define MAX_NAME_LENGTH     32

#define charsmin                  -1

//#define TEST

//HL OF
#define HLW_KNIFE           0x0019
#define HLW_PIPEWRENCH      18

#define DELAY ewrite_short(/*get_pcvar_num(g_cvar_bsod_iDelay)*/ 10*4096) //Remember 4096 is ~1-sec per 'spec unit'

#define FLAGS ewrite_short(0x0001)

#define ALPHA ewrite_byte(500)


//Screenfade color.

#define BLU ewrite_byte(0);ewrite_byte(0);ewrite_byte(random_num(200,255))

#define GRN ewrite_byte(0);ewrite_byte(random_num(200,255));ewrite_byte(0)

#define PNK ewrite_byte(255);ewrite_byte(random_num(170,200));ewrite_byte(203)

#define PUR ewrite_byte(118);ewrite_byte(random_num(25,75));ewrite_byte(1

///new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new g_Szsatchel_ring, g_fade, g_mortar_range, g_proximity

new const SzSatchSfx[]="items/airtank1.wav"

///new const satchel_sound[][]={"sound/player/geiger1.wav", "sound/player/geiger2.wav", "sound/player/geiger3.wav", "sound/player/geiger4.wav", "sound/player/geiger5.wav", "sound/player/geiger6.wav"}

new disarmament[][]=
{
    ///"monster_satchel",
    "mortar_shell",
    "monster_snark",
    "monster_tripmine",
    "monster_penguin",
    "monster_babycrab",
    "monster_grenade",
    ///if plugin
    "Hook_rope",
    "Hook_wire",
    "Hook_rope_barnacle",
    "Hook_rope_push",
    "Hook_rope_mine",
    "Hook_rope_guin",
    "Hook_rope_leech",
    "Hook_rope_crab",
    "Hook_rope_snark",
    "Hook_illuminati",
    "Hook_displacer"
}

new g_enable, g_health, g_Hostname, g_satchel
new g_SzMonster_class[MAX_NAME_LENGTH];
new g_lash_damage, g_fire
const LINUX_OFFSET_WEAPONS = 4;
const LINUX_OFFSET = 20;
const LINUX_DIFF = 5;

//tripmine data
new iRealOwner2;
new iBeamEnt, iRTripMineOwner, iRPenguinOwner;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_Hostname      =       get_cvar_pointer("hostname");

    for( new list; list < sizeof disarmament; ++list)
        register_touch(disarmament[list], "player", "disarm_")

    register_touch("monster_satchel", "player", "@touch")

    g_enable = register_cvar("hl_satchel", "1")
    g_health = register_cvar("hl_satchel_health", "15")
    g_mortar_range = register_cvar("hl_satchel_mortar", "300.0")
    g_enable = register_cvar("hl_satchel", "1")
    g_lash_damage = register_cvar("hl_satchel_lash", "15")
    g_fade = get_user_msgid("ScreenFade")

    iBeamEnt = (find_ent_data_info("CTripmineGrenade", "m_pBeam")/LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    iRTripMineOwner = (find_ent_data_info("CTripmineGrenade", "m_pRealOwner") - LINUX_OFFSET)
    iRPenguinOwner = (find_ent_data_info("CPenguinGrenade", "m_hOwner") - LINUX_OFFSET)

    if(has_map_ent_class("op4mortar"))
    {
        g_proximity = register_forward(FM_PlayerPreThink, "mortar_proximity", true)
    }
}

public plugin_cfg()
{
    if(get_pcvar_num(g_enable))
        g_satchel = register_forward(FM_SetModel,"FORWARD_SET_MODEL", 1);
}

public plugin_end()
{
    unregister_forward(FM_SetModel, g_satchel, 1)
}

public plugin_precache()
{
    g_Szsatchel_ring = precache_model("sprites/zerogxplode.spr")
    precache_sound(SzSatchSfx)
    g_fire = precache_model("sprites/laserbeam.spr")
}

@touch(iExplosive, iExplosives_Handler)
{
//    for(new list=0; list < sizeof satchel_sound; list++)
    {
        //client_cmd(iExplosives_Handler,"spk valve/sound/weapons/dryfire1.wav")
        client_cmd(iExplosives_Handler,"spk common/menu1.wav")
        //client_cmd(iExplosives_Handler, "%A", satchel_sound[list])
    }

    if(have_tool(iExplosives_Handler))
        remove_entity(iExplosive);
}

public FORWARD_SET_MODEL(iExplosive, model[])
{
    ///
    {
        if(!pev_valid(iExplosive)
        || !equal(model,"models/w_satchel.mdl")
        //|| !equal(model,"models/w_rpg.mdl")
        //|| !equal(model,"models/w_argrenade.mdl")
        //|| !equal(model,"models/crossbow_bolt.mdl")
        //|| !equal(model,"models/w_grenade.mdl")
    )
        return FMRES_IGNORED;

        new iExplosives_Handler;
        iExplosives_Handler = pev(iExplosive,pev_owner);
        if(is_user_alive(iExplosives_Handler))
        {

            if(iExplosives_Handler <1 || !is_user_connected(iExplosives_Handler))
                return FMRES_IGNORED;

            new Float:health; health = get_pcvar_float(g_health)

            set_pev(iExplosive,pev_health,health);
            set_pev(iExplosive,pev_takedamage,DAMAGE_AIM); //aim is bullets, yes is blast
            set_pev(iExplosive,pev_solid,SOLID_SLIDEBOX);

            new  SziExplosive[5];
            format(SziExplosive, charsmax(SziExplosive), "%i", iExplosive)

            client_cmd(iExplosives_Handler,"spk valve/sound/items/clipinsert1.wav")
            #if defined TEST
            if(is_user_admin(iExplosives_Handler) && !task_exists(iExplosives_Handler))
                set_task(35.0, "@test", iExplosives_Handler, SziExplosive, charsmax(SziExplosive))
            #endif

            new players[ MAX_PLAYERS ]
            new playercount

            get_players(players,playercount,"h")
            for (new m=1; m<=playercount; ++m)
            {
                new playerlocation[3]
                new iPlayer; iPlayer = players[m]
                if(is_user_connected(iPlayer))
                {
                    get_user_origin(iPlayer, playerlocation)
                    new resultdance; resultdance = get_entity_distance(iExplosive, iPlayer);
                    if(resultdance < 350)
                    {
                        new iExplosives_Handler; iExplosives_Handler = pev(iExplosive,pev_owner)
                        if(iPlayer != iExplosives_Handler)
                        {
                            fakedamage(iPlayer,"Satchel lash",get_pcvar_num(g_lash_damage)*1.0,DMG_ENERGYBEAM)
                            emit_sound(iPlayer, CHAN_BODY, SzSatchSfx, VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
                            set_pev(iExplosive,pev_effects,EF_BRIGHTFIELD);

                            if(!is_user_bot(iPlayer))
                            {
                                client_cmd iPlayer, "spk valve/sound/common/wpn_denyselect.wav"
                            }
                            else
                            {
                                emessage_begin(MSG_ONE_UNRELIABLE, g_fade,{0,0,0}, iPlayer);
                                DELAY;DELAY;FLAGS;PNK;ALPHA; //This is where one can change BLU to GRN.
                                emessage_end();
                            }
                            if(iPlayer == iExplosives_Handler)
                                goto END
                            else
                            {
                                @fume_blindness(iExplosive, iPlayer, iExplosives_Handler)
                            }
                        }

                        if(!is_user_bot(iExplosives_Handler))
                            client_cmd iExplosives_Handler,"spk valve/sound/plats/elevbell1.wav"
                    }
                }
            }
        }
    }
    END:
    return FMRES_IGNORED;
}

@fume_blindness(iExplosive, index, iExplosives_Handler)
{
    client_print iExplosives_Handler, print_chat, "Got %n.", index
    emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    ewrite_byte(TE_BEAMRING)
    ewrite_short(iExplosive)  //(start entity)
    ewrite_short(index)  //(end entity)
    ewrite_short(g_Szsatchel_ring)  //(sprite index)
    ewrite_byte(1)   //(starting frame)
    ewrite_byte(4)   //(frame rate in 0.1's)
    ewrite_byte(75)   //(life in 0.1's)
    ewrite_byte(random_num(35,75))   //(line width in 0.1's)
    ewrite_byte(10)   //(noise amplitude in 0.01's)
    ewrite_byte(random(100))   //(red)
    ewrite_byte(random_num(5,75))   //(green)
    ewrite_byte(random(75))   //(blue)
    ewrite_byte(100)   //(brightness)
    ewrite_byte(35)   //(scroll speed in 0.1's)
    emessage_end()
}

@test(SziExplosive[], iExplosives_Handler)
{
    static iBom; iBom = str_to_num(SziExplosive)
    if(is_user_admin(iExplosives_Handler) && pev_valid(iBom))
    {
        client_print iExplosives_Handler, print_chat,"Resetting your explosive..."
        set_pev(iBom,pev_owner, 0)
    }
}

/*
public client_putinserver(iExplosives_Handler)
    if(is_user_connected(iExplosives_Handler))
        get_user_name(iExplosives_Handler,ClientName[iExplosives_Handler],charsmax(ClientName[]))
*/

stock have_tool(iExplosives_Handler)
{
    return (get_user_weapon(iExplosives_Handler) == HLW_KNIFE || get_user_weapon(iExplosives_Handler) == HLW_CROWBAR || get_user_weapon(iExplosives_Handler) == HLW_PIPEWRENCH) ? 1 : 0;
}

public mortar_proximity(id)
{
    if(!have_tool(id) || !is_user_alive(id))
        return
    if(!find_ent(MaxClients, "op4mortar"))
    {
        unregister_forward(FM_PlayerPreThink, g_proximity)
        log_amx "Disabling mortar think due to no more cannons."
        return
    }

    new ent[4]
    static ents

    ent[0] = find_ent(MaxClients, "mortar_shell")

    if(ent[0])
    {
        ents = ent[0]
        ent[1] = find_ent(ent[0], "mortar_shell")
    }

    if(ent[1])
    {
        ents = ent[2]
        ent[2] = find_ent(ent[1], "mortar_shell")
    }
    if(ent[2])
    {
        ent[3] = find_ent(ent[2], "mortar_shell")
        ents = ent[3]
    }

    if(ents && pev_valid(ents))
    {

        if(entity_range(id, ents) < get_pcvar_float(g_mortar_range))
        {
            if(pev_valid(ents))
            {
                static Float:Origin[3]
                pev(ents, pev_origin, Origin)
                remove_entity(ents)
                if(is_user_connected(id))
                {
                    client_print(0, print_center,"[ %s ]^n^n%n handled a mortar shell!", PLUGIN, id );
                    client_cmd(id,"spk controller/con_die1.wav");
                    {
                        //emessage_begin( iDust > 1 ? MSG_BROADCAST : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0},  iDust > 1 ? 0 : iBotOwner[id]);
                        emessage_begin(MSG_PVS, SVC_TEMPENTITY, {0,0,0}, 0 );
                        ewrite_byte(TE_PARTICLEBURST)
                        ewrite_coord_f(Origin[0])
                        ewrite_coord_f(Origin[1])
                        ewrite_coord_f(Origin[2])
                        ewrite_short(500)//(radius)
                        ewrite_byte(random(256))
                        ewrite_byte(MAX_IP_LENGTH * 10) //(duration * 10) (will be randomized a bit)
                        emessage_end()

                        new iPlayerOrigin[3]
                        get_user_origin(id, iPlayerOrigin, 1)

                        #define TE_LIGHTNING 7          // TE_BEAMPOINTS with simplified parameters
                        new origin[3];
                        origin[0] = floatround(Origin[0]);
                        origin[1] = floatround(Origin[1]);
                        origin[2] = floatround(Origin[2]);

                        emessage_begin(MSG_PVS, SVC_TEMPENTITY, {0,0,0}, 0);
                        ewrite_byte(TE_LIGHTNING)
                        ewrite_coord(iPlayerOrigin[0])      // end position
                        ewrite_coord(iPlayerOrigin[1])
                        ewrite_coord(iPlayerOrigin[2])
                        ewrite_coord(origin[0])      // start position
                        ewrite_coord(origin[1])
                        ewrite_coord(origin[2])
                        ewrite_byte(30)       // life in 0.1's
                        ewrite_byte(50)        // width in 0.1's
                        ewrite_byte(10) // amplitude in 0.01's
                        ewrite_short(g_fire)     // sprite model index
                        emessage_end()
                    }
                }
            }
        }
    }
}

public disarm_(iExplosive, iExplosives_Handler)
{
    static szHost[MAX_NAME_LENGTH];
    static Float:null[3];
    null[0] = -5000000.0;
    null[1] = -5000000.0;
    null[2] = -5000000.0;

    if(get_pcvar_num(g_enable) && pev_valid(iExplosive) && have_tool(iExplosives_Handler))
    {
        entity_get_string(iExplosive,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))
        if(containi(g_SzMonster_class, "monster_") > MaxClients)
            replace(g_SzMonster_class,charsmax(g_SzMonster_class),"monster_","")

        client_print(0, print_center,"[ %s ]^n^n%n handled a %s.", PLUGIN, iExplosives_Handler/*ClientName[iExplosives_Handler]*/, g_SzMonster_class );

        if(equal(g_SzMonster_class,"mortar_shell"))
        {
            remove_entity(iExplosive);
        }

        if(containi(g_SzMonster_class, "penguin") > MaxClients)
        {
            iRealOwner2 = get_pdata_ent(iExplosive,  iRPenguinOwner,  LINUX_OFFSET)
            ///client_print 0, print_chat, "Disarmed Bird was owned by %n!",  is_user_connected(iRealOwner2) ? iRealOwner2 : 0
            is_user_connected(iRealOwner2) ? client_print( 0, print_chat, "Disarmed Penguin was owned by %n!",  iRealOwner2 ) :
            client_print( 0, print_chat, "Disarmed Penguin was owned by %s!",  szHost )
        }
        if(equal(g_SzMonster_class,"tripmine"))
        {
            static iLiveTripMine; iLiveTripMine = iExplosive
            if(get_pcvar_num(g_enable) == 1)
            {
                iRealOwner2 = get_pdata_ent(iLiveTripMine,  iRTripMineOwner,  LINUX_OFFSET)
                get_pcvar_string(g_Hostname, szHost, charsmax(szHost))

                entity_set_float(iLiveTripMine, EV_FL_dmg, 1.0);
                entity_set_vector(iLiveTripMine,EV_VEC_origin, null);
                @kill_mine(iLiveTripMine, iExplosives_Handler)

                client_cmd(iExplosives_Handler,"spk weapons/debris1.wav");
                is_user_connected(iRealOwner2)  ? client_print( 0, print_chat, "Disarmed Mine was owned by %n!",  iRealOwner2 ) :
                client_print( 0, print_chat, "Disarmed Mine was owned by %s!",  szHost )
            }
            else if(get_pcvar_num(g_enable) > 1 && pev(iExplosives_Handler, pev_button) & IN_DUCK && pev(iExplosives_Handler, pev_oldbuttons) & IN_DUCK )
            {
                entity_set_float(iLiveTripMine, EV_FL_dmg, 1.0);
                entity_set_vector(iLiveTripMine, EV_VEC_origin, null);
            }

        }
        if(equal(g_SzMonster_class,"satchel"))
        {
            remove_entity(iExplosive);
        }
        else
        {
            if(!pev_valid(iExplosive))
                return

            set_pev(iExplosive,pev_solid, SOLID_NOT);//teleporter stack fix
            remove_entity(iExplosive);
        }
        client_cmd(iExplosives_Handler,"spk weapons/debris3.wav");
    }

}

@kill_mine(iLiveTripMine, iExplosives_Handler)
{
    if(!pev_valid(iLiveTripMine))
    {
        client_cmd(iExplosives_Handler,"spk weapons/debris2.wav")
        return
    }

    static iBeam; iBeam = get_pdata_cbase( iLiveTripMine,  iBeamEnt , LINUX_OFFSET_WEAPONS );

    remove_entity(iBeam)
}
