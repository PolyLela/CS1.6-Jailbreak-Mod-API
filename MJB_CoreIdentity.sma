#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "Core Identity"
#define IUSER1_BUYZONE_KEY 302142
#define MsgId_TextMsg 77 
#define MsgId_SendAudio 100 
#define MsgId_StatusText 106 
#define MsgId_ClCorpse 122 
#define MsgId_HudTextArgs 145

new Trie:g_tRemoveEntities, Trie:g_tRadioSounds;
new g_fmSpawnPostHandle;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	set_cvar_num("mp_freezetime", 0);

	register_message(get_user_msgid("MOTD"), "BlockMotd");
	RegisterHookChain(RG_ShowVGUIMenu, "BlockMenu", false);
	RegisterHookChain(RG_ShowMenu, "BlockMenu", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_PlayerSpawn_Post", true);

	register_event("DeathMsg", "DeathMsg", "a")

	RegisterHam(Ham_TraceAttack, "func_button", "Ham_ButtonTrace_Post", 1);

	register_message(MsgId_TextMsg, "Message_TextMsg");
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

public RG_PlayerSpawn_Post(id) {
	rg_remove_all_items(id);
	rg_give_item(id, "weapon_knife");
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


public BlockMotd() {
   return PLUGIN_HANDLED;
}

public BlockMenu() {
   return HC_SUPERCEDE;
}

public client_putinserver(id)
{
    set_task(0.1, "ForceJoin", id);
}

public ForceJoin(id)
{
    if (!is_user_connected(id))
        return;
	
    //kill player if there is last prisoner to not rune the game
    
    rg_join_team(id, TEAM_TERRORIST);
    if (mjb_find_last_prisoner() != -1) {
	client_print(0, print_chat, "Found last prisoner, player got executed");
	set_task(0.1, "KillPlayer", id);
    }
}

public KillPlayer(id) {
	user_kill(id, 1);
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
