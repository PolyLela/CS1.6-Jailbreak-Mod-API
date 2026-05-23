/* TODO
	Restructure FreedayNextday and ChoosePrisonerLast
	Boxing State
*/
#include <amxmodx>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "PlayerStates"

#define TASK_PROCESS_FREEDAY 5489

/* =========================
   GLOBAL DATA
========================= */
enum 
{
	DATA_STATE,
	DATA_MG_TEAM,
	DATA_NUM
};

new g_PlayerData[MAX_PLAYERS + 1][DATA_NUM];

/* Forwards */
new g_fwStateChanged;
new g_fwMinigamesTeamChanged;

new g_iPlayerMinigamesTeam[MAX_PLAYERS + 1];
new bool:g_bNextdayFreeday[MAX_PLAYERS + 1];
/* =========================
   PLUGIN INIT
========================= */
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	/* Hooks */
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "OnPlayerTraceAttack_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled_Post", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", true);

	/* Forwards */
	g_fwStateChanged		 = CreateMultiForward("mjb_state_changed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	if (g_fwStateChanged == -1) {
		log_error(AMX_ERR_NATIVE, "Failed to CreateMultiForward");
	}
	g_fwMinigamesTeamChanged = CreateMultiForward("mjb_minigames_team_changed", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_precache()
{
	precache_sound("MOON_JB/MOON_wanted.wav");
}

/* =========================
   EVENTS
========================= */
public client_putinserver(id)
{
	SetPlayerState(id, NORMAL);
	SetPlayerMinigamesTeam(id, 0);
}

public client_disconnected(id)
{
	SetPlayerState(id, NORMAL);
	SetPlayerMinigamesTeam(id, 0);
	if (GetTeam(id) == PRISONER)
		set_task(0.1, "ChoosePrisonerLast");
}

public mjb_phase_changed(iOldPhase, iNewPhase)
{
	if (iNewPhase == PHASE_DAY_STARTED && iOldPhase != PHASE_DAY_STARTED)
		OnDayStart();
	
	if (iNewPhase == PHASE_DAY_ENDED && iOldPhase != PHASE_DAY_ENDED)
		OnDayEnd();

	if (iOldPhase == PHASE_GAMEDAY_NORMAL) {
		if (task_exists(TASK_PROCESS_FREEDAY))
			remove_task(TASK_PROCESS_FREEDAY);
		
		set_task(1.0, "ProcessFreedayNextday", TASK_PROCESS_FREEDAY);
	}
}

public OnDayStart()
{
	SetAllState(NORMAL);
	ResetEveryoneMinigamesTeam();
	if (GetTeamCount(PRISONER, false) == 1)
		set_task(1.0, "ChoosePrisonerLast");
	set_task(1.0, "ProcessFreedayNextday", TASK_PROCESS_FREEDAY);
}

public OnDayEnd()
{
	SetAllState(NORMAL);
	ResetEveryoneMinigamesTeam();
}

public OnPlayerTraceAttack_Pre(pevVictim, pevAttacker, Float:flDamage, Float:vecDir[3], tracehandle, bitsDamageType)
{
	if (!mjb_is_valid_player(pevAttacker) || pevVictim == pevAttacker)
		return;

	SetPlayerWanted(pevVictim, pevAttacker);
}

public OnPlayerKilled_Post(pevVictim, pevAttacker, iGib)
{
	SetPlayerState(pevVictim, NORMAL);
	SetPlayerWanted(pevVictim, pevAttacker);
	if (GetTeam(pevVictim) == PRISONER)
		set_task(0.1, "ChoosePrisonerLast");
}

public OnPlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		SetPlayerState(id, NORMAL);
		SetPlayerMinigamesTeam(id, 0);
		if (GetTeam(id) == PRISONER && !(mjb_get_phase() == PHASE_DAY_STARTED && GetTeamCount(PRISONER, false) > 1))
			set_task(0.5, "ChoosePrisonerLast");
	}
}

/* =========================
   CORE: STATE SYSTEM
========================= */
public ProcessFreedayNextday()
{
	/*if (mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
		return;

	for (new id = 1; id <= MAX_PLAYERS; id++)
	{
		if (!mjb_is_valid_player(id) || !is_user_alive(id) || GetTeam(id) != PRISONER || !g_bNextdayFreeday[id])
			continue;
		g_bNextdayFreeday[id] = false;
		SetPlayerState(id, PRISONER_FREEDAY);
	}*/
}

