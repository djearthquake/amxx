#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <fakemeta>

#define PLUGIN "OpFor Arms Race Pro"
#define VERSION "3.1"
#define AUTHOR "SPiNX"

#define MAX_LEVELS 14
#define TASK_AR_HUD 991

new g_iPlayerLevel[MAX_PLAYERS+1];
new g_iVotesYes, g_iVotesNo;
new bool:g_bArActive = false;

new const g_szLevelWeapons[MAX_LEVELS][] = 
{
    "weapon_knife", "weapon_9mmhandgun", "weapon_eagle", "weapon_357",
    "weapon_9mmAR", "weapon_shotgun", "weapon_crossbow", "weapon_m249",
    "weapon_rpg", "weapon_shockroach", "weapon_sporelauncher", "weapon_sniperrifle",
    "weapon_displacer", "weapon_pipewrench" 
};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
    
    register_forward(FM_Touch, "fw_Touch");
    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
    
    register_clcmd("say /vote_ar", "cmd_CallVote");
}

// --- INFINITE BIO & INSTANT REFILL ---
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
    if (!g_bArActive || !is_user_alive(id)) return;

    static iEnt;
    iEnt = get_pdata_cbase(id, 373); // m_pActiveItem
    if (!pev_valid(iEnt)) return;

    static szClass[MAX_PLAYERS];
    pev(iEnt, pev_classname, szClass, charsmax(szClass));

    // Force Clip/Energy to Max for Bio-Weapons
    if (equal(szClass, "weapon_shockroach"))
    {
        set_pdata_int(iEnt, 51, 31, 4); // Roach max energy
    }
    else if (equal(szClass, "weapon_sporelauncher"))
    {
        set_pdata_int(iEnt, 51, 5, 4);  // Spore max clip
        ExecuteHamB(Ham_GiveAmmo, id, 20, "spores", 20); // Keep reserves full
    }
    else if (equal(szClass, "weapon_displacer"))
    {
        // Displacer uses Uranium (9mm/Uranium shared in some HL mods, but OpFor is unique)
        set_pdata_int(iEnt, 51, 100, 4); 
    }
    else 
    {
        // General Ammo Freeze for all other guns
        set_pdata_int(iEnt, 51, 99, 4);
    }
}

// --- AMMO & SPAWN ---
stock give_impossible_ammo(id, const szWeapon[])
{
    if (equal(szWeapon, "weapon_9mmhandgun") || equal(szWeapon, "weapon_9mmAR")) ExecuteHamB(Ham_GiveAmmo, id, 999, "9mm", 999);
    else if (equal(szWeapon, "weapon_357") || equal(szWeapon, "weapon_eagle")) ExecuteHamB(Ham_GiveAmmo, id, 999, "357", 999);
    else if (equal(szWeapon, "weapon_shotgun")) ExecuteHamB(Ham_GiveAmmo, id, 999, "buckshot", 999);
    else if (equal(szWeapon, "weapon_m249")) ExecuteHamB(Ham_GiveAmmo, id, 999, "556", 999);
    else if (equal(szWeapon, "weapon_crossbow")) ExecuteHamB(Ham_GiveAmmo, id, 999, "bolts", 999);
    else if (equal(szWeapon, "weapon_sporelauncher")) ExecuteHamB(Ham_GiveAmmo, id, 999, "spores", 999);
    else if (equal(szWeapon, "weapon_sniperrifle")) ExecuteHamB(Ham_GiveAmmo, id, 999, "762", 999);
    else if (equal(szWeapon, "weapon_rpg")) ExecuteHamB(Ham_GiveAmmo, id, 999, "rockets", 999);
}

public fw_PlayerSpawn_Post(id)
{
    if (g_bArActive && is_user_alive(id)) set_task(0.2, "task_DelayedGive", id);
}

public task_DelayedGive(id)
{
    if (!is_user_alive(id)) return;
    strip_user_weapons(id);
    
    new iLvl = g_iPlayerLevel[id];
    give_item(id, g_szLevelWeapons[iLvl]);
    give_impossible_ammo(id, g_szLevelWeapons[iLvl]);
    engclient_cmd(id, g_szLevelWeapons[iLvl]);
}

// --- CLEANUP & LOGIC ---
public fw_Touch(entity, id)
{
    if (!g_bArActive || !is_user_alive(id)) return FMRES_IGNORED;
    static szClass[MAX_PLAYERS];
    pev(entity, pev_classname, szClass, charsmax(szClass));
    if (equal(szClass, "weaponbox") || equal(szClass, "armoury_entity") || (contain(szClass, "weapon_") != -1) || (contain(szClass, "ammo_") != -1))
    {
        set_pev(entity, pev_effects, pev(entity, pev_effects) | EF_NODRAW);
        set_pev(entity, pev_solid, SOLID_NOT);
        return FMRES_SUPERCEDE; 
    }
    return FMRES_IGNORED;
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
    if (!g_bArActive || !is_user_connected(attacker) || attacker == victim) return;
    if (g_iPlayerLevel[attacker] < MAX_LEVELS - 1)
    {
        g_iPlayerLevel[attacker]++;
        task_DelayedGive(attacker);
        client_cmd(attacker, "spk buttons/bell1");
    }
    else declare_ar_winner(attacker);
}

public task_ArHud()
{
    if (!g_bArActive) return;
    static iPlayers[MAX_PLAYERS], iNum, id;
    get_players(iPlayers, iNum, "ch");
    for (new i = 0; i < iNum; i++)
    {
        id = iPlayers[i];
        set_hudmessage(255, 215, 0, 0.02, 0.2, 0, 0.0, 1.1, 0.0, 0.1, 3);
        show_hudmessage(id, "ARMS RACE^nWeapon: %s^nLevel: %d / %d", g_szLevelWeapons[g_iPlayerLevel[id]], g_iPlayerLevel[id] + 1, MAX_LEVELS);
    }
}

public cmd_CallVote(id)
{
    if (g_bArActive) return PLUGIN_HANDLED;
    new menu = menu_create("\yStart OpFor Arms Race?", "menu_VoteHandler");
    menu_additem(menu, "Yes", "1"); menu_additem(menu, "No", "2");
    g_iVotesYes = 0; g_iVotesNo = 0;
    static iPlayers[MAX_PLAYERS], iNum; get_players(iPlayers, iNum);
    for (new i = 0; i < iNum; i++) menu_display(iPlayers[i], menu, 0);
    set_task(10.0, "task_FinishVote");
    return PLUGIN_HANDLED;
}

public menu_VoteHandler(id, menu, item)
{
    if (item != MENU_EXIT) (item == 0) ? g_iVotesYes++ : g_iVotesNo++;
    return PLUGIN_HANDLED;
}

public task_FinishVote()
{
    if (g_iVotesYes > g_iVotesNo)
    {
        g_bArActive = true;
        arrayset(g_iPlayerLevel, 0, 33);
        static iPlayers[MAX_PLAYERS], iNum; get_players(iPlayers, iNum);
        for(new i = 0; i < iNum; i++) if(is_user_alive(iPlayers[i])) task_DelayedGive(iPlayers[i]);
        set_task(1.0, "task_ArHud", TASK_AR_HUD, _, _, "b");
    }
}

public declare_ar_winner(id)
{
    static szName[MAX_PLAYERS]; get_user_name(id, szName, charsmax(szName));
    client_print(0, print_chat, "[AR] %s WON THE ARMS RACE!", szName);
    g_bArActive = false;
    remove_task(TASK_AR_HUD);
}
