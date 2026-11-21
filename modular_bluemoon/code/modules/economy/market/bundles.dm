/// Пачка скупки: несколько паков каталога одного отдела у одного партнёра в одном ящике, только целиком и со скидкой. Цена фиксирована при выставлении.
/datum/supply_pack/bundle
	name = "пачка скупки"
	group = BUNDLE_GROUP
	crate_name = "ящик скупки"
	var/uid
	var/seller_id
	/// Отдел, для которого собрана пачка: её глава, ГП или капитан берут пачку за бюджет отдела
	var/department_id
	var/price = 0
	/// Сколько стоили бы те же паки по отдельности у этого партнёра
	var/full_value = 0
	var/discount = 0
	var/expires_at
	/// Паки пачки: ящик наполняют они сами
	var/list/source_packs = list()
	var/list/pack_names = list()
	/// Что из пачки отделу нужно сейчас и почему, из "нужно сейчас" окна бюджета; пусто - пачка на каждый день
	var/need

/datum/supply_pack/bundle/Destroy()
	source_packs = null
	return ..()

/datum/supply_pack/bundle/market_cost(datum/bank_account/paying_account, datum/trade_partner/partner)
	return price

/datum/supply_pack/bundle/fill(obj/structure/closet/crate/C)
	for(var/datum/supply_pack/pack as anything in source_packs)
		pack.fill(C)

/// Паки с замком в одной пачке - только с одинаковым доступом: ящик пачки запирается им.
/datum/supply_pack/bundle/proc/take_access(datum/supply_pack/pack)
	if(!pack.access && !pack.access_any)
		return TRUE
	if(!access && !access_any)
		access = pack.access
		access_any = pack.access_any
		crate_type = /obj/structure/closet/crate/secure
		return TRUE
	return access == pack.access && access_any ~= pack.access_any

/// Для кого пачка, в названии: "Скупка для медбея".
/proc/econ_bundle_whom(department_id)
	var/static/list/whom = list(
		ACCOUNT_MED = "медбея",
		ACCOUNT_ENG = "инженерии",
		ACCOUNT_SCI = "науки",
		ACCOUNT_SEC = "СБ",
		ACCOUNT_SRV = "сервиса",
	)
	return whom[department_id]

/datum/economy_department
	COOLDOWN_DECLARE(bundle_notice_cooldown)

/datum/controller/subsystem/market
	/// Пачки скупки, которые сейчас можно купить
	var/list/bundles = list()
	var/next_bundle_at = 0
	var/bundle_uid = 0

/// Раз в минуту из fire(): просроченные пачки снимаются, новые выставляются, пока их меньше BUNDLES_MAX; продавца выбирает вес bundle_spawn_chance(), и тот же шанс решает, выставит ли он пачку: партнёр, чьи пачки не берут, выставляет реже.
/datum/controller/subsystem/market/proc/tick_bundles()
	for(var/datum/supply_pack/bundle/bundle as anything in bundles)
		if(world.time >= bundle.expires_at)
			bundles -= bundle
			var/datum/trade_partner/seller = get_partner(bundle.seller_id)
			seller?.note_bundle_ignored(bundle)
			qdel(bundle)
	if(!next_bundle_at)
		next_bundle_at = world.time + rand(BUNDLE_GAP_MIN, BUNDLE_GAP_MAX)
		return
	if(world.time < next_bundle_at)
		return
	next_bundle_at = world.time + rand(BUNDLE_GAP_MIN, BUNDLE_GAP_MAX)
	if(length(bundles) >= BUNDLES_MAX)
		return
	var/list/weights = list()
	var/total = 0
	for(var/datum/trade_partner/seller as anything in bundle_sellers())
		weights[seller] = seller.bundle_spawn_chance()
		total += weights[seller]
	if(total <= 0)
		return
	var/roll = rand() * total
	for(var/datum/trade_partner/seller as anything in weights)
		if(!weights[seller])
			continue
		roll -= weights[seller]
		if(roll <= 0)
			if(prob(weights[seller]))
				generate_bundle(seller)
			return

