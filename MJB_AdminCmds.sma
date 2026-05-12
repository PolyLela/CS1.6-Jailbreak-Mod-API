/* ################################################################################# */
/* #    _      ____  _             _         __  __           _        ____        # */
/* #   / \    |  _ \| |_   _  __ _(_)_ __   |  \/  | __ _  __| | ___  | __ ) _   _ # */
/* #  / _ \   | |_) | | | | |/ _` | | '_ \  | |\/| |/ _` |/ _` |/ _ \ |  _ \| | | |# */
/* # / ___ \  |  __/| | |_| | (_| | | | | | | |  | | (_| | (_| |  __/ | |_) | |_| |# */
/* #/_/   \_\ |_|   |_|\__,_|\__, |_|_| |_| |_|  |_|\__,_|\__,_|\___| |____/ \__, |# */
/* #         _ _   _ ____ ___|___/ _   ____   ___   ____ _____ ___  ____     |___/ # */
/* #        | | | | / ___|_   _| || | |  _ \ / _ \ / ___|_   _/ _ \|  _ \          # */
/* #     _  | | | | \___ \ | | | || |_| | | | | | | |     | || | | | |_) |         # */
/* #    | |_| | |_| |___) || | |__   _| |_| | |_| | |___  | || |_| |  _ <          # */
/* #     \___/ \___/|____/_|_|    |_| |____/ \___/ \____| |_| \___/|_| \_\         # */
/* #                  / ___|| |_ _   _  __| (_) ___  ___                           # */
/* #                  \___ \| __| | | |/ _` | |/ _ \/ __|                          # */
/* #                   ___) | |_| |_| | (_| | | (_) \__ \                          # */
/* #                  |____/ \__|\__,_|\__,_|_|\___/|___/                          # */
/* ################################################################################# */

#include <amxmodx>
#include <amxmisc>
#include <MJB_Core>

#define PLUGIN "Admin Commands"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("mjb_set_team", "Cmd_SetPlayerTeam", ADMIN_BAN);
	register_concmd("mjb_get_team", "Cmd_GetPlayerTeam", ADMIN_BAN);
	register_concmd("mjb_set_state", "Cmd_SetPlayerState", ADMIN_BAN);
	register_concmd("mjb_get_state", "Cmd_GetPlayerState", ADMIN_BAN);
	register_concmd("mjb_open_cell", "Cmd_OpenCell", ADMIN_BAN);
	register_concmd("mjb_get_cell_state", "Cmd_GetCellState", ADMIN_BAN);
	register_concmd("mjb_close_cell", "Cmd_CloseCell", ADMIN_BAN);
}

public Cmd_SetPlayerTeam(id)
{
    new arg1[32], arg2[32];
    read_argv(1, arg1, charsmax(arg1));
    read_argv(2, arg2, charsmax(arg2));
    
    new targetId = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
    
    ParseAndSetTeam(targetId, arg2);

    if (id == targetId)
	PrintPlayerTeam(id);
    else
	PrintOtherPlayerTeam(id, targetId);
}

public Cmd_GetPlayerTeam(id)
{
    new name[32];
    read_argv(1, name, charsmax(name));

    new target = cmd_target(target, name, CMDTARGET_ALLOW_SELF);
	
    if (id == target)
	PrintPlayerTeam(id);
    else
	PrintOtherPlayerTeam(id, target);
}

public Cmd_SetPlayerState(id)
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
}
