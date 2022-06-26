/*
*
*   SSSSSSSSSSSSSSS PPPPPPPPPPPPPPPPP     iiii  NNNNNNNN        NNNNNNNNXXXXXXX       XXXXXXX
* SS:::::::::::::::SP::::::::::::::::P   i::::i N:::::::N       N::::::NX:::::X       X:::::X
*S:::::SSSSSS::::::SP::::::PPPPPP:::::P   iiii  N::::::::N      N::::::NX:::::X       X:::::X
*S:::::S     SSSSSSSPP:::::P     P:::::P        N:::::::::N     N::::::NX::::::X     X::::::X
*S:::::S              P::::P     P:::::Piiiiiii N::::::::::N    N::::::NXXX:::::X   X:::::XXX
*S:::::S              P::::P     P:::::Pi:::::i N:::::::::::N   N::::::N   X:::::X X:::::X
* S::::SSSS           P::::PPPPPP:::::P  i::::i N:::::::N::::N  N::::::N    X:::::X:::::X
*  SS::::::SSSSS      P:::::::::::::PP   i::::i N::::::N N::::N N::::::N     X:::::::::X
*    SSS::::::::SS    P::::PPPPPPPPP     i::::i N::::::N  N::::N:::::::N     X:::::::::X
*       SSSSSS::::S   P::::P             i::::i N::::::N   N:::::::::::N    X:::::X:::::X
*            S:::::S  P::::P             i::::i N::::::N    N::::::::::N   X:::::X X:::::X
*            S:::::S  P::::P             i::::i N::::::N     N:::::::::NXXX:::::X   X:::::XXX
*SSSSSSS     S:::::SPP::::::PP          i::::::iN::::::N      N::::::::NX::::::X     X::::::X
*S::::::SSSSSS:::::SP::::::::P          i::::::iN::::::N       N:::::::NX:::::X       X:::::X
*S:::::::::::::::SS P::::::::P          i::::::iN::::::N        N::::::NX:::::X       X:::::X
* SSSSSSSSSSSSSSS   PPPPPPPPPP          iiiiiiiiNNNNNNNN         NNNNNNNXXXXXXX       XXXXXXX
*
*──────────────────────────────▄▄
*──────────────────────▄▄▄▄▄▄▄▄▌▐▄
*─────────────────────█▄▄▄▄▄▄▄▄▌▐▄█
*────────────────────█▄▄▄▄▄▄▄█▌▌▐█▄█
*──────▄█▀▄─────────█▄▄▄▄▄▄▄▌░▀░░▀░▌
*────▄██▀▀▀▀▄──────▐▄▄▄▄▄▄▄▐ ▌█▐░▌█▐▌
*──▄███▀▀▀▀▀▀▀▄────▐▄▄▄▄▄▄▄▌░░░▄▄▌░▐
*▄████▀▀▀▀▀▀▀▀▀▀▄──▐▄▄▄▄▄▄▄▌░░▄▄▄▄░▐
*████▀▀▀▀▀▀▀▀▀▀▀▀▀▄▐▄▄▄▄▄▄▌░▄░░▀▀░░▌
*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▌░▐▀▄▄▄▄▀
*▒▒▒▒▄▄▀▀▀▀▀▀▀▀▄▄▄▄▀▀█▄▄▄▄▄▌░░░░░▌
*▒▄▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌
*▒▌░░░░░▀▄░░░░░░░░░░░░░░░▀▄▄▄▄▄▄░▀▄▄▄▄▄
*▒▌░░░░░░░▀▄░░░░░░░░░░░░░░░░░░░░▀▀▀▀▄░▀▀▀▄
*▒▌░░░░░░░▄▀▀▄░░░░░░░░░░░░░░░▀▄░▄░▄░▄▌░▄░▄▌
*▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
*
*
*
*
*
* __..__  .  .\  /
*(__ [__)*|\ | ><
*.__)|   || \|/  \
*
*    Aliased Admin Help Plugin. Aliases of Amx_SearchCommand.
*    Copyleft (C) 2020 .sρiηX҉.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*    Credits: AMXX DEV TEAM for everything including adminhelp.sma.
*    AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
*/
#include <amxmodx>
#define MAX_PLAYERS 32
const MaxMapLength         = 32;
const MaxDefaultEntries    = 10;
const MaxCommandLength     = 32;
const MaxCommandInfoLength = 128;
const DefaultMsgTime       = 15;

/*Dynamic aliases*/
new alias;
#define ALIAS1 "find"
#define ALIAS2 "amx_get"
#define ALIAS3 "amx_searchcommand"
#define ALIAS4 "amx_search"
#if !defined read_argv_int
#define read_argv_int read_argv
#endif

