/*
	Make checks for GameDAy
*/
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <reapi>
#include <MJB_Core>

/* Plugin Definition */
#define PLUGIN "Last Request"

/* Task IDs */
#define DUEL_BEAM_TASK	5612

/* Plugin Specific Enums */
enum {
	LR_NONDUEL,
	LR_DUEL_ONESHOOT,
	LR_DUEL
};

/* Menu Related Arrays */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS + 1], g_iMenuCount[MAX_PLAYERS + 1];

/* Duel Data*/
new g_iDuelOneShootTurn;
new g_iDuellerCT = 0, g_iDuellerT = 0;
new g_iDuelType = LR_NONDUEL;
new WeaponIdType:g_iDuelWeaponId = WEAPON_NONE;
new wpnTEnt;
new wpnCTEnt;

new g_iCachedMeleeIndex[MAX_PLAYERS + 1], Float:g_fCachedGravityValue[MAX_PLAYERS + 1];

/* Forwards */
new g_fwUserSetDuel;

/* Sprites */
new g_pSpriteDuelRed, g_pSpriteDuelBlue, g_pSpriteWave;

/* Blockage Behaviour */
new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle",
	"func_tracktrain",
	"func_tank",
	"game_player_hurt",
	"func_recharge",
	"func_healthcharger",
	"game_player_equip",
	"player_weaponstrip",
	//"func_button",
	"trigger_hurt",
	"trigger_gravity",
	"armoury_entity",
	"weaponbox",
	"weapon_shield"
};
new HamHook:g_iHamHookForwards[14];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	menus_init();
	ham_weapons_init();

	RegisterHookChain(RG_CBasePlayer_TraceAttack, "OnPlayerTraceAttack_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled_Pre", false);
	
	for(new i; i <= 8; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	
	g_fwUserSetDuel = CreateMultiForward("mjb_user_set_in_duel", ET_IGNORE, FP_CELL);
	
	register_clcmd("say ", "HOOK_Say");
}

public ham_weapons_init() {
	new const g_szWeaponName[][] = {"weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade",
	"weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp",
	"weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
	"weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"};
	for(new i; i < sizeof(g_szWeaponName); i++) {
		RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponName[i], "Ham_ItemPrimaryAttack_Post", true);
		//RegisterHam(Ham_Weapon_Reload, g_szWeaponName[i], "Ham_Weapon_Reload_Pre", 0);
	}
	
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_awp", "Ham_BlockScope");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_scout", "Ham_BlockScope");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_sg550", "Ham_BlockScope");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_g3sg1", "Ham_BlockScope");
	
	register_clcmd("drop", "Cmd_BlockDrop");
}

