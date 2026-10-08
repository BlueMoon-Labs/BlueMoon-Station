/// Pedestrian crossing signal for tram
/obj/machinery/transport/crossing_signal
	name = "crossing signal"
	desc = "Показывает пешеходам, можно ли переходить пути. Подключён к датчикам вдоль путей."
	icon = 'modular_bluemoon/icons/obj/tram/crossing_signal.dmi'
	icon_state = "crossing-inbound"
	base_icon_state = "crossing-inbound"
	layer = TRAM_SIGNAL_LAYER
	max_integrity = 250
	integrity_failure = 0.25
	light_range = 2
	light_power = 0.7
	idle_power_usage = 360
	active_power_usage = 720
	anchored = TRUE
	density = FALSE
	interaction_flags_machine = INTERACT_MACHINE_OPEN
	circuit = /obj/item/circuitboard/machine/crossing_signal
	light_color = LIGHT_COLOR_BABY_BLUE
	init_process = FALSE
	/// green, amber, or red for tram, blue if it's emag, tram missing, etc.
	var/signal_state = XING_STATE_MALF
	/// the sensor we use
	var/datum/weakref/sensor_ref
	/// Inbound station
	var/inbound
	/// Outbound station
	var/outbound
	/// If us or anything else in the operation chain is broken
	var/operating_status = TRANSPORT_SYSTEM_NORMAL
	var/sign_dir = INBOUND
	/// Proximity thresholds for crossing signal states
	var/amber_distance_threshold = XING_THRESHOLD_AMBER
	var/red_distance_threshold = XING_THRESHOLD_RED

/obj/machinery/transport/crossing_signal/northwest
	dir = NORTH
	sign_dir = INBOUND

/obj/machinery/transport/crossing_signal/northeast
	dir = NORTH
	sign_dir = OUTBOUND

/obj/machinery/transport/crossing_signal/southwest
	dir = SOUTH
	sign_dir = INBOUND
	pixel_y = 20

/obj/machinery/transport/crossing_signal/southeast
	dir = SOUTH
	sign_dir = OUTBOUND
	pixel_y = 20

/obj/machinery/static_signal
	name = "crossing signal"
	desc = "Показывает пешеходам, можно ли переходить пути."
	icon = 'modular_bluemoon/icons/obj/tram/crossing_signal.dmi'
	icon_state = "crossing-inbound"
	base_icon_state = "crossing-inbound"
	layer = TRAM_SIGNAL_LAYER
	max_integrity = 250
	integrity_failure = 0.25
	idle_power_usage = 360
	anchored = TRUE
	density = FALSE
	light_range = 1.5
	light_power = 3
	light_color = COLOR_VIBRANT_LIME
	init_process = FALSE
	var/sign_dir = INBOUND

/obj/machinery/static_signal/northwest
	dir = NORTH
	sign_dir = INBOUND

/obj/machinery/static_signal/northeast
	dir = NORTH
	sign_dir = OUTBOUND

/obj/machinery/static_signal/southwest
	dir = SOUTH
	sign_dir = INBOUND
	pixel_y = 20

/obj/machinery/static_signal/southeast
	dir = SOUTH
	sign_dir = OUTBOUND
	pixel_y = 20

/obj/machinery/transport/crossing_signal/Initialize(mapload)
	. = ..()
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(wake_up))
	SStransport.crossing_signals += src
	register_context()

/obj/machinery/transport/crossing_signal/LateInitialize()
	. = ..()
	link_tram()
	link_sensor()
	find_uplink()

/obj/machinery/transport/crossing_signal/Destroy()
	SStransport.crossing_signals -= src
	STOP_PROCESSING(SStransport, src)
	return ..()

/obj/machinery/transport/crossing_signal/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, icon_state, icon_state, tool)

