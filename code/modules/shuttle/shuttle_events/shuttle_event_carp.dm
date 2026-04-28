/// Carp pass by or through the shuttle during hyperspace (tg-style CARPTIDE)
/datum/shuttle_event/simple_spawner/carp
	name = "Косяк карпов (опасно!)"
	event_probability = 4
	activation_fraction = 0.2
	spawning_list = list(/mob/living/simple_animal/hostile/carp = 12, /mob/living/simple_animal/hostile/carp/megacarp = 3)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 20
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE

/datum/shuttle_event/simple_spawner/carp/friendly
	name = "Косяк карпов (безобидно)"
	event_probability = 3
	activation_fraction = 0.1
	spawning_list = list(/mob/living/simple_animal/hostile/carp/shuttle_passive = 1)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	/// Was 2 @ 100% every SS shuttle tick — hundreds of mobs per flight and MC stalls (DEFCON).
	spawns_per_spawn = 1
	spawn_probability_per_process = 35
	remove_from_list_when_spawned = FALSE
	var/hit_the_shuttle_chance = 40
	/// Stop spawning after this many carps; otherwise the event never ends and can freeze MC.
	var/spawns_done = 0
	var/max_spawns_total = 36

/datum/shuttle_event/simple_spawner/carp/friendly/event_process()
	if(spawns_done >= max_spawns_total)
		return SHUTTLE_EVENT_CLEAR
	return ..()

/datum/shuttle_event/simple_spawner/carp/friendly/spawn_movable(spawn_type)
	if(spawns_done >= max_spawns_total)
		return
	if(..(spawn_type))
		spawns_done++

/datum/shuttle_event/simple_spawner/carp/friendly/start_up_event(evacuation_duration)
	. = ..()
	// Spread picks so the school doesn't all share one turf / one row feel every tick.
	if(length(spawning_turfs_hit))
		shuffle_inplace(spawning_turfs_hit)
	if(length(spawning_turfs_miss))
		shuffle_inplace(spawning_turfs_miss)

/datum/shuttle_event/simple_spawner/carp/friendly/get_spawn_turf()
	var/list/L = prob(hit_the_shuttle_chance) ? spawning_turfs_hit : spawning_turfs_miss
	if(!length(L))
		L = spawning_turfs_hit + spawning_turfs_miss
	if(!length(L))
		return null
	return pick(L)
