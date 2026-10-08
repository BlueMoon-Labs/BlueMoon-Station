/// If anyone changes the hydraulic sound effect I sure hope they update this...
#define HYDRAULIC_SFX_DURATION (2 SECONDS)

///coordinate and control movement across linked transport_controllers. allows moving large single multitile platforms and many 1 tile platforms.
///also is capable of linking platforms across linked z levels
/datum/transport_controller/linear
	///the lift platforms we consider as part of this transport. ordered in order of lowest z level to highest z level after init.
	var/list/obj/structure/transport/linear/transport_modules

	/// Typepath list of what to ignore smashing through, controls all lifts
	var/static/list/ignored_smashthroughs = list(
		/obj/machinery/power/supermatter_crystal,
		/obj/structure/holosign,
		/obj/machinery/field,
		/obj/structure/fluff/tram_rail,
	)

	///taken from our lift platforms. if true we go through each z level of platforms and attempt to make the lowest left corner platform
	///into one giant multitile object the size of all other platforms on that z level.
	var/create_modular_set = FALSE

	///lift platforms have already been sorted in order of z level.
	var/z_sorted = FALSE

	///transport_id taken from our base lift platform, used to put us into SStransport.transports_by_type
	var/transport_id = TRANSPORT_TYPE_ELEVATOR

	///overridable ID string to link control units to this specific transport_controller datum. created by placing a transport id landmark object
	///somewhere on the tram, if its anywhere on the tram we'll find it in init and set this to whatever it specifies
	var/specific_transport_id

	///bitfield of various transport states
	var/controller_status = NONE

	/// probability of being thrown hard during an emergency stop
	var/throw_chance = 17.5

/datum/transport_controller/linear/New(obj/structure/transport/linear/transport_module)
	transport_id = transport_module.transport_id
	create_modular_set = transport_module.create_modular_set

	link_transport_modules(transport_module)
	if(!ignored_smashthroughs[ignored_smashthroughs[1]])
		ignored_smashthroughs = typecacheof(ignored_smashthroughs)

	LAZYADDASSOCLIST(SStransport.transports_by_type, transport_id, src)

	for(var/obj/structure/transport/linear/lift as anything in transport_modules)
		lift.add_initial_contents()

/datum/transport_controller/linear/Destroy()
	for(var/obj/structure/transport/linear/transport_module as anything in transport_modules)
		transport_module.transport_controller_datum = null
	transport_modules = null

	LAZYREMOVEASSOC(SStransport.transports_by_type, transport_id, src)
	if(isnull(SStransport.transports_by_type))
		SStransport.transports_by_type = list()

	return ..()

/datum/transport_controller/linear/proc/add_transport_modules(obj/structure/transport/linear/new_transport_module)
	if(new_transport_module in transport_modules)
		return
	for(var/obj/structure/transport/linear/other_module in new_transport_module.loc)
		if(other_module != new_transport_module)
			stack_trace("there is more than one transport module on a tile when a controller adds it. this causes problems")
			qdel(other_module)

	new_transport_module.transport_controller_datum = src
	LAZYADD(transport_modules, new_transport_module)
	RegisterSignal(new_transport_module, COMSIG_PARENT_QDELETING, PROC_REF(remove_transport_modules))

	check_for_landmarks(new_transport_module)

	if(z_sorted)
		order_platforms_by_z_level()

/datum/transport_controller/linear/proc/remove_transport_modules(obj/structure/transport/linear/old_transport_module)
	SIGNAL_HANDLER

	if(!(old_transport_module in transport_modules))
		return

	old_transport_module.transport_controller_datum = null
	LAZYREMOVE(transport_modules, old_transport_module)
	UnregisterSignal(old_transport_module, COMSIG_PARENT_QDELETING)
	if(!length(transport_modules))
		qdel(src)

