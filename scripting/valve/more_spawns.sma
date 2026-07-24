#include <amxmodx>
#include <fakemeta>

#define MAX_CHOSEN 64

// Explicit forward function prototypes to guarantee compilation visibility
forward render_private_admin_markers(id);
forward sprite_loop_callback(param[1]);

new Float:g_chosenX[MAX_CHOSEN];
new Float:g_chosenY[MAX_CHOSEN];
new Float:g_chosenZ[MAX_CHOSEN];
new g_chosenCount;

new g_genEnt[MAX_CHOSEN];
new g_genCount;

new bool:g_adminShowing[33];
new g_activeClassName[32];
new g_glowSprite;

public plugin_precache()
{
    g_glowSprite = precache_model("sprites/glow01.spr");
}

public plugin_init()
{
    register_plugin("Auto Spawn Generic", "1.8", "SPiNX");
    register_clcmd("asg_regen", "cmd_regen", ADMIN_MAP);
    register_clcmd("asg_show", "cmd_show", ADMIN_RCON);

    copy(g_activeClassName, charsmax(g_activeClassName), "info_player_deathmatch");

    set_task(3.0, "run_autospawns");
}

public client_disconnected(id)
{
    g_adminShowing[id] = false;
}

public remove_generated()
{
    new i;
    for (i = 0; i < g_genCount; i++)
    {
        if (pev_valid(g_genEnt[i]))
        {
            engfunc(EngFunc_RemoveEntity, g_genEnt[i]);
        }
    }
    g_genCount = 0;
}

public render_private_admin_markers(id)
{
    if (!is_user_connected(id) || !g_adminShowing[id])
    {
        return;
    }

    new ent;
    ent = -1;
    new Float:org[3];
    new count;
    count = 0;

    while (count < MAX_CHOSEN)
    {
        ent = engfunc(EngFunc_FindEntityByString, ent, "classname", g_activeClassName);
        if (ent <= 0)
        {
            break;
        }

        pev(ent, pev_origin, org);

        message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
        write_byte(17); // TE_SPRITE
        write_coord(floatround(org[0]));
        write_coord(floatround(org[1]));
        write_coord(floatround(org[2]) + 16);
        write_short(g_glowSprite);
        write_byte(10); // Scale
        write_byte(200); // Brightness
        message_end();

        count++;
    }

    new param[1];
    param[0] = id;
    set_task(2.5, "sprite_loop_callback", 0, param, 1);
}

public sprite_loop_callback(param[1])
{
    new id;
    id = param[0];
    render_private_admin_markers(id);
}

public bool:identify_map_spawns()
{
    if (engfunc(EngFunc_FindEntityByString, -1, "classname", "info_player_deathmatch") > 0)
    {
        copy(g_activeClassName, charsmax(g_activeClassName), "info_player_deathmatch");
        return true;
    }
    if (engfunc(EngFunc_FindEntityByString, -1, "classname", "info_op4ctf_team1") > 0)
    {
        copy(g_activeClassName, charsmax(g_activeClassName), "info_op4ctf_team1");
        return true;
    }
    if (engfunc(EngFunc_FindEntityByString, -1, "classname", "info_op4ctf_team2") > 0)
    {
        copy(g_activeClassName, charsmax(g_activeClassName), "info_op4ctf_team2");
        return true;
    }
    if (engfunc(EngFunc_FindEntityByString, -1, "classname", "info_player_start") > 0)
    {
        copy(g_activeClassName, charsmax(g_activeClassName), "info_player_start");
        return true;
    }
    return false;
}

