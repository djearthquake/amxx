#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <fun>
#define COLOR random_num(0,255)
new g_model,sprite;

public plugin_init(){
register_plugin("HL Grenade Trail","A","SPiNX");
register_think("grenade","CurentWeapon");
RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_handgrenade", "CurentWeapon", 1);
RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_handgrenade", "grenade_attack2", 1);
}

public plugin_precache(){
sprite = precache_model("sprites/smoke.spr");
g_model = find_ent_by_class(-1,"grenade");
}

public grenade_attack2(id)
{
    if(task_exists(g_model))
        remove_task(g_model);
    
    set_task_ex(0.2, "hull_glow", g_model, .flags = SetTask_Once);

}

public hull_glow(model){
    if(pev_valid(g_model)){
    switch(random_num(0,1)){
    case 0: set_ent_rendering(g_model, kRenderFxExplode, COLOR, COLOR, COLOR, kRenderGlow, power(g_model,1000));
    case 1: set_ent_rendering(g_model, kRenderFxGlowShell, COLOR, COLOR, COLOR, kRenderNormal, random_num(80,200));}
    }
    return PLUGIN_CONTINUE;
}
public CurentWeapon(id){
    g_model = find_ent_by_class(-1,"grenade");
    if(pev_valid(g_model))
    {
    switch(random_num(0,1))
        {
        case 0: set_ent_rendering(g_model, kRenderFxExplode, COLOR, COLOR, COLOR, kRenderGlow, power(g_model,1000));
        case 1: set_ent_rendering(g_model, kRenderFxGlowShell, COLOR, COLOR, COLOR, kRenderNormal, random_num(80,200));
        }
    set_task_ex(0.2, "Trail_me", g_model, .flags = SetTask_Repeat);}
}
public Trail_me(g_model){
    new lums = random_num(10,100);new time = random_num(10,21);new width = random_num(1,5);
/// if(pev_valid(g_model))set_ent_rendering(g_model, kRenderFxGlowShell, COLOR, COLOR, COLOR, kRenderNormal, 80)
    message_begin(MSG_ALL,23);write_byte(TE_BEAMFOLLOW);
    write_short(g_model);write_short(sprite);
    write_byte(time);write_byte(width);
    write_byte(COLOR);write_byte(COLOR);write_byte(COLOR);
    write_byte(lums);message_end();
    if(!is_valid_ent(g_model))remove_task(g_model);
}

