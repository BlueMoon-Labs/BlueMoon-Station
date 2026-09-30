#define PROB_MOUSE_SPAWN 98

SUBSYSTEM_DEF(minor_mapping)
	name = "Minor Mapping"
	init_order = INIT_ORDER_MINOR_MAPPING
	flags = SS_NO_FIRE

/datum/controller/subsystem/minor_mapping/Initialize(timeofday)
	trigger_migration(CONFIG_GET(number/mice_roundstart))
	// place_satchels()
	return ..()

/datum/controller/subsystem/minor_mapping/proc/trigger_migration(num_mice=10)
	var/list/exposed_wires = find_exposed_wires()

	var/mob/living/simple_animal/mouse/mouse
	var/turf/proposed_turf

	while((num_mice > 0) && exposed_wires.len)
		proposed_turf = pick_n_take(exposed_wires)
		if(prob(PROB_MOUSE_SPAWN))
			if(!mouse)
				mouse = new(proposed_turf)
			else
				mouse.forceMove(proposed_turf)
		// else
		// 	mouse = new /mob/living/simple_animal/hostile/regalrat/controlled(proposed_turf)
			if(mouse.environment_is_safe())
				num_mice -= 1
				mouse = null

// /datum/controller/subsystem/minor_mapping/proc/place_satchels(amount=10)
// 	var/list/turfs = find_satchel_suitable_turfs()

// 	while(turfs.len && amount > 0)
// 		var/turf/T = pick_n_take(turfs)
// 		var/obj/item/storage/backpack/satchel/flat/F = new(T)

// 		SEND_SIGNAL(F, COMSIG_OBJ_HIDE, T.intact)
// 		amount--

/proc/find_exposed_wires(list/z_levels = SSmapping.levels_by_trait(ZTRAIT_STATION))
	var/list/exposed_wires = list()
	var/list/checked_turfs = list()
	for(var/obj/structure/cable/cable as anything in GLOB.cable_list)
		var/turf/open/floor/plating/cable_turf = cable.loc
		if(!istype(cable_turf) || checked_turfs[cable_turf] || !(cable_turf.z in z_levels))
			continue
		checked_turfs[cable_turf] = TRUE
		if(!is_blocked_turf(cable_turf))
			exposed_wires += cable_turf

	return shuffle(exposed_wires)

// /proc/find_satchel_suitable_turfs()
// 	var/list/suitable = list()

// 	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
// 		for(var/t in block(locate(1,1,z), locate(world.maxx,world.maxy,z)))
// 			if(isfloorturf(t) && !isplatingturf(t))
// 				suitable += t

// 	return shuffle(suitable)

#undef PROB_MOUSE_SPAWN
