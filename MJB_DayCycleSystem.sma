/*
	Todo:
	Force map change on DayEnd when rounds reach 15 (if someone played with cvars the whole server will look ambigous)
	Also Connect that with (Vote Map System (still didnt made))
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "Days State System FSM"
#define DAY_END_TASK		7124
#define TASK_TOGGLE_CELL	2174
#define FREEDAY_TIME		240.0
#define SELECT_SIMON_TIME	30.0
#define VOTE_TIME			15.0

new const DayTypes[MAX_DAYS + 1] = {
    -1,
    FREEDAY, GAMEDAY, NORMALDAY, NORMALDAY,
    GAMEDAY,
    NORMALDAY, NORMALDAY, NORMALDAY, NORMALDAY,
    NORMALDAY, NORMALDAY,
    GAMEDAY,
    NORMALDAY, NORMALDAY,
    FREEDAY
};

/* Blockage Behaviour */
new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle",
	"func_tracktrain",
	"func_tank",
	"game_player_hurt",
	"func_recharge",
	"func_healthcharger",
	"game_player_equip",
	"player_weaponstrip",
	//"func_button",
	"trigger_hurt",
	"trigger_gravity",
	"armoury_entity",
	"weaponbox",
	"weapon_shield"
};
new HamHook:g_iHamHookForwards[14];

new g_iPhase = -1;
new g_iFreePhaseCount;
new bool:g_bManyFreeEnabled = true;

new g_iFreedayTimer = -1;
new g_iSimonTimer  = -1;
new g_iVoteTimer  = -1;

new g_fwPhaseChanged;
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	set_cvar_num("mp_maxrounds", MAX_DAYS);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundStart", true);
	RegisterHookChain(RG_RoundEnd, "OnRoundEnd", true);
	for(new i; i <= 8; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	g_fwPhaseChanged = CreateMultiForward("mjb_phase_changed", ET_IGNORE, FP_CELL, FP_CELL);
	OnRoundStart();
}

public plugin_precache() {
	precache_model("models/MOON_JB/MOON_JB_v_round_sound.mdl");
}

/* =========================
   FSM CORE
========================= */

public ChangePhase(newPhase)
{
	if (g_iPhase == newPhase)
		return;
	
	new iOldPhase = g_iPhase;
	g_iPhase = newPhase;
	new ret;
	ExecuteForward(g_fwPhaseChanged, ret, iOldPhase, g_iPhase);
	switch (newPhase)
	{
		case PHASE_DAY_STARTED:
		{
			g_iFreePhaseCount = 0;
			
			switch (GetDayType(GetDay()))
			{
				case FREEDAY:   ChangePhase(PHASE_FREEDAY);
				case NORMALDAY: {
					if (!mjb_simon_exists()) ChangePhase(PHASE_SIMON_SELECT);
					else ChangePhase(PHASE_NORMAL);
				}
				case GAMEDAY:   ChangePhase(PHASE_GAMEDAY_VOTE);
			}
		}
		
		case PHASE_FREEDAY:
		{
			StopSimonTimer();
			StartFreedayTimer();
			if (task_exists(TASK_TOGGLE_CELL)) remove_task(TASK_TOGGLE_CELL);
			set_task(0.3, "TaskOpenCell", TASK_TOGGLE_CELL)
		}
		
		case PHASE_FREE_ENDED:
		{
			if (task_exists(TASK_TOGGLE_CELL)) remove_task(TASK_TOGGLE_CELL);
			set_task(0.3, "TaskCloseCell", TASK_TOGGLE_CELL)
			
			if (!mjb_simon_exists())
				ChangePhase(PHASE_SIMON_SELECT);
			else
				ChangePhase(PHASE_NORMAL);
		}
		
		case PHASE_SIMON_SELECT:
		{
			StopFreedayTimer();
			StartSimonTimer();
		}
		
		case PHASE_SELECT_ENDED:
		{
			if (!mjb_simon_exists())
			{
				if (!g_bManyFreeEnabled && g_iFreePhaseCount >= 1)
					ChangePhase(PHASE_SIMON_NOT_SELECTED);
				else
					ChangePhase(PHASE_FREEDAY);
			}	
			else
			{
				ChangePhase(PHASE_NORMAL);
			}
		}
		
		case PHASE_NORMAL:
		{
			StopAllTimers();
		}
		
		case PHASE_DAY_ENDED:
		{
			StopAllTimers();
		}
		
		case PHASE_SIMON_KILLED, PHASE_SIMON_DISCONNECTED:
		{
			if (mjb_simon_exists())
				ChangePhase(PHASE_NORMAL);
		}
		
		case PHASE_GAMEDAY_NORMAL:
		{
			if (!mjb_simon_exists()) ChangePhase(PHASE_SIMON_SELECT);
			else ChangePhase(PHASE_NORMAL);
		}

		case PHASE_GAMEDAY_VOTE:
		{
			StartVoteTimer();
		}
	}
	
}

