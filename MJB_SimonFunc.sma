#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "Simon Functionality"

new g_iCountdownTimer = -1;
new g_iCenterHudSync;
new g_iLastSecond;

new g_bSimonMenuBlocked = MJB_False;
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS + 1], g_iMenuCount[MAX_PLAYERS + 1];
new g_bFootballMatchRunning = MJB_False;
new g_iFootballTeamScore[3]; //0 is a garbage value
new g_iWinningScore = 1;

new g_bBoxingMatchRunning = MJB_False;
new g_iBoxingStartingHealth = 100;
new g_iBoxingStartingHPindex = 3;
new g_BoxingStartingHP[] = {
	1,
	5,
	50,
	100
};
new menus[14];
/* =========================
   PLUGIN LIFECYCLE
========================= */
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say", "HandleSay");
	menus[0] = register_menuid("SimonMenu");
	menus[1] = register_menuid("CountdownMenu");
	menus[2] = register_menuid("WantedsMenu");
	menus[3] = register_menuid("ManagePrisonerMenu");
	menus[4] = register_menuid("_MinigamesMenu");
	menus[5] = register_menuid("_BoxingMenu");
	menus[6] = register_menuid("BoxingTeamsMenu");
	menus[7] = register_menuid("_FootballMenu");
	menus[8] = register_menuid("_TeamsMenu");
	menus[9] = register_menuid("FreeDayControlMenu");
	menus[10] = register_menuid("VoiceMenu");
	menus[11] = register_menuid("TreatMenu");
	menus[12] = register_menuid("PunishMenu");
	menus[13] = register_menuid("TransferMenu");
	register_menucmd(menus[0], 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_SimonMenu");
	register_menucmd(menus[1], 		(1<<0|1<<1|1<<2|1<<9),                                   "Handle_CountdownMenu");
	register_menucmd(menus[2], 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_WantedPrisonersMenu");
	register_menucmd(menus[3], 		(1<<0|1<<1|1<<2|1<<9),                                   "Handle_ManagePrisonerMenu");
	register_menucmd(menus[4], 		(1<<0|1<<1|1<<2|1<<9),                                   "Handle_MinigamesMenu");
	register_menucmd(menus[5], 		(1<<0|1<<1|1<<2|1<<9),                                   "Handle_BoxingMenu");
	register_menucmd(menus[6], 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<9),                                   "Handle_BoxingTeamsMenu");
	register_menucmd(menus[7], 		(1<<0|1<<1|1<<2|1<<3|1<<9),                                   "Handle_FootballMenu");
	register_menucmd(menus[8], 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<9),                                   "Handle_TeamsMenu");
	register_menucmd(menus[9], 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_FreeDayControlMenu");
	register_menucmd(menus[10], 	         (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_VoiceControlMenu");
	register_menucmd(menus[11],   		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_TreatPrisonerMenu");
	register_menucmd(menus[12], 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_PunishMenu");
	register_menucmd(menus[13], 	         (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_TransferSimonMenu");
	g_iCenterHudSync = CreateHudSyncObj();
}

/* =========================
   API NATIVES
========================= */

public plugin_natives() {
	register_library("MJB_Core");
	
	register_native("mjb_block_simon_menu", "native_block_simon_menu");
	register_native("mjb_unblock_simon_menu", "native_unblock_simon_menu");
	register_native("mjb_show_simon_menu", "native_show_simon_menu");
}

public native_block_simon_menu() {
	new id = get_param(1);
	BlockSimonMenu(id);
}

public native_unblock_simon_menu() {
	UnBlockSimonMenu();
}

public native_show_simon_menu() {
	new id = get_param(1);
	SimonMenu(id);
}

/* =========================
   RESOURCES
========================= */
public plugin_precache() {
	precache_sound("MOON_JB/MOON_Bell.wav");
	for (new i = 0; i <= 10; i++) {
		new szBuffer[32];
		format(szBuffer, 31, "MOON_JB/Countdown/%d.wav", i);
		precache_sound(szBuffer);
	}
	precache_sound("MOON_JB/simon_open_cell.wav");
	precache_sound("MOON_JB/simon_close_cell.wav");
	precache_sound("MOON_JB/Soccer/crowd.wav");
	precache_sound("MOON_JB/Soccer/clear.wav");
	precache_sound("MOON_JB/Soccer/whistle_start.wav");
	precache_sound("MOON_JB/Soccer/whistle_end.wav");
	precache_sound("MOON_JB/Boxing/tt_boxing.mp3");
}

/* =========================
   EVENTS
========================= */
public mjb_phase_changed(iOldPhase, iNewPhase)
{
	if (iNewPhase == PHASE_DAY_STARTED && iOldPhase != PHASE_DAY_STARTED)
		OnDayStart();
	
	if (iNewPhase == PHASE_DAY_ENDED && iOldPhase != PHASE_DAY_ENDED)
		OnDayEnd();
}

public OnDayStart() {
	UnBlockSimonMenu()
}

public OnDayEnd() {
	show_menu(0, 0, "^n", 1);
	StopCountdown();
}

public client_PostThink(id) {
	if(!mjb_is_simon(id) || !(entity_get_int(id, EV_INT_flags) & FL_ONGROUND))
		return PLUGIN_CONTINUE;
	
	static Float:origin[3];
	static Float:last[3];
	
	entity_get_vector(id, EV_VEC_origin, origin);
	if (get_distance_f(origin, last) < 32.0) {
		return PLUGIN_CONTINUE;
	}
	
	vec_copy(origin, last);
	if (entity_get_int(id, EV_INT_bInDuck)) {
		origin[2] -= 18.0;
	} else {
		origin[2] -= 36.0;
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	write_coord(floatround(origin[0]));
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2]));
	write_byte(105); // Decal index for black footprints
	message_end();
	
	return PLUGIN_CONTINUE;
}

/* =========================
   HELPER FUNCTIONS
========================= */
public BlockSimonMenu(id) {
	g_bSimonMenuBlocked = MJB_True;
	if (mjb_is_valid_player(id)) {
		show_menu(id, 0, "^n", 1);
	}
}

public UnBlockSimonMenu() {
	g_bSimonMenuBlocked = MJB_False;
}

public SemiCanOpenSimonMenu(id) {
	if (!mjb_is_valid_player(id))
		return MJB_False;
	
	if (!is_user_alive(id) || !mjb_is_simon(id)) {
		if (!hasRank(id, RANK_CO_OWNER)) MJB_Print(id, "!tOnly simon can open this menu");
		return MJB_False;
	}
	
	if (g_bSimonMenuBlocked  || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_is_user_in_duel(id)) {
		if (!hasRank(id, RANK_CO_OWNER)) MJB_Print(id, "!nSimon menu is disabled");
		return MJB_False;
	}
	return MJB_True;
}

public CanOpenSimonMenu(id) {
	if (hasRank(id, RANK_CO_OWNER) || SemiCanOpenSimonMenu(id)) {
		return MJB_True;
	}
		
	return MJB_False;
}

/* =========================
   CORE: SIMON HANDLING
========================= */
public HandleSay(id) {
	new said[192];
	read_args(said, charsmax(said));
	
	if (containi(said, "/simon") == -1)
		return PLUGIN_CONTINUE;
	
	GiveSimon(id);
	return PLUGIN_HANDLED;
}

public GiveSimon(id) {
	if (GetTeam(id) == GUARD && mjb_get_phase() != PHASE_GAMEDAY_VOTE && mjb_get_phase() != PHASE_GAMEDAY_ACTIVE && !mjb_is_user_in_duel(id)) {
		mjb_set_simon(id);
	}
	SimonMenu(id);
}

public mjb_simon_set(id) {
	rg_give_item(id, "weapon_m249");
	rg_give_item(id, "weapon_deagle");
	rg_set_user_bpammo(id, WEAPON_M249, 200);
	rg_set_user_bpammo(id, WEAPON_DEAGLE, 35);
	set_pev(id, pev_health, 511.0);
	set_pev(id, pev_armorvalue, 200.0);
}

public mjb_simon_cleared(iOldSimon) {
	if (!mjb_is_valid_player(iOldSimon) || !is_user_alive(iOldSimon))
		return;
		
	show_menu(iOldSimon, 0, "^n", 1);
	engclient_cmd(iOldSimon, "drop", "weapon_m249");
	engclient_cmd(iOldSimon, "drop", "weapon_deagle");
	if (GetTeam(iOldSimon) == GUARD) {
		set_pev(iOldSimon, pev_health, 200.0);
		set_pev(iOldSimon, pev_armorvalue, 100.0);
	}
}

/* =========================
   MENUS: SIMON MENU
========================= */
public SimonMenu(id){
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \ySimon Menu^n^n", id);
	
	if(!mjb_is_cell_opened()){
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \yOpen Doors^n", id);
	}
	else{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \rClose Doors^n", id);
	}
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wRing Bell^n", id);
	iKeys |= (1<<1);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wCountdown \w[\r3\w, \r5\w, \r10\w]^n", id);
	iKeys |= (1<<2);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wPunish Guard^n", id);
	iKeys |= (1<<3);
	
	if(mjb_get_day_type() != FREEDAY){
		if(mjb_get_phase() != PHASE_FREEDAY){	
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wStart Freeday^n", id);
		} else{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wEnd Freeday^n", id);
		}
		iKeys |= (1<<4);
	} else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. Already Freeday^n", id);
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \wMini Games \yNew^n", id);
	iKeys |= (1<<5);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7\d. \wWanted Prisoners \yShow^n", id);
	iKeys |= (1<<6);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8\d. \wManage Prisoners \w[\rFD\w, \rVoice\w, \rHeal\w]^n", id);
	iKeys |= (1<<7);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9\d. \wTransfer Simon^n", id);
	iKeys |= (1<<8);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "SimonMenu");
	
}

public Handle_SimonMenu(id, iKeys){
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch(iKeys)
	{
		case 0:
		{
			if(!mjb_is_cell_opened()) {
				mjb_open_cell(); 
				emit_sound(0, CHAN_AUTO, "MOON_JB/simon_open_cell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else {
				mjb_close_cell();
				emit_sound(0, CHAN_AUTO, "MOON_JB/simon_close_cell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
		}
		case 1:
		{
			emit_sound(0, CHAN_AUTO, "MOON_JB/MOON_Bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case 2:
		{
			return CountdownMenu(id);
		}
		case 3:
		{
			return Cmd_PunishMenu(id);
		}
		case 4:
		{
			if(mjb_get_day_type() != FREEDAY){
				if(mjb_get_phase() != PHASE_FREEDAY){	
					mjb_start_freeday();
				} else{
					mjb_end_freeday();
				}
			}
			return SimonMenu(id);
		}
		case 5:
		{
			return MinigamesMenu(id);
		}
		case 6:
		{
			return Cmd_WantedPrisonersMenu(id);
		}
		case 7:
		{
			return Show_ManagePrisonerMenu(id);
		}
		case 8:
		{
			return Cmd_TransferSimonMenu(id);
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return SimonMenu(id);
}

/* =========================
   CORE: Countdown Menu
========================= */
public CountdownMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yCountdown^n^n", id);
	
	if (!mjb_is_timer_running(g_iCountdownTimer)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \y3 \wSeconds^n", id);
		iKeys |= (1<<0);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \y5 \wSeconds^n", id);
		iKeys |= (1<<1);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \y10 \wSeconds^n^n^n^n^n^n^n", id);
		iKeys |= (1<<2);
	} else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. 3 Seconds^n", id);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. 5 Seconds^n", id);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. 10 Seconds^n^n^n^n^n^n^n", id);
	}
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "CountdownMenu");
}

public Handle_CountdownMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			if (!mjb_is_timer_running(g_iCountdownTimer)) g_iCountdownTimer = mjb_start_timer(3.0);
		}
		case 1: {
			if (!mjb_is_timer_running(g_iCountdownTimer)) g_iCountdownTimer = mjb_start_timer(5.0);
		}
		case 2: {
			if (!mjb_is_timer_running(g_iCountdownTimer)) g_iCountdownTimer = mjb_start_timer(10.0);
		}
		case 9: {
			return SimonMenu(id);
		}
	}
	return CountdownMenu(id);
}

public mjb_timer_started(iTimer, Float:fTimeleft)
{
	if (iTimer != g_iCountdownTimer)
		return;
	g_iLastSecond = floatround(fTimeleft, floatround_ceil);
	printCenterHud(0, "Countdown: %d", 1.0, g_iLastSecond);
}

public mjb_timer_ticked(iTimer, Float:fTimeleft)
{
	if (iTimer != g_iCountdownTimer)
		return;
	
	new iCurrent = floatround(fTimeleft, floatround_ceil);
	
	// avoid negative / weird zero duplication
	if (iCurrent < 0)
		iCurrent = 0;
	
	// play sound ONLY when second changes
	if (iCurrent != g_iLastSecond)
	{
		new szBuffer[64];
		formatex(szBuffer, charsmax(szBuffer), "MOON_JB/Countdown/%d.wav", iCurrent);
		emit_sound(0, CHAN_AUTO, szBuffer, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		g_iLastSecond = iCurrent;
	}
	
	printCenterHud(0, "Countdown: %d", 1.0, g_iLastSecond);
}

public mjb_timer_ended(iTimer)
{
	if (iTimer != g_iCountdownTimer)
		return;
	
	g_iCountdownTimer = -1;
	g_iLastSecond = 0;
	printCenterHud(0, "Countdown Ended!", 1.0);
}

public StopCountdown() {
	mjb_stop_timer(g_iCountdownTimer);
	g_iCountdownTimer = -1;
	g_iLastSecond = 0;
}

/* =========================
    MENU: Punish Guards
========================= */
public Cmd_PunishMenu(id) {
	ResetMenuPlayers(id);
	new pl[32], iPlayersNum;
	get_players(pl, iPlayersNum, "h");
	
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if (pl[i] == id || !mjb_is_valid_player(pl[i]) || GetTeam(pl[i]) != GUARD)
			continue;
	
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_PunishMenu(id, g_iMenuPosition[id] = 0);
}

Show_PunishMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	
	if(g_iMenuCount[id] == 0)
	{
		MJB_Print(id, "!nNo guards found.");
		return SimonMenu(id);
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yPunish guards \w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\y[%d] \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	
	return show_menu(id, iKeys, szMenu, -1, "PunishMenu");
}

public Handle_PunishMenu(id, iKey)
{
	if(!CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_PunishMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_PunishMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_PunishMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || GetTeam(iTarget) != GUARD) return Show_PunishMenu(id, g_iMenuPosition[id]);
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			MJB_Print(id, "!tSimon !g%s !tPunished !g%s", szName, szTargetName);
			rg_set_user_team(iTarget, TEAM_TERRORIST, MODEL_AUTO, true, true);
			user_kill(iTarget, 1);
		}
	}
	return Show_PunishMenu(id, g_iMenuPosition[id]);
}

/* =========================
   MENU: Minigames
========================= */
public MinigamesMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yMini Games^n^n", id);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wDistance Drop^n", id);
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wBoxing \yNew^n", id);
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wFootball Menu^n^n^n^n^n^n^n", id);
	iKeys |= (1<<2);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wBack", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "_MinigamesMenu");
}

