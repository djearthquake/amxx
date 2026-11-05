/*
 * osprey_drone_buy.sma
 *
 * Mini Osprey drone delivery.
 *
 * When a player tries to buy while OUTSIDE the buyzone or AFTER buy time,
 * they are offered a drone delivery at a higher price. The drone only
 * spawns after the player confirms the fee and has enough money.
 *
 * Usage:
 *   Press B and pick a weapon (outside the buyzone / after buy time)
 *   or type /drone in chat, or "drone" in the console.
 *
 * Uses the real Gearbox/OP4 model: models/mini_osprey.mdl
 *
 * CVars:
 *   drone_buy_enabled    1   Enable/disable the plugin
 *   drone_buy_multiplier 2   Cost multiplier (default 2 = double)
 */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <fun>

#define PLUGIN  "Mini Osprey Drone Delivery"
#define VERSION "0.1"
#define AUTHOR  "SPiNX"

#define MAX_DRONES  8
#define PAGE_SIZE   8

#define DRONE_MODEL       "models/mini_osprey.mdl"
#define DRONE_SOUND       "misc/plane_drone.wav"
#define DRONE_HOVER_SOUND "ambience/dronemachine1.wav"

#define MAX_WEAPONS 16

#define TASK_BUYTIME_EXPIRE 1337

new g_weaponName[MAX_WEAPONS][MAX_PLAYERS]
new g_weaponAlias[MAX_WEAPONS][MAX_PLAYERS]
new g_weaponId[MAX_WEAPONS]
new g_weaponPrice[MAX_WEAPONS]
new g_weaponAmmo[MAX_WEAPONS]
new g_weaponCount = 0

// Drone slots
new g_droneEnt[MAX_DRONES]
new g_droneOwner[MAX_DRONES]
new g_droneWeapon[MAX_DRONES]
new Float:g_droneExpire[MAX_DRONES]
new bool:g_droneDelivered[MAX_DRONES]

// Player state
new g_pendingWeapon[MAX_PLAYERS + 1]
new g_pendingDrone[MAX_PLAYERS + 1]
new g_menuPage[MAX_PLAYERS + 1]
new g_confirmWeapon[MAX_PLAYERS + 1]
new Float:g_menuShown[MAX_PLAYERS + 1]

// Round timing
new Float:g_roundStart = 0.0

new g_cvarEnabled
new g_cvarMultiplier

new g_menuKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0
new g_confirmKeys = MENU_KEY_1 | MENU_KEY_2;
//new g_pCustomBuyTime;
//new g_pBuyAnywhereCvar;

public bool:g_bInBuyZone[MAX_PLAYERS + 1];

public check_buyzone_status(id) {
    /*
    if (!is_user_alive(id)) return 0;

    // 1. Convert the custom cvar minutes limit directly to seconds
    new Float:fBuyTimeLimit = get_pcvar_float(g_pCustomBuyTime) * 60.0;
    if (fBuyTimeLimit <= 0.0) {
        fBuyTimeLimit = 15.0; // Fallback default
    }

    // 2. TIME CHECK: If custom round buy time has run out, drone menu is allowed everywhere
    if ((get_gametime() - g_roundStart) > fBuyTimeLimit) {
        return 0; // 0 = Outside buy zone / allowed to use drone
    }

    // 3. RANGE CHECK: Otherwise, follow standard spatial base restrictions
    */
    return g_bInBuyZone[id] ? 1 : 0; // 1 = Inside buy zone (forces normal menu)
}

/*
// THE LOCK MECHANIC: Fires instantly whenever any engine source tries to change this value
public OnBuyAnywhereChanged(pcvar, const old_value[], const new_value[]) {
    if (str_to_num(new_value) != 1) {
        // Forcefully overwrite it back to 1 immediately
        set_pcvar_num(g_pBuyAnywhereCvar, 1);
        
        // Log a silent notice to the server logs to let owners know it's pinned
        log_amx("[Drone System] Blocked attempt to change mp_buy_anywhere. Pinned to 1 for drone functionality.");
    }
}
*/

