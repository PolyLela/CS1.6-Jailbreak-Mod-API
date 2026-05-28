#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <MJB_Core>

#define PLUGIN "Gameday Modes"

/* Global Definitions */
#define MsgId_WeaponList 78

new g_iWaitTime, g_iWaitTimer = -1;

/* Event Handlers */
new HamHook:g_iGrenadeTouchForward, HamHook:g_iTraceAttackPre;
//HamHook:g_iTakeDamagePre;
new HamHook:g_iKilledPost;
new g_iFakeMetaSetModel;
new g_iFakeMetaAddToFullPack, g_iFakeMetaCheckVisibility;
new g_iFakeMetaEmitSound;

/*===== -> DayModes Variables -> =====*///{
/* Birth Day */
new g_CakeModel[][] = {
	"models/MOON_JB/DayModes/v_cake.mdl",
	"models/MOON_JB/DayModes/p_cake.mdl",
	"models/MOON_JB/DayModes/w_cake.mdl"
}

new g_pCakeIndex, g_pDecalIndex[4];

/* Ringolevio Day */
#define BREAK_GLASS 0x01
#define IUSER1_DEATH_TIMER 754645
#define TASK_DEATH_TIMER 785689
#define TASK_PROTECTION_TIME 125908

new g_iUserEntityTimer[MAX_PLAYERS + 1]
new Float:g_fUserDeathTimer[MAX_PLAYERS + 1]
new g_iUserLife[MAX_PLAYERS + 1];
new g_pSpriteFrost, g_pModelFrost;

/* Ghosts Day */
#define TASK_AMBIENCE_SOUND 921515

/*===== <- DayModes Variables <- =====*///}

/*===== -> Plugin Initializer -> =====*///{
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR, _, "This Plugin Implements All DayModes Logic Based On DayModeCore");
	register_daymodes();
	register_events();
}

public plugin_precache() {
	Birthday_Precache_Resources();
	Ringolevio_Precache_Resources();
	GhostDay_Precache_Resources();
	g_pDecalIndex[0] = engfunc(EngFunc_DecalIndex,"{blood1");
	g_pDecalIndex[1] = engfunc(EngFunc_DecalIndex,"{blood2");
	g_pDecalIndex[2] = engfunc(EngFunc_DecalIndex,"{blood3");
	g_pDecalIndex[3] = engfunc(EngFunc_DecalIndex,"{blood4");
}

register_daymodes() {
	mjb_register_daymode("Sparta Day", 	"sparta_day", 		187, 	WINSTATUS_TERRORISTS);
	mjb_register_daymode("Prisedent Day", 	"prisedent_day",	200, 	WINSTATUS_DRAW);
	mjb_register_daymode("Birth Day", 	"birth_day", 		187, 	WINSTATUS_TERRORISTS);
	mjb_register_daymode("Boxing Day", 	"boxing_day", 		200, 	WINSTATUS_DRAW);
	mjb_register_daymode("Space Day", 	"space_day", 		187, 	WINSTATUS_DRAW);
	mjb_register_daymode("Ringolevio Day", 	"ringolevio_day", 	192, 	WINSTATUS_TERRORISTS);
	mjb_register_daymode("Ghost Day", 	"ghost_day", 		180, 	WINSTATUS_CTS);
	mjb_register_daymode("Hide N Seek Day", "zmurka_day", 		240, 	WINSTATUS_TERRORISTS);
	mjb_register_daymode("Snowball Day", 	"snowball_day", 	175, 	WINSTATUS_DRAW);
	mjb_register_daymode("Paintball Day", 	"paintball_day", 	175, 	WINSTATUS_DRAW);             
}