/// Партнёры, у которых есть что сложить в пачку: открытые, не под эмбарго, не контрабандные.
/datum/controller/subsystem/market/proc/bundle_sellers()
	. = list()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(partner.unlocked && !partner.embargoed() && !partner.contraband && length(partner.sells_groups))
			. += partner

/// Паки каталогов отделов, которые seller может сложить в пачку: id отдела -> паки, у отдела их не меньше BUNDLE_PACKS_MIN.
/datum/controller/subsystem/market/proc/bundle_sources(datum/trade_partner/seller)
	. = list()
	for(var/department_id in econ_group_departments())
		var/datum/economy_department/department = SSeconomy.get_department(department_id)
		if(!department)
			continue
		var/list/packs = list()
		for(var/datum/supply_pack/pack as anything in department.catalog())
			if(econ_bundle_source_ok(seller, pack))
				packs += pack
		if(length(packs) >= BUNDLE_PACKS_MIN)
			.[department_id] = packs

/// Пак годится в пачку: seller его везёт, внутри только вещи, не опасный, не из личного каталога и сам по себе не дороже BUNDLE_VALUE_MAX.
/proc/econ_bundle_source_ok(datum/trade_partner/seller, datum/supply_pack/pack)
	if(pack.dangerous || !length(pack.contains) || ispath(pack.type, /datum/supply_pack/critter) || econ_personal_catalog_pack(pack) || !econ_partner_supplies(seller, pack))
		return FALSE
	for(var/item_type in pack.contains)
		if(!ispath(item_type, /obj/item))
			return FALSE
	return seller.pack_price(pack) <= BUNDLE_VALUE_MAX

/datum/controller/subsystem/market/proc/bundle_for_department(department_id)
	for(var/datum/supply_pack/bundle/bundle as anything in bundles)
		if(bundle.department_id == department_id)
			return bundle

/// Отдел для новой пачки: с сотрудниками на смене и без своей пачки в скупке; чем больше его "нужно сейчас" есть у продавца, тем чаще. Таких нет - любой.
/datum/controller/subsystem/market/proc/pick_bundle_department(list/sources)
	var/list/stats = econ_staff_stats()
	var/list/weights = list()
	for(var/department_id in sources)
		var/datum/economy_department/department = SSeconomy.get_department(department_id)
		if(bundle_for_department(department_id) || !department.staff_on_shift(stats))
			continue
		var/weight = 1
		var/list/packs = sources[department_id]
		for(var/pack_type in department.needs_now())
			if(SSshuttle.supply_packs[pack_type] in packs)
				weight++
		weights[department_id] = weight
	return length(weights) ? pickweight(weights) : pick(sources)

