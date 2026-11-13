/// Разделы личного каталога: питомцы, одежда и украшения, праздник, музыка и творчество, уют. Без оружия и снаряжения, дающего преимущество в бою или работе.
/proc/econ_personal_catalog_sections()
	var/static/list/sections
	if(!sections)
		sections = list(
			"Питомцы" = list(
				/datum/supply_pack/critter/cat,
				/datum/supply_pack/critter/chick,
				/datum/supply_pack/critter/corgi,
				/datum/supply_pack/critter/corgis/exotic,
				/datum/supply_pack/critter/fox,
				/datum/supply_pack/critter/kiwi,
				/datum/supply_pack/critter/mouse,
				/datum/supply_pack/critter/parrot,
				/datum/supply_pack/critter/pug,
			),
			"Одежда и украшения" = list(
				/datum/supply_pack/goody/dyespray,
				/datum/supply_pack/goody/cloak,
				/datum/supply_pack/costumes_toys/formalwear,
				/datum/supply_pack/costumes_toys/costume_original,
				/datum/supply_pack/costumes_toys/wizard,
				/datum/supply_pack/costumes_toys/randomised,
				/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_vr,
				/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_b_vr,
				/datum/supply_pack/costumes_toys/randomised/tesh_beltcloaks_vr,
				/datum/supply_pack/costumes_toys/randomised/tesh_beltcloaks_b_vr,
				/datum/supply_pack/costumes_toys/randomised/tesh_hoodcloaks_vr,
				/datum/supply_pack/costumes_toys/randomised/tesh_hoodcloaks_b_vr,
				/datum/supply_pack/misc/exoticfootwear,
				/datum/supply_pack/misc/jewelry,
				/datum/supply_pack/misc/diamondring,
				/datum/supply_pack/misc/wedding,
				/datum/supply_pack/costumes_toys/wedding,
			),
			"Праздник и угощение" = list(
				/datum/supply_pack/organic/party,
				/datum/supply_pack/organic/pizza,
				/datum/supply_pack/organic/combomeal2,
				/datum/supply_pack/organic/fiestatortilla,
				/datum/supply_pack/organic/randomized/candy,
				/datum/supply_pack/organic/shrimp,
				/datum/supply_pack/organic/kvass_bottles,
				/datum/supply_pack/organic/kvass_barrel,
				/datum/supply_pack/goody/valentine,
			),
			"Музыка, игры и творчество" = list(
				/datum/supply_pack/misc/bigband,
				/datum/supply_pack/goody/guitarbag,
				/datum/supply_pack/misc/jukebox,
				/datum/supply_pack/misc/artsupply,
				/datum/supply_pack/misc/book_crate,
				/datum/supply_pack/misc/fountainpens,
				/datum/supply_pack/misc/microbricks,
				/datum/supply_pack/costumes_toys/randomised/plush,
				/datum/supply_pack/costumes_toys/randomised/tcg,
				/datum/supply_pack/goody/beeplush,
				/datum/supply_pack/goody/beach_ball,
			),
			"Уют" = list(
				/datum/supply_pack/misc/candles,
				/datum/supply_pack/misc/potted_plants,
				/datum/supply_pack/misc/coloredsheets,
				/datum/supply_pack/misc/carpet_exotic,
				/datum/supply_pack/misc/shower,
				/datum/supply_pack/misc/funeral,
			),
		)
	return sections

GLOBAL_LIST_INIT(econ_personal_catalog, econ_personal_catalog_typecache())

/proc/econ_personal_catalog_typecache()
	var/list/types = list()
	var/list/sections = econ_personal_catalog_sections()
	for(var/section in sections)
		types += sections[section]
	return typecacheof(types, only_root_path = TRUE)

/proc/econ_personal_catalog_pack(datum/supply_pack/pack)
	return !!GLOB.econ_personal_catalog[pack?.type]

/// Пак личного каталога, если его сейчас можно купить лично; иначе null.
/proc/econ_personal_catalog_orderable(pack_type)
	if(!GLOB.econ_personal_catalog[pack_type])
		return null
	var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
	if(!pack || pack.hidden || pack.contraband || pack.DropPodOnly || !pack.can_private_buy || (pack.special && !pack.special_enabled))
		return null
	return pack

