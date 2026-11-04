///Пад пункта подработки: отправляет ЦК предметы по контрактам поставки.
/obj/machinery/piratepad/civilian
	name = "contract pad"
	desc = "Пад пункта подработки NT. Положите на него то, что просят контракты поставки, и отправьте с пульта: подходящие предметы уйдут ЦК, остальное останется на месте."
	layer = TABLE_LAYER
	warmup_time = 3 SECONDS
	circuit = /obj/item/circuitboard/machine/bountypad

/obj/machinery/piratepad/civilian/examine(mob/user)
	. = ..()
	. += span_notice("ЦК принимает отправки только с пада на станции. [econ_contracts_help()]")

///Пульт пункта подработки: доска контрактов NT и отправка с пада подработки.
/obj/machinery/computer/piratepad_control/civilian
	name = "contract terminal"
	desc = "Пульт пункта подработки NT: контракты всех отделов станции и отправка предметов с пада подработки."
	status_report = "Готов к отправке."
	icon_screen = "civ_bounty"
	icon_keyboard = "id_key"
	circuit = /obj/item/circuitboard/computer/bountypad
	//Родитель неразрушаем ради антагонистов, а станционный пульт подработки ломается как обычная машина.
	resistance_flags = NONE
	var/datum/weakref/sender_ref

/obj/machinery/computer/piratepad_control/civilian/examine(mob/user)
	. = ..()
	. += span_notice(econ_contracts_help())

/obj/machinery/computer/piratepad_control/civilian/LateInitialize()
	. = ..()
	pad = null
	if(istype(pad_ref?.resolve(), /obj/machinery/piratepad/civilian))
		return
	pad_ref = null
	for(var/obj/machinery/piratepad/civilian/candidate in range(4, src))
		pad_ref = WEAKREF(candidate)
		return

/obj/machinery/computer/piratepad_control/civilian/multitool_act(mob/living/user, obj/item/multitool/I)
	if(istype(I) && I.buffer && !istype(I.buffer, /obj/machinery/piratepad/civilian))
		to_chat(user, span_warning("[src] работает только с падом подработки."))
		return TRUE
	return ..()

/obj/machinery/computer/piratepad_control/civilian/proc/linked_pad()
	return pad_ref?.resolve()

/obj/machinery/computer/piratepad_control/civilian/recalc()
	if(sending)
		return FALSE
	var/obj/machinery/piratepad/linked = linked_pad()
	if(!linked)
		status_report = "Пад подработки не найден."
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return FALSE
	var/list/contracts = econ_delivery_contracts_for(null)
	var/matched = 0
	var/imported = 0
	for(var/atom/movable/thing in get_turf(linked))
		if(thing == linked)
			continue
		imported += econ_contracts_imported_matches(thing)
		for(var/atom/movable/item as anything in econ_contract_candidates(thing))
			for(var/datum/econ_contract/delivery/contract as anything in contracts)
				if(contract.wants(item))
					matched++
					break
	if(!matched)
		status_report = "На паде нет ничего по контрактам поставки.[imported_note(imported)]"
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return FALSE
	status_report = "Подходит под контракты: [matched] шт.[imported_note(imported)]"
	playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
	return TRUE

/obj/machinery/computer/piratepad_control/civilian/send()
	if(!sending)
		return
	sending = FALSE
	var/mob/sender = sender_ref?.resolve()
	sender_ref = null
	var/obj/machinery/piratepad/linked = linked_pad()
	if(!linked)
		status_report = "Пад подработки не найден."
		return
	linked.icon_state = linked.idle_state
	if(!is_station_level(linked.z))
		status_report = "Пад вне станции: ЦК принимает отправки только со станции."
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return
	var/shipped = 0
	var/imported = 0
	for(var/atom/movable/thing in get_turf(linked))
		if(thing == linked || QDELETED(thing))
			continue
		if(econ_contracts_ship(thing, sender))
			shipped++
		if(!QDELETED(thing))
			imported += econ_contracts_imported_matches(thing)
	if(!shipped)
		status_report = "На паде нет ничего по контрактам поставки. Отправка отменена.[imported_note(imported)]"
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return
	status_report = "Отправлено по контрактам: [shipped].[imported_note(imported)]"
	linked.visible_message(span_notice("[linked] срабатывает!"))
	flick(linked.sending_state, linked)
	playsound(loc, 'sound/machines/wewewew.ogg', 70, TRUE)
	playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)

/obj/machinery/computer/piratepad_control/civilian/proc/imported_note(imported)
	return imported ? " Купленное через снабжение по контрактам не засчитывается: [imported] шт. осталось на паде." : ""

/obj/machinery/computer/piratepad_control/civilian/withdraw_points(mob/living/user)
	to_chat(user, span_notice("У пульта подработки нет своей кассы: награды по контрактам сразу приходят на счета."))

/obj/machinery/computer/piratepad_control/civilian/stop_sending(custom_report)
	if(!sending)
		return
	sending = FALSE
	sender_ref = null
	status_report = custom_report || "Готов к отправке."
	var/obj/machinery/piratepad/linked = linked_pad()
	if(linked)
		linked.icon_state = linked.idle_state
	deltimer(sending_timer)

/obj/machinery/computer/piratepad_control/civilian/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ContractBoard", name)
		ui.open()

/obj/machinery/computer/piratepad_control/civilian/ui_static_data(mob/user)
	return list("mode" = "pad", "contracts_help" = econ_contracts_help())

/obj/machinery/computer/piratepad_control/civilian/ui_data(mob/user)
	var/list/data = econ_contracts_ui_data(user)
	var/obj/machinery/piratepad/linked = linked_pad()
	data["pad"] = !!linked
	data["pad_on_station"] = !!(linked && is_station_level(linked.z))
	data["sending"] = sending
	data["status_report"] = status_report
	return data

/obj/machinery/computer/piratepad_control/civilian/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(action == "send")
		sender_ref = WEAKREF(usr)
	. = ..()
	if(. || action != "take")
		return
	econ_take_contract(usr, params["uid"], src)
	return TRUE

///Маяк: сбрасывает пад и пульт пункта подработки.
/obj/item/civ_bounty_beacon
	name = "contract pad beacon"
	desc = "Маяк NT: бросьте его, и с ЦК пришлют пад и пульт пункта подработки."
	icon = 'icons/obj/objects.dmi'
	icon_state = "floor_beacon"
	var/uses = 2

/obj/item/civ_bounty_beacon/attack_self()
	loc.visible_message(span_warning("[src] начинает громко пищать!"))
	addtimer(CALLBACK(src, PROC_REF(launch_payload)), 4 SECONDS)

/obj/item/civ_bounty_beacon/proc/launch_payload()
	playsound(src, "sparks", 80, TRUE)
	switch(uses)
		if(2)
			new /obj/machinery/piratepad/civilian(drop_location())
		if(1)
			new /obj/machinery/computer/piratepad_control/civilian(drop_location())
			qdel(src)
	uses = uses - 1
