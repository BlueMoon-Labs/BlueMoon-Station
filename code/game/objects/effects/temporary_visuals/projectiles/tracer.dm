/proc/generate_tracer_between_points(datum/point/starting, datum/point/ending, beam_type, color, qdel_in = 5, light_range = 2, light_color_override, light_intensity = 1, list/turfs)		//Do not pass z-crossing points as that will not be properly (and likely will never be properly until it's absolutely needed) supported!
	if(!istype(starting) || !istype(ending) || !ispath(beam_type))
		return
	var/datum/point/midpoint = point_midpoint_points(starting, ending)
	var/obj/effect/projectile/tracer/PB = new beam_type
	if(isnull(light_color_override))
		light_color_override = color
	PB.apply_vars(angle_between_points(starting, ending), midpoint.return_px(), midpoint.return_py(), color, pixel_length_between_points(starting, ending) / world.icon_size, midpoint.return_turf(), 0)
	. = PB
	if(light_range > 0 && light_intensity > 0)
		var/list/turf/line = getline(starting.return_turf(), ending.return_turf())
		// With a turfs list the caller lights the whole beam path at once (generate_tracer_lighting).
		if(islist(turfs))
			for(var/turf/line_turf as anything in line)
				turfs[line_turf] = TRUE
		else
			var/list/lights = generate_tracer_lighting(line, light_color_override, light_range, light_intensity)
			if(length(lights))
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(______qdel_list_wrapper), lights), qdel_in > 0 ? qdel_in : 5)
	if(qdel_in)
		QDEL_IN(PB, qdel_in)

/// A beam light of this range or less lights only the four corners of its own tile.
#define TRACER_LIGHT_OWN_TILE_RANGE 1.5

/**
 * Lights a beam path, a turf list in path order.
 * A short-range light touches only its own tile corners, and inside a straight run two neighbours share a corner edge,
 * so every other tile at double power gives the shared corners the same sum. The alternation goes on through turns; only the edges next to path ends and diagonal steps differ by one light.
 */
/proc/generate_tracer_lighting(list/turf/path, color, range, intensity)
	. = list()
	var/count = length(path)
	if(!count || range <= 0 || intensity <= 0)
		return
	var/list/weights = new /list(count)
	for(var/i in 1 to count)
		weights[i] = 1
	if(max(range, MINIMUM_USEFUL_LIGHT_RANGE) <= TRACER_LIGHT_OWN_TILE_RANGE)
		var/run_start = 1
		while(run_start < count)
			var/turf/first = path[run_start]
			var/turf/second = path[run_start + 1]
			var/step_x = second.x - first.x
			var/step_y = second.y - first.y
			if(abs(step_x) + abs(step_y) != 1 || first.z != second.z)
				run_start++
				continue
			var/run_end = run_start + 1
			while(run_end < count)
				var/turf/current = path[run_end]
				var/turf/next = path[run_end + 1]
				if(next.x - current.x != step_x || next.y - current.y != step_y || next.z != current.z)
					break
				run_end++
			// A run that starts on a turn tile with no light of its own goes on with the alternation shifted.
			var/phase = weights[run_start] == 0 ? 0 : 2
			for(var/i in run_start + 1 to run_end - 1)
				weights[i] = (i - run_start) % 2 ? 2 - phase : phase
			// A turn into another straight run (a reflector) keeps the alternation, or the turn tile and its neighbours get half the light.
			if(run_end < count)
				var/turf/turn_turf = path[run_end]
				var/turf/after_turn = path[run_end + 1]
				if(abs(after_turn.x - turn_turf.x) + abs(after_turn.y - turn_turf.y) == 1 && after_turn.z == turn_turf.z)
					weights[run_end] = 2 - weights[run_end - 1]
			run_start = run_end
	for(var/i in 1 to count)
		if(weights[i])
			. += new /obj/effect/projectile_lighting(path[i], color, range, intensity * weights[i])

#undef TRACER_LIGHT_OWN_TILE_RANGE

/obj/effect/projectile/tracer
	name = "beam"
	icon = 'icons/obj/projectiles_tracer.dmi'

/obj/effect/projectile/tracer/laser
	name = "laser"
	icon_state = "beam"

/obj/effect/projectile/tracer/laser/blue
	icon_state = "beam_blue"

/obj/effect/projectile/tracer/disabler
	name = "disabler"
	icon_state = "beam_omni"

/obj/effect/projectile/tracer/xray
	name = "\improper X-ray laser"
	icon_state = "xray"

/obj/effect/projectile/tracer/pulse
	name = "pulse laser"
	icon_state = "u_laser"

/obj/effect/projectile/tracer/plasma_cutter
	name = "plasma blast"
	icon_state = "plasmacutter"

/obj/effect/projectile/tracer/stun
	name = "stun beam"
	icon_state = "stun"

/obj/effect/projectile/tracer/heavy_laser
	name = "heavy laser"
	icon_state = "beam_heavy"

//BEAM RIFLE
/obj/effect/projectile/tracer/tracer/beam_rifle
	icon_state = "tracer_beam"

/obj/effect/projectile/tracer/tracer/aiming
	icon_state = "pixelbeam_greyscale"
	layer = BYOND_LIGHTING_LAYER
	plane = BYOND_LIGHTING_PLANE

/obj/effect/projectile/tracer/wormhole
	icon_state = "wormhole_g"

/obj/effect/projectile/tracer/laser/wavemotion
	name = "particle trail"
	icon_state = "tracer_wavemotion"

/obj/effect/projectile/tracer/laser/emitter
	name = "emitter beam"
	icon_state = "emitter"
