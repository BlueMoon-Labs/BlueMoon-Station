/*
This is the decay subsystem that is run once at startup.
These procs are incredibly expensive and should only really be run once.
*/

#define WALL_RUST_PERCENT_CHANCE 15

#define FLOOR_DIRT_PERCENT_CHANCE 15
#define FLOOR_BLOOD_PERCENT_CHANCE 1
#define FLOOR_TILE_MISSING_PERCENT_CHANCE 1
#define FLOOR_COBWEB_PERCENT_CHANCE 1

SUBSYSTEM_DEF(decay)
	name = "Decay System"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_OVERLAY

	/// Maps that should not receive roundstart decay.
	var/list/station_filter = list("MultiZ Debug", "Gateway Test")
	var/list/possible_turfs = list()
	var/list/possible_areas = list()
	var/severity_modifier = 1

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

	for(var/area/iterating_area as anything in GLOB.all_areas)
		if(!is_station_level(iterating_area.z))
			continue
		possible_areas += iterating_area
		for(var/turf/area_turf as anything in iterating_area)
			if(!(area_turf.flags_1 & CAN_BE_DIRTY_1))
				continue
			possible_turfs += area_turf

	if(!length(possible_turfs))
		message_admins("SSDecay had no possible turfs to use.")
		log_world("SSDecay had no possible turfs to use.")
		return SS_INIT_NO_NEED

	severity_modifier = CONFIG_GET(number/ssdecay_intensity)
	if(!severity_modifier || severity_modifier == 5)
		severity_modifier = rand(1, 4)

	message_admins("SSDecay severity modifier set to [severity_modifier]")
	log_world("SSDecay severity modifier set to [severity_modifier]")

	do_common()
	do_maintenance()

	return SS_INIT_SUCCESS

/datum/controller/subsystem/decay/proc/can_decay_break_floor(turf/open/floor/floor_turf)
	if(istype(floor_turf, /turf/open/floor/plating) || istype(floor_turf, /turf/open/floor/glass))
		return FALSE
	return TRUE

/// Structural decay across the station — rusted walls and missing floor tiles.
/datum/controller/subsystem/decay/proc/do_common()
	for(var/turf/iterating_turf as anything in possible_turfs)
		if(!isopenturf(iterating_turf))
			continue
		var/turf/open/floor/iterating_floor = iterating_turf
		if(can_decay_break_floor(iterating_floor))
			if(prob(FLOOR_TILE_MISSING_PERCENT_CHANCE * severity_modifier) && prob(60))
				iterating_floor.break_tile_to_plating()

	for(var/turf/iterating_turf as anything in possible_turfs)
		if(!isclosedturf(iterating_turf))
			continue
		var/turf/closed/iterating_wall = iterating_turf
		if(HAS_TRAIT(iterating_wall, TRAIT_RUSTY))
			continue
		if(prob(WALL_RUST_PERCENT_CHANCE * severity_modifier))
			iterating_wall.AddElement(/datum/element/rust)

/// Cosmetic decay — dirt, blood, and cobwebs only in maintenance tunnels.
/datum/controller/subsystem/decay/proc/do_maintenance()
	for(var/area/maintenance/iterating_maintenance as anything in possible_areas)
		for(var/turf/open/iterating_floor as anything in iterating_maintenance)
			if(prob(FLOOR_DIRT_PERCENT_CHANCE * severity_modifier))
				new /obj/effect/decal/cleanable/dirt(iterating_floor)

			if(prob(FLOOR_DIRT_PERCENT_CHANCE * severity_modifier))
				new /obj/effect/decal/cleanable/dirt(iterating_floor)

			if(prob(FLOOR_BLOOD_PERCENT_CHANCE * severity_modifier))
				var/obj/effect/decal/cleanable/blood/old/spawned_blood = new(iterating_floor)
				if(!iterating_floor.Enter(spawned_blood))
					qdel(spawned_blood)

			if(prob(FLOOR_COBWEB_PERCENT_CHANCE * severity_modifier))
				var/obj/structure/spider/stickyweb/spawned_web = new(iterating_floor)
				if(!iterating_floor.Enter(spawned_web))
					qdel(spawned_web)

#undef WALL_RUST_PERCENT_CHANCE
#undef FLOOR_DIRT_PERCENT_CHANCE
#undef FLOOR_BLOOD_PERCENT_CHANCE
#undef FLOOR_TILE_MISSING_PERCENT_CHANCE
#undef FLOOR_COBWEB_PERCENT_CHANCE
