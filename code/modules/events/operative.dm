/datum/round_event_control/operative
	name = "Lone Operative"
	typepath = /datum/round_event/ghost_role/operative
	// Исторический вес растёт, пока диск лежит без движения (nuclearbomb.dm). Нулевой старт
	// не выключает событие: он лишь не даёт оперативнику прийти без причины.
	weight = 0
	weight_can_change = TRUE
	max_occurrences = 1
	min_players = 30
	category = EVENT_CATEGORY_INVASION
	severity = DIRECTOR_SEVERITY_GHOST // в том числе при форсе обязан считаться антаг-нагрузкой
	cost = 15
	intensity = 20 // одиночка, но с ядерным риском
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	director_ghost_jobban = ROLE_OPERATIVE
	director_ghost_preference = ROLE_OPERATIVE
	description = "A single nuclear operative assaults the station."

// На Extended защитник может появиться самостоятельно. В Dynamic Light этот же тип роли
// запускается только связанной второй волной после успешного Lone Operative (см. ниже).
/datum/round_event_control/operative/keeper
	name = "Lone Operative (Disk Keeper)"
	typepath = /datum/round_event/ghost_role/operative/keeper
	admin_only = FALSE
	weight = 10
	min_players = 15 // Extended живёт и на лоупопе; унаследованные 30 делали событие практически недоступным
	earliest_start = 30 MINUTES
	required_round_type = list(ROUNDTYPE_EXTENDED)
	director_linked_round_types = list(ROUNDTYPE_DYNAMIC_LIGHT)
	director_linked_detail = "появляется только второй волной после успешного Lone Operative"
	cost = 10
	intensity = 10 // защитник, а не угроза: мягкий вклад в гост-пул фонового режима
	description = "A syndicate specialist arrives to guard the nuclear authentication disk."

/datum/round_event/ghost_role/operative
	minimum_required = 1
	role_name = "lone operative"
	fakeable = FALSE

/datum/round_event/ghost_role/operative/spawn_role()
	return spawn_operative()

/datum/round_event/ghost_role/operative/keeper
	role_name = "disk keeper"

/datum/round_event/ghost_role/operative/keeper/spawn_role()
	return spawn_operative(TRUE)

/datum/round_event/ghost_role/operative/proc/spawn_operative(keeper_force = FALSE, turf/last_spawn_loc = null)
	var/list/candidates = get_candidates(ROLE_OPERATIVE, null, ROLE_OPERATIVE)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc
	for(var/obj/effect/landmark/loneopspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc
	// Связанную пару разводим по разным точкам, если карта даёт выбор.
	if(keeper_force && last_spawn_loc && length(spawn_locs) > 1)
		spawn_locs -= last_spawn_loc

	if(!spawn_locs.len)
		return MAP_ERROR

	var/spawn_loc = pick(spawn_locs)

	var/mob/living/carbon/human/operative = new(spawn_loc)
	var/datum/preferences/A = new
	A.copy_to(operative)
	operative.dna.update_dna_identity()

	// GLOB.round_type, не master_mode: смена режима мидгеймом дописывает master_mode суффиксом
	// "(Changed Midgame)" и строковое сравнение с ROUNDTYPE_* умирает.
	var/datum/antagonist/nukeop/lone/antag_type = keeper_force ? /datum/antagonist/nukeop/lone/syndicate : /datum/antagonist/nukeop/lone
	if(GLOB.round_type == ROUNDTYPE_EXTENDED)
		antag_type = new /datum/antagonist/nukeop/lone/syndicate
		antag_type.nukeop_outfit = /datum/outfit/syndicate/lone/extended

	var/antag_name = initial(antag_type.name)
	var/datum/mind/Mind = new(selected.key)
	Mind.assigned_role = antag_name
	Mind.special_role = antag_name
	Mind.active = 1
	Mind.transfer_to(operative)

	Mind.add_antag_datum(antag_type)

	message_admins("[ADMIN_LOOKUPFLW(operative)] has been made into [antag_name] by an event.")
	log_game("[key_name(operative)] was spawned as a [antag_name] by an event.")
	spawned_mobs += operative
	// Light сохраняет историческую пару: сначала боевой Lone Operative, затем отдельный
	// опрос на защитника диска. Защитник не является самостоятельным кандидатом директора.
	if(should_spawn_linked_keeper(keeper_force, GLOB.round_type))
		addtimer(CALLBACK(src, PROC_REF(spawn_linked_keeper), get_turf(spawn_loc)), 10 SECONDS)
	return SUCCESSFUL_SPAWN

/// Чистый профильный гейт пары, вынесенный отдельно для сторожевого unit-теста.
/datum/round_event/ghost_role/operative/proc/should_spawn_linked_keeper(keeper_force, round_type)
	return !keeper_force && round_type == ROUNDTYPE_DYNAMIC_LIGHT

/// Вторая волна Light не тратит ещё один кошелёк и не ставит ещё одну паузу, но обязана
/// пройти обычный гост-опрос и попасть в живой intensity-трекинг под своим control.
/datum/round_event/ghost_role/operative/proc/spawn_linked_keeper(turf/last_spawn_loc)
	var/spawned_before = length(spawned_mobs)
	var/result = spawn_operative(TRUE, last_spawn_loc)
	if(result != SUCCESSFUL_SPAWN)
		message_admins("Связанный защитник диска после Lone Operative не появился: [result == NOT_ENOUGH_PLAYERS ? "нет желающих" : "ошибка карты"].")
		return
	var/list/linked_spawns = spawned_mobs.Copy(spawned_before + 1)
	var/datum/round_event_control/operative/keeper/keeper_control = locate() in SSdirector.event_controls()
	if(!keeper_control || !SSdirector.track_ghost_role_spawn(keeper_control, linked_spawns, budget_backed = FALSE))
		message_admins("Связанный защитник диска появился, но директор не смог поставить его на живой трекинг.")
		return
	keeper_control.occurrences++
	for(var/mob/spawned as anything in linked_spawns)
		announce_to_ghosts(spawned)