public plugin_precache()
{
    precache_model(DRONE_MODEL)
    precache_sound(DRONE_SOUND)
    precache_sound(DRONE_HOVER_SOUND)
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    register_event("StatusIcon", "OnEnterBuyzone", "be", "1=1", "2=buyzone")
    register_event("StatusIcon", "OnLeaveBuyzone", "be", "1=0", "2=buyzone")

    g_cvarEnabled = register_cvar("drone_buy_enabled", "1")
    g_cvarMultiplier = register_cvar("drone_buy_multiplier", "2")
    /*
    // 1. Locate or create the CVAR pointer using your preferred setup check
    g_pBuyAnywhereCvar = get_cvar_pointer("mp_buy_anywhere") ? get_cvar_pointer("mp_buy_anywhere") : register_cvar("mp_buy_anywhere", "1");
    
    // 2. Intercept changes to the CVAR to permanently pin it to 1
    hook_cvar_change(g_pBuyAnywhereCvar, "OnBuyAnywhereChanged");
    
    // 3. Enforce the value right now on startup
    set_pcvar_num(g_pBuyAnywhereCvar, 1);
*/
    register_clcmd("buy", "cmd_buy_intercept")
    //register_clcmd("drone", "cmd_drone")

    register_menucmd(register_menuid("Drone Buy Menu"), g_menuKeys, "menu_drone_buy")
    register_menucmd(register_menuid("Drone Confirm"), g_confirmKeys, "menu_drone_confirm")

    register_logevent("event_round_start", 2, "1=Round_Start")
    register_logevent("event_round_end", 2, "1=Round_End")
    
    
    register_event("HLTV", "event_round_start_hltv", "a", "1=0", "2=0")

    init_weapons()

    // Intercept every buy-menu weapon command so the drone offer works
    // where the normal buy menu would otherwise refuse the purchase.
    for (new i = 0; i < g_weaponCount; i++)
        register_clcmd(g_weaponAlias[i], "cmd_buy_alias")

    register_clcmd("autobuy", "cmd_buy_intercept")
    //register_clcmd("rebuy", "cmd_buy_intercept")
    register_clcmd("rebuy", "cmd_vgui_buy_intercept")
    
    register_clcmd("cl_initbuy", "cmd_vgui_buy_intercept");
    register_clcmd("client_buy_open", "cmd_vgui_buy_intercept");

    // The client sends client_buy_open when B is pressed. Away from the
    // buyzone / after buy time, close the engine menu and show ours instead.
    register_clcmd("client_buy_open", "cmd_buy_open")

    // Guaranteed way to open the drone menu even if the client refuses
    // to open the normal buy menu away from a buy zone.
    register_clcmd("drone", "cmd_drone_menu")
    register_concmd("dronework", "cmd_drone")
    register_clcmd("say /drone", "cmd_drone_menu")

    set_task(5.0, "task_cleanup_drones", 0, "", 0, "b")

    log_amx("[Drone] %s loaded (%d weapons)", PLUGIN, g_weaponCount)

    // Hook the modern VGUI buy menu initialization
    register_clcmd("client_buy_open", "cmd_vgui_buy_intercept")
    //g_pCustomBuyTime = register_cvar("mp_buytime_custom", "0.25");
}

public OnEnterBuyzone(id)
{
    g_bInBuyZone[id] = true
}

public OnLeaveBuyzone(id)
{
    g_bInBuyZone[id] = false
}

public cmd_drone(id)
{
    if (is_user_alive(id))
    {
        console_cmd 0, "mp_buy_anywhere 1"
        // Fix 3: Added missing parentheses for client_print
        client_print(id, print_chat, "Trying our drone work...")
        
        show_drone_menu(id, 0)
        
        // Fix 4: Changed to PLUGIN_HANDLED so "Unknown command" doesn't print in console
        return PLUGIN_HANDLED 
    }
    return PLUGIN_HANDLED
}


