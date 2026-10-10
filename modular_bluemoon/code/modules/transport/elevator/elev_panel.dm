/// Wall panel that sends its elevator to a chosen floor. Works both mounted on the elevator and next to the shaft
/obj/machinery/elevator_control_panel
	name = "elevator panel"
	desc = "<i>«При пожаре пользуйтесь лестницей»</i>. А значит, пользуйтесь лестницей всегда."
	density = FALSE

	icon = 'modular_bluemoon/icons/obj/machines/elevator_panel.dmi'
	icon_state = "elevpanel0"
	base_icon_state = "elevpanel"

	mouse_over_pointer = MOUSE_HAND_POINTER
	power_channel = ENVIRON
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	init_process = FALSE
	light_power = 0.5
	light_range = 1.5
	light_color = LIGHT_COLOR_DARK_BLUE

	/// Were we instantiated at mapload? Used to determine when we should link / throw errors
	var/maploaded = FALSE

	/// A weakref to the transport_controller datum we control
	var/datum/weakref/lift_weakref
	/// What specific_transport_id do we link with?
	var/linked_elevator_id

	/// A list of all possible destinations this elevator can travel.
	/// Assoc list of "Floor name" to "z level of destination".
	var/list/linked_elevator_destination
	/// If you want to override what each floor is named as, you can do so with this list.
	/// Assoc list of "floor" to "desired name", floors numbered as in tg maps: the lowest floor of the stack is "2".
	var/list/preset_destination_names

	/// What z-level did we move to last? Used for showing the user in the UI which direction we're moving.
	var/last_move_target
	/// TimerID to our door reset timer, made by emergency opening doors
	var/door_reset_timerid
	/// The light mask overlay we use
	var/light_mask = "elev-light-mask"

/obj/machinery/elevator_control_panel/Initialize(mapload)
	. = ..()

	var/static/list/tool_behaviors = list(
		TOOL_MULTITOOL = list(SCREENTIP_CONTEXT_LMB = "Сбросить панель"),
	)
	AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)
	AddElement(/datum/element/contextual_screentip_bare_hands, lmb_text = "Отправить лифт")

	maploaded = mapload
	// Non-mapload panels link here, maploaded ones in LateInitialize once every elevator part exists
	if(!mapload)
		link_with_lift(log_error = FALSE)

/obj/machinery/elevator_control_panel/LateInitialize()
	. = ..()
	if(!maploaded)
		return

	link_with_lift(log_error = TRUE)

/// Link with associated transport controllers, only log failure to find a lift in LateInit because those are mapped in
/obj/machinery/elevator_control_panel/proc/link_with_lift(log_error = FALSE)
	var/datum/transport_controller/linear/lift = get_associated_lift()
	if(!lift)
		if(log_error)
			log_mapping("Elevator control panel at [AREACOORD(src)] found no associated lift to link with, this may be a mapping error.")
		return

	lift_weakref = WEAKREF(lift)
	populate_destinations_list(lift)
	var/obj/effect/abstract/elevator_music_zone/music = GLOB.elevator_music[linked_elevator_id]
	music?.link_to_panel(src)

