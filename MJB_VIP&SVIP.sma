#include <amxmodx>
#include <reapi>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#include <MJB_Core>

#define PLUGIN "Rank Privileges"
#define SCOREATTRIB_FLAG_DEAD 1
#define SCOREATTRIB_FLAG_VIP  4

#define MAX_DISTANCE 100.0 

#define VIPMENU_CHOOSE_LIMIT 1
#define SVIPMENU_CHOOSE_LIMIT 2
#define KNIVESMENU_CHOOSE_LIMIT 1
#define SPECIALMENU_CHOOSE_LIMIT 1
#define DOOR_OPEN_LIMIT 1
#define FLASH_CHOOSE_LIMIT 1
#define TRAP_CHOOSE_LIMIT 1

enum _:Menus {
	COUNT_VIPMENU = 0,
	COUNT_SVIPMENU,
	COUNT_KNIVESMENU,
	COUNT_SPECIALMENU
};

new g_iMenuChooseCount[MAX_PLAYERS + 1][Menus];
new g_iOpenDoorCount[MAX_PLAYERS + 1], g_iFlashChooseCount[MAX_PLAYERS + 1], g_iTrapChooseCount[MAX_PLAYERS + 1];
new iBlinded[MAX_PLAYERS + 1], iTrapped[MAX_PLAYERS + 1], Float:fTrapCooldown[MAX_PLAYERS + 1];
new Float:g_fMaxSpeed[MAX_PLAYERS + 1];
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say ", "Hook_Say");
	register_clcmd("say_team ", "Hook_Say");
	
	register_event("CurWeapon", "CurWeapon", "be") // speed
	
	register_menucmd(register_menuid("VIPMenu"), (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_VIPMenu");
	register_menucmd(register_menuid("SuperMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9), "Handle_SVIPMenu");
	register_menucmd(register_menuid("WeaponMenu"), (1<<0|1<<1|1<<9), "Handle_WeaponMenu");
	register_menucmd(register_menuid("KnivesMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_KnivesMenu");
	register_menucmd(register_menuid("SpecialMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_SpecialMenu");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled_Pre", false);
	register_message(get_user_msgid("ScoreAttrib"), "Hook_ScoreAttribute");
}

public plugin_precache() {
	precache_model("models/trap.mdl");
	precache_sound("trap.wav");
}

public CurWeapon(id) {
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return;
	if (g_fMaxSpeed[id] != 0.0 && !mjb_is_user_in_duel(id))
		entity_set_float(id, EV_FL_maxspeed, g_fMaxSpeed[id]);
}

public client_putinserver(id) {
	if (!hasRank(id, RANK_VIP))
		return;
	set_task(1.0, "Show_WelcomeMsg", id);
	ResetMenusChooseCount(id);
	iBlinded[id] = MJB_False;
}

public client_disconnected(id) {
	iBlinded[id] = MJB_False;
	iTrapped[id] = MJB_False;
}

public Show_WelcomeMsg(id){ 
	if (!hasRank(id, RANK_VIP))
		return;
	new name[32];
	get_user_name(id, name, 31);
	new pl[32], plnum, tempid;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		tempid = pl[i];
		if (!mjb_is_valid_player(tempid) || tempid == id)
			continue;
		set_hudmessage(0, 255, 255, -1.0, 0.12, 0, 0.0, 3.0, 0.3, 0.5, 2);
		show_hudmessage(tempid, "Vip Client %s Connected On The Server", name)
	}
}

ShowVips(id, iSvips = 0) {
	new szVipNames[32][32], szFinalMsg[192], len;
	new pl[32], plnum, count;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		if (!mjb_is_valid_player(pl[i]) || (iSvips && !hasRank(pl[i], RANK_SVIP)) || (!iSvips && !hasRank(pl[i], RANK_VIP)))
			continue;
		get_user_name(pl[i], szVipNames[count++], charsmax(szVipNames[]));
	}
	
	if (count > 0) {
		len = formatex(szFinalMsg, charsmax(szFinalMsg), "!t%ss Currently Online : !g", (iSvips) ? "SuperVIP" : "VIP");
		for (new i = 0; i < count; i++) {
			len += formatex(szFinalMsg[len], charsmax(szFinalMsg) - len, "%s%s", szVipNames[i], ((i < (count-1)) ? "!t, " : "!t."));
		}
		} else {
		formatex(szFinalMsg, charsmax(szFinalMsg), "!gThere is no %ss Online Currently.", (iSvips) ? "SuperVIP" : "VIP");
	}
	MJB_Print(id, "%s", szFinalMsg);
	MJB_Print(id, "!tTo buy !g%s !tcontact : !g[TEMPLATE]", (iSvips) ? "SuperVIP" : "VIP");
	
}

public Hook_Say(id) {
	new said[192];
	read_args(said, charsmax(said));
	if (containi(said, "/vips") != -1) {
		ShowVips(id);
		return PLUGIN_HANDLED;
	} else if (containi(said, "/svips") != -1) {
		ShowVips(id, MJB_True);
		return PLUGIN_HANDLED;
	} else if (containi(said, "/vipmenu") != -1 || containi(said, "/vmenu") != -1) {
		VIPMenu(id);
		return PLUGIN_HANDLED;
	} else if (containi(said, "/svipmenu") != -1) {
		SVIPMenu(id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public OnPlayerSpawn_Post(id) {
	new Float:fUserHealth, Float:fUserArmor;
	if (GetTeam(id) == GUARD) {
		if (mjb_is_simon(id)) {
			fUserHealth = 511.0;
			fUserArmor = 255.0;
			} else {
			if(hasRank(id, RANK_VIP)) {
				fUserHealth = 250.0;
				fUserArmor = 200.0;
				} else {
				fUserHealth = 200.0;
				fUserArmor = 100.0;
			}
		}
		} else if (GetTeam(id) == PRISONER) {
		if(hasRank(id, RANK_VIP)) {
			fUserHealth = 150.0;
			fUserArmor = 100.0;
			} else {
			fUserHealth = 100.0;
			fUserArmor = 0.0;
		}
	}
	set_pev(id, pev_health, fUserHealth);
	set_pev(id, pev_armorvalue, fUserArmor);
	if (hasRank(id, RANK_VIP)) {
		GiveBombPackage(id);
		fm_switch_to_knife(id);
		MJB_Print(id, "!gYou got !tHe, 2xFlash, Smoke !gAnd Hp : !t%d !g|| Armor : !t%d", floatround(fUserHealth), floatround(fUserArmor));
	}
	ResetMenusChooseCount(id);
	g_fMaxSpeed[id] = 0.0;
	trap_off(id);
}

public OnPlayerKilled_Post(id) {
	unblind_player(id);
	g_fMaxSpeed[id] = 0.0;
}

public Hook_ScoreAttribute() {
	new id = get_msg_arg_int(1);
	if (mjb_is_valid_player(id) && hasRank(id, RANK_VIP)) {
		set_msg_arg_int(2, ARG_BYTE, is_user_alive(id) ? SCOREATTRIB_FLAG_VIP : SCOREATTRIB_FLAG_DEAD);
	}
}

public CanOpenVIPMenu(id) {
	if (!hasRank(id, RANK_VIP))
		return 0;
	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
		MJB_Print(id, "!nVIP Menu is disabled until gameday finishes.");
		return 0;
	}
	
	if (mjb_is_user_in_duel(id)) {
		MJB_Print(id, "!nYou can't access VIP Menu you are in a duel");
		return PLUGIN_HANDLED;
	}
	
	if (g_iMenuChooseCount[id][COUNT_VIPMENU] >= VIPMENU_CHOOSE_LIMIT) {
		MJB_Print(id, "!nYou have exceeded usage limit, wait until next day.");
		return 0;
	}
	return 1;
}

public VIPMenu(id) {
	if (!CanOpenVIPMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys = 0, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wVIP Menu^n^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wBomb Package \y[\rHe\y, \r2xFlash\y, \rSmoke\y] ^n");
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wGravity^n", id);
	iKeys |= (1<<1);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wHealth Package \y[\r170 HP\y, \r130 AP\y]^n");
	iKeys |= (1<<2);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \y1000 \wDinar^n");
	iKeys |= (1<<3);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "VIPMenu");
	
}

public Handle_VIPMenu(id, iKeys){
	if (!CanOpenVIPMenu(id))
		return PLUGIN_HANDLED;
	switch(iKeys)
	{
		case 0:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			GiveBombPackage(id);
			MJB_Print(id, "!gYou got !tHe!g, !t2xFlash!g, !tSmoke !g!");
			g_iMenuChooseCount[id][COUNT_VIPMENU]++;
		}
		case 1:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			set_pev(id, pev_gravity, 0.4);
			MJB_Print(id, "!gYou got !tGravity !g!");
			g_iMenuChooseCount[id][COUNT_VIPMENU]++;
		}
		case 2:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			set_pev(id, pev_health, 170.0);
			set_pev(id, pev_armorvalue, 130.0);
			MJB_Print(id, "!gYou got !tHP!g:!t170 !gAnd !tAP!g:!t130");
			g_iMenuChooseCount[id][COUNT_VIPMENU]++;
		}
		case 3:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			rg_add_account(id, 1000, AS_ADD, true);
			g_iMenuChooseCount[id][COUNT_VIPMENU]++;
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public CanOpenSVIPMenu(id) {
	if (!hasRank(id, RANK_SVIP)) {
		return 0;
	}
	if (mjb_get_phase() == PHASE_GAMEDAY_VOTE || mjb_get_phase() == PHASE_GAMEDAY_ACTIVE) {
		MJB_Print(id, "!nSuperVIP Menu is disabled until gameday finishes.");
		return 0;
	}
	
	if (mjb_is_user_in_duel(id)) {
		MJB_Print(id, "!nYou can't access SuperVIP Menu you are in a duel");
		return PLUGIN_HANDLED;
	}
	
	if (g_iMenuChooseCount[id][COUNT_SVIPMENU] >= SVIPMENU_CHOOSE_LIMIT) {
		MJB_Print(id, "!nYou have exceeded usage limit, wait until next day.");
		return 0;
	}
	return 1;
}

public SVIPMenu(id) {
	if (!CanOpenSVIPMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys = 0, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wSuper Vip Menu  \r[\wBy\r] \r[\wMISTER\r]^n^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wKnives ^n");
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \rHP Package^n");
	iKeys |= (1<<1);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \yDrugs^n");
	iKeys |= (1<<2);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wBomb Package^n");
	iKeys |= (1<<3);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \rGravity^n");
	iKeys |= (1<<4);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6\d. \yAmmunition^n");
	iKeys |= (1<<5);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7\d. \wSpeed^n");
	iKeys |= (1<<6);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "SuperMenu");
	
}

public Handle_SVIPMenu(id, iKeys){
	if (!CanOpenSVIPMenu(id))
		return PLUGIN_HANDLED;
	switch(iKeys)
	{
		case 0:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			
			return Show_WeaponMenu(id);
		}
		case 1:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			set_pev(id, pev_health, 170.0);
			set_pev(id, pev_armorvalue, 130.0);
			MJB_Print(id, "!gYou got !tHP!g:!t170 !gAnd !tAP!g:!t130");
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
		}
		case 2:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			
			set_user_drug(id, MJB_True);
			MJB_Print(id, "!gYou took Drugs, you were bored");
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
		}
		case 3:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			
			GiveBombPackage(id);
			MJB_Print(id, "!gYou got !tHe!g, !t2xFlash!g, !tSmoke !g!");
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
		}
		case 4:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			
			set_pev(id, pev_gravity, 0.4);
			MJB_Print(id, "!gYou got !tGravity !g!");
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
		}
		case 5:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			
			rg_set_user_bpammo(id,WEAPON_AK47,5000);
			rg_set_user_bpammo(id,WEAPON_AWP,5000);
			rg_set_user_bpammo(id,WEAPON_DEAGLE,5000);
			rg_set_user_bpammo(id,WEAPON_M249,5000);
			rg_set_user_bpammo(id,WEAPON_FAMAS,5000);
			rg_set_user_bpammo(id,WEAPON_GALIL,5000);
			rg_set_user_bpammo(id,WEAPON_GLOCK18,5000);
			rg_set_user_bpammo(id,WEAPON_XM1014,5000);
			rg_set_user_bpammo(id,WEAPON_SCOUT,5000);
			rg_set_user_bpammo(id,WEAPON_AUG,5000);
			rg_set_user_bpammo(id,WEAPON_M3,5000);
			rg_set_user_bpammo(id,WEAPON_MP5N,5000);		
			rg_set_user_bpammo(id,WEAPON_M4A1,5000);
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
		}
		case 6:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			
			g_fMaxSpeed[id] = 500.0;
			entity_set_float(id, EV_FL_maxspeed, g_fMaxSpeed[id]);
			MJB_Print(id, "!gYou got !tSpeed !g!");
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public Show_WeaponMenu(id) {
	if (!CanOpenSVIPMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys = 0, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wArms Menu^n^n");
	
	if (hasRank(id, RANK_HEAD_ADMIN)) {
		if (GetTeam(id) == PRISONER) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wSpecial Weapons \y(\dAvailable only for protection\y) ^n");
			if (hasRank(id, RANK_CO_OWNER))
				iKeys |= (1<<0);
		} else if (GetTeam(id) == GUARD) {
			if (g_iMenuChooseCount[id][COUNT_SPECIALMENU] >= SPECIALMENU_CHOOSE_LIMIT) {
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \dSpecial Weapons (Available in the next round) ^n");
				if (hasRank(id, RANK_CO_OWNER))
					iKeys |= (1<<0);
			} else {
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wSpecial Weapons ^n");
				iKeys |= (1<<0);
			}
		}
	} else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wSpecial Weapons \y(\dNot available for you\y) ^n");
	}
	
	if (g_iMenuChooseCount[id][COUNT_KNIVESMENU] >= KNIVESMENU_CHOOSE_LIMIT) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \dKnives (Available in the next round)^n");
	} else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wKnives^n");
		iKeys |= (1<<1);
	}
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "WeaponMenu");
}

