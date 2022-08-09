#include amxmodx
#include engine
#include fakemeta

#define MAX_CMD_LENGTH  128
new const Ent_of_interest[] = "ambient_generic"
new const battery[]  = "models/w_battery.mdl"
new const SzAmbientFilePath[] = "ambience/sheep.wav"
new const SzAmbientFilePath1[] = "ambience/guit1.wav"

//sentences.txt
new const SzSpeakerSnd1[]="HG_TAUNT"
new const SzSpeakerSnd2[]="SC_ANSWER"
new const SzSpeakerSnd3[]="SC_SCREAM"
new bool: bAdjustedAmbient

@_t_music()
{
    if(bAdjustedAmbient)
    {
        server_print("Remaking ambient radio.")
        new iTerrorist_music
        iTerrorist_music = create_entity("ambient_generic")
        DispatchKeyValue(iTerrorist_music, "origin", "-840 -1820 75") //radio
        DispatchKeyValue(iTerrorist_music, "targetname", "radio")
        DispatchKeyValue(iTerrorist_music, "pitchstart", "100")
        DispatchKeyValue(iTerrorist_music, "pitch", "100")
        DispatchKeyValue(iTerrorist_music, "health", "10.0")
        DispatchKeyValue(iTerrorist_music, "message", SzAmbientFilePath1)
    
        DispatchKeyValue(iTerrorist_music, "spawnflags", "8")
        DispatchSpawn(iTerrorist_music)
    }
}
@speaker()
{
    //talk about it
    server_print("Making speakers.")

    //ent
    new iSpeaker= create_entity("speaker")

    //pararmeters
    DispatchKeyValue(iSpeaker, "preset", "0")
    DispatchKeyValue(iSpeaker, "message", SzSpeakerSnd1)
    DispatchKeyValue(iSpeaker, "health", "10")
    DispatchKeyValue(iSpeaker, "origin", "-1972 -1564 -18"/*cam1*/)
    //DispatchKeyValue(iSpeaker, "targetname", "speakeasy") //whatever 'unique' name works
    //DispatchKeyValue(iSpeaker, "spawnflags", "0") //1 is trigger
    //make
    DispatchSpawn(iSpeaker);
    //see if it is out there and if not remake. If so tell the number.
    DispatchSpawn(iSpeaker) ? server_print("Speaker ent is %i", iSpeaker) : DispatchSpawn(iSpeaker);

    new iSpeaker2= create_entity("speaker")

    //pararmeters
    DispatchKeyValue(iSpeaker2, "preset", "0")
    DispatchKeyValue(iSpeaker2, "message", SzSpeakerSnd2)
    DispatchKeyValue(iSpeaker2, "health", "10")
    DispatchKeyValue(iSpeaker2, "origin", "-1210 -1578 8"/*cam2*/)

    //make
    DispatchSpawn(iSpeaker2);
    //see if it is out there and if not remake. If so tell the number.
    DispatchSpawn(iSpeaker2) ? server_print("Speaker ent is %i", iSpeaker2) : DispatchSpawn(iSpeaker2);

    new iSpeaker3= create_entity("speaker")

    //pararmeters
    DispatchKeyValue(iSpeaker3, "preset", "0")
    DispatchKeyValue(iSpeaker3, "message", SzSpeakerSnd3)
    DispatchKeyValue(iSpeaker3, "health", "10")
    DispatchKeyValue(iSpeaker3, "origin", "-1902 -1852 104"/*cam_room*/)

    //make
    DispatchSpawn(iSpeaker3);
    //see if it is out there and if not remake. If so tell the number.
    DispatchSpawn(iSpeaker3) ? server_print("Speaker ent is %i", iSpeaker3) : DispatchSpawn(iSpeaker3);
}

public plugin_precache()
{
    new mapname[MAX_RESOURCE_PATH_LENGTH]
    get_mapname(mapname,charsmax(mapname))

    if(!equali(mapname,"cs_arabstreets"))
        pause "a"

    precache_sound(SzAmbientFilePath)
    precache_model(battery);

    @_t_music
}

