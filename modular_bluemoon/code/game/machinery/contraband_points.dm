// ============================================
// ПЛАТФОРМА СДАЧИ КОНТРАБАНДЫ
// ============================================
/obj/machinery/vanguard/contraband
	name = "contraband exchange pad"
	desc = "A machine designed to send contraband to CentCom for processing. Can be upgraded with better parts."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "lpad-idle"
	density = FALSE
	anchored = TRUE
	var/idle_state = "lpad-idle"
	var/warmup_state = "lpad-idle"
	var/sending_state = "lpad-beam"
	var/warmup_time = 3 SECONDS
	var/cargo_hold_id
	layer = TABLE_LAYER
	circuit = /obj/item/circuitboard/machine/contrabandpad

	// Множитель эффективности (рассчитывается в RefreshParts)
	var/efficiency_multiplier = 1.0

/obj/machinery/vanguard/contraband/RefreshParts()
	var/total_rating = 0
	var/part_count = 0

	for(var/obj/item/stock_parts/part in component_parts)
		if(istype(part, /obj/item/stock_parts/scanning_module) || istype(part, /obj/item/stock_parts/manipulator))
			total_rating += part.rating
			part_count++

	// Формула: multiplier = 1.0 + ((average_rating - 1) * 0.25)
	// T1 = 1.0x (без бонуса)
	// T2 = 1.25x
	// T3 = 1.50x
	// T4 = 1.75x
	// T5 = 2.00x
	// T6 = 2.25x
	if(part_count > 0)
		var/average_rating = total_rating / part_count
		efficiency_multiplier = 1.0 + ((average_rating - 1) * 0.25)
	else
		efficiency_multiplier = 1.0

/obj/machinery/vanguard/contraband/proc/get_efficiency()
	var/total_rating = 0
	var/part_count = 0
	for(var/obj/item/stock_parts/part in component_parts)
		if(istype(part, /obj/item/stock_parts/scanning_module) || istype(part, /obj/item/stock_parts/manipulator))
			total_rating += part.rating
			part_count++
	if(part_count > 0)
		return ((total_rating / part_count) - 1) * 0.25
	return 0

/obj/machinery/vanguard/contraband/proc/get_adjusted_value(obj/item/I, base_value)
	return round(base_value * efficiency_multiplier)

// ============================================
// ОСМОТР
// ============================================

/obj/machinery/vanguard/contraband/examine(mob/user)
	. = ..()
	. += "\nDisplay shows you current efficiency of the exchange pad: [span_green("[get_efficiency() * 100]% bonus")]"

// ============================================
// СБОРКА / РАЗБОРКА (стандартные процедуры)
// ============================================

/obj/machinery/vanguard/contraband/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "lpad-idle-off", "lpad-idle", I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

// ============================================
// АНИМАЦИЯ
// ============================================

/obj/machinery/vanguard/contraband/proc/play_beam()
	icon_state = sending_state
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/machinery/vanguard/contraband, reset_icon)), 2 SECONDS)

/obj/machinery/vanguard/contraband/proc/reset_icon()
	icon_state = idle_state


// ============================================
// КОНСОЛЬ УПРАВЛЕНИЯ ПЛАТФОРМОЙ
// ============================================
/obj/machinery/computer/vanguard_control/contraband
	name = "contraband exchange terminal"
	desc = "A console for exchanging contraband for bounty points. Points are credited to the ID card of the user."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	icon_screen = "request"
	icon_keyboard = "id_key"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/computer/contrabandpad

	var/obj/machinery/vanguard/contraband/pad
	var/sending = FALSE
	var/status_report = "Ready for delivery."
	var/mob/living/last_user

	// Таблица стоимости контрабанды в очках
	var/list/contraband_values = list(
		/obj/item/gun/ballistic = 50,
		/obj/item/gun/energy = 40,
		/obj/item/melee/baton = 20,
		/obj/item/reagent_containers/hypospray = 30,
		/obj/item/stack/sheet/plasteel = 5,
		/obj/item/storage/box/syndie_kit = 100,
		/obj/item/clothing/under/syndicate = 25,
		/obj/item/reagent_containers/food/drinks/bottle/whiskey = 10,
		/obj/item/reagent_containers/glass/bottle = 15
	)

+/obj/machinery/computer/vanguard_control/contraband/Initialize(mapload)
+	. = ..()
+	return INITIALIZE_HINT_LATELOAD
+
+/obj/machinery/computer/vanguard_control/contraband/LateInitialize()
+	. = ..()
+	pad = locate() in range(4, src)

/obj/machinery/computer/vanguard_control/contraband/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	if(.)
		return TRUE

	if(!istype(I))
		return FALSE

	if(!istype(I.buffer, /obj/machinery/vanguard/contraband))
		to_chat(user, "<span class='warning'>Your multitool doesn't have a valid contraband pad in its buffer!</span>")
		return TRUE

	pad = I.buffer
	to_chat(user, "<span class='notice'>You link [src] with [pad] using [I].</span>")
	return TRUE

