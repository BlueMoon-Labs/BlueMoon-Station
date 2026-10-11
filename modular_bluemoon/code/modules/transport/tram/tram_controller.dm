/// Tram specific variant of the generic linear transport controller.
/datum/transport_controller/linear/tram
	///whether this controller is active (any state we don't accept new orders, not nessecarily moving)
	var/controller_active = FALSE
	///whether all required parts of the tram are considered operational
	var/controller_operational = TRUE
	///the controller cabinet located on the tram
	var/obj/machinery/transport/tram_controller/paired_cabinet
	///the home controller located in telecoms
	var/obj/machinery/transport/tram_controller/tcomms/home_controller
	///if we're travelling, what direction are we going
	var/travel_direction = NONE
	///if we're travelling, how far do we have to go
	var/travel_remaining = 0
	///how far in total we'll be travelling
	var/travel_trip_length = 0
	///multiplier on how much damage/force the tram imparts on things it hits
	var/collision_lethality = 1
	/// reference to the navigation landmark associated with this tram. since we potentially span multiple z levels we dont actually
	/// know where on us this platform is. as long as we know THAT its on us we can just move the distance and direction between this
	/// and the destination landmark.
	var/obj/effect/landmark/transport/nav_beacon/tram/nav/nav_beacon
	/// reference to the landmark we consider ourself stationary at.
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/idle_platform
	/// reference to the destination landmark we consider ourselves travelling towards.
	var/obj/effect/landmark/transport/nav_beacon/tram/destination_platform

	var/current_speed = 0
	var/current_load = 0

	///decisecond delay between horizontal movement. cannot make the tram move faster than 1 movement per world.tick_lag.
	var/internal_movement_delay

	///version of internal_movement_delay that gets set in init and is considered our base delay if our tram gets slowed down
	var/base_internal_movement_delay

	///speed of the death machine on rails (in percent)
	var/tram_max_speed = 100

	///the world.time we should next move at. in case our speed is set to less than 1 movement per tick
	var/scheduled_move = INFINITY

	///whether we have been slowed down automatically
	var/recovery_mode = FALSE

	///how many times we moved while costing more than SStransport.max_time milliseconds per movement.
	var/recovery_activate_count = 0

	///how many times we moved while costing less than 0.5 * SStransport.max_time milliseconds per movement
	var/recovery_clear_count = 0

	///if the tram's next stop will be the tram malfunction event sequence
	var/malf_active = TRANSPORT_SYSTEM_NORMAL

	///fluff information of the tram, such as ongoing kill count and age
	var/datum/tram_mfg_info/tram_registration

	///previous trams that have been destroyed
	var/list/tram_history

	///cooldown on tram announcement system
	COOLDOWN_DECLARE(announce_cooldown)

/datum/tram_mfg_info
	///serial number of this tram (what round ID it first appeared in)
	var/serial_number
	///is it the active tram for the map
	var/active = TRUE
	///date the tram was created
	var/mfg_date
	///what map the tram is used on
	var/install_location
	///lifetime distance the tram has travelled
	var/distance_travelled = 0
	///lifetime number of players hit by the tram
	var/collisions = 0

/datum/tram_mfg_info/New(specific_transport_id)
	if(GLOB.round_id)
		serial_number = "LT306TG[add_leading("[GLOB.round_id]", 6, "0")]"
	else
		serial_number = "LT306TG[rand(100000, 999999)]"

	mfg_date = "[GLOB.year_integer + 540]-[time2text(world.timeofday, "MM-DD")]"
	install_location = specific_transport_id

/datum/tram_mfg_info/proc/load_from_json(list/json_data)
	serial_number = json_data["serial_number"]
	active = json_data["active"]
	mfg_date = json_data["mfg_date"]
	install_location = json_data["install_location"]
	distance_travelled = json_data["distance_travelled"]
	collisions = json_data["collisions"]

/datum/tram_mfg_info/proc/export_to_json()
	var/list/new_data = list()
	new_data["serial_number"] = serial_number
	new_data["active"] = active
	new_data["mfg_date"] = mfg_date
	new_data["install_location"] = install_location
	new_data["distance_travelled"] = distance_travelled
	new_data["collisions"] = collisions
	return new_data

