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
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "Cell Manager System"
#define DOOR_TAG 921321

/* =========================
   GLOBAL DATA
========================= */
new Array:g_aDoorsList, g_iDoorsSize, Trie:g_tButtonsMap;
new g_isDoorOpen = MJB_False;
new g_iFakeMetaKV_Handler;

/* Forwards */
new g_fwCellOpened, g_fwCellClosed;

/* =========================
   PLUGIN LIFECYCLE
========================= */
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_logevent("OnRoundEnd", 2, "1=Round_End");
	g_fwCellOpened = CreateMultiForward("mjb_cell_opened", ET_IGNORE);
	g_fwCellClosed = CreateMultiForward("mjb_cell_closed", ET_IGNORE);
	doors_init();
	ham_init();
}

public plugin_end() {
	ArrayDestroy(g_aDoorsList);
}

public plugin_precache() {
	g_tButtonsMap = TrieCreate();
	g_iFakeMetaKV_Handler = register_forward(FM_KeyValue, "EntityKeyValueProcessed", MJB_True);
}

public OnRoundEnd() {
	MJB_CloseCell();	
}

/* =========================
   DOORS COLLECTING LOGIC
========================= */
doors_init() {
	g_aDoorsList = ArrayCreate();
	new iSpawnPoint, Float:fOrigin[3];
	while ((iSpawnPoint = engfunc(EngFunc_FindEntityByString, iSpawnPoint, "classname", "info_player_deathmatch"))) {
		pev(iSpawnPoint, pev_origin, fOrigin)
		GetDoorsFromSpawnPoint(fOrigin);
	}
	TrieDestroy(g_tButtonsMap);
	unregister_forward(FM_KeyValue, g_iFakeMetaKV_Handler, MJB_True);
}

public GetDoorsFromSpawnPoint(Float:SpawnPointOrigin[3]) {
	new iEntity = 0, szClassName[32], szTargetName[32];
	while ((iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, SpawnPointOrigin, 265.0))) {
		if (!pev_valid(iEntity))
			continue;
		
		pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
		if (contain(szClassName, "door") == -1)
			continue;
		
		if (pev(iEntity, pev_iuser1) == DOOR_TAG)
			continue;
		
		pev(iEntity, pev_targetname, szTargetName, charsmax(szTargetName));
		if (TrieKeyExists(g_tButtonsMap, szTargetName)) {
			set_pev(iEntity, pev_iuser1, DOOR_TAG);
			ArrayPushCell(g_aDoorsList, iEntity);
			fm_set_kvd(iEntity, szClassName, "spawnflags", "0");
			fm_set_kvd(iEntity, szClassName, "wait", "-1");
		}
	}
	g_iDoorsSize = ArraySize(g_aDoorsList);
}

public EntityKeyValueProcessed(iEntity, KVD_Handle) {
	if (!pev_valid(iEntity))
		return;
	
	new szBuffer[64];
	get_kvd(KVD_Handle, KV_ClassName, szBuffer, charsmax(szBuffer)) // gets the entity class name
	if (contain(szBuffer, "button") == -1) //this isnt a button
		return;
		
	//we need the KV pair target and targetname to save it in g_tButtonsList
	get_kvd(KVD_Handle, KV_KeyName, szBuffer, charsmax(szBuffer));
	if (contain(szBuffer, "target") == -1)
		return;
		
	get_kvd(KVD_Handle, KV_Value, szBuffer, charsmax(szBuffer));
	TrieSetCell(g_tButtonsMap, szBuffer, iEntity);
}

/* =========================
   OVERRIDING DEFAULT DOOR FUNCTIONS
========================= */

public ham_init() {
	new const szDoorClasses[][] = { "func_door", "func_door_rotating" };
	for (new i = 0; i < sizeof(szDoorClasses); i++) {
		RegisterHam(Ham_Use, szDoorClasses[i], "Ham_Use_Door");
		RegisterHam(Ham_Blocked, szDoorClasses[i], "Ham_Door_Blocked");
	}
}

public Ham_Use_Door(iEntity, iCaller, iActivator) {
	if (iCaller != iActivator && (pev(iEntity, pev_iuser1) == DOOR_TAG))
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public Ham_Door_Blocked(iBlocked, iBlocker) {
	if (mjb_is_valid_player(iBlocker) && mjb_is_player_alive(iBlocker) && (pev(iBlocked, pev_iuser1) == DOOR_TAG)) {
		ExecuteHam(Ham_TakeDamage, iBlocker, 0, 0, 9999.0, 0);
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

/* =========================
   API
========================= */
public plugin_natives() {
	register_library("MJB_Core");
	
	register_native("mjb_open_cell", "MJB_OpenCell");
	register_native("mjb_close_cell", "MJB_CloseCell");
	register_native("mjb_is_cell_opened", "MJB_IsCellOpened");
	register_native("mjb_is_a_cell", "MJB_IsACell");
}


public MJB_OpenCell() {
	for (new i = 0; i < g_iDoorsSize; i++) {
		new ent = ArrayGetCell(g_aDoorsList, i);
		dllfunc(DLLFunc_Use, ent, 0);
	}
	MJB_SetDoorState(MJB_True);
}

public MJB_CloseCell() {
	for (new i = 0; i < g_iDoorsSize; i++) {
		new ent = ArrayGetCell(g_aDoorsList, i);
		dllfunc(DLLFunc_Think, ent, 0);
	}
	MJB_SetDoorState(MJB_False);
}

public MJB_SetDoorState(iState) {
	new ret;
	if (iState == MJB_True) {
		g_isDoorOpen = MJB_True;
		ExecuteForward(g_fwCellOpened, ret);
	} else if (iState == MJB_False) {
		g_isDoorOpen = MJB_False;
		ExecuteForward(g_fwCellClosed, ret);
	}
}

public MJB_IsCellOpened() {
	return g_isDoorOpen;
}


public MJB_IsACell(entity) {
	if (!pev_valid(entity))
		return 0;
	
	new szClassname[32];
	pev(entity, pev_classname, szClassname, 31);
	if ((equal(szClassname, "func_door") || equal(szClassname, "func_door_rotating")) && pev(entity, pev_iuser1) == DOOR_TAG)
		return 1;
	return 0;
}