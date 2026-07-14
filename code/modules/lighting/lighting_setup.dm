/// Drains the three lighting work queues (sources -> corners -> objects) synchronously, in order.
/// Each queue is claimed atomically (Copy + Cut with no yield between) and processed from the private
/// snapshot. This is interleave-safe: the drain sleeps in CHECK_TICK on an async stack, and a
/// concurrent SSlighting.fire() (or second drain) only ever sees entries it owns - unlike an
/// index/prefix-cut over the SHARED list, where a fire() Cut during the yield shifts elements under
/// the saved cursor and the closing Cut discards sources nobody processed (needs_update stays
/// non-NO_UPDATE, so the EFFECT_UPDATE re-append guard then refuses to re-enqueue them - permanently
/// stale lights). A source dirtied DURING the drain either sits later in the snapshot (we process it)
/// or re-enters the live queue for fire() (its needs_update was already reset). Each queue fully
/// drains before the next is claimed, so the cascade lights->corners->objects is covered.
/proc/drain_lighting_queues_snapshot()
	if(GLOB.lighting_update_lights.len)
		var/list/pending_sources = GLOB.lighting_update_lights.Copy()
		GLOB.lighting_update_lights.Cut()
		for(var/datum/light_source/queued_source as anything in pending_sources)
			if(!QDELETED(queued_source))
				queued_source.update_corners()
				queued_source.needs_update = LIGHTING_NO_UPDATE
			CHECK_TICK

	if(GLOB.lighting_update_corners.len)
		var/list/pending_corners = GLOB.lighting_update_corners.Copy()
		GLOB.lighting_update_corners.Cut()
		for(var/datum/lighting_corner/queued_corner as anything in pending_corners)
			queued_corner.update_objects()
			queued_corner.needs_update = FALSE
			CHECK_TICK

	if(GLOB.lighting_update_objects.len)
		var/list/pending_objects = GLOB.lighting_update_objects.Copy()
		GLOB.lighting_update_objects.Cut()
		for(var/atom/movable/lighting_object/queued_object as anything in pending_objects)
			if(!QDELETED(queued_object))
				queued_object.update(use_animate = FALSE)
				queued_object.needs_update = FALSE
			CHECK_TICK

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

	// Batch process all queued sources/corners/objects directly during init — instant lighting, no
	// adaptive cap or animate(). Prefix-cut inside the helper keeps any cascade tail dirtied during a
	// CHECK_TICK yield in the queue for SSlighting.fire() instead of blanket-discarding it.
	drain_lighting_queues_snapshot()

	// Mark initialized z-levels and queue deferred ones for background init
	if(SSmapping?.initialized)
		SSlighting.bg_queued_zlevels = list()
		for(var/datum/space_level/level as anything in SSmapping.z_list)
			if(!skip_z["[level.z_value]"])
				level.lighting_initialized = TRUE
			else
				SSlighting.bg_queued_zlevels += level.z_value

/// TRUE if any parked deferred light atom still belongs to z_level. An interrupted on-demand init
/// can leave the level flagged lighting_initialized with its sources never flushed; this lets
/// create_lighting_for_zlevel detect and recover that stuck state instead of staying black forever.
/proc/zlevel_has_deferred_lighting(z_level)
	for(var/atom/deferred_atom as anything in GLOB.lighting_deferred_atoms)
		if(QDELETED(deferred_atom))
			continue
		var/turf/atom_turf = get_turf(deferred_atom)
		if(atom_turf?.z == z_level)
			return TRUE
	return FALSE

/// Synchronous gate shared by /mob/living and /mob/dead update_z: should a client entering new_z
/// schedule on-demand lighting init? TRUE only when lighting/mapping are ready, no bulk op owns
/// lighting, and the level exists but is not yet initialized. Bounds-guards the z_list index instead
/// of SSmapping.get_level() (which CRASHes on an unmanaged z).
/proc/should_ondemand_init_zlevel(new_z)
	if(!new_z || !SSlighting?.initialized || !SSmapping?.initialized || GLOB.lighting_defer_active)
		return FALSE
	var/datum/space_level/level = SSmapping.z_list.len >= new_z ? SSmapping.z_list[new_z] : null
	return level && !level.lighting_initialized

/// Creates lighting infrastructure for a single z-level on demand (synchronous fallback).
/// Called when a player enters a z-level before background init reaches it.
/proc/create_lighting_for_zlevel(z_level)
	var/datum/space_level/level = SSmapping.get_level(z_level)
	// Self-heal: also re-run when a prior (possibly interrupted) init left deferred light atoms for
	// this z unflushed — otherwise the level stays flagged "initialized" yet permanently black.
	if(level.lighting_initialized && !zlevel_has_deferred_lighting(z_level))
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
	// Sources get queued to GLOB.lighting_update_lights; fire() processes them with active corners.
	// Живой список мутируем ТОЛЬКО in place (удаление до ближайшего CHECK_TICK): переприсваивание
	// глобала устаревшим снапшотом теряло атомы, запаркованные во время сна параллельным прогоном
	// (второй игрок на другом отложенном z, фоновый краул) - такой атом навсегда выпадал из
	// отложки и был невидим для сейфнет-скана.
	for(var/atom/A as anything in GLOB.lighting_deferred_atoms.Copy())
		if(QDELETED(A))
			GLOB.lighting_deferred_atoms -= A
			continue
		var/turf/T = get_turf(A)
		if(T?.z == z_level)
			GLOB.lighting_deferred_atoms -= A
			A.update_light()
		CHECK_TICK
	GLOB.lighting_deferred_z_cache = null

	// Phase 2: Queue deferred starlight for fire() Phase -1 instead of processing synchronously.
	// Тот же инвариант: только in-place удаление, никаких переприсваиваний глобала.
	for(var/turf/open/space/S in GLOB.lighting_deferred_starlight.Copy())
		if(S.z == z_level)
			GLOB.lighting_starlight_queue |= S
			GLOB.lighting_deferred_starlight -= S
		CHECK_TICK

	// Drain the work this on-demand init just queued so the z a player is standing on lights up
	// immediately, instead of leaving the backlog under fire()'s dilation-adaptive source cap (which
	// collapses to ~20-40 sources/fire under atmospherics load: tens of seconds of black, far longer
	// on heavy away-maps). fire() Phase -1 still creates the queued starlight sources separately.
	drain_lighting_queues_snapshot()
