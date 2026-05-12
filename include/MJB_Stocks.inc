#if defined _mjb_stocks_library
	#endinput
#endif

#define _mjb_stocks_library

#if !defined _amxmodx_included
    #include <amxmodx>
#endif

#if !defined _amxmodx_included
    #include <amxmodx>
#endif

#if !defined _cstrike_included
    #include <cstrike>
#endif

#if !defined _mjb_consts_library
    #include <MJB_Consts>
#endif
    

/**
 * Sends a colored chat message.
 *
 * @param id        Client index (use 0 to send to all players)
 * @param message     The message to send
 * @param any:...       Variable number of formatting parameters
 *
 * @return          Length of the printed message
 */
stock MJB_Print(const id, const message[], any:...)
{
	new pl[32], pnum = 1;
	static msg[191], finalmsg[191];

	vformat(msg, charsmax(msg), message, 3);

	// Add prefix here
	formatex(finalmsg, charsmax(finalmsg), "!g[%s] %s", SERVERTAG, msg);

	replace_all(finalmsg, charsmax(finalmsg), "!n", "^x01");
	replace_all(finalmsg, charsmax(finalmsg), "!t", "^x03");
	replace_all(finalmsg, charsmax(finalmsg), "!g", "^x04");

	if (id)
		pl[0] = id;
	else
		get_players(pl, pnum, "ch");

	for (new i = 0; i < pnum; i++)
	{
		if (is_user_connected(pl[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, pl[i]);
			write_byte(pl[i]);
			write_string(finalmsg);
			message_end();
		}
	}

	return strlen(finalmsg);
}

stock ParseAndSetState(id, const stateStr[])
{
	if (stateStr[0] == 'F')
		mjb_set_state(id, PRISONER_FREEDAY);
	else if (stateStr[0] == 'W')
		mjb_set_state(id, PRISONER_WANTED);
	else
		mjb_set_state(id, NONE);
}

stock GetTeamStr(id, output[], len)
{
	copy(output, len, TeamNames[mjb_get_team(id)]);
}

stock GetStateStr(id, output[], len)
{
	copy(output, len, StateNames[mjb_get_state(id)]);
}

stock GetDayTypeStr(output[], len) {
	copy(output, len, DayNames[mjb_get_day_type()]);
}

stock GetPhaseStr(iPhase) { 
	new szBuffer[32];
	
	switch(iPhase) 
	{ 
		case PHASE_DAY_STARTED : copy(szBuffer, 31, "PHASE_DAY_STARTED");
		case PHASE_DAY_ENDED : copy(szBuffer, 31, "PHASE_DAY_ENDED");
		case PHASE_FREEDAY : copy(szBuffer, 31, "PHASE_FREE_STARTED");
		case PHASE_FREE_ENDED : copy(szBuffer, 31, "PHASE_FREE_ENDED");
		case PHASE_NORMAL : copy(szBuffer, 31, "PHASE_NORMAL");
		case PHASE_SIMON_SELECT : copy(szBuffer, 31, "PHASE_SIMON_SELECT");
		case PHASE_SELECT_ENDED : copy(szBuffer, 31, "PHASE_SELECT_ENDED");
		case PHASE_SIMON_NOT_SELECTED : copy(szBuffer, 31, "PHASE_SIMON_NOT_SELECTED");
		case PHASE_SIMON_KILLED : copy(szBuffer, 31, "PHASE_SIMON_KILLED");
		case PHASE_SIMON_DISCONNECTED : copy(szBuffer, 31, "PHASE_SIMON_DISCONNECTED");
		case PHASE_GAMEDAY_VOTE : copy(szBuffer, 31, "PHASE_GAMEDAY_VOTE");
		case PHASE_GAMEDAY_ACTIVE : copy(szBuffer, 31, "PHASE_GAMEDAY_ACTIVE");
		case PHASE_GAMEDAY_NORMAL : copy(szBuffer, 31, "PHASE_GAMEDAY_NORMAL");
	} 
	
	return szBuffer; 
}

public canAffect(id, iTarget) {
	if (!mjb_is_valid_player(id))
		return MJB_False;
		
	new rankId = get_user_rank_level(id);
	new rankTarget = get_user_rank_level(iTarget);
	
	if (rankId > rankTarget)
		return MJB_True;
	return MJB_False;
}

public hasRank(id, rank)
{
	if (!mjb_is_valid_player(id))
		return MJB_False;
		
	if ((get_user_flags(id) & rank) == rank)
		return MJB_True;
	return MJB_False;
}

stock GetMGTStr(iMinigamesTeam, output[], len) {
	switch(iMinigamesTeam) {
		case BLUE : copy(output, len, "Blue");
		case RED : copy(output, len, "Red");
		default: copy(output, len, "Nul");
	}
}

stock GetPrefix(id, output[], len) {
	new iRankLevel = get_user_rank_level(id);
	switch(iRankLevel) {
		case RANK_LEVEL_OWNER: {
			format(output, len, "[OWNER]");
		}
		case RANK_LEVEL_CO_OWNER: {
			format(output, len, "[CO-OWNER]");
		}
		case RANK_LEVEL_ADMINISTRATOR: {
			format(output, len, "[ADMINISTRATOR]");
		}
		case RANK_LEVEL_HEAD_ADMIN, RANK_LEVEL_DEPUTY: {
			format(output, len, "[HEAD-ADMIN]");
		}
		case RANK_LEVEL_GOLD_ADMIN, RANK_LEVEL_FULL_ADMIN, RANK_LEVEL_ADMIN: {
			format(output, len, "[ADMIN]");
		}
		default: {
			format(output, len, "");
		}
	}
	if (hasRank(id, RANK_SVIP))
		add(output, len, "[SVIP]");
	if (hasRank(id, RANK_VIP))
		add(output, len, "[VIP]");
}

stock GetRankLevelStr(id, output[], len, iRankLevel = -1) {
	if (iRankLevel == -1)
		iRankLevel = get_user_rank_level(id);
	switch(iRankLevel) {
		case RANK_LEVEL_NONE : {
			format(output, len, "NONE");
		}
		case RANK_LEVEL_VIP : {
			format(output, len, "VIP");
		}
		case RANK_LEVEL_SVIP : {
			format(output, len, "SVIP");
		}
		case RANK_LEVEL_ADMIN : {
			format(output, len, "ADMIN");
		}
		case RANK_LEVEL_FULL_ADMIN : {
			format(output, len, "FULL ADMIN");
		}
		case RANK_LEVEL_GOLD_ADMIN : {
			format(output, len, "GOLD ADMIN");
		}
		case RANK_LEVEL_HEAD_ADMIN, RANK_LEVEL_DEPUTY : {
			format(output, len, "HEAD ADMIN");
		}
		case RANK_LEVEL_ADMINISTRATOR : {
			format(output, len, "ADMINISTRATOR");
		} 
		case RANK_LEVEL_CO_OWNER : {
			format(output, len, "CO-OWNER");
		}
		case RANK_LEVEL_OWNER : {
			format(output, len, "OWNER");
		}  
	}
}

stock get_user_rank_level(id)
{
	new flags = get_user_flags(id);
	
	if ((flags & RANK_OWNER) == RANK_OWNER)
		return RANK_LEVEL_OWNER;
		
	else if ((flags & RANK_CO_OWNER) == RANK_CO_OWNER)
		return RANK_LEVEL_CO_OWNER;
		
	else if ((flags & RANK_ADMINISTRATOR) == RANK_ADMINISTRATOR)
		return RANK_LEVEL_ADMINISTRATOR;
		
	else if ((flags & RANK_HEAD_ADMIN) == RANK_HEAD_ADMIN)
		return RANK_LEVEL_HEAD_ADMIN;
		
	else if ((flags & RANK_DEPUTY_HEAD) == RANK_DEPUTY_HEAD)
		return RANK_LEVEL_DEPUTY;
		
	else if ((flags & RANK_GOLD_ADMIN) == RANK_GOLD_ADMIN)
		return RANK_LEVEL_GOLD_ADMIN;
		
	else if ((flags & RANK_FULL_ADMIN) == RANK_FULL_ADMIN)
		return RANK_LEVEL_FULL_ADMIN;
		
	else if ((flags & RANK_ADMIN) == RANK_ADMIN)
		return RANK_LEVEL_ADMIN;
		
	else if ((flags & RANK_SVIP) == RANK_SVIP)
		return RANK_LEVEL_SVIP;
		
	else if ((flags & RANK_VIP) == RANK_VIP)
		return RANK_LEVEL_VIP;
	
	return RANK_LEVEL_NONE;
}

stock set_user_drug(id, iToggle = 0) 
{
	if (iToggle) {
		message_begin(MSG_ONE, get_user_msgid("SetFOV"), { 0, 0, 0 }, id);
		write_byte(180);
		message_end();
	}
	else
	{
		message_begin(MSG_ONE, get_user_msgid("SetFOV"), { 0, 0, 0 }, id);
		write_byte(90);
		message_end();
	}
}

stock CREATE_PLAYERATTACHMENT(pPlayer, iHeight = 50, pSprite, iLife)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(pPlayer);
	write_coord(iHeight);
	write_short(pSprite);
	write_short(iLife); // 0.1's
	message_end();
}