/* =========================
   TIMER CONTROL
========================= */
public StartVoteTimer()
{
	StopVoteTimer();
	g_iVoteTimer = mjb_start_timer(VOTE_TIME);
}

public StartFreedayTimer()
{
	StopFreedayTimer();
	g_iFreedayTimer = mjb_start_timer(FREEDAY_TIME);
}

public StartSimonTimer()
{
	StopSimonTimer();
	g_iSimonTimer = mjb_start_timer(SELECT_SIMON_TIME);
}

public StopVoteTimer()
{
	if (g_iVoteTimer != -1)
	{
		mjb_stop_timer(g_iVoteTimer);
		g_iVoteTimer = -1;
	}
}

public StopFreedayTimer()
{
	if (g_iFreedayTimer != -1)
	{
		mjb_stop_timer(g_iFreedayTimer);
		g_iFreedayTimer = -1;
	}
}

public StopSimonTimer()
{
	if (g_iSimonTimer != -1)
	{
		mjb_stop_timer(g_iSimonTimer);
		g_iSimonTimer = -1;
	}
}

public StopAllTimers()
{
	StopFreedayTimer();
	StopSimonTimer();
	StopVoteTimer();
}

/* =========================
   EVENTS
========================= */
public OnRoundStart()
{
	UnblockGameBehaviour();
	ChangePhase(PHASE_DAY_STARTED);
}

public OnRoundEnd()
{
	StopAllTimers();
	ChangePhase(PHASE_DAY_ENDED);
	mjb_close_cell();
	if (!task_exists(DAY_END_TASK))
		set_task(0.1, "DayEnd");
}

public DayEnd() {
	BlockGameBehaviour();
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		client_cmd(i, "mp3 stop");
		static iszViewModel = 0; //get the model one time
		if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/MOON_JB/MOON_JB_v_round_sound.mdl")))
			set_pev_string(i, pev_viewmodel2, iszViewModel);
		set_member(i, m_flNextAttack);
		UTIL_WeaponAnimation(i, 0);
	}
}

public mjb_timer_ended(iTimer)
{
	if (iTimer == g_iFreedayTimer)
	{
		g_iFreedayTimer = -1;
		g_iFreePhaseCount++;
		ChangePhase(PHASE_FREE_ENDED);
	}
	else if (iTimer == g_iSimonTimer)
	{
		g_iSimonTimer = -1;
		ChangePhase(PHASE_SELECT_ENDED);
	}
	else if (iTimer == g_iVoteTimer)
	{
		ChangePhase(PHASE_GAMEDAY_VOTE_ENDED)
	}
}

public mjb_vote_results_processed(iResult) {
	switch(iResult) {
		case -1: ChangePhase(PHASE_GAMEDAY_NORMAL);
		default: ChangePhase(PHASE_GAMEDAY_ACTIVE);
	}
}