/// Группа "Личный каталог" окна снабжения: те же паки, что в своих группах, с пометкой.
/proc/econ_personal_catalog_group(show_contraband_partners)
	var/list/packs = list()
	for(var/pack_type in GLOB.econ_personal_catalog)
		var/datum/supply_pack/pack = econ_personal_catalog_orderable(pack_type)
		if(!pack)
			continue
		var/list/entry = econ_cargo_static_entry(pack)
		entry["name"] = pack.name
		entry["id"] = pack_type
		entry["goody"] = pack.goody
		entry["access"] = pack.access
		entry["private_goody"] = pack.goody == PACK_GOODY_PRIVATE
		entry["can_private_buy"] = TRUE
		entry["personal"] = TRUE
		packs += list(entry)
	return list("name" = ECON_PERSONAL_CATALOG_GROUP, "packs" = packs)

/// Каталог для кошелька КПК по разделам: имя, описание и опись пака; цены - в econ_personal_catalog_prices().
/proc/econ_personal_catalog_ui()
	. = list()
	var/list/sections = econ_personal_catalog_sections()
	for(var/section in sections)
		var/list/packs = list()
		for(var/pack_type in sections[section])
			var/datum/supply_pack/pack = econ_personal_catalog_orderable(pack_type)
			if(!pack)
				continue
			packs += list(list(
				"id" = "[pack_type]",
				"name" = pack.name,
				"desc" = pack.desc,
				"contents" = econ_pack_contents(pack),
				"random" = econ_pack_random_count(pack),
			))
		if(length(packs))
			. += list(list("name" = section, "packs" = packs))

/// Сколько случайных предметов из описи кладёт пак; 0 - кладёт всё.
/proc/econ_pack_random_count(datum/supply_pack/pack)
	if(istype(pack, /datum/supply_pack/costumes_toys/randomised))
		var/datum/supply_pack/costumes_toys/randomised/random_pack = pack
		return random_pack.num_contained
	if(istype(pack, /datum/supply_pack/organic/randomized))
		var/datum/supply_pack/organic/randomized/random_pack = pack
		return random_pack.num_contained
	return 0

/// Цена для account и наличие паков личного каталога: "тип" -> list(цена, есть ли у партнёров).
/proc/econ_personal_catalog_prices(datum/bank_account/account)
	var/list/packs = list()
	for(var/pack_type in GLOB.econ_personal_catalog)
		var/datum/supply_pack/pack = econ_personal_catalog_orderable(pack_type)
		if(pack)
			packs += pack
	var/list/offers = SSmarket.best_offers(packs, account)
	. = list()
	for(var/datum/supply_pack/pack as anything in packs)
		var/list/offer = offers[pack]
		.["[pack.type]"] = list(offer ? round(offer[2]) : round(pack.market_cost(account)), !econ_pack_traded(pack) || !!offer)

/// Заказ оплачен с КПК: деньги уже списаны с личного счёта покупателя.
/datum/supply_order/proc/personal_prepaid()
	return prepaid && !department_id && paying_account

