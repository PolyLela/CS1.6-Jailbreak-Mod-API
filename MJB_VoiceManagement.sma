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
#include <amxmisc>
#include <fakemeta>
#include <MJB_Core>

#define PLUGIN "Voice Management"

new g_iCanSpeakPlayers[MAX_PLAYERS + 1];
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_logevent("OnRoundEnd", 2, "1=Round_End");
	register_forward(FM_Voice_SetClientListening, "FakeMeta_Voice_SetListening", false);
}

public OnRoundEnd() {
	for (new i = 0; i < sizeof(g_iCanSpeakPlayers); i++) {
		g_iCanSpeakPlayers[i] = MJB_False;
	}
}

public plugin_natives() {
	register_library("MJB_Core");
	
	register_native("mjb_enable_speaking", "native_enable_speaking");
	register_native("mjb_disable_speaking", "native_disable_speaking");
	register_native("mjb_can_speak", "native_can_speak");
}

public native_enable_speaking() {
	new id = get_param(1);
	if (!mjb_is_valid_player(id))
		return;
	g_iCanSpeakPlayers[id] = MJB_True;
}

public native_disable_speaking() {
	new id = get_param(1);
	if (!mjb_is_valid_player(id))
		return;
	g_iCanSpeakPlayers[id] = MJB_False;
}

public native_can_speak() {
	new id = get_param(1);
	if (!mjb_is_valid_player(id))
		return -1;
	return g_iCanSpeakPlayers[id];
}

public FakeMeta_Voice_SetListening(iReceiver, iSender, bool:bListen)
{
	if (!mjb_is_valid_player(iReceiver) || !mjb_is_valid_player(iSender))
		return FMRES_IGNORED;

	new bool:allow = false;

	if (g_iCanSpeakPlayers[iSender] 
	|| (hasRank(iSender, RANK_DEPUTY_HEAD))
	|| (mjb_get_team(iSender) == GUARD && mjb_is_player_alive(iSender)))
	{
		allow = true;
	}

	if (allow != bListen)
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, allow);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}