register_events() {
	register_clcmd("drop", "ClCmd_Drop");
	register_clcmd("mjb_dm_wpn_cake", "ClCmd_WpnCake");
	register_impulse(100, "Client_FlashlightImpulse");
	DisableHamForward(g_iGrenadeTouchForward = RegisterHam(Ham_Touch, "grenade", "HamHook_Touch_Grenade_Post", true));
	DisableHamForward(g_iTraceAttackPre = RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_Pre", 0));
	//DisableHamForward(g_iTakeDamagePre = RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Pre", 0));
	DisableHamForward(g_iKilledPost = RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", 1));
}

public plugin_natives() {
	register_library("MJB_Core");
	
	register_native("mjb_dm_get_wait_timerid", "native_dm_get_wait_timerid");
}

public native_dm_get_wait_timerid() {
	return g_iWaitTimer;
}

/*===== <- Plugin Initializer <- =====*///}

/*===== -> Events -> =====*///{
public ClCmd_WpnCake(id)
{
	engclient_cmd(id, "weapon_smokegrenade");
	return PLUGIN_HANDLED;
}

public ClCmd_Drop(id)
{
	if (IsDayUID("ghost_day"))
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public Client_FlashlightImpulse(id)
{
	if (IsDayUID("zmurka_day"))
		return Zmurka_FlashlightImpulse(id);
	return PLUGIN_CONTINUE
}

public FakeMeta_SetModel_Post(iEntity, const szModel[]) 
{
	if (mjb_get_phase() != PHASE_GAMEDAY_ACTIVE)
		return FMRES_IGNORED;
	
	if (IsDayUID("birth_day")) {
		return Birthday_Callback_FM_SetModel(iEntity, szModel);
	}
	return FMRES_IGNORED;
}

public HamHook_Touch_Grenade_Post(iTouched, iToucher)
{
	if (IsDayUID("birth_day"))
		Birthday_Callback_Touch_Grenade(iTouched, iToucher);
}

public FakeMeta_AddToFullPack_Post(ES_Handle, iE, iEntity, iHost, iHostFlags, iPlayer, pSet)
{
	if (IsDayUID("ringolevio_day"))
		return Ringolevio_AddToFullPack_Post(ES_Handle, iE, iEntity, iHost, iHostFlags, iPlayer, pSet);
	return FMRES_IGNORED;
}

public FakeMeta_CheckVisibility(iEntity, pSet)
{
	if (IsDayUID("ringolevio_day"))
		return Ringolevio_CheckVisibility(iEntity, pSet);
	return FMRES_IGNORED;
}

public FakeMeta_EmitSound(id, iChannel, szSample[], Float:flVolume, Float:flAttn, iFlag, iPitch) {
	if (IsDayUID("ghost_day"))
		return GhostDay_EmitSound(id, iChannel, szSample, flVolume, flAttn, iFlag, iPitch);
	return FMRES_IGNORED;
}

public client_disconnected(id)
{
	if (IsDayUID("ringolevio_day"))
		Ringolevio_ClientDisconnected(id);
}

public Ham_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vecDirection[3], iTrace, iBitDamage)
{
	if (IsDayUID("ringolevio_day"))
		return Ringolevio_TraceAttack_Pre(iVictim, iAttacker, fDamage, vecDirection, iTrace, iBitDamage);
	//else if (IsDayUID("prisedent_day"))
	//	return President_TraceAttack_Pre(iVictim, iAttacker, fDamage, vecDirection, iTrace, iBitDamage);
	return HAM_IGNORED;
}

/*public Ham_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, damagebits)
{
	if (IsDayUID("prisedent_day"))
		return President_TakeDamage_Pre(iVictim, iInflictor, iAttacker, fDamage, damagebits);
	return HAM_IGNORED;
}*/

public mjb_update_melee_pre(id, iMelee) 
{
	if (IsDayUID("ringolevio_day"))
		return Ringolevio_UpdateMelee_Pre(id, iMelee);
	else if (IsDayUID("ghost_day"))
		return GhostDay_UpdateMelee_Pre(id, iMelee);
	return PLUGIN_CONTINUE;
}

public MJB_PreGetDesiredSkin(id, model[], len, &body, &skin)
{
	if (IsDayUID("ghost_day")) {
		return GhostDay_PreGetDesiredSkin(id, model, len, body, skin);
	}
	return PLUGIN_CONTINUE;
}

public Ham_PlayerKilled_Post(iVictim, iAttacker, iGib) {
	GhostDay_PlayerKilledPost(iVictim, iAttacker, iGib);
}

public mjb_timer_ended(iTimerId) 
{
	if (iTimerId != g_iWaitTimer)
		return;
	if (IsDayUID("prisedent_day"))
		President_WaitTimerEnded(iTimerId);
	if (IsDayUID("zmurka_day"))
		Zmurka_WaitTimerEnded(iTimerId);
}

public mjb_vote_results_processed(iDayMode, DayModeUID[]) {
	if (equal(DayModeUID, "birth_day")) {
		Birthday_Init();
	} else if (equal(DayModeUID, "boxing_day")) {
		BoxingDay_Init();
	} else if (equal(DayModeUID, "space_day")) {
		SpaceDay_Init();
	} else if (equal(DayModeUID, "ringolevio_day")) {
		Ringolevio_Init();
	} else if (equal(DayModeUID, "prisedent_day")) {
		President_Init();
	} else if (equal(DayModeUID, "zmurka_day")) {
		Zmurka_Init();
	} else if (equal(DayModeUID, "ghost_day")) {
		GhostDay_Init();
	} 
}

public mjb_daymode_ended(iDayMode, DayModeUID[], WinStatus:WinTeam) {
	if (equal(DayModeUID, "birth_day")) {
		Birthday_End(WinTeam);
	} else if (equal(DayModeUID, "boxing_day")) {
		BoxingDay_End();
	} else if (equal(DayModeUID, "space_day")) {
		SpaceDay_End();
	} else if (equal(DayModeUID, "ringolevio_day")) {
		Ringolevio_End(WinTeam);
	} else if (equal(DayModeUID, "prisedent_day")) {
		President_End();
	} else if (equal(DayModeUID, "zmurka_day")) {
		Zmurka_End(WinTeam);
	} else if (equal(DayModeUID, "ghost_day")) {
		GhostDay_End(WinTeam);
	}
}
/*===== <- Events <- =====*///}

/*===== -> President day Block -> =====*///{
President_Init() {
	mjb_open_cell();
	g_iWaitTime = 15;
	StartWaitTimer();
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i, false);
		rg_give_item(i, "weapon_knife");
		set_pev(i, pev_armorvalue, 0.0);
		switch(GetTeam(i)) {
			case PRISONER: {
				set_task(0.1, "TaskFreezeAndBlind", i+1724);
			}
			case GUARD: {
				rg_give_item(i, "weapon_ak47", GT_APPEND);
				rg_give_item(i, "weapon_awp", GT_APPEND);
				rg_give_item(i, "weapon_m4a1", GT_APPEND);
				rg_give_item(i, "weapon_deagle", GT_APPEND);
				rg_set_user_bpammo(i, WEAPON_AK47, 5000);
				rg_set_user_bpammo(i, WEAPON_AWP, 5000);
				rg_set_user_bpammo(i, WEAPON_M4A1, 5000);
				rg_set_user_bpammo(i, WEAPON_DEAGLE, 5000);
				set_pev(i, pev_health, 511.0);
			}
		}
	}
	mjb_block_game_behaviour();
	//EnableHamForward(g_iTraceAttackPre);
	//EnableHamForward(g_iTakeDamagePre);
}

