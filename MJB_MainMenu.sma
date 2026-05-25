/*
	Make Syringe
*/

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "Main Menu"

enum _:GuardShopCvarTypes {
	GSHOP_ENABLED,
	GSHOP_PRICE_HP,
	GSHOP_PRICE_HE,
	GSHOP_PRICE_FLASH,
	GSHOP_PRICE_SMOKE,
	GSHOP_PRICE_GRAVITY,
}

enum _:PrisonerShopCvarTypes {
	PSHOP_ENABLED,
	PSHOP_PRICE_FD,
	PSHOP_PRICE_HE,
	PSHOP_PRICE_FLASH,
	PSHOP_PRICE_SMOKE,
	PSHOP_PRICE_SYRINGE,
	PSHOP_PRICE_GRAVITY
}

new g_bMainMenuBlocked = MJB_False;
new g_pcShopMenuNoScam;
new GuardShopMenuPCvars[GuardShopCvarTypes];
new PrisonerShopMenuPCvars[PrisonerShopCvarTypes];
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHookChain(RG_CBasePlayer_Spawn, "PostPlayerSpawn", true);
	register_clcmd("say", "Hook_Say");
	register_clcmd("say_team", "Hook_Say");
	register_clcmd("chooseteam", "Hook_ChooseTeam");
	menus_init();
	cvars_init();
	
}

public plugin_precache() {
	precache_sound("MOON_JB/buyfd.wav");
}

/* Events & Hooks */
public Hook_Say(id) {
	new said[192];
	if (containi(said, "/shop") == -1)
		return PLUGIN_CONTINUE;
	
	return ShowShopMenu(id);
}

public Hook_ChooseTeam(id) {
	MainMenu(id);
	return PLUGIN_HANDLED;
}

public PostPlayerSpawn(id) {
	if (!is_user_alive(id) || get_user_team(id) != GUARD || mjb_get_day_type() == GAMEDAY)
		return;

	WeaponsMenu(id);
}

/* Rules */
public bool:CanOpenWeaponMenu(id) {
	if (get_user_team(id) != GUARD || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE || !is_user_alive(id))
		return false; 
	
	if (mjb_is_user_in_duel(id))
		return false;
	return true;
}

public bool:CanOpenShopMenu(id, iShopTeam) {
	if (!is_user_alive(id) || get_user_team(id) != iShopTeam || mjb_is_user_in_duel(id))
		return false;
		
	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE)
		return false; 
		
	if ((iShopTeam == GUARD && !get_pcvar_num(GuardShopMenuPCvars[GSHOP_ENABLED])) || (iShopTeam == PRISONER && !get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_ENABLED])))
		return false;
	
	return true;
}

/* Main Menu and Followers */
public MainMenu(id) {
	if (g_bMainMenuBlocked)
		return PLUGIN_HANDLED;
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rMOON JB \w| \wMain Menu^n", id);
	new szDiscord[32];
	GetCommunityDiscord(szDiscord, 31);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d https://%s^n", szDiscord);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d      MOON JailBreak^n^n", id);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wHats \yFree^n", id);
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wShop \y[\wItems\y]^n", id);
	iKeys |= (1<<1);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wChoose Team \y[\wTeam Select\y]^n", id);
	iKeys |= (1<<2);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wPmodmenu^n", id);
	iKeys |= (1<<3);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wPayment INFO\r[\wOwner INFO\r]^n", id);
	iKeys |= (1<<4);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \wVIP Menu^n", id);
	iKeys |= (1<<5);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7\d. \wSuperVIP Menu^n", id);
	iKeys |= (1<<6);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8\d. \wRanks \r[\wPrices\r]^n", id);
	iKeys |= (1<<7);
	
	if (!mjb_simon_exists() && get_user_team(id) == GUARD)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9\d. \rTake Simon^n", id);
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9\d. \rSimon Menu^n", id);
	iKeys |= (1<<8);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "MainMenu");
}

