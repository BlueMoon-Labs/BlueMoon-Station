/// One tile of a lift or tram. Connected tiles share a transport controller
/obj/structure/transport/linear
	name = "linear transport module"
	desc = "Лёгкая подъёмная платформа. Она ездит."
	icon = 'icons/obj/smooth_structures/catwalk.dmi'
	icon_state = "catwalk"
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	armor = list(MELEE = 80, BULLET = 90, LASER = 0, ENERGY = 0, BOMB = 70, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	max_integrity = 50
	layer = TRAM_FLOOR_LAYER
	plane = GAME_PLANE
	smooth = SMOOTH_MORE
	canSmoothWith = null
	obj_flags = BLOCK_Z_OUT_DOWN
	appearance_flags = PIXEL_SCALE|KEEP_TOGETHER

	///ID used to determine what transport types we can merge with
	var/transport_id = TRANSPORT_TYPE_ELEVATOR

	///what movables on our platform that we are moving
	var/list/atom/movable/transport_contents = list()
	///weakrefs to the contents we have when we're first created. stored so that admins can clear the tram to its initial state
	var/list/datum/weakref/initial_contents = list()

	///what glide_size we set our moving contents to.
	var/glide_size_override = 8
	///movables inside transport_contents who had their glide_size changed since our last movement.
	var/list/atom/movable/changed_gliders = list()

	///decisecond delay between horizontal movements. only used to give to the transport_controller
	var/internal_movement_delay = 0.5

	///master datum that controls our movement
	var/datum/transport_controller/linear/transport_controller_datum
	///what subtype of /datum/transport_controller to create for itself if no other platform on this tram has created one yet.
	var/transport_controller_type = /datum/transport_controller/linear

	///how many tiles this platform extends on the x axis
	var/width = 1
	///how many tiles this platform extends on the y axis (north-south not up-down, that would be the z axis)
	var/height = 1

	///if TRUE, this platform will late initialize and then expand to become a multitile object across all other linked platforms on this z level
	var/create_modular_set = FALSE

	/// Does our elevator warn people (with visual effects) when moving down?
	var/warns_on_down_movement = FALSE
	/// if TRUE, we will gib anyone we land on top of. if FALSE, we will just apply damage
	var/violent_landing = TRUE
	/// damage multiplier if a mob is hit by the lift while it is moving horizontally
	var/collision_lethality = 1
	/// How long does it take for the elevator to move vertically?
	var/elevator_vertical_speed = 2 SECONDS

	/// We use a radial to travel primarily, instead of a button / ui
	var/radial_travel = TRUE
	/// A lazylist of REFs to all mobs which have a radial open currently
	var/list/current_operators

/obj/structure/transport/linear/Initialize(mapload)
	. = ..()
	if(radial_travel)
		AddElement(/datum/element/contextual_screentip_bare_hands, lmb_text = "Отправить")

	set_movement_registrations()

	if(!transport_controller_datum && transport_controller_type)
		transport_controller_datum = new transport_controller_type(src)
		return INITIALIZE_HINT_LATELOAD

/obj/structure/transport/linear/LateInitialize()
	. = ..()
	transport_controller_datum?.order_platforms_by_z_level()

/obj/structure/transport/linear/Destroy()
	transport_contents.Cut()
	changed_gliders.Cut()
	transport_controller_datum = null
	return ..()

///set the movement registrations to our current turf(s) so contents moving out of our tile(s) are removed from our movement lists
/obj/structure/transport/linear/proc/set_movement_registrations(list/turfs_to_set)
	for(var/turf/turf_loc as anything in turfs_to_set || locs)
		RegisterSignal(turf_loc, COMSIG_ATOM_EXITED, PROC_REF(uncrossed_remove_item_from_transport))
		RegisterSignal(turf_loc, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_CREATED), PROC_REF(add_item_on_transport))

///unset our movement registrations from turfs that no longer contain us (or every loc if turfs_to_unset is unspecified)
/obj/structure/transport/linear/proc/unset_movement_registrations(list/turfs_to_unset)
	var/static/list/registrations = list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED, COMSIG_ATOM_CREATED)
	for(var/turf/turf_loc as anything in turfs_to_unset || locs)
		UnregisterSignal(turf_loc, registrations)

/obj/structure/transport/linear/proc/uncrossed_remove_item_from_transport(datum/source, atom/movable/gone, direction)
	SIGNAL_HANDLER
	if(!(gone.loc in locs))
		remove_item_from_transport(gone)