/datum/transport_controller/linear/tram/New(obj/structure/transport/linear/tram/transport_module)
	. = ..()
	set_tram_speed(tram_max_speed)
	base_internal_movement_delay = internal_movement_delay
	tram_history = SSpersistence.load_tram_history(specific_transport_id)
	var/datum/tram_mfg_info/previous_tram = LAZYLEN(tram_history) ? tram_history[length(tram_history)] : null
	if(!isnull(previous_tram) && previous_tram.active)
		tram_registration = pop(tram_history)
	else
		tram_registration = new /datum/tram_mfg_info(specific_transport_id)

	check_starting_landmark()

/// Keeps tram_max_speed and the movement delays consistent when one of them is varedited
/datum/transport_controller/linear/tram/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == NAMEOF(src, tram_max_speed))
		set_tram_speed(tram_max_speed)
	if(var_name == NAMEOF(src, internal_movement_delay))
		internal_movement_delay = round(max(internal_movement_delay, 0.5), 0.1)
		tram_max_speed = round(50 / internal_movement_delay, 1)
	if(var_name == NAMEOF(src, base_internal_movement_delay))
		base_internal_movement_delay = round(max(base_internal_movement_delay, 0.5), 0.1)
		internal_movement_delay = max(internal_movement_delay, base_internal_movement_delay)
		tram_max_speed = round(50 / internal_movement_delay, 1)

/datum/transport_controller/linear/tram/Destroy()
	STOP_PROCESSING(SStransport, src)
	paired_cabinet = null
	home_controller = null
	set_status_code(SYSTEM_FAULT, TRUE)
	if(tram_registration)
		tram_registration.active = FALSE
		SSblackbox.record_feedback("amount", "tram_destroyed", 1)
#ifndef UNIT_TESTS
		SSpersistence.save_tram_history(specific_transport_id)
#endif
	nav_beacon = null
	idle_platform = null
	destination_platform = null
	return ..()

/datum/transport_controller/linear/tram/add_transport_modules(obj/structure/transport/linear/new_transport_module)
	. = ..()
	RegisterSignal(new_transport_module, COMSIG_MOVABLE_BUMP, PROC_REF(gracefully_break))

/// Picks up the platform the tram was mapped at and the nav beacon riding on it
/datum/transport_controller/linear/tram/check_for_landmarks(obj/structure/transport/linear/tram/new_transport_module)
	. = ..()
	for(var/turf/platform_loc as anything in new_transport_module.locs)
		var/obj/effect/landmark/transport/nav_beacon/tram/platform/initial_destination = locate() in platform_loc
		var/obj/effect/landmark/transport/nav_beacon/tram/nav/beacon = locate() in platform_loc

		if(initial_destination)
			idle_platform = initial_destination
			destination_platform = initial_destination

		if(beacon)
			nav_beacon = beacon

/// SStransport only fires on maps that have a tram
/datum/transport_controller/linear/tram/proc/check_starting_landmark()
	if(!idle_platform || !nav_beacon)
		CRASH("a tram transport controller was initialized without the required landmarks to give it direction!")

	SStransport.can_fire = TRUE

	return TRUE

/// The tram explodes if it bumps into something it cannot smash through
/datum/transport_controller/linear/tram/proc/gracefully_break(obj/structure/transport/linear/tram/source, atom/bumped_atom)
	SIGNAL_HANDLER

	travel_remaining = 0
	bumped_atom.visible_message(span_userdanger("[capitalize(source.name)] с размаху врезается в [bumped_atom]!"))
	INVOKE_ASYNC(src, PROC_REF(break_apart))

/datum/transport_controller/linear/tram/proc/break_apart()
	for(var/obj/structure/transport/linear/tram/transport_module as anything in transport_modules.Copy())
		transport_module.set_travelling(FALSE)
		for(var/explosive_target in transport_module.transport_contents.Copy())
			if(iseffect(explosive_target))
				continue

			if(isliving(explosive_target))
				explosion(explosive_target, devastation_range = rand(0, 1), heavy_impact_range = 2, light_impact_range = 3)

			else if(prob(9))
				explosion(explosive_target, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3)

		explosion(transport_module, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3)
		qdel(transport_module)

	if(!QDELETED(src))
		send_transport_status_update()

