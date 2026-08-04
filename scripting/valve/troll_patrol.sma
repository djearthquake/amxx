#include amxmodx
#include amxmisc

#define charsmin -1
#define WORD_FILE "troll_words.ini"

new Array:g_aTrollWords;

public plugin_init()
{
    register_plugin("Troll Patrol", "0.1", "SPiNX");

    register_clcmd("say", "HandleChat");
    register_clcmd("say_team", "HandleChat");

    g_aTrollWords = ArrayCreate(64);
    LoadTrollWords();
}

public plugin_end()
{
    if (g_aTrollWords != Invalid_Array)
    {
        ArrayDestroy(g_aTrollWords);
    }
}

public HandleChat(lamer)
{
    if(is_user_connected(lamer))
    {
        static szArg[MAX_USER_INFO_LENGTH];
        read_argv(1, szArg, charsmax(szArg));
        trim(szArg);

        if (szArg[0] == EOS)
        {
            return PLUGIN_CONTINUE;
        }

        new iSize = ArraySize(g_aTrollWords);
        new szWord[64];

        for(new s; s < iSize; ++s)
        {
            ArrayGetString(g_aTrollWords, s, szWord, charsmax(szWord));

            if (containi(szArg, szWord) != charsmin)
            {
                console_print(lamer, "%s disallowed on server.", szArg);
                return PLUGIN_HANDLED;
            }
        }
    }

    return PLUGIN_CONTINUE;
}

LoadTrollWords()
{
    static szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    formatex(szFilePath, charsmax(szFilePath), "%s/%s", szFilePath, WORD_FILE);

    new iFile = fopen(szFilePath, "rt");
    if (iFile)
    {
        new szBuffer[512];
        while (!feof(iFile))
        {
            fgets(iFile, szBuffer, charsmax(szBuffer));
            trim(szBuffer);

            if (szBuffer[0] == ';' || szBuffer[0] == EOS)
            {
                continue;
            }

            static szChunk[64];
            new iChunkPos = 0;

            for (new i = 0; szBuffer[i] != EOS; i++)
            {
                if (szBuffer[i] == ',')
                {
                    szChunk[iChunkPos] = EOS;
                    trim(szChunk);
                    remove_quotes(szChunk);

                    if (szChunk[0] != EOS)
                    {
                        ArrayPushString(g_aTrollWords, szChunk);
                    }

                    iChunkPos = 0;
                    szChunk[0] = EOS;
                }
                else
                {
                    if (iChunkPos < charsmax(szChunk))
                    {
                        szChunk[iChunkPos++] = szBuffer[i];
                    }
                }
            }

            szChunk[iChunkPos] = EOS;
            trim(szChunk);
            remove_quotes(szChunk);

            if (szChunk[0] != EOS)
            {
                ArrayPushString(g_aTrollWords, szChunk);
            }
        }
        fclose(iFile);
    }
}