/obj/structure/transport/linear/proc/remove_item_from_transport(atom/movable/potential_rider)
	SIGNAL_HANDLER
	if(!(potential_rider in transport_contents))
		return

	transport_contents -= potential_rider
	changed_gliders -= potential_rider

	UnregisterSignal(potential_rider, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE))

/obj/structure/transport/linear/proc/add_item_on_transport(datum/source, atom/movable/new_transport_contents)
	SIGNAL_HANDLER
	var/static/list/blacklisted_types = typecacheof(list(/obj/structure/fluff/tram_rail, /obj/effect/decal/cleanable, /obj/structure/transport/linear, /mob/camera, /atom/movable/lighting_object))
	//prevents the tram from stealing things like landmarks, underfloor pipes and the lighting objects that live in turf contents
	if(is_type_in_typecache(new_transport_contents, blacklisted_types) || new_transport_contents.invisibility == INVISIBILITY_ABSTRACT || new_transport_contents.level == 1)
		return FALSE
	if(new_transport_contents in transport_contents)
		return FALSE

	transport_contents += new_transport_contents
	RegisterSignal(new_transport_contents, COMSIG_PARENT_QDELETING, PROC_REF(remove_item_from_transport))

	return TRUE

///adds everything on our tile that can be added to our transport_contents and initial_contents lists when we're created
/obj/structure/transport/linear/proc/add_initial_contents()
	for(var/turf/turf_loc in locs)
		for(var/atom/movable/movable_contents as anything in turf_loc)
			if(movable_contents == src)
				continue

			if(add_item_on_transport(src, movable_contents))
				var/datum/weakref/new_initial_contents = WEAKREF(movable_contents)
				if(!new_initial_contents)
					continue

				initial_contents += new_initial_contents

///verify the movables in our list of contents are actually on our loc
/obj/structure/transport/linear/proc/verify_transport_contents()
	for(var/atom/movable/movable_contents as anything in transport_contents.Copy())
		if(!(movable_contents.loc in locs))
			remove_item_from_transport(movable_contents)

/obj/structure/transport/linear/proc/check_for_humans()
	for(var/atom/movable/movable_contents as anything in transport_contents)
		if(ishuman(movable_contents))
			return TRUE

	return FALSE

///signal handler for COMSIG_MOVABLE_UPDATE_GLIDE_SIZE: when a movable in transport_contents changes its glide_size independently.
/obj/structure/transport/linear/proc/on_changed_glide_size(atom/movable/moving_contents, new_glide_size)
	SIGNAL_HANDLER
	if(new_glide_size != glide_size_override)
		changed_gliders += moving_contents

///make this tram platform multitile, expanding to cover all the tram platforms adjacent to us and deleting them. makes movement more efficient.
///the platform becoming multitile should be in the lower left corner since thats assumed to be the loc of multitile objects
/obj/structure/transport/linear/proc/create_modular_set(min_x, min_y, max_x, max_y, z)
	if(!(min_x && min_y && max_x && max_y && z))
		for(var/obj/structure/transport/linear/other_transport as anything in transport_controller_datum.transport_modules)
			if(other_transport.z != z)
				continue

			min_x = min(min_x, other_transport.x)
			max_x = max(max_x, other_transport.x)

			min_y = min(min_y, other_transport.y)
			max_y = max(max_y, other_transport.y)

	var/turf/lower_left_corner = locate(min_x, min_y, z)
	var/obj/structure/transport/linear/primary_module = locate() in lower_left_corner

	if(!primary_module)
		stack_trace("no lift in the lower left corner of a lift level!")
		return FALSE

	if(primary_module != src)
		return primary_module.create_modular_set()

	width = (max_x - min_x) + 1
	height = (max_y - min_y) + 1

	///list of turfs we dont go over. if for whatever reason we encounter an already multitile lift platform
	///we add all of its locs to this list so we dont add that lift platform multiple times as we iterate through its locs
	var/list/locs_to_skip = locs.Copy()

	bound_width = bound_width * width
	bound_height = bound_height * height

	var/last_x = max(max_x - min_x, 0)
	var/last_y = max(max_y - min_y, 0)

	for(var/y in 0 to last_y)
		var/y_pixel_offset = world.icon_size * y

		for(var/x in 0 to last_x)
			var/x_pixel_offset = world.icon_size * x

			var/turf/set_turf = locate(x + min_x, y + min_y, z)
			if(!set_turf || (set_turf in locs_to_skip))
				continue

			var/obj/structure/transport/linear/other_transport = locate() in set_turf
			if(!other_transport)
				continue

			locs_to_skip += other_transport.locs.Copy()

			other_transport.pixel_x = x_pixel_offset
			other_transport.pixel_y = y_pixel_offset

			overlays += other_transport

	for(var/obj/structure/transport/linear/other_transport in transport_controller_datum.transport_modules.Copy())
		if(other_transport == src || other_transport.z != z)
			continue

		transport_controller_datum.transport_modules -= other_transport
		for(var/atom/movable/rider as anything in other_transport.transport_contents.Copy())
			other_transport.remove_item_from_transport(rider)
			add_item_on_transport(src, rider)
		if(other_transport.initial_contents)
			initial_contents |= other_transport.initial_contents

		qdel(other_transport)

	transport_controller_datum.create_modular_set = TRUE

	var/turf/old_loc = loc

	forceMove(locate(min_x, min_y, z))
	set_movement_registrations(locs - old_loc)
	update_appearance()
	return TRUE

