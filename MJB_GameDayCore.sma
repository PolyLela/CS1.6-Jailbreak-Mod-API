#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "GameDay Mode Core"

/* Static Daymodes */
#define DAYMODE_FREEDAY 	-2
#define DAYMODE_NORMALDAY	-1

/* Dynamic Daymodes Registration */
enum _:DayModeData {
	DM_Name[32],
	DM_UID[32],
	DM_VoteNum
};

new Array:g_DayModes;

/* Menu Related */
new g_iVoteMenuId, g_iMenuPosition[MAX_PLAYERS + 1];

/* Vote Variables */
new bool:g_bChoosedDayMode[MAX_PLAYERS + 1];
new g_iElectedDayMode = -1; // This variable stores the winning day mode after vote and the reason it is -1 so if no one choosed and the variable still -1 normalday starts

/* Forwards */
new g_fwVoteResultsProcessed;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	g_DayModes = ArrayCreate();
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_PlayerSpawn_Post", true);
	g_fwVoteResultsProcessed = CreateMultiForward("mjb_vote_results_processed", ET_IGNORE, FP_CELL);
	g_iVoteMenuId = register_menuid("Vote Menu ID");
	register_menucmd(g_iVoteMenuId, 1023, "Handle_VoteMenu");
}

public plugin_end() {
	ArrayDestroy(g_DayModes);
}

/* Dynamic Registration Logic */
public plugin_natives() {
	register_library("MJB_Core");
	register_native("mjb_register_daymode", "native_register_daymode");
}

public native_register_daymode(plugin, params) {
	new data[DayModeData];
	get_string(1, data[DM_Name], charsmax(data[DM_Name]));
	get_string(2, data[DM_UID], charsmax(data[DM_UID]));
	data[DM_VoteNum] = 0;
	
	ArrayPushArray(g_DayModes, data);
	
	return ArraySize(g_DayModes) - 1;
}

/* Vote Handling Logic */
public InitVote() {
	g_iElectedDayMode = -1;
	ResetDayModesVoteNum();
	InitVoteForEveryone();
}

public ProcessVoteResults() {
	new candidate, candidateVotes;
	new data[DayModeData];
	for (new i = 0; i < ArraySize(g_DayModes); i++) {
		ArrayGetArray(g_DayModes, i, data);
		if (data[DM_VoteNum] > candidateVotes) {
			candidate = i;
			candidateVotes = data[DM_VoteNum];
		} else if (data[DM_VoteNum] == candidateVotes) {
			if (random_num(1,2) == 1) {
				candidate = i;
				candidateVotes = data[DM_VoteNum];
			}
		}
	}
	//Meaning that nothing is choosen because if there is a thing choosen votes will be atleast 1
	if (candidateVotes == 0)
		candidate = -1;
	g_iElectedDayMode = candidate;
	new ret;
	ExecuteForward(g_fwVoteResultsProcessed, ret, g_iElectedDayMode);
}

public ResetDayModesVoteNum() {
	new data[DayModeData];
	for (new i = 0; i < ArraySize(g_DayModes); i++) {
		ArrayGetArray(g_DayModes, i, data);
		data[DM_VoteNum] = 0;
		ArraySetArray(g_DayModes, i, data);
	}
}

public IncreamentDayModeVoteNum(index) {
	new data[DayModeData];
	ArrayGetArray(g_DayModes, index, data);
	data[DM_VoteNum]++;
	ArraySetArray(g_DayModes, index, data);
}

/* Events Determining Processes */
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
		ProcessVoteResults();
	}
}

/* Menu Logic */
public CmdVoteMenu(id) {
	return ShowVoteMenu(id, g_iMenuPosition[id] = 0);
}

public ShowVoteMenu(id, iPos) {
	if (iPos < 0 || mjb_get_phase() != PHASE_GAMEDAY_VOTE)
		return PLUGIN_HANDLED;
	
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
		if (!g_bChoosedDayMode[id]) iKeys |= (1<<b);
		new data[DayModeData];
		ArrayGetArray(g_DayModes, a, data);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\r%d\d. %s%s \r[\y%d\r]^n", ++b, (g_bChoosedDayMode) ? "\w" : "\d", data[DM_Name], data[DM_VoteNum]);
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
			
			g_bChoosedDayMode[id] = true;
			IncreamentDayModeVoteNum(index);
			new szDayModeName[32]
			GetDayModeName(index, szDayModeName, 31);
			MJB_Print(id, "!tYou have choosen !g%s!t.", szDayModeName);
		}
	}
	return ShowVoteMenu(id, g_iMenuPosition[id]);
}

public GetDayModeName(index, output[], len) {
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

public InitVoteForEveryone() {
	new pl[32], plnum, id;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		id = pl[i];
		g_bChoosedDayMode[id] = false;
		if (!mjb_is_valid_player(id) || !is_user_alive(id))
			continue;
		FreezePlayer(id);
		BlindPlayer(id);
		CmdVoteMenu(id);
	}
}

public BlindPlayer(id) {
	UTIL_ScreenFade(id, 0, 0, 4, 0, 0, 0, 255);
}

public UnBlindPlayer(id) {
	UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
}

public FreezePlayer(id) {
	new flags = pev(id, pev_flags);
	if (IsFreezed(id))
		return;
	flags |= FL_FROZEN;
	set_pev(id, pev_flags, flags);
	set_member(id, m_flNextAttack, mjb_get_timer_timeleft(mjb_get_vote_timer_id()));
}

public UnFreezePlayer(id) {
	new flags = pev(id, pev_flags);
	if (!IsFreezed(id))
		return;
	flags &= ~FL_FROZEN;
	set_pev(id, pev_flags, flags);
	set_member(id, m_flNextAttack, 0.0);
}

public bool:IsFreezed(id) {
	if (pev(id, pev_flags) & FL_FROZEN)
		return true;
	return false;
}

