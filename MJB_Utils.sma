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

stock fm_set_entity_visibility(index, visible = 1) set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)

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
new g_FreedayHudSync, g_WantedHudSync, g_GeneralInfoHudSync;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
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
	set_task(1.0, "HudGeneralInfo", TASK_HUD_GENERAL_INFO, _, _, "b");
}

public plugin_precache() {
	precache_model("models/MOON_JB/Costumes/mjb_costumes.mdl");
	precache_model("models/MOON_JB/Costumes/sheep.mdl");
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
	set_hudmessage(0, 255, 0, 0.25, 0.25, 0, 0.0, 1.0, _, _, 3);
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
	set_hudmessage(255, 0, 0, 0.6, 0.7, 0, 0.0, 1.0, _, _, 4);
	ShowSyncHudMsg(0, g_WantedHudSync, szMessage);
}

/* General Hud Info */
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
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "☺ Good luck, Have fun!^n");
	set_hudmessage(0, 255, 255, 0.6, 0.05, 0, 0.0, 1.0, _, _, 1);
	ShowSyncHudMsg(0, g_GeneralInfoHudSync, szMessage);
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
	new iStart = iPos * 8;
	if (iStart >= g_iMenuCount) iStart = g_iMenuCount - 8;
	if (iStart < 0) iStart = 0;
	iStart -= (iStart % 8);
	g_iMenuPosition[id] = iStart / 8;
	new iEnd = iStart + 8;
	if (iEnd > g_iMenuCount) iEnd = g_iMenuCount;
	new szMenu[512], iLen, iPagesNum = (g_iMenuCount / 8 + ((g_iMenuCount % 8) ? 1 : 0));
	
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
	
	for(new i = b; i < 8; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iEnd < g_iMenuCount)
	{
		iKeys |= (1<<8);
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
			new index = g_iMenuPosition[id] * 8 + iKeys;
			
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