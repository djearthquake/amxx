/* Amxx Gauss Port by SPiNX
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 * Special Thanks to :: NiHiLaNTh [ZE] Extra Item: Tau Cannon 1.2.
 * That was where most of the base code comes from.
 *
 * Special Thanks to :: One-Eyed Jacks for introducing us to Half-Life Elite.
 * Rejuvenating the idea.
 *
 * Credits due to Half-Life Elite for concept and skins.
 * Credit due to Amxx team. Still thought this was impossible and finished all in same day.
 *
 * Changelog
 * ---------
 * 03-25-2021 Version A::
 * -Port from Zombie Plague / Jailbreak.
 * -Make weapon purchasable and amx_help view.
 * -Cvar for cost.
 * -Expanded backpack ammo, increased primary fire rate(cvar later for cost/power and overcharge mushroom cloud etc)
 * -Select stock HD model over the purposed alt model.
 * -Expand to include Half-Life Elite Gauss effects. Color control on Guass beam, molten steel bb's and heat marks.
 * -Make breakables explode when hit with beam.
 * -Make charge up sound more 'unique'.
 *
 * 03-25-2021 Version A::
 * -Color Cvars, finish tuning sound.
 * 08-21-2024 Versions A1::
 * -Added CZ Bot support
 *
 * POTENTIAL AND KNOWN ISSUES:
 * ---------------------------
 * Host_Error: CL_EntityNum: 1537 is an invalid number, cl.max_edicts is 1365
 *
   Solution:
   Add to launch.
  -heapsize 128000 -num_edicts 8192
  *
  * Picking funny numbers on color CVAR crashes.
  *
  * Solution:
  * Let me finish! Clamp applied.
 */

#include < amxmodx >
#include < amxmisc >

#include < cstrike >
#include < csx >

#include < engine >
#include < fakemeta >

#include < hamsandwich >
#include < xs >
#include < fun >

// Plugin information
#define Plugin  "Tau Cannon Port"
#define Version "A1"
#define Author  "SPINX"
// Maxplayers
const MaxPlayers = 32

// Weapon models
new const g_szModelGaussP[ ] = "models/p_gauss.mdl"
new const g_szModelGaussV[ ] = "models/v_gauss.mdl"
//new const g_szModelGaussV2[ ] = "models/v_alt_gauss.mdl"
new const g_szModelGaussW[ ] = "models/w_gauss.mdl"

// Weapon sounds
new const g_szSoundGaussFire[ ] = "weapons/gauss2.wav"
new const g_szSoundGaussSpin[ ] = "ambience/pulsemachine.wav"
new const g_szSoundElectro1[ ] = "weapons/electro4.wav"
new const g_szSoundElectro2[ ] = "weapons/electro5.wav"
new const g_szSoundElectro3[ ] = "weapons/electro6.wav"

// Some gauss/beam stuff
#define GAUSS_REFIRERATE    0.1 // Primary attack
#define GAUSS_REFIRERATE2   0.1 // Secondary attack(you shouldnt change this!)
#define GAUSS_RECOIL        -2.0 // Only X axis!
#define GAUSS_CHARGETIME    4.0 // From HLSDK
#define GAUSS_RELOADTIME    0.1 // Reload time
#define BEAM_RED        255 // Red amount
#define BEAM_GREEN      128 // Green amount
#define BEAM_BLUE       0 // Blue amount
#define BEAM_ALPHA      255 // Brightness(Alpha)
#define BALL_AMOUNT     8 // How many balls should appear :p

// Max. bp ammo amount
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
    5, 100, 900, // This is gauss max bp ammo.Change it if you want!
32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }


// Player variables
new g_iHasGauss[ MaxPlayers+1 ] // Whether player has gauss
new g_iSoundState[ MaxPlayers+1 ] // Weapon sound state
new g_bInAttack[ MaxPlayers+1 ] // Current gauss attack state
new g_iCurrentWeapon[ MaxPlayers+1 ] // Current weapon player is holding
new Float:g_flLastShotTime[ MaxPlayers+1 ] // Last shot time
new Float:g_fflPlayAfterShock[ MaxPlayers+1 ] // Play aftershock sound
new Float:g_flWeaponIdleTime[ MaxPlayers+1 ] // Weapon idle time
new Float:g_flNextAmmoBurn[ MaxPlayers+1 ] // Next ammo burn time
new Float:g_flStartCharge[ MaxPlayers+1 ] // Weapon start charge
new Float:g_flAmmoStartCharge[ MaxPlayers+1 ] // Ammo start charge
new bool:g_bIsAlive[ MaxPlayers+1 ] // Whether player is alive
new bool:g_bIsConnected[ MaxPlayers+1 ] // Whether player is connected
new bool:g_bPrimaryFire[ MaxPlayers+1 ] // Does this weapon is using primary attack ?
new bool:g_bKilledByLaser[ MaxPlayers+1 ] // Imma firin mah lazor O.o
new bool:bRegistered; //cz hambot

// CVAR pointers
new cvar_oneround // Whether gun should be only for 1 round
new cvar_dmgprim // Primary attack damage
new cvar_dmgsec // Secondary attack damage
new cvar_clip // Clip amount

// Cached CVAR
new g_pOneRound
new Float:g_pDmgPrim
new Float:g_pDmgSec
new g_pClip
new g_free_for_all

// Global varibles
new g_gauss_color_beam //beam color override CVAR
new g_debug
new g_iMaxPlayers // Maxplayers
new bool:g_bGameRestart // Detect game restart

//new g_iBeam // Beam sprite
new g_iBall0y, g_iBall1o, g_iBall2r, g_iBall3k, g_iBall4p, g_iBall5b, g_iBall6t, g_iBall7g, g_iBall8w;

//new g_iBalls // Hotglowing sparks
new g_iBeam0y, g_iBeam1o, g_iBeam2r, g_iBeam3k, g_iBeam4p, g_iBeam5b, g_iBeam6t, g_iBeam7g, g_iBeam8w;
new g_gauss_color;

//Cstrike buy system
new g_item_cost;

new g_iGaussID // Item ID
new gmsgScreenFade // Screen fade

//Decal
new g_decal;
new const choice[ ] = "{GAUSSSHOT1" //DECALS.WAD

// CS Offsets
const m_pPlayer = 41
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48
const m_iPrimaryAmmoType = 49
const m_iClip = 51
const m_fInReload = 54
const m_flNextAttack  = 83
const m_rgAmmo_player_Slot0 = 376

// Macro
#define is_user_valid_connected(%1)     ( 1 <= %1 <= g_iMaxPlayers && g_bIsConnected [ %1 ] )
#define is_user_in_water(%1)            ( pev ( %1, pev_waterlevel ) == 3 )
#define VectorSubtract(%1,%2,%3)        ( %3[ 0 ] = %1[ 0 ] - %2[ 0 ], %3[ 1 ] = %1[ 1 ] - %2[ 1 ], %3[ 2 ] = %1[ 2 ] - %2[ 2 ] )
#define VectorAdd(%1,%2,%3)             ( %3[ 0 ] = %1[ 0 ] + %2[ 0 ], %3[ 1 ] = %1[ 1 ] + %2[ 2 ], %3[ 2 ] = %1[ 2 ] + %2[ 2 ] )
#define VectorScale(%1,%2,%3)           ( %3[ 0 ] = %2 * %1[ 0 ], %3[ 1 ] = %2 * %1[ 1 ], %3[ 2 ] = %2 * %1[ 2 ] )
#define VectorLength(%1)                ( floatsqroot ( %1[ 0 ] * %1[ 0 ] + %1[ 1 ] * %1[ 1 ] + %1[ 2 ] * %1[ 2 ] ) )

// Hack!Custom fields
#define pev_weaponkey       pev_impulse
#define pev_bpammo      pev_iuser3

// Misc stuff
#define FCVAR_FLAGS     ( FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED )
#define GAUSS_WEAPONKEY 42856
#define NULLENT     -1
#define FFADE_IN        0x0000
#define UNIT_SECOND     (1<<12)

// Entity classnames
new const g_szClassPlayer[ ] = "player"
new const g_szClassM249[ ] = "weapon_m249"

