#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <regex>
#include <reapi>
#include <MJB_Stocks>
#include <MJB_Consts>

#define PLUGIN_NAME	"Advanced Freekill"
#define PLUGIN_VERSION	"0.8.1"
#define PLUGIN_AUTHOR	"Exolent"

#pragma semicolon 1



// ===============================================
// CUSTOMIZATION STARTS HERE
// ===============================================



// Keep as it is
//#define KEEP_DEFAULT_BANS


// uncomment the line below if you want the history to be in one file
//#define HISTORY_ONE_FILE


// if you must have a maximum amount of fks to be compatible with AMXX versions before 1.8.0
// change this number to your maximum amount
// if you would rather have unlimited (requires AMXX 1.8.0 or higher) then set it to 0
#define MAX_FKS 0


// if you want to use SQL for your server, then uncomment the line below
//#define USING_SQL


// ===============================================
// CUSTOMIZATION ENDS HERE
// ===============================================



#if defined USING_SQL
#include <sqlx>

#define TABLE_NAME			"advanced_fks"
#define KEY_NAME			"name"
#define KEY_STEAMID			"steamid"
#define KEY_FKLENGTH		"fklength"
#define KEY_UNFKTIME		"unfkltime"
#define KEY_REASON			"reason"
#define KEY_ADMIN_NAME		"admin_name"
#define KEY_ADMIN_STEAMID	"admin_steamid"

#define RELOAD_FKS_INTERVAL	60.0
#endif

#define REGEX_IP_PATTERN "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
#define REGEX_STEAMID_PATTERN "^^STEAM_0:(0|1):\d+$"

new Regex:g_IP_pattern;
new Regex:g_SteamID_pattern;
new g_regex_return;

/*bool:IsValidIP(const ip[])
{
	return regex_match_c(ip, g_IP_pattern, g_regex_return) > 0;
}*/

#define IsValidIP(%1) (regex_match_c(%1, g_IP_pattern, g_regex_return) > 0)

/*bool:IsValidAuthid(const authid[])
{
	return regex_match_c(authid, g_SteamID_pattern, g_regex_return) > 0;
}*/

#define IsValidAuthid(%1) (regex_match_c(%1, g_SteamID_pattern, g_regex_return) > 0)


enum // for name displaying
{
	ACTIVITY_NONE, // nothing is shown
	ACTIVITY_HIDE, // admin name is hidden
	ACTIVITY_SHOW  // admin name is shown
};
new const g_admin_activity[] =
{
	ACTIVITY_NONE, // amx_show_activity 0 = show nothing to everyone
	ACTIVITY_HIDE, // amx_show_activity 1 = hide admin name from everyone
	ACTIVITY_SHOW, // amx_show_activity 2 = show admin name to everyone
	ACTIVITY_SHOW, // amx_show_activity 3 = show name to admins but hide it from normal users
	ACTIVITY_SHOW, // amx_show_activity 4 = show name to admins but show nothing to normal users
	ACTIVITY_HIDE  // amx_show_activity 5 = hide name from admins but show nothing to normal users
};
new const g_normal_activity[] =
{
	ACTIVITY_NONE, // amx_show_activity 0 = show nothing to everyone
	ACTIVITY_HIDE, // amx_show_activity 1 = hide admin name from everyone
	ACTIVITY_SHOW, // amx_show_activity 2 = show admin name to everyone
	ACTIVITY_HIDE, // amx_show_activity 3 = show name to admins but hide it from normal users
	ACTIVITY_NONE, // amx_show_activity 4 = show name to admins but show nothing to normal users
	ACTIVITY_NONE  // amx_show_activity 5 = hide name from admins but show nothing to normal users
};


#if MAX_FKS <= 0
enum _:FKLData
{
	fk_name[32],
	fk_steamid[35],
	fk_fklength,
	fk_unfktime[32],
	fk_reason[128],
	fk_admin_name[64],
	fk_admin_steamid[35]
};

new Trie:g_trie;
new Array:g_array;
#else
new g_names[MAX_FKS][32];
new g_steamids[MAX_FKS][35];
new g_fklengths[MAX_FKS];
new g_unfkltimes[MAX_FKS][32];
new g_reasons[MAX_FKS][128];
new g_admin_names[MAX_FKS][64];
new g_admin_steamids[MAX_FKS][35];
#endif
new g_total_fks;

#if !defined USING_SQL
new g_fk_file[64];
#else
new Handle:g_sql_tuple;
new bool:g_loading_fks = true;
#endif

new ab_website;
new ab_fkdelay;
new ab_unfklcheck;

new amx_show_activity;

#if MAX_FKS <= 0
new Array:g_maxfkl_times;
new Array:g_maxfkl_flags;
#else
#define MAX_FKLIMITS	30
new g_maxfkl_times[MAX_FKLIMITS];
new g_maxfkl_flags[MAX_FKLIMITS];
#endif
new g_total_maxfkl_times;

new g_unfkl_entity;

new g_max_clients;

new g_msgid_SayText;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar("advanced_fks", PLUGIN_VERSION, FCVAR_SPONLY);
	
	register_dictionary("advanced_fks.txt");

	RegisterHookChain(RG_CBasePlayer_Spawn, "PlayerSpawned", true);
	RegisterHookChain(RG_CBasePlayer_RoundRespawn, "PlayerSpawned", true);

	register_concmd("mjb_set_fk", 	 "CmdFK", 	    RANK_FULL_ADMIN, "<nick, #userid, authid> <time in minutes> <reason>");
	register_concmd("mjb_set_ip_fk", "CmdFKIp", 	RANK_FULL_ADMIN, "<nick, #userid, authid> <time in minutes> <reason>");
	register_concmd("mjb_add_fk",    "CmdAddFK",	RANK_CO_OWNER, "<name> <authid or ip> <time in minutes> <reason>");
	register_concmd("mjb_remove_fk", "CmdRemoveFK", 	RANK_ADMINISTRATOR, "<authid or ip>");
	register_concmd("mjb_fklist", 	  "CmdFKList",RANK_FULL_ADMIN, "[start] -- shows everyone who is in fk list");
	register_srvcmd("mjb_addfklimit", "CmdAddFKLimit", -1, "<flag> <time in minutes>");
	
	ab_website = register_cvar("ab_website", "");
	ab_fkdelay = register_cvar("ab_fkdelay", "1.0");
	ab_unfklcheck = register_cvar("ab_unfklcheck", "5.0");
	
	amx_show_activity = register_cvar("amx_show_activity", "2");
	
	#if MAX_FKS <= 0
	g_trie = TrieCreate();
	g_array = ArrayCreate(FKLData);
	#endif
	
	#if !defined MAX_FKLIMITS
	g_maxfkl_times = ArrayCreate(1);
	g_maxfkl_flags = ArrayCreate(1);
	#endif
	
	#if !defined USING_SQL
	get_datadir(g_fk_file, sizeof(g_fk_file) - 1);
	add(g_fk_file, sizeof(g_fk_file) - 1, "/advanced_fks.txt");
	
	LoadFKs();
	#else
	g_sql_tuple = SQL_MakeStdTuple();
	PrepareTable();
	#endif
	
	new error[2];
	g_IP_pattern = regex_compile(REGEX_IP_PATTERN, g_regex_return, error, sizeof(error) - 1);
	g_SteamID_pattern = regex_compile(REGEX_STEAMID_PATTERN, g_regex_return, error, sizeof(error) - 1);
	
	g_max_clients = get_maxplayers();
	
	g_msgid_SayText = get_user_msgid("SayText");
}

