#define TRANSFER_BONUS_EFFICIENCY 5

/obj/machinery/bloodbankgen
	name = "Blood bank generator"
	desc = "Преобразует обычную кровь в универсальную синтетическую, совместимую с любой группой."
	icon = 'icons/obj/bloodbank.dmi'
	icon_state = "bloodbank-off"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 80
	active_power_usage = 300
	circuit = /obj/item/circuitboard/machine/bloodbankgen
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_SET_MACHINE
	var/draining = FALSE // draining of bag
	var/filling = FALSE // filling outbag
	var/obj/item/reagent_containers/blood/bag = null
	var/obj/item/reagent_containers/blood/outbag = null
	var/maxbloodstored = 500 // Max uints of blood bank
	var/transfer_amount = 20 // Draining && Filling amount
	var/efficiency = 1
	var/datum/looping_sound/bloodbankgen/soundloop // Working sound

/obj/machinery/bloodbankgen/Initialize(mapload)
	. = ..()
	create_reagents(maxbloodstored, NO_REACT)
	update_icon()
	soundloop = new(src, draining || filling)

/obj/machinery/bloodbankgen/Destroy()
	if(bag)
		bag.forceMove(drop_location())
		bag = null
	if(outbag)
		outbag.forceMove(drop_location())
		outbag = null
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/bloodbankgen/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Статус дисплей показывает: \n\
		- Эффективность конвертации: <b>[efficiency*100]%</b>.")

/obj/machinery/bloodbankgen/handle_atom_del(atom/A)
	..()
	if(A == bag)
		bag = null
		update_icon()
	if(A == outbag)
		outbag = null
		update_icon()
	QDEL_NULL(soundloop)

/obj/machinery/bloodbankgen/RefreshParts()
	var/E = 0
	var/bin_rating = 0
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		E += M.rating
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		bin_rating += B.rating

	efficiency = E
	transfer_amount = round(initial(transfer_amount) + TRANSFER_BONUS_EFFICIENCY*(efficiency))
	maxbloodstored = initial(maxbloodstored) * bin_rating
	var/datum/reagents/R = reagents
	if(istype(R))
		reagents.maximum_volume = maxbloodstored

/obj/machinery/bloodbankgen/update_icon_state()
	if(is_operational())
		icon_state = "bloodbank-[is_operational() ? "on" : "off"]"

/obj/machinery/bloodbankgen/update_overlays()
	. = ..()
	if(panel_open)
		. += "bloodbank-panel"

	add_bag_overlay(., bag, "input")
	add_bag_overlay(., outbag, "output")

/obj/machinery/bloodbankgen/proc/add_bag_overlay(list/result, obj/item/reagent_containers/blood/bag, prefix)
	if(!bag)
		return

	result += "bloodbag-[prefix]"

	if(!bag.reagents.total_volume)
		return

	var/mutable_appearance/filling_overlay = mutable_appearance(icon, "[prefix]-reagent")

	var/percent = round((bag.reagents.total_volume / bag.volume) * 100)

	// Выбор иконки по проценту
	switch(percent)
		if(0 to 9)
			filling_overlay.icon_state = "[prefix]-reagent0"
		if(10 to 24)
			filling_overlay.icon_state = "[prefix]-reagent10"
		if(25 to 49)
			filling_overlay.icon_state = "[prefix]-reagent25"
		if(50 to 74)
			filling_overlay.icon_state = "[prefix]-reagent50"
		if(75 to 79)
			filling_overlay.icon_state = "[prefix]-reagent75"
		if(80 to 90)
			filling_overlay.icon_state = "[prefix]-reagent80"
		if(91 to INFINITY)
			filling_overlay.icon_state = "[prefix]-reagent100"

	filling_overlay.color = list(mix_color_from_reagents(bag.reagents.reagent_list))
	result += filling_overlay

