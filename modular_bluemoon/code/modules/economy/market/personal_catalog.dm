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
				"contents" = econ_pack_catalog_contents(pack),
				"random" = econ_pack_random_count(pack),
			))
		if(length(packs))
			. += list(list("name" = section, "packs" = packs))

/// Опись пака для каталога: бустеры NT TCG собираются при отгрузке, их опись - числом.
/proc/econ_pack_catalog_contents(datum/supply_pack/pack)
	var/datum/supply_pack/costumes_toys/randomised/tcg/boosters = pack
	if(istype(boosters))
		return list("бустер NT TCG случайной серии ×[boosters.booster_count]")
	return econ_pack_contents(pack)

/// Сколько случайных предметов из описи кладёт пак; 0 - кладёт всё.
/proc/econ_pack_random_count(datum/supply_pack/pack)
	if(istype(pack, /datum/supply_pack/costumes_toys/randomised))
		var/datum/supply_pack/costumes_toys/randomised/random_pack = pack
		return random_pack.num_contained < length(pack.contains) ? random_pack.num_contained : 0
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

/datum/supply_order
	/// Подарок с КПК: посылка заперта на этот счёт, платит paying_account
	var/datum/bank_account/gift_to
	/// Даритель скрыл своё имя от получателя
	var/gift_hide_name = FALSE

/// Заказ оплачен с КПК: деньги уже списаны с личного счёта покупателя.
/datum/supply_order/proc/personal_prepaid()
	return prepaid && !department_id && paying_account

/// Чья ID-карта откроет посылку: получателя подарка или плательщика.
/datum/supply_order/proc/delivery_account()
	return gift_to || paying_account

/datum/bank_account
	COOLDOWN_DECLARE(personal_gift_cooldown)