public Handle_MainMenu(id, iKeys) {
	if (g_bMainMenuBlocked)
		return PLUGIN_HANDLED;
	switch(iKeys) {
		case 0: { 
			client_cmd(id, "say /hats");
		}
		case 1: {
			if (mjb_is_user_in_duel(id) || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
				return PLUGIN_HANDLED;
			}
			return ShowShopMenu(id);
		}
		case 2: { 
			return TeamMenu(id);
		}
		case 3: {
			if (mjb_is_user_in_duel(id) || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /pmodmenu");
		}
		case 4: { 
			client_cmd(id, "say /paymentinfo");
		}
		case 5: { 
			if (mjb_is_user_in_duel(id) || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /vipmenu");
		}
		case 6: { 
			if (mjb_is_user_in_duel(id) || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /svipmenu");
		}
		case 7: { 
			client_cmd(id, "say /prices");
		}
		case 8: {
			if (mjb_is_user_in_duel(id) || mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
				return PLUGIN_HANDLED;
			}
			if (!mjb_simon_exists())
				client_cmd(id, "say /simon");
			else
				mjb_show_simon_menu(id);
		}
		case 9: {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public ShowShopMenu(id) {
	if (GetTeam(id) == PRISONER)
		return PrisonerShopMenu(id);
	if (GetTeam(id) == GUARD)
		return PrisonerShopMenu(id);
	return PLUGIN_CONTINUE;
}

public GuardShopMenu(id) {
	if (!CanOpenShopMenu(id, GUARD))
		return PLUGIN_HANDLED;
		
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\rM\yOON JB \r| \yShop \y[\rGuards\y]^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\rYour discount: 20%^n^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \w300 Health \w[\r$\y%d\w]^n",get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_HP]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wHE Grenade \w[\r$\y%d\w]^n", get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_HE]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wFLASH Grenade \w[\r$\y%d\w]^n", get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_FLASH]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wSMOKE Grenade \w[\r$\y%d\w]^n", get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_SMOKE]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wGravity \w[\r$\y%d\w]^n", get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_GRAVITY]));
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r0\d. \wExit", id);
	return show_menu(id, iKeys, szMenu, -1, "Guard Shop Menu");
}

public Handle_GuardShopMenu(id, iKeys) {
	if (!CanOpenShopMenu(id, GUARD))
		return PLUGIN_HANDLED;
		
	new userMoney = get_member(id, m_iAccount);
	new pvNoScam = get_pcvar_num(g_pcShopMenuNoScam);
	if (iKeys < 9 && userMoney < get_pcvar_num(GuardShopMenuPCvars[iKeys+1])) {// we add one to cvar type to use it as an item cvar index because index 0 at first was for menu enabled
		return PLUGIN_HANDLED;
	}
	
	switch(iKeys) {
		case 0: {
			set_pev(id, pev_health, 300.0);
			rg_add_account(id, userMoney-get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_HP]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !g300 !tHealth");
		}
		case 1: {
			if (pvNoScam && rg_has_item_by_name(id, "weapon_hegrenade")) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			rg_give_item(id, "weapon_hegrenade");
			rg_add_account(id, userMoney-get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_HE]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gHE-Grenade");
		}
		case 2: {
			if (pvNoScam && rg_has_item_by_name(id, "weapon_flashbang") && rg_get_user_bpammo(id, WEAPON_FLASHBANG) > 2) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			rg_give_item(id, "weapon_flashbang");
			rg_add_account(id, userMoney-get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_FLASH]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gFlashbang");
		}
		case 3: {
			if (pvNoScam && rg_has_item_by_name(id, "weapon_smokegrenade")) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			rg_give_item(id, "weapon_smokegrenade");
			rg_add_account(id, userMoney-get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_SMOKE]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gSmoke Grenade");
		}
		case 4: {
			if (pvNoScam && pev(id, pev_gravity) == 0.4) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			set_pev(id, pev_gravity, 0.4);
			rg_add_account(id, userMoney-get_pcvar_num(GuardShopMenuPCvars[GSHOP_PRICE_GRAVITY]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gGravity");
		}
		case 9: {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public PrisonerShopMenu(id) {
	if (!CanOpenShopMenu(id, PRISONER))
		return PLUGIN_HANDLED;
		
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\rM\yOON JB \r| \yShop \y[\rPrisoners\y]^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\rYour discount: 20%^n^n");

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wFreeday \w[\r$\y%d\w]^n", get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_FD]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wHE Grenade \w[\r$\y%d\w]^n", get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_HE]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wFLASH Grenade \w[\r$\y%d\w]^n", get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_FLASH]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wSMOKE Grenade \w[\r$\y%d\w]^n", get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_SMOKE]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wSyringe \w[\r$\y%d\w]^n", get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_SYRINGE]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \wGravity \w[\r$\y%d\w]^n", get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_GRAVITY]));
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r0\d. \wExit");
	return show_menu(id, iKeys, szMenu, -1, "Prisoner Shop Menu");
}

public Handle_PrisonerShopMenu(id, iKeys) {
	if (!CanOpenShopMenu(id, PRISONER))
		return PLUGIN_HANDLED;
		
	new userMoney = get_member(id, m_iAccount);
	new pvNoScam = get_pcvar_num(g_pcShopMenuNoScam);
	if (iKeys < 9 && userMoney < get_pcvar_num(PrisonerShopMenuPCvars[iKeys+1])) {// we add one to cvar type to use it as an item cvar index because index 0 at first was for menu enabled
		return PLUGIN_HANDLED;
	}
	switch(iKeys) {
		case 0: {
			if (mjb_get_state(id) == PRISONER_FREEDAY || mjb_get_phase() == PHASE_FREEDAY || mjb_get_day_type() == FREEDAY) {
				mjb_set_user_freeday_nextday(id, true);
			} else {
				mjb_set_user_freeday(id);
			}
			rg_add_account(id, userMoney-get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_FD]), AS_SET, true);
			emit_sound(id, CHAN_AUTO, "MOON_JB/buyfd.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			MJB_Print(id, "!tYou have purchased !g300 !tHealth");
		}
		case 1: {
			if (pvNoScam && rg_has_item_by_name(id, "weapon_hegrenade")) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			rg_give_item(id, "weapon_hegrenade");
			rg_add_account(id, userMoney-get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_HE]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gHE-Grenade");
		}
		case 2: {
			if (pvNoScam && rg_has_item_by_name(id, "weapon_flashbang") && rg_get_user_bpammo(id, WEAPON_FLASHBANG) > 2) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			rg_give_item(id, "weapon_flashbang");
			rg_add_account(id, userMoney-get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_FLASH]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gFlashbang");
		}
		case 3: {
			if (pvNoScam && rg_has_item_by_name(id, "weapon_smokegrenade")) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			rg_give_item(id, "weapon_smokegrenade");
			rg_add_account(id, userMoney-get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_SMOKE]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gSmoke Grenade");
		}
		case 4: {
			rg_add_account(id, userMoney-get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_SYRINGE]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gSyringe");
		}
		case 5: {
			if (pvNoScam && pev(id, pev_gravity) == 0.4) {
				MJB_Print(id, "!nYou already have this item");
				return PLUGIN_HANDLED;
			}
			set_pev(id, pev_gravity, 0.4);
			rg_add_account(id, userMoney-get_pcvar_num(PrisonerShopMenuPCvars[PSHOP_PRICE_GRAVITY]), AS_SET, true);
			MJB_Print(id, "!tYou have purchased !gGravity");
		}
		case 9: {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public TeamMenu(id) {
	if (g_bMainMenuBlocked)
		return PLUGIN_HANDLED;
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wSelect a team^n", id);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\yBalance: 1 CT - 3 TT^n", id);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\rRead The Rules!^n^n", id);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[1] \wGuard [\rMicrophone Required\w]^n", id);
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[2] \wPrisoner^n", id);
	iKeys |= (1<<1);

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[0] \wExit", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "TeamMenu");
}

public Handle_TeamMenu(id, iKeys) {
	if (g_bMainMenuBlocked)
		return PLUGIN_HANDLED;
	switch(iKeys) {
		case 0: {
			new pl[32], plnum, ctnum = 0, tnum = 0;
			get_players(pl, plnum, "h");
			for (new i =0; i < plnum; i++) {
				if (get_user_team(pl[i]) == GUARD)
					ctnum++;
				else if (get_user_team(pl[i]) == PRISONER)
					tnum++;
			}
			if (3 * ctnum > tnum) {
				MJB_Print(id, "!nUnable to change team to guards due to unbalance");
				return PLUGIN_HANDLED;
			}
			rg_set_user_team(id, TEAM_CT, MODEL_AUTO, true, true);
			user_kill(id, 1);
			MJB_Print(id, "!tYou changed your team to guards");
		}
		case 1: {
			rg_set_user_team(id, TEAM_TERRORIST, MODEL_AUTO, true, true);
			user_kill(id, 1);
			MJB_Print(id, "!tYou changed your team to prisoners");
		}
		case 9: {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public WeaponsMenu(id){
	if (!CanOpenWeaponMenu(id))
		return PLUGIN_HANDLED;
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\yWeapons Menu^n^n", id);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wAK47^n", id);
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wM4A1^n", id);
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wAWP^n", id);
	iKeys |= (1<<2);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wXM1014^n", id);
	iKeys |= (1<<3);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wFAMAS^n^n", id);
	iKeys |= (1<<4);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wEXIT", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "WeaponsMenu");
}

public Handle_WeaponsMenu(id, iKey){
	if (!CanOpenWeaponMenu(id))
		return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:{
			rg_give_item(id, "weapon_ak47")
			rg_set_user_bpammo(id, WEAPON_AK47, 256)
		}
		case 1:{
			rg_give_item(id, "weapon_m4a1")
			rg_set_user_bpammo(id, WEAPON_M4A1, 256)
		}
		case 2:{
			rg_give_item(id, "weapon_awp")
			rg_set_user_bpammo(id, WEAPON_AWP, 256)
		}
		case 3:{
			rg_give_item(id, "weapon_xm1014")
			rg_set_user_bpammo(id, WEAPON_XM1014, 256)
		}
		case 4:{
			rg_give_item(id, "weapon_famas")
			rg_set_user_bpammo(id, WEAPON_FAMAS, 256)
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_PistolsMenu(id);
}

public Show_PistolsMenu(id)
{
	if (!CanOpenWeaponMenu(id))
		return PLUGIN_HANDLED;
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\yWeapons Menu^n^n", id);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wDEAGLE^n", id);
	iKeys |= (1<<0);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wUSP^n", id);
	iKeys |= (1<<1);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wGLOCK18^n^n", id);
	iKeys |= (1<<2);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wEXIT", id);
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "PistolsMenu");
}

public Handle_PistolsMenu(id, iKey)
{
	if (!CanOpenWeaponMenu(id))
		return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			rg_give_item(id, "weapon_deagle")
			rg_set_user_bpammo(id, WEAPON_DEAGLE, 2560)
		
		}
		case 1:
		{
			rg_give_item(id, "weapon_usp")
			rg_set_user_bpammo(id, WEAPON_USP, 256)
		
		}
		case 2:
		{
			rg_give_item(id, "weapon_glock18")
			rg_set_user_bpammo(id, WEAPON_GLOCK18, 256)
		
		}
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

/* Initiatilizers and Natives */
menus_init() {
	register_menucmd(register_menuid("MainMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainMenu");
	register_menucmd(register_menuid("Guard Shop Menu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_GuardShopMenu");
	register_menucmd(register_menuid("Prisoner Shop Menu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<9), "Handle_PrisonerShopMenu");
	register_menucmd(register_menuid("TeamMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_TeamMenu");

	register_menucmd(register_menuid("WeaponsMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_WeaponsMenu");
	register_menucmd(register_menuid("PistolsMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_PistolsMenu");
}

cvars_init() {
	/* first initialize guard shop menu pcvars */
	GuardShopMenuPCvars[GSHOP_ENABLED] 		= register_cvar("mjb_gr_shop_enabled", "1");
	PrisonerShopMenuPCvars[PSHOP_ENABLED] 		= register_cvar("mjb_pr_shop_enabled", "1");
	g_pcShopMenuNoScam				= register_cvar("mjb_shop_no_scam", "0");
	GuardShopMenuPCvars[GSHOP_PRICE_HP] 		= register_cvar("mjb_gr_shop_price_hp", "5000");
	GuardShopMenuPCvars[GSHOP_PRICE_HE] 		= register_cvar("mjb_gr_shop_price_he", "3000");
	GuardShopMenuPCvars[GSHOP_PRICE_FLASH] 		= register_cvar("mjb_gr_shop_price_flash", "2500");
	GuardShopMenuPCvars[GSHOP_PRICE_SMOKE] 		= register_cvar("mjb_gr_shop_price_smoke", "3500");
	GuardShopMenuPCvars[GSHOP_PRICE_GRAVITY] 	= register_cvar("mjb_gr_shop_price_gravity", "6000");
	
	/* then initialize prisoner shop menu pcvars */
	PrisonerShopMenuPCvars[PSHOP_PRICE_FD] 		= register_cvar("mjb_pr_shop_price_freeday", "16000");
	PrisonerShopMenuPCvars[PSHOP_PRICE_HE] 		= register_cvar("mjb_pr_shop_price_he", "8000");
	PrisonerShopMenuPCvars[PSHOP_PRICE_FLASH] 	= register_cvar("mjb_pr_shop_price_flash", "7000");
	PrisonerShopMenuPCvars[PSHOP_PRICE_SMOKE] 	= register_cvar("mjb_pr_shop_price_smoke", "7000");
	PrisonerShopMenuPCvars[PSHOP_PRICE_SYRINGE] 	= register_cvar("mjb_pr_shop_price_syringe", "3000");
	PrisonerShopMenuPCvars[PSHOP_PRICE_GRAVITY] 	= register_cvar("mjb_gr_shop_price_gravity", "4000");
}

public plugin_natives() {
	register_library("MJB_Core");
	
	register_native("mjb_block_main_menu", "native_block_main_menu");
	register_native("mjb_unblock_main_menu", "native_unblock_main_menu");
	register_native("mjb_show_main_menu", "native_show_main_menu");
}

public native_block_main_menu() {
	g_bMainMenuBlocked = MJB_True;
}

public native_unblock_main_menu() {
	g_bMainMenuBlocked = MJB_False;
}

public native_show_main_menu() {
	new id = get_param(1);
	MainMenu(id);
}
