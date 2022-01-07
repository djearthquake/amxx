/*Install instructions: Add z to cmdaccess.ini entry "amx_votemapmenu"   "jz" ; mapsmenu.amxx*/
#include amxmodx

public plugin_init()
    register_plugin("Simpler RTV", "1.0", "SPiNX")&
    register_clcmd("say rtv","handlesay")

public handlesay(id)
    client_cmd(id,"amx_votemapmenu");