public Handle_MinigamesMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			for(new i = 1; i <= MAX_PLAYERS; i++)
			{
				if(!mjb_is_valid_player(i) || !is_user_alive(i) || GetTeam(i) != PRISONER || mjb_get_state(i) != NORMAL)
					continue;
				rg_remove_item(i, "weapon_deagle", true);
				new iEntity = rg_give_item(i, "weapon_deagle");
				if(pev_valid(iEntity)) rg_set_user_ammo(id, WEAPON_DEAGLE, 0);
			}
			MJB_Print(0, "!tSimon started a distance drop game.");
		}
		case 1: {
			return BoxingMenu(id);
		}
		case 2: {
			return FootballMenu(id);
		}
		case 9: {
			return SimonMenu(id);
		}
	}
	return MinigamesMenu(id);
}

public BoxingMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yBoxing Menu^n^n");
	
	if (!g_bBoxingMatchRunning)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \yStart Match^n");
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \rEnd Match^n");
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wSet starting HP \y[\d%d\y]^n", g_iBoxingStartingHealth);
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wTeams Menu^n");
	iKeys |= (1<<2);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wBack");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "_BoxingMenu");
}

public Handle_BoxingMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			if (g_bBoxingMatchRunning) {
				if (EndBoxingMatch(id))
					MJB_Print(0, "!tSimon ended the boxing match");
			}
			else {
				if (StartBoxingMatch(id))
					MJB_Print(0, "!tSimon started a boxing match");
			}
		}
		case 1: {
			g_iBoxingStartingHPindex = (g_iBoxingStartingHPindex+1) % sizeof(g_BoxingStartingHP);
			g_iBoxingStartingHealth = g_BoxingStartingHP[g_iBoxingStartingHPindex];
		}
		case 2: {
			return BoxingTeamsMenu(id);
		}
		case 9: {
			return MinigamesMenu(id);
		}
	}
	return BoxingMenu(id);
}

