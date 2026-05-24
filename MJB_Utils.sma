/*
	CmdHatsMenu (g_iMenuPositon = 0);
*/
#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <MJB_Core>

#define PLUGIN "Utilites"

/* Tasks */
#define TASK_HUD_FD 6283
#define TASK_HUD_WANTED 6382
#define TASK_HUD_GENERAL_INFO 8362
#define TASK_HUD_MAIN_INFO 8632

#define CHANNEL_HUD_GENERAL_INFO 1
#define CHANNEL_HUD_MAIN_INFO 2
#define CHANNEL_HUD_FD 3
#define CHANNEL_HUD_WANTED 4

stock fm_set_entity_visibility(index, visible = 1) set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)

new Trie:g_tViewModels, Trie:g_tWorldModels;

/* Hat Variables */
new g_Hats[][] = {
	"Mono",
	"Elephant",
	"Panda",
	"Bunny",
	"Squirrel",
	"Cow",
	"Medo",
	"Patak",
	"Macak",
	"Rainbow Horse",
	"Bedouin",
	"Tiger",          
	"Crocodile",
	"Captain America",
	"Pink Panther",
	"Gara",
	"Naruto",
	"Kakashi",
	"Dragon",
	"Coyote",
	"Yoda",
	"MC Cape"       
};

new g_iHat[MAX_PLAYERS + 1];
new g_iHatEnt[MAX_PLAYERS + 1];
new g_iMenuPosition[MAX_PLAYERS + 1];
new const g_iMenuCount = sizeof(g_Hats) + 2;

/* Hud Damage Variablese */
new g_iLastAttacker[MAX_PLAYERS + 1];

/* Hud Freeday & Wanted */
new Array:g_aFreedayPrisoners, Array:g_aWantedPrisoners;
new g_FreedayHudSync, g_WantedHudSync, g_GeneralInfoHudSync, g_MainInfoHudSync;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	/* Weapon Skins Events */
	register_forward(FM_SetModel,"ChangeWorldModelSkin",1)
	register_event("CurWeapon","ChangeWeaponSkin","be","1=1")
	
	/* Hud Damage */
	register_message(get_user_msgid("Damage"), "Message_Damage");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "HudDamage", true);
	
	/* Hats */
	register_clcmd("say /hats", "Cmd_HatsMenu");
	register_menucmd(register_menuid("HatsMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_HatsMenu");
	
	/* Hud Freeday & Wanted */
	g_aFreedayPrisoners = ArrayCreate(1);
	g_aWantedPrisoners = ArrayCreate(1);
	g_FreedayHudSync = CreateHudSyncObj();
	g_WantedHudSync = CreateHudSyncObj();
	
	/* General Info Hud */
	g_GeneralInfoHudSync = CreateHudSyncObj();
	g_MainInfoHudSync = CreateHudSyncObj();
	set_task(1.0, "HudGeneralInfo", TASK_HUD_GENERAL_INFO, _, _, "b");
	set_task(1.0, "HudMainInfo", TASK_HUD_MAIN_INFO, _, _, "b");
}

public plugin_end() {
	ArrayDestroy(g_aFreedayPrisoners);
	ArrayDestroy(g_aWantedPrisoners);
	TrieDestroy(g_tViewModels);
	TrieDestroy(g_tWorldModels);
}        
        
