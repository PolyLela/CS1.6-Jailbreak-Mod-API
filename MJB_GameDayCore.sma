#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "GameDay Mode Core"
#define MAX_DAYMODES	15

new Array:g_DayModes;
new g_iDayModeTimer = -1;

new g_iDayModeVotes[MAX_DAYMODES];

/* Menu Related */
new g_iVoteMenuId, g_iMenuPosition[MAX_PLAYERS + 1];

/* Vote Variables */
new g_iChoosenDayMode[MAX_PLAYERS + 1];
new g_iElectedDayMode = -1; // This variable stores the winning day mode after vote and the reason it is -1 so if no one choosed and the variable still -1 normalday starts

/* Forwards */
new g_fwVoteResultsProcessed;
new g_fwDayModeEnded;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	g_DayModes = ArrayCreate(DayModeData);
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_PlayerSpawn_Post", true);
	g_fwVoteResultsProcessed = CreateMultiForward("mjb_vote_results_processed", ET_IGNORE, FP_CELL, FP_STRING);
	g_fwDayModeEnded = CreateMultiForward("mjb_daymode_ended", ET_IGNORE, FP_CELL, FP_STRING, FP_CELL);
	g_iVoteMenuId = register_menuid("Vote Menu ID");
	register_menucmd(g_iVoteMenuId, 1023, "Handle_VoteMenu");
}

public plugin_end() {
	if (g_DayModes != Invalid_Array) ArrayDestroy(g_DayModes);
}

/* Dynamic Registration Logic */
public plugin_natives() {
	register_library("MJB_Core");
	register_native("mjb_register_daymode", "native_register_daymode");
	register_native("mjb_get_current_daymode", "native_get_current_daymode");
	register_native("mjb_get_daymode_timer", "native_get_daymode_timer");
}

public native_register_daymode(plugin, params) {
	new data[DayModeData];
	get_string(1, data[DM_Name], charsmax(data[DM_Name]));
	get_string(2, data[DM_UID], charsmax(data[DM_UID]));
	data[DM_Time] = get_param(3);
	
	ArrayPushArray(g_DayModes, data);
	
	return ArraySize(g_DayModes) - 1;
}

public bool:native_get_current_daymode(plugin, params) {
	new data[DayModeData];
	// there is no daymode elected (maybe when phase isnt vote or its off-bounds)
	if (g_iElectedDayMode < 0 || g_iElectedDayMode >= ArraySize(g_DayModes)) {
		return false;
	}
		
	if (mjb_get_phase() != PHASE_GAMEDAY_ACTIVE)
		return false;
		
	ArrayGetArray(g_DayModes, g_iElectedDayMode, data);
	set_array(1, data, sizeof(data));
	return true;
}

public native_get_daymode_timer(plugin, params) {
	if (mjb_get_phase() != PHASE_GAMEDAY_ACTIVE)
		return -1;
	return g_iDayModeTimer;
}

/* Daymodes timer */
public StartDayModeTimer(iTime)
{
	if (iTime == -1)
		return;
	
	StopDayModeTimer();
	g_iDayModeTimer = mjb_start_timer(float(iTime));
}

public StopDayModeTimer()
{
	if (g_iDayModeTimer != -1)
	{
		mjb_stop_timer(g_iDayModeTimer);
		g_iDayModeTimer = -1;
	}
}

public mjb_timer_ended(iTimerId) {
	if (iTimerId == g_iDayModeTimer) {
		EndDayMode(0);
	}
}

public EndDayMode(iWinTeam) {
	if (g_iElectedDayMode < 0 || g_iElectedDayMode >= ArraySize(g_DayModes)) {
		return
	}
	StopDayModeTimer();
	new ret;
	new data[DayModeData];
	ArrayGetArray(g_DayModes, g_iElectedDayMode, data);
	ExecuteForward(g_fwDayModeEnded, ret, g_iElectedDayMode, data[DM_UID], iWinTeam); // basic win condition if there is any alive prisoner then prisoners won else guards won
	ResetDayModesVoteNum();
	g_iElectedDayMode = -1;
}

/* Vote Handling Logic */
public InitVote() {
	g_iElectedDayMode = -1;
	ResetDayModesVoteNum();
	ShowVoteMenuAll(true);
}

public ProcessVoteResults()
{
	new highestVotes = 0;
	
	new tiedModes[MAX_DAYMODES];
	new tiedCount = 0;
	
	// Find highest vote count
	for (new i = 0; i < ArraySize(g_DayModes); i++)
	{
		new votes = g_iDayModeVotes[i];
		
		if (votes > highestVotes)
		{
			highestVotes = votes;
		
			tiedModes[0] = i;
			tiedCount = 1;
		}
		else if (votes == highestVotes && votes > 0)
		{
			tiedModes[tiedCount++] = i;
		}
	}
		
	// Nobody voted
	if (highestVotes == 0)
	{
		g_iElectedDayMode = -1;
		
		new emptyUID[1];
		emptyUID[0] = EOS;
		
		new ret;
		ExecuteForward(g_fwVoteResultsProcessed, ret, -1, emptyUID);
		
		return;
	}
	
	// Pick random tied candidate fairly
	new randomIndex = random(tiedCount);
	g_iElectedDayMode = tiedModes[randomIndex];
	
	// Start timer
	new data[DayModeData];
	ArrayGetArray(g_DayModes, g_iElectedDayMode, data);
	
	StartDayModeTimer(data[DM_Time]);
	
	new ret;
	ExecuteForward(g_fwVoteResultsProcessed, ret, g_iElectedDayMode, data[DM_UID]);
}

public ResetDayModesVoteNum() {
	for (new i; i < sizeof(g_iDayModeVotes); i++) {
		g_iDayModeVotes[i] = 0;
	}
}

