#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <MJB_Core>

#define PLUGIN "Gameday Modes"

new g_CakeModel[][] = {
	"models/MOON_JB/DayModes/v_cake.mdl",
	"models/MOON_JB/DayModes/p_cake.mdl",
	"models/MOON_JB/DayModes/w_cake.mdl"
}

new g_iCakeTouchForward;
new g_iFakeMetaSetModel;
new g_pCakeIndex, g_pDecalIndex[4];
public plugin_init() {
	mjb_register_daymode("Birthday", "birth_day", 187);
	DisableHamForward(g_iCakeTouchForward = RegisterHam(Ham_Touch, "grenade", "HamHook_Touch_Grenade_Post", true));
}

public plugin_precache() {
	for (new i; i < sizeof(g_CakeModel); i++) {
		precache_model(g_CakeModel[i]);
	}
	g_pCakeIndex = engfunc(EngFunc_PrecacheModel, "sprites/jb_engine/cake_explosion.spr");
	//engfunc(EngFunc_PrecacheSound, "jb_engine/days_mode/birthday/cake_explosion.wav");
	engfunc(EngFunc_PrecacheGeneric, "sound/MOON_JB/DayModes/cake_explosion.wav");
	//engfunc(EngFunc_PrecacheGeneric, "sprites/jb_engine/wpn_cake.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/mjb_dm_wpn_cake.txt");
	g_pDecalIndex[0] = engfunc(EngFunc_DecalIndex,"{blood1");
	g_pDecalIndex[1] = engfunc(EngFunc_DecalIndex,"{blood2");
	g_pDecalIndex[2] = engfunc(EngFunc_DecalIndex,"{blood3");
	g_pDecalIndex[3] = engfunc(EngFunc_DecalIndex,"{blood4");
}

public FakeMeta_SetModel_Post(iEntity, const szModel[]) {
	if (equal(szModel, "models/w_smokegrenade")) {
		engfunc(EngFunc_SetModel, iEntity, g_CakeModel[2]);
		new Float:vecVelocity[3];
		pev(iEntity, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 1.5, vecVelocity);
		set_pev(iEntity, pev_velocity, vecVelocity);
		engfunc(EngFunc_SetSize, iEntity, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0});
	}
}

public ChangeWeaponSkin(id) {
	if (!CheckDayUID("birth_day"))
		return;
	new viewmodel[32];
	new weaponmodel[32];
	pev(id, pev_viewmodel2, viewmodel, charsmax(viewmodel));
	pev(id, pev_weaponmodel2, weaponmodel, charsmax(weaponmodel));
	if (equal(viewmodel, "models/v_smokegrenade.mdl")) {
		set_pev(id, pev_viewmodel2, g_CakeModel[0]);
		set_pev(id, pev_weaponmodel2, g_CakeModel[1]);
	}
}

public mjb_vote_results_processed(iDayMode, data[DayModeData]) {
	if (equal(data[DM_UID], "birth_day")) {
		for (new i; i <= MAX_PLAYERS; i++) {
			if (!mjb_is_valid_player(i) || !is_user_alive(i))
				continue;
			rg_remove_all_items(i, true);
			switch(GetTeam(i)) {
				case PRISONER: {
					set_pev(i, pev_gravity, 0.5);
				}
				case GUARD: {
					rg_give_item(i, "weapon_smokegrenade");
					rg_set_user_bpammo(i, WEAPON_SMOKEGRENADE, 200);
					message_begin(MSG_ONE, MsgId_WeaponList, _, i);
					write_string("mjb_dm_wpn_cake");
					write_byte(13);
					write_byte(1);
					write_byte(-1);
					write_byte(-1);
					write_byte(3);
					write_byte(3);
					write_byte(9);
					write_byte(24);
					message_end();
					static iszViewModel, iszWeaponModel;
					if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_CakeModel[0]))) set_pev_string(i, pev_viewmodel2, iszViewModel);
					if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_CakeModel[1]))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				}
			}
		}
		mjb_block_game_behaviour();
		EnableHamForward(g_iCakeTouchForward);
		g_iFakeMetaSetModel = register_forward(FM_SetModel, "FakeMeta_SetModel_Post", true);
	}
}

public mjb_daymode_ended(iDayMode, data[DayModeData]) {
	if (equal(data[DM_UID], "birth_day")) {
		mjb_unblock_game_behaviour();
		DisableHamForward(g_iCakeTouchForward);
		unregister_forward(FM_SetModel, g_iFakeMetaSetModel, true);
		new i, iEntity, iOwner;
		while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "grenade")))
		{
			if(!pev_valid(iEntity)) continue;
			iOwner = pev(iEntity, pev_owner);
			if(mjb_is_valid_player(iOwner)) set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		}
	}
}

stock CheckDayUID(const uid[]) {
	new data[DayModeData];
	if (!mjb_get_current_daymode(data))
		return false;
	
	if (!equal(data[DM_UID], uid))
		return false;
	return true;
}