///returns an unordered list of all lift platforms adjacent to us. used so our transport_controller_datum can control all connected platforms.
///includes platforms directly above or below us as well. only includes platforms with an identical transport_id to our own.
/obj/structure/transport/linear/proc/module_adjacency(datum/transport_controller/transport_controller_datum)
	. = list()
	for(var/direction in GLOB.cardinals_multiz)
		var/obj/structure/transport/linear/neighbor = locate() in get_step_multiz(src, direction)
		if(!neighbor || neighbor.transport_id != transport_id)
			continue
		. += neighbor

/// Main proc for moving the lift in the direction [travel_direction]. handles horizontal and/or vertical movement for multi platformed lifts and multitile lifts.
/obj/structure/transport/linear/proc/travel(travel_direction)
	var/list/things_to_move = transport_contents
	var/turf/destination
	if(!isturf(travel_direction))
		destination = get_step_multiz(src, travel_direction)
	else
		destination = travel_direction
		travel_direction = get_dir_multiz(loc, travel_direction)

	if(!destination)
		return

	var/x_offset = ROUND_UP(bound_width / world.icon_size) - 1
	var/y_offset = ROUND_UP(bound_height / world.icon_size) - 1

	var/list/dest_locs = block(
		locate(destination.x, destination.y, destination.z),
		locate(min(destination.x + x_offset, world.maxx), min(destination.y + y_offset, world.maxy), destination.z),
	)

	var/list/entering_locs = dest_locs - locs
	var/list/exited_locs = locs - dest_locs

	if(travel_direction == DOWN)
		for(var/turf/dest_turf as anything in entering_locs)
			SEND_SIGNAL(dest_turf, COMSIG_TURF_INDUSTRIAL_LIFT_ENTER, things_to_move)

			if(iswallturf(dest_turf))
				smash_wall(dest_turf)

			for(var/mob/living/crushed in dest_turf.contents)
				to_chat(crushed, span_userdanger("[capitalize(src.name)] обрушивается на вас!"))
				if(violent_landing)
					crushed.investigate_log("has been gibbed by [src].", INVESTIGATE_DEATHS)
					crushed.gib(FALSE, FALSE, FALSE)
				else
					crushed.Paralyze(30 SECONDS, ignore_canstun = TRUE)
					crushed.apply_damage(30, BRUTE, BODY_ZONE_CHEST, wound_bonus = 30)
					crushed.apply_damage(20, BRUTE, BODY_ZONE_HEAD, wound_bonus = 25)
					crushed.apply_damage(15, BRUTE, BODY_ZONE_L_LEG, wound_bonus = 15)
					crushed.apply_damage(15, BRUTE, BODY_ZONE_R_LEG, wound_bonus = 15)
					crushed.apply_damage(15, BRUTE, BODY_ZONE_L_ARM, wound_bonus = 15)
					crushed.apply_damage(15, BRUTE, BODY_ZONE_R_ARM, wound_bonus = 15)

	else if(travel_direction == UP)
		for(var/turf/dest_turf as anything in entering_locs)
			SEND_SIGNAL(dest_turf, COMSIG_TURF_INDUSTRIAL_LIFT_ENTER, things_to_move)

			if(iswallturf(dest_turf))
				smash_wall(dest_turf)

	else
		///potentially finds a spot to throw the victim at for daring to be hit by a tram. is null if we havent found anything to throw
		var/atom/throw_target

		for(var/turf/dest_turf as anything in entering_locs)
			SEND_SIGNAL(dest_turf, COMSIG_TURF_INDUSTRIAL_LIFT_ENTER, things_to_move)

			if(iswallturf(dest_turf))
				smash_wall(dest_turf)

			if(ismineralturf(dest_turf))
				var/turf/closed/mineral/dest_mineral_turf = dest_turf
				for(var/mob/client_mob in SSspatial_grid.orthogonal_range_search(dest_mineral_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, 8))
					shake_camera(client_mob, 2, 3)
				dest_mineral_turf.gets_drilled()

			for(var/obj/structure/victim_structure in dest_turf.contents)
				if(QDELING(victim_structure))
					continue
				if(is_type_in_typecache(victim_structure, transport_controller_datum.ignored_smashthroughs))
					continue
				var/true_plane = PLANE_TO_TRUE(victim_structure.plane)
				if(!((true_plane == FLOOR_PLANE && victim_structure.layer > TRAM_RAIL_LAYER) || (true_plane == GAME_PLANE && victim_structure.layer > LOW_OBJ_LAYER)))
					continue
				if(victim_structure.anchored && initial(victim_structure.anchored))
					visible_message(span_danger("[capitalize(src.name)] проламывает [victim_structure]!"))
					victim_structure.deconstruct(FALSE)
				else
					if(!throw_target)
						throw_target = get_edge_target_turf(src, turn(travel_direction, pick(45, -45)))
					visible_message(span_danger("[capitalize(src.name)] с размаху отбрасывает [victim_structure] с дороги!"))
					victim_structure.set_anchored(FALSE)
					victim_structure.take_damage(rand(20, 25) * collision_lethality)
					victim_structure.throw_at(throw_target, 200 * collision_lethality, 4 * collision_lethality)

			for(var/obj/machinery/victim_machine in dest_turf.contents)
				if(QDELING(victim_machine))
					continue
				if(is_type_in_typecache(victim_machine, transport_controller_datum.ignored_smashthroughs))
					continue
				if(victim_machine.layer >= LOW_OBJ_LAYER)
					playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
					visible_message(span_danger("[capitalize(src.name)] сносит [victim_machine]!"))
					qdel(victim_machine)

			for(var/mob/living/victim_living in dest_turf.contents)
				if(transport_controller_datum.ignored_smashthroughs[victim_living.type])
					continue
				if(!throw_target)
					throw_target = get_edge_target_turf(src, turn(travel_direction, pick(45, -45)))
				collide_with_mob(victim_living, throw_target)

	unset_movement_registrations(exited_locs)
	group_move(things_to_move, travel_direction)
	set_movement_registrations(entering_locs)

