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

#define PLUGIN "Core Identity"
#define IUSER1_BUYZONE_KEY 302142
#define MsgId_ShowMenu 96
#define MsgId_VGUIMenu 114
#define MsgId_TextMsg 77 
#define MsgId_SendAudio 100 
#define MsgId_StatusText 106 
#define MsgId_VGUIMenu 114 
#define MsgId_ClCorpse 122 
#define MsgId_HudTextArgs 145

#define VGUIMenu_TeamMenu 2
#define VGUIMenu_ClassMenuTe 26
#define VGUIMenu_ClassMenuCt 27
#define ShowMenu_TeamMenu 19
#define ShowMenu_TeamSpectMenu 51
#define ShowMenu_IgTeamMenu 531
#define ShowMenu_IgTeamSpectMenu 563
#define ShowMenu_ClassMenu 31

new Trie:g_tRemoveEntities, Trie:g_tRadioSounds;
new g_fmSpawnPostHandle;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	set_cvar_num("mp_freezetime", 0);
	set_cvar_num("mp_autoteambalance", 0);
	set_cvar_num("mp_limitteams", 0);
	register_event("DeathMsg", "DeathMsg", "a")
	RegisterHam(Ham_TraceAttack, "func_button", "Ham_ButtonTrace_Post", 1);
	register_message(get_user_msgid("MOTD"), "Message_MOTD");
	register_message(MsgId_TextMsg, "Message_TextMsg");
	register_message(MsgId_ShowMenu, "Message_ShowMenu");
	register_message(MsgId_VGUIMenu, "Message_VGUIMenu");
	register_message(MsgId_ClCorpse, "Message_ClCorpse");
	register_message(MsgId_HudTextArgs, "Message_HudTextArgs");
	register_message(MsgId_SendAudio, "Message_SendAudio");
	register_message(MsgId_StatusText, "Message_StatusText");
	
	new szRadioSounds[][] = {
		"%!MRAD_LOCKNLOAD",
		"%!MRAD_MOVEOUT",
		"%!MRAD_LETSGO",
		"%!MRAD_GO",
		"%!MRAD_ELIM",
		"%!MRAD_GETOUT",
		"%!MRAD_VIP",
		"%!MRAD_FIREINHOLE"
	}
	
	g_tRadioSounds = TrieCreate()
	for(new i; i < sizeof(szRadioSounds); i++)
		TrieSetCell(g_tRadioSounds, szRadioSounds[i], 1)
	
	for(new i, szBlockCmd[][] = {"jointeam", "joinclass"}; i < sizeof szBlockCmd; i++)
		register_clcmd(szBlockCmd[i], "ClCmd_Block");
		
	TrieDestroy(g_tRemoveEntities);
	unregister_forward(FM_Spawn, g_fmSpawnPostHandle, 1);
}

