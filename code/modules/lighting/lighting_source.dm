// This is where the fun begins.
// These are the main datums that emit light.

/datum/light_source
	var/atom/top_atom        // The atom we're emitting light from (for example a mob if we're from a flashlight that's being held).
	var/atom/source_atom     // The atom that we belong to.

	var/turf/source_turf     // The turf under the above.
	var/turf/pixel_turf      // The turf the top_atom appears to over.
	var/light_power    // Intensity of the emitter light.
	var/light_range      // The range of the emitted light.
	var/light_color    // The colour of the light, string, decomposed by PARSE_LIGHT_COLOR()
	var/light_height   // Height off the ground on the pseudo-z-axis.

	// Cone (directional) lighting variables.
	var/light_cone_angle = 0
	var/light_cone_dir = 0
	var/cone_dir_x = 0
	var/cone_dir_y = 0
	var/cone_half_cos = 0
	var/cone_penumbra_cos = 0

	// Variables for keeping track of the colour.
	var/lum_r
	var/lum_g
	var/lum_b

	// The lumcount values used to apply the light.
	var/tmp/applied_lum_r
	var/tmp/applied_lum_g
	var/tmp/applied_lum_b

	var/list/datum/lighting_corner/effect_str     // List used to store how much we're affecting corners.

	// Reusable buffers to reduce GC pressure in update_corners() (cleared with .Cut(), not reallocated)
	var/list/datum/lighting_corner/_corners_buf

	var/applied = FALSE // Whether we have applied our light yet or not.
	var/applied_power = 0 // The light_power used to compute current effect_str values (for deriving raw falloff)
	var/cone_signal_registered = FALSE // Whether COMSIG_ATOM_DIR_CHANGE is registered on top_atom.

	var/needs_update = LIGHTING_NO_UPDATE    // Whether we are queued for an update.

// Thanks to Lohikar for flinging this tiny bit of code at me, increasing my brain cell count from 1 to 2 in the process.
// This macro will only offset up to 1 tile, but anything with a greater offset is an outlier and probably should handle its own lighting offsets.
// Anything pixelshifted 16px or more will be considered on the next tile.
#define GET_APPROXIMATE_PIXEL_DIR(PX, PY) ((!(PX) ? 0 : ((PX >= 16 ? EAST : (PX <= -16 ? WEST : 0)))) | (!PY ? 0 : (PY >= 16 ? NORTH : (PY <= -16 ? SOUTH : 0))))
#define UPDATE_APPROXIMATE_PIXEL_TURF var/_mask = GET_APPROXIMATE_PIXEL_DIR(top_atom.pixel_x, top_atom.pixel_y); pixel_turf = _mask ? (get_step(source_turf, _mask) || source_turf) : source_turf

/datum/light_source/New(var/atom/owner, var/atom/top)
	source_atom = owner // Set our new owner.
	LAZYADD(source_atom.light_sources, src)
	GLOB.all_light_sources += src
	top_atom = top
	if (top_atom != source_atom)
		LAZYADD(top_atom.light_sources, src)

	source_turf = top_atom
	UPDATE_APPROXIMATE_PIXEL_TURF

	light_power = source_atom.light_power
	light_range = min(source_atom.light_range, LIGHTING_MAX_RANGE)
	light_color = source_atom.light_color
	light_height = source_atom.light_height
	light_cone_angle = source_atom.light_cone_angle

	if(light_cone_angle > 0)
		update_cone_cache()

	PARSE_LIGHT_COLOR(src)

	update()

	// Register for direction changes if we have a cone and follow top_atom's dir.
	// NOTE: When light_cone_dir is set on the source atom, the cone direction is FIXED
	// and will NOT rotate with the holder. This is by design for wall-mounted fixtures, etc.
	// Once registered, stays registered until top_atom changes or Destroy — handler has early return for inactive cones.
	if(light_cone_angle > 0 && top_atom && !source_atom.light_cone_dir)
		RegisterSignal(top_atom, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_holder_dir_change))
		cone_signal_registered = TRUE

