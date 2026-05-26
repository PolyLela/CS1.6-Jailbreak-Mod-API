#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <reapi>
#include <MJB_Core>

#define PLUGIN "Melee System"

new const g_Melee[MeleeType][MeleeData] =
{
	// PRISONER (HAND)
	{
		"models/MOON_JB/Weapons/v_hand.mdl",
		"models/MOON_JB/Weapons/p_hand.mdl",
		
		"MOON_JB/Weapons/hand_deploy.wav",
		"MOON_JB/Weapons/hand_slash.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		
		0.4,
		1.0
	},
	
	// GUARD (BATON)
	{
		"models/MOON_JB/Weapons/v_baton.mdl",
		"models/MOON_JB/Weapons/p_baton.mdl",
		
		"MOON_JB/Weapons/baton_deploy.wav",
		"MOON_JB/Weapons/baton_slash.wav",
		"MOON_JB/Weapons/baton_stab.wav",
		"MOON_JB/Weapons/baton_hitwall.wav",
		"MOON_JB/Weapons/baton_hit.wav",
		
		0.4,
		1.0
	},
	
	//SuperVIP (AXE)
	{
		"models/MOON_JB/SuperVIPMenu/v_axe.mdl",
		"models/MOON_JB/SuperVIPMenu/p_axe.mdl",
		
		"MOON_JB/SuperVIPMenu/axe/deploy.wav",
		"MOON_JB/SuperVIPMenu/axe/slash.wav",
		"MOON_JB/SuperVIPMenu/axe/stab.wav",
		"MOON_JB/SuperVIPMenu/axe/hitwall.wav",
		"MOON_JB/SuperVIPMenu/axe/hit.wav",
		
		0.5,
		2.2
	},
	
	//SuperVIP (COMBAT)
	{
		"models/MOON_JB/SuperVIPMenu/v_combat.mdl",
		"models/MOON_JB/SuperVIPMenu/p_combat.mdl",
		
		"MOON_JB/SuperVIPMenu/combat/deploy.wav",
		"MOON_JB/SuperVIPMenu/combat/slash.wav",
		"MOON_JB/SuperVIPMenu/combat/stab.wav",
		"MOON_JB/SuperVIPMenu/combat/hitwall.wav",
		"MOON_JB/SuperVIPMenu/combat/hit.wav",
		
		0.4,
		1.3
	},
	
	//SuperVIP (HAMMER)
	{
		"models/MOON_JB/SuperVIPMenu/v_hammer.mdl",
		"models/MOON_JB/SuperVIPMenu/p_hammer.mdl",
		
		"MOON_JB/SuperVIPMenu/hammer/deploy.wav",
		"MOON_JB/SuperVIPMenu/hammer/slash.wav",
		"MOON_JB/SuperVIPMenu/hammer/stab.wav",
		"MOON_JB/SuperVIPMenu/hammer/hit.wav",
		"MOON_JB/SuperVIPMenu/hammer/hit.wav",
		
		0.4,
		3.0
	},
	
	//SuperVIP (KATANA)
	{
		"models/MOON_JB/SuperVIPMenu/v_katana.mdl",
		"models/MOON_JB/SuperVIPMenu/p_katana.mdl",
		
		"MOON_JB/SuperVIPMenu/katana/deploy.wav",
		"MOON_JB/SuperVIPMenu/katana/slash.wav",
		"MOON_JB/SuperVIPMenu/katana/stab.wav",
		"MOON_JB/SuperVIPMenu/katana/hitwall.wav",
		"MOON_JB/SuperVIPMenu/katana/hit.wav",
		
		0.4,
		1.4
	},
	
	//SuperVIP (STAP)
	{
		"models/MOON_JB/SuperVIPMenu/v_stap.mdl",
		"models/MOON_JB/SuperVIPMenu/p_stap.mdl",
		
		"MOON_JB/SuperVIPMenu/stap/deploy.wav",
		"MOON_JB/SuperVIPMenu/stap/miss.wav",
		"MOON_JB/SuperVIPMenu/stap/hit.wav",
		"MOON_JB/SuperVIPMenu/stap/hitwall.wav",
		"MOON_JB/SuperVIPMenu/stap/hit.wav",
		
		0.4,
		0.8
	},
	
	//Boxing Gloves (Red)
	{
		"models/MOON_JB/Boxing/v_boxing_red.mdl",
		"models/MOON_JB/Boxing/p_boxing_red.mdl",
		
		"", //no deploy sound
		"MOON_JB/Weapons/hand_slash.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		
		0.6,
		1.4
	},
	
	//Boxing Gloves (Blue)
	{
		"models/MOON_JB/Boxing/v_boxing_blue.mdl",
		"models/MOON_JB/Boxing/p_boxing_blue.mdl",
		
		"", //no deploy sound
		"MOON_JB/Weapons/hand_slash.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		"MOON_JB/Weapons/hand_hit.wav",
		
		0.6,
		1.4
	}
};

