/// Пачка скупки: разные предметы из ассортимента партнёра, только целиком и со скидкой. Цена фиксирована при выставлении.
/datum/supply_pack/bundle
	name = "пачка скупки"
	group = BUNDLE_GROUP
	crate_name = "ящик скупки"
	var/uid
	var/seller_id
	var/price = 0
	/// Сколько стоили бы те же предметы по отдельности у этого партнёра
	var/full_value = 0
	var/discount = 0
	var/expires_at
	var/list/item_names = list()

/datum/supply_pack/bundle/market_cost(datum/bank_account/paying_account, datum/trade_partner/partner)
	return price

/datum/controller/subsystem/market
	/// Пачки скупки, которые сейчас можно купить
	var/list/bundles = list()
	var/next_bundle_at = 0
	var/bundle_uid = 0

/// Раз в минуту из fire(): просроченные пачки снимаются, новые выставляются, пока их меньше BUNDLES_MAX.
/datum/controller/subsystem/market/proc/tick_bundles()
	for(var/datum/supply_pack/bundle/bundle as anything in bundles)
		if(world.time >= bundle.expires_at)
			bundles -= bundle
			qdel(bundle)
	if(!next_bundle_at)
		next_bundle_at = world.time + rand(BUNDLE_GAP_MIN, BUNDLE_GAP_MAX)
		return
	if(world.time < next_bundle_at)
		return
	next_bundle_at = world.time + rand(BUNDLE_GAP_MIN, BUNDLE_GAP_MAX)
	if(length(bundles) < BUNDLES_MAX)
		generate_bundle()

/// Партнёры, у которых есть что сложить в пачку: открытые, не под эмбарго, не контрабандные.
/datum/controller/subsystem/market/proc/bundle_sellers()
	. = list()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(partner.unlocked && !partner.embargoed() && !partner.contraband && length(partner.sells_groups))
			. += partner

/// Новая пачка у seller (или у случайного партнёра): BUNDLE_ITEMS_MIN..MAX разных предметов из его паков, скидка BUNDLE_DISCOUNT_MIN..MAX%.
/datum/controller/subsystem/market/proc/generate_bundle(datum/trade_partner/seller)
	if(!seller)
		var/list/sellers = bundle_sellers()
		if(!length(sellers))
			return null
		seller = pick(sellers)
	var/list/values = list()
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(!econ_partner_supplies(seller, pack) || pack.dangerous || pack.goody || econ_personal_catalog_pack(pack))
			continue
		var/count = length(pack.contains)
		if(!count || count > BUNDLE_SOURCE_PACK_MAX)
			continue
		var/unit = seller.pack_price(pack) / count
		for(var/item_type in pack.contains)
			if(ispath(item_type, /obj/item) && !values[item_type])
				values[item_type] = unit
	if(length(values) < BUNDLE_ITEMS_MIN)
		return null
	var/datum/supply_pack/bundle/bundle = new
	bundle.uid = ++bundle_uid
	bundle.seller_id = seller.id
	bundle.contains = list()
	var/list/pool = values.Copy()
	for(var/i in 1 to min(rand(BUNDLE_ITEMS_MIN, BUNDLE_ITEMS_MAX), length(pool)))
		var/obj/item/item_type = pick(pool)
		bundle.full_value += pool[item_type]
		pool -= item_type
		bundle.contains += item_type
		bundle.item_names += initial(item_type.name)
	bundle.full_value = round(bundle.full_value)
	bundle.discount = rand(BUNDLE_DISCOUNT_MIN, BUNDLE_DISCOUNT_MAX)
	bundle.price = max(1, round(bundle.full_value * (100 - bundle.discount) / 100))
	bundle.cost = bundle.price
	bundle.expires_at = world.time + BUNDLE_LIFETIME
	bundle.name = "Скупка у \"[seller.name]\": [length(bundle.contains)] предм."
	bundle.desc = "Только целиком: [jointext(bundle.item_names, ", ")]."
	bundles += bundle
	log_econ("Скупка #[bundle.uid] у [seller.name]: [jointext(bundle.item_names, ", ")] за [bundle.price] кр. вместо [bundle.full_value]")
	return bundle

/datum/controller/subsystem/market/proc/bundle_by_uid(uid)
	for(var/datum/supply_pack/bundle/bundle as anything in bundles)
		if(bundle.uid == uid)
			return bundle

/// Покупка пачки из окна снабжения: снабжение за бюджет или лично; заявкой скупку не взять. Пачка уходит в корзину и пропадает из скупки.
/proc/econ_cargo_buy_bundle(mob/user, list/params, atom/movable/speaker, self_paid, can_buy_for_cargo, show_contraband = FALSE)
	var/uid = params["uid"]
	if(istext(uid))
		uid = text2num(uid)
	var/datum/supply_pack/bundle/bundle = SSmarket.bundle_by_uid(uid)
	if(!bundle)
		speaker.say("Эту пачку уже забрали или сняли.")
		return FALSE
	if(!self_paid && !can_buy_for_cargo)
		speaker.say("За бюджет снабжения скупку берёт только снабжение; купить пачку можно лично.")
		return FALSE
	var/datum/bank_account/account
	if(self_paid)
		account = econ_cargo_private_account(user, speaker)
		if(!account)
			return FALSE
	SSmarket.bundles -= bundle
	var/datum/supply_order/order = econ_cargo_new_order(user, bundle, "", account, FALSE)
	order.partner_id = bundle.seller_id
	order.contraband_supply = show_contraband
	speaker.say("Пачка скупки в корзине: [bundle.price] кр.[account ? ", оплата со счёта [account.account_holder] при доставке" : ""].")
	log_econ("[key_name(user)] берёт скупку #[bundle.uid] за [bundle.price] кр.[account ? " лично" : ""]")
	return TRUE

/// Скупка для окон снабжения.
/proc/econ_bundles_ui_data()
	. = list()
	for(var/datum/supply_pack/bundle/bundle as anything in SSmarket.bundles)
		var/datum/trade_partner/seller = SSmarket.get_partner(bundle.seller_id)
		. += list(list(
			"uid" = bundle.uid,
			"partner" = seller?.name,
			"partner_id" = bundle.seller_id,
			"items" = bundle.item_names,
			"full_value" = bundle.full_value,
			"price" = bundle.price,
			"discount" = bundle.discount,
			"left" = max(0, CEILING((bundle.expires_at - world.time) / (1 SECONDS), 1)),
		))