public ChoosePrisonerLast()
{
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	new lastPn = 0;
	new pnum = 0;
	for (new i = 0; i < plnum; i++)
	{
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER)
			continue;

		pnum++;
		lastPn = tempid;
	}

	if (pnum > 1)
		return;
	SetPlayerLast(lastPn);
}

public FindPrisonerLast()
{
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	new lastPn = 0;
	for (new i = 0; i < plnum; i++)
	{
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != PRISONER)
			continue;

		if (GetPlayerState(tempid) == PRISONER_LAST)
			lastPn = tempid;
	}
	return lastPn;
}

public SetPlayerState(id, iState)
{
	if (iState < NORMAL || iState >= STATES_NUM)
		return false;

	/*This variable should prevent runtime error 10 "invalid player or entity" by ReGameDLL*/
	new team = (mjb_is_valid_player(id)) ? GetTeam(id) : UNASSIGNED;

	if (team == GUARD && iState > NORMAL)
	{
		return false;
	}

	if (mjb_is_valid_player(id) && GetPlayerState(id) == PRISONER_LAST && is_user_alive(id))
	{
		return false;
	}

	new OldState = g_PlayerData[id][DATA_STATE];
	g_PlayerData[id][DATA_STATE] = iState;
	Forward_StateChanged(id, OldState);
	return true;
}

public GetPlayerState(id)
{
	return g_PlayerData[id][DATA_STATE];
}

