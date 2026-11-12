GLOBAL_VAR_INIT(market_offer_uid, 0)

/// Спецзаказ партнёра: товар, количество, цена единицы с множителем и срок.
/datum/market_offer
	var/uid
	var/partner_id
	var/wanted_type
	var/wanted_name
	/// Подходят и подтипы wanted_type; без этого - только сам тип (у стопок - их merge_type)
	var/wanted_subtypes = FALSE
	/// Реагент, которого в каждой единице должно быть не меньше wanted_volume
	var/wanted_reagent
	var/wanted_volume = 0
	var/quantity
	var/delivered = 0
	var/multiplier
	var/unit_price
	/// До взятия - когда спецзаказ снимут, после - срок выполнения
	var/deadline = 0
	var/accepted = FALSE
	/// Выплачено по базовой цене за принятые штуки
	var/paid = 0
	/// Премия сверх базы за принятые штуки: снабжение получает её при выполнении
	var/premium_due = 0
	var/margin_paid = 0

/datum/market_offer/New(partner_id, wanted_type, wanted_name, quantity, multiplier, unit_price, wanted_reagent, wanted_volume, wanted_subtypes = FALSE)
	uid = ++GLOB.market_offer_uid
	src.partner_id = partner_id
	src.wanted_type = wanted_type
	src.wanted_name = wanted_name
	src.quantity = quantity
	src.multiplier = multiplier
	src.unit_price = unit_price
	src.wanted_reagent = wanted_reagent
	src.wanted_volume = wanted_volume || 0
	src.wanted_subtypes = wanted_subtypes
	deadline = world.time + SSmarket.offer_minutes * MARKET_OFFER_UNTAKEN_LIFETIME MINUTES

/datum/market_offer/Destroy()
	var/datum/trade_partner/partner = get_partner()
	partner?.offers -= src
	return ..()

/datum/market_offer/proc/get_partner()
	return SSmarket.get_partner(partner_id)

/datum/market_offer/proc/partner_name()
	var/datum/trade_partner/partner = get_partner()
	return partner?.name

/datum/market_offer/proc/unit_reward()
	return round(unit_price * multiplier)

/datum/market_offer/proc/open()
	var/datum/trade_partner/partner = get_partner()
	return !QDELETED(src) && partner?.unlocked && world.time <= deadline && (accepted || !partner.embargoed())

/// Спецзаказ контрабандного партнёра принимает только отгрузка с допуском контрабанды.
/datum/market_offer/proc/contraband()
	var/datum/trade_partner/partner = get_partner()
	return partner?.contraband

/// Строка о спецзаказе в сообщение ЦК об отгрузке; о спецзаказе контрабандного партнёра её видит только взломанная консоль снабжения.
/datum/market_offer/proc/add_note(datum/export_report/report, text)
	if(!report)
		return
	if(contraband())
		report.contraband_notes += text
	else
		report.offer_notes += text

/datum/market_offer/proc/accept(mob/user)
	if(accepted || !open())
		return FALSE
	accepted = TRUE
	deadline = world.time + SSmarket.offer_deadline_minutes MINUTES
	log_econ("[user ? key_name(user) : "Снабжение"] взял спецзаказ #[uid] партнёра [partner_name()]: [quantity] x [wanted_name] по [unit_reward()] кр.")
	return TRUE

/// Предмет подходит: нужного типа, не куплен через снабжение, с нужным реагентом не из лейта.
/datum/market_offer/proc/matches(atom/movable/thing)
	if(thing.econ_imported || !istype(thing, wanted_type))
		return FALSE
	if(!wanted_subtypes)
		var/obj/item/stack/stack = thing
		if((istype(stack) ? stack.merge_type : thing.type) != wanted_type)
			return FALSE
	if(!wanted_reagent)
		return TRUE
	var/list/printed = thing.econ_print_reagents
	var/volume = thing.reagents?.get_reagent_amount(wanted_reagent) - (printed ? printed[wanted_reagent] : 0)
	return volume >= wanted_volume

/// Полная выплата за штуку; собранное на станции - не дороже своих материалов, как при обычной продаже.
/datum/market_offer/proc/unit_payout(atom/movable/thing)
	. = unit_reward()
	if(!wanted_reagent && !isstack(thing) && islist(thing.econ_print_cap))
		. = min(., econ_cap_value(thing.econ_print_cap))

