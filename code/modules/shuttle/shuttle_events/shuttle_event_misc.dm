/// Random maintenance junk drifting past the shuttle
/datum/shuttle_event/simple_spawner/maintenance
	name = "Обломки техтоннелей"
	event_probability = 3
	activation_fraction = 0.1
	spawning_list = list()
	dynamic_loot_spawns = TRUE
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 100
	spawns_per_spawn = 2

/datum/shuttle_event/simple_spawner/maintenance/get_type_to_spawn()
	var/list/spawn_list = GLOB.maintenance_loot
	while(islist(spawn_list))
		spawn_list = pickweight(spawn_list)
	return spawn_list
