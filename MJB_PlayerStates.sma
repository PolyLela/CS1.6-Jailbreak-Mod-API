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
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "PlayerStates"

/* =========================
   GLOBAL DATA
========================= */
enum _:PlayerDataField {
    DATA_TEAM = 0,
    DATA_STATE,
    DATA_LIFE
};

new g_PlayerData[MAX_PLAYERS + 1][PlayerDataField];

/* Forwards */
new g_fwTeamChanged;
new g_fwStateChanged;
new g_fwLifeStateChanged;
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
    register_event("TeamInfo", "Event_TeamInfo", "a");
    register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");

    /* Hooks */
    RegisterHam(Ham_TraceAttack, "player", "OnPlayerTraceAttack_Pre");
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", 1);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);
    
    /* Forwards */
    g_fwTeamChanged  = CreateMultiForward("mjb_team_changed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
    g_fwStateChanged = CreateMultiForward("mjb_state_changed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
    g_fwLifeStateChanged = CreateMultiForward("mjb_life_state_changed", ET_IGNORE, FP_CELL, FP_CELL);
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
	
	register_native("mjb_set_team", "native_mjb_set_team");
	register_native("mjb_get_team", "native_mjb_get_team");
	register_native("mjb_get_team_count", "native_get_team_count");
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
	register_native("mjb_is_player_alive", "native_mjb_is_player_alive");
}

public native_mjb_set_team() {
	new id = get_param(1);
	new iTeam = get_param(2);
	new bKill = get_param(3);
	SetPlayerTeam(id, iTeam, bKill);
}

public native_mjb_get_team() {
	new id = get_param(1);
	return GetPlayerTeam(id);
}

public native_get_team_count() {
	new iTeam = get_param(1);
	new iAliveOnly = get_param(2);
	
	GetTeamCount(iTeam, iAliveOnly);
}

public native_mjb_set_state() {
	new id = get_param(1);
	new iState = get_param(2);
	SetPlayerState(id, iState);
}

public native_mjb_get_state() {
	new id = get_param(1);
	return GetPlayerState(id);
}

public native_set_user_soccer() {
	new id = get_param(1);
	return SetPlayerSoccer(id);
}

public native_set_user_boxing() {
	new id = get_param(1);
	return SetPlayerBoxing(id);
}

public native_set_user_freeday() {
	new id = get_param(1);
	return SetPlayerFreeday(id);
}

public native_set_user_freeday_nextday() {
	new id = get_param(1);
	new bToggle = get_param(2);
	if (!mjb_is_valid_player(id) || mjb_get_team(id) != PRISONER)
		return 0;
	g_bNextdayFreeday[id] = bToggle;
	return 1;
}

public native_is_user_freeday_nextday() {
	new id = get_param(1);
	if (!mjb_is_valid_player(id) || mjb_get_team(id) != PRISONER)
		return 0;
	return g_bNextdayFreeday[id];
}

public native_set_user_mg_team() {
	new id = get_param(1);
	new iMinigamesTeam = get_param(2);
	return SetPlayerMinigamesTeam(id, iMinigamesTeam);
}

public native_get_user_mg_team() {
	new id = get_param(1);
	return GetPlayerMinigamesTeam(id);
}

public native_get_mg_team_count() {
	new iMinigamesTeam = get_param(1);
	return GetMinigamesTeamCount(iMinigamesTeam);
}

public native_mjb_set_all_state() {
	new iState = get_param(1);
	SetAllState(iState);
}

public native_mjb_is_player_alive() {
	new id = get_param(1);
	return IsPlayerAlive(id);
}

/* =========================
   EVENTS
========================= */
public client_putinserver(id)
{
    g_PlayerData[id][DATA_STATE] = NORMAL;
    g_PlayerData[id][DATA_LIFE] = MJB_False;
}

public client_disconnected(id) {
	set_task(0.1, "ChoosePrisonerLast");
}

public Event_NewRound() {
    for(new id = 1; id <= 32; id++) {
        g_PlayerData[id][DATA_STATE] = NORMAL;
    }
    set_task(1.0, "ChoosePrisonerLast");
    set_task(1.0, "ProcessFreedayNextday", 50);
}

public mjb_phase_changed(iOldPhase, iNewPhase) {
	if (iOldPhase != PHASE_GAMEDAY_ACTIVE && iOldPhase != PHASE_GAMEDAY_VOTE)
		return;
	if (iNewPhase != PHASE_DAY_ENDED)
		return;
	remove_task(50);
	set_task(1.0, "ProcessFreedayNextday", 50);
}

public OnPlayerTraceAttack_Pre(victim, attacker, Float:damage, Float:direction[3], damagebits)
{
    if (!mjb_is_valid_player(victim) || !mjb_is_valid_player(attacker) || victim == attacker)
        return HAM_IGNORED;

    SetPlayerWanted(victim, attacker);

    return HAM_IGNORED;
}

public OnPlayerKilled_Post(victim, killer) {
	SetPlayerDead(victim);
	SetPlayerState(victim, NORMAL);
	set_task(0.1, "ChoosePrisonerLast");
}

public OnPlayerSpawn_Post(id) {
	if (is_user_alive(id)) {
		SetPlayerAlive(id);
		g_PlayerData[id][DATA_STATE] = NORMAL;
		g_iPlayerMinigamesTeam[id] = NONE;
		set_task(0.5, "ChoosePrisonerLast");
	}
}

public Event_TeamInfo()
{
    new id = read_data(1);

    if (!mjb_is_valid_player(id))
        return;

    new teamStr[16];
    read_data(2, teamStr, charsmax(teamStr));

    ParseAndSetTeam(id, teamStr);
    GetTeamStr(id, teamStr, 15);
}

/* =========================
   CORE: TEAM SYSTEM
========================= */
public SetPlayerTeamInfo(id, iTeam)
{
	if (!mjb_is_valid_player(id))
		return;
	
	if (iTeam < PRISONER || iTeam > GUARD)
		iTeam = NONE;
    
	new OldTeam = g_PlayerData[id][DATA_TEAM]
	g_PlayerData[id][DATA_TEAM] = iTeam;
	Forward_TeamChanged(id, OldTeam);
}

public SetPlayerTeam(id, iTeam, bKill)
{
	if (!mjb_is_valid_player(id))
		return;
	
	
	switch (iTeam)
	{
		case PRISONER:
		{
			if(bKill) {
				if (bKill == 1) user_kill(id, 1);
				cs_set_user_team(id, CS_TEAM_T);
				if (bKill == 2) {
					// Leave observer mode
					set_pev(id, pev_iuser1, 0);
					set_pev(id, pev_iuser2, 0);
					
					// Clear spectator flags
					//set_pev(id, pev_deadflag, DEAD_NO);
					//set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_NODRAW);
					
					// Respawn through CS code
					ExecuteHamB(Ham_CS_RoundRespawn, id);
					
					fm_give_item(id, "weapon_knife");
					
					message_begin(MSG_ONE, get_user_msgid("Spectator"), _, id);
					write_byte(0);
					write_byte(0);
					message_end();
					
					message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ResetHUD"), _, id);
					message_end();
					
					message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("InitHUD"), _, id);
					message_end();
				}
				set_pdata_int(id, m_bHasChangeTeamThisRound, 1, linux_diff_player);
				return;
			}
			engclient_cmd(id, "jointeam", "1");
			engclient_cmd(id, "joinclass", "1");
		}
		case GUARD:
		{
			if(bKill) {
				if (bKill == 1) user_kill(id, 1);
				cs_set_user_team(id, CS_TEAM_CT);
				if (bKill == 2) ExecuteHamB(Ham_Spawn, id);  
				set_pdata_int(id, m_bHasChangeTeamThisRound, 1, linux_diff_player);
				return;
			}
			engclient_cmd(id, "jointeam", "2");
			engclient_cmd(id, "joinclass", "2");
		}
		default:
		{
			if(bKill) {
				if (bKill == 1) user_kill(id, 1);
				cs_set_user_team(id, CS_TEAM_SPECTATOR);
				if (bKill == 2) ExecuteHamB(Ham_Spawn, id);
				set_pdata_int(id, m_bHasChangeTeamThisRound, 1, linux_diff_player);
				return;
			}
			engclient_cmd(id, "jointeam", "6");
			iTeam = 6;
		}
	}
}

