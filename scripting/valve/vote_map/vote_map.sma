#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>

#define PLUGIN "Vote Map"
#define VERSION "1.3"
#define AUTHOR "Emp`SPiNX"
#define FORCE_CHANGE_TARGETNAME "changelevel"
#define FORCE_ROCKTHEVOTE "rockthevote"
#define RANDOM "@random"
#define EMPTY ""
#define SCALE 0.5
#define MAX_PLAYERS 32
#define charsmin                  -1
#define MAX_RESOURCE_PATH_LENGTH   64
#define MAX_CMD_LENGTH             128
#define MAX_USER_INFO_LENGTH       256

#if AMXX_VERSION_NUM != 182
#define strbreak argbreak
#endif

new bool:VoteMap = false
new bool:changed = false
new count = 0, loaded = 0, random_count = 0
new mapname[MAX_RESOURCE_PATH_LENGTH]
new configDir[MAX_CMD_LENGTH], fileDir[MAX_CMD_LENGTH], file[MAX_CMD_LENGTH], random_file[MAX_CMD_LENGTH]
new map_limit;

public plugin_init()
{
    register_plugin(PLUGIN,VERSION,AUTHOR)
    register_cvar("Vote_Map_Plugin",VERSION,FCVAR_SERVER|FCVAR_SPONLY)
    map_limit = register_cvar("vote_map_limit", "5")
    set_cvar_string("Vote_Map_Plugin",VERSION)
    register_forward(FM_Touch,"entity_touch", true)
    set_task(5.0,"check_map")
    changed = false
}
public plugin_precache()
{
    get_mapname(mapname,charsmax(mapname))
    get_configsdir(configDir,charsmax(configDir))
    format(fileDir,charsmax(fileDir),"%s/vote_map/",configDir)
    format(file,charsmax(file),"%s/vote_map/%s.cfg",configDir,mapname)
    format(random_file,charsmax(random_file),"%s/vote_map/random_maps.cfg",configDir)
    if(containi(mapname,"vote_")!=charsmin)
        VoteMap = true
    else
        VoteMap = false
    if(!dir_exists(fileDir))
    {
        mkdir(fileDir)
    }
    new line[MAX_USER_INFO_LENGTH]
    if(!file_exists(random_file) && cstrike_running())
    {
        format(line, charsmax(line), "// List maps here that you want to replace %s in the other map files",RANDOM)
        write_file(random_file, line,charsmin)
        write_file(random_file, "de_dust",charsmin)
        write_file(random_file, "de_dust2",charsmin)
        write_file(random_file, "cs_assault",charsmin)
        write_file(random_file, "cs_militia",charsmin)
        write_file(random_file, "de_aztec",charsmin)
    }
    else
    {
        log_amx "Pausing plugin due to missing config file."
        pause "c"
    }
    if(VoteMap)
    {
        set_task(1.0,"write_how_many")
        //lets find which ones we need to load
        new charnum, sprite_precache[MAX_USER_INFO_LENGTH], Left[51], Right[1501], bool:stop = false
        for(new i=0; i<=file_size(file, 1); i++)
        {
            read_file(file,i,line,charsmax(line),charnum)
            while(equali(line,"//",2) || equali(line,EMPTY))
            {
                stop = true
                break
            }
            if(stop)
            {
                stop = false
                continue
            }
            strbreak(line, Left, 50, Right, 1500)
            if(ValidMap(Left)>0)
            {
                format(sprite_precache,charsmax(sprite_precache),"sprites/vote_map/%s.spr",Left)
                precache_model(sprite_precache)
            }
        }
        for(new i=0; i<=file_size(random_file, 1); i++)
        {
            read_file(random_file,i,line,charsmax(line),charnum)
            while(equali(line,"//",2) || equali(line,EMPTY))
            {
                stop = true
                break
            }
            if(stop){
                stop = false
                continue
            }
            strbreak(line, Left, 50, Right, 1500)
            if(ValidMap(Left)>0)
            {
                format(sprite_precache,charsmax(sprite_precache),"sprites/vote_map/%s.spr",Left)
                precache_model(sprite_precache)
                precache_generic(sprite_precache)
            }
        }
    }
}
public write_how_many()
{
    new vote_ent = charsmin, how_many = 0, target[31], line[MAX_USER_INFO_LENGTH]
    while((vote_ent = fm_find_ent_by_tname(vote_ent, FORCE_CHANGE_TARGETNAME)))
    {
        pev(vote_ent, pev_target, target, get_pcvar_num(map_limit))
        if(!equali(target,"none"))
            continue
        how_many++
    }
    if(how_many==0)
        return
    if(!file_exists(file))
    {
        format(line, charsmax(line), "// List full map names here, or use %s for a random map from %s",RANDOM,random_file)
        write_file(file, line,charsmin)
        for(new i=0; i<how_many; i++)
            write_file(file, RANDOM,charsmin)
    }
}
public entity_touch(ent1, ent2)
{
    if(pev_valid(ent1) && pev_valid(ent2) && (is_user_alive(ent1) || is_user_alive(ent2)) && !changed)
    {
        new targetname[15]
        new mapchange=0, rockthevote=0
        pev(ent1, pev_targetname, targetname, charsmax(targetname))

        if(equal(targetname, FORCE_CHANGE_TARGETNAME) && ent2 < MAX_PLAYERS+1)
            mapchange = 1
        else
        {
            pev(ent2, pev_targetname, targetname, charsmax(targetname))
            if(equal(targetname, FORCE_CHANGE_TARGETNAME) && ent1 < MAX_PLAYERS+1)
                mapchange = 2
        }
        if(mapchange)
        {
            static ent
            static target[MAX_NAME_LENGTH]
            ent = (mapchange == 1) ? ent1 : ent2
            pev(ent, pev_target, target, charsmax(target))
            if(strlen(target))
            {
                //2025 SPiNX. If none game is frozen.
                if(equal(target, "none"))
                {
                    console_cmd 0, "reload"
                    goto END
                }
                set_cvar_string "amx_nextmap", target
                static exec[MAX_CMD_LENGTH]
                format(exec,charsmax(exec), "changelevel %s",target)
                static SzWon[MAX_CMD_LENGTH]
                formatex(SzWon,charsmax(SzWon),"%s won the vote!", target)
                if(VoteMap && !task_exists(2021))
                    set_task(2.0,"@Won",2021,exec,charsmax(exec))
                @finale(SzWon)

                changed = true
            }
            return FMRES_SUPERCEDE
        }
        pev(ent1, pev_targetname, targetname, charsmax(targetname))
        if(equal(targetname, FORCE_ROCKTHEVOTE) && ent2 < MAX_PLAYERS+1)
            rockthevote = 1
        else
        {
            pev(ent2, pev_targetname, targetname, charsmax(targetname))
            if(equal(targetname, FORCE_ROCKTHEVOTE) && ent1 < MAX_PLAYERS+1)
                rockthevote = 2
        }
        if(rockthevote)
        {
            client_print(0, print_chat, "Rocking The Vote...")
            if(VoteMap)
                console_cmd(0,"dmap_rockthevote")
            changed = true
            return FMRES_SUPERCEDE
        }

    }
    END:
    return FMRES_IGNORED
}
@Won(exec[MAX_CMD_LENGTH])
    console_cmd(0,exec)