/*public President_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vecDirection[3], iTrace, iBitDamage) {
	if (GetTeam(iVictim) == PRISONER && GetTeam(iAttacker) == GUARD && mjb_is_timer_running(g_iWaitForGuardsTimer))
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public President_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, damagebits) {
	if (GetTeam(iVictim) == PRISONER && GetTeam(iAttacker) == GUARD && mjb_is_timer_running(g_iWaitForGuardsTimer))
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}*/

public President_WaitTimerEnded(iTimerId) {
	for (new i = 0; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || GetTeam(i) != PRISONER)
			continue;
		UnBlindPlayer(i);
		if (is_user_alive(i)) {
			UnFreezePlayer(i);
			set_pev(i, pev_takedamage, DAMAGE_YES);
			rg_give_item(i, "weapon_ak47", GT_APPEND);
			rg_give_item(i, "weapon_awp", GT_APPEND);
			rg_give_item(i, "weapon_m4a1", GT_APPEND);
			rg_give_item(i, "weapon_deagle", GT_APPEND);
			rg_set_user_bpammo(i, WEAPON_AK47, 5000);
			rg_set_user_bpammo(i, WEAPON_AWP, 5000);
			rg_set_user_bpammo(i, WEAPON_M4A1, 5000);
			rg_set_user_bpammo(i, WEAPON_DEAGLE, 5000);
		}
	}
}

President_End() {
	StopWaitTimer();
	mjb_unblock_game_behaviour();
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i, false);
		rg_give_item(i, "weapon_knife");
		set_pev(i, pev_armorvalue, 0.0);
		if (GetTeam(i) == PRISONER) {
			if (mjb_is_timer_running(g_iWaitTimer)) {
				UnBlindPlayer(i);
				UnFreezePlayer(i);
				set_pev(i, pev_takedamage, DAMAGE_YES);
			}
		}
	}
	//DisableHamForward(g_iTraceAttackPre);
	//DisableHamForward(g_iTakeDamagePre);
}

/*===== <- President day Block <- =====*///}