#if defined USING_SQL
PrepareTable()
{
	new query[128];
	formatex(query, sizeof(query) - 1,\
		"CREATE TABLE IF NOT EXISTS `%s` (`%s` varchar(32) NOT NULL, `%s` varchar(35) NOT NULL, `%s` int(10) NOT NULL, `%s` varchar(32) NOT NULL, `%s` varchar(128) NOT NULL, `%s` varchar(64) NOT NULL, `%s` varchar(35) NOT NULL);",\
		TABLE_NAME, KEY_NAME, KEY_STEAMID, KEY_FKLENGTH, KEY_UNFKTIME, KEY_REASON, KEY_ADMIN_NAME, KEY_ADMIN_STEAMID
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryCreateTable", query);
}

public QueryCreateTable(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		LoadFKs();
	}
}
#endif

public plugin_cfg()
{
	CreateUnFKEntity();
}

public CreateUnFKEntity()
{
	static failtimes;
	
	g_unfkl_entity = create_entity("info_target");
	
	if( !is_valid_ent(g_unfkl_entity) )
	{
		++failtimes;
		
		log_amx("[ERROR] Failed to create unfk entity (%i/10)", failtimes);
		
		if( failtimes < 10 )
		{
			set_task(1.0, "CreateUnFKEntity");
		}
		else
		{
			log_amx("[ERROR] Could not create unfk entity!");
		}
		
		return;
	}
	
	entity_set_string(g_unfkl_entity, EV_SZ_classname, "unFK_entity");
	entity_set_float(g_unfkl_entity, EV_FL_nextthink, get_gametime() + 1.0);
	
	register_think("unFK_entity", "FwdThink");
}

public PlayerSpawned(client)
{
	static authid[35];
	get_user_authid(client, authid, sizeof(authid) - 1);
	
	static ip[35];
	get_user_ip(client, ip, sizeof(ip) - 1, 1);
	
	#if MAX_FKS > 0
	static fkned_authid[35], bool:is_ip;
	for( new i = 0; i < g_total_fks; i++ )
	{
		copy(fkned_authid, sizeof(fkned_authid) - 1, g_steamids[i]);
		
		is_ip = bool:(containi(fkned_authid, ".") != -1);
		
		if( is_ip && equal(ip, fkned_authid) || !is_ip && equal(authid, fkned_authid) )
		{
			static name[32], reason[128], unfktime[32], admin_name[32], admin_steamid[64];
			copy(name, sizeof(name) - 1, g_names[i]);
			copy(reason, sizeof(reason) - 1, g_reasons[i]);
			new fklength = g_fklengths[i];
			copy(unfktime, sizeof(unfktime) - 1, g_unfkltimes[i]);
			copy(admin_name, sizeof(admin_name) - 1, g_admin_names[i]);
			copy(admin_steamid, sizeof(admin_steamid) - 1, g_admin_steamids[i]);
			
			PrintBanInformation(client, name, fkned_authid, reason, fklength, unfktime, admin_name, admin_steamid, true, true);
			
			set_task(get_pcvar_float(ab_fkdelay), "TaskReturnPlayerToPrisoners", client);
			break;
		}
	}
	#else
	static array_pos;
	
	if( TrieGetCell(g_trie, authid, array_pos) || TrieGetCell(g_trie, ip, array_pos) )
	{
		static data[FKLData];
		ArrayGetArray(g_array, array_pos, data);
		
		PrintBanInformation(client, data[fk_name], data[fk_steamid], data[fk_reason], data[fk_fklength], data[fk_unfktime], data[fk_admin_name], data[fk_admin_steamid], true, true);
		
		set_task(get_pcvar_float(ab_fkdelay), "TaskReturnPlayerToPrisoners", client);
	}
	#endif
}

