/// An event that runs while the emergency shuttle is on the reserved transit Z-level (hyperspace).
/datum/shuttle_event
	var/name = "shuttle event"
	var/event_probability = 50
	/// If FALSE, omitted from GLOB.admin_forceable_hyperspace_events (abstract parents).
	var/admin_forceable = TRUE
	var/active = FALSE
	/// Fraction of total flight duration before this activates (0 = start of flight)
	var/activation_fraction = 0
	var/activate_at
	var/obj/docking_port/mobile/port

/datum/shuttle_event/New(obj/docking_port/mobile/port)
	. = ..()
	src.port = port

/datum/shuttle_event/Destroy(force)
	port = null
	return ..()

/datum/shuttle_event/proc/start_up_event(evacuation_duration)
	if(!evacuation_duration)
		evacuation_duration = 1
	activate_at = world.time + evacuation_duration * activation_fraction

/// Called when the event begins affecting the shuttle
/datum/shuttle_event/proc/activate()
	return

/// Return SHUTTLE_EVENT_CLEAR to remove this event from the shuttle
/datum/shuttle_event/proc/event_process()
	if(!active)
		if(world.time < activate_at)
			return FALSE
		active = TRUE
		activate()
	return TRUE

/datum/shuttle_event/simple_spawner
	var/spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE | SHUTTLE_EVENT_HIT_SHUTTLE
	var/list/turf/spawning_turfs_hit
	var/list/turf/spawning_turfs_miss
	var/spawn_probability_per_process = 0
	var/spawns_per_spawn = 1
	var/list/spawning_list = list()
	var/remove_from_list_when_spawned = FALSE
	var/self_destruct_when_empty = FALSE
	/// If TRUE, empty spawning_list is allowed; use overridden get_type_to_spawn() instead of pickweight(spawning_list)
	var/dynamic_loot_spawns = FALSE

/datum/shuttle_event/simple_spawner/start_up_event(evacuation_duration)
	. = ..()
	if(!port)
		return
	generate_spawning_turfs(port.return_coords(), spawning_flags, port.preferred_direction)

/datum/shuttle_event/simple_spawner/proc/generate_spawning_turfs(list/bounding_coords, spawning_behaviour, direction)
	spawning_turfs_hit = list()
	spawning_turfs_miss = list()
	if(!length(bounding_coords))
		return
	var/list/step_dir
	var/list/target_corner
	var/list/spawn_offset

	if(bounding_coords[1] > bounding_coords[3])
		bounding_coords = list(bounding_coords[3], bounding_coords[4], bounding_coords[1], bounding_coords[2])

	switch(direction)
		if(NORTH)
			step_dir = list(1, 0)
			target_corner = list(bounding_coords[1], bounding_coords[2])
			spawn_offset = list(0, SHUTTLE_TRANSIT_BORDER)
		if(SOUTH)
			step_dir = list(-1, 0)
			target_corner = list(bounding_coords[3], bounding_coords[4])
			spawn_offset = list(0, -SHUTTLE_TRANSIT_BORDER)
		if(EAST)
			step_dir = list(0, 1)
			target_corner = list(bounding_coords[3], bounding_coords[4])
			spawn_offset = list(SHUTTLE_TRANSIT_BORDER, 0)
		if(WEST)
			step_dir = list(0, -1)
			target_corner = list(bounding_coords[1], bounding_coords[2])
			spawn_offset = list(-SHUTTLE_TRANSIT_BORDER, 0)
		else
			step_dir = list(1, 0)
			target_corner = list(bounding_coords[1], bounding_coords[2])
			spawn_offset = list(0, SHUTTLE_TRANSIT_BORDER)

	if(spawning_behaviour & SHUTTLE_EVENT_HIT_SHUTTLE)
		var/tile_amount = abs((direction == NORTH || direction == SOUTH) ? bounding_coords[1] - bounding_coords[3] : bounding_coords[2] - bounding_coords[4])
		// Pathological docking coords could make this huge and freeze MC during admin-forced start_up_event.
		tile_amount = min(tile_amount, 127)
		for(var/i in 0 to tile_amount)
			var/list/target_coords = list(target_corner[1] + step_dir[1] * i + spawn_offset[1], target_corner[2] + step_dir[2] * i + spawn_offset[2])
			var/turf/T = locate(target_coords[1], target_coords[2], port.z)
			if(T)
				spawning_turfs_hit += T
			if(!(i % 12))
				CHECK_TICK
	if(spawning_behaviour & SHUTTLE_EVENT_MISS_SHUTTLE)
		for(var/i in 1 to SHUTTLE_TRANSIT_BORDER)
			var/turf/T = locate(target_corner[1] - step_dir[1] * i + spawn_offset[1], target_corner[2] - step_dir[2] * i + spawn_offset[2], port.z)
			if(T)
				spawning_turfs_miss += T
			CHECK_TICK
		var/list/corner_delta = list(bounding_coords[3] - bounding_coords[1], bounding_coords[2] - bounding_coords[4])
		for(var/i in 1 to SHUTTLE_TRANSIT_BORDER)
			var/turf/T = locate(target_corner[1] + corner_delta[1] * step_dir[1] + step_dir[1] * i + spawn_offset[1], target_corner[2] + corner_delta[2] * step_dir[2] + step_dir[2] * i + spawn_offset[2], port.z)
			if(T)
				spawning_turfs_miss += T
			CHECK_TICK