/*===== -> Birthday Block -> =====*///{
Birthday_Init() {
	mjb_open_cell();
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i, false);
		switch(GetTeam(i)) {
			case PRISONER: {
				set_pev(i, pev_gravity, 0.3);
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
	EnableHamForward(g_iGrenadeTouchForward);
	g_iFakeMetaSetModel = register_forward(FM_SetModel, "FakeMeta_SetModel_Post", true);
}

Birthday_Precache_Resources() {
	for (new i; i < sizeof(g_CakeModel); i++) {
		precache_model(g_CakeModel[i]);
	}
	g_pCakeIndex = engfunc(EngFunc_PrecacheModel, "sprites/cake_explosion.spr");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/cake_explosion.wav");
	engfunc(EngFunc_PrecacheGeneric, "sprites/wpn_cake.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/mjb_dm_wpn_cake.txt");
}

public Birthday_Callback_Touch_Grenade(iTouched, iToucher) {
	if(!pev_valid(iTouched)) return;
	new Float:vecOrigin[3];
	pev(iTouched, pev_origin, vecOrigin);
	if(pev_valid(iToucher) == 2)
	{
		new iOwner = pev(iTouched, pev_owner);
		if(mjb_is_valid_player(iToucher))
		{
			if(GetTeam(iToucher) == PRISONER) ExecuteHamB(Ham_TakeDamage, iToucher, iOwner, iOwner, 50.0, DMG_SONIC);
			UTIL_ScreenFade(iToucher, (1<<12), (1<<12), 0, 24, 10, 10, 250);
		}
		else ExecuteHamB(Ham_TakeDamage, iToucher, iOwner, iOwner, 50.0, DMG_SONIC);
	}
	else CREATE_WORLDDECAL(vecOrigin, g_pDecalIndex[random_num(0, 3)]);
	CREATE_SPRITE(vecOrigin, g_pCakeIndex, 15, 255);
	emit_sound(iTouched, CHAN_AUTO, "MOON_JB/DayModes/cake_explosion.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pev(iTouched, pev_flags, pev(iTouched, pev_flags) | FL_KILLME);
}

public Birthday_Callback_FM_SetModel(iEntity, const szModel[]) {
	if (equal(szModel, "models/w_smokegrenade.mdl")) {
		engfunc(EngFunc_SetModel, iEntity, g_CakeModel[2]);
		new Float:vecVelocity[3];
		pev(iEntity, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 1.5, vecVelocity);
		set_pev(iEntity, pev_velocity, vecVelocity);
		engfunc(EngFunc_SetSize, iEntity, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0});
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

Birthday_End(WinStatus:WinTeam) {
	mjb_unblock_game_behaviour();
	DisableHamForward(g_iGrenadeTouchForward);
	unregister_forward(FM_SetModel, g_iFakeMetaSetModel, true);
	new i, iEntity, iOwner;
	for(i = 1; i <= MAX_PLAYERS; i++)
			{
				if(!mjb_is_valid_player(i) || !is_user_alive(i) || GetTeam(i) != GUARD)
					continue;
		
				if(WinTeam == WINSTATUS_CTS) rg_remove_all_items(i);
				else ExecuteHamB(Ham_Killed, i, i, 0);
			}
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "grenade")))
	{
		if(!pev_valid(iEntity)) continue;
		iOwner = pev(iEntity, pev_owner);
		if(mjb_is_valid_player(iOwner)) set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
	}
}
/*===== <- Birthday Block <- =====*///}

/*===== -> BoxingDay Block -> =====*///{
BoxingDay_Init() {
	mjb_open_cell();
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i);
		rg_give_item(i, "weapon_knife");
		set_pev(i, pev_armorvalue, 0.0);
		switch(GetTeam(i)) {
			case PRISONER: {
				set_pev(i, pev_health, 50.0);
				mjb_set_user_melee(i, MELEE_BOXING_RED);
			}
			case GUARD: {
				set_pev(i, pev_health, 150.0);
				mjb_set_user_melee(i, MELEE_BOXING_BLUE);
				
			}
		}
	}
	mjb_block_game_behaviour();
}

BoxingDay_End() {
	mjb_unblock_game_behaviour();
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;

		mjb_set_user_melee(i);
	}
}
/*===== <- BoxingDay Block <- =====*///}

/*===== -> SpaceDay Block -> =====*///{
SpaceDay_Init() {
	mjb_open_cell();
	set_lights("c");
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i);
		rg_give_item(i, "weapon_scout");
		rg_set_user_bpammo(i, WEAPON_SCOUT, 5000);
		set_pev(i, pev_armorvalue, 100.0);
		set_pev(i, pev_health, 511.0);
		set_pev(i, pev_gravity, 0.2);
	}
	mjb_block_game_behaviour();
}

SpaceDay_End() {
	mjb_unblock_game_behaviour();
	set_lights("#OFF");
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;

		rg_remove_all_items(i);
		rg_give_item(i, "weapon_knife");
		set_pev(i, pev_gravity, 1.0);
	}
}
/*===== <- SpaceDay Block <- =====*///}

