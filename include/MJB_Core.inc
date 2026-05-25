#if defined _mjb_core_library
	#endinput
#endif

#define _mjb_core_library

#include <MJB_Consts>

/* ============================================================
 *  Moon JB Core
 *  Author: 4D0CtOR4
 * ------------------------------------------------------------
 *  This library provides functions for player data (team, state)
 * ============================================================
 */

/**
 * Blocks default game behaviour in some functions.
 *
 * @noreturn
 */
native mjb_block_game_behaviour();

/**
 * Unblocks default game behaviour in some functions.
 *
 * @noreturn
 */
native mjb_unblock_game_behaviour();
 
/**
 * Checks if a user is in duel.
 *
 * @param id		Player id.
 *
 * @return		1 if so 0 if not.
 */
native mjb_is_user_in_duel(id);

/**
 * Checks if a 2 users is in duel.
 *
 * @param id1		Player One id.
 * @param id2		Player Two id.
 *
 * @return		1 if so 0 if not.
 */
native mjb_is_users_in_duel(id1, id2);

/**
 * Checks if a duel is running.
 *
 * @return		1 if so 0 if not.
 */
native mjb_is_duel_running();
 
/**
 * Sets a player melee (use MeleeType Enum).
 *
 * @param id		Player id to set (Must be valid).
 * @param iType		Melee type (use MeleeType Enum) if smaller than 0 or bigger than MeleeType size it sets to default melee
 *
 * @noreturn
 */
native mjb_set_user_melee(id, iType=0);

/**
 * Gets a user melee.
 *
 * @param id		Player id to set (Must be valid).
 *
 * @return		Melee Type if valid if no -1.
 */
native mjb_get_user_melee(id);

/**
 * Registers a gameday mode.
 *
 * @param name		Name of the mode.
 * @param uid		Unique Id String of The Mode.
 * @param time		Time of the daymode.
 *
 * @return		Daymode index.
 */
native mjb_register_daymode(const name[], const uid[], const time); 

/**
 * Wrties Data of Current Daymode.
 *
 * @return		True on success False on failure;
 */
native bool:mjb_get_current_daymode(data[DayModeData]);

/**
 * Gets DayMdoe Timer.
 *
 * @return		timer id on success if phase isnt active then -1;
 */
native mjb_get_daymode_timer();

/**
 * Blocks main menu.
 *
 * @noreturn
 */
native mjb_block_main_menu();

/**
 * Unblocks main menu.
 *
 * @noreturn
 */
native mjb_unblock_main_menu();

/**
 * Shows main menu.
 *
 * @param id        Player index.
 *
 * @noreturn
 */
native mjb_show_main_menu(id);

/**
 * Enables player speaking (if player is valid).
 *
 * @param id        Player index.
 *
 * @noreturn
 */
native mjb_enable_speaking(id);

/**
 * Disables player speaking (if player is valid).
 *
 * @param id        Player index.
 *
 * @noreturn
 */
native mjb_disable_speaking(id);

/**
 * Checks if a player can speak.
 *
 * @param id        Player index.
 *
 * @return	1 if can speak 0 if cannot (also return -1 if player isnt valid)
 */
native mjb_can_speak(id);

/**
 * UnBlocks simon menu.
 *
 * @noreturn
 */
native mjb_unblock_simon_menu();

/**
 * Blocks simon menu until new round (if id is given as parameter it shows ghost menu to the player).
 *
 * @param id        Player index if id is set to > 0 shows ghost menu to that player.
 *
 * @noreturn
 */
native mjb_block_simon_menu(id = 0);

/**
 * Shows simon menu.
 *
 * @param id        Player index.
 *
 * @noreturn
 */
native mjb_show_simon_menu(id);

/**
 * Sets a player to simon if there is no simon and if there is a simon it doesnt do anything.
 *
 * @param id        Player index.
 *
 * @noreturn
 */
native mjb_set_simon(id);

/**
 * Forces setting a player to simon.
 *
 * @param id        Player index.
 *
 * Unlike "mjb_set_simon" it gives simon to player even if there is another simon.
 *
 * @noreturn
 */
native mjb_force_set_simon(id);

/**
 * Clears Simon.
 *
 * @noreturn
 */
native mjb_clear_simon(); 

/**
 * Checks if a player is simon.
 *
 * @param id        Player index.
 *
 * @return	1 if he is 0 if not.
 */
native mjb_is_simon(id);

/**
 * Gets Simon Id.
 *
 * @return	simon's id.
 */
native mjb_get_simon();

/**
 * Checks if a simon exists.
 *
 * @return	1 if he exists 0 if not.
 */
native mjb_simon_exists();

/**
 * Opens Cell.
 *
 * @noreturn
 */
native mjb_open_cell();

/**
 * Closes Cell.
 *
 * @noreturn
 */
native mjb_close_cell();

/**
 * Checks if cell is opened.
 *
 * @return	1 for opened 0 for closed
 */
native mjb_is_cell_opened();

/**
 * Checks if an entiy is cell.
 *
 * @param entity	Entity index.
 *
 * @return		1 for true 0 for false
 */
native mjb_is_a_cell(entity);

/**
 * Starts Freeday PHASE if day type isnt freeday and one freeday happened in the round.
 *
 * @return	1 for success 0 for failure
 */
native mjb_start_freeday();