/// Оплаченные с КПК личные заказы и подарки счёта, которые ещё ждут шаттла.
/proc/econ_personal_orders_of(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		if(order.paying_account == account && order.personal_prepaid())
			. += order

/// Получатель подарка по имени или номеру счёта: list(счёт) или list(null, отказ игроку). shop - подарок из магазина: его забирает сам получатель, поэтому где он и жив ли, до оплаты не проверяется и не раскрывается.
/proc/econ_personal_gift_recipient(datum/bank_account/buyer, target_text, shop = FALSE)
	if(isnum(target_text))
		target_text = "[target_text]"
	target_text = trim(copytext_char(target_text, 1, MAX_NAME_LEN + 1))
	var/datum/bank_account/target = SSeconomy.find_account(text2num(target_text))
	if(!target)
		var/list/namesakes = SSeconomy.find_accounts_by_name(target_text)
		if(length(namesakes) > 1)
			return list(null, "На имя \"[target_text]\" несколько счетов - укажите номер.")
		target = length(namesakes) ? namesakes[1] : null
	if(!target)
		for(var/datum/bank_account/sleeper as anything in SSeconomy.bank_accounts)
			if(sleeper.state == ACCOUNT_DORMANT && SSeconomy.is_personal_account(sleeper) && lowertext(sleeper.account_holder) == lowertext(target_text))
				target = sleeper
				break
	if(!SSeconomy.is_personal_account(target))
		return list(null, "Личный счёт \"[target_text]\" не найден.")
	if(target == buyer)
		return list(null, "Себе подарок не оформить: выберите получателем «Себе».")
	if(shop)
		return list(target)
	if(target.offstation)
		return list(null, "Шаттл снабжения возит посылки только экипажу станции.")
	if(target.state == ACCOUNT_DORMANT)
		return list(null, "[target.account_holder] сейчас не на смене: посылку некому будет забрать.")
	if(target.state == ACCOUNT_FROZEN)
		return list(null, "Подарок на этот счёт сейчас не оформить.")
	return list(target)

/// Личный заказ с КПК: цена партнёра без наценки списывается сразу, заказ встаёт в очередь шаттла снабжения личным. shown_price - цена, которую видел покупатель; recipient_text - имя или номер счёта получателя подарка. Возвращает list(принят ли, ответ игроку).
/proc/econ_personal_order(mob/living/user, datum/bank_account/account, pack_type, shown_price, recipient_text, hide_name)
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
	var/datum/bank_account/recipient
	if(isnum(recipient_text) || (istext(recipient_text) && length(trim(recipient_text))))
		var/list/found = econ_personal_gift_recipient(account, recipient_text)
		recipient = found[1]
		if(!recipient)
			return list(FALSE, found[2])
	if(recipient && !COOLDOWN_FINISHED(account, personal_gift_cooldown))
		return list(FALSE, "Подарки можно оформлять не чаще раза в [DisplayTimeText(ECON_PERSONAL_GIFT_COOLDOWN)]: подождите ещё [DisplayTimeText(COOLDOWN_TIMELEFT(account, personal_gift_cooldown))].")
	var/limit = SSeconomy.settings.personal_order_limit
	if(length(econ_personal_orders_of(account)) >= limit)
		return list(FALSE, "Больше заказов сразу не принять, шаттла ждут уже [limit]: дождитесь отгрузки или отмените один.")
	if(econ_pack_unavailable(pack))
		return list(FALSE, "[pack.name] сейчас нет у партнёров, загляните позже.")
	var/price = round(econ_pack_price(pack, account))
	if(istext(shown_price))
		shown_price = text2num(shown_price)
	if(shown_price != price)
		return list(FALSE, "Цена изменилась: [pack.name] теперь стоит [price] кр. Проверьте и закажите снова.")
	if(!account.debit(price, ECON_PERSONAL_CATALOG, user, "[recipient ? "Подарок для [recipient.account_holder]" : "Личный заказ"]: [pack.name]"))
		return list(FALSE, "На счёте не хватает денег: [pack.name] стоит [price] кр.")
	var/datum/supply_order/order = econ_cargo_new_order(user, pack, recipient ? "Подарок с КПК" : "Личный заказ с КПК", account, FALSE)
	order.prepaid = price
	econ_personal_order_notice(pack)
	if(!recipient)
		log_econ("[key_name(user)] заказал с КПК [pack.name] за [price] кр. со счёта [account.account_holder] ([account.account_id]), заказ #[order.id]")
		account.bank_card_talk("Заказ №[order.id] оплачен: [pack.name] за [price] кр. Его привезёт ближайший шаттл снабжения - запертой посылкой на ваше имя. Пока шаттл не вылетел, заказ можно отменить в Кошельке.")
		return list(TRUE, "Заказ №[order.id] оплачен: [pack.name] за [price] кр.")
	order.gift_to = recipient
	order.gift_hide_name = !!hide_name
	COOLDOWN_START(account, personal_gift_cooldown, ECON_PERSONAL_GIFT_COOLDOWN)
	if(order.gift_hide_name)
		order.orderer = "аноним"
	log_econ("[key_name(user)] заказал с КПК [pack.name] за [price] кр. со счёта [account.account_holder] ([account.account_id]) в подарок [recipient.account_holder] ([recipient.account_id])[order.gift_hide_name ? " без имени дарителя" : ""], заказ #[order.id]")
	account.bank_card_talk("Подарок №[order.id] оплачен: [pack.name] за [price] кр. для [recipient.account_holder]. Его привезёт ближайший шаттл снабжения - запертой посылкой на имя получателя. Пока шаттл не вылетел, подарок можно отменить в Кошельке.")
	recipient.bank_card_talk("Вам едет посылка: [order.gift_hide_name ? "кто-то из экипажа" : account.account_holder] дарит вам [pack.name]. Её привезёт ближайший шаттл снабжения, откроет её ваша ID-карта.", balloon = "вам подарок")
	return list(TRUE, "Подарок №[order.id] для [recipient.account_holder] оплачен: [pack.name] за [price] кр.")

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

/// Возврат плательщику за снятый с корзины оплаченный с КПК заказ; quiet - без сообщения его карте, card_text - своё сообщение вместо слов о снабжении. Получатель подарка узнаёт, что подарок не приедет.
/proc/econ_refund_personal_order(datum/supply_order/order, mob/user, quiet = FALSE, card_text, who_text)
	var/datum/bank_account/buyer = order.paying_account
	var/refund = order.prepaid
	order.prepaid = 0
	var/datum/bank_account/recipient = order.gift_to
	if(!QDELETED(recipient))
		recipient.bank_card_talk("Подарок №[order.id] ([order.pack.name])[order.gift_hide_name ? "" : " от [buyer?.account_holder]"] отменён и не приедет.")
	var/who = user ? key_name(user) : (who_text || "Снабжение")
	if(QDELETED(buyer) || !buyer.credit(refund, ECON_REFUND, user, "Отмена заказа: [order.pack.name]"))
		log_econ("Личный заказ #[order.id] [order.pack.name] снят ([who]), но [refund] кр. вернуть некуда")
		return FALSE
	log_econ("Личный заказ #[order.id] [order.pack.name] счёта [buyer.account_holder] ([buyer.account_id])[recipient ? " в подарок [recipient.account_holder] ([recipient.account_id])" : ""] снят ([who]), возвращено [refund] кр.")
	if(!quiet)
		buyer.bank_card_talk(card_text || "Снабжение сняло ваш заказ №[order.id] ([order.pack.name]) с корзины: [refund] кр. вернулись на счёт.")
	return TRUE

/// Владелец счёта ушёл со смены: неотгруженные личные заказы, которые открыла бы его карта, снимаются с корзины, деньги возвращаются плательщику.
/proc/econ_refund_dormant_orders(datum/bank_account/account)
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		if(!order.personal_prepaid() || order.delivery_account() != account)
			continue
		var/refund = order.prepaid
		SSshuttle.shoppinglist -= order
		log_econ("Личный заказ #[order.id] [order.pack.name] снят с корзины: владелец счёта [account.account_holder] ([account.account_id]) ушёл со смены")
		econ_refund_personal_order(order, null, who_text = "автовозврат: владелец ушёл со смены", card_text = order.gift_to ? "Подарок №[order.id] ([order.pack.name]) снят с корзины: [account.account_holder] ушёл со смены. [refund] кр. вернулись на счёт." : "Заказ №[order.id] ([order.pack.name]) снят с корзины, пока вас не было на смене: [refund] кр. вернулись на счёт.")
		qdel(order)

/obj/docking_port/mobile/supply
	/// Личные заказы, которые шаттл везёт на станцию: weakref счёта, чья карта откроет посылку -> list("№id пак"); карта узнает о них, когда шаттл сядет
	var/list/personal_arrivals = list()

/// Отгрузка личного заказа: владелец посылки узнает о нём по прибытии шаттла на станцию.
/obj/docking_port/mobile/supply/proc/note_personal_shipment(datum/supply_order/order)
	var/datum/weakref/owner_ref = WEAKREF(order.delivery_account())
	if(!owner_ref)
		return
	if(!personal_arrivals[owner_ref])
		personal_arrivals[owner_ref] = list()
	var/gift = order.gift_to ? " (подарок[order.gift_hide_name ? "" : " от [order.paying_account?.account_holder]"])" : ""
	personal_arrivals[owner_ref] += "№[order.id] [order.pack.name][gift]"

/obj/docking_port/mobile/supply/proc/notify_personal_arrivals()
	for(var/datum/weakref/owner_ref as anything in personal_arrivals)
		var/datum/bank_account/owner = owner_ref.resolve()
		var/list/orders = personal_arrivals[owner_ref]
		owner?.bank_card_talk("Шаттл снабжения привёз на станцию [length(orders) > 1 ? "ваши заказы" : "ваш заказ"] [jointext(orders, ", ")]: запертая посылка на ваше имя ждёт в отделе снабжения, откроет её ваша ID-карта.")
	personal_arrivals.Cut()

/// Личные заказы account, которые шаттл уже везёт на станцию.
/obj/docking_port/mobile/supply/proc/personal_in_transit(datum/bank_account/account)
	if(!account?.weak_reference)
		return list()
	return personal_arrivals[account.weak_reference] || list()

/// Магазин Кошелька: раздел -> тип вещи или питомца -> list(цена, название в витрине, заметка). Только вид и уют: без брони, оружия, лекарств и доступов.
/proc/econ_shop_sections()
	var/static/list/sections
	if(!sections)
		sections = list(
			"Головные уборы" = list(
				/obj/item/clothing/head/flatcap = list(300, "Кепка", ""),
				/obj/item/clothing/head/beanie/striped = list(300, "Полосатая шапка", "Вязаная."),
				/obj/item/clothing/head/beret/black = list(400, "Чёрный берет", ""),
				/obj/item/clothing/head/fedora = list(500, "Фетровая шляпа", ""),
				/obj/item/clothing/head/bowler = list(600, "Котелок", ""),
				/obj/item/clothing/head/sombrero = list(600, "Сомбреро", ""),
				/obj/item/clothing/head/kitty = list(700, "Кошачьи ушки", ""),
				/obj/item/clothing/head/rabbitears = list(700, "Кроличьи ушки", ""),
				/obj/item/clothing/head/that = list(900, "Цилиндр", "Для торжественных случаев."),
				/obj/item/clothing/head/cowboyhat = list(800, "Ковбойская шляпа", ""),
			),
			"Одежда" = list(
				/obj/item/clothing/neck/tie/red = list(200, "Красный галстук", ""),
				/obj/item/clothing/neck/scarf/red = list(250, "Красный шарф", ""),
				/obj/item/clothing/neck/scarf/zebra = list(300, "Шарф в полоску", ""),
				/obj/item/clothing/accessory/maidapron/polychromic = list(500, "Фартук горничной", "Цвета выбираете сами."),
				/obj/item/clothing/shoes/sneakers/poly/polychromic = list(600, "Кеды", "Цвета выбираете сами."),
				/obj/item/clothing/under/shorts/polychromic = list(700, "Шорты", "Цвета выбираете сами."),
				/obj/item/clothing/glasses/monocle = list(800, "Монокль", ""),
				/obj/item/clothing/under/costume/kilt/polychromic = list(1200, "Килт", "Цвета выбираете сами."),
				/obj/item/clothing/under/dress/skirt/polychromic = list(1200, "Юбка", "Цвета выбираете сами."),
				/obj/item/clothing/under/dress/skirt/polychromic/pleated = list(1200, "Плиссированная юбка", "Цвета выбираете сами."),
				/obj/item/clothing/under/suit/black = list(1500, "Строгий чёрный костюм", ""),
				/obj/item/clothing/under/suit/white = list(1500, "Белый костюм", ""),
				/obj/item/clothing/suit/jacket/urbanjacket/polychromic = list(1800, "Городская куртка", "Цвета выбираете сами."),
				/obj/item/clothing/suit/hooded/wintercoat/polychromic = list(2200, "Зимнее пальто", "С капюшоном, цвета выбираете сами."),
				/obj/item/clothing/neck/cloak/polychromic = list(2500, "Плащ", "Цвета выбираете сами."),
				/obj/item/clothing/under/dress/polychromic/evening = list(3000, "Вечернее платье", "Цвета выбираете сами."),
			),
			"Краски" = list(
				/obj/item/storage/crayons = list(300, "Коробка мелков", "Мелок в стиральной машине вместе с одеждой красит её в свой цвет."),
				/obj/item/dyespray = list(500, "Краска для волос", "Цвет выбираете сами, красить можно себя и других."),
			),
			"Плюшевые и игрушки" = list(
				/obj/item/toy/cards/deck = list(150, "Колода карт", ""),
				/obj/item/toy/eightball = list(200, "Шар предсказаний", ""),
				/obj/item/toy/plush/carpplushie = list(250, "Плюшевый космокарп", ""),
				/obj/item/toy/plush/lizardplushie = list(250, "Плюшевая ящерица", ""),
				/obj/item/toy/plush/snakeplushie = list(250, "Плюшевая змея", ""),
				/obj/item/toy/plush/slimeplushie = list(250, "Плюшевый слайм", ""),
				/obj/item/toy/plush/beeplushie = list(300, "Плюшевая пчела", ""),
				/obj/item/toy/plush/mothplushie = list(300, "Плюшевая моль", ""),
				/obj/item/toy/plush/bubbleplush = list(300, "Плюшевый пузырь", ""),
				/obj/item/toy/plush/nukeplushie = list(400, "Плюшевый оперативник", ""),
			),
			"Уют для каюты" = list(
				/obj/item/poster/random_official = list(150, "Официальный плакат", "Какой - узнаете, развернув. Вешается на стену, гравировку на плакат не сделать."),
				/obj/item/canvas/twentythreeXtwentythree = list(150, "Большой холст", "Рисуйте мелками и вешайте на стену в рамке из доски."),
				/obj/item/storage/fancy/candle_box = list(250, "Коробка свечей", ""),
				/obj/item/bedsheet/blue = list(300, "Синяя простыня", ""),
				/obj/item/bedsheet/purple = list(300, "Фиолетовая простыня", ""),
				/obj/item/bedsheet/rainbow = list(500, "Радужная простыня", ""),
				/obj/item/instrument/harmonica = list(600, "Губная гармошка", ""),
			),
			"Питомцы" = list(
				/mob/living/simple_animal/butterfly = list(400, "Бабочка", "Не держите рядом с ящеркой - съест."),
				/mob/living/simple_animal/mouse/white = list(600, "Белая мышка", ""),
				/mob/living/simple_animal/chick = list(800, "Цыплёнок", "Вырастет в курицу."),
				/mob/living/simple_animal/crab = list(1000, "Краб", ""),
				/mob/living/simple_animal/hostile/lizard = list(1200, "Ящерка", "Ловит насекомых и съест бабочку, если та рядом."),
				/mob/living/simple_animal/pet/cat/kitten = list(4000, "Котёнок", ""),
				/mob/living/simple_animal/pet/dog/corgi/puppy = list(5000, "Щенок корги", ""),
			),
		)
	return sections

/// Пул новинок: каждую смену из него продаётся ECON_SHOP_NOVELTIES случайных вещей.
/proc/econ_shop_novelty_pool()
	var/static/list/pool
	if(!pool)
		pool = list(
			/obj/item/clothing/head/beanie/christmas = list(400, "Праздничная шапка", ""),
			/obj/item/clothing/neck/scarf/christmas = list(400, "Праздничный шарф", ""),
			/obj/item/clothing/head/maid = list(400, "Наколка горничной", ""),
			/obj/item/toy/plush/teddybear = list(350, "Плюшевый мишка", ""),
			/obj/item/toy/plush/deer = list(350, "Плюшевый олень", ""),
			/obj/item/toy/plush/drake = list(450, "Плюшевый пепельный дракон", ""),
			/obj/item/toy/plush/bird = list(350, "Плюшевая птица", ""),
			/obj/item/toy/plush/crab = list(350, "Плюшевый краб", ""),
			/obj/item/clothing/neck/cloak/alt/polychromic = list(2500, "Длинный плащ", "Цвета выбираете сами."),
			/obj/item/clothing/neck/cloak/cancloak/polychromic = list(2500, "Плащ-накидка", "Цвета выбираете сами."),
			/obj/item/clothing/under/performer/polychromic = list(2500, "Сценический костюм", "Цвета выбираете сами."),
		)
	return pool

GLOBAL_LIST_INIT(econ_shop_novelties, econ_shop_pick_novelties())

/proc/econ_shop_pick_novelties()
	var/list/pool = econ_shop_novelty_pool()
	var/list/left = pool.Copy()
	. = list()
	for(var/i in 1 to min(ECON_SHOP_NOVELTIES, length(left)))
		.[pick_n_take(left)] = TRUE

/// Запись магазина, если вещь продаётся сейчас: list(цена, название, заметка, раздел); иначе null.
/proc/econ_shop_entry(item_type)
	if(!ispath(item_type, /atom/movable))
		return null
	var/list/sections = econ_shop_sections()
	for(var/section in sections)
		var/list/items = sections[section]
		var/list/entry = items[item_type]
		if(entry)
			return entry + section
	if(GLOB.econ_shop_novelties[item_type])
		var/list/pool = econ_shop_novelty_pool()
		var/list/entry = pool[item_type]
		return entry + ECON_SHOP_NOVELTY_SECTION
	return null

/// Можно ли выгравировать надпись: не на питомце и не на плакате, который на стене становится другим предметом.
/proc/econ_shop_engravable(item_type)
	return !ispath(item_type, /mob/living) && !ispath(item_type, /obj/item/poster)

/proc/econ_shop_sprite_id(item_type)
	return replacetext(copytext("[item_type]", 2), "/", "-")

/datum/asset/spritesheet_batched/econ_shop
	name = "econ_shop"

/datum/asset/spritesheet_batched/econ_shop/create_spritesheets()
	var/list/pool = econ_shop_novelty_pool()
	var/list/types = pool.Copy()
	var/list/sections = econ_shop_sections()
	for(var/section in sections)
		types |= sections[section]
	for(var/atom/item_type as anything in types)
		var/icon_file = initial(item_type.icon)
		var/icon_state = initial(item_type.icon_state)
		if(!econ_shop_icon_ok(icon_file, icon_state))
			continue
		insert_icon(econ_shop_sprite_id(item_type), uni_icon(icon_file, icon_state, SOUTH, color = initial(item_type.color)))

/// Годится ли пара для листа иконок: IconForge читает только DMI, а пустой или отсутствующий стейт роняет весь шард.
/proc/econ_shop_icon_ok(icon_file, icon_state)
	return icon_file && copytext("[icon_file]", -4) == ".dmi" && istext(icon_state) && length(icon_state) && icon_exists(icon_file, icon_state)

/// Магазин для окна кошелька: новинки смены, затем разделы; у вещи цена, заметка и CSS-класс иконки.
/proc/econ_shop_ui()
	var/datum/asset/spritesheet_batched/econ_shop/sheet = get_asset_datum(/datum/asset/spritesheet_batched/econ_shop)
	. = list()
	var/list/novelties = list()
	var/list/pool = econ_shop_novelty_pool()
	for(var/item_type in GLOB.econ_shop_novelties)
		novelties += list(econ_shop_card(item_type, pool[item_type], sheet))
	if(length(novelties))
		. += list(list("name" = ECON_SHOP_NOVELTY_SECTION, "novelty" = TRUE, "items" = novelties))
	var/list/sections = econ_shop_sections()
	for(var/section in sections)
		var/list/items = sections[section]
		var/list/cards = list()
		for(var/item_type in items)
			cards += list(econ_shop_card(item_type, items[item_type], sheet))
		. += list(list("name" = section, "items" = cards))

/proc/econ_shop_card(item_type, list/entry, datum/asset/spritesheet_batched/econ_shop/sheet)
	return list(
		"id" = "[item_type]",
		"name" = entry[2],
		"note" = entry[3],
		"price" = entry[1],
		"pet" = ispath(item_type, /mob/living),
		"engravable" = econ_shop_engravable(item_type),
		"icon" = sheet?.icon_class_name(econ_shop_sprite_id(item_type)),
	)

/datum/bank_account
	COOLDOWN_DECLARE(personal_shop_cooldown)

/// Имя плательщика для получателя, как на кассе: имя на ID-карте, с которой платят, иначе владелец счёта.
/proc/econ_payer_name(obj/item/card/id/card, datum/bank_account/account)
	if(istype(card) && card.registered_account == account && length(card.registered_name))
		return card.registered_name
	return account?.account_holder

/// Корзина магазина из окна: lines - list(list("id", "price", "text")), text - гравировка вещи или кличка питомца. Возвращает list(корзина) - list(list(тип, цена, текст)) - или list(null, отказ игроку). Цена каждой вещи сверяется с той, что видел покупатель.
/proc/econ_shop_parse_cart(mob/living/user, list/lines)
	if(!islist(lines) || !length(lines))
		return list(null, "Корзина пуста.")
	if(length(lines) > ECON_SHOP_CART_MAX)
		return list(null, "В одну капсулу помещается не больше [ECON_SHOP_CART_MAX] вещей.")
	var/list/cart = list()
	for(var/list/line in lines)
		var/item_type = line["id"]
		if(istext(item_type))
			item_type = text2path(item_type)
		var/list/entry = econ_shop_entry(item_type)
		if(!entry)
			return list(null, "Этого в магазине сейчас нет.")
		var/pet = ispath(item_type, /mob/living)
		if(pet && length(lines) > 1)
			return list(null, "Питомец летит в своей капсуле: закажите его отдельно от вещей.")
		var/shown_price = line["price"]
		if(istext(shown_price))
			shown_price = text2num(shown_price)
		if(shown_price != entry[1])
			return list(null, "Цена изменилась: [entry[2]] теперь стоит [entry[1]] кр. Проверьте и купите снова.")
		var/list/text_result = econ_player_text(user, line["text"], pet ? MAX_NAME_LEN : ECON_SHOP_ENGRAVING_MAX)
		if(text_result[2])
			return list(null, text_result[2])
		var/text = text_result[1]
		if(length(text) && pet)
			text = reject_bad_name(text_result[3], TRUE, MAX_NAME_LEN, FALSE)
			if(!text)
				return list(null, "Такую кличку не дать: нужны буквы, без лишних знаков.")
		else if(length(text) && !econ_shop_engravable(item_type))
			return list(null, "[entry[2]]: гравировку здесь не сделать.")
		cart += list(list(item_type, entry[1], text))
	if(length(cart) != length(lines))
		return list(null, "Корзина сбилась, соберите её заново.")
	return list(cart)

/// Сколько стоит корзина: цены вещей и гравировки.
/proc/econ_shop_cart_total(list/cart)
	. = 0
	for(var/list/line as anything in cart)
		. += line[2] + (length(line[3]) && econ_shop_engravable(line[1]) ? ECON_SHOP_ENGRAVING_PRICE : 0)

/// Корзина словами для игрока: названия витрины, с гравировкой или кличкой.
/proc/econ_shop_cart_names(list/cart)
	var/list/names = list()
	for(var/list/line as anything in cart)
		var/list/entry = econ_shop_entry(line[1])
		var/title = entry ? entry[2] : "[line[1]]"
		if(length(line[3]))
			title += econ_shop_engravable(line[1]) ? " с гравировкой" : " по кличке [line[3]]"
		names += title
	return jointext(names, ", ")

/// Корзина для лога: тип, цена и текст игрока каждой вещи.
/proc/econ_shop_cart_log(list/cart)
	var/list/parts = list()
	for(var/list/line as anything in cart)
		parts += "[line[1]] [line[2]] кр.[length(line[3]) ? " \"[line[3]]\"" : ""]"
	return jointext(parts, "; ")