/obj/machinery/elevator_control_panel/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE

	var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
	if(!lift)
		return FALSE

	obj_flags |= EMAGGED

	for(var/obj/structure/transport/linear/lift_platform as anything in lift.transport_modules)
		lift_platform.violent_landing = TRUE
		lift_platform.warns_on_down_movement = FALSE
		lift_platform.elevator_vertical_speed = initial(lift_platform.elevator_vertical_speed) * 0.5

	for(var/obj/machinery/door/elevator_door as anything in GLOB.elevator_doors)
		if(elevator_door.transport_linked_id != linked_elevator_id)
			continue
		if(elevator_door.obj_flags & EMAGGED)
			continue
		elevator_door.elevator_status = LIFT_PLATFORM_UNLOCKED
		INVOKE_ASYNC(elevator_door, TYPE_PROC_REF(/obj/machinery/door, open), BYPASS_DOOR_CHECKS)
		elevator_door.obj_flags |= EMAGGED

	playsound(src, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	balloon_alert(user, "предохранители отключены")
	return TRUE

/obj/machinery/elevator_control_panel/multitool_act(mob/living/user, obj/item/tool)
	var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
	if(!lift)
		return FALSE

	balloon_alert(user, "сбрасываем панель...")
	playsound(src, 'sound/machines/locktoggle.ogg', 50, TRUE)
	if(!do_after(user, 6 SECONDS, target = src))
		balloon_alert(user, "прервано!")
		return TRUE

	if(QDELETED(lift) || !length(lift.transport_modules))
		return TRUE

	if(obj_flags & EMAGGED)
		for(var/obj/structure/transport/linear/lift_platform as anything in lift.transport_modules)
			lift_platform.violent_landing = initial(lift_platform.violent_landing)
			lift_platform.warns_on_down_movement = initial(lift_platform.warns_on_down_movement)
			lift_platform.elevator_vertical_speed = initial(lift_platform.elevator_vertical_speed)

		for(var/obj/machinery/door/elevator_door as anything in GLOB.elevator_doors)
			if(elevator_door.transport_linked_id != linked_elevator_id)
				continue
			if(!(elevator_door.obj_flags & EMAGGED))
				continue
			elevator_door.obj_flags &= ~EMAGGED
			INVOKE_ASYNC(elevator_door, TYPE_PROC_REF(/obj/machinery/door, close))

		obj_flags &= ~EMAGGED

	if(door_reset_timerid)
		deltimer(door_reset_timerid)
	reset_doors()

	balloon_alert(user, "панель сброшена")
	playsound(src, 'sound/machines/locktoggle.ogg', 50, TRUE)

	return TRUE

/// Find the elevator associated with our lift button.
/obj/machinery/elevator_control_panel/proc/get_associated_lift()
	for(var/datum/transport_controller/linear/possible_match as anything in SStransport.transports_by_type[TRANSPORT_TYPE_ELEVATOR])
		if(possible_match.specific_transport_id != linked_elevator_id)
			continue

		return possible_match

	return null

/// Goes through and populates the linked_elevator_destination list with all possible destinations the lift can go.
/obj/machinery/elevator_control_panel/proc/populate_destinations_list(datum/transport_controller/linear/linked_lift)
	var/list/raw_destinations = list()

	var/list/starting_locs = list()
	for(var/obj/structure/transport/linear/lift_piece as anything in linked_lift.transport_modules)
		starting_locs |= lift_piece.locs
		raw_destinations |= lift_piece.z

	add_destinations_in_a_direction_recursively(starting_locs, DOWN, raw_destinations)
	add_destinations_in_a_direction_recursively(starting_locs, UP, raw_destinations)

	sortTim(raw_destinations, GLOBAL_PROC_REF(cmp_numeric_dsc))

	linked_elevator_destination = list()
	for(var/z_level in raw_destinations)
		linked_elevator_destination["[z_level]"] = destination_name(z_level)

	update_static_data_for_all_viewers()

/obj/machinery/elevator_control_panel/proc/destination_name(z_level)
	var/floor = transport_floor_number(z_level)
	var/preset_name = preset_destination_names ? preset_destination_names["[floor + 1]"] : null
	return preset_name || "Этаж [floor]"

/// Номер этажа в связке z-уровней, снизу с единицы.
/proc/transport_floor_number(z_level)
	var/list/levels = SSmapping.get_connected_levels(z_level)
	return max(levels.Find(z_level), 1)

/// Recursively adds destinations to the list of linked_elevator_destination
/obj/machinery/elevator_control_panel/proc/add_destinations_in_a_direction_recursively(list/turfs_to_check, direction, list/destinations)
	if(direction != UP && direction != DOWN)
		CRASH("[type] was given an invalid direction in add_destinations_in_a_direction_recursively!")

	var/list/turf/checked_turfs = list()
	for(var/turf/place in turfs_to_check)
		if(direction == DOWN && !isopenspaceturf(place))
			return

		var/turf/next_level = get_step_multiz(place, direction)
		if(!next_level)
			return
		if(direction == UP && !isopenspaceturf(next_level))
			return

		checked_turfs += next_level

	if(!length(checked_turfs))
		return

	for(var/turf/found as anything in checked_turfs)
		destinations |= found.z

	add_destinations_in_a_direction_recursively(checked_turfs, direction, destinations)

/obj/machinery/elevator_control_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ElevatorPanel", name)
		ui.open()

/obj/machinery/elevator_control_panel/ui_status(mob/user, datum/ui_state/state)
	if(user.z != z)
		return UI_CLOSE

	if(!lift_weakref?.resolve())
		return UI_UPDATE

	if(!check_panel())
		return UI_DISABLED

	return ..()

/obj/machinery/elevator_control_panel/ui_data(mob/user)
	var/list/data = list()

	data["emergency_level"] = SECURITY_LEVEL_NAME_RU(GLOB.security_level) || "неизвестный"
	data["is_emergency"] = GLOB.security_level >= SEC_LEVEL_RED
	data["doors_open"] = !!door_reset_timerid

	var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
	if(lift && length(lift.transport_modules))
		var/obj/structure/transport/linear/lowest_module = lift.transport_modules[1]
		data["lift_exists"] = TRUE
		data["currently_moving"] = !!(lift.controller_status & CONTROLS_LOCKED)
		data["currently_moving_to_floor"] = last_move_target
		data["current_floor"] = lowest_module.z

	else
		data["lift_exists"] = FALSE
		data["currently_moving"] = FALSE
		data["current_floor"] = 0

	return data

/obj/machinery/elevator_control_panel/ui_static_data(mob/user)
	var/list/data = list()

	data["all_floor_data"] = list()
	for(var/destination in linked_elevator_destination)
		data["all_floor_data"] += list(list(
			"name" = linked_elevator_destination[destination],
			"z_level" = text2num(destination),
		))

	return data

/obj/machinery/elevator_control_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!check_panel())
		return TRUE

	switch(action)
		if("move_lift")
			if(!allowed(usr))
				balloon_alert(usr, "доступ запрещён!")
				return

			var/desired_z = text2num("[params["z"]]")
			// num2text here is required as the z is stored as strings in the list, but passed here as a number.
			if(!desired_z || !(num2text(desired_z) in linked_elevator_destination))
				return TRUE

			var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
			if(!lift || lift.controller_status & CONTROLS_LOCKED)
				return TRUE

			INVOKE_ASYNC(lift, TYPE_PROC_REF(/datum/transport_controller/linear, move_to_zlevel), desired_z, CALLBACK(src, PROC_REF(check_panel)), usr)
			last_move_target = desired_z
			return TRUE

		if("emergency_door")
			var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
			if(!lift)
				return TRUE

			if(GLOB.security_level < SEC_LEVEL_RED)
				return TRUE

			lift.update_lift_doors(action = CYCLE_OPEN)
			door_reset_timerid = addtimer(CALLBACK(src, PROC_REF(reset_doors)), 3 MINUTES, TIMER_UNIQUE|TIMER_STOPPABLE)
			return TRUE

		if("reset_doors")
			if(!door_reset_timerid)
				return TRUE

			deltimer(door_reset_timerid)
			reset_doors()
			return TRUE

