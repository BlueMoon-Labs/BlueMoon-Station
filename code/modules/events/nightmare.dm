/datum/round_event_control/nightmare
	name = "Spawn Nightmare"
	typepath = /datum/round_event/ghost_role/nightmare
	max_occurrences = 2
	min_players = 25 // порог от больших серверов резал разнообразие на типичных 25-35: гост-пул сужался до метеора
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
	var/list/candidates = get_candidates(ROLE_ALIEN, null, ROLE_ALIEN)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick(candidates)

	var/datum/mind/player_mind = new /datum/mind(selected.key)
	player_mind.active = TRUE

	var/list/spawn_locs = list()
	for(var/X in GLOB.xeno_spawn)
		var/turf/T = X
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += T

	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/mob/living/carbon/human/S = new ((pick(spawn_locs)))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Nightmare"
	player_mind.special_role = "Nightmare"
	player_mind.add_antag_datum(/datum/antagonist/nightmare)
	S.set_species(/datum/species/shadow/nightmare)
	playsound(S, 'sound/magic/ethereal_exit.ogg', 50, 1, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Nightmare by an event.")
	log_game("[key_name(S)] was spawned as a Nightmare by an event.")
	spawned_mobs += S
	return SUCCESSFUL_SPAWN