public StartBoxingMatch(id) {
	if (g_bBoxingMatchRunning) {
		MJB_Print(id, "!nYou can start boxing match in normal days only");
		return 0;
	}
	
	if (g_bFootballMatchRunning) {
		MJB_Print(id, "!nEnd football match first");
		return 0;
	}
		
	if (mjb_get_phase() != PHASE_NORMAL) {
		MJB_Print(id, "!nYou can start boxing match in normal days only");
		return 0;
	}
	
	if (mjb_get_mg_team_count(BLUE) <= 0 || mjb_get_mg_team_count(RED) <= 0) {
		MJB_Print(id, "!nBoth boxing teams must have atleast one prisoner");
		return 0;
	}
	
	g_bBoxingMatchRunning = MJB_True;
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER || mjb_get_state(tempid) == PRISONER_WANTED  || mjb_get_state(tempid) == PRISONER_FREEDAY || mjb_get_state(tempid) == PRISONER_LAST)
			continue;
		
		switch (mjb_get_user_mg_team(tempid)) {
			case BLUE: {
				mjb_set_user_boxing(tempid);
				mjb_set_user_melee(tempid, MELEE_BOXING_BLUE);
				fm_switch_to_knife(tempid);
			}
			case RED: {
				mjb_set_user_boxing(tempid);
				mjb_set_user_melee(tempid, MELEE_BOXING_RED);
				fm_switch_to_knife(tempid);
			}
		}
	}
	client_cmd(0, "mp3 play sound/MOON_JB/Boxing/tt_boxing.mp3");
	return 1;
}

