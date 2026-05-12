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
#include <engine> 
#include <fakemeta> 
#include <hamsandwich> 
#include <cstrike> 
#include <MJB_Core>

#define MAX_NETS 2 

/* =========================
   AUTHOR DECLARATION
========================= */
new const PLUGIN_AUTHOR[] = "CreePs & lolz123 & @f0rce";
new const PLUGIN_VERSION[] = "2.1" 

/* =========================
   BALL SNDS&MDLS
========================= */
static const g_szBallBounce[] = "MOON_JB/ball/bounce.wav" 
static const g_szBallGoal[] = "MOON_JB/ball/goal.wav"
static const g_szBallModel[] = "models/MOON_JB/ball/ball.mdl" 
static const g_szBallName[] = "ball"
new kicked[] = "MOON_JB/ball/kicked.wav"
new gotball[] = "MOON_JB/ball/gotball.wav"


enum 
{ 
	FIRST_POINT = 0, 
	SECOND_POINT 
} 

new g_szFile[128] 
new g_szMapname[32] 
new g_buildingstage[33] 

new gBall 
new g_iTrailSprite 
new ball_speed 
new ball_distance 
new countnets = 0 

new bool:g_bHighlight[2] = {false, false};
new bool:g_buildingNet[33] 
new bool:g_bNeedBall 
new bool:g_bScored 

new Float:g_vOrigin[3] 
new Float:g_fOriginBox[33][2][3] 
new Float:g_fLastTouch 
new g_OwnerOrigin[3] 

new g_Owner 

new g_iMainMenu 
new g_iBallMenu 
new g_iNetMenu 

new g_fwScored;
public plugin_init() 
{ 
	register_plugin("JB: Football [OciXCrom + 4D0CtOR4  DT Edit]", PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("JBFootball", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	 
	ball_speed = register_cvar("jb_ball_speed", "200.0") 
	ball_distance = register_cvar("jb_ball_distance", "600")
	 
	register_logevent("EventRoundStart", 2, "1=Round_Start") //create or respawn ball
	register_event("CurWeapon", "CurWeapon", "be") // speed
	 
	register_forward(FM_PlayerPreThink, "PlayerPreThink", 0) //building stage
	register_forward(FM_Touch, "FwdTouch", 0) //goal checking
	 
	RegisterHam(Ham_ObjectCaps, "player", "FwdHamObjectCaps", 1) //kick ball logic
	 
	register_think(g_szBallName, "FwdThinkBall") //ball logic there gotball logic too
	register_touch(g_szBallName, "player", "FwdTouchPlayer")  //gotball logic up also
	//register_touch(g_szBallName, "JailNet",    "touchNet") duplicated headache
	g_fwScored = CreateMultiForward("mjb_player_scored", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	 
	remove_entity_name("func_pushable") 
	 
	new const szEntity[][] = { 
		"worldspawn", "func_wall", "func_door",  "func_door_rotating", 
		"func_wall_toggle", "func_breakable", "func_pushable", "func_train", 
		"func_illusionary", "func_button", "func_rot_button", "func_rotating" 
	} 
	 
	for(new i; i < sizeof(szEntity); i++) 
		register_touch(g_szBallName, szEntity[i], "FwdTouchWorld") //ball interaction with world
		 
	CreateMenus() 
	 
	register_clcmd("say /ball", "ShowMainMenu") 
	register_clcmd("say /resetball", "UpdateBall") 
	set_task(1.0, "taskShowNet", 1000, "", 0, "b", 0) 
	g_bHighlight[0] = true 	 
} 

public CreateMenus() 
{ 
	g_iMainMenu = register_menuid("SoccerMain") 
	g_iBallMenu = register_menuid("BallMenu") 
	g_iNetMenu = register_menuid("NetMenu") 

	register_menucmd(g_iMainMenu, (1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<9), "HandleMainMenu") 
	register_menucmd(g_iBallMenu, (1<<0 | 1<<1 | 1<<2 | 1<<9), "HandleBallMenu") 
	register_menucmd(g_iNetMenu,  (1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<9), "HandleNetMenu") 
} 

public CanOpenSoccerMenu(id) {
	if (!mjb_is_valid_player(id) || !mjb_is_player_alive(id))
		return MJB_False;
	
	if ((mjb_is_simon(id) && mjb_get_phase() == PHASE_NORMAL) || hasRank(id, RANK_CO_OWNER))
		return MJB_True;
	return MJB_False;
}

public ShowMainMenu(id)
{
	if(!CanOpenSoccerMenu(id))
	{
		return PLUGIN_HANDLED
	}
	
	new szBuffer[512], iLen 
	new col[3], col2[3] 
	 
	col = hasRank(id, RANK_CO_OWNER) ? "r" : "d" 
	col2 = hasRank(id, RANK_CO_OWNER) ? "w" : "d" 
	 
	iLen = formatex(szBuffer, sizeof szBuffer - 1, "\rM\wOON JB \r| \wSoccer Manager^n^n") 
	 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r1\d. \wBall Menu^n") 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r2\d. \wNet Menu^n^n") 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s3\d. \%sLoad All^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s4\d. \%sDelete All^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s5\d. \%sSave All^n^n^n^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0\d. \wExit", col, col2) 
	 
	new iKeys = ( 1<<0 | 1<<1 | 1<<9 ) 
	if (hasRank(id, RANK_CO_OWNER)) {
		iKeys |= (1<<2 | 1<<3 | 1<<4);
	}
	show_menu(id, iKeys, szBuffer, -1, "SoccerMain")
	return PLUGIN_HANDLED
} 

public HandleMainMenu(id, key) 
{ 
	if(!CanOpenSoccerMenu(id)) { 
		return PLUGIN_HANDLED; 
	} 
	 
	switch(key) 
	{ 
		case 0: 
		{ 
			return ShowBallMenu(id) 

		} 
		case 1: 
		{ 
			return ShowNetMenu(id) 
		} 
		case 2: 
		{ 
			if(is_valid_ent(gBall)) { 
				entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 }) 
				entity_set_origin(gBall, g_vOrigin ) 
				 
				entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE) 
				entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 }) 
				entity_set_int(gBall, EV_INT_iuser1, 0) 
				 
				MJB_Print(id, "Successfully loaded entity!") 
			} 
		} 
		case 3: 
		{ 
			new ent 
			new ball, net 
			while((ent = find_ent_by_class(ent, g_szBallName)) > 0) 
			{ 
				remove_entity(ent) 
				ball++ 
			} 
				 
			while((ent = find_ent_by_class(ent, "JailNet")) > 0) 
			{ 
				remove_entity(ent) 
				countnets-- 
				net++ 
			} 
				 
			MJB_Print(id, "Successfully removed !g%d ball and!g %d nets", ball, net) 
		} 
		case 4: SaveAll(id) 
		case 9: return PLUGIN_HANDLED 
	} 

	return ShowMainMenu(id);
} 

