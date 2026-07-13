#define WALL_RUST_PERCENT_CHANCE 15

SUBSYSTEM_DEF(decay)
	name = "Decay System"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_OVERLAY

	var/list/station_filter = list("Runtime Station", "MultiZ Debug", "Gateway Test")
	var/list/possible_turfs = list()
	var/severity_modifier = 1

/datum/controller/subsystem/decay/Initialize()
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

	do_wall_rust()

	return SS_INIT_SUCCESS

/datum/controller/subsystem/decay/proc/do_wall_rust()
	for(var/turf/closed/iterating_wall as anything in possible_turfs)
		if(HAS_TRAIT(iterating_wall, TRAIT_RUSTY))
			continue
		if(prob(WALL_RUST_PERCENT_CHANCE * severity_modifier))
			iterating_wall.AddElement(/datum/element/rust)

#undef WALL_RUST_PERCENT_CHANCE