// Primary weapon bitsum
const PRIMARY_WEAPONS_BITSUM =
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

// Animation sequnces
enum
{
    gauss_idle,
    gauss_idle2,
    gauss_fidget,
    gauss_spinup,
    gauss_spin,
    gauss_fire,
    gauss_fire2,
    gauss_holster,
    gauss_draw
};

// Precache
public plugin_precache( )
{
    // Weapon models
    precache_model( g_szModelGaussP  )
    precache_model( g_szModelGaussV  )
    //precache_model( g_szModelGaussV2 )
    precache_model( g_szModelGaussW  )

    // Sounds
    precache_sound( g_szSoundGaussFire )
    precache_sound( g_szSoundGaussSpin )
    precache_sound( g_szSoundElectro1 )
    precache_sound( g_szSoundElectro2 )
    precache_sound( g_szSoundElectro3 )
    precache_sound( "weapons/357_cock1.wav" )

    // Sprites
    g_iBeam0y = precache_model( "sprites/gauss_beam0.spr" )
    g_iBeam1o = precache_model( "sprites/gauss_beam1.spr" )
    g_iBeam2r = precache_model( "sprites/gauss_beam2.spr" )
    g_iBeam3k = precache_model( "sprites/gauss_beam3.spr" )
    g_iBeam4p = precache_model( "sprites/gauss_beam4.spr" )
    g_iBeam5b = precache_model( "sprites/gauss_beam5.spr" )
    g_iBeam6t = precache_model( "sprites/gauss_beam6.spr" )
    g_iBeam7g = precache_model( "sprites/gauss_beam7.spr" )
    g_iBeam8w = precache_model( "sprites/gauss_beam8.spr" )


    //yel,orange,red,pink,purple,blue,teal, grn, white
    g_iBall0y = precache_model( "sprites/gauss_spark0.spr" )
    g_iBall1o = precache_model( "sprites/gauss_spark1.spr" )
    g_iBall2r = precache_model( "sprites/gauss_spark2.spr" )
    g_iBall3k = precache_model( "sprites/gauss_spark3.spr" )
    g_iBall4p = precache_model( "sprites/gauss_spark4.spr" )
    g_iBall5b = precache_model( "sprites/gauss_spark5.spr" )
    g_iBall6t = precache_model( "sprites/gauss_spark6.spr" )
    g_iBall7g = precache_model( "sprites/gauss_spark7.spr" )
    g_iBall8w = precache_model( "sprites/gauss_spark8.spr" )


}

// Initialization
public plugin_init( )
{
    // New plugin
    register_plugin( Plugin, Version, Author )

    g_decal = engfunc(EngFunc_DecalIndex, choice)

    g_item_cost   = register_cvar("gauss_cost", "9000" )
    g_gauss_color = register_cvar("gauss_color","10" ) //random
    g_gauss_color_beam = register_cvar("gauss_beam", "000000000")

    //filter for stability
    clamp(g_gauss_color,0,10);

    // For www.gametracker.com support
    register_cvar( "tcannon_version", Version, FCVAR_FLAGS )

    register_clcmd("buy_gauss","cmd_give_tso",0,"Acquire HL Elite Gauss.");
    g_free_for_all = register_cvar("gauss_free", "1");

    // Events
    register_event( "CurWeapon", "EV_CurWeapon", "b", "1=1" )
    register_event( "DeathMsg", "EV_DeathMsg", "a" )

    if(cstrike_running())
    {
        register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" )
        register_event( "TextMsg", "EV_GameRestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in" )
    }

    // FakeMeta forwards
    register_forward( FM_SetModel, "fw_SetModel" )
    register_forward( FM_CmdStart, "fw_CmdStart" )
    register_forward( FM_UpdateClientData, "fw_UpdateClientData_Post", 1 )
    register_forward( FM_PlayerPreThink, "fw_PlayerPreThink" )

    // HamSandwich forwards
    RegisterHam( Ham_Spawn, g_szClassPlayer, "fw_PlayerSpawn_Post", 1 )
    RegisterHam( Ham_Item_Deploy, g_szClassM249, "fw_TCannonDeploy_Post", 1 )
    RegisterHam( Ham_Item_Holster, g_szClassM249, "fw_TCannonHolster_Post", 1 )
    RegisterHam( Ham_Item_AddToPlayer, g_szClassM249, "fw_TCannonAddToPlayer" )
    RegisterHam( Ham_Item_PostFrame, g_szClassM249, "fw_TCannonPostFrame" )
    RegisterHam( Ham_Weapon_Reload, g_szClassM249, "fw_TCannonReload_Post", 1 )

    // CVARs are in Load_Cvars( ) function!

    // Messages
    register_message( get_user_msgid( "DeathMsg" ), "fn_DeathMsg" )
    gmsgScreenFade = get_user_msgid( "ScreenFade" )

    // Store maxplayers in a global variable
    g_iMaxPlayers = get_maxplayers( )
    g_debug = register_cvar("gauss_debug", "0")
}

// Configuration
public plugin_cfg( )
{
    // Cache CVARs
    set_task( 1.5, "Load_Cvars" )
}

// ------------------------------- Game Events ----------------------------------------

// Client connected
public client_connect( Player )
{

        // Make a lot of updates
        g_iHasGauss[ Player ] = false
        g_bInAttack[ Player ] = 0
        g_fflPlayAfterShock[ Player ] = 0.0
        g_flWeaponIdleTime[ Player ] = 0.0
        g_bPrimaryFire[ Player ] = false
        g_bIsAlive[ Player ] = false
        g_bIsConnected[ Player ] = true
}

// Client disconnected
#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif
public client_disconnected( Player )
{
    // Only few important updates
    g_bIsAlive[ Player ] = false
    g_bIsConnected[ Player ] = false
}

public cmd_give_tso(Player, level, cid)
{
    if(!cmd_access ( Player, level, cid, 1))
        return PLUGIN_HANDLED;

    buy_gauss(Player);
    //if(get_pcvar_num(g_debug))server_print("Acquiring the ported gauss");
    return PLUGIN_HANDLED;
}

public free_gauss(Player)
{
    ze_select_item_post(Player, g_iGaussID);
    return PLUGIN_HANDLED;
}

public buy_gauss(Player)
{
    new name[MaxPlayers];

    get_user_name(Player,name,charsmax(name));

    new tmp_money = cs_get_user_money(Player);

    if ( !g_iHasGauss[ Player ]  )
    {

        if(tmp_money < get_pcvar_num(g_item_cost))
        {
            client_print(Player, print_center, "You can't afford a Gauss Rifle %s!", name);
            client_print(0, print_chat, "Hey guys %s keeps trying to buy Gauss Rifle they can't afford!", name);
            return PLUGIN_HANDLED;
        }
        else
        {
            cs_set_user_money(Player, tmp_money - get_pcvar_num(g_item_cost));
            client_print(Player, print_center, "You bought Tso Rifle!");
            ze_select_item_post(Player, g_iGaussID);
        }

    }
    else
    {
        client_print(Player, print_center, "You ALREADY OWN a Tso Cannon...");
        client_print(0, print_chat, "Hey guys %s keeps trying to buy a Gauss Rifle and already owns one!", name);
    }
    return PLUGIN_HANDLED;
}

public ze_select_item_post(Player, itemid)
{
    if (itemid != g_iGaussID)
        return

    // Drop all primary weapons
    UTIL_DropPrimary( Player )

    // Update
    g_iHasGauss[ Player ] = true

    // Give m249
    give_item( Player, "weapon_m249" )

    // Find weapon entity
    new iEnt = find_ent_by_owner( NULLENT, g_szClassM249, Player )

    // Apply new clip
    cs_set_weapon_ammo( iEnt, g_pClip )

    // Back pack ammo
    cs_set_user_bpammo( Player, CSW_M249, MAXBPAMMO[ 20 ] )
}