/// Оплаченные с КПК личные заказы счёта, которые ещё ждут шаттла.
/proc/econ_personal_orders_of(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		if(order.paying_account == account && order.personal_prepaid())
			. += order

/// Личный заказ с КПК: цена партнёра без наценки списывается сразу, заказ встаёт в очередь шаттла снабжения личным. Возвращает list(принят ли, ответ игроку).
/proc/econ_personal_order(mob/living/user, datum/bank_account/account, pack_type)
	if(istext(pack_type))
		pack_type = text2path(pack_type)
	var/datum/supply_pack/pack = ispath(pack_type, /datum/supply_pack) ? econ_personal_catalog_orderable(pack_type) : null
	if(!pack)
		return list(FALSE, "Этого нет в личном каталоге.")
	var/problem = SSeconomy.personal_account_problem(account, TRUE)
	if(problem)
		return list(FALSE, problem)
	if(account.offstation)
		return list(FALSE, "Шаттл снабжения возит заказы только экипажу станции.")
	var/limit = SSeconomy.settings.personal_order_limit
	if(length(econ_personal_orders_of(account)) >= limit)
		return list(FALSE, "Больше заказов сразу не принять, шаттла ждут уже [limit]: дождитесь отгрузки или отмените один.")
	if(econ_pack_unavailable(pack))
		return list(FALSE, "[pack.name] сейчас нет у партнёров, загляните позже.")
	var/price = round(econ_pack_price(pack, account))
	if(!account.debit(price, ECON_PERSONAL_CATALOG, user, "Личный заказ: [pack.name]"))
		return list(FALSE, "На счёте не хватает денег: [pack.name] стоит [price] кр.")
	var/datum/supply_order/order = econ_cargo_new_order(user, pack, "Личный заказ с КПК", account, FALSE)
	order.prepaid = price
	log_econ("[key_name(user)] заказал с КПК [pack.name] за [price] кр. со счёта [account.account_holder] ([account.account_id]), заказ #[order.id]")
	account.bank_card_talk("Заказ №[order.id] оплачен: [pack.name] за [price] кр. Его привезёт ближайший шаттл снабжения - запертой посылкой на ваше имя. Пока шаттл не вылетел, заказ можно отменить в Кошельке.")
	econ_personal_order_notice(pack)
	return list(TRUE, "Заказ №[order.id] оплачен: [pack.name] за [price] кр.")

/// Канал снабжения слышит об оплаченном с КПК заказе, не чаще ECON_CARGO_REQUEST_RADIO_COOLDOWN.
/proc/econ_personal_order_notice(datum/supply_pack/pack)
	var/static/next_notice = 0
	if(world.time < next_notice)
		return
	next_notice = world.time + ECON_CARGO_REQUEST_RADIO_COOLDOWN
	paperwork_radio("Оплачен личный заказ с КПК: [pack.name]. Он в корзине и полетит ближайшим шаттлом.", RADIO_CHANNEL_SUPPLY)

/// Покупатель отменяет свой оплаченный заказ до отлёта шаттла. Возвращает list(отменён ли, ответ игроку).
/proc/econ_cancel_personal_order(mob/living/user, datum/bank_account/account, order_id)
	if(istext(order_id))
		order_id = text2num(order_id)
	for(var/datum/supply_order/order as anything in econ_personal_orders_of(account))
		if(order.id != order_id)
			continue
		var/refund = order.prepaid
		var/pack_name = order.pack.name
		SSshuttle.shoppinglist -= order
		econ_refund_personal_order(order, user, quiet = TRUE)
		qdel(order)
		return list(TRUE, "Заказ №[order_id] ([pack_name]) отменён, [refund] кр. вернулись на счёт.")
	return list(FALSE, "Этого заказа уже нет в корзине: шаттл улетел с ним, или его отменили.")

/// Возврат покупателю за снятый с корзины оплаченный с КПК заказ; quiet - без сообщения карте.
/proc/econ_refund_personal_order(datum/supply_order/order, mob/user, quiet = FALSE)
	var/datum/bank_account/buyer = order.paying_account
	var/refund = order.prepaid
	order.prepaid = 0
	if(QDELETED(buyer) || !buyer.credit(refund, ECON_REFUND, user, "Отмена заказа: [order.pack.name]"))
		log_econ("Личный заказ #[order.id] [order.pack.name] снят [key_name(user)], но [refund] кр. вернуть некуда")
		return FALSE
	log_econ("[key_name(user)] снял личный заказ #[order.id] [order.pack.name] счёта [buyer.account_holder] ([buyer.account_id]), возвращено [refund] кр.")
	if(!quiet)
		buyer.bank_card_talk("Снабжение сняло ваш заказ №[order.id] ([order.pack.name]) с корзины: [refund] кр. вернулись на счёт.")
	return TRUE

/obj/docking_port/mobile/supply
	/// Личные заказы последней отгрузки: weakref счёта покупателя -> list("№id пак"); карта узнает о них, когда шаттл сядет на станции
	var/list/personal_arrivals = list()

/// Отгрузка личного заказа: покупатель узнает о нём по прибытии шаттла на станцию.
/obj/docking_port/mobile/supply/proc/note_personal_shipment(datum/supply_order/order)
	var/datum/weakref/buyer_ref = WEAKREF(order.paying_account)
	if(!buyer_ref)
		return
	if(!personal_arrivals[buyer_ref])
		personal_arrivals[buyer_ref] = list()
	personal_arrivals[buyer_ref] += "№[order.id] [order.pack.name]"

/obj/docking_port/mobile/supply/proc/notify_personal_arrivals()
	for(var/datum/weakref/buyer_ref as anything in personal_arrivals)
		var/datum/bank_account/buyer = buyer_ref.resolve()
		var/list/orders = personal_arrivals[buyer_ref]
		buyer?.bank_card_talk("Шаттл снабжения привёз на станцию [length(orders) > 1 ? "ваши заказы" : "ваш заказ"] [jointext(orders, ", ")]: запертая посылка на ваше имя ждёт в отделе снабжения, откроет её ваша ID-карта.")
	personal_arrivals.Cut()

/// Личные заказы account, которые шаттл уже везёт на станцию.
/obj/docking_port/mobile/supply/proc/personal_in_transit(datum/bank_account/account)
	if(!account?.weak_reference)
		return list()
	return personal_arrivals[account.weak_reference] || list()
