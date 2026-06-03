#include <amxmodx>
#include <amxmisc>
#include <MJB_Core>

#define PLUGIN "Admin Commands"

public plugin_init() {
    register_plugin(PLUGIN, PLUGIN, PLUGIN)
	
    register_concmd("mjb_open_cell",        "Cmd_OpenCell",         RANK_HEAD_ADMIN);
    register_concmd("mjb_close_cell",       "Cmd_CloseCell",        RANK_HEAD_ADMIN);
    register_concmd("mjb_lock_cell",        "Cmd_LockCell",         RANK_CO_OWNER, "<@all, @players, @server, @admins, nick, #userid, authid>");
    register_concmd("mjb_unlock_cell",      "Cmd_UnlockCell",       RANK_CO_OWNER, "<@all, @players, @server, @admins, nick, #userid, authid>");
    register_concmd("mjb_give_melee",       "Cmd_GiveMelee",        RANK_ADMINISTRATOR, "<@all, @guards, @prisoners, nick, #userid, authid> [0=Default | 1..5=SuperVIP | 6,7=Boxing");
    register_concmd("mjb_add_multijumps",   "Cmd_AddMultijumps",    RANK_OWNER, "<@all, @guards, @prisoners, nick, #userid, authid> value");
    register_concmd("mjb_kill_simon",       "Cmd_KillSimon",        RANK_CO_OWNER);
    register_concmd("mjb_give_simon",       "Cmd_GiveSimon",        RANK_CO_OWNER, "<nick, #userid, authid>");
    register_concmd("mjb_take_simon",       "Cmd_TakeSimon",        RANK_CO_OWNER);
    register_concmd("mjb_block_simon",      "Cmd_BlockSimon",       RANK_CO_OWNER, "<nick, #userid, authid>");
    register_concmd("mjb_unblock_simon",    "Cmd_UnblockSimon",     RANK_CO_OWNER, "<nick, #userid, authid>");
}

/* =========================
   Open/Close Cell CCs
========================= */
public Cmd_OpenCell(id, iLevel, cid)
{
    if (!hasCmdAccess(id, iLevel, cid, 0))
        return PLUGIN_HANDLED;
    
    if (mjb_is_cell_opened()) {
        console_print(id, "[Moon JB CMD] Cell is already openned.");
        return PLUGIN_HANDLED;
    }

    // we pass CELL_ADMINS index and not caller index because this an admin cmd
    if (!mjb_open_cell(CELL_ADMINS)) {
        console_print(id, "[Moon JB CMD] You can't open the Cell right now, it is locked.");
        return PLUGIN_HANDLED;
    }

    new szAdminName[32];
    get_user_name(id, szAdminName, charsmax(szAdminName));

    MJB_Print(0, "!tADMIN !g%s!t: Openned Cell", szAdminName);
    log_amx("ADMIN %s Openned Cell", szAdminName);
    return PLUGIN_HANDLED;
}

public Cmd_CloseCell(id, iLevel, cid)
{
    if (!hasCmdAccess(id, iLevel, cid, 0))
        return PLUGIN_HANDLED;
    
    if (!mjb_is_cell_opened()) {
        console_print(id, "[Moon JB CMD] Cell is already closed.");
        return PLUGIN_HANDLED;
    }

    // we pass CELL_ADMINS index and not caller index because this an admin cmd
    if (!mjb_close_cell(CELL_ADMINS)) {
        console_print(id, "[Moon JB CMD] You can't close the Cell right now, it is locked.");
        return PLUGIN_HANDLED;
    }

    new szAdminName[32];

    get_user_name(id, szAdminName, charsmax(szAdminName));

    MJB_Print(0, "!tADMIN !g%s!t: Closed Cell", szAdminName);
    log_amx("ADMIN %s Closed Cell", szAdminName);
    return PLUGIN_HANDLED;
}

/* =========================
   Lock/Unlock Cell CCs
========================= */
public Cmd_LockCell(id, iLevel, cid)
{
    if (!hasCmdAccess(id, iLevel, cid, 1))
        return PLUGIN_HANDLED;
    
    new szArg1[32];
    read_argv(1, szArg1, 31);

    Helper_LockCell(id, true, szArg1);
    return PLUGIN_HANDLED;
}

public Cmd_UnlockCell(id, iLevel, cid)
{
    if (!hasCmdAccess(id, iLevel, cid, 1))
        return PLUGIN_HANDLED;
    
    new szArg1[32];
    read_argv(1, szArg1, 31);

    Helper_LockCell(id, false, szArg1);
    return PLUGIN_HANDLED;
}