/// Забирает из отгрузки подходящее до нужного количества и возвращает базовую выплату; премия копится до выполнения, остальное в ящике продаётся обычным порядком.
/datum/market_offer/proc/deliver(atom/movable/shipment, datum/export_report/report, allowed_categories = EXPORT_CARGO)
	. = 0
	if(!accepted || !open() || delivered >= quantity)
		add_note(report, "Спецзаказ \"[wanted_name]\" уже не принимает груз, ящик продан обычным порядком.")
		return
	if(contraband() && !(allowed_categories & EXPORT_CONTRABAND))
		add_note(report, "Спецзаказ \"[wanted_name]\" принимает только отгрузка с допуском контрабанды, ящик продан обычным порядком.")
		return
	var/units_before = delivered
	var/premium = 0
	for(var/atom/movable/thing as anything in shipment.GetAllContents())
		if(delivered >= quantity)
			break
		if(thing == shipment || QDELETED(thing) || !matches(thing))
			continue
		var/units = 1
		if(isstack(thing))
			var/obj/item/stack/stack = thing
			units = min(stack.amount, quantity - delivered)
		var/full = unit_payout(thing)
		var/base = min(unit_price, full)
		. += units * base
		premium += units * (full - base)
		delivered += units
		take(thing, units, shipment)
	var/units = delivered - units_before
	if(!units)
		return
	paid += .
	premium_due += premium
	var/datum/trade_partner/partner = get_partner()
	partner.note_sale(.)
	log_econ("Спецзаказ #[uid] партнёра [partner.name]: принято [units] x [wanted_name] ([delivered]/[quantity]), выплата [.] кр., премия к выполнению [premium] кр.")
	add_note(report, "Спецзаказ [partner.name]: принято [units] шт. \"[wanted_name]\" ([delivered] из [quantity]), [.] кр.")
	if(delivered >= quantity)
		complete(report)

/datum/market_offer/proc/take(atom/movable/thing, units, atom/movable/shipment)
	if(isstack(thing))
		var/obj/item/stack/stack = thing
		if(units < stack.amount)
			stack.use(units)
			return
	for(var/atom/movable/inner as anything in thing.contents)
		inner.forceMove(shipment)
	qdel(thing)

/// Выполнен: премия - маржа отделу, закрывшему спецзаказ (отгрузкой шаттла - снабжению), репутация партнёру.
/datum/market_offer/proc/complete(datum/export_report/report, datum/economy_department/closer)
	var/datum/trade_partner/partner = get_partner()
	var/premium = round(premium_due)
	if(!closer)
		closer = SSeconomy.get_department(ACCOUNT_CAR)
	var/closer_name = closer.id == ACCOUNT_CAR ? "снабжению" : "отделу [closer.name]"
	if(premium > 0)
		if(closer.id == ACCOUNT_CAR)
			margin_paid = premium
		closer.account.credit(premium, ECON_EXPORT, memo = "Маржа спецзаказа: [partner?.name]")
		partner?.note_sale(premium)
	partner?.add_reputation(MARKET_OFFER_REPUTATION_SUCCESS)
	add_note(report, "Спецзаказ выполнен: маржа [closer_name] [premium] кр., репутация у партнёра +[MARKET_OFFER_REPUTATION_SUCCESS].")
	log_econ("Спецзаказ #[uid] партнёра [partner?.name] выполнен: выплачено [paid] кр., маржа [closer_name] [premium] кр.")
	SEND_SIGNAL(SSmarket, COMSIG_MARKET_OFFER_RESOLVED, src, TRUE)
	qdel(src)

/// Провал: без премии и с потерей репутации.
/datum/market_offer/proc/fail()
	var/datum/trade_partner/partner = get_partner()
	partner?.add_reputation(-MARKET_OFFER_REPUTATION_FAIL)
	var/notice = "Спецзаказ [partner?.name] \"[wanted_name]\" провален: срок вышел, принято [delivered] из [quantity], маржи не будет. Репутация у партнёра -[MARKET_OFFER_REPUTATION_FAIL][partner?.company ? ", оценка акций [partner.company] -[MARKET_OFFER_FAIL_STOCK_SHOCK * 100]%" : ""]."
	if(contraband())
		SSmarket.contraband_message = SSmarket.contraband_message ? "[SSmarket.contraband_message] [notice]" : notice
	else
		SSshuttle.centcom_message = SSshuttle.centcom_message ? "[SSshuttle.centcom_message] [notice]" : notice
	log_econ("Спецзаказ #[uid] партнёра [partner?.name] провален: принято [delivered] из [quantity].")
	SEND_SIGNAL(SSmarket, COMSIG_MARKET_OFFER_RESOLVED, src, FALSE)
	qdel(src)

/// Спецзаказ можно сдать на паде подработки: открыт, не контрабандный и ещё не набран.
/datum/market_offer/proc/pad_open()
	return open() && !contraband() && delivered < quantity

