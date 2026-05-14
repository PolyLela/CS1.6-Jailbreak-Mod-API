#if defined _mjb_consts_library
	#endinput
#endif

#define _mjb_consts_library

/* ============================================================
 *  Moon JB Consts
 *  Author: 4D0CtOR4
 * ------------------------------------------------------------
 *  This library provides const data for whole system
 * ============================================================
 */
 
#define MOD  "Moon Jailbreak"
#define VERSION "1.1"
#define AUTHOR  "4D0CtOR4  DT"
#define SERVERTAG "MJB"

/* =========================
   Player Ranks
========================= */
#define RANK_HOOK 0x00080000
#define RANK_VIP 0x00008002
#define RANK_SVIP 0x00040000
#define RANK_GRAB 0x00020000
#define RANK_RAKE 0x00010000
#define RANK_ADD_FK 0x00004000
#define RANK_ADMIN 0x00000115
#define RANK_FULL_ADMIN 0x0000011D
#define RANK_GOLD_ADMIN 0x0000431D
#define RANK_DEPUTY_HEAD 0x000FC31F
#define RANK_HEAD_ADMIN 0x000FD31F
#define RANK_ADMINISTRATOR 0x001FD35F
#define RANK_CO_OWNER 0x011FD3FF
#define RANK_OWNER 0x011FFFFF

#define RANK_LEVEL_NONE			0
#define RANK_LEVEL_VIP			1
#define RANK_LEVEL_SVIP			2
#define RANK_LEVEL_ADMIN		3
#define RANK_LEVEL_FULL_ADMIN		4
#define RANK_LEVEL_GOLD_ADMIN		5
#define RANK_LEVEL_DEPUTY		6
#define RANK_LEVEL_HEAD_ADMIN		7
#define RANK_LEVEL_ADMINISTRATOR	8
#define RANK_LEVEL_CO_OWNER		9
#define RANK_LEVEL_OWNER		10

/* =========================
   Multijumps
========================= */
#define JUMPS_VIP			2
#define JUMPS_SVIP			2
#define JUMPS_ADMIN_STACKED		3

/* =========================
   Message ids
========================= */
#define MsgId_ScreenShake 97
#define MsgId_ScreenFade 98

/* =========================
   CONSTANTS & MACROS
========================= */
#define MJB_True 1
#define MJB_False 0

#define MAX_PLAYERS 32
#define PLAYERS_PER_PAGE 8

#define MAX_TIMERS 10

#define FROST_RADIUS 240.0
#define FROST_R	0
#define FROST_G	206
#define FROST_B	209

#define mjb_is_valid_player(%1) (1 <= %1 <= MAX_PLAYERS && is_user_connected(%1))
#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

new const StateNames[][] = {
	"None",
	"Freeday",
	"Wanted",
	"Soccer",
	"Boxing",
	"Last"
};

new const DayNames[][] = {
	"Normal",
	"Freeday",
	"Gamesday"
};

/* =========================
   ENUMS
========================= */
enum _:MeleeType
{
    MELEE_FISTS = 0,
    MELEE_BATON,
    MELEE_SVIP_AXE,
    MELEE_SVIP_COMBAT,
    MELEE_SVIP_HAMMER,
    MELEE_SVIP_KATANA,
    MELEE_SVIP_STAP,
    MELEE_BOXING_RED,
    MELEE_BOXING_BLUE
};

enum _:MeleeData
{
    MELEE_V_MODEL[64],
    MELEE_P_MODEL[64],

    MELEE_SND_DEPLOY[64],
    MELEE_SND_SLASH[64],
    MELEE_SND_STAB[64],
    MELEE_SND_HITWALL[64],
    MELEE_SND_HIT[64],

    Float:MELEE_PRIMARY_DELAY,
    Float:MELEE_SECONDARY_DELAY
};

enum _:DoorState {
	DOOR_CLOSED = 0,
	DOOR_OPENING,
	DOOR_OPEN,
	DOOR_CLOSING,
};

enum _:DayType {
	NORMALDAY = 0,
	FREEDAY,
	GAMEDAY
};

enum _:DayPhase {
	PHASE_DAY_STARTED,
	PHASE_DAY_ENDED,
	PHASE_SIMON_SELECT,
	PHASE_SELECT_ENDED,
	PHASE_FREEDAY,
	PHASE_FREE_ENDED,
	PHASE_NORMAL,
	PHASE_SIMON_KILLED,
	PHASE_SIMON_DISCONNECTED,
	PHASE_SIMON_NOT_SELECTED,
	PHASE_GAMEDAY_VOTE,
	PHASE_GAMEDAY_ACTIVE,
	PHASE_GAMEDAY_NORMAL,
};

enum _:TimerState {
	Stopped = 0,
	Running
};

enum _:SoccerTeam{ 	
	BLUE = 1,
	RED
};

enum _:PlayerState {
	NORMAL = 0,
	PRISONER_FREEDAY,
	PRISONER_WANTED,
	PRISONER_SOCCER,
	PRISONER_BOXING,
	PRISONER_LAST,
	STATES_NUM
};
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
