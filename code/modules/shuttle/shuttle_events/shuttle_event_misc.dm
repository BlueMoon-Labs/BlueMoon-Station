/// Random maintenance junk drifting past the shuttle
/datum/shuttle_event/simple_spawner/maintenance
	name = "Вещи из технических тоннелей"
	event_probability = 4
	activation_fraction = 0.1
	spawning_list = list()
	dynamic_loot_spawns = TRUE
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 22
	spawns_per_spawn = 2

/datum/shuttle_event/simple_spawner/maintenance/get_type_to_spawn()
	for(var/attempts in 1 to 32)
		var/picked = pickweight(GLOB.maintenance_loot)
		if(picked == "")
			continue
		if(!ispath(picked))
			continue
		if(ispath(picked, /obj/effect/spawner))
			continue
		return picked
	return /obj/item/cigbutt

/datum/shuttle_event/simple_spawner/italian
	name = "Итальянский шторм"
	event_probability = 5
	activation_fraction = 0.12
	spawns_per_spawn = 2
	spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE | SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 24
	spawning_list = list(
		/obj/item/reagent_containers/food/snacks/boiledspaghetti = 4,
		/obj/item/reagent_containers/food/snacks/meatball = 3,
		/obj/item/reagent_containers/food/snacks/meatballspaghetti = 3,
		/obj/item/reagent_containers/food/snacks/pastatomato = 2,
		/obj/item/pizzabox/margherita = 1,
		/obj/item/pizzabox/mushroom = 1,
		/obj/item/pizzabox/meat = 1,
	)
	remove_from_list_when_spawned = FALSE
	self_destruct_when_empty = FALSE
