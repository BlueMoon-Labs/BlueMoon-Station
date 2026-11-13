///Пад пункта подработки: отправляет ЦК предметы по контрактам поставки.
/obj/machinery/piratepad/civilian
	name = "contract pad"
	desc = "Пад пункта подработки NT. Положите на него то, что просят контракты поставки или спецзаказы партнёров, и отправьте с пульта: подходящие предметы уйдут ЦК, остальное останется на месте. Свою вещь отсюда же можно выставить на аукцион экипажа - кнопкой на пульте, итог торгов вернётся сюда запертой посылкой. Чужую запертую посылку пад не отправляет."
	layer = TABLE_LAYER
	warmup_time = 3 SECONDS
	circuit = /obj/item/circuitboard/machine/bountypad

/obj/machinery/piratepad/civilian/examine(mob/user)
	. = ..()
	. += span_notice("ЦК принимает отправки только с пада на станции. [econ_contracts_examine_note()]")

///Пульт пункта подработки: доска контрактов NT и отправка с пада подработки.
/obj/machinery/computer/piratepad_control/civilian
	name = "contract terminal"
	desc = "Пульт пункта подработки NT: контракты всех отделов станции, отправка предметов с пада подработки и приём вещей экипажа на аукцион."
	status_report = "Готов к отправке."
	icon_screen = "civ_bounty"
	icon_keyboard = "id_key"
	circuit = /obj/item/circuitboard/computer/bountypad
	//Родитель неразрушаем ради антагонистов, а станционный пульт подработки ломается как обычная машина.
	resistance_flags = NONE
	var/datum/weakref/sender_ref

/obj/machinery/computer/piratepad_control/civilian/examine(mob/user)
	. = ..()
	. += span_notice(econ_contracts_examine_note())

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
	var/list/offers = list()
	for(var/datum/market_offer/offer as anything in SSmarket.all_offers())
		if(offer.pad_open())
			offers += offer
	var/matched = 0
	var/imported = 0
	for(var/atom/movable/thing in get_turf(linked))
		if(thing == linked || locked_parcel(thing))
			continue
		imported += econ_contracts_imported_matches(thing)
		for(var/atom/movable/item as anything in econ_contract_candidates(thing))
			var/wanted = FALSE
			for(var/datum/econ_contract/delivery/contract as anything in contracts)
				if(contract.wants(item))
					wanted = TRUE
					break
			for(var/datum/market_offer/offer as anything in offers)
				if(wanted)
					break
				wanted = offer.matches(item)
			if(wanted)
				matched++
	if(!matched)
		status_report = "На паде нет ничего по контрактам поставки и спецзаказам партнёров.[imported_note(imported)]"
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return FALSE
	status_report = "Подходит под контракты и спецзаказы: [matched] шт.[imported_note(imported)]"
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
	var/offer_units = 0
	var/imported = 0
	for(var/atom/movable/thing in get_turf(linked))
		if(thing == linked || QDELETED(thing) || locked_parcel(thing))
			continue
		if(econ_contracts_ship(thing, sender))
			shipped++
		if(!QDELETED(thing))
			offer_units += econ_offers_ship(thing, sender)
		if(!QDELETED(thing))
			imported += econ_contracts_imported_matches(thing)
	if(!shipped && !offer_units)
		status_report = "На паде нет ничего по контрактам поставки и спецзаказам партнёров. Отправка отменена.[imported_note(imported)]"
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return
	status_report = "Отправлено по контрактам: [shipped], по спецзаказам партнёров: [offer_units] шт.[imported_note(imported)]"
	linked.visible_message(span_notice("[linked] срабатывает!"))
	flick(linked.sending_state, linked)
	playsound(loc, 'sound/machines/wewewew.ogg', 70, TRUE)
	playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)

/// Запертая именная посылка на паде (итог аукциона) чужому нажатию не отправляется: открыть её и сдать содержимое может только владелец.
/obj/machinery/computer/piratepad_control/civilian/proc/locked_parcel(atom/movable/thing)
	var/obj/item/storage/lockbox/order/parcel = thing
	return istype(parcel) && parcel.privacy_lock