///Collect all bordered platforms via a simple floodfill algorithm. allows multiz trams because its funny
/datum/transport_controller/linear/proc/link_transport_modules(obj/structure/transport/linear/base_transport_module)
	add_transport_modules(base_transport_module)
	var/list/possible_expansions = list(base_transport_module)

	while(possible_expansions.len)
		for(var/obj/structure/transport/linear/borderline as anything in possible_expansions)
			var/list/result = borderline.module_adjacency(src)
			for(var/obj/structure/transport/linear/transport_module as anything in result)
				if(transport_modules.Find(transport_module))
					continue

				add_transport_modules(transport_module)
				possible_expansions |= transport_module

			possible_expansions -= borderline

///check for any landmarks placed inside the locs of the given transport_module
/datum/transport_controller/linear/proc/check_for_landmarks(obj/structure/transport/linear/new_transport_module)
	SHOULD_CALL_PARENT(TRUE)

	for(var/turf/platform_loc as anything in new_transport_module.locs)
		var/obj/effect/landmark/transport/transport_id/id_giver = locate() in platform_loc

		if(id_giver)
			set_info_from_id_landmark(id_giver)

///set vars and such given an overriding transport_id landmark
/datum/transport_controller/linear/proc/set_info_from_id_landmark(obj/effect/landmark/transport/transport_id/landmark)
	SHOULD_CALL_PARENT(TRUE)

	if(!istype(landmark, /obj/effect/landmark/transport/transport_id))
		return

	if(landmark.specific_transport_id)
		specific_transport_id = landmark.specific_transport_id

	qdel(landmark)

///orders the lift platforms in order of lowest z level to highest z level.
/datum/transport_controller/linear/proc/order_platforms_by_z_level()
	var/list/platforms_by_z = list()
	platforms_by_z.len = world.maxz

	for(var/z in 1 to world.maxz)
		platforms_by_z[z] = list()

	for(var/obj/structure/transport/linear/transport_module as anything in transport_modules.Copy())
		if(QDELETED(transport_module) || !transport_module.z)
			transport_modules -= transport_module
			continue

		platforms_by_z[transport_module.z] += transport_module

	if(create_modular_set)
		for(var/list/z_list as anything in platforms_by_z)
			if(!length(z_list))
				continue

			create_modular_set_for_z_level(z_list)

	var/list/output = list()

	for(var/list/z_list as anything in platforms_by_z)
		output += z_list

	transport_modules = output

	z_sorted = TRUE

///goes through all platforms in the given list and finds the one in the lower left corner
/datum/transport_controller/linear/proc/create_modular_set_for_z_level(list/obj/structure/transport/linear/platforms_in_z)
	var/min_x = INFINITY
	var/max_x = 0

	var/min_y = INFINITY
	var/max_y = 0

	var/z = 0

	for(var/obj/structure/transport/linear/module_to_sort as anything in platforms_in_z)
		if(!z)
			if(!module_to_sort.z)
				stack_trace("create_modular_set_for_z_level() was given a platform in nullspace or not on a turf!")
				platforms_in_z -= module_to_sort
				continue

			z = module_to_sort.z

		if(z != module_to_sort.z)
			stack_trace("create_modular_set_for_z_level() was given lifts on different z levels!")
			platforms_in_z -= module_to_sort
			continue

		min_x = min(min_x, module_to_sort.x)
		max_x = max(max_x, module_to_sort.x)

		min_y = min(min_y, module_to_sort.y)
		max_y = max(max_y, module_to_sort.y)

	var/turf/lower_left_corner_loc = locate(min_x, min_y, z)
	if(!lower_left_corner_loc)
		CRASH("was unable to find a turf at the lower left corner of this z")

	var/obj/structure/transport/linear/lower_left_corner_transport = locate() in lower_left_corner_loc

	if(!lower_left_corner_transport)
		CRASH("there was no transport in the lower left corner of the given transport")

	platforms_in_z.Cut()
	platforms_in_z += lower_left_corner_transport

	lower_left_corner_transport.create_modular_set(min_x, min_y, max_x, max_y, z)

