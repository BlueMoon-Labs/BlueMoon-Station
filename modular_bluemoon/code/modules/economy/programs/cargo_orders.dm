/// Заказы снабжения с КПК: окно консоли снабжения. Снабжение заказывает за бюджет карго и решает заявки, остальные подают заявки; шаттл, аренда шаттла и спецзаказы - только с консоли.
/datum/computer_file/program/cargo_orders
	filename = "orderapp"
	filedesc = "Заказы снабжения"
	category = PROGRAM_CATEGORY_SUPL
	program_icon_state = "request"
	extended_desc = "Каталог, корзина и заявки снабжения NT с рынком и партнёрами. Снабжение заказывает за бюджет карго и решает заявки, остальные подают заявки. Шаттл и спецзаказы - только с консоли снабжения."
	requires_ntnet = TRUE
	size = 5
	tgui_id = "NtosCargo"
	program_icon = "boxes"
	available_on_ntnet = FALSE
	var/self_paid = FALSE
	/// Версии цен, рынка и состава каталога, которые уже ушли в окна
	var/list/prices_seen
	/// Паки каталога окна: таблица цен окна несёт только их
	var/list/catalog_ids = list()
	/// Оповещает канал снабжения о заявках, как консоль запросов; лежит в nullspace и попадает в КПК только на время сообщения
	var/obj/item/radio/headset/radio
	var/message_cooldown = 0

/datum/computer_file/program/cargo_orders/Destroy()
	QDEL_NULL(radio)
	return ..()

/// Снабжение по доступу ID в КПК или у пользователя: квартирмейстер и грузчики.
/datum/computer_file/program/cargo_orders/proc/is_supply_staff(mob/living/user)
	if(!isliving(user) || issilicon(user))
		return FALSE
	var/obj/item/card/id/card = computer?.GetID() || user.get_idcard(TRUE)
	if(!card)
		return FALSE
	var/list/access = card.GetAccess()
	return (ACCESS_CARGO in access) || (ACCESS_QM in access)

/datum/computer_file/program/cargo_orders/ui_static_data(mob/user)
	catalog_ids = list()
	var/list/data = econ_cargo_window_static(FALSE, FALSE, FALSE, null, catalog_ids)
	prices_seen = list(GLOB.econ_cargo_prices.version, GLOB.econ_cargo_prices.market_version, GLOB.econ_cargo_prices.catalog_version)
	RegisterSignal(GLOB.econ_cargo_prices, COMSIG_ECON_CARGO_PRICES_TICK, PROC_REF(on_cargo_prices_tick), override = TRUE)
	GLOB.econ_cargo_prices.start()
	return data

/datum/computer_file/program/cargo_orders/proc/on_cargo_prices_tick(datum/econ_cargo_prices/source)
	SIGNAL_HANDLER
	prices_seen = econ_cargo_push(src, prices_seen, FALSE, catalog_ids)
	if(!length(SStgui.open_uis_by_src[REF(src)]))
		UnregisterSignal(source, COMSIG_ECON_CARGO_PRICES_TICK)

/datum/computer_file/program/cargo_orders/ui_data(mob/user)
	var/list/data = get_header_data() + econ_cargo_ui_data(user, FALSE)
	var/staff = is_supply_staff(user)
	data["is_app"] = TRUE
	data["requestonly"] = !staff
	data["can_send"] = FALSE
	data["can_edit_cart"] = staff
	data["can_approve_requests"] = staff
	data["can_take_offers"] = FALSE
	data["self_paid"] = self_paid
	data["message"] = econ_cargo_message("Bluespace instability detected. Shuttle movement impossible.")
	return data

/datum/computer_file/program/cargo_orders/proc/announce_request()
	if(message_cooldown > world.time)
		return
	if(!radio)
		radio = new /obj/item/radio/headset/headset_cargo(null)
	radio.forceMove(computer)
	radio.talk_into(computer, "Был запрошен новый заказ.", RADIO_CHANNEL_SUPPLY)
	radio.moveToNullspace()
	message_cooldown = world.time + ECON_CARGO_REQUEST_RADIO_COOLDOWN

/datum/computer_file/program/cargo_orders/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !computer)
		return
	var/mob/living/user = usr
	var/staff = is_supply_staff(user)
	switch(action)
		if("add")
			var/datum/supply_pack/pack = SSshuttle.supply_packs[text2path(params["id"])]
			if(!istype(pack) || pack.hidden || pack.contraband || pack.DropPodOnly || pack.exclusive_consoles || pack.department_catalog || (pack.special && !pack.special_enabled))
				return
			if(econ_cargo_order_refused(pack, computer, self_paid, FALSE))
				return
			var/datum/bank_account/account
			if(self_paid)
				account = econ_cargo_private_account(user, computer)
				if(!account)
					return
			var/as_request = !staff && !self_paid
			var/reason = ""
			if(as_request)
				reason = econ_cargo_given_reason(params)
				if(!reason)
					if(!user.client)
						return
					reason = tgui_input_text(user, "Причина:", "Заявка снабжению", "", ECON_REQUEST_REASON_MAX, FALSE, TRUE)
					if(isnull(reason) || QDELETED(computer) || QDELETED(ui) || ui_status(user, ui.state) != UI_INTERACTIVE)
						return
			econ_cargo_new_order(user, pack, reason, account, as_request)
			if(account)
				computer.say("Order processed. The price will be charged to [account.account_holder]'s bank account on delivery.")
			if(as_request)
				announce_request()
			return TRUE
		if("toggleprivate")
			self_paid = !self_paid
			return TRUE
		if("print_manifest")
			econ_print_manifest(user, computer)
			return TRUE
		if("send", "loan", "accept_offer", "print_offer_manifest")
			computer.say("Это делается только с консоли снабжения.")
			return TRUE
	if(!staff)
		return
	switch(action)
		if("remove")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/order in SSshuttle.shoppinglist)
				if(order.id == id)
					if(order.applied_coupon)
						computer.say("Купон возвращён.")
						order.applied_coupon.forceMove(get_turf(computer))
					econ_cancel_order(order, user)
					SSshuttle.shoppinglist -= order
					return TRUE
		if("clear")
			for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
				econ_cancel_order(order, user)
			SSshuttle.shoppinglist.Cut()
			return TRUE
		if("approve", "deny")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/order in SSshuttle.requestlist)
				if(order.id == id)
					SSshuttle.requestlist -= order
					if(action == "approve")
						SSshuttle.shoppinglist += order
					return TRUE
		if("denyall")
			SSshuttle.requestlist.Cut()
			return TRUE