/// Капсула магазина: тихая, без взрыва и свиста, только негромкий звук посадки.
/proc/econ_shop_new_pod()
	var/obj/structure/closet/supplypod/bluespacepod/pod = new(null)
	pod.effectQuiet = TRUE
	pod.landingSound = 'sound/effects/phasein.ogg'
	pod.soundVolume = 30
	return pod

/// Корзина в капсулу и капсула на landing.
/proc/econ_shop_launch(turf/landing, list/cart, recipient_name, giver_name, gift)
	var/obj/structure/closet/supplypod/pod = econ_shop_new_pod()
	for(var/list/line as anything in cart)
		econ_shop_pack(line[1], pod, line[2], line[3])
	if(gift)
		econ_shop_gift_card(pod, recipient_name, giver_name)
	new /obj/effect/pod_landingzone(landing, pod)
	return pod

/// Покупка в магазине Кошелька: cart_lines - корзина из окна (см. econ_shop_parse_cart). Себе - цена списывается сразу и корзина прилетает тихой капсулой рядом; в подарок - платит даритель, а получатель забирает подарок в своём Кошельке. Возвращает list(принято ли, ответ игроку).
/proc/econ_shop_order(mob/living/user, datum/bank_account/account, list/cart_lines, recipient_text, hide_name, payer_name)
	var/problem = SSeconomy.personal_account_problem(account, TRUE)
	if(problem)
		return list(FALSE, problem)
	var/list/parsed = econ_shop_parse_cart(user, cart_lines)
	var/list/cart = parsed[1]
	if(!cart)
		return list(FALSE, parsed[2])
	var/total = econ_shop_cart_total(cart)
	var/names = econ_shop_cart_names(cart)
	if(isnum(recipient_text) || (istext(recipient_text) && length(trim(recipient_text))))
		return econ_shop_gift_order(user, account, cart, total, names, recipient_text, hide_name ? null : (payer_name || account.account_holder))
	if(!COOLDOWN_FINISHED(account, personal_shop_cooldown))
		return list(FALSE, "Капсулу можно вызывать не чаще раза в [DisplayTimeText(ECON_SHOP_ORDER_COOLDOWN)]: подождите ещё [DisplayTimeText(COOLDOWN_TIMELEFT(account, personal_shop_cooldown))].")
	var/turf/landing = econ_express_landing(user)
	if(!landing)
		return list(FALSE, "Капсуле негде сесть: нужен свободный пол рядом с вами, в том же помещении станции, не за стеклом.")
	if(!account.debit(total, ECON_PERSONAL_CATALOG, user, "Магазин: [names]"))
		return list(FALSE, "На счёте не хватает денег: [names] - [total] кр.")
	COOLDOWN_START(account, personal_shop_cooldown, ECON_SHOP_ORDER_COOLDOWN)
	econ_shop_launch(landing, cart)
	log_econ("[key_name(user)] купил в магазине Кошелька за [total] кр. со счёта [account.account_holder] ([account.account_id]): [econ_shop_cart_log(cart)], капсула в [AREACOORD(landing)]")
	econ_shop_log_texts(user, cart)
	return list(TRUE, "Оплачено [total] кр.: [names] уже летит, капсула сядет рядом с вами через пару секунд.")