/datum/transport_controller/linear/tram/proc/calculate_route(obj/effect/landmark/transport/nav_beacon/tram/destination)
	if(destination == idle_platform)
		return FALSE

	destination_platform = destination
	travel_direction = get_dir(nav_beacon, destination_platform)
	travel_remaining = get_dist(nav_beacon, destination_platform)
	travel_trip_length = travel_remaining
	log_transport("TC: [specific_transport_id] trip calculation: src: [nav_beacon.x], [nav_beacon.y], [nav_beacon.z] dst: [destination_platform] [destination_platform.x], [destination_platform.y], [destination_platform.z] = Dir [travel_direction] Dist [travel_remaining].")
	return TRUE

/datum/transport_controller/linear/tram/proc/dispatch_transport(obj/effect/landmark/transport/nav_beacon/tram/destination_platform)
	log_transport("TC: [specific_transport_id] starting departure.")
	set_status_code(PRE_DEPARTURE, FALSE)
	if(controller_status & EMERGENCY_STOP)
		set_status_code(EMERGENCY_STOP, FALSE)
		cabinet_report('sound/machines/synth_yes.ogg', "Контроллер перезапущен.")
	nav_beacon.tram_loop.start()
	for(var/obj/structure/transport/linear/tram/transport_module as anything in transport_modules)
		if(transport_module.travelling) // a second dispatch got queued while the first one runs
			return
		if(malf_active == TRANSPORT_LOCAL_WARNING)
			if(transport_module.check_for_humans())
				throw_chance *= 1.75
				malf_active = TRANSPORT_LOCAL_FAULT
				addtimer(CALLBACK(src, PROC_REF(announce_malf_event)), 1 SECONDS)
		transport_module.verify_transport_contents()
		transport_module.internal_movement_delay = internal_movement_delay
		transport_module.glide_size_override = DELAY_TO_GLIDE_SIZE(internal_movement_delay)
		transport_module.set_travelling(TRUE)

	scheduled_move = world.time + internal_movement_delay

	START_PROCESSING(SStransport, src)

/datum/transport_controller/linear/tram/process(seconds_per_tick)
	if(isnull(paired_cabinet))
		set_status_code(SYSTEM_FAULT, TRUE)

	if(controller_status & SYSTEM_FAULT || controller_status & EMERGENCY_STOP)
		halt_and_catch_fire()
		return PROCESS_KILL

	if(!travel_remaining)
		if(!controller_operational || malf_active == TRANSPORT_LOCAL_FAULT)
			degraded_stop()
		else
			normal_stop()

		return PROCESS_KILL

	else if(world.time >= scheduled_move)
		var/start_time = TICK_USAGE_REAL
		travel_remaining--

		move_transport_horizontally(travel_direction)

		var/duration = TICK_USAGE_TO_MS(start_time)
		current_load = duration
		var/obj/structure/transport/linear/lead_module = transport_modules[1]
		current_speed = lead_module.glide_size
		if(recovery_mode)
			if(duration <= (SStransport.max_time / 2))
				recovery_clear_count++
			else
				recovery_clear_count = 0

			if(recovery_clear_count >= SStransport.max_cheap_moves)
				set_tram_speed(tram_max_speed)
				recovery_mode = FALSE
				recovery_clear_count = 0
				log_transport("TC: [specific_transport_id] removing speed limiter, performance issue resolved. Last tick was [duration]ms.")

		else if(duration > SStransport.max_time)
			recovery_activate_count++
			if(recovery_activate_count >= SStransport.max_exceeding_moves)
				message_admins("The tram at [ADMIN_JMP(lead_module)] is taking [duration] ms which is more than [SStransport.max_time] ms per movement for [recovery_activate_count] ticks. Reducing its movement speed until it recovers. If this continues to be a problem you can reset the tram contents to its original state, and clear added objects with the Reset Tram verb.")
				log_transport("TC: [specific_transport_id] activating speed limiter due to poor performance. Last tick was [duration]ms.")
				base_internal_movement_delay = internal_movement_delay
				internal_movement_delay = base_internal_movement_delay * 2
				recovery_mode = TRUE
				recovery_activate_count = 0
		else
			recovery_activate_count = max(recovery_activate_count - 1, 0)

		if(travel_remaining < 39 && COOLDOWN_FINISHED(src, announce_cooldown))
			make_announcement("Следующая станция: [destination_platform].")
			COOLDOWN_START(src, announce_cooldown, 4 SECONDS)

		scheduled_move = world.time + internal_movement_delay

