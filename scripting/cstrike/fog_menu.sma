#include amxmodx
#include amxmisc

static g_m;
static g_iModeCvar;

// Global Settings (Mode 0: Admin)
static g_c[3] = { 255, 255, 255 };
static Float:g_d = 0.0;
static bool:g_a = false;
static bool:g_r = false;
static Float:g_h = 0.0;

// Per-player Settings (Mode 1: Clients)
static g_cc[MAX_PLAYERS + 1][3];
static Float:g_dd[MAX_PLAYERS + 1];
static bool:g_aa[MAX_PLAYERS + 1];
static bool:g_rr[MAX_PLAYERS + 1];
static Float:g_hh[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin("Fog Dual Mode Engine", "0.1", "SPiNX");

    if (!cvar_exists("mp_startmoney"))
    {
        set_fail_state("CS only");
        return;
    }

    g_iModeCvar = register_cvar("amx_fog_per_user", "0");
    register_clcmd("amx_fogmenu", "cmd_open_routing", 0, "");
    g_m = get_user_msgid("Fog");
}

public client_putinserver(id)
{
    g_cc[id][0] = 255;
    g_cc[id][1] = 255;
    g_cc[id][2] = 255;
    g_dd[id] = 0.0;
    g_aa[id] = false;
    g_rr[id] = false;
    g_hh[id] = 0.0;

    if (is_user_connected(id) && !is_user_bot(id))
    {
        set_task(0.5, "upd", id);
    }
}

public upd(id)
{
    if (get_pcvar_num(g_iModeCvar) == 1)
    {
        if (g_aa[id])
        {
            msg(id, g_cc[id][0], g_cc[id][1], g_cc[id][2], g_dd[id], false);
        }
    }
    else
    {
        if (g_a)
        {
            msg(id, g_c[0], g_c[1], g_c[2], g_d, false);
        }
    }
}

public cmd_open_routing(id)
{
    new isPerUser = get_pcvar_num(g_iModeCvar);

    if (isPerUser == 0 && !(get_user_flags(id) & ADMIN_RCON))
    {
        client_print_color(id, print_team_default, "^x04[AMXX]^x01 Restricted to Admins (Global Mode Active).");
        return PLUGIN_HANDLED;
    }

    m_main(id);
    return PLUGIN_HANDLED;
}

static s_r(id, bool:globalMode)
{
    if (globalMode)
    {
        if (g_r)
        {
            remove_task(1337);
            g_r = false;
        }
    }
    else
    {
        if (g_rr[id])
        {
            remove_task(2000 + id);
            g_rr[id] = false;
        }
    }
}

static sync(id, bool:globalMode)
{
    if (globalMode)
    {
        if (!g_a)
        {
            msg(0, 0, 0, 0, 0.0, true);
        }
        else if (!g_r)
        {
            msg(0, g_c[0], g_c[1], g_c[2], g_d, false);
        }
    }
    else
    {
        if (!g_aa[id])
        {
            msg(id, 0, 0, 0, 0.0, true);
        }
        else if (!g_rr[id])
        {
            msg(id, g_cc[id][0], g_cc[id][1], g_cc[id][2], g_dd[id], false);
        }
    }
}
public m_main(id)
{
    new m = menu_create("Fog Engine Interface:", "h_main");
    static s[64];
    new isPerUser = get_pcvar_num(g_iModeCvar);

    new bool:active = (isPerUser == 1) ? g_aa[id] : g_a;

    formatex(s, charsmax(s), "Engine Status: %s", active ? "\yACTIVE" : "\dDISABLED");
    menu_additem(m, s, "1");

    formatex(s, charsmax(s), "Tuning Submenu (Density/RGB)");
    menu_additem(m, s, "2");

    formatex(s, charsmax(s), "Profiles & Color Palettes");
    menu_additem(m, s, "3");

    menu_display(id, m, 0);
}

public h_main(id, m, it)
{
    if (it == MENU_EXIT)
    {
        menu_destroy(m);
        return PLUGIN_HANDLED;
    }

    static dt[2];
    menu_item_getinfo(m, it, _, dt, charsmax(dt), _, 0, _);
    menu_destroy(m);

    new isPerUser = get_pcvar_num(g_iModeCvar);

    switch (dt[0])
    {
        case '1':
        {
            if (isPerUser == 1)
            {
                g_aa[id] = !g_aa[id];
                if (!g_aa[id])
                {
                    s_r(id, false);
                }
                else if (g_dd[id] == 0.0)
                {
                    g_dd[id] = 0.005;
                }
                sync(id, false);
            }
            else
            {
                g_a = !g_a;
                if (!g_a)
                {
                    s_r(id, true);
                }
                else if (g_d == 0.0)
                {
                    g_d = 0.005;
                }
                sync(id, true);
            }
            m_main(id);
        }
        case '2':
        {
            m_tune(id);
        }
        case '3':
        {
            m_palette(id, 0);
        }
    }
    return PLUGIN_HANDLED;
}