public ShowBallMenu(id) 
{ 
	if(!CanOpenSoccerMenu(id))
	{
		return PLUGIN_HANDLED
	}
	new szBuffer[512], iLen 
	new col[3], col2[3] 
	 
	col = hasRank(id, RANK_CO_OWNER) ? "r" : "d" 
	col2 = hasRank(id, RANK_CO_OWNER) ? "w" : "d" 
	 
	iLen = formatex(szBuffer, sizeof szBuffer - 1, "\rM\wOON JB \r| \wBall Manager^n^n") 
	 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s1\d. \%sCreate Ball^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r2\d. \wHighlight Ball %s^n", (g_bHighlight[1]) ? "\yON" : "\rOFF") 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s3\d. \%sDelete Ball^n^n^n^n^n^n^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0\d. \wBack") 
	 
	new iKeys = ( 1<<1 | 1<<9 ) 
	if (hasRank(id, RANK_CO_OWNER)) {
		iKeys |= (1<<0 | 1<<2);
	}
	show_menu(id, iKeys, szBuffer, -1, "BallMenu") 
	return PLUGIN_HANDLED;
} 

public HandleBallMenu(id, key) 
{ 
	if(!CanOpenSoccerMenu(id)) { 
		return PLUGIN_HANDLED 
	} 
	 
	switch(key) 
	{ 
		case 0: 
		{ 
			if(pev_valid(gBall)) 
				return PLUGIN_CONTINUE 
				 
			new ball 
			ball = CreateBall(id) 
			 
			if(pev_valid(ball)) 
				MJB_Print(id, "Successfully created ball!") 
			else 
				MJB_Print(id, "Failled to create ball!") 
		} 
		case 1: 
		{ 
			if(!g_bHighlight[1]) 
			{ 
				set_rendering(gBall, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 255) 
				entity_set_float(gBall, EV_FL_renderamt, 1.0) 
				 
				g_bHighlight[1] = true 
				 
				MJB_Print(id, "Ball highlight has been!t Enabled!g.") 
			} else { 
				set_rendering(gBall, kRenderFxNone, 0, 0, 255, kRenderNormal, 255) 
				entity_set_float(gBall, EV_FL_renderamt, 1.0) 
				 
				g_bHighlight[1] = false 
				 
				MJB_Print(id, "Ball highlight has been!t Disabled!g.") 
			} 
		} 
		case 2: 
		{ 
			new ent 
			new bool:bFound 
			while((ent = find_ent_by_class(ent, g_szBallName)) > 0) 
			{ 
				remove_entity(ent) 
				bFound = true 
			} 
			if(bFound) 
				MJB_Print(id, "Successfully removed ball!") 
			else 
				MJB_Print(id, "No ball was found to remove") 
		} 
		case 9: 
		{ 
			return ShowMainMenu(id) 
		} 
	} 
	 
	
	return ShowBallMenu(id) 
} 

