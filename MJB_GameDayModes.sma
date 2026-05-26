#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <MJB_Core>

#define PLUGIN "Gameday Modes"

/* Global Definitions */
#define MsgId_WeaponList 78

/* Event Handlers */
new HamHook:g_iGrenadeTouchForward, HamHook:g_iTraceAttack;
//HamHook:g_iKilledPost;
new g_iFakeMetaSetModel;
new g_iFakeMetaAddToFullPack, g_iFakeMetaCheckVisibility;

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
	g_pDecalIndex[0] = engfunc(EngFunc_DecalIndex,"{blood1");
	g_pDecalIndex[1] = engfunc(EngFunc_DecalIndex,"{blood2");
	g_pDecalIndex[2] = engfunc(EngFunc_DecalIndex,"{blood3");
	g_pDecalIndex[3] = engfunc(EngFunc_DecalIndex,"{blood4");
}

register_daymodes() {
	mjb_register_daymode("Sparta Day", "sparta_day", 187);
	mjb_register_daymode("Predator Day", "pred_day", 187);
	mjb_register_daymode("Birth Day", "birth_day", 187);
	mjb_register_daymode("Boxing Day", "boxing_day", 187);
	mjb_register_daymode("Space Day", "space_day", 187);
	mjb_register_daymode("Ringolevio Day", "ringolevio_day", 192);
	mjb_register_daymode("Zmurka Day", "zmurka_day", 187);
}

register_events() {
	register_clcmd("mjb_dm_wpn_cake", "ClCmd_WpnCake");
	DisableHamForward(g_iGrenadeTouchForward = RegisterHam(Ham_Touch, "grenade", "HamHook_Touch_Grenade_Post", true));
	DisableHamForward(g_iTraceAttack = RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_Pre", 0));
	//DisableHamForward(g_iKilledPost = RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", 1));
}

/*===== <- Plugin Initializer <- =====*///}

/*===== -> Events -> =====*///{
public ClCmd_WpnCake(id)
{
	engclient_cmd(id, "weapon_smokegrenade");
	return PLUGIN_HANDLED;
}

public FakeMeta_SetModel_Post(iEntity, const szModel[]) {
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

public client_disconnected(id)
{
	if (IsDayUID("ringolevio_day"))
		Ringolevio_ClientDisconnected(id);
}

public Ham_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vecDirection[3], iTrace, iBitDamage)
{
	if (IsDayUID("ringolevio_day"))
		return Ringolevio_TraceAttack_Pre(iVictim, iAttacker, fDamage, vecDirection, iTrace, iBitDamage);
	return HAM_IGNORED;
}

public mjb_update_melee_pre(id, iMelee) {
	if (IsDayUID("ringolevio_day"))
		return Ringolevio_UpdateMelee_Pre(id, iMelee);
	return PLUGIN_CONTINUE;
}

//public Ham_PlayerKilled_Post(iVictim, iAttacker, iGib);

public mjb_vote_results_processed(iDayMode, DayModeUID[]) {
	if (equal(DayModeUID, "birth_day")) {
		Birthday_Init();
	} else if (equal(DayModeUID, "ringolevio_day")) {
		Ringolevio_Init();
	}
}

public mjb_daymode_ended(iDayMode, DayModeUID[], iWinTeam) {
	if (equal(DayModeUID, "birth_day")) {
		Birthday_End(iWinTeam);
	} else if (equal(DayModeUID, "ringolevio_day")) {
		Ringolevio_End(iWinTeam);
	}
}
/*===== <- Events <- =====*///}

/*===== -> Birthday Block -> =====*///{
Birthday_Init() {
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!mjb_is_valid_player(i) || !is_user_alive(i))
			continue;
		rg_remove_all_items(i, false);
		mjb_open_cell();
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

Birthday_End(iWinTeam) {
	mjb_unblock_game_behaviour();
	DisableHamForward(g_iGrenadeTouchForward);
	unregister_forward(FM_SetModel, g_iFakeMetaSetModel, true);
	new i, iEntity, iOwner;
	for(i = 1; i <= MAX_PLAYERS; i++)
			{
				if(!mjb_is_valid_player(i) || !is_user_alive(i) || GetTeam(i) != GUARD)
					continue;
		
				if(iWinTeam) rg_remove_all_items(i);
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
				static iszViewModel, iszWeaponModel;
				if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString,     "models/MOON_JB/DayModes/v_candy_cane.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
				if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/MOON_JB/DayModes/p_candy_cane.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				set_pev(i, pev_maxspeed, 400.0);
			}
		}
	}
	mjb_block_game_behaviour();
	EnableHamForward(g_iTraceAttack);
	g_iFakeMetaAddToFullPack = register_forward(FM_AddToFullPack, "FakeMeta_AddToFullPack_Post", 1);
	g_iFakeMetaCheckVisibility = register_forward(FM_CheckVisibility, "FakeMeta_CheckVisibility", 0);
}

Ringolevio_Precache_Resources() {
	engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/p_candy_cane.mdl");
	engfunc(EngFunc_PrecacheModel, "models/MOON_JB/DayModes/v_candy_cane.mdl");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/defrost_player.wav");
	engfunc(EngFunc_PrecacheSound, "MOON_JB/DayModes/freeze_player.wav");
	engfunc(EngFunc_PrecacheModel, "sprites/MOON_JB/death_timer.spr");
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

Ringolevio_End(iWinTeam) {
	mjb_close_cell();
	mjb_unblock_game_behaviour();
	DisableHamForward(g_iTraceAttack);
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
				if(iWinTeam) rg_remove_all_items(i);
				else ExecuteHamB(Ham_Killed, i, i, 0);
			}
		}
	}
}
/*===== <- Ringolevio Block <- =====*///}

/*===== -> Stocks -> =====*///{
stock IsDayUID(const uid[]) {
	new data[DayModeData];
	if (!mjb_get_current_daymode(data))
		return false;
	
	if (!equal(data[DM_UID], uid))
		return false;
	return true;
}
/*===== <- Stocks <- =====*///}