/datum/light_source/Destroy(force)
	GLOB.all_light_sources -= src
	if (applied || effect_str)
		remove_lum()
	if (source_atom)
		// Clear the atom's light reference if we are its active source.
		// Without this, the atom's `light` var becomes a zombie reference
		// after qdel — update_light() sees `if(light)` as TRUE and calls
		// light.update() on the dead datum instead of creating a new source.
		if(source_atom.light == src)
			source_atom.light = null
		LAZYREMOVE(source_atom.light_sources, src)

	if (top_atom)
		if(cone_signal_registered)
			UnregisterSignal(top_atom, COMSIG_ATOM_DIR_CHANGE)
			cone_signal_registered = FALSE
		if (top_atom != source_atom)
			LAZYREMOVE(top_atom.light_sources, src)

	if (needs_update)
		needs_update = LIGHTING_NO_UPDATE
		// Do NOT remove from GLOB.lighting_update_lights here.
		// Removing mid-iteration during fire() causes list-shift that skips
		// the next entry, permanently stranding it. fire()'s QDELETED(L)
		// check will skip this dead datum, and Cut() removes it from the list.

	top_atom = null
	source_atom = null
	source_turf = null
	pixel_turf = null
	_corners_buf = null
	..()
	return QDEL_HINT_IWILLGC

// Yes this doesn't align correctly on anything other than 4 width tabs.
// If you want it to go switch everybody to elastic tab stops.
// Actually that'd be great if you could!
#define EFFECT_UPDATE(level)                \
	if (needs_update == LIGHTING_NO_UPDATE) \
		GLOB.lighting_update_lights += src; \
	if (needs_update < level)               \
		needs_update            = level;    \


// This proc will cause the light source to update the top atom, and add itself to the update queue.
/datum/light_source/proc/update(var/atom/new_top_atom)
	// This top atom is different.
	if (new_top_atom && new_top_atom != top_atom)
		// Unregister cone signal from old top_atom
		if(cone_signal_registered && top_atom)
			UnregisterSignal(top_atom, COMSIG_ATOM_DIR_CHANGE)
			cone_signal_registered = FALSE
		if(top_atom != source_atom && top_atom.light_sources) // Remove ourselves from the light sources of that top atom.
			LAZYREMOVE(top_atom.light_sources, src)

		top_atom = new_top_atom

		if (top_atom != source_atom)
			LAZYADD(top_atom.light_sources, src) // Add ourselves to the light sources of our new top atom.

		// Re-register cone signal on new top_atom if cone is active
		if(light_cone_angle > 0 && !source_atom.light_cone_dir)
			RegisterSignal(top_atom, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_holder_dir_change))
			cone_signal_registered = TRUE
			update_cone_cache()

	EFFECT_UPDATE(LIGHTING_CHECK_UPDATE)

// Will force an update without checking if it's actually needed.
/datum/light_source/proc/force_update()
	EFFECT_UPDATE(LIGHTING_FORCE_UPDATE)

// Will cause the light source to recalculate turfs that were removed or added to visibility only.
/datum/light_source/proc/vis_update()
	EFFECT_UPDATE(LIGHTING_VIS_UPDATE)

/// Recalculates cached cone direction cosines from the source atom's properties.
/datum/light_source/proc/update_cone_cache()
	var/effective_dir = source_atom.light_cone_dir
	if(!effective_dir && top_atom)
		effective_dir = top_atom.dir
	if(!effective_dir)
		effective_dir = SOUTH
	light_cone_dir = effective_dir
	var/list/vec = GLOB.light_dir_vectors[effective_dir]
	if(vec)
		cone_dir_x = vec[1]
		cone_dir_y = vec[2]
	else
		cone_dir_x = 0
		cone_dir_y = -1
	var/half_angle = light_cone_angle * 0.5
	cone_half_cos = cos(half_angle)
	cone_penumbra_cos = cos(min(half_angle + LIGHTING_CONE_PENUMBRA, 180))

