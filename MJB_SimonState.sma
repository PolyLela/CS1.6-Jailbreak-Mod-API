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
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "Simon State"

new g_iSimon = 0;
new g_fwSimonSet, g_fwSimonCleared, g_fwSimonDied, g_fwSimonDisconnected;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Killed, "player" , "PostKilled", 1);
	register_event("HLTV", "OnNewRound", "a", "1=0", "2=0");
	g_fwSimonSet = CreateMultiForward("mjb_simon_set", ET_IGNORE, FP_CELL);
	g_fwSimonCleared = CreateMultiForward("mjb_simon_cleared", ET_IGNORE, FP_CELL);
	g_fwSimonDied = CreateMultiForward("mjb_simon_died", ET_IGNORE, FP_CELL);
	g_fwSimonDisconnected = CreateMultiForward("mjb_simon_disconnected", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
	register_library("MJB_Core");
	register_native("mjb_set_simon",	"native_set_simon");
	register_native("mjb_force_set_simon",	"native_force_set_simon");
	register_native("mjb_get_simon",	"native_get_simon");
	register_native("mjb_clear_simon",	"native_clear_simon");
	register_native("mjb_is_simon", 	"native_is_simon");
	register_native("mjb_simon_exists",	"native_simon_exists");
}

public native_set_simon() {
	SetSimon(get_param(1));
}

public native_force_set_simon() {
	ForceSetSimon(get_param(1));
}

public native_get_simon() {
	return GetSimon();
}

public native_clear_simon() {
	ClearSimon();
}

public native_is_simon() {
	return IsSimon(get_param(1));
}

public native_simon_exists() {
	return SimonExists();
}

public OnNewRound() {
	ClearSimon();
}

public client_disconnect(id) {
	if (id != g_iSimon)
		return;
		
	ClearSimon();
	new ret;
	ExecuteForward(g_fwSimonDisconnected, ret, id);
}

public PostKilled(id, idattacker) {
	if (id != g_iSimon)
		return;
		
	ClearSimon();
	new ret;
	ExecuteForward(g_fwSimonDied, ret, id);
}

public SetSimon(id) {
	if (mjb_get_team(id) != GUARD || SimonExists() || !mjb_is_valid_player(id))
		return;
	g_iSimon = id;
	new ret;
	ExecuteForward(g_fwSimonSet, ret, id);
}

public ForceSetSimon(id) {
	if (mjb_get_team(id) != GUARD || !mjb_is_valid_player(id))
		return;

	ClearSimon();
	SetSimon(id);
}

public ClearSimon() {
	new iOldSimon = g_iSimon;
	g_iSimon = 0;
	new ret;
	ExecuteForward(g_fwSimonCleared, ret, iOldSimon);
}

public IsSimon(id) {
	if (GetSimon() == id)
		return MJB_True;
	return MJB_False;
}

public GetSimon() {
	return g_iSimon;
}

public SimonExists() {
	if (g_iSimon > 0)
		return MJB_True;
	return MJB_False;
}
