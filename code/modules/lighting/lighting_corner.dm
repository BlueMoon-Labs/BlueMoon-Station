// Because we can control each corner of every lighting object.
// And corners get shared between multiple turfs (unless you're on the corners of the map, then 1 corner doesn't).
// For the record: these should never ever ever be deleted, even if the turf doesn't have dynamic lighting.

/datum/lighting_corner
	var/turf/northeast
	var/turf/northwest
	var/turf/southeast
	var/turf/southwest
	var/list/datum/light_source/affecting // Light sources affecting us.
	var/active                            = FALSE  // TRUE if one of our masters has dynamic lighting.

	var/x     = 0
	var/y     = 0
	var/z     = 0

	var/lum_r = 0
	var/lum_g = 0
	var/lum_b = 0

	var/needs_update = FALSE

	/// Accumulated shadow weight from adjacent turfs (0.0-4.0) — used for contact shadow dimming.
	/// Opaque turfs contribute 1.0, non-opaque turfs contribute their shadow_weight_sum.
	var/opaque_neighbors = 0
	/// Pre-computed sqrt(min(opaque_neighbors, 3)) — avoids sqrt() in the hot lighting_object/update() path
	var/shadow_sqrt_cache = 0

	var/cache_r  = LIGHTING_SOFT_THRESHOLD
	var/cache_g  = LIGHTING_SOFT_THRESHOLD
	var/cache_b  = LIGHTING_SOFT_THRESHOLD
	var/cache_mx = 0

// Diagonal is our direction FROM them, not to.
/datum/lighting_corner/New(turf/new_turf, diagonal)
	. = ..()

#define SET_DIAGONAL(turf, diagonal) \
	switch(diagonal){ \
		if(SOUTHWEST) { northeast = turf; turf.lc_bottomleft = src; } \
		if(SOUTHEAST) { northwest = turf; turf.lc_bottomright = src; } \
		if(NORTHEAST) { southwest = turf; turf.lc_topright = src; } \
		if(NORTHWEST) { southeast = turf; turf.lc_topleft = src; } \
	}
	SET_DIAGONAL(new_turf, diagonal)
	z = new_turf.z

	var/vertical   = diagonal & ~(diagonal - 1) // The horizontal directions (4 and 8) are bigger than the vertical ones (1 and 2), so we can reliably say the lsb is the horizontal direction.
	var/horizontal = diagonal & ~vertical       // Now that we know the horizontal one we can get the vertical one.

	x = new_turf.x + (horizontal == EAST  ? 0.5 : -0.5)
	y = new_turf.y + (vertical   == NORTH ? 0.5 : -0.5)

	var/turf/T
	// Build diagonal one
	T = get_step(new_turf, diagonal)
	if(T)
		SET_DIAGONAL(T, turn(diagonal, 180))
	// Build horizontal
	T = get_step(new_turf, horizontal)
	if(T)
		SET_DIAGONAL(T, turn(((T.x > x) ? EAST : WEST) | ((T.y > y) ? NORTH : SOUTH), 180))
	// Build vertical
	T = get_step(new_turf, vertical)
	if(T)
		SET_DIAGONAL(T, turn(((T.x > x) ? EAST : WEST) | ((T.y > y) ? NORTH : SOUTH), 180))

	update_active()
	// Initialize contact shadow state from adjacent turfs (float weights for semi-transparent shadows)
	if(northeast)
		opaque_neighbors += northeast.has_opaque_atom ? 1 : northeast.shadow_weight_sum
	if(northwest)
		opaque_neighbors += northwest.has_opaque_atom ? 1 : northwest.shadow_weight_sum
	if(southeast)
		opaque_neighbors += southeast.has_opaque_atom ? 1 : southeast.shadow_weight_sum
	if(southwest)
		opaque_neighbors += southwest.has_opaque_atom ? 1 : southwest.shadow_weight_sum
	if(opaque_neighbors > 0.005)
		shadow_sqrt_cache = sqrt(min(opaque_neighbors, CONTACT_SHADOW_MAX_NEIGHBORS))

#undef SET_DIAGONAL

/datum/lighting_corner/proc/update_active()
	active = FALSE
	if(northeast?.lighting_object || northwest?.lighting_object || southeast?.lighting_object || southwest?.lighting_object)
		active = TRUE