///returns the closest transport to the specified atom, prioritizing transports on the same z level. used for comparing distance
/datum/transport_controller/linear/proc/return_closest_platform_to(atom/comparison, allow_multiple_answers = FALSE)
	if(!istype(comparison) || !comparison.z)
		return FALSE

	var/list/obj/structure/transport/linear/candidate_platforms = list()

	for(var/obj/structure/transport/linear/platform as anything in transport_modules)
		if(platform.z == comparison.z)
			candidate_platforms += platform

	if(!length(candidate_platforms))
		return FALSE

	var/obj/structure/transport/linear/winner = candidate_platforms[1]
	var/winner_distance = get_dist(comparison, winner)

	var/list/tied_winners = list(winner)

	for(var/obj/structure/transport/linear/platform_to_sort as anything in candidate_platforms)
		var/platform_distance = get_dist(comparison, platform_to_sort)

		if(platform_distance < winner_distance)
			winner = platform_to_sort
			winner_distance = platform_distance

			if(allow_multiple_answers)
				tied_winners = list(winner)

		else if(platform_distance == winner_distance && allow_multiple_answers)
			tied_winners += platform_to_sort

	if(allow_multiple_answers)
		return tied_winners

	return winner

/// Returns a platform on the z-level which is vertically closest to the passed target_z
/datum/transport_controller/linear/proc/return_closest_platform_to_z(target_z)
	var/obj/structure/transport/linear/found_platform
	for(var/obj/structure/transport/linear/lift as anything in transport_modules)
		if(lift.z == target_z)
			found_platform = lift
			break

		if(!found_platform)
			found_platform = lift
			continue

		if(lift.z == found_platform.z)
			continue

		if(abs(found_platform.z - target_z) < abs(lift.z - target_z))
			continue

		found_platform = lift

	return found_platform

/// Returns a list of all the z-levels our transport is currently on.
/datum/transport_controller/linear/proc/get_zs_we_are_on()
	var/list/zs_we_are_present_on = list()
	for(var/obj/structure/transport/linear/lift as anything in transport_modules)
		zs_we_are_present_on |= lift.z
	return zs_we_are_present_on

/// Moves the platform UP or DOWN, this is what users invoke with their hand.
/datum/transport_controller/linear/proc/move_lift_vertically(going, mob/user)
	//transport_modules are sorted in order of lowest z to highest z, so going upwards we need to move them in reverse order to not collide
	if(going == UP)
		var/current_index = length(transport_modules)

		while(current_index > 0)
			var/obj/structure/transport/linear/platform_to_move = transport_modules[current_index]
			current_index--

			platform_to_move.travel(going)

	else if(going == DOWN)
		for(var/obj/structure/transport/linear/transport_module as anything in transport_modules)
			transport_module.travel(going)

/// Moves the platform after a passed delay.
/datum/transport_controller/linear/proc/move_after_delay(lift_move_duration, door_duration, direction, mob/user)
	if(!isnum(lift_move_duration))
		CRASH("[type] move_after_delay called with invalid duration ([lift_move_duration]).")
	if(lift_move_duration <= 0 SECONDS)
		move_lift_vertically(direction, user)
		return

	var/obj/structure/transport/linear/prime_lift = return_closest_platform_to_z(direction == UP ? world.maxz : 0)

	playsound(prime_lift, 'sound/mecha/hydraulic.ogg', 25, vary = TRUE, frequency = clamp(HYDRAULIC_SFX_DURATION / lift_move_duration, 0.33, 3))

	addtimer(CALLBACK(src, PROC_REF(move_lift_vertically), direction, user), lift_move_duration, TIMER_UNIQUE)
	if(isnum(door_duration))
		addtimer(CALLBACK(src, PROC_REF(open_lift_doors_callback)), door_duration, TIMER_UNIQUE)

	if(direction != DOWN)
		return

	var/list/turf/lift_locs = list()
	for(var/obj/structure/transport/linear/going_to_move as anything in transport_modules)
		if(!going_to_move.warns_on_down_movement)
			continue
		lift_locs |= going_to_move.locs

	for(var/turf/moving in lift_locs)
		var/turf/below_us = get_step_multiz(moving, DOWN)
		if(!below_us || (below_us in lift_locs))
			continue
		new /obj/effect/temp_visual/telegraphing/lift_travel(below_us, lift_move_duration)

