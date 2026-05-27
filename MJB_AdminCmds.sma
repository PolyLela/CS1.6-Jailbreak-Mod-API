#include <amxmodx>
#include <amxmisc>
#include <MJB_Core>

#define PLUGIN "Admin Commands"

public plugin_init() {
	register_plugin(PLUGIN, PLUGIN, PLUGIN)
	
	register_concmd("mjb_set_state", "Cmd_SetPlayerState", ADMIN_BAN);
	register_concmd("mjb_get_state", "Cmd_GetPlayerState", ADMIN_BAN);
	/*register_concmd("mjb_set_state", "Cmd_SetPlayerState", ADMIN_BAN);
	register_concmd("mjb_get_state", "Cmd_GetPlayerState", ADMIN_BAN);
	register_concmd("mjb_open_cell", "Cmd_OpenCell", ADMIN_BAN);
	register_concmd("mjb_get_cell_state", "Cmd_GetCellState", ADMIN_BAN);
	register_concmd("mjb_close_cell", "Cmd_CloseCell", ADMIN_BAN);*/
}

public Cmd_SetPlayerState(id)
{
    new arg1[32], arg2[8];
    read_argv(1, arg1, charsmax(arg1));
    read_argv(2, arg2, charsmax(arg2));
    
    new targetId = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY);
    
    new iState = str_to_num(arg2);
    mjb_set_state(targetId, iState);
}

public Cmd_GetPlayerState(id)
{
    new arg1[32];
    read_argv(1, arg1, charsmax(arg1));
    
    new targetId = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY);
    
    new szBuffer[64];
    format(szBuffer, 63, "state : %d", mjb_get_state(targetId));
    MJB_Print(id, szBuffer);
    
}

public mjb_state_changed(id, iOldState, iNewState) {
	MJB_Print(id, "Your state changed from %d to %d", iOldState, iNewState);
}

/*public Cmd_SetPlayerState(id)
{
    new arg1[32], arg2[32];
    read_argv(1, arg1, charsmax(arg1));
    read_argv(2, arg2, charsmax(arg2));
    
    new targetId = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
    
    ParseAndSetState(targetId, arg2);
	
    if (id == targetId)
	PrintPlayerState(id);
    else
	PrintOtherPlayerState(id, targetId);
}

public Cmd_GetPlayerState(id)
{
    new name[32];
    read_argv(1, name, charsmax(name));

    new target = cmd_target(id, name, CMDTARGET_ALLOW_SELF);

    if (id == target)
	PrintPlayerState(id);
    else
	PrintOtherPlayerState(id, target);
}

public Cmd_OpenCell() {
	mjb_open_cell();
}

public Cmd_CloseCell() {
	mjb_close_cell();
}

public Cmd_GetCellState() {
	MJB_Print(0, "cell is : %d", mjb_is_cell_opened());
}*/