/**
 * Ends Freeday PHASE if day type isnt freeday and current phase is PHASE_FREEDAY.
 *
 * @return	1 for success 0 for failure
 */
native mjb_end_freeday();

/**
 * Gets current day number.
 *
 * @return	Day number.
 */
native mjb_get_day();

/**
 * Gets current day type.
 *
 * @return	Day Type [Normalday, Freeday, Gameday].
 */  
native mjb_get_day_type();

/**
 * Gets current phase.
 *
 * @return	Day Phase see MJB_Consts.
 */
native mjb_get_phase();

/**
 * Gets freeday timer id.
 *
 * @return	Freeday timer id if running and if not returns -1.
 */
native mjb_get_free_timer_id();

/**
 * Gets simon select timer id.
 *
 * @return	Simon select timer id if running and if not returns -1.
 */
native mjb_get_simon_timer_id();

/**
 * Gets gameday vote timer id.
 *
 * @return	Vote timer id if running and if not returns -1.
 */
native mjb_get_vote_timer_id();

/**
 * Start a new timer with duration.
 *
 * @param fDuration       Duration value in floating numbers.
 *
 * @return		  Timer Id.
 */
native mjb_start_timer(Float:fDuration);

/**
 * Gets a timer state.
 *
 * @param iTimerId        Timer id (Generated).
 *
 * @return                Timer state value 0 for stopped, 1 for running.
 */
native mjb_is_timer_running(iTimerId);

/**
 * Gets a timer state.
 *
 * @param iTimerId        Timer id (Generated).
 *
 * @return                Timer TimeLeft in FLOAT
 */
native Float:mjb_get_timer_timeleft(iTimerId);

/**
 * Gets timer info.
 *
 * @param iSlot				Slot of the timer 0 to MAX_TIMERS.
 * @param &iTimerId			Timer id placeholder to write the actual timer id to.
 * @param &iGen				Generation placeholder to write the generation number.
 * @param Float:fTimeleft		Timeleft placeholder.
 *
 * @return			1 on succes 0 on failure.
 */
native mjb_get_timer_info(iSlot, &iTimerId, &iGen, &Float:fTimeleft);

/**
 * Gets number of running timers (useful for making unique timers ids).
 *
 * @return                Timers running.
 */
native mjb_get_timers();

/**
 * Stops a timer with given id.
 *
 * @param iTimerId        Timer id (Generated).
 *
 * @noreturn
 */
native mjb_stop_timer(iTimerId);

/**
 * Add given duration value to give timer's end value.
 *
 * @param iTimerId        Timer id (Generated).
 * @param fDuration       Duration value in floating numbers.
 *
 * @noreturn
 */
native mjb_extend_timer(iTimerId, Float:fDuration);

/**
 * Stops all timers.
 *
 * @noreturn
 */
native mjb_stop_all_timers();

/**
 * Sets a player's Jailbreak state.
 *
 * @param id        Player index.
 * @param iState    State value (STATE_NONE, STATE_FREEDAY, STATE_WANTED).
 *
 * @noreturn
 */
native mjb_set_state(id, iState);

/**
 * Finds Prisoner of State Last.
 *
 * @return		Priosner id if valid, and if not valid -1.
 */
native mjb_find_last_prisoner();

/**
 * Retrieves a player's Jailbreak state.
 *
 * @param id        Player index.
 *
 * @return          Player's state value.
 */
native mjb_get_state(id);

/**
 * Sets a user to soccer.
 *
 * @param id        	Player index.
 *
 * @return		1 on success 0 on failure.
 */
native mjb_set_user_soccer(id);

/**
 * Sets a user to Boxing.
 *
 * @param id        	Player index.
 *
 * @return		1 on success 0 on failure.
 */
native mjb_set_user_boxing(id);

/**
 *  Sets a user to Freeday.
 *
 * @param id        	Player index.
 *
 * @return		1 on success 0 on failure.
 */
native mjb_set_user_freeday(id);

/**
 *  Sets a user to Freeday Nextday.
 *
 * @param id	        Player index.
 * @param bToggle	If set to MJB_False it takes nextday freeday from id.
 *
 * @return		1 on success 0 on failure.
 */
native mjb_set_user_freeday_nextday(id, bToggle=MJB_True);

/**
 *  Checks if a user is Freeday Nextday.
 *
 * @param id        Player index.
 *
 * @noreturn
 */
native mjb_is_user_freeday_nextday(id);
/**
 * Sets user minigames team.
 *
 * @param id        		Player index.
 * @param iMinigamesTeam	Minigames team to set 0 for none 1 for red 2 for blue
 
 *
 * @return          Player's state value.
 */
native mjb_set_user_mg_team(id, iMinigamesTeam);

/**
 * Retrieves a player's Jailbreak state.
 *
 * @param id        Player index.
 *
 * @return          Player's state value.
 */
native mjb_get_user_mg_team(id);

/**
 * Retrieves a player's Jailbreak state.
 *
 * @param iMinigamesTeam	Minigames team ID.
 *
 * @return          		Players count in the given team id.
 */
native mjb_get_mg_team_count(iMinigamesTeam);

/**
 * Sets all players' Jailbreak state.
 *
 * @param iState    State value (STATE_NONE, STATE_FREEDAY, STATE_WANTED).
 *
 * @noreturn
 */
native mjb_set_all_state(iState);

#include <MJB_Stocks>