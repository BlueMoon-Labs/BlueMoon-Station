
/proc/createRandomZlevel(name = AWAY_MISSION_NAME, list/traits = list(ZTRAIT_AWAY = TRUE), list/potential_levels = GLOB.potential_away_levels)
	if(GLOB.random_zlevels_generated[name])
		stack_trace("[name] level already generated.")
		return
	if(!length(potential_levels))
		stack_trace("No potential [name] level to load has been found.")
		return

	var/start_time = REALTIMEOFDAY
	var/map = pick(potential_levels)
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
	current.target_turfs += get_turf(src)

/obj/effect/landmark/awaystart/nodelay
	delay = FALSE

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
