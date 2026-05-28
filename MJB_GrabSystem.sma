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

/*This plugin steales some ideas and functions from Jedi Grab and reshaped it to be suitable for the JB modpack*/

#include <amxmodx>
#include <fakemeta>
#include <MJB_Core>

#define PLUGIN "Grab System"

new g_iGrabbing[MAX_PLAYERS + 1];
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_PlayerPreThink, "PlayerPreThink");
	register_clcmd("+grab", "GrabOn");
	register_clcmd("-grab", "GrabOff");
}

public PlayerPreThink(id) {
	if (g_iGrabbing[id] == -1) {
		new Float:fEyePosition[3], Float:vAimVector[3];
		get_view_pos(id, fEyePosition);
		vAimVector = st_velocity_by_aim(id, 9999);
		
		vAimVector[0] += fEyePosition[0];
		vAimVector[1] += fEyePosition[1];
		vAimVector[2] += fEyePosition[2];
		new target = traceline(fEyePosition, vAimVector, id, vAimVector);
		
		new szMessage[64];
		if (mjb_is_valid_player(target)) {
			new name[32];
			get_user_name(target, name, 31);
			format(szMessage, 63, "!tYou grabbed player !g%s", name);
			g_iGrabbing[id] = target;
		} else {
			
			if (target && pev_valid(target)) { 	
				g_iGrabbing[id] = target;
			} else {
				target = 0;
				new ent;
				while (!target && (ent = engfunc( EngFunc_FindEntityInSphere, -1, vAimVector, 12.0 ))) {
					if (ent != id)
						target = ent;
				}
			}
			format(szMessage, 63, "!tYou grabbed entity !g%s", name);
		}
	}
}

public CanGrab(id) {
	return (mjb_is_valid_player(id) && hasRank(id, RANK_GRAB));
}

public GrabOn(id) {
	if (!CanGrab(id))
		return PLUGIN_CONTINUE;
	g_iGrabbing[id] = -1;
	return PLUGIN_HANDLED;
}

public GrabOff(id) {
	if (!CanGrab(id))
		return PLUGIN_CONTINUE;
	g_iGrabbing[id] = 0;
	return PLUGIN_HANDLED;
}

stock get_entity_type(entid) {
	if (!pev_valid(entid))
		return 0;
	
	new m = pev(entid, pev_movetype);
	if (m == MOVETYPE_WALK || m == MOVETYPE_BOUNCE || m == MOVETYPE_STEP || m == MOVETYPE_TOSS)
		return 1;
		
	if (mjb_is_a_cell(entid))
		return 2;
}

stock get_view_pos(const id, Float:fViewPos[3])
{
	new Float:vOfs[3];
	pev(id, pev_origin, fViewPos);
	pev(id, pev_view_ofs, vOfs);	
	
	fViewPos[0] += vOfs[0];
	fViewPos[1] += vOfs[1];
	fViewPos[2] += vOfs[2];
}

stock Float:st_velocity_by_aim(id, speed = 1)
{
	new Float:vAngleVector[3], Float:vBlah[3];
	pev( id, pev_v_angle, vAngleVector );
	engfunc( EngFunc_AngleVectors, vAngleVector, vAngleVector, vBlah, vBlah);
	
	vAngleVector[0] *= speed;
	vAngleVector[1] *= speed;
	vAngleVector[2] *= speed;
	
	return vAngleVector;
}

stock traceline( const Float:vStart[3], const Float:vEnd[3], const pIgnore, Float:vHitPos[3] )
{
	engfunc( EngFunc_TraceLine, vStart, vEnd, 0, pIgnore, 0 )
	get_tr2( 0, TR_vecEndPos, vHitPos )
	return get_tr2( 0, TR_pHit )
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
