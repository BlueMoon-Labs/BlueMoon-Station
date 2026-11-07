GLOBAL_DATUM_INIT(econ_cargo_prices, /datum/econ_cargo_prices, new)

/// Цены, поставщики и наличие паков, рынок и партнёры для окон снабжения. Пока окна подписаны, пересчёт раз в ECON_CARGO_PRICES_REFRESH.
/datum/econ_cargo_prices
	/// Тип пака -> list(cost, supplier, in_stock) без контрабандных партнёров
	var/list/table = list()
	/// То же с контрабандными партнёрами - для взломанной консоли
	var/list/table_all = list()
	var/list/market_public
	var/list/market_all
	var/list/partners_public
	var/list/partners_all
	/// Тип пака -> list(цена, id поставщика, в наличии) для каталога окон снабжения, без контрабанды и с ней
	var/list/prices_public = list()
	var/list/prices_all = list()
	var/built_at
	/// Растёт, когда пересчёт изменил цены каталога
	var/version = 0
	var/last_json
	/// Растёт, когда изменились рынок или партнёры
	var/market_version = 0
	var/last_market_json
	/// Растёт, когда изменился состав каталога: скрытые паки и выключенные особые
	var/catalog_version = 0
	var/last_catalog_key

/datum/econ_cargo_prices/proc/refresh(force = FALSE)
	if(!force && !isnull(built_at) && world.time < built_at + ECON_CARGO_PRICES_REFRESH)
		return
	built_at = world.time
	var/list/fresh = list()
	var/list/fresh_all = list()
	var/list/packs = list()
	for(var/pack_type in SSshuttle.supply_packs)
		packs += SSshuttle.supply_packs[pack_type]
	var/list/offers_all = SSmarket.best_offers(packs, null, TRUE)
	var/list/catalog_off = list()
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		var/list/offer_all = offers_all[pack]
		var/datum/trade_partner/cheapest = offer_all ? offer_all[1] : null
		// Самый дешёвый из всех и не контрабандный - он же самый дешёвый без контрабанды
		fresh[pack_type] = econ_cargo_price_row(pack, cheapest?.contraband ? SSmarket.best_offer(pack) : offer_all)
		fresh_all[pack_type] = econ_cargo_price_row(pack, offer_all)
		if(pack.hidden || (pack.special && !pack.special_enabled))
			catalog_off += "[pack_type]"
	table = fresh
	table_all = fresh_all
	market_public = econ_cargo_market_data(FALSE)
	market_all = econ_cargo_market_data(TRUE)
	partners_public = econ_cargo_partners_data(FALSE)
	partners_all = econ_cargo_partners_data(TRUE)
	var/json = json_encode(fresh) + json_encode(fresh_all)
	if(json != last_json)
		last_json = json
		version++
		prices_public = econ_cargo_window_prices(fresh)
		prices_all = econ_cargo_window_prices(fresh_all)
	var/market_json = json_encode(market_public) + json_encode(market_all) + json_encode(partners_public) + json_encode(partners_all)
	if(market_json != last_market_json)
		last_market_json = market_json
		market_version++
	var/catalog_key = "[length(SSshuttle.supply_packs)]|[jointext(catalog_off, ";")]"
	if(catalog_key != last_catalog_key)
		last_catalog_key = catalog_key
		catalog_version++

/// Общая таблица цен: тип пака -> list(цена, id поставщика, в наличии); имя поставщика окно берёт из партнёров. Окну уходят только строки его каталога.
/proc/econ_cargo_window_prices(list/rows)
	. = list()
	for(var/pack_type in rows)
		var/list/row = rows[pack_type]
		.[pack_type] = list(row["cost"], row["supplier"], row["in_stock"], row["choices"])

/// Паки каталога окна по его группам: таблица цен окна несёт только их.
/proc/econ_cargo_supply_ids(list/supplies)
	. = list()
	for(var/group in supplies)
		for(var/list/entry as anything in supplies[group]["packs"])
			.[entry["id"]] = TRUE

/// Изменчивая часть окна снабжения: цены паков pack_ids, рынок и партнёры. Уходит со статикой и частичным обновлением после пересчёта, а не с каждым обновлением окна.
/proc/econ_cargo_live_data(show_contraband, list/pack_ids)
	var/datum/econ_cargo_prices/prices = GLOB.econ_cargo_prices
	prices.refresh()
	var/list/table = show_contraband ? prices.prices_all : prices.prices_public
	var/list/window_prices = list()
	for(var/pack_type in pack_ids)
		var/list/row = table[pack_type]
		if(row)
			window_prices[pack_type] = row
	return list(
		"prices" = window_prices,
		"market" = show_contraband ? prices.market_all : prices.market_public,
		"partners" = show_contraband ? prices.partners_all : prices.partners_public,
	)