/*===== -> Ringolevio Block -> =====*///{
Ringolevio_Init() {
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_alive(i)) continue;
		rg_remove_all_items(i);
		rg_give_item(i, "weapon_knife");
		set_pev(i, pev_gravity, 0.3);
		mjb_open_cell();
		switch(GetTeam(i))
		{
			case PRISONER:
			{
				set_pev(i, pev_maxspeed, 380.0);
				g_iUserLife[i] = 3;
			}
			case GUARD:
			{
				message_begin(MSG_ONE, MsgId_WeaponList, _, i);
				write_string("mjb_dm_wpn_candycane");
				write_byte(-1); // no primary ammo
				write_byte(-1);
				write_byte(-1); // no secondary ammo
				write_byte(-1);
				write_byte(2);  // knife slot
				write_byte(1);  // position
				write_byte(CSW_KNIFE);
				write_byte(0);
				message_end();
				static iszViewModel, iszWeaponModel;
				if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString,     "models/MOON_JB/DayModes/v_candy_cane.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
				if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/MOON_JB/DayModes/p_candy_cane.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				set_pev(i, pev_maxspeed, 400.0);
			}
		}
	}
	mjb_block_game_behaviour();
	EnableHamForward(g_iTraceAttackPre);
	g_iFakeMetaAddToFullPack = register_forward(FM_AddToFullPack, "FakeMeta_AddToFullPack_Post", 1);
	g_iFakeMetaCheckVisibility = register_forward(FM_CheckVisibility, "FakeMeta_CheckVisibility", 0);
}

Ringolevio_Precache_Resources() {
	engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/p_candy_cane.mdl");
	engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/v_candy_cane.mdl");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/defrost_player.wav");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/freeze_player.wav");
	engfunc(EngFunc_PrecacheModel, "sprites/MOON_JB/death_timer.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/MOON_JB/wpn_candycane.spr");
	g_pSpriteFrost = engfunc(EngFunc_PrecacheModel, "sprites/frostgib.spr");
	g_pModelFrost = engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/frostgibs.mdl");
}

public Ringolevio_AddToFullPack_Post(ES_Handle, iE, iEntity, iHost, iHostFlags, iPlayer, pSet)
{
	if(!pev_valid(iEntity) || pev(iEntity, pev_iuser1) != IUSER1_DEATH_TIMER) return FMRES_IGNORED;
	if(GetTeam(iHost) == 2)
	{
		static iEffects;
		if(!iEffects) iEffects = get_es(ES_Handle, ES_Effects);
		set_es(ES_Handle, ES_Effects, iEffects | EF_NODRAW);
		return FMRES_IGNORED;
	}
	new Float:vecHostOrigin[3], Float:vecEntityOrigin[3], Float:vecEndPos[3], Float:vecNormal[3];
	pev(iHost, pev_origin, vecHostOrigin);
	pev(iEntity, pev_origin, vecEntityOrigin);
	new pTr = create_tr2();
	engfunc(EngFunc_TraceLine, vecHostOrigin, vecEntityOrigin, IGNORE_MONSTERS, iEntity, pTr);
	get_tr2(pTr, TR_vecEndPos, vecEndPos);
	get_tr2(pTr, TR_vecPlaneNormal, vecNormal);
	xs_vec_mul_scalar(vecNormal, 10.0, vecNormal);
	xs_vec_add(vecEndPos, vecNormal, vecNormal);
	set_es(ES_Handle, ES_Origin, vecNormal);
	new Float:fDist, Float:fScale;
	fDist = get_distance_f(vecNormal, vecHostOrigin);
	fScale = fDist / 300.0;
	if(fScale < 0.4) fScale = 0.4;
	else if(fScale > 1.0) fScale = 1.0;
	set_es(ES_Handle, ES_Scale, fScale);
	set_es(ES_Handle, ES_Frame, g_fUserDeathTimer[pev(iEntity, pev_iuser2)]);
	free_tr2(pTr);
	return FMRES_IGNORED;
}

public Ringolevio_CheckVisibility(iEntity, pSet)
{
	if(!pev_valid(iEntity) || pev(iEntity, pev_iuser1) != IUSER1_DEATH_TIMER) return FMRES_IGNORED;
	forward_return(FMV_CELL, 1);
	return FMRES_SUPERCEDE;
}

public Ringolevio_ClientDisconnected(id) {
	if(IsFreezed(id))
	{
		UnFreezePlayer(id);
		if(pev_valid(g_iUserEntityTimer[id])) set_pev(g_iUserEntityTimer[id], pev_flags, pev(g_iUserEntityTimer[id], pev_flags) | FL_KILLME);
	}
}