/// Signal handler: when the holder (top_atom) changes direction, queue cone recalculation.
/// Does NOT update cone vars directly — defers to update_corners() which detects direction
/// change via update_cone_cache() and uses the geometry FAST path (skips expensive view()).
/datum/light_source/proc/on_holder_dir_change(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER
	if(light_cone_angle <= 0)
		return
	// Skip if final direction matches last processed direction
	if(new_dir == light_cone_dir)
		return
	// Queue for check update — update_corners() will detect the direction change
	// and use the geometry fast path instead of the view() full path
	EFFECT_UPDATE(LIGHTING_CHECK_UPDATE)

// Caches datum vars to locals before corner iteration. Call before APPLY_CORNER.
// The sheet is a pre-computed 2D lookup table of falloff values, eliminating sqrt from the hot path.
#define SETUP_CORNERS_CACHE(lighting_source)                                                       \
	var/_pixel_turf_x = lighting_source.pixel_turf.x;                                              \
	var/_pixel_turf_y = lighting_source.pixel_turf.y;                                              \
	var/list/_sheet = get_sheet();                                                                  \
	if(!islist(_sheet)) { CRASH("get_sheet() returned non-list: [_sheet] (range=[lighting_source.light_range], power=[lighting_source.light_power])"); }; \
	var/_range_offset = (length(_sheet) + 1) * 0.5;                                                \
	var/_light_power = lighting_source.light_power;                                                \
	var/_applied_lum_r = lighting_source.applied_lum_r;                                            \
	var/_applied_lum_g = lighting_source.applied_lum_g;                                            \
	var/_applied_lum_b = lighting_source.applied_lum_b;                                            \
	var/_lum_r = lighting_source.lum_r;                                                            \
	var/_lum_g = lighting_source.lum_g;                                                            \
	var/_lum_b = lighting_source.lum_b;                                                            \
	var/_cone_dir_x = lighting_source.cone_dir_x;                                                  \
	var/_cone_dir_y = lighting_source.cone_dir_y;                                                  \
	var/_cone_half_cos = lighting_source.cone_half_cos;                                            \
	var/_cone_penumbra_cos = lighting_source.cone_penumbra_cos;                                    \
	var/_cone_half_cos_sq = _cone_half_cos * _cone_half_cos;                                      \
	var/_cone_penumbra_cos_sq = _cone_penumbra_cos * _cone_penumbra_cos;                          \
	var/_cone_narrow = (_cone_half_cos >= 0 && _cone_penumbra_cos >= 0);                          \
	var/_cone_inner_sq = LIGHTING_CONE_INNER_RADIUS * LIGHTING_CONE_INNER_RADIUS;                  \
	var/_sheet_size = length(_sheet);                                                    \
	if(_sheet_size < (CEILING(lighting_source.light_range, 1) + 2) * 2 + 2) {           \
		CRASH("LUM_FALLOFF: sheet size [_sheet_size] too small for range [lighting_source.light_range]"); \
	};

// Lighter cache for remove-only operations (no sheet needed).
#define SETUP_CORNERS_REMOVAL_CACHE(lighting_source)   \
	var/_applied_lum_r = lighting_source.applied_lum_r; \
	var/_applied_lum_g = lighting_source.applied_lum_g; \
	var/_applied_lum_b = lighting_source.applied_lum_b;

// Sheet lookup: O(1) array access instead of sqrt calculation per corner.
#define LUM_FALLOFF(C) _sheet[round(C.x - _pixel_turf_x + _range_offset)][round(C.y - _pixel_turf_y + _range_offset)]

// Cone-aware variant: applies cone attenuation math per corner.
// Only used when light_cone_angle > 0. Per-corner profiler counters removed
// for performance — cone branch stats are tracked at source level after the loop.
#define APPLY_CORNER(C)                                  \
	. = LUM_FALLOFF(C);                                  \
	var/_cdx = C.x - _pixel_turf_x;                      \
	var/_cdy = C.y - _pixel_turf_y;                      \
	var/_cdist_sq = _cdx * _cdx + _cdy * _cdy;           \
	if(_cdist_sq > _cone_inner_sq) {                      \
		var/_raw_dot = _cdx * _cone_dir_x + _cdy * _cone_dir_y; \
		if(_raw_dot <= 0 && _cone_half_cos >= 0) {       \
			. = 0;                                       \
		} else if(_cone_narrow && _raw_dot > 0) {        \
			var/_raw_sq = _raw_dot * _raw_dot;           \
			if(_raw_sq < _cone_penumbra_cos_sq * _cdist_sq) { \
				. = 0;                                   \
			} else if(_raw_sq < _cone_half_cos_sq * _cdist_sq) { \
				var/_cdist = sqrt(_cdist_sq);            \
				var/_cdot = _raw_dot / _cdist;           \
				. *= (_cdot - _cone_penumbra_cos) / (_cone_half_cos - _cone_penumbra_cos); \
			};                                           \
		} else {                                         \
			var/_cdist = sqrt(_cdist_sq);                 \
			var/_cdot = _raw_dot / _cdist;               \
			if(_cdot < _cone_penumbra_cos) {             \
				. = 0;                                   \
			} else if(_cdot < _cone_half_cos) {          \
				. *= (_cdot - _cone_penumbra_cos) / (_cone_half_cos - _cone_penumbra_cos); \
			};                                           \
		};                                               \
	};                                                   \
	. *= _light_power;                                   \
	var/OLD = effect_str[C];                             \
	effect_str[C] = .;                                   \
	var/_ulc_dr = (. * _lum_r) - (OLD * _applied_lum_r); \
	var/_ulc_dg = (. * _lum_g) - (OLD * _applied_lum_g); \
	var/_ulc_db = (. * _lum_b) - (OLD * _applied_lum_b); \
	if(_ulc_dr || _ulc_dg || _ulc_db) {                 \
		C.lum_r += _ulc_dr;                              \
		C.lum_g += _ulc_dg;                              \
		C.lum_b += _ulc_db;                              \
		if(!C.needs_update) {                            \
			C.needs_update = TRUE;                       \
			GLOB.lighting_update_corners += C;           \
		};                                               \
	};

// No-cone variant: just sheet lookup + delta, skips all 9 cone branches and profiler counters.
// For 90%+ of sources (non-cone), this eliminates ~30 lines of dead cone math per corner.
#define APPLY_CORNER_NOCONE(C)                           \
	. = LUM_FALLOFF(C);                                  \
	. *= _light_power;                                   \
	var/OLD = effect_str[C];                             \
	effect_str[C] = .;                                   \
	var/_ulc_dr = (. * _lum_r) - (OLD * _applied_lum_r); \
	var/_ulc_dg = (. * _lum_g) - (OLD * _applied_lum_g); \
	var/_ulc_db = (. * _lum_b) - (OLD * _applied_lum_b); \
	if(_ulc_dr || _ulc_dg || _ulc_db) {                 \
		C.lum_r += _ulc_dr;                              \
		C.lum_g += _ulc_dg;                              \
		C.lum_b += _ulc_db;                              \
		if(!C.needs_update) {                            \
			C.needs_update = TRUE;                       \
			GLOB.lighting_update_corners += C;           \
		};                                               \
	};

#define REMOVE_CORNER(C)                                 \
	. = -effect_str[C];                                  \
	var/_ulc_rr = . * _applied_lum_r;                    \
	var/_ulc_rg = . * _applied_lum_g;                    \
	var/_ulc_rb = . * _applied_lum_b;                    \
	if(_ulc_rr || _ulc_rg || _ulc_rb) {                  \
		C.lum_r += _ulc_rr;                              \
		C.lum_g += _ulc_rg;                              \
		C.lum_b += _ulc_rb;                              \
		if(!C.needs_update) {                            \
			C.needs_update = TRUE;                       \
			GLOB.lighting_update_corners += C;           \
		};                                               \
	};

/// Returns a cached pre-computed falloff sheet for this light's range and height.
/// The sheet is a 2D list of lists indexed by x/y offsets from the light center.
/datum/light_source/proc/get_sheet()
	var/range_step = light_range > 5 ? 0.25 : LIGHTING_SHEET_RANGE_STEP
	var/range = max(1, CEILING(light_range, range_step))
	var/height = round(light_height, LIGHTING_SHEET_HEIGHT_STEP)
	var/key = "[range]-[height]-[GLOB.lighting_falloff_mode]"
	var/list/hand_back = GLOB.lighting_sheets[key]
	if(hand_back)
		return hand_back
	// Cache miss: generate new sheet
	hand_back = generate_sheet(range, height)
	if(length(GLOB.lighting_sheets) >= LIGHTING_SHEETS_MAX_ENTRIES)
		// Bulk eviction: remove 25% of oldest entries to amortize eviction cost
		var/evict_count = max(1, length(GLOB.lighting_sheets) / 4)
		GLOB.lighting_sheets.Cut(1, evict_count + 1)
	GLOB.lighting_sheets[key] = hand_back
	return hand_back

/// Generates a 2D falloff lookup table for the given range and height.
/// Pure function — no side effects or reads from the source object.
/datum/light_source/proc/generate_sheet(range, height)
	var/list/encode = list()
	// +2 buffer: +1 for pixel_turf offset (up to 1 tile), +1 for float rounding in range quantization
	var/bound_range = CEILING(range, 1) + 2
	// Corners are at 0.5 offsets from turf centers
	for(var/x in -(bound_range) - 0.5 to bound_range + 0.5)
		var/list/row = list()
		for(var/y in -(bound_range) - 0.5 to bound_range + 0.5)
			row += falloff_at_coord(x, y, range, height)
		encode += list(row)
	return encode

/// Calculates the light falloff multiplier (0 to 1) at a given x,y offset from the source.
/// Supports runtime switching between linear (with soft edge) and inverse-square modes.
/datum/light_source/proc/falloff_at_coord(x, y, range, height)
	var/dist_sq = x * x + y * y + height * height
	var/range_divisor = max(1, range)
	var/dist = sqrt(max(0, dist_sq))
	var/normalized_dist = dist / range_divisor
	if(normalized_dist >= 1)
		return 0
	if(GLOB.lighting_falloff_mode == LIGHTING_FALLOFF_INVERSE_SQUARE)
		// Inverse-square: brighter center, softer edges, more realistic light distribution
		var/raw = 1 / (1 + LIGHTING_INVERSE_SQUARE_K * normalized_dist * normalized_dist)
		// Soft edge: quadratic fade at boundary prevents hard cutoff (29% → 0% jump)
		if(normalized_dist > LIGHTING_SOFT_EDGE)
			var/t = (normalized_dist - LIGHTING_SOFT_EDGE) / (1 - LIGHTING_SOFT_EDGE)
			raw *= 1 - t * t
		return raw
	// Linear with soft edge: quadratic fade at boundary prevents visible "ring"
	// Derivative-continuous at the junction point (no visual kink)
	var/raw = 1 - normalized_dist
	if(normalized_dist > LIGHTING_SOFT_EDGE)
		var/t = (normalized_dist - LIGHTING_SOFT_EDGE) / (1 - LIGHTING_SOFT_EDGE)
		raw *= 1 - t * t
	return raw

/datum/light_source/proc/remove_lum()
	SETUP_CORNERS_REMOVAL_CACHE(src)
	applied = FALSE
	var/thing

	var/datum/lighting_corner/C
	for (thing in effect_str)
		C = thing
		REMOVE_CORNER(C)

		LAZYREMOVE(C.affecting, src)

	effect_str = null

/datum/light_source/proc/recalc_corner(var/datum/lighting_corner/C)
	SETUP_CORNERS_CACHE(src)
	LAZYINITLIST(effect_str)
	if (effect_str[C])
		REMOVE_CORNER(C)
		effect_str[C] = 0
	if(light_cone_angle > 0)
		APPLY_CORNER(C)
	else
		APPLY_CORNER_NOCONE(C)
	UNSETEMPTY(effect_str)

/datum/light_source/proc/update_corners()
	var/update = FALSE
	var/moved = FALSE // Track if position/range changed — gates the expensive view() path
	var/geometry_changed = FALSE // Track if falloff shape changed (height/cone) — invalidates falloff cache
	var/range_shrunk = FALSE // Track if range decreased — enables shrink path (skip view)
	var/atom/source_atom = src.source_atom

	if (QDELETED(source_atom))
		qdel(src)
		return

	if (source_atom.light_power != light_power)
		light_power = source_atom.light_power
		update = TRUE

	if (min(source_atom.light_range, LIGHTING_MAX_RANGE) != light_range)
		var/old_range = light_range
		light_range = min(source_atom.light_range, LIGHTING_MAX_RANGE)
		if(light_range < old_range && applied && CEILING(old_range, 1) <= CEILING(light_range, 1) + 1)
			// Small range decrease: shrink path can skip view() — just remove out-of-range corners
			// Only used when decrease is ≤1 integer step; larger decreases iterate too many old corners
			// and a fresh full path at the new (smaller) range is cheaper
			range_shrunk = TRUE
			geometry_changed = TRUE
		else
			// Range increased, first-apply, or large decrease: need view()/full path
			moved = TRUE
		update = TRUE

	if (source_atom.light_height != light_height)
		light_height = source_atom.light_height
		geometry_changed = TRUE // Different falloff sheet
		update = TRUE

	if (source_atom.light_cone_angle != light_cone_angle)
		light_cone_angle = source_atom.light_cone_angle
		if(light_cone_angle > 0)
			update_cone_cache()
			// Register signal on first cone activation — stays registered even if cone later disabled
			// (handler has early return for inactive cones, avoiding register/unregister churn)
			if(!cone_signal_registered && top_atom && !source_atom.light_cone_dir)
				RegisterSignal(top_atom, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_holder_dir_change))
				cone_signal_registered = TRUE
		// No unregister when cone disabled — handler early-returns for light_cone_angle <= 0
		geometry_changed = TRUE // Cone shape changed
		update = TRUE
	else if(light_cone_angle > 0)
		// Angle unchanged but cone active — check if resolved direction changed
		// Resolve direction cheaply first to avoid cos() calls in update_cone_cache() when unchanged
		var/effective_dir = source_atom.light_cone_dir
		if(!effective_dir)
			effective_dir = top_atom?.dir
		if(!effective_dir)
			effective_dir = SOUTH
		if(effective_dir != light_cone_dir)
			update_cone_cache()
			geometry_changed = TRUE // Cone direction changed
			update = TRUE

	if (!top_atom)
		top_atom = source_atom
		moved = TRUE
		update = TRUE

	if (!light_range || !light_power)
		qdel(src)
		return

	if (isturf(top_atom))
		if (source_turf != top_atom)
			source_turf = top_atom
			UPDATE_APPROXIMATE_PIXEL_TURF
			moved = TRUE
			update = TRUE
	else if (top_atom.loc != source_turf)
		source_turf = top_atom.loc
		UPDATE_APPROXIMATE_PIXEL_TURF
		moved = TRUE
		update = TRUE

	if (!isturf(source_turf))
		if (applied)
			remove_lum()
		return

	if (!pixel_turf)
		if (applied)
			remove_lum()
		return

	if (light_range && light_power && !applied)
		moved = TRUE // First application: need full view()
		update = TRUE

	if (source_atom.light_color != light_color)
		light_color = source_atom.light_color
		PARSE_LIGHT_COLOR(src)
		update = TRUE

	else if (applied_lum_r != lum_r || applied_lum_g != lum_g || applied_lum_b != lum_b)
		update = TRUE

	if (update)
		needs_update = LIGHTING_CHECK_UPDATE
		applied = TRUE
	else if (needs_update == LIGHTING_CHECK_UPDATE)
		return //nothing's changed

	// Visibility updates (wall opened/closed) always need full view() recalculation
	if(needs_update == LIGHTING_VIS_UPDATE || needs_update == LIGHTING_FORCE_UPDATE)
		moved = TRUE

	// FAST PATH: position/range/visibility unchanged — skip expensive view() + list diffs
	if(!moved && effect_str)
		if(range_shrunk)
			// SHRINK PATH: range decreased on existing source — skip view()
			// Reapply existing corners with new (smaller) falloff sheet.
			// Corners beyond new sheet bounds get removed.
			SETUP_CORNERS_CACHE(src)
			var/shrink_max_offset = CEILING(light_range, 1) + 1.5
			var/datum/lighting_corner/C
			var/list/to_remove
			if(light_cone_angle > 0)
				for(var/thing in effect_str)
					C = thing
					if(abs(C.x - _pixel_turf_x) > shrink_max_offset || abs(C.y - _pixel_turf_y) > shrink_max_offset)
						LAZYADD(to_remove, C)
						continue
					if(!C.active)
						continue
					APPLY_CORNER(C)
			else
				for(var/thing in effect_str)
					C = thing
					if(abs(C.x - _pixel_turf_x) > shrink_max_offset || abs(C.y - _pixel_turf_y) > shrink_max_offset)
						LAZYADD(to_remove, C)
						continue
					if(!C.active)
						continue
					APPLY_CORNER_NOCONE(C)
			// Remove out-of-range corners
			for(var/thing in to_remove)
				C = thing
				REMOVE_CORNER(C)
				LAZYREMOVE(C.affecting, src)
			if(to_remove)
				effect_str -= to_remove
		else if(!geometry_changed && applied_power)
			// FASTEST: only color/power changed — derive raw falloff from effect_str, skip ALL cone math
			// Typical for wall lights toggling power states or changing color
			var/_applied_lum_r = applied_lum_r
			var/_applied_lum_g = applied_lum_g
			var/_applied_lum_b = applied_lum_b
			var/_lum_r = lum_r
			var/_lum_g = lum_g
			var/_lum_b = lum_b
			var/datum/lighting_corner/C
			if(light_power != applied_power)
				// POWER CHANGED: recompute effect_str values with ratio
				var/_power_ratio = light_power / applied_power
				for(var/thing in effect_str)
					C = thing
					if(!C.active)
						continue
					var/OLD = effect_str[C]
					. = OLD * _power_ratio
					effect_str[C] = .
					var/_ulc_dr = (. * _lum_r) - (OLD * _applied_lum_r)
					var/_ulc_dg = (. * _lum_g) - (OLD * _applied_lum_g)
					var/_ulc_db = (. * _lum_b) - (OLD * _applied_lum_b)
					if(_ulc_dr || _ulc_dg || _ulc_db)
						C.lum_r += _ulc_dr
						C.lum_g += _ulc_dg
						C.lum_b += _ulc_db
						if(!C.needs_update)
							C.needs_update = TRUE
							GLOB.lighting_update_corners += C
			else
				// COLOR-ONLY: effect_str values unchanged, just apply color delta
				var/_dr = _lum_r - _applied_lum_r
				var/_dg = _lum_g - _applied_lum_g
				var/_db = _lum_b - _applied_lum_b
				for(var/thing in effect_str)
					C = thing
					if(!C.active)
						continue
					var/val = effect_str[C]
					var/_ulc_dr = val * _dr
					var/_ulc_dg = val * _dg
					var/_ulc_db = val * _db
					if(_ulc_dr || _ulc_dg || _ulc_db)
						C.lum_r += _ulc_dr
						C.lum_g += _ulc_dg
						C.lum_b += _ulc_db
						if(!C.needs_update)
							C.needs_update = TRUE
							GLOB.lighting_update_corners += C
		else
			// FAST: geometry changed (cone rotation, height) — recalculate falloff but skip view()
			// APPLY_CORNER uses delta pattern internally, no need for REMOVE_CORNER
			SETUP_CORNERS_CACHE(src)
			var/datum/lighting_corner/C
			if(light_cone_angle > 0)
				for(var/thing in effect_str)
					C = thing
					if(!C.active)
						continue
					APPLY_CORNER(C)
			else
				for(var/thing in effect_str)
					C = thing
					if(!C.active)
						continue
					APPLY_CORNER_NOCONE(C)

		applied_lum_r = lum_r
		applied_lum_g = lum_g
		applied_lum_b = lum_b
		applied_power = light_power
		UNSETEMPTY(effect_str)
		return

	// FULL PATH: position or range changed, need to recalculate which turfs/corners are affected
	if(!_corners_buf)
		_corners_buf = list()
	else
		_corners_buf.Cut()
	var/list/datum/lighting_corner/corners = _corners_buf
	var/datum/lighting_corner/C
	var/thing

	if (source_turf)
		var/oldlum = source_turf.luminosity
		source_turf.luminosity = CEILING(light_range, 1)
		var/list/_view_result = view(CEILING(light_range, 1), source_turf)
		for(var/turf/T in _view_result)
			if((!IS_DYNAMIC_LIGHTING(T) && !T.light_sources) || T.has_opaque_atom )
				continue
			if(!T.lighting_corners_initialised)
				T.generate_missing_corners()
			corners[T.lc_topright] = 0
			corners[T.lc_bottomright] = 0
			corners[T.lc_bottomleft] = 0
			corners[T.lc_topleft] = 0
		source_turf.luminosity = oldlum

	SETUP_CORNERS_CACHE(src)
	LAZYINITLIST(effect_str)
	var/_vis_only = (needs_update == LIGHTING_VIS_UPDATE)
	if(light_cone_angle > 0)
		for (thing in corners)
			C = thing
			if(isnull(effect_str[C]))
				// New corner — cull if raw falloff is below perceptual threshold (abs for negative-power darkness sources)
				if(C.active && abs(LUM_FALLOFF(C) * _light_power) < LIGHTING_FALLOFF_CULL_THRESHOLD)
					continue
				LAZYADD(C.affecting, src)
			else if(_vis_only)
				continue
			if (!C.active)
				effect_str[C] = 0
				continue
			APPLY_CORNER(C)
	else
		for (thing in corners)
			C = thing
			if(isnull(effect_str[C]))
				// New corner — cull if raw falloff is below perceptual threshold (abs for negative-power darkness sources)
				if(C.active && abs(LUM_FALLOFF(C) * _light_power) < LIGHTING_FALLOFF_CULL_THRESHOLD)
					continue
				LAZYADD(C.affecting, src)
			else if(_vis_only)
				continue
			if (!C.active)
				effect_str[C] = 0
				continue
			APPLY_CORNER_NOCONE(C)

	var/list/L = effect_str - corners
	for (thing in L) // Old, now gone, corners.
		C = thing
		REMOVE_CORNER(C)
		LAZYREMOVE(C.affecting, src)
	effect_str -= L


	applied_lum_r = lum_r
	applied_lum_g = lum_g
	applied_lum_b = lum_b
	applied_power = light_power

	UNSETEMPTY(effect_str)

#undef EFFECT_UPDATE
#undef SETUP_CORNERS_CACHE
#undef SETUP_CORNERS_REMOVAL_CACHE
#undef LUM_FALLOFF
#undef REMOVE_CORNER
#undef APPLY_CORNER
#undef APPLY_CORNER_NOCONE