public ShowNetMenu(id) 
{ 
	if (!CanOpenSoccerMenu(id)) {
		return PLUGIN_HANDLED
	}
	new szBuffer[512], iLen 
	new col[3], col2[3] 

	col = hasRank(id, RANK_CO_OWNER) ? "r" : "d" 
	col2 = hasRank(id, RANK_CO_OWNER) ? "w" : "d" 
	 
	iLen = formatex(szBuffer, sizeof szBuffer - 1, "\rM\wOON JB \r| \wNet Manager^n^n") 
	 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s1\d. \%sCreate Net^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r2\d. \wHighlight Net^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s3\d. \%sDelete Net^n^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\%s4\d. \%sMove Net^n^n^n^n^n", col, col2) 
	iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0\d. \wBack") 
	 
	new iKeys = ( 1<<9 ) 
	if (hasRank(id, RANK_CO_OWNER)) {
		iKeys |= (1<<0 | 1<<1 | 1<<2 | 1<<3);
	}
	show_menu(id, iKeys, szBuffer, -1, "NetMenu") 
	return PLUGIN_HANDLED;
} 

public HandleNetMenu(id, key) 
{ 
	if (!CanOpenSoccerMenu(id)) {
		return PLUGIN_HANDLED
	}
	 
	switch(key) 
	{ 
		case 0: 
		{ 
			if(g_buildingNet[id]) 
			{ 
				MJB_Print(id, "!nAlready in building net mod.") 
				 
				return ShowNetMenu(id) 
			} 
			if(countnets >= MAX_NETS) 
			{ 
				MJB_Print(id, "!nSorry, limit of nets reached (%d).", countnets) 
				 
				return ShowNetMenu(id) 
			} 
			 
			g_buildingNet[id] = true 
			 
			MJB_Print(id, "!tSet the origin for the top right corner of the box.") 
		} 
		case 1: 
		{ 
			if(!g_bHighlight[0]) 
			{ 
				set_task(1.0, "taskShowNet", 1000, "", 0, "b", 0) 
				g_bHighlight[0] = true 
				 
				MJB_Print(id, "!gNet highlight has been!t Enabled!g.") 
			} else { 
				if (task_exists(1000)) remove_task(1000) 
				g_bHighlight[0] = false 
				 
				MJB_Print(id, "!gNet highlight has been!t Disabled!g.") 
			} 
		} 
		case 2: 
		{ 
			new ent, body 
			new bool:bFound 
			static classname[32] 
		 
			get_user_aiming(id, ent, body, 9999) 
			entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname)) 
			 
			if(is_valid_ent(ent) && equal(classname, "JailNet")) 
			{ 
				remove_entity(ent) 
				countnets-- 
					 
				bFound = true 
			} else { 
				new Float:fPlrOrigin[3], Float:fNearestDist = 9999.0, iNearestEnt 
				new Float:fOrigin[3], Float:fCurDist 
	 
				pev(id, pev_origin, fPlrOrigin) 
	 
				new ent = -1 
				while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "JailNet")) != 0) 
				{ 
					pev(ent, pev_origin, fOrigin) 
		 
					fCurDist = vector_distance(fPlrOrigin, fOrigin) 
		 
					if(fCurDist < fNearestDist) 
					{ 
						iNearestEnt = ent 
						fNearestDist = fCurDist 
					} 
				} 
				if(iNearestEnt > 0 && is_valid_ent(iNearestEnt)) 
				{ 
					remove_entity(iNearestEnt) 
					countnets-- 
				} 
				 
				bFound = true 
			} 
			if(bFound) 
				MJB_Print(id, "Successfully removed net!") 
			else 
				MJB_Print(id, "No net was found to remove") 
		} 
		case 9: 
		{ 
			
			return ShowMainMenu(id) 
		} 
	} 
	 
	 
	return ShowNetMenu(id)
} 
		
public PlayerPreThink(id) 
{ 
	if(!mjb_is_player_alive(id)) 
		return PLUGIN_CONTINUE 
	 
	if(pev(id, pev_button) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE) && g_buildingNet[id]) { 
		new Float:fOrigin[3], fOriginn[3] 
		get_user_origin(id, fOriginn, 3) 
	 
		IVecFVec(fOriginn, fOrigin) 
		if(g_buildingstage[id] == FIRST_POINT) 
		{ 
			g_buildingstage[id] = SECOND_POINT 
			 
			g_fOriginBox[id][FIRST_POINT] = fOrigin 
			 
			MJB_Print(id, "Now set the origin for the bottom left corner of the box.") 
		} 
		else 
		{ 
			g_buildingstage[id] = FIRST_POINT 
			g_buildingNet[id] = false 
			 
			g_fOriginBox[id][SECOND_POINT] = fOrigin 
			 
			CreateNet(g_fOriginBox[id][FIRST_POINT], g_fOriginBox[id][SECOND_POINT]) 
			 
			MJB_Print(id, "Successfully created net #%d", ++countnets) 
		} 
	} 
	if(is_valid_ent(gBall)) { 
		static iOwner 
		 
		iOwner = pev(gBall, pev_iuser1) 
		 
		if(iOwner != id) 
			ResetMaxspeed(id) 
	} 
	 
	return PLUGIN_HANDLED 
} 

