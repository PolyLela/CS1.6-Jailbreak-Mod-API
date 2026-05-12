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
#include <fakemeta>
#include <MJB_Core>

#define PLUGIN "Main Menu"

new g_bMainMenuBlocked = MJB_False;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("chooseteam", "Hook_ChooseTeam");
	register_menucmd(register_menuid("MainMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainMenu");
	register_menucmd(register_menuid("TeamMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_TeamMenu");
	register_menucmd(register_menuid("WeaponsMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_WeaponsMenu");
	register_menucmd(register_menuid("PistolsMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_PistolsMenu");
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

public Hook_ChooseTeam(id) {
	MainMenu(id);
	return PLUGIN_HANDLED;
}

public mjb_life_state_changed(id, isAlive) {
	if (!isAlive || mjb_get_team(id) != GUARD)
		return;
	WeaponsMenu(id);
}

public MainMenu(id) {
	if (g_bMainMenuBlocked)
		return PLUGIN_HANDLED;
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\rMOON JB \w| \wMain Menu^n", id);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d https://discord.gg/XkD8tZe^n", id);
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
	
	if (!mjb_simon_exists() && mjb_get_team(id) == GUARD)
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
			if (mjb_is_user_in_duel(id)) {
				MJB_Print(id, "!nYou can't access this command you are in a duel");
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /hats");
		}
		case 1: {
			if (mjb_is_user_in_duel(id)) {
				MJB_Print(id, "!nYou can't access this command you are in a duel");
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /shop");
		}
		case 2: { 
			return TeamMenu(id);
		}
		case 3: {
			if (mjb_is_user_in_duel(id)) {
				MJB_Print(id, "!nYou can't access this command you are in a duel");
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /pmodmenu");
		}
		case 4: { 
			client_cmd(id, "say /paymentinfo");
		}
		case 5: { 
			if (mjb_is_user_in_duel(id)) {
				MJB_Print(id, "!nYou can't access this command you are in a duel");
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /vipmenu");
		}
		case 6: { 
			if (mjb_is_user_in_duel(id)) {
				MJB_Print(id, "!nYou can't access this command you are in a duel");
				return PLUGIN_HANDLED;
			}
			client_cmd(id, "say /svipmenu");
		}
		case 7: { 
			client_cmd(id, "say /prices");
		}
		case 8: {
			if (mjb_is_user_in_duel(id)) {
				MJB_Print(id, "!nYou can't access this command you are in a duel");
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
				if (mjb_get_team(pl[i]) == GUARD)
					ctnum++;
				else if (mjb_get_team(pl[i]) == PRISONER)
					tnum++;
			}
			if (3 * ctnum > tnum) {
				MJB_Print(id, "!nUnable to change team to guards due to unbalance");
				return PLUGIN_HANDLED;
			}
			mjb_set_team(id, GUARD, MJB_True);
			MJB_Print(id, "!tYou changed your team to guards");
		}
		case 1: {
			mjb_set_team(id, PRISONER, MJB_True);
			MJB_Print(id, "!tYou changed your team to prisoners");
		}
		case 9: {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public WeaponsMenu(id){
	if (mjb_get_team(id) != GUARD || mjb_is_user_in_duel(id))
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
	if (mjb_get_team(id) != GUARD || mjb_is_user_in_duel(id))
		return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:{
			fm_strip_user_weapons(id)
			fm_give_item(id, "weapon_knife")
			fm_give_item(id, "weapon_ak47")
			fm_set_user_bpammo(id, CSW_AK47, 250)
		}
		case 1:{
			fm_strip_user_weapons(id)
			fm_give_item(id, "weapon_knife")
			fm_give_item(id, "weapon_m4a1")
			fm_set_user_bpammo(id, CSW_M4A1, 250)
		}
		case 2:{
			fm_strip_user_weapons(id)
			fm_give_item(id, "weapon_knife")
			fm_give_item(id, "weapon_awp")
			fm_set_user_bpammo(id, CSW_AWP, 250)
		}
		case 3:{
			fm_strip_user_weapons(id)
			fm_give_item(id, "weapon_knife")
			fm_give_item(id, "weapon_xm1014")
			fm_set_user_bpammo(id, CSW_XM1014, 250)
		}
		case 4:{
			fm_strip_user_weapons(id)
			fm_give_item(id, "weapon_knife")
			fm_give_item(id, "weapon_famas")
			fm_set_user_bpammo(id, CSW_FAMAS, 250)
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_PistolsMenu(id);
}

public Show_PistolsMenu(id)
{
	if (mjb_get_team(id) != GUARD || mjb_is_user_in_duel(id))
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
	if (mjb_get_team(id) != GUARD || mjb_is_user_in_duel(id))
		return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			fm_give_item(id, "weapon_deagle")
			fm_set_user_bpammo(id, CSW_DEAGLE, 250)
		
		}
		case 1:
		{
			fm_give_item(id, "weapon_usp")
			fm_set_user_bpammo(id, CSW_USP, 250)
		
		}
		case 2:
		{
			fm_give_item(id, "weapon_glock18")
			fm_set_user_bpammo(id, CSW_GLOCK18, 250)
		
		}
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}