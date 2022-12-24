/*Attempting disarm of several HL/OF explosives including snarks and penguins!*/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <hlsdk_const>

#define PLUGIN "Disarmable Satchel Mine"
#define VERSION "1.6"
#define AUTHOR "SPiNX"
#define MAX_PLAYERS         32
#define MAX_NAME_LENGTH     32
#define HLW_KNIFE           0x0019
#define HLW_PIPEWRENCH      18
#define charsmin                  -1
//#define TEST //comment out to stop admin mines test disarm.

new ClientName[MAX_PLAYERS + 1][MAX_NAME_LENGTH + 1]
new g_Szsatchel_ring

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

new g_enable, g_health
new g_SzMonster_class[MAX_NAME_LENGTH];
const LINUX_OFFSET_WEAPONS = 4;
const LINUX_DIFF = 5;

//tripmine data
#if defined TEST
new iOwner,  iRealOwner, iRealOwner2;
#endif
new iBeamEnt, iLength,  iTripMineOwner, iRTripMineOwner, SzType, SzType2, SzType3, iType, iType2, iType3;

new bool:bUNsigned
new bool:bUNsigned2
new bool:bUNsigned3
new offset_test
///////////////////
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_SetModel,"FORWARD_SET_MODEL");

    for( new list; list < sizeof disarmament; list++)
        register_touch(disarmament[list], "player", "disarm_")
    register_touch("monster_satchel", "player", "@touch")
    g_enable = register_cvar("hl_satchel", "1")
    g_health = register_cvar("hl_satchel_health", "15")

    iBeamEnt = (find_ent_data_info("CTripmineGrenade", "m_pBeam")/LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    iLength  = (find_ent_data_info("CTripmineGrenade", "m_flBeamLength")/LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
    iTripMineOwner = (find_ent_data_info("CTripmineGrenade", "m_hOwner", SzType, iType, bUNsigned) /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS //ehandle
    iRTripMineOwner = (find_ent_data_info("CTripmineGrenade", "m_pRealOwner", SzType2, iType2, bUNsigned2) /LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS  //edict_t*
    offset_test = (find_ent_data_info("CTripmine", "m_usTripFire", SzType3, iType3, bUNsigned3)/LINUX_OFFSET_WEAPONS) - LINUX_OFFSET_WEAPONS
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

        if (iExplosives_Handler<1 || !is_user_connected(iExplosives_Handler) || is_user_connecting(iExplosives_Handler) || !is_user_alive(iExplosives_Handler) || is_user_bot(iExplosives_Handler))
            return FMRES_IGNORED;

        new Float:health = get_pcvar_float(g_health)

        set_pev(iExplosive,pev_health,health);
        set_pev(iExplosive,pev_takedamage,DAMAGE_AIM); //aim is bullets, yes is blast
        set_pev(iExplosive,pev_solid,SOLID_SLIDEBOX);
        //set_pev(iExplosive,pev_movetype,MOVETYPE_FOLLOW);

        new SziExplosive[5]
        format(SziExplosive, charsmax(SziExplosive), "%i", iExplosive)

        client_cmd(iExplosives_Handler,"spk valve/sound/items/clipinsert1.wav")
        #if defined TEST
        if(is_user_admin(iExplosives_Handler) && !task_exists(iExplosives_Handler))
            set_task(35.0, "@test", iExplosives_Handler, SziExplosive, charsmax(SziExplosive))
        #endif

        new players[ MAX_PLAYERS ]
        new playercount

        get_players(players,playercount,"h")
        for (new m=0; m<playercount; m++)
        {
            new playerlocation[3]
            if(is_user_connected(players[m]))
            if(is_user_bot(players[m]) ||  !is_user_bot(players[m]))
            {
                get_user_origin(players[m], playerlocation)
                new resultdance = get_entity_distance(iExplosive, players[m]);
                if (resultdance < 350)
                {
                    new iExplosives_Handler = pev(iExplosive,pev_owner)
                    if(players[m] != iExplosives_Handler)
                    {
                        fakedamage(players[m],"Satchel lash",35.0,DMG_ENERGYBEAM)

                        emit_sound(players[m], CHAN_BODY, SzSatchSfx, VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
                        set_pev(iExplosive,pev_effects,EF_BRIGHTFIELD);

                        if(!is_user_bot(players[m]))
                            client_cmd players[m],"spk valve/sound/common/wpn_denyselect.wav"

                        emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                        ewrite_byte(TE_BEAMRING)
                        ewrite_short(iExplosive)  //(start entity)
                        ewrite_short(players[m])  //(end entity)
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

                    if(!is_user_bot(iExplosives_Handler))
                        client_cmd iExplosives_Handler,"spk valve/sound/plats/elevbell1.wav"
                }
            }
        }
    }
    return FMRES_IGNORED;
}

@test(SziExplosive[], iExplosives_Handler)
{
    new iBom = str_to_num(SziExplosive)
    if(is_user_admin(iExplosives_Handler) && pev_valid(iBom) > 1)
    {
        client_print iExplosives_Handler, print_chat,"Resetting your explosive..."
        set_pev(iBom,pev_owner, 0)
        new effects = pev(iBom, pev_effects)
        set_pev(iBom,pev_effects, (effects |~EF_BRIGHTFIELD|EF_BRIGHTLIGHT) );
        //https://www.amxmodx.org/api/hlsdk_const
    }
}

public client_putinserver(iExplosives_Handler)
    if(is_user_connected(iExplosives_Handler))
        get_user_name(iExplosives_Handler,ClientName[iExplosives_Handler],charsmax(ClientName[]))

stock have_tool(iExplosives_Handler)
    return get_user_weapon(iExplosives_Handler) == HLW_KNIFE || get_user_weapon(iExplosives_Handler) == HLW_CROWBAR || get_user_weapon(iExplosives_Handler) == HLW_PIPEWRENCH ? 1 : 0

public disarm_(iExplosive, iExplosives_Handler)
{
    new Float:null[3];
    null[0] = -5000000.0;
    null[1] = -5000000.0;
    null[2] = -5000000.0;

    if( get_pcvar_num(g_enable) && pev_valid(iExplosive) && have_tool(iExplosives_Handler))//!pev( iExplosive, pev_owner )
    {
        entity_get_string(iExplosive,EV_SZ_classname,g_SzMonster_class,charsmax(g_SzMonster_class))
        if(containi(g_SzMonster_class, "monster_") > charsmin)
            replace(g_SzMonster_class,charsmax(g_SzMonster_class),"monster_","")

        client_print(0, print_center,"[ %s ]^n^n%s handled a %s.", PLUGIN, ClientName[iExplosives_Handler], g_SzMonster_class );
        if(equal(g_SzMonster_class,"tripmine"))
        {
            new iLiveTripMine = iExplosive
            if(get_pcvar_num(g_enable) == 1)
            {
                #if defined TEST
                ///https://www.amxmodx.org/api/engine_const#edicts-use-with-entity-get-set-edict
               //iRealOwner2 = entity_get_edict(iLiveTripMine, iRTripMineOwner)  //less than 0
                iRealOwner2 = entity_get_edict2(iLiveTripMine, iRTripMineOwner)
                //iRealOwner2  = get_pdata_ent(iExplosive, iRTripMineOwner, 20) //less than 0
                if(is_user_admin(iExplosives_Handler))
                {
                    client_print iExplosives_Handler, print_chat, "Mine possibly owned by %i",  iRealOwner2
                }
                #endif
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
    // https://github.com/FWGS/halflife/blob/master/dlls/tripmine.cpp
    if(!pev_valid(iLiveTripMine))
    {
        client_cmd(iExplosives_Handler,"spk weapons/debris2.wav")
        return
    }
    //find beam
    new iBeam = get_pdata_cbase( iLiveTripMine,  iBeamEnt , LINUX_OFFSET_WEAPONS ); //perfect
    #if defined TEST
    ///set_pdata_float(iLiveTripMine, iLength,  1.0, LINUX_OFFSET_WEAPONS ); //need done when planting
    //who placed it
    new iBeamOwner = get_pdata_cbase_safe( iLiveTripMine,  iRTripMineOwner , LINUX_OFFSET_WEAPONS) //just testing

    iOwner = get_pdata_ehandle(iLiveTripMine, iTripMineOwner , 20, 20)
    //edict
    iRealOwner2 = entity_get_edict(iLiveTripMine, iRTripMineOwner)
    //report
    if(is_user_admin(iExplosives_Handler))
    {
        client_print iExplosives_Handler, print_chat, "%i | %i | %i^n %i %i %i",  iBeamEnt, iLength, iTripMineOwner, iBeam, iBeamOwner, iOwner
        client_print iExplosives_Handler, print_chat, "Mine data %i %i %i %i^n Real Owner %i|%i|%i|%i ^n hOwner %i|%i|%i|%i", offset_test, SzType3, iType3, bUNsigned3, iRealOwner2, SzType2, iType2, bUNsigned2, iRealOwner, SzType, iType, bUNsigned
    }
    #endif
    //remove beam
    remove_entity(iBeam)
}