public CurWeapon(id) 
{ 
	if(!mjb_is_player_alive(id)) 
		return PLUGIN_CONTINUE 
	if(is_valid_ent(gBall)) { 
		static iOwner 
		 
		iOwner = pev(gBall, pev_iuser1) 

		if(iOwner == id) 
			entity_set_float(id, EV_FL_maxspeed, get_pcvar_float(ball_speed)) 
	} 
	 
	return PLUGIN_HANDLED 
} 

public UpdateBall(id) 
{ 
	if(!mjb_is_simon(id) && !hasRank(id, RANK_CO_OWNER))
		return PLUGIN_HANDLED;
	
	if(is_valid_ent(gBall)) 
	{ 
		entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 })
		entity_set_origin(gBall, g_vOrigin)
		entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
		entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
		entity_set_int(gBall, EV_INT_iuser1, 0)
	} 
	 
	return PLUGIN_HANDLED 
} 

public MoveBall(where) 
{ 
	if(!is_valid_ent(gBall)) 
		return PLUGIN_HANDLED 
	 
	switch(where) 
	{ 
		case 0: 
		{ 
			new Float:orig[3] 
	 
			for(new x=0;x<3;x++) 
				orig[x] = -9999.9 
			entity_set_origin(gBall,orig) 
		} 
		case 1: 
		{ 
			if(is_valid_ent(gBall)) { 
				new vOrigin[3] 
				 
				entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 }) 
				entity_set_origin(gBall, g_vOrigin ) 
				entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE) 
				entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 }) 
				entity_set_int(gBall, EV_INT_iuser1, 0) 
				g_bScored = false 
				FVecIVec(g_vOrigin, vOrigin) 
				flameWave(vOrigin, 0, 255, 0, 15) 
			} 
		} 
	} 
	return PLUGIN_HANDLED 
} 

public plugin_precache() 
{ 
	precache_model(g_szBallModel) 
	precache_sound(g_szBallBounce)
	precache_sound(g_szBallGoal)
	precache_sound(kicked);
	precache_sound(gotball);
	 
	g_iTrailSprite = precache_model("sprites/laserbeam.spr") 
	 
	get_mapname(g_szMapname, 31) 
	strtolower(g_szMapname ) 
	 
	new szDatadir[64] 
	get_localinfo("amxx_datadir", szDatadir, charsmax(szDatadir)) 
	 
	formatex(szDatadir, charsmax( szDatadir ), "%s", szDatadir) 
	 
	if(!dir_exists( szDatadir)) 
		mkdir(szDatadir) 
	 
	formatex(g_szFile, charsmax(g_szFile), "%s/ball.ini", szDatadir) 
	 
	if(!file_exists(g_szFile)) 
	{ 
		write_file(g_szFile, "// Soccerjam Ball/Nets Spawn Editor", -1) 
		write_file(g_szFile, "// Credits to us ", -1)
		return 
	} 
	 
	LoadAll(0) 
} 

public LoadAll(id) 
{ 
	new szData[512] 
	new szMap[32] 
	new szOrigin[3][16] 
	new szfPoint[2][3][16], szlPoint[2][3][16] 
	new iFile = fopen(g_szFile, "rt") 
	 
	while(!feof(iFile)) 
	{ 
		fgets(iFile, szData, charsmax(szData)) 
		 
		if(!szData[0] || szData[0] == ';' || szData[0] == ' ' || ( szData[0] == '/' && szData[1] == '/' )) 
			continue 

		parse(szData, szMap, 31, szOrigin[0], 15, szOrigin[1], 15, szOrigin[2], 15, 
			szfPoint[0][0], 15, szfPoint[0][1], 15, szfPoint[0][2], 15, 
			szlPoint[0][0], 15, szlPoint[0][1], 15, szlPoint[0][2], 15, 
			szfPoint[1][0], 15, szfPoint[1][1], 15, szfPoint[1][2], 15, 
			szlPoint[1][0], 15, szlPoint[1][1], 15, szlPoint[1][2], 15) 
		 
		if(equal(szMap, g_szMapname)) 
		{ 
			new Float:vOrigin[3] 
			new Float:fPoint[2][3] 
			new Float:lPoint[2][3] 
			 
			vOrigin[0] = str_to_float(szOrigin[0]) 
			vOrigin[1] = str_to_float(szOrigin[1]) 
			vOrigin[2] = str_to_float(szOrigin[2]) 
			 
			for(new i = 0; i < 2; i++) 
			{ 
				for(new j = 0; j < 3; j++) 
				{ 
					fPoint[i][j] = str_to_float(szfPoint[i][j]) 
					lPoint[i][j] = str_to_float(szlPoint[i][j]) 
				} 
			} 
			 
			CreateBall(0, vOrigin) 
			 
			CreateNet(fPoint[0], lPoint[0]) 
			CreateNet(fPoint[1], lPoint[1]) 
			 
			g_vOrigin = vOrigin 
			countnets = 2 
			 
			break 
		} 
	} 
	 
	fclose(iFile) 
} 

