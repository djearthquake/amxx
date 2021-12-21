#include amxmodx
#include amxmisc
#include engine
#include engine_stocks
#include fakemeta_util
#include fakemeta

#define MAX_NAME_LENGTH 32

public client_putinserver(id)
if(is_user_connected(id) && is_user_admin(id))
    set_task(0.1,"@check_texture",id,.flags="b")

public client_disconnected(id)
    remove_task(id)

@check_texture(id)
{
    if(is_user_alive(id) && is_user_admin(id))
    {
        static iEntity,iBodypart
        new Float:vOrigin[ 3 ], Float:vEndPos[ 3 ];
        new szTexture[ MAX_NAME_LENGTH ];

        pev( id, pev_origin, vOrigin )
        fm_get_aim_origin(id, vEndPos)
        get_user_aiming(id,iEntity,iBodypart)
        engfunc( EngFunc_TraceTexture, iEntity, vOrigin, vEndPos, szTexture, charsmax( szTexture ) );

        if(!iBodypart & !equali(szTexture,"NoTexture"))
        {
            iEntity ? client_print( id, print_center, "%i %s", iEntity, szTexture) : client_print( id, print_center, "%s",szTexture)

            new iType = dllfunc(DLLFunc_PM_FindTextureType, szTexture);
            client_print id, print_console, "%s", iType
            new txt[MAX_NAME_LENGTH]
            switch (iType)
            {
                //case 'C': copy(txt, charsmax(txt), "concrete");
                case 'D': copy(txt, charsmax(txt), "dirt");
                case 'G': copy(txt, charsmax(txt), "grate");
                case 'M': copy(txt, charsmax(txt), "metal");
                case 'N': copy(txt, charsmax(txt), "snow");
                case 'P': copy(txt, charsmax(txt), "computer");
                case 'S': copy(txt, charsmax(txt), "slosh");
                case 'T': copy(txt, charsmax(txt), "tile");
                case 'V': copy(txt, charsmax(txt), "ventilation");
                case 'W': copy(txt, charsmax(txt), "wood");
                case 'Y': copy(txt, charsmax(txt), "glass");
            }
            client_print id, print_chat, txt
        }

    }

}