/// Simple wrapper for checking if we can move 1 zlevel, and if we can, do said move.
/datum/transport_controller/linear/proc/simple_move_wrapper(direction, lift_move_duration, mob/user)
	if(!Check_lift_move(direction))
		return FALSE

	controls_lock(TRUE)
	SEND_SIGNAL(src, COMSIG_LIFT_SET_DIRECTION, direction)
	update_lift_doors(action = CYCLE_CLOSED)

	if(isnull(lift_move_duration) || lift_move_duration <= 0 SECONDS)
		move_lift_vertically(direction, user)
		update_lift_doors(get_zs_we_are_on(), action = CYCLE_OPEN)
		controls_lock(FALSE)
		return TRUE

	move_after_delay(
		lift_move_duration = lift_move_duration,
		door_duration = lift_move_duration * 1.5,
		direction = direction,
		user = user,
	)

	addtimer(CALLBACK(src, PROC_REF(finish_simple_move_wrapper)), lift_move_duration * 1.5)
	return TRUE

/// Wrap everything up from simple_move_wrapper finishing its movement
/datum/transport_controller/linear/proc/finish_simple_move_wrapper()
	SEND_SIGNAL(src, COMSIG_LIFT_SET_DIRECTION, 0)
	controls_lock(FALSE)

/// Moves the platform to the passed z-level.
/datum/transport_controller/linear/proc/move_to_zlevel(target_z, datum/callback/loop_callback, mob/user)
	if(!isnum(target_z) || target_z <= 0)
		CRASH("[type] move_to_zlevel was passed an invalid target_z ([target_z]).")

	var/obj/structure/transport/linear/prime_lift = return_closest_platform_to_z(target_z)
	var/lift_z = prime_lift.z
	if(target_z == lift_z)
		return FALSE

	var/z_difference = abs(target_z - lift_z)
	var/direction = lift_z < target_z ? UP : DOWN

	if(!Check_lift_move(direction))
		return FALSE

	controls_lock(TRUE)
	SEND_SIGNAL(src, COMSIG_LIFT_SET_DIRECTION, direction)
	var/travel_speed = prime_lift.elevator_vertical_speed

	update_lift_doors(action = CYCLE_CLOSED)
	sleep(1.1 SECONDS)
	for(var/i in 1 to z_difference)
		if(QDELETED(src) || !Check_lift_move(direction))
			break
		if(loop_callback && !loop_callback.Invoke())
			break
		move_after_delay(
			lift_move_duration = travel_speed,
			direction = direction,
			user = user,
		)
		stoplag(travel_speed + 0.1 SECONDS)
		if(QDELETED(src) || QDELETED(prime_lift))
			return

	if(QDELETED(src))
		return
	update_lift_doors(get_zs_we_are_on(), action = CYCLE_OPEN)
	SEND_SIGNAL(src, COMSIG_LIFT_SET_DIRECTION, 0)
	controls_lock(FALSE)
	return TRUE

/// Updates all blast doors and shutters that share an ID with our lift.
/datum/transport_controller/linear/proc/update_lift_doors(on_z_level, action)
	if(!isnull(on_z_level) && !islist(on_z_level))
		on_z_level = list(on_z_level)

	var/played_ding = FALSE
	for(var/obj/machinery/door/elevator_door as anything in GLOB.elevator_doors)
		if(elevator_door.transport_linked_id != specific_transport_id)
			continue
		if(on_z_level && !(elevator_door.z in on_z_level))
			continue
		switch(action)
			if(CYCLE_OPEN)
				elevator_door.elevator_status = LIFT_PLATFORM_UNLOCKED
				if(!played_ding)
					playsound(elevator_door, 'sound/machines/ping.ogg', 50, TRUE)
					played_ding = TRUE
				addtimer(CALLBACK(elevator_door, TYPE_PROC_REF(/obj/machinery/door, open)), 0.7 SECONDS)
			if(CYCLE_CLOSED)
				elevator_door.elevator_status = LIFT_PLATFORM_LOCKED
				INVOKE_ASYNC(elevator_door, TYPE_PROC_REF(/obj/machinery/door, close))
			else
				stack_trace("Elevator lift update_lift_doors called with an improper action ([action]).")

