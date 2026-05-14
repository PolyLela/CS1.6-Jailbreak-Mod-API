#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "Days State System FSM"
#define DAY_END_TASK	7124

new const DayTypes[16] = {
    FREEDAY,
    FREEDAY, NORMALDAY, NORMALDAY, NORMALDAY,
    GAMEDAY,
    NORMALDAY, NORMALDAY, NORMALDAY, NORMALDAY,
    NORMALDAY, NORMALDAY,
    GAMEDAY,
    NORMALDAY, NORMALDAY,
    FREEDAY
};

new g_iPhase = -1;
new g_iFreePhaseCount;
new bool:g_bManyFreeEnabled = true;

new g_iFreedayTimer = -1;
new g_iSimonTimer  = -1;

new g_HudSync;
new g_fwPhaseChanged;
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	set_cvar_num("mp_maxrounds", 15);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundStart", true);
	RegisterHookChain(RG_RoundEnd, "OnRoundEnd", true);
	g_fwPhaseChanged = CreateMultiForward("mjb_phase_changed", ET_IGNORE, FP_CELL, FP_CELL);
	OnRoundStart();
	g_HudSync = CreateHudSyncObj();
	set_task(1.0, "MainHud", _, _, _, "b");
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
			mjb_open_cell();
		}
		
		case PHASE_FREE_ENDED:
		{
			mjb_close_cell();
			
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
	}
	
}

/* =========================
   TIMER CONTROL
========================= */
public StartFreedayTimer()
{
	StopFreedayTimer();
	g_iFreedayTimer = mjb_start_timer(240.0);
}

public StartSimonTimer()
{
	StopSimonTimer();
	g_iSimonTimer = mjb_start_timer(30.0);
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
}

/* =========================
   EVENTS
========================= */
public OnRoundStart()
{
	mjb_unblock_game_behaviour();
	ChangePhase(PHASE_DAY_STARTED);
}

public OnRoundEnd()
{
	StopAllTimers();
	ChangePhase(PHASE_DAY_ENDED);
	if (!task_exists(DAY_END_TASK))
		set_task(0.1, "DayEnd");
}

public DayEnd() {
	mjb_block_game_behaviour();
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
   HUD
========================= */
public MainHud()
{
	new iFreedayTimeLeft = (g_iFreedayTimer != -1) ?
	floatround(mjb_get_timer_timeleft(g_iFreedayTimer)) : 0;
	
	new iSimonTimeLeft = (g_iSimonTimer != -1) ?
	floatround(mjb_get_timer_timeleft(g_iSimonTimer)) : 0;

	switch(g_iPhase) {
		case PHASE_FREEDAY: {
			set_hudmessage(0, 255, 0, 0.05, 0.15, 0, 0.0, 1.0);
			ShowSyncHudMsg(0, g_HudSync, "DayMode : Freeday^nFreeday Ends In : %d seconds", iFreedayTimeLeft);
		}
		case PHASE_SIMON_SELECT: {
			set_hudmessage(0, 255, 255, 0.05, 0.15, 0, 0.0, 1.0);
			ShowSyncHudMsg(0, g_HudSync, "Simon Not Selected^nFreeday Starts In : %d seconds", iSimonTimeLeft);
		}
		case PHASE_NORMAL: {
			new id = mjb_get_simon();
			if (mjb_is_valid_player(id)) {
				new szBuffer[32];
				get_user_name(id, szBuffer, 31);
				set_hudmessage(0, 255, 255, 0.05, 0.15, 0, 0.0, 1.0);
				ShowSyncHudMsg(0, g_HudSync, "DayMode : Normal^nSimon : %s", szBuffer);
			}
		}
		case PHASE_SIMON_NOT_SELECTED: {
			set_hudmessage(255, 255, 0, 0.05, 0.15, 0, 0.0, 1.0);
			ShowSyncHudMsg(0, g_HudSync, "Simon Not Selected");
		}
		case PHASE_SIMON_KILLED: {
			set_hudmessage(255, 255, 0, 0.05, 0.15, 0, 0.0, 1.0);
			ShowSyncHudMsg(0, g_HudSync, "Simon Is Killed");
		}
		case PHASE_SIMON_DISCONNECTED: {
			set_hudmessage(255, 255, 0, 0.05, 0.15, 0, 0.0, 1.0);
			ShowSyncHudMsg(0, g_HudSync, "Simon Disconnected");
		}
	}
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
	register_native("mjb_get_free_timer_id", "native_get_free_timer_id")
	register_native("mjb_get_simon_timer_id", "native_get_simon_timer_id")
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
