/// Личный счёт в КПК: баланс, история, переводы, чаевые, личные заказы, аукцион, контракты и объявления, акции и метадоллары.
/datum/computer_file/program/wallet
	filename = "wallet"
	filedesc = "Кошелёк"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "wallet"
	extended_desc = "Личный счёт: баланс, история операций, переводы и чаевые, оплата человеку рядом по его ID-карте и запрос оплаты у него, магазин одежды, игрушек и питомцев с доставкой капсулой и подарками, которые получатель забирает сам, личные заказы и подарки экипажу из каталога снабжения, ставки на аукционе сектора и экипажа, подработка по контрактам NT и объявлениям экипажа, акции, лотерея сектора и метадоллары."
	requires_ntnet = FALSE
	usage_flags = PROGRAM_ON_TABLETS
	size = 4
	tgui_id = "NtosWallet"
	program_icon = "wallet"
	/// Ответ на последнее действие для окна
	var/message = ""
	/// Счёт, к которому относится message: при смене карты ответ стирается
	var/datum/weakref/message_account
	/// Цены личного каталога для personal_prices_for, пересчитываются не чаще ECON_CARGO_PRICES_REFRESH
	var/list/personal_prices
	var/personal_prices_at
	var/datum/weakref/personal_prices_for

/// Счёт ID-карты в устройстве, без карты - собственный счёт пользователя.
/datum/computer_file/program/wallet/proc/wallet_account(mob/user)
	var/obj/item/card/id/card = computer?.GetID()
	if(istype(card) && card.registered_account)
		return card.registered_account
	return econ_account_of(user)

/datum/computer_file/program/wallet/ui_interact(mob/user, datum/tgui/ui)
	if(!SStgui.get_open_ui(user, src))
		message = ""
	return ..()

/datum/computer_file/program/wallet/ui_static_data(mob/user)
	return wallet_static_data()

/datum/computer_file/program/wallet/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet_batched/econ_shop))

/datum/computer_file/program/wallet/ui_data(mob/user)
	return get_header_data() + wallet_data(user)

/datum/computer_file/program/wallet/proc/wallet_static_data()
	var/datum/economy_settings/settings = SSeconomy.settings
	return list(
		"transfer_max" = settings.transfer_max,
		"transfer_cooldown" = settings.transfer_cooldown_seconds,
		"memo_max" = ECON_TRANSFER_MEMO_MAX,
		"name_max" = MAX_NAME_LEN,
		"audit_rights" = SSeconomy.audit_rights_text(),
		"owed_cap" = settings.owed_wages_cap_paychecks,
		"wage_floor" = settings.wage_floor,
		"tax_nt_share" = settings.tax_nt_share,
		"wage_interval" = round(settings.payroll_interval_ticks * SSeconomy.wait / (1 MINUTES), 1),
		"dormant_minutes" = settings.dormant_after_minutes,
		"performer_share" = settings.contract_performer_share,
		"contracts_help_topics" = econ_contracts_help_topics(),
		"crew" = wallet_crew_names(),
		"personal_catalog" = econ_personal_catalog_ui(),
		"personal_order_limit" = settings.personal_order_limit,
		"shop" = econ_shop_ui(),
		"engraving_price" = ECON_SHOP_ENGRAVING_PRICE,
		"engraving_max" = ECON_SHOP_ENGRAVING_MAX,
		"shop_cooldown" = ECON_SHOP_ORDER_COOLDOWN / (1 SECONDS),
		"cart_max" = ECON_SHOP_CART_MAX,
		"gift_minutes" = settings.shop_gift_accept_minutes,
		"nearby_range" = ECON_NEARBY_PAY_RANGE,
		"pay_request_minutes" = ECON_PAY_REQUEST_TTL / (1 MINUTES),
	)

