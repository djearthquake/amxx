/** name:cmd_pik
    @param pik # #
    @returns Validates pdata from powerups to weapon backpacks.
    EXPERIMENTAL FOR DEVELOPERS NOT INTENDED FOR PRODUCTION SERVER.
    * Sometime after doing this offset incremented +2 Then back down to +1 checked end of 2022.

    Example: In console type pik 315 300 in HL you have 300 cartridges
    of depleted Uranium.

    OP4 Scribed Powerup Pick combinations
    317 | 900 |   health, and jump
    317 | 900 |   skull
    317 | 850 |   bullet
    317 | 800 |   skull
    317 | 700 |   All
    317 | 50  |   skull and bullet
    317 | 16  |   bullet
    317 |12-15|   jump and shield
    317 | 4-7 |   jump
    317 | 8-9 |   shield
    317 | 0-3 |   erase
    317 |  -1  |   All

    op4 backpack piks."pik 362 20" gives 20 backpack hivehand
    op4 is +43 offset to HL table
    |364|#| hegrenades
    |365|#| snark
    |366|#| hivehand
    |367|#| mach gun
    |362|#| satchels
    |361|#| bow
    |362|#| tripmine
    |360|#| RPG
    |358|#| 357
    |359|#| Uranium
    |357|#| ar grenades
    |356|#| 9mm
    |355|#| shotgun
    |371|#| penguin
    |370|#| sniper
    |369|#| shock
    |368|#| spore

    hl is -43 offset to OP4
    Hl AMMO OFFSETS
    322 hivehand
    321 snarks
    320 handgrenades
    319 satchels
    318 tripmines
    317 bow
    316 rpg
    315 uranium
    314 Eagle
    313 9mmargren
    312 9mmar
    311 12g
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new g_iArg1[6], g_iArg2[6], g_pik;

public plugin_init()
{
    register_clcmd("pik","cmd_pik",ADMIN_KICK,"<311-322> OP4 Weapon <capacity> magazine| +43 OP4 offset")
    g_pik = register_cvar("allow_pik","1")
    register_plugin("Pdata Explorer","3.17-700",".sρiηX҉.");
}

new const g_szPowerup_sounds[][]={"ctf/pow_armor_charge.wav","ctf/pow_backpack.wav","ctf/pow_health_charge.wav","turret/tu_ping.wav"};

public plugin_precache()
for(new list;list < sizeof g_szPowerup_sounds;++list)
precache_sound(g_szPowerup_sounds[list]);

public cmd_pik(id,level,cid)
{
    if( (!cmd_access ( id, level, cid, 1 )) && !(get_pcvar_num(g_pik)) )
        return PLUGIN_HANDLED;
    read_argv(1,g_iArg1,charsmax(g_iArg1));read_argv(2,g_iArg2,charsmax(g_iArg2));

    set_pdata_int(id,str_to_num(g_iArg1),str_to_num(g_iArg2));

    client_print(0,print_chat,"Pick attempt|%s|%s|made!",g_iArg1,g_iArg2)
    return PLUGIN_HANDLED;
}
