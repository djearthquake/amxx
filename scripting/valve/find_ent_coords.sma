#include amxmodx
#include engine
#include engine_stocks

#define  charsmin -1
#define DEFAULT "weaponbox"
#define BAR "**********************************************************"

static world = 0;
new g_entity_coord
new Float:fOrigin[3]
new SzEntityClass[MAX_NAME_LENGTH];
new ent1, next_ent, third_ent, fourth_ent, fifth_ent

public plugin_init()
{
    register_plugin("ENT:CORD FINDER", "0.1", ".sρiηX҉.");
    register_clcmd("coord_ent" , "@ent_finder"    , 0, ": Print ent coordinates.");
    g_entity_coord  = register_cvar("entity_coord", DEFAULT)
}

@ent_finder(id)
{
    if(is_user_connected(id))
    {
        new ent
        get_pcvar_string(g_entity_coord, SzEntityClass, charsmax(SzEntityClass))

        ent_finder()

        if (ent1 > world)
        {
            ent = ent1
            @print_coords(id, ent)
            console_print(id, "Found a %s: numbered %i",SzEntityClass, ent1)

            if(next_ent > world)
            {
                ent = next_ent
                @print_coords(id, ent)
                console_print(id, "2nd %s: numbered %i",SzEntityClass, next_ent)
            }
            if(third_ent > world)
            {
                ent = third_ent
                @print_coords(id, ent)
                console_print(id, "3rd %s: numbered %i",SzEntityClass, third_ent)
            }
            if(fourth_ent > world)
            {
                ent = fourth_ent
                @print_coords(id, ent)
                console_print(id, "Fourth %s: numbered %i",SzEntityClass, fourth_ent)
            }
            if(fifth_ent > world)
            {
                ent = fifth_ent
                @print_coords(id, ent)
                console_print(id, "Fifth %s: numbered %i",SzEntityClass, fifth_ent)
                console_print(id, "There might be more %s.", SzEntityClass)
            }
        }
        else
        {
            console_print(id, "%s NOT FOUND!", SzEntityClass)
        }
        console_print(id, BAR)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

@print_coords(id, ent)
if(is_user_connected(id))
{
    get_brush_entity_origin(ent, fOrigin)
    console_print(id, "%f|%f|%f",fOrigin[0], fOrigin[1], fOrigin[2])

    @mark_target(id, fOrigin)
}

@mark_target(id, {Float,_}:...)
if(is_user_connected(id))
{
    new PfOrigin[3];

    get_user_origin(id, PfOrigin);
    emessage_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
    ewrite_byte(TE_LINE);
    ewrite_coord(PfOrigin[0]);
    ewrite_coord(PfOrigin[1]);
    ewrite_coord(PfOrigin[2]);
    ewrite_coord(floatround(fOrigin[0]));
    ewrite_coord(floatround(fOrigin[1]));
    ewrite_coord(floatround(fOrigin[2]));
    ewrite_short(random_num(75, 95)); //life
    ewrite_byte(100); //r
    ewrite_byte(random(255)); //g
    ewrite_byte(random(75));  //b
    emessage_end();
}

stock ent_finder()
{
    get_pcvar_string(g_entity_coord, SzEntityClass, charsmax(SzEntityClass))

    ent1            = find_ent_by_class(charsmin, SzEntityClass);

    if(ent1)
        next_ent    = find_ent_by_class(ent1, SzEntityClass);
    if(next_ent)
        third_ent   = find_ent_by_class(next_ent, SzEntityClass);
    if(third_ent)
        fourth_ent  = find_ent_by_class(third_ent, SzEntityClass);
    if(fourth_ent)
        fifth_ent   = find_ent_by_class(fourth_ent, SzEntityClass);

    if (ent1 > world)
        return ent1;

    if (next_ent > ent1)
        return next_ent;

    if (third_ent > next_ent > ent1)
        return third_ent;

    if (fourth_ent > third_ent > ent1)
        return fourth_ent;

    if (fifth_ent > fourth_ent > ent1)
        return fifth_ent;

    return PLUGIN_CONTINUE;
}
