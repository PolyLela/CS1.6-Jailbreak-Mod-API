/* TODO
	Use Source of truth for any Day-related events from DayCycleSystem
	👍Make SetPlayerWanted + Check on Killed because maybe player killed player without touching like when throwing grenades
	👍 Add Phase Check on SetPlayerWanted for GAMEDAY IMPORTANTTTTTTTTTTTTTTTTT
*/
#include <amxmodx>
#include <reapi>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "PlayerStates"

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
new g_bNextdayFreeday[MAX_PLAYERS + 1];
/* =========================
   PLUGIN INIT
========================= */
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	/* Events */
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRoundStart", true);

	/* Hooks */
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "OnPlayerTraceAttack_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled_Post", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", true);

	/* Forwards */
	g_fwStateChanged		 = CreateMultiForward("mjb_state_changed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_fwMinigamesTeamChanged = CreateMultiForward("mjb_minigames_team_changed", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_precache()
{
	precache_sound("MOON_JB/MOON_wanted.wav");
}

/* =========================
   PLUGIN NATIVES
========================= */
public plugin_natives()
{
	register_library("MJB_Core");

	register_native("mjb_set_state", "native_mjb_set_state");
	register_native("mjb_get_state", "native_mjb_get_state");
	register_native("mjb_set_user_soccer", "native_set_user_soccer");
	register_native("mjb_set_user_boxing", "native_set_user_boxing");
	register_native("mjb_set_user_freeday", "native_set_user_freeday");
	register_native("mjb_set_user_freeday_nextday", "native_set_user_freeday_nextday");
	register_native("mjb_is_user_freeday_nextday", "native_is_user_freeday_nextday");
	register_native("mjb_set_user_mg_team", "native_set_user_mg_team");
	register_native("mjb_get_user_mg_team", "native_get_user_mg_team");
	register_native("mjb_get_mg_team_count", "native_get_mg_team_count");
	register_native("mjb_set_all_state", "native_mjb_set_all_state");
}

public native_mjb_set_state()
{
	new id	   = get_param(1);
	new iState = get_param(2);
	return SetPlayerState(id, iState);
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
	new bToggle = get_param(2);
	if (!mjb_is_valid_player(id) || GetTeam(id) != TEAM_TERRORIST)
		return 0;
	g_bNextdayFreeday[id] = bToggle;
	return 1;
}

public native_is_user_freeday_nextday()
{
	new id = get_param(1);
	if (!mjb_is_valid_player(id) || GetTeam(id) != TEAM_TERRORIST)
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

/* =========================
   EVENTS
========================= */
public client_putinserver(id)
{
	SetPlayerState(id, NORMAL);
}

public client_disconnected(id)
{
	SetPlayerState(id, NORMAL);
	set_task(0.1, "ChoosePrisonerLast");
}

public OnRoundStart()
{
	for (new id = 1; id <= MAX_PLAYERS; id++)
	{
		SetPlayerState(id, NORMAL);
	}
	set_task(1.0, "ChoosePrisonerLast");
	set_task(1.0, "ProcessFreedayNextday", 50);
}

public mjb_phase_changed(iOldPhase, iNewPhase)
{
	if (iOldPhase != PHASE_GAMEDAY_ACTIVE && iOldPhase != PHASE_GAMEDAY_VOTE)
		return;
	if (iNewPhase != PHASE_DAY_ENDED)
		return;
	remove_task(50);
	set_task(1.0, "ProcessFreedayNextday", 50);
}

public OnPlayerTraceAttack_Pre(pevVictim, pevAttacker, Float:flDamage, Float:vecDir[3], tracehandle, bitsDamageType)
{
	if (!mjb_is_valid_player(pevAttacker) || pevVictim == pevAttacker)
		return HAM_IGNORED;

	SetPlayerWanted(pevVictim, pevAttacker);

	return HAM_IGNORED;
}

public OnPlayerKilled_Post(pevVictim, pevAttacker, iGib)
{
	SetPlayerState(pevVictim, NORMAL);
	SetPlayerWanted(pevVictim, pevAttacker);
	set_task(0.1, "ChoosePrisonerLast");
}

public OnPlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		SetPlayerState(id, NORMAL);
		g_iPlayerMinigamesTeam[id]	 = NONE;
		set_task(0.5, "ChoosePrisonerLast");
	}
}

/* =========================
   CORE: STATE SYSTEM
========================= */
public ProcessFreedayNextday()
{
	//if (mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
	//	return;

	for (new id = 1; id < MAX_PLAYERS; id++)
	{
		if (!mjb_is_valid_player(id) || !is_user_alive(id) || GetTeam(id) != TEAM_TERRORIST || !g_bNextdayFreeday[id])
			continue;
		g_bNextdayFreeday[id] = MJB_False;
		SetPlayerState(id, PRISONER_FREEDAY);
	}
}