public Ringolevio_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vecDeriction[3], iTrace, iBitDamage) {
	switch(GetTeam(iAttacker))
	{
		case PRISONER: if(IsFreezed(iVictim) && GetTeam(iVictim) == PRISONER) ringolevio_user_defrost(iVictim, iAttacker);
		case GUARD: if(!IsFreezed(iVictim) && GetTeam(iVictim) == PRISONER && !task_exists(iVictim+TASK_PROTECTION_TIME)) ringolevio_user_freeze(iVictim, iAttacker);
	}
	return HAM_SUPERCEDE;
}

public Ringolevio_UpdateMelee_Pre(id, iMelee) {
	if (GetTeam(id) == GUARD)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

ringolevio_user_defrost(iVictim, iAttacker)
{
	if(task_exists(iVictim+TASK_DEATH_TIMER)) remove_task(iVictim+TASK_DEATH_TIMER);
	UnFreezePlayer(iVictim)
	fm_set_user_rendering(iVictim, kRenderFxGlowShell, 255.0, 0.0, 0.0, kRenderNormal, 0.0);
	set_task(3.0, "ringolevio_protection_time", iVictim+TASK_PROTECTION_TIME);
	UTIL_ScreenFade(iVictim, (1<<10), (1<<10), 0, 32, 164, 241, 200, 1);
	new Float:fOrigin[3];
	pev(iVictim, pev_origin, fOrigin);
	CREATE_BREAKMODEL(fOrigin, _, _, 10, g_pModelFrost, 10, 25, BREAK_GLASS);
	emit_sound(iVictim, CHAN_AUTO, "MOON_JB/DayModes/defrost_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	if(pev_valid(g_iUserEntityTimer[iVictim])) set_pev(g_iUserEntityTimer[iVictim], pev_flags, pev(g_iUserEntityTimer[iVictim], pev_flags) | FL_KILLME);
	if(iAttacker) g_iUserLife[iAttacker]++;
}

public ringolevio_protection_time(id)
{
	id -= TASK_PROTECTION_TIME;
	fm_set_user_rendering(id, kRenderFxNone, 255.0, 0.0, 0.0, kRenderNormal, 0.0);
}

ringolevio_user_freeze(iVictim, iAttacker)
{
	if(--g_iUserLife[iVictim])
	{
		FreezePlayer(iVictim);
		fm_set_user_rendering(iVictim, kRenderFxGlowShell, 32.0, 164.0, 241.0, kRenderNormal, 0.0);
		UTIL_ScreenFade(iVictim, 0, 0, 4, 32, 164, 241, 200);
		new Float:vecOrigin[3];
		pev(iVictim, pev_origin, vecOrigin);
		set_pev(iVictim, pev_origin, vecOrigin);
		vecOrigin[2] += 15.0;
		CREATE_SPRITETRAIL(vecOrigin, g_pSpriteFrost, 30, 20, 2, 20, 10);
		g_fUserDeathTimer[iVictim] = 20.0;
		ringolevio_create_death_timer(iVictim, vecOrigin);
		emit_sound(iVictim, CHAN_AUTO, "MOON_JB/DayModes/freeze_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		new iArg[1]; iArg[0] = iAttacker;
		set_task(1.0, "ringolevio_user_death_timer", iVictim+TASK_DEATH_TIMER, iArg, sizeof(iArg), "a", 20);
	}
	else ExecuteHamB(Ham_Killed, iVictim, iAttacker, 2);
}

public ringolevio_user_death_timer(const iAttacker[], iVictim)
{
	iVictim -= TASK_DEATH_TIMER;
	if(!IsFreezed(iVictim) && task_exists(iVictim+TASK_DEATH_TIMER))
	{
		remove_task(iVictim+TASK_DEATH_TIMER);
		return;
	}
	if(g_fUserDeathTimer[iVictim] -= 1.0) return;
	UnFreezePlayer(iVictim);
	fm_set_user_rendering(iVictim, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
	UTIL_ScreenFade(iVictim, (1<<10), (1<<10), 0, 32, 164, 241, 200, 1);
	ExecuteHamB(Ham_Killed, iVictim, iAttacker[0], 2);
	if(pev_valid(g_iUserEntityTimer[iVictim])) set_pev(g_iUserEntityTimer[iVictim], pev_flags, pev(g_iUserEntityTimer[iVictim], pev_flags) | FL_KILLME);
}

public ringolevio_create_death_timer(id, Float:vecOrigin[3])
{
	static iszInfoTarget = 0;
	if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) g_iUserEntityTimer[id] = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);
	if(!pev_valid(g_iUserEntityTimer[id])) return;
	vecOrigin[2] += 35.0;
	set_pev(g_iUserEntityTimer[id], pev_classname, "death_timer");
	set_pev(g_iUserEntityTimer[id], pev_origin, vecOrigin);
	set_pev(g_iUserEntityTimer[id], pev_iuser1, IUSER1_DEATH_TIMER);
	set_pev(g_iUserEntityTimer[id], pev_iuser2, id);
	engfunc(EngFunc_SetModel, g_iUserEntityTimer[id], "sprites/MOON_JB/death_timer.spr");
	fm_set_user_rendering(g_iUserEntityTimer[id], kRenderFxNone, 0.0, 0.0, 0.0, kRenderTransAdd, 255.0);
	set_pev(g_iUserEntityTimer[id], pev_solid, SOLID_NOT);
	set_pev(g_iUserEntityTimer[id], pev_movetype, MOVETYPE_NONE);
}

Ringolevio_End(WinStatus:WinTeam) {
	mjb_unblock_game_behaviour();
	DisableHamForward(g_iTraceAttackPre);
	unregister_forward(FM_AddToFullPack, g_iFakeMetaAddToFullPack, 1);
	unregister_forward(FM_CheckVisibility, g_iFakeMetaCheckVisibility, 0);
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		switch(GetTeam(i))
		{
			case PRISONER:
			{
				rg_remove_all_items(i);
				rg_give_item(i, "weapon_knife");
				if(IsFreezed(i)) ringolevio_user_defrost(i, 0);
			}
			case GUARD:
			{
				if(WinTeam == WINSTATUS_CTS) rg_remove_all_items(i);
				else ExecuteHamB(Ham_Killed, i, i, 0);
			}
		}
	}
}
/*===== <- Ringolevio Block <- =====*///}

/*===== -> Ghosts day Block -> =====*///{
public GhostDay_Init()
{
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
			
		switch(GetTeam(i))
		{
			case PRISONER:
			{
				rg_remove_all_items(i);
				rg_give_item(i, "weapon_m249");
				rg_set_user_bpammo(i, WEAPON_M249, 9999);
				rg_give_item(i, "item_assaultsuit");
				set_pev(i, pev_health, 120.0);
			}
			case GUARD:
			{
				// jbe_set_user_model(i, "jbe_dm_ghost"); we will add our own way
				rg_remove_all_items(i);
				rg_give_item(i, "weapon_knife");
				static iszViewModel, iszWeaponModel;
				if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/MOON_JB/DayModes/v_ghost.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
				if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/MOON_JB/DayModes/p_ghost.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				fm_set_user_rendering(i, kRenderFxGlowShell, 150.0, 150.0, 170.0, kRenderNormal, 0.0);
				set_pev(i, pev_movetype, MOVETYPE_NOCLIP);
				set_pev(i, pev_health, 506.0);
				set_member(i, m_bloodColor, 15);
				set_pev(i, pev_maxspeed, 320.0);
			}
		}
	}
	mjb_block_game_behaviour();
	set_lights("c");
	EnableHamForward(g_iKilledPost);
	GhostDay_Ambience_Task();
	g_iFakeMetaEmitSound = register_forward(FM_EmitSound, "FakeMeta_EmitSound", 0);
}