/obj/machinery/computer/vanguard_control/contraband/proc/get_contraband_value(obj/item/I)
	for(var/typepath in contraband_values)
		if(istype(I, typepath))
			var/value = contraband_values[typepath]
			if(istype(I, /obj/item/stack))
				var/obj/item/stack/S = I
				value *= S.amount
			return value
	return 0

/obj/machinery/vanguard/contraband/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	if(.)
		return TRUE

	I.buffer = src
	to_chat(user, "<span class='notice'>You add [src] to [I]'s buffer. Now use the multitool on a contraband exchange terminal to link them.</span>")
	return TRUE

/obj/machinery/computer/vanguard_control/contraband/proc/recalc()
	if(sending)
		return FALSE

	var/total_value = 0
	if(pad)
		for(var/atom/movable/AM in get_turf(pad))
			if(AM == pad)
				continue
			if(isitem(AM))
				var/obj/item/I = AM
				var/base_value = get_contraband_value(I)
				if(base_value > 0)
					total_value += pad.get_adjusted_value(I, base_value)

	if(total_value > 0)
		var/mult_text = ""
		if(pad && pad.efficiency_multiplier > 1.0)
			mult_text = " (with [pad.efficiency_multiplier]x efficiency bonus)"
		status_report = "Contraband detected. Value: [total_value] points[mult_text]."
		playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
	else
		status_report = "No applicable contraband found."
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)

/obj/machinery/computer/vanguard_control/contraband/proc/start_sending()
	if(sending)
		return
	sending = TRUE
	status_report = "Sending contraband..."

	if(pad)
		pad.icon_state = pad.warmup_state
		addtimer(CALLBACK(pad, TYPE_PROC_REF(/obj/machinery/vanguard/contraband, play_beam)), pad.warmup_time)

	addtimer(CALLBACK(src, PROC_REF(send)), pad ? pad.warmup_time : 3 SECONDS)

/obj/machinery/computer/vanguard_control/contraband/proc/stop_sending()
	sending = FALSE
	if(pad)
		pad.icon_state = pad.idle_state

/obj/machinery/computer/vanguard_control/contraband/proc/send()
	playsound(loc, 'sound/machines/wewewew.ogg', 70, TRUE)

	if(!sending || !pad)
		stop_sending()
		return

	var/total_value = 0
	var/items_sent = 0

	for(var/atom/movable/AM in get_turf(pad))
		if(AM == pad)
			continue
		if(isitem(AM))
			var/obj/item/I = AM
			var/base_value = get_contraband_value(I)
			if(base_value > 0)
				var/adjusted_value = pad.get_adjusted_value(I, base_value)
				total_value += adjusted_value
				items_sent++
				qdel(AM)

	if(items_sent > 0)
		var/points_credited = 0
		if(last_user && !QDELETED(last_user))
			var/obj/item/card/id/user_id = last_user.get_idcard()
			if(user_id)
				user_id.contraband_points += total_value
				points_credited = total_value
				to_chat(last_user, "<span class='notice'>[total_value] bounty point\s credited to your ID card.</span>")
			else
				status_report = "Contraband processed, but no ID card found on user!"
		else
			status_report = "Contraband processed, but user has left!"

		if(points_credited > 0)
			status_report = "Contraband processed! [points_credited] points distributed."

		pad.visible_message("<span class='notice'>[pad] activates and beams away the contraband!</span>")
		playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
	else
		status_report = "No applicable contraband found. Aborting."

	last_user = null
	stop_sending()


/obj/machinery/computer/vanguard_control/contraband/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "computer", "computer", I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

// ============================================
// TGUI
// ============================================

/obj/machinery/computer/vanguard_control/contraband/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ContrabandExchange", name)
		ui.open()

/obj/machinery/computer/vanguard_control/contraband/ui_data(mob/user)
	var/list/data = list()
	data["pad"] = pad ? TRUE : FALSE
	data["sending"] = sending
	data["status_report"] = status_report

	data["efficiency_multiplier"] = 1.0
	if(pad)
		data["efficiency_multiplier"] = pad.efficiency_multiplier

	var/mob/living/L = user
	var/obj/item/card/id/user_id = L?.get_idcard()
	data["user_has_id"] = user_id ? TRUE : FALSE
	data["user_points"] = user_id ? user_id.contraband_points : 0

	var/total_value = 0
	var/list/items_on_pad = list()
	if(pad)
		for(var/atom/movable/AM in get_turf(pad))
			if(AM == pad)
				continue
			if(isitem(AM))
				var/obj/item/I = AM
				var/base_value = get_contraband_value(I)
				if(base_value > 0)
					var/adjusted_value = pad.get_adjusted_value(I, base_value)
					total_value += adjusted_value
					items_on_pad += list(list(
						"name" = I.name,
						"base_value" = base_value,
						"adjusted_value" = adjusted_value
					))

	data["total_value"] = total_value
	data["items_on_pad"] = items_on_pad

	return data

/obj/machinery/computer/vanguard_control/contraband/ui_act(action, params)
	if(..())
		return
	if(!usr.canUseTopic(src, BE_CLOSE))
		return

	switch(action)
		if("recalc")
			recalc()
		if("send")
			last_user = usr
			start_sending()
		if("stop")
			stop_sending()
			last_user = null
	return TRUE
