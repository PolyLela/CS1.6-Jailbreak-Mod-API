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
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "JB Stable Skin System - FIXED"

// ================= OFFSETS =================
#define ClCorpse_ModelName 1
#define ClCorpse_PlayerID 12
#define TASK_SKIN 1337

// ================= FLAGS =================
#define ADMIN ADMIN_BAN
#define HEAD_ADMIN ADMIN_CVAR

// ================= MODELS =================
static const szAdminModel[]    = "MoonJb_Admin";
static const szPrisonerModel[] = "mjb_prisoners";
static const szGuardModel[]    = "MOON_JB_guard";
static const szSimonModel[]    = "MOON_JB_Simon";

static const szSoccerBlueModel[] = "MJB_BlueTeam";
static const szSoccerRedModel[]  = "MJB_RedTeam";

// ================= BODY ENUMS =================
enum _:AdminBody {
    ADMIN_PRISONER = 2,
    ADMIN_GUARD
};

enum _:AdminSkin {
    BLUE_ADMIN = 0,
    YELLOW_ADMIN,
    RAINBOW_ADMIN,
    FREEDAY_ADMIN,
    WANTED_ADMIN
};

enum _:PrisonerSkin {
    FREEDAY_SKIN = 6,
    WANTED_SKIN
};

// ================= STATE STORAGE =================
new Trie:g_tModelIndex;

// LIVE STATE
new g_szLastModel[33][32];
new g_iLastBody[33];
new g_iLastSkin[33];

// DEATH SNAPSHOT (IMPORTANT FIX)
new g_szDeathModel[33][32];
new g_iDeathBody[33];
new g_iDeathSkin[33];
new g_bIsDead[33];

// CACHE
new g_iCachedSkin[33];
new g_bSkinLocked[33];

// ================= PRECACHE =================
public plugin_precache()
{
    g_tModelIndex = TrieCreate();

    precache_and_store(szAdminModel);
    precache_and_store(szPrisonerModel);
    precache_and_store(szGuardModel);
    precache_and_store(szSimonModel);
    precache_and_store(szSoccerBlueModel);
    precache_and_store(szSoccerRedModel);
}

precache_and_store(const model[])
{
    new path[128];
    formatex(path, charsmax(path),
        "models/player/%s/%s.mdl", model, model);

    new idx = precache_model(path);
    TrieSetCell(g_tModelIndex, model, idx);
}

// ================= INIT =================
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", 1);

    register_forward(FM_SetClientKeyValue, "SetClientKeyValue");

    register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse");
}

// ================= CLEANUP =================
public plugin_end()
{
    TrieDestroy(g_tModelIndex);
}

// ================= SPAWN =================
public OnPlayerSpawn(id)
{
    if(!mjb_is_valid_player(id))
        return;

    g_bIsDead[id] = false;
    
    if(task_exists(id + TASK_SKIN))
	remove_task(id + TASK_SKIN);
    set_task(0.1, "ApplySkinTask", id + TASK_SKIN);
}

// ================= ROUND CYCLE EVENTS =================
public mjb_simon_set(id) {
    if(!mjb_is_valid_player(id))
        return;

    if(task_exists(id + TASK_SKIN))
	remove_task(id + TASK_SKIN);
    set_task(0.1, "ApplySkinTask", id + TASK_SKIN);
}

public mjb_simon_cleared(id) {
    if(!mjb_is_valid_player(id) || !mjb_is_player_alive(id))
        return;
	
    if(task_exists(id + TASK_SKIN))
	remove_task(id + TASK_SKIN);
    set_task(0.2, "ApplySkinTask", id + TASK_SKIN);
}

public mjb_state_changed(id) {
    if(!mjb_is_valid_player(id) || !mjb_is_player_alive(id))
        return;
	
    if(task_exists(id + TASK_SKIN))
	remove_task(id + TASK_SKIN);
    set_task(0.1, "ApplySkinTask", id + TASK_SKIN);
}

public mjb_phase_changed() {
	new pl[32], plnum;
	get_players(pl, plnum, "ah");
	for(new i = 0; i  < plnum; i++) {
		if (!mjb_is_valid_player(pl[i]) || !mjb_is_player_alive(pl[i])) 
			continue
		if(task_exists(pl[i] + TASK_SKIN))
			remove_task(pl[i] + TASK_SKIN);
		set_task(0.1, "ApplySkinTask", pl[i] + TASK_SKIN);
	}
}

// ================= DEATH SNAPSHOT =================
public OnPlayerKilled(victim, attacker, shouldgib)
{
    if(!mjb_is_valid_player(victim))
        return;

    g_bIsDead[victim] = true;

    // snapshot CURRENT correct skin BEFORE engine resets anything
    copy(g_szDeathModel[victim], 31, g_szLastModel[victim]);
    g_iDeathBody[victim] = g_iLastBody[victim];
    g_iDeathSkin[victim] = g_iLastSkin[victim];
}

// ================= CORE APPLY =================
public ApplySkinTask(taskid) {
	new id = taskid - TASK_SKIN;
	ApplySkin(id);
}

public ApplySkin(id)
{
    if(!mjb_is_valid_player(id))
        return;

    if(g_bIsDead[id])
        return; // IMPORTANT: stop alive updates on dead players

    new model[32], body, skin;

    GetDesiredSkin(id, model, charsmax(model), body, skin);

    if(equal(model, g_szLastModel[id]) &&
       body == g_iLastBody[id] &&
       skin == g_iLastSkin[id])
        return;

    copy(g_szLastModel[id], 31, model);
    g_iLastBody[id] = body;
    g_iLastSkin[id] = skin;

    ApplyToEngine(id, model, body, skin);
}