/datum/computer_file/program/wallet/proc/wallet_data(mob/user)
	var/static/list/state_names = list("active", "frozen", "dormant")
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/bank_account/account = wallet_account(user)
	if(message && message_account?.resolve() != account)
		message = ""
	var/list/data = list(
		"message" = message,
		"metadollars_available" = !!user?.client?.ckey,
		"metadollars" = user?.client?.ckey ? SSmetadollars.get_metadollars(user.client.ckey) : 0,
		"has_account" = !!account,
		"lottery" = SSeconomy.lottery?.ui_entry(account),
	)
	if(!account)
		return data
	var/obj/item/card/id/card = computer?.GetID()
	data["from_card"] = istype(card) && card.registered_account == account
	data["holder"] = account.account_holder
	data["number"] = account.account_id
	data["balance"] = account.account_balance
	data["state"] = state_names[account.state + 1]
	data["blocked"] = !account.transferable
	data["anonymous"] = istype(account, /datum/bank_account/anonymous)
	data["personal"] = SSeconomy.is_personal_account(account)
	data["frozen_by"] = account.frozen_by
	data["freeze_source"] = account.state == ACCOUNT_FROZEN ? SSeconomy.freeze_source(account.frozen_by) : null
	data["freeze_reason"] = account.freeze_reason
	data["cooldown_left"] = CEILING(COOLDOWN_TIMELEFT(account, personal_payment_cooldown) / (1 SECONDS), 1)
	data["nearby"] = wallet_nearby_data(user)
	var/list/requests = list()
	for(var/datum/econ_pay_request/request as anything in econ_pay_requests_for(account))
		requests += list(list("id" = request.id, "from" = request.requester_name, "amount" = request.amount, "reason" = request.reason))
	data["pay_requests"] = requests
	var/list/gifts = list()
	for(var/datum/econ_shop_gift/gift as anything in econ_shop_gifts_for(account))
		gifts += list(list("id" = gift.id, "from" = gift.giver_name, "items" = econ_shop_cart_names(gift.cart), "left" = max(0, round((gift.expires_at - world.time) / (1 MINUTES), 1))))
	data["shop_gifts"] = gifts
	var/datum/economy_department/department = SSeconomy.get_department(account.department_id)
	data["wage"] = list(
		"grade" = account.pay_grade ? wallet_grade_name(account.pay_grade) : null,
		"department" = department?.name,
		"base" = account.pay_grade ? settings.wages[account.pay_grade] : 0,
		"bonus" = account.wage_bonus,
		"amount" = account.wage_amount(),
		"floor_only" = (!account.pay_grade || !department) && account.nt_floor_crew(),
		"tax_rate" = SSeconomy.tax_rate,
		"tax_nt_share" = SSeconomy.tax_nt_share_now(),
		"tax_mood_note" = SSeconomy.tax_mood_note(),
		"tax_mood_progress" = SSeconomy.tax_mood_progress(),
		"owed" = account.owed_wages,
	)
	data["history"] = account.ui_history()
	var/list/board = econ_contracts_ui_data(user, account)
	for(var/key in board)
		data[key] = board[key]
	var/list/shares = list()
	for(var/ticker in account.shares)
		var/datum/stock_company/company = SSmarket.get_company(ticker)
		shares += list(list(
			"ticker" = ticker,
			"name" = company?.name || ticker,
			"count" = account.shares[ticker],
			"value" = company ? round(company.price * account.shares[ticker]) : 0,
		))
	data["shares"] = shares
	data["portfolio"] = SSmarket.portfolio_value(account)
	var/list/personal = wallet_personal_data(account)
	for(var/key in personal)
		data[key] = personal[key]
	var/list/auction = econ_auction_ui_data(account)
	for(var/key in auction)
		data[key] = auction[key]
	return data

/// Личные заказы: цены каталога для счёта, свои оплаченные заказы в корзине и в пути, где шаттл снабжения.
/datum/computer_file/program/wallet/proc/wallet_personal_data(datum/bank_account/account)
	if(personal_prices_for?.resolve() != account || isnull(personal_prices_at) || world.time >= personal_prices_at + ECON_CARGO_PRICES_REFRESH)
		personal_prices = econ_personal_catalog_prices(account)
		personal_prices_at = world.time
		personal_prices_for = WEAKREF(account)
	var/list/orders = list()
	for(var/datum/supply_order/order as anything in econ_personal_orders_of(account))
		orders += list(list("id" = order.id, "name" = order.pack.name, "price" = order.prepaid, "gift_to" = order.gift_to?.account_holder))
	return list(
		"personal_prices" = personal_prices,
		"personal_orders" = orders,
		"personal_in_transit" = SSshuttle.supply?.personal_in_transit(account) || list(),
		"shuttle" = econ_cargo_shuttle_data(),
	)

/datum/computer_file/program/wallet/proc/wallet_crew_names()
	. = list()
	for(var/datum/data/record/record in GLOB.data_core.general)
		var/name = record.fields["name"]
		if(istext(name) && length(name))
			. |= name

/datum/computer_file/program/wallet/proc/wallet_grade_name(grade)
	return GLOB.econ_pay_grade_names[grade] || grade

/datum/computer_file/program/wallet/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return wallet_act(usr, action, params)

