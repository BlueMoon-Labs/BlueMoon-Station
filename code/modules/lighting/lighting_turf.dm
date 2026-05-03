/turf
	var/dynamic_lighting = TRUE
	luminosity           = 1

	var/tmp/lighting_corners_initialised = FALSE

	var/tmp/atom/movable/lighting_object/lighting_object // Our lighting object.
	var/tmp/datum/lighting_corner/lc_topleft
	var/tmp/datum/lighting_corner/lc_topright
	var/tmp/datum/lighting_corner/lc_bottomleft
	var/tmp/datum/lighting_corner/lc_bottomright
	var/tmp/has_opaque_atom = FALSE // Not to be confused with opacity, this will be TRUE if there's any opaque atom on the tile.
	var/tmp/shadow_weight_sum = 0 // Accumulated shadow weight from non-opaque atoms with shadow_weight > 0. Clamped to 1.0.
	var/tmp/cached_lumcount // Cached normalized brightness for get_lumcount() (null = dirty)

// counterclockwisse 0 to 360
#define PROC_ON_CORNERS(operation) lc_topright?.##operation;lc_bottomright?.##operation;lc_bottomleft?.##operation;lc_topleft?.##operation

// Causes any affecting light sources to be queued for a visibility update, for example a door got opened.
// Derives the set of affecting lights from corner data instead of maintaining a per-turf list.
/turf/proc/reconsider_lights()
	var/list/done = list()
	#define _RECONSIDER_CORNER(corner) \
		if(corner) { \
			for(var/datum/light_source/L in corner.affecting) { \
				if(!done[L]) { \
					done[L] = TRUE; \
					if(get_dist(src, L.source_turf) < CEILING(L.light_range, 1)) { \
						L.vis_update(); \
					}; \
				}; \
			}; \
		}
	_RECONSIDER_CORNER(lc_topright)
	_RECONSIDER_CORNER(lc_bottomright)
	_RECONSIDER_CORNER(lc_bottomleft)
	_RECONSIDER_CORNER(lc_topleft)
	#undef _RECONSIDER_CORNER

/turf/proc/lighting_clear_overlay()
	if (lighting_object)
		qdel(lighting_object, force=TRUE)

	PROC_ON_CORNERS(update_active())

// Builds a lighting object for us, but only if our area is dynamic.
/turf/proc/lighting_build_overlay()
	if (lighting_object)
		qdel(lighting_object, force=TRUE) //Shitty fix for lighting objects persisting after death

	var/area/our_area = loc
	if (!IS_DYNAMIC_LIGHTING(our_area) && !light_sources)
		return

	if (!lighting_corners_initialised)
		generate_missing_corners()

	new /atom/movable/lighting_object(src)

	var/datum/light_source/S
	var/i
#define OPERATE(corner) \
	if(corner && !corner.active) { \
		for(i in corner.affecting) { \
			S = i ; \
			S.recalc_corner(corner) \
		} \
		corner.active = TRUE \
	}
	OPERATE(lc_topright)
	OPERATE(lc_bottomright)
	OPERATE(lc_bottomleft)
	OPERATE(lc_topleft)
#undef OPERATE

// Used to get a scaled lumcount.
/turf/proc/get_lumcount(var/minlum = 0, var/maxlum = 1)
	if(!lighting_object)
		return TRUE

	var/totallums = cached_lumcount
	if(isnull(totallums))
		totallums = ((lc_topright? (lc_topright.lum_r + lc_topright.lum_g + lc_topright.lum_b) : 0) \
		+ (lc_bottomright? (lc_bottomright.lum_r + lc_bottomright.lum_g + lc_bottomright.lum_b) : 0) \
		+ (lc_bottomleft? (lc_bottomleft.lum_r + lc_bottomleft.lum_g + lc_bottomleft.lum_b) : 0) \
		+ (lc_topleft? (lc_topleft.lum_r + lc_topleft.lum_g + lc_topleft.lum_b) : 0)) / 12
		cached_lumcount = totallums

	totallums = (totallums - minlum) / (maxlum - minlum)

	return CLAMP01(totallums)

// Returns a boolean whether the turf is on soft lighting.
// Soft lighting being the threshold at which point the overlay considers
// itself as too dark to allow sight and see_in_dark becomes useful.
// So basically if this returns true the tile is unlit black.
/turf/proc/is_softly_lit()
	if (!lighting_object)
		return FALSE

	return !luminosity

// Can't think of a good name, this proc will recalculate the has_opaque_atom variable.
// Full contents scan — used when opacity changes (need to check all atoms for remaining opaque ones).
/turf/proc/recalc_atom_opacity()
	var/old_opaque = has_opaque_atom
	var/old_weight = shadow_weight_sum
	has_opaque_atom = opacity
	if(opacity)
		shadow_weight_sum = 1
	else
		shadow_weight_sum = shadow_weight // turf's own weight
		for(var/atom/A in src.contents)
			if(A.opacity)
				has_opaque_atom = TRUE
				shadow_weight_sum = 1
				break
			if(A.shadow_weight > 0)
				shadow_weight_sum += A.shadow_weight
		shadow_weight_sum = min(shadow_weight_sum, 1) // Clamp to 1.0 max per turf
	// During bulk operations (shuttle moves), skip per-turf corner propagation — batch recalc after
	if(GLOB.lighting_defer_active)
		return
	// If opacity state changed, update light visibility AND contact shadows
	if(has_opaque_atom != old_opaque)
		PROC_ON_CORNERS(recalc_opaque_neighbors())
	// If only shadow weight changed (no opacity change), still update contact shadows
	else if(abs(shadow_weight_sum - old_weight) > 0.01)
		PROC_ON_CORNERS(recalc_opaque_neighbors())