/// Helper used in callbacks to open all the doors our platform is on
/datum/transport_controller/linear/proc/open_lift_doors_callback()
	update_lift_doors(get_zs_we_are_on(), action = CYCLE_OPEN)

/// Moves the platform, this is what users invoke with their hand.
/datum/transport_controller/linear/proc/move_transport_horizontally(going)
	if(create_modular_set)
		controls_lock(TRUE)
		for(var/obj/structure/transport/linear/module_to_move as anything in transport_modules)
			module_to_move.travel(going)

		controls_lock(FALSE)
		return

	var/max_x = 0
	var/max_y = 0
	var/max_z = 0
	var/min_x = world.maxx
	var/min_y = world.maxy
	var/min_z = world.maxz

	for(var/obj/structure/transport/linear/transport_module as anything in transport_modules)
		max_z = max(max_z, transport_module.z)
		min_z = min(min_z, transport_module.z)

		min_x = min(min_x, transport_module.x)
		max_x = max(max_x, transport_module.x)

		min_y = min(min_y, transport_module.y)
		max_y = max(max_y, transport_module.y)

	// Modules are moved starting from the leading edge, so no module ever steps onto a tile another one still occupies
	for(var/z in min_z to max_z)
		if(going & WEST)
			for(var/x in min_x to max_x)
				move_column_horizontally(going, x, z, min_y, max_y)
		else
			for(var/x in max_x to min_x step -1)
				move_column_horizontally(going, x, z, min_y, max_y)

/datum/transport_controller/linear/proc/move_column_horizontally(going, x, z, min_y, max_y)
	if(going & NORTH)
		for(var/y in max_y to min_y step -1)
			var/obj/structure/transport/linear/transport_module = locate(/obj/structure/transport/linear) in locate(x, y, z)
			transport_module?.travel(going)
	else
		for(var/y in min_y to max_y)
			var/obj/structure/transport/linear/transport_module = locate(/obj/structure/transport/linear) in locate(x, y, z)
			transport_module?.travel(going)

///Check destination turfs
/datum/transport_controller/linear/proc/Check_lift_move(check_dir)
	for(var/obj/structure/transport/linear/transport_module as anything in transport_modules)
		var/turf/destination = get_step_multiz(transport_module, check_dir)
		if(!destination)
			return FALSE
		if(check_dir == UP && !isopenspaceturf(destination))
			return FALSE
		var/turf/platform_turf = get_turf(transport_module)
		if(check_dir == DOWN && !isopenspaceturf(platform_turf))
			return FALSE
	return TRUE

/// Sets transport controls_locked state. Used to prevent moving mid movement, or cooldowns.
/datum/transport_controller/linear/proc/controls_lock(state)
	if(state)
		controller_status |= CONTROLS_LOCKED
	else
		controller_status &= ~CONTROLS_LOCKED

/// resets the contents of all platforms to their original state in case someone put a bunch of shit onto the platform.
/datum/transport_controller/linear/proc/reset_lift_contents(consider_anything_past = 0, foreign_objects = TRUE, foreign_non_player_mobs = TRUE, consider_player_mobs = FALSE)
	for(var/obj/structure/transport/linear/lift_to_reset in transport_modules)
		lift_to_reset.reset_contents(consider_anything_past, foreign_objects, foreign_non_player_mobs, consider_player_mobs)

	return TRUE

#undef HYDRAULIC_SFX_DURATION
