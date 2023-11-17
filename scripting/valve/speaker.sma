#include amxmodx
#include engine
#include fakemeta
#include hamsandwich

new const SzSpeakerSnd[]="FAR_WAR"
new const SzTestMap[]="op4_yard"
//from sentences.txt

public plugin_init()
{
    make_speaker()
    register_plugin("Speaker PA", "1.0", ".sρiηX҉.")
    //register_touch("player", "item_healthkit", "@target_sound")
}

public make_speaker()
{///https://twhl.info/wiki/page/speaker1
/*
    new iEnt[6]

    new mname[MAX_NAME_LENGTH];get_mapname(mname,charsmax(mname));

    if(equali(mname, SzTestMap))
    {
        for(new list ; list < sizeof iEnt;++list)
        {
            server_print("Making speaker for %s", SzTestMap)
            iEnt[list] = create_entity("speaker")
            //DispatchKeyValue(iEnt, "targetname", "speakeasy")
            DispatchKeyValue(iEnt[list], "preset", "0")
            DispatchKeyValue(iEnt[list], "message", SzSpeakerSnd)
            DispatchKeyValue(iEnt[list], "health", "10")
            //DispatchKeyValue(iEnt, "spawnflags", "0")
            DispatchKeyValue(iEnt[0], "origin", "0 0 0")

            //op4_yard
            DispatchKeyValue(iEnt[1], "origin", "558.0 -292.6 -182.96")
            DispatchKeyValue(iEnt[2], "origin", "515.5 -84.5 -89.5")
            DispatchKeyValue(iEnt[3], "origin", "-14.8 -109.4 130.8")
            DispatchKeyValue(iEnt[4], "origin", "523.8 -743.4 65.1")
            DispatchKeyValue(iEnt[5], "origin", "325.5 -408.1 -230.0")

            if(pev_valid(iEnt[list]) == 2 && iEnt[list] > 33)
                DispatchSpawn(iEnt[list]);

            //DispatchSpawn(iEnt[list])
            server_print("Speaker ent is %i",iEnt[list])
            //DispatchSpawn(iEnt[list]) ? server_print("Speaker ent is %i",iEnt[list]) : DispatchSpawn(iEnt[list]);


        }

    }
    else
*/
    {
        server_print("Making speaker.")
        new iSpeaker= create_entity("speaker")
        //DispatchKeyValue(iSpeaker, "targetname", "speakeasy")
        DispatchKeyValue(iSpeaker, "preset", "0")
        DispatchKeyValue(iSpeaker, "message", SzSpeakerSnd)
        DispatchKeyValue(iSpeaker, "health", "10")
        DispatchKeyValue(iSpeaker, "origin", "0 0 0")
        //DispatchKeyValue(iSpeaker, "flags", "1")
        DispatchSpawn(iSpeaker);
        DispatchSpawn(iSpeaker) ? server_print("Speaker ent is %i",iSpeaker) : DispatchSpawn(iSpeaker);

    }

}

@target_sound(id, kit)
{
    new ent = find_ent(-1, "speaker")
    ExecuteHam(Ham_Use, ent, id, id, 1, 0.0)
    //ExecuteHam(Ham_Use, ent, id, 0, use_type, use_float)
}

/*
 ///NOTES
speaker - Point Entity
Creates a public announcement system that randomly plays announcements from the sentences.txt file.
Attributes

    Name (targetname) - Property used to identify entities.
    Preset (preset) - Preset sentence group.
        0 = Use Sentence Group Name
        1 = C1A0_
        2 = C1A1_
        3 = C1A2_
        4 = C1A3_
        5 = C1A4_
        6 = C2A1_
        7 = C2A2_
        8 = C2A3_
        9 = C2A4_
        10 = C2A5_
        11 = C3A1_
        12 = C3A2_
    Sentence Group Name (message) - The sentence group to randomly select sentences from.
    Volume(10=loudest) (health) - Sound Volume for the public announcement.

Flags

    Start Silent (1) - If enabled, the entity will have to be triggered to work.

Notes

    Place this in one or more spots in your level. Every 3 to 10 minutes it will make a random announcement, as if a public announcement system is in effect.
    Sentences are chosen from a sentence group by simply adding a number. For instance, if the Sentence Group Name is C1A0_, it will randomly choose the sentences from C1A0_0 to C1A0_N.
    Sentence Group Name should not have an ! as a prefix unless you only plan on playing one sentence (I.E. scripted announcements)
*/
