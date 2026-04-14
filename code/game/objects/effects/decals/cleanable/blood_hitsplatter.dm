/**
 * Flying blood splatter (tgstation-style): moves across turfs, leaves trail decals, stains along the path.
 * Sprites: icons/effects/blood.dmi — hitsplatter1–3, trails_1 / trails_2
 */

/obj/effect/decal/cleanable/blood/fly_trail
	name = "blood trail"
	icon_state = "trails_1"
	random_icon_states = list("trails_1", "trails_2")
	mergeable_decal = FALSE
	persistence_allow_stacking = TRUE
	blood_state = BLOOD_STATE_BLOOD

/obj/effect/decal/cleanable/blood/hitsplatter
	name = "blood splatter"
	desc = "A spray of blood."
	pass_flags = PASSTABLE | PASSGRILLE
	icon_state = "hitsplatter1"
	random_icon_states = list("hitsplatter1", "hitsplatter2", "hitsplatter3")
	plane = GAME_PLANE
	layer = ABOVE_WINDOW_LAYER
	mergeable_decal = FALSE
	turf_loc_check = FALSE
	var/turf/prev_loc
	/// Skip floor DNA in finish when we already placed a wall/window splatter.
	var/skip = FALSE
	var/splatter_strength = 3
	var/hit_endpoint = FALSE
	var/splatter_speed = 1
	var/flight_dir = NONE
	var/datum/move_loop/blood_move_loop

/obj/effect/decal/cleanable/blood/hitsplatter/Initialize(mapload, list/datum/disease/diseases, splatter_strength)
	. = ..()
	prev_loc = get_turf(src)
	if(splatter_strength)
		src.splatter_strength = splatter_strength

/obj/effect/decal/cleanable/blood/hitsplatter/Destroy()
	detach_blood_move_loop()
	return ..()

/obj/effect/decal/cleanable/blood/hitsplatter/proc/detach_blood_move_loop()
	if(!blood_move_loop)
		return
	UnregisterSignal(blood_move_loop, list(COMSIG_MOVELOOP_PREPROCESS_CHECK, COMSIG_MOVELOOP_POSTPROCESS, COMSIG_PARENT_QDELETING))
	blood_move_loop = null

/obj/effect/decal/cleanable/blood/hitsplatter/proc/finish_flight_splat()
	if(QDELETED(src))
		return
	if(isturf(loc) && !skip && LAZYLEN(blood_DNA))
		playsound(src, 'sound/weapons/slice.ogg', 35, TRUE, -1)
		loc.add_blood_DNA(blood_DNA.Copy(), null)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/expire()
	if(QDELETED(src))
		return
	SSmove_manager.stop_looping(src)
	detach_blood_move_loop()
	finish_flight_splat()
	qdel(src)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/fly_towards(turf/target_turf, range)
	if(!target_turf || QDELETED(src))
		qdel(src)
		return
	flight_dir = get_dir(src, target_turf)
	blood_move_loop = SSmove_manager.move_towards(
		src,
		target_turf,
		splatter_speed,
		FALSE,
		splatter_speed * range,
		SSmovement,
		MOVEMENT_ABOVE_SPACE_PRIORITY,
		MOVEMENT_LOOP_START_FAST,
		null,
	)
	if(!blood_move_loop)
		qdel(src)
		return
	RegisterSignal(blood_move_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_move))
	RegisterSignal(blood_move_loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_move))
	RegisterSignal(blood_move_loop, COMSIG_PARENT_QDELETING, PROC_REF(loop_done))

/obj/effect/decal/cleanable/blood/hitsplatter/proc/pre_move(datum/move_loop/source)
	SIGNAL_HANDLER
	prev_loc = get_turf(src)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/post_move(datum/move_loop/source, success, visual_delay)
	SIGNAL_HANDLER
	if(loc == prev_loc || !isturf(loc))
		return

	for(var/atom/movable/iter_atom in loc)
		if(hit_endpoint)
			return
		if(iter_atom == src || iter_atom.invisibility || iter_atom.alpha <= 0 || (isobj(iter_atom) && !iter_atom.density))
			continue
		if(splatter_strength <= 0)
			break
		if(!LAZYLEN(blood_DNA))
			break
		iter_atom.add_blood_DNA(blood_DNA.Copy(), null)

	splatter_strength--
	if(splatter_strength <= 0)
		expire()
		return

	if(!LAZYLEN(blood_DNA))
		return

	var/obj/effect/decal/cleanable/blood/fly_trail/fly_trail = new(loc, null)
	fly_trail.dir = dir
	if(ISDIAGONALDIR(flight_dir))
		var/matrix/smear = matrix()
		smear.Turn((flight_dir == NORTHEAST || flight_dir == SOUTHWEST) ? 135 : 45)
		fly_trail.transform = smear
	fly_trail.icon_state = pick("trails_1", "trails_2")
	fly_trail.blood_DNA = blood_DNA.Copy()
	fly_trail.bloodiness = max(round(fly_trail.bloodiness * 0.34), 1)
	fly_trail.update_icon()

/obj/effect/decal/cleanable/blood/hitsplatter/proc/loop_done(datum/move_loop/source)
	SIGNAL_HANDLER
	blood_move_loop = null
	if(!QDELETED(src))
		expire()

/obj/effect/decal/cleanable/blood/hitsplatter/Bump(atom/bumped_atom)
	if(!iswallturf(bumped_atom) && !istype(bumped_atom, /obj/structure/window))
		expire()
		return

	if(istype(bumped_atom, /obj/structure/window))
		var/obj/structure/window/bumped_window = bumped_atom
		if(!bumped_window.fulltile)
			hit_endpoint = TRUE
			expire()
			return

	hit_endpoint = TRUE
	if(!isturf(prev_loc))
		abstract_move(bumped_atom)
		expire()
		return

	abstract_move(bumped_atom)
	skip = TRUE
	if(istype(bumped_atom, /obj/structure/window))
		if(land_on_window(bumped_atom))
			return

	if(!LAZYLEN(blood_DNA))
		expire()
		return

	var/obj/effect/decal/cleanable/blood/splatter/over_window/final_splatter = new(prev_loc, null)
	final_splatter.blood_DNA = blood_DNA.Copy()
	final_splatter.update_icon()
	final_splatter.pixel_x = (dir == EAST ? 32 : (dir == WEST ? -32 : 0))
	final_splatter.pixel_y = (dir == NORTH ? 32 : (dir == SOUTH ? -32 : 0))
	expire()

/obj/effect/decal/cleanable/blood/hitsplatter/proc/land_on_window(obj/structure/window/the_window)
	if(!LAZYLEN(blood_DNA))
		expire()
		return TRUE
	if(!the_window.fulltile)
		return FALSE
	var/obj/effect/decal/cleanable/blood/splatter/over_window/final_splatter = new(prev_loc, null)
	final_splatter.blood_DNA = blood_DNA.Copy()
	final_splatter.update_icon()
	final_splatter.forceMove(the_window)
	the_window.vis_contents += final_splatter
	expire()
	return TRUE

/obj/effect/decal/cleanable/blood/splatter/over_window
	layer = ABOVE_WINDOW_LAYER
	plane = GAME_PLANE
	alpha = 180

/obj/effect/decal/cleanable/blood/splatter/over_window/NeverShouldHaveComeHere(turf/here_turf)
	return isgroundlessturf(here_turf)