public IncrementDayModeVoteNum(index) {
	if (index < 0 || index >= ArraySize(g_DayModes))
		return;
	g_iDayModeVotes[index]++;
	ShowVoteMenuAll();
}

/* Events Determining Processes */
public client_disconnected(id) {
	if (g_iChoosenDayMode[id] != -1) {
		// this ensures that choosen day mode votes is subtracted by one but doesnt be negative ever
		g_iDayModeVotes[g_iChoosenDayMode[id]] = (g_iDayModeVotes[g_iChoosenDayMode[id]]-1 >= 0) ? g_iDayModeVotes[g_iChoosenDayMode[id]]-1 : 0;
	}
	g_iChoosenDayMode[id] = -1;
}

public mjb_timer_ticked(iTimerId, Float:fTimeleft) {
	if (iTimerId == mjb_get_vote_timer_id())
		ShowVoteMenuAll();
}

public RG_PlayerSpawn_Post(id) {
	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE) {
		FreezePlayer(id);
		BlindPlayer(id);
		CmdVoteMenu(id);
	}
}

public mjb_phase_changed(iOldPhase, iNewPhase) {
	if (iNewPhase == PHASE_GAMEDAY_VOTE) {
		InitVote();
	} else if (iNewPhase == PHASE_GAMEDAY_VOTE_ENDED) {
		Un_FreezeAndBlindAll();
		show_menu(0, 0, "^n", 1);
		ProcessVoteResults();
	} else if (iOldPhase == PHASE_GAMEDAY_ACTIVE && iNewPhase == PHASE_DAY_ENDED) {
		EndDayMode(GetTeamCount(PRISONER, true) ? PRISONER : GUARD);
	}
}

/* Menu Logic */
public CmdVoteMenu(id) {
	return ShowVoteMenu(id, g_iMenuPosition[id] = 0);
}

public ShowVoteMenu(id, iPos) {
	if (mjb_get_phase() != PHASE_GAMEDAY_VOTE)
		return PLUGIN_HANDLED;
	
	if (iPos < 0 )
		iPos = 0;
	
	new iMenuCount = ArraySize(g_DayModes);
	new iStart = iPos * ITEMS_PER_PAGE;
	if (iStart >= iMenuCount) iStart = iMenuCount - ITEMS_PER_PAGE;
	if (iStart < 0) iStart = 0;
	iStart -= (iStart % ITEMS_PER_PAGE);
	g_iMenuPosition[id] = iStart / ITEMS_PER_PAGE;
	new iEnd = iStart + ITEMS_PER_PAGE;
	if (iEnd > iMenuCount) iEnd = iMenuCount;
	new szMenu[512], iLen, iPagesNum = (iMenuCount / ITEMS_PER_PAGE + ((iMenuCount % ITEMS_PER_PAGE) ? 1 : 0));
	
	new iKeys = (1<<9), b = 0;
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \w| \yChoose a Game^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\dRemaining time: \d[\r%d\d] %d/%d^n", floatround(mjb_get_timer_timeleft(mjb_get_vote_timer_id())), iPos+1, iPagesNum);
	
	for(new a = iStart; a < iEnd; a++)
	{
		if (g_iChoosenDayMode[id] == -1) iKeys |= (1<<b);
		new data[DayModeData];
		ArrayGetArray(g_DayModes, a, data);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\r%d\d. %s%s \r[\y%d\r]^n", ++b, (g_iChoosenDayMode[id] != -1) ? "\d" : "\w", data[DM_Name], g_iDayModeVotes[a]);
	}
	
	for(new i = b; i < ITEMS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < iMenuCount)
	{
		iKeys |= (1<<ITEMS_PER_PAGE);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r9\d. \w%s^n\r0\d. \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r0\d. \w%s", iPos ? "Back" : "Exit");
	
	return show_menu(id, iKeys, szMenu, -1, "Vote Menu ID");
}

public Handle_VoteMenu(id, iKeys) {
	switch(iKeys)
	{
		case 8: {
			return ShowVoteMenu(id, ++g_iMenuPosition[id]);
		}
		case 9: return ShowVoteMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * ITEMS_PER_PAGE + iKeys;
			
			if(index >= ArraySize(g_DayModes))
				return ShowVoteMenu(id, g_iMenuPosition[id]);
				
			if(g_iChoosenDayMode[id] != -1)
				return PLUGIN_HANDLED;
			
			g_iChoosenDayMode[id] = index;
			IncrementDayModeVoteNum(index);
			new szDayModeName[32]
			GetDayModeName(index, szDayModeName, 31);
			MJB_Print(id, "!tYou have choosen !g%s!t.", szDayModeName);
		}
	}
	return ShowVoteMenu(id, g_iMenuPosition[id]);
}

public GetDayModeName(index, output[], len) {
	if (index < 0 || index >= ArraySize(g_DayModes))
		return;
		
	new data[DayModeData];
	ArrayGetArray(g_DayModes, index, data);
	copy(output, len, data[DM_Name]);
}

/* Player Related Logic */
public Un_FreezeAndBlindAll() {
	new pl[32], plnum, id;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		id = pl[i];
		if (!mjb_is_valid_player(id) || !is_user_alive(id))
			continue;
		UnFreezePlayer(id);
		UnBlindPlayer(id);
	}
}

ShowVoteMenuAll(bool:init=false) {
	new pl[32], plnum, id;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		id = pl[i];
		if (init) g_iChoosenDayMode[id] = -1;
		if (!mjb_is_valid_player(id) || !is_user_alive(id))
			continue;
		if (init) FreezePlayer(id);
		if (init) BlindPlayer(id);
		CmdVoteMenu(id);
	}
}