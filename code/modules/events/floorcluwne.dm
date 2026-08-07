/// Вес события в Dynamic Light: охотник там допустим, но как крайняя редкость (базовый вес 10)
#define FLOOR_CLUWNE_LIGHT_WEIGHT 1

/datum/round_event_control/floor_cluwne
	name = "Floor Cluwne"
	typepath = /datum/round_event/floor_cluwne
	max_occurrences = 3
	min_players = 20
	weight = 10
	category = EVENT_CATEGORY_ANOMALIES
	severity = DIRECTOR_SEVERITY_MODERATE // одиночный мирный моб, не тянет на MAJOR из категории
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT) // только динамик: в Extended охотник за экипажем неуместен

/datum/round_event_control/floor_cluwne/get_weight(datum/director_signals/signals)
	if(GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT)
		return FLOOR_CLUWNE_LIGHT_WEIGHT
	return ..()

/datum/round_event/floor_cluwne/start()
	var/list/spawn_locs = list()
	for(var/X in GLOB.xeno_spawn)
		spawn_locs += X

	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/turf/T = get_turf(pick(spawn_locs))
	var/mob/living/simple_animal/hostile/floor_cluwne/S = new(T)
	playsound(S, 'sound/misc/bikehorn_creepy.ogg', 50, 1, -1)
	message_admins("A floor cluwne has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("A floor cluwne has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN

#undef FLOOR_CLUWNE_LIGHT_WEIGHT