public menus_init() {
	register_menucmd(register_menuid("LastRequestMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_LastRequestMenu");
	register_menucmd(register_menuid("ChooseGuardMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ChooseGuardMenu");
}

public plugin_precache() {
	g_pSpriteDuelRed = precache_model("sprites/MOON_JB/duel_red.spr");
	g_pSpriteDuelBlue = precache_model("sprites/MOON_JB/duel_blue.spr");
	g_pSpriteWave = precache_model("sprites/shockwave.spr");
	precache_sound("MOON_JB/Duel/nasheed.mp3");
	precache_sound("MOON_JB/Duel/badboys.mp3");
}

public plugin_natives() {
	register_library("MJB_Core");
	register_native("mjb_is_user_in_duel", "native_is_user_in_duel");
	register_native("mjb_is_users_in_duel", "native_is_users_in_duel");
	register_native("mjb_is_duel_running", "native_is_duel_running");
	register_native("mjb_block_game_behaviour", "native_block_game_behaviour");
	register_native("mjb_unblock_game_behaviour", "native_unblock_game_behaviour");
}

public native_is_user_in_duel() {
	new id = get_param(1);
	return isUserDuel(id);
}

public native_is_users_in_duel() {
	new id1 = get_param(1);
	new id2 = get_param(2);
	return isUsersDuel(id1, id2);
}

public native_is_duel_running() {
	return isDuelRunning();
}

public native_block_game_behaviour() {
	BlockGameBehaviour();
}

public native_unblock_game_behaviour() {
	UnblockGameBehaviour();
}

public mjb_state_changed(id, iOldState, iNewState) {
	if (iNewState == PRISONER_LAST)
		Show_LastRequestMenu(id);
	else if (iOldState == PRISONER_LAST)
		ClearDuel();
}

public mjb_phase_changed(iOldPhase, iNewPhase) {
	if (iNewPhase != PHASE_DAY_ENDED)
		return;
	ClearDuel();
}

public UnblockGameBehaviour() {
	for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
}

public BlockGameBehaviour() {
	for(new i; i < charsmax(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
}

public Cmd_BlockDrop(id) {
	if(isDuelRunning() && isUserDuel(id) && g_iDuelType != LR_NONDUEL)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public HamHook_EntityBlock(iEntity, id)
{
	if(isDuelRunning() && isUserDuel(id)) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public Ham_Weapon_Reload_Pre(iWpnEnt) {
	if (!isDuelRunning() || g_iDuelType != LR_DUEL_ONESHOOT)
		return HAM_IGNORED;

	new pPlayer = get_member(iWpnEnt, m_pPlayer);
	if (!isUserDuel(pPlayer))
		return HAM_IGNORED;
		
	if (g_iDuelOneShootTurn == pPlayer)
		return HAM_IGNORED;
	
	return HAM_SUPERCEDE;
}

public Ham_ItemPrimaryAttack_Post(iWpnEnt) {
	new pPlayer = get_member(iWpnEnt, m_pPlayer);
	new pPlayer2;
	
	if (!isDuelRunning())
		return;
	
	if (g_iDuelType == LR_DUEL && g_iDuelWeaponId == WEAPON_M249) {
		rg_set_user_ammo(pPlayer, WEAPON_M249, 511);
		rg_set_user_ammo(pPlayer2, WEAPON_M249, 511);
	} else if (g_iDuelType == LR_DUEL_ONESHOOT) {
		if (pPlayer == g_iDuellerT)
			pPlayer2 = g_iDuellerCT;
		else if (pPlayer == g_iDuellerCT)
			pPlayer2 = g_iDuellerT;
			
		if (!mjb_is_valid_player(pPlayer2))
			return;
			
		new weapon = get_member(pPlayer2, m_pActiveItem);
		if (pev_valid(weapon)) {
			rg_set_user_ammo(pPlayer2, g_iDuelWeaponId, 1);
		}
		rg_set_user_ammo(pPlayer, g_iDuelWeaponId, 0);
	}
}

public Ham_BlockScope(iWpnEnt) {
	if (!isDuelRunning() || g_iDuelType != LR_DUEL_ONESHOOT)
		return HAM_IGNORED;
	
	new pPlayer = get_member(iWpnEnt, m_pPlayer);
	if (!isUserDuel(pPlayer))
		return HAM_IGNORED;
	return HAM_SUPERCEDE;
}

public OnPlayerTraceAttack_Pre(victim, attacker, Float:damage, Float:dir[3], trace, damagebits)
{
	if (!isDuelRunning())
		return HC_CONTINUE;
		
	if ((isUserDuel(victim) && !isUserDuel(attacker)) || (!isUserDuel(victim) && isUserDuel(attacker)))
		return HC_SUPERCEDE;
		
	return HC_CONTINUE;
}

public OnPlayerKilled_Pre(victim, attacker) {
	if (!isDuelRunning())
		return;
	
	if (!isUserDuel(victim))
		return;
	
	ClearDuel();
}

public client_disconnected(id) {
	if (!isUserDuel(id))
		return;
	
	if (!isDuelRunning())
		return;
	
	ClearDuel();
}

public StartDuel(iDuellerT, iDuellerCT) {
	if (isDuelRunning())
		return;

	SetUsersDuel(iDuellerT, iDuellerCT);
}

public ClearDuel() {
	if (!isDuelRunning())
		return;

	ClearUsersDuel();
}

public SetUsersDuel(iDuellerT, iDuellerCT) {
	if (!mjb_is_valid_player(iDuellerT) || !mjb_is_valid_player(iDuellerCT) || !is_user_alive(iDuellerT) || !is_user_alive(iDuellerCT))
		return 0;
	
	if (isDuelRunning())
		return 0;
	
	if (iDuellerT == iDuellerCT || GetTeam(iDuellerT) != PRISONER || GetTeam(iDuellerCT) != GUARD)
		return 0;
	
	switch(random(1)) {
		case 0 : {
			client_cmd(0, "mp3 play sound/MOON_JB/Duel/nasheed.mp3");
		}
		case 1: {
			client_cmd(0, "mp3 play sound/MOON_JB/Duel/badboys.mp3");
		}
	}
	g_iDuellerT = iDuellerT;
	g_iDuellerCT = iDuellerCT;
	rg_reset_maxspeed(g_iDuellerCT);
	rg_reset_maxspeed(g_iDuellerT);
	
	RemoveAndSaveWeapons(g_iDuellerT);
	RemoveAndSaveWeapons(g_iDuellerCT);
	
	GiveDuelWeapon(g_iDuellerT, g_iDuellerCT);
	
	CreateAttachments(g_iDuellerT, g_iDuellerCT);
	
	set_pev(g_iDuellerT, pev_health, 100.0);
	set_pev(g_iDuellerCT, pev_health, 100.0);
	set_pev(g_iDuellerT, pev_armorvalue, 100.0);
	set_pev(g_iDuellerCT, pev_armorvalue, 100.0);
	
	mjb_open_cell();
	BlockGameBehaviour();
	
	new ret;
	ExecuteForward(g_fwUserSetDuel, ret, g_iDuellerT);
	ExecuteForward(g_fwUserSetDuel, ret, g_iDuellerCT);
	return 1;
}

public CreateAttachments(iDuellerT, iDuellerCT) {
	set_rendering(iDuellerT, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
	set_rendering(iDuellerCT, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 0);
	CREATE_PLAYERATTACHMENT(iDuellerT, _, g_pSpriteDuelRed, 6000);
	CREATE_PLAYERATTACHMENT(iDuellerCT, _, g_pSpriteDuelBlue, 6000);
	set_task(1.0, "DuelBeamCylinder", DUEL_BEAM_TASK, _, _, "b");
}

public DuelBeamCylinder(taskid) {
	new Float:vecOrigin[3];
	pev(g_iDuellerT, pev_origin, vecOrigin);
	if(pev(g_iDuellerT, pev_flags) & FL_DUCKING) vecOrigin[2] -= 15.0;
	else vecOrigin[2] -= 33.0;
	CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 5, 3, _, 255, 0, 0, 255, _);
	pev(g_iDuellerCT, pev_origin, vecOrigin);
	if(pev(g_iDuellerCT, pev_flags) & FL_DUCKING) vecOrigin[2] -= 15.0;
	else vecOrigin[2] -= 33.0;
	CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 5, 3, _, 0, 0, 255, 255, _);
}

public DestroyAttachments(iDuellerT, iDuellerCT) {
	set_rendering(iDuellerT);
	set_rendering(iDuellerCT);
	if (task_exists(DUEL_BEAM_TASK)) remove_task(DUEL_BEAM_TASK);
	CREATE_KILLPLAYERATTACHMENTS(iDuellerT);
	CREATE_KILLPLAYERATTACHMENTS(iDuellerCT);
}

public GiveDuelWeapon(iDuellerT, iDuellerCT) {
	new szWpnName[32];
	//Untag because this function from amxmodx uses CSW_*
	get_weaponname(_:g_iDuelWeaponId, szWpnName, 31);
	wpnTEnt = rg_give_item(iDuellerT, szWpnName);
	wpnCTEnt = rg_give_item(iDuellerCT, szWpnName);
	if (g_iDuelType == LR_DUEL_ONESHOOT) {
		if (pev_valid(wpnTEnt))
			rg_set_user_ammo(iDuellerT, g_iDuelWeaponId, 1);
		if (pev_valid(wpnCTEnt))
			rg_set_user_ammo(iDuellerCT, g_iDuelWeaponId, 0);
	} else if (g_iDuelType == LR_DUEL) {
		if (g_iDuelWeaponId == WEAPON_M249) {
			rg_set_user_bpammo(iDuellerT, g_iDuelWeaponId, 256);
			rg_set_user_bpammo(iDuellerCT, g_iDuelWeaponId, 256);
			if (pev_valid(wpnTEnt))
				rg_set_user_ammo(iDuellerT, g_iDuelWeaponId, 511);
			if (pev_valid(wpnCTEnt))
				rg_set_user_ammo(iDuellerCT, g_iDuelWeaponId, 511);
		} else if (g_iDuelWeaponId == WEAPON_KNIFE) {
			mjb_set_user_melee(iDuellerT, MELEE_BOXING_RED);
			mjb_set_user_melee(iDuellerCT, MELEE_BOXING_BLUE);
		}
	}
}

public RemoveAndSaveWeapons(id) {
	g_iCachedMeleeIndex[id] = mjb_get_user_melee(id);
	pev(id, pev_gravity, g_fCachedGravityValue[id]);
	mjb_set_user_melee(id);
	set_pev(id, pev_gravity, 1.0);
	MJB_Print(id, "cached melee : %d", g_iCachedMeleeIndex[id]);
	rg_remove_all_items(id);
	
}

public ReturnWeapons(id) {
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return;
	mjb_set_user_melee(id, g_iCachedMeleeIndex[id]);
	set_pev(id, pev_gravity, g_fCachedGravityValue[id]);
	set_pev(id, pev_health, 100.0);
	
	rg_give_item(id, "weapon_knife");
}
public ClearUsersDuel() {
	if (!isUsersDuel(g_iDuellerT, g_iDuellerCT))
		return 0;
	
	if (!isDuelRunning())
		return 0;
	
	new iDuellerT = g_iDuellerT;
	new iDuellerCT = g_iDuellerCT;
	
	g_iDuellerT = 0;
	g_iDuellerCT = 0;
	UnblockGameBehaviour();
	rg_remove_all_items(id);
	rg_remove_all_items(id);
	ReturnWeapons(iDuellerT);
	ReturnWeapons(iDuellerCT);
	DestroyAttachments(iDuellerT, iDuellerCT);
	if (is_user_alive(iDuellerT)) {
		Show_LastRequestMenu(iDuellerT);
		//if (pev_valid(wpnCTEnt)) engfunc(EngFunc_RemoveEntity, wpnCTEnt); they cause the crash
	}
	else if (is_user_alive(iDuellerCT)) {
		//if (pev_valid(wpnTEnt)) engfunc(EngFunc_RemoveEntity, wpnTEnt); here
	}
	client_cmd(0,  "mp3 stop");
	return 1;
}

public GetUsersDuel(&iDuellerT, &iDuellerCT) {
	iDuellerT = g_iDuellerT;
	iDuellerCT = g_iDuellerCT;
}

public isUsersDuel(id1, id2) {
	if (!isUserDuel(id1) || !isUserDuel(id2))
		return 0;
	return 1;
}

public isUserDuel(id) {
	if (g_iDuellerT == id || g_iDuellerCT == id)
		return 1;
	return 0;
}

public isDuelRunning() {
	if (!mjb_is_valid_player(g_iDuellerT) || !mjb_is_valid_player(g_iDuellerCT))
		return 0;
	return 1;
}

public HOOK_Say(id) {
	new args[256];
	read_args(args, 255);
	
	if (containi(args, "/last") != -1 || containi(args, "/lr") != -1) {
		Show_LastRequestMenu(id);
	}
}

/* =========================
	MENUS
	MENUS
	MENUS
	MENUS
	MENUS
========================= */
public CanOpenLastRequestMenu(id) {
	if (!mjb_is_valid_player(id) || !is_user_alive(id) || GetTeam(id) != PRISONER || mjb_get_state(id) != PRISONER_LAST || isUserDuel(id))
		return MJB_False;
	return MJB_True;
}

public Show_LastRequestMenu(id) {
	if (!CanOpenLastRequestMenu(id))
		return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \w| \wLast Request^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wDeagle^n");
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wGlock18^n");
	iKeys |= (1<<1);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wUSP^n");
	iKeys |= (1<<2);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wAWP \yNo Scope^n", id);
	iKeys |= (1<<3);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wM3^n");
	iKeys |= (1<<4);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \wAK47^n");
	iKeys |= (1<<5);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7\d. \wM249 \yInfinite Ammo^n");
	iKeys |= (1<<6);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8\d. \wBoxing^n");
	iKeys |= (1<<7);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9\d. \wTake Freeday Next Round^n");
	iKeys |= (1<<8);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "LastRequestMenu");
}

public Handle_LastRequestMenu(id, iKeys) {
	if (!CanOpenLastRequestMenu(id))
		return PLUGIN_HANDLED;
		
	switch(iKeys) {
		case 0: {
			g_iDuelType = LR_DUEL_ONESHOOT;
			g_iDuelWeaponId = WEAPON_DEAGLE;
		}
		case 1: {
			g_iDuelType = LR_DUEL_ONESHOOT;
			g_iDuelWeaponId = WEAPON_GLOCK18;
		}
		case 2: {
			g_iDuelType = LR_DUEL_ONESHOOT;
			g_iDuelWeaponId = WEAPON_USP;
		}
		case 3: {
			g_iDuelType = LR_DUEL_ONESHOOT;
			g_iDuelWeaponId = WEAPON_AWP;
		}
		case 4: {
			g_iDuelType = LR_DUEL_ONESHOOT;
			g_iDuelWeaponId = WEAPON_M3;
		}
		case 5: {
			g_iDuelType = LR_DUEL_ONESHOOT;
			g_iDuelWeaponId = WEAPON_AK47;
		}
		case 6: {
			g_iDuelType = LR_DUEL;
			g_iDuelWeaponId = WEAPON_M249;
		}
		case 7: {
			g_iDuelType = LR_DUEL;
			g_iDuelWeaponId = WEAPON_KNIFE;
		}
		case 8: {
			g_iDuelType = LR_NONDUEL;
			mjb_set_user_freeday_nextday(id);
			user_kill(id, 1);
		}
		case 9: {
			return PLUGIN_HANDLED;
		}
	}
	if (g_iDuelType != LR_NONDUEL)
		return Cmd_ChooseGuardMenu(id);
	return PLUGIN_HANDLED;
}

public Cmd_ChooseGuardMenu(id) {
	ResetMenuPlayers(id);
	new pl[32], iPlayersNum;
	get_players(pl, iPlayersNum, "h");
	
	new j = 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		if (!mjb_is_valid_player(pl[i]) || !is_user_alive(pl[i]) || GetTeam(pl[i]) != GUARD)
			continue;
	
		g_iMenuPlayers[id][j++] = pl[i];
	}
	
	g_iMenuCount[id] = j;
	return Show_ChooseGuardMenu(id, g_iMenuPosition[id] = 0);
}

Show_ChooseGuardMenu(id, iPos)
{
	if(iPos < 0 || !CanOpenLastRequestMenu(id))
		return PLUGIN_HANDLED;
	
	show_menu(id, 0, "^n", 1);
	
	if(g_iMenuCount[id] == 0)
	{
		MJB_Print(id, "!nNo guards found.");
		return PLUGIN_HANDLED;
	}
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart >= g_iMenuCount[id]) iStart = g_iMenuCount[id] - PLAYERS_PER_PAGE;
	if(iStart < 0) iStart = 0;
	iStart -= (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iMenuCount[id]) iEnd = g_iMenuCount[id];
	
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount[id] / PLAYERS_PER_PAGE + ((g_iMenuCount[id] % PLAYERS_PER_PAGE) ? 1 : 0));
	
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \yChoose a Guard\w[%d|%d]^n^n", g_iMenuPosition[id] + 1, iPagesNum);
	
	new szName[32], tempid, iKeys = (1<<9), b = 0;
	
	for(new a = iStart; a < iEnd; a++)
	{
		tempid = g_iMenuPlayers[id][a];
		get_user_name(tempid, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\y[%d] \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount[id])
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \w%s^n\r[\y0\r] \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Back" : "Exit");
	
	return show_menu(id, iKeys, szMenu, -1, "ChooseGuardMenu");
}

public Handle_ChooseGuardMenu(id, iKey)
{
	if(!CanOpenLastRequestMenu(id)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_ChooseGuardMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_ChooseGuardMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(index >= g_iMenuCount[id])
				return Show_ChooseGuardMenu(id, g_iMenuPosition[id]);
			
			new iTarget = g_iMenuPlayers[id][index];
			if(!mjb_is_valid_player(iTarget) || !is_user_alive(iTarget) || GetTeam(iTarget) != GUARD)
				return Show_ChooseGuardMenu(id, g_iMenuPosition[id]);
			
			if (g_iDuelType != LR_NONDUEL && g_iDuelWeaponId != WEAPON_NONE)
				StartDuel(id, iTarget);
		}
	}
	
	return PLUGIN_HANDLED;
}

stock ResetMenuPlayers(id)
{
	g_iMenuCount[id] = 0;
	
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		g_iMenuPlayers[id][i] = 0;
	}
}
