/// An indicator display aka an elevator hall lantern w/ floor number
/obj/machinery/lift_indicator
	name = "elevator indicator"
	desc = "Показывает, на каком этаже лифт и куда он едет."
	icon = 'modular_bluemoon/icons/obj/machines/lift_indicator.dmi'
	icon_state = "lift_indo-base"
	base_icon_state = "lift_indo-"
	max_integrity = 500
	integrity_failure = 0.25
	idle_power_usage = 5
	active_power_usage = 20
	anchored = TRUE
	density = FALSE
	init_process = FALSE

	light_range = 1
	light_power = 1
	light_color = COLOR_DISPLAY_BLUE

	maptext_x = 18
	maptext_y = 20
	maptext_width = 8
	maptext_height = 16

	/// What specific_transport_id do we link with?
	var/linked_elevator_id
	/// 'Floors' for display purposes are by default offset by 1 from their actual z-levels
	var/lowest_floor_offset = 1
	/// Weakref to the transport.
	var/datum/weakref/lift_ref
	/// Positive for going up, negative going down, 0 for stopped
	var/current_lift_direction = 0
	/// The elevator's current floor relative to its lowest floor being 1
	var/current_lift_floor = 1

/obj/machinery/lift_indicator/LateInitialize()
	. = ..()

	for(var/datum/transport_controller/linear/possible_match as anything in SStransport.transports_by_type[TRANSPORT_TYPE_ELEVATOR])
		if(possible_match.specific_transport_id != linked_elevator_id)
			continue

		lift_ref = WEAKREF(possible_match)
		RegisterSignal(possible_match, COMSIG_LIFT_SET_DIRECTION, PROC_REF(on_lift_direction))
		break

	update_operating()

/obj/machinery/lift_indicator/Destroy()
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/lift_indicator/examine(mob/user)
	. = ..()

	if(!is_operational())
		. += span_notice("Табло не горит.")
		return

	var/dirtext
	switch(current_lift_direction)
		if(UP)
			dirtext = "едет вверх"
		if(DOWN)
			dirtext = "едет вниз"
		else
			dirtext = "стоит"

	. += span_notice("Лифт на этаже [current_lift_floor] и [dirtext].")

/// Update state, and only process if elevator is moving.
/obj/machinery/lift_indicator/proc/on_lift_direction(datum/source, direction)
	SIGNAL_HANDLER

	if(!lift_ref?.resolve())
		return

	set_lift_state(direction, current_lift_floor)
	update_operating()

/obj/machinery/lift_indicator/on_set_is_operational(old_value)
	. = ..()
	update_operating()

/// Update processing state.
/obj/machinery/lift_indicator/proc/update_operating()
	if(process() != PROCESS_KILL)
		START_PROCESSING(SSmachines, src)
		return TRUE
	STOP_PROCESSING(SSmachines, src)
	return FALSE

/obj/machinery/lift_indicator/process()
	var/datum/transport_controller/linear/lift = lift_ref?.resolve()

	if(!lift || !is_operational() || !length(lift.transport_modules))
		set_lift_state(0, 0, force = !is_operational())
		return PROCESS_KILL

	var/obj/structure/transport/linear/lift_part = lift.transport_modules[1]

	if(QDELETED(lift_part))
		set_lift_state(0, 0, force = !is_operational())
		return PROCESS_KILL

	set_lift_state(current_lift_direction, lift_part.z - lowest_floor_offset)

	if(!current_lift_direction)
		return PROCESS_KILL

/// Set the state and update appearance.
/obj/machinery/lift_indicator/proc/set_lift_state(new_direction, new_floor, force = FALSE)
	if(new_direction == current_lift_direction && new_floor == current_lift_floor && !force)
		return

	current_lift_direction = new_direction
	current_lift_floor = new_floor
	update_appearance()

/obj/machinery/lift_indicator/update_appearance(updates)
	. = ..()

	if(!is_operational())
		set_light(l_on = FALSE)
		maptext = ""
		return

	set_light(l_on = TRUE)
	maptext = "<div style='font-family: TinyUnicode; font-size: 12pt; color: [COLOR_DISPLAY_BLUE]'>[current_lift_floor]</div>"

/obj/machinery/lift_indicator/update_overlays()
	. = ..()

	if(!is_operational())
		return

	. += emissive_appearance(icon, "[base_icon_state]e", alpha = src.alpha, offset_spokesman = src)

	if(!current_lift_direction)
		return

	var/arrow_icon_state = "[base_icon_state][current_lift_direction == UP ? "up" : "down"]"

	. += mutable_appearance(icon, arrow_icon_state)
	. += emissive_appearance(icon, "[arrow_icon_state]e", alpha = src.alpha, offset_spokesman = src)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/lift_indicator, 32)
