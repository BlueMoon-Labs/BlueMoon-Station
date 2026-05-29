// Define config entries for cryo
#define SUBSYSTEM_CRYO_CAN_RUN CONFIG_GET(flag/autocryo_enabled)
#define SUBSYSTEM_CRYO_CHECK_GHOSTS CONFIG_GET(flag/ghost_checking)
#define SUBSYSTEM_CRYO_TIME CONFIG_GET(number/autocryo_time_trigger)
#define SUBSYSTEM_CRYO_GHOST_PERIOD CONFIG_GET(number/ghost_check_time)

SUBSYSTEM_DEF(auto_cryo)
	name = "Automated Cryogenics"
	flags = SS_BACKGROUND
	wait = 5 MINUTES
	/// Current batch of SSD mobs being processed
	var/list/currentrun_cryo = list()
	/// Current batch of ghosts being processed
	var/list/currentrun_ghosts = list()

/datum/controller/subsystem/auto_cryo/Initialize()
	// Check config before running
	if(!SUBSYSTEM_CRYO_CAN_RUN)
		can_fire = FALSE

	return ..()

/datum/controller/subsystem/auto_cryo/fire()
	// Process cryo mobs
	if(SUBSYSTEM_CRYO_CAN_RUN)
		var/datum/weakref/cached_computer = cryo_find_control_computer(urgent = TRUE)
		if(!currentrun_cryo.len)
			currentrun_cryo = GLOB.ssd_mob_list.Copy()
		var/processed_cryo = FALSE
		while(currentrun_cryo.len)
			var/mob/living/cryo_mob = currentrun_cryo[currentrun_cryo.len]
			currentrun_cryo.len--
			if(QDELETED(cryo_mob) || !isliving(cryo_mob) || !(cryo_mob in GLOB.ssd_mob_list))
				continue
			var/afk_time = world.time - cryo_mob.lastclienttime
			if(afk_time < SUBSYSTEM_CRYO_TIME)
				continue
			// Гарантируем минимум 1 обработку за fire(), yield перед последующими
			if(processed_cryo && MC_TICK_CHECK)
				return
			processed_cryo = TRUE
			cryoMob(cryo_mob, cached_computer, is_teleporter = TRUE, effects = TRUE) //BLUEMOON CHANGE было is_teleporter = FALSE (нужно для правильного описания коробки в некоторых ситуациях)
			log_game("[cryo_mob] was sent to cryo after being SSD for [afk_time] ticks.")

	//BLUEMOON REWORKED теперь реально удаляем гостов
	if(SUBSYSTEM_CRYO_CHECK_GHOSTS)
		if(!currentrun_ghosts.len)
			currentrun_ghosts = GLOB.dead_mob_list.Copy()
		var/processed_ghosts = FALSE
		while(currentrun_ghosts.len)
			var/mob/dead/observer/ghost_mob = currentrun_ghosts[currentrun_ghosts.len]
			currentrun_ghosts.len--
			if(QDELETED(ghost_mob) || !istype(ghost_mob) || ghost_mob.client)
				continue
			var/afk_time = world.time - ghost_mob.lastclienttime
			if(afk_time < SUBSYSTEM_CRYO_GHOST_PERIOD)
				continue
			// Гарантируем минимум 1 обработку за fire(), yield перед последующими
			if(processed_ghosts && MC_TICK_CHECK)
				return
			processed_ghosts = TRUE
			log_game("[ghost_mob] was deleted after being SSD for [afk_time] ticks.")
			qdel(ghost_mob)
	//BLUEMOON REWORKED END

// Remove defines
#undef SUBSYSTEM_CRYO_CAN_RUN
#undef SUBSYSTEM_CRYO_CHECK_GHOSTS
#undef SUBSYSTEM_CRYO_TIME
#undef SUBSYSTEM_CRYO_GHOST_PERIOD
