// Define config entries for cryo
#define SUBSYSTEM_CRYO_CAN_RUN CONFIG_GET(flag/autocryo_enabled)
#define SUBSYSTEM_CRYO_CHECK_GHOSTS CONFIG_GET(flag/ghost_checking)
#define SUBSYSTEM_CRYO_TIME CONFIG_GET(number/autocryo_time_trigger)
#define SUBSYSTEM_CRYO_GHOST_PERIOD CONFIG_GET(number/ghost_check_time)
/// How often the SSD/ghost lists are rescanned for new candidates. The subsystem itself
/// fires far more often than this - the frequent fires exist to drain delete_queue.
#define SUBSYSTEM_CRYO_SCAN_PERIOD (5 MINUTES)

SUBSYSTEM_DEF(auto_cryo)
	name = "Automated Cryogenics"
	flags = SS_BACKGROUND
	wait = 10 SECONDS
	/// Current batch of SSD mobs being processed
	var/list/currentrun_cryo = list()
	/// Current batch of ghosts being processed
	var/list/currentrun_ghosts = list()
	/// Atoms handed over by cryoMob() for staggered deletion. Despawning a geared player
	/// (gear cascade + the mob itself) in one go used to eat a whole tick per despawn;
	/// instead the pieces land here and get qdel'd a few per tick. FIFO - order matters:
	/// gear strictly before its wearer, borg MMIs strictly after their shell.
	var/list/delete_queue = list()
	/// Next world.time we rescan ssd_mob_list/dead_mob_list for candidates.
	var/next_scan = 0

/datum/controller/subsystem/auto_cryo/fire(resumed)
	// Stage 0: drain the staggered-deletion queue. Runs even with autocryo configs off -
	// cryopods and the admin panel feed the queue through cryoMob() regardless.
	var/drained_any = FALSE
	while(length(delete_queue))
		// Guarantee at least one deletion per fire, yield before the rest.
		if(drained_any && MC_TICK_CHECK)
			return
		var/atom/movable/victim = delete_queue[1]
		delete_queue.Cut(1, 2)
		drained_any = TRUE
		if(!QDELETED(victim))
			qdel(victim)

	// Stage 1: periodic rescan of the candidate lists (the old once-per-5-minutes cadence).
	// Unfinished batches from the previous scan are never clobbered.
	if(world.time >= next_scan)
		next_scan = world.time + SUBSYSTEM_CRYO_SCAN_PERIOD
		if(SUBSYSTEM_CRYO_CAN_RUN && !length(currentrun_cryo))
			currentrun_cryo = GLOB.ssd_mob_list.Copy()
		if(SUBSYSTEM_CRYO_CHECK_GHOSTS && !length(currentrun_ghosts))
			currentrun_ghosts = GLOB.dead_mob_list.Copy()

	// Stage 2: send expired SSD mobs to cryo. cryoMob() itself is cheap now - the heavy
	// deletions land in delete_queue and are paid off next fire, a few per tick.
	if(SUBSYSTEM_CRYO_CAN_RUN && length(currentrun_cryo))
		var/datum/weakref/cached_computer = cryo_find_control_computer(urgent = TRUE)
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
	if(SUBSYSTEM_CRYO_CHECK_GHOSTS && length(currentrun_ghosts))
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

/// Queues an atom for staggered deletion in fire(). Callers must have already detached it
/// from gameplay (nullspace/containers) - it may live for a few more seconds.
/datum/controller/subsystem/auto_cryo/proc/queue_deletion(atom/movable/victim)
	if(QDELETED(victim))
		return
	delete_queue += victim

/// Queues a whole list for staggered deletion, preserving order.
/datum/controller/subsystem/auto_cryo/proc/queue_deletion_list(list/victims)
	for(var/atom/movable/victim as anything in victims)
		if(!QDELETED(victim))
			delete_queue += victim

/datum/controller/subsystem/auto_cryo/Recover()
	if(islist(SSauto_cryo.currentrun_cryo))
		currentrun_cryo = SSauto_cryo.currentrun_cryo
	if(islist(SSauto_cryo.currentrun_ghosts))
		currentrun_ghosts = SSauto_cryo.currentrun_ghosts
	if(islist(SSauto_cryo.delete_queue))
		delete_queue = SSauto_cryo.delete_queue
	if(isnum(SSauto_cryo.next_scan))
		next_scan = SSauto_cryo.next_scan

// Remove defines
#undef SUBSYSTEM_CRYO_CAN_RUN
#undef SUBSYSTEM_CRYO_CHECK_GHOSTS
#undef SUBSYSTEM_CRYO_TIME
#undef SUBSYSTEM_CRYO_GHOST_PERIOD
#undef SUBSYSTEM_CRYO_SCAN_PERIOD
