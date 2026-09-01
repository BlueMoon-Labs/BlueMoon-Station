#define MAX_SPAWN_ATTEMPT 3


/datum/round_event/ghost_role
	// We expect 0 or more /clients (or things with .key) in this list
	var/list/priority_candidates = list()
	var/minimum_required = 1
	var/role_name = "debug rat with cancer" // Q U A L I T Y  M E M E S
	var/list/spawned_mobs = list()
	var/status
	var/cached_announcement_chance
	fakeable = FALSE

/datum/round_event/ghost_role/start()
	try_spawning()

/datum/round_event/ghost_role/proc/try_spawning(sanity = 0, retry = 0)
	// The event does not run until the spawning has been attempted
	// to prevent us from getting gc'd halfway through
	processing = FALSE

	status = spawn_role()
	if(isnull(cached_announcement_chance))
		cached_announcement_chance = announce_chance //only announce once we've finished the spawning loop.
	announce_chance = (status == SUCCESSFUL_SPAWN ? cached_announcement_chance : 0)
	if((status == WAITING_FOR_SOMETHING))
		if(retry >= MAX_SPAWN_ATTEMPT)
			message_admins("[role_name] event has exceeded maximum spawn attempts. Aborting and refunding.")
			refund_failed_spawn("превышено число отложенных попыток спауна")
			return
		var/waittime = 600 * (2^retry)
		message_admins("The event will not spawn a [role_name] until certain \
			conditions are met. Waiting [waittime/10]s and then retrying.")
		addtimer(CALLBACK(src, PROC_REF(try_spawning), 0, ++retry), waittime)
		return

	if(status == MAP_ERROR)
		message_admins("[role_name] cannot be spawned due to a map error.")
		refund_failed_spawn("ошибка карты или отсутствует точка спауна")
	else if(status == NOT_ENOUGH_PLAYERS)
		message_admins("[role_name] cannot be spawned due to lack of players \
			signing up.")
		refund_failed_spawn("гост-опрос завершился без достаточного числа желающих")
	else if(status == SUCCESSFUL_SPAWN)
		if(spawned_mobs.len && SSdirector.track_ghost_role_spawn(control, spawned_mobs, triggered_randomly))
			message_admins("[role_name] spawned successfully.")
			for(var/mob/M in spawned_mobs)
				announce_to_ghosts(M)
		else
			message_admins("[role_name] reported a successful spawn without any live spawned mobs. Aborting and refunding; this is a bug.")
			refund_failed_spawn("spawn_role() сообщил успех, но не создал отслеживаемую роль")
	else
		message_admins("An attempt to spawn [role_name] returned [status], \
			this is a bug.")

	processing = TRUE

/// Никто не заспаунился - события не случилось: вернуть попытку, кошелёк ступени и снять
/// вклад intensity сразу (без linger). Иначе провальный ролл гост-антага висел бы 30 минут
/// фантомной нагрузкой в antag_load и глушил клапан давления директора.
/datum/round_event/ghost_role/proc/refund_failed_spawn(reason = "гост-роль не была создана")
	if(!control)
		return
	// Бюджет тратился только на естественный запуск через бит (админ-форс идёт мимо кошельков).
	SSdirector.note_failed_action(control, refund_budget = triggered_randomly, retry_replacement = triggered_randomly)
	SSdirector.director_log_beat(SSdirector.collect_signals(), control, DIRECTOR_BEAT_FAILED,
		detail = "[reason]; [triggered_randomly ? "бюджет и паузы возвращены, запрошена замена" : "ручной запуск, бюджет не списывался; паузы возвращены"]")

/datum/round_event/ghost_role/proc/spawn_role()
	// Return true if role was successfully spawned, false if insufficent
	// players could be found, and just runtime if anything else happens
	return TRUE

/datum/round_event/ghost_role/proc/get_candidates(jobban, gametypecheck, be_special)
	// Returns a list of candidates in priority order, with candidates from
	// `priority_candidates` first, and ghost roles randomly shuffled and
	// appended after
	var/list/regular_candidates
	// don't get their hopes up
	if(priority_candidates.len < minimum_required)
		regular_candidates = pollGhostCandidates("Хотите ли вы занять роль '[role_name]'?", jobban, gametypecheck, be_special, poll_time = 30 SECONDS, minimum_required = minimum_required)
	else
		regular_candidates = list()

	shuffle_inplace(regular_candidates)

	var/list/candidates = priority_candidates + regular_candidates

	return candidates

#undef MAX_SPAWN_ATTEMPT
