/obj/machinery/computer/tram_controls
	name = "tram controls"
	desc = "Пульт трамвая: говорите ему, куда ехать, и, возможно, он туда даже доедет. Я здесь, чтобы описать управление, а не вселять уверенность."
	icon = 'modular_bluemoon/icons/obj/machines/tram_computer.dmi'
	icon_state = "tram_controls"
	base_icon_state = "tram"
	icon_screen = TRAMSTATION_LINE_1
	icon_keyboard = null
	layer = SIGN_LAYER
	density = FALSE
	max_integrity = 400
	integrity_failure = 0.1
	power_channel = ENVIRON
	idle_power_usage = 25
	armor = list(MELEE = 40, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 45, BIO = 0, RAD = 0, FIRE = 90, ACID = 100)
	circuit = /obj/item/circuitboard/computer/tram_controls
	light_color = COLOR_BLUE_LIGHT
	brightness_on = 0 //we dont want to spam SSlighting with source updates every movement
	/// Weakref to the tram piece we control
	var/datum/weakref/transport_ref
	/// The ID of the tram we're controlling
	var/specific_transport_id = TRAMSTATION_LINE_1
	/// If the sign is adjusted for split type tram windows
	var/split_mode = FALSE
	/// Unique tag of this device in transport logs
	var/id_tag

/obj/machinery/computer/tram_controls/split
	circuit = /obj/item/circuitboard/computer/tram_controls/split
	split_mode = TRUE

/obj/machinery/computer/tram_controls/split/directional/north
	dir = SOUTH
	pixel_x = -8
	pixel_y = 32

/obj/machinery/computer/tram_controls/split/directional/south
	dir = NORTH
	pixel_x = 8
	pixel_y = -32

/obj/machinery/computer/tram_controls/split/directional/east
	dir = WEST
	pixel_x = 32

/obj/machinery/computer/tram_controls/split/directional/west
	dir = EAST
	pixel_x = -32

/obj/machinery/computer/tram_controls/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	var/obj/item/circuitboard/computer/tram_controls/my_circuit = circuit
	if(istype(my_circuit))
		split_mode = my_circuit.split_mode

/obj/machinery/computer/tram_controls/LateInitialize()
	. = ..()
	if(!id_tag)
		id_tag = assign_random_name()
	SStransport.hello(src, name, id_tag)
	RegisterSignal(SStransport, COMSIG_TRANSPORT_RESPONSE, PROC_REF(call_response))
	find_tram()

	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(tram)
		RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(update_display))
		update_display(src, tram, tram.controller_active, tram.controller_status, tram.travel_direction, tram.destination_platform)

/// Finds the tram from the console
/obj/machinery/computer/tram_controls/proc/find_tram()
	for(var/datum/transport_controller/linear/transport as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(transport.specific_transport_id == specific_transport_id)
			transport_ref = WEAKREF(transport)
			return

/obj/machinery/computer/tram_controls/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/obj/machinery/computer/tram_controls/ui_status(mob/user, datum/ui_state/state)
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()

	if(tram?.controller_active)
		return UI_CLOSE
	if(!in_range(user, src) && !isobserver(user))
		return UI_CLOSE
	return ..()

/obj/machinery/computer/tram_controls/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TramControl", name)
		ui.open()

/obj/machinery/computer/tram_controls/ui_data(mob/user)
	var/datum/transport_controller/linear/tram/tram_controller = transport_ref?.resolve()
	var/list/data = list()
	data["moving"] = tram_controller?.controller_active
	data["broken"] = isnull(tram_controller) || isnull(tram_controller.paired_cabinet)
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/current_loc = tram_controller?.idle_platform
	if(current_loc)
		data["tram_location"] = current_loc.name
	return data

/obj/machinery/computer/tram_controls/ui_static_data(mob/user)
	var/list/data = list()
	data["destinations"] = SStransport.detailed_destination_list(specific_transport_id)
	return data

/obj/machinery/computer/tram_controls/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("send")
			var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination_platform
			for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination as anything in SStransport.nav_beacons[specific_transport_id])
				if(destination.platform_code == params["destination"])
					destination_platform = destination
					break

			if(isnull(destination_platform))
				return FALSE

			SStransport.incoming_request(src, specific_transport_id, destination_platform.platform_code)
			update_appearance()
			return TRUE

/obj/machinery/computer/tram_controls/proc/update_display(datum/source, datum/transport_controller/linear/tram/controller, controller_active, controller_status, travel_direction, obj/effect/landmark/transport/nav_beacon/tram/destination_platform)
	SIGNAL_HANDLER

	if(machine_stat & (NOPOWER|BROKEN))
		icon_screen = null
		update_appearance()
		return

	if(controller && (controller.specific_transport_id != specific_transport_id))
		return

	if(isnull(controller) || !controller.controller_operational)
		icon_screen = "[base_icon_state]_broken"
		update_appearance()
		return

	if(isnull(destination_platform))
		icon_screen = "[specific_transport_id]"
		update_appearance()
		return

	if(controller.controller_status & EMERGENCY_STOP || controller.controller_status & SYSTEM_FAULT)
		icon_screen = "[base_icon_state]_NIS"
		update_appearance()
		return

	if(controller_active)
		icon_screen = "[base_icon_state]_0[travel_direction]"
		update_appearance()
		return

	icon_screen = "[controller.specific_transport_id][destination_platform.platform_code]"
	update_appearance()

/obj/machinery/computer/tram_controls/power_change()
	. = ..()
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(isnull(tram))
		if(!(machine_stat & (NOPOWER|BROKEN)))
			icon_screen = "[base_icon_state]_broken"
		update_appearance()
		return

	update_display(src, tram, tram.controller_active, tram.controller_status, tram.travel_direction, tram.destination_platform)

/obj/machinery/computer/tram_controls/proc/call_response(datum/source, list/relevant, response_code, response_info)
	SIGNAL_HANDLER
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(!tram || response_code != REQUEST_FAIL || !LAZYFIND(relevant, src))
		return

	switch(response_info)
		if(NOT_IN_SERVICE)
			tram.nav_beacon.say("Трамвай не обслуживается. Пожалуйста, обратитесь к ближайшему инженеру.")
		if(INVALID_PLATFORM)
			tram.nav_beacon.say("Ошибка конфигурации. Пожалуйста, обратитесь к ближайшему инженеру.")
		if(INTERNAL_ERROR)
			tram.nav_beacon.say("Ошибка контроллера трамвая. Обратитесь к ближайшему инженеру или к сотруднику с доступом к телекоммуникациям, чтобы перезапустить контроллер.")

/obj/item/circuitboard/computer/tram_controls
	name = "Tram Controls (Computer Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/computer/tram_controls
	var/split_mode = FALSE

/obj/item/circuitboard/computer/tram_controls/split
	split_mode = TRUE

/obj/item/circuitboard/computer/tram_controls/examine(mob/user)
	. = ..()
	. += span_info("Плата настроена на [split_mode ? "разделённое" : "обычное"] окно.")
	. += span_notice("Режим платы переключается [EXAMINE_HINT("мультитулом")].")

/obj/item/circuitboard/computer/tram_controls/multitool_act(mob/living/user, obj/item/tool)
	split_mode = !split_mode
	to_chat(user, span_notice("[capitalize(src.name)] теперь настроена на [split_mode ? "разделённое" : "обычное"] окно."))
	return TRUE

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/tram_controls, 32)