/// Тексты игрока на вещах и кличках - в игровой лог.
/proc/econ_shop_log_texts(mob/living/user, list/cart)
	for(var/list/line as anything in cart)
		if(length(line[3]))
			log_game("[key_name(user)] [econ_shop_engravable(line[1]) ? "выгравировал на" : "назвал"] [line[1]] из магазина Кошелька: \"[line[3]]\"")

/// Подарок из магазина: деньги списываются с дарителя, получатель узнаёт о подарке и забирает его в Кошельке, иначе через shop_gift_accept_minutes деньги вернутся. giver_name - имя для получателя и открытки, null - аноним.
/proc/econ_shop_gift_order(mob/living/user, datum/bank_account/account, list/cart, total, names, recipient_text, giver_name)
	var/list/found = econ_personal_gift_recipient(account, recipient_text, TRUE)
	var/datum/bank_account/recipient = found[1]
	if(!recipient)
		return list(FALSE, found[2])
	if(!COOLDOWN_FINISHED(account, personal_gift_cooldown))
		return list(FALSE, "Подарки можно оформлять не чаще раза в [DisplayTimeText(ECON_PERSONAL_GIFT_COOLDOWN)]: подождите ещё [DisplayTimeText(COOLDOWN_TIMELEFT(account, personal_gift_cooldown))].")
	if(!account.debit(total, ECON_PERSONAL_CATALOG, user, "Подарок для [recipient.account_holder]: [names]"))
		return list(FALSE, "На счёте не хватает денег: [names] - [total] кр.")
	COOLDOWN_START(account, personal_gift_cooldown, ECON_PERSONAL_GIFT_COOLDOWN)
	var/minutes = SSeconomy.settings.shop_gift_accept_minutes
	var/datum/econ_shop_gift/gift = new(account, recipient, cart, total, giver_name, minutes)
	log_econ("[key_name(user)] оформил подарок #[gift.id] из магазина Кошелька за [total] кр. со счёта [account.account_holder] ([account.account_id]) для [recipient.account_holder] ([recipient.account_id])[giver_name ? "" : " без имени дарителя"]: [econ_shop_cart_log(cart)]")
	econ_shop_log_texts(user, cart)
	recipient.bank_card_talk("Вам подарок от [giver_name || "анонимного дарителя"]: [names]. Заберите его в Кошельке КПК, вкладка «Магазин», кнопка «Получить» - капсула сядет рядом с вами. Подарок ждёт [minutes] мин.", balloon = "вам подарок")
	return list(TRUE, "Подарок №[gift.id] для [recipient.account_holder] оплачен: [total] кр. Получатель заберёт его в своём Кошельке, а если не заберёт за [minutes] мин., деньги вернутся.")