/// Breaks a wall the module drives into
/obj/structure/transport/linear/proc/smash_wall(turf/closed/wall/hit_wall)
	do_sparks(2, FALSE, hit_wall)
	hit_wall.dismantle_wall(devastated = TRUE)
	for(var/mob/client_mob in SSspatial_grid.orthogonal_range_search(hit_wall, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, 8))
		shake_camera(client_mob, 2, 3)
	playsound(hit_wall, 'sound/effects/meteorimpact.ogg', 100, TRUE)

/// Hits a mob standing in the way of horizontal travel
/obj/structure/transport/linear/proc/collide_with_mob(mob/living/victim_living, atom/throw_target)
	var/damage_multiplier = victim_living.maxHealth * 0.01
	var/extra_ouch = FALSE
	if(internal_movement_delay <= 1) // slow trams don't cause extra damage
		for(var/obj/structure/tram/spoiler/my_spoiler in transport_contents)
			if(istype(victim_living.buckled, /obj/structure/fluff/tram_rail))
				extra_ouch = TRUE
				break
			if(get_dist(my_spoiler, victim_living) != 1)
				continue
			if(my_spoiler.deployed)
				extra_ouch = TRUE
				break

	to_chat(victim_living, span_userdanger("[capitalize(src.name)] врезается в вас!"))
	SEND_SIGNAL(victim_living, COMSIG_LIVING_HIT_BY_TRAM, src)
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	log_combat(src, victim_living, "collided with")
	var/damage = 0
	if(prob(15))
		damage = 29 * collision_lethality * damage_multiplier
	else
		damage = rand(7, 21) * collision_lethality * damage_multiplier
	victim_living.apply_damage(2 * damage, BRUTE, BODY_ZONE_HEAD, wound_bonus = 7)
	victim_living.apply_damage(3 * damage, BRUTE, BODY_ZONE_CHEST, wound_bonus = 21)
	victim_living.apply_damage(0.5 * damage, BRUTE, BODY_ZONE_L_LEG, wound_bonus = 14)
	victim_living.apply_damage(0.5 * damage, BRUTE, BODY_ZONE_R_LEG, wound_bonus = 14)
	victim_living.apply_damage(0.5 * damage, BRUTE, BODY_ZONE_L_ARM, wound_bonus = 14)
	victim_living.apply_damage(0.5 * damage, BRUTE, BODY_ZONE_R_ARM, wound_bonus = 14)

	if(extra_ouch)
		playsound(src, 'sound/effects/grillehit.ogg', 50, TRUE)
		var/obj/item/bodypart/head/head = victim_living.get_bodypart(BODY_ZONE_HEAD)
		if(head)
			log_combat(src, victim_living, "beheaded")
			head.dismember()
			victim_living.regenerate_icons()
			register_collision(points = 3)

	if(QDELETED(victim_living))
		return

	var/turf/turf_to_bloody = get_turf(victim_living)
	turf_to_bloody.add_mob_blood(victim_living)

	var/datum/callback/land_slam = CALLBACK(src, PROC_REF(tram_slam_land), victim_living)
	victim_living.throw_at(throw_target, 200 * collision_lethality, 4 * collision_lethality, callback = land_slam)

	if(victim_living.client && istype(transport_controller_datum, /datum/transport_controller/linear/tram))
		register_collision(points = 1)