new CvarDisplayClientMessage;
new CvarDisplayMessageTime;
new CvarHelpAmount;
new const SearchCommand[][] = {".","!","?",ALIAS1,ALIAS2,ALIAS3,ALIAS4}
//Arkshine's Amx_SearchCommand forked & backwards ported with aliasing on Sept 20 2021 AM.

new const DIC[] = "admin_alias.txt"

new info[MaxCommandInfoLength];

new CvarNextmap[MaxMapLength];
new CvarTimeLimit

new bool:DisplayClientMessage[MAX_PLAYERS + 1 char];

public plugin_init()
{
    register_plugin("Admin Help Alias", "1.0", ".sρiηX҉.Arkshine");

    register_dictionary(DIC) ? register_dictionary(DIC) : log_amx("Paused to prevent crash from missing %s.", DIC)&pause("a")

    for (new alias; alias < sizeof SearchCommand;++alias)
    {
        #if AMXX_VERSION_NUM == 182
            register_concmd(SearchCommand[alias], "@ConsoleCommand_Search", ADMIN_ALL, lang_offset())
        #else
            register_concmd(SearchCommand[alias], "@ConsoleCommand_Search", ADMIN_ALL, "SEARCH_CMD_INFO", .info_ml = true);
        #endif
    }
    #if AMXX_VERSION_NUM == 182
    {
        CvarDisplayClientMessage = register_cvar("amx_help_display_msg"     , "1")
        CvarDisplayMessageTime   = register_cvar("amx_help_display_msg_time", "15")
        CvarHelpAmount           = register_cvar("amx_help_amount_per_page" , "10")
    }
    #else
    {
        bind_pcvar_num(create_cvar("amx_help_display_msg"     , "1" , .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0), CvarDisplayClientMessage);
        bind_pcvar_num(create_cvar("amx_help_display_msg_time", "15", .has_min = true, .min_val = 0.0), CvarDisplayMessageTime);
        bind_pcvar_num(create_cvar("amx_help_amount_per_page" , "10", .has_min = true, .min_val = 0.0), CvarHelpAmount);
    }
    #endif

    new const pointer = get_cvar_pointer("amx_nextmap");

    if (pointer)
        get_cvar_string("amx_nextmap", CvarNextmap , charsmax(CvarNextmap))

    CvarTimeLimit = get_cvar_pointer("mp_timelimit")
}

public client_putinserver(id)
{
    if (CvarDisplayClientMessage > 0 && !is_user_bot(id))
    {
        DisplayClientMessage{id} = true;

        new messageTime = get_pcvar_num(CvarDisplayMessageTime) <= 0 ? DefaultMsgTime : get_pcvar_num(CvarDisplayMessageTime);
        set_task(float(messageTime), "@Task_DisplayMessage", id);
    }
}

public client_disconnected(id)
if(!is_user_connecting(id))
{
    if (DisplayClientMessage{id})
    {
        DisplayClientMessage{id} = false;
        remove_task(id);
    }
}

@Task_DisplayMessage(id)
if(is_user_connected(id))
{
    for (new alias; alias < sizeof SearchCommand;++alias)
        client_print(id, print_chat, "%L", LANG_PLAYER, "TYPE_HELP_2" , SearchCommand[alias]);

    if (get_pcvar_num(CvarTimeLimit) > 0)
    {
        new timeleft = get_timeleft();

        if (timeleft > 0)
            client_print(id, print_chat, "%L", LANG_PLAYER, "TIME_INFO_1", timeleft / 60, timeleft % 60, CvarNextmap);

        else if (CvarNextmap[0] != EOS)
            client_print(id, print_chat, "%L", LANG_PLAYER, "TIME_INFO_2", CvarNextmap);

    }

}