public SetPlayerLast(id)
{
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return false;

	if (GetTeamCount(PRISONER, true) > 1 || GetTeamCount(GUARD, false) <= 0)
	{
		return false;
	}

	if (mjb_get_phase() == PHASE_GAMEDAY_ACTIVE  || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
		return false;
	
	if (GetTeam(id) != PRISONER || GetPlayerState(id) == PRISONER_LAST)
		return false;

	// if found a last prisoner
	new lastPn = FindPrisonerLast();
	if (mjb_is_valid_player(lastPn))
	{
		return false;
	}

	if (!SetPlayerState(id, PRISONER_LAST))
		return false;
	
	return true;
}

public SetPlayerWanted(victim, attacker)
{
	if (victim == attacker || !mjb_is_valid_player(attacker) || !is_user_alive(attacker))
		return false;

	if (GetTeam(victim) != GUARD || GetTeam(attacker) != PRISONER)
		return false;

	if (GetPlayerState(attacker) == PRISONER_WANTED || GetPlayerState(attacker) == PRISONER_LAST)
		return false;
	
	if (mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
		return false;
	
	SetPlayerState(attacker, PRISONER_WANTED);
	emit_sound(0, CHAN_AUTO, "MOON_JB/MOON_wanted.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return true;
}

public SetPlayerFreeday(id)
{
	if (!mjb_is_valid_player(id))
		return false;

	if (mjb_get_day_type() == FREEDAY || mjb_get_phase() == PHASE_FREEDAY || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE)
		return true;

	if (!is_user_alive(id))
		return false;

	if (GetTeam(id) != PRISONER)
		return false;

	if (GetPlayerState(id) != NORMAL && GetPlayerState(id) != PRISONER_BOXING && GetPlayerState(id) != PRISONER_SOCCER)
		return false;

	SetPlayerState(id, PRISONER_FREEDAY);
	return true;
}

public SetPlayerBoxing(id)
{
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return false;

	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) 
		return false;

	if (GetTeam(id) != PRISONER)
		return false;

	if (GetPlayerState(id) != NORMAL && GetPlayerState(id) != PRISONER_SOCCER)
		return false;

	SetPlayerState(id, PRISONER_BOXING);
	return true;
}

public SetPlayerSoccer(id)
{
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return false;

	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) 
		return false;

	if (GetTeam(id) != PRISONER)
		return false;

	if (GetPlayerState(id) != NORMAL && GetPlayerState(id) != PRISONER_BOXING)
		return false;

	SetPlayerState(id, PRISONER_SOCCER);
	return true;
}

public SetPlayerMinigamesTeam(id, iMinigamesTeam)
{
	g_iPlayerMinigamesTeam[id] = iMinigamesTeam;
	Forward_MinigamesTeamChanged(id);
	return true;
}

public GetPlayerMinigamesTeam(id)
{
	return g_iPlayerMinigamesTeam[id];
}

public GetMinigamesTeamCount(iMinigamesTeam)
{
	new iCount = 0;
	for (new i = 1; i <= MAX_PLAYERS; i++)
	{
		if (g_iPlayerMinigamesTeam[i] != iMinigamesTeam)
			continue;
		iCount++;
	}
	return iCount;
}

public ResetEveryoneMinigamesTeam()
{
	for (new i = 1; i <= MAX_PLAYERS; i++)
	{
		SetPlayerMinigamesTeam(i, 0);
	}
}

public SetAllState(iState)
{
	for (new id = 1; id <= MAX_PLAYERS; id++)
	{
		SetPlayerState(id, iState);
	}
}

/* =========================
   FORWARDS
=========================*/
public Forward_StateChanged(id, OldState)
{
	new ret;
	ExecuteForward(g_fwStateChanged, ret, id, OldState, g_PlayerData[id][DATA_STATE]);
}

public Forward_MinigamesTeamChanged(id)
{
	new ret;
	ExecuteForward(g_fwMinigamesTeamChanged, ret, id, g_iPlayerMinigamesTeam[id]);
}

/* =========================
   PLUGIN NATIVES
========================= */
public plugin_natives()
{
	register_library("MJB_Core");


	register_native("mjb_set_state", "native_mjb_set_state");
	register_native("mjb_find_last_prisoner", "native_find_last_prisoner")
	register_native("mjb_get_state", "native_mjb_get_state");
	register_native("mjb_set_user_soccer", "native_set_user_soccer");
	register_native("mjb_set_user_boxing", "native_set_user_boxing");
	register_native("mjb_set_user_freeday", "native_set_user_freeday");
	register_native("mjb_set_user_freeday_nextday", "native_set_user_freeday_nextday");
	register_native("mjb_is_user_freeday_nextday", "native_is_user_freeday_nextday");
	register_native("mjb_set_user_mg_team", "native_set_user_mg_team");
	register_native("mjb_get_user_mg_team", "native_get_user_mg_team");
	register_native("mjb_get_mg_team_count", "native_get_mg_team_count");
	register_native("mjb_set_all_state", "native_set_all_state");
}

public native_mjb_set_state()
{
	new id	   = get_param(1);
	new iState = get_param(2);
	return SetPlayerState(id, iState);
}

public native_find_last_prisoner() {
	new lastPn = FindPrisonerLast();
	if (!mjb_is_valid_player(lastPn))
		return -1;
	return lastPn;
}

public native_mjb_get_state()
{
	new id = get_param(1);
	return GetPlayerState(id);
}

public native_set_user_soccer()
{
	new id = get_param(1);
	return SetPlayerSoccer(id);
}

public native_set_user_boxing()
{
	new id = get_param(1);
	return SetPlayerBoxing(id);
}

public native_set_user_freeday()
{
	new id = get_param(1);
	return SetPlayerFreeday(id);
}

public native_set_user_freeday_nextday()
{
	new id		= get_param(1);
	new bool:bToggle = bool:get_param(2);
	if (!mjb_is_valid_player(id) || GetTeam(id) != PRISONER)
		return 0;
	g_bNextdayFreeday[id] = bToggle;
	return 1;
}

public native_is_user_freeday_nextday()
{
	new id = get_param(1);
	if (!mjb_is_valid_player(id) || GetTeam(id) != PRISONER)
		return 0;
	return g_bNextdayFreeday[id];
}

public native_set_user_mg_team()
{
	new id			   = get_param(1);
	new iMinigamesTeam = get_param(2);
	return SetPlayerMinigamesTeam(id, iMinigamesTeam);
}

public native_get_user_mg_team()
{
	new id = get_param(1);
	return GetPlayerMinigamesTeam(id);
}

public native_get_mg_team_count()
{
	new iMinigamesTeam = get_param(1);
	return GetMinigamesTeamCount(iMinigamesTeam);
}

public native_set_all_state()
{
	new iState = get_param(1);
	SetAllState(iState);
}
