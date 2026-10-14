/obj/machinery/button/elevator
	name = "elevator button"
	desc = "Вернись. Вернись. Вернись. Сможешь вызвать лифт?"
	icon = 'modular_bluemoon/icons/obj/machines/tram_button.dmi'
	icon_state = "tram"
	skin = "tram"
	can_alter_skin = FALSE
	device_type = /obj/item/assembly/control/elevator
	req_access = list()
	id = 1

/obj/machinery/button/elevator/Initialize(mapload, ndir, built)
	. = ..()
	AddElement(/datum/element/contextual_screentip_bare_hands, lmb_text = "Вызвать лифт")

/obj/machinery/button/elevator/examine(mob/user)
	. = ..()
	. += span_notice("На кнопке мелкая надпись...")
	. += span_notice("ЭТА КНОПКА ВЫЗЫВАЕТ ЛИФТ! ОНА ИМ НЕ УПРАВЛЯЕТ! Куда ехать, выбирают на панели в самом лифте!")

/obj/machinery/button/elevator/emag_act(mob/user)
	. = ..()
	if(device?.emag_act(user))
		return TRUE

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/button/elevator, 32)

/obj/item/assembly/control/elevator
	name = "elevator controller"
	desc = "Небольшое устройство, вызывающее лифт на текущий этаж."
	/// A weakref to the transport_controller datum we control
	var/datum/weakref/lift_weakref
	COOLDOWN_DECLARE(elevator_cooldown)

/obj/item/assembly/control/elevator/Initialize(mapload)
	. = ..()
	if(mapload)
		return INITIALIZE_HINT_LATELOAD

/obj/item/assembly/control/elevator/LateInitialize()
	. = ..()
	var/datum/transport_controller/linear/lift = get_lift()
	if(!lift)
		log_mapping("Elevator call button at [AREACOORD(src)] found no associated elevator to link with, this may be a mapping error.")
		return

	lift_weakref = WEAKREF(lift)

/// Resolves our elevator, linking to it lazily for buttons built mid-round
/obj/item/assembly/control/elevator/proc/resolve_lift()
	var/datum/transport_controller/linear/lift = lift_weakref?.resolve()
	if(lift)
		return lift
	lift = get_lift()
	if(lift)
		lift_weakref = WEAKREF(lift)
	return lift

// Emagging elevator buttons will disable safeties
/obj/item/assembly/control/elevator/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE

	var/datum/transport_controller/linear/lift = resolve_lift()
	if(!lift)
		return FALSE

	obj_flags |= EMAGGED
	for(var/obj/structure/transport/linear/lift_platform as anything in lift.transport_modules)
		lift_platform.violent_landing = TRUE
		lift_platform.warns_on_down_movement = FALSE
		lift_platform.elevator_vertical_speed = initial(lift_platform.elevator_vertical_speed) * 0.5

	for(var/obj/machinery/door/elevator_door as anything in GLOB.elevator_doors)
		if(elevator_door.transport_linked_id != lift.specific_transport_id)
			continue
		if(elevator_door.obj_flags & EMAGGED)
			continue
		elevator_door.elevator_status = LIFT_PLATFORM_UNLOCKED
		INVOKE_ASYNC(elevator_door, TYPE_PROC_REF(/obj/machinery/door, open), BYPASS_DOOR_CHECKS)
		elevator_door.obj_flags |= EMAGGED

	var/atom/balloon_alert_loc = istype(loc, /obj/machinery/button) ? loc : src
	balloon_alert_loc.balloon_alert(user, "предохранители отключены")
	return TRUE

// Multitooling emagged elevator buttons will fix the safeties
/obj/item/assembly/control/elevator/multitool_act(mob/living/user, obj/item/tool)
	if(!(obj_flags & EMAGGED))
		return ..()

	var/datum/transport_controller/linear/lift = resolve_lift()
	if(isnull(lift))
		return ..()

	for(var/obj/structure/transport/linear/lift_platform as anything in lift.transport_modules)
		lift_platform.violent_landing = initial(lift_platform.violent_landing)
		lift_platform.warns_on_down_movement = initial(lift_platform.warns_on_down_movement)
		lift_platform.elevator_vertical_speed = initial(lift_platform.elevator_vertical_speed)

	for(var/obj/machinery/door/elevator_door as anything in GLOB.elevator_doors)
		if(elevator_door.transport_linked_id != lift.specific_transport_id)
			continue
		if(!(elevator_door.obj_flags & EMAGGED))
			continue
		elevator_door.obj_flags &= ~EMAGGED
		INVOKE_ASYNC(elevator_door, TYPE_PROC_REF(/obj/machinery/door, close))

	balloon_alert(user, "предохранители восстановлены")
	obj_flags &= ~EMAGGED
	return TRUE

/obj/item/assembly/control/elevator/activate(mob/activator)
	if(!COOLDOWN_FINISHED(src, elevator_cooldown))
		return

	COOLDOWN_START(src, elevator_cooldown, 2 SECONDS)
	if(!call_elevator(activator))
		playsound(loc, 'sound/machines/buzz-two.ogg', 50, TRUE)

	COOLDOWN_START(src, elevator_cooldown, 2 SECONDS)

/// Shows the result of a call to the activator, or to whoever stands next to the button if nobody is known
/obj/item/assembly/control/elevator/proc/report(mob/activator, message)
	if(QDELETED(loc))
		return
	if(activator)
		loc.balloon_alert(activator, message)
	else
		loc.balloon_alert_to_viewers(message, vision_distance = 2)

/// Actually calls the elevator.
/// Returns FALSE if we failed to setup the move.
/// Returns TRUE if the move setup was a success, EVEN IF the move itself fails afterwards
/obj/item/assembly/control/elevator/proc/call_elevator(mob/activator)
	var/datum/transport_controller/linear/lift = resolve_lift()
	if(!lift)
		report(activator, "лифт не подключён!")
		return FALSE

	if(lift.controller_status & CONTROLS_LOCKED)
		report(activator, "лифт в пути!")
		return FALSE

	var/obj/structure/transport/linear/prime_lift = lift.return_closest_platform_to_z(loc.z)
	if(prime_lift.z == loc.z)
		INVOKE_ASYNC(lift, TYPE_PROC_REF(/datum/transport_controller/linear, open_lift_doors_callback))
		report(activator, "лифт уже здесь!")
		return TRUE

	report(activator, "лифт вызван")

	if(!lift.move_to_zlevel(loc.z, CALLBACK(src, PROC_REF(check_button))))
		report(activator, "лифт не работает!")
		return FALSE

	if(!check_button())
		return TRUE

	if(!QDELETED(prime_lift) && prime_lift.z != loc.z)
		report(activator, "лифт не работает!")
		playsound(loc, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		return TRUE

	report(activator, "лифт прибыл")
	return TRUE

/// Callback for move_to_zlevel / general proc to check if we're still in a button
/obj/item/assembly/control/elevator/proc/check_button()
	if(QDELETED(src) || !istype(loc, /obj/machinery/button))
		return FALSE
	return TRUE

/// Gets the elevator associated with our assembly / button
/obj/item/assembly/control/elevator/proc/get_lift()
	for(var/datum/transport_controller/linear/possible_match as anything in SStransport.transports_by_type[TRANSPORT_TYPE_ELEVATOR])
		if(possible_match.specific_transport_id != id)
			continue

		return possible_match

	return null
