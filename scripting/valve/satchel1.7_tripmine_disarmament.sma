/*Attempting disarm of several HL/OF explosives including snarks and penguins!*/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Disarmable Satchel Mine"
#define VERSION "1.7"
#define AUTHOR "SPiNX"
#define MAX_PLAYERS         32
#define MAX_NAME_LENGTH     32

#define charsmin                  -1

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

new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new g_Szsatchel_ring, g_fade

new const SzSatchSfx[]="items/airtank1.wav"
new disarmament[][]=
{
    "monster_satchel",
    "mortar_shell",
    "monster_snark",
    "monster_tripmine",
    "monster_penguin",
    "monster_babycrab",
    "monster_grenade"
}

new g_enable, g_health, gMaxPlayers
new g_SzMonster_class[MAX_NAME_LENGTH];
new g_lash_damage
const LINUX_OFFSET_WEAPONS = 4;
const LINUX_OFFSET = 20;
const LINUX_DIFF = 5;

//tripmine data
new iRealOwner2;
new iBeamEnt, iRTripMineOwner, iRPenguinOwner;

public plugin_init()
{
    gMaxPlayers = get_maxplayers()
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_SetModel,"FORWARD_SET_MODEL");

    for( new list; list < sizeof disarmament; list++)
        register_touch(disarmament[list], "player", "disarm_")
    register_touch("monster_satchel", "player", "@touch")
    g_enable = register_cvar("hl_satchel", "1")
    g_health = register_cvar("hl_satchel_health", "15")
    g_lash_damage = register_cvar("hl_satchel_lash", "15")
    g_fade = get_user_msgid("ScreenFade")

    iBeamEnt = (find_ent_data_info("CTripmineGrenade", "m_pBeam")/LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    iRTripMineOwner = (find_ent_data_info("CTripmineGrenade", "m_pRealOwner") - LINUX_OFFSET)
    iRPenguinOwner = (find_ent_data_info("CPenguinGrenade", "m_hOwner") - LINUX_OFFSET)
}

public plugin_precache()
{
    g_Szsatchel_ring = precache_model("sprites/zerogxplode.spr")
    precache_sound(SzSatchSfx)
}

@touch(iExplosive, iExplosives_Handler)
{
     client_cmd(iExplosives_Handler,"spk valve/sound/weapons/dryfire1.wav")

     if(have_tool(iExplosives_Handler))
        remove_entity(iExplosive);
}

public FORWARD_SET_MODEL(iExplosive, model[])
{
    if(get_pcvar_num(g_enable))
    {
        if(pev_valid(iExplosive) < 2
        || !equal(model,"models/w_satchel.mdl")
        //|| !equal(model,"models/w_rpg.mdl")
        //|| !equal(model,"models/w_argrenade.mdl")
        //|| !equal(model,"models/crossbow_bolt.mdl")
        //|| !equal(model,"models/w_grenade.mdl")
    )
        return FMRES_IGNORED;

        static iExplosives_Handler;
        iExplosives_Handler = pev(iExplosive,pev_owner);

        if(iExplosives_Handler <1 || !is_user_connected(iExplosives_Handler))
            return FMRES_IGNORED;

        static Float:health; health = get_pcvar_float(g_health)

        set_pev(iExplosive,pev_health,health);
        set_pev(iExplosive,pev_takedamage,DAMAGE_AIM); //aim is bullets, yes is blast
        set_pev(iExplosive,pev_solid,SOLID_SLIDEBOX);

        static SziExplosive[5]
        format(SziExplosive, charsmax(SziExplosive), "%i", iExplosive)

        client_cmd(iExplosives_Handler,"spk valve/sound/items/clipinsert1.wav")
        #if defined TEST
        if(is_user_admin(iExplosives_Handler) && !task_exists(iExplosives_Handler))
            set_task(35.0, "@test", iExplosives_Handler, SziExplosive, charsmax(SziExplosive))
        #endif

        new players[ MAX_PLAYERS ]
        new playercount

        get_players(players,playercount,"h")
        for (new m=1; m<=playercount; m++)
        {
            static playerlocation[3]
            static iPlayer; iPlayer = players[m]
            if(is_user_connected(iPlayer))
            {
                get_user_origin(iPlayer, playerlocation)
                static resultdance; resultdance = get_entity_distance(iExplosive, iPlayer);
                if(resultdance < 350)
                {
                    static iExplosives_Handler; iExplosives_Handler = pev(iExplosive,pev_owner)
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
                        if(m == iExplosives_Handler)
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
    if(is_user_admin(iExplosives_Handler) && pev_valid(iBom) > 1)
    {
        client_print iExplosives_Handler, print_chat,"Resetting your explosive..."
        set_pev(iBom,pev_owner, 0)
    }
}

public client_putinserver(iExplosives_Handler)
    if(is_user_connected(iExplosives_Handler))
        get_user_name(iExplosives_Handler,ClientName[iExplosives_Handler],charsmax(ClientName[]))

stock have_tool(iExplosives_Handler)
{
    if(get_user_weapon(iExplosives_Handler) == HLW_KNIFE || get_user_weapon(iExplosives_Handler) == HLW_CROWBAR || get_user_weapon(iExplosives_Handler) == HLW_PIPEWRENCH)
        return 1
    else
        return 0
}

public disarm_(iExplosive, iExplosives_Handler)
{
    static Float:null[3];
    null[0] = -5000000.0;
    null[1] = -5000000.0;
    null[2] = -5000000.0;

    if(get_pcvar_num(g_enable) && pev_valid(iExplosive) && have_tool(iExplosives_Handler))
    {
        entity_get_string(iExplosive,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))
        if(containi(g_SzMonster_class, "monster_") > charsmin)
            replace(g_SzMonster_class,charsmax(g_SzMonster_class),"monster_","")

        client_print(0, print_center,"[ %s ]^n^n%s handled a %s.", PLUGIN, ClientName[iExplosives_Handler], g_SzMonster_class );

        if(containi(g_SzMonster_class, "penguin") > charsmin)
        {
            iRealOwner2 = get_pdata_ent(iExplosive,  iRPenguinOwner,  LINUX_OFFSET)
            client_print 0, print_chat, "Disarmed Bird was owned by %n!",  is_user_connected(iRealOwner2) ? iRealOwner2 : 0
        }
        if(equal(g_SzMonster_class,"tripmine"))
        {
            static iLiveTripMine; iLiveTripMine = iExplosive
            if(get_pcvar_num(g_enable) == 1)
            {
                iRealOwner2 = get_pdata_ent(iLiveTripMine,  iRTripMineOwner,  LINUX_OFFSET)

                client_print 0, print_chat, "Disarmed Mine was owned by %n!",  is_user_connected(iRealOwner2) ? iRealOwner2 : 0
                entity_set_float(iLiveTripMine, EV_FL_dmg, 1.0);
                entity_set_vector(iLiveTripMine,EV_VEC_origin, null);
                @kill_mine(iLiveTripMine, iExplosives_Handler)

                client_cmd(iExplosives_Handler,"spk weapons/debris1.wav");
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
