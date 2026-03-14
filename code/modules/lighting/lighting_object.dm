/atom/movable/lighting_object
	icon = LIGHTING_ICON
	icon_state = null
	plane = LIGHTING_PLANE
	layer = LIGHTING_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	anchored = TRUE
	rad_flags = RAD_NO_CONTAMINATE
	// Initial color is the fully-lit white matrix so the first animate() interpolates correctly
	color = LIGHTING_BASE_MATRIX

	///whether we are already in the SSlighting.objects_queue list
	var/needs_update = FALSE

	///the turf that our light is applied to
	var/turf/affected_turf

	// Cached previous corner values — skip animate() when unchanged
	var/prev_rr = 1; var/prev_rg = 1; var/prev_rb = 1
	var/prev_gr = 1; var/prev_gg = 1; var/prev_gb = 1
	var/prev_br = 1; var/prev_bg = 1; var/prev_bb = 1
	var/prev_ar = 1; var/prev_ag = 1; var/prev_ab = 1

	/// Shared static color matrix buffer — reused across all lighting objects to avoid per-instance allocation.
	/// Safe because update() runs sequentially in SSlighting fire() and BYOND copies the list on color assignment.
	var/static/list/shared_color_buffer = list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)

	// Fast skip for turfs that stay dark — avoids ALL corner reads, shadow, profile, and matrix work
	var/prev_was_dark = FALSE

	// Cached blended area profile (averaged with cardinal neighbors for soft transitions)
	var/blended_temperature = 0
	var/blended_contrast = 1
	var/blended_contact_shadow = 1
	var/blended_ambient = AMBIENT_LIGHT_DEFAULT

/atom/movable/lighting_object/New(turf/source)
	// Call parent without passing source as loc — we render via vis_contents, not loc
	..()
	if(!isturf(source))
		qdel(src, force=TRUE)
		stack_trace("a lighting object was assigned to [source], a non turf! ")
		return

	affected_turf = source
	if (affected_turf.lighting_object)
		qdel(affected_turf.lighting_object, force = TRUE)
		stack_trace("a lighting object was assigned to a turf that already had a lighting object!")

	affected_turf.lighting_object = src
	affected_turf.luminosity = 0
	affected_turf.vis_contents += src

	if(SSlighting.init_in_progress)
		// During init, collect space turfs for batch processing (deduped via assoc list)
		for(var/turf/open/space/space_tile in RANGE_TURFS(1, affected_turf))
			GLOB.lighting_deferred_starlight[space_tile] = TRUE
	else
		for(var/turf/open/space/space_tile in RANGE_TURFS(1, affected_turf))
			space_tile.update_starlight()

	// Compute blended area profile from this turf + cardinal neighbors for soft zone transitions
	calculate_area_blend()

	needs_update = TRUE
	GLOB.lighting_update_objects += src

/atom/movable/lighting_object/Destroy(force)
	if (!force)
		return QDEL_HINT_LETMELIVE
	// Cancel any in-progress animation to release BYOND's internal reference that prevents GC
	animate(src, flags = ANIMATION_END_NOW)
	needs_update = FALSE
	GLOB.lighting_update_objects -= src
	GLOB.lighting_update_blends -= src
	if (isturf(affected_turf))
		affected_turf.lighting_object = null
		affected_turf.luminosity = 1
		affected_turf.vis_contents -= src
	affected_turf = null
	return ..()

/// Computes blended area lighting profile by averaging this turf's area with 4 cardinal neighbors.
/// Produces soft transitions at zone boundaries instead of hard color jumps.
/atom/movable/lighting_object/proc/calculate_area_blend()
	prev_was_dark = FALSE
	var/area/center_area = affected_turf.loc
	var/turf/n_turf = get_step(affected_turf, NORTH)
	var/turf/s_turf = get_step(affected_turf, SOUTH)
	var/turf/e_turf = get_step(affected_turf, EAST)
	var/turf/w_turf = get_step(affected_turf, WEST)
	// Fast path: all cardinal neighbors belong to the same area — skip averaging
	if((!n_turf || n_turf.loc == center_area) && (!s_turf || s_turf.loc == center_area) && \
	   (!e_turf || e_turf.loc == center_area) && (!w_turf || w_turf.loc == center_area))
		blended_temperature = center_area.light_temperature
		blended_contrast = center_area.light_contrast
		blended_contact_shadow = center_area.contact_shadow_multiplier
		blended_ambient = center_area.ambient_light
		return
	// Slow path: area boundary — average with neighbors for soft transitions
	var/total_temp = center_area.light_temperature
	var/total_contrast = center_area.light_contrast
	var/total_contact = center_area.contact_shadow_multiplier
	var/total_ambient = center_area.ambient_light
	var/count = 1
	var/area/neighbor_area
	if(n_turf)
		neighbor_area = n_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	if(s_turf)
		neighbor_area = s_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	if(e_turf)
		neighbor_area = e_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	if(w_turf)
		neighbor_area = w_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	blended_temperature = total_temp / count
	blended_contrast = total_contrast / count
	blended_contact_shadow = total_contact / count
	blended_ambient = total_ambient / count