// Current weapon player is holding
public EV_CurWeapon( Player )
{
    // Not alive
    if( !g_bIsAlive[ Player ] )
        return PLUGIN_CONTINUE

    // Update
    g_iCurrentWeapon[ Player ] = read_data( 2 )

   /*
    //Get and check weapon ID
    new weaponID = read_data( 2 )

    if(weaponID==CSW_C4 || weaponID==CSW_KNIFE || weaponID==CSW_HEGRENADE || weaponID==CSW_SMOKEGRENADE || weaponID==CSW_FLASHBANG)
        return PLUGIN_CONTINUE

    if(weaponID==CSW_M249)
        if (cs_get_user_bpammo(Player, weaponID) != CSW_MAXAMMO[weaponID])
            cs_set_user_bpammo(Player, weaponID, CSW_MAXAMMO[weaponID])
    */

    return PLUGIN_CONTINUE
}

// Someone died
public EV_DeathMsg( )
{
    // Get victim
    static iVictim
    iVictim = read_data( 2 )

    // Not connected
    if( !is_user_valid_connected( iVictim ) )
        return

    // Update
    g_bIsAlive[ iVictim ] = false

    // Check if victim has gauss
    if( g_iHasGauss[ iVictim ] && !is_user_bot( iVictim ) )
    {
        // Force to drop
        engclient_cmd( iVictim, "drop weapon_m249" )
    }
}

// Round started
public EV_RoundStart( )
{
    // Restart/One round only
    if( g_bGameRestart || g_pOneRound )
    {
        // Reset array value
        arrayset( g_iHasGauss, false, MaxPlayers+1 )
    }

    // Update
    g_bGameRestart = false
}

// Game restart
public EV_GameRestart( )
{
    // Update
    g_bGameRestart = true
}

// Hook death message
public fn_DeathMsg( Player, Dest, iEntity )
{
    // Get victim
    static iVictim, iKiller
    iKiller = get_msg_arg_int( 1 )
    iVictim = get_msg_arg_int( 2 )

    // Not connected
    if( !is_user_valid_connected( iVictim ) || iKiller == iVictim )
        return PLUGIN_CONTINUE

    // We were killed by laser
    if ( g_bKilledByLaser[ iVictim ] )
    {
        // Replace name in console
        set_msg_arg_string ( 4, "tau cannon" )
    }
    return PLUGIN_CONTINUE
}

// ------------------------------- Forwards ----------------------------------------

