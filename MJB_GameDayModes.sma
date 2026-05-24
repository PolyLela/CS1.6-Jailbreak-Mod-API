#include <amxmodx>
#include <MJB_Core>

#define PLUGIN "Gameday Modes"

public plugin_init() {
	mjb_register_daymode("Sparta Day", "sparta_day");
	mjb_register_daymode("President Day", "president_day");
}