/datum/computer_file/program/wallet/proc/wallet_act(mob/living/user, action, list/params)
	if(!isliving(user) || !islist(params))
		return FALSE
	message_account = WEAKREF(wallet_account(user))
	switch(action)
		if("transfer", "tip")
			return wallet_payment(user, action, params)
		if("lottery_buy")
			return wallet_lottery(user, params["count"])
		if("personal_order")
			message = econ_personal_order(user, wallet_account(user), params["id"], params["price"], params["recipient"], params["hide_name"])[2]
			personal_prices_at = null
			return TRUE
		if("shop_order")
			message = econ_shop_order(user, wallet_account(user), params["items"], params["recipient"], params["hide_name"], econ_payer_name(computer?.GetID(), wallet_account(user)))[2]
			return TRUE
		if("shop_gift_accept")
			message = econ_shop_gift_accept(user, wallet_account(user), params["id"], econ_payer_name(computer?.GetID(), wallet_account(user)))[2]
			return TRUE
		if("pay_nearby")
			return wallet_pay_nearby(user, params)
		if("request_payment")
			return wallet_request_payment(user, params)
		if("pay_request_answer")
			message = econ_answer_pay_request(user, wallet_account(user), params["id"], params["answer"], econ_payer_name(computer?.GetID(), wallet_account(user)))[2]
			return TRUE
		if("personal_cancel")
			message = econ_cancel_personal_order(user, wallet_account(user), params["id"])[2]
			return TRUE
		if("auction_bid")
			return wallet_auction_bid(user, params)
		if("auction_cancel", "auction_buyout")
			var/uid = params["uid"]
			if(istext(uid))
				uid = text2num(uid)
			if(action == "auction_cancel")
				message = SSmarket.cancel_crew_lot(wallet_account(user), uid, user)[2]
			else
				message = SSmarket.buyout_crew_lot(wallet_account(user), uid, user)[2]
			return TRUE
		if("md_withdraw", "md_deposit")
			return metadollar_act(user, action, params)
	var/list/contract_result = econ_contract_act(user, action, params, wallet_account(user))
	if(contract_result)
		message = contract_result[2]
		return TRUE
	return FALSE

/datum/computer_file/program/wallet/proc/wallet_payment(mob/living/user, action, list/params)
	var/datum/bank_account/account = wallet_account(user)
	if(!account)
		message = "Нет банковского счёта."
		return TRUE
	var/amount = params["amount"]
	if(istext(amount))
		amount = text2num(amount)
	if(!isnum(amount) || !(amount >= 1))
		message = "Неверная сумма."
		return TRUE
	var/target_text = params["target"]
	if(isnum(target_text))
		target_text = "[target_text]"
	if(!istext(target_text))
		message = "Укажите получателя."
		return TRUE
	target_text = trim(copytext_char(target_text, 1, MAX_NAME_LEN + 1))
	var/datum/bank_account/target = SSeconomy.find_account(text2num(target_text)) || SSeconomy.find_account_by_name(target_text)
	if(!target)
		var/list/namesakes = SSeconomy.find_accounts_by_name(target_text)
		message = length(namesakes) > 1 ? "На имя \"[target_text]\" несколько счетов - укажите номер." : "Счёт \"[target_text]\" не найден."
		return TRUE
	var/error
	if(action == "tip")
		error = SSeconomy.send_tip(account, target, amount, user)
	else
		error = SSeconomy.send_transfer(account, target, amount, user, params["memo"])
	if(error)
		message = error
		return TRUE
	message = "[action == "tip" ? "Чаевые" : "Перевод"] [round(amount)] кр. → [target.account_holder] (№[target.account_id])."
	return TRUE

/// Люди в ECON_NEARBY_PAY_RANGE клетках, которых видит сам user, с ID-картой на личном счёте: REF человека -> карта. Мёртвых и почти прозрачных не видно.
/datum/computer_file/program/wallet/proc/nearby_payees(mob/living/user)
	. = list()
	if(!get_turf(user))
		return
	for(var/mob/living/carbon/human/person in view(ECON_NEARBY_PAY_RANGE, user))
		if(person == user || person.stat == DEAD || person.alpha < ECON_NEARBY_MIN_ALPHA)
			continue
		var/obj/item/card/id/card = person.get_idcard(FALSE)
		if(card && SSeconomy.is_personal_account(card.registered_account))
			.[REF(person)] = card

/// Кому рядом можно заплатить: имя и должность - как на ID-карте, а не как на самом деле; requestable - у него можно попросить оплату (не SSD).
/datum/computer_file/program/wallet/proc/wallet_nearby_data(mob/living/user)
	. = list()
	var/list/payees = nearby_payees(user)
	for(var/ref in payees)
		var/obj/item/card/id/card = payees[ref]
		var/mob/living/person = locate(ref)
		. += list(list("ref" = ref, "name" = card.registered_name || "без имени", "job" = card.assignment, "requestable" = !!GET_CLIENT(person)))