public GhostDay_Precache_Resources() {
	engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/v_ghost.mdl");
	engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/p_ghost.mdl");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/ghost_slash.wav");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/ghost_stab.wav");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/ghost_death.wav");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/ghost_pain.wav");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/ghost_hit.wav");
	engfunc(EngFunc_PrecacheGeneric, "sound/MOON_JB/DayModes/ghost_ambience.mp3");
}

public GhostDay_Ambience_Task()
{
	client_cmd(0, "mp3 play sound/MOON_JB/DayModes/ghost_ambience.mp3");
	set_task(126.0, "GhostDay_Ambience_Task", TASK_AMBIENCE_SOUND);
}

public GhostDay_UpdateMelee_Pre(id, iMelee) {
	if (GetTeam(id) == GUARD)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public GhostDay_PreGetDesiredSkin(id, model[], len, &body, &skin) {
	if (GetTeam(id) == GUARD) {
		formatex(model, len, "ghost");
		body = 0;
		skin = 0;
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public GhostDay_PlayerKilledPost(iVictim, iAttacker, iGib) {
	if (GetTeam(iVictim) == GUARD)
		fm_set_user_rendering(iVictim, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
}

public GhostDay_EmitSound(id, iChannel, szSample[], Float:flVolume, Float:flAttn, iFlag, iPitch)
{
	if(!mjb_is_valid_player(id) || GetTeam(id) != GUARD)
		return FMRES_IGNORED;
	
	if (contain(szSample, "knife") != -1) {
		switch(szSample[17])
		{
			case 'l': {} // knife_deploy1.wav
			case 'w': emit_sound(id, iChannel, "MOON_JB/DayModes/ghost_slash.wav", flVolume, flAttn, iFlag, iPitch); // knife_hitwall1.wav
			case 's': emit_sound(id, iChannel, "MOON_JB/DayModes/ghost_slash.wav", flVolume, flAttn, iFlag, iPitch); // knife_slash(1-2).wav
			case 'b': emit_sound(id, iChannel, "MOON_JB/DayModes/ghost_stab.wav", flVolume, flAttn, iFlag, iPitch); // knife_stab.wav
			default: emit_sound(id, iChannel,  "MOON_JB/DayModes/ghost_hit.wav", flVolume, flAttn, iFlag, iPitch); // knife_hit(1-4).wav
		}
		return FMRES_SUPERCEDE;
	}
	if(contain(szSample, "death") != -1)
	{
		emit_sound(id, iChannel, "MOON_JB/DayModes/ghost_death.wav", flVolume, flAttn, iFlag, iPitch);
		return FMRES_SUPERCEDE;
	}
	if(contain(szSample, "bhit") != -1)
	{
		emit_sound(id, iChannel, "MOON_JB/DayModes/ghost_pain.wav", flVolume, flAttn, iFlag, iPitch);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public GhostDay_End(WinStatus:WinTeam)
{
	mjb_unblock_game_behaviour();
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		switch(GetTeam(i))
		{
			case PRISONER: rg_remove_all_items(i);
			case GUARD:
			{
				if(WinTeam == WINSTATUS_CTS) rg_remove_all_items(i);
				else ExecuteHamB(Ham_Killed, i, i, 0);
				fm_set_user_rendering(i, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
			}
		}
	}
	set_lights("#OFF");
	remove_task(TASK_AMBIENCE_SOUND);
	client_cmd(0, "mp3 stop");
	DisableHamForward(g_iKilledPost);
	unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound, 0);
}
/*===== <- Ghosts day Block <- =====*///}

/*===== -> Hide N Seek Block -> =====*///{
public Zmurka_Init() {
	set_lights("b");
	mjb_open_cell();
	g_iWaitTime = 60;
	StartWaitTimer();
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i, false);
		rg_give_item(i, "weapon_knife");
		if (GetTeam(i) == GUARD) {
			rg_give_item(i, "weapon_m3", GT_APPEND);
			rg_give_item(i, "weapon_deagle", GT_APPEND);
			rg_set_user_bpammo(i, WEAPON_M3, 5000);
			rg_set_user_bpammo(i, WEAPON_DEAGLE, 5000);
			set_task(0.1, "TaskFreezeAndBlind", i+1724);
		}
	}
	server_cmd("mp_flashlight 1");
	mjb_block_game_behaviour();
}

public Zmurka_FlashlightImpulse(id) {
	if (GetTeam(id) == PRISONER) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Zmurka_WaitTimerEnded(iTimerId) {
	for (new i = 0; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i))
			continue;
		UnBlindPlayer(i);
		if (!is_user_alive(i))
			continue;
		switch(GetTeam(i)) {
			case GUARD: {
				UnFreezePlayer(i);
				set_pev(i, pev_takedamage, DAMAGE_YES);
			}
			case PRISONER: {
				FreezePlayer(i);
			}
		}
	}
}

public Zmurka_End(WinStatus:iWinTeam) {
	server_cmd("mp_flashlight 0");
	set_lights("#OFF");
	mjb_unblock_game_behaviour();
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(is_user_alive(i) && GetTeam(i) == GUARD)
		{
			if(iWinTeam == WINSTATUS_CTS) rg_remove_all_items(i);
			else ExecuteHamB(Ham_Killed, i, i, 0);
		}
	}
}
/*===== <- Hide N Seek Block <- =====*///}

/*===== -> Stocks -> =====*///{
public TaskFreezeAndBlind(taskid) {
	new id = taskid-1724
	BlindPlayer(id);
	FreezePlayer(id);
	set_pev(id, pev_takedamage, DAMAGE_NO);
}

stock StartWaitTimer()
{
	StopWaitTimer();
	g_iWaitTimer = mjb_start_timer(float(g_iWaitTime));
}

stock StopWaitTimer()
{
	if (g_iWaitTimer != -1)
	{
		mjb_stop_timer(g_iWaitTimer);
		g_iWaitTimer = -1;
	}
}

stock IsDayUID(const uid[]) {
	new data[DayModeData];
	if (!mjb_get_current_daymode(data))
		return false;
	
	if (!equal(data[DM_UID], uid))
		return false;
	return true;
}
/*===== <- Stocks <- =====*///}