/// Шлёт окнам host то, что сменил пересчёт после seen = list(версия цен, рынка, каталога): смена состава каталога - всей статикой, цены и рынок - частичным обновлением. Возвращает новые версии.
/proc/econ_cargo_push(datum/host, list/seen, show_contraband, list/pack_ids)
	var/datum/econ_cargo_prices/prices = GLOB.econ_cargo_prices
	. = list(prices.version, prices.market_version, prices.catalog_version)
	var/list/windows = SStgui.open_uis_by_src[REF(host)]
	if(!length(windows) || (seen ~= .))
		return
	if(!seen || seen[3] != prices.catalog_version)
		INVOKE_ASYNC(host, TYPE_PROC_REF(/datum, update_static_data_for_all_viewers))
		return
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(econ_cargo_send_live), windows.Copy(), econ_cargo_live_data(show_contraband, pack_ids))

/// Статика окна снабжения: справка, каталог и цены, рынок и партнёры для него. Возвращает её, в pack_ids кладёт паки каталога.
/proc/econ_cargo_window_static(show_hidden, show_contraband_packs, show_contraband, obj/machinery/computer/cargo/console, list/pack_ids)
	. = econ_cargo_static_data(show_contraband)
	var/list/supplies = econ_cargo_supplies(show_hidden, show_contraband_packs, show_contraband, console)
	.["supplies"] = supplies
	pack_ids += econ_cargo_supply_ids(supplies)
	var/list/live = econ_cargo_live_data(show_contraband, pack_ids)
	for(var/key in live)
		.[key] = live[key]

/proc/econ_cargo_send_live(list/windows, list/live)
	for(var/datum/tgui/window as anything in windows)
		window.send_update(live)

/datum/econ_cargo_prices/proc/start()
	addtimer(CALLBACK(src, PROC_REF(tick)), ECON_CARGO_PRICES_REFRESH, TIMER_UNIQUE)

/datum/econ_cargo_prices/proc/tick()
	refresh(TRUE)
	SEND_SIGNAL(src, COMSIG_ECON_CARGO_PRICES_TICK)
	if(comp_lookup && comp_lookup[COMSIG_ECON_CARGO_PRICES_TICK])
		start()

/// Партнёр виден в окне: контрабандный - только на взломанной консоли снабжения.
/proc/econ_partner_visible(datum/trade_partner/partner, show_contraband)
	return partner && (show_contraband || !partner.contraband)

/// Строка таблицы цен по SSmarket.best_offer(): без поставщика - цена рынка, и пак в наличии, только если идёт мимо партнёров.
/proc/econ_cargo_price_row(datum/supply_pack/pack, list/offer)
	if(!offer)
		return list("cost" = pack.market_cost(), "supplier" = null, "in_stock" = !econ_pack_traded(pack))
	var/datum/trade_partner/supplier = offer[1]
	return list("cost" = offer[2], "supplier" = supplier.id, "in_stock" = TRUE, "choices" = length(offer) >= 3 ? offer[3] : null)

/// Цена, поставщик, товар рынка и наличие пака для строки каталога; поставщик - только из видимых окну партнёров.
/proc/econ_cargo_pack_entry(datum/supply_pack/pack, show_contraband_partners)
	var/list/price = show_contraband_partners ? GLOB.econ_cargo_prices.table_all[pack.type] : GLOB.econ_cargo_prices.table[pack.type]
	if(!price)
		price = econ_cargo_price_row(pack, SSmarket.best_offer(pack, null, show_contraband_partners))
	var/datum/trade_partner/supplier = SSmarket.get_partner(price["supplier"])
	var/datum/commodity/commodity = econ_pack_traded(pack) ? econ_pack_commodity(pack) : null
	return list(
		"cost" = price["cost"],
		"commodity" = commodity?.name,
		"supplier" = supplier?.name,
		"in_stock" = price["in_stock"],
	)

/// Неизменная часть строки каталога окна снабжения; цена, поставщик и наличие - в econ_cargo_live_data().
/proc/econ_cargo_static_entry(datum/supply_pack/pack)
	var/datum/commodity/commodity = econ_pack_traded(pack) ? econ_pack_commodity(pack) : null
	var/datum/trade_partner/exclusive = pack.partner_exclusive ? SSmarket.get_partner(pack.partner_exclusive) : null
	return list(
		"commodity" = commodity?.name,
		"contents" = econ_pack_contents(pack),
		"exclusive" = exclusive ? list(exclusive.name, pack.exclusive_tier) : null,
	)

