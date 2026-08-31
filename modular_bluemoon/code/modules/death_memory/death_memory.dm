/*
	Попытка в унификацию внутриигровой помощи админам в проверке, кто помнит свою смерть, а кто не помнит.
*/

/// Mob forgets its death due to a reason, passed as an argument. Uses DEATH_FORGETFULNESS_REASON_UNKNOWN as a default.
/datum/mind/proc/forget_death(reason = DEATH_FORGETFULNESS_REASON_UNKNOWN)
	if(HAS_TRAIT_FROM(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, reason))
		return
	if(!istype(current))
		return
	current.log_message("does not remember its own death anymore. Reason: [reason]", LOG_VICTIM)
	ADD_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, reason)

/// Checks whether mind's mob does remember its death and acts accordingly, removing forgetfulness trait and informing revived and admins
/// about situation. Revival method - can be "defibrillator", "strange reagent" etc.
/datum/mind/proc/revival_handle_memory(revival_method = "something")
	var/forgotten = HAS_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS)

	REMOVE_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, DEATH_FORGETFULNESS_REASON_IMMEDIATE)
	REMOVE_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, DEATH_FORGETFULNESS_REASON_LATE)
	REMOVE_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, DEATH_FORGETFULNESS_REASON_STRANGE_REAGENT)
	REMOVE_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, DEATH_FORGETFULNESS_REASON_SYNTHTISSUE)
	REMOVE_TRAIT(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, DEATH_FORGETFULNESS_REASON_UNKNOWN)

	var/list/policies = CONFIG_GET(keyed_list/policy)
	var/policy = forgotten ? policies[POLICYCONFIG_ON_DEFIB_LATE] : policies[POLICYCONFIG_ON_DEFIB_INTACT]
	if(policy)
		to_chat(current, policy)
	current.log_message("revived using [revival_method] after [(world.time - current.timeofdeath) / 10] seconds, considered [forgotten ? "late" : "memory-intact"] revival under configured policy limits.", LOG_GAME)
	message_admins("[ADMIN_LOOKUPFLW(current)] возвращён к жизни и [forgotten ? "ничего не помнит" : "всё помнит"].")
	log_admin("[current] возвращён к жизни и [forgotten ? "ничего не помнит" : "всё помнит"].")


/// Handles memory loss after a some time being dead
/datum/mind/proc/death_handle_memory()
	if(HAS_TRAIT_FROM(src, TRAIT_BLUEMOON_DEATH_FORGETFULNESS, DEATH_FORGETFULNESS_REASON_LATE))
		return
	// Конфиг в секундах, переводим в децисекунды
	var/timelimit = CONFIG_GET(number/defib_cmd_time_limit) * 10
	if(!timelimit)
		return
	addtimer(CALLBACK(src, PROC_REF(forget_death), DEATH_FORGETFULNESS_REASON_LATE), timelimit)






