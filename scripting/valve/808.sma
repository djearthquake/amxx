#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <json>
#include <fun>

#define PLUGIN  "Bonzo Studio: Ultra-Spaced Unified"
#define VERSION "9.9"
#define AUTHOR  "djearthquake"

#define MAX_STEPS       8
#define TRACKS          11
#define MAX_VAULT_SAVES 30
#define MAX_NAME_LEN    32

static const g_drum_samples[TRACKS][MAX_NAME_LEN] =
{
	"weapons/g_bounce1.wav", "weapons/ric1.wav", "debris/wood1.wav", "debris/wood2.wav",
	"debris/metal2.wav", "buttons/button3.wav", "weapons/pl_gun1.wav", "items/gunpickup2.wav",
	"weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav", "weapons/hvy_bounce.wav"
};

new bool:g_step[MAX_PLAYERS + 1][TRACKS][MAX_STEPS];
new g_current_step[MAX_PLAYERS + 1], bool:g_is_playing[MAX_PLAYERS + 1];
new g_menu_track[MAX_PLAYERS + 1], Float:g_tempo[MAX_PLAYERS + 1];

new g_vault_path[128], bool:g_naming[MAX_PLAYERS + 1], bool:g_muted[MAX_PLAYERS + 1];
new g_last_author[MAX_PLAYERS + 1][MAX_NAME_LEN];

// --- HELPER FUNCTIONS (Defined first so they can be called by menus) ---

clear_current_pattern(id)
{
	for (new t = 0; t < TRACKS; t++)
	{
		for (new s = 0; s < MAX_STEPS; s++)
		{
			g_step[id][t][s] = false;
		}
	}
}

public beat_clock(id)
{
	if (!g_is_playing[id] || !is_user_connected(id))
	{
		return;
	}

	for (new t = 0; t < TRACKS; t++)
	{
		if (g_step[id][t][g_current_step[id]])
		{
			for (new i = 1; i <= MAX_PLAYERS; i++)
			{
				if (is_user_connected(i) && !g_muted[i])
				{
					client_cmd(i, "spk %s", g_drum_samples[t]);
				}
			}
		}
	}

	g_current_step[id] = (g_current_step[id] + 1) % MAX_STEPS;
	set_task(g_tempo[id], "beat_clock", id, .flags="a", .repeat=1);
}

public callback_disabled(id, menu, item)
{
	return ITEM_DISABLED;
}

save_to_global_vault(id, const beat_name[])
{
	new JSON:root = file_exists(g_vault_path) ? json_parse(g_vault_path, true) : json_init_array();
	if (root == Invalid_JSON) root = json_init_array();

	new JSON:entry = json_init_object();
	new p_name[MAX_NAME_LEN], final_credit[MAX_NAME_LEN * 2];
	get_user_name(id, p_name, charsmax(p_name));

	if (g_last_author[id][0] != 0 && !equal(p_name, g_last_author[id]))
	{
		formatex(final_credit, charsmax(final_credit), "%s + %s", g_last_author[id], p_name);
	}
	else
	{
		copy(final_credit, charsmax(final_credit), p_name);
	}

	json_object_set_string(entry, "title", beat_name);
	json_object_set_string(entry, "author", final_credit);

	new JSON:data = json_init_array();
	for (new t = 0; t < TRACKS; t++)
	{
		new JSON:row = json_init_array();
		for (new s = 0; s < MAX_STEPS; s++)
		{
			json_array_append_bool(row, g_step[id][t][s]);
		}
		json_array_append_value(data, row);
		json_free(row);
	}
	json_object_set_value(entry, "pattern", data);
	json_array_append_value(root, entry);

	if (json_array_get_count(root) > MAX_VAULT_SAVES)
	{
		json_array_remove(root, 0);
	}

	json_serial_to_file(root, g_vault_path, true);
	json_free(data);
	json_free(entry);
	json_free(root);
}

// --- MENU FUNCTIONS ---