stock CREATE_KILLPLAYERATTACHMENTS(pPlayer)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(pPlayer);
	message_end();
}

#if defined _hamsandwich_included
stock ham_strip_weapon_name(pPlayer, const szWeaponName[])
{
	new iEntity;
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", szWeaponName)) && pev(iEntity, pev_owner) != pPlayer) {}
	if(!iEntity) return 0;
	new iWeaponId = get_weaponid(szWeaponName);
	if(get_user_weapon(pPlayer) == iWeaponId) ExecuteHamB(Ham_Weapon_RetireWeapon, iEntity);
	if(!ExecuteHamB(Ham_RemovePlayerItem, pPlayer, iEntity)) return 0;
	ExecuteHamB(Ham_Item_Kill, iEntity);
	set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) & ~(1<<iWeaponId));
	return 1;
}
#endif

#if defined _fakemeta_included
#if !defined _fakemeta_util_included
stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 32.0 + iRadius * 2);
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}


stock fm_switch_to_knife(pPlayer) {
	if(get_user_weapon(pPlayer) != CSW_KNIFE) engclient_cmd(pPlayer, "weapon_knife");
	else
	{
		new iActiveItem = get_pdata_cbase(pPlayer, m_pActiveItem);
		if(iActiveItem > 0)
		{
			ExecuteHamB(Ham_Item_Deploy, iActiveItem);
			UTIL_WeaponAnimation(pPlayer, 3);
		}
	}
}