/datum/shuttle_event/simple_spawner/event_process()
	. = ..()
	if(!.)
		return
	if(!length(spawning_list) && !dynamic_loot_spawns)
		if(self_destruct_when_empty)
			return SHUTTLE_EVENT_CLEAR
		return
	if(prob(spawn_probability_per_process))
		for(var/i in 1 to spawns_per_spawn)
			spawn_movable(get_type_to_spawn())
			CHECK_TICK // spawn_movable can still be heavy (mob Initialize); yield between spawns

/datum/shuttle_event/simple_spawner/proc/get_spawn_turf()
	var/list/pool = spawning_turfs_hit + spawning_turfs_miss
	if(!length(pool))
		return null
	return pick(pool)

/datum/shuttle_event/simple_spawner/proc/spawn_movable(spawn_type)
	if(!ispath(spawn_type))
		return FALSE
	var/turf/spawn_point = get_spawn_turf()
	if(!spawn_point)
		return FALSE
	post_spawn(new spawn_type(spawn_point))
	return TRUE

/datum/shuttle_event/simple_spawner/proc/get_type_to_spawn()
	. = pickweight(spawning_list)
	if(remove_from_list_when_spawned)
		spawning_list[.] -= 1
		if(spawning_list[.] < 1)
			spawning_list.Remove(.)

/datum/shuttle_event/simple_spawner/proc/post_spawn(atom/movable/spawnee)
	// Do NOT add TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT here: transit.dm and shuttle_cling treat it like
	// TRAIT_FREE_HYPERSPACE_MOVEMENT and skip/stop hyperspace drift — carp, humans, debris would pile up at the spawn edge.
	// Meteors/projectiles use anchored or their own motion; use TRAIT_FREE_HYPERSPACE_MOVEMENT there when needed.
	ADD_TRAIT(spawnee, TRAIT_DEL_ON_SPACE_DUMP, INNATE_TRAIT)
	// Defer cling: synchronous AddComponent in the same tick as SSshuttle.fire was stalling MC (DEFCON).
	if(ismovable(spawnee) && !spawnee.anchored && istype(get_turf(spawnee), /turf/open/space/transit))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(deferred_init_shuttle_cling_for_event), WEAKREF(spawnee)), 1)

/// Walkable turfs inside a mobile shuttle's registered areas (for station-dock ghost spawns).
/proc/get_mobile_shuttle_interior_turfs(obj/docking_port/mobile/port)
	var/list/turfs = list()
	if(!port?.shuttle_areas)
		return turfs
	for(var/area/shuttle/shuttle_area as anything in port.shuttle_areas)
		for(var/turf/open/T as anything in shuttle_area)
			if(T.density)
				continue
			turfs += T
	return turfs

/// Abstract parents keep /datum/shuttle_event's default name and are excluded from rolls/admin lists.
/proc/is_abstract_shuttle_event(datum/shuttle_event/event_type)
	var/datum/shuttle_event/base_type = /datum/shuttle_event
	return initial(event_type.name) == initial(base_type.name)

/// pickweight pool for one random hyperspace event per evacuation transit.
/proc/get_hyperspace_event_roll_weights()
	var/list/weights = list()
	for(var/datum/shuttle_event/event_type in subtypesof(/datum/shuttle_event))
		if(is_abstract_shuttle_event(event_type))
			continue
		var/weight = initial(event_type.event_probability)
		if(weight > 0)
			weights[event_type] = weight
	return weights

GLOBAL_LIST_INIT(admin_forceable_hyperspace_events, list())

/proc/get_admin_forceable_hyperspace_events()
	if(!length(GLOB.admin_forceable_hyperspace_events))
		GLOB.admin_forceable_hyperspace_events = collect_admin_forceable_hyperspace_events()
	return GLOB.admin_forceable_hyperspace_events

/proc/collect_admin_forceable_hyperspace_events()
	var/list/result = list()
	for(var/datum/shuttle_event/event_type in subtypesof(/datum/shuttle_event))
		if(!initial(event_type.admin_forceable))
			continue
		if(is_abstract_shuttle_event(event_type))
			continue
		result += event_type
	return result