/obj/machinery/transport/crossing_signal/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/transport/crossing_signal/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(panel_open && held_item?.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Повернуть сигнал"
		context[SCREENTIP_CONTEXT_LMB] = "Сменить направление"

	if(istype(held_item, /obj/item/card/emag) && !(obj_flags & EMAGGED))
		context[SCREENTIP_CONTEXT_LMB] = "Отключить датчики"

	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/transport/crossing_signal/examine(mob/user)
	. = ..()
	. += span_notice("Сервисная панель [panel_open ? "открыта" : "закрыта"].")
	if(panel_open)
		. += span_notice("Направление меняется [EXAMINE_HINT("гаечным ключом")], поворот - [EXAMINE_HINT("Alt-кликом")] с ключом в руке.")
	switch(operating_status)
		if(TRANSPORT_REMOTE_WARNING)
			. += span_notice("Горит оранжевый индикатор [EXAMINE_HINT("удалённого предупреждения")].")
			. += span_notice("Табло: «Проверьте путевой датчик».")
		if(TRANSPORT_REMOTE_FAULT)
			. += span_notice("Горит синий индикатор [EXAMINE_HINT("сбоя телекоммуникаций")].")
			. += span_notice("Табло: «Проверьте сеть телекоммуникаций».")
		if(TRANSPORT_LOCAL_FAULT)
			. += span_notice("Горит красный индикатор [EXAMINE_HINT("местной неисправности")].")
			. += span_notice("Табло: «Требуется ремонт».")
	switch(dir)
		if(NORTH, SOUTH)
			. += span_notice("Схема на табло: пути ВОСТОК/ЗАПАД.")
		if(EAST, WEST)
			. += span_notice("Схема на табло: пути СЕВЕР/ЮГ.")

/obj/machinery/transport/crossing_signal/emag_act(mob/living/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	balloon_alert(user, "датчики движения отключены")
	operating_status = TRANSPORT_LOCAL_FAULT
	obj_flags |= EMAGGED
	return TRUE

/obj/machinery/transport/crossing_signal/AltClick(mob/user)
	var/obj/item/tool = user.get_active_held_item()
	if(!panel_open || tool?.tool_behaviour != TOOL_WRENCH || !user.canUseTopic(src, be_close = TRUE))
		return ..()

	tool.play_tool_sound(src, 50)
	setDir(turn(dir, -90))
	balloon_alert(user, "повёрнуто")
	find_uplink()
	return TRUE

/obj/machinery/transport/crossing_signal/wrench_act(mob/living/user, obj/item/tool)
	if(!panel_open)
		return FALSE
	sign_dir = (sign_dir == INBOUND) ? OUTBOUND : INBOUND
	to_chat(user, span_notice("Вы меняете направление [src]."))
	update_appearance()
	return TRUE

/obj/machinery/transport/crossing_signal/proc/link_sensor()
	sensor_ref = WEAKREF(find_closest_valid_sensor())
	update_appearance()

/obj/machinery/transport/crossing_signal/proc/unlink_sensor()
	sensor_ref = null
	if(operating_status < TRANSPORT_REMOTE_WARNING)
		operating_status = TRANSPORT_REMOTE_WARNING
	update_appearance()

/obj/machinery/transport/crossing_signal/proc/wake_sensor()
	var/obj/machinery/transport/guideway_sensor/linked_sensor = sensor_ref?.resolve()
	if(isnull(linked_sensor))
		operating_status = TRANSPORT_REMOTE_WARNING

	else if(linked_sensor.trigger_sensor())
		operating_status = TRANSPORT_SYSTEM_NORMAL

	else
		operating_status = TRANSPORT_REMOTE_WARNING

/obj/machinery/transport/crossing_signal/proc/clear_uplink()
	inbound = null
	outbound = null
	update_appearance()

/// Only process if the tram is actually moving
/obj/machinery/transport/crossing_signal/proc/wake_up(datum/source, transport_controller, controller_active)
	SIGNAL_HANDLER

	if(machine_stat & BROKEN || machine_stat & NOPOWER)
		operating_status = TRANSPORT_LOCAL_FAULT
		update_appearance()
		return

	if(prob(TRANSPORT_BREAKDOWN_RATE))
		operating_status = TRANSPORT_LOCAL_FAULT
		local_fault()
		return

	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	var/obj/machinery/transport/guideway_sensor/linked_sensor = sensor_ref?.resolve()

	if(malfunctioning || (obj_flags & EMAGGED))
		operating_status = TRANSPORT_LOCAL_FAULT
	else if(isnull(tram) || tram.controller_status & COMM_ERROR)
		operating_status = TRANSPORT_REMOTE_FAULT
	else
		operating_status = TRANSPORT_SYSTEM_NORMAL
		if(isnull(linked_sensor))
			link_sensor()
		wake_sensor()

	update_operating()

/obj/machinery/transport/crossing_signal/on_stat_update(old_value)
	. = ..()
	if(machine_stat & BROKEN || machine_stat & NOPOWER)
		operating_status = TRANSPORT_LOCAL_FAULT
	else if(!malfunctioning && !(obj_flags & EMAGGED))
		operating_status = TRANSPORT_SYSTEM_NORMAL

/obj/machinery/transport/crossing_signal/on_set_is_operational(old_value)
	. = ..()
	if(!is_operational)
		operating_status = TRANSPORT_LOCAL_FAULT
	else if(!malfunctioning && !(obj_flags & EMAGGED))
		operating_status = TRANSPORT_SYSTEM_NORMAL
	update_operating()

/// Update processing state.
/obj/machinery/transport/crossing_signal/proc/update_operating()
	update_appearance()
	if(process() != PROCESS_KILL)
		use_power = ACTIVE_POWER_USE
		START_PROCESSING(SStransport, src)
		return
	use_power = IDLE_POWER_USE
	STOP_PROCESSING(SStransport, src)

/obj/machinery/transport/crossing_signal/process()
	var/idle_aspect = operating_status == TRANSPORT_SYSTEM_NORMAL ? XING_STATE_GREEN : XING_STATE_MALF
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(tram?.controller_status & COMM_ERROR)
		idle_aspect = XING_STATE_MALF

	if(!tram || !tram.controller_operational || !tram.controller_active || !is_operational || !inbound || !outbound)
		set_signal_state(idle_aspect, force = !is_operational)
		return PROCESS_KILL

	var/obj/structure/transport/linear/tram_part = tram.return_closest_platform_to(src)

	if(QDELETED(tram_part))
		set_signal_state(idle_aspect, force = !is_operational)
		return PROCESS_KILL

	var/signal_pos
	var/tram_pos
	var/tram_velocity_sign // 1 for positive axis movement, -1 for negative
	if(tram.travel_direction & (NORTH|SOUTH))
		signal_pos = y
		tram_pos = tram_part.y
		tram_velocity_sign = tram.travel_direction & NORTH ? 1 : -1
	else
		signal_pos = x
		tram_pos = tram_part.x
		tram_velocity_sign = tram.travel_direction & EAST ? 1 : -1

	// How far away are we? negative if already passed.
	var/approach_distance = tram_velocity_sign * (signal_pos - (tram_pos + DEFAULT_TRAM_MIDPOINT))

	if(approach_distance < -abs(DEFAULT_TRAM_MIDPOINT))
		set_signal_state(idle_aspect)
		return PROCESS_KILL

	// Check the tram's terminus station.
	// INBOUND 1 < 2 < 3
	// OUTBOUND 1 > 2 > 3
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination = tram.destination_platform
	if(istype(destination))
		if(tram.travel_direction & WEST && inbound < destination.platform_code)
			set_signal_state(idle_aspect)
			return PROCESS_KILL
		if(tram.travel_direction & EAST && outbound > destination.platform_code)
			set_signal_state(idle_aspect)
			return PROCESS_KILL

	if(approach_distance <= red_distance_threshold && operating_status == TRANSPORT_SYSTEM_NORMAL)
		set_signal_state(XING_STATE_RED)
		return
	if(approach_distance <= amber_distance_threshold && operating_status == TRANSPORT_SYSTEM_NORMAL)
		set_signal_state(XING_STATE_AMBER)
		return
	set_signal_state(idle_aspect)

/// Set the signal state and update appearance.
/obj/machinery/transport/crossing_signal/proc/set_signal_state(new_state, force = FALSE)
	if(new_state == signal_state && !force)
		return

	signal_state = new_state
	update_appearance()

/obj/machinery/transport/crossing_signal/update_icon_state()
	switch(dir)
		if(SOUTH, EAST)
			pixel_y = 20
		if(NORTH, WEST)
			pixel_y = 0

	switch(sign_dir)
		if(INBOUND)
			icon_state = "crossing-inbound"
			base_icon_state = "crossing-inbound"
		if(OUTBOUND)
			icon_state = "crossing-outbound"
			base_icon_state = "crossing-outbound"

	return ..()

/obj/machinery/static_signal/update_icon_state()
	switch(dir)
		if(SOUTH, EAST)
			pixel_y = 20
		if(NORTH, WEST)
			pixel_y = 0

	switch(sign_dir)
		if(INBOUND)
			icon_state = "crossing-inbound"
			base_icon_state = "crossing-inbound"
		if(OUTBOUND)
			icon_state = "crossing-outbound"
			base_icon_state = "crossing-outbound"

	return ..()

/obj/machinery/transport/crossing_signal/update_appearance(updates)
	. = ..()

	if(machine_stat & NOPOWER)
		set_light(l_on = FALSE)
		return

	var/new_color
	switch(signal_state)
		if(XING_STATE_MALF)
			new_color = LIGHT_COLOR_BABY_BLUE
		if(XING_STATE_GREEN)
			new_color = LIGHT_COLOR_VIVID_GREEN
		if(XING_STATE_AMBER)
			new_color = LIGHT_COLOR_BRIGHT_YELLOW
		else
			new_color = LIGHT_COLOR_FLARE

	set_light(l_color = new_color, l_on = TRUE)

/obj/machinery/transport/crossing_signal/update_overlays()
	. = ..()

	if(machine_stat & NOPOWER)
		return

	if(machine_stat & BROKEN)
		operating_status = TRANSPORT_LOCAL_FAULT

	var/lights_overlay = "[base_icon_state]-l[signal_state]"
	var/status_overlay = "[base_icon_state]-s[operating_status]"

	. += mutable_appearance(icon, lights_overlay)
	. += mutable_appearance(icon, status_overlay)
	. += emissive_appearance(icon, lights_overlay, alpha = src.alpha, offset_spokesman = src)
	. += emissive_appearance(icon, status_overlay, alpha = src.alpha, offset_spokesman = src)

/obj/machinery/static_signal/power_change()
	. = ..()

	if(!is_operational())
		set_light(l_on = FALSE)
		return

	set_light(l_on = TRUE)

/obj/machinery/static_signal/update_overlays()
	. = ..()

	if(!is_operational())
		return

	. += mutable_appearance(icon, "[base_icon_state]-l0")
	. += mutable_appearance(icon, "[base_icon_state]-s0")
	. += emissive_appearance(icon, "[base_icon_state]-l0", alpha = src.alpha, offset_spokesman = src)
	. += emissive_appearance(icon, "[base_icon_state]-s0", alpha = src.alpha, offset_spokesman = src)

/obj/machinery/transport/guideway_sensor
	name = "guideway sensor"
	icon = 'modular_bluemoon/icons/obj/tram/tram_sensor.dmi'
	icon_state = "sensor-base"
	desc = "Засекает проходящий трамвай инфракрасным лучом. Работает в паре с датчиком на другой стороне путей."
	layer = TRAM_RAIL_LAYER
	plane = FLOOR_PLANE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/guideway_sensor
	init_process = FALSE
	/// Sensors work in a married pair
	var/datum/weakref/paired_sensor
	/// If us or anything else in the operation chain is broken
	var/operating_status = TRANSPORT_SYSTEM_NORMAL

/obj/machinery/transport/guideway_sensor/Initialize(mapload)
	. = ..()
	SStransport.sensors += src
	register_context()

/obj/machinery/transport/guideway_sensor/LateInitialize()
	. = ..()
	pair_sensor()
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(wake_up))

/obj/machinery/transport/guideway_sensor/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(panel_open && held_item?.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = "Повернуть датчик"

	if(istype(held_item, /obj/item/card/emag) && !(obj_flags & EMAGGED))
		context[SCREENTIP_CONTEXT_LMB] = "Отключить датчик"

	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/transport/guideway_sensor/examine(mob/user)
	. = ..()
	. += span_notice("Сервисная панель [panel_open ? "открыта" : "закрыта"].")
	if(panel_open)
		. += span_notice("Датчик поворачивается [EXAMINE_HINT("гаечным ключом")].")
	switch(operating_status)
		if(TRANSPORT_REMOTE_WARNING)
			. += span_notice("Горит оранжевый индикатор [EXAMINE_HINT("удалённого предупреждения")].")
			. += span_notice("Табло: «Проверьте парный датчик».")
		if(TRANSPORT_REMOTE_FAULT)
			. += span_notice("Горит синий индикатор [EXAMINE_HINT("удалённой неисправности")].")
			. += span_notice("Табло: «Парный датчик не найден».")
		if(TRANSPORT_LOCAL_FAULT)
			. += span_notice("Горит красный индикатор [EXAMINE_HINT("местной неисправности")].")
			. += span_notice("Табло: «Требуется ремонт».")

/obj/machinery/transport/guideway_sensor/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, icon_state, icon_state, tool)

/obj/machinery/transport/guideway_sensor/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/transport/guideway_sensor/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	balloon_alert(user, "датчик отключён")
	update_appearance()
	return TRUE

/obj/machinery/transport/guideway_sensor/proc/pair_sensor()
	set_machine_stat(machine_stat | MAINT)
	var/obj/machinery/transport/guideway_sensor/divorcee = paired_sensor?.resolve()
	if(divorcee)
		divorcee.set_machine_stat(divorcee.machine_stat | MAINT)
		divorcee.paired_sensor = null
		divorcee.update_appearance()
	paired_sensor = null

	for(var/obj/machinery/transport/guideway_sensor/potential_sensor in SStransport.sensors)
		if(potential_sensor == src)
			continue
		switch(potential_sensor.dir)
			if(NORTH, SOUTH)
				if(potential_sensor.x == x)
					paired_sensor = WEAKREF(potential_sensor)
					set_machine_stat(machine_stat & ~MAINT)
					break
			if(EAST, WEST)
				if(potential_sensor.y == y)
					paired_sensor = WEAKREF(potential_sensor)
					set_machine_stat(machine_stat & ~MAINT)
					break

	update_appearance()

	var/obj/machinery/transport/guideway_sensor/new_partner = paired_sensor?.resolve()
	if(isnull(new_partner))
		return

	new_partner.paired_sensor = WEAKREF(src)
	new_partner.set_machine_stat(new_partner.machine_stat & ~MAINT)
	new_partner.update_appearance()
	playsound(src, 'sound/machines/synth_yes.ogg', 75, vary = FALSE)

/obj/machinery/transport/guideway_sensor/Destroy()
	SStransport.sensors -= src
	var/obj/machinery/transport/guideway_sensor/divorcee = paired_sensor?.resolve()
	if(divorcee)
		divorcee.set_machine_stat(divorcee.machine_stat | MAINT)
		divorcee.paired_sensor = null
		divorcee.update_appearance()
		playsound(src, 'sound/machines/synth_no.ogg', 75, vary = FALSE)
	paired_sensor = null
	return ..()

/obj/machinery/transport/guideway_sensor/wrench_act(mob/living/user, obj/item/tool)
	if(default_change_direction_wrench(user, tool))
		pair_sensor()
		return TRUE
	return FALSE

/obj/machinery/transport/guideway_sensor/update_overlays()
	. = ..()

	if(machine_stat & BROKEN || machine_stat & NOPOWER || malfunctioning || (obj_flags & EMAGGED))
		operating_status = TRANSPORT_LOCAL_FAULT
		. += sensor_light(TRANSPORT_LOCAL_FAULT)
		return

	if(machine_stat & MAINT)
		operating_status = TRANSPORT_REMOTE_FAULT
		. += sensor_light(TRANSPORT_REMOTE_FAULT)
		return

	var/obj/machinery/transport/guideway_sensor/buddy = paired_sensor?.resolve()
	if(!buddy)
		operating_status = TRANSPORT_REMOTE_FAULT
		. += sensor_light(TRANSPORT_REMOTE_FAULT)
		return

	if(!buddy.is_operational || buddy.malfunctioning || (buddy.obj_flags & EMAGGED))
		operating_status = TRANSPORT_REMOTE_WARNING
		. += sensor_light(TRANSPORT_REMOTE_WARNING)
		return

	operating_status = TRANSPORT_SYSTEM_NORMAL
	. += sensor_light(TRANSPORT_SYSTEM_NORMAL)

/// A status light overlay plus its glow
/obj/machinery/transport/guideway_sensor/proc/sensor_light(status)
	return list(
		mutable_appearance(icon, "sensor-[status]"),
		emissive_appearance(icon, "sensor-[status]", alpha = src.alpha, offset_spokesman = src),
	)

/obj/machinery/transport/guideway_sensor/proc/trigger_sensor()
	var/obj/machinery/transport/guideway_sensor/buddy = paired_sensor?.resolve()
	if(!buddy)
		return FALSE

	if(!is_operational || malfunctioning || (obj_flags & EMAGGED))
		return FALSE

	if(!buddy.is_operational || buddy.malfunctioning || (buddy.obj_flags & EMAGGED))
		return FALSE

	return TRUE

/obj/machinery/transport/guideway_sensor/proc/wake_up(datum/source)
	SIGNAL_HANDLER

	if(machine_stat & BROKEN)
		update_appearance()
		return

	if(prob(TRANSPORT_BREAKDOWN_RATE))
		operating_status = TRANSPORT_LOCAL_FAULT
		local_fault()

	var/obj/machinery/transport/guideway_sensor/buddy = paired_sensor?.resolve()

	if(buddy && !malfunctioning)
		set_machine_stat(machine_stat & ~MAINT)

	update_appearance()

/obj/machinery/transport/guideway_sensor/on_set_is_operational(old_value)
	. = ..()

	var/obj/machinery/transport/guideway_sensor/buddy = paired_sensor?.resolve()
	buddy?.update_appearance()

	update_appearance()

/obj/machinery/transport/crossing_signal/proc/find_closest_valid_sensor()
	if(!z)
		return null

	var/list/obj/machinery/transport/guideway_sensor/sensor_candidates = list()

	for(var/obj/machinery/transport/guideway_sensor/sensor in SStransport.sensors)
		if(sensor.z != z)
			continue
		if(sensor.x != x && !(sensor.dir & (NORTH|SOUTH)))
			continue
		if(sensor.y != y && !(sensor.dir & (EAST|WEST)))
			continue

		sensor_candidates += sensor

	var/obj/machinery/transport/guideway_sensor/selected_sensor = get_closest_atom(/obj/machinery/transport/guideway_sensor, sensor_candidates, src)
	if(selected_sensor && get_dist(src, selected_sensor) <= DEFAULT_TRAM_LENGTH)
		return selected_sensor

	return null

/obj/machinery/transport/crossing_signal/proc/find_uplink()
	if(!z)
		return FALSE

	var/list/obj/effect/landmark/transport/nav_beacon/tram/platform/inbound_candidates = list()
	var/list/obj/effect/landmark/transport/nav_beacon/tram/platform/outbound_candidates = list()

	inbound = null
	outbound = null

	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/beacon in SStransport.nav_beacons[configured_transport_id])
		if(beacon.z != z)
			continue

		switch(dir)
			if(NORTH, SOUTH)
				if(abs((beacon.y - y)) <= DEFAULT_TRAM_LENGTH)
					if(beacon.x < x)
						inbound_candidates += beacon
					else
						outbound_candidates += beacon
			if(EAST, WEST)
				if(abs((beacon.x - x)) <= DEFAULT_TRAM_LENGTH)
					if(beacon.y < y)
						inbound_candidates += beacon
					else
						outbound_candidates += beacon

	var/obj/effect/landmark/transport/nav_beacon/tram/platform/selected_inbound = get_closest_atom(/obj/effect/landmark/transport/nav_beacon/tram/platform, inbound_candidates, src)
	if(isnull(selected_inbound))
		return FALSE

	inbound = selected_inbound.platform_code

	var/obj/effect/landmark/transport/nav_beacon/tram/platform/selected_outbound = get_closest_atom(/obj/effect/landmark/transport/nav_beacon/tram/platform, outbound_candidates, src)
	if(isnull(selected_outbound))
		return FALSE

	outbound = selected_outbound.platform_code

	update_appearance()

/obj/item/circuitboard/machine/crossing_signal
	name = "Crossing Signal (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/transport/crossing_signal
	req_components = list(/obj/item/stock_parts/micro_laser = 1)

/obj/item/circuitboard/machine/guideway_sensor
	name = "Guideway Sensor (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/transport/guideway_sensor
	req_components = list(/obj/item/assembly/prox_sensor = 1)