/// Опись пака для карточки каталога: "имя ×N" по списку contains, одинаковые предметы сложены.
/proc/econ_pack_contents(datum/supply_pack/pack)
	. = list()
	var/list/counts = list()
	for(var/atom/item_type as anything in pack.contains)
		if(!ispath(item_type, /atom))
			continue
		var/item_name = initial(item_type.name)
		counts[item_name] = (counts[item_name] || 0) + 1
	for(var/item_name in counts)
		. += counts[item_name] > 1 ? "[item_name] ×[counts[item_name]]" : item_name

/// Где шаттл снабжения и сколько секунд до прибытия: state - station, centcom, to_station, to_centcom, recharging, loaned или away.
/proc/econ_cargo_shuttle_data()
	var/obj/docking_port/mobile/supply/shuttle = SSshuttle.supply
	if(!shuttle)
		return list("state" = "away", "eta" = 0)
	if(SSshuttle.shuttle_loan?.dispatched)
		return list("state" = "loaned", "eta" = 0)
	var/docked = shuttle.getDockedId()
	switch(shuttle.mode)
		if(SHUTTLE_IDLE)
			return list("state" = docked == "supply_home" ? "station" : (docked == "supply_away" ? "centcom" : "away"), "eta" = 0)
		if(SHUTTLE_RECHARGING)
			return list("state" = "recharging", "eta" = shuttle.timeLeft(1 SECONDS))
	var/heading_home = shuttle.destination?.shuttle_id == "supply_home"
	if(shuttle.mode == SHUTTLE_RECALL)
		heading_home = !heading_home
	return list("state" = heading_home ? "to_station" : "to_centcom", "eta" = shuttle.timeLeft(1 SECONDS))

/// Группы каталога снабжения без цен: цены уходят отдельной таблицей econ_cargo_live_data().
/proc/econ_cargo_supplies(show_hidden, show_contraband_packs, show_contraband_partners, obj/machinery/computer/cargo/console)
	GLOB.econ_cargo_prices.refresh()
	var/list/supplies = list()
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack.department_catalog || pack.DropPodOnly)
			continue
		if(pack.exclusive_consoles && !(console && is_type_in_list(console, pack.exclusive_consoles)))
			continue
		if(!supplies[pack.group])
			supplies[pack.group] = list("name" = pack.group, "packs" = list())
		if((pack.hidden && !show_hidden) || (pack.contraband && !show_contraband_packs) || (pack.special && !pack.special_enabled))
			continue
		var/list/entry = econ_cargo_static_entry(pack)
		entry["name"] = pack.name
		entry["id"] = pack_type
		entry["desc"] = pack.desc || pack.name
		entry["goody"] = pack.goody
		entry["access"] = pack.access
		entry["private_goody"] = pack.goody == PACK_GOODY_PRIVATE
		entry["can_private_buy"] = pack.can_private_buy
		entry["personal"] = econ_personal_catalog_pack(pack)
		supplies[pack.group]["packs"] += list(entry)
	supplies[ECON_PERSONAL_CATALOG_GROUP] = econ_personal_catalog_group(show_contraband_partners)
	return supplies

/// Справочные числа окна снабжения, общие для консоли и приложения.
/proc/econ_cargo_static_data(show_contraband)
	return list(
		"market_help" = econ_cargo_market_help(show_contraband),
		"help_topics" = econ_cargo_help_topics(show_contraband),
		"add_max" = ECON_CARGO_ADD_MAX,
		"reputation_per_credit" = SSmarket.reputation_per_credit,
		"reason_max" = ECON_REQUEST_REASON_MAX,
		"contracts_help" = econ_contracts_help(),
		"tier_step" = PARTNER_TIER_STEP,
		"tier_max" = PARTNER_TIER_MAX,
		"reputation_max" = PARTNER_REPUTATION_MAX,
		"private_markup" = ECON_PRIVATE_ORDER_MARKUP,
		"manifest_fee" = SSeconomy.settings.cargo_handling_fee,
	)