public plugin_init()
{
    new iRadio = find_ent_by_target(-1,"radio")
    if(iRadio)
    {
        DispatchKeyValue(iRadio, "explodemagnitude", "100") //make it hurt
        DispatchKeyValue(iRadio, "spawnobject", "1") //make armor
        DispatchKeyValue(iRadio, "gibmodel", battery)

        DispatchKeyValue(iRadio, "targetname", "radio_breakable")
        DispatchKeyValue(iRadio, "target", "radio")
        DispatchSpawn(iRadio); //make gib work
        server_print "Rigged the radio!"

        new iDoor_Opener = find_ent_by_target(-1,"door1")
        if(iDoor_Opener)
        {
            set_pev(iDoor_Opener, pev_targetname, "door_opener") //make a multisource to close the door opening? should be easier
            //set_pev(iDoor_Opener, pev_classname, "button_target") //shoot open
            set_pev(iDoor_Opener, pev_spawnflags, "352") //320 locked
            set_pev(iDoor_Opener, pev_health, "1")
            DispatchKeyValue(iDoor_Opener, "sounds", "1")
            DispatchSpawn(iDoor_Opener)
        }
        new iDoor_Opener_outside = find_ent_by_target(iDoor_Opener,"door1")
        if(iDoor_Opener_outside)
        {
            set_pev(iDoor_Opener_outside, pev_spawnflags, "320")
            //set_pev(iDoor_Opener_outside, pev_health, "300")
            DispatchKeyValue(iDoor_Opener_outside, "health", "1000")
            DispatchKeyValue(iDoor_Opener_outside, "sounds", "10")
            DispatchSpawn(iDoor_Opener_outside)
        }


        new iGarage_Door
        iGarage_Door = find_ent_by_tname(-1,"door1")
        if(iGarage_Door)
        {
            DispatchKeyValue(iGarage_Door, "angles", "-180 0 0")
            DispatchKeyValue(iGarage_Door, "targetname", "door1")
            DispatchKeyValue(iGarage_Door, "spawnflags", "32") //start closed
            DispatchKeyValue(iGarage_Door, "unlocked_sentence", "8") //start closed
            //DispatchKeyValue(iGarage_Door, "health", "1")
            DispatchKeyValue(iGarage_Door, "rendercolor", "150 51 200")
            server_print "Adjusting the door's killtarget"
        }

        register_event("SendAudio", "@clear_armor", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
    }

}

@clear_armor()
{
    new iEnt;
    while ((iEnt = find_ent_by_class(-1, "item_battery")) > 0)
        remove_entity(iEnt)
}

public pfn_keyvalue( ent )
{
    new Classname[  MAX_NAME_LENGTH ], key[ MAX_NAME_LENGTH ], value[ MAX_CMD_LENGTH ]
    copy_keyvalue( Classname, charsmax(Classname), key, charsmax(key), value, charsmax(value) )

    if(equali(Classname,Ent_of_interest) && equali(key,"targetname") && equali(value,"radio" ))
    {
        DispatchKeyValue("targetname", "radio")

        DispatchKeyValue("pitchstart", "20")
        DispatchKeyValue("pitch", "65")
        DispatchKeyValue("health", "1")
        DispatchKeyValue("preset", "21")

        server_print "Adjusted radio sound parameters."
    }

    if(equali(Classname,Ent_of_interest) && equali(key,"message") && equali(value,"ambience/arabmusic.wav"))
    {
        bAdjustedAmbient = true
        register_plugin("Arabsteets Radio 2", "1.1", ".sρiηX҉.")

        ///DispatchKeyValue("message", "") //voids what is now sheep sound
        DispatchKeyValue("message", SzAmbientFilePath) 

        @speaker() //replace
        server_print "Adjusted radio output sound."
    }

    if(equali(Classname,"func_door") && equali(key,"spawnflags") && equali(value,"33" ))
    {
         DispatchKeyValue("spawnflags", "33")
         DispatchKeyValue("unlocked_sentence", "8")
         DispatchKeyValue("locked_sentence", "2")
         DispatchKeyValue("health", "200")

    }
    if(equali(Classname,"func_breakable") && equali(key,"health") && equali(value,"1" ))
    {
        //churchy glass window
        //DispatchKeyValue("health", "2022")
        //DispatchKeyValue("spawnobject", "1") //make armor
        DispatchKeyValue("spawnflags", "1") //unbreakable
        //DispatchKeyValue("targetname", "hostage_window")
        //DispatchKeyValue("explodemagnitude", "500")
        //DispatchKeyValue("gibmodel", battery)
    }

}