/// Mobs thrown by the tram punch through plating and lattices they land on
/obj/structure/transport/linear/proc/tram_slam_land(mob/living/thrown)
	if(QDELETED(thrown))
		return
	var/turf/landing = thrown.loc
	if(!isturf(landing) || (!isopenspaceturf(landing) && !isplatingturf(landing)))
		return

	if(isplatingturf(thrown.loc))
		var/turf/open/floor/smashed_plating = thrown.loc
		thrown.visible_message(span_danger("[thrown] с силой врезается в [smashed_plating] и пробивает его насквозь!"), \
			span_userdanger("Вас с силой швыряет в [smashed_plating], и вы пробиваете его насквозь!"))
		thrown.apply_damage(rand(5, 20), BRUTE, BODY_ZONE_CHEST)
		smashed_plating.ScrapeAway(1, CHANGETURF_INHERIT_AIR)

	for(var/obj/structure/lattice/lattice in thrown.loc)
		thrown.visible_message(span_danger("[thrown] с силой врезается в [lattice] и пробивает его насквозь!"), \
			span_userdanger("Вас с силой швыряет в [lattice], и вы пробиваете его насквозь!"))
		thrown.apply_damage(rand(5, 10), BRUTE, BODY_ZONE_CHEST)
		lattice.deconstruct(FALSE)

/obj/structure/transport/linear/proc/register_collision(points = 1)
	SSpersistence.tram_hits_this_round += points
	SSblackbox.record_feedback("amount", "tram_collision", points)
	var/datum/transport_controller/linear/tram/tram_controller = transport_controller_datum
	if(!istype(tram_controller))
		return
	tram_controller.register_collision(points)

///move the movers list of movables on our tile to destination if we successfully move there first.
///this is like calling forceMove() on everything in movers and ourselves, except nothing in movers
///has destination.Entered() and origin.Exited() called on them, as only our movement can be perceived.
///none of the movers are able to react to the movement of any other mover, saving a lot of needless processing cost
///and is more sensible. without this, if you and a banana are on the same platform, when that platform moves you will slip
///on the banana even if youre not moving relative to it.
/obj/structure/transport/linear/proc/group_move(list/atom/movable/movers, movement_direction)
	if(movement_direction == NONE)
		stack_trace("a transport was told to move to somewhere it already is!")
		return FALSE

	var/vertical = movement_direction & (UP|DOWN)
	var/turf/our_dest = vertical ? get_step_multiz(src, movement_direction) : get_step(src, movement_direction)

	var/turf/mover_old_loc
	var/area/mover_old_area

	var/turf/mover_new_loc
	var/area/mover_new_area

	if(glide_size != glide_size_override)
		set_glide_size(glide_size_override)

	forceMove(our_dest)
	if(loc != our_dest || QDELETED(src))
		return FALSE

	for(var/atom/movable/mover as anything in changed_gliders)
		if(QDELETED(mover))
			movers -= mover
			continue

		if(mover.glide_size != glide_size_override)
			mover.set_glide_size(glide_size_override)

	changed_gliders.Cut()

	for(var/atom/movable/mover as anything in movers.Copy())
		if(QDELETED(mover))
			movers -= mover
			continue

		mover_old_loc = mover.loc
		mover_old_area = mover_old_loc.loc

		mover_new_loc = vertical ? get_step_multiz(mover, movement_direction) : get_step(mover, movement_direction)
		if(!mover_new_loc)
			continue
		mover.loc = mover_new_loc
		mover_new_area = mover_new_loc.loc

		if(mover_old_area != mover_new_area)
			mover_old_area.Exited(mover, mover_new_loc)
			mover_new_area.Entered(mover, mover_old_loc)

		if(mover_old_loc.z != mover_new_loc.z)
			mover.onTransitZ(mover_old_loc.z, mover_new_loc.z)

		// the platform carries them, so none of this counts as drifting
		var/was_inertia_moving = mover.inertia_moving
		mover.inertia_moving = TRUE
		mover.Moved(mover_old_loc, movement_direction, TRUE)
		mover.inertia_moving = was_inertia_moving

	return TRUE