/datum/transport_controller/linear/tram/proc/set_tram_speed(new_speed)
	internal_movement_delay = round(clamp(50 / new_speed, 0.5, 5), 0.1)

/datum/transport_controller/linear/tram/proc/make_announcement(broadcast)
	playsound(nav_beacon, 'modular_bluemoon/sound/machines/tram/info_chime.ogg', 100, vary = FALSE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_exponent = 1.4)
	nav_beacon.say(broadcast)

/// The cabinet beeps and says something, if it still exists
/datum/transport_controller/linear/tram/proc/cabinet_report(sound, message)
	if(isnull(paired_cabinet))
		return
	playsound(paired_cabinet, sound, 50, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	paired_cabinet.say(message)

/// Tram stops normally, performs post-trip actions and updates the tram registration.
/datum/transport_controller/linear/tram/proc/normal_stop()
	cycle_doors(CYCLE_OPEN)
	log_transport("TC: [specific_transport_id] trip completed. Info: nav_pos ([nav_beacon.x], [nav_beacon.y], [nav_beacon.z]) idle_pos ([destination_platform.x], [destination_platform.y], [destination_platform.z]).")
	nav_beacon.tram_loop.stop()
	addtimer(CALLBACK(src, PROC_REF(unlock_controls)), 2 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(platform_arrival_jingle)), 2.5 SECONDS)
	if((controller_status & SYSTEM_FAULT) && (nav_beacon.loc == destination_platform.loc))
		set_status_code(SYSTEM_FAULT, FALSE)
		cabinet_report('sound/machines/synth_yes.ogg', "Контроллер перезапущен.")
		log_transport("TC: [specific_transport_id] position data successfully reset.")
	idle_platform = destination_platform

	tram_registration.distance_travelled += (travel_trip_length - travel_remaining)
	travel_trip_length = 0
	current_speed = 0
	current_load = 0
	set_tram_speed(tram_max_speed)

/// Tram comes to an in-station degraded stop, throwing the players. Caused by power loss or tram malfunction event.
/datum/transport_controller/linear/tram/proc/degraded_stop()
	crash_fx()
	log_transport("TC: [specific_transport_id] trip completed with a degraded status. Info: [TC_TS_STATUS] nav_pos ([nav_beacon.x], [nav_beacon.y], [nav_beacon.z]) idle_pos ([destination_platform.x], [destination_platform.y], [destination_platform.z]).")
	nav_beacon.tram_loop.stop()
	addtimer(CALLBACK(src, PROC_REF(unlock_controls)), 4 SECONDS)
	if(controller_status & SYSTEM_FAULT)
		set_status_code(SYSTEM_FAULT, FALSE)
		cabinet_report('sound/machines/synth_yes.ogg', "Контроллер перезапущен.")
		log_transport("TC: [specific_transport_id] position data successfully reset. ")
	if(malf_active == TRANSPORT_LOCAL_FAULT)
		set_status_code(SYSTEM_FAULT, TRUE)
		addtimer(CALLBACK(src, PROC_REF(cycle_doors), CYCLE_OPEN), 2 SECONDS)
		malf_active = TRANSPORT_SYSTEM_NORMAL
		throw_chance = initial(throw_chance)
		cabinet_report('sound/machines/buzz-sigh.ogg', "Ошибка контроллера. Обратитесь в инженерный отдел.")
	idle_platform = destination_platform
	tram_registration.distance_travelled += (travel_trip_length - travel_remaining)
	travel_trip_length = 0
	current_speed = 0
	current_load = 0
	set_tram_speed(tram_max_speed)
	var/throw_direction = travel_direction
	for(var/obj/structure/transport/linear/tram/module in transport_modules)
		module.estop_throw(throw_direction)

