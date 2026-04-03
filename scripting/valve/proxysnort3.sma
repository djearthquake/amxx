#include <amxmodx>
#include <amxmisc>
#include <sockets>
#include <json>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#define PLUGIN  "ProxySnort: Troll Edition"
#define VERSION "3.1"
#define AUTHOR  "SPiNX"

#define MAX_HUD_ENTRIES 3
#define SVC_SPAWNSTATICSOUND 29

new g_cvar_token, g_cvar_risk_kick, g_cvar_troll, g_cvar_prune;
new g_hud_sync, g_log_path[MAX_RESOURCE_PATH_LENGTH], g_whitelist_path[MAX_RESOURCE_PATH_LENGTH];

new g_names[MAX_HUD_ENTRIES][MAX_NAME_LENGTH];
new g_risks[MAX_HUD_ENTRIES];
new g_info[MAX_HUD_ENTRIES][MAX_NAME_LENGTH * 2];
new g_entry_count = 0;

new bool:g_is_proxy[MAX_PLAYERS + 1];
new bool:g_half_damage[MAX_PLAYERS + 1];
new bool:g_is_whitelisted[MAX_PLAYERS + 1];
new g_active_troll[MAX_PLAYERS + 1];
new g_original_name[MAX_PLAYERS + 1][MAX_NAME_LENGTH];

new g_sound_index;
new const g_alert_sound[] = "buttons/button10.wav";

forward bool:check_file_whitelist(id);
forward get_troll_name(type, dest[], len);

public plugin_precache()
{
    g_sound_index = precache_sound(g_alert_sound);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_cvar_token     = register_cvar("sv_proxycheckio-key", "null", FCVAR_PROTECTED|FCVAR_NOEXTRAWHITEPACE|FCVAR_SPONLY);
    g_cvar_risk_kick = register_cvar("ps_risk_kick", "80");
    g_cvar_troll     = register_cvar("ps_discombobulate", "1");
    g_cvar_prune     = register_cvar("ps_log_prune_days", "7");

    g_hud_sync = CreateHudSyncObj();

    register_clcmd("say /proxies", "cmd_show_proxies");
    register_concmd("amx_proxy_whitelist", "cmd_whitelist_add", ADMIN_RCON, "<name or #userid>");

    register_forward(FM_ClientUserInfoChanged, "fwd_ClientUserInfoChanged");
    RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage");
    RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn", 1);

    static config_dir[MAX_RESOURCE_PATH_LENGTH];
    get_configsdir(config_dir, charsmax(config_dir));
    formatex(g_log_path, charsmax(g_log_path), "%s/proxy_logs.json", config_dir);
    formatex(g_whitelist_path, charsmax(g_whitelist_path), "%s/proxy_whitelist.ini", config_dir);

    set_task(10.0, "display_proxy_hud", .flags="b");
}

public client_connect(id)
{
    g_is_proxy[id] = false;
    g_half_damage[id] = false;
    g_active_troll[id] = 0;
    g_is_whitelisted[id] = check_file_whitelist(id);

    if (is_user_bot(id) || g_is_whitelisted[id])
        return;

    static ip[16];
    get_user_ip(id, ip, charsmax(ip), 1);
    if (!equal(ip, "127.0.0.1"))
        start_proxy_check(id, ip);
}

public fwd_PlayerSpawn(id)
{
    if (!is_user_alive(id) || !g_is_proxy[id] || !get_pcvar_num(g_cvar_troll))
        return;

    switch(g_active_troll[id])
    {
        case 1:
        {
            message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), {0,0,0}, id);
            write_short(1<<14); write_short(1<<14); write_short(1<<14);
            message_end();
        }
        case 2: set_user_health(id, 50);
        case 4:
        {
            set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
            set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25);
        }
    }
}

public fwd_ClientUserInfoChanged(id, infobuffer)
{
    if (!g_is_proxy[id] || !get_pcvar_num(g_cvar_troll))
        return FMRES_IGNORED;

    static current_name[MAX_NAME_LENGTH], target_name[MAX_NAME_LENGTH];
    engfunc(EngFunc_InfoKeyValue, infobuffer, "name", current_name, charsmax(current_name));
    formatex(target_name, charsmax(target_name), "PROXY: %s", g_original_name[id]);

    if (!equal(current_name, target_name))
    {
        engfunc(EngFunc_SetClientKeyValue, id, infobuffer, "name", target_name);
        return FMRES_HANDLED;
    }
    return FMRES_IGNORED;
}

public fwd_TakeDamage(victim, inflictor, attacker, Float:damage, damage_bits)
{
    if (is_user_connected(attacker) && g_half_damage[attacker])
    {
        SetHamParamFloat(4, damage * 0.5);
        return HAM_HANDLED;
    }
    return HAM_IGNORED;
}

