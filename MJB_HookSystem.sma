#include <amxmodx>
#include <fakemeta>
#include <MJB_Core>

#define PLUGIN "Hook System"

#define HOOK_TASK 2425
#define SHOOK_TASK 2430
#define TRAIL_LIFE 10
#define TRAIL_WIDTH 10
#define TRAIL_BRIGTHNESS 220
#define TRAIL_P_RED 0
#define TRAIL_P_GREEN 255
#define TRAIL_P_BLUE 0
#define TRAIL_G_RED 0
#define TRAIL_G_GREEN 0
#define TRAIL_G_BLUE 255

new bool:g_bIsHooking[MAX_PLAYERS + 1];
new bool:g_bIsSHooking[MAX_PLAYERS + 1];
new g_iHookOrigin[MAX_PLAYERS + 1][3];
new g_iHookSpr, g_iSuperHookSpr, g_iHookTrailSpr, g_iSHookEffectSpr, g_iEffectSpr[6];
new g_szEffects[6][] = 
{
	"sprites/3dmflared.spr",
	"sprites/3dmflaora.spr" ,
	"sprites/frostgib.spr" ,
	"sprites/ledglow.spr" ,
	"sprites/pink.spr" ,
	"sprites/star_gib.spr"
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("+hook", "HookOn");
	register_clcmd("+shook", "SHookOn");
	register_clcmd("-hook", "HookOff");
	register_clcmd("-shook", "SHookOff");
}

public plugin_precache() {
	for (new i; i < sizeof(g_szEffects); i++) {
		g_iEffectSpr[i] = precache_model(g_szEffects[i]);
	}
	g_iHookSpr = precache_model("sprites/MOON_JB/Hook/lightning.spr");
	g_iSuperHookSpr = precache_model("sprites/MOON_JB/Hook/super_hook.spr");
	g_iSHookEffectSpr = precache_model("sprites/MOON_JB/Hook/shook_effect.spr");
	g_iHookTrailSpr = precache_model("sprites/vselennaya.spr")
	precache_sound("MOON_JB/Hook/lightning_hook.wav");
	precache_sound("MOON_JB/Hook/hook_rope.wav");
}

public client_putinserver(id) {
	RemoveBeam(id);
	g_bIsHooking[id] = false;
	g_bIsSHooking[id] = false;
}

public client_disconnected(id) {
	RemoveBeam(id);
	g_bIsHooking[id] = false;
	g_bIsSHooking[id] = false;
}

public CanHook(id) {
	return (mjb_is_valid_player(id) && is_user_alive(id) && hasRank(id, RANK_HOOK) && mjb_get_phase() != PHASE_GAMEDAY_VOTE);
}

public CanSHook(id) {
	return (mjb_is_valid_player(id) && is_user_alive(id) && hasRank(id, RANK_HOOK) && hasRank(id, RANK_GOLD_ADMIN) && mjb_get_phase() != PHASE_GAMEDAY_VOTE);
}

