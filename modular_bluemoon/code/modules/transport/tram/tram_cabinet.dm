/// The cabinet on the tram, the player-facing terminal of the tram controller
/obj/machinery/transport/tram_controller
	name = "tram controller"
	desc = "Заставляет трамвай ехать. Ну, или что-то в этом роде. Внутри электроника, органы управления и сервисная панель. Наклейка над считывателем карт гласит: «Только для инженеров»."
	icon = 'modular_bluemoon/icons/obj/tram/tram_controllers.dmi'
	icon_state = "tram-controller"
	base_icon_state = "tram"
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 80, BULLET = 90, LASER = 0, ENERGY = 0, BOMB = 70, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE | INTERACT_MACHINE_OFFLINE
	max_integrity = 750
	integrity_failure = 0.25
	layer = SIGN_LAYER
	req_access = list(ACCESS_TCOMSAT)
	idle_power_usage = 25
	power_channel = ENVIRON
	init_process = FALSE
	var/datum/transport_controller/linear/tram/controller_datum
	/// If this machine has a cover installed
	var/has_cover = TRUE
	/// If the cover is open
	var/cover_open = FALSE
	/// If the cover is locked
	var/cover_locked = TRUE
	COOLDOWN_DECLARE(manual_command_cooldown)

/obj/machinery/transport/tram_controller/Initialize(mapload)
	. = ..()
	register_context()

/obj/machinery/transport/tram_controller/LateInitialize()
	. = ..()
	SStransport.hello(src, name, id_tag)
	find_controller()
	update_appearance()

/obj/machinery/transport/tram_controller/Destroy()
	controller_datum = null
	return ..()

/obj/machinery/transport/tram_controller/obj_break(damage_flag)
	. = ..()
	set_machine_stat(machine_stat | BROKEN)

/obj/machinery/transport/tram_controller/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(held_item?.tool_behaviour == TOOL_SCREWDRIVER && has_cover && cover_open)
		context[SCREENTIP_CONTEXT_LMB] = panel_open ? "Закрыть панель" : "Открыть панель"

	if(!held_item && has_cover)
		context[SCREENTIP_CONTEXT_LMB] = cover_open ? "Пульт управления" : (cover_locked ? "Отпереть картой" : "Открыть шкаф")
		if(cover_open)
			context[SCREENTIP_CONTEXT_ALT_LMB] = "Закрыть шкаф"

	if(istype(held_item, /obj/item/card/id) && has_cover && !cover_open)
		context[SCREENTIP_CONTEXT_LMB] = cover_locked ? "Отпереть" : "Запереть"

	if(panel_open && cover_open && held_item?.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = "Снять шкаф"

	if(held_item?.tool_behaviour == TOOL_WELDER)
		context[SCREENTIP_CONTEXT_LMB] = "Починить корпус"

	if(istype(held_item, /obj/item/card/emag) && !(obj_flags & EMAGGED))
		context[SCREENTIP_CONTEXT_LMB] = "Взломать"

	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/transport/tram_controller/examine(mob/user)
	. = ..()
	if(has_cover)
		. += span_notice("Дверца [cover_locked ? "заперта. Проведите ID-картой, чтобы отпереть" : "не заперта. Проведите ID-картой, чтобы запереть"].")
		if(cover_open)
			if(panel_open)
				. += span_notice("Шкаф прикручен к стене трамвая [EXAMINE_HINT("болтами")].")
				. += span_notice("Сервисную панель можно закрыть [EXAMINE_HINT("отвёрткой")].")
			else
				. += span_notice("Сервисную панель можно открыть [EXAMINE_HINT("отвёрткой")].")

	if(cover_open || !has_cover)
		. += span_notice("[EXAMINE_HINT("Жёлтая кнопка сброса")] перезапускает контроллер трамвая, если что-то пошло не так.")
		. += span_notice("[EXAMINE_HINT("Красная кнопка")] немедленно останавливает трамвай, после чего нужен перезапуск.")
		if(has_cover)
			. += span_notice("Шкаф закрывается по [EXAMINE_HINT("Alt-клику")].")
	else
		. += span_notice("Шкаф открывается [EXAMINE_HINT("рукой")].")

/obj/machinery/transport/tram_controller/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/card/id) && has_cover && user.a_intent != INTENT_HARM)
		if(cover_open)
			balloon_alert(user, "сначала закройте шкаф!")
			return STOP_ATTACK_PROC_CHAIN
		try_toggle_lock(user, attacking_item)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/machinery/transport/tram_controller/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(. || cover_open || !has_cover)
		return

	if(cover_locked)
		var/obj/item/card/id/id_card = user.get_idcard(TRUE)
		if(isnull(id_card))
			balloon_alert(user, "доступ запрещён!")
			return

		try_toggle_lock(user, id_card)
		return

	toggle_door()

/obj/machinery/transport/tram_controller/AltClick(mob/user)
	. = ..()
	if(!has_cover || !cover_open || !user.canUseTopic(src, be_close = TRUE))
		return
	toggle_door()
	return TRUE