stock Helper_LockCell(id, bool:bToggle, szArg1[])
{
    new iLockedFromId = -1;
    new szAdminName[32], szTargetName[32];

    get_user_name(id, szAdminName, charsmax(szAdminName));

    if (equali(szArg1, "@all")) {
        iLockedFromId = CELL_ALL;
        format(szTargetName, charsmax(szTargetName), "ALL");
    } else if (equali(szArg1, "@server")) {
        iLockedFromId = CELL_SERVER;
        format(szTargetName, charsmax(szTargetName), "SERVER");
    } else if (equali(szArg1, "@players")) {
        iLockedFromId = CELL_PLAYERS;
        format(szTargetName, charsmax(szTargetName), "PLAYERS");
    } else if (equali(szArg1, "@admins")) {
        iLockedFromId = CELL_ADMINS;
        format(szTargetName, charsmax(szTargetName), "ADMINS");
    }
    else {
        new iTargetId = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
        
        if (!mjb_is_valid_player(iTargetId)) {
            console_print(id, "[Moon JB CMD] Invalid Player index %d", iTargetId);
            return PLUGIN_HANDLED;
        }

        get_user_name(iTargetId, szTargetName, charsmax(szTargetName));

        if (!TryAffect(id, iTargetId, szTargetName))
            return PLUGIN_HANDLED;

        iLockedFromId = iTargetId;
    }

    mjb_lock_cell(bToggle, iLockedFromId);

    MJB_Print(0, "!tADMIN !g%s!t: %socked Cells For !g%s", szAdminName, (bToggle) ? "L" : "Unl", szTargetName);
    log_amx("ADMIN %s %socked Cells For %s", szAdminName, (bToggle) ? "L" : "Unl", szTargetName);
    return PLUGIN_HANDLED;
}

/* =========================
   Give Melee CCs
========================= */
public Cmd_GiveMelee(id, iLevel, cid) {
    if (!hasCmdAccess(id, iLevel, cid, 2))
        return PLUGIN_HANDLED;
    
    new szArg1[24], szArg2[6];
    read_argv(1, szArg1, 23);
    read_argv(2, szArg2, 2);
    
    new iMeleeType = str_to_num(szArg2);

    new szAdminName[32], szTargetName[32];
    get_user_name(id, szAdminName, charsmax(szAdminName));

    if (szArg1[0] == '@') {

        new iPlayers[MAX_PLAYERS], iPlNum, szGetPlFlags[12], szGetPlTeam[32];
        new iTargetId;
        new szRank[32];
        new szTempName[32];
        copy(szGetPlFlags, charsmax(szGetPlFlags), "ah")

        switch(szArg1[1]) {
            case 'a', 'A':
            {
                format(szTargetName, charsmax(szTargetName), "All");
            } 
            case 'g', 'G', 'c', 'C':
            {
                add(szGetPlFlags, charsmax(szGetPlFlags), "e");
                format(szGetPlTeam, charsmax(szGetPlTeam), "CT");
                format(szTargetName, charsmax(szTargetName), "Guards");
            } 
            case 'p', 'P', 't', 'T':
            {
                add(szGetPlFlags, charsmax(szGetPlFlags), "e");
                format(szGetPlTeam, charsmax(szGetPlTeam), "TERRORIST");
                format(szTargetName, charsmax(szTargetName), "Prisoners");
            }
        }

        get_players(iPlayers, iPlNum, szGetPlFlags, szGetPlTeam);

        for (new i = 0; i < iPlNum; i++) {
            iTargetId = iPlayers[i];

            if (!mjb_is_valid_player(iTargetId))
                continue;

            

            if (!canAffect(id, iTargetId)) {
                get_user_name(iTargetId, szTempName, charsmax(szTempName));
                GetRankLevelStr(iTargetId, szRank, charsmax(szRank));
                console_print(id, "[Moon JB CMD] Skipping %s %s because he is Immune to you", szRank, szTempName);
                continue;
            }

            mjb_set_user_melee(iTargetId, iMeleeType);
        }
    }
    else {
        new iTargetId = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);

        get_user_name(iTargetId, szTargetName, charsmax(szTargetName));

        if (!TryAffect(id, iTargetId, szTargetName))
            return PLUGIN_HANDLED;
        
        mjb_set_user_melee(iTargetId, iMeleeType);
    }

    new szMeleeType[24];
    GetMeleeTypeStr(iMeleeType, szMeleeType, charsmax(szMeleeType));
    if (iMeleeType == 0) {
        MJB_Print(0, "!tADMIN !g%s!t: Set !g%s !tMelee To !g%s", szAdminName, szTargetName, szMeleeType);
        log_amx("ADMIN %s Set %s Melee To %s", szAdminName, szTargetName, szMeleeType);
    } else {
        MJB_Print(0, "!tADMIN !g%s!t: Gave !g%s !tTo !g%s", szAdminName, szMeleeType, szTargetName);
        log_amx("ADMIN %s Gave %s To %s", szAdminName, szMeleeType, szTargetName);
    }
    return PLUGIN_HANDLED;
}