stock fm_give_item(pPlayer, const szItem[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem));
	if(!pev_valid(iEntity)) return 0;
	new Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Touch, iEntity, pPlayer);
	if(pev(iEntity, pev_solid) != SOLID_NOT)
	{
		engfunc(EngFunc_RemoveEntity, iEntity);
		return -1;
	}
	return iEntity;
}

stock fm_strip_user_weapons(pPlayer, iType = 0)
{
	static iEntity, iszWeaponStrip = 0;
	if(iszWeaponStrip || (iszWeaponStrip = engfunc(EngFunc_AllocString, "player_weaponstrip"))) iEntity = engfunc(EngFunc_CreateNamedEntity, iszWeaponStrip);
	if(!pev_valid(iEntity)) return 0;
	if(iType && get_user_weapon(pPlayer) != CSW_KNIFE)
	{
		engclient_cmd(pPlayer, "weapon_knife");
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 66, {0.0, 0.0, 0.0}, pPlayer);
		write_byte(1);
		write_byte(CSW_KNIFE);
		write_byte(0);
		message_end();
	}
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Use, iEntity, pPlayer);
	engfunc(EngFunc_RemoveEntity, iEntity);
	set_pdata_int(pPlayer, m_fHasPrimary, 0, linux_diff_player);
	return 1;
}