// Replace world model
public fw_SetModel ( Entity, const Model [ ] )
{
    // Prevent invalid entity messages
    if( !pev_valid( Entity ) )
        return FMRES_IGNORED

    // Not w_awp.mdl
    if( !equal( Model, "models/w_m249.mdl" ) )
        return FMRES_IGNORED

    // Get entity classname
    static szClassname[ 32 ]
    pev( Entity, pev_classname, szClassname, charsmax( szClassname ) )

    // Not weaponbox
    if( !equal( szClassname, "weaponbox" ) )
        return FMRES_IGNORED

    // Get owner
    static iOwner
    iOwner = pev( Entity, pev_owner )

    // Get awp ID
    static iWeaponID
    iWeaponID = find_ent_by_owner( NULLENT, g_szClassM249, Entity )

    // Make sure that we have gauss
    if( g_iHasGauss [ iOwner ] && is_valid_ent( iWeaponID ) )
    {
        // Hack! Store weaponkey
        set_pev( iWeaponID, pev_weaponkey, GAUSS_WEAPONKEY )

        // Hack! Store bp ammo
        set_pev( iWeaponID, pev_bpammo, cs_get_user_bpammo( iOwner, CSW_M249 ) )

        // Update
        g_iHasGauss[ iOwner ] = false

        // Replace models
        engfunc( EngFunc_SetModel, Entity, g_szModelGaussW )
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

// Command start
public fw_CmdStart( Player, UC_Handle, Seed )
{
    // Not alive/dont have gauss/not m249
    if( !g_bIsAlive[ Player ] || !g_iHasGauss[ Player ] || g_iCurrentWeapon[ Player ] != CSW_M249 )
        return FMRES_IGNORED

    // Retrieve pressed button bitsum
    static iButtons
    iButtons = get_uc( UC_Handle, UC_Buttons )

    // Retrieve game time
    static Float:flGameTime
    flGameTime = get_gametime( )

    // Retrieve weapon entity
    static iEnt
    iEnt = find_ent_by_owner( NULLENT, g_szClassM249, Player )

    // Retrieve clip amount
    static iClip
    iClip = cs_get_weapon_ammo( iEnt )

    // Primary attack
    if( iButtons & IN_ATTACK )
    {
        // Remove attack buttons from their button mask
        iButtons &= ~IN_ATTACK
        set_uc( UC_Handle, UC_Buttons, iButtons )

        // Prevent too fast shooting
        if( flGameTime - g_flLastShotTime[ Player ] < GAUSS_REFIRERATE )
            return FMRES_IGNORED

        // Dont fire while reloading
        if( get_pdata_int( iEnt, m_fInReload, 4 ) )
            return FMRES_IGNORED

        // Not enough clip/under water
        if( iClip < 2 || is_user_in_water( Player ) )
        {
            // Emit empty sound
            ExecuteHamB( Ham_Weapon_PlayEmptySound, iEnt )
            return FMRES_IGNORED
        }

        // Update
        g_bPrimaryFire[ Player ] = true

        // Start to fire
        StartFire( Player )

        // Decrease clip
        cs_set_weapon_ammo( iEnt, iClip-2 )

        // Reset weapon attack status
        g_bInAttack[ Player ] = 0

        // Set time when idle animation should be played
        g_flWeaponIdleTime[ Player ] = flGameTime + 1.0

        // Remember last shot time
        g_flLastShotTime[ Player ] = flGameTime
    }
    // Secondary attack
    else if( iButtons & IN_ATTACK2 )
    {
        // Prevent too fast shooting
        if( flGameTime - g_flLastShotTime[ Player ] < GAUSS_REFIRERATE2 )
            return FMRES_IGNORED

        // Dont fire while reloading
        if( get_pdata_int( iEnt, m_fInReload, 4 ) )
            return FMRES_IGNORED

        // Are we swimming ?
        if( is_user_in_water( Player ) )
        {
            // We are in a middle of attack
            if( g_bInAttack[ Player ] != 0 )
            {
                // Stop attack
                emit_sound( Player, CHAN_WEAPON, g_szSoundElectro1, VOL_NORM, ATTN_NORM, 0, 80 + random_num( 0, 0x3f ) )

                // Gun idle
                UTIL_PlayWeaponAnimation( Player, gauss_idle )
                return FMRES_IGNORED
            }
            else
            {
                // Empty sound
                ExecuteHam( Ham_Weapon_PlayEmptySound, iEnt )
                return FMRES_IGNORED
            }
        }

        // Get player oldbuttons
        static iOldButtons
        iOldButtons = pev( Player, pev_oldbuttons )

        // Make sure that we are holding secondary attack button
        if( iOldButtons & IN_ATTACK2 )
        {
            // Which attack state do we have
            switch ( g_bInAttack[ Player ] )
            {
                case 0: // Attack start
                {
                    // Out of ammo
                    if ( iClip <= 0 )
                    {
                        ExecuteHam( Ham_Weapon_PlayEmptySound, iEnt )
                        return FMRES_IGNORED
                    }

                    // We aren't using primary attack anymore
                    g_bPrimaryFire[ Player ] = false

                    // Decrease clip
                    cs_set_weapon_ammo( iEnt, --iClip )

                    // Update
                    g_flNextAmmoBurn[ Player ] = flGameTime

                    // Send spinup animation
                    UTIL_PlayWeaponAnimation( Player, gauss_spinup )

                    // Update attack state
                    g_bInAttack[ Player ] = 1

                    // Next idle time
                    g_flWeaponIdleTime[ Player ] = flGameTime + 0.5

                    // Update
                    g_flStartCharge[ Player ] = flGameTime
                    g_flAmmoStartCharge[ Player ] = flGameTime + GAUSS_CHARGETIME

                    // Update sound state
                    g_iSoundState[ Player ] = 0

                    // Spin sound
                    emit_sound( Player, CHAN_WEAPON, g_szSoundGaussSpin, VOL_NORM, ATTN_NORM, g_iSoundState[Player ], 110 )

                    // Change sound state
                    g_iSoundState[ Player ] = SND_CHANGE_PITCH
                }
                case 1: // In a middle of attack
                {
                    if( g_flWeaponIdleTime[ Player ] < flGameTime )
                    {
                        // Spin anim
                        UTIL_PlayWeaponAnimation( Player, gauss_spin )

                        // Update state
                        g_bInAttack[ Player ] = 2
                    }
                }
                default: // End of attack
                {
                    // During the charging process, eat one bit of ammo every once in a while
                    if( flGameTime >= g_flNextAmmoBurn[ Player ] && g_flNextAmmoBurn[ Player ] != 1000 )
                    {
                        // Decrease clip
                        cs_set_weapon_ammo( iEnt, --iClip )

                        // Next time when ammo should be decreased
                        g_flNextAmmoBurn[ Player ] = flGameTime + 0.1
                    }

                    // Shit!We run out of ammo
                    if( iClip <= 0 )
                    {
                        // Force gun to fire
                        StartFire( Player )

                        // Reset weapon state
                        g_bInAttack[ Player ] = 0

                        // Set next idle time
                        g_flWeaponIdleTime[ Player ] = flGameTime + 1.0
                    }

                    // Gun is fully charged up
                    if( flGameTime >= g_flAmmoStartCharge[ Player ] )
                    {
                        // Dont eat any more ammo!
                        g_flNextAmmoBurn[ Player ] = 1000.0
                    }

                    // Calculate pitch
                    static Float:flPitch
                    //flPitch = ( flGameTime - g_flStartCharge[ Player ] ) * ( 150 / GAUSS_CHARGETIME ) + 100
                    flPitch = ( flGameTime - g_flStartCharge[ Player ] ) * ( random_num(50,350) / GAUSS_CHARGETIME ) + random_num(50,350)

                    // Pitch shouldnt be THAT big
                    if ( flPitch > 250 )
                    {
                        flPitch = 250.0 //Anything over "250.0" will crash.
                    }

                    // Spin sound
                    emit_sound( Player, CHAN_WEAPON, g_szSoundGaussSpin, VOL_NORM, ATTN_NORM, ( g_iSoundState[ Player ] == SND_CHANGE_PITCH ) ? 1 : 0, floatround( flPitch ) )

                    // Hack for going through level transitions
                    g_iSoundState[ Player ] = SND_CHANGE_PITCH

                    // We are charing way too long!
                    if( g_flStartCharge[ Player ] < flGameTime - 10 )
                    {
                        // ZAP!
                        emit_sound( Player, CHAN_WEAPON, g_szSoundElectro1, VOL_NORM, ATTN_NORM, 0, 80 + random_num( 0, 0x3f ) )
                        emit_sound( Player, CHAN_VOICE, g_szSoundElectro3, VOL_NORM, ATTN_NORM, 0, 80 + random_num( 0, 0x3f ) )

                        // Reset fire state
                        g_bInAttack[ Player ] = 0

                        // Next idle time
                        g_flWeaponIdleTime[ Player ] = flGameTime + 1.0

                        // Damage player
                        ExecuteHamB( Ham_TakeDamage, Player, 0, Player, 50.0, DMG_SHOCK )

                        // Make screen fade
                        UTIL_ScreenFade( Player, UNIT_SECOND*2, UNIT_SECOND/2, FFADE_IN, 255, 128, 0, 128 )

                        // Idle animation
                        UTIL_PlayWeaponAnimation( Player, gauss_idle )
                    }
                }
            }

            // Update
            g_flLastShotTime[ Player ] = flGameTime
        }
    }

    return FMRES_HANDLED
}

// Update client data post
public fw_UpdateClientData_Post ( Player, SendWeapons, CD_Handle )
{
    // Not alive / dont have gauss/ not m249
    if ( !g_bIsAlive [ Player ] || !g_iHasGauss [ Player ] || g_iCurrentWeapon [ Player ] != CSW_M249 )
        return FMRES_IGNORED

    // Block default sounds/animations
    set_cd ( CD_Handle, CD_flNextAttack, halflife_time ( ) + 0.001 )
    return FMRES_HANDLED
}

// Player pre think
public fw_PlayerPreThink( Player )
{
    if(is_user_connected( Player ))
    {
        // Not alive / dont have gauss/ not m249
        if ( !g_bIsAlive [ Player ] || !g_iHasGauss [ Player ] || g_iCurrentWeapon [ Player ] != CSW_M249 )
            return

        // Play aftershock discharge
        if( g_fflPlayAfterShock[ Player ] && g_fflPlayAfterShock[ Player ] < get_gametime( ) )
        {
            // Randomly play sound
            switch( random_num(0, 3 ) )
            {
                case 0: emit_sound( Player, CHAN_WEAPON, g_szSoundElectro1,random_float( 0.7, 0.8 ), ATTN_NORM, 0, PITCH_NORM )
                    case 1: emit_sound( Player, CHAN_WEAPON, g_szSoundElectro2,random_float( 0.7, 0.8 ), ATTN_NORM, 0, PITCH_NORM )
                    case 2: emit_sound( Player, CHAN_WEAPON, g_szSoundElectro3,random_float( 0.7, 0.8 ), ATTN_NORM, 0, PITCH_NORM )
                    case 3: return // No sound
                }

            // Reset discharge
            g_fflPlayAfterShock[ Player ] = 0.0
        }

        // Check if we are in a middle of attack
        if( g_bInAttack[ Player ] != 0 )
        {
            // Check if have released attack2 button
            if( get_gametime( ) - g_flLastShotTime[ Player ] > 0.2 )
            {
                // Start to fire
                StartFire( Player )

                // Reset attack state
                g_bInAttack[ Player ] = 0

                // Next idle time
                g_flWeaponIdleTime[ Player ] = get_gametime( ) + 2.0
            }
        }
        else
        {
            // Force to idle
            WeaponIdle( Player )
        }
    }
}

// Player respawned
public fw_PlayerSpawn_Post( Player )
{
    // Not alive
    if( !is_user_alive( Player ) )
        return

    // Update
    g_bIsAlive[ Player ] = true
    if(get_pcvar_num(g_free_for_all))
    {
        free_gauss(Player)
    }
}

// Gauss deploy
public fw_TCannonDeploy_Post( iEnt )
{
    // Get owner
    static Player
    Player = get_pdata_cbase( iEnt, m_pPlayer, 4 )

    if(!is_user_valid_connected(Player) || !(get_user_weapon(Player) & CSW_M249))   return

    // Does this player has gauss?
    if ( g_iHasGauss[ Player ] )
    {
        // Replace models
        set_pev( Player, pev_viewmodel2, g_szModelGaussV )

        set_pev( Player, pev_weaponmodel2, g_szModelGaussP )

        // Deploy animation
        UTIL_PlayWeaponAnimation( Player, gauss_draw )

        // Reset aftershock
        g_fflPlayAfterShock[ Player ] = 0.0
    }
}

// Gauss holster
public fw_TCannonHolster_Post( iEnt )
{
    // Get owner
    static Player
    Player = get_pdata_cbase( iEnt, m_pPlayer, 4 )

    // Does this player has gauss?
    if ( g_iHasGauss[ Player ] )
    {
        // Check if player is still attacking
        if( g_bInAttack[ Player ] )
        {
            // Bug!Bug!Stop spin sound
            emit_sound( Player, CHAN_WEAPON, g_szSoundGaussSpin, 0.0, 0.0, SND_STOP, 0 )

            // Attack
            StartFire( Player )
        }

        // Holster animation
        UTIL_PlayWeaponAnimation( Player, gauss_holster )

        // Reset attack status
        g_bInAttack[ Player ] = 0
    }
}

// Add Gauss to players inventory
public fw_TCannonAddToPlayer( iEnt, Player )
{
    // Prevent run-time errors
    if( is_valid_ent( iEnt ) && is_user_valid_connected( Player ) )
    {
        // Seems that player has picked up a gauss
        if( pev( iEnt, pev_weaponkey ) == GAUSS_WEAPONKEY )
        {
            // Update variable
            g_iHasGauss[ Player ] = true

            // Update bp ammo
            cs_set_user_bpammo( Player, CSW_M249, pev( iEnt, pev_bpammo ) )

            // Reset weapon options
            set_pev( iEnt, pev_weaponkey, 0 )
            set_pev( iEnt, pev_bpammo, 0 )

            return HAM_HANDLED
        }
    }
    return HAM_IGNORED
}

// Gauss post frame
public fw_TCannonPostFrame( iEnt )
{
    // Get owner
    static iOwner
    iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4)

    if(!is_valid_ent(iEnt) || !is_user_valid_connected(iOwner)) return

    // Does this player has gauss?
    if ( g_iHasGauss[ iOwner ] )
    {
        // Reload offset
        static fInReload
        fInReload = get_pdata_int ( iEnt, m_fInReload,4 )

        // Next attack time
        static Float:flNextAttack
        flNextAttack = get_pdata_float (iOwner, m_flNextAttack, 5)

        // Clip
        static iClip
        iClip = get_pdata_int ( iEnt, m_iClip, 4 )

        // Ammo type
        static iAmmoType
        iAmmoType = m_rgAmmo_player_Slot0 + get_pdata_int ( iEnt, m_iPrimaryAmmoType, 4 )

        // BP ammo
        static iBpAmmo
        iBpAmmo = get_pdata_int ( iOwner, iAmmoType, 5 )

        // Reloading
        if ( fInReload && flNextAttack <= 0.0 )
        {
            // Calculate the difference
            static j
            j = min ( g_pClip - iClip, iBpAmmo )

            // Set new clip
            set_pdata_int ( iEnt, m_iClip, iClip + j, 4 )

            // Decrease 'x' bullets from backpack(depending on new clip)
            set_pdata_int( iOwner, iAmmoType, iBpAmmo-j, 5 )

            // Not reloding anymore
            set_pdata_int ( iEnt, m_fInReload, 0, 4 )
            fInReload = 0
        }

        // Get buttons
        static iButton ; iButton = pev ( iOwner, pev_button)

        // Attack/Attack2 buttons and next prim/sec attack time hasnt' come yet
        if( ( iButton & IN_ATTACK2 && get_pdata_float ( iEnt, m_flNextSecondaryAttack, 4 ) <= 0.0)
        || ( iButton & IN_ATTACK && get_pdata_float ( iEnt, m_flNextPrimaryAttack, 4 ) <= 0.0) )
        {
            return
        }

        // Reload button / not reloading
        if( iButton & IN_RELOAD && !fInReload )
        {
            // Old clip is more/equal than/to new
            if( iClip >= g_pClip )
            {
                // Remove reload button
                set_pev ( iOwner, pev_button, iButton & ~IN_RELOAD )

                // Idle animation
                UTIL_PlayWeaponAnimation ( iOwner, gauss_idle )

                // Idle time
                g_flWeaponIdleTime[ iOwner ] = get_gametime( ) + 0.5
            }
            else
            {
                // Out of ammo
                if ( !iBpAmmo )
                    return

                // Reload weapon
                UTIL_WeaponReload ( iOwner, iEnt )
            }
        }
    }
}

// Gauss reload post
public fw_TCannonReload_Post( iEnt )
{
    // Get owner
    static Player
    Player = get_pdata_cbase( iEnt, m_pPlayer, 4 )

    // Does this player has gauss and is he in a middle of reloading ?
    if ( g_iHasGauss[ Player ] && get_pdata_int( iEnt, m_fInReload, 4 ) )
    {
        // Reload
        UTIL_WeaponReload( Player, iEnt )
    }
}

// ------------------------------- Internal Functions ----------------------------------------

// Gauss start fire
public StartFire( Player )
{
    // This var holds damage
    static Float:flDamage

    // Make vectors
    UTIL_MakeVectors( Player )

    // Get gametime
    static Float:flGameTime
    flGameTime = get_gametime( )

    // This is maximal possible damage from secondary attack!
    if( flGameTime - g_flStartCharge[ Player ] > GAUSS_CHARGETIME )
    {
        flDamage = g_pDmgSec
    }
    else
    {
        // The longer you hold attack button - the bigger is damage
        flDamage = g_pDmgSec * ( ( flGameTime - g_flStartCharge[ Player ] ) / GAUSS_CHARGETIME )
    }

    // Primary attack do less damage
    if( g_bPrimaryFire[ Player ] )
    {
        flDamage = g_pDmgPrim
    }

    // Make sure that we are not ending attack
    if( g_bInAttack[ Player ] != 3 )
    {
        // Secondary attack can pop you up in the air.Not primary attack!
        if( !g_bPrimaryFire[ Player ] )
        {
            // Current players velocity
            static Float:flVel[ 3 ], Float:v_forward[ 3 ]
            pev( Player, pev_velocity, flVel )
            global_get( glb_v_forward, v_forward )

            // Try to affect only vertical velocity
            VectorMS( flVel, flDamage * 5.0, v_forward, flVel )

            // Jump!
            set_pev( Player, pev_velocity, flVel )
        }
    }

    // Recoil
    static Float:flRecoil[ 3 ]
    flRecoil[ 0 ] = GAUSS_RECOIL
    set_pev( Player, pev_punchangle, flRecoil )

    // Fire animation
    UTIL_PlayWeaponAnimation( Player, gauss_fire2 )

    // Fire sound
    static Float:flResult
    flResult = 0.5 + flDamage * ( 1.0 / 400.0 )

    if( flResult > 1.0 )
    {
        flResult = 1.0
    }

    emit_sound( Player, CHAN_WEAPON, g_szSoundGaussFire, flResult, ATTN_NORM, 0, 85 + random_num( 0, 31 ) ) //0x1f

    // Get players aimpoint position
    static Float:vecDest[ 3 ]
    global_get( glb_v_forward, vecDest )

    // Calculate start position
    static Float:vecSrc[ 3 ]
    UTIL_GetGunPosition( Player, vecSrc )

    // Time until aftershock 'static discharge' sound
    g_fflPlayAfterShock[ Player ] = flGameTime + random_float( 0.3, 0.8 )

    // Fire!
    Fire( Player, vecSrc, vecDest, flDamage )
}

// Fire!
Fire( Player, Float:vecOrigSrc[ ], Float:vecDir[ ], Float:flDamage )
{
    //floatround(get_pcvar_num(g_gauss_color))
    clamp(get_pcvar_num(g_gauss_color),0,10);
    // Start position
    static Float:vecSrc[ 3 ]
    xs_vec_copy( vecOrigSrc, vecSrc )

    // Calculate end position
    static Float:vecDest[ 3 ]
    VectorMA( vecSrc, 8192.0, vecDir, vecDest )

    // Few trace handles
    static tr, beam_tr

    // Max fraction
    static Float:flMaxFrac
    flMaxFrac = 1.0

    // Total
    static nTotal
    nTotal = 0

    // Does this beam punched the wall ?
    static bool:fHasPunched
    fHasPunched = false

    // Does this is first beam
    static bool:fFirstBeam
    fFirstBeam = true

    // Max hits
    static nMaxHits
    nMaxHits = 10

    // Entity whoch should be ignored
    static pEntToIgnore

    // Make sure that beam will'be able to cause damage
    while( flDamage > 10 && nMaxHits > 0 )
    {
        // Decrease hit count
        nMaxHits--

        // Draw a trace line
        engfunc( EngFunc_TraceLine, vecSrc, vecDest, DONT_IGNORE_MONSTERS, pEntToIgnore, tr )

        // We'll never get outside!
        if( get_tr2( tr, TR_AllSolid ) )
            break

        // Get entity which was hit
        static pEntity
        pEntity = Instance( get_tr2( tr, TR_pHit ) )

        // Get vector end position
        static Float:vecEnd[ 3 ]
        get_tr2( tr, TR_vecEndPos, vecEnd )

        // Its first beam
        if( fFirstBeam )
        {
            if(get_pcvar_num(g_debug))server_print("Doing 1st gauss beam!");
            // Add muzzleflash
            set_pev( Player, pev_effects, pev(Player, pev_effects) | EF_MUZZLEFLASH )

            // Its not first anymore
            fFirstBeam = false

            // Add
            nTotal += 26

            // Draw beam
            engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 )
            write_byte( TE_BEAMENTPOINT ) // Temp. entity ID
            write_short( Player | 0x1000) // Start entity
            engfunc( EngFunc_WriteCoord, vecEnd[ 0 ] ) // End position X
            engfunc( EngFunc_WriteCoord, vecEnd[ 1 ] ) // End position Y
            engfunc( EngFunc_WriteCoord, vecEnd[ 2 ] ) // End position Z

            if(get_pcvar_num(g_gauss_color) == 0)
                write_short(g_iBeam0y) //g_iBeam
            if(get_pcvar_num(g_gauss_color) == 1)
                write_short(g_iBeam1o)
            if(get_pcvar_num(g_gauss_color) == 2)
                write_short(g_iBeam2r)
            if(get_pcvar_num(g_gauss_color) == 3)
                write_short(g_iBeam3k)
            if(get_pcvar_num(g_gauss_color) == 4)
                write_short(g_iBeam4p)
            if(get_pcvar_num(g_gauss_color) == 5)
                write_short(g_iBeam5b)
            if(get_pcvar_num(g_gauss_color) == 6)
                write_short(g_iBeam6t)
            if(get_pcvar_num(g_gauss_color) == 7)
                write_short(g_iBeam7g)
            if(get_pcvar_num(g_gauss_color) == 8)
                write_short(g_iBeam8w)
            else
            if(get_pcvar_num(g_gauss_color) >= 9)
            {
                switch(random_num(0,8))
                {
                    case 0: write_short(g_iBeam0y);
                    case 1: write_short(g_iBeam1o);
                    case 2: write_short(g_iBeam2r);
                    case 3: write_short(g_iBeam3k);
                    case 4: write_short(g_iBeam4p);
                    case 5: write_short(g_iBeam5b);
                    case 6: write_short(g_iBeam6t);
                    case 7: write_short(g_iBeam7g);
                    case 8: write_short(g_iBeam8w);
                }
            }
            write_byte( 0 ) // Start frame
            write_byte( 1 ) // Frame rate
            write_byte( 1 ) // Life
            write_byte( g_bPrimaryFire[ Player ] ? 16 : 25 ) // Line width
            write_byte( 0 ) // Noise amplitude
            if(!get_pcvar_num(g_gauss_color_beam))
            {
                write_byte( 255 ) //r
                write_byte( 255 ) //g
                write_byte( 255 ) //b
            }
            else
            {
                write_byte( BEAM_RED ) //r
                write_byte( BEAM_GREEN ) //g
                write_byte( BEAM_BLUE ) //b
            }

            write_byte( BEAM_ALPHA ) // Alpha 255
            write_byte( 0 ) // Scroll speed
            message_end( )
        }
        else
        {
            if(get_pcvar_num(g_debug))server_print("Doing subsequent gauss beam!");
            // Draw beam
            engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 )
            write_byte( TE_BEAMPOINTS ) // Temp. entity ID
            engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] ) // Start position X
            engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] ) // Start position Y
            engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] ) // Start position Z
            engfunc( EngFunc_WriteCoord, vecEnd[ 0 ] ) // End position X
            engfunc( EngFunc_WriteCoord, vecEnd[ 1 ] ) // End position Y
            engfunc( EngFunc_WriteCoord, vecEnd[ 2 ] ) // End position Z

            if(get_pcvar_num(g_gauss_color) == 0)
                write_short(g_iBeam0y) //g_iBeam
            if(get_pcvar_num(g_gauss_color) == 1)
                write_short(g_iBeam1o)
            if(get_pcvar_num(g_gauss_color) == 2)
                write_short(g_iBeam2r)
            if(get_pcvar_num(g_gauss_color) == 3)
                write_short(g_iBeam3k)
            if(get_pcvar_num(g_gauss_color) == 4)
                write_short(g_iBeam4p)
            if(get_pcvar_num(g_gauss_color) == 5)
                write_short(g_iBeam5b)
            if(get_pcvar_num(g_gauss_color) == 6)
                write_short(g_iBeam6t)
            if(get_pcvar_num(g_gauss_color) == 7)
                write_short(g_iBeam7g)
            if(get_pcvar_num(g_gauss_color) == 8)
                write_short(g_iBeam8w)
            else
            if(get_pcvar_num(g_gauss_color) >= 9)
            {
                switch(random_num(0,8))
                {
                    case 0: write_short(g_iBeam0y);
                    case 1: write_short(g_iBeam1o);
                    case 2: write_short(g_iBeam2r);
                    case 3: write_short(g_iBeam3k);
                    case 4: write_short(g_iBeam4p);
                    case 5: write_short(g_iBeam5b);
                    case 6: write_short(g_iBeam6t);
                    case 7: write_short(g_iBeam7g);
                    case 8: write_short(g_iBeam8w);
                }
            }

            write_byte( 0 ) // Start frame
            write_byte( 1 ) // Frame rate
            write_byte( 1 ) // Life
            write_byte( g_bPrimaryFire[ Player ] ? 15 : 25 ) // Line width
            write_byte( 0 ) // Noise amplitude

            if(!get_pcvar_num(g_gauss_color_beam))
            {
                write_byte( 255 ) //r
                write_byte( 255 ) //g
                write_byte( 255 ) //b
            }
            else
            {
                write_byte( BEAM_RED ) //r
                write_byte( BEAM_GREEN ) //g
                write_byte( BEAM_BLUE ) //b
            }
            write_byte( BEAM_ALPHA ) //255 Alpha
            write_byte( 0 ) // Scroll speed
            message_end( )
        }

        // Check if this entity should take any damage
        if( pev( pEntity, pev_takedamage ) != DAMAGE_NO )
        {
            if(get_pcvar_num(g_debug))server_print("Gauss damage no");
            // Check if this is player and zombie
            if( pEntity != Player) //no foot shooting!
            {
                // Retrieve health
                static iHealth
                iHealth = pev( pEntity, pev_health )

                if( !is_user_valid_connected( pEntity ) )
                {
                    ExecuteHam( Ham_TakeDamage, pEntity, 0, Player, flDamage, DMG_SONIC )
                    //make sure breakables pop
                    if(is_valid_ent( pEntity) || iHealth < -50)

                        dllfunc(DLLFunc_Use, pEntity, 0)
                }

                // We should be alive
                if( iHealth - flDamage >= 1 )
                {
                    // Cause some damage
                    ExecuteHam( Ham_TakeDamage, pEntity, 0, Player, flDamage, DMG_BULLET | DMG_ALWAYSGIB )

                }
                else
                {
                    // Die
                    if(get_pcvar_num(g_debug))server_print("Gauss damage kill")
                    g_bKilledByLaser[ pEntity ] = true
                    ExecuteHamB( Ham_Killed, pEntity, Player, 2 )
                    g_bKilledByLaser[ pEntity ] = false
                }
            }
        }

        // Check if this entity should reflect our beam
        if( ReflectGauss( pEntity ) )
        {
            if(get_pcvar_num(g_debug))server_print("Gauss should reflect?")
            static Float:n

            // Return normal vector in a spot we hit
            static Float:vecPlaneNormal[ 3 ]
            get_tr2( tr, TR_vecPlaneNormal, vecPlaneNormal )

            // Calculate dot product
            n = - xs_vec_dot( vecPlaneNormal, vecDir )

            // 60 degrees
            if ( 0 < n < 0.5 )
            {
                static Float:r[ 3 ]
                VectorMA( vecDir, 2.0 * n, vecPlaneNormal, r )

                // Get vector end position
                get_tr2( tr, TR_vecEndPos, vecEnd )

                // Get trace fraction
                static Float:trflFraction
                get_tr2( tr, TR_flFraction, trflFraction )

                // Calculate fraction
                flMaxFrac = flMaxFrac - trflFraction

                // Copy vectors
                xs_vec_copy( r, vecDir )

                // Make more vector calculations
                VectorMA( vecEnd, 8.0, vecDir, vecSrc )
                VectorMA( vecSrc, 8192.0, vecDir, vecDest )

                // Undone!Do radius damage

                // Increase
                nTotal += 34

                if( n == 0 )
                {
                    // Lose energy
                    n = 0.1
                }

                // Calculate new damage
                flDamage = flDamage * ( 1 - n )
            }
            else
            {
                if(get_pcvar_num(g_debug))server_print("Gauss decal")
                // Add gun shot decal on the world
                FX_GunShotDecal( vecEnd, pEntity )

                // Add glowing sprite on the world
                FX_TempSprite( vecEnd, 6, floatround( flDamage / 255.0 ) )

                // Increase
                nTotal += 13

                // Limit it to one hole punch
                if( fHasPunched )
                    break

                // Update
                fHasPunched = true

                // Try punching through wall if secondary attack (primary is incapable of
                // breaking through)
                if( !g_bPrimaryFire[ Player ] )
                {
                    // Retrieve vector end position
                    get_tr2( tr, TR_vecEndPos, vecEnd )

                    // Modify start origin
                    static Float:vecStart[ 3 ]
                    VectorMA( vecEnd, 8.0, vecDir, vecStart )

                    // Draw another trace line
                    engfunc( EngFunc_TraceLine, vecSrc, vecDest, DONT_IGNORE_MONSTERS, pEntToIgnore, beam_tr )

                    // We'll never get outside
                    if( !get_tr2( beam_tr, TR_AllSolid ) )
                    {
                        // Get end position
                        static Float:vecBeamEndPos[ 3 ]
                        get_tr2( beam_tr, TR_vecEndPos, vecBeamEndPos )

                        // Trace backwards to find exit point
                        engfunc( EngFunc_TraceLine, vecBeamEndPos, vecEnd, DONT_IGNORE_MONSTERS, pEntToIgnore, beam_tr )

                        // Again get end position
                        get_tr2( beam_tr, TR_vecEndPos, vecBeamEndPos )

                        static Float:ns, Float:vecSub[ 3 ]

                        // Subtract vectors
                        xs_vec_sub( vecBeamEndPos, vecEnd, vecSub )

                        // Get vector length
                        ns = xs_vec_len( vecSub )

                        if( ns < flDamage )
                        {
                            // Lose enery
                            if( ns == 0 )
                            {
                                ns = 1.0
                            }

                            // Decrease damage
                            flDamage -= ns

                            // Subtract
                            static Float:vecCalc[ 3 ]
                            VectorSubtract( vecEnd, vecDir, vecCalc )

                            // Absorbtion balls
                            FX_SpriteTrail( vecEnd, vecCalc, BALL_AMOUNT, 15, 3, 25, 25 )

                            // Add gun shot decal on the world
                            FX_GunShotDecal( vecBeamEndPos, pEntity )

                            // And glowing sprite
                            FX_TempSprite( vecBeamEndPos, 6, floatround( flDamage / 255.0 ) )

                            // Subtract
                            VectorSubtract( vecBeamEndPos, vecDir, vecCalc )

                            // Absorbtion balls
                            FX_SpriteTrail( vecEnd, vecCalc, BALL_AMOUNT, 15, 3, 25, 25 )

                            // Increase shit
                            nTotal += 21

                            /*
                            // Calculate radius damage
                            static Float:flRadDmg
                            flRadDmg = flDamage * 1.75

                            // Undone.Do radius damage here!
                            floatradius( flDamage, flRadDmg, vecBeamEndPos )
                            */

                            // Increase
                            nTotal += 53

                            VectorMA( vecBeamEndPos, 8.0, vecDir, vecSub )

                            // Add up vector
                            xs_vec_add( vecBeamEndPos, vecDir, vecSrc )
                        }
                    }
                    else
                    {
                        flDamage = 0.0
                    }
                }
                else
                {
                    // Primary attack
                    if( g_bPrimaryFire [ Player ] )
                    {
                        // Slug doesn't punch through ever with primary
                        // fire, so leave a little glowy bit and make some balls
                        FX_TempSprite( vecEnd, 6, floatround( flDamage / 255.0 ) )
                        FX_SpriteTrail( vecEnd, vecDir, BALL_AMOUNT, 15, 3, 25, 25 )
                        if(get_pcvar_num(g_debug))server_print("Gauss sprite Trail")
                    }

                    flDamage = 0.0
                }
            }
        }
        else
        {
            // Add up vector
            xs_vec_add( vecEnd, vecDir, vecSrc )
            pEntToIgnore = pEntity
        }
    }
}

