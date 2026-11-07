#!/bin/sh
#Patching Linux hlds on Debian Bookworm on 11/26/2023 -SPINX

#Error:./libstdc++.so.6: version `CXXABI_1.3.8' not found (required by /home/myuserid/Steam/steamapps/common/Half-Life/filesystem_stdio.so)
#email debug.log to linux@valvesoftware.com

if find -name "libstdc++.so.6"
then
unlink ./.local/share/Steam/steamcmd/linux32/libstdc++.so.6
unlink ./Steam/steamapps/common/Half-Life/libstdc++.so.6
fi

export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:./.local/share/Steam/steamcmd/linux32/libstdc++.so.6
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:./Steam/steamapps/common/Half-Life/libstdc++.so.6

if find -name "libgcc_s.so.1"

then
unlink ./Steam/steamapps/common/Half-Life/libgcc_s.so.1
fi

#in case it was not a link
if ls ./Steam/steamapps/common/Half-Life/libgcc_s.so.1
then
rm ./Steam/steamapps/common/Half-Life/libgcc_s.so.1
fi