/// Tram comes to an emergency stop without completing its trip. Caused by emergency stop button or some catastrophic tram failure.
/datum/transport_controller/linear/tram/proc/halt_and_catch_fire()
	if(controller_status & SYSTEM_FAULT)
		cabinet_report('sound/machines/buzz-sigh.ogg', "Ошибка контроллера. Обратитесь в инженерный отдел.")
		log_transport("TC: [specific_transport_id] Transport Controller failed!")

	if(travel_remaining)
		travel_remaining = 0
		crash_fx()
		var/throw_direction = travel_direction
		for(var/obj/structure/transport/linear/tram/module in transport_modules)
			module.estop_throw(throw_direction)
	nav_beacon.tram_loop.stop()
	addtimer(CALLBACK(src, PROC_REF(unlock_controls)), 4 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(cycle_doors), CYCLE_OPEN), 2 SECONDS)
	idle_platform = null
	log_transport("TC: [specific_transport_id] Transport Controller needs new position data from the tram.")
	tram_registration.distance_travelled += (travel_trip_length - travel_remaining)
	travel_trip_length = 0
	current_speed = 0
	current_load = 0

/// Performs a reset of the tram's position data by finding a predetermined reference landmark, then driving to it.
/datum/transport_controller/linear/tram/proc/reset_position()
	malf_active = TRANSPORT_SYSTEM_NORMAL
	if(idle_platform)
		if(get_turf(idle_platform) == get_turf(nav_beacon))
			set_status_code(SYSTEM_FAULT, FALSE)
			set_status_code(EMERGENCY_STOP, FALSE)
			cabinet_report('sound/machines/synth_yes.ogg', "Контроллер перезапущен.")
			log_transport("TC: [specific_transport_id] Transport Controller reset was requested, but the tram nav data seems correct. Info: nav_pos ([nav_beacon.x], [nav_beacon.y], [nav_beacon.z]) idle_pos ([idle_platform.x], [idle_platform.y], [idle_platform.z]).")
			return

	log_transport("TC: [specific_transport_id] performing Transport Controller reset. Locating closest reset beacon to ([nav_beacon.x], [nav_beacon.y], [nav_beacon.z])")
	var/tram_velocity_sign
	if(travel_direction & (NORTH|SOUTH))
		tram_velocity_sign = travel_direction & NORTH ? OUTBOUND : INBOUND
	else
		tram_velocity_sign = travel_direction & EAST ? OUTBOUND : INBOUND

	var/reset_beacon = closest_nav_in_travel_dir(nav_beacon, tram_velocity_sign, specific_transport_id)

	if(!reset_beacon)
		cabinet_report('sound/machines/buzz-sigh.ogg', "Перезапуск контроллера не удался. Обратитесь к производителю.")
		log_transport("TC: [specific_transport_id] non-recoverable error! Tram is at ([nav_beacon.x], [nav_beacon.y], [nav_beacon.z] [tram_velocity_sign == OUTBOUND ? "OUTBOUND" : "INBOUND"]) and can't find a reset beacon.")
		message_admins("Tram ID [specific_transport_id] is in a non-recoverable error state at [ADMIN_JMP(nav_beacon)]. If it's causing problems, delete the controller datum with the Reset Tram verb.")
		return

	travel_direction = get_dir(nav_beacon, reset_beacon)
	travel_remaining = get_dist(nav_beacon, reset_beacon)
	travel_trip_length = travel_remaining
	destination_platform = reset_beacon
	internal_movement_delay = 1.5
	cabinet_report('sound/machines/ping.ogg', "Перезапуск контроллера... Следуем к точке сброса.")
	log_transport("TC: [specific_transport_id] trip calculation: src: [nav_beacon.x], [nav_beacon.y], [nav_beacon.z] dst: [destination_platform] [destination_platform.x], [destination_platform.y], [destination_platform.z] = Dir [travel_direction] Dist [travel_remaining].")
	cycle_doors(CYCLE_CLOSED)
	set_active(TRUE)
	set_status_code(CONTROLS_LOCKED, TRUE)
	addtimer(CALLBACK(src, PROC_REF(dispatch_transport), reset_beacon), 3 SECONDS)
	log_transport("TC: [specific_transport_id] trying to reset at [destination_platform].")