/obj/machinery/bloodbankgen/process()
	if(!is_operational())
		soundloop.stop()
		use_power = NO_POWER_USE
		return

	if(draining || filling)
		use_power = ACTIVE_POWER_USE
		soundloop.start()
		if(draining)
			if(reagents.total_volume >= reagents.maximum_volume || !bag || !bag.reagents.total_volume)
				ToggleDrain(silent = TRUE)
				playsound(src, 'sound/machines/triple_beep.ogg', 50, 1)
				return
			bag.reagents.get_reagent_amount()
			var/datum/reagent/blood/selected_blood
			for(var/datum/reagent/blood/B in bag.reagents.reagent_list)
				if(islist(B.data) && B.data["blood_type"] == "SY")
					continue
				selected_blood = B
				break
			var/amount = 0
			if(selected_blood)
				amount = round(min(selected_blood.volume, min(transfer_amount, reagents.maximum_volume - reagents.total_volume)))
			if(!selected_blood || !amount)
				ToggleDrain(silent = TRUE)
				playsound(src, 'sound/machines/triple_beep.ogg', 50, 1)
				return

			var/bonus = round((amount/transfer_amount)*(TRANSFER_BONUS_EFFICIENCY*efficiency))
			reagents.add_reagent(/datum/reagent/blood/synthetics, amount + bonus)
			bag.reagents.remove_reagent(selected_blood.type, amount)
		if(filling)
			if(!reagents.total_volume || !outbag || outbag.reagents.total_volume >= outbag.reagents.maximum_volume)
				ToggleFilling(silent = TRUE)
				playsound(src, 'sound/machines/ping.ogg', 50, 1)
				return
			//monitor the output bag's  reagents storage.
			var/amount = min(transfer_amount, outbag.reagents.maximum_volume - outbag.reagents.total_volume)
			reagents.trans_to(outbag, amount)
		update_icon()
	else
		use_power = IDLE_POWER_USE
		soundloop.stop()

/obj/machinery/bloodbankgen/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(!anchored)
		balloon_alert(user, span_balloon_warning("Прикрути!"))
		return TRUE
	if(default_deconstruction_screwdriver(user, "bloodbank-off", "bloodbank-off", I))
		if(bag)
			var/obj/item/reagent_containers/blood/B = bag
			B.forceMove(drop_location())
			bag = null
		if(outbag)
			var/obj/item/reagent_containers/blood/B = outbag
			B.forceMove(drop_location())
			outbag = null
		update_icon()
	return TRUE

/obj/machinery/bloodbankgen/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	var/result = default_unfasten_wrench(user, I, 2 SECONDS)
	if(result == SUCCESSFUL_UNFASTEN)
		if(bag)
			var/obj/item/reagent_containers/blood/B = bag
			B.forceMove(drop_location())
			bag = null
		if(outbag)
			var/obj/item/reagent_containers/blood/B = outbag
			B.forceMove(drop_location())
			outbag = null
		update_icon()

	return result != CANT_UNFASTEN

/obj/machinery/bloodbankgen/can_be_unfasten_wrench(mob/user, silent = FALSE)
	. = ..()
	if(. == FAILED_UNFASTEN)
		return .
	if(!panel_open)
		if(!silent)
			balloon_alert(user, "Открути панель")
		return FAILED_UNFASTEN

/obj/machinery/bloodbankgen/crowbar_act(mob/living/user, obj/item/I)
	. = ..()
	if(default_deconstruction_crowbar(I))
		return TRUE

