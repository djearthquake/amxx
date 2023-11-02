#!/bin/bash
#Global server parameters
ACCT="anonymous"
BOOST="-pingboost 3"
CFG="+mapchangecfgfile server.cfg"
CPU_LIM="35" ##percent##
EDI="-num_edicts 8192"
UPD="Updating...sparing you the details."

MAX_PLAYERS="32"
#ENTER NAME OF MOD HERE
MOD="sven"

#localhost
SERVER_IP=`hostname  -I | cut -f1 -d' '`
ID=`whoami`
NAME=`hostname`

ATTN="ATTENTION $ID"

#mod SVEN
SERVICE="dlls/server.so"
MAP="uplink"

#metamod
LOC="+localinfo mm_gamedll dlls/server.so"
#LOG="+log on +localinfo mm_debug 10"
#LOG="+log on +localinfo mm_debug 0"
META="-dll addons/metamod/dlls/metamod.so"

#hlds
PORT="-port 27017"
NET="-tos -tcp -debug +condebug"

######end parameters#########
if [ "$ID" == "root" ];
then
{
    echo "ROOT: FAIL|YOU MIGHT BE RUNNING AS ROOT BY MISTAKE!!!"
    exit 1;
}
else
    echo "ROOT: Passed Check."
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
    echo "$MOD found/ Not running"
    exit 1;
}

else
{
    echo "$UPD"
    if    ls /usr/games/steamcmd > /dev/null
    then
          /usr/games/steamcmd +login $ACCT +app_update 276060 validate +quit > /dev/null
    else
          echo "HLDS Software is missing. If on Debian based system try:: apt install steamcmd"
    fi

    echo $MOD intregrity check complete.

    cd /home/$ID/Steam/steamapps/common/Sven\ Co-op\ Dedicated\ Server/
    nohup screen -A -m -d -S $MOD ./svends_run +ip "${SERVER_IP}" $BOOST +map $MAP $EDI $ZONE $META $LOC $NET $PORT $CFG +maxplayers $MAX_PLAYERS +hostname $NAME$ID  > /dev/null &
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
