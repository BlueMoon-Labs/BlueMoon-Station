/datum/round_event_control/blob
	name = "Blob"
	typepath = /datum/round_event/ghost_role/blob
	weight = 5
	max_occurrences = 1

	earliest_start = 90 MINUTES
	min_players = 40
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 15
	intensity = 30
	intensity_linger = 45 MINUTES // блоб-осада живёт заметно дольше спавнера
	antag_heavy = TRUE // угроза всей станции: мягкие профили такое выключают
	family = "blob" // с рулсетами-двойниками динамика (гост-блоб, заражение): не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // не экста и не лайт
	description = "Spawns a new blob overmind."

/datum/round_event/ghost_role/blob
	announce_when	= -1
	role_name = "blob overmind"
	fakeable = TRUE

/datum/round_event/ghost_role/blob/announce(fake)
	if(prob(75))
		priority_announce("Подтвержденная вспышка биологической опасности уровня 5 на борту [station_name()]. Весь персонал должен противостоять эпидемии.", "Биологическая Тревога", "outbreak5", type = "outbreak5", has_important_message = TRUE)
	else
		print_command_report("Подтвержденная вспышка биологической опасности уровня 5 на борту [station_name()]. Весь персонал должен противостоять эпидемии.", "Биологическая Тревога")

/datum/round_event/ghost_role/blob/spawn_role()
	if(!GLOB.blobstart.len)
		return MAP_ERROR
	var/list/candidates = get_candidates(ROLE_BLOB, null, ROLE_BLOB)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS
	var/mob/dead/observer/new_blob = pick(candidates)
	var/mob/camera/blob/BC = new_blob.become_overmind()
	spawned_mobs += BC
	message_admins("[ADMIN_LOOKUPFLW(BC)] has been made into a blob overmind by an event.")
	log_game("[key_name(BC)] was spawned as a blob overmind by an event.")
	return SUCCESSFUL_SPAWN