public mjb_life_state_changed(id, isAlive) {
	if (!isAlive && mjb_get_state(id) == PRISONER_BOXING) {
		mjb_set_state(id, NORMAL);
		mjb_set_user_melee(id, 0);
		mjb_set_user_mg_team(id, 0);
	}
}

public EndBoxingMatch(id) {
	if (!g_bBoxingMatchRunning) {
		MJB_Print(id, "!nThere is no boxing match running to end");
		return 0;
	}
	
	g_bBoxingMatchRunning = MJB_False;
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER)
			continue;

		if (mjb_get_state(tempid) == PRISONER_BOXING) mjb_set_state(tempid, NORMAL);
		mjb_set_user_melee(tempid, 0);
	}
	engclient_cmd(id, "mp3", "stop");
	return 1;
}

public BoxingTeamsMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yTeams Manager^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\dBlue \r[\y%d\r] \d: Red \r[\y%d\r]^n", mjb_get_mg_team_count(BLUE), mjb_get_mg_team_count(RED));
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wDivide prisoners evenly^n");
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wAdd target to \yblue^n");
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wAdd target to \yred^n");
	iKeys |= (1<<2);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wClear target team^n");
	iKeys |= (1<<3);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wClear all team^n");
	iKeys |= (1<<4);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wBack");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "BoxingTeamsMenu");
}

