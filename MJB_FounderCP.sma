#include <amxmodx>
#include <amxmisc>
#include <MJB_Core>

#define PLUGIN "Founder Control Panel"
#define DEBUG_TASK 4345

new g_iDebuggerToggled[MAX_PLAYERS + 1];
new HudSync;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("mjb_toggle_debugger", "ToggleDebugger", -1, " - toggles debbuger system", 0);
	HudSync = CreateHudSyncObj();
}

public client_disconnected(id)
{
    remove_task(id + DEBUG_TASK);
}

public hasDebugger(id) {
	if (hasRank(id, RANK_OWNER)) {
		MJB_Print(id, "!tYou are authorized");
		return MJB_True;
	}
	return MJB_False;
}

public ToggleDebugger(id, level, cid) {
	if (!hasDebugger(id))
		return PLUGIN_HANDLED;
	
	g_iDebuggerToggled[id] = !g_iDebuggerToggled[id];
	client_print(id, print_console, "^nSuccessfully set Debugger %s^n", (g_iDebuggerToggled[id]) ? "ON" : "OFF");
	StartDebugging(id)
	
	return PLUGIN_HANDLED;
}

public StartDebugging(id) { 
	remove_task(id + DEBUG_TASK);
	set_task(1.0, "HudTask", id + DEBUG_TASK, _, _, "b");
}

public HudTask(hudID) {
	new id = hudID - DEBUG_TASK;
	if (!g_iDebuggerToggled[id]) {
		if (task_exists(hudID))	remove_task(hudID);
		return;
	}
	new szFormat[2568], iLen;
	for (new i = 0; i < MAX_TIMERS; i++) {
		new timerId, gen, Float:timeleft;
		if (!mjb_get_timer_info(i, timerId, gen, timeleft))
			continue;
		
		iLen += formatex(szFormat[iLen], charsmax(szFormat) - iLen, "%d | %d | %d | %d^n", i, timerId, gen, floatround(timeleft));
	}
	new szName[32], szTeam[32], szMGTeam[32], szState[32], szRank[32];
	new pl[32], plnum;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		if (!mjb_is_valid_player(pl[i]))
			continue;
		
		get_user_name(pl[i], szName, 31);
		GetTeamStr(pl[i], szTeam, 31);
		GetMGTStr(mjb_get_user_mg_team(pl[i]), szMGTeam, 31);
		GetStateStr(pl[i], szState, 31);
		GetRankLevelStr(pl[i], szRank, 31);
		iLen += formatex(szFormat[iLen], charsmax(szFormat) - iLen, "^n%s | %s | %s | %s%s | %s^n", szName, szRank, szTeam, szMGTeam, (mjb_is_user_in_duel(pl[i]) ? "D | " : ""),szState, is_user_alive(pl[i]) ? "ALIVE" : "DEAD");
	}
	iLen += formatex(szFormat[iLen], charsmax(szFormat) - iLen, "^n%d | %d | %s%s",mjb_get_day(), mjb_get_day_type(), (mjb_is_duel_running() ? "DUEL  | " : ""),GetPhaseStr(mjb_get_phase()));
	set_hudmessage(75, 75, 75, 0.0, 0.7, 0, 0.0, 1.0, _, _, 4);
	ShowSyncHudMsg(id, HudSync, "%s", szFormat);
}