public run_autospawns()
{
    g_chosenCount = 0;
    g_genCount = 0;

    if (!identify_map_spawns())
    {
        server_print("[ASG] Production Warning: No valid spawn entities recognized on this layout.");
        return;
    }

    new ent;
    ent = -1;
    new Float:org[3];

    while (g_chosenCount < MAX_CHOSEN)
    {
        ent = engfunc(EngFunc_FindEntityByString, ent, "classname", g_activeClassName);
        if (ent <= 0)
        {
            break;
        }

        pev(ent, pev_origin, org);
        g_chosenX[g_chosenCount] = org[0];
        g_chosenY[g_chosenCount] = org[1];
        g_chosenZ[g_chosenCount] = org[2];
        g_chosenCount++;
    }

    if (g_chosenCount == 0 || g_chosenCount >= 32)
    {
        return;
    }

    new need;
    need = 32 - g_chosenCount;
    new i;
    for (i = 0; i < need; i++)
    {
        new Float:bestX;
        new Float:bestY;
        new Float:bestZ;
        new bool:found;
        found = false;

        new j;
        for (j = 0; j < g_chosenCount; j++)
        {
            new d;
            for (d = 0; d < 8; d++)
            {
                new Float:candX;
                new Float:candY;
                new Float:candZ;

                if (d == 0) { candX = g_chosenX[j] + 128.0; candY = g_chosenY[j]; }
                else if (d == 1) { candX = g_chosenX[j] - 128.0; candY = g_chosenY[j]; }
                else if (d == 2) { candX = g_chosenX[j]; candY = g_chosenY[j] + 128.0; }
                else if (d == 3) { candX = g_chosenX[j]; candY = g_chosenY[j] - 128.0; }
                else if (d == 4) { candX = g_chosenX[j] + 90.0; candY = g_chosenY[j] + 90.0; }
                else if (d == 5) { candX = g_chosenX[j] + 90.0; candY = g_chosenY[j] - 90.0; }
                else if (d == 6) { candX = g_chosenX[j] - 90.0; candY = g_chosenY[j] + 90.0; }
                else if (d == 7) { candX = g_chosenX[j] - 90.0; candY = g_chosenY[j] - 90.0; }
                candZ = g_chosenZ[j];

                new Float:candVec[3];
                candVec[0] = candX;
                candVec[1] = candY;
                candVec[2] = candZ;

                new tr;
                tr = create_tr2();
                engfunc(EngFunc_TraceHull, candVec, candVec, 1, 1, 0, tr);
                new bool:stuck;
                stuck = get_tr2(tr, TR_StartSolid) ? true : false;
                free_tr2(tr);

                if (!stuck)
                {
                    new bool:tooClose;
                    tooClose = false;
                    new k;
                    for (k = 0; k < g_chosenCount; k++)
                    {
                        new Float:dx;
                        new Float:dy;
                        new Float:dz;
                        dx = candX - g_chosenX[k];
                        dy = candY - g_chosenY[k];
                        dz = candZ - g_chosenZ[k];
                        new Float:distSq;
                        distSq = (dx * dx) + (dy * dy) + (dz * dz);
                        if (distSq < 9216.0)
                        {
                            tooClose = true;
                            break;
                        }
                    }

                    if (!tooClose)
                    {
                        bestX = candX;
                        bestY = candY;
                        bestZ = candZ;
                        found = true;
                        break;
                    }
                }
            }
            if (found)
            {
                break;
            }
        }

        if (!found)
        {
            break;
        }

        new newEnt;
        newEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, g_activeClassName));
        if (newEnt > 0)
        {
            new Float:spawnVec[3];
            spawnVec[0] = bestX;
            spawnVec[1] = bestY;
            spawnVec[2] = bestZ;

            new Float:angVec[3];
            new randVal;
            randVal = random_num(0, 360);
            angVec[0] = 0.0;
            angVec[1] = float(randVal);
            angVec[2] = 0.0;

            engfunc(EngFunc_SetOrigin, newEnt, spawnVec);
            set_pev(newEnt, pev_angles, angVec);
            dllfunc(DLLFunc_Spawn, newEnt);

            g_genEnt[g_genCount] = newEnt;
            g_genCount++;

            g_chosenX[g_chosenCount] = bestX;
            g_chosenY[g_chosenCount] = bestY;
            g_chosenZ[g_chosenCount] = bestZ;
            g_chosenCount++;
        }
    }
}

public cmd_regen(id)
{
    g_adminShowing[id] = false;
    remove_generated();
    run_autospawns();
    console_print(id, "[ASG] Re-generated spawn matrix layout safely.");
    return 1;
}

public cmd_show(id)
{
    g_adminShowing[id] = !g_adminShowing[id];

    if (g_adminShowing[id])
    {
        render_private_admin_markers(id);

        new ent;
        ent = -1;
        new Float:org[3];
        new index;
        index = 1;

        console_print(id, "--- Active Spawns Profile [%s] ---", g_activeClassName);

        while (index <= g_chosenCount)
        {
            ent = engfunc(EngFunc_FindEntityByString, ent, "classname", g_activeClassName);
            if (ent <= 0)
            {
                break;
            }

            pev(ent, pev_origin, org);
            console_print(id, "Node %d: X: %.1f | Y: %.1f | Z: %.1f", index, org[0], org[1], org[2]);
            index++;
        }

        console_print(id, "Total verified mapside targets: %d", index - 1);
    }

    console_print(id, "[ASG] Private tracking glowing sprites: %s", g_adminShowing[id] ? "ON" : "OFF");
    return 1;
}