/obj/machinery/bloodbankgen/attackby(obj/item/O, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(istype(O, /obj/item/reagent_containers/blood))
		. = TRUE //no afterattack
		if(bag && outbag)
			balloon_alert(user, span_balloon_warning("Нет места!"))
			return
		else if(!bag || !outbag)
			var/datum/reagent/blood/B = O.reagents.get_master_reagent()
			var/is_syntblood = istype(B) && islist(B.data) && B.data["blood_type"] == "SY"
			if(is_syntblood || O.reagents.reagent_list.len == 0)
				attach_bag(O, user, is_input = FALSE)
			else // Blood I guess
				attach_bag(O, user, is_input = TRUE)

/obj/machinery/bloodbankgen/is_operational()
	return ..() && anchored

/obj/machinery/bloodbankgen/proc/ToggleDrain(mob/user, silent = FALSE)
	if(!draining && !bag)
		if(!silent)
			to_chat(user, span_warning("Пакет на переработку не установлен!"))
		return

	draining = !draining
	update_icon()

/obj/machinery/bloodbankgen/proc/ToggleFilling(mob/user, silent = FALSE)
	if(!filling && !outbag)
		if(!silent)
			to_chat(user, span_warning("Пакет для заполнения не установлен!"))
		return

	filling = !filling
	update_icon()

/obj/machinery/bloodbankgen/proc/detach_bag(mob/user, is_input)
	var/obj/item/B = is_input ? bag : outbag
	if(!B)
		return

	B.forceMove(drop_location())
	if(user && Adjacent(user) && user.can_hold_items())
		user.put_in_hands(B)

	if(is_input)
		bag = null
		draining = null
	else
		outbag = null
		filling = null

	playsound(src, 'sound/machines/eject.ogg', 70, 1)
	update_icon()

/obj/machinery/bloodbankgen/proc/attach_bag(obj/item/O, mob/user, silent = FALSE, is_input)
	var/obj/item/B = is_input ? bag : outbag
	if(B)
		if(!silent)
			to_chat(user, span_warning("[is_input ? "Пакет на переработку уже установлен." : "Пакет для заполнения уже установлен."]"))
		return

	if(panel_open)
		balloon_alert(user, span_balloon_warning("Закрой панель!"))
		return
	if(!anchored)
		balloon_alert(user, span_balloon_warning("Прикрути!"))
		return
	if(!user.transferItemToLoc(O, src))
		return

	if(is_input)
		bag = O
	else
		outbag = O

	if(!silent)
		to_chat(user, span_notice("[is_input ? "[O] помещен на переработку." : "[O] помещен для заполнения."]"))

	playsound(src, 'sound/machines/eject.ogg', 70, 1)
	update_icon()

/obj/machinery/bloodbankgen/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, no_tk = TRUE, silent = TRUE))
		return
	if(outbag)
		detach_bag(user, FALSE)
	else if(bag)
		detach_bag(user, TRUE)

/obj/machinery/bloodbankgen/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/bloodbankgen/ui_status(mob/user)
	. = ..()
	if(. <= UI_DISABLED)
		return .
	if(!is_operational())
		return UI_DISABLED

/obj/machinery/bloodbankgen/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BloodBankGen", name)
		ui.open()

/obj/machinery/bloodbankgen/ui_data(mob/user)
	var/list/data = list()
	data["bank"] = list("maxVolume" = reagents.maximum_volume, "currentVolume" = reagents.total_volume)
	if(bag)
		data["inputBag"] = list("maxVolume" = bag.reagents.maximum_volume, "currentVolume" = bag.reagents.total_volume)
	else
		data["inputBag"] = null
	if(outbag)
		data["outputBag"] = list("maxVolume" = outbag.reagents.maximum_volume, "currentVolume" = outbag.reagents.total_volume)
	else
		data["outputBag"] = null
	data["draining"] = draining
	data["filling"] = filling

	return data

/obj/machinery/bloodbankgen/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .
	switch(action)
		if("drain")
			ToggleDrain(usr)
		if("fill")
			ToggleFilling(usr)
		if("take")
			detach_bag(usr, params["type"] == "input")
		if("insert")
			var/mob/user = usr
			var/obj/item/reagent_containers/blood/I = user.get_active_held_item()
			if(!istype(I))
				return
			attach_bag(I, user, TRUE, params["type"] == "input")

#undef TRANSFER_BONUS_EFFICIENCY
