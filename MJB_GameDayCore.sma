#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "GameDay Mode Core"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_PlayerSpawn_Post", true);
}

public RG_PlayerSpawn_Post(id) {
	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE)
		FreezePlayer(id);
}

public mjb_phase_changed(iOldPhase, iNewPhase) {
	if (iNewPhase == PHASE_GAMEDAY_VOTE) {
		FreezeAndBlindAll();
	}
}

public FreezeAndBlindAll() {
	new pl[32], plnum, id;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		id = pl[i];
		if (!mjb_is_valid_player(id) || !is_user_alive(id))
			continue;
		FreezePlayer(id);
		BlindPlayer(id);
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
	if (IsFreezed)
		return;
	flags |= FL_FROZEN;
	set_pev(id, pev_flags, flags);
	set_member(id, m_flNextAttack, mjb_get_timer_timeleft(mjb_get_vote_timer_id()));
}

public UnFreezePlayer(id) {
	new flags = pev(id, pev_flags);
	if (!IsFreezed)
		return;
	flags &= ~FL_FROZEN;
	set_member(id, m_flNextAttack, 0.0);
}

public bool:IsFreezed(id) {
	return (flags & FL_FROZEN);
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
