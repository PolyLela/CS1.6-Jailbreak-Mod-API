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

/* ################################################################################# */
/* # Timer Manager (Fixed: Slot + Generation System)                                # */
/* ################################################################################# */

#include <amxmodx>
#include <amxmisc>
#include <MJB_Core>

#define PLUGIN "Timer Manager"

new g_iTimerState[MAX_TIMERS];
new Float:g_fEndTime[MAX_TIMERS];
new g_iGeneration[MAX_TIMERS]; // ?? generation system

new g_fwStartHandler, g_fwTickHandler, g_fwStopHandler, g_fwEndHandler;
new g_iTimerCount = 0;

/* =========================
   INIT
========================= */
public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_fwStartHandler = CreateMultiForward("mjb_timer_started", ET_IGNORE, FP_CELL, FP_FLOAT);
    g_fwTickHandler  = CreateMultiForward("mjb_timer_ticked", ET_IGNORE, FP_CELL, FP_FLOAT);
    g_fwStopHandler  = CreateMultiForward("mjb_timer_stopped", ET_IGNORE, FP_CELL);
    g_fwEndHandler   = CreateMultiForward("mjb_timer_ended", ET_IGNORE, FP_CELL);

    set_task(0.2, "GlobalTick", 0, _, _, "b");
}

/* =========================
   ID SYSTEM (CORE FIX)
========================= */

stock MakeTimerId(slot) {
    return (g_iGeneration[slot] << 16) | slot;
}

stock GetSlotFromId(timerId) {
    return timerId & 0xFFFF;
}

stock GetGenFromId(timerId) {
    return timerId >> 16;
}

/* =========================
   VALIDATION
========================= */

stock isValidTimer(timerId) {
    new slot = GetSlotFromId(timerId);

    if (slot < 0 || slot >= MAX_TIMERS)
        return 0;

    if (g_iTimerState[slot] != Running)
        return 0;

    if (g_iGeneration[slot] != GetGenFromId(timerId))
        return 0;

    return 1;
}

/* =========================
   CORE LOGIC
========================= */

public CreateTimer(Float:fDuration) {
    new slot = FindFreeTimerSlot();

    if (slot == -1)
        return -1;

    g_iGeneration[slot]++; // ?? NEW GENERATION

    g_fEndTime[slot] = get_gametime() + fDuration;
    g_iTimerState[slot] = Running;
    g_iTimerCount++;

    new timerId = MakeTimerId(slot);

    new ret;
    ExecuteForward(g_fwStartHandler, ret, timerId, fDuration);

    return timerId;
}

public FindFreeTimerSlot() {
    for (new i = 0; i < MAX_TIMERS; i++) {
        if (g_iTimerState[i] != Running) {
            ResetTimer(i);
            return i;
        }
    }
    return -1;
}

public GlobalTick() {
    new Float:fCurrentTime = get_gametime();

    for (new slot = 0; slot < MAX_TIMERS; slot++) {
        if (g_iTimerState[slot] != Running)
            continue;

        new timerId = MakeTimerId(slot);
        new Float:fTimeLeft = g_fEndTime[slot] - fCurrentTime;

        if (fTimeLeft <= 0.0) {
            Forward_Ticked(timerId, 0.0);
            Forward_Ended(timerId);
            KillTimer(timerId);
            continue;
        }

        Forward_Ticked(timerId, fTimeLeft);
    }
}

/* =========================
   API LOGIC
========================= */

public IsTimerRunning(timerId) {
    return isValidTimer(timerId) ? MJB_True : MJB_False;
}

public Float:GetTimerTimeLeft(timerId) {
    if (!isValidTimer(timerId))
        return -1.0;

    new slot = GetSlotFromId(timerId);
    return g_fEndTime[slot] - get_gametime();
}

public KillTimer(timerId) {
    if (!isValidTimer(timerId))
        return 0;

    new slot = GetSlotFromId(timerId);

    Forward_Stopped(timerId);

    g_iTimerState[slot] = Stopped;
    g_iTimerCount--;

    return 1;
}

public ExtendTimer(timerId, Float:fDuration) {
    if (!isValidTimer(timerId))
        return 0;

    new slot = GetSlotFromId(timerId);
    g_fEndTime[slot] += fDuration;

    return 1;
}

public KillAllTimers() {
    for (new slot = 0; slot < MAX_TIMERS; slot++) {
        if (g_iTimerState[slot] == Running) {
            new timerId = MakeTimerId(slot);

            g_iTimerState[slot] = Stopped;
            Forward_Stopped(timerId);
        }
    }
    g_iTimerCount = 0;
}

public GetRunningTimers() {
    return g_iTimerCount;
}

public GetTimerInfo(slot, &timerId, &gen, &Float:timeLeft)
{
    if (g_iTimerState[slot] != Running)
        return 0;

    timerId = MakeTimerId(slot);
    gen = g_iGeneration[slot];
    timeLeft = g_fEndTime[slot] - get_gametime();

    return 1;
}

/* =========================
   RESET
========================= */

stock ResetTimer(slot) {
    g_iTimerState[slot] = Stopped;
    g_fEndTime[slot] = 0.0;
}

/* =========================
   NATIVES
========================= */

public plugin_natives() {
    register_library("MJB_Core");

    register_native("mjb_start_timer", "native_mjb_start_timer");
    register_native("mjb_is_timer_running", "native_mjb_is_timer_running");
    register_native("mjb_get_timer_timeleft", "native_mjb_get_timer_timeleft");
    register_native("mjb_get_timer_info", "native_get_timer_info");
    register_native("mjb_stop_timer", "native_mjb_stop_timer");
    register_native("mjb_extend_timer", "native_mjb_extend_timer");
    register_native("mjb_stop_all_timers", "native_mjb_stop_all_timers");
    register_native("mjb_get_timers", "native_mjb_get_timers");
}

public native_mjb_start_timer() {
    new Float:fSeconds = get_param_f(1);
    return CreateTimer(fSeconds);
}

public native_mjb_is_timer_running() {
    new timerId = get_param(1);
    return IsTimerRunning(timerId);
}

public Float:native_mjb_get_timer_timeleft() {
    new timerId = get_param(1);
    return GetTimerTimeLeft(timerId);
}

public native_get_timer_info()
{
    new slot = get_param(1);

    new timerId;
    new gen;
    new Float:timeLeft;

    if (!GetTimerInfo(slot, timerId, gen, timeLeft))
        return 0;

    set_param_byref(2, timerId);
    set_param_byref(3, gen);
    set_param_byref(4, _:timeLeft);

    return 1;
}

public native_mjb_stop_timer() {
    new timerId = get_param(1);
    return KillTimer(timerId);
}

public native_mjb_extend_timer() {
    new timerId = get_param(1);
    new Float:fSeconds = get_param_f(2);
    return ExtendTimer(timerId, fSeconds);
}

public native_mjb_stop_all_timers() {
    KillAllTimers();
}

public native_mjb_get_timers() {
    return GetRunningTimers();
}

/* =========================
   FORWARDS
========================= */

public Forward_Ticked(timerId, Float:fTimeLeft) {
    new ret;
    ExecuteForward(g_fwTickHandler, ret, timerId, fTimeLeft);
}

public Forward_Stopped(timerId) {
    new ret;
    ExecuteForward(g_fwStopHandler, ret, timerId);
}

public Forward_Ended(timerId) {
    new ret;
    ExecuteForward(g_fwEndHandler, ret, timerId);
}