/datum/transport_controller/linear/tram/proc/estop()
	cabinet_report('sound/machines/buzz-sigh.ogg', "Аварийная остановка!")
	set_status_code(EMERGENCY_STOP, TRUE)
	log_transport("TC: [specific_transport_id] requested emergency stop.")

/// Tram crash sound and visuals
/datum/transport_controller/linear/tram/proc/crash_fx()
	playsound(nav_beacon, 'modular_bluemoon/sound/vehicles/car_crash.ogg', 100, vary = FALSE, falloff_distance = DEFAULT_TRAM_LENGTH)
	nav_beacon.audible_message(span_userdanger("Раздаётся скрежет металла: трамвай резко и полностью останавливается!"))
	for(var/mob/living/tram_passenger in SSspatial_grid.orthogonal_range_search(nav_beacon, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, DEFAULT_TRAM_LENGTH - 2))
		if(tram_passenger.stat >= UNCONSCIOUS)
			continue
		shake_camera(tram_passenger, 0.2 SECONDS, 3)

/datum/transport_controller/linear/tram/proc/unlock_controls()
	controls_lock(FALSE)
	for(var/obj/structure/transport/linear/tram/transport_module as anything in transport_modules)
		transport_module.set_travelling(FALSE)
	set_active(FALSE)

/// Sets the active status for the controller and sends a signal to listeners.
/datum/transport_controller/linear/tram/proc/set_active(new_status)
	if(controller_active == new_status)
		return

	controller_active = new_status
	send_transport_status_update()
	log_transport("TC: [specific_transport_id] controller state [controller_active ? "READY > PROCESSING" : "PROCESSING > READY"].")

/// Sets the controller status bitfield
/datum/transport_controller/linear/tram/proc/set_status_code(code, value)
	if(code != DOORS_READY)
		log_transport("TC: [specific_transport_id] status change [value ? "+" : "-"][english_list(bitfield2list(code, TRANSPORT_FLAGS), nothing_text = "none", and_text = ", ")].")

	if(value)
		controller_status |= code
	else
		controller_status &= ~code
	send_transport_status_update()

/datum/transport_controller/linear/tram/proc/send_transport_status_update()
	SEND_SIGNAL(SStransport, COMSIG_TRANSPORT_UPDATED, src, controller_active, controller_status, travel_direction, destination_platform)

/// Part of the pre-departure list, checks if all doors are closed, and updates the status code accordingly.
/datum/transport_controller/linear/tram/proc/update_status()
	for(var/obj/machinery/door/airlock/tram/door as anything in SStransport.doors)
		if(door.transport_linked_id != specific_transport_id)
			continue
		if(door.crushing_in_progress)
			log_transport("TC: [specific_transport_id] door [door.id_tag] failed crush status check.")
			set_status_code(DOORS_READY, FALSE)
			return

	set_status_code(DOORS_READY, TRUE)

/datum/transport_controller/linear/tram/proc/cycle_doors(door_status, rapid)
	for(var/obj/machinery/door/airlock/tram/door as anything in SStransport.doors)
		if(door.transport_linked_id != specific_transport_id)
			continue
		switch(door_status)
			if(CYCLE_OPEN)
				INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock/tram, open), rapid)
			if(CYCLE_CLOSED)
				INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock/tram, close), rapid)

/datum/transport_controller/linear/tram/proc/notify_controller(obj/machinery/transport/tram_controller/new_cabinet)
	paired_cabinet = new_cabinet
	RegisterSignal(new_cabinet, COMSIG_MACHINERY_POWER_LOST, PROC_REF(power_lost))
	RegisterSignal(new_cabinet, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(power_restored))
	RegisterSignal(new_cabinet, COMSIG_PARENT_QDELETING, PROC_REF(on_cabinet_qdel))
	log_transport("TC: [specific_transport_id] is now paired with [new_cabinet].")
	if(controller_status & SYSTEM_FAULT)
		set_status_code(SYSTEM_FAULT, FALSE)
		reset_position()