public cmd_studio_menu(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new names[TRACKS][4] = { "BD", "SD", "CH", "OH", "CY", "CB", "RS", "CP", "LT", "MT", "HT" };
	new title[128];

	formatex(title, charsmax(title), "\y808 STUDIO^n^n^n\d- \r[%s]^n^n\wTempo: \y%.2fs^n^n^n", names[g_menu_track[id]], g_tempo[id]);

	new menu = menu_create(title, "studio_handler");

	for (new i = 0; i < MAX_STEPS; i++)
	{
		new txt[64], info[3];
		formatex(txt, charsmax(txt), "\wStep %d: %s", i + 1, g_step[id][g_menu_track[id]][i] ? "[\rON\y]" : "[\dOFF\y]");
		num_to_str(i, info, charsmax(info));
		menu_additem(menu, txt, info);
	}

	menu_additem(menu, "\d ", "999", .callback = menu_makecallback("callback_disabled"));

	menu_additem(menu, "\y[+] Tempo Faster", "101");
	menu_additem(menu, "\r[-] Tempo Slower", "102");

	new track_info[64];
	formatex(track_info, charsmax(track_info), "\wNext Track \d(%s)", names[g_menu_track[id]]);
	menu_additem(menu, track_info, "103");

	menu_additem(menu, "\rCLEAR PATTERN", "104");

	menu_additem(menu, "\d ", "999", .callback = menu_makecallback("callback_disabled"));

	menu_additem(menu, "\gSAVE BEAT", "106");
	menu_additem(menu, "\vLOAD BEAT", "107");
	menu_additem(menu, g_is_playing[id] ? "\rSTOP ENGINE" : "\gSTART ENGINE", "105");

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public cmd_load_menu(id)
{
	if (!file_exists(g_vault_path))
	{
		client_print(id, print_chat, "[Bonzo] Vault is empty!");
		return PLUGIN_HANDLED;
	}

	new JSON:root = json_parse(g_vault_path, true);
	if (root == Invalid_JSON) return PLUGIN_HANDLED;

	new menu = menu_create("\yBonzo Beat Vault^n^n^n^n\dSelect a pattern:^n^n", "load_handler");
	menu_setprop(menu, MPROP_PERPAGE, 3);

	new count = json_array_get_count(root);
	for (new i = 0; i < count; i++)
	{
		new JSON:item_obj = json_array_get_value(root, i);
		new title[32], author[MAX_NAME_LEN], disp[128], info[4];

		json_object_get_string(item_obj, "title", title, charsmax(title));
		json_object_get_string(item_obj, "author", author, charsmax(author));

		formatex(disp, charsmax(disp), "\w%s^n\d--------------------^n\yBy: \w%s^n\d ", title, author);
		num_to_str(i, info, charsmax(info));

		menu_additem(menu, disp, info);
		json_free(item_obj);
	}

	menu_additem(menu, "\d ", "999", .callback = menu_makecallback("callback_disabled"));
	json_free(root);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

// --- HANDLERS ---

public studio_handler(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new info[6], _access, callback;
	menu_item_getinfo(menu, item, _access, info, charsmax(info), _, _, callback);
	new choice = str_to_num(info);

	if (choice == 999) return PLUGIN_CONTINUE;

	switch(choice)
	{
		case 101: g_tempo[id] = floatmax(0.05, g_tempo[id] - 0.02);
		case 102: g_tempo[id] = floatmin(1.0, g_tempo[id] + 0.02);
		case 103: g_menu_track[id] = (g_menu_track[id] + 1) % TRACKS;
		case 104: { clear_current_pattern(id); g_last_author[id][0] = 0; }
		case 106: { g_naming[id] = true; client_print(id, print_chat, "[Bonzo] Name your beat in chat!"); menu_destroy(menu); return PLUGIN_HANDLED; }
		case 107: { menu_destroy(menu); cmd_load_menu(id); return PLUGIN_HANDLED; }
		case 105:
		{
			g_is_playing[id] = !g_is_playing[id];
			if (g_is_playing[id]) { g_current_step[id] = 0; beat_clock(id); }
			else remove_task(id);
		}
		default:
		{
			if (choice >= 0 && choice < MAX_STEPS)
				g_step[id][g_menu_track[id]][choice] = !g_step[id][g_menu_track[id]][choice];
		}
	}

	menu_destroy(menu);
	cmd_studio_menu(id);
	return PLUGIN_HANDLED;
}

public load_handler(id, menu, item)
{
	if (item == MENU_EXIT) { menu_destroy(menu); cmd_studio_menu(id); return PLUGIN_HANDLED; }
	new info[6];
	menu_item_getinfo(menu, item, _, info, charsmax(info), _, _, _);
	new idx = str_to_num(info);
	if (idx == 999) return PLUGIN_CONTINUE;

	new JSON:root = json_parse(g_vault_path, true);
	new JSON:entry = json_array_get_value(root, idx);
	json_object_get_string(entry, "author", g_last_author[id], charsmax(g_last_author[]));

	new JSON:pattern = json_object_get_value(entry, "pattern");
	for (new t = 0; t < TRACKS; t++)
	{
		new JSON:row = json_array_get_value(pattern, t);
		for (new s = 0; s < MAX_STEPS; s++) g_step[id][t][s] = json_array_get_bool(row, s);
		json_free(row);
	}

	json_free(pattern); json_free(entry); json_free(root);
	menu_destroy(menu);
	cmd_studio_menu(id);
	return PLUGIN_HANDLED;
}

// --- PLUGIN INIT ---

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /bonzo", "cmd_studio_menu", 0, "- Opens the Drum Studio");
	register_clcmd("say /mute", "cmd_mute_toggle", 0, "- Toggles drum sounds");
	register_clcmd("say", "handle_say_name", 0, "- Name your beats");

	new cfg_dir[64];
	get_configsdir(cfg_dir, charsmax(cfg_dir));
	formatex(g_vault_path, charsmax(g_vault_path), "%s/bonzo_global.json", cfg_dir);
}

public client_putinserver(id)
{
	g_is_playing[id] = false;
	g_tempo[id] = 0.20;
	g_muted[id] = false;
	g_naming[id] = false;
	g_last_author[id][0] = 0;
	clear_current_pattern(id);
}

public handle_say_name(id)
{
	if (!g_naming[id]) return PLUGIN_CONTINUE;
	new beat_name[32];
	read_args(beat_name, charsmax(beat_name));
	remove_quotes(beat_name); trim(beat_name);
	if (strlen(beat_name) > 0)
	{
		save_to_global_vault(id, beat_name);
		g_naming[id] = false;
	}
	cmd_studio_menu(id);
	return PLUGIN_HANDLED;
}

public cmd_mute_toggle(id)
{
	g_muted[id] = !g_muted[id];
	client_print(id, print_chat, "[Bonzo] Mute: %s", g_muted[id] ? "ON" : "OFF");
	return PLUGIN_HANDLED;
}