public Handle_BoxingTeamsMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			new pl[32], plnum, tempid;
			new prisoners[32], prnum;
			get_players(pl, plnum, "h");
			
			for (new i = 0; i < plnum; i++) {
				tempid = pl[i];
				if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER || 
				(mjb_get_state(tempid) != NORMAL && mjb_get_state(tempid) != PRISONER_SOCCER && mjb_get_state(tempid) != PRISONER_BOXING))
					continue;
				prisoners[prnum++] = tempid;
			}
			
			if (prnum == 0) {
				MJB_Print(id, "!nNo prisoners found");
				return BoxingMenu(id);
			}
			
			for (new i = 0; i < prnum; i++) {
				tempid = prisoners[i];
				if (i % 2 == 0) //even then add to blue team
					mjb_set_user_mg_team(tempid, BLUE);
				else //odd then add to red team
					mjb_set_user_mg_team(tempid, RED);
					
			}
			MJB_Print(id, "!nSuccessfully divided prisoners into two teams");
		}
		case 1: {
			new target, body;
			get_user_aiming(id, target, body);
			if (!mjb_is_valid_player(target) || !is_user_alive(target) || GetTeam(target) != PRISONER)
				return PLUGIN_HANDLED;
			mjb_set_user_mg_team(target, BLUE);
			MJB_Print(id, "Successfully set target team to blue");
		}
		case 2: {
			new target, body;
			get_user_aiming(id, target, body);
			if (!mjb_is_valid_player(target) || !is_user_alive(target) || GetTeam(target) != PRISONER)
				return PLUGIN_HANDLED;
			mjb_set_user_mg_team(target, RED);
			MJB_Print(id, "Successfully set target team to red");
		}
		case 3: {
			new target, body;
			get_user_aiming(id, target, body);
			if (!mjb_is_valid_player(target) || !is_user_alive(target) || GetTeam(target) != PRISONER)
				return PLUGIN_HANDLED;
			mjb_set_user_mg_team(target, 0);
			MJB_Print(id, "Successfully cleared target team");
		}
		case 4: {
			new pl[MAX_PLAYERS], plnum, tempid;
			get_players(pl, plnum, "h");
			
			for (new i = 0; i < plnum; i++) {
				tempid = pl[i];
				if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER)
					continue;
				mjb_set_user_mg_team(tempid, 0);
			}
			MJB_Print(id, "Successfully cleared prisoners team");
		}
		case 9: {
			return BoxingMenu(id);
		}
	}
	return BoxingTeamsMenu(id);
}

public FootballMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yFootball Manager^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\dBlue Score \r[\y%d\r] \d: Red Score \r[\y%d\r]^n", g_iFootballTeamScore[BLUE], g_iFootballTeamScore[RED]);
	
	if (!g_bFootballMatchRunning)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \yStart Match^n");
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \rEnd Match^n");
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wRespawn ball^n");
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wSet winning score \y[\d%d\y]^n", g_iWinningScore);
	iKeys |= (1<<2);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wTeams Menu^n");
	iKeys |= (1<<3);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wBack");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "_FootballMenu");
}

public Handle_FootballMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			if (g_bFootballMatchRunning) {
				if (EndFootballMatch(id))
					MJB_Print(0, "!gSimon ended the football match");
			}
			else {
				if (StartFootballMatch(id))
				MJB_Print(0, "!gSimon started a football match");
			}
		}
		case 1: {
			client_cmd(id, "say /resetball");
		}
		case 2: {
			if (g_iWinningScore < 3)
				g_iWinningScore++;
			else if (g_iWinningScore == 3)
				g_iWinningScore = 5;
			else
				g_iWinningScore = 1;
		}
		case 3: {
			return TeamsMenu(id);
		}
		case 9: {
			return MinigamesMenu(id);
		}
	}
	return FootballMenu(id);
}

