#include amxmodx
#include engine
#include fakemeta

//clock-wise yaw  tail-spin fish-tailing
public ChangeAngle(ent)
{
    set_pev(ent, pev_owner, 0);

    new Float:LEFT = 270.0
    new Float:Origin[3]
    new Float:Axis[3]

    if(pev_valid(ent))

    {
        entity_get_vector(ent,EV_VEC_angles,Axis);


        new Float:X = Axis[0]
        new Float:Y = Axis[1]
        new Float:Z = Axis[2]

        if( Y == LEFT )
        {
            Y = Axis[1]-180.0
            set_pev( ent, pev_angles, Y)
            client_print(0, print_console, "Dead on!");
            return
        }


        if( Y != LEFT )
        {
            Y = Axis[1]+90.0
            set_pev( ent, pev_angles, Y)
            client_print(0, print_console, "Flipping...");
        }
        else
        set_pev( ent, pev_angles, Axis[1]+90.0)
    }

}