/// reset the contents of this lift platform to its original state in case someone put too much shit on it.
/obj/structure/transport/linear/proc/reset_contents(consider_anything_past = 0, foreign_objects = TRUE, foreign_non_player_mobs = TRUE, consider_player_mobs = FALSE)
	if(!foreign_objects && !foreign_non_player_mobs && !consider_player_mobs)
		return FALSE

	consider_anything_past = isnum(consider_anything_past) ? max(consider_anything_past, 0) : 0

	if(consider_anything_past && length(transport_contents) <= consider_anything_past)
		return FALSE

	var/list/atom/movable/original_contents = list(src)
	var/list/atom/movable/foreign_contents = list()

	for(var/datum/weakref/initial_contents_ref as anything in initial_contents)
		if(!initial_contents_ref)
			continue

		var/atom/movable/resolved_contents = initial_contents_ref.resolve()
		if(!resolved_contents || !(resolved_contents in transport_contents))
			continue

		original_contents += resolved_contents

	for(var/turf/turf_loc as anything in locs)
		var/list/atom/movable/foreign_contents_in_loc = list()

		for(var/atom/movable/foreign_movable as anything in (turf_loc.contents - original_contents))
			if(istype(foreign_movable, /atom/movable/lighting_object))
				continue
			if(foreign_objects && !ismob(foreign_movable) && !istype(foreign_movable, /obj/effect/landmark/transport/nav_beacon))
				foreign_contents_in_loc += foreign_movable
				continue

			if(foreign_non_player_mobs && ismob(foreign_movable))
				var/mob/foreign_mob = foreign_movable
				if(consider_player_mobs || !foreign_mob.mind)
					foreign_contents_in_loc += foreign_mob
					continue

		if(consider_anything_past)
			foreign_contents_in_loc.len = max(foreign_contents_in_loc.len - consider_anything_past, 0)

		foreign_contents += foreign_contents_in_loc

	for(var/atom/movable/contents_to_delete as anything in foreign_contents)
		qdel(contents_to_delete)

	return TRUE

/// Callback / general proc to check if the lift is usable by the passed mob.
/obj/structure/transport/linear/proc/can_open_lift_radial(mob/living/user, starting_position)
	if(starting_position != loc)
		return FALSE
	if(IsAdminGhost(user))
		return TRUE
	if(!isliving(user))
		return FALSE
	if(user.incapacitated())
		return FALSE
	if(user.a_intent == INTENT_HARM)
		return FALSE
	if(!user.Adjacent(src))
		return FALSE

	return TRUE