public GetPlayerTeam(id)
{
    if (!mjb_is_valid_player(id))
        return NONE;

    return g_PlayerData[id][DATA_TEAM];
}

public GetTeamCount(iTeam, iAliveOnly) {
	new count;
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || (iAliveOnly && !IsPlayerAlive(tempid)) || GetPlayerTeam(tempid) != iTeam)
			continue;
		count++;
	}
	return count;
}

/* =========================
   CORE: STATE SYSTEM
========================= */
public ProcessFreedayNextday() {
	if (mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
		return;
	
	for (new id = 1; id < sizeof(g_bNextdayFreeday); id++) {
		if (!mjb_is_valid_player(id) || !IsPlayerAlive(id) || GetPlayerTeam(id) != PRISONER || !g_bNextdayFreeday[id])
			continue;
		g_bNextdayFreeday[id] = MJB_False;
		SetPlayerState(id, PRISONER_FREEDAY);
	}
}

public ChoosePrisonerLast() {
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	new lastPn = 0;
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !IsPlayerAlive(tempid) || GetPlayerTeam(tempid) != PRISONER || g_bNextdayFreeday[tempid])
			continue;

		lastPn = tempid;
	}
	
	SetPlayerLast(lastPn);
}

public FindPrisonerLast() {
	new pl[MAX_PLAYERS], plnum, tempid;
	get_players(pl, plnum, "h");
	new lastPn = 0;
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || !IsPlayerAlive(tempid) || GetPlayerTeam(tempid) != PRISONER)
			continue;
		
		if (GetPlayerState(tempid) == PRISONER_LAST)
			lastPn = tempid;
	}
	return lastPn;
}