public plugin_precache() {
	precache_model("models/MOON_JB/Costumes/mjb_costumes.mdl");
	precache_model("models/MOON_JB/Costumes/sheep.mdl");
	
	g_tViewModels = TrieCreate();
	g_tWorldModels = TrieCreate();
	
	TrieSetString(g_tViewModels, "models/v_hegrenade.mdl", "models/MOON_JB/WeaponSkins/v_hegrenade.mdl");
	TrieSetString(g_tViewModels, "models/v_m4a1.mdl", "models/MOON_JB/WeaponSkins/v_m4a1.mdl");
	TrieSetString(g_tViewModels, "models/v_smokegrenade.mdl", "models/MOON_JB/WeaponSkins/v_smokegrenade.mdl");
	TrieSetString(g_tViewModels, "models/v_ak47.mdl", "models/MOON_JB/WeaponSkins/v_ak47.mdl");
	TrieSetString(g_tViewModels, "models/v_awp.mdl", "models/MOON_JB/WeaponSkins/v_awp.mdl");
	TrieSetString(g_tViewModels, "models/v_m249.mdl", "models/MOON_JB/WeaponSkins/v_m249.mdl");
	TrieSetString(g_tViewModels, "models/v_galil.mdl", "models/MOON_JB/WeaponSkins/v_galil.mdl");
	TrieSetString(g_tViewModels, "models/v_mp5.mdl", "models/MOON_JB/WeaponSkins/v_mp5.mdl");
	TrieSetString(g_tViewModels, "models/v_deagle.mdl", "models/MOON_JB/WeaponSkins/v_deagle.mdl");
	TrieSetString(g_tViewModels, "models/v_flashbang.mdl", "models/MOON_JB/WeaponSkins/v_flashbang.mdl");
	
	TrieSetString(g_tWorldModels, "models/w_hegrenade.mdl", "models/MOON_JB/WeaponSkins/w_hegrenade.mdl");
	TrieSetString(g_tWorldModels, "models/w_smokegrenade.mdl", "models/MOON_JB/WeaponSkins/w_smokegrenade.mdl");
	TrieSetString(g_tWorldModels, "models/w_flashbang.mdl", "models/MOON_JB/WeaponSkins/w_flashbang.mdl");
	
	new szKey[32], szValue[64];
	new Snapshot:snap = TrieSnapshotCreate(g_tViewModels);
	for (new i = 0; i < TrieSnapshotLength(snap); i++) {
		TrieSnapshotGetKey(snap, i, szKey, charsmax(szKey));
		TrieGetString(g_tViewModels, szKey, szValue, charsmax(szValue));
		precache_model(szValue);
	}
	szKey = "";
	szValue = "";
	snap = TrieSnapshotCreate(g_tWorldModels);
	for (new i = 0; i < TrieSnapshotLength(snap); i++) {
		TrieSnapshotGetKey(snap, i, szKey, charsmax(szKey));
		TrieGetString(g_tWorldModels, szKey, szValue, charsmax(szValue));
		precache_model(szValue);
	}
}