@ConsoleCommand_Search(id, level, cid)
{
    if(is_user_connected(id))
    {
        new entry[MaxCommandLength], start_here[4];
        read_argv(1, entry, charsmax(entry));

        read_argv(2, start_here, charsmax(start_here));
        new list_index = str_to_num(start_here)
        if(list_index < 1)
            list_index = 2;
        return ProcessHelp(id, .start_argindex = list_index, .do_search = true, .main_command = SearchCommand[alias], .search = entry);
    }
    return PLUGIN_CONTINUE
}
ProcessHelp(id, start_argindex, bool:do_search, const main_command[], const search[] = "")
{
    if(is_user_connected(id))
    {
        new user_flags = get_user_flags(id);

        // HACK: ADMIN_ADMIN is never set as a user's actual flags, so those types of commands never show
        if (user_flags > 0 && !(user_flags & ADMIN_USER))
        {
            user_flags |= ADMIN_ADMIN;
        }

        new clcmdsnum = get_concmdsnum(user_flags, id);

        if (get_pcvar_num(CvarHelpAmount) <= 0)
        {
            set_pcvar_num(CvarHelpAmount, MaxDefaultEntries)
        }
        #if AMXX_VERSION_NUM == 182
        new szArg[MaxCommandLength];
        new szArgCmd[4],szArgCmd1[4]
        read_args(szArg, charsmax(szArg));
        read_argv(start_argindex,szArgCmd, charsmax(szArgCmd))
        new start  = clamp(start_argindex, .min = 1, .max = clcmdsnum) - 1
        #else
        new start  = clamp(read_argv_int(start_argindex), .min = 1, .max = clcmdsnum) - 1; // Zero-based list;
        #endif


        #if AMXX_VERSION_NUM == 182
        read_argv(start_argindex+1,szArgCmd1, charsmax(szArgCmd1))
        new amount = !id ? start_argindex : get_pcvar_num(CvarHelpAmount);
        #else
        new amount = !id ? read_argv_int(start_argindex) : CvarHelpAmount
        #endif

        new end    = min(start + (amount > 0 ? amount : CvarHelpAmount), clcmdsnum);
        #if AMXX_VERSION_NUM == 182
        console_print(id, "^n----- %L -----", LANG_PLAYER, "HELP_COMS");
        #else
        console_print(id, "^n----- %l -----", LANG_PLAYER, "HELP_COMS");
        #endif
        new command[MaxCommandLength];
        new command_flags;
        new bool:is_info_ml;
        new entries_found;
        new total_entries;
        new index;

        if (do_search)
        {
            for (index = 0; index < clcmdsnum; ++index)
            {
                #if AMXX_VERSION_NUM == 182
                get_concmd(index, command, charsmax(command), command_flags, info, charsmax(info), user_flags, id);
                #else
                get_concmd(index, command, charsmax(command), command_flags, info, charsmax(info), user_flags, id, is_info_ml);
                #endif

                if (containi(command, search) != -1 && ++entries_found > start && (total_entries = entries_found) <= end)
                {
                    LookupLangKey(info, charsmax(info), info, id);
                    console_print(id, "%3d: %s %s", entries_found, command, info);
                }
            }

            if (!entries_found || entries_found > total_entries)
            {
                #if AMXX_VERSION_NUM == 182
                console_print(id, "%l", LANG_PLAYER, "NO_MATCHING_RESULTS");
                #else
                console_print(id, "%l", LANG_PLAYER, "NO_MATCHING_RESULTS");
                #endif
                return PLUGIN_HANDLED;
            }

            index = entries_found;
            clcmdsnum = total_entries;
            end = min(end, clcmdsnum);
        }
        else
        {
            for (index = start; index < end; ++index)
            {
                #if AMXX_VERSION_NUM == 182
                get_concmd(index, command, charsmax(command), command_flags, info, charsmax(info), user_flags, id);
                #else
                get_concmd(index, command, charsmax(command), command_flags, info, charsmax(info), user_flags, id, is_info_ml);
                #endif

                LookupLangKey(info, charsmax(info), info, id);

                console_print(id, "%3d: %s %s", index + 1, command, info);
            }
        }
        #if AMXX_VERSION_NUM == 182
        client_print id, print_console, "----- %L -----", LANG_PLAYER, "HELP_ENTRIES", start + 1, end, clcmdsnum
        #else
        console_print(id, "----- %l -----", "HELP_ENTRIES", start + 1, end, clcmdsnum);
        #endif


        formatex(command, charsmax(command), "%s%c%s", main_command, do_search ? " " : "", search);

        if (end < clcmdsnum)
        {
            #if AMXX_VERSION_NUM == 182
            client_print id, print_console, "----- %L -----", LANG_PLAYER, "HELP_USE_MORE", command, end + 1
            #else
            console_print(id, "----- %l -----", "HELP_USE_MORE", command, end + 1);
            #endif

        }
        else if (start || index != clcmdsnum)
        {
            #if AMXX_VERSION_NUM == 182
            client_print id, print_console, "----- %L -----", LANG_PLAYER, "HELP_USE_BEGIN", command
            #else
            console_print(id, "----- %l -----", "HELP_USE_MORE", command, end + 1);
            #endif

        }

    }
    return PLUGIN_HANDLED
}

stock lang_offset()
{
    //amxx182 support
    #define LANG_SERVER     0
    new buffer[MaxCommandInfoLength], id;
    register_dictionary(DIC)
    LookupLangKey(buffer, charsmax(buffer), "SEARCH_CMD_INFO", id);
    return buffer
}