GLOBAL_LIST_EMPTY(econ_shop_gifts)
GLOBAL_VAR_INIT(econ_shop_gift_serial, 0)

/// Оплаченный подарок из магазина: ждёт, пока получатель заберёт его в Кошельке.
/datum/econ_shop_gift
	var/id
	var/datum/weakref/giver_ref
	var/datum/weakref/recipient_ref
	/// list(list(тип, цена, текст)), как из econ_shop_parse_cart
	var/list/cart
	var/total
	/// Имя дарителя для получателя и открытки; null - аноним
	var/giver_name
	var/expires_at

/datum/econ_shop_gift/New(datum/bank_account/giver, datum/bank_account/recipient, list/cart, total, giver_name, minutes)
	id = ++GLOB.econ_shop_gift_serial
	giver_ref = WEAKREF(giver)
	recipient_ref = WEAKREF(recipient)
	src.cart = cart
	src.total = total
	src.giver_name = giver_name
	expires_at = world.time + minutes MINUTES
	GLOB.econ_shop_gifts += src
	addtimer(CALLBACK(src, PROC_REF(expire)), minutes MINUTES)

/datum/econ_shop_gift/Destroy()
	GLOB.econ_shop_gifts -= src
	return ..()

/// Срок вышел: деньги возвращаются дарителю, без объяснения, почему подарок не забрали.
/datum/econ_shop_gift/proc/expire()
	var/names = econ_shop_cart_names(cart)
	var/datum/bank_account/giver = giver_ref.resolve()
	var/datum/bank_account/recipient = recipient_ref.resolve()
	if(giver && giver.credit(total, ECON_REFUND, null, "Подарок не забрали: [names]"))
		giver.bank_card_talk("Подарок №[id] ([names]) никто не забрал: [total] кр. вернулись на счёт.")
		log_econ("Подарок #[id] из магазина Кошелька для [recipient?.account_holder] ([recipient?.account_id]) не забрали, [total] кр. возвращены [giver.account_holder] ([giver.account_id])")
	else
		log_econ("Подарок #[id] из магазина Кошелька для [recipient?.account_holder] не забрали, но [total] кр. вернуть некуда")
	qdel(src)