/obj/machinery/computer/piratepad_control/civilian/proc/imported_note(imported)
	return imported ? " Купленное в автоматах и через снабжение по контрактам и спецзаказам не засчитывается: [imported] шт. осталось на паде." : ""

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
	return list("mode" = "pad", "contracts_help_topics" = econ_contracts_help_topics())

/obj/machinery/computer/piratepad_control/civilian/ui_data(mob/user)
	var/list/data = econ_contracts_ui_data(user)
	var/obj/machinery/piratepad/linked = linked_pad()
	data["pad"] = !!linked
	data["pad_on_station"] = !!(linked && is_station_level(linked.z))
	data["sending"] = sending
	data["status_report"] = status_report
	data["auction"] = auction_pad_data(user)
	return data

/obj/machinery/computer/piratepad_control/civilian/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(action == "send")
		sender_ref = WEAKREF(usr)
	. = ..()
	if(.)
		return
	if(action == "auction_list")
		return auction_list(usr, params)
	return econ_contract_console_act(usr, action, params, src)

/// Аукцион экипажа на пульте: вещи на паде с причиной отказа, условия и лимиты лотов. Всё, что не предмет (свет, машины, мобы), молча пропускается.
/obj/machinery/computer/piratepad_control/civilian/proc/auction_pad_data(mob/user)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/bank_account/account = econ_account_of(user)
	var/list/items = list()
	var/turf/pad_turf = get_turf(linked_pad())
	for(var/atom/movable/thing as anything in pad_turf?.contents)
		if(!isitem(thing) || thing.invisibility > SEE_INVISIBLE_LIVING)
			continue
		items += list(list("ref" = REF(thing), "name" = econ_auction_lot_name(thing), "problem" = econ_auction_item_problem(thing), "inscription" = econ_auction_inscription(thing)))
		if(length(items) >= AUCTION_PAD_ITEMS_MAX)
			break
	return list(
		"items" = items,
		"minutes" = settings.auction_minutes_options(),
		"fee" = settings.auction_crew_fee,
		"min_price" = AUCTION_MIN_INCREMENT,
		"max_price" = AUCTION_BID_MAX,
		"relist_left" = account ? CEILING(COOLDOWN_TIMELEFT(account, auction_relist_cooldown) / (1 SECONDS), 1) : 0,
		"mine" = length(SSmarket.crew_lots_of(account)),
		"per_account" = settings.auction_crew_lots_per_account,
		"lots" = length(SSmarket.crew_lots),
		"lots_max" = settings.auction_crew_lots_max,
	)

/// Вещь с пада уходит на аукцион экипажа от счёта того, кто нажал.
/obj/machinery/computer/piratepad_control/civilian/proc/auction_list(mob/living/user, list/params)
	var/obj/machinery/piratepad/linked = linked_pad()
	var/list/result
	if(!linked)
		result = list(FALSE, "Пад подработки не найден.")
	else if(sending)
		result = list(FALSE, "Пад занят отправкой: дождитесь её или отмените.")
	else if(!is_station_level(linked.z))
		result = list(FALSE, "Пад вне станции: аукцион принимает вещи только со станции.")
	else
		var/atom/movable/thing = istext(params["ref"]) ? locate(params["ref"]) : null
		if(!istype(thing) || thing.loc != get_turf(linked))
			result = list(FALSE, "Этой вещи уже нет на паде.")
		else
			var/price = params["price"]
			if(istext(price))
				price = text2num(price)
			var/minutes = params["minutes"]
			if(istext(minutes))
				minutes = text2num(minutes)
			var/anonymous = params["anonymous"]
			if(istext(anonymous))
				anonymous = text2num(anonymous)
			var/buyout = params["buyout"]
			if(istext(buyout))
				buyout = text2num(buyout)
			result = SSmarket.start_crew_lot(user, econ_account_of(user), thing, price, minutes, !!anonymous, get_turf(linked), buyout || 0)
	status_report = result[2]
	if(result[1])
		flick(linked.sending_state, linked)
		playsound(linked, 'sound/machines/wewewew.ogg', 50, TRUE)
	playsound(loc, result[1] ? 'sound/machines/synth_yes.ogg' : 'sound/machines/synth_no.ogg', 30, TRUE)
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