// ================= ENGINE APPLY =================
ApplyToEngine(id, const model[], body, skin)
{
    if(!mjb_is_valid_player(id))
        return;

    if(mjb_is_player_alive(id))
    {
        set_user_info(id, "model", model);
    }
    else
    {
        cs_set_user_model(id, model);
    }

    if(TrieKeyExists(g_tModelIndex, model))
    {
        new idx;
        TrieGetCell(g_tModelIndex, model, idx);
        set_pev(id, pev_modelindex, idx);
    }
    set_pev(id, pev_body, body);
    set_pev(id, pev_skin, skin);
}

// ================= KEY HOOK (FIXED) =================
public SetClientKeyValue(id, const buffer[], const key[], const value[])
{
    if(!mjb_is_valid_player(id))
        return FMRES_IGNORED;

    if(!equal(key, "model"))
        return FMRES_IGNORED;

    new model[32], body, skin;
    GetDesiredSkin(id, model, charsmax(model), body, skin);

    if(equal(value, model))
        return FMRES_IGNORED;

    set_user_info(id, "model", model);
    if(TrieKeyExists(g_tModelIndex, model))
    {
        new idx;
        TrieGetCell(g_tModelIndex, model, idx);
        set_pev(id, pev_modelindex, idx);
    }
    set_pev(id, pev_body, body);
    set_pev(id, pev_skin, skin);

    return FMRES_SUPERCEDE;
}

// ================= CORPSE FIX (IMPORTANT) =================
public Message_ClCorpse()
{
    new id = get_msg_arg_int(ClCorpse_PlayerID);

    if(!mjb_is_valid_player(id))
        return;

    if(!g_bIsDead[id])
        return;

    set_msg_arg_string(ClCorpse_ModelName, g_szDeathModel[id]);
}

// ================= SKIN LOGIC =================
GetDesiredSkin(id, model[], len, &body, &skin)
{
	new team  = mjb_get_team(id);
	new iState = mjb_get_state(id);
	new phase = mjb_get_phase();
	
	// ================= GUARD =================
	if(team == GUARD)
	{
		if(mjb_is_simon(id))
		{
			copy(model, len, szSimonModel);
			body = 0; skin = 0;
			return;
		}
		else if(hasRank(id, RANK_ADMIN))
		{
			copy(model, len, szAdminModel);
			body = ADMIN_GUARD;
			skin = 0;
			return;
		}
		
		copy(model, len, szGuardModel);
		body = 0; skin = 0;
		return;
	}
	
	// ================= PRISONER =================
	if(team == PRISONER)
	{
		/*if(iState == DUEL)
		{
			if(hasRank(id, RANK_DEPUTY_HEAD))
			{
				copy(model, len, szAdminModel);
				body = ADMIN_PRISONER;
				skin = RAINBOW_ADMIN;
			}
			else if (hasRank(id, RANK_GOLD_ADMIN))
			{
				copy(model, len, szAdminModel);
				body = ADMIN_PRISONER;
				skin = YELLOW_ADMIN;
			}
			else if (hasRank(id, RANK_ADMIN))
			{
				copy(model, len, szAdminModel);
				body = ADMIN_PRISONER;
				skin = BLUE_ADMIN;
			}
			else 
			{
				copy(model, len, szPrisonerModel);
				body = 0;
			
				if(!g_bSkinLocked[id])
				{
					g_iCachedSkin[id] = random_num(0, 4);
					g_bSkinLocked[id] = true;
				}
			
				skin = g_iCachedSkin[id];
			}
			
			return;
		}*/
		
		if(iState == PRISONER_WANTED)
		{
			if(hasRank(id, RANK_ADMIN))
			{
				copy(model, len, szAdminModel);
				body = ADMIN_PRISONER;
				skin = WANTED_ADMIN;
			} else {
				copy(model, len, szPrisonerModel);
				body = 0;
				skin = WANTED_SKIN;
			}
			return;
		}
		
		if(iState == PRISONER_SOCCER && !hasRank(id, RANK_ADMIN) && mjb_get_user_mg_team(id) > 0)
		{
			if (mjb_get_user_mg_team(id) == 1)
				copy(model, len, szSoccerBlueModel);
			else
				copy(model, len, szSoccerRedModel);
			body = 0; skin = 0;
			return;
		}
		
		if(iState == PRISONER_FREEDAY || phase == PHASE_FREEDAY)
		{
			if(hasRank(id, RANK_ADMIN))
			{
				copy(model, len, szAdminModel);
				body = ADMIN_PRISONER;
				skin = FREEDAY_ADMIN;
			}
			else 
			{
				copy(model, len, szPrisonerModel);
				body = 0;
				skin = FREEDAY_SKIN;
			}
			return;
		}
		
		if(hasRank(id, RANK_DEPUTY_HEAD))
		{
			copy(model, len, szAdminModel);
			body = ADMIN_PRISONER;
			skin = RAINBOW_ADMIN;
		}
		else if (hasRank(id, RANK_GOLD_ADMIN))
		{
			copy(model, len, szAdminModel);
			body = ADMIN_PRISONER;
			skin = YELLOW_ADMIN;
		}
		else if (hasRank(id, RANK_ADMIN))
		{
			copy(model, len, szAdminModel);
			body = ADMIN_PRISONER;
			skin = BLUE_ADMIN;
		}
		else 
		{
			copy(model, len, szPrisonerModel);
			body = 0;
		
			if(!g_bSkinLocked[id])
			{
				g_iCachedSkin[id] = random_num(0, 4);
				g_bSkinLocked[id] = true;
			}
		
			skin = g_iCachedSkin[id];
		}
		
		return;
	}
	
	model[0] = 0;
}