/// Подарки, которые ждут account.
/proc/econ_shop_gifts_for(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/econ_shop_gift/gift as anything in GLOB.econ_shop_gifts)
		if(gift.recipient_ref.resolve() == account)
			. += gift

/// Получатель забирает подарок: капсула садится рядом с ним, на открытке - его имя с ID-карты. Возвращает list(забрал ли, ответ игроку).
/proc/econ_shop_gift_accept(mob/living/user, datum/bank_account/account, gift_id, recipient_name)
	if(istext(gift_id))
		gift_id = text2num(gift_id)
	var/datum/econ_shop_gift/gift
	for(var/datum/econ_shop_gift/waiting as anything in econ_shop_gifts_for(account))
		if(waiting.id == gift_id)
			gift = waiting
	if(!gift)
		return list(FALSE, "Этого подарка уже нет.")
	if(!COOLDOWN_FINISHED(account, personal_shop_cooldown))
		return list(FALSE, "Капсулу можно вызывать не чаще раза в [DisplayTimeText(ECON_SHOP_ORDER_COOLDOWN)]: подождите ещё [DisplayTimeText(COOLDOWN_TIMELEFT(account, personal_shop_cooldown))]. Подарок подождёт.")
	var/turf/landing = econ_express_landing(user)
	if(!landing)
		return list(FALSE, "Капсуле негде сесть: нужен свободный пол рядом с вами, в том же помещении станции, не за стеклом. Подарок подождёт.")
	COOLDOWN_START(account, personal_shop_cooldown, ECON_SHOP_ORDER_COOLDOWN)
	var/names = econ_shop_cart_names(gift.cart)
	econ_shop_launch(landing, gift.cart, recipient_name || account.account_holder, gift.giver_name, TRUE)
	var/datum/bank_account/giver = gift.giver_ref.resolve()
	log_econ("[key_name(user)] забрал подарок #[gift.id] из магазина Кошелька на счёт [account.account_holder] ([account.account_id]) от [giver?.account_holder] ([giver?.account_id]): [econ_shop_cart_log(gift.cart)], капсула в [AREACOORD(landing)]")
	giver?.bank_card_talk("Подарок №[gift.id] ([names]) получен.")
	qdel(gift)
	return list(TRUE, "Подарок летит: [names], капсула сядет рядом с вами через пару секунд.")

