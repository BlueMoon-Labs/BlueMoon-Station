/proc/gateway_destination_name_for_z(z)
	var/datum/space_level/level = SSmapping.get_level(z)
	return level?.name || AWAY_MISSION_NAME

/proc/away_map_display_name(map_path)
	var/name = map_path
	var/slash = findtext(name, "/")
	while(slash)
		name = copytext(name, slash + 1)
		slash = findtext(name, "/")
	var/dot = findtext(name, ".dmm")
	if(dot)
		name = copytext(name, 1, dot)
	return name

/proc/createRandomZlevel(name = AWAY_MISSION_NAME, list/traits = list(ZTRAIT_AWAY = TRUE), list/potential_levels = GLOB.potential_away_levels)
	if(GLOB.random_zlevels_generated[name])
		stack_trace("[name] level already generated.")
		return
	if(!length(potential_levels))
		stack_trace("No potential [name] level to load has been found.")
		return

	var/start_time = REALTIMEOFDAY
	var/map = pick(potential_levels)
	if(name == AWAY_MISSION_NAME)
		name = away_map_display_name(map)
	if(!load_new_z_level(map, name, traits))
		INIT_ANNOUNCE("Failed to load [name]! map filepath: [map]!")
		return
	INIT_ANNOUNCE("Loaded [name] in [(REALTIMEOFDAY - start_time)/10]s!")
	GLOB.random_zlevels_generated[name] = TRUE

/proc/load_away_mission(mission_file, existing_z = null)
	var/datum/map_template/away_mission = new(mission_file)
	var/list/traits = list(ZTRAIT_AWAY = TRUE)
	var/z
	if(existing_z)
		z = existing_z
		traits[ZTRAIT_REEBE] = TRUE  // This will prevent the z-level from being reset
	else
		z = createRandomZlevel(traits = traits)
	away_mission.load(locate(1, 1, z), centered = FALSE)
	return z

/obj/effect/landmark/awaystart
	name = "away mission spawn"
	desc = "Randomly picked away mission spawn points."
	var/id
	var/delay = TRUE // If the generated destination should be delayed by configured gateway delay

/obj/effect/landmark/awaystart/Initialize(mapload)
	. = ..()
	var/turf/spawn_turf = get_turf(src)
	/// PACT siege maps use /datum/gateway_destination/point/pact_siege_battle instead.
	if(spawn_turf && is_pact_siege_level(spawn_turf.z))
		return
	var/datum/gateway_destination/point/current
	for(var/datum/gateway_destination/point/D in GLOB.gateway_destinations)
		if(D.id == id)
			current = D
	if(!current)
		current = new
		current.id = id
		if(delay)
			current.wait = CONFIG_GET(number/gateway_delay)
		GLOB.gateway_destinations += current
	if(!id)
		current.name = gateway_destination_name_for_z(spawn_turf.z)
	current.target_turfs += get_turf(src)
	sync_away_gateway_calibration_wait(spawn_turf.z)

/obj/effect/landmark/awaystart/nodelay
	delay = FALSE

/// Away /gateway/away destinations must respect the same calibration delay as awaystarts on that z-level.
/proc/sync_away_gateway_calibration_wait(z)
	if(!z || is_pact_siege_level(z))
		return
	var/wait = CONFIG_GET(number/gateway_delay)
	for(var/datum/gateway_destination/point/D as anything in GLOB.gateway_destinations)
		if(istype(D, /datum/gateway_destination/point/pact_siege_battle) || istype(D, /datum/gateway_destination/point/pact_siege_station_return))
			continue
		var/found = FALSE
		for(var/turf/T as anything in D.target_turfs)
			if(T?.z == z)
				wait = D.wait
				found = TRUE
				break
		if(found)
			break
	for(var/datum/gateway_destination/gateway/GD as anything in GLOB.gateway_destinations)
		if(!istype(GD, /datum/gateway_destination/gateway))
			continue
		var/obj/machinery/gateway/G = GD.target_gateway
		if(!G || G.z != z)
			continue
		GD.wait = wait

/proc/generateMapList(filename)
	. = list()
	var/list/Lines = world.file2list(filename)

	if(!Lines.len)
		return
	for (var/t in Lines)
		if (!t)
			continue

		t = trim(t)
		if (length(t) == 0)
			continue
		else if (t[1] == "#")
			continue

		var/pos = findtext(t, " ")
		var/name = null

		if (pos)
			name = lowertext(copytext(t, 1, pos))

		else
			name = lowertext(t)

		if (!name)
			continue

		. += t
