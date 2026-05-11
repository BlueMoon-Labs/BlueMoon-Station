/datum/shuttle_event/simple_spawner/donk_swarm
	name = "Донк-флот (гипердоставка)"
	event_probability = 6
	activation_fraction = 0.15
	spawns_per_spawn = 2
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 30
	spawning_list = list(/obj/item/storage/box/donkpockets = 5)
	remove_from_list_when_spawned = FALSE
	self_destruct_when_empty = FALSE

/datum/shuttle_event/simple_spawner/soft_drink_spray
	name = "Газировка в потоке"
	event_probability = 7
	activation_fraction = 0.1
	spawns_per_spawn = 3
	spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE | SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 35
	spawning_list = list(
		/obj/item/reagent_containers/food/drinks/soda_cans/cola = 2,
		/obj/item/reagent_containers/food/drinks/soda_cans/space_up = 2,
		/obj/item/reagent_containers/food/drinks/soda_cans/dr_gibb = 2,
		/obj/item/reagent_containers/food/drinks/soda_cans/starkist = 1,
		/obj/item/reagent_containers/food/drinks/soda_cans/lemon_lime = 2,
	)
	remove_from_list_when_spawned = FALSE
	self_destruct_when_empty = FALSE

/datum/shuttle_event/simple_spawner/corgi_parade
	name = "Коргигидон"
	event_probability = 7
	activation_fraction = 0.12
	spawns_per_spawn = 1
	spawning_flags = SHUTTLE_EVENT_MISS_SHUTTLE | SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 20
	spawning_list = list(
		/mob/living/simple_animal/pet/dog/corgi = 3,
		/mob/living/simple_animal/pet/dog/corgi/puppy = 1,
	)
	remove_from_list_when_spawned = FALSE
	self_destruct_when_empty = FALSE