/// Opens the radial for the lift, allowing the user to move it around.
/obj/structure/transport/linear/proc/open_lift_radial(mob/living/user)
	var/starting_position = loc
	if(!can_open_lift_radial(user, starting_position))
		return
	for(var/obj/structure/transport/linear/other_platform as anything in transport_controller_datum.transport_modules)
		if(REF(user) in other_platform.current_operators)
			return

	var/list/possible_directions = list()
	if(transport_controller_datum.Check_lift_move(UP))
		var/static/image/up_arrow
		if(!up_arrow)
			up_arrow = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTH)

		possible_directions["Вверх"] = up_arrow

	if(transport_controller_datum.Check_lift_move(DOWN))
		var/static/image/down_arrow
		if(!down_arrow)
			down_arrow = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTH)

		possible_directions["Вниз"] = down_arrow

	add_fingerprint(user)
	if(!length(possible_directions))
		balloon_alert(user, "лифт не работает!")
		return

	LAZYADD(current_operators, REF(user))
	var/result = show_radial_menu(
		user = user,
		anchor = src,
		choices = possible_directions,
		custom_check = CALLBACK(src, PROC_REF(can_open_lift_radial), user, starting_position),
		require_near = TRUE,
		tooltips = TRUE,
	)

	LAZYREMOVE(current_operators, REF(user))
	if(!can_open_lift_radial(user, starting_position))
		return
	if(!isnull(result) && transport_controller_datum.controller_status & CONTROLS_LOCKED)
		balloon_alert(user, "управление заблокировано!")
		return
	switch(result)
		if("Вверх")
			if(!transport_controller_datum.simple_move_wrapper(UP, elevator_vertical_speed, user))
				return

			show_fluff_message(UP, user)
			open_lift_radial(user)

		if("Вниз")
			if(!transport_controller_datum.simple_move_wrapper(DOWN, elevator_vertical_speed, user))
				return

			show_fluff_message(DOWN, user)
			open_lift_radial(user)

/obj/structure/transport/linear/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(. || !radial_travel)
		return

	open_lift_radial(user)

//ai probably shouldn't get to use lifts but they sure are great for admins to crush people with
/obj/structure/transport/linear/attack_ghost(mob/dead/observer/user)
	. = ..()
	if(. || !radial_travel || !IsAdminGhost(user))
		return

	open_lift_radial(user)

/obj/structure/transport/linear/attack_paw(mob/user)
	if(!radial_travel)
		return ..()

	open_lift_radial(user)

/obj/structure/transport/linear/attackby(obj/item/attacking_item, mob/user, params)
	if(!radial_travel)
		return ..()

	open_lift_radial(user)
	return STOP_ATTACK_PROC_CHAIN

/obj/structure/transport/linear/attack_robot(mob/user)
	if(!radial_travel)
		return ..()

	open_lift_radial(user)

/// Shows a message indicating that the lift has moved up or down.
/obj/structure/transport/linear/proc/show_fluff_message(direction, mob/user)
	if(direction == UP)
		user.visible_message(span_notice("[user] поднимает лифт."), span_notice("Вы поднимаете лифт."))

	if(direction == DOWN)
		user.visible_message(span_notice("[user] опускает лифт."), span_notice("Вы опускаете лифт."))

/obj/machinery/door/poddoor/lift
	name = "elevator door"
	desc = "Не даёт таким идиотам, как вы, шагнуть в открытую шахту лифта."
	icon = 'modular_bluemoon/icons/obj/doors/liftdoor.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/poddoor/lift/Initialize(mapload)
	if(!isnull(transport_linked_id))
		elevator_mode = TRUE
	return ..()

/obj/machinery/door/poddoor/lift/preopen
	icon_state = "open"
	density = FALSE
	opacity = FALSE

// A subtype intended for "public use"
/obj/structure/transport/linear/public
	icon = 'icons/turf/floors.dmi'
	icon_state = "rockvault"
	smooth = NONE
	warns_on_down_movement = TRUE
	violent_landing = FALSE
	elevator_vertical_speed = 3 SECONDS
	radial_travel = FALSE

/obj/structure/transport/linear/debug
	name = "transport platform"
	desc = "Лёгкая платформа. Ездит в любую сторону, кроме вверх и вниз."
	color = "#5286b9ff"
	transport_id = TRANSPORT_TYPE_DEBUG
	radial_travel = TRUE

/obj/structure/transport/linear/debug/open_lift_radial(mob/living/user)
	var/starting_position = loc
	if(!can_open_lift_radial(user, starting_position))
		return
	var/static/list/tool_list = list(
		"NORTH" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTH),
		"NORTHEAST" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTH),
		"EAST" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = EAST),
		"SOUTHEAST" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = EAST),
		"SOUTH" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTH),
		"SOUTHWEST" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTH),
		"WEST" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = WEST),
		"NORTHWEST" = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = WEST),
	)

	var/result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(can_open_lift_radial), user, starting_position), require_near = TRUE, tooltips = FALSE)
	if(!can_open_lift_radial(user, starting_position))
		return
	if(!isnull(result) && transport_controller_datum.controller_status & CONTROLS_LOCKED)
		balloon_alert(user, "управление заблокировано!")
		return

	var/static/list/direction_names = list(
		"NORTH" = NORTH,
		"NORTHEAST" = NORTHEAST,
		"EAST" = EAST,
		"SOUTHEAST" = SOUTHEAST,
		"SOUTH" = SOUTH,
		"SOUTHWEST" = SOUTHWEST,
		"WEST" = WEST,
		"NORTHWEST" = NORTHWEST,
	)
	var/direction = direction_names[result]
	if(!direction)
		return

	transport_controller_datum.move_transport_horizontally(direction)
	add_fingerprint(user)
	open_lift_radial(user)