public DeathMsg() {
	new headshot = read_data(3);
	if (headshot) {
		emit_sound(0, CHAN_AUTO, "MOON_JB/headshot.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

public Ham_ButtonTrace_Post(ent, attacker, Float:damage, Float:dir[3], trace, damagebits) {
	if (!mjb_is_valid_player(attacker))
		return;
	ExecuteHamB(Ham_Use, ent, attacker, attacker, USE_TOGGLE, 1.0);
}

public mjb_life_state_changed(id, iLifeState) {
	if (iLifeState == MJB_True) {
		if (mjb_get_team(id) == GUARD) {
			set_pev(id, pev_health, 200.0);
			set_pev(id, pev_health, 100.0);
		}
	}
}

public ClCmd_Block() return PLUGIN_HANDLED;

public Message_TextMsg()
{
    new szArg[64];
    get_msg_arg_string(2, szArg, charsmax(szArg));

    // normalize (remove leading '#')
    new i = 0;
    if (szArg[0] == '#')
        i = 1;

    if (containi(szArg[i], "Game_teammate_attack") != -1 ||
        containi(szArg[i], "Game_teammate_kills") != -1 ||
        containi(szArg[i], "Game_join_terrorist") != -1 ||
        containi(szArg[i], "Game_join_ct") != -1 ||
        containi(szArg[i], "Game_scoring") != -1 ||
        containi(szArg[i], "Game_will_restart_in") != -1 ||
        containi(szArg[i], "Game_Commencing") != -1 ||
        containi(szArg[i], "Killed_Teammate") != -1)
    {
        return PLUGIN_HANDLED;
    }

    if (get_msg_args() == 5)
    {
        get_msg_arg_string(5, szArg, charsmax(szArg));

        if (containi(szArg, "Fire_in_the_hole") != -1)
            return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

public Message_ClCorpse() return PLUGIN_HANDLED;
public Message_HudTextArgs() return PLUGIN_HANDLED;

public Message_SendAudio()
{
	new szArg[32];
	get_msg_arg_string(2, szArg, charsmax(szArg));
	
	if(TrieKeyExists(g_tRadioSounds, szArg)) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Message_StatusText() return PLUGIN_HANDLED;


public Message_MOTD(iMsgId, iMsgDest, iReceiver) {
	return PLUGIN_HANDLED;
}

public Message_ShowMenu(iMsgId, iMsgDest, iReceiver)
{
	if(get_msg_arg_int(1) == ShowMenu_ClassMenu || get_msg_arg_int(1) == ShowMenu_IgTeamMenu || 
	get_msg_arg_int(1) == ShowMenu_IgTeamSpectMenu || get_msg_arg_int(1) == ShowMenu_TeamMenu || get_msg_arg_int(1) == ShowMenu_TeamSpectMenu)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public Message_VGUIMenu(iMsgId, iMsgDest, iReceiver)
{
	if(get_msg_arg_int(1) == VGUIMenu_ClassMenuTe || get_msg_arg_int(1) == VGUIMenu_ClassMenuCt || get_msg_arg_int(1) == VGUIMenu_TeamMenu)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public client_putinserver(id) {
	set_task(0.3, "AutoJoin", id);
}

public AutoJoin(id) {
	new pl[32], pnum, gNum, pNum;
	get_players(pl, pnum, "h");
	
	for (new i = 0; i < pnum; i++) {
		if (!mjb_is_valid_player(pl[i]) || !mjb_is_player_alive(pl[i]))
			continue;
		switch (mjb_get_team(pl[i])) {
			case PRISONER : pNum++;
			case GUARD : gNum++;
		}
	}
	if (pNum >= 2 && gNum == 0) {
		mjb_set_team(id, GUARD, MJB_False);
		set_task(0.1, "ChangeTeamR", id + 30);
		return;
	}
	
	if (pNum >= 1 && gNum >= 1) {
		mjb_set_team(id, GUARD, MJB_False);
		set_task(0.1, "ChangeTeamK", id + 30);
		return;
	}
	mjb_set_team(id, PRISONER, MJB_False);
	set_pdata_int(id, m_bHasChangeTeamThisRound, false, linux_diff_player);
	set_task(0.3, "CheckIfTeamChanged", id + 20);
}

public ChangeTeamR(taskid) {
	new id = taskid - 30;
	mjb_set_team(id, PRISONER, 2);
}

public ChangeTeamK(taskid) {
	new id = taskid - 30;
	mjb_set_team(id, PRISONER, 1);
}

public CheckIfTeamChanged(taskid) { 
	new id = taskid - 20;
	if (mjb_get_team(id) != PRISONER) {
		mjb_set_team(id, NONE, MJB_True);
		set_pdata_int(id, m_bHasChangeTeamThisRound, false, linux_diff_player);
	}
}

public plugin_precache() {
	precache_sound("MOON_JB/headshot.wav");
	mjb_create_buyzone();
	g_tRemoveEntities = TrieCreate();
	new const szRemoveEntities[][] = {"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target", "func_vip_safetyzone",
	"info_vip_start", "func_escapezone", "hostage_entity", "monster_scientist", "func_buyzone", "func_pushable"};
	for (new i = 0; i < sizeof(szRemoveEntities); i++) TrieSetCell(g_tRemoveEntities, szRemoveEntities[i], i);
	g_fmSpawnPostHandle = register_forward(FM_Spawn, "FakeMeta_SpawnPost", 1);
}

public FakeMeta_SpawnPost(iEntity) {
	if (!pev_valid(iEntity))
		return FMRES_IGNORED;
	
	new szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if (TrieKeyExists(g_tRemoveEntities, szClassName)) {
		if (contain(szClassName, "buyzone") != -1 && pev(iEntity, pev_iuser1) == IUSER1_BUYZONE_KEY) return FMRES_IGNORED;
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
	return FMRES_IGNORED;
}

mjb_create_buyzone()
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	set_pev(iEntity, pev_iuser1, IUSER1_BUYZONE_KEY);
	iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "game_player_equip"));
	fm_set_kvd(iEntity, "game_player_equip", "weapon_knife", "1");
}