public StartFootballMatch(iSimonId) {
	if (mjb_get_phase() != PHASE_NORMAL) {
		MJB_Print(iSimonId, "!nYou can start football match in normal days only");
		return 0;
	}
	if (g_bBoxingMatchRunning) {
		MJB_Print(iSimonId, "!nEnd boxing match first");
		return 0;
	}
	if (g_bFootballMatchRunning) {
		MJB_Print(iSimonId, "!nAlready a football match is running");
		return 0;
	}
	if (mjb_get_mg_team_count(BLUE) <= 0 || mjb_get_mg_team_count(RED) <= 0) {
		MJB_Print(iSimonId, "!nBoth football teams must have atleast one prisoner");
		return 0;
	}
	g_bFootballMatchRunning = MJB_True;
	
	//maybe show hud to red team players and blue team players
	emit_sound(0, CHAN_AUTO, "MOON_JB/Soccer/whistle_start.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_task(1.0, "PlayCrowdSound");
	return 1;
}

public mjb_player_scored(id, iBall, iNet) {
	if (!g_bFootballMatchRunning)
		return;
	
	new iShouldGiveScoreTeam;
	if (iNet == BLUE)
		iShouldGiveScoreTeam = RED;
	else
		iShouldGiveScoreTeam = BLUE;
	g_iFootballTeamScore[iShouldGiveScoreTeam]++;
	if (g_iFootballTeamScore[iShouldGiveScoreTeam] >= g_iWinningScore) {
		g_bFootballMatchRunning = MJB_False;
		g_iFootballTeamScore[1] = 0;
		g_iFootballTeamScore[2] = 0;
		MJB_Print(0, "!tFootball match ended, Winner is : !g%s", (iShouldGiveScoreTeam == BLUE) ? "Blue team" : "Red team");
		printCenterHud(mjb_get_simon(), ">>Winner : %s<<", 3.0, (iShouldGiveScoreTeam == BLUE) ? "Blue team" : "Red team");
		ClearAllTeam(mjb_get_simon())
		StopCrowdSound();
		emit_sound(0, CHAN_AUTO, "MOON_JB/Soccer/whistle_end.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}	
}

public PlayCrowdSound() {
	emit_sound(0, CHAN_STATIC, "MOON_JB/Soccer/crowd.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public StopCrowdSound() {
	emit_sound(0, CHAN_STATIC, "MOON_JB/Soccer/crowd.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
}

public EndFootballMatch(iSimonId) {
	if (!g_bFootballMatchRunning) {
		MJB_Print(iSimonId, "!nThere isnt a football match running to end");
		return 0;
	}
	g_bFootballMatchRunning = MJB_False;
	
	if (g_iFootballTeamScore[BLUE] > g_iFootballTeamScore[RED]) {
		MJB_Print(0, "!tFootball match ended, Winner is : !gBlue team");
		printCenterHud(mjb_get_simon(), ">>Winner : Blue team<<", 3.0);
	} else if (g_iFootballTeamScore[RED] > g_iFootballTeamScore[BLUE]) {
		MJB_Print(0, "!tFootball match ended, Winner is : !gRed team");
		printCenterHud(mjb_get_simon(), ">>Winner : Red team<<", 3.0);
	} else {
		MJB_Print(0, "!tFootball match ended, The result is !gDraw");
		printCenterHud(mjb_get_simon(), ">>Result : Draw<<", 3.0);
	}
	ClearAllTeam(iSimonId)
	g_iFootballTeamScore[1] = 0;
	g_iFootballTeamScore[2] = 0;
	StopCrowdSound();
	emit_sound(0, CHAN_AUTO, "MOON_JB/Soccer/whistle_end.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}

public TeamsMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yTeams Manager^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\dBlue \r[\y%d\r] \d: Red \r[\y%d\r]^n", mjb_get_mg_team_count(BLUE), mjb_get_mg_team_count(RED));
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wDivide prisoners evenly^n");
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wAdd target to \yblue^n");
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wAdd target to \yred^n");
	iKeys |= (1<<2);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wClear target team^n");
	iKeys |= (1<<3);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wClear all team^n");
	iKeys |= (1<<4);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wBack");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "_TeamsMenu");
}

public Handle_TeamsMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			new pl[32], plnum, tempid;
			new prisoners[32], prnum;
			get_players(pl, plnum, "h");
			
			for (new i = 0; i < plnum; i++) {
				tempid = pl[i];
				if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER)
					continue;
				prisoners[prnum++] = tempid;
			}
			
			if (prnum == 0) {
				MJB_Print(id, "!nNo prisoners found");
				return FootballMenu(id);
			}
			
			for (new i = 0; i < prnum; i++) {
				tempid = prisoners[i];
				mjb_set_user_soccer(tempid);
				if (i % 2 == 0) //even then add to blue team
					mjb_set_user_mg_team(tempid, BLUE);
				else //odd then add to red team
					mjb_set_user_mg_team(tempid, RED);
					
			}
			MJB_Print(id, "!nSuccessfully divided prisoners into two teams");
		}
		case 1: {
			new target, body;
			get_user_aiming(id, target, body);
			if (!mjb_is_valid_player(target) || !is_user_alive(target) || GetTeam(target) != PRISONER)
				return PLUGIN_HANDLED;
			if (!mjb_set_user_soccer(target)) {
				MJB_Print(id, "Failed to set target to footballer");
				return PLUGIN_HANDLED;
			}
			mjb_set_user_mg_team(target, BLUE);
			MJB_Print(id, "Successfully set target team to blue");
		}
		case 2: {
			new target, body;
			get_user_aiming(id, target, body);
			if (!mjb_is_valid_player(target) || !is_user_alive(target) || GetTeam(target) != PRISONER)
				return PLUGIN_HANDLED;
			if (!mjb_set_user_soccer(target)) {
				MJB_Print(id, "Failed to set target to footballer");
				return PLUGIN_HANDLED;
			}
			mjb_set_user_mg_team(target, RED);
			MJB_Print(id, "Successfully set target team to red");
		}
		case 3: {
			new target, body;
			get_user_aiming(id, target, body);
			if (!mjb_is_valid_player(target) || !is_user_alive(target) || GetTeam(target) != PRISONER)
				return PLUGIN_HANDLED;
			
			if (mjb_get_state(target) != PRISONER_SOCCER)
				return PLUGIN_HANDLED;
			mjb_set_state(target, NORMAL);
			mjb_set_user_mg_team(target, 0);
			client_cmd(target, "spk MOON_JB/Soccer/clear.wav");
			MJB_Print(id, "Successfully cleared target team");
		}
		case 4: {
			ClearAllTeam(id)
		}
		case 9: {
			return FootballMenu(id);
		}
	}
	return TeamsMenu(id);
}

public ClearAllTeam(id) {
	new pl[32], plnum, tempid;
	get_players(pl, plnum, "h");
	
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER)
			continue;
		if (mjb_get_state(tempid) != PRISONER_SOCCER)
			continue;
		mjb_set_state(tempid, NORMAL);
		mjb_set_user_mg_team(tempid, 0);
		client_cmd(tempid, "spk MOON_JB/Soccer/clear.wav");
	}
	MJB_Print(id, "Successfully cleared all team");
}

/* =========================
   MENU: Wanted Prisoners
========================= */
public Cmd_WantedPrisonersMenu(id)
{
	ResetMenuPlayers(id);
	new pl[32], iPlayersNum;
	get_players(pl, iPlayersNum, "ah");
	
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if (pl[i] == id || !mjb_is_valid_player(pl[i]) || GetTeam(pl[i]) != PRISONER || mjb_get_state(pl[i]) != PRISONER_WANTED)
			continue;
	
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_WantedPrisonersMenu(id, g_iMenuPosition[id] = 0);
}