public m_tune(id)
{
    new m = menu_create("Fog Tuning Options:", "h_tune");
    static s[64];
    new isPerUser = get_pcvar_num(g_iModeCvar);

    new Float:density = (isPerUser == 1) ? g_dd[id] : g_d;
    new r = (isPerUser == 1) ? g_cc[id][0] : g_c[0];
    new g = (isPerUser == 1) ? g_cc[id][1] : g_c[1];
    new b = (isPerUser == 1) ? g_cc[id][2] : g_c[2];
    new bool:rainbow = (isPerUser == 1) ? g_rr[id] : g_r;

    formatex(s, charsmax(s), "Density Scale: \r%.4f", density);
    menu_additem(m, s, "1");

    formatex(s, charsmax(s), "RGB Palette: \rR:%d \yG:%d \wB:%d", r, g, b);
    menu_additem(m, s, "2");

    formatex(s, charsmax(s), "Rainbow Cycle Engine: %s", rainbow ? "\r[ON]" : "\d[OFF]");
    menu_additem(m, s, "3");

    menu_display(id, m, 0);
}

public h_tune(id, m, it)
{
    if (it == MENU_EXIT)
    {
        menu_destroy(m);
        m_main(id);
        return PLUGIN_HANDLED;
    }

    static dt[2];
    menu_item_getinfo(m, it, _, dt, charsmax(dt), _, 0, _);
    menu_destroy(m);

    new isPerUser = get_pcvar_num(g_iModeCvar);

    switch (dt[0])
    {
        case '1':
        {
            new nm = menu_create("Select Density Intensity:", "h_d");
            menu_additem(nm, "Very Light (0.0015)", "1");
            menu_additem(nm, "Light (0.0035)", "2");
            menu_additem(nm, "Medium Mist (0.0065)", "3");
            menu_additem(nm, "Heavy Haze (0.0120)", "4");
            menu_additem(nm, "Blindness (0.0250)", "5");
            menu_display(id, nm, 0);
        }
        case '2':
        {
            s_r(id, (isPerUser == 0));
            new nm = menu_create("Select RGB Channel:", "h_ch");
            static s[64];
            new r = (isPerUser == 1) ? g_cc[id][0] : g_c[0];
            new g = (isPerUser == 1) ? g_cc[id][1] : g_c[1];
            new b = (isPerUser == 1) ? g_cc[id][2] : g_c[2];
            formatex(s, charsmax(s), "Red Color Channel: \r[%d]", r); menu_additem(nm, s, "0");
            formatex(s, charsmax(s), "Green Color Channel: \y[%d]", g); menu_additem(nm, s, "1");
            formatex(s, charsmax(s), "Blue Color Channel: \w[%d]", b); menu_additem(nm, s, "2");
            menu_display(id, nm, 0);
        }
        case '3':
        {
            if (isPerUser == 1)
            {
                if (g_rr[id])
                {
                    s_r(id, false);
                    sync(id, false);
                }
                else
                {
                    g_aa[id] = true;
                    if (g_dd[id] == 0.0)
                    {
                        g_dd[id] = 0.006;
                    }
                    g_rr[id] = true;
                    g_hh[id] = 0.0;
                    set_task(0.2, "rb_user_loop", 2000 + id, _, _, "b");
                }
            }
            else
            {
                if (g_r)
                {
                    s_r(id, true);
                    sync(id, true);
                }
                else
                {
                    g_a = true;
                    if (g_d == 0.0)
                    {
                        g_d = 0.006;
                    }
                    g_r = true;
                    g_h = 0.0;
                    set_task(0.2, "rb_global_loop", 1337, _, _, "b");
                }
            }
            m_tune(id);
        }
    }
    return PLUGIN_HANDLED;
}
public h_d(id, m, it)
{
    if (it == MENU_EXIT)
    {
        menu_destroy(m);
        m_tune(id);
        return PLUGIN_HANDLED;
    }

    static dt[2];
    menu_item_getinfo(m, it, _, dt, charsmax(dt), _, 0, _);

    new isPerUser = get_pcvar_num(g_iModeCvar);
    new Float:val = 0.005;

    switch (dt[0])
    {
        case '1': val = 0.0015;
        case '2': val = 0.0035;
        case '3': val = 0.0065;
        case '4': val = 0.0120;
        case '5': val = 0.0250;
    }

    if (isPerUser == 1)
    {
        g_dd[id] = val;
        g_aa[id] = true;
        sync(id, false);
    }
    else
    {
        g_d = val;
        g_a = true;
        sync(id, true);
    }

    menu_display(id, m, 0);
    return PLUGIN_HANDLED;
}