// Register and cache CVARs
public Load_Cvars( )
{
    cvar_oneround = register_cvar( "ze_tcannon_oneround", "0" )
    cvar_dmgprim = register_cvar( "ze_tcannon_dmgprim", "20" )
    cvar_dmgsec = register_cvar( "ze_tcannon_dmgsec", "500" )
    cvar_clip = register_cvar( "ze_tcannon_clip", "500" )

    g_pOneRound = get_pcvar_num( cvar_oneround )
    g_pDmgPrim = get_pcvar_float( cvar_dmgprim )
    g_pDmgSec = get_pcvar_float( cvar_dmgsec )
    g_pClip = get_pcvar_num( cvar_clip )
}

// Gauss weapon idle
WeaponIdle( Player )
{
    // Get gametime
    static Float:flGameTime
    flGameTime = get_gametime( )

    if( g_flWeaponIdleTime[ Player ] > flGameTime )
        return

    // Animation sequence variable
    static iAnim

    // Animation randomizer
    static Float:flRand
    flRand = random_float( 0.1, 1.0 )

    if( flRand <= 0.5 )
    {
        iAnim = gauss_idle
        g_flWeaponIdleTime[ Player ] = flGameTime + random_float( 10.0, 15.0 )
    }
    else if( flRand <= 0.75 )
    {
        iAnim = gauss_idle2
        g_flWeaponIdleTime[ Player ] = flGameTime + random_float( 10.0, 15.0 )
    }
    else
    {
        iAnim = gauss_fidget
        g_flWeaponIdleTime[ Player ] = flGameTime + 3
    }

    // Idle
    UTIL_PlayWeaponAnimation( Player, iAnim )
}

