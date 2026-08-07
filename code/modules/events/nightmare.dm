/datum/round_event_control/nightmare
	name = "Spawn Nightmare"
	typepath = /datum/round_event/ghost_role/nightmare
	max_occurrences = 1 // двойной кошмар за раунд (9771) - одного достаточно, повтор только руками админа
	min_players = 25 // порог от больших серверов резал разнообразие на типичных 25-35: гост-пул сужался до метеора
	// Ранняя волна гост-пула - с 20-й минуты (см. Spawn Morph): без порога кошмар оставался
	// единственной целью копилки первых минут в хард-раундах после гейта ревенанта.
	earliest_start = 20 MINUTES
	weight = 8
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 10
	intensity = 15
	director_ghost_jobban = ROLE_ALIEN
	director_ghost_preference = ROLE_ALIEN
	family = "nightmare" // с рулсетом-двойником динамика: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // как у рулсета-двойника: не экста и не лайт
	description = "Spawns a nightmare, aiming to darken the station."

/datum/round_event/ghost_role/nightmare
	minimum_required = 1
	role_name = "nightmare"
	fakeable = FALSE

/datum/round_event/ghost_role/nightmare/spawn_role()
	// Точку ищем ДО гост-опроса: раньше пул кандидатов собирался полминуты и только потом
	// выяснялось, что выпускать кошмара некуда.
	var/turf/spawn_turf = find_nightmare_spawn()
	if(!spawn_turf)
		message_admins("Кошмар не создан: на станции нет ни одного тёмного турфа (проверено [length(GLOB.xeno_spawn)] точек xeno_spawn и все техтоннели).")
		log_game("Nightmare event aborted: no dark turf found on the station.")
		return MAP_ERROR

	var/list/candidates = get_candidates(ROLE_ALIEN, null, ROLE_ALIEN)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	// Пока шёл опрос, свет мог включиться или точку могли занять - перевыбираем.
	if(!is_valid_nightmare_spawn(spawn_turf))
		spawn_turf = find_nightmare_spawn()
	if(!spawn_turf)
		message_admins("Кошмар не создан: пока шёл гост-опрос, темнота на станции пропала.")
		log_game("Nightmare event aborted: the station lit up while polling ghosts.")
		return MAP_ERROR

	var/mob/dead/selected = pick(candidates)

	var/datum/mind/player_mind = new /datum/mind(selected.key)
	player_mind.active = TRUE

	log_nightmare_spawn(spawn_turf)
	var/mob/living/carbon/human/nightmare = new (spawn_turf)
	player_mind.transfer_to(nightmare)
	player_mind.assigned_role = "Nightmare"
	player_mind.special_role = "Nightmare"
	player_mind.add_antag_datum(/datum/antagonist/nightmare)
	nightmare.set_species(/datum/species/shadow/nightmare)
	playsound(nightmare, 'sound/magic/ethereal_exit.ogg', 50, 1, -1)
	message_admins("[ADMIN_LOOKUPFLW(nightmare)] has been made into a Nightmare by an event.")
	log_game("[key_name(nightmare)] was spawned as a Nightmare by an event.")
	spawned_mobs += nightmare
	return SUCCESSFUL_SPAWN
