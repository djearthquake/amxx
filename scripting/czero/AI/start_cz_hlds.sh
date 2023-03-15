#!/bin/bash
#Global server parameters
ATTN="ATTENTION SERVER OWNER"
ACCT="anonymous"
BOOST="-pingboost 3"
CFG="+mapchangecfgfile server.cfg"
CPU_LIM="35" ##percent##
EDI="-num_edicts 1540"
UPD="Updating...sparing you the details."

MAX_PLAYERS="24"
#ENTER NAME OF MOD HERE
MOD="czero"

#localhost
SERVER_IP=`hostname  -I | cut -f1 -d' '`
ID=`whoami`
NAME=`hostname`

#mod tfc
SERVICE="czero/dlls/cs.so"
MAP="de_dust2_cz"

#metamod
LOC="+localinfo mm_gamedll dlls/cs.so"
#LOG="+log on +localinfo mm_debug 10"
#LOG="+log on +localinfo mm_debug 0"
META="-dll addons/metamod/dlls/metamod.so"

#hlds
PORT="-port 27015"
NET="-tos -tcp -debug +condebug"

######end parameters#########
if namei -m "/usr/games/steamcmd" | grep  -q w;
then
{
    echo "ROOT: Passed Check."
}
else
    echo "ROOT: FAIL|YOU MIGHT BE RUNNING AS ROOT BY MISTAKE!!!"
    exit 1;
fi

if groups $ID | grep sudo > /dev/null
then
{
    echo "SUDO: FAIL|Absolutely no admin right should be used on Steam!"
    exit 1;
}
else
    echo "SUDO: Passed Check."
fi

if lsof -w | grep "$SERVICE" >/dev/null

then
{
    echo "Condition Zero found/ Not running"
    exit 1;
}

else
{
    echo "$UPD"
    if    ls /usr/games/steamcmd > /dev/null
    then
          /usr/games/steamcmd +login $ACCT +app_update 90 validate +app_set_config 90 mod $MOD +app_update 90 +quit > /dev/null
    else
          echo "HLDS Software is missing. If on Debian based system try:: apt install steamcmd"
    fi

    echo $MOD intregrity check complete.

    cd /home/$ID/Steam/steamapps/common/Half-Life/
    nohup screen -A -m -d -S $MOD ./hlds_run +ip "${SERVER_IP}" $BOOST -game $MOD +map $MAP $EDI $ZONE $META $LOC $NET $PORT $CFG +maxplayers $MAX_PLAYERS +mapchangecfgfile server.cfg +hostname $NAME$ID -heapsize 1024000 -update > /dev/null &
    if cpulimit -l $CPU_LIM -e hlds_linux -b
    then
        echo "CPU limiter set to $CPU_LIM%"
    else
    {
        echo "$ATTN to limit CPU usage install package:"
        echo "apt install cpulimit"
    }
    fi
}
fi