// Play weapon animation
UTIL_PlayWeaponAnimation( const Player, const Sequence )
{
    set_pev( Player, pev_weaponanim, Sequence )

    message_begin( MSG_ONE, SVC_WEAPONANIM, .player = Player )
    write_byte( Sequence )
    write_byte( pev( Player, pev_body ) )
    message_end( )
}

// Make ScreenFade
UTIL_ScreenFade( Player, Duration, HoldTime, Flags, iRed, iGreen, iBlue, iAlpha )
{
    if(get_pcvar_num(g_debug))server_print("Gauss screen fade")
    message_begin( MSG_ONE_UNRELIABLE, gmsgScreenFade, _, Player )
    write_short( Duration )
    write_short( HoldTime )
    write_short( Flags )
    write_byte( iRed )
    write_byte( iGreen )
    write_byte( iBlue )
    write_byte( iAlpha )
    message_end( )
}

// Reload gauss
UTIL_WeaponReload( Player, iEnt )
{
    // Modify time until next attack
    set_pdata_float( Player, m_flNextAttack, GAUSS_RELOADTIME+0.5, 5 )

    // Reload animation
    UTIL_PlayWeaponAnimation( Player, gauss_spin )

    // Enable reload offset
    set_pdata_int( iEnt, m_fInReload, 1, 4 )

    // Modify next idle time
    g_flWeaponIdleTime[ Player ] = get_gametime( ) + GAUSS_RELOADTIME + 1.0
}

