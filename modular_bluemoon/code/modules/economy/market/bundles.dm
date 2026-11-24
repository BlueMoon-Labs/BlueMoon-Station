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
	/// Тип пака пачки из "нужно сейчас" отдела; почему нужен, берёт need_reason() живьём. Пусто - пачка на каждый день
	var/need_pack
	/// До этого world.time пачку берут только за бюджет её отдела; 0 - окна нет или оно прошло
	var/department_until = 0
	/// Кто и как взял пачку: "имя (должность) лично"
	var/taken_by

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

/// Почему need_pack нужен отделу сейчас; нужда прошла - null.
/datum/supply_pack/bundle/proc/need_reason()
	if(!need_pack)
		return null
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	return department?.needs_now()[need_pack]

/// Цена пачки лично: с наценкой частного заказа, округлённая так же, как списание при доставке.
/datum/supply_pack/bundle/proc/private_price()
	return round(price * ECON_PRIVATE_ORDER_MARKUP)

/// Сколько ещё пачку берут только за бюджет её отдела, в децисекундах.
/datum/supply_pack/bundle/proc/department_left()
	return max(0, department_until - world.time)

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
		else if(bundle.department_until && !bundle.department_left())
			bundle.department_until = 0
			log_econ("Скупка #[bundle.uid] открыта снабжению и для личной покупки")
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
		if(!pack.can_private_buy)
			bundle.can_private_buy = FALSE
		if(!bundle.need_pack && needs[pack.type])
			bundle.need_pack = pack.type
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
	if(department.has_approver_on_shift())
		bundle.department_until = world.time + BUNDLE_DEPARTMENT_FIRST
	bundle.name = "Скупка для [econ_bundle_whom(department_id)]: [jointext(bundle.pack_names, ", ")]"
	bundle.desc = "Только целиком, у \"[seller.name]\"."
	bundle.crate_name = "ящик скупки для [econ_bundle_whom(department_id)]"
	bundles += bundle
	// Окно отдела - только когда отдел о пачке услышал
	if(!announce_bundle(bundle))
		bundle.department_until = 0
	log_econ("Скупка #[bundle.uid] у [seller.name] для [department.name]: [jointext(bundle.pack_names, ", ")] за [bundle.price] кр. вместо [bundle.full_value][bundle.department_until ? ", первые [round(BUNDLE_DEPARTMENT_FIRST / (1 MINUTES))] мин. - только за бюджет отдела" : ""][bundle.can_private_buy ? "" : ", лично не купить"]")
	return bundle

/// Строка о новой пачке в канал её отдела и на карты его начальства на смене, не чаще BUNDLE_RADIO_COOLDOWN на отдел. Возвращает сообщение или null.
/datum/controller/subsystem/market/proc/announce_bundle(datum/supply_pack/bundle/bundle)
	var/datum/economy_department/department = SSeconomy.get_department(bundle.department_id)
	var/channel = GLOB.econ_department_radio[bundle.department_id]
	if(!department || !channel || !COOLDOWN_FINISHED(department, bundle_notice_cooldown))
		return null
	COOLDOWN_START(department, bundle_notice_cooldown, BUNDLE_RADIO_COOLDOWN)
	var/datum/trade_partner/seller = get_partner(bundle.seller_id)
	var/datum/supply_pack/needed = SSshuttle.supply_packs[bundle.need_pack]
	var/reason = bundle.need_reason()
	var/first = bundle.department_until ? " Первые [round(BUNDLE_DEPARTMENT_FIRST / (1 MINUTES))] мин. она только для отдела." : ""
	. = "[bundle.name]. У \"[seller?.name]\" за [bundle.price] кр. вместо [bundle.full_value], только целиком и ещё [round(BUNDLE_LIFETIME / (1 MINUTES))] мин.[reason ? " Нужно сейчас: [needed.name] - [reason]." : ""] Взять за бюджет отдела может глава, ГП или капитан в \"Бюджете отдела\" на КПК или в окне снабжения.[first]"
	paperwork_radio(., channel)
	for(var/datum/bank_account/manager_account as anything in department.managers_on_shift())
		manager_account.bank_card_talk(.)

/// Канал отдела пачки слышит, как её взяли: how - "за бюджет отдела", "за бюджет снабжения" или "лично". За бюджет - и кто, по ID-карте из заказа; личного покупателя не называют.
/proc/econ_bundle_taken(datum/supply_pack/bundle/bundle, datum/supply_order/order, how)
	var/channel = GLOB.econ_department_radio[bundle.department_id]
	if(how == "лично")
		bundle.taken_by = how
		if(channel)
			paperwork_radio("Пачку скупки для [econ_bundle_whom(bundle.department_id)] взяли лично.", channel)
		return
	var/static/list/no_name = list("Unknown", "*None Provided*")
	var/static/list/no_rank = list("No id", "No job", "*None Provided*")
	var/who = length(order.orderer) && !(order.orderer in no_name) ? order.orderer : "без имени на ID-карте"
	var/rank = length(order.orderer_rank) && !(order.orderer_rank in no_rank) ? order.orderer_rank : null
	bundle.taken_by = "[who][rank ? " ([rank])" : ""] [how]"
	if(channel)
		paperwork_radio("Пачку скупки для [econ_bundle_whom(bundle.department_id)] взяли [how]: [who][rank ? ", [rank]" : ""].", channel)

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
	econ_bundle_taken(bundle, order, "за бюджет отдела")
	return list(TRUE, "Пачка в корзине снабжения: [bundle.price] кр. списано, [department.budget_name] сэкономил [bundle.full_value - bundle.price] кр.")

