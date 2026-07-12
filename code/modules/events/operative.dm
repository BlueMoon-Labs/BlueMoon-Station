/datum/round_event_control/operative
	name = "Lone Operative"
	typepath = /datum/round_event/ghost_role/operative
	admin_only = TRUE
	max_occurrences = 1
	min_players = 30
	category = EVENT_CATEGORY_INVASION
	severity = DIRECTOR_SEVERITY_GHOST // admin_only, но форс-запуск обязан считаться антаг-нагрузкой
	cost = 15
	intensity = 20 // одиночка, но с ядерным риском
	description = "A single nuclear operative assaults the station."

// Мирный вариант по правилам проекта: на Extended и Dynamic Light одинокий оперативник
// появляется защитником Диска Ядерной Аутентификации, а не боевым раунд-эндером.
/datum/round_event_control/operative/keeper
	name = "Lone Operative (Disk Keeper)"
	typepath = /datum/round_event/ghost_role/operative/keeper
	admin_only = FALSE
	weight = 10
	min_players = 15 // Light предлагается на лоупопе; унаследованные 30 делали событие практически недоступным
	earliest_start = 30 MINUTES
	required_round_type = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)
	cost = 10
	intensity = 10 // защитник, а не угроза: мягкий вклад в гост-пул фоновых режимов
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

/datum/round_event/ghost_role/operative/proc/spawn_operative(keeper_force = FALSE)
	var/list/candidates = get_candidates(ROLE_OPERATIVE, null, ROLE_OPERATIVE)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc
	for(var/obj/effect/landmark/loneopspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc

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
	return SUCCESSFUL_SPAWN