/// Оплата человеку рядом по его ID-карте, без номера счёта: обычный перевод, обе стороны видят друг друга по именам с карт, номера счетов не раскрываются.
/datum/computer_file/program/wallet/proc/wallet_pay_nearby(mob/living/user, list/params)
	var/datum/bank_account/account = wallet_account(user)
	if(!account)
		message = "Нет банковского счёта."
		return TRUE
	var/amount = params["amount"]
	if(istext(amount))
		amount = text2num(amount)
	if(!isnum(amount) || !(amount >= 1))
		message = "Неверная сумма."
		return TRUE
	var/list/payees = nearby_payees(user)
	var/obj/item/card/id/card = istext(params["ref"]) ? payees[params["ref"]] : null
	if(!card)
		message = "Этого человека уже нет рядом, или на нём нет ID-карты со счётом."
		return TRUE
	var/payee_name = card.registered_name || "без имени"
	var/error = SSeconomy.send_transfer(account, card.registered_account, amount, user, params["memo"], econ_payer_name(computer?.GetID(), account), payee_name)
	message = error || "Оплачено [round(amount)] кр. → [payee_name]."
	return TRUE

/// Запрос оплаты у человека рядом: тот же список, что для оплаты, без SSD.
/datum/computer_file/program/wallet/proc/wallet_request_payment(mob/living/user, list/params)
	var/datum/bank_account/account = wallet_account(user)
	if(!account)
		message = "Нет банковского счёта."
		return TRUE
	var/list/payees = nearby_payees(user)
	var/ref = params["ref"]
	var/obj/item/card/id/card = istext(ref) ? payees[ref] : null
	var/mob/living/person = card ? locate(ref) : null
	if(!card || !GET_CLIENT(person))
		message = "Этого человека уже нет рядом, или на нём нет ID-карты со счётом."
		return TRUE
	message = econ_request_payment(user, account, econ_payer_name(computer?.GetID(), account), card.registered_account, card.registered_name || "без имени", params["amount"], params["reason"])[2]
	return TRUE

/datum/computer_file/program/wallet/proc/wallet_lottery(mob/living/user, count)
	if(!SSeconomy.lottery)
		message = "Лотерея сейчас не проводится."
		return TRUE
	if(istext(count))
		count = text2num(count)
	var/error = SSeconomy.lottery.buy(wallet_account(user), count, user)
	message = error || "Куплено билетов: [round(count)]."
	return TRUE

/// Ставка на аукционе с кошелька: тот же счёт, что у окна.
/datum/computer_file/program/wallet/proc/wallet_auction_bid(mob/living/user, list/params)
	var/amount = params["amount"]
	if(istext(amount))
		amount = text2num(amount)
	var/uid = params["uid"]
	if(istext(uid))
		uid = text2num(uid)
	var/datum/auction_lot/lot = SSmarket.find_auction_lot(uid)
	var/error = isnum(uid) ? SSmarket.place_auction_bid(wallet_account(user), amount, user, uid, !!params["outbid"]) : "Этот лот уже не продаётся."
	message = error || "Ставка [lot.bid] кр. на \"[lot.name]\" принята: деньги заморожены до конца торгов, перебьют - вернутся."
	return TRUE

/// Метадоллары: постоянный счёт игрока, с кредитами станции не связан.
/datum/computer_file/program/wallet/proc/metadollar_act(mob/living/user, action, list/params)
	var/client/user_client = user.client
	if(!user_client?.ckey)
		message = "Нет связи с вашим счётом метадолларов."
		return TRUE
	switch(action)
		if("md_withdraw")
			var/amount = params["amount"]
			if(istext(amount))
				amount = text2num(amount)
			if(!isnum(amount) || !(amount >= 1))
				message = "Неверная сумма."
				return TRUE
			amount = round(amount)
			var/balance = SSmetadollars.get_metadollars(user_client.ckey)
			if(balance < amount)
				message = "Недостаточно метадолларов: на счёте [balance] M$."
				return TRUE
			SSmetadollars.metadollar_adjust(-amount, user_client.ckey, user_client.key)
			var/obj/item/stack/metadollar/notes = new(user.drop_location(), amount)
			user.put_in_hands(notes)
			log_admin("METADOLLAR: [user.real_name] ([user_client.ckey]) withdrew [amount] M$ via PDA. Balance: [SSmetadollars.get_metadollars(user_client.ckey)] M$.")
			message = "Снято [amount] M$."
			return TRUE
		if("md_deposit")
			var/obj/item/stack/metadollar/notes = user.get_active_held_item()
			if(!istype(notes))
				message = "Возьмите стопку метадолларов в активную руку."
				return TRUE
			var/amount = notes.amount
			if(amount <= 0)
				message = "В стопке нет метадолларов."
				return TRUE
			SSmetadollars.metadollar_adjust(amount, user_client.ckey, user_client.key)
			log_admin("METADOLLAR: [user.real_name] ([user_client.ckey]) deposited [amount] M$ via PDA. Balance: [SSmetadollars.get_metadollars(user_client.ckey)] M$.")
			qdel(notes)
			message = "Зачислено [amount] M$."
			return TRUE
