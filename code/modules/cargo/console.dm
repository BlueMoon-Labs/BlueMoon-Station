/obj/machinery/computer/cargo
	name = "supply console"
	desc = "Консоль снабжения: заказы у торговых партнёров за бюджет снабжения, заявки экипажа, рынок, спецзаказы и шаттл. Справка о рынке - в окне консоли."
	icon_screen = "supply"
	circuit = /obj/item/circuitboard/computer/cargo
	light_color = "#E2853D"//orange

	/// Версии цен, рынка и состава каталога, которые уже ушли в окна
	var/list/prices_seen
	/// Паки каталога окна: таблица цен окна несёт только их
	var/list/catalog_ids = list()
	///Can the supply console send the shuttle back and forth? Used in the UI backend.
	var/can_send = TRUE
	///Can this console only send requests?
	var/requestonly = FALSE
	///Can you approve requests placed for cargo? Works differently between the app and the computer.
	var/can_approve_requests = TRUE
	var/contraband = FALSE
	var/self_paid = FALSE
	var/safety_warning = "Автоматический шаттл снабжения не перевозит живых существ, тела, \
		ядерное оружие, маяки наведения и машины с искусственным интеллектом."
	var/blockade_warning = "Блюспейс-нестабильность: шаттл не может двигаться."
	/// radio used by the console to send messages on supply channel
	var/obj/item/radio/headset/radio
	/// var that tracks message cooldown
	var/message_cooldown
	var/list/loaded_coupons
	/// var that makes express console use rockets
	var/is_express = FALSE

/obj/machinery/computer/cargo/request
	name = "supply request console"
	desc = "Консоль заявок: здесь экипаж просит снабжение заказать пак или заказывает его на свой счёт. Пак из каталога своего отдела уходит заявкой отделу и оплачивается бюджетом отдела."
	icon_screen = "request"
	circuit = /obj/item/circuitboard/computer/cargo/request
	can_send = FALSE
	can_approve_requests = FALSE
	requestonly = TRUE

/obj/machinery/computer/cargo/Initialize(mapload)
	. = ..()
	radio = new /obj/item/radio/headset/headset_cargo(src)

/obj/machinery/computer/cargo/Destroy()
	QDEL_NULL(radio)
	return ..()

/obj/machinery/computer/cargo/proc/get_export_categories()
	. = EXPORT_CARGO
	if(contraband)
		. |= EXPORT_CONTRABAND
	if(obj_flags & EMAGGED)
		. |= EXPORT_EMAG

/obj/machinery/computer/cargo/emag_act(mob/user)
	. = ..()
	if(!requestonly && SSmarket.open_contraband_partners(user) && user)
		to_chat(user, span_notice("Консоль ловит частоты Вольных торговцев: контрабанду Синдиката они купят с шаттла, отправленного с этой консоли."))
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	if(user)
		user.visible_message(span_warning("[user] проводит подозрительной картой по [src]!"),
			span_notice((requestonly ? "Вы перенастраиваете консоль заявок: в каталоге появились особые поставки и контрабанда. Торговать с Вольными торговцами можно только с консоли снабжения, отправляющей шаттл." : "Вы перенастраиваете маршрутизацию и приёмник консоли: открыты особые поставки и контрабанда.")))

	obj_flags |= EMAGGED
	contraband = TRUE

	// This also permamently sets this on the circuit board
	var/obj/item/circuitboard/computer/cargo/board = circuit
	board.contraband = TRUE
	board.obj_flags |= EMAGGED
	update_static_data(user)

/obj/machinery/computer/cargo/on_construction()
	. = ..()
	circuit.configure_machine(src)

/obj/machinery/computer/cargo/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Cargo", name)
		ui.open()

/obj/machinery/computer/cargo/ui_data(mob/user)
	var/list/data = econ_cargo_ui_data(user, shows_contraband())
	data["can_take_offers"] = can_take_offers()
	data["requestonly"] = requestonly
	data["self_paid"] = self_paid
	data["can_send"] = can_send
	data["can_edit_cart"] = can_send
	data["can_approve_requests"] = can_approve_requests
	data["budget_request"] = requestonly ? econ_budget_request_ui(user) : null
	data["message"] = econ_cargo_message(blockade_warning, has_contraband_permit())
	return data

/obj/machinery/computer/cargo/ui_static_data(mob/user)
	catalog_ids = list()
	var/list/data = econ_cargo_window_static(obj_flags & EMAGGED, contraband, shows_contraband(), src, catalog_ids)
	data["market_help"] = econ_cargo_market_help(has_contraband_permit())
	data["help_topics"] = econ_cargo_help_topics(has_contraband_permit())
	data["requestonly"] = requestonly
	prices_seen = list(GLOB.econ_cargo_prices.version, GLOB.econ_cargo_prices.market_version, GLOB.econ_cargo_prices.catalog_version)
	RegisterSignal(GLOB.econ_cargo_prices, COMSIG_ECON_CARGO_PRICES_TICK, PROC_REF(on_cargo_prices_tick), override = TRUE)
	GLOB.econ_cargo_prices.start()
	return data

