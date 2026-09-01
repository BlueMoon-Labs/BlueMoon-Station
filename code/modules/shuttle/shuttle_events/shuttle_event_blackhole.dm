/// Admin / traitor-adjacent singularity visuals — keep investigate quiet for shuttle transit.
/obj/singularity/gravitational/shuttle_event
	name = "гравитационная аномалия"
	desc = "Сенсоры фиксируют искажение метрики по курсу шаттла."
	anchored = FALSE
	move_self = TRUE
	dissipate = TRUE

/obj/singularity/gravitational/shuttle_event/admin_investigate_setup()
	return

/// Hyperspace drift uses Move(); default singulo turf checks block sliding toward the hull.
/obj/singularity/gravitational/shuttle_event/can_move(turf/T)
	if(istype(get_turf(src), /turf/open/space/transit))
		return TRUE
	return ..()

/// Sensors indicate a black hole's gravitational field — tg-style (normally admin-only roll).
/datum/shuttle_event/simple_spawner/black_hole
	name = "Чёрная дыра"
	event_probability = 2
	spawn_probability_per_process = 10
	activation_fraction = 0.35
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawning_list = list(/obj/singularity/gravitational/shuttle_event = 1)
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE

/datum/shuttle_event/simple_spawner/black_hole/get_spawn_turf()
	if(length(spawning_turfs_miss))
		return pick(spawning_turfs_miss)
	return ..()

/datum/shuttle_event/simple_spawner/black_hole/post_spawn(atom/movable/spawnee)
	. = ..()
	var/obj/singularity/gravitational/shuttle_event/singulo = spawnee
	if(!istype(singulo))
		return
	singulo.target = port
	if(singulo.energy < 200)
		singulo.energy = 200
		singulo.check_energy()

/datum/shuttle_event/simple_spawner/black_hole/adminbus
	name = "Чёрные дыры (много)"
	event_probability = 1
	spawn_probability_per_process = 50
	activation_fraction = 0.2
	spawning_list = list(/obj/singularity/gravitational/shuttle_event = 10)
	remove_from_list_when_spawned = TRUE