public ChangeWorldModelSkin(ent,model[])
{
	if(!pev_valid(ent))
	{
		return FMRES_IGNORED
	}
	if (TrieKeyExists(g_tWorldModels, model)) {
		new new_model[64];
		TrieGetString(g_tWorldModels, model, new_model, charsmax(new_model));
		engfunc(EngFunc_SetModel,ent,new_model)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public ChangeWeaponSkin(id) {
	if (!mjb_is_valid_player(id) || !is_user_alive(id))
		return;
	
	new model[32], new_model[64];
	pev(id, pev_viewmodel2, model, charsmax(model));
	if (TrieKeyExists(g_tViewModels, model)) {
		TrieGetString(g_tViewModels, model, new_model, charsmax(new_model));
		set_pev(id, pev_viewmodel2, new_model);
	}
}

/* Hud Freeday & Wanted Logic */
public client_disconnected(id) {
	if (GetTeam(id) != PRISONER)
		return;
	RemoveFromArrays(id);
}

public mjb_state_changed(id, iOldState, iNewState) {
	if (GetTeam(id) != PRISONER)
		return;
	if (iNewState == PRISONER_FREEDAY && ArrayFindValue(g_aFreedayPrisoners, id) == -1) {
		ArrayPushCell(g_aFreedayPrisoners, id);
		if (ArraySize(g_aFreedayPrisoners) == 1) {
			set_task(1.0, "HudFreedayPrisoners", TASK_HUD_FD, _, _, "b");
		}
	}
	if (iNewState == PRISONER_WANTED && ArrayFindValue(g_aWantedPrisoners, id) == -1) {
		ArrayPushCell(g_aWantedPrisoners, id);
		if (ArraySize(g_aWantedPrisoners) == 1) {
			set_task(1.0, "HudWantedPrisoners", TASK_HUD_WANTED, _, _, "b");
		}
	}
	if (iNewState == NORMAL) {
		RemoveFromArrays(id);
	}
}

public RemoveFromArrays(id) {
	new index;
	index = ArrayFindValue(g_aFreedayPrisoners, id);
	if (index != -1) {
		ArrayDeleteItem(g_aFreedayPrisoners, index);
		if (!ArraySize(g_aFreedayPrisoners)) {
			remove_task(TASK_HUD_FD);
		}
	}
	index = ArrayFindValue(g_aWantedPrisoners, id);
	if (index != -1) {
		ArrayDeleteItem(g_aWantedPrisoners, index);
		if (!ArraySize(g_aWantedPrisoners)) {
			remove_task(TASK_HUD_WANTED);
		}
	}
}

public HudFreedayPrisoners() {
	new szMessage[512], iLen;
	iLen = formatex(szMessage, charsmax(szMessage), "Freeday Prisoners:^n");
	new id, szName[MAX_NAME_LENGTH];
	for (new i = 0; i < ArraySize(g_aFreedayPrisoners); i++) {
		id = ArrayGetCell(g_aFreedayPrisoners, i);
		get_user_name(id, szName, charsmax(szName));
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s^n", szName);
	}
	set_hudmessage(0, 255, 0, 0.25, 0.25, 0, 0.0, 1.0, _, _, CHANNEL_HUD_FD);
	ShowSyncHudMsg(0, g_FreedayHudSync, szMessage);
}

public HudWantedPrisoners() {
	new szMessage[512], iLen;
	iLen = formatex(szMessage, charsmax(szMessage), "Wanted Prisoners:^n");
	new id, szName[MAX_NAME_LENGTH];
	for (new i = 0; i < ArraySize(g_aWantedPrisoners); i++) {
		id = ArrayGetCell(g_aWantedPrisoners, i);
		get_user_name(id, szName, charsmax(szName));
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s^n", szName);
	}
	set_hudmessage(255, 0, 0, 0.6, 0.7, 0, 0.0, 1.0, _, _, CHANNEL_HUD_WANTED);
	ShowSyncHudMsg(0, g_WantedHudSync, szMessage);
}

/* Main Huds Info */
public mjb_phase_changed(iOldPhase, iPhase) {
	if (!task_exists(TASK_HUD_MAIN_INFO) && (iPhase == PHASE_FREEDAY || iPhase == PHASE_NORMAL || iPhase == PHASE_SIMON_SELECT || iPhase == PHASE_GAMEDAY_ACTIVE))
		set_task(0.1, "SetMainHud", 9171);
}

public SetMainHud() {
	set_task(1.0, "HudMainInfo", TASK_HUD_MAIN_INFO, _, _, "b");
}

public HudGeneralInfo() {
	new szMessage[512], iLen, ip[32], dayType[32], szTime[32], szDate[32], szDiscord[32];
	get_user_ip(0, ip, charsmax(ip));
	GetDayTypeStr(dayType, charsmax(dayType));
	get_time("%H:%M", szTime, charsmax(szTime));
	get_time("%d.%m.%Y", szDate, charsmax(szDate));
	GetCommunityDiscord(szDiscord, 31)
	iLen = format(szMessage, charsmax(szMessage), "  MOON JailBreak  ^n");
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s^n", ip);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "--------------------^n");
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Today Is: %s^n", dayType);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Day : %d | %d^n", mjb_get_day(), MAX_DAYS);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Time : [%s]^n", szTime);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Date : [%s]^n", szDate);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "--------------------^n");
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Prisoners - [%d / %d]^n", GetTeamCount(PRISONER, true), GetTeamCount(PRISONER, false));
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "JbGuards - [%d / %d]^n", GetTeamCount(GUARD, true), GetTeamCount(GUARD, false));
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Players - [%d / %d]^n", GetTeamCount(GUARD, false) + GetTeamCount(PRISONER, false), MAX_PLAYERS);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "--------------------^n");
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s^n", szDiscord);
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "--------------------^n");
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Good luck, Have fun!^n");
	set_hudmessage(0, 255, 255, 0.9, 0.02, 0, 0.0, 1.0, _, _, CHANNEL_HUD_GENERAL_INFO);
	ShowSyncHudMsg(0, g_GeneralInfoHudSync, szMessage);
}

