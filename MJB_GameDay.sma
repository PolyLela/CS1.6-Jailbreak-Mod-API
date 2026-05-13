#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "Gameday"

enum {
	DAY_SPARTA = 0,
	DAY_PREDATOR,
	DAY_PRESIDANT,
	DAY_BOXING,
	DAY_SCOUT,
	DAY_SNOWBALL,
	DAY_FREE,
	DAY_INVERTED,
	DAY_NORMAL,
	DAYS_NUM
}

new g_iVoteTimer;
new g_iDayModeVotes[DAYS_NUM];
new g_iCurrentVote[MAX_PLAYERS + 1];
new g_iFreezed[MAX_PLAYERS + 1];
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Spawn, "player", "HamSpawnPost", 1);
	register_menucmd(register_menuid("VoteMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_VoteMenu");
}

public client_disconnect(id) {
	g_iFreezed[id] = MJB_False;
	g_iCurrentVote[id] = -1;
}

public HamSpawnPost(id) {
	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE && !g_iFreezed[id]) {
		VoteMenu(id);
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
		set_pdata_float(id, m_flNextAttack, mjb_get_timer_timeleft(g_iVoteTimer), linux_diff_player);
		UTIL_ScreenFade(id, 0, 0, 4, 0, 0, 0, 255);
	}
}

public mjb_phase_changed(iOldPhase, iNewPhase) {
	if (iNewPhase == PHASE_GAMEDAY_VOTE) {
		StartVote();
	}
}

public mjb_timer_ended(iTimerId) {
	if (g_iVoteTimer != iTimerId)
		return;
	EndVote();
	ProcessVoteResult();
}

public mjb_timer_ticked(iTimerId) {
	if (g_iVoteTimer != iTimerId)
		return;
	RefreshVoteMenu();
}

public RefreshVoteMenu() {
	new players[32], plnum, id;
	get_players(players, plnum, "ah");
	for (new i = 0; i < plnum; i++) {
		id = players[i];
		if (!mjb_is_valid_player(id) || !mjb_is_player_alive(id))
			continue;
		
		VoteMenu(id);
	}
}

public StartVote() {
	g_iVoteTimer = mjb_start_timer(15.0);
	new players[32], plnum, id;
	get_players(players, plnum, "ah");
	mjb_block_simon_menu();
	mjb_block_main_menu();
	arrayset(g_iDayModeVotes, 0, sizeof(g_iDayModeVotes));
	for (new i = 0; i < plnum; i++) {
		id = players[i];
		if (!mjb_is_valid_player(id) || g_iFreezed[id])
			continue;
		
		g_iFreezed[id] = MJB_True;
		g_iCurrentVote[id] = -1;
		VoteMenu(id);
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
		set_pdata_float(id, m_flNextAttack, mjb_get_timer_timeleft(g_iVoteTimer), linux_diff_player);
		UTIL_ScreenFade(id, 0, 0, 4, 0, 0, 0, 255);
	}
}

public EndVote() {
	new players[32], plnum, id;
	get_players(players, plnum, "ah");
	mjb_unblock_simon_menu();
	mjb_unblock_main_menu();
	for (new i = 0; i < plnum; i++) {
		id = players[i];
		if (!mjb_is_valid_player(id))
			continue;
		g_iFreezed[id] = MJB_False;
		show_menu(id, 0, "^n");
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
		set_pdata_float(id, m_flNextAttack, 0.0, linux_diff_player);
		UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);

	}
}

public ProcessVoteResult() {
	new candidate = -1, curDay;
	for (new i = 0; i < sizeof(g_iDayModeVotes); i++) {
		curDay = g_iDayModeVotes[i];
		new c = (candidate == -1) ? 0 : candidate;
		if (curDay > 0 && curDay >= g_iDayModeVotes[c])
			candidate = i;
	}
	if (candidate == -1 || candidate == DAY_NORMAL) {
		MJB_Print(0, "No daymode choosed, Normalday starts");
		mjb_end_gameday_vote(0);
	} else if (candidate == DAY_FREE){ 
		mjb_end_gameday_vote(1);
	} else {
		new szDayMode[32];
		GetDayModeStr(candidate, szDayMode, 31);
		MJB_Print(0, "Vote ended daymode : %s", szDayMode);
		mjb_end_gameday_vote(2);
	}
}

stock GetDayModeStr(iDayMode, szOutput[], len) {
	switch(iDayMode) {
		case DAY_SPARTA : format(szOutput, len, "Sparta Day");
		case DAY_PREDATOR : format(szOutput, len, "Predator Day");
		case DAY_PRESIDANT : format(szOutput, len, "Presidant Day");
		case DAY_BOXING : format(szOutput, len, "Boxing Day");
		case DAY_SCOUT : format(szOutput, len, "Scout Day");
		case DAY_SNOWBALL : format(szOutput, len, "Snowball Day");
		case DAY_FREE : format(szOutput, len, "Free Day");
		case DAY_INVERTED : format(szOutput, len, "Inverted Day");
		case DAY_NORMAL : format(szOutput, len, "Normal Day");
	}
}

public VoteMenu(id) {
	if (mjb_get_phase() != PHASE_GAMEDAY_VOTE || !mjb_is_timer_running(g_iVoteTimer))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yVote Menu^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\dRemaining time: [\r%d\d]^n^n", floatround(mjb_get_timer_timeleft(g_iVoteTimer)));
	
	if (g_iCurrentVote[id] == -1) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wSparta Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_SPARTA]);
		iKeys |= (1<<0);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wPredator Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_PREDATOR]);
		iKeys |= (1<<1);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wPresidant Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_PRESIDANT]);
		iKeys |= (1<<2);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wBoxing Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_BOXING]);
		iKeys |= (1<<3);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wScout Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_SCOUT]);
		iKeys |= (1<<4);
	
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \wSnowball Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_SNOWBALL]);
		iKeys |= (1<<5);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7\d. \wFree Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_FREE]);
		iKeys |= (1<<6);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8\d. \wInverted Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_INVERTED]);
		iKeys |= (1<<7);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9\d. \wNormal Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_NORMAL]);
		iKeys |= (1<<8);
	} else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \dSparta Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_SPARTA]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \dPredator Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_PREDATOR]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \dPresidant Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_PRESIDANT]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \dBoxing Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_BOXING]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \dScout Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_SCOUT]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \dSnowball Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_SNOWBALL]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7\d. \dFree Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_FREE]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8\d. \dInverted Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_INVERTED]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9\d. \dNormal Day \r[\y%d\r]^n", g_iDayModeVotes[DAY_NORMAL]);
	}
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "VoteMenu");
	
}

public Handle_VoteMenu(id, iKeys){
	if (mjb_get_phase() != PHASE_GAMEDAY_VOTE || !mjb_is_timer_running(g_iVoteTimer))
		return PLUGIN_HANDLED;
	if (iKeys >= 0 && iKeys <= 8) {
		if (g_iCurrentVote[id] == -1) {
			g_iCurrentVote[id] = iKeys
			if (get_user_flags(id) & ADMIN_LEVEL_H) //VIP
				g_iDayModeVotes[g_iCurrentVote[id]] += 2;
			else
				g_iDayModeVotes[g_iCurrentVote[id]] += 1;
		}
	} else if (iKeys == 9) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