Show_WantedPrisonersMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	
	if(g_iMenuCount[id] == 0)
	{
		MJB_Print(id, "!nNo wanted prisoners found.");
		return SimonMenu(id);
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yWanted Prisoners \w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\y[%d] \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	
	return show_menu(id, iKeys, szMenu, -1, "WantedsMenu");
}

public Handle_WantedPrisonersMenu(id, iKey)
{
	if(!CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_WantedPrisonersMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_WantedPrisonersMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_WantedPrisonersMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || GetTeam(iTarget) != PRISONER || mjb_get_state(iTarget) != PRISONER_WANTED) return Show_WantedPrisonersMenu(id, g_iMenuPosition[id]);
		}
	}
	return Show_WantedPrisonersMenu(id, g_iMenuPosition[id]);
}

/* =========================
   MENU: ManagerPrisonerMenu
========================= */
public Show_ManagePrisonerMenu(id) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\r\wMOON JB \r| \yPrisoner Management^n^n", id);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \yGive\w/\rTake \wFree day^n", id);
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wHeal prisoners^n^n^n^n^n^n^n", id);
	iKeys |= (1<<2);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \yMute\w/\rUnmute \wprisoners Voice^n", id);
	iKeys |= (1<<2);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "ManagePrisonerMenu");
}

public Handle_ManagePrisonerMenu(id, iKeys) {
	if (!CanOpenSimonMenu(id))
		return PLUGIN_HANDLED;
	switch (iKeys) {
		case 0: {
			return Cmd_FreeDayControlMenu(id);
		}
		case 1: {
			return Cmd_TreatPrisonerMenu(id);
		}
		case 2: {
			return Cmd_VoiceControlMenu(id);
		}
		case 9: {
			return SimonMenu(id);
		}
	}
	return Show_ManagePrisonerMenu(id);
}

/* =========================
   MENU: Give/Take Freeday
========================= */
public Cmd_FreeDayControlMenu(id) {
	ResetMenuPlayers(id);
	new pl[32];
	new iPlayersNum;
	get_players(pl, iPlayersNum, "ah");
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if(pl[i] == id || !mjb_is_valid_player(pl[i]) || GetTeam(pl[i]) != PRISONER || (mjb_get_state(pl[i]) != NORMAL && mjb_get_state(pl[i]) != PRISONER_FREEDAY)) 
			continue;
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_FreeDayControlMenu(id, g_iMenuPosition[id] = 0);
}
Show_FreeDayControlMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenSimonMenu(id)) 
		return PLUGIN_HANDLED;
	
	if (mjb_get_day_type() == FREEDAY) {
		MJB_Print(id, "!nFreeday control disabled until next round.");
		return PLUGIN_HANDLED;
	} else if (mjb_get_phase() == PHASE_FREEDAY) {
		MJB_Print(id, "!nFreeday control disable until freeday end.");
		return PLUGIN_HANDLED;
	}
	
	show_menu(id, 0, "^n", 1);
	if(g_iMenuCount[id] == 0)
	{
		MJB_Print(id, "!nNo normal prisoners found.");
		return Show_ManagePrisonerMenu(id);
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yFreeday Management \w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s \r[%s]^n", ++b, szName, (mjb_get_state(tempid) == PRISONER_FREEDAY) ? "TAKE" : "GIVE");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	return show_menu(id, iKeys, szMenu, -1, "FreeDayControlMenu");
}

public Handle_FreeDayControlMenu(id, iKey)
{
	if(mjb_get_day_type() != NORMALDAY || mjb_get_phase() == PHASE_FREEDAY || !CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_FreeDayControlMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_FreeDayControlMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_FreeDayControlMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || GetTeam(iTarget) != PRISONER || (mjb_get_state(iTarget) != NORMAL && mjb_get_state(iTarget) != PRISONER_FREEDAY)) return Show_FreeDayControlMenu(id, g_iMenuPosition[id]);
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			if(is_user_alive(iTarget)) {
				if(mjb_get_state(iTarget) == PRISONER_FREEDAY)
				{
					MJB_Print(0, "!tSimon !g%s !tTook Freeday From !g%s", szName, szTargetName);
					mjb_set_state(iTarget, NORMAL);
				}
				else
				{
					MJB_Print(0, "!tSimon !g%s !tGave Freeday To !g%s", szName, szTargetName)
					mjb_set_user_freeday(iTarget);
				}
			} else {
				if(mjb_is_user_freeday_nextday(iTarget))
				{
					MJB_Print(0, "!tSimon !g%s !tTook Nextday Freeday From !g%s", szName, szTargetName);
					mjb_set_user_freeday_nextday(iTarget, MJB_False);
				}
				else
				{
					MJB_Print(0, "!tSimon !g%s !tGave Freeday To !g%s", szName, szTargetName)
					mjb_set_user_freeday_nextday(iTarget, MJB_True);
				}
			}
		}
	}
	return Show_FreeDayControlMenu(id, g_iMenuPosition[id]);
}