public CmdFK(client, level, cid)
{
	if( !hasCmdAccess(client, level, cid, 4) ) return PLUGIN_HANDLED;
	
	static arg[128];
	read_argv(1, arg, sizeof(arg) - 1);
	
	new target = cmd_target(client, arg, GetTargetFlags(client));
	if( !target ) return PLUGIN_HANDLED;
	
	if (!canAffect(client, target)) {
		new szRank[35], szTargetName[35];
		GetRankLevelStr(target, szRank, charsmax(szRank));
		get_user_name(target, szTargetName, 34);
		console_print(client, "you can't affect '%s' he is %s", szTargetName, szRank);
		return PLUGIN_HANDLED;
	}

	static target_authid[35];
	get_user_authid(target, target_authid, sizeof(target_authid) - 1);
	
	if( !IsValidAuthid(target_authid) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_NOT_AUTHORIZED");
		return PLUGIN_HANDLED;
	}
	
	#if MAX_FKS <= 0
	if( TrieKeyExists(g_trie, target_authid) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_ALREADY_BANNED_STEAMID");
		return PLUGIN_HANDLED;
	}
	#else
	for( new i = 0; i < g_total_fks; i++ )
	{
		if( !strcmp(target_authid, g_steamids[i], 1) )
		{
			console_print(client, "[AdvancedBans FK] %L", client, "ABF_ALREADY_BANNED_STEAMID");
			return PLUGIN_HANDLED;
		}
	}
	#endif
	
	read_argv(2, arg, sizeof(arg) - 1);
	
	new length = str_to_num(arg);
	new maxlength = GetMaxBanTime(client);
	
	if( maxlength && (!length || length > maxlength) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
	
	static unfk_time[64];
	if( length == 0 )
	{
		formatex(unfk_time, sizeof(unfk_time) - 1, "%L", client, "ABF_PERMANENT_BAN");
	}
	else
	{
		GenerateUnfkTime(length, unfk_time, sizeof(unfk_time) - 1);
	}
	
	read_argv(3, arg, sizeof(arg) - 1);
	
	static admin_name[64], target_name[32];
	get_user_name(client, admin_name, sizeof(admin_name) - 1);
	get_user_name(target, target_name, sizeof(target_name) - 1);
	
	static admin_authid[35];
	get_user_authid(client, admin_authid, sizeof(admin_authid) - 1);
	
	AddBan(target_name, target_authid, arg, length, unfk_time, admin_name, admin_authid);
	
	PrintBanInformation(target, target_name, target_authid, arg, length, unfk_time, admin_name, admin_authid, true, true);
	PrintBanInformation(client, target_name, target_authid, arg, length, unfk_time, admin_name, admin_authid, false, false);
	
	set_task(get_pcvar_float(ab_fkdelay), "TaskReturnPlayerToPrisoners", target);
	
	GetBanTime(length, unfk_time, sizeof(unfk_time) - 1);
	
	PrintActivity(admin_name, "^x04[AdvancedBans FK] $name^x01 :^x03  added %s. to fk list Reason: %s. Ban Length: %s", target_name, arg, unfk_time);
	
	Log("%s <%s> added %s <%s> to fk list || Reason: ^"%s^" || Ban Length: %s", admin_name, admin_authid, target_name, target_authid, arg, unfk_time);
	
	return PLUGIN_HANDLED;
}

public CmdFKIp(client, level, cid)
{
	if( !hasCmdAccess(client, level, cid, 4) ) return PLUGIN_HANDLED;
	
	static arg[128];
	read_argv(1, arg, sizeof(arg) - 1);
	
	new target = cmd_target(client, arg, GetTargetFlags(client));
	if( !target ) return PLUGIN_HANDLED;

	if (!canAffect(client, target)) {
		new szRank[35], szTargetName[35];
		GetRankLevelStr(target, szRank, charsmax(szRank));
		get_user_name(target, szTargetName, 34);
		console_print(client, "you can't affect '%s' he is %s", szTargetName, szRank);
		return PLUGIN_HANDLED;
	}

	static target_ip[35];
	get_user_ip(target, target_ip, sizeof(target_ip) - 1, 1);
	
	#if MAX_FKS <= 0
	if( TrieKeyExists(g_trie, target_ip) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_ALREADY_BANNED_IP");
		return PLUGIN_HANDLED;
	}
	#else
	for( new i = 0; i < g_total_fks; i++ )
	{
		if( !strcmp(target_ip, g_steamids[i], 1) )
		{
			console_print(client, "[AdvancedBans FK] %L", client, "ABF_ALREADY_BANNED_IP");
			return PLUGIN_HANDLED;
		}
	}
	#endif
	
	read_argv(2, arg, sizeof(arg) - 1);
	
	new length = str_to_num(arg);
	new maxlength = GetMaxBanTime(client);
	
	if( maxlength && (!length || length > maxlength) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
	
	static unfk_time[32];
	
	if( length == 0 )
	{
		formatex(unfk_time, sizeof(unfk_time) - 1, "%L", client, "ABF_PERMANENT_BAN");
	}
	else
	{
		GenerateUnfkTime(length, unfk_time, sizeof(unfk_time) - 1);
	}
	
	read_argv(3, arg, sizeof(arg) - 1);
	
	static admin_name[64], target_name[32];
	get_user_name(client, admin_name, sizeof(admin_name) - 1);
	get_user_name(target, target_name, sizeof(target_name) - 1);
	
	static admin_authid[35];
	get_user_authid(client, admin_authid, sizeof(admin_authid) - 1);
	
	AddBan(target_name, target_ip, arg, length, unfk_time, admin_name, admin_authid);
	
	PrintBanInformation(target, target_name, target_ip, arg, length, unfk_time, admin_name, admin_authid, true, true);
	PrintBanInformation(client, target_name, target_ip, arg, length, unfk_time, admin_name, admin_authid, false, false);
	
	set_task(get_pcvar_float(ab_fkdelay), "TaskReturnPlayerToPrisoners", target);
	
	GetBanTime(length, unfk_time, sizeof(unfk_time) - 1);
	
	PrintActivity(admin_name, "^x04[AdvancedBans FK] $name^x01 :^x03  fkned %s. Reason: %s. Ban Length: %s", target_name, arg, unfk_time);
	
	Log("%s <%s> fkned %s <%s> || Reason: ^"%s^" || Ban Length: %s", admin_name, admin_authid, target_name, target_ip, arg, unfk_time);
	
	return PLUGIN_HANDLED;
}

public CmdAddFK(client, level, cid)
{
	if( !hasCmdAccess(client, level, cid, 5) ) return PLUGIN_HANDLED;
	
	static target_name[32], target_authid[35], fktime[10], reason[128];
	read_argv(1, target_name, sizeof(target_name) - 1);
	read_argv(2, target_authid, sizeof(target_authid) - 1);
	read_argv(3, fktime, sizeof(fktime) - 1);
	read_argv(4, reason, sizeof(reason) - 1);
	
	new bool:is_ip = bool:(containi(target_authid, ".") != -1);
	
	if( !is_ip && !IsValidAuthid(target_authid) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_INVALID_STEAMID");
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_VALID_STEAMID_FORMAT");
		
		return PLUGIN_HANDLED;
	}
	else if( is_ip )
	{
		new pos = contain(target_authid, ":");
		if( pos > 0 )
		{
			target_authid[pos] = 0;
		}
		
		if( !IsValidIP(target_authid) )
		{
			console_print(client, "[AdvancedBans FK] %L", client, "ABF_INVALID_IP");
			
			return PLUGIN_HANDLED;
		}
	}
	
	#if MAX_FKS <= 0
	if( TrieKeyExists(g_trie, target_authid) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, is_ip ? "ABF_ALREADY_BANNED_IP" : "ABF_ALREADY_BANNED_STEAMID");
		return PLUGIN_HANDLED;
	}
	#else
	for( new i = 0; i < g_total_fks; i++ )
	{
		if( !strcmp(target_authid, g_steamids[i], 1) )
		{
			console_print(client, "[AdvancedBans FK] %L", client, is_ip ? "ABF_ALREADY_BANNED_IP" : "ABF_ALREADY_BANNED_STEAMID");
			return PLUGIN_HANDLED;
		}
	}
	#endif
	
	new length = str_to_num(fktime);
	new maxlength = GetMaxBanTime(client);
	
	if( maxlength && (!length || length > maxlength) )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
	
	if( is_user_connected(find_player(is_ip ? "d" : "c", target_authid)) )
	{
		client_cmd(client, "amx_fk ^"%s^" %i ^"%s^"", target_authid, length, reason);
		return PLUGIN_HANDLED;
	}
	
	static unfk_time[32];
	if( length == 0 )
	{
		formatex(unfk_time, sizeof(unfk_time) - 1, "%L", client, "ABF_PERMANENT_BAN");
	}
	else
	{
		GenerateUnfkTime(length, unfk_time, sizeof(unfk_time) - 1);
	}
	
	static admin_name[64], admin_authid[35];
	get_user_name(client, admin_name, sizeof(admin_name) - 1);
	get_user_authid(client, admin_authid, sizeof(admin_authid) - 1);
	
	AddBan(target_name, target_authid, reason, length, unfk_time, admin_name, admin_authid);
	
	PrintBanInformation(client, target_name, target_authid, reason, length, unfk_time, "", "", false, false);
	
	GetBanTime(length, unfk_time, sizeof(unfk_time) - 1);
	
	PrintActivity(admin_name, "^x04[AdvancedBans FK] $name^x01 :^x03  fkned %s %s. Reason: %s. Ban Length: %s", is_ip ? "IP" : "SteamID", target_authid, reason, unfk_time);
	
	Log("%s <%s> fkned %s <%s> || Reason: ^"%s^" || Ban Length: %s", admin_name, admin_authid, target_name, target_authid, reason, unfk_time);
	
	return PLUGIN_HANDLED;
}

public CmdRemoveFK(client, level, cid)
{
	if( !hasCmdAccess(client, level, cid, 2) ) return PLUGIN_HANDLED;
	
	static arg[35];
	read_argv(1, arg, sizeof(arg) - 1);
	
	#if MAX_FKS > 0
	static fkned_authid[35];
	for( new i = 0; i < g_total_fks; i++ )
	{
		copy(fkned_authid, sizeof(fkned_authid) - 1, g_steamids[i]);
		
		if( equal(arg, fkned_authid) )
		{
			static admin_name[64];
			get_user_name(client, admin_name, sizeof(admin_name) - 1);
			
			static name[32], reason[128];
			copy(name, sizeof(name) - 1, g_names[i]);
			copy(reason, sizeof(reason) - 1, g_reasons[i]);
			
			PrintActivity(admin_name, "^x04[AdvancedBans FK] $name^x01 :^x03  unfkned %s^x01 [%s] [Ban Reason: %s]", name, arg, reason);
			
			static authid[35];
			get_user_authid(client, authid, sizeof(authid) - 1);
			
			Log("%s <%s> unfkned %s <%s> || Ban Reason: ^"%s^"", admin_name, authid, name, arg, reason);
			
			RemoveBan(i);
			
			return PLUGIN_HANDLED;
		}
	}
	#else
	if( TrieKeyExists(g_trie, arg) )
	{
		static array_pos;
		TrieGetCell(g_trie, arg, array_pos);
		
		static data[FKLData];
		ArrayGetArray(g_array, array_pos, data);
		
		static unfk_name[32];
		get_user_name(client, unfk_name, sizeof(unfk_name) - 1);
		
		PrintActivity(unfk_name, "^x04[AdvancedBans FK] $name^x01 :^x03  unfkned %s^x01 [%s] [Ban Reason: %s]", data[fk_name], data[fk_steamid], data[fk_reason]);
		
		static admin_name[64];
		get_user_name(client, admin_name, sizeof(admin_name) - 1);
		
		static authid[35];
		get_user_authid(client, authid, sizeof(authid) - 1);
		
		Log("%s <%s> unfkned %s <%s> || Ban Reason: ^"%s^"", admin_name, authid, data[fk_name], data[fk_steamid], data[fk_reason]);
		
		RemoveBan(array_pos, data[fk_steamid]);
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	console_print(client, "[AdvancedBans FK] %L", client, "ABF_NOT_IN_BAN_LIST", arg);
	
	return PLUGIN_HANDLED;
}

public CmdFKList(client, level, cid)
{
	if( !hasCmdAccess(client, level, cid, 1) ) return PLUGIN_HANDLED;
	
	if( !g_total_fks )
	{
		console_print(client, "[AdvancedBans FK] %L", client, "ABF_NO_BANS");
		return PLUGIN_HANDLED;
	}
	
	static start;
	
	if( read_argc() > 1 )
	{
		static arg[5];
		read_argv(1, arg, sizeof(arg) - 1);
		
		start = min(str_to_num(arg), g_total_fks) - 1;
	}
	else
	{
		start = 0;
	}
	
	new last = min(start + 10, g_total_fks);
	
	if( client == 0 )
	{
		server_cmd("echo ^"%L^"", client, "ABF_BAN_LIST_NUM", start + 1, last);
	}
	else
	{
		client_cmd(client, "echo ^"%L^"", client, "ABF_BAN_LIST_NUM", start + 1, last);
	}
	
	for( new i = start; i < last; i++ )
	{
		#if MAX_FKS <= 0
		static data[FKLData];
		ArrayGetArray(g_array, i, data);
		
		PrintBanInformation(client, data[fk_name], data[fk_steamid], data[fk_reason], data[fk_fklength], data[fk_unfktime], data[fk_admin_name], data[fk_admin_steamid], true, false);
		#else
		static name[32], steamid[35], reason[128], fklength, unfktime[32], admin_name[32], admin_steamid[35];
		
		copy(name, sizeof(name) - 1, g_names[i]);
		copy(steamid, sizeof(steamid) - 1, g_steamids[i]);
		copy(reason, sizeof(reason) - 1, g_reasons[i]);
		fklength = g_fklengths[i];
		copy(unfktime, sizeof(unfktime) - 1, g_unfkltimes[i]);
		copy(admin_name, sizeof(admin_name) - 1, g_admin_names[i]);
		copy(admin_steamid, sizeof(admin_steamid) - 1, g_admin_steamids[i]);
		
		PrintBanInformation(client, name, steamid, reason, fklength, unfktime, admin_name, admin_steamid, true, false);
		#endif
	}
	
	if( ++last < g_total_fks )
	{
		if( client == 0 )
		{
			server_cmd("echo ^"%L^"", client, "ABF_BAN_LIST_NEXT", last);
		}
		else
		{
			client_cmd(client, "echo ^"%L^"", client, "ABF_BAN_LIST_NEXT", last);
		}
	}
	
	return PLUGIN_HANDLED;
}

public CmdAddFKLimit()
{
	if( read_argc() != 3 )
	{
		log_amx("amx_addfklimit was used with incorrect parameters!");
		log_amx("Usage: amx_addfklimit <flags> <time in minutes>");
		return PLUGIN_HANDLED;
	}
	
	static arg[16];
	
	read_argv(1, arg, sizeof(arg) - 1);
	new flags = read_flags(arg);
	
	read_argv(2, arg, sizeof(arg) - 1);
	new minutes = str_to_num(arg);
	
	#if !defined MAX_FKLIMITS
	ArrayPushCell(g_maxfkl_flags, flags);
	ArrayPushCell(g_maxfkl_times, minutes);
	#else
	if( g_total_maxfkl_times >= MAX_FKLIMITS )
	{
		static notified;
		if( !notified )
		{
			log_amx("The amx_addfklimit has reached its maximum!");
			notified = 1;
		}
		return PLUGIN_HANDLED;
	}
	
	g_maxfkl_flags[g_total_maxfkl_times] = flags;
	g_maxfkl_times[g_total_maxfkl_times] = minutes;
	#endif
	g_total_maxfkl_times++;
	
	return PLUGIN_HANDLED;
}

public FwdThink(entity)
{
	if( entity != g_unfkl_entity ) return;
	
	#if defined USING_SQL
	if( g_total_fks > 0 && !g_loading_fks )
	#else
	if( g_total_fks > 0 )
	#endif
	{
		static _hours[5], _minutes[5], _seconds[5], _month[5], _day[5], _year[7];
		format_time(_hours, sizeof(_hours) - 1, "%H");
		format_time(_minutes, sizeof(_minutes) - 1, "%M");
		format_time(_seconds, sizeof(_seconds) - 1, "%S");
		format_time(_month, sizeof(_month) - 1, "%m");
		format_time(_day, sizeof(_day) - 1, "%d");
		format_time(_year, sizeof(_year) - 1, "%Y");
		
		// c = current
		// u = unfk
		
		new c_hours = str_to_num(_hours);
		new c_minutes = str_to_num(_minutes);
		new c_seconds = str_to_num(_seconds);
		new c_month = str_to_num(_month);
		new c_day = str_to_num(_day);
		new c_year = str_to_num(_year);
		
		static unfk_time[32];
		static u_hours, u_minutes, u_seconds, u_month, u_day, u_year;
		
		for( new i = 0; i < g_total_fks; i++ )
		{
			#if MAX_FKS <= 0
			static data[FKLData];
			ArrayGetArray(g_array, i, data);
			
			if( data[fk_fklength] == 0 ) continue;
			#else
			if( g_fklengths[i] == 0 ) continue;
			#endif
			
			#if MAX_FKS <= 0
			copy(unfk_time, sizeof(unfk_time) - 1, data[fk_unfktime]);
			#else
			copy(unfk_time, sizeof(unfk_time) - 1, g_unfkltimes[i]);
			#endif
			replace_all(unfk_time, sizeof(unfk_time) - 1, ":", " ");
			replace_all(unfk_time, sizeof(unfk_time) - 1, "/", " ");
			
			parse(unfk_time,\
				_hours, sizeof(_hours) - 1,\
				_minutes, sizeof(_minutes) - 1,\
				_seconds, sizeof(_seconds) - 1,\
				_month, sizeof(_month) - 1,\
				_day, sizeof(_day) - 1,\
				_year, sizeof(_year) - 1
				);
			
			u_hours = str_to_num(_hours);
			u_minutes = str_to_num(_minutes);
			u_seconds = str_to_num(_seconds);
			u_month = str_to_num(_month);
			u_day = str_to_num(_day);
			u_year = str_to_num(_year);
			
			if( u_year < c_year
			|| u_year == c_year && u_month < c_month
			|| u_year == c_year && u_month == c_month && u_day < c_day
			|| u_year == c_year && u_month == c_month && u_day == c_day && u_hours < c_hours
			|| u_year == c_year && u_month == c_month && u_day == c_day && u_hours == c_hours && u_minutes < c_minutes
			|| u_year == c_year && u_month == c_month && u_day == c_day && u_hours == c_hours && u_minutes == c_minutes && u_seconds <= c_seconds )
			{
				#if MAX_FKS <= 0
				Log("Ban time is up for: %s [%s]", data[fk_name], data[fk_steamid]);
				
				Print("^x04[AdvancedBans FK]^x03 %s^x01[^x04%s^x01]^x03 fk time is up!^x01 [Ban Reason: %s]", data[fk_name], data[fk_steamid], data[fk_reason]);
				
				RemoveBan(i, data[fk_steamid]);
				#else
				Log("Ban time is up for: %s [%s]", g_names[i], g_steamids[i]);
				
				Print("^x04[AdvancedBans FK]^x03 %s^x01[^x04%s^x01]^x03 fk time is up!^x01 [Ban Reason: %s]", g_names[i], g_steamids[i], g_reasons[i]);
				
				RemoveBan(i);
				#endif
				
				i--; // current pos was replaced with another fk, so we need to check it again.
			}
		}
	}
	
	entity_set_float(g_unfkl_entity, EV_FL_nextthink, get_gametime() + get_pcvar_float(ab_unfklcheck));
}

public TaskReturnPlayerToPrisoners(client)
{
	if (GetTeam(client) != GUARD)
		return;
	rg_set_user_team(client, TEAM_TERRORIST, MODEL_AUTO, true, false);
	if (is_user_alive(client)) user_kill(client);
	console_print(client, "You are fkned from joining Guard Team");
}

AddBan(const target_name[], const target_steamid[], const reason[], const length, const unfk_time[], const admin_name[], const admin_steamid[])
{
	#if MAX_FKS > 0
	if( g_total_fks == MAX_FKS )
	{
		log_amx("Ban list is full! (%i)", g_total_fks);
		return;
	}
	#endif
	
	#if defined USING_SQL
	static target_name2[32], reason2[128], admin_name2[32];
	MakeStringSQLSafe(target_name, target_name2, sizeof(target_name2) - 1);
	MakeStringSQLSafe(reason, reason2, sizeof(reason2) - 1);
	MakeStringSQLSafe(admin_name, admin_name2, sizeof(admin_name2) - 1);
	
	static query[512];
	formatex(query, sizeof(query) - 1,\
		"INSERT INTO `%s` (`%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`) VALUES ('%s', '%s', '%i', '%s', '%s', '%s', '%s');",\
		TABLE_NAME, KEY_NAME, KEY_STEAMID, KEY_FKLENGTH, KEY_UNFKTIME, KEY_REASON, KEY_ADMIN_NAME, KEY_ADMIN_STEAMID,\
		target_name2, target_steamid, length, unfk_time, reason2, admin_name2, admin_steamid
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryAddBan", query);
	#else
	new f = fopen(g_fk_file, "a+");
	
	fprintf(f, "^"%s^" ^"%s^" %i ^"%s^" ^"%s^" ^"%s^" ^"%s^"^n",\
		target_steamid,\
		target_name,\
		length,\
		unfk_time,\
		reason,\
		admin_name,\
		admin_steamid
		);
	
	fclose(f);
	#endif
	
	#if MAX_FKS <= 0
	static data[FKLData];
	copy(data[fk_name], sizeof(data[fk_name]) - 1, target_name);
	copy(data[fk_steamid], sizeof(data[fk_steamid]) - 1, target_steamid);
	data[fk_fklength] = length;
	copy(data[fk_unfktime], sizeof(data[fk_unfktime]) - 1, unfk_time);
	copy(data[fk_reason], sizeof(data[fk_reason]) - 1, reason);
	copy(data[fk_admin_name], sizeof(data[fk_admin_name]) - 1, admin_name);
	copy(data[fk_admin_steamid], sizeof(data[fk_admin_steamid]) - 1, admin_steamid);
	
	TrieSetCell(g_trie, target_steamid, g_total_fks);
	ArrayPushArray(g_array, data);
	#else
	copy(g_names[g_total_fks], sizeof(g_names[]) - 1, target_name);
	copy(g_steamids[g_total_fks], sizeof(g_steamids[]) - 1, target_steamid);
	g_fklengths[g_total_fks] = length;
	copy(g_unfkltimes[g_total_fks], sizeof(g_unfkltimes[]) - 1, unfk_time);
	copy(g_reasons[g_total_fks], sizeof(g_reasons[]) - 1, reason);
	copy(g_admin_names[g_total_fks], sizeof(g_admin_names[]) - 1, admin_name);
	copy(g_admin_steamids[g_total_fks], sizeof(g_admin_steamids[]) - 1, admin_steamid);
	#endif
	
	g_total_fks++;
	
	#if MAX_FKS > 0
	if( g_total_fks == MAX_FKS )
	{
		log_amx("Ban list is full! (%i)", g_total_fks);
	}
	#endif
}

#if defined USING_SQL
public QueryAddBan(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		// Yay, fk was added! We can all rejoice!
	}
}

public QueryDeleteBan(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		// Yay, fk was deleted! We can all rejoice!
	}
}

public QueryLoadFKs(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		if( SQL_NumResults(query) )
		{
			#if MAX_FKS <= 0
			static data[FKLData];
			while( SQL_MoreResults(query) )
			#else
			while( SQL_MoreResults(query) && g_total_fks < MAX_FKS )
			#endif
			{
				#if MAX_FKS <= 0
				SQL_ReadResult(query, 0, data[fk_name], sizeof(data[fk_name]) - 1);
				SQL_ReadResult(query, 1, data[fk_steamid], sizeof(data[fk_steamid]) - 1);
				data[fk_fklength] = SQL_ReadResult(query, 2);
				SQL_ReadResult(query, 3, data[fk_unfktime], sizeof(data[fk_unfktime]) - 1);
				SQL_ReadResult(query, 4, data[fk_reason], sizeof(data[fk_reason]) - 1);
				SQL_ReadResult(query, 5, data[fk_admin_name], sizeof(data[fk_admin_name]) - 1);
				SQL_ReadResult(query, 6, data[fk_admin_steamid], sizeof(data[fk_admin_steamid]) - 1);
				
				ArrayPushArray(g_array, data);
				TrieSetCell(g_trie, data[fk_steamid], g_total_fks);
				#else
				SQL_ReadResult(query, 0, g_names[g_total_fks], sizeof(g_names[]) - 1);
				SQL_ReadResult(query, 1, g_steamids[g_total_fks], sizeof(g_steamids[]) - 1);
				g_fklengths[g_total_fks] = SQL_ReadResult(query, 2);
				SQL_ReadResult(query, 3, g_unfkltimes[g_total_fks], sizeof(g_unfkltimes[]) - 1);
				SQL_ReadResult(query, 4, g_reasons[g_total_fks], sizeof(g_reasons[]) - 1);
				SQL_ReadResult(query, 5, g_admin_names[g_total_fks], sizeof(g_admin_names[]) - 1);
				SQL_ReadResult(query, 6, g_admin_steamids[g_total_fks], sizeof(g_admin_steamids[]) - 1);
				#endif
				
				g_total_fks++;
				
				SQL_NextRow(query);
			}
		}
		
		set_task(RELOAD_BANS_INTERVAL, "LoadFKs");
		
		g_loading_fks = false;
	}
}
#endif