/datum/transport_controller/linear/tram/proc/set_home_controller(obj/machinery/transport/tram_controller/tcomms/tcomms_unit)
	home_controller = tcomms_unit
	RegisterSignal(tcomms_unit, COMSIG_MACHINERY_POWER_LOST, PROC_REF(home_power_lost))
	RegisterSignal(tcomms_unit, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(home_power_restored))
	RegisterSignal(tcomms_unit, COMSIG_PARENT_QDELETING, PROC_REF(on_home_qdel))
	log_transport("TC: [specific_transport_id] is now paired with home controller [tcomms_unit].")
	if(controller_status & COMM_ERROR)
		set_status_code(COMM_ERROR, FALSE)

/datum/transport_controller/linear/tram/proc/on_cabinet_qdel(datum/source)
	SIGNAL_HANDLER
	paired_cabinet = null
	log_transport("TC: [specific_transport_id] received QDEL from controller cabinet.")
	set_status_code(SYSTEM_FAULT, TRUE)

/datum/transport_controller/linear/tram/proc/on_home_qdel(datum/source)
	SIGNAL_HANDLER
	home_controller = null
	log_transport("TC: [specific_transport_id] received QDEL from home controller.")
	set_status_code(COMM_ERROR, TRUE)

/datum/transport_controller/linear/tram/proc/home_power_lost(datum/source)
	SIGNAL_HANDLER
	set_status_code(COMM_ERROR, TRUE)

/datum/transport_controller/linear/tram/proc/home_power_restored(datum/source)
	SIGNAL_HANDLER
	set_status_code(COMM_ERROR, FALSE)

/// Tram malfunction random event. Set comm error, requiring engineering or AI intervention.
/datum/transport_controller/linear/tram/proc/start_malf_event()
	malf_active = TRANSPORT_LOCAL_WARNING
	paired_cabinet?.update_appearance()
	throw_chance *= 1.25
	log_transport("TC: [specific_transport_id] starting Tram Malfunction event.")

/datum/transport_controller/linear/tram/proc/end_malf_event()
	if(!malf_active)
		return
	malf_active = TRANSPORT_SYSTEM_NORMAL
	paired_cabinet?.update_appearance()
	throw_chance = initial(throw_chance)
	log_transport("TC: [specific_transport_id] ending Tram Malfunction event.")

/datum/transport_controller/linear/tram/proc/announce_malf_event()
	priority_announce("Автоматическая система управления потеряла связь с бортовым компьютером трамвая. Сохраняйте спокойствие: к трамваю уже направлены инженеры для перезапуска.", "Инженерный отдел [command_name()]")

/datum/transport_controller/linear/tram/proc/register_collision(points = 1)
	tram_registration.collisions += points
	SEND_TRANSPORT_SIGNAL(COMSIG_TRAM_COLLISION, SSpersistence.tram_hits_this_round)

/datum/transport_controller/linear/tram/proc/power_lost(datum/source)
	SIGNAL_HANDLER
	set_operational(FALSE)
	log_transport("TC: [specific_transport_id] power lost.")

/datum/transport_controller/linear/tram/proc/power_restored(datum/source)
	SIGNAL_HANDLER
	set_operational(TRUE)
	log_transport("TC: [specific_transport_id] power restored.")
	cycle_doors(CYCLE_OPEN)

/datum/transport_controller/linear/tram/proc/set_operational(new_value)
	controller_operational = new_value
	send_transport_status_update()