/// Пересчёт цен доходит до окон; без открытых окон консоль отписывается.
/obj/machinery/computer/cargo/proc/on_cargo_prices_tick(datum/econ_cargo_prices/source)
	SIGNAL_HANDLER
	prices_seen = econ_cargo_push(src, prices_seen, shows_contraband(), catalog_ids)
	if(!length(SStgui.open_uis_by_src[REF(src)]))
		UnregisterSignal(source, COMSIG_ECON_CARGO_PRICES_TICK)

/obj/machinery/computer/cargo/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(econ_cargo_viewer_act(usr, action, params, catalog_ids))
		return TRUE
	switch(action)
		if("auction_bid")
			. = econ_cargo_auction_bid(usr, params, src)
		if("buy_bundle")
			if(is_express)
				return
			. = econ_cargo_buy_bundle(usr, params, src, self_paid, can_send && !requestonly, shows_contraband())
		if("print_manifest")
			. = !!econ_print_manifest(usr, src)
		if("accept_offer")
			var/datum/market_offer/offer = offer_for_act(params["uid"])
			if(!offer?.accept(usr))
				var/datum/trade_partner/partner = offer?.get_partner()
				if(!offer?.accepted && partner?.embargoed())
					say("[partner.name] под эмбарго: спецзаказ не взять, пока эмбарго не снимут.")
				return
			say("Спецзаказ взят: [offer.quantity] x [offer.wanted_name] для [offer.partner_name()], срок [DisplayTimeText(offer.deadline - world.time)].")
			. = TRUE
		if("print_offer_manifest")
			var/datum/market_offer/offer = offer_for_act(params["uid"])
			if(!offer?.accepted)
				return
			var/datum/bank_account/account = econ_account_of(usr)
			if(!account)
				say("Накладная спецзаказа печатается на счёт сотрудника, счёт не найден.")
				return
			if(!COOLDOWN_FINISHED(account, manifest_print_cooldown))
				to_chat(usr, span_warning("Накладную можно печатать не чаще раза в [DisplayTimeText(ECON_MANIFEST_PRINT_COOLDOWN)]."))
				return
			COOLDOWN_START(account, manifest_print_cooldown, ECON_MANIFEST_PRINT_COOLDOWN)
			playsound(src, 'sound/effects/printer.ogg', 50, FALSE)
			usr.put_in_hands(print_offer_manifest(offer, drop_location()))
			log_econ("[key_name(usr)] напечатал накладную спецзаказа #[offer.uid]")
			. = TRUE
		if("send")
			if(!can_send || requestonly)
				return
			if(!SSshuttle.supply.canMove())
				say(safety_warning)
				return
			if(SSshuttle.supplyBlocked)
				say(blockade_warning)
				return
			if(SSshuttle.supply.getDockedId() == "supply_home")
				SSshuttle.supply.export_categories = get_export_categories()
				SSshuttle.moveShuttle(SSshuttle.supply.shuttle_id, "supply_away", TRUE)
				say("Шаттл снабжения отправляется.")
				investigate_log("[key_name(usr)] sent the supply shuttle away.", INVESTIGATE_CARGO)
			else
				investigate_log("[key_name(usr)] called the supply shuttle.", INVESTIGATE_CARGO)
				say("Шаттл снабжения вызван, прибудет через [DisplayTimeText(SSshuttle.supply.timeLeft(1))].")
				SSshuttle.moveShuttle(SSshuttle.supply.shuttle_id, "supply_home", TRUE)
			. = TRUE
		if("loan")
			if(requestonly || !SSshuttle.shuttle_loan)
				return
			if(SSshuttle.supplyBlocked)
				say(blockade_warning)
				return
			else if(SSshuttle.supply.mode != SHUTTLE_IDLE)
				return
			else if(SSshuttle.supply.getDockedId() != "supply_away")
				return
			else
				SSshuttle.shuttle_loan.loan_shuttle()
				say("Шаттл снабжения передан ЦК.")
				investigate_log("[key_name(usr)] accepted a shuttle loan event.", INVESTIGATE_CARGO)
				log_game("[key_name(usr)] accepted a shuttle loan event.")
				. = TRUE
		if("add")
			if(is_express)
				return
			var/id = text2path(params["id"])
			var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
			if(!istype(pack))
				return
			if((pack.hidden && !(obj_flags & EMAGGED)) || (pack.contraband && !contraband) || pack.DropPodOnly)
				return
			if(pack.exclusive_consoles && !is_type_in_list(src, pack.exclusive_consoles))
				return
			if(pack.department_catalog)
				return
			if(econ_cargo_order_refused(pack, src, self_paid, shows_contraband()))
				return
			var/datum/bank_account/account
			if(self_paid)
				account = econ_cargo_private_account(usr, src)
				if(!account)
					return
			var/reason = ""
			var/datum/economy_department/budget_department
			if(requestonly && !self_paid)
				reason = econ_cargo_given_reason(params)
				if(!reason)
					if(!usr.client)
						return
					budget_department = econ_request_department(usr, pack)
					reason = tgui_input_text(usr, "Причина:", budget_department ? "Заявка: платит [budget_department.budget_name]" : "Заявка снабжению", "", ECON_REQUEST_REASON_MAX, FALSE, TRUE)
					if(isnull(reason) || QDELETED(src) || QDELETED(ui) || ui_status(usr, ui.state) != UI_INTERACTIVE)
						return
				budget_department = econ_request_department(usr, pack, src)
			if(budget_department)
				for(var/obj/item/coupon/coupon_check as anything in loaded_coupons)
					if(pack.type == coupon_check.discounted_pack)
						say("Купон остаётся в консоли: заявку оплатит бюджет отдела.")
						break
				econ_cargo_department_order(budget_department, usr, pack, reason, econ_cargo_add_amount(params), src, radio)
				post_signal("supply")
				return TRUE

			var/obj/item/coupon/applied_coupon
			for(var/i in loaded_coupons)
				var/obj/item/coupon/coupon_check = i
				if(pack.type == coupon_check.discounted_pack)
					say("Найден купон: скидка [round(coupon_check.discount_pct_off * 100)]%.")
					coupon_check.moveToNullspace()
					applied_coupon = coupon_check
					break

			var/amount = econ_cargo_add_amount(params)
			var/datum/trade_partner/partner = econ_requested_partner(params, pack, shows_contraband())
			for(var/i in 1 to amount)
				var/datum/supply_order/order = econ_cargo_new_order(usr, pack, reason, account, requestonly && !self_paid, i == 1 ? applied_coupon : null, get_turf(src))
				order.contraband_supply = shows_contraband()
				order.partner_id = partner?.id
			if(account)
				say("Заказ принят[amount > 1 ? ", [amount] шт." : ""]: оплата со счёта [account.account_holder] при доставке.")
			if(requestonly && message_cooldown < world.time)
				radio.talk_into(src, "Был запрошен новый заказ.", RADIO_CHANNEL_SUPPLY)
				message_cooldown = world.time + ECON_CARGO_REQUEST_RADIO_COOLDOWN
			. = TRUE
		if("remove")
			if(!can_send)
				return
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
				if(SO.id == id)
					if(SO.applied_coupon)
						say("Купон возвращён.")
						SO.applied_coupon.forceMove(get_turf(src))
					econ_cancel_order(SO, usr)
					SSshuttle.shoppinglist -= SO
					. = TRUE
					break
		if("clear")
			if(!can_send)
				return
			for(var/datum/supply_order/SO as anything in SSshuttle.shoppinglist)
				econ_cancel_order(SO, usr)
			SSshuttle.shoppinglist.Cut()
			. = TRUE
		if("approve")
			if(!can_approve_requests)
				return
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.requestlist)
				if(SO.id == id)
					SSshuttle.requestlist -= SO
					SSshuttle.shoppinglist += SO
					. = TRUE
					break
		if("deny")
			if(!can_approve_requests)
				return
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.requestlist)
				if(SO.id == id)
					SSshuttle.requestlist -= SO
					. = TRUE
					break
		if("denyall")
			if(requestonly)
				return
			SSshuttle.requestlist.Cut()
			. = TRUE
		if("toggleprivate")
			self_paid = !self_paid
			. = TRUE
	if(.)
		post_signal("supply")

/// Спецзаказы берёт и печатает только консоль снабжения на станции, не экспресс и не консоль запросов.
/obj/machinery/computer/cargo/proc/can_take_offers()
	return !requestonly && !is_express && is_station_level(z)

/// Спецзаказ по uid из окна, если консоль его берёт и партнёр ей виден.
/obj/machinery/computer/cargo/proc/offer_for_act(uid)
	var/datum/market_offer/offer = can_take_offers() ? SSmarket.offer_by_uid(uid) : null
	return econ_partner_visible(offer?.get_partner(), shows_contraband()) ? offer : null

/// Вольных торговцев видит и заказывает у них только взломанная консоль, которая отправляет шаттл.
/obj/machinery/computer/cargo/proc/shows_contraband()
	return !requestonly && !is_express && (obj_flags & EMAGGED)

/// Шаттл с этой консоли идёт с допуском контрабанды (взлом или широкий приёмник платы): Вольные торговцы покупают его груз, и консоль видит эти сделки.
/obj/machinery/computer/cargo/proc/has_contraband_permit()
	return !requestonly && !is_express && (get_export_categories() & EXPORT_CONTRABAND)

/obj/machinery/computer/cargo/proc/post_signal(command)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = command))
	frequency.post_signal(src, status_signal)
