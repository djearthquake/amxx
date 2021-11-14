/*Alter trigger_hurts*/
#tryinclude amxmodx
#tryinclude engine
//////////////////////////////////////////////////////////
new const Ent_of_interest[] = "trigger_hurt"
    //Trigger_hurt values
new const Value_to_alter1[] = "dmg"
new const Value_to_alter2[] = "damagetype"
//////////////////////////////////////////////////////////
const MAX_CMD_LENGTH    =   128

enum _:authors_details
{
    plugin[MAX_NAME_LENGTH],
    version[MAX_IP_LENGTH],
    author[MAX_NAME_LENGTH]
}

new plugin_registry[ authors_details ]
new Trie:g_tHurts
new ent_counter = 0

new g_heal, g_dam

new tbuffer[MAX_NAME_LENGTH]
new vbuffer[MAX_IP_LENGTH]

new new_value1[MAX_NAME_LENGTH]
new new_value2[MAX_NAME_LENGTH]
new iTranslation

public plugin_init()
{
    new hour,min,sec
    time(hour,min,sec)
    formatex(vbuffer,charsmax(vbuffer),"%i:%i:%i", hour, min, sec)
    plugin_registry[ plugin ] = "trigger_hurts"
    plugin_registry[ version ] = vbuffer
    plugin_registry[ author ] = ".sρiηX҉."
    set_task( 5.0, "@register", 777, plugin_registry, authors_details )
}

@register()
{
    register_plugin
    (
        .plugin_name = plugin_registry[ plugin ],
        .version =  plugin_registry[ version ],
        .author = plugin_registry[ author ]
    )

    if(ent_counter)
        log_amx "Altered %i trigger_hurt ents!", ent_counter

}

public pfn_keyvalue( ent )
{
    g_heal = register_cvar("trigger_heal", "1") //-1/0|1 Toggle trigger_hurt. -1 debug. 1 hurt. 0 heal.
    g_dam = register_cvar("trigger_type", "FREEZE") //Damage type. Typo defaults to generic.

    new iStarter1 = get_pcvar_num(g_heal) ?  -1 : 1

    formatex(new_value1,charsmax(new_value1),"%i",iStarter1)

    g_tHurts = TrieCreate( )

    TrieSetCell(g_tHurts,"GENERIC",0)
    TrieSetCell(g_tHurts,"CRUSH",1)
    TrieSetCell(g_tHurts,"BULLET",2)
    TrieSetCell(g_tHurts,"SLASH",4)
    TrieSetCell(g_tHurts,"BURN",8)
    TrieSetCell(g_tHurts,"FREEZE",16)
    TrieSetCell(g_tHurts,"FALL",32)
    TrieSetCell(g_tHurts,"BLAST",64)
    TrieSetCell(g_tHurts,"CLUB",128)
    TrieSetCell(g_tHurts,"SHOCK",256)
    TrieSetCell(g_tHurts,"SONIC",512)
    TrieSetCell(g_tHurts,"ENERGYBEAM",1024)
    TrieSetCell(g_tHurts,"DROWN",16384)
    TrieSetCell(g_tHurts,"PARALYSE",32768)
    TrieSetCell(g_tHurts,"NERVEGAS",65536)
    TrieSetCell(g_tHurts,"POISON",131072)
    TrieSetCell(g_tHurts,"RADIATION",262144)
    TrieSetCell(g_tHurts,"DROWNRECOVER",524288)
    TrieSetCell(g_tHurts,"CHEMICAL",1048576)
    TrieSetCell(g_tHurts,"SLOWBURN",2097152)
    TrieSetCell(g_tHurts,"SLOWFREEZE",4194304)

    get_pcvar_string(g_dam, tbuffer, charsmax(tbuffer))

    if( TrieKeyExists( g_tHurts, tbuffer ) )
    {
        new fix_possible_typo = TrieGetCell( g_tHurts, tbuffer, iTranslation ) ? iTranslation : 0
        formatex(new_value2,charsmax(new_value2),"%i",fix_possible_typo)

        new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
        copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )
        if(equali(Classname,Ent_of_interest))
        {
            if(equali(key,Value_to_alter1) && !equali(value,new_value1))
            {
                if(get_pcvar_num(g_heal) < 0)
                    log_amx "Attempting| %s altered to %s", Value_to_alter1, new_value1

                DispatchKeyValue(Value_to_alter1,new_value1)

                if(get_pcvar_num(g_heal) < 0)
                    log_amx"Success!|%s altered to %s", Value_to_alter1, new_value1

                ent_counter++
            }

            if(equali(key,Value_to_alter2) && !equali(value,new_value2))
            {
                if(get_pcvar_num(g_heal) < 0)
                    log_amx "Attempting|change %s to %s|%s", Value_to_alter2, tbuffer, new_value2

                DispatchKeyValue(Value_to_alter2, new_value2)

                if(get_pcvar_num(g_heal) < 0)
                    log_amx"Success!|%s altered to %s|%s", Value_to_alter2, tbuffer, new_value2
            }

        }

    }

}