/* =========================
   Add Multijumps CCs
========================= */
public Cmd_AddMultijumps(id, iLevel, cid) {
    if (!hasCmdAccess(id, iLevel, cid, 2))
        return PLUGIN_HANDLED;
    
    new szArg1[24], szArg2[6];
    read_argv(1, szArg1, 23);
    read_argv(2, szArg2, 2);
    
    new iValue = str_to_num(szArg2);

    new szAdminName[32], szTargetName[32];
    get_user_name(id, szAdminName, charsmax(szAdminName));

    if (szArg1[0] == '@') {
        new iPlayers[MAX_PLAYERS], iPlNum, szGetPlFlags[6], szGetPlTeam[10];
        new iTargetId;
        new szRank[32], szTempName[32];
        copy(szGetPlFlags, charsmax(szGetPlFlags), "ah")

        switch(szArg1[1]) {
            case 'a', 'A': {
                format(szTargetName, charsmax(szTargetName), "All");
            }
            case 'g', 'G', 'c', 'C': {
                add(szGetPlFlags, charsmax(szGetPlFlags), "e");
                format(szGetPlTeam, charsmax(szGetPlTeam), "CT");
                format(szTargetName, charsmax(szTargetName), "Guards");
            }
            case 'p', 'P', 't', 'T': {
                add(szGetPlFlags, charsmax(szGetPlFlags), "e");
                format(szGetPlTeam, charsmax(szGetPlTeam), "TERRORIST");
                format(szTargetName, charsmax(szTargetName), "Prisoners");
            }
            default: {
                console_print(id, "[Moon JB CMD] Unkown flags");
                return PLUGIN_HANDLED;
            }
        }
        
        get_players(iPlayers, iPlNum, szGetPlFlags, szGetPlTeam);

        for (new i = 0; i < iPlNum; i++) {
            iTargetId = iPlayers[i];

            if (!mjb_is_valid_player(iTargetId))
                continue;

            get_user_name(iTargetId, szTempName, charsmax(szTempName));

            if (!canAffect(id, iTargetId)) {
                GetRankLevelStr(iTargetId, szRank, charsmax(szRank));
                console_print(id, "[Moon JB CMD] Skipping %s %s because he is Immune to you", szRank, szTempName);
                continue;
            }

            mjb_add_multijumps(iTargetId, iValue);
        }
    }
    else {
        new iTargetId = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);

        get_user_name(iTargetId, szTargetName, charsmax(szTargetName));

        if (!TryAffect(id, iTargetId, szTargetName))
            return PLUGIN_HANDLED;
        
        mjb_add_multijumps(iTargetId, iValue);
    }

    if (iValue == 0) {
        MJB_Print(0, "!tADMIN !g%s!t: Set !g%s !tAdditional Multijumps To !g%d", szAdminName, szTargetName, iValue);
        log_amx("ADMIN %s Set %s Additional Multijumps To !g%d", szAdminName, szTargetName, iValue);
    } else {
        MJB_Print(0, "!tADMIN !g%s!t: Gave !g%d !tMultijumps !tTo !g%s", szAdminName, iValue, szTargetName);
        log_amx("ADMIN %s: Gave %d Multijumps To %s", szAdminName, iValue, szTargetName);
    }
    return PLUGIN_HANDLED;
}

public Cmd_KillSimon(id, iLevel, cid) {
    if (!hasCmdAccess(id, iLevel, cid, 0))
        return PLUGIN_HANDLED;
    
    new iTargetId = mjb_get_simon();

    if (!mjb_is_valid_player(iTargetId)) {
        console_print(id, "[Moon JB CMD] Simon doesnt exists or is dead");
        return PLUGIN_HANDLED;
    }

    new szAdminName[32], szTargetName[32];
    get_user_name(id, szAdminName, charsmax(szAdminName));
    get_user_name(iTargetId, szTargetName, charsmax(szTargetName));

    if (!TryAffect(id, iTargetId, szTargetName))
        return PLUGIN_HANDLED;

    user_kill(iTargetId);
    MJB_Print(0, "!tADMIN !g%s!t: Remotely Killed !g%s", szAdminName, szTargetName);
    log_amx("ADMIN %s Remotely Killed %s", szAdminName, szTargetName);
    return PLUGIN_HANDLED;
}