public plugin_cfg()
{
    g_roundStart = get_gametime()
}

init_weapons()
{
    add_weapon("AK-47",    "ak47",    CSW_AK47,    2500, 90)
    add_weapon("M4A1",     "m4a1",    CSW_M4A1,    3100, 90)
    add_weapon("AWP",      "awp",     CSW_AWP,     4750, 30)
    add_weapon("Deagle",   "deagle",  CSW_DEAGLE,   650, 35)
    add_weapon("MP5 Navy", "mp5",     CSW_MP5NAVY, 1500, 120)
    add_weapon("Famas",    "famas",   CSW_FAMAS,   2250, 90)
    add_weapon("Galil",    "galil",   CSW_GALIL,   2000, 90)
    add_weapon("AUG",      "aug",     CSW_AUG,     3500, 90)
    add_weapon("SG552",    "sg552",   CSW_SG552,   3500, 90)
    add_weapon("Scout",    "scout",   CSW_SCOUT,   2750, 90)
    add_weapon("P90",      "p90",     CSW_P90,     2350, 100)
    add_weapon("UMP45",    "ump45",   CSW_UMP45,   1700, 100)
    add_weapon("MAC10",    "mac10",   CSW_MAC10,   1400, 100)
    add_weapon("TMP",      "tmp",     CSW_TMP,     1250, 120)
    add_weapon("M3",       "m3",      CSW_M3,      1700, 32)
    add_weapon("XM1014",   "xm1014",  CSW_XM1014,  3000, 32)
}

add_weapon(const name[], const alias[], weaponId, price, ammo)
{
    if (g_weaponCount >= MAX_WEAPONS)
        return

    copy(g_weaponName[g_weaponCount], 31, name)
    copy(g_weaponAlias[g_weaponCount], 31, alias)
    g_weaponId[g_weaponCount] = weaponId
    g_weaponPrice[g_weaponCount] = price
    g_weaponAmmo[g_weaponCount] = ammo
    g_weaponCount++
}

public event_round_start()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        g_pendingWeapon[i] = -1
        g_pendingDrone[i] = -1
        g_menuPage[i] = 0
        g_confirmWeapon[i] = -1
        g_menuShown[i] = 0.0
    }

    for (new i = 0; i < MAX_DRONES; i++)
    {
        g_droneEnt[i] = 0
        g_droneOwner[i] = 0
        g_droneWeapon[i] = -1
        g_droneExpire[i] = 0.0
        g_droneDelivered[i] = false
    }
    g_roundStart = get_gametime()
    new Float:fBuyTimeLimit = get_cvar_float("mp_buytime") * 60.0
    if (fBuyTimeLimit > 0.0)
    {
        set_task(fBuyTimeLimit, "Task_BuytimeExpired", TASK_BUYTIME_EXPIRE)
    }
    for (new i = 1; i <= MaxClients; i++)
    {
        g_pendingWeapon[i] = -1
        g_pendingDrone[i] = -1
        g_menuPage[i] = 0
        g_confirmWeapon[i] = -1
        g_menuShown[i] = 0.0
    }
}

public Task_BuytimeExpired()
{
    // Run-time loop optimized for actual server capacity
    for (new i = 1; i <= MaxClients; i++)
    {
        g_bInBuyZone[i] = false
    }
}

public event_round_start_hltv()
{
    g_roundStart = get_gametime()
}