public h_ch(id, m, it)
{
    if (it == MENU_EXIT)
    {
        menu_destroy(m);
        m_tune(id);
        return PLUGIN_HANDLED;
    }

    static dt[2];
    menu_item_getinfo(m, it, _, dt, charsmax(dt), _, 0, _);
    menu_destroy(m);

    new ch = str_to_num(dt);
    new nm = menu_create("Dial Control Shift:", "h_t");
    static s[32];

    formatex(s, charsmax(s), "%d_1", ch);
    menu_additem(nm, "Increase (+15)", s);
    formatex(s, charsmax(s), "%d_2", ch);
    menu_additem(nm, "Decrease (-15)", s);
    formatex(s, charsmax(s), "%d_3", ch);
    menu_additem(nm, "Highly Boost (+50)", s);
    formatex(s, charsmax(s), "%d_4", ch);
    menu_additem(nm, "Highly Drop (-50)", s);

    menu_display(id, nm, 0);
    return PLUGIN_HANDLED;
}

public h_t(id, m, it)
{
    if (it == MENU_EXIT)
    {
        menu_destroy(m);
        m_tune(id);
        return PLUGIN_HANDLED;
    }

    static dt[8], c_s[4], a_s[4];
    menu_item_getinfo(m, it, _, dt, charsmax(dt), _, 0, _);
    menu_destroy(m);

    strtok(dt, c_s, charsmax(c_s), a_s, charsmax(a_s), '_');
    new ch = str_to_num(c_s);
    new ac = str_to_num(a_s);
    new isPerUser = get_pcvar_num(g_iModeCvar);
    new diff = 0;

    switch (ac)
    {
        case 1: diff = 15;
        case 2: diff = -15;
        case 3: diff = 50;
        case 4: diff = -50;
    }

    if (isPerUser == 1)
    {
        g_cc[id][ch] = clamp(g_cc[id][ch] + diff, 0, 255);
        sync(id, false);
    }
    else
    {
        g_c[ch] = clamp(g_c[ch] + diff, 0, 255);
        sync(id, true);
    }

    new nm = menu_create("Dial Control Shift:", "h_t");
    static s[32];

    formatex(s, charsmax(s), "%d_1", ch);
    menu_additem(nm, "Increase (+15)", s);
    formatex(s, charsmax(s), "%d_2", ch);
    menu_additem(nm, "Decrease (-15)", s);
    formatex(s, charsmax(s), "%d_3", ch);
    menu_additem(nm, "Highly Boost (+50)", s);
    formatex(s, charsmax(s), "%d_4", ch);
    menu_additem(nm, "Highly Drop (-50)", s);

    menu_display(id, nm, 0);
    return PLUGIN_HANDLED;
}

public m_palette(id, page)
{
    new m = menu_create("Presets Engine:", "h_p");

    menu_additem(m, "Clean White Profile", "1");
    menu_additem(m, "Deep Black Profile", "2");
    menu_additem(m, "Toxic Green Profile", "3");
    menu_additem(m, "Blood Red Profile", "4");
    menu_additem(m, "Deep Blue Profile", "5");
    menu_additem(m, "Cyberpunk Cyan", "6");
    menu_additem(m, "Acid Yellow", "7");
    menu_additem(m, "Royal Purple", "8");

    menu_display(id, m, page);
}