public SaveAll(id) 
{ 
	new iBall, iNets[2], ent, i = 0; 
	new Float:vOrigin[3] 
	new Float:fMaxs[3] 
	new Float:fOrigin[3] 
	new Float:vfPoint[2][3] 
	new Float:vlPoint[2][3] 
	 
	while((ent = find_ent_by_class(ent, g_szBallName)) > 0) 
		iBall = ent 
	
	ent = -1;
	
	while((ent = find_ent_by_class(ent, "JailNet")) > 0) 
		iNets[i++] = ent 
		 
	if(iBall > 0 && iNets[0] > 0 && iNets[1] > 0 && countnets == 2) 
	{ 
		entity_get_vector(iBall, EV_VEC_origin, vOrigin) 
		 
		for(new i = 0; i < 2; i++) 
		{ 
			entity_get_vector(iNets[i], EV_VEC_origin, fOrigin) 
			entity_get_vector(iNets[i], EV_VEC_maxs, fMaxs) 
			 
			for(new j = 0; j < 3; j++) 
			{ 
				vfPoint[i][j] = fOrigin[j] + fMaxs[j] 
				vlPoint[i][j] = fOrigin[j] - fMaxs[j] 
			} 
		} 
	} 
	else 
		return PLUGIN_HANDLED 
		 
	new bool:bFound, iPos, szData[512], iFile = fopen(g_szFile, "r+") 
			 
	if(!iFile) 
		return PLUGIN_HANDLED 
			 
	while(!feof(iFile)) { 
		fgets(iFile, szData, 511) 
		parse(szData, szData, 511) 
				 
		iPos++ 
				 
		if(equal(szData, g_szMapname)) { 
			bFound = true 
					 
			new szString[512] 
			formatex(szString, 511, "%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f", g_szMapname, vOrigin[0], vOrigin[1], vOrigin[2], 
				vfPoint[0][0], vfPoint[0][1], vfPoint[0][2], vlPoint[0][0], vlPoint[0][1], vlPoint[0][2], 
				vfPoint[1][0], vfPoint[1][1], vfPoint[1][2], vlPoint[1][0], vlPoint[1][1], vlPoint[1][2]) 
					 
			write_file(g_szFile, szString, iPos - 1) 
					 
			break 
		} 
	} 
			 
	if(!bFound) 
		fprintf(iFile, "%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f^n", g_szMapname, vOrigin[0], vOrigin[1], vOrigin[2], 
			vfPoint[0][0], vfPoint[0][1], vfPoint[0][2], vlPoint[0][0], vlPoint[0][1], vlPoint[0][2], 
			vfPoint[1][0], vfPoint[1][1], vfPoint[1][2], vlPoint[1][0], vlPoint[1][1], vlPoint[1][2]) 
	fclose(iFile) 
			 
	MJB_Print(id, "Successfully saved ball & nets!") 
	 
	return PLUGIN_HANDLED 
} 
 
public EventRoundStart() 
{ 
	if(!g_bNeedBall) 
	return 
	 
	if(!is_valid_ent(gBall)) 
		CreateBall(0, g_vOrigin) 
	else { 
		entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 }) 
		entity_set_origin(gBall, g_vOrigin) 
		 
		entity_set_int(gBall, EV_INT_solid, SOLID_BBOX) 
		entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE) 
		entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 }) 
		entity_set_int(gBall, EV_INT_iuser1, 0) 
	} 
} 

public FwdHamObjectCaps(id) 
{ 
	if(pev_valid(gBall) && mjb_is_player_alive(id)) { 
		static iOwner 
		 
		iOwner = pev(gBall, pev_iuser1) 
		 
		if(iOwner == id) 
		{ 
			KickBall(id) 
			g_Owner = iOwner 
		 
			get_user_origin(id, g_OwnerOrigin) 
		} 
	} 
} 