public HookOn(id) {
	if (!CanHook(id))
		return PLUGIN_CONTINUE;
	
	g_bIsHooking[id] = true;
	get_user_origin(id, g_iHookOrigin[id], 3);
	CreateHookEffects(id, g_iHookOrigin[id]);
	fm_set_user_rendering(id, kRenderFxGlowShell,  random_float( 0.0,255.0 ),  random_float( 0.0,255.0 ),  random_float( 0.0,255.0 ), kRenderNormal, 16.0 )
	emit_sound(id, CHAN_STATIC, "MOON_JB/Hook/lightning_hook.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_task(0.1, "HookThink", id + HOOK_TASK, _, _, "ab");
	HookThink(id + HOOK_TASK);
	return PLUGIN_HANDLED;
}

public SHookOn(id) {
	if (!CanSHook(id))
		return PLUGIN_CONTINUE;
	
	g_bIsSHooking[id] = true;
	get_user_origin(id, g_iHookOrigin[id], 3);
	CreateSHookEffects(id, g_iHookOrigin[id]);
	new Float:fValue = random_float( 200.0,255.0 );
	fm_set_user_rendering(id, kRenderFxGlowShell, fValue,  fValue,  fValue, kRenderNormal, 16.0 )
	emit_sound(id, CHAN_STATIC, "MOON_JB/Hook/hook_rope.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_task(0.1, "SHookThink", id + SHOOK_TASK, _, _, "ab");
	SHookThink(id + SHOOK_TASK);
	return PLUGIN_HANDLED;
}

public HookThink(taskid) {
	new id = taskid - HOOK_TASK;
	if (g_bIsSHooking[id]) {
		if (task_exists(id + SHOOK_TASK)) remove_task(id + SHOOK_TASK);
	}
	
	if (!g_bIsHooking[id] || !CanHook(id)) {
		if (task_exists(id + HOOK_TASK)) remove_task(id + HOOK_TASK);
		return;
	}
	
	new iOrigin[3];
	RemoveBeam(id);
	get_user_origin(id, iOrigin);
	CreateHookBeam(id);
	CreateHookTrail(id);
	new iMagnitude = get_distance(g_iHookOrigin[id], iOrigin);
	new Float:g_fVecVelocity[3];
	if (iMagnitude > 25) {
		// we are getting the direction vector scaled by the speed
		g_fVecVelocity[0] = float((g_iHookOrigin[id][0] - iOrigin[0]) * 800  / iMagnitude);
		g_fVecVelocity[1] = float((g_iHookOrigin[id][1] - iOrigin[1]) * 800 / iMagnitude);
		g_fVecVelocity[2] = float((g_iHookOrigin[id][2] - iOrigin[2]) * 800 / iMagnitude);
	}
	set_pev(id, pev_velocity, g_fVecVelocity);
}

public SHookThink(taskid) {
	new id = taskid - SHOOK_TASK;
	if (g_bIsHooking[id]) {
		if (task_exists(id + HOOK_TASK)) remove_task(id + HOOK_TASK);
	}
	
	if (!g_bIsSHooking[id] || !CanSHook(id)) {
		if (task_exists(id + SHOOK_TASK)) remove_task(id + SHOOK_TASK);
		return;
	}
	
	new iOrigin[3];
	RemoveBeam(id);
	get_user_origin(id, iOrigin);
	CreateSHookBeam(id);
	CreateHookTrail(id);
	new iMagnitude = get_distance(g_iHookOrigin[id], iOrigin);
	new Float:g_fVecVelocity[3];
	if (iMagnitude > 25) {
		// we are getting the direction vector scaled by the speed
		g_fVecVelocity[0] = float((g_iHookOrigin[id][0] - iOrigin[0]) * 1200  / iMagnitude);
		g_fVecVelocity[1] = float((g_iHookOrigin[id][1] - iOrigin[1]) * 1200 / iMagnitude);
		g_fVecVelocity[2] = float((g_iHookOrigin[id][2] - iOrigin[2]) * 1200 / iMagnitude);
	}
	set_pev(id, pev_velocity, g_fVecVelocity);
}

public HookOff(id) {
	RemoveBeam(id);
	fm_set_user_rendering(id, kRenderFxGlowShell, 0.0, 0.0, 0.0, kRenderNormal, 16.0 )
	g_bIsHooking[id] = false;
	if (task_exists(id + HOOK_TASK)) remove_task(id + HOOK_TASK);
	return PLUGIN_HANDLED;
}

public SHookOff(id) {
	RemoveBeam(id);
	fm_set_user_rendering(id, kRenderFxGlowShell, 0.0, 0.0, 0.0, kRenderNormal, 16.0 )
	g_bIsSHooking[id] = false;
	if (task_exists(id + SHOOK_TASK)) remove_task(id + SHOOK_TASK);
	return PLUGIN_HANDLED;
}

public CreateHookEffects(id, iOrigin[3]) {
	for (new i = 0; i < sizeof(g_iEffectSpr); i++) {
		message_begin(MSG_ALL,SVC_TEMPENTITY,{0,0,0},id)
		write_byte(TE_SPRITETRAIL) 
		write_coord(iOrigin[0])		// startposition.x
		write_coord(iOrigin[1])		// startposition.y
		write_coord(iOrigin[2]+20)	// startposition.z
		write_coord(iOrigin[0])		// endposition.x
		write_coord(iOrigin[1])		// endposition.y
		write_coord(iOrigin[2]+80)	// endposition.z
		write_short(g_iEffectSpr[i]);	// sprite index
		write_byte(1)			// count
		write_byte(20)			// life in 0.1's
		write_byte(4)			// scale in 0.1's
		write_byte(20)			// velocity along vector in 10's
		write_byte(10)			// randomness of velocity in 10's
		message_end()                
	}
}

public CreateSHookEffects(id, iOrigin[3]) {
	message_begin(MSG_ALL,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(TE_SPRITETRAIL) 
	write_coord(iOrigin[0])		// startposition.x
	write_coord(iOrigin[1])		// startposition.y
	write_coord(iOrigin[2]+20)	// startposition.z
	write_coord(iOrigin[0])		// endposition.x
	write_coord(iOrigin[1])		// endposition.y
	write_coord(iOrigin[2]+80)	// endposition.z
	write_short(g_iSHookEffectSpr);	// sprite index
	write_byte(random_num(6, 9))	// count
	write_byte(20)			// life in 0.1's
	write_byte(4)			// scale in 0.1's
	write_byte(20)			// velocity along vector in 10's
	write_byte(10)			// randomness of velocity in 10's
	message_end()                
}

public CreateHookTrail(id) {
	message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (TE_BEAMFOLLOW)
	write_short (id)
	write_short(g_iHookTrailSpr)
	write_byte (TRAIL_LIFE)
	write_byte (TRAIL_WIDTH)
	new iRed, iBlue, iGreen;
	getTrailRGB(id, iRed, iBlue, iGreen);
	write_byte(iRed);
	write_byte(iBlue);
	write_byte(iGreen);
	write_byte (TRAIL_BRIGTHNESS)
	message_end()
}


public CreateHookBeam(id) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(id); //write_short(start entity)
	write_coord(g_iHookOrigin[id][0]); //write_coord(endposition.x)
	write_coord(g_iHookOrigin[id][1]); //write_coord(endposition.y)
	write_coord(g_iHookOrigin[id][2]); //write_coord(endposition.z)
	write_short(g_iHookSpr);  //write_short(sprite index)      
	write_byte(0);             //write_byte(starting frame)
	write_byte(1);             //write_byte(frame rate in 0.1's)
	write_byte(1);             //write_byte(life in 0.1's)
	write_byte(42);             //write_byte(line width in 0.1's)
	write_byte(30);          //write_byte(noise amplitude in 0.0
	new iRed, iBlue, iGreen;
	randomRGB(iRed, iBlue, iGreen);
	write_byte(iRed);            // write_byte(red)
	write_byte(iBlue);             //write_byte(green)
	write_byte(iGreen);          //write_byte(blue)
	write_byte(255);         //write_byte(brightness)
	write_byte(0);             //write_byte(scroll speed in 0.1's)
	message_end();           
}

public CreateSHookBeam(id) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(id); //write_short(start entity)
	write_coord(g_iHookOrigin[id][0]); //write_coord(endposition.x)
	write_coord(g_iHookOrigin[id][1]); //write_coord(endposition.y)
	write_coord(g_iHookOrigin[id][2]); //write_coord(endposition.z)
	write_short(g_iSuperHookSpr);  //write_short(sprite index)      
	write_byte(0);             //write_byte(starting frame)
	write_byte(1);             //write_byte(frame rate in 0.1's)
	write_byte(1);             //write_byte(life in 0.1's)
	write_byte(30);             //write_byte(line width in 0.1's)
	write_byte(0);          //write_byte(noise amplitude in 0.0)
	write_byte(255);            // write_byte(red)
	write_byte(255);             //write_byte(green)
	write_byte(255);          //write_byte(blue)
	write_byte(1000);         //write_byte(brightness)
	write_byte(0);             //write_byte(scroll speed in 0.1's)
	message_end();           
}

public RemoveBeam(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(id)
	message_end()
}

stock getTrailRGB(id, &iRed, &iGreen, &iBlue) {
	if (g_bIsSHooking[id]) {
		iRed = 255;
		iGreen = 255;
		iBlue = 255;
		return
	}
	switch(GetTeam(id)) {
		case PRISONER : {
			iRed = TRAIL_P_RED;
			iGreen = TRAIL_P_GREEN;
			iBlue = TRAIL_P_BLUE;
		}
		case GUARD : {
			iRed = TRAIL_G_RED;
			iGreen = TRAIL_G_GREEN;
			iBlue = TRAIL_G_BLUE;
		}
	}
}

stock randomRGB(&iRed, &iGreen, &iBlue)
{
	switch(random(10))
	{
		case 0:
		{
			iRed = 255;
			iGreen = 255;
			iBlue = 0;
		}
		
		case 1:
		{
			iRed = 0;
			iGreen = 255;
			iBlue = 255;
		}
		
		case 2:
		{
			iRed = 0;
			iGreen = 255;
			iBlue = 255;
		}
		
		case 3:
		{
			iRed = 255;
			iGreen = 255;
			iBlue = 0;
		}
		
		case 4:
		{
			iRed = 0;
			iGreen = 255;
			iBlue = 0;
		}
		
		case 5:
		{
			iRed = 0;
			iGreen = 0;
			iBlue = 255;
		}
		
		case 6:
		{
			iRed = 255;
			iGreen = 0;
			iBlue = 0;
		}
		
		case 7:
		{
			iRed = 255;
			iGreen = 192;
			iBlue = 203;
		}
		
		case 8:
		{
			iRed = 255;
			iGreen = 192;
			iBlue = 203;
		}
		
		case 9:
		{
			iRed = 0;
			iGreen = 128;
			iBlue = 128;
		}
	}
}
