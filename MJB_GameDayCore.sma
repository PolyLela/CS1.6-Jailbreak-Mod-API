#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <MJB_Core>

#define PLUGIN "GameDay Mode Core"

#define VOTE_TIME 15.0
#define MAX_DAYMODES 16

enum DayModeStruct {
    dm_name[32],
    dm_start_func,
    dm_end_func
};

new g_DayModes[MAX_DAYMODES][DayModeStruct];
new g_iDayModeCount;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
}

public RegisterDayMode(const name[], const startFunc[], const endFunc[]) {
	if (g_iDayModeCount >= MAX_DAYMODES)
		return -1;
	
	copy(g_DayModes[g_iDayModeCount][dm_name], 31, name);
	g_DayModes[g_iDayModeCount][dm_start_func] = funcidx(startFunc);
	g_DayModes[g_iDayModeCount][dm_end_func] = funcidx(endFunc);
	
	g_iDayModeCount++;
	return g_iDayModeCount;
}

public ExecuteDayMode(iMode) {
	new plugin = g_DayModes[iMode][dm_plugin_id];
	new func[32], szPlugin[32];
	copy(func, 31, g_DayModes[iMode][dm_start_func]);
	
	callfunc_begin(func, szPlugin);
	callfunc_end();
}

public EndDayMode(iMode) {
	new plugin = g_DayModes[iMode][dm_plugin_id];
	new func[32], szPlugin[32];
	copy(func, 31, g_DayModes[iMode][dm_end_func]);
	num_to_str(plugin, szPlugin, charsmax(szPlugin));
	
	callfunc_begin(func, szPlugin);
	callfunc_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