/// Новая пачка у seller (или у случайного партнёра) для отдела department_id (или выбранного pick_bundle_department()): BUNDLE_PACKS_MIN..MAX паков его каталога, сперва то, что отделу нужно сейчас, скидка BUNDLE_DISCOUNT_MIN..MAX%. Канал отдела слышит о ней.
/datum/controller/subsystem/market/proc/generate_bundle(datum/trade_partner/seller, department_id)
	if(!seller)
		var/list/sellers = bundle_sellers()
		if(!length(sellers))
			return null
		seller = pick(sellers)
	var/list/sources = bundle_sources(seller)
	if(!department_id && length(sources))
		department_id = pick_bundle_department(sources)
	var/list/packs = sources[department_id]
	if(!packs)
		return null
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	var/list/needs = department.needs_now()
	var/list/needed = list()
	for(var/pack_type in needs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack in packs)
			needed += pack
	var/list/rest = shuffle(packs - needed)
	var/wanted = rand(BUNDLE_PACKS_MIN, BUNDLE_PACKS_MAX)
	// Одно место - не из "нужно сейчас", иначе пачки отдела выходят одинаковыми
	var/first_needed = min(length(needed), length(rest) ? wanted - 1 : wanted)
	var/list/candidates = needed.Copy(1, first_needed + 1) + rest + needed.Copy(first_needed + 1)
	var/datum/supply_pack/bundle/bundle = new
	var/value = 0
	for(var/datum/supply_pack/pack as anything in candidates)
		if(length(bundle.source_packs) >= wanted)
			break
		var/pack_value = seller.pack_price(pack) - pack.market_packaging(null, pack.market_total())
		if(value + pack_value > BUNDLE_VALUE_MAX || !bundle.take_access(pack))
			continue
		value += pack_value
		bundle.source_packs += pack
		bundle.pack_names += pack.name
		if(!bundle.need && needs[pack.type])
			bundle.need = "[pack.name] - [needs[pack.type]]"
	if(length(bundle.source_packs) < BUNDLE_PACKS_MIN)
		qdel(bundle)
		return null
	bundle.uid = ++bundle_uid
	bundle.seller_id = seller.id
	bundle.department_id = department_id
	bundle.contains = list()
	for(var/datum/supply_pack/pack as anything in bundle.source_packs)
		bundle.contains += pack.contains
	bundle.full_value = round(value + econ_packaging_value(bundle.crate_type))
	bundle.discount = rand(BUNDLE_DISCOUNT_MIN, BUNDLE_DISCOUNT_MAX)
	bundle.price = max(1, round(bundle.full_value * (100 - bundle.discount) / 100))
	bundle.cost = bundle.price
	bundle.expires_at = world.time + BUNDLE_LIFETIME
	bundle.name = "Скупка для [econ_bundle_whom(department_id)]: [jointext(bundle.pack_names, ", ")]"
	bundle.desc = "Только целиком, у \"[seller.name]\"."
	bundle.crate_name = "ящик скупки для [econ_bundle_whom(department_id)]"
	bundles += bundle
	log_econ("Скупка #[bundle.uid] у [seller.name] для [department.name]: [jointext(bundle.pack_names, ", ")] за [bundle.price] кр. вместо [bundle.full_value]")
	announce_bundle(bundle)
	return bundle

/// Строка о новой пачке в канал её отдела, не чаще BUNDLE_RADIO_COOLDOWN на отдел. Возвращает сообщение или null.
/datum/controller/subsystem/market/proc/announce_bundle(datum/supply_pack/bundle/bundle)
	var/datum/economy_department/department = SSeconomy.get_department(bundle.department_id)
	var/channel = GLOB.econ_department_radio[bundle.department_id]
	if(!department || !channel || !COOLDOWN_FINISHED(department, bundle_notice_cooldown))
		return null
	COOLDOWN_START(department, bundle_notice_cooldown, BUNDLE_RADIO_COOLDOWN)
	var/datum/trade_partner/seller = get_partner(bundle.seller_id)
	. = "[bundle.name]. У \"[seller?.name]\" за [bundle.price] кр. вместо [bundle.full_value], только целиком и ещё [round(BUNDLE_LIFETIME / (1 MINUTES))] мин.[bundle.need ? " Нужно сейчас: [bundle.need]." : ""] Взять за бюджет отдела может глава, ГП или капитан в \"Бюджете отдела\" на КПК или в окне снабжения."
	paperwork_radio(., channel)

/datum/controller/subsystem/market/proc/bundle_by_uid(uid)
	for(var/datum/supply_pack/bundle/bundle as anything in bundles)
		if(bundle.uid == uid)
			return bundle

/// Продавец пачки, если он сейчас может её продать: открыт и не под эмбарго; иначе null.
/proc/econ_bundle_seller(datum/supply_pack/bundle/bundle)
	var/datum/trade_partner/seller = SSmarket.get_partner(bundle.seller_id)
	return (seller?.unlocked && !seller.embargoed()) ? seller : null

/// Отдел, для которого собрана пачка скупки; не пачка - null.
/proc/econ_bundle_department(datum/supply_pack/pack)
	var/datum/supply_pack/bundle/bundle = pack
	return istype(bundle) ? bundle.department_id : null