/proc/econ_cargo_market_data(show_contraband)
	var/list/commodities = list()
	for(var/id in SSmarket.commodities)
		if(id == COMMODITY_CONTRABAND && !show_contraband)
			continue
		var/datum/commodity/commodity = SSmarket.commodities[id]
		var/list/history = list()
		for(var/point in commodity.history)
			history += round(point, 0.01)
		var/datum/trade_partner/buyer = econ_cargo_best_buyer(id, show_contraband)
		commodities += list(list(
			"id" = id,
			"name" = commodity.name,
			"factor" = round(commodity.buy_factor(), 0.01),
			"sell" = round(commodity.sell_factor() * econ_buyer_factor(id, show_contraband), 0.01),
			"hot" = commodity.hot_mult > 1 ? round(commodity.hot_mult, 0.1) : 0,
			"demand" = round(commodity.demand * 100),
			"history" = history,
			"buyer" = buyer?.name,
		))
	return list("commodities" = commodities, "price_index" = round(SSeconomy.price_index(), 0.01))

/proc/econ_cargo_best_buyer(commodity_id, show_contraband)
	return SSmarket.best_buyer(commodity_id, show_contraband)

/proc/econ_partner_unlock_text(datum/trade_partner/partner)
	if(partner.unlocked)
		return null
	if(partner.contraband)
		return "Открывается только взломом консоли снабжения, до конца смены."
	if(!islist(partner.unlock))
		return "Закрыт для станции."
	if(partner.unlock["partner"])
		var/datum/trade_partner/sponsor = SSmarket.get_partner(partner.unlock["partner"])
		return "Откроется, когда репутация у партнёра \"[sponsor?.name]\" дойдёт до ступени [partner.unlock["tier"]]."
	return "Откроется, когда у [PARTNER_UNLOCK_SPONSORS] открытых партнёров репутация дойдёт до ступени [partner.unlock["any_two_tier"]]."

/proc/econ_cargo_partners_data(show_contraband)
	var/list/partners = list()
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if(!econ_partner_visible(partner, show_contraband))
			continue
		var/list/buys = list()
		for(var/commodity_id in partner.buys)
			var/datum/commodity/commodity = SSmarket.get_commodity(commodity_id)
			buys += "[commodity_id == PARTNER_ANY ? "всё остальное" : commodity?.name] x[partner.buys[commodity_id]]"
		var/list/sells = list()
		for(var/group in partner.sells_groups)
			sells += group == PARTNER_ANY ? "все группы каталога" : group
		partners += list(list(
			"id" = id,
			"name" = partner.name,
			"desc" = partner.desc,
			"unlocked" = partner.unlocked,
			"tier" = partner.tier(),
			"reputation" = round(partner.reputation),
			"discount" = round(partner.discount() * 100),
			"markup" = partner.markup,
			"wealth" = round(partner.wealth),
			"next_unlock" = econ_partner_unlock_text(partner),
			"embargo_minutes" = partner.embargoed() ? CEILING((partner.embargo_until - world.time) / (1 MINUTES) - 0.001, 1) : 0,
			"buys" = jointext(buys, ", "),
			"sells" = jointext(sells, ", "),
		))
	return partners

/// Динамические данные окна снабжения, общие для консоли и приложения КПК.
/proc/econ_cargo_ui_data(mob/user, show_contraband)
	var/list/data = econ_contracts_ui_data(user)
	var/datum/economy_department/manifest_department = econ_manifest_department_for(user)
	data["manifest_department"] = manifest_department?.name
	data["location"] = SSshuttle.supply.getStatusText()
	data["shuttle"] = econ_cargo_shuttle_data()
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	data["points"] = cargo?.account_balance
	data["away"] = SSshuttle.supply.getDockedId() == "supply_away"
	data["docked"] = SSshuttle.supply.mode == SHUTTLE_IDLE
	data["loan"] = !!SSshuttle.shuttle_loan
	data["loan_dispatched"] = SSshuttle.shuttle_loan && SSshuttle.shuttle_loan.dispatched
	data["cart"] = list()
	data["department_requests"] = list()
	for(var/datum/supply_order/order in SSshuttle.shoppinglist)
		data["cart"] += list(order.cart_entry())
		var/datum/economy_department/department = order.prepaid ? SSeconomy.get_department(order.department_id) : null
		if(department)
			data["department_requests"] += list(list(
				"id" = order.id,
				"object" = order.pack.name,
				"department" = department.name,
				"orderer" = order.orderer,
				"reason" = order.reason,
				"prepaid" = order.prepaid,
			))
	data["requests"] = list()
	for(var/datum/supply_order/order in SSshuttle.requestlist)
		data["requests"] += list(list(
			"object" = order.pack.name,
			"cost" = order.pack.get_cost(order.paying_account),
			"orderer" = order.orderer,
			"reason" = order.reason,
			"id" = order.id,
		))
	var/list/auction = econ_auction_ui_data(econ_account_of(user))
	for(var/key in auction)
		data[key] = auction[key]
	data["bundles"] = econ_bundles_ui_data()
	data["special_offers"] = list()
	for(var/datum/market_offer/offer as anything in SSmarket.all_offers())
		if(econ_partner_visible(offer.get_partner(), show_contraband))
			data["special_offers"] += list(offer.ui_entry())
	return data