/atom/movable/lighting_object/proc/update(animate_time = LIGHTING_ANIMATE_TIME, use_animate = TRUE)

	// To the future coder who sees this and thinks
	// "Why didn't he just use a loop?"
	// Well my man, it's because the loop performed like shit.
	// And there's no way to improve it because
	// without a loop you can make the list all at once which is the fastest you're gonna get.
	// Oh it's also shorter line wise.
	// Including with these comments.

	var/static/datum/lighting_corner/dummy/dummy_lighting_corner = new

	var/datum/lighting_corner/red_corner = affected_turf.lc_bottomleft || dummy_lighting_corner
	var/datum/lighting_corner/green_corner = affected_turf.lc_bottomright || dummy_lighting_corner
	var/datum/lighting_corner/blue_corner = affected_turf.lc_topleft || dummy_lighting_corner
	var/datum/lighting_corner/alpha_corner = affected_turf.lc_topright || dummy_lighting_corner

	// Fast skip: if this turf was dark last update and all corners are still dark,
	// skip ALL 12 corner value reads, shadow calculation, profile, epsilon, and matrix work
	if(prev_was_dark)
		if(red_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD \
			&& green_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD \
			&& blue_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD \
			&& alpha_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD)
			return

	var/max = max(red_corner.cache_mx, green_corner.cache_mx, blue_corner.cache_mx, alpha_corner.cache_mx)

	var/rr = red_corner.cache_r
	var/rg = red_corner.cache_g
	var/rb = red_corner.cache_b

	var/gr = green_corner.cache_r
	var/gg = green_corner.cache_g
	var/gb = green_corner.cache_b

	var/br = blue_corner.cache_r
	var/bg = blue_corner.cache_g
	var/bb = blue_corner.cache_b

	var/ar = alpha_corner.cache_r
	var/ag = alpha_corner.cache_g
	var/ab = alpha_corner.cache_b

	// Contact shadows: dim corners based on nearby opaque/heavy atoms, scaled by area multiplier
	// Uses pre-computed shadow_sqrt_cache on corners (set during recalc_opaque_neighbors)
	// Supports float weights for semi-transparent shadows from tables, lockers, etc.
	var/contact_str = CONTACT_SHADOW_STRENGTH * blended_contact_shadow
	var/_rsc = red_corner.shadow_sqrt_cache
	var/_gsc = green_corner.shadow_sqrt_cache
	var/_bsc = blue_corner.shadow_sqrt_cache
	var/_asc = alpha_corner.shadow_sqrt_cache
	if(contact_str > 0 && (_rsc || _gsc || _bsc || _asc))
		var/shadow_mul
		if(_rsc)
			shadow_mul = max(0, 1 - contact_str * _rsc)
			rr *= shadow_mul; rg *= shadow_mul; rb *= shadow_mul
		if(_gsc)
			shadow_mul = max(0, 1 - contact_str * _gsc)
			gr *= shadow_mul; gg *= shadow_mul; gb *= shadow_mul
		if(_bsc)
			shadow_mul = max(0, 1 - contact_str * _bsc)
			br *= shadow_mul; bg *= shadow_mul; bb *= shadow_mul
		if(_asc)
			shadow_mul = max(0, 1 - contact_str * _asc)
			ar *= shadow_mul; ag *= shadow_mul; ab *= shadow_mul

	// Area lighting profile: temperature (warm/cool) and contrast — uses blended values for soft transitions
	if(blended_contrast != 1)
		var/contrast = blended_contrast
		rr *= contrast; rg *= contrast; rb *= contrast
		gr *= contrast; gg *= contrast; gb *= contrast
		br *= contrast; bg *= contrast; bb *= contrast
		ar *= contrast; ag *= contrast; ab *= contrast
	if(blended_temperature)
		// Multiplicative temperature: brighter areas shift more, dark areas stay neutral
		// Warm (temp > 0): ↑red ↓blue; Cool (temp < 0): ↓red ↑blue
		var/warm_mul = 1 + blended_temperature
		var/cool_mul = max(0, 1 - blended_temperature)
		rr *= warm_mul; gr *= warm_mul; br *= warm_mul; ar *= warm_mul
		rb *= cool_mul; gb *= cool_mul; bb *= cool_mul; ab *= cool_mul

		// Complementary shadow tinting: shadows shift to the opposite hue of the area temperature
		// Warm light → cool (blue) shadows, cool light → warm (red) shadows
		var/shadow_shift = -blended_temperature * SHADOW_TINT_FACTOR
		var/threshold_3x = SHADOW_TINT_THRESHOLD * 3
		var/inv_threshold = 1 / SHADOW_TINT_THRESHOLD
		var/corner_sum
		var/tint_strength
		// Red corner (bottom-left) — sum check skips division for bright corners
		corner_sum = rr + rg + rb
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			rr += shadow_shift * tint_strength
			rb -= shadow_shift * tint_strength
		// Green corner (bottom-right)
		corner_sum = gr + gg + gb
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			gr += shadow_shift * tint_strength
			gb -= shadow_shift * tint_strength
		// Blue corner (top-left)
		corner_sum = br + bg + bb
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			br += shadow_shift * tint_strength
			bb -= shadow_shift * tint_strength
		// Alpha corner (top-right)
		corner_sum = ar + ag + ab
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			ar += shadow_shift * tint_strength
			ab -= shadow_shift * tint_strength

	#if LIGHTING_SOFT_THRESHOLD != 0
	var/set_luminosity = max > LIGHTING_SOFT_THRESHOLD
	#else
	// Because of floating points, it won't even be a flat 0.
	// This number is mostly arbitrary.
	var/set_luminosity = max > 1e-6
	#endif

	// Luminosity is a cheap boolean — always update
	affected_turf.luminosity = set_luminosity
	prev_was_dark = !set_luminosity

	// Skip matrix construction + animate() if nothing visually changed
	// Short-circuit: compute first 6 abs() values, skip remaining 6 if already above threshold
	// Post-spike objects typically have large changes, so first half exceeds threshold quickly
	var/_eps_diff = abs(rr - prev_rr) + abs(rg - prev_rg) + abs(rb - prev_rb) + \
	   abs(gr - prev_gr) + abs(gg - prev_gg) + abs(gb - prev_gb)
	if(_eps_diff < LIGHTING_ROUND_VALUE)
		_eps_diff += abs(br - prev_br) + abs(bg - prev_bg) + abs(bb - prev_bb) + \
		   abs(ar - prev_ar) + abs(ag - prev_ag) + abs(ab - prev_ab)
		if(_eps_diff < LIGHTING_ROUND_VALUE)
			return

	prev_rr = rr; prev_rg = rg; prev_rb = rb
	prev_gr = gr; prev_gg = gg; prev_gb = gb
	prev_br = br; prev_bg = bg; prev_bb = bb
	prev_ar = ar; prev_ag = ag; prev_ab = ab

	affected_turf.cached_lumcount = null

	var/list/new_color
	if((rr & gr & br & ar) && (rg + gg + bg + ag + rb + gb + bb + ab == 8))
		//anything that passes the first case is very likely to pass the second, and addition is a little faster in this case
		// Fully lit — white matrix (invisible on BLEND_MULTIPLY)
		new_color = LIGHTING_BASE_MATRIX
	else if(!set_luminosity)
		if(blended_ambient > 0)
			// Ambient floor: barely-visible base light instead of pure black (textures remain faintly visible)
			// luminosity stays FALSE — turf is still "dark" for vision mechanics
			var/amb = blended_ambient
			var/amb_key = "[round(amb, 0.005)]"
			var/list/cached = GLOB.lighting_ambient_matrices[amb_key]
			if(!cached)
				cached = list(amb, amb, amb, 0, amb, amb, amb, 0, amb, amb, amb, 0, amb, amb, amb, 0, 0, 0, 0, 1)
				GLOB.lighting_ambient_matrices[amb_key] = cached
			new_color = cached
		else
			// Fully dark — black matrix (space, void areas)
			new_color = LIGHTING_DARK_MATRIX
	else
		// Normal lit — reuse shared static buffer (BYOND copies on color assignment/animate)
		shared_color_buffer[1]  = rr; shared_color_buffer[2]  = rg; shared_color_buffer[3]  = rb
		shared_color_buffer[5]  = gr; shared_color_buffer[6]  = gg; shared_color_buffer[7]  = gb
		shared_color_buffer[9]  = br; shared_color_buffer[10] = bg; shared_color_buffer[11] = bb
		shared_color_buffer[13] = ar; shared_color_buffer[14] = ag; shared_color_buffer[15] = ab
		new_color = shared_color_buffer

	if(!use_animate || animate_time <= LIGHTING_ANIMATE_TIME_FAST)
		color = new_color
	else
		animate(src, color = new_color, time = animate_time)