stock fm_get_user_bpammo(pPlayer, iWeaponId)
{
	new iOffset;
	switch(iWeaponId)
	{
		case CSW_AWP: iOffset = 377; // ammo_338magnum
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: iOffset = 378; // ammo_762nato
		case CSW_M249: iOffset = 379; // ammo_556natobox
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: iOffset = 380; // ammo_556nato
		case CSW_M3, CSW_XM1014: iOffset = 381; // ammo_buckshot
		case CSW_USP, CSW_UMP45, CSW_MAC10: iOffset = 382; // ammo_45acp
		case CSW_FIVESEVEN, CSW_P90: iOffset = 383; // ammo_57mm
		case CSW_DEAGLE: iOffset = 384; // ammo_50ae
		case CSW_P228: iOffset = 385; // ammo_357sig
		case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: iOffset = 386; // ammo_9mm
		case CSW_FLASHBANG: iOffset = 387;
		case CSW_HEGRENADE: iOffset = 388;
		case CSW_SMOKEGRENADE: iOffset = 389;
		case CSW_C4: iOffset = 390;
		default: return 0;
	}
	return get_pdata_int(pPlayer, iOffset, linux_diff_player);
}

stock fm_set_user_bpammo(pPlayer, iWeaponId, iAmount)
{
	new iOffset;
	switch(iWeaponId)
	{
		case CSW_AWP: iOffset = 377; // ammo_338magnum
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: iOffset = 378; // ammo_762nato
		case CSW_M249: iOffset = 379; // ammo_556natobox
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: iOffset = 380; // ammo_556nato
		case CSW_M3, CSW_XM1014: iOffset = 381; // ammo_buckshot
		case CSW_USP, CSW_UMP45, CSW_MAC10: iOffset = 382; // ammo_45acp
		case CSW_FIVESEVEN, CSW_P90: iOffset = 383; // ammo_57mm
		case CSW_DEAGLE: iOffset = 384; // ammo_50ae
		case CSW_P228: iOffset = 385; // ammo_357sig
		case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: iOffset = 386; // ammo_9mm
		case CSW_FLASHBANG: iOffset = 387;
		case CSW_HEGRENADE: iOffset = 388;
		case CSW_SMOKEGRENADE: iOffset = 389;
		case CSW_C4: iOffset = 390;
		default: return;
	}
	set_pdata_int(pPlayer, iOffset, iAmount, linux_diff_player);
}

public fm_set_kvd(iEntity, const szClassName[], const szKeyName[], const szValue[]) {
	set_kvd(0, KV_ClassName, szClassName);
	set_kvd(0, KV_KeyName, szKeyName);
	set_kvd(0, KV_Value, szValue);
	set_kvd(0, KV_fHandled, 0);
	return dllfunc(DLLFunc_KeyValue, iEntity, 0)
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_pev(pPlayer, pev_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MsgId_ScreenFade);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0.0, 0.0, 0.0}, pPlayer);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
	}
}

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}
#endif
#endif

#if defined _engine_included
stock ResetMaxspeed(id) 
{ 
	static Float:max_speed 
	switch ( get_user_weapon(id) ) 
	{ 
		case CSW_SG550, CSW_AWP, CSW_G3SG1:        max_speed = 210.0 
		case CSW_M249:                    max_speed = 220.0 
		case CSW_AK47:                    max_speed = 221.0 
		case CSW_M3, CSW_M4A1:                max_speed = 230.0 
		case CSW_SG552:                    max_speed = 235.0 
		case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS:    max_speed = 240.0 
		case CSW_P90:                    max_speed = 245.0 
		case CSW_SCOUT:                    max_speed = 260.0 
		default:                    max_speed = 250.0 
	} 
	 
	entity_set_float(id, EV_FL_maxspeed, max_speed) 
}
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