public Handle_WeaponMenu(id, iKeys) {
	switch(iKeys) {
		case 0 : {
			return Show_SpecialMenu(id);
		}
		case 1 : {
			return Show_KnivesMenu(id);
		}
		case 9 : {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public Show_KnivesMenu(id) {
	if (!CanOpenSVIPMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys = 0, iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wKnives Menu^n^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wAxe^n");
	iKeys |= (1<<0);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wCombat Knife^n");
	iKeys |= (1<<1);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wHammer^n");
	iKeys |= (1<<2);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4\d. \wKatana^n");
	iKeys |= (1<<3);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5\d. \wStap^n");
	iKeys |= (1<<4);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "KnivesMenu");
}

public Handle_KnivesMenu(id, iKeys) {
	switch(iKeys) {
		case 0 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			mjb_set_user_melee(id, MELEE_SVIP_AXE);
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_KNIVESMENU]++;
		}
		case 1 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			mjb_set_user_melee(id, MELEE_SVIP_COMBAT);
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_KNIVESMENU]++;
		}
		case 2 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			mjb_set_user_melee(id, MELEE_SVIP_HAMMER);
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_KNIVESMENU]++;
		}
		case 3 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			mjb_set_user_melee(id, MELEE_SVIP_KATANA);
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_KNIVESMENU]++;
		}
		case 4 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			mjb_set_user_melee(id, MELEE_SVIP_STAP);
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_KNIVESMENU]++;
		}
		case 9 : {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

public Show_SpecialMenu(id) {
	if (!CanOpenSVIPMenu(id))
		return PLUGIN_HANDLED;
	show_menu(id, 0, "^n", 1);
	new szMenu[512], iKeys = 0, iLen;
	if (GetTeam(id) == GUARD) {
		iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wSpecial Weapons^n^n");
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wWeapon 1^n");
		iKeys |= (1<<0);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wWeapon 2^n");
		iKeys |= (1<<1);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wWeapon 3^n");
		iKeys |= (1<<2);
	}
	else if (GetTeam(id) == PRISONER)
	{
		if (!hasRank(id, RANK_CO_OWNER))
			return PLUGIN_HANDLED;
		iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \r| \wSpecial Menu^n^n");
		
		if (g_iOpenDoorCount[id] < DOOR_OPEN_LIMIT) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. \wEscape^n");
			iKeys |= (1<<0);
		} else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1\d. Escape^n");
		}
		
		if (g_iFlashChooseCount[id] < FLASH_CHOOSE_LIMIT) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. \wFlash guards^n");
			iKeys |= (1<<1);
		} else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2\d. Flash guards^n");
		}
		
		if (g_iTrapChooseCount[id] < TRAP_CHOOSE_LIMIT) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. \wSet trap^n");
			iKeys |= (1<<2);
		} else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3\d. Set trap^n");
		}
	}
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\d. \wExit");
	iKeys |= (1<<9);
	return show_menu(id, iKeys, szMenu, -1, "SpecialMenu");
}