// Drop all primary weapons
UTIL_DropPrimary( Player )
{
    // Get user weapons
    static weapons[ 32 ], num, i, weaponid
    num = 0 // reset passed weapons count (bugfix)
    get_user_weapons( Player, weapons, num )

    // Loop through them and drop primaries
    for( i = 0; i < num; i++ )
    {
        // Prevent re-indexing the array
        weaponid = weapons[ i ]

        // We definetely are holding primary gun
        if(( (1<<weaponid) & PRIMARY_WEAPONS_BITSUM ) )
        {
            // Get weapon entity
            static wname[32]
            get_weaponname(weaponid, wname, charsmax(wname))

            // Player drops the weapon and looses his bpammo
            engclient_cmd( Player, "drop", wname)
        }
    }
}

// Get gun position
UTIL_GetGunPosition( Player, Float:flOrigin[ ] )
{
    static Float:vf_Origin[ 3 ], Float:vf_ViewOfs[ 3 ]

    pev( Player, pev_origin, vf_Origin )
    pev( Player, pev_view_ofs, vf_ViewOfs )

    xs_vec_add( vf_Origin, vf_ViewOfs, flOrigin )
}

// Make vectors
UTIL_MakeVectors ( Player )
{
    static Float:flAngle[ 3 ], Float:flPunchAngle[ 3 ]

    pev( Player, pev_v_angle, flAngle )
    pev( Player, pev_punchangle, flPunchAngle )

    xs_vec_add( flAngle, flPunchAngle, flAngle )
    engfunc( EngFunc_MakeVectors, flAngle )
}

