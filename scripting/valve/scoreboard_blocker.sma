#include <amxmodx>
#include <fakemeta>

new bool:g_Allow_board = true;

public plugin_init()
{
  register_plugin("Score tab controller","A",".sρiηX҉.");
  register_forward(FM_UpdateClientData, "@fw_UpdateClientData")
  register_logevent("@Allow_scoreboard", 2, "1=Round_Start", "0=World triggered", "1=Round_End");
}

@Allow_scoreboard()
{
  g_Allow_board = true;
  set_task(20.0, "@Block_scoreboard");
}

@Block_scoreboard(){g_Allow_board = false;}

@fw_UpdateClientData(id)
{
  if (g_Allow_board == false) {
    if( (pev(id, pev_button) & IN_SCORE) && (pev(id, pev_oldbuttons) & IN_SCORE) ){
        console_cmd(id, "-showscores")
        client_print(id,print_center, "No scores during game.");
        }
    }
}