/// Incremental shadow weight adjustment — avoids full contents scan for non-opaque atom enter/exit.
/// Only valid when the atom is NOT opaque (opaque changes must use recalc_atom_opacity).
/turf/proc/adjust_shadow_weight(delta)
	if(has_opaque_atom)
		return // Opaque atom present = weight locked at 1.0, delta irrelevant
	var/old_weight = shadow_weight_sum
	shadow_weight_sum = clamp(shadow_weight_sum + delta, 0, 1)
	if(GLOB.lighting_defer_active)
		return
	if(abs(shadow_weight_sum - old_weight) > 0.01)
		PROC_ON_CORNERS(recalc_opaque_neighbors())

/turf/Exited(atom/movable/Obj, atom/newloc)
	. = ..()

	if(Obj && !GLOB.lighting_defer_active)
		if(Obj.opacity)
			recalc_atom_opacity() // Make sure to do this before reconsider_lights(), incase we're on instant updates.
			reconsider_lights()
		else if(Obj.shadow_weight > 0)
			adjust_shadow_weight(-Obj.shadow_weight)

/turf/proc/change_area(var/area/old_area, var/area/new_area, skip_blend = FALSE)
	if(SSlighting.initialized)
		if (new_area.dynamic_lighting != old_area.dynamic_lighting)
			if (new_area.dynamic_lighting)
				lighting_build_overlay()
			else
				lighting_clear_overlay()
		// Recalculate blended area profiles for this turf and its cardinal neighbors
		// skip_blend = TRUE during bulk operations (shuttle moves) — batch recalc is done after
		if(!skip_blend)
			if(old_area.light_temperature != new_area.light_temperature || \
			   old_area.light_contrast != new_area.light_contrast || \
			   old_area.contact_shadow_multiplier != new_area.contact_shadow_multiplier || \
			   old_area.ambient_light != new_area.ambient_light)
				recalc_area_blend_region()

/// Queues blended area profile recalculation on this turf and its cardinal neighbors.
/// Called when a turf changes area or an area's lighting profile is modified.
/// Actual recalculation is batched in SSlighting fire() Phase 0 to avoid O(n*5) spikes.
/turf/proc/recalc_area_blend_region()
	if(lighting_object)
		GLOB.lighting_update_blends |= lighting_object
		if(!lighting_object.needs_update)
			lighting_object.needs_update = TRUE
			GLOB.lighting_update_objects += lighting_object
	var/turf/neighbor
	neighbor = get_step(src, NORTH)
	if(neighbor?.lighting_object)
		GLOB.lighting_update_blends |= neighbor.lighting_object
		if(!neighbor.lighting_object.needs_update)
			neighbor.lighting_object.needs_update = TRUE
			GLOB.lighting_update_objects += neighbor.lighting_object
	neighbor = get_step(src, SOUTH)
	if(neighbor?.lighting_object)
		GLOB.lighting_update_blends |= neighbor.lighting_object
		if(!neighbor.lighting_object.needs_update)
			neighbor.lighting_object.needs_update = TRUE
			GLOB.lighting_update_objects += neighbor.lighting_object
	neighbor = get_step(src, EAST)
	if(neighbor?.lighting_object)
		GLOB.lighting_update_blends |= neighbor.lighting_object
		if(!neighbor.lighting_object.needs_update)
			neighbor.lighting_object.needs_update = TRUE
			GLOB.lighting_update_objects += neighbor.lighting_object
	neighbor = get_step(src, WEST)
	if(neighbor?.lighting_object)
		GLOB.lighting_update_blends |= neighbor.lighting_object
		if(!neighbor.lighting_object.needs_update)
			neighbor.lighting_object.needs_update = TRUE
			GLOB.lighting_update_objects += neighbor.lighting_object

/turf/proc/generate_missing_corners()
	if (!IS_DYNAMIC_LIGHTING(src) && !light_sources)
		return
	// Corners must never be qdel'd; if a ref is stale, allow recreation (avoids bad state during moves)
	if(lc_topright && QDELETED(lc_topright))
		lc_topright = null
	if(lc_bottomright && QDELETED(lc_bottomright))
		lc_bottomright = null
	if(lc_bottomleft && QDELETED(lc_bottomleft))
		lc_bottomleft = null
	if(lc_topleft && QDELETED(lc_topleft))
		lc_topleft = null
	lighting_corners_initialised = TRUE
	// counterclockwise from 0 to 360.
	if(!lc_topright)
		new /datum/lighting_corner(src, NORTHEAST)
	if(!lc_bottomright)
		new /datum/lighting_corner(src, SOUTHEAST)
	if(!lc_bottomleft)
		new /datum/lighting_corner(src, SOUTHWEST)
	if(!lc_topleft)
		new /datum/lighting_corner(src, NORTHWEST)

#undef PROC_ON_CORNERS