public HudMainInfo() {
	new iPhase = mjb_get_phase();
	new szMessage[256], iLen;
	new iColor[3];
	if (iPhase == PHASE_FREEDAY) {
		new iTimeLeft = floatround(mjb_get_timer_timeleft(mjb_get_free_timer_id()));
		iLen = format(szMessage, charsmax(szMessage), "Today is: Free Day^n");
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Ends in: %d seconds!^n", iTimeLeft);
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n- Prisoners may go wherever they want, except the gunroom.^n");
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "[MOON] After it ends, Normal routine resumes.^n");
		iColor = {0, 255, 0};
	} else if (iPhase == PHASE_NORMAL)  {
		new szSimonName[MAX_NAME_LENGTH];
		get_user_name(mjb_get_simon(), szSimonName, charsmax(szSimonName));
		iLen = format(szMessage, charsmax(szMessage), "Today is: Normal Day^n");
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Simon: Sir, %s^n", szSimonName);
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n-All players must obey his orders, Even the guards.^n");
		iColor = {0, 255, 255};
	} else if (iPhase == PHASE_SIMON_SELECT) {
		new iTimeLeft = floatround(mjb_get_timer_timeleft(mjb_get_simon_timer_id()));
		iColor = {0, 255, 255};
		new pl[32], plnum;
		get_players(pl, plnum, "h");
		for (new i = 0; i < plnum; i++) {
			if (!mjb_is_valid_player(pl[i]))
				continue;
			if (is_user_alive(pl[i]) && GetTeam(pl[i]) == GUARD) {
				iLen = format(szMessage, charsmax(szMessage), "You have %d seconds to become simon^n", iTimeLeft);
				iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Command for taking it: /simon");
				set_hudmessage(iColor[0], iColor[1], iColor[2], -1.0, 0.03, 0, 0.0, 1.0, 0.4, 0.4, CHANNEL_HUD_MAIN_INFO);
				ShowSyncHudMsg(pl[i], g_MainInfoHudSync, szMessage);
			} else {
				iLen = format(szMessage, charsmax(szMessage), "Today is: Normalday^n");
				iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Simon is not Selected^n");
				iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "- Freeday starts in: %d", iTimeLeft);
				set_hudmessage(iColor[0], iColor[1], iColor[2], 0.05, 0.15, 0, 0.0, 1.0, 0.4, 0.4, CHANNEL_HUD_MAIN_INFO);
				ShowSyncHudMsg(pl[i], g_MainInfoHudSync, szMessage);
			}
		}
		return;
	} else if (iPhase == PHASE_GAMEDAY_ACTIVE) {
		iLen = format(szMessage, charsmax(szMessage), "Today Game: [SOON]^n");
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Game [SOON] will end in: d seconds!^n");
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n-During Game: All menus and shops are disabled^n");
		iColor = {255, 255, 0};
	} else if (iPhase == PHASE_SIMON_DISCONNECTED) {
		iLen = format(szMessage, charsmax(szMessage), "Simon Disconnected^n");
		iColor = {128, 128, 128};
	} else if (iPhase == PHASE_SIMON_KILLED) {
		iLen = format(szMessage, charsmax(szMessage), "Simon is Killed^n");
		iColor = {220, 20, 0};
	} else if (iPhase == PHASE_SIMON_NOT_SELECTED) {
		iLen = format(szMessage, charsmax(szMessage), "Simon is not Selected^n");
		iColor = {255, 255, 0};
	} else {
		remove_task(TASK_HUD_MAIN_INFO);
	}
	set_hudmessage(iColor[0], iColor[1], iColor[2], 0.05, 0.15, 0, 0.0, 1.0, _, _, CHANNEL_HUD_MAIN_INFO);
	ShowSyncHudMsg(0, g_MainInfoHudSync, szMessage);
}