/// Returns the closest beacon of beacon_type ahead of origin in the given INBOUND/OUTBOUND direction
/datum/transport_controller/linear/tram/proc/closest_nav_in_travel_dir(atom/origin, travel_dir, beacon_type)
	if(!istype(origin) || !origin.z)
		return FALSE

	var/list/obj/effect/landmark/transport/nav_beacon/tram/inbound_candidates = list()
	var/list/obj/effect/landmark/transport/nav_beacon/tram/outbound_candidates = list()

	for(var/obj/effect/landmark/transport/nav_beacon/tram/candidate_beacon in SStransport.nav_beacons[beacon_type])
		if(candidate_beacon.z != origin.z || candidate_beacon.z != nav_beacon.z)
			continue

		switch(nav_beacon.dir)
			if(EAST, WEST)
				if(candidate_beacon.y != nav_beacon.y)
					continue
				else if(candidate_beacon.x < nav_beacon.x)
					inbound_candidates += candidate_beacon
				else
					outbound_candidates += candidate_beacon
			if(NORTH, SOUTH)
				if(candidate_beacon.x != nav_beacon.x)
					continue
				else if(candidate_beacon.y < nav_beacon.y)
					inbound_candidates += candidate_beacon
				else
					outbound_candidates += candidate_beacon

	switch(travel_dir)
		if(INBOUND)
			var/obj/effect/landmark/transport/nav_beacon/tram/selected = get_closest_atom(/obj/effect/landmark/transport/nav_beacon/tram, inbound_candidates, origin)
			if(selected)
				return selected
			stack_trace("No inbound beacon candidate found for [origin]. Cancelling dispatch.")
			return FALSE

		if(OUTBOUND)
			var/obj/effect/landmark/transport/nav_beacon/tram/selected = get_closest_atom(/obj/effect/landmark/transport/nav_beacon/tram, outbound_candidates, origin)
			if(selected)
				return selected
			stack_trace("No outbound beacon candidate found for [origin]. Cancelling dispatch.")
			return FALSE

		else
			stack_trace("Tram receieved invalid travel direction [travel_dir]. Cancelling dispatch.")

	return FALSE

/// Plays the arrival jingle associated with the platform
/datum/transport_controller/linear/tram/proc/platform_arrival_jingle()
	if(isnull(idle_platform))
		return
	playsound(idle_platform, idle_platform.arrival_sound, 60, vary = FALSE, extrarange = 7, falloff_distance = 5)

/// Pushes the tram to the nearest rod landmark along the rod's flight and returns that landmark
/datum/transport_controller/linear/tram/proc/rod_collision(obj/effect/immovablerod/collided_rod)
	log_transport("TC: [specific_transport_id] hit an immovable rod.")
	if(!controller_operational)
		return
	var/rod_velocity_sign
	if(collided_rod.dir & (NORTH|SOUTH))
		rod_velocity_sign = collided_rod.dir & NORTH ? OUTBOUND : INBOUND
	else
		rod_velocity_sign = collided_rod.dir & EAST ? OUTBOUND : INBOUND

	var/obj/effect/landmark/transport/nav_beacon/tram/nav/push_destination = closest_nav_in_travel_dir(origin = nav_beacon, travel_dir = rod_velocity_sign, beacon_type = IMMOVABLE_ROD_DESTINATIONS)
	if(!push_destination)
		return
	travel_direction = get_dir(nav_beacon, push_destination)
	travel_remaining = get_dist(nav_beacon, push_destination)
	travel_trip_length = travel_remaining
	destination_platform = push_destination
	log_transport("TC: [specific_transport_id] collided at ([nav_beacon.x], [nav_beacon.y], [nav_beacon.z]) towards [push_destination] ([push_destination.x], [push_destination.y], [push_destination.z]) Dir [travel_direction] Dist [travel_remaining].")
	priority_announce("По воле весьма странного стечения обстоятельств [station_name()] столкнулась с неподвижным стержнем. (Не спрашивайте, откуда он взялся.) У одной из трамвайных платформ отказали тормоза.\n\n\
		Наши самоотверженные инженеры уже в курсе и спешат на место - пусть и не так быстро, как недавно летел ваш трамвай.\n\n\
		Пока мы все дивимся загадочному чувству юмора вселенной, пожалуйста, держитесь подальше от путей и не заходите за жёлтую линию.", "Тормозящие новости")
	set_active(TRUE)
	set_status_code(CONTROLS_LOCKED, TRUE)
	dispatch_transport(destination_platform = push_destination)
	return push_destination

/datum/transport_controller/linear/tram/slow
	tram_max_speed = 16.5

DEFINE_BITFIELD(controller_status, list(
	"SYSTEM_FAULT" = SYSTEM_FAULT,
	"COMM_ERROR" = COMM_ERROR,
	"EMERGENCY_STOP" = EMERGENCY_STOP,
	"PRE_DEPARTURE" = PRE_DEPARTURE,
	"DOORS_READY" = DOORS_READY,
	"CONTROLS_LOCKED" = CONTROLS_LOCKED,
	"BYPASS_SENSORS" = BYPASS_SENSORS,
))