public SetPlayerState(id, iState)
{
	if (!mjb_is_valid_player(id))
		return;
    
	if (GetPlayerTeam(id) == GUARD) {
		g_PlayerData[id][DATA_STATE] = NORMAL;
		return;
	}
	
	if (GetPlayerState(id) == PRISONER_LAST && IsPlayerAlive(id)) {
		return;
	}
	
	new OldState = g_PlayerData[id][DATA_STATE];
	g_PlayerData[id][DATA_STATE] = iState;
	Forward_StateChanged(id, OldState);
}

public GetPlayerState(id)
{
	if (!mjb_is_valid_player(id))
		return -1;

	return g_PlayerData[id][DATA_STATE];
}

public SetPlayerLast(id) {
	if (!mjb_is_valid_player(id) || !IsPlayerAlive(id))
		return;
	
	if (GetTeamCount(PRISONER, MJB_True) > 1 || GetTeamCount(GUARD, MJB_True) <= 0 )
	{
		return;
	}
	
	if (GetPlayerTeam(id) != PRISONER || GetPlayerState(id) == PRISONER_LAST || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || mjb_get_phase() == PHASE_GAMEDAY_VOTE)
		return;
		
	if (FindPrisonerLast()) {
		new name[32];
		get_user_name(FindPrisonerLast(), name, 31);
		return;
	}
	
	SetPlayerState(id, PRISONER_LAST);
}