/* Hud Damage Logic */
public HudDamage(victim, inflictor, attacker, Float:damage, damagebits){
	if (victim == attacker || !mjb_is_valid_player(attacker))
		return;
	g_iLastAttacker[victim] = attacker;
}

public Message_Damage(iMsgId, iDest, victim) {
	new attacker = g_iLastAttacker[victim];
	if (!mjb_is_valid_player(attacker))
		return;
	new damage = get_msg_arg_int(2);
	if (damage <= 0)
		return;
	new Float:Xfloat = random_float(0.25, 0.55), Float:Yfloat = random_float(0.25, 0.55);
	set_hudmessage(0, 255, 255, Xfloat, Yfloat, 0, 3.0, 3.0, 0.1, 1.0);
	show_hudmessage(attacker, "%d", damage);
}

/* Hat Logic */
public Cmd_HatsMenu(id) {
	return HatsMenu(id, 0);
}

public HatsMenu(id, iPos) {
	if (iPos < 0) {
		return PLUGIN_HANDLED;
	}
	new iStart = iPos * ITEMS_PER_PAGE;
	if (iStart >= g_iMenuCount) iStart = g_iMenuCount - ITEMS_PER_PAGE;
	if (iStart < 0) iStart = 0;
	iStart -= (iStart % ITEMS_PER_PAGE);
	g_iMenuPosition[id] = iStart / ITEMS_PER_PAGE;
	new iEnd = iStart + ITEMS_PER_PAGE;
	if (iEnd > g_iMenuCount) iEnd = g_iMenuCount;
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount / ITEMS_PER_PAGE + ((g_iMenuCount % ITEMS_PER_PAGE) ? 1 : 0));
	
	new iKeys = (1<<9), b = 0;
	iLen = formatex(szMenu, charsmax(szMenu), "\rM\wOON JB \w| \wHats Menu \d%d\w|\d%d^n", iPos+1, iPagesNum);
	
	if (iPos == 0) {
		if (g_iHat[id]) iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d\d. %sNone^n", ++b, (g_iHat[id] == 0) ? "\d" : "\w");
		
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d\d. \wSheep^n", ++b);
		iStart += 2;
	}
	for(new a = iStart; a < iEnd; a++)
	{
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\r%d\d. \w%s^n", ++b, g_Hats[a-2]);
	}
	
	for(new i = b; i < ITEMS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount)
	{
		iKeys |= (1<<ITEMS_PER_PAGE);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r9\d. \w%s^n\r0\d. \w%s", "Next", iPos ? "Back" : "Exit");
	}
	
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r0\d. \w%s", iPos ? "Back" : "Exit");
	
	return show_menu(id, iKeys, szMenu, -1, "HatsMenu");
}

public Handle_HatsMenu(id, iKeys) {
	switch(iKeys)
	{
		case 8: {
			return HatsMenu(id, ++g_iMenuPosition[id]);
		}
		case 9: return HatsMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new index = g_iMenuPosition[id] * ITEMS_PER_PAGE + iKeys;
			
			if(index >= g_iMenuCount)
				return HatsMenu(id, g_iMenuPosition[id]);
			
			if (index == 0) {
				if (pev_valid(g_iHatEnt[id])) fm_set_entity_visibility(g_iHatEnt[id], 0);
			} else if (index == 1 && g_iHat[id] != index) {
				SetHat(id, "models/MOON_JB/Costumes/sheep.mdl");
			} else {
				SetHat(id, "models/MOON_JB/Costumes/mjb_costumes.mdl", index -= 2);
			}
			g_iHat[id] = index;
		}
	}
	return HatsMenu(id, g_iMenuPosition[id]);
}

SetHat(id, const model[], body = 0) {
	if (!pev_valid(g_iHatEnt[id])) {
		g_iHatEnt[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(g_iHatEnt[id], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_iHatEnt[id], pev_aiment, id)
		set_pev(g_iHatEnt[id], pev_rendermode, 	kRenderNormal)
	}
	fm_set_entity_visibility(g_iHatEnt[id], 1);
	engfunc(EngFunc_SetModel, g_iHatEnt[id], model)
	set_pev(g_iHatEnt[id], pev_body, body);
}