#if MAX_FKS > 0
RemoveBan(remove)
{
	#if defined USING_SQL
	static query[128];
	formatex(query, sizeof(query) - 1,\
		"DELETE FROM `%s` WHERE `%s` = '%s';",\
		TABLE_NAME, KEY_STEAMID, g_steamids[remove]
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryDeleteBan", query);
	#endif
	
	for( new i = remove; i < g_total_fks; i++ )
	{
		if( (i + 1) == g_total_fks )
		{
			copy(g_names[i], sizeof(g_names[]) - 1, "");
			copy(g_steamids[i], sizeof(g_steamids[]) - 1, "");
			g_fklengths[i] = 0;
			copy(g_unfkltimes[i], sizeof(g_unfkltimes[]) - 1, "");
			copy(g_reasons[i], sizeof(g_reasons[]) - 1, "");
			copy(g_admin_names[i], sizeof(g_admin_names[]) - 1, "");
			copy(g_admin_steamids[i], sizeof(g_admin_steamids[]) - 1, "");
		}
		else
		{
			copy(g_names[i], sizeof(g_names[]) - 1, g_names[i + 1]);
			copy(g_steamids[i], sizeof(g_steamids[]) - 1, g_steamids[i + 1]);
			g_fklengths[i] = g_fklengths[i + 1];
			copy(g_unfkltimes[i], sizeof(g_unfkltimes[]) - 1, g_unfkltimes[i + 1]);
			copy(g_reasons[i], sizeof(g_reasons[]) - 1, g_reasons[i + 1]);
			copy(g_admin_names[i], sizeof(g_admin_names[]) - 1, g_admin_names[i + 1]);
			copy(g_admin_steamids[i], sizeof(g_admin_steamids[]) - 1, g_admin_steamids[i + 1]);
		}
	}
	
	g_total_fks--;
	
	#if !defined USING_SQL
	new f = fopen(g_fk_file, "wt");
	
	static name[32], steamid[35], fklength, unfktime[32], reason[128], admin_name[32], admin_steamid[35];
	for( new i = 0; i < g_total_fks; i++ )
	{
		copy(name, sizeof(name) - 1, g_names[i]);
		copy(steamid, sizeof(steamid) - 1, g_steamids[i]);
		fklength = g_fklengths[i];
		copy(unfktime, sizeof(unfktime) - 1, g_unfkltimes[i]);
		copy(reason, sizeof(reason) - 1, g_reasons[i]);
		copy(admin_name, sizeof(admin_name) - 1, g_admin_names[i]);
		copy(admin_steamid, sizeof(admin_steamid) - 1, g_admin_steamids[i]);
		
		fprintf(f, "^"%s^" ^"%s^" %i ^"%s^" ^"%s^" ^"%s^" ^"%s^"^n",\
			steamid,\
			name,\
			fklength,\
			unfktime,\
			reason,\
			admin_name,\
			admin_steamid
			);
	}
	
	fclose(f);
	#endif
}
#else
RemoveBan(pos, const authid[])
{
	TrieDeleteKey(g_trie, authid);
	ArrayDeleteItem(g_array, pos);
	
	g_total_fks--;
	
	#if defined USING_SQL
	static query[128];
	formatex(query, sizeof(query) - 1,\
		"DELETE FROM `%s` WHERE `%s` = '%s';",\
		TABLE_NAME, KEY_STEAMID, authid
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryDeleteBan", query);
	
	new data[FKLData];
	for( new i = 0; i < g_total_fks; i++ )
	{
		ArrayGetArray(g_array, i, data);
		TrieSetCell(g_trie, data[fk_steamid], i);
	}
	#else
	new f = fopen(g_fk_file, "wt");
	
	new data[FKLData];
	for( new i = 0; i < g_total_fks; i++ )
	{
		ArrayGetArray(g_array, i, data);
		TrieSetCell(g_trie, data[fk_steamid], i);
		
		fprintf(f, "^"%s^" ^"%s^" %i ^"%s^" ^"%s^" ^"%s^" ^"%s^"^n",\
			data[fk_steamid],\
			data[fk_name],\
			data[fk_fklength],\
			data[fk_unfktime],\
			data[fk_reason],\
			data[fk_admin_name],\
			data[fk_admin_steamid]
			);
	}
	
	fclose(f);
	#endif
}
#endif

#if defined KEEP_DEFAULT_BANS
LoadOldBans(filename[])
{
	if( file_exists(filename) )
	{
		new f = fopen(filename, "rt");
		
		static data[96];
		static command[10], minutes[10], steamid[35], length, unfk_time[32];
		
		while( !feof(f) )
		{
			fgets(f, data, sizeof(data) - 1);
			if( !data[0] ) continue;
			
			parse(data, command, sizeof(command) - 1, minutes, sizeof(minutes) - 1, steamid, sizeof(steamid) - 1);
			if( filename[0] == 'b' && !equali(command, "fkid") || filename[0] == 'l' && !equali(command, "addip") ) continue;
			
			length = str_to_num(minutes);
			GenerateUnfkTime(length, unfk_time, sizeof(unfk_time) - 1);
			
			AddBan("", steamid, "", length, unfk_time, "", "");
		}
		
		fclose(f);
		
		static filename2[32];
		
		// copy current
		copy(filename2, sizeof(filename2) - 1, filename);
		
		// cut off at the "."
		// fkned.cfg = fkned
		// listip.cfg = listip
		filename2[containi(filename2, ".")] = 0;
		
		// add 2.cfg
		// fkned = fkned2.cfg
		// listip = listip2.cfg
		add(filename2, sizeof(filename2) - 1, "2.cfg");
		
		// rename file so that it isnt loaded again
		while( !rename_file(filename, filename2, 1) ) { }
	}
}
#endif

public LoadFKs()
{
	if( g_total_fks )
	{
		#if MAX_FKS <= 0
		TrieClear(g_trie);
		ArrayClear(g_array);
		#endif
		
		g_total_fks = 0;
	}
	
	#if defined USING_SQL
	static query[128];
	formatex(query, sizeof(query) - 1,\
		"SELECT * FROM `%s`;",\
		TABLE_NAME
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryLoadFKs", query);
	
	g_loading_fks = true;
	#else
	if( file_exists(g_fk_file) )
	{
		new f = fopen(g_fk_file, "rt");
		
		static filedata[512], length[10];
		
		#if MAX_FKS <= 0
		static data[FKLData];
		while( !feof(f) )
		#else
		while( !feof(f) && g_total_fks < MAX_FKS )
		#endif
		{
			fgets(f, filedata, sizeof(filedata) - 1);
			
			if( !filedata[0] ) continue;
			
			#if MAX_FKS <= 0
			parse(filedata,\
				data[fk_steamid], sizeof(data[fk_steamid]) - 1,\
				data[fk_name], sizeof(data[fk_name]) - 1,\
				length, sizeof(length) - 1,\
				data[fk_unfktime], sizeof(data[fk_unfktime]) - 1,\
				data[fk_reason], sizeof(data[fk_reason]) - 1,\
				data[fk_admin_name], sizeof(data[fk_admin_name]) - 1,\
				data[fk_admin_steamid], sizeof(data[fk_admin_steamid]) - 1
				);
			
			data[fk_fklength] = str_to_num(length);
			
			ArrayPushArray(g_array, data);
			TrieSetCell(g_trie, data[fk_steamid], g_total_fks);
			#else
			static steamid[35], name[32], unfktime[32], reason[128], admin_name[32], admin_steamid[35];
			
			parse(filedata,\
				steamid, sizeof(steamid) - 1,\
				name, sizeof(name) - 1,\
				length, sizeof(length) - 1,\
				unfktime, sizeof(unfktime) - 1,\
				reason, sizeof(reason) - 1,\
				admin_name, sizeof(admin_name) - 1,\
				admin_steamid, sizeof(admin_steamid) - 1
				);
			
			copy(g_names[g_total_fks], sizeof(g_names[]) - 1, name);
			copy(g_steamids[g_total_fks], sizeof(g_steamids[]) - 1, steamid);
			g_fklengths[g_total_fks] = str_to_num(length);
			copy(g_unfkltimes[g_total_fks], sizeof(g_unfkltimes[]) - 1, unfktime);
			copy(g_reasons[g_total_fks], sizeof(g_reasons[]) - 1, reason);
			copy(g_admin_names[g_total_fks], sizeof(g_admin_names[]) - 1, admin_name);
			copy(g_admin_steamids[g_total_fks], sizeof(g_admin_steamids[]) - 1, admin_steamid);
			#endif
			
			g_total_fks++;
		}
		
		fclose(f);
	}
	#endif
	
	// load these after, so when they are added to the file with AddBan(), they aren't loaded again from above.
	
	#if defined KEEP_DEFAULT_BANS
	LoadOldBans("fkned.cfg");
	LoadOldBans("listip.cfg");
	#endif
}

#if defined USING_SQL
MakeStringSQLSafe(const input[], output[], len)
{
	copy(output, len, input);
	replace_all(output, len, "'", "*");
	replace_all(output, len, "^"", "*");
	replace_all(output, len, "`", "*");
}
#endif

GetBanTime(const fktime, length[], len)
{
	new minutes = fktime;
	new hours = 0;
	new days = 0;
	
	while( minutes >= 60 )
	{
		minutes -= 60;
		hours++;
	}
	
	while( hours >= 24 )
	{
		hours -= 24;
		days++;
	}
	
	new bool:add_before;
	if( minutes )
	{
		formatex(length, len, "%i minute%s", minutes, minutes == 1 ? "" : "s");
		
		add_before = true;
	}
	if( hours )
	{
		if( add_before )
		{
			format(length, len, "%i hour%s, %s", hours, hours == 1 ? "" : "s", length);
		}
		else
		{
			formatex(length, len, "%i hour%s", hours, hours == 1 ? "" : "s");
			
			add_before = true;
		}
	}
	if( days )
	{
		if( add_before )
		{
			format(length, len, "%i day%s, %s", days, days == 1 ? "" : "s", length);
		}
		else
		{
			formatex(length, len, "%i day%s", days, days == 1 ? "" : "s");
			
			add_before = true;
		}
	}
	if( !add_before )
	{
		// minutes, hours, and days = 0
		// assume permanent fk
		copy(length, len, "Permanent Ban");
	}
}

GenerateUnfkTime(const fktime, unfk_time[], len)
{
	static _hours[5], _minutes[5], _seconds[5], _month[5], _day[5], _year[7];
	format_time(_hours, sizeof(_hours) - 1, "%H");
	format_time(_minutes, sizeof(_minutes) - 1, "%M");
	format_time(_seconds, sizeof(_seconds) - 1, "%S");
	format_time(_month, sizeof(_month) - 1, "%m");
	format_time(_day, sizeof(_day) - 1, "%d");
	format_time(_year, sizeof(_year) - 1, "%Y");
	
	new hours = str_to_num(_hours);
	new minutes = str_to_num(_minutes);
	new seconds = str_to_num(_seconds);
	new month = str_to_num(_month);
	new day = str_to_num(_day);
	new year = str_to_num(_year);
	
	minutes += fktime;
	
	while( minutes >= 60 )
	{
		minutes -= 60;
		hours++;
	}
	
	while( hours >= 24 )
	{
		hours -= 24;
		day++;
	}
	
	new max_days = GetDaysInMonth(month, year);
	while( day > max_days )
	{
		day -= max_days;
		month++;
	}
	
	while( month > 12 )
	{
		month -= 12;
		year++;
	}
	
	formatex(unfk_time, len, "%i:%02i:%02i %i/%i/%i", hours, minutes, seconds, month, day, year);
}

GetDaysInMonth(month, year=0)
{
	switch( month )
	{
		case 1:		return 31; // january
		case 2:		return ((year % 4) == 0) ? 29 : 28; // february
		case 3:		return 31; // march
		case 4:		return 30; // april
		case 5:		return 31; // may
		case 6:		return 30; // june
		case 7:		return 31; // july
		case 8:		return 31; // august
		case 9:		return 30; // september
		case 10:	return 31; // october
		case 11:	return 30; // november
		case 12:	return 31; // december
	}
	
	return 30;
}

GetTargetFlags(client)
{
	static const flags_no_immunity = (CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS);
	return flags_no_immunity;
}

GetMaxBanTime(client)
{
	if( !g_total_maxfkl_times ) return 0;
	
	new flags = get_user_flags(client);
	
	for( new i = 0; i < g_total_maxfkl_times; i++ )
	{
		#if !defined MAX_FKLIMITS
		if( flags & ArrayGetCell(g_maxfkl_flags, i) )
		{
			return ArrayGetCell(g_maxfkl_times, i);
		}
		#else
		if( flags & g_maxfkl_flags[i] )
		{
			return g_maxfkl_times[i];
		}
		#endif
	}
	
	return 0;
}

PrintBanInformation(client, const target_name[], const target_authid[], const reason[], const length, const unfk_time[], const admin_name[], const admin_authid[], bool:show_admin, bool:show_website)
{
	static website[64], fk_length[64];
	if( client == 0 )
	{
		server_print("************************************************");
		server_print("%L", client, "ABF_BAN_INFORMATION");
		server_print("%L: %s", client, "ABF_NAME", target_name);
		server_print("%L: %s", client, IsValidAuthid(target_authid) ? "ABF_STEAMID" : "ABF_IP", target_authid);
		server_print("%L: %s", client, "ABF_REASON", reason);
		if( length > 0 )
		{
			GetBanTime(length, fk_length, sizeof(fk_length) - 1);
			server_print("%L: %s", client, "ABF_BAN_LENGTH", fk_length);
		}
		server_print("%L: %s", client, "ABF_UNBAN_TIME", unfk_time);
		if( show_admin )
		{
			server_print("%L: %s", client, "ABF_ADMIN_NAME", admin_name);
			server_print("%L: %s", client, "ABF_ADMIN_STEAMID", admin_authid);
		}
		if( show_website )
		{
			get_pcvar_string(ab_website, website, sizeof(website) - 1);
			if( website[0] )
			{
				server_print("");
				server_print("%L", client, "ABF_WEBSITE");
				server_print("%s", website);
			}
		}
		server_print("************************************************");
	}
	else
	{
		client_cmd(client, "echo ^"************************************************^"");
		client_cmd(client, "echo ^"%L^"", client, "ABF_BAN_INFORMATION");
		client_cmd(client, "echo ^"%L: %s^"", client, "ABF_NAME", target_name);
		client_cmd(client, "echo ^"%L: %s^"", client, IsValidAuthid(target_authid) ? "ABF_STEAMID" : "ABF_IP", target_authid);
		client_cmd(client, "echo ^"%L: %s^"", client, "ABF_REASON", reason);
		if( length > 0 )
		{
			GetBanTime(length, fk_length, sizeof(fk_length) - 1);
			client_cmd(client, "echo ^"%L: %s^"", client, "ABF_BAN_LENGTH", fk_length);
		}
		client_cmd(client, "echo ^"%L: %s^"", client, "ABF_UNBAN_TIME", unfk_time);
		if( show_admin )
		{
			client_cmd(client, "echo ^"%L: %s^"", client, "ABF_ADMIN_NAME", admin_name);
			client_cmd(client, "echo ^"%L: %s^"", client, "ABF_ADMIN_STEAMID", admin_authid);
		}
		if( show_website )
		{
			get_pcvar_string(ab_website, website, sizeof(website) - 1);
			if( website[0] )
			{
				client_cmd(client, "echo ^"^"");
				client_cmd(client, "echo ^"%L^"", client, "ABF_WEBSITE");
				client_cmd(client, "echo ^"%s^"", website);
			}
		}
		client_cmd(client, "echo ^"************************************************^"");
	}
}

PrintActivity(const admin_name[], const message_fmt[], any:...)
{
	if( !get_playersnum() ) return;
	
	new activity = get_pcvar_num(amx_show_activity);
	if( !(0 <= activity <= 5) )
	{
		set_pcvar_num(amx_show_activity, (activity = 2));
	}
	
	static message[192], temp[192];
	vformat(message, sizeof(message) - 1, message_fmt, 3);
	
	for( new client = 1; client <= g_max_clients; client++ )
	{
		if( !is_user_connected(client) ) continue;
		
		switch( is_user_admin(client) ? g_admin_activity[activity] : g_normal_activity[activity] )
		{
			case ACTIVITY_NONE:
			{
				
			}
			case ACTIVITY_HIDE:
			{
				copy(temp, sizeof(temp) - 1, message);
				replace(temp, sizeof(temp) - 1, "$name", "ADMIN");
				
				message_begin(MSG_ONE_UNRELIABLE, g_msgid_SayText, _, client);
				write_byte(client);
				write_string(temp);
				message_end();
			}
			case ACTIVITY_SHOW:
			{
				copy(temp, sizeof(temp) - 1, message);
				replace(temp, sizeof(temp) - 1, "$name", admin_name);
				
				message_begin(MSG_ONE_UNRELIABLE, g_msgid_SayText, _, client);
				write_byte(client);
				write_string(temp);
				message_end();
			}
		}
	}
}

Print(const message_fmt[], any:...)
{
	if( !get_playersnum() ) return;
	
	static message[192];
	vformat(message, sizeof(message) - 1, message_fmt, 2);
	
	for( new client = 1; client <= g_max_clients; client++ )
	{
		if( !is_user_connected(client) ) continue;
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgid_SayText, _, client);
		write_byte(client);
		write_string(message);
		message_end();
	}
}

Log(const message_fmt[], any:...)
{
	static message[256];
	vformat(message, sizeof(message) - 1, message_fmt, 2);
	
	static filename[96];
	#if defined HISTORY_ONE_FILE
	if( !filename[0] )
	{
		get_basedir(filename, sizeof(filename) - 1);
		add(filename, sizeof(filename) - 1, "/logs/fk_history.log");
	}
	#else
	static dir[64];
	if( !dir[0] )
	{
		get_basedir(dir, sizeof(dir) - 1);
		add(dir, sizeof(dir) - 1, "/logs");
	}
	
	format_time(filename, sizeof(filename) - 1, "%m%d%Y");
	format(filename, sizeof(filename) - 1, "%s/FK_HISTORY_%s.log", dir, filename);
	#endif
	
	log_amx("%s", message);
	log_to_file(filename, "%s", message);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
