/datum/shuttle_event/simple_spawner/meteor
	spawning_list = list(/obj/effect/meteor/dust = 1)

/datum/shuttle_event/simple_spawner/meteor/post_spawn(atom/movable/spawnee)
	. = ..()
	ADD_TRAIT(spawnee, TRAIT_FREE_HYPERSPACE_MOVEMENT, INNATE_TRAIT)

/datum/shuttle_event/simple_spawner/meteor/spawn_movable(spawn_type)
	var/turf/spawn_turf = get_spawn_turf()
	if(!spawn_turf)
		return FALSE
	if(ispath(spawn_type, /obj/effect/meteor))
		var/turf/goal = get_edge_target_turf(spawn_turf, angle2dir(dir2angle(port.preferred_direction) + 180))
		post_spawn(new spawn_type(spawn_turf, goal))
	else
		post_spawn(new spawn_type(spawn_turf))
	return TRUE

/// Weak meteors — mostly miss the shuttle hull.
/datum/shuttle_event/simple_spawner/meteor/dust
	name = "Космическая пыль (почти безопасно)"
	event_probability = 2
	activation_fraction = 0.1
	spawn_probability_per_process = 100
	spawns_per_spawn = 5
	spawning_list = list(/obj/effect/meteor/dust = 1, /obj/effect/meteor/medium = 1)
	spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE | SHUTTLE_EVENT_HIT_SHUTTLE
	var/hit_the_shuttle_chance = 1

/datum/shuttle_event/simple_spawner/meteor/dust/get_spawn_turf()
	var/list/L = prob(hit_the_shuttle_chance) ? spawning_turfs_hit : spawning_turfs_miss
	if(!length(L))
		L = spawning_turfs_hit + spawning_turfs_miss
	if(!length(L))
		return null
	return pick(L)

/// Heavier meteors, only beside the shuttle (miss band).
/datum/shuttle_event/simple_spawner/meteor/safe
	name = "Метеорный поток (мимо шаттла)"
	event_probability = 5
	activation_fraction = 0.1
	spawn_probability_per_process = 100
	spawns_per_spawn = 6
	spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE
	spawning_list = list(
		/obj/effect/meteor/medium = 10,
		/obj/effect/meteor/big = 5,
		/obj/effect/meteor/flaming = 3,
		/obj/effect/meteor/irradiated = 3,
		/obj/effect/meteor/tunguska = 1,
	)

/datum/shuttle_event/simple_spawner/meteor/dust/meaty
	name = "Мясные метеоры"
	spawning_list = list(/obj/effect/meteor/meaty = 1)
	spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE | SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 1
	activation_fraction = 0.1
	spawn_probability_per_process = 100
	spawns_per_spawn = 3
	hit_the_shuttle_chance = 2