public FwdThinkBall(ent) { 
	if(!is_valid_ent(gBall)) 
		return PLUGIN_HANDLED 
	 
	static Float:vOrigin[3], Float:vBallVelocity[3] 
	 
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.05) 
	entity_get_vector(ent, EV_VEC_origin, vOrigin) 
	entity_get_vector(ent, EV_VEC_velocity, vBallVelocity) 
	 
	static iOwner 
	static iSolid 
	 
	iSolid = pev(ent, pev_solid) 
	iOwner = pev(ent, pev_iuser1) 
	 
	static Float:flGametime, Float:flLastThink 
	flGametime = get_gametime() 
	 
	if(flLastThink < flGametime) { 
		if(floatround(vector_length(vBallVelocity)) > 10) 
		{ 
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
			write_byte(TE_KILLBEAM) 
			write_short(gBall) 
			message_end() 
			 
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
			write_byte(TE_BEAMFOLLOW) 
			write_short(gBall) 
			write_short(g_iTrailSprite) 
			write_byte(10) 
			write_byte(10) 
			write_byte(0) 
			write_byte(50) 
			write_byte(255) 
			write_byte(200) 
			message_end() 
		} 
		 
		flLastThink = flGametime + 3.0 
	} 
	 
	if(iOwner > 0) 
	{ 
		static Float:vOwnerOrigin[3] 
		static const Float:vVelocity[3] = { 1.0, 1.0, 0.0 } 
		entity_get_vector( iOwner, EV_VEC_origin, vOwnerOrigin ) 
		 
		if(!mjb_is_player_alive(iOwner)) 
		{ 
			vOwnerOrigin[ 2 ] += 5.0 
			 
			entity_set_int(ent, EV_INT_iuser1, 0) 
			entity_set_origin(ent, vOwnerOrigin) 
			entity_set_vector(ent, EV_VEC_velocity, vVelocity) 
			 
			return PLUGIN_CONTINUE 
		} 
		 
		if(iSolid != SOLID_NOT) 
		{ 
			set_pev(ent, pev_solid, SOLID_NOT) 
			set_hudmessage(255, 20, 20, -1.0, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2) 
			show_hudmessage(iOwner, "** YOU HAVE THE BALL! **") 
		} 
		 
		static Float:vAngles[3], Float:vReturn[3] 
		entity_get_vector( iOwner, EV_VEC_v_angle, vAngles ) 
		 
		vReturn[0] = (floatcos(vAngles[1], degrees) * 55.0) + vOwnerOrigin[0] 
		vReturn[1] = (floatsin(vAngles[1], degrees) * 55.0) + vOwnerOrigin[1] 
		vReturn[2] = vOwnerOrigin[2] 
		vReturn[2] -= (entity_get_int(iOwner, EV_INT_flags) & FL_DUCKING) ? 10 : 30 
		 
		entity_set_vector(ent, EV_VEC_velocity, vVelocity) 
		entity_set_origin(ent, vReturn) 
	} else { 
		if(iSolid != SOLID_BBOX ) 
			set_pev(ent, pev_solid, SOLID_BBOX) 
		 
		static Float:flLastVerticalOrigin 
		 
		if(vBallVelocity[2] == 0.0) 
		{ 
			static iCounts 
			 
			if(flLastVerticalOrigin > vOrigin[2]) 
			{ 
				iCounts++ 
				 
				if( iCounts > 10 && !g_bScored) 
				{ 
					iCounts = 0 
					UpdateBall(0) 
				} 
			} else { 
				iCounts = 0 
				 
				if(PointContents(vOrigin) != CONTENTS_EMPTY && !g_bScored) 
					UpdateBall(0) 
			} 
			 
			flLastVerticalOrigin = vOrigin[2] 
		} 
	} 
	 
	return PLUGIN_CONTINUE 
} 

KickBall(id) 
{ 
	ResetMaxspeed(id) 
	static Float:vOrigin[3] 
	entity_get_vector(gBall, EV_VEC_origin, vOrigin) 
	 
	if(PointContents(vOrigin) != CONTENTS_EMPTY) 
		return PLUGIN_HANDLED 

	new Float:vVelocity[3] 
	velocity_by_aim( id, get_pcvar_num(ball_distance), vVelocity) 
		 
	set_pev(gBall, pev_solid, SOLID_BBOX) 
	entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 }) 
	entity_set_int(gBall, EV_INT_iuser1, 0) 
	entity_set_vector(gBall, EV_VEC_velocity, vVelocity) 
	emit_sound(id, CHAN_ITEM, kicked, 1.0, ATTN_NORM, 0, PITCH_NORM)
		 
	return PLUGIN_CONTINUE 
} 