public start_proxy_check(id, const ip[])
{
    static token[MAX_NAME_LENGTH], request[MAX_FMT_LENGTH], authid[MAX_AUTHID_LENGTH], modname[MAX_NAME_LENGTH];
    get_pcvar_string(g_cvar_token, token, charsmax(token));
    get_user_authid(id, authid, charsmax(authid));
    get_modname(modname, charsmax(modname));

    static error, socket;
    socket = socket_open("proxycheck.io", 80, SOCKET_TCP, error);
    
    if (socket > 0)
    {
        formatex(request, charsmax(request),
            "GET /v2/%s?key=%s&vpn=1&risk=2&asn=1&tag=%s-%s HTTP/1.1^nHost: proxycheck.io^nConnection: close^n^n",
            ip, token, modname, authid);

        socket_send(socket, request, charsmax(request));

        static data[12];
        num_to_str(id, data, charsmax(data));
        set_task(1.5, "parse_json_response", socket, data, charsmax(data));
    }
}

public parse_json_response(const data[], socket)
{
    new id = str_to_num(data);
    static buffer[2048];
    socket_recv(socket, buffer, charsmax(buffer));
    socket_close(socket);

    new body_start = contain(buffer, "{");
    if (body_start == -1) return;

    new JSON:root = json_parse(buffer[body_start]);
    if (root == Invalid_JSON) return;

    static ip[16];
    get_user_ip(id, ip, charsmax(ip), 1);

    new JSON:ip_obj = json_object_get_value(root, ip);
    if (ip_obj != Invalid_JSON)
    {
        new risk_score = json_object_get_number(ip_obj, "risk");
        if (risk_score >= get_pcvar_num(g_cvar_risk_kick))
        {
            static country[MAX_NAME_LENGTH], isp[MAX_NAME_LENGTH * 2], attack_reason[MAX_NAME_LENGTH];
            copy(attack_reason, charsmax(attack_reason), "Proxy/VPN");

            new JSON:history = json_object_get_value(ip_obj, "attack history");
            if (history != Invalid_JSON)
            {
                if (json_object_has_value(history, "Vulnerability Probing"))
                    copy(attack_reason, charsmax(attack_reason), "Vulnerability Probing");
                else if (json_object_has_value(history, "Login Attempt"))
                    copy(attack_reason, charsmax(attack_reason), "Brute Force");
                else if (json_object_has_value(history, "Comment Spam"))
                    copy(attack_reason, charsmax(attack_reason), "Spam Bot");
                json_free(history);
            }

            json_object_get_string(ip_obj, "country", country, charsmax(country));
            json_object_get_string(ip_obj, "isp", isp, charsmax(isp));
            execute_troll(id, ip, risk_score, country, isp, attack_reason);
        }
    }
    json_free(root);
}

public execute_troll(id, const ip[], risk, const country[], const isp[], const reason[])
{
    if (g_is_whitelisted[id] || !is_user_connected(id)) return;

    if (get_playersnum() >= (get_maxplayers() - 2))
    {
        server_cmd("kick #%d ^"Server Full: High Risk Proxy (%d%%)^"", get_user_userid(id), risk);
        return;
    }

    g_is_proxy[id] = true;
    get_user_name(id, g_original_name[id], charsmax(g_original_name[]));

    static admin_msg[MAX_FMT_LENGTH];
    formatex(admin_msg, charsmax(admin_msg), "^x04[ProxySnort]^x03 %s^x01 (Risk: %d%%) - Type: ^x04%s", g_original_name[id], risk, reason);

    new players[MAX_PLAYERS], pnum;
    get_players(players, pnum, "ch");
    for(new i = 0; i < pnum; i++)
    {
        if(get_user_flags(players[i]) & ADMIN_KICK)
            client_print_color(players[i], print_team_default, admin_msg);
    }

    for (new i = MAX_HUD_ENTRIES - 1; i > 0; i--)
    {
        copy(g_names[i], charsmax(g_names[]), g_names[i-1]);
        copy(g_info[i], charsmax(g_info[]), g_info[i-1]);
        g_risks[i] = g_risks[i-1];
    }

    copy(g_names[0], charsmax(g_names[]), g_original_name[id]);
    formatex(g_info[0], charsmax(g_info[]), "%s (%s)", country, reason);
    g_risks[0] = risk;

    if (g_entry_count < MAX_HUD_ENTRIES) g_entry_count++;

    g_active_troll[id] = random_num(1, 4);
    if (g_active_troll[id] == 3) g_half_damage[id] = true;

    static troll_name[MAX_NAME_LENGTH];
    get_troll_name(g_active_troll[id], troll_name, charsmax(troll_name));

    static Float:origin[3];
    pev(id, pev_origin, origin);

    message_begin(MSG_ONE_UNRELIABLE, SVC_SPAWNSTATICSOUND, .player=id);
    write_coord(floatround(origin[0])); 
    write_coord(floatround(origin[1])); 
    write_coord(floatround(origin[2]));
    write_short(g_sound_index); 
    write_byte(255); 
    write_byte(60);  
    write_byte(0);   
    write_byte(64);  
    message_end();

    fwd_PlayerSpawn(id);
    log_to_json(id, ip, risk, troll_name, reason);

    static kick_data[MAX_NAME_LENGTH];
    copy(kick_data, charsmax(kick_data), reason);
    set_task(8.0, "delayed_kick_custom", id, kick_data, charsmax(kick_data));
}