/obj/structure/transport/linear/tram
	name = "tram subfloor"
	desc = "Решётчатое основание пола трамвая. Титановыми листами здесь собирается рама стены трамвая, а термопластиковой плиткой выкладывается пол."
	icon = 'modular_bluemoon/icons/obj/tram/tram_structure.dmi'
	icon_state = "subfloor"
	density = FALSE
	layer = TRAM_STRUCTURE_LAYER
	smooth = NONE
	transport_id = TRANSPORT_TYPE_TRAM
	transport_controller_type = /datum/transport_controller/linear/tram
	radial_travel = FALSE
	/// Set by the tram control console in late initialize
	var/travelling = FALSE

	/// Do we want this transport to link with nearby modules to make a multi-tile platform
	create_modular_set = TRUE

/obj/structure/transport/linear/tram/corner/northwest
	icon_state = "subfloor-corner-nw"

/obj/structure/transport/linear/tram/corner/southwest
	icon_state = "subfloor-corner-sw"

/obj/structure/transport/linear/tram/corner/northeast
	icon_state = "subfloor-corner-ne"

/obj/structure/transport/linear/tram/corner/southeast
	icon_state = "subfloor-corner-se"

/obj/structure/transport/linear/tram/add_item_on_transport(datum/source, atom/movable/item)
	. = ..()
	if(. && travelling)
		RegisterSignal(item, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE, PROC_REF(on_changed_glide_size))
		on_changed_glide_size(item, item.glide_size)

/obj/structure/transport/linear/tram/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/stack/thermoplastic) || istype(attacking_item, /obj/item/stack/sheet/mineral/titanium))
		var/turf/open/clicked_turf = clicked_turf(params)
		if(!istype(clicked_turf))
			return ..()
		if(istype(attacking_item, /obj/item/stack/thermoplastic))
			clicked_turf.build_with_transport_tiles(attacking_item, user)
		else
			clicked_turf.build_with_titanium(attacking_item, user)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/// The tram is one multitile object, so a click has to be mapped back to the tile under the cursor
/obj/structure/transport/linear/tram/proc/clicked_turf(params)
	var/list/modifiers = params2list(params)
	var/icon_x = text2num(modifiers?["icon-x"])
	var/icon_y = text2num(modifiers?["icon-y"])
	if(isnull(icon_x) || isnull(icon_y))
		return get_turf(src)
	var/offset_x = clamp(round((icon_x - 1) / world.icon_size), 0, width - 1)
	var/offset_y = clamp(round((icon_y - 1) / world.icon_size), 0, height - 1)
	return locate(x + offset_x, y + offset_y, z)

/obj/structure/transport/linear/tram/proc/set_travelling(travelling)
	if(src.travelling == travelling)
		return

	for(var/atom/movable/glider as anything in transport_contents)
		if(travelling)
			glider.set_glide_size(glide_size_override)
			RegisterSignal(glider, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE, PROC_REF(on_changed_glide_size))
		else
			changed_gliders -= glider
			UnregisterSignal(glider, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE)

	src.travelling = travelling

/obj/structure/transport/linear/tram/set_currently_z_moving()
	return FALSE

/obj/structure/transport/linear/tram/proc/estop_throw(throw_direction)
	for(var/mob/living/passenger in transport_contents.Copy())
		var/mob_throw_chance = transport_controller_datum.throw_chance
		if(prob(mob_throw_chance || 17.5) || HAS_TRAIT(passenger, TRAIT_CURSED))
			passenger.AddElement(/datum/element/window_smashing, 1.5 SECONDS)
		var/throw_target = get_edge_target_turf(src, throw_direction)
		passenger.throw_at(throw_target, 30, 7, force = MOVE_FORCE_OVERPOWERING)

/obj/structure/transport/linear/tram/slow
	transport_controller_type = /datum/transport_controller/linear/tram/slow