public Goal(iNet) 
{ 
	new name[32], fdistance 
	new Float:fOrigin[3] 
	entity_get_vector(gBall, EV_VEC_origin,fOrigin) 
	new Origin[3] 
	 
	FVecIVec(fOrigin, Origin) 
	 
	get_user_name(g_Owner, name,31) 
	fdistance = get_distance(Origin, g_OwnerOrigin) 
	set_hudmessage(211, 211, 211, -1.0, 0.82, 0, 6.0, 6.0) 
	 
	if(g_Owner != 0) 
	{
		show_hudmessage(0, "%s scored a goal^nfrom %d units!", name, fdistance) 
		emit_sound(g_Owner, CHAN_ITEM, g_szBallGoal, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	 
	flameWave(Origin, 0, 0, 255, 4) 
	 
	g_bScored = true 
	if (pev_valid(iNet) && g_Owner != 0) {
		new ret;
		ExecuteForward(g_fwScored, ret, g_Owner, gBall, pev(iNet, pev_iuser2));
		MJB_Print(0, "goal %d team %s", pev(iNet, pev_iuser2), (pev(iNet, pev_iuser2) == BLUE) ? "BLUE" : "RED");
	}
	 
	MoveBall(0) 
	 
	set_task(5.0, "MoveBall", 1) 
} 
	
public FwdTouchPlayer(Ball, id) 
{ 
	if(is_user_bot(id)) 
		return PLUGIN_CONTINUE 
	 
	static iOwner 
	 
	iOwner = pev(Ball, pev_iuser1) 
	 
	if( iOwner == 0 ) 
	{ 
		entity_set_int(Ball, EV_INT_iuser1, id) 
		entity_set_float(id, EV_FL_maxspeed, get_pcvar_float(ball_speed)) 
		set_hudmessage(255, 20, 20, -1.0, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)
		show_hudmessage(id,"*** YOU HAVE THE BALL! ***")
		emit_sound(id, CHAN_ITEM, gotball, 1.0, ATTN_NORM, 0, PITCH_NORM)
	} 
	 
	return PLUGIN_CONTINUE 
} 

public FwdTouchWorld(Ball, World) 
{ 
	static Float:vVelocity[3] 
	entity_get_vector(Ball, EV_VEC_velocity, vVelocity) 
	 
	if(floatround(vector_length(vVelocity)) > 10) 
	{ 
		vVelocity[0] *= 0.85 
		vVelocity[1] *= 0.85 
		vVelocity[2] *= 0.85 
		 
		entity_set_vector(Ball, EV_VEC_velocity, vVelocity) 
		 
		emit_sound(Ball, CHAN_ITEM, g_szBallBounce, 1.0, ATTN_NORM, 0, PITCH_NORM) 
	} 

	return PLUGIN_CONTINUE 
} 

public FwdTouch(ent, id) 
{ 
	static szNameEnt[32], szNameId[32] 
	pev(ent, pev_classname, szNameEnt, sizeof szNameEnt - 1) 
	pev(id, pev_classname, szNameId, sizeof szNameId - 1) 
	 
	static Float:fGameTime 
	fGameTime = get_gametime() 
	 
	if(equal(szNameEnt, "JailNet") && equal(szNameId, g_szBallName) && (fGameTime - g_fLastTouch) > 0.1) 
	{ 
		Goal(ent) 
		g_fLastTouch = fGameTime 
	} 
} 

CreateBall(id, Float:vOrigin[ 3 ] = { 0.0, 0.0, 0.0 }) 
{ 
	if(!id && vOrigin[0] == 0.0 && vOrigin[1] == 0.0 && vOrigin[2] == 0.0) 
		return 0 
	 
	g_bNeedBall = true 
	 
	gBall = create_entity("info_target") 
	 
	if(is_valid_ent(gBall)) 
	{ 
		entity_set_string(gBall, EV_SZ_classname, g_szBallName) 
		entity_set_int(gBall, EV_INT_solid, SOLID_BBOX) 
		entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE) 
		entity_set_model(gBall, g_szBallModel) 
		entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 }) 
		 
		entity_set_float(gBall, EV_FL_framerate, 0.0) 
		entity_set_int(gBall, EV_INT_sequence, 0) 
		 
		entity_set_float(gBall, EV_FL_nextthink, get_gametime() + 0.05) 
		 
		if(id > 0) { 
			new iOrigin[3] 
			get_user_origin(id, iOrigin, 3) 
			IVecFVec(iOrigin, vOrigin) 
		 
			vOrigin[2] += 5.0 
			 
			entity_set_origin(gBall, vOrigin) 
		} else 
			entity_set_origin(gBall, vOrigin) 
		 
		g_vOrigin = vOrigin 
		 
		return gBall 
	} 
	 
	return -1 
} 