// God that was a mess, now to do the rest of the corner code! Hooray!
/datum/lighting_corner/proc/update_lumcount(var/delta_r, var/delta_g, var/delta_b)
	if ((abs(delta_r)+abs(delta_g)+abs(delta_b)) == 0)
		return

	lum_r += delta_r
	lum_g += delta_g
	lum_b += delta_b

	if (!needs_update)
		needs_update = TRUE
		GLOB.lighting_update_corners += src

/// Recalculates opaque_neighbors weight sum. Called event-driven from turf/recalc_atom_opacity().
/// Uses float weights: opaque turfs contribute 1.0, non-opaque turfs contribute their shadow_weight_sum.
/datum/lighting_corner/proc/recalc_opaque_neighbors()
	var/weight = 0
	if(northeast)
		weight += northeast.has_opaque_atom ? 1 : northeast.shadow_weight_sum
	if(northwest)
		weight += northwest.has_opaque_atom ? 1 : northwest.shadow_weight_sum
	if(southeast)
		weight += southeast.has_opaque_atom ? 1 : southeast.shadow_weight_sum
	if(southwest)
		weight += southwest.has_opaque_atom ? 1 : southwest.shadow_weight_sum
	if(abs(weight - opaque_neighbors) > 0.005)
		opaque_neighbors = weight
		shadow_sqrt_cache = weight > 0.005 ? sqrt(min(weight, CONTACT_SHADOW_MAX_NEIGHBORS)) : 0
		// Shadow changes don't affect corner lum values, but lighting objects need re-rendering
		// for the contact shadow visual. Force-queue adjacent objects directly (bypasses
		// update_objects() cache-skip since cache_r/g/b/mx won't change).
		#define _SHADOW_QUEUE(turf) if(turf?.lighting_object && !turf.lighting_object.needs_update) { turf.lighting_object.needs_update = TRUE; GLOB.lighting_update_objects += turf.lighting_object }
		_SHADOW_QUEUE(northeast)
		_SHADOW_QUEUE(northwest)
		_SHADOW_QUEUE(southeast)
		_SHADOW_QUEUE(southwest)
		#undef _SHADOW_QUEUE

/datum/lighting_corner/proc/update_objects()
	// Cache these values a head of time so 4 individual lighting objects don't all calculate them individually.
	var/lum_r = src.lum_r
	var/lum_g = src.lum_g
	var/lum_b = src.lum_b
	var/mx = max(lum_r, lum_g, lum_b) // Scale it so one of them is the strongest lum, if it is above 1.
	. = 1 // factor
	if (mx > 1)
		. = 1 / mx

	#if LIGHTING_SOFT_THRESHOLD != 0
	else if (mx < LIGHTING_SOFT_THRESHOLD)
		. = 0 // 0 means soft lighting.

	var/new_r = round(lum_r * ., LIGHTING_ROUND_VALUE) || LIGHTING_SOFT_THRESHOLD
	var/new_g = round(lum_g * ., LIGHTING_ROUND_VALUE) || LIGHTING_SOFT_THRESHOLD
	var/new_b = round(lum_b * ., LIGHTING_ROUND_VALUE) || LIGHTING_SOFT_THRESHOLD
	#else
	var/new_r = round(lum_r * ., LIGHTING_ROUND_VALUE)
	var/new_g = round(lum_g * ., LIGHTING_ROUND_VALUE)
	var/new_b = round(lum_b * ., LIGHTING_ROUND_VALUE)
	#endif
	var/new_mx = round(mx, LIGHTING_ROUND_VALUE)

	// Early return: if rounded cache values are identical, skip queuing adjacent objects
	if(new_r == cache_r && new_g == cache_g && new_b == cache_b && new_mx == cache_mx)
		return

	cache_r = new_r
	cache_g = new_g
	cache_b = new_b
	cache_mx = new_mx

	#define QUEUE(turf) if(turf?.lighting_object && !turf.lighting_object.needs_update) { turf.lighting_object.needs_update = TRUE; GLOB.lighting_update_objects += turf.lighting_object }
	QUEUE(northeast)
	QUEUE(northwest)
	QUEUE(southeast)
	QUEUE(southwest)
	#undef QUEUE

/datum/lighting_corner/dummy/New()
	return


/datum/lighting_corner/Destroy(var/force)
	if (!force)
		return QDEL_HINT_LETMELIVE

	stack_trace("Ok, Look, /tg/, I need you to find whatever fucker decided to call qdel on a fucking lighting corner, then tell him very nicely and politely that he is 100% stupid and needs his head checked. Thanks. Send them my regards by the way.")

	return ..()
