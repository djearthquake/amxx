#include amxmodx
#include fakemeta
#include fun
#include gearbox
#include hamsandwich

#define charsmin     -1

static const szEnt[]="weaponbox";

public plugin_init()
{
    register_plugin ( "weaponbox packer", "0.3", "spinx" )
    RegisterHam(Ham_Touch, szEnt, "@box_touch")
    RegisterHam(Ham_Spawn, "weaponbox", "Ham__WeaponBoxSpawn_Pre", 0)
}

public Ham__WeaponBoxSpawn_Pre(iWeaponBoxEntity)
{
    static box_info;
    new iOwner = pev(iWeaponBoxEntity, pev_owner)
    box_info = pev(iOwner, pev_weapons)
    set_pev(iWeaponBoxEntity, pev_iuser2, box_info)
    //pack owner name for later
}


@box_touch(ibox,id)
{
    static box;
    if(ibox)
    {
        box = ibox
    }
    else
    return 1
    ibox = 0

    static box_data, SzWeaponClassname[MAX_PLAYERS];

    if(pev_valid(box))
    {
        box_data = pev(box, pev_iuser2);
        if(!pev(box, pev_iuser1))
        if(box_data)
        {
            set_pev(ibox, pev_iuser1, 1)
            new iOwner = pev(box, pev_owner);
            if(is_user_alive(id) && id !=iOwner)
            {
                set_pev(box, pev_owner, id)
                client_print(id, print_console, is_user_connected(iOwner) ? "%n's weapons:":"Found new weaponbox:", iOwner)

                box = 0;set_pev(box, pev_iuser2, 0);
                for (new iArms = HLW_CROWBAR; iArms <= HLW_PENGUIN; iArms++)
                {
                    if(box_data & 1<<iArms)
                    {
                        if(get_weaponname(iArms, SzWeaponClassname, charsmax(SzWeaponClassname)))
                        {
                            if(!equal(SzWeaponClassname, "weapon_null"))
                            {
                                if(contain(SzWeaponClassname, "weapon_")!=charsmin)
                                {
                                    if(is_user_alive(id))
                                    {
                                        give_item(id, SzWeaponClassname)

                                        replace(SzWeaponClassname, charsmax(SzWeaponClassname), "weapon_", "")
                                        client_print id, print_console, SzWeaponClassname

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 0;
}