public delayed_kick_custom(const reason[], id)
{
    if (is_user_connected(id))
        server_cmd("kick #%d ^"Security Risk: %s (%d%% Risk)^"", get_user_userid(id), reason, g_risks[0]);
}

public log_to_json(id, const ip[], risk, const troll[], const reason[])
{
    new JSON:root = Invalid_JSON;
    if (file_exists(g_log_path)) root = json_parse(g_log_path, true);
    if (root == Invalid_JSON) root = json_init_array();

    new iCurrentTime = get_systime();
    new iCutoff = iCurrentTime - (get_pcvar_num(g_cvar_prune) * 86400);

    for (new i = 0; i < json_array_get_count(root); i++)
    {
        new JSON:temp = json_array_get_value(root, i);
        if (json_object_get_number(temp, "timestamp") < iCutoff)
            json_array_remove(root, i--);
        json_free(temp);
    }

    new JSON:entry = json_init_object();
    static name[MAX_NAME_LENGTH], t[MAX_NAME_LENGTH];
    get_user_name(id, name, charsmax(name));
    get_time("%m/%d %H:%M", t, charsmax(t));

    json_object_set_number(entry, "timestamp", iCurrentTime);
    json_object_set_string(entry, "time", t);
    json_object_set_string(entry, "user", name);
    json_object_set_string(entry, "ip", ip);
    json_object_set_number(entry, "risk", risk);
    json_object_set_string(entry, "attack_type", reason);
    json_object_set_string(entry, "troll", troll);

    json_array_append_value(root, entry);
    if (json_array_get_count(root) > 100) json_array_remove(root, 0);

    json_serial_to_file(root, g_log_path, true);
    json_free(entry); json_free(root);
}

public cmd_show_proxies(id)
{
    if (!(get_user_flags(id) & ADMIN_KICK) || g_entry_count == 0)
        return PLUGIN_HANDLED;

    client_print(id, print_chat, "--- Recent Proxy Detections ---");
    for (new i = 0; i < g_entry_count; i++)
        client_print(id, print_chat, "#%d: %s (%d%% Risk) - %s", i + 1, g_names[i], g_risks[i], g_info[i]);

    return PLUGIN_HANDLED;
}

public display_proxy_hud()
{
    if (g_entry_count == 0) return;

    static hud_text[MAX_FMT_LENGTH];
    new len = formatex(hud_text, charsmax(hud_text), "[ Recent Proxy Blocks ]^n");

    for (new i = 0; i < g_entry_count; i++)
        len += formatex(hud_text[len], charsmax(hud_text) - len, "%s (%d%%) - %s^n", g_names[i], g_risks[i], g_info[i]);

    set_hudmessage(150, 150, 150, 0.75, 0.02, 0, 0.0, 10.1, 0.1, 0.1, -1);
    ShowSyncHudMsg(0, g_hud_sync, hud_text);
}

public bool:check_file_whitelist(id)
{
    if (!file_exists(g_whitelist_path)) return false;

    static authid[MAX_AUTHID_LENGTH], line[MAX_AUTHID_LENGTH + 4];
    new file = fopen(g_whitelist_path, "rt");
    get_user_authid(id, authid, charsmax(authid));

    if (file)
    {
        while (!feof(file))
        {
            fgets(file, line, charsmax(line));
            trim(line);
            
            // FIXED: index array 'line' properly for 1.10 compatibility
            if (line[0] == ';' || line[0] == '#' || !line[0]) 
                continue;
                
            if (equal(authid, line)) { fclose(file); return true; }
        }
        fclose(file);
    }
    return false;
}

public get_troll_name(type, dest[], len)
{
    switch(type)
    {
        case 1: copy(dest, len, "Screen Shake");
        case 2: copy(dest, len, "Half HP");
        case 3: copy(dest, len, "Half Damage");
        case 4: copy(dest, len, "Freeze");
        default: copy(dest, len, "None");
    }
}

public cmd_whitelist_add(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;

    static arg[MAX_PLAYERS];
    read_argv(1, arg, charsmax(arg));
    new target = cmd_target(id, arg, 0);

    if (target)
    {
        static authid[MAX_AUTHID_LENGTH], name[MAX_NAME_LENGTH];
        get_user_authid(target, authid, charsmax(authid));
        get_user_name(target, name, charsmax(name));
        write_file(g_whitelist_path, authid, -1);
        g_is_whitelisted[target] = true;
        g_is_proxy[target] = false;
        console_print(id, "[ProxySnort] Added %s to whitelist.", name);
    }
    return PLUGIN_HANDLED;
}