public ChoosePrisonerLast()
{
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	new lastPn = 0;
	for (new i = 0; i < plnum; i++)
	{
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !is_user_alive(tempid) || GetTeam(tempid) != TEAM_TERRORIST || g_bNextdayFreeday[tempid])
			continue;

		lastPn = tempid;
	}

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
		if (!mjb_is_valid_player(tempid) || !IsPlayerAlive(tempid) || GetTeam(tempid) != TERRORIST)
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

	if (GetTeam(id) == TEAM_CT && iState > NORMAL)
	{
		return false;
	}

	if (GetPlayerState(id) == PRISONER_LAST && is_user_alive(id))
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

	if (GetTeamCount(TEAM_TERRORIST, MJB_True) > 1 || GetTeamCount(TEAM_CT, MJB_True) <= 0)
	{
		return false;
	}
	//Removed Temporarily
	// mjb_get_phase() == PHASE_GAMEDAY_ACTIVE  || mjb_get_phase() == PHASE_GAMEDAY_VOTE
	if (GetTeam(id) != TEAM_TERRORIST || GetPlayerState(id) == PRISONER_LAST)
		return false;

	new lastPn = FindPrisonerLast();
	if (mjb_is_valid_player(lastPn))
	{
		return false;
	}

	if (!SetPlayerState(id, PRISONER_LAST));
		return false;
	
	return true;
}

public SetPlayerWanted(victim, attacker)
{
	if (victim == attacker || !mjb_is_valid_player(attacker) || !is_user_alive(attacker))
		return false;

	if (GetTeam(victim) != TEAM_CT || GetTeam(attacker) != TEAM_TERRORIST)
		return false;

	if (GetPlayerState(attacker) == PRISONER_WANTED || GetPlayerState(attacker) == PRISONER_LAST)
		return false;
	
	//When restructuring DayCycleSystem
	//if (mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
	//	return false;
	SetPlayerState(attacker, PRISONER_WANTED);
	emit_sound(0, CHAN_AUTO, "MOON_JB/MOON_wanted.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return true;
}

public SetPlayerFreeday(id)
{
	if (!mjb_is_valid_player(id))
		return false;

	//if (mjb_get_day_type() == FREEDAY || mjb_get_phase() == PHASE_FREEDAY || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE)
	//	return 0

	if (!is_user_alive(id))
		return false;

	if (GetTeam(id) != TEAM_TERRORIST)
		return false;

	if (GetPlayerState(id) != NORMAL && GetPlayerState(id) != PRISONER_BOXING && GetPlayerState(id) != PRISONER_SOCCER)
		return false;

	SetPlayerState(id, PRISONER_FREEDAY);
	return 1;
}

public SetPlayerBoxing(id)
{
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return false;

	//if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) 
	//	return false;

	if (GetTeam(id) != TEAM_TERRORIST)
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

	//if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) 
	//	return false;

	if (GetTeam(id) != TEAM_TERRORIST)
		return false;

	if (GetPlayerState(id) != NORMAL && GetPlayerState(id) != PRISONER_BOXING)
		return false;

	SetPlayerState(id, PRISONER_SOCCER);
	return true;
}

public SetPlayerMinigamesTeam(id, iMinigamesTeam)
{
	if (!mjb_is_valid_player(id))
		return false;
	g_iPlayerMinigamesTeam[id] = iMinigamesTeam;
	Forward_MinigamesTeamChanged(id);
	return true;
}

public GetPlayerMinigamesTeam(id)
{
	if (!mjb_is_valid_player(id))
		return -1;

	return g_iPlayerMinigamesTeam[id];
}

public GetMinigamesTeamCount(iMinigamesTeam)
{
	new iCount = 0;
	for (new i = 0; i <= MAX_PLAYERS; i++)
	{
		if (g_iPlayerMinigamesTeam[i] != iMinigamesTeam)
			continue;
		iCount++;
	}
	return iCount;
}

public ResetPlayerMinigamesTeam(id)
{
	g_iPlayerMinigamesTeam[id] = 0;
	Forward_MinigamesTeamChanged(id)
}

public ResetEveryoneMinigamesTeam()
{
	for (new i = 0; i <= MAX_PLAYERS; i++)
	{
		g_iPlayerMinigamesTeam[i] = 0;
		Forward_MinigamesTeamChanged(i)
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
========================= */
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