@finale(SzWon[MAX_CMD_LENGTH],{Float,_}:...)
{
    emessage_begin(MSG_BROADCAST,SVC_FINALE,_,0);
    ewrite_string(SzWon);
    emessage_end()
}
public check_map()
{
    if(VoteMap)
    {
        //lets load some maps
        new line[MAX_USER_INFO_LENGTH]
        new vote_ent = charsmin, target[MAX_PLAYERS], Float:origin[3]
        new charnum, random_size = file_size(random_file, 1)
        new Left[51], Right[1501], sprite_ent, sprite[MAX_USER_INFO_LENGTH], bool:random_map
        while((vote_ent = fm_find_ent_by_tname(vote_ent, FORCE_CHANGE_TARGETNAME)) && count<file_size(file,1) && random_count<file_size(random_file,1))
        {
            pev(vote_ent, pev_target, target, get_pcvar_num(map_limit))
            if(!equali(target,"none"))
                continue
            random_map = false
            read_file(file,count,line,charsmax(line),charnum)
            while(equali(line,"//",2))
            {
                count++
                read_file(file,count,line,charsmax(line),charnum)
            }
            strbreak(line, Left, 50, Right, 1500)
            while(equali(Left,EMPTY) || equali(Left,RANDOM))
            {
                random_map = true
                read_file(random_file,random_num(0,random_size),line,charsmax(line),charnum)
                while(equali(line,"//",2))
                {
                    read_file(random_file,random_num(0,random_size),line,charsmax(line),charnum)
                }
                strbreak(line, Left, 50, Right, 1500)
            }
            //ok, we should have a valid map by now, but lets make sure the server has it
            switch(ValidMap(Left))
            {
                case 1,2:
                {
                    //lets make sure that its not on the map already
                    if(CheckDups(Left))
                    {
                        if(!random_map)
                            count++
                        vote_ent = charsmin
                    }
                    else
                    {
                        if(ValidMap(Left)==2)
                            set_pev(vote_ent, pev_targetname, FORCE_ROCKTHEVOTE)
                        else
                            set_pev(vote_ent, pev_target, Left)
                        sprite_ent = fm_create_entity("info_target")
                        fm_get_brush_entity_origin(vote_ent, origin)
                        fm_entity_set_origin(sprite_ent, origin)
                        format(sprite, charsmax(sprite), "sprites/vote_map/%s.spr",Left)
                        fm_entity_set_model(sprite_ent,sprite)
                        set_pev(sprite_ent, pev_scale, SCALE)
                        if(random_map)
                            random_count++
                        count++
                        loaded++
                    }
                }
                case charsmin:
                {
                    vote_ent = charsmin
                    log_amx("Invalid Map : %s : Sprite File not found",Left);
//                  break
                    pause("a");
                }
                default:
                {
                    vote_ent = charsmin
                    log_amx("Invalid Map : %s : Map File not found",Left)
//                  break
                    pause("a");
                }

            }

        }
        log_amx("Loaded %d Change Maps",loaded)
    }
    return PLUGIN_CONTINUE;
}
CheckDups(const MapName[])
{
    new vote_ent = charsmin, target[MAX_PLAYERS]
    if(equali(MapName,FORCE_ROCKTHEVOTE))
    {
        while((vote_ent = fm_find_ent_by_tname(vote_ent, FORCE_ROCKTHEVOTE)))
            return 1
    }
    else
    {
        while((vote_ent = fm_find_ent_by_tname(vote_ent, FORCE_CHANGE_TARGETNAME)))
        {
            pev(vote_ent, pev_target, target, get_pcvar_num(map_limit))
            if(equali(target,MapName))
                return 1
        }

    }
    return 0
}

ValidMap(const MapName[])
{
    if(equali(MapName,FORCE_ROCKTHEVOTE))
        return 2
    static sprite_file[MAX_CMD_LENGTH]
    format(sprite_file,charsmax(sprite_file),"sprites/vote_map/%s.spr",MapName)

    if(is_map_valid(MapName))
    {
        if(file_exists(sprite_file))
            return 1
        else
            return charsmin
    }
    return 0
}