/// Сообщение ЦК об отгрузке; сделки с контрабандным партнёром - только окну, которое его видит.
/proc/econ_cargo_message(blockade_warning, show_contraband = FALSE)
	if(SSshuttle.supplyBlocked)
		return blockade_warning
	var/message = SSshuttle.centcom_message
	if(show_contraband && length(SSmarket.contraband_message))
		message = message ? "[message] [SSmarket.contraband_message]" : SSmarket.contraband_message
	return message || "Не забывайте штамповать и возвращать накладные."

/// Сколько одинаковых паков добавить по нажатию: amount из окна в пределах 1..ECON_CARGO_ADD_MAX, без него - один.
/proc/econ_cargo_add_amount(list/params)
	var/amount = params["amount"]
	if(istext(amount))
		amount = text2num(amount)
	if(!isnum(amount))
		return 1
	return clamp(round(amount), 1, ECON_CARGO_ADD_MAX)

/// Ставка на аукционе из окна снабжения с личного счёта; ответ произносит speaker.
/proc/econ_cargo_auction_bid(mob/user, list/params, atom/movable/speaker)
	var/amount = params["amount"]
	if(istext(amount))
		amount = text2num(amount)
	var/uid = params["uid"]
	if(istext(uid))
		uid = text2num(uid)
	var/error = SSmarket.place_auction_bid(econ_account_of(user), amount, user, uid)
	if(error)
		to_chat(user, span_warning(error))
		return FALSE
	speaker.say("Ставка принята: [amount] кр.")
	return TRUE

/// Причина заявки из окна или null, если окно её не прислало.
/proc/econ_cargo_given_reason(list/params)
	var/reason = econ_ui_reason(params["reason"])
	return length(reason) ? reason : null

/// Отказ заказать пак сразу, до вопроса о причине; отказ произносит speaker.
/proc/econ_cargo_order_refused(datum/supply_pack/pack, atom/movable/speaker, self_paid, show_contraband)
	if(econ_pack_unavailable(pack, show_contraband))
		speaker.say("Нет в наличии у партнёров.")
		return TRUE
	if(self_paid && !pack.can_private_buy)
		speaker.say("Этот пак лично не купить.")
		return TRUE
	if(pack.goody == PACK_GOODY_PRIVATE && !self_paid)
		playsound(speaker, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
		speaker.say("Личные малые кейсы покупаются только со своего счёта.")
		return TRUE
	return FALSE

/// Личный счёт по ID в руке для частного заказа; без него отказ произносит speaker.
/proc/econ_cargo_private_account(mob/user, atom/movable/speaker)
	var/mob/living/living_user = user
	if(!istype(living_user) || issilicon(living_user))
		speaker.say("Лично покупает только сотрудник со своей ID-картой.")
		return null
	var/obj/item/card/id/id_card = living_user.get_idcard(TRUE)
	if(!istype(id_card))
		speaker.say("ID-карта не найдена.")
		return null
	if(istype(id_card, /obj/item/card/id/departmental_budget))
		speaker.say("Карта бюджета отдела для личной покупки не годится.")
		return null
	if(!istype(id_card.registered_account))
		speaker.say("У карты нет банковского счёта.")
		return null
	return id_card.registered_account

/// Новый заказ от имени user: в очередь заявок или сразу в корзину снабжения.
/proc/econ_cargo_new_order(mob/user, datum/supply_pack/pack, reason, datum/bank_account/account, as_request, obj/item/coupon/coupon, turf/requisition_turf)
	var/name = "*None Provided*"
	var/rank = "*None Provided*"
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		name = human_user.get_authentification_name()
		rank = human_user.get_assignment(hand_first = TRUE)
	else if(issilicon(user))
		name = user.real_name
		rank = "Silicon"
	var/datum/supply_order/order = new(pack, name, rank, user.ckey, reason, account, coupon)
	if(requisition_turf)
		order.generateRequisition(requisition_turf)
	if(as_request)
		SSshuttle.requestlist += order
	else
		SSshuttle.shoppinglist += order
	return order