/// Покупка пачки за бюджет её отдела: как заказ пака каталога главой - глава отдела, ГП или капитан, деньги списываются сразу. Возвращает list(успех, ответ).
/proc/econ_bundle_buy_for_department(mob/living/user, datum/supply_pack/bundle/bundle)
	if(!bundle || !(bundle in SSmarket.bundles))
		return list(FALSE, "Эту пачку уже забрали или сняли.")
	var/datum/economy_department/department = SSeconomy.get_department(bundle.department_id)
	if(!department)
		return list(FALSE, "Эта пачка ни для какого отдела: её берут снабжение или лично.")
	if(!econ_bundle_seller(bundle))
		return list(FALSE, "Партнёр под эмбарго: пачку можно будет купить, когда его снимут.")
	if(!department.can_manage(user))
		return list(FALSE, "За [department.budget_name] пачку берёт глава отдела, ГП или капитан: нужна их ID-карта.")
	var/datum/supply_order/order = department.order_pack(bundle, user, "Скупка для отдела \"[department.name]\"")
	if(!order)
		return list(FALSE, "В бюджете не хватает денег: пачка стоит [bundle.price] кр., в бюджете [department.account.account_balance] кр.")
	SSmarket.bundles -= bundle
	order.partner_id = bundle.seller_id
	log_econ("[key_name(user)] берёт скупку #[bundle.uid] за [bundle.price] кр. из бюджета отдела [department.name]")
	return list(TRUE, "Пачка в корзине снабжения: [bundle.price] кр. списано, [department.budget_name] сэкономил [bundle.full_value - bundle.price] кр.")

/// Покупка пачки из окна снабжения: за бюджет её отдела (budget) - глава, ГП или капитан; за бюджет снабжения - снабжение; или лично. Заявкой скупку не взять, у партнёра под эмбарго - тоже. Пачка уходит в корзину и пропадает из скупки.
/proc/econ_cargo_buy_bundle(mob/user, list/params, atom/movable/speaker, self_paid, can_buy_for_cargo, show_contraband = FALSE)
	var/uid = params["uid"]
	if(istext(uid))
		uid = text2num(uid)
	var/datum/supply_pack/bundle/bundle = SSmarket.bundle_by_uid(uid)
	if(!bundle)
		speaker.say("Эту пачку уже забрали или сняли.")
		return FALSE
	if(params["budget"])
		var/list/result = econ_bundle_buy_for_department(user, bundle)
		speaker.say(result[2])
		return result[1]
	if(!econ_bundle_seller(bundle))
		speaker.say("Партнёр под эмбарго: пачку можно будет купить, когда его снимут.")
		return FALSE
	if(!self_paid && !can_buy_for_cargo)
		speaker.say("За бюджет снабжения скупку берёт только снабжение. Пачку для отдела берёт за его бюджет глава, ГП или капитан, лично - любой.")
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

/// Скупка для окон снабжения и бюджета отдела (only_department - только пачки этого отдела); can_budget - user может взять пачку за бюджет её отдела.
/proc/econ_bundles_ui_data(mob/living/user, only_department)
	. = list()
	for(var/datum/supply_pack/bundle/bundle as anything in SSmarket.bundles)
		if(only_department && bundle.department_id != only_department)
			continue
		var/datum/trade_partner/seller = SSmarket.get_partner(bundle.seller_id)
		var/datum/economy_department/department = SSeconomy.get_department(bundle.department_id)
		. += list(list(
			"uid" = bundle.uid,
			"partner" = seller?.name,
			"partner_id" = bundle.seller_id,
			"department" = department?.name,
			"whom" = econ_bundle_whom(bundle.department_id),
			"packs" = bundle.pack_names,
			"need" = bundle.need,
			"full_value" = bundle.full_value,
			"price" = bundle.price,
			"discount" = bundle.discount,
			"embargoed" = !econ_bundle_seller(bundle),
			"left" = max(0, CEILING((bundle.expires_at - world.time) / (1 SECONDS), 1)),
			"can_budget" = !!department?.can_manage(user),
		))