/obj/machinery/transport/tram_controller/proc/toggle_door()
	if(!cover_open)
		playsound(loc, 'sound/machines/closet_open.ogg', 35, TRUE, -3)
	else
		playsound(loc, 'sound/machines/closet_close.ogg', 50, TRUE, -3)
		panel_open = FALSE
		SStgui.close_uis(src)
	cover_open = !cover_open
	update_appearance()

/obj/machinery/transport/tram_controller/proc/try_toggle_lock(mob/living/user, obj/item/card/id_card)
	if(isnull(id_card))
		id_card = user.get_idcard(TRUE)
	if(obj_flags & EMAGGED)
		balloon_alert(user, "замок сгорел!")
		return FALSE

	if(check_access(id_card))
		cover_locked = !cover_locked
		balloon_alert(user, cover_locked ? "заперто" : "отперто")
		update_appearance()
		return TRUE

	balloon_alert(user, "доступ запрещён!")
	return FALSE

/obj/machinery/transport/tram_controller/wrench_act(mob/living/user, obj/item/tool)
	if(!has_cover || !panel_open || !cover_open)
		return FALSE

	balloon_alert(user, "откручиваем...")
	tool.play_tool_sound(src)
	if(!tool.use_tool(src, user, 6 SECONDS))
		return TRUE
	playsound(loc, 'sound/items/deconstruct.ogg', 50, vary = TRUE)
	balloon_alert(user, "снято")
	deconstruct(TRUE)
	return TRUE

/obj/machinery/transport/tram_controller/screwdriver_act(mob/living/user, obj/item/tool)
	if(!cover_open)
		return FALSE

	tool.play_tool_sound(src)
	panel_open = !panel_open
	balloon_alert(user, panel_open ? "крепёжные болты открыты" : "крепёжные болты закрыты")
	return TRUE

/obj/machinery/transport/tram_controller/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/drop_location = find_obstruction_free_location(1, src) || drop_location()
		if(disassembled)
			new /obj/item/wallframe/tram(drop_location)
		else
			new /obj/item/stack/sheet/mineral/titanium(drop_location, 2)
			new /obj/item/stack/sheet/metal(drop_location)
	qdel(src)

/// Update the blinky lights based on the controller status, allowing to quickly check without opening up the cabinet.
/obj/machinery/transport/tram_controller/update_overlays()
	. = ..()

	if(has_cover)
		if(!cover_open)
			. += mutable_appearance(icon, "[base_icon_state]-closed")
			if(cover_locked)
				. += mutable_appearance(icon, "[base_icon_state]-locked")

		else
			var/mutable_appearance/controller_door = mutable_appearance(icon, "[base_icon_state]-open")
			controller_door.pixel_x = -3
			. += controller_door

	if(machine_stat & NOPOWER)
		. += status_light("estop")
		return

	. += status_light("power")

	if(!controller_datum)
		. += status_light("fatal")
		return

	if(controller_datum.controller_status & EMERGENCY_STOP)
		. += status_light("estop")
		return

	if(controller_datum.controller_status & SYSTEM_FAULT || controller_datum.malf_active != TRANSPORT_SYSTEM_NORMAL)
		. += status_light("fault")
		return

	if(!(controller_datum.controller_status & DOORS_READY))
		. += status_light("doors")

	if(controller_datum.controller_active)
		. += status_light("active")

	if(controller_datum.controller_status & COMM_ERROR)
		. += status_light("comms")
	else
		. += status_light("normal")

/// A status light overlay plus its glow
/obj/machinery/transport/tram_controller/proc/status_light(light_name)
	return list(
		mutable_appearance(icon, "[base_icon_state]-[light_name]"),
		emissive_appearance(icon, "[base_icon_state]-[light_name]", alpha = src.alpha, offset_spokesman = src),
	)

/// Find the controller associated with the transport module the cabinet is sitting on.
/obj/machinery/transport/tram_controller/proc/find_controller()
	var/obj/structure/transport/linear/tram/tram_structure = locate() in loc
	if(!tram_structure)
		return

	controller_datum = tram_structure.transport_controller_datum
	if(!controller_datum)
		return

	controller_datum.notify_controller(src)
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(sync_controller))

/// Since the machinery obj is a dumb terminal for the controller datum, sync the display with the status bitfield of the tram
/obj/machinery/transport/tram_controller/proc/sync_controller(datum/source, controller, controller_active, controller_status, travel_direction, destination_platform)
	SIGNAL_HANDLER
	if(controller != controller_datum)
		return
	use_power(active_power_usage)
	update_appearance()