new g_iPlayerMelee[MAX_PLAYERS + 1];
new bool:g_bFreezed[MAX_PLAYERS + 1];
new exploSpr;
/* =========================
   PLUGIN LIFECYCLE
========================= */
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("CurWeapon", "CurWeapon", "be", "1=1");
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "OnPlayerTraceAttack_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage_Pre", false);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_KnifeDeploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Ham_Melee_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Ham_Melee_SecondaryAttack_Post", 1);
	register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
}

public plugin_precache()
{
	for (new i = 0; i < sizeof(g_Melee); i++)
	{
		precache_model(g_Melee[i][MELEE_V_MODEL]);
		precache_model(g_Melee[i][MELEE_P_MODEL]);
		
		if (!equal(g_Melee[i][MELEE_SND_DEPLOY], "")) precache_sound(g_Melee[i][MELEE_SND_DEPLOY]);
		precache_sound(g_Melee[i][MELEE_SND_SLASH]);
		precache_sound(g_Melee[i][MELEE_SND_STAB]);
		precache_sound(g_Melee[i][MELEE_SND_HITWALL]);
		precache_sound(g_Melee[i][MELEE_SND_HIT]);
	}
	precache_sound("MOON_JB/SuperVIPMenu/combat/frostnova.wav");
	exploSpr = precache_model("sprites/shockwave.spr");
}

/* =========================
   API
========================= */
public plugin_natives() {
	register_library("MJB_Core");
	
	register_native("mjb_set_user_melee", "native_set_user_melee");
	register_native("mjb_get_user_melee", "native_get_user_melee");
}

public native_set_user_melee() {
	new id = get_param(1);
	new iType = get_param(2);
	if (!mjb_is_valid_player(id))
		return;
	iType--;
	if (iType <= 0 || iType >= sizeof(g_Melee)) {
		g_iPlayerMelee[id] = 0;
		fm_switch_to_knife(id);
		return;
	} 
	g_iPlayerMelee[id] = iType;
	fm_switch_to_knife(id);
}

public native_get_user_melee() {
	new id = get_param(1);
	if (!mjb_is_valid_player(id))
		return -1;

	return GetUserMelee(id);
}

public GetUserMelee(id) {
	return g_iPlayerMelee[id] + 1;
}

/* =========================
   Update Events
========================= */
public client_putinserver(id) {
	g_bFreezed[id] = false;
}

public CurWeapon(id) {
	if (read_data(2) != CSW_KNIFE)
		return PLUGIN_CONTINUE;
	UpdateMelee(id)
	return PLUGIN_CONTINUE;
}

public OnPlayerSpawn_Post(id) {
	g_iPlayerMelee[id] = 0;
	g_bFreezed[id] = false;
	rg_give_item(id, "weapon_knife", GT_REPLACE);
	fm_switch_to_knife(id);
}

public Ham_KnifeDeploy_Post(iEntity) 
{
	new id = get_member(iEntity, m_pPlayer);
	
	UpdateMelee(id);
}


public Ham_Melee_PrimaryAttack_Post(iEntity) 
{
	new id = get_member(iEntity, m_pPlayer);
	new m = GetPlayerMelee(id);
	
	set_member(iEntity, m_Weapon_flNextPrimaryAttack, g_Melee[m][MELEE_PRIMARY_DELAY]);
	set_member(id, m_flNextAttack, g_Melee[m][MELEE_PRIMARY_DELAY]);
}

public Ham_Melee_SecondaryAttack_Post(iEntity)
{
	new id = get_member(iEntity, m_pPlayer);
	new m = GetPlayerMelee(id);
	
	set_member(iEntity, m_Weapon_flNextSecondaryAttack, g_Melee[m][MELEE_SECONDARY_DELAY]);
	set_member(id, m_flNextAttack, g_Melee[m][MELEE_SECONDARY_DELAY]);
}