/// Сдача с пада подработки: первая сдача сама берёт спецзаказ. База за штуки - отделу сдавшего за вычетом сбора снабжения, ему лично доля участника контракта; маржа при выполнении - тому же отделу. Возвращает принятые штуки.
/datum/market_offer/proc/ship_from_pad(atom/movable/thing, mob/shipper)
	if(!pad_open() || !matches(thing))
		return 0
	if(!accepted && !accept(shipper))
		return 0
	var/units = 1
	if(isstack(thing))
		var/obj/item/stack/stack = thing
		units = min(stack.amount, quantity - delivered)
	var/full = unit_payout(thing)
	var/base = min(unit_price, full)
	var/revenue = units * base
	premium_due += units * (full - base)
	delivered += units
	paid += revenue
	take(thing, units, thing.drop_location())
	var/datum/trade_partner/partner = get_partner()
	partner.note_sale(revenue)
	var/datum/economy_department/department = econ_pad_offer_payee(shipper)
	var/memo = "Спецзаказ: [partner.name]"
	var/datum/bank_account/account = econ_account_of(shipper)
	var/share = account ? round(revenue * SSeconomy.settings.contract_team_share / 100) : 0
	if(share > 0)
		var/net = SSeconomy.pay_personal(null, account, share, ECON_CONTRACT, shipper, memo)
		account.bank_card_talk("Спецзаказ [partner.name]: [share] кр. до налога, на руки [net] кр.", balloon = net ? "спецзаказ +[net] кр" : null)
	econ_pay_crate(revenue - share, department, memo)
	log_econ("Спецзаказ #[uid] партнёра [partner.name]: с пада подработки принято [units] x [wanted_name] ([delivered]/[quantity]) от [key_name(shipper)], выплата [revenue] кр. ([department.name], лично [share])")
	if(delivered >= quantity)
		complete(closer = department)
	return units

/// Отдел, которому платит сдача спецзаказа с пада: отдел счёта сдавшего, без него - снабжение.
/proc/econ_pad_offer_payee(mob/shipper)
	var/datum/bank_account/account = econ_account_of(shipper)
	var/datum/economy_department/department = account ? SSeconomy.get_department(account.department_id) : null
	if(!department || department.id == ACCOUNT_CMD)
		department = SSeconomy.get_department(ACCOUNT_CAR)
	return department

/// Засчитывает предмет и его содержимое по спецзаказам партнёров с пада подработки. Возвращает принятые штуки.
/proc/econ_offers_ship(atom/movable/thing, mob/shipper)
	. = 0
	var/list/offers = list()
	for(var/datum/market_offer/offer as anything in SSmarket.all_offers())
		if(offer.pad_open())
			offers += offer
	if(!length(offers))
		return
	for(var/atom/movable/item as anything in econ_contract_candidates(thing))
		for(var/datum/market_offer/offer as anything in offers)
			if(QDELETED(item))
				break
			if(QDELETED(offer))
				continue
			. += offer.ship_from_pad(item, shipper)

/// Спецзаказы, которые можно сдать на паде, для доски контрактов.
/proc/econ_pad_offers_ui()
	. = list()
	for(var/datum/market_offer/offer as anything in SSmarket.all_offers())
		if(offer.pad_open())
			. += list(offer.ui_entry())

/datum/market_offer/proc/requirement_text()
	if(!wanted_reagent)
		return "\"[wanted_name]\""
	var/datum/reagent/reagent_type = wanted_reagent
	return "\"[wanted_name]\", в каждой не меньше [wanted_volume] ед. [initial(reagent_type.name)]"

/datum/market_offer/proc/ui_entry()
	var/datum/trade_partner/partner = get_partner()
	return list(
		"uid" = uid,
		"partner" = partner_name(),
		"partner_id" = partner_id,
		"item" = wanted_name,
		"requirement" = requirement_text(),
		"quantity" = quantity,
		"delivered" = delivered,
		"unit_price" = unit_price,
		"unit_reward" = unit_reward(),
		"premium" = (unit_reward() - unit_price) * quantity,
		"reward" = unit_reward() * quantity,
		"paid" = paid,
		"accepted" = accepted,
		"contraband" = !!contraband(),
		"embargoed" = !!partner?.embargoed(),
		"time_left" = max(round((deadline - world.time) / (1 SECONDS)), 0),
	)

/// Описание для осмотра накладной спецзаказа.
/datum/market_offer/proc/manifest_text()
	return "Спецзаказ партнёра [partner_name()]: [requirement_text()], принято [delivered] из [quantity], [unit_price] кр. за штуку при отгрузке и [unit_reward() - unit_price] кр. за штуку маржи снабжению при выполнении, осталось [DisplayTimeText(max(deadline - world.time, 0))]. Купленное через снабжение не засчитывается, собранное на станции оплачивается не дороже его материалов. Накладная отдела в том же ящике делит оплату за штуки, как выручку ящика. Спецзаказ не контрабандного партнёра можно сдать и на паде подработки."

/// Накладная спецзаказа: печатает консоль снабжения для взятого спецзаказа.
/proc/print_offer_manifest(datum/market_offer/offer, atom/where)
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/obj/item/export_manifest/manifest = cargo.print_manifest(where)
	manifest.special_offer_id = offer.uid
	manifest.name = "special order manifest ([offer.wanted_name])"
	manifest.update_appearance()
	return manifest
