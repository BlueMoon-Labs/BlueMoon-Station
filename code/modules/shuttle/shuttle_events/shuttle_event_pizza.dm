/datum/shuttle_event/simple_spawner/pizza_bombardment
	name = "Пиццедождь (доставка CentCom)"
	event_probability = 4
	activation_fraction = 0.18
	spawning_list = list(/obj/item/pizzabox/margherita = 1) // плейсхолдер; реальная доставка в spawn_movable
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 16
	spawns_per_spawn = 1
	/// «Бомбардируем» пиццами, пока не выберем столько сбросов на полёт.
	var/pizza_drops = 0
	var/max_pizza_drops = 16
	var/static/list/allowed_pizza_types

/datum/shuttle_event/simple_spawner/pizza_bombardment/get_type_to_spawn()
	return /obj/item/pizzabox/margherita

/datum/shuttle_event/simple_spawner/pizza_bombardment/spawn_movable(spawn_type)
	if(pizza_drops >= max_pizza_drops)
		return FALSE
	if(!allowed_pizza_types)
		allowed_pizza_types = subtypesof(/obj/item/pizzabox)
		allowed_pizza_types -= /obj/item/pizzabox/margherita/robo
		allowed_pizza_types -= /obj/item/pizzabox/bomb
		allowed_pizza_types -= /obj/item/pizzabox/infinite
	var/turf/T = get_spawn_turf()
	if(!T)
		return FALSE
	var/obj/structure/closet/supplypod/centcompod/pod = new()
	var/pizzatype = pick(allowed_pizza_types)
	new pizzatype(pod)
	pod.explosionSize = list(0, 0, 0, 0)
	new /obj/effect/pod_landingzone(T, pod)
	pizza_drops++
	return TRUE

/datum/shuttle_event/simple_spawner/pizza_bombardment/event_process()
	. = ..()
	if(!.)
		return
	if(pizza_drops >= max_pizza_drops)
		return SHUTTLE_EVENT_CLEAR
	return