public FakeMeta_EmitSound(id, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch) 
{
	if (!mjb_is_valid_player(id))
		return FMRES_IGNORED;
	
	if (contain(szSample, "knife") == -1)
		return FMRES_IGNORED;
	
	new m = GetPlayerMelee(id);
	new sndType = GetMeleeSound(m, szSample);
	
	if (sndType == -1)
		return FMRES_IGNORED;
	
	if (!equal(g_Melee[m][sndType], ""))
		emit_sound(id, iChannel, g_Melee[m][sndType], fVolume, fAttn, iFlag, iPitch);
	return FMRES_SUPERCEDE;
}


/* =========================
   Abilities Events
========================= */
public mjb_phase_changed(iOldPhase, iNewPhase) {
	if (iNewPhase != PHASE_DAY_ENDED)
		return;
	new pl[32], plnum;
	get_players(pl, plnum, "h");
	for (new i = 0; i < plnum; i++) {
		if (!mjb_is_valid_player(pl[i]))
			continue;
		if (g_bFreezed[pl[i]]) {
			unFreeze(pl[i]);
			if (task_exists(pl[i] + 2026)) remove_task(pl[i] + 2026);
		}
		
	}
}

public OnPlayerTraceAttack_Pre(victim, attacker, Float:damage, Float:dir[3], trace, damagebits)
{
	if (!mjb_is_valid_player(victim) || !mjb_is_valid_player(attacker) || victim == attacker)
		return HC_CONTINUE;
	
		
	if  (GetTeam(victim) == GUARD &&  GetTeam(attacker) == GUARD) {
		return HC_SUPERCEDE;
	} 
	
	new bool:bothArePrisoners = (GetTeam(victim) == PRISONER && GetTeam(attacker) == PRISONER);
	new bool:bothAreBoxing = (mjb_get_state(victim) == PRISONER_BOXING && mjb_get_state(attacker) == PRISONER_BOXING);
	new bool:sameMGTeam = (mjb_get_user_mg_team(victim) == mjb_get_user_mg_team(attacker));
	
	if (bothArePrisoners && (!bothAreBoxing || sameMGTeam)) {
			return HC_SUPERCEDE;
	}
	
	if (g_bFreezed[victim]) 
	{
		return HC_SUPERCEDE;
	}
	
	if(get_user_weapon(attacker) != CSW_KNIFE)
		return HC_CONTINUE;
	
	new meleeType = GetUserMelee(attacker);
	new attButtons = get_user_button(attacker);
	

	if (meleeType == MELEE_SVIP_HAMMER) 
	{
		if (attButtons & IN_ATTACK2)
		{
			new Float:velocity[3], Float:current[3];

			pev(victim, pev_velocity, current);
			
			velocity[0] = current[0] + dir[0];
			velocity[1] = current[1] + dir[1];
			velocity[2] = current[2] + 1600.0;
			set_pev(victim, pev_velocity, velocity);
		}
		else if (attButtons & IN_ATTACK)
		{
			for (new i; i < 3; i++) user_slap(victim,0,0);
		}
	}
	else if (meleeType == MELEE_SVIP_KATANA)
	{
		if (attButtons & IN_ATTACK2) {
			Bleed(victim);
		}
	}

	return HC_CONTINUE;
}

public OnPlayerTakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!mjb_is_valid_player(victim) || !mjb_is_valid_player(attacker) || victim == attacker)
		return HC_CONTINUE;
	
	new meleeType = GetUserMelee(attacker);
	new vicMeleeType = GetUserMelee(victim);
	
	new bool:bothArePrisoners = (GetTeam(victim) == PRISONER && GetTeam(attacker) == PRISONER);
	new bool:sameMGTeam = (mjb_get_user_mg_team(victim) == mjb_get_user_mg_team(attacker));
	new bool:bothHasBoxingGloves = (((meleeType == MELEE_BOXING_BLUE || meleeType == MELEE_BOXING_RED) && get_user_weapon(attacker) == CSW_KNIFE) && ((vicMeleeType == MELEE_BOXING_BLUE || vicMeleeType == MELEE_BOXING_RED) && get_user_weapon(victim) == CSW_KNIFE));
	
	if (g_bFreezed[victim]) 
	{
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}
	
	if (bothArePrisoners && !sameMGTeam && bothHasBoxingGloves) {
		if (get_member(victim, m_LastHitGroup) == HIT_HEAD)
		{
			damage = 22.0;
			UTIL_ScreenShake(victim, (1<<15), (1<<14), (1<<15));
			UTIL_ScreenFade(victim, (1<<13), (1<<13), 0, 0, 0 ,0, 245);
			
		}
		else damage = 15.0;
		SetHookChainArg(4, ATYPE_FLOAT, damage);
		
		return HC_CONTINUE;
	}
	
	if(get_user_weapon(attacker) != CSW_KNIFE)
		return HC_CONTINUE;

	if (meleeType == MELEE_SVIP_COMBAT) 
	{
		Freeze(victim);
	}

	if ((meleeType == MELEE_SVIP_STAP || meleeType == MELEE_SVIP_AXE) && get_user_button(attacker) & IN_ATTACK2)
	{
		if (damage < 150) SetHookChainArg(4, ATYPE_FLOAT, damage = 80.0); //not stab from behind
	}
	return HC_CONTINUE;
}

