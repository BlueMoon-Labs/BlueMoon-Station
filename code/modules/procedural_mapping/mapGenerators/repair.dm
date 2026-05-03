/datum/mapGeneratorModule/bottomLayer/repairFloorPlasteel
	spawnableTurfs = list(/turf/open/floor/plating = 100)
	var/ignore_wall = FALSE
	allowAtomsOnSpace = TRUE

/datum/mapGeneratorModule/bottomLayer/repairFloorPlasteel/place(turf/T)
	if(isclosedturf(T) && !ignore_wall)
		return FALSE
	return ..()

/datum/mapGeneratorModule/bottomLayer/repairFloorPlasteel/flatten
	ignore_wall = TRUE

/datum/mapGeneratorModule/border/normalWalls
	spawnableAtoms = list()
	spawnableTurfs = list(/turf/closed/wall = 100)
	allowAtomsOnSpace = TRUE

/datum/mapGeneratorModule/reload_station_map/generate()
	if(!istype(mother, /datum/mapGenerator/repair/reload_station_map))
		return FALSE
	var/datum/mapGenerator/repair/reload_station_map/reload_generator = mother
	return reload_generator.run_reload_phase()

/datum/mapGenerator/repair
	modules = list(/datum/mapGeneratorModule/bottomLayer/repairFloorPlasteel,
	/datum/mapGeneratorModule/bottomLayer/repressurize)
	buildmode_name = "Repair: Floor"

/datum/mapGenerator/repair/delete_walls
	modules = list(/datum/mapGeneratorModule/bottomLayer/repairFloorPlasteel/flatten,
	/datum/mapGeneratorModule/bottomLayer/repressurize)
	buildmode_name = "Repair: Floor: Flatten Walls"

/datum/mapGenerator/repair/enclose_room
	modules = list(/datum/mapGeneratorModule/bottomLayer/repairFloorPlasteel/flatten,
	/datum/mapGeneratorModule/border/normalWalls,
	/datum/mapGeneratorModule/bottomLayer/repressurize)
	buildmode_name = "Repair: Generate Aired Room"

/datum/mapGenerator/repair/reload_station_map
	modules = list(/datum/mapGeneratorModule/bottomLayer/massdelete/no_delete_mobs)
	var/x_low = 0
	var/x_high = 0
	var/y_low = 0
	var/y_high = 0
	var/z = 0
	var/cleanload = FALSE
	var/datum/mapGeneratorModule/reload_station_map/loader
	var/tmp/last_reload_succeeded = null
	buildmode_name = "Repair: Reload Block \[DO NOT USE\]"

/datum/mapGenerator/repair/reload_station_map/clean
	buildmode_name = "Repair: Reload Block - Mass Delete"
	cleanload = TRUE

/datum/mapGenerator/repair/reload_station_map/clean/in_place
	modules = list(/datum/mapGeneratorModule/bottomLayer/massdelete/regeneration_delete)
	buildmode_name = "Repair: Reload Block - Mass Delete - In Place"

/datum/mapGenerator/repair/reload_station_map/defineRegion(turf/start, turf/end, replace = 0)
	. = ..()
	if(!is_station_level(start.z) || !is_station_level(end.z))
		return
	x_low = min(start.x, end.x)
	y_low = min(start.y, end.y)
	x_high = max(start.x, end.x)
	y_high = max(start.y, end.y)
	z = SSmapping.station_start

/datum/mapGenerator/repair/reload_station_map/proc/run_delete_phase(run_clean = cleanload)
	if(!run_clean)
		return TRUE
	for(var/datum/mapGeneratorModule/module as anything in modules)
		if(QDELETED(module))
			continue
		module.sync(src)
		module.generate()
	return TRUE

/datum/mapGenerator/repair/reload_station_map/proc/run_reload_phase()
	// This is kind of finicky on multi-Z maps but the reader would need to be
	// changed to allow Z cropping and that's a mess
	var/z_offset = SSmapping.station_start
	var/list/bounds
	for(var/path in SSmapping.config.GetFullMapPaths())
		var/datum/parsed_map/parsed = load_map(file(path), 1, 1, z_offset, orientation = SSmapping.config.orientation, cropMap = TRUE, x_lower = x_low, y_lower = y_low, x_upper = x_high, y_upper = y_high)
		if(!parsed?.bounds)
			return FALSE
		bounds = parsed.bounds
		z_offset += bounds[MAP_MAXZ] - bounds[MAP_MINZ] + 1

	var/list/obj/machinery/atmospherics/atmos_machines = list()
	var/list/obj/structure/cable/cables = list()
	var/list/atom/atoms = list()
	var/list/reloaded_turfs = list()

	repopulate_sorted_areas()

	var/turf/bottom_left = locate(bounds[MAP_MINX], bounds[MAP_MINY], SSmapping.station_start)
	var/turf/top_right = locate(bounds[MAP_MAXX], bounds[MAP_MAXY], z_offset - 1)
	if(!bottom_left || !top_right)
		return FALSE

	for(var/turf/B as anything in block(bottom_left, top_right))
		reloaded_turfs += B
		atoms += B
		B.assemble_baseturfs(B.type)
		for(var/atom/A as anything in B)
			atoms += A
			if(istype(A, /obj/structure/cable))
				cables += A
				continue
			if(istype(A, /obj/machinery/atmospherics))
				atmos_machines += A

	SSatoms.InitializeAtoms(atoms)
	SSmachines.setup_template_powernets(cables)
	SSair.setup_template_machinery(atmos_machines)
	// Atom init above can ChangeTurf (late-load overlays, wall-on-plating, atmos turf
	// swaps, etc.), which replaces the turf datum at that coord. Re-resolve via
	// locate() so the lighting rebuild runs on the live turf, not a gc'd ref.
	var/list/live_reloaded_turfs = list()
	for(var/turf/T as anything in reloaded_turfs)
		var/turf/current = locate(T.x, T.y, T.z)
		if(current)
			live_reloaded_turfs += current
	for(var/turf/T as anything in live_reloaded_turfs)
		T.recalc_atom_opacity()
		T.reconsider_lights()
		// load_map/ChangeTurf usually transfers the existing overlay, but some
		// real map layouts can still leave a dynamic-lighting turf without one.
		if(!T.lighting_object)
			T.lighting_build_overlay()
		if(T.lighting_object)
			GLOB.lighting_update_blends |= T.lighting_object
			if(!T.lighting_object.needs_update)
				T.lighting_object.needs_update = TRUE
				GLOB.lighting_update_objects += T.lighting_object
	return TRUE

GLOBAL_VAR_INIT(reloading_map, FALSE)

/datum/mapGenerator/repair/reload_station_map/generate(clean = cleanload)
	if(!loader)
		loader = new
	syncModules()
	loader.sync(src)
	if(GLOB.reloading_map || !map.len)
		return FALSE
	last_reload_succeeded = null
	GLOB.reloading_map = TRUE
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/mapGenerator/repair/reload_station_map, run_repair_reload), clean)
	return TRUE

/datum/mapGenerator/repair/reload_station_map/proc/run_repair_reload(run_clean = cleanload)
	var/succeeded = FALSE
	if(loader)
		loader.sync(src)
	syncModules()
	if(run_delete_phase(run_clean))
		if(loader)
			succeeded = loader.generate()
	last_reload_succeeded = succeeded
	if(!succeeded)
		log_game("Repair reload failed for [type] at ([x_low], [y_low], [z]) to ([x_high], [y_high], [z])")
	GLOB.reloading_map = FALSE
	return succeeded