/// Покупка пачки из окна снабжения: за бюджет её отдела (budget) - глава, ГП или капитан; за бюджет снабжения - снабжение; или лично, если все её паки продаются лично и на счёте хватает на цену с наценкой частного заказа.
/// Пока идёт окно department_left(), только за бюджет отдела. Заявкой скупку не взять, у партнёра под эмбарго - тоже. Пачка уходит в корзину и пропадает из скупки.
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
		speaker.say("За бюджет снабжения скупку берёт только снабжение. Пачку для отдела берёт за его бюджет глава, ГП или капитан, лично - любой, если в ней нет паков, которые лично не продаются.")
		return FALSE
	var/first_left = bundle.department_left()
	if(first_left)
		var/datum/economy_department/department = SSeconomy.get_department(bundle.department_id)
		speaker.say("Первые [round(BUNDLE_DEPARTMENT_FIRST / (1 MINUTES))] мин. эту пачку берут только за [department?.budget_name || "бюджет её отдела"]: снабжению и лично она откроется через [CEILING(first_left / (1 MINUTES), 1)] мин.")
		return FALSE
	var/datum/bank_account/account
	if(self_paid)
		if(!bundle.can_private_buy)
			speaker.say("В этой пачке есть паки, которые лично не продаются: её берут за бюджет отдела или снабжения.")
			return FALSE
		account = econ_cargo_private_account(user, speaker)
		if(!account)
			return FALSE
		var/private_price = bundle.private_price()
		if(!account.has_money(private_price))
			speaker.say("На счёте не хватает: лично пачка стоит [private_price] кр. с наценкой частного заказа, на счёте [account.account_balance] кр.")
			return FALSE
	SSmarket.bundles -= bundle
	var/datum/supply_order/order = econ_cargo_new_order(user, bundle, "", account, FALSE)
	order.partner_id = bundle.seller_id
	order.contraband_supply = show_contraband
	speaker.say(account ? "Пачка скупки в корзине: [bundle.private_price()] кр. с наценкой частного заказа, оплата со счёта [account.account_holder] при доставке." : "Пачка скупки в корзине: [bundle.price] кр.")
	log_econ("[key_name(user)] берёт скупку #[bundle.uid] за [bundle.price] кр.[account ? " лично" : ""]")
	econ_bundle_taken(bundle, order, account ? "лично" : "за бюджет снабжения")
	return TRUE

/// Скупка для окон снабжения и бюджета отдела (only_department - только пачки этого отдела); can_budget - user может взять пачку за бюджет её отдела.
/// need - пак, который отделу нужен сейчас; почему нужен (need_why) видят окно бюджета, сотрудники отдела и те, кто берёт пачку за его бюджет: в причине бывают данные датчиков.
/proc/econ_bundles_ui_data(mob/living/user, only_department)
	. = list()
	var/datum/bank_account/user_account = econ_account_of(user)
	var/user_department = user_account?.department_id
	for(var/datum/supply_pack/bundle/bundle as anything in SSmarket.bundles)
		if(only_department && bundle.department_id != only_department)
			continue
		var/datum/trade_partner/seller = SSmarket.get_partner(bundle.seller_id)
		var/datum/economy_department/department = SSeconomy.get_department(bundle.department_id)
		var/can_budget = !!department?.can_manage(user)
		var/reason = bundle.need_reason()
		var/datum/supply_pack/needed = reason && SSshuttle.supply_packs[bundle.need_pack]
		. += list(list(
			"uid" = bundle.uid,
			"partner" = seller?.name,
			"partner_id" = bundle.seller_id,
			"department" = department?.name,
			"whom" = econ_bundle_whom(bundle.department_id),
			"packs" = bundle.pack_names,
			"need" = needed?.name,
			"need_why" = (needed && (only_department || can_budget || user_department == bundle.department_id)) ? reason : null,
			"full_value" = bundle.full_value,
			"price" = bundle.price,
			"private_price" = bundle.private_price(),
			"discount" = bundle.discount,
			"embargoed" = !econ_bundle_seller(bundle),
			"left" = max(0, CEILING((bundle.expires_at - world.time) / (1 SECONDS), 1)),
			"can_budget" = can_budget,
			"private_ok" = bundle.can_private_buy,
			"department_left" = CEILING(bundle.department_left() / (1 SECONDS), 1),
		))