public Cmd_GiveSimon(id, iLevel, cid) {
    if (!hasCmdAccess(id, iLevel, cid, 0))
        return PLUGIN_HANDLED;

    new szArg1[32];
    read_argv(1, szArg1, 31);

    new iTargetId = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
    new szTargetName[32];

    get_user_name(iTargetId, szTargetName, 31);
    
    if (!TryAffect(id, iTargetId, szTargetName))
        return PLUGIN_HANDLED;

    new iSimonId = mjb_get_simon();

    new szAdminName[32];
    get_user_name(id, szAdminName, charsmax(szAdminName));
    
    if (mjb_is_valid_player(iSimonId)) {
        new szSimonName[32];
        get_user_name(iSimonId, szSimonName, charsmax(szSimonName));

        if (!TryAffect(id, iSimonId, szSimonName))
            return PLUGIN_HANDLED;

        if (!mjb_force_set_simon(iTargetId)) {
            console_print(id, "[Moon JB CMD] Cannot set target to simon, ensure that he is alive and he is a guard and unblocked");
            return PLUGIN_HANDLED;
        }

        MJB_Print(0, "!tADMIN !g%s!t: Transferred simoni from !g%s !tto !g%s", szAdminName, szSimonName, szTargetName);
        log_amx("ADMIN %s: Transferred simoni from %s to %s", szAdminName, szSimonName, szTargetName);
        return PLUGIN_HANDLED;
    }

    if (!mjb_set_simon(iTargetId)) {
        console_print(id, "[Moon JB CMD] Cannot set target to simon, ensure that he is alive and he is a guard and unblocked");
        return PLUGIN_HANDLED;
    }

    MJB_Print(0, "!tADMIN !g%s!t: Gave simoni to !g%s", szAdminName, szTargetName);
    log_amx("ADMIN %s Gave simoni to %s", szAdminName, szTargetName);
    return PLUGIN_HANDLED;
}

public Cmd_TakeSimon(id, iLevel, cid) {
    if (!hasCmdAccess(id, iLevel, cid, 0))
        return PLUGIN_HANDLED;
    
    new iSimonId = mjb_get_simon();

    if (!mjb_is_valid_player(iSimonId)) {
        console_print(id, "[Moon JB CMD] Simon doesnt exists or is dead");
        return PLUGIN_HANDLED;
    }

    new szSimonName[32];
    get_user_name(iSimonId, szSimonName, charsmax(szSimonName));

    if (!TryAffect(id, iSimonId, szSimonName))
        return PLUGIN_HANDLED;

    new szAdminName[32];
    get_user_name(id, szAdminName, charsmax(szAdminName));

    mjb_clear_simon();
    MJB_Print(0, "!tADMIN !g%s!t: Took simoni from !g%s", szAdminName, szSimonName);
    log_amx("ADMIN %s: Took simoni from %s", szAdminName, szSimonName);
    return PLUGIN_HANDLED;
}

public Cmd_BlockSimon(id, iLevel, cid) {
    return Helper_ToggleBlockSimon(id, iLevel, cid, true);
}

public Cmd_UnblockSimon(id, iLevel, cid) {
    return Helper_ToggleBlockSimon(id, iLevel, cid, false);
}

public Helper_ToggleBlockSimon(id, iLevel, cid, bool:bToggle) {
    if (!hasCmdAccess(id, iLevel, cid, 0))
        return PLUGIN_HANDLED;
    
    new szArg1[32];
    read_argv(1, szArg1, 31);
    remove_quotes(szArg1)

    new iTargetId = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);

    new szTargetName[32];
    get_user_name(iTargetId, szTargetName, 31);

    if (!TryAffect(id, iTargetId, szTargetName))
        return PLUGIN_HANDLED;
    
    new szAdminName[32];
    get_user_name(id, szAdminName, 31);

    if (bToggle) {
        mjb_block_from_simoni(iTargetId, true);
        MJB_Print(0, "!tADMIN !g%s!t: Blocked player !g%s from being simon", szAdminName, szTargetName);
        log_amx("ADMIN %s Blocked player %s from being simon", szAdminName, szTargetName);
    } else {
        mjb_block_from_simoni(iTargetId, false);
        MJB_Print(0, "!tADMIN !g%s!t: Unblocked player !g%s from being simon", szAdminName, szTargetName);
        log_amx("ADMIN %s Unblocked player %s from being simon", szAdminName, szTargetName);
    }

    return PLUGIN_HANDLED;
}

stock bool:TryAffect(id, iTargetId, const szTargetName[]) {
    if (!canAffect(id, iTargetId)) {
        new szRank[32];
        GetRankLevelStr(iTargetId, szRank, charsmax(szRank));
        console_print(id, "[Moon JB CMD] You can't affect '%s' he is %s", szTargetName, szRank);
        return false;
    }
    return true;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
