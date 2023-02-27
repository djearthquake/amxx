/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 * When clients connect with the duplicate name or non-utf8 it renames them.
 *
    *
    Credit: OciXCroM https://forums.alliedmods.net/showthread.php?t=336394. Helped with rename and array.
    Install instructions: Recommended quick start:
    Symbolic link BotNames.ini with existing 'alternative' bot names file.
    *
 *
*/

#include <amxmodx>
#include <amxmisc>

#define MAX_PLAYERS                32
#define MAX_NAME_LENGTH            32
#define MAX_AUTHID_LENGTH          64
#define MAX_CMD_LENGTH             128
#define MAX_USER_INFO_LENGTH       256

#define PLUGIN "!Client ReNaMeR"
#define VERSION "1.0"

new const SzBotFileName[]="/BotNames.ini"

new Array:g_aBotNames, g_iTotalNames;

new ClientAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH];
new ClientName[MAX_PLAYERS+1][MAX_NAME_LENGTH];
new XBots_only, XCyborgFilter, XUTF8_Strafe;

static const SzInitFakeName[] = "gamer"

public client_infochanged(id)
{
    if(is_user_connected(id))
    {
        if(!is_user_bot(id) && get_pcvar_num(XBots_only))
            return

        get_user_name(id,ClientName[id],charsmax(ClientName[]))

        new Szcheck[2]
        copy(Szcheck, charsmax(Szcheck), ClientName[id])

        if(containi(ClientName[id],"(1)") > -1 || equal(ClientName[id], "") || get_pcvar_num(XUTF8_Strafe) && get_char_bytes(Szcheck) != 1)
            @player_rename(id)
    }
}

@player_rename(id)
{
    if(g_iTotalNames)
    {
        if(is_user_connected(id))
        {
            if(is_user_bot(id) && get_pcvar_num(XCyborgFilter))
            {
                get_user_authid(id,ClientAuth[id],charsmax(ClientAuth[]))
                if(!equali(ClientAuth[id], "BOT"))
                    return
            }
            if(g_iTotalNames--)
            {
                new szName[MAX_NAME_LENGTH], i = random(g_iTotalNames)
                ArrayGetString(g_aBotNames, i, szName, charsmax(szName))
                ArrayDeleteItem(g_aBotNames, i)

                static const szNameField[] = "name"
                server_print "%s renamed to %s", ClientName[id], szName
                set_user_info(id, szNameField, szName)
            }
            else
            {
                server_print "Try growing your name list!"
                return
                ///@init_fake_file() //will make new name based on time
            }
        }

    }
    else
    {
        log_amx "Try growing your array list!"
        pause ("c")
    }
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "SPiNX")

    XCyborgFilter   = register_cvar("sv_rename_intregrity","0") //If humans complain when sv_rename_humans 1 seldomly fails.
    XBots_only      = register_cvar("sv_rename_humans","0") //This was made for bots but applied to humans also.
    XUTF8_Strafe    = register_cvar("sv_rename_utf","0") //Ever watched the flood from renaming non-utf8 CountryOnName? Not pretty.

    g_aBotNames = ArrayCreate(MAX_NAME_LENGTH)
    ReadFile()
}

public plugin_end()
    ArrayDestroy(g_aBotNames)

ReadFile()
{
    new szFilename[MAX_USER_INFO_LENGTH]
    get_configsdir(szFilename, charsmax(szFilename))
    add(szFilename, charsmax(szFilename), SzBotFileName)
    new iFilePointer = fopen(szFilename, "rt")
    new szData[MAX_NAME_LENGTH]

    if(!iFilePointer)
    {
        @init_fake_file()
        return
    }

    else if(iFilePointer)
    {
        while(!feof(iFilePointer))
        {
            fgets(iFilePointer, szData, charsmax(szData))
            trim(szData)

            switch(szData[0])
            {
                case EOS, '#', ';': continue
                default:
                {
                    g_iTotalNames++
                    ArrayPushString(g_aBotNames, szData)
                }

            }

        }
        fclose(iFilePointer)
    }

}

@init_fake_file()
{
    new rSzName[MAX_NAME_LENGTH]
    new mod_name[MAX_NAME_LENGTH]

    new SzBuffer[MAX_NAME_LENGTH]

    //make name off what is in script
    copy(SzBuffer, charsmax(SzBuffer), SzInitFakeName)
    @file_data(SzBuffer)

    //make name off what is in script 1st LTR upper
    copy(SzBuffer, charsmax(SzBuffer),SzInitFakeName)
    mb_ucfirst(SzBuffer, charsmax(SzBuffer))
    @file_data(SzBuffer)

    //add time in epoch to default alias
    formatex(rSzName, charsmax(rSzName), "%s:%i", SzInitFakeName, get_systime())
    copy(SzBuffer, charsmax(SzBuffer), rSzName)
    @file_data(SzBuffer)

    //add time in epoch to default alias Swapped
    formatex(rSzName, charsmax(rSzName), "%s:%i", SzInitFakeName, swapchars(get_systime()))
    copy(SzBuffer, charsmax(SzBuffer), rSzName)
    @file_data(SzBuffer)

    //make name off mod name
    get_modname(mod_name, charsmax(mod_name))
    copy(SzBuffer, charsmax(SzBuffer), mod_name)
    @file_data(SzBuffer)

    //make name off what is in script all upper
    mb_strtoupper(SzBuffer, charsmax(SzBuffer))
    @file_data(SzBuffer)

    //make name off mod name 1sr cap plus time
    mb_ucfirst(mod_name, charsmax(mod_name))
    formatex(SzBuffer, charsmax(SzBuffer), "%s:%i", mod_name, get_systime())
    //mb_strtolower(SzBuffer, charsmax(SzBuffer))
    @file_data(SzBuffer)

    //go back to reading
    ReadFile()
}

@file_data(SzBuffer[MAX_NAME_LENGTH])
{
    server_print "%s|trying save %s", PLUGIN, SzBuffer
    new szFilePath[ MAX_USER_INFO_LENGTH ]
    get_configsdir( szFilePath, charsmax( szFilePath ) )
    add( szFilePath, charsmax( szFilePath ), SzBotFileName )

    write_file(szFilePath, SzBuffer)
}
