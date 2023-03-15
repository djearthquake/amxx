#!/bin/bash

SERVICE="dlls/dod.so"
if lsof | grep "$SERVICE" >/dev/null
then
echo "DoD found/ Not running"
else

SERVER_IP=`hostname  -I | cut -f1 -d' '`
NAME=`hostname`
ID=`whoami`
#so you can crontab root niced at -20
cd /home/$ID/Steam/steamapps/common/Half-Life/

nohup screen -A -m -d -S dod ./hlds_run -tos -tcp -debug +condebug -game dod +map dod_caen +ip "${SERVER_IP}" +maxplayers 16 +mapchangecfgfile server.cfg +hostname $NAME$ID &