/* =========================
   MENU: Toggle Voice Menu
========================= */
public Cmd_VoiceControlMenu(id) {
	ResetMenuPlayers(id);
	new pl[32];
	new iPlayersNum;
	get_players(pl, iPlayersNum, "ah");
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if(pl[i] == id || !mjb_is_valid_player(pl[i]) || GetTeam(pl[i]) != PRISONER) 
			continue;
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_VoiceControlMenu(id, g_iMenuPosition[id] = 0);
}

Show_VoiceControlMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenSimonMenu(id)) 
		return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	if(g_iMenuCount[id] == 0)
	{
		return Show_ManagePrisonerMenu(id);
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yVoice Control \w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		if (get_user_flags(tempid) & ADMIN_MAP) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \d%s \rADMIN^n", ++b, szName);
		} else {
			iKeys |= (1<<b);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s \r[%s]^n", ++b, szName, (mjb_can_speak(tempid)) ? "DISABLE" : "ENABLE");
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	return show_menu(id, iKeys, szMenu, -1, "VoiceMenu");
}

public Handle_VoiceControlMenu(id, iKey)
{
	if(!CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_VoiceControlMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_VoiceControlMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_VoiceControlMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || GetTeam(iTarget) != PRISONER || !is_user_alive(iTarget)) 
				return Show_VoiceControlMenu(id, g_iMenuPosition[id]);
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			if (!mjb_can_speak(iTarget)) {
				mjb_enable_speaking(iTarget);
				MJB_Print(0, "!tSimon !g%s !tenabled speaking for prisoner !g%s!t.", szName, szTargetName);
			} else {
				mjb_disable_speaking(iTarget);
				MJB_Print(0, "!tSimon !g%s !tdisabled speaking for prisoner !g%s!t.", szName, szTargetName);
			}
		}
	}
	return Show_VoiceControlMenu(id, g_iMenuPosition[id]);
}

/* =========================
    MENU: Treat Prisoners
========================= */
public Cmd_TreatPrisonerMenu(id) {
	ResetMenuPlayers(id);
	new pl[32];
	new iPlayersNum;
	get_players(pl, iPlayersNum, "ah");
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if(pl[i] == id || !mjb_is_valid_player(pl[i]) || GetTeam(pl[i]) != PRISONER || !is_user_alive(pl[i])) 
			continue;
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_TreatPrisonerMenu(id, g_iMenuPosition[id] = 0);
}

Show_TreatPrisonerMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	if(g_iMenuCount[id] == 0)
	{
		MJB_Print(id, "!nNo alive prisoners found.");
		return Show_ManagePrisonerMenu(id);
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yHeal Prisoners \w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		if(pev(tempid, pev_health) >= 100.0) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \d%s^n", ++b, szName);
		} else {
			iKeys |= (1<<b);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s^n", ++b, szName);
		}
		
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	return show_menu(id, iKeys, szMenu, -1, "TreatMenu");
}

public Handle_TreatPrisonerMenu(id, iKey)
{
	if(!CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_TreatPrisonerMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_TreatPrisonerMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_TreatPrisonerMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || GetTeam(iTarget) != PRISONER || !is_user_alive(iTarget) || pev(iTarget, pev_health) >= 100.0) 
				return Show_TreatPrisonerMenu(id, g_iMenuPosition[id]);
			
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			set_pev(iTarget, pev_health, 100.0)
			MJB_Print(0, "!tSimon %s healed prisoner %s.", szName, szTargetName);
		}
	}
	return Show_TreatPrisonerMenu(id, g_iMenuPosition[id]);
}
/* =========================
    MENU: Transfer Simon
========================= */
public Cmd_TransferSimonMenu(id) {
	ResetMenuPlayers(id);
	new pl[32], iPlayersNum;
	get_players(pl, iPlayersNum, "ah");
	
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if (pl[i] == id || !mjb_is_valid_player(pl[i]) || GetTeam(pl[i]) != GUARD || !is_user_alive(pl[i]))
			continue;
	
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_TransferSimonMenu(id, g_iMenuPosition[id] = 0);
}

Show_TransferSimonMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenSimonMenu(id)) 
		return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	if(g_iMenuCount[id] == 0)
	{
		MJB_Print(id, "!nNo guards found.");
		return SimonMenu(id);
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yTransfer Simon \w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\y[%d] \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	
	return show_menu(id, iKeys, szMenu, -1, "TransferMenu");
}

public Handle_TransferSimonMenu(id, iKey)
{
	if(!CanOpenSimonMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_TransferSimonMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_TransferSimonMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_TransferSimonMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || GetTeam(iTarget) != GUARD || !is_user_alive(iTarget)) return Show_TransferSimonMenu(id, g_iMenuPosition[id]);
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			mjb_force_set_simon(iTarget);
			MJB_Print(id, "!gSimon was transferred to %s from %s", szTargetName, szName);
		}
	}
	return Show_TransferSimonMenu(id, g_iMenuPosition[id]);
}

stock printCenterHud(id, szMessage[64], Float:fDuration, any:...) {
	set_hudmessage(255, 234, 101, -1.0, 0.22, 0, 0.0, fDuration);
	new szBuffer[64];
	vformat(szBuffer, 63, szMessage, 3);
	ShowSyncHudMsg(id, g_iCenterHudSync, szBuffer);
}

stock ResetMenuPlayers(id)
{
    g_iMenuCount[id] = 0;

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        g_iMenuPlayers[id][i] = 0;
    }
}
