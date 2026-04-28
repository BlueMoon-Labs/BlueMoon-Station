/// Admin / traitor-adjacent singularity visuals — keep investigate quiet for shuttle transit.
/obj/singularity/gravitational/shuttle_event
	name = "гравитационная аномалия"
	desc = "Сенсоры фиксируют искажение метрики по курсу шаттла."
	anchored = FALSE
	contained = TRUE
	move_self = FALSE
	dissipate = TRUE
	dissipate_strength = 5

/obj/singularity/gravitational/shuttle_event/admin_investigate_setup()
	return

/// Sensors indicate a black hole's gravitational field — tg-style (normally admin-only roll).
/datum/shuttle_event/simple_spawner/black_hole
	name = "Чёрная дыра"
	event_probability = 0
	spawn_probability_per_process = 10
	activation_fraction = 0.35
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	spawning_list = list(/obj/singularity/gravitational/shuttle_event = 1)
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE

/datum/shuttle_event/simple_spawner/black_hole/adminbus
	name = "Чёрные дыры (много)"
	spawn_probability_per_process = 50
	activation_fraction = 0.2
	spawning_list = list(/obj/singularity/gravitational/shuttle_event = 10)
	remove_from_list_when_spawned = TRUE