public h_p(id, m, it)
{
    if (it == MENU_EXIT)
    {
        menu_destroy(m);
        m_main(id);
        return PLUGIN_HANDLED;
    }

    static dt[4];
    menu_item_getinfo(m, it, _, dt, charsmax(dt), _, 0, _);
    menu_destroy(m);

    new isPerUser = get_pcvar_num(g_iModeCvar);
    s_r(id, (isPerUser == 0));

    new tr = 255, tg = 255, tb = 255;
    switch (str_to_num(dt))
    {
        case 1: { tr = 255; tg = 255; tb = 255; }
        case 2: { tr = 15; tg = 15; tb = 15; }
        case 3: { tr = 0; tg = 220; tb = 0; }
        case 4: { tr = 220; tg = 0; tb = 0; }
        case 5: { tr = 0; tg = 0; tb = 250; }
        case 6: { tr = 0; tg = 240; tb = 255; }
        case 7: { tr = 245; tg = 255; tb = 0; }
        case 8: { tr = 160; tg = 0; tb = 240; }
    }

    if (isPerUser == 1)
    {
        g_cc[id][0] = tr;
        g_cc[id][1] = tg;
        g_cc[id][2] = tb;
        if(g_dd[id] == 0.0)
        {
            g_dd[id] = 0.005;
        }
        g_aa[id] = true;
        sync(id, false);
    }
    else
    {
        g_c[0] = tr;
        g_c[1] = tg;
        g_c[2] = tb;
        if(g_d == 0.0)
        {
            g_d = 0.005;
        }
        g_a = true;
        sync(id, true);
    }

    m_tune(id);
    return PLUGIN_HANDLED;
}
public rb_global_loop()
{
    g_h += 5.0;
    if (g_h >= 360.0)
    {
        g_h = 0.0;
    }

    new Float:x = (1.0 - floatabs((g_h / 60.0) - floatround(g_h / 60.0, floatround_floor) * 2.0 - 1.0));
    new Float:r, Float:g, Float:b;

    if (g_h < 60.0) { r = 1.0; g = x; b = 0.0; }
    else if (g_h < 120.0) { r = x; g = 1.0; b = 0.0; }
    else if (g_h < 180.0) { r = 0.0; g = 1.0; b = x; }
    else if (g_h < 240.0) { r = 0.0; g = x; b = 1.0; }
    else if (g_h < 300.0) { r = x; g = 0.0; b = 1.0; }
    else { r = 1.0; g = 0.0; b = x; }

    // FIXED: Explicitly target array indices [0], [1], and [2]
    g_c[0] = floatround(r * 255.0);
    g_c[1] = floatround(g * 255.0);
    g_c[2] = floatround(b * 255.0);

    if(get_pcvar_num(g_iModeCvar) == 0)
    {
        msg(0, g_c[0], g_c[1], g_c[2], g_d, false);
    }
}

public rb_user_loop(taskId)
{
    new id = taskId - 2000;
    if (!is_user_connected(id))
    {
        return;
    }

    g_hh[id] += 5.0;
    if (g_hh[id] >= 360.0)
    {
        g_hh[id] = 0.0;
    }

    new Float:x = (1.0 - floatabs((g_hh[id] / 60.0) - floatround(g_hh[id] / 60.0, floatround_floor) * 2.0 - 1.0));
    new Float:r, Float:g, Float:b;

    if (g_hh[id] < 60.0) { r = 1.0; g = x; b = 0.0; }
    else if (g_hh[id] < 120.0) { r = x; g = 1.0; b = 0.0; }
    else if (g_hh[id] < 180.0) { r = 0.0; g = 1.0; b = x; }
    else if (g_hh[id] < 240.0) { r = 0.0; g = x; b = 1.0; }
    else if (g_hh[id] < 300.0) { r = x; g = 0.0; b = 1.0; }
    else { r = 1.0; g = 0.0; b = x; }

    // FIXED: Explicitly target per-player multi-dimensional array slots
    g_cc[id][0] = floatround(r * 255.0);
    g_cc[id][1] = floatround(g * 255.0);
    g_cc[id][2] = floatround(b * 255.0);

    if(get_pcvar_num(g_iModeCvar) == 1)
    {
        msg(id, g_cc[id][0], g_cc[id][1], g_cc[id][2], g_dd[id], false);
    }
}

stock msg(idx, r, g, b, Float:df, bool:cl)
{
    if (!idx || is_user_connected(idx))
    {
        new d = _:floatclamp(df, 0.0001, 0.25) * _:!cl;
        message_begin(idx ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_m, .player = idx);
        write_byte(clamp(r, 0, 255));
        write_byte(clamp(g, 0, 255));
        write_byte(clamp(b, 0, 255));
        write_long(_:d);
        message_end();
    }
}
