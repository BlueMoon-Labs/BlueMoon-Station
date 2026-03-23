/proc/create_all_lighting_objects()
	SSlighting.init_in_progress = TRUE

	// Build set of z-levels to skip (reserved/transit/mining — deferred until player visits)
	var/list/skip_z = list()
	if(SSmapping?.initialized)
		for(var/datum/space_level/level as anything in SSmapping.z_list)
			if(level.traits[ZTRAIT_RESERVED] || level.traits[ZTRAIT_MINING])
				skip_z["[level.z_value]"] = TRUE

	for(var/area/A in world)
		if(!IS_DYNAMIC_LIGHTING(A))
			continue

		for(var/turf/T in A)
			if(!IS_DYNAMIC_LIGHTING(T))
				continue
			// Skip reserved z-levels — will be initialized on demand
			if(skip_z["[T.z]"])
				continue

			new /atom/movable/lighting_object(T)
			CHECK_TICK
		CHECK_TICK

	// Process deferred starlight (deduplicated via assoc list keys)
	for(var/turf/open/space/S as anything in GLOB.lighting_deferred_starlight)
		S.update_starlight()
		CHECK_TICK
	GLOB.lighting_deferred_starlight.Cut()
	SSlighting.init_in_progress = FALSE

	// Batch process all queued light sources directly during init
	// This is faster than going through the subsystem fire() loop:
	// no adaptive cap, no queue overhead, no animate() — instant lighting
	for(var/datum/light_source/L as anything in GLOB.lighting_update_lights)
		if(!QDELETED(L))
			L.update_corners()
			L.needs_update = LIGHTING_NO_UPDATE
		CHECK_TICK
	GLOB.lighting_update_lights.Cut()

	// Process corners
	for(var/datum/lighting_corner/C as anything in GLOB.lighting_update_corners)
		C.update_objects()
		C.needs_update = FALSE
		CHECK_TICK
	GLOB.lighting_update_corners.Cut()

	// Process lighting objects — no animation during init (map appears instantly lit)
	for(var/atom/movable/lighting_object/O as anything in GLOB.lighting_update_objects)
		if(!QDELETED(O))
			O.update(use_animate = FALSE)
			O.needs_update = FALSE
		CHECK_TICK
	GLOB.lighting_update_objects.Cut()

	// Mark initialized z-levels and queue deferred ones for background init
	if(SSmapping?.initialized)
		SSlighting.bg_queued_zlevels = list()
		for(var/datum/space_level/level as anything in SSmapping.z_list)
			if(!skip_z["[level.z_value]"])
				level.lighting_initialized = TRUE
			else
				SSlighting.bg_queued_zlevels += level.z_value

/// Creates lighting infrastructure for a single z-level on demand (synchronous fallback).
/// Called when a player enters a z-level before background init reaches it.
/proc/create_lighting_for_zlevel(z_level)
	var/datum/space_level/level = SSmapping.get_level(z_level)
	if(level.lighting_initialized)
		return
	level.lighting_initialized = TRUE
	// Cancel background init if it was working on this z-level
	if(SSlighting.bg_current_zlevel == z_level)
		SSlighting.bg_current_zlevel = 0
		SSlighting.bg_phase = 0
		SSlighting.bg_turfs = null
		SSlighting.bg_turf_index = 0
	else if(SSlighting.bg_queued_zlevels)
		SSlighting.bg_queued_zlevels -= z_level
	log_world("## LIGHTING: On-demand init for z-level [z_level] ([level.name]) (background preempted)")

	SSlighting.init_in_progress = TRUE

	// Phase 0: Create lighting objects FIRST — corners must be active before sources process
	// Objects make corners active; without them, update_corners() stores effect_str[C]=0 and skips APPLY_CORNER
	var/list/zlevel_turfs = block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level))
	for(var/turf/T as anything in zlevel_turfs)
		var/area/A = T.loc
		if(!IS_DYNAMIC_LIGHTING(A))
			continue
		if(!IS_DYNAMIC_LIGHTING(T))
			continue
		if(T.lighting_object)
			continue
		new /atom/movable/lighting_object(T)
		// Activate corners created during init with active=FALSE (no objects existed then)
		if(T.lighting_corners_initialised)
			if(T.lc_topright) T.lc_topright.active = TRUE
			if(T.lc_bottomright) T.lc_bottomright.active = TRUE
			if(T.lc_bottomleft) T.lc_bottomleft.active = TRUE
			if(T.lc_topleft) T.lc_topleft.active = TRUE
		CHECK_TICK

	SSlighting.init_in_progress = FALSE

	// Phase 1: Create deferred light sources — objects exist now, corners are active
	// Sources get queued to GLOB.lighting_update_lights; fire() processes them with active corners
	var/list/remaining_atoms = list()
	for(var/atom/A as anything in GLOB.lighting_deferred_atoms)
		if(QDELETED(A))
			continue
		var/turf/T = get_turf(A)
		if(T?.z == z_level)
			A.update_light()
		else
			remaining_atoms += A
		CHECK_TICK
	GLOB.lighting_deferred_atoms = remaining_atoms

	// Phase 2: Queue deferred starlight for fire() Phase -1 instead of processing synchronously
	var/list/remaining_starlight = list()
	for(var/turf/open/space/S in GLOB.lighting_deferred_starlight)
		if(S.z == z_level)
			GLOB.lighting_starlight_queue |= S
		else
			remaining_starlight[S] = TRUE
		CHECK_TICK
	GLOB.lighting_deferred_starlight = remaining_starlight
	// NO batch processing here — SSlighting fire() handles queued lights/corners/objects
	// gradually through its adaptive cap (40-200 sources/tick), preventing server freeze.
	// Phase 0 sources are already in GLOB.lighting_update_lights from their constructor.
	// Starlight sources will be created by fire() Phase -1 from GLOB.lighting_starlight_queue.