/* =========================
   Backend Logic
========================= */
public GetPlayerMelee(id) {
	// 1. Player override (SVIP choice)
	if (g_iPlayerMelee[id] > 0)
		return g_iPlayerMelee[id] + 1; //Offset correctness since SVIP melees start from index 2 on MeleeType Enum
	
	// 2. Team default fallback
	switch (GetTeam(id))
	{
		case PRISONER: return MELEE_FISTS;
		case GUARD:    return MELEE_BATON;
	}
	
	// 3. Hard fallback safety
	return MELEE_FISTS;
}

public GetMeleeSound(m, const sample[])
{
	if (contain(sample, "deploy") != -1) return MELEE_SND_DEPLOY;
	if (contain(sample, "slash") != -1) return MELEE_SND_SLASH;
	if (contain(sample, "stab") != -1) return MELEE_SND_STAB;
	if (contain(sample, "hitwall") != -1) return MELEE_SND_HITWALL;
	if (contain(sample, "hit") != -1) return MELEE_SND_HIT;
	
	return -1;
}

public UpdateMelee(id)
{
	new m = GetPlayerMelee(id);
	
	set_pev(id, pev_viewmodel2, g_Melee[m][MELEE_V_MODEL]);
	set_pev(id, pev_weaponmodel2, g_Melee[m][MELEE_P_MODEL]);
}

/* =========================
   Abilities Logic
========================= */
unFreeze(id) {
	if (!mjb_is_valid_player(id))
		return;
	g_bFreezed[id] = false;
	set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
	glow(id, 0);
}

Freeze(id) {
	if (!mjb_is_valid_player(id) || !is_user_alive(id) || task_exists(id + 2026))
		return;
	g_bFreezed[id] = true;
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
	glow(id, 1);
	new iOrigin[3];
	get_user_origin(id, iOrigin);
	create_explosion(iOrigin);
	set_task(6.0, "Freeze_ended", id + 2026);
}

public Freeze_ended(taskid) {
	new id = taskid - 2026;
	unFreeze(id);
}

stock glow(target, iToggle)
{
	if (iToggle) {
		set_user_rendering( target, kRenderFxGlowShell, 0, 210, 223, kRenderNormal, 18);
	}
	else
	{
		set_user_rendering( target, kRenderFxNone, 255, 255, 255, kRenderNormal, 16);
	}
}

stock Bleed( id )
{
	new iorigin[3];
	get_user_origin(id, iorigin);
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
	write_byte( TE_LAVASPLASH ); 
	write_coord( iorigin[ 0 ] ); 
	write_coord( iorigin[ 1 ] ); 
	write_coord( iorigin[ 2 ] ); 
	message_end(); 
}

stock create_explosion(const origin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(21); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2]); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2] + 385);
	write_short(exploSpr); 
	write_byte(0); 
	write_byte(0); 
	write_byte(4); 
	write_byte(60);
	write_byte(0);
	write_byte(FROST_R); 
	write_byte(FROST_G); 
	write_byte(FROST_B); 
	write_byte(100); 
	write_byte(0); 
	message_end();

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(21); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2]); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2] + 470); 
	write_short(exploSpr); 
	write_byte(0); 
	write_byte(0); 
	write_byte(4); 
	write_byte(60); 
	write_byte(0); 
	write_byte(FROST_R); 
	write_byte(FROST_G); 
	write_byte(FROST_B); 
	write_byte(100); 
	write_byte(0); 
	message_end();

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(21); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2]); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2] + 555); 
	write_short(exploSpr); 
	write_byte(0); 
	write_byte(0); 
	write_byte(4); 
	write_byte(60); 
	write_byte(0); 
	write_byte(FROST_R); 
	write_byte(FROST_G); 
	write_byte(FROST_B); 
	write_byte(100); 
	write_byte(0); 
	message_end();

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(27); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2]); 
	write_byte(floatround(FROST_RADIUS/5.0)); 
	write_byte(FROST_R);
	write_byte(FROST_G); 
	write_byte(FROST_B); 
	write_byte(8);
	write_byte(60);
	message_end();
} 
