#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <MJB_Core>

#define PLUGIN "Multijump system"

new g_iAddJumps[MAX_PLAYERS + 1];
new g_iJumpNum[MAX_PLAYERS + 1];
new g_iShouldJump[MAX_PLAYERS + 1];
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
}

public client_putinserver(id) {
	g_iAddJumps[id] = 0;
	g_iJumpNum[id] = 0;
	g_iShouldJump[id] = MJB_False;
}

public client_disconnected(id)
{
	g_iJumpNum[id] = 0;
	g_iShouldJump[id] = MJB_False;
}

public client_PreThink(id)
{
	if (!mjb_is_player_alive(id))
		return PLUGIN_CONTINUE;
	
	new iButton = get_user_button(id);
	new iOldButton = get_user_oldbutton(id);
	
	if((iButton & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(iOldButton & IN_JUMP))
	{
		if(g_iJumpNum[id] < GetMaxJumps(id))
		{
			g_iShouldJump[id] = true
			g_iJumpNum[id]++
			return PLUGIN_CONTINUE
		}
	}
	if((iButton & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		g_iJumpNum[id] = 0
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE;
}

public client_PostThink(id) {
	if (!mjb_is_player_alive(id)) 
		return PLUGIN_CONTINUE;
	if (g_iShouldJump[id]) {
		new Float:fVelocity[3];
		entity_get_vector(id, EV_VEC_velocity, fVelocity);
		fVelocity[2] = random_float(265.0,285.0);
		entity_set_vector(id, EV_VEC_velocity, fVelocity);
		g_iShouldJump[id] = MJB_False;
	}
	return PLUGIN_CONTINUE;
}

public ResetAllAddJumps() {
	new pl[32], plnum;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		if (!mjb_is_valid_player(pl[i]))
			continue;
		g_iAddJumps[pl[i]] = 0;
	}
}

public GetMaxJumps(id) {
	new iRankLevel = get_user_rank_level(id);
	new iMaxJumps = 0;
	if (iRankLevel >= RANK_LEVEL_ADMIN) {
		iMaxJumps = 0
		if (iRankLevel == RANK_LEVEL_OWNER)
			iMaxJumps++;
		if (iRankLevel >= RANK_LEVEL_ADMINISTRATOR)
			iMaxJumps++;
		if (hasRank(id, RANK_VIP))
			iMaxJumps++;
		if (hasRank(id, RANK_SVIP))
			iMaxJumps++;
	} else if (iRankLevel == RANK_LEVEL_SVIP) {
		iMaxJumps = 1;
	} else if (iRankLevel == RANK_LEVEL_VIP) {
		iMaxJumps = 1;
	} else {
		iMaxJumps = 0;
	}
	iMaxJumps += g_iAddJumps[id];
	return iMaxJumps;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