public Handle_SpecialMenu(id, iKeys) {
	switch(iKeys) {
		case 0 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			if (GetTeam(id) == PRISONER) {
				mjb_open_cell();
				g_iOpenDoorCount[id]++;
			}
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_SPECIALMENU]++;
		}
		case 1 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			if (GetTeam(id) == PRISONER) {
				blind_guards(id);
				g_iFlashChooseCount[id]++;
			}
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_SPECIALMENU]++;
		}
		case 2 : {
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;
			if (GetTeam(id) == PRISONER) {
				trap(id);
				g_iTrapChooseCount[id]++;
			}
			g_iMenuChooseCount[id][COUNT_SVIPMENU]++;
			g_iMenuChooseCount[id][COUNT_SPECIALMENU]++;
		}
		case 9 : {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

blind_guards(id) {
	new pl[32], plnum
	get_players(pl, plnum)
	
	for(new i = 0; i < plnum; i++) 
	{
		if(!mjb_is_valid_player(pl[i]) || !is_user_alive(pl[i]) || GetTeam(pl[i]) == PRISONER)
			continue;
			
		new szName[33]
		UTIL_ScreenFade(pl[i], 0, 0, 4, 0, 0, 0, 255); 
		get_user_name(id, szName, 32);
		set_hudmessage(255, 255, 255, -1.0, 0.4, 0, 0.0, 3.0, _, _, 2);
		show_hudmessage(pl[i], "MOON JBer %s blinded you temporarely", szName);
		iBlinded[pl[i]] = MJB_True;
		set_task(3.0, "unblind_player", pl[i]);
	}
}

unblind_player(id) {
	if (!iBlinded[id])
		return;
	UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
	iBlinded[id] = MJB_False;
}

public trap(id)
{
	new Float:origin[3]
	
	entity_get_vector(id,EV_VEC_origin,origin)
	
	new ent = create_entity("info_target")
	
	entity_set_origin(ent,origin);
	origin[2] += 100.0
	entity_set_origin(id,origin)
	
	entity_set_float(ent,EV_FL_takedamage,0.0) 
	
	entity_set_string(ent,EV_SZ_classname,"npc_totem");
	entity_set_model(ent,"models/trap.mdl");
	entity_set_int(ent,EV_INT_solid, 2)
	
	entity_set_byte(ent,EV_BYTE_controller1,125);
	entity_set_byte(ent,EV_BYTE_controller2,125);
	entity_set_byte(ent,EV_BYTE_controller3,125);
	entity_set_byte(ent,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {16.0,16.0,36.0}
	new Float:mins[3] = {-16.0,-16.0,-36.0}    
	entity_set_size(ent,mins,maxs)
	
	entity_set_float(ent,EV_FL_animtime,2.0)
	entity_set_float(ent,EV_FL_framerate,1.0)
	entity_set_int(ent,EV_INT_sequence,0);
	
	entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.01)
	
	drop_to_floor(ent)
	return 1;
}

/*public client_PreThink(id)
{
	if(!mjb_is_valid_player(id) || !is_user_alive(id) || GetTeam(id) != GUARD)
		return PLUGIN_CONTINUE;
	
	new Float:gametime = get_gametime();
	if(fTrapCooldown[id] < gametime)
		return PLUGIN_CONTINUE;
	
	new ent = -1
	new Float:vOrigin[3], Float:pOrigin[3], Float:distance;
	entity_get_vector(id, EV_VEC_origin, pOrigin);
	while((ent = find_ent_by_class(ent, "npc_totem")))
	{
		entity_get_vector(ent, EV_VEC_origin, vOrigin);
		distance = get_distance_f(pOrigin, vOrigin);
		if(distance < MAX_DISTANCE)
		{
			set_user_maxspeed(id, 1.0 );
			rg_strip_user_weapons(id);
			
			if(!iTrapped[id])
			{
				iTrapped[id] = MJB_True;
				client_cmd(id, "spk trap.wav");
				MJB_Print(id, "!tYou fell into a trap");
				set_task(10.0, "end_trap", id);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
} */ 

public end_trap(id) {
	trap_off(id);
	fTrapCooldown[id] = get_gametime() + 60.0;
	rg_give_item(id, "weapon_knife");
	rg_give_item(id,"weapon_deagle");
	rg_give_item(id,"weapon_m4a1");
	rg_set_user_bpammo(id,WEAPON_M4A1, 90);
	rg_set_user_bpammo(id,WEAPON_DEAGLE, 35);
}

public trap_off(id)
{
	if (iTrapped[id]) {
		remove_entity_name( "npc_totem" ); 
		set_user_maxspeed(id, 240.0 );
		MJB_Print(id, "!tTrap destroyed");
		iTrapped[id] = MJB_False;
	}
}

stock ResetMenusChooseCount(id) {
	for (new i = 0; i < Menus; i++) {
		g_iMenuChooseCount[id][i] = 0;
	}
}

stock GiveBombPackage(id) {
	rg_give_item(id, "weapon_hegrenade");
	rg_give_item(id, "weapon_flashbang");
	rg_give_item(id, "weapon_flashbang");
	rg_give_item(id, "weapon_smokegrenade");
}
