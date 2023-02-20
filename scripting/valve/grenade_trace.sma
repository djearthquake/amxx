#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <fun>
#define iRandomColor random(256)
new g_model,sprite;

public plugin_init()
{
    register_plugin("HL Grenade Trail","A1","SPiNX");
    register_think("grenade","CurentWeapon");
    register_think("ARgrenade","CurentWeapon");
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_handgrenade", "CurentWeapon", 0);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_9mmAR", "CurentWeapon", 0);
}

public plugin_precache()
{
    sprite = precache_model("sprites/smoke.spr");
}

public grenade_attack2(id)
{
    if(task_exists(g_model))
        remove_task(g_model);

    set_task_ex(0.2, "hull_glow", g_model, .flags = SetTask_Once);

}

public hull_glow(model)
{
    if(pev_valid(g_model))
    {
        switch(random_num(0,1))
        {
            case 0: set_ent_rendering(g_model, kRenderFxExplode, iRandomColor, iRandomColor, iRandomColor, kRenderGlow, power(g_model,10));
            case 1: set_ent_rendering(g_model, kRenderFxGlowShell, iRandomColor, iRandomColor, iRandomColor, kRenderNormal, random_num(8,100));
        }

    }
    return PLUGIN_CONTINUE;
}

public CurentWeapon(id)
{
    g_model = 0;
    g_model = find_ent_by_class(-1,"grenade");

    if(!g_model)
        g_model = find_ent_by_class(-1,"ARgrenade");

    if(g_model)

    if(pev_valid(g_model))
    {
        switch(random_num(0,1))
        {
            case 0: set_ent_rendering(g_model, kRenderFxExplode, iRandomColor, iRandomColor, iRandomColor, kRenderGlow, power(g_model,10));
            case 1: set_ent_rendering(g_model, kRenderFxGlowShell, iRandomColor, iRandomColor, iRandomColor, kRenderNormal, random_num(8,100));
        }
        Trail_me(g_model)
    }
}

public Trail_me(g_model)
{
    new lums = random_num(50,75);new time = random_num(10,21);new width = random_num(1,5);

    if(pev_valid(g_model))
    {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMFOLLOW);
        write_short(g_model);
        write_short(sprite);
        write_byte(time);
        write_byte(width);
        write_byte(iRandomColor);
        write_byte(iRandomColor);
        write_byte(iRandomColor);
        write_byte(lums);
        message_end();
    }
    else
    {
        remove_task(g_model);
    }
}