/// Вещь из магазина в container: питомец - в закрытой переноске, text - его кличка или гравировка вещи. Купленное помечено как из автомата: NT выкупает его не дороже доли цены.
/proc/econ_shop_pack(item_type, atom/container, price, text)
	var/atom/movable/thing
	if(ispath(item_type, /mob/living))
		var/obj/item/pet_carrier/carrier = new(container)
		var/mob/living/pet = new item_type(container)
		if(length(text) && isanimal(pet) && !pet.key)
			pet.name = text
			pet.real_name = text
		carrier.add_occupant(pet)
		carrier.open = FALSE
		carrier.update_icon()
		thing = carrier
	else
		thing = new item_type(container)
		if(length(text) && econ_shop_engravable(item_type))
			thing.AddComponent(/datum/component/econ_engraving, text)
	econ_mark_vended(thing, price)
	return thing

/// Открытка к подарку: кому - имя получателя с его ID-карты, от кого - имя дарителя, если он не скрылся.
/proc/econ_shop_gift_card(atom/container, recipient_name, giver_name)
	var/obj/item/paper/card = new(container)
	card.name = "gift card"
	card.add_raw_text("Подарок для [recipient_name][giver_name ? " от [giver_name]" : ""].")
	card.update_appearance()
	econ_mark_vended(card, 0)
	return card

/// Гравировка из магазина Кошелька: видна при осмотре и не зависит от описания вещи, которое меняют игрушки и окраска.
/datum/component/econ_engraving
	var/text

/datum/component/econ_engraving/Initialize(text)
	if(!isatom(parent) || !length(text))
		return COMPONENT_INCOMPATIBLE
	src.text = text

/datum/component/econ_engraving/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/econ_engraving/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/datum/component/econ_engraving/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("На вещи выгравировано: «[text]».")
