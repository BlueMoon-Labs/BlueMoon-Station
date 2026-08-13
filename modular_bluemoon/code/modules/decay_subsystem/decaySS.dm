/*
This is the decay subsystem that is run once at startup.
These procs are incredibly expensive and should only really be run once.
*/

#define WALL_RUST_PERCENT_CHANCE 15

#define FLOOR_DIRT_PERCENT_CHANCE 15
#define FLOOR_BLOOD_PERCENT_CHANCE 1
#define FLOOR_TILE_MISSING_PERCENT_CHANCE 1
#define FLOOR_STRUCTURE_PERCENT_CHANCE 1

SUBSYSTEM_DEF(decay)
	name = "Decay System"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_OVERLAY

	/// Maps that should not receive roundstart decay.
	var/list/station_filter = list("MultiZ Debug", "Gateway Test")
	var/list/possible_turfs = list()
	var/list/possible_areas = list()
	var/severity_modifier = 1

	/// Activation chance (%) per ssdecay_intensity config value (index 1-5).
	var/static/list/activation_chances = list(10, 32, 53, 75, 50)

/datum/controller/subsystem/decay/Initialize()
	. = ..()
	if(CONFIG_GET(flag/ssdecay_disabled))
		message_admins("SSDecay was disabled in config.")
		log_world("SSDecay was disabled in config.")
		return SS_INIT_NO_NEED

	if(SSmapping.config.map_name in station_filter)
		message_admins("SSDecay was disabled due to map filter.")
		log_world("SSDecay was disabled due to map filter.")
		return SS_INIT_NO_NEED

	var/configured_intensity = CONFIG_GET(number/ssdecay_intensity)
	configured_intensity = clamp(configured_intensity || 5, 1, 5)

	var/activation_chance = activation_chances[configured_intensity]
	if(!prob(activation_chance))
		message_admins("SSDecay did not activate this round (rolled against [activation_chance]% chance for intensity [configured_intensity]).")
		log_world("SSDecay did not activate this round (rolled against [activation_chance]% chance for intensity [configured_intensity]).")
		return SS_INIT_NO_NEED

	for(var/area/iterating_area as anything in GLOB.all_areas)
		if(!is_station_level(iterating_area.z))
			continue
		possible_areas += iterating_area
		for(var/turf/area_turf as anything in iterating_area)
			if(!(area_turf.flags_1 & CAN_BE_DIRTY_1))
				continue
			if(!istype(area_turf, /turf/open/floor) && !istype(area_turf, /turf/closed))
				continue
			possible_turfs += area_turf

	if(!length(possible_turfs))
		message_admins("SSDecay had no possible turfs to use.")
		log_world("SSDecay had no possible turfs to use.")
		return SS_INIT_NO_NEED

	severity_modifier = configured_intensity
	if(severity_modifier == 5)
		severity_modifier = rand(1, 4)

	message_admins("SSDecay activated with severity modifier [severity_modifier] (config intensity [configured_intensity], activation roll [activation_chance]%).")
	log_world("SSDecay activated with severity modifier [severity_modifier] (config intensity [configured_intensity], activation roll [activation_chance]%).")

	do_common()
	do_maintenance()

	return SS_INIT_SUCCESS

/// Structural decay across the station — rusted walls and missing floor tiles.
/datum/controller/subsystem/decay/proc/do_common()
	for(var/turf/open/floor/iterating_floor in possible_turfs)
		if(iterating_floor.can_ssdecay_break())
			if(prob(FLOOR_TILE_MISSING_PERCENT_CHANCE * severity_modifier) && prob(60))
				iterating_floor.break_tile_to_plating()

		if(prob(FLOOR_DIRT_PERCENT_CHANCE * severity_modifier))
			try_spawn_decay_dirt(iterating_floor)

		if(prob(FLOOR_DIRT_PERCENT_CHANCE * severity_modifier))
			try_spawn_decay_dirt(iterating_floor)

	for(var/turf/closed/iterating_wall in possible_turfs)
		if(istype(iterating_wall, /turf/closed/indestructible))
			continue
		if(istype(iterating_wall, /turf/closed/mineral))
			continue
		if(istype(iterating_wall, /turf/closed/wall/rust) || istype(iterating_wall, /turf/closed/wall/r_wall/rust))
			continue
		if(HAS_TRAIT(iterating_wall, TRAIT_RUSTY))
			continue
		if(prob(WALL_RUST_PERCENT_CHANCE * severity_modifier))
			iterating_wall.AddElement(/datum/element/rust)

/// Cosmetic decay — blood and cobwebs only in maintenance tunnels.
/datum/controller/subsystem/decay/proc/do_maintenance()
	for(var/area/iterating_area as anything in possible_areas)
		if(!istype(iterating_area, /area/maintenance))
			continue
		var/area/maintenance/iterating_maintenance = iterating_area
		if(iterating_maintenance.sound_environment != SOUND_AREA_TUNNEL_ENCLOSED)
			continue
		for(var/turf/open/floor/iterating_floor in iterating_maintenance)
			if(!(iterating_floor.flags_1 & CAN_BE_DIRTY_1))
				continue
			if(isspaceturf(iterating_floor) || isgroundlessturf(iterating_floor))
				continue
			if(get_area(iterating_floor) != iterating_maintenance)
				continue

			if(prob(FLOOR_BLOOD_PERCENT_CHANCE * severity_modifier))
				var/obj/effect/decal/cleanable/blood/old/spawned_blood = new(iterating_floor)
				if(!iterating_floor.Enter(spawned_blood))
					qdel(spawned_blood)

			if(prob(FLOOR_STRUCTURE_PERCENT_CHANCE * severity_modifier))
				var/obj/structure/spider/stickyweb/spawned_web = new(iterating_floor)
				if(!iterating_floor.Enter(spawned_web))
					qdel(spawned_web)

			if(prob(FLOOR_STRUCTURE_PERCENT_CHANCE * severity_modifier))
				var/obj/structure/barricade/wooden/spawned_barricade = new(iterating_floor)
				if(!iterating_floor.Enter(spawned_barricade))
					qdel(spawned_barricade)

/datum/controller/subsystem/decay/proc/try_spawn_decay_dirt(turf/open/floor/floor_turf)
	if(!floor_turf || QDELETED(floor_turf))
		return
	if(!(floor_turf.flags_1 & CAN_BE_DIRTY_1))
		return
	if(isspaceturf(floor_turf) || isgroundlessturf(floor_turf))
		return
	if(locate(/obj/effect/decal/cleanable/dirt) in floor_turf)
		return
	new /obj/effect/decal/cleanable/dirt(floor_turf)

#undef WALL_RUST_PERCENT_CHANCE
#undef FLOOR_DIRT_PERCENT_CHANCE
#undef FLOOR_BLOOD_PERCENT_CHANCE
#undef FLOOR_TILE_MISSING_PERCENT_CHANCE
#undef FLOOR_STRUCTURE_PERCENT_CHANCE