public SetPlayerWanted(victim, attacker) {
	if (!mjb_is_valid_player(attacker))
		return;
		
	if (GetPlayerState(attacker) == PRISONER_WANTED || GetPlayerState(attacker) == PRISONER_LAST || GetPlayerTeam(victim) != GUARD || GetPlayerTeam(attacker) != PRISONER)
		return;
	SetPlayerState(attacker, PRISONER_WANTED);
	emit_sound(0, CHAN_AUTO, "MOON_JB/MOON_wanted.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
}

public SetPlayerFreeday(id) {
	if (!mjb_is_valid_player(id))
		return 0;
	
	if (mjb_get_day_type() == FREEDAY || mjb_get_phase() == PHASE_FREEDAY || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE)
		return 0
	
	if (GetPlayerTeam(id) != PRISONER || g_PlayerData[id][DATA_STATE] == PRISONER_FREEDAY || g_PlayerData[id][DATA_STATE] == PRISONER_WANTED || g_PlayerData[id][DATA_STATE] == PRISONER_LAST)
		return 0;
	
	SetPlayerState(id, PRISONER_FREEDAY);
	return 1;
}

public SetPlayerBoxing(id) {
	if (!mjb_is_valid_player(id) || !IsPlayerAlive(id))
		return 0;
		
	if (mjb_get_phase() != PHASE_NORMAL)
		return 0;
	
	if (GetPlayerTeam(id) != PRISONER)
		return 0;
	
	if (g_PlayerData[id][DATA_STATE] == PRISONER_FREEDAY || g_PlayerData[id][DATA_STATE] == PRISONER_WANTED || g_PlayerData[id][DATA_STATE] == PRISONER_BOXING || g_PlayerData[id][DATA_STATE] == PRISONER_LAST)
		return 0;
		
	SetPlayerState(id, PRISONER_BOXING);
	return 1;
}

public SetPlayerSoccer(id) {
	if (!mjb_is_valid_player(id) || !IsPlayerAlive(id))
		return 0;
		
	if (mjb_get_phase() == PHASE_FREEDAY || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE)
		return 0;
	if (GetPlayerTeam(id) != PRISONER)
		return 0;
	
	if (g_PlayerData[id][DATA_STATE] == PRISONER_FREEDAY || g_PlayerData[id][DATA_STATE] == PRISONER_WANTED || g_PlayerData[id][DATA_STATE] == PRISONER_SOCCER || g_PlayerData[id][DATA_STATE] == PRISONER_LAST)
		return 0;
		
	SetPlayerState(id, PRISONER_SOCCER);
	g_iPlayerMinigamesTeam[id] = 0;
	return 1;
}

public SetPlayerMinigamesTeam(id, iMinigamesTeam) {
	if (!mjb_is_valid_player(id))
		return 0;
	g_iPlayerMinigamesTeam[id] = iMinigamesTeam;
	Forward_MinigamesTeamChanged(id);
	return 1;
}

public GetPlayerMinigamesTeam(id) {
	if (!mjb_is_valid_player(id))
		return -1;
		
	return g_iPlayerMinigamesTeam[id];
}

public GetMinigamesTeamCount(iMinigamesTeam) {
	new iCount = 0;
	for (new i = 0; i <= MAX_PLAYERS; i++) {
		if (g_iPlayerMinigamesTeam[i] != iMinigamesTeam)
			continue;
		iCount++;
	}
	return iCount;
}

public ResetPlayerMinigamesTeam(id) {
	g_iPlayerMinigamesTeam[id] = 0;
	Forward_MinigamesTeamChanged(id)
}

public ResetEveryoneMinigamesTeam() {
	for (new i = 0; i <= MAX_PLAYERS; i++) {
		g_iPlayerMinigamesTeam[i] = 0;
		Forward_MinigamesTeamChanged(i)
	}
}

public SetAllState(iState) {
	for (new id = 1; id <= MAX_PLAYERS; id++) {
		SetPlayerState(id, iState);
	}
}

/* =========================
   CORE: LIFE STATE SYSTEM
========================= */
public SetPlayerDead(id) {
	g_PlayerData[id][DATA_LIFE] = MJB_False;
	Forward_LifeStateChanged(id);
}

public SetPlayerAlive(id) {
	g_PlayerData[id][DATA_LIFE] = MJB_True;
	Forward_LifeStateChanged(id);
}

public IsPlayerAlive(id) {
	return g_PlayerData[id][DATA_LIFE];
}

/* =========================
   FORWARDS
========================= */
public Forward_TeamChanged(id, OldTeam)
{
    new ret;
    ExecuteForward(g_fwTeamChanged, ret, id, OldTeam, g_PlayerData[id][DATA_TEAM]);
}

public Forward_StateChanged(id, OldState)
{
    new ret;
    ExecuteForward(g_fwStateChanged, ret, id, OldState, g_PlayerData[id][DATA_STATE]);
}

public Forward_LifeStateChanged(id)
{
    new ret;
    ExecuteForward(g_fwLifeStateChanged, ret, id, g_PlayerData[id][DATA_LIFE]);
}

public Forward_MinigamesTeamChanged(id)
{
    new ret;
    ExecuteForward(g_fwMinigamesTeamChanged, ret, id, g_iPlayerMinigamesTeam[id]);
}


/* =========================
   PLUGIN SPECIFIC STOCKS
========================= */
stock ParseAndSetTeam(id, const teamStr[])
{
	if (teamStr[0] == 'T')
		SetPlayerTeamInfo(id, PRISONER);
	else if (teamStr[0] == 'C')
		SetPlayerTeamInfo(id, GUARD);
	else
		SetPlayerTeamInfo(id, NONE);
}