public mjb_daymode_ended(iDayMode, DayModeUID[], iWinTeam) {
	new WinStatus:ws, ScenarioEventEndRound:rg;
	switch (iWinTeam) {
		case PRISONER: {
			ws = WINSTATUS_TERRORISTS;
			rg = ROUND_TERRORISTS_WIN;
			
		}
		case GUARD: {
			ws = WINSTATUS_CTS;
			rg = ROUND_CTS_WIN;
			
		}
		default: {
			ws = WINSTATUS_DRAW
			rg = ROUND_GAME_OVER
		}
	}
	rg_round_end(5.0, ws, rg, _, _, true);
}

public mjb_simon_set(id)
{
	if (g_iPhase == PHASE_SIMON_SELECT || g_iPhase == PHASE_SIMON_NOT_SELECTED || g_iPhase == PHASE_SIMON_KILLED || g_iPhase == PHASE_SIMON_DISCONNECTED)
		ChangePhase(PHASE_SELECT_ENDED);
}

public mjb_simon_died(id)
{
	if (g_iPhase == PHASE_NORMAL)
		ChangePhase(PHASE_SIMON_KILLED);
}

public mjb_simon_disconnected(id)
{
	if (g_iPhase == PHASE_NORMAL)
		ChangePhase(PHASE_SIMON_DISCONNECTED);
}

/* =========================
   DAY SYSTEM
========================= */
public GetDay()
{
	return get_member_game(m_iTotalRoundsPlayed) + 1;
}

public GetDayType(iDay)
{
	return DayTypes[iDay];
}

/* =========================
   API
========================= */
public plugin_natives() {
	register_library("MJB_Core");
	register_native("mjb_start_freeday", "native_start_freeday");
	register_native("mjb_end_freeday", "native_end_freeday");
	register_native("mjb_end_gameday_vote", "native_end_gameday_vote");
	register_native("mjb_get_day", "native_get_day");
	register_native("mjb_get_day_type", "native_get_day_type");
	register_native("mjb_get_phase", "native_get_phase");
	register_native("mjb_get_free_timer_id", "native_get_free_timer_id");
	register_native("mjb_get_simon_timer_id", "native_get_simon_timer_id");
	register_native("mjb_get_vote_timer_id", "native_get_vote_timer_id");
	register_native("mjb_block_game_behaviour", "BlockGameBehaviour", 1);
	register_native("mjb_unblock_game_behaviour", "UnblockGameBehaviour", 1);
}

public native_end_gameday_vote() {
	if (g_iPhase != PHASE_GAMEDAY_VOTE)
		return;
	new vote = get_param(1);
	switch(vote) {
		case 0 : ChangePhase(PHASE_GAMEDAY_NORMAL);
		case 1 : ChangePhase(PHASE_FREEDAY);
		case 2 : ChangePhase(PHASE_GAMEDAY_ACTIVE);
	}
}

public native_start_freeday() {
	if (GetDayType(GetDay()) == FREEDAY || g_iFreePhaseCount >= 1)
		return MJB_False;
	ChangePhase(PHASE_FREEDAY);
	return MJB_True;
}

public native_end_freeday() {
	if (GetDayType(GetDay()) == FREEDAY || g_iPhase != PHASE_FREEDAY)
		return MJB_False;
	
	StopFreedayTimer();
	g_iFreePhaseCount++;
	ChangePhase(PHASE_FREE_ENDED);
	return MJB_True;
}

public native_get_day() {
	return GetDay();
}

public native_get_day_type() {
	return GetDayType(GetDay());
}

public native_get_phase() {
	return g_iPhase;
}

public native_get_free_timer_id() {
	return g_iFreedayTimer;
}

public native_get_simon_timer_id() {
	return g_iSimonTimer;
}

public native_get_vote_timer_id() {
	return g_iVoteTimer;
}

public UnblockGameBehaviour() {
	for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
}

public BlockGameBehaviour() {
	for(new i; i < charsmax(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
}

public HamHook_EntityBlock(iEntity, id)
{
	return HAM_SUPERCEDE;
}

public TaskOpenCell() {
	mjb_open_cell()
}

public TaskCloseCell() {
	mjb_close_cell()
}