public event_round_end()
{
    for (new i = 0; i < MAX_DRONES; i++)
    {
        if (g_droneEnt[i])
        {
            if (is_valid_ent(g_droneEnt[i]))
                remove_entity(g_droneEnt[i])
            clear_slot(i, true)
        }
    }

    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        g_pendingWeapon[i] = -1
        g_pendingDrone[i] = -1
        g_menuPage[i] = 0
        g_confirmWeapon[i] = -1
        g_menuShown[i] = 0.0
    }
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
    g_pendingWeapon[id] = -1
    g_pendingDrone[id] = -1
    g_menuPage[id] = 0
    g_confirmWeapon[id] = -1
    g_menuShown[id] = 0.0
}

bool:buy_time_expired()
{
    if (g_roundStart <= 0.0)
        return false

    new Float:buyTime = get_cvar_float("mp_buytime")
    if (buyTime <= 0.0)
        return false

    return ((get_gametime() - g_roundStart) > buyTime * 60.0)
}

bool:can_use_drone(id)
{
    if (!get_pcvar_num(g_cvarEnabled))
        return false

    if (!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id))
        return false

    return true
}

// The engine's buy menu opening. If buying is not allowed, close it and
// reuse the /drone flow (unless the drone menu is already on screen).
public cmd_buy_open(id)
{
    if (is_user_alive(id))
    {
        if (!can_use_drone(id))
            return PLUGIN_CONTINUE
    
        if (cs_get_user_buyzone(id) && !buy_time_expired())
            return PLUGIN_CONTINUE
    
        if (g_pendingDrone[id] >= 0)
        {
            client_print(id, print_chat, "[Drone] Your mini osprey is already en route.")
            return PLUGIN_HANDLED
        }
    
        if (get_gametime() - g_menuShown[id] < 16.0)
            return PLUGIN_HANDLED
    
        g_menuShown[id] = get_gametime()
    
        // The engine buy menu is client-side and cannot be closed from the
        // server, so let the player pick a weapon there: the weapon command
        // below is intercepted and turned into the drone offer.
        //client_print(id, print_chat,"[Drone] Out of buy range - pick a weapon to order it by drone (%dx price) or type /drone."
        //if(!g_bInBuyZone[id] ||
        if(buy_time_expired())
        {
            cmd_drone_menu(id)
            get_pcvar_num(g_cvarMultiplier)
    
            return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public cmd_drone_menu(id)
{
    if (!can_use_drone(id))
        return PLUGIN_CONTINUE

    if (g_pendingDrone[id] >= 0)
    {
        client_print(id, print_chat, "[Drone] Your mini osprey is already en route.")
        return PLUGIN_HANDLED
    }

    if (cs_get_user_buyzone(id) && !buy_time_expired())
    {
        client_print(id, print_chat, "[Drone] You are in the buy zone - use the normal buy menu.")
        return PLUGIN_HANDLED
    }

    g_menuShown[id] = get_gametime()
    show_drone_menu(id, 0)
    return PLUGIN_HANDLED
}

// We intercept the VGUI menu open attempt
public cmd_vgui_buy_intercept(id)
{
    // Run your exact drone logic. 
    // If it returns PLUGIN_HANDLED, it blocks the VGUI menu from showing and handles the drone.
    return handle_drone_routing(id)
}

// We intercept console / standard text buy commands
public cmd_buy_intercept(id)
{
    return handle_drone_routing(id)
}

// Combined core logic to keep your code clean
public handle_drone_routing(id)
{
    if (!can_use_drone(id))
        return PLUGIN_CONTINUE

    if (g_pendingDrone[id] >= 0)
    {
        client_print(id, print_chat, "[Drone] Your mini osprey is already en route.")
        return PLUGIN_HANDLED
    }

    // If they ARE in the buyzone, let the default game buy menu handle it
    // Returning PLUGIN_CONTINUE allows the standard CS menu to open

    if (g_bInBuyZone[id])
        return PLUGIN_CONTINUE

    // Player is OUTSIDE the buyzone -> Trigger drone menu
    if (get_gametime() - g_menuShown[id] < 16.0)
    {
        return PLUGIN_HANDLED 
    }

    g_menuShown[id] = get_gametime()
    
    show_drone_menu(id, 0)
    
    return PLUGIN_HANDLED
}
/*
public cmd_buy_intercept(id)
{
    if (!can_use_drone(id))
        return PLUGIN_CONTINUE

    if (g_pendingDrone[id] >= 0)
    {
        client_print(id, print_chat, "[Drone] Your mini osprey is already en route.")
        return PLUGIN_HANDLED
    }

    // If they ARE in the buyzone, let the default game buy menu handle it
    if (g_bInBuyZone[id])
        return PLUGIN_CONTINUE

    // Player is OUTSIDE the buyzone -> Trigger drone menu
    // Anti-spam check: prevents re-opening if they pressed 'buy' less than 16 seconds ago
    if (get_gametime() - g_menuShown[id] < 16.0)
    {
        return PLUGIN_HANDLED // Silently block the command during cooldown
    }

    g_menuShown[id] = get_gametime()
    show_drone_menu(id, 0)
    
    return PLUGIN_HANDLED
}
*/

// The CS buy menu sends a weapon alias (e.g. "deagle") to the server.
// When the player cannot buy normally, turn that into a drone offer.
public cmd_buy_alias(id)
{
    if (!can_use_drone(id))
        return PLUGIN_CONTINUE

    new alias[32]
    read_argv(0, alias, charsmax(alias))

    new idx = -1
    for (new i = 0; i < g_weaponCount; i++)
    {
        if (equali(alias, g_weaponAlias[i]))
        {
            idx = i
            break
        }
    }

    if (idx < 0)
        return PLUGIN_CONTINUE

    if (g_pendingDrone[id] >= 0)
    {
        client_print(id, print_chat, "[Drone] Your mini osprey is already en route.")
        return PLUGIN_HANDLED
    }

    // Inside the buyzone during buy time: let CS handle the purchase.
    if (cs_get_user_buyzone(id) && !buy_time_expired())
        return PLUGIN_CONTINUE

    new price = g_weaponPrice[idx] * get_pcvar_num(g_cvarMultiplier)
    new money = cs_get_user_money(id)

    if (money < price)
    {
        client_print(id, print_chat, "[Drone] You cannot afford %s - need $%d, you have $%d.",
            g_weaponName[idx], price, money)
        return PLUGIN_HANDLED
    }

    show_confirm_menu(id, idx)
    return PLUGIN_HANDLED
}

show_drone_menu(id, page)
{
    g_menuPage[id] = page

    new menuText[768]
    new len = 0
    new mult = get_pcvar_num(g_cvarMultiplier)
    new start = page * PAGE_SIZE

    len += formatex(menuText[len], charsmax(menuText) - len, "\yMini Osprey Delivery\w - %dx price^n^n", mult)

    for (new i = 0; i < PAGE_SIZE; i++)
    {
        new idx = start + i
        if (idx >= g_weaponCount)
            break

        len += formatex(menuText[len], charsmax(menuText) - len, "\r%d. \w%s \y($%d)^n",
            i + 1, g_weaponName[idx], g_weaponPrice[idx] * mult)
    }

    if (start + PAGE_SIZE < g_weaponCount)
        len += formatex(menuText[len], charsmax(menuText) - len, "^n\r9. \wMore weapons...")
    else if (page > 0)
        len += formatex(menuText[len], charsmax(menuText) - len, "^n\r9. \wBack")

    len += formatex(menuText[len], charsmax(menuText) - len, "^n\r0. \wCancel")

    show_menu(id, g_menuKeys, menuText, 15, "Drone Buy Menu")
}

public menu_drone_buy(id, key)
{
    g_menuShown[id] = 0.0

    if (key == 9)
    {
        client_print(id, print_chat, "[Drone] Delivery cancelled.")
        return PLUGIN_HANDLED
    }

    if (key == 8)
    {
        if (g_menuPage[id] == 0 && PAGE_SIZE < g_weaponCount)
            show_drone_menu(id, 1)
        else if (g_menuPage[id] > 0)
            show_drone_menu(id, g_menuPage[id] - 1)
        return PLUGIN_HANDLED
    }

    new idx = g_menuPage[id] * PAGE_SIZE + key
    if (idx < 0 || idx >= g_weaponCount)
        return PLUGIN_HANDLED

    new price = g_weaponPrice[idx] * get_pcvar_num(g_cvarMultiplier)
    new money = cs_get_user_money(id)

    if (money < price)
    {
        client_print(id, print_chat, "[Drone] You cannot afford %s - need $%d, you have $%d.",
            g_weaponName[idx], price, money)
        return PLUGIN_HANDLED
    }

    show_confirm_menu(id, idx)
    return PLUGIN_HANDLED
}

show_confirm_menu(id, idx)
{
    // Ask for confirmation before taking any money
    g_confirmWeapon[id] = idx

    new price = g_weaponPrice[idx] * get_pcvar_num(g_cvarMultiplier)

    new menuText[256]
    formatex(menuText, charsmax(menuText),
        "\yConfirm drone delivery^n^n\wWeapon: \r%s^n\wFee: \r$%d^n^n\r1. \wYes, deliver it^n\r2. \wNo, cancel",
        g_weaponName[idx], price)

    show_menu(id, g_confirmKeys, menuText, 15, "Drone Confirm")
}

public menu_drone_confirm(id, key)
{
    g_menuShown[id] = 0.0

    new idx = g_confirmWeapon[id]
    g_confirmWeapon[id] = -1

    if (key != 0 || idx < 0 || idx >= g_weaponCount)
    {
        client_print(id, print_chat, "[Drone] Delivery cancelled.")
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(id))
    {
        client_print(id, print_chat, "[Drone] You must be alive to order.")
        return PLUGIN_HANDLED
    }

    new price = g_weaponPrice[idx] * get_pcvar_num(g_cvarMultiplier)
    new money = cs_get_user_money(id)

    if (money < price)
    {
        client_print(id, print_chat, "[Drone] Not enough money - need $%d, you have $%d.", price, money)
        return PLUGIN_HANDLED
    }

    new slot = spawn_drone(id, idx)

    if (slot < 0)
    {
        client_print(id, print_chat, "[Drone] No osprey available right now - not charged.")
        return PLUGIN_HANDLED
    }

    cs_set_user_money(id, money - price, 1)

    g_pendingWeapon[id] = idx
    g_pendingDrone[id] = slot

    client_print(id, print_chat, "[Drone] Mini osprey inbound - %s for $%d.", g_weaponName[idx], price)

    new name[32]
    get_user_name(id, name, charsmax(name))
    log_amx("[Drone] %s ordered %s ($%d)", name, g_weaponName[idx], price)

    return PLUGIN_HANDLED
}

get_hover_pos(id, Float:hoverPos[3])
{
    new Float:eye[3], Float:ang[3], Float:fwd[3]
    entity_get_vector(id, EV_VEC_origin, eye)
    entity_get_vector(id, EV_VEC_v_angle, ang)
    ang[0] = 0.0
    angle_vector(ang, ANGLEVECTOR_FORWARD, fwd)

    new Float:start[3]
    start[0] = eye[0]
    start[1] = eye[1]
    start[2] = eye[2] + 10.0

    // Start well in front of the player, then pull the point in until the
    // line of sight is clear and the spot is not inside a wall or ceiling.
    new Float:dist = 300.0
    new Float:hgt = 40.0
    new Float:cand[3], Float:tr[3]

    for (new tries = 0; tries < 6; tries++)
    {
        cand[0] = start[0] + fwd[0] * dist
        cand[1] = start[1] + fwd[1] * dist
        cand[2] = eye[2] + hgt

        trace_line(id, start, cand, tr)

        new Float:dx = tr[0] - cand[0]
        new Float:dy = tr[1] - cand[1]
        new Float:dz = tr[2] - cand[2]
        new Float:gap = floatsqroot(dx * dx + dy * dy + dz * dz)

        if (gap < 10.0 && point_contents(cand) != CONTENTS_SOLID)
            break

        dist *= 0.65
        hgt *= 0.8

        if (dist < 120.0)
            dist = 120.0
        if (hgt < 30.0)
            hgt = 30.0
    }

    hoverPos[0] = cand[0]
    hoverPos[1] = cand[1]
    hoverPos[2] = cand[2]
}

spawn_drone(id, weaponIdx)
{
    new slot = -1
    for (new i = 0; i < MAX_DRONES; i++)
    {
        if (!g_droneEnt[i] || !is_valid_ent(g_droneEnt[i]))
        {
            slot = i
            break
        }
    }

    if (slot == -1)
        return -1

    new drone = create_entity("info_target")
    if (!drone)
        return -1

    entity_set_string(drone, EV_SZ_classname, "mini_osprey_drone")
    entity_set_model(drone, DRONE_MODEL)
    entity_set_int(drone, EV_INT_movetype, MOVETYPE_FLY)
    entity_set_int(drone, EV_INT_solid, SOLID_NOT)
    entity_set_size(drone, Float:{-10.0, -10.0, -10.0}, Float:{10.0, 10.0, 10.0})
    entity_set_int(drone, EV_INT_sequence, 0)
    entity_set_float(drone, EV_FL_frame, 0.0)
    entity_set_float(drone, EV_FL_framerate, 20.0)

    // Start high above the delivery point and descend into view
    new Float:hoverPos[3]
    get_hover_pos(id, hoverPos)

    new Float:startPos[3]
    startPos[0] = hoverPos[0]
    startPos[1] = hoverPos[1]
    startPos[2] = hoverPos[2] + 150.0
    entity_set_vector(drone, EV_VEC_origin, startPos)

    new Float:vel[3]
    vel[0] = 0.0
    vel[1] = 0.0
    vel[2] = -75.0
    entity_set_vector(drone, EV_VEC_velocity, vel)

    g_droneEnt[slot] = drone
    g_droneOwner[slot] = id
    g_droneWeapon[slot] = weaponIdx
    g_droneExpire[slot] = get_gametime() + 15.0
    g_droneDelivered[slot] = false

    entity_set_int(drone, EV_INT_iuser1, slot)
    entity_set_int(drone, EV_INT_iuser2, id)

    emit_sound(drone, CHAN_AUTO, DRONE_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)

    set_task(2.0, "drone_deliver", drone)

    return slot
}

public drone_deliver(drone)
{
    if (!is_valid_ent(drone))
        return

    new slot = entity_get_int(drone, EV_INT_iuser1)
    if (slot < 0 || slot >= MAX_DRONES)
        return

    new owner = g_droneOwner[slot]

    if (!is_user_connected(owner) || !is_user_alive(owner))
    {
        clear_slot(slot, true)
        if (is_valid_ent(drone))
            remove_entity(drone)
        return
    }

    new Float:hoverPos[3]
    get_hover_pos(owner, hoverPos)
    entity_set_vector(drone, EV_VEC_origin, hoverPos)

    new Float:zero[3]
    entity_set_vector(drone, EV_VEC_velocity, zero)

    emit_sound(drone, CHAN_AUTO, DRONE_HOVER_SOUND, 0.8, ATTN_NORM, 0, PITCH_NORM)

    set_task(2.5, "drone_drop_item", drone)
}

public drone_drop_item(drone)
{
    if (!is_valid_ent(drone))
        return

    new slot = entity_get_int(drone, EV_INT_iuser1)
    if (slot < 0 || slot >= MAX_DRONES)
        return

    new owner = g_droneOwner[slot]
    new idx = g_droneWeapon[slot]

    if (!is_user_connected(owner) || !is_user_alive(owner) || idx < 0 || idx >= g_weaponCount)
    {
        clear_slot(slot, true)
        if (is_valid_ent(drone))
            remove_entity(drone)
        return
    }

    new weaponName[32]
    get_weaponname(g_weaponId[idx], weaponName, charsmax(weaponName))

    if (weaponName[0])
    {
        give_item(owner, weaponName)
        cs_set_user_bpammo(owner, g_weaponId[idx], g_weaponAmmo[idx])
        engclient_cmd(owner, "use", weaponName)

        g_droneDelivered[slot] = true

        client_print(owner, print_chat, "[Drone] Delivered %s! (%dx price)",
            g_weaponName[idx], get_pcvar_num(g_cvarMultiplier))

        new name[32]
        get_user_name(owner, name, charsmax(name))
        log_amx("[Drone] delivered %s to %s", g_weaponName[idx], name)
    }
    else
    {
        client_print(owner, print_chat, "[Drone] Delivery failed - refunded.")
    }

    emit_sound(drone, CHAN_AUTO, DRONE_SOUND, 0.7, ATTN_NORM, 0, PITCH_NORM)

    set_task(1.0, "drone_depart", drone)
}

public drone_depart(drone)
{
    if (!is_valid_ent(drone))
        return

    new slot = entity_get_int(drone, EV_INT_iuser1)
    if (slot < 0 || slot >= MAX_DRONES)
        return

    new Float:vel[3]
    vel[0] = 0.0
    vel[1] = 0.0
    vel[2] = 250.0
    entity_set_vector(drone, EV_VEC_velocity, vel)

    set_task(3.0, "drone_remove", drone)
}

public drone_remove(drone)
{
    new slot = -1
    for (new i = 0; i < MAX_DRONES; i++)
    {
        if (g_droneEnt[i] == drone)
        {
            slot = i
            break
        }
    }

    if (is_valid_ent(drone))
        remove_entity(drone)

    if (slot >= 0)
        clear_slot(slot, true)
}

public task_cleanup_drones()
{
    new Float:now = get_gametime()

    for (new i = 0; i < MAX_DRONES; i++)
    {
        if (g_droneEnt[i] && is_valid_ent(g_droneEnt[i]))
        {
            if (now > g_droneExpire[i])
            {
                remove_entity(g_droneEnt[i])
                clear_slot(i, true)
            }
        }
        else if (g_droneEnt[i] != 0)
        {
            clear_slot(i, true)
        }
    }
}

clear_slot(slot, bool:refund)
{
    if (slot < 0 || slot >= MAX_DRONES)
        return

    new owner = g_droneOwner[slot]
    new idx = g_droneWeapon[slot]
    new bool:delivered = g_droneDelivered[slot]

    if (refund && owner > 0 && owner <= MAX_PLAYERS && !delivered)
    {
        if (is_user_connected(owner) && idx >= 0 && idx < g_weaponCount)
        {
            new price = g_weaponPrice[idx] * get_pcvar_num(g_cvarMultiplier)
            cs_set_user_money(owner, cs_get_user_money(owner) + price, 1)
            client_print(owner, print_chat, "[Drone] Delivery failed - $%d refunded.", price)
        }
    }

    if (owner > 0 && owner <= MAX_PLAYERS)
    {
        if (g_pendingDrone[owner] == slot)
        {
            g_pendingDrone[owner] = -1
            g_pendingWeapon[owner] = -1
        }
    }

    g_droneEnt[slot] = 0
    g_droneOwner[slot] = 0
    g_droneWeapon[slot] = -1
    g_droneExpire[slot] = 0.0
    g_droneDelivered[slot] = false
}

public plugin_end()
{
    for (new i = 0; i < MAX_DRONES; i++)
    {
        if (g_droneEnt[i] && is_valid_ent(g_droneEnt[i]))
            remove_entity(g_droneEnt[i])
    }
}