CreateNet(Float:firstPoint[3], Float:lastPoint[3]) 
{ 
	new ent 
	new Float:fCenter[3], Float:fSize[3] 
	new Float:fMins[3], Float:fMaxs[3] 
		 
	for ( new i = 0; i < 3; i++ ) 
	{ 
		fCenter[i] = (firstPoint[i] + lastPoint[i]) / 2.0 
				 
		fSize[i] = get_float_difference(firstPoint[i], lastPoint[i]) 
				 
		fMins[i] = fSize[i] / -2.0 
		fMaxs[i] = fSize[i] / 2.0 
	} 
	 
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target")) 
	 
	if (ent) { 
		engfunc(EngFunc_SetOrigin, ent, fCenter) 
		new goal = 1;
		new ent_check = engfunc(EngFunc_FindEntityByString, -1, "classname", "JailNet");
		if (ent_check != 0)
			goal = 2;
		set_pev(ent, pev_classname, "JailNet");
		set_pev(ent, pev_iuser2, goal);
		dllfunc(DLLFunc_Spawn, ent) 
	 
		set_pev(ent, pev_movetype, MOVETYPE_FLY) 
		set_pev(ent, pev_solid, SOLID_TRIGGER) 
	 
		engfunc(EngFunc_SetSize, ent, fMins, fMaxs) 
	} 
}

public sqrt(num) 
{         
	new div = num 
	new result = 1 
	 
	while (div > result) 
	{ 
		div = (div + result) / 2 
		result = num / div 
	} 
	 
	return div 
} 

stock Float:get_float_difference(Float:num1, Float:num2) 
{ 
	if(num1 > num2) 
		return (num1-num2) 
	else if(num2 > num1) 
		return (num2-num1) 
	 
	return 0.0 
} 

public taskShowNet() 
{ 
	new ent 
	new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3] 
	new vMaxs[3], vMins[3] 
	new iColor[3] = { 255, 0, 0 } 
	new pl[32], plnum, id;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		id = pl[i];
		if (!mjb_is_valid_player(id) || is_user_bot(id))
			continue;
		while((ent = find_ent_by_class(ent, "JailNet")) > 0) 
		{ 
			pev(ent, pev_mins, fMins) 
			pev(ent, pev_maxs, fMaxs) 
			pev(ent, pev_origin, fOrigin) 
		 
			fMins[0] += fOrigin[0] 
			fMins[1] += fOrigin[1] 
			fMins[2] += fOrigin[2] 
			fMaxs[0] += fOrigin[0] 
			fMaxs[1] += fOrigin[1] 
			fMaxs[2] += fOrigin[2] 
			 
			FVecIVec(fMins, vMins) 
			FVecIVec(fMaxs, vMaxs) 
		
			fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor) 
			fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMins[1], vMaxs[2], iColor) 
			fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMaxs[1], vMins[2], iColor) 
			fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor) 
			fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMaxs[1], vMins[2], iColor) 
			fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMins[1], vMaxs[2], iColor) 
			fm_draw_line(id, vMins[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMins[2], iColor) 
			fm_draw_line(id, vMins[0], vMaxs[1], vMins[2], vMaxs[0], vMaxs[1], vMins[2], iColor) 
			fm_draw_line(id, vMaxs[0], vMaxs[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor) 
			fm_draw_line(id, vMaxs[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMaxs[2], iColor) 
			fm_draw_line(id, vMaxs[0], vMins[1], vMaxs[2], vMins[0], vMins[1], vMaxs[2], iColor) 
			fm_draw_line(id, vMins[0], vMins[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor) 
		} 
	}
} 

public flameWave(Origin[3], r, g, b, speed) 
{ 
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BEAMCYLINDER) 
	write_coord(Origin[0])    //position.x 
	write_coord(Origin[1])    //position.y 
	write_coord(Origin[2]-20)    //position.z 
	write_coord(Origin[0])        //axis.x 
	write_coord(Origin[1])        //axis.y 
	write_coord(Origin[2]+200)    //axis.z 
	write_short(g_iTrailSprite)    //sprite index 
	write_byte(0)           //starting frame 
	write_byte(0)           //frame rate in 0.1's 
	write_byte(5)            //life in 0.1's 
	write_byte(70)            //line width in 0.1's 
	write_byte(10)            //noise amplitude in 0.01's 
	write_byte(r)            // r 
	write_byte(g)            // g 
	write_byte(b)        // b 
	write_byte(255)            // brightness 
	write_byte(speed/20)        // scroll speed in 0.1's 
	message_end() 
} 
stock fm_draw_line(id, x1, y1, z1, x2, y2, z2, g_iColor[3]) 
{ 
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, id ? id : 0) 
	 
	write_byte(TE_BEAMPOINTS) 
	 
	write_coord(x1) 
	write_coord(y1) 
	write_coord(z1) 
	 
	write_coord(x2) 
	write_coord(y2) 
	write_coord(z2) 
	 
	write_short(g_iTrailSprite) 
	write_byte(1) 
	write_byte(1) 
	write_byte(10) 
	write_byte(5) 
	write_byte(0) 
	 
	write_byte(g_iColor[0]) 
	write_byte(g_iColor[1]) 
	write_byte(g_iColor[2]) 
	 
	write_byte(200) 
	write_byte(0) 
	 
	message_end() 
} 