// From HL SDK.
VectorMA( Float:a[ ], Float:flScale, Float:b[ ], Float:c[ ] )
{
    c[ 0 ] = a[ 0 ] + flScale * b[ 0 ]
    c[ 1 ] = a[ 1 ] + flScale * b[ 1 ]
    c[ 2 ] = a[ 2 ] + flScale * b[ 2 ]
}

VectorMS( const Float:flSource[ ], const Float:flScale, const Float:flMult[ ], Float:flOutput[ ] )
{
        flOutput[ 0 ] = flSource[ 0 ] - flMult[ 0 ] * flScale
        flOutput[ 1 ] = flSource[ 1 ] - flMult[ 1 ] * flScale
        flOutput[ 2 ] = flSource[ 2 ] - flMult[ 2 ] * flScale
}

// Another stuff from HLSDK
Instance( iEnt )
{
    return iEnt == -1 ? 0 : iEnt
}

// Does this entity should refect gauss?
ReflectGauss( iEnt )
{
        return IsBSPModel( iEnt ) && pev( iEnt, pev_takedamage ) == DAMAGE_NO
}

// Does this entity is BSP model?
IsBSPModel( iEnt )
{
    return pev( iEnt, pev_solid ) == SOLID_BSP || pev( iEnt, pev_movetype ) == MOVETYPE_PUSHSTEP
}

// Add gun shot decal on world!
FX_GunShotDecal( Float:flPos[ ], pEntity )
{
    // Draw gunshot

    engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flPos, 0 )
    write_byte( TE_GUNSHOTDECAL ) // Temp.entity ID
    engfunc( EngFunc_WriteCoord, flPos[ 0 ] ) // Position X
    engfunc( EngFunc_WriteCoord, flPos[ 1 ] ) // Position Y
    engfunc( EngFunc_WriteCoord, flPos[ 2 ] ) // Position Z
    write_short( pEntity ) // Which entity to mark?
    if(get_pcvar_num(g_debug))server_print("Gauss trying to do te_gunshotdecal")
    write_byte( g_decal ) // Texture name from decals.wad
    message_end( )

}

// Add glow sprite on world
FX_TempSprite( Float:flPos[ ], iScale, iSize )
{
    clamp(get_pcvar_num(g_gauss_color),0,10);
    if(get_pcvar_num(g_debug))server_print("Gauss trying to do glows")
    engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flPos, 0 )
    write_byte( TE_GLOWSPRITE ) // Temp.entity ID
    engfunc( EngFunc_WriteCoord, flPos[ 0 ] ) // Position X
    engfunc( EngFunc_WriteCoord, flPos[ 1 ] ) // Position Y
    engfunc( EngFunc_WriteCoord, flPos[ 2 ] ) // Position Z

    if(get_pcvar_num(g_gauss_color) == 0)
        write_short(g_iBall0y) //g_iBalls
    if(get_pcvar_num(g_gauss_color) == 1)
        write_short(g_iBall1o)
    if(get_pcvar_num(g_gauss_color) == 2)
        write_short(g_iBall2r)
    if(get_pcvar_num(g_gauss_color) == 3)
        write_short(g_iBall3k)
    if(get_pcvar_num(g_gauss_color) == 4)
        write_short(g_iBall4p)
    if(get_pcvar_num(g_gauss_color) == 5)
        write_short(g_iBall5b)
    if(get_pcvar_num(g_gauss_color) == 6)
        write_short(g_iBall6t)
    if(get_pcvar_num(g_gauss_color) == 7)
        write_short(g_iBall7g)
    if(get_pcvar_num(g_gauss_color) == 8)
        write_short(g_iBall8w)
    else
    if(get_pcvar_num(g_gauss_color) >= 9)
    {

        switch(random_num(0,8))
        {
            case 0: write_short(g_iBall0y);
            case 1: write_short(g_iBall1o);
            case 2: write_short(g_iBall2r);
            case 3: write_short(g_iBall3k);
            case 4: write_short(g_iBall4p);
            case 5: write_short(g_iBall5b);
            case 6: write_short(g_iBall6t);
            case 7: write_short(g_iBall7g);
            case 8: write_short(g_iBall8w);
        }

    }

    write_byte( iScale ) // Scale
    write_byte( iSize ) // Size
    write_byte( 255 ) // Brightness
    message_end( )
}

// Add sprite trail
FX_SpriteTrail( Float:vecStart[ ], Float:vecDest[ ], iCount, iLife, iScale, iVel, iRnd )
{
    //floatround(get_pcvar_num(g_gauss_color))
    clamp(get_pcvar_num(g_gauss_color),0,10);
    if(get_pcvar_num(g_debug))server_print("Gauss trying to do trail")
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte( TE_SPRITETRAIL ) // Sprite trail
    engfunc( EngFunc_WriteCoord, vecStart[ 0 ] ) // Position X
    engfunc( EngFunc_WriteCoord, vecStart[ 1 ] ) // Position Y
    engfunc( EngFunc_WriteCoord, vecStart[ 2 ] ) // Position Z
    engfunc( EngFunc_WriteCoord, vecDest[ 0 ] ) // Position X
    engfunc( EngFunc_WriteCoord, vecDest[ 1 ] ) // Position Y
    engfunc( EngFunc_WriteCoord, vecDest[ 2 ] ) // Position Z

    if(get_pcvar_num(g_gauss_color) == 0)
        write_short(g_iBall0y) //g_iBalls
    if(get_pcvar_num(g_gauss_color) == 1)
        write_short(g_iBall1o)
    if(get_pcvar_num(g_gauss_color) == 2)
        write_short(g_iBall2r)
    if(get_pcvar_num(g_gauss_color) == 3)
        write_short(g_iBall3k)
    if(get_pcvar_num(g_gauss_color) == 4)
        write_short(g_iBall4p)
    if(get_pcvar_num(g_gauss_color) == 5)
        write_short(g_iBall5b)
    if(get_pcvar_num(g_gauss_color) == 6)
        write_short(g_iBall6t)
    if(get_pcvar_num(g_gauss_color) == 7)
        write_short(g_iBall7g)
    if(get_pcvar_num(g_gauss_color) == 8)
        write_short(g_iBall8w)
    else
    if(get_pcvar_num(g_gauss_color) >= 9)
    {

        switch(random_num(0,8))
        {
            case 0: write_short(g_iBall0y);
            case 1: write_short(g_iBall1o);
            case 2: write_short(g_iBall2r);
            case 3: write_short(g_iBall3k);
            case 4: write_short(g_iBall4p);
            case 5: write_short(g_iBall5b);
            case 6: write_short(g_iBall6t);
            case 7: write_short(g_iBall7g);
            case 8: write_short(g_iBall8w);
        }

    }

    write_byte( iCount ) // Amount
    write_byte( iLife ) // Life
    write_byte( iScale ) // Scale
    write_byte( iVel ) // Velocity along vector
    write_byte( iRnd ) // Randomness of velocity
    message_end( )
}

//CONDITION ZERO TYPE BOTS. SPiNX
@register(ham_bot)
{
    if(is_user_connected(ham_bot))
    {
        RegisterHamFromEntity( Ham_Spawn, ham_bot, "fw_PlayerSpawn_Post", 1 );
        server_print("Gauss ham bot from %N", ham_bot)
    }
}

public client_authorized(bot, const authid[])
{
    if(equal(authid, "BOT") && !bRegistered)
    {
        set_task(0.1, "@register", bot);
        bRegistered = true;
    }
}