/obj/machinery/transport/tram_controller/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		balloon_alert(user, "уже сожжено!")
		return FALSE
	obj_flags |= EMAGGED
	cover_locked = FALSE
	playsound(src, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	balloon_alert(user, "замок закорочен")
	update_appearance()
	return TRUE

/obj/machinery/transport/tram_controller/ui_status(mob/user, datum/ui_state/state)
	if(issilicon(user) && (isnull(controller_datum) || controller_datum.controller_status & SYSTEM_FAULT || controller_datum.controller_status & COMM_ERROR || !is_operational()))
		to_chat(user, span_warning("Мигает код ошибки: сбой связи! [capitalize(src.name)] не отвечает на удалённые команды!"))
		return UI_CLOSE

	return ..()

/obj/machinery/transport/tram_controller/ui_interact(mob/user, datum/tgui/ui)
	if(!cover_open && !issilicon(user) && !isobserver(user))
		return

	if(machine_stat & BROKEN || isnull(controller_datum))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TramController")
		ui.open()

/obj/machinery/transport/tram_controller/ui_data(mob/user)
	return list(
		"transportId" = controller_datum.specific_transport_id,
		"controllerActive" = controller_datum.controller_active,
		"controllerOperational" = controller_datum.controller_operational,
		"travelDirection" = controller_datum.travel_direction,
		"destinationPlatform" = "[controller_datum.destination_platform || ""]",
		"idlePlatform" = "[controller_datum.idle_platform || ""]",
		"recoveryMode" = controller_datum.recovery_mode,
		"currentSpeed" = controller_datum.current_speed,
		"currentLoad" = controller_datum.current_load,
		"statusSF" = controller_datum.controller_status & SYSTEM_FAULT || controller_datum.malf_active != TRANSPORT_SYSTEM_NORMAL,
		"statusCE" = controller_datum.controller_status & COMM_ERROR,
		"statusES" = controller_datum.controller_status & EMERGENCY_STOP,
		"statusPD" = controller_datum.controller_status & PRE_DEPARTURE,
		"statusDR" = controller_datum.controller_status & DOORS_READY,
		"statusCL" = controller_datum.controller_status & CONTROLS_LOCKED,
		"statusBS" = controller_datum.controller_status & BYPASS_SENSORS,
	)

/obj/machinery/transport/tram_controller/ui_static_data(mob/user)
	var/list/data = list()
	data["destinations"] = SStransport.detailed_destination_list(controller_datum?.specific_transport_id)
	return data

/obj/machinery/transport/tram_controller/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!COOLDOWN_FINISHED(src, manual_command_cooldown) || isnull(controller_datum))
		return

	if(machine_stat & NOPOWER)
		visible_message(span_warning("Кнопка не срабатывает: на [src] мигает индикатор отказа питания!"), vision_distance = COMBAT_MESSAGE_RANGE)
		return

	switch(action)
		if("dispatch")
			var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination_platform
			for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination as anything in SStransport.nav_beacons[controller_datum.specific_transport_id])
				if(destination.name == params["tripDestination"])
					destination_platform = destination
					break

			if(!destination_platform)
				return FALSE

			SEND_SIGNAL(src, COMSIG_TRANSPORT_REQUEST, controller_datum.specific_transport_id, destination_platform.platform_code)
			update_appearance()

		if("estop")
			controller_datum.estop()

		if("reset")
			controller_datum.reset_position()

		if("dclose")
			controller_datum.cycle_doors(CYCLE_CLOSED)

		if("dopen")
			controller_datum.cycle_doors(CYCLE_OPEN)

		if("togglesensors")
			controller_datum.set_status_code(BYPASS_SENSORS, !(controller_datum.controller_status & BYPASS_SENSORS))

	COOLDOWN_START(src, manual_command_cooldown, 2 SECONDS)
	return TRUE

/// Controller that sits in the telecoms room
/obj/machinery/transport/tram_controller/tcomms
	name = "tram central controller"
	desc = "Этот полупроводниковый блок - половина мозгов трамвая и всего его вспомогательного оборудования."
	icon_state = "home-controller"
	base_icon_state = "home"
	density = TRUE
	layer = BELOW_OBJ_LAYER
	power_channel = EQUIP
	cover_open = TRUE
	has_cover = FALSE

/// Handles the machine being affected by an EMP, causing signal failure.
/obj/machinery/transport/tram_controller/tcomms/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(prob(100 / severity) && !(machine_stat & EMPED))
		set_machine_stat(machine_stat | EMPED)
		controller_datum?.set_status_code(COMM_ERROR, TRUE)
		var/duration = (300 SECONDS) / severity
		addtimer(CALLBACK(src, PROC_REF(de_emp)), rand(duration - 2 SECONDS, duration + 2 SECONDS))

/// Handles the machine stopping being affected by an EMP.
/obj/machinery/transport/tram_controller/tcomms/proc/de_emp()
	set_machine_stat(machine_stat & ~EMPED)
	controller_datum?.set_status_code(COMM_ERROR, FALSE)

/obj/machinery/transport/tram_controller/tcomms/find_controller()
	link_tram()
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	controller_datum = tram
	if(!controller_datum)
		return
	controller_datum.set_home_controller(src)
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(sync_controller))

/obj/item/wallframe/tram
	name = "tram controller cabinet"
	desc = "Короб с аппаратурой управления трамваем. Осталось закрепить его на стене трамвая."
	icon = 'modular_bluemoon/icons/obj/tram/tram_controllers.dmi'
	icon_state = "tram-controller"
	custom_materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT * 20)
	result_path = /obj/machinery/transport/tram_controller
	pixel_shift = 32
	inverse = TRUE