/// Callback for move_to_zlevel to ensure the elevator can continue to move.
/obj/machinery/elevator_control_panel/proc/check_panel()
	if(QDELETED(src))
		return FALSE
	if(machine_stat & (NOPOWER|BROKEN))
		return FALSE

	return TRUE

/// Opens the doors on the floor the elevator is at and closes the rest
/obj/machinery/elevator_control_panel/proc/reset_doors()
	door_reset_timerid = null
	var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
	if(!lift)
		return

	var/list/zs_we_are_present_on = lift.get_zs_we_are_on()
	var/list/zs_we_are_absent = list()

	for(var/z_level in linked_elevator_destination)
		z_level = text2num(z_level)
		if(z_level in zs_we_are_present_on)
			continue

		zs_we_are_absent |= z_level

	lift.update_lift_doors(zs_we_are_present_on, action = CYCLE_OPEN)
	lift.update_lift_doors(zs_we_are_absent, action = CYCLE_CLOSED)

/obj/machinery/elevator_control_panel/update_overlays()
	. = ..()
	if(!light_mask)
		return

	if(!(machine_stat & (NOPOWER|BROKEN)) && !panel_open)
		. += emissive_appearance(icon, light_mask, alpha = alpha, offset_spokesman = src)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/elevator_control_panel, 31)
