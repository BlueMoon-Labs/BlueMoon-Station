/// Все 23 товара загружены из конфига при инициализации SSmarket, с русскими названиями.
/datum/unit_test/economy_market_commodities/Run()
	var/list/ids = list(COMMODITY_METALS, COMMODITY_PRECIOUS, COMMODITY_PLASMA, COMMODITY_CRYSTALS, COMMODITY_GASES, COMMODITY_ENERGY, COMMODITY_FOOD, COMMODITY_DRINKS, COMMODITY_MEDICINE, COMMODITY_CHEMICALS, COMMODITY_ELECTRONICS, COMMODITY_MACHINERY, COMMODITY_ROBOTICS, COMMODITY_WEAPONS, COMMODITY_TEXTILES, COMMODITY_LUXURY, COMMODITY_BIOMATERIALS, COMMODITY_ARTIFACTS, COMMODITY_SEEDS, COMMODITY_CONSTRUCTION, COMMODITY_FUEL, COMMODITY_CULTURE, COMMODITY_CONTRABAND)
	TEST_ASSERT_EQUAL(length(SSmarket.commodities), length(ids), "Число товаров рынка")
	for(var/id in ids)
		var/datum/commodity/commodity = SSmarket.get_commodity(id)
		TEST_ASSERT_NOTNULL(commodity, "Нет товара [id]")
		TEST_ASSERT_EQUAL(commodity.id, id, "id товара")
		TEST_ASSERT_NOTEQUAL(commodity.name, id, "Название товара [id] не задано")

/// Подменяет рынок свежей копией из конфига репозитория (все цены 1, спрос полный, канал сводки молчит); вернуть - econ_test_restore_market().
/proc/econ_test_swap_market()
	. = list(
		"commodities" = SSmarket.commodities,
		"price_index" = SSmarket.price_index,
		"next_shift" = SSmarket.next_shift,
		"shift_count" = SSmarket.shift_count,
		"shift_minutes" = SSmarket.shift_minutes,
		"hot_chance" = SSmarket.hot_chance,
		"partners" = SSmarket.partners,
		"partner_restock_minutes" = SSmarket.partner_restock_minutes,
		"partner_stock_default" = SSmarket.partner_stock_default,
		"reputation_per_credit" = SSmarket.reputation_per_credit,
		"next_restock" = SSmarket.next_restock,
		"offer_minutes" = SSmarket.offer_minutes,
		"offers_max" = SSmarket.offers_max,
		"offer_chance" = SSmarket.offer_chance,
		"offer_deadline_minutes" = SSmarket.offer_deadline_minutes,
		"next_offers" = SSmarket.next_offers,
		"companies" = SSmarket.companies,
		"scheduled_events" = SSmarket.scheduled_events,
		"station_events" = SSmarket.station_events,
		"company_event_templates" = SSmarket.company_event_templates,
		"company_event_chance" = SSmarket.company_event_chance,
		"station_event_cooldowns" = SSmarket.station_event_cooldowns,
		"recent_trades" = SSmarket.recent_trades,
		"press_release_ready_at" = SSmarket.press_release_ready_at,
		"press_released" = SSmarket.press_released,
		"digest_minutes" = SSmarket.digest_minutes,
		"news_flash_minutes" = SSmarket.news_flash_minutes,
		"next_digest" = SSmarket.next_digest,
		"last_news" = SSmarket.last_news,
		"pending_news" = SSmarket.pending_news,
		"pending_hot" = SSmarket.pending_hot,
		"news_published" = SSmarket.news_published,
		"last_digest_key" = SSmarket.last_digest_key,
		"persist_decay" = SSmarket.persist_decay,
		"contraband_message" = SSmarket.contraband_message,
	)
	var/datum/news/feed_channel/channel = SSmarket.news_channel()
	.["news_messages"] = channel.messages.Copy()
	SSmarket.commodities = list()
	SSmarket.partners = list()
	SSmarket.companies = list()
	SSmarket.scheduled_events = list()
	SSmarket.station_event_cooldowns = list()
	SSmarket.recent_trades = list()
	SSmarket.press_release_ready_at = 0
	SSmarket.press_released = list()
	SSmarket.price_index = 1
	SSmarket.pending_news = list()
	SSmarket.pending_hot = list()
	SSmarket.next_digest = 0
	SSmarket.last_news = world.time
	SSmarket.last_digest_key = null
	SSmarket.contraband_message = ""
	SSmarket.load_settings(SSeconomy.settings.raw?["market"])

/proc/econ_test_restore_market(list/saved)
	if(!saved)
		return
	QDEL_LIST_ASSOC_VAL(SSmarket.commodities)
	QDEL_LIST_ASSOC_VAL(SSmarket.partners)
	QDEL_LIST(SSmarket.scheduled_events)
	QDEL_LIST_ASSOC_VAL(SSmarket.companies)
	var/datum/news/feed_channel/channel = SSmarket.news_channel()
	channel.messages = saved["news_messages"]
	saved -= "news_messages"
	for(var/var_name in saved)
		SSmarket.vars[var_name] = saved[var_name]
	INVOKE_ASYNC(SSmarket, TYPE_PROC_REF(/datum/controller/subsystem/market, refresh_vending_prices))

/// Худший для петель случай партнёров на подменённом рынке: все открыты, у всех высшая ступень скидки.
/proc/econ_test_partner_extremes()
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		partner.unlocked = TRUE
		partner.reputation = PARTNER_REPUTATION_MAX

/// Пак со взрывающимся в Destroy() содержимым: скан его не открывает, отложенный взрыв попал бы в арену следующих тестов.
/proc/econ_test_explodes_on_delete(datum/supply_pack/pack)
	var/static/list/explosive_types = typecacheof(list(
		/obj/machinery/satellite,
		/obj/vehicle/sealed/car,
		/obj/structure/checkoutmachine,
	))
	for(var/item in pack.contains)
		if(explosive_types[item])
			return TRUE
	return FALSE

/// Убирает с турфа всё, что скан оставил после пака или дизайна: высыпанное из ящиков, заспавненное позже.
/proc/econ_test_clear_turf(turf/scan_turf)
	for(var/atom/movable/leftover in scan_turf)
		if(!istype(leftover, /obj/effect/landmark))
			qdel(leftover)

/// Тесты на изолированной копии рынка из конфига репозитория, состояние SSmarket возвращается.
/datum/unit_test/economy_market
	abstract_type = /datum/unit_test/economy_market
	var/list/saved_market
	var/hot_signals = 0
	var/shift_signals = 0

/datum/unit_test/economy_market/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	SSmarket.next_restock = world.time + 1 HOURS
	SSmarket.next_offers = world.time + 1 HOURS
	RegisterSignal(SSmarket, COMSIG_MARKET_HOT, PROC_REF(on_hot))
	RegisterSignal(SSmarket, COMSIG_MARKET_SHIFTED, PROC_REF(on_shifted))

/datum/unit_test/economy_market/Destroy()
	UnregisterSignal(SSmarket, list(COMSIG_MARKET_HOT, COMSIG_MARKET_SHIFTED))
	econ_test_restore_market(saved_market)
	rand_seed(world.realtime + world.timeofday)
	return ..()

/datum/unit_test/economy_market/proc/on_hot(datum/source, datum/commodity/commodity)
	SIGNAL_HANDLER
	hot_signals++

/datum/unit_test/economy_market/proc/on_shifted(datum/source)
	SIGNAL_HANDLER
	shift_signals++

/// Секция market из economy.json репозитория грузится без ошибок.
/datum/unit_test/economy_market/repo_config/Run()
	var/list/errors = SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	TEST_ASSERT(!length(errors), "economy.json market: [jointext(errors, "; ")]")
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	TEST_ASSERT(abs(contraband.demand_capacity - 5000) < 0.1, "Ёмкость спроса контрабанды из конфига")
	var/datum/commodity/food = SSmarket.get_commodity(COMMODITY_FOOD)
	TEST_ASSERT(food.consumer, "Продукты в корзине индекса")
	TEST_ASSERT(abs(food.links[COMMODITY_DRINKS] - 0.3) < 0.01, "Связь продуктов с напитками")

/// Битая секция market пишет ошибки и оставляет встроенные дефолты, мир не падает.
/datum/unit_test/economy_market/bad_config/Run()
	var/list/errors = SSmarket.load_settings("мусор")
	TEST_ASSERT(length(errors), "Секция не объект - ошибка")
	TEST_ASSERT_EQUAL(length(SSmarket.commodities), 23, "Встроенные товары при битой секции")
	var/default_minutes = initial(SSmarket.shift_minutes)
	var/default_hot = initial(SSmarket.hot_chance)
	var/list/bad = list(
		"shift_minutes" = 0,
		"hot_chance" = 500,
		"partners" = list(),
		"commodities" = list(
			COMMODITY_METALS = list("volatility" = -1, "links" = list("nope" = 0.3)),
			"unobtainium" = list("name" = "Анобтаниум"),
			COMMODITY_FOOD = "плохо",
			COMMODITY_CONTRABAND = list("demand_capacity" = 0),
			COMMODITY_TEXTILES = list("consumer" = "да"),
		),
	)
	errors = SSmarket.load_settings(bad)
	TEST_ASSERT_EQUAL(length(errors), 8, "Ошибки: интервал, шанс, волатильность, связь, неизвестный товар, не объект, ёмкость, флаг корзины ([jointext(errors, "; ")])")
	var/datum/commodity/textiles = SSmarket.get_commodity(COMMODITY_TEXTILES)
	TEST_ASSERT(textiles.consumer == TRUE, "Неверный флаг корзины затёр встроенный")
	TEST_ASSERT_EQUAL(SSmarket.shift_minutes, default_minutes, "Нулевой интервал сдвига принят")
	TEST_ASSERT_EQUAL(SSmarket.hot_chance, default_hot, "Шанс выше 100 принят")
	TEST_ASSERT_EQUAL(length(SSmarket.commodities), 23, "Неизвестный товар добавлен")
	TEST_ASSERT_NULL(SSmarket.get_commodity("unobtainium"), "Неизвестный товар добавлен")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	TEST_ASSERT(metals.volatility > 0, "Отрицательная волатильность принята")
	TEST_ASSERT(!("nope" in metals.links), "Связь с несуществующим товаром принята")
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	TEST_ASSERT(contraband.demand_capacity > 0, "Нулевая ёмкость спроса принята")
	errors = SSmarket.load_settings(list("commodities" = "плохо", "partners" = list()))
	TEST_ASSERT_EQUAL(length(errors), 1, "commodities не объект - одна ошибка")
	TEST_ASSERT_EQUAL(length(SSmarket.commodities), 23, "Встроенные товары при битом списке")

/// Встроенные дефолты рынка совпадают с секцией market из economy.json репозитория поле за полем.
/datum/unit_test/economy_market/defaults_match_config/Run()
	SSmarket.load_settings(list())
	var/list/builtin = snapshot_params()
	SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	var/list/configured = snapshot_params()
	TEST_ASSERT_EQUAL(length(builtin), length(configured), "Число параметров")
	for(var/key in configured)
		TEST_ASSERT_EQUAL(builtin[key], configured[key], "Встроенное [key] расходится с economy.json")

/datum/unit_test/economy_market/proc/snapshot_params()
	. = list("shift_minutes" = "[SSmarket.shift_minutes]", "hot_chance" = "[SSmarket.hot_chance]", "digest_minutes" = "[SSmarket.digest_minutes]", "news_flash_minutes" = "[SSmarket.news_flash_minutes]")
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		var/list/link_texts = list()
		for(var/linked_id in commodity.links)
			link_texts += "[linked_id]=[commodity.links[linked_id]]"
		.[id] = "[commodity.name]|[commodity.volatility]|[commodity.demand_capacity]|[commodity.demand_recovery]|[commodity.consumer]|[jointext(link_texts, ",")]"

/// Входящая доля связей в товар не больше 1: лишняя связь отбрасывается с ошибкой, тренды цикла затухают.
/datum/unit_test/economy_market/link_inbound/Run()
	var/list/section = list("partners" = list(), "commodities" = list(
		COMMODITY_CRYSTALS = list("links" = list(COMMODITY_GASES = 1)),
		COMMODITY_WEAPONS = list("links" = list(COMMODITY_GASES = 1)),
		COMMODITY_GASES = list("links" = list(COMMODITY_CRYSTALS = 1, COMMODITY_WEAPONS = 1)),
	))
	var/list/errors = SSmarket.load_settings(section)
	TEST_ASSERT_EQUAL(length(errors), 1, "Одна лишняя связь в газы ([jointext(errors, "; ")])")
	var/list/inbound = list()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		for(var/linked_id in commodity.links)
			inbound[linked_id] += commodity.links[linked_id]
	for(var/linked_id in inbound)
		TEST_ASSERT(round(inbound[linked_id], 0.001) <= MARKET_LINK_INBOUND_MAX, "Входящая доля в [linked_id]: [inbound[linked_id]]")
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.volatility = 0
		commodity.trend = MARKET_PRICE_MAX
	SSmarket.hot_chance = 0
	for(var/i in 1 to 300)
		SSmarket.market_shift()
	for(var/id in list(COMMODITY_CRYSTALS, COMMODITY_WEAPONS, COMMODITY_GASES))
		var/datum/commodity/commodity = SSmarket.get_commodity(id)
		TEST_ASSERT(commodity.trend < 1.2, "Тренд [id] заперт связями: [commodity.trend]")

/// 500 сдвигов с фиксированным сидом: цены в коридоре, тренд возвращается к 1.
/datum/unit_test/economy_market/bounded/Run()
	rand_seed(4242)
	var/datum/commodity/commodity = new
	commodity.volatility = 0.08
	var/trend_sum = 0
	for(var/i in 1 to 500)
		commodity.shift(0)
		TEST_ASSERT(commodity.price_factor >= MARKET_PRICE_MIN && commodity.price_factor <= MARKET_PRICE_MAX, "Цена вне коридора: [commodity.price_factor]")
		trend_sum += commodity.trend
	TEST_ASSERT(length(commodity.history) <= MARKET_HISTORY_MAX, "История длиннее [MARKET_HISTORY_MAX]")
	qdel(commodity)
	var/mean = trend_sum / 500
	TEST_ASSERT(mean > 0.85 && mean < 1.15, "Тренд не уходит от 1: среднее [mean]")

/// Продажа истощает спрос и снижает цену продажи; сдвиги его восстанавливают.
/datum/unit_test/economy_market/demand/Run()
	var/datum/commodity/commodity = new
	commodity.volatility = 0
	commodity.demand_capacity = 1000
	commodity.demand_recovery = 0.25
	var/fresh = commodity.sell_factor()
	commodity.note_sale(800)
	var/depleted = commodity.sell_factor()
	TEST_ASSERT(depleted < fresh, "Цена не упала после продажи")
	var/expected_ratio = MARKET_DEMAND_FLOOR + (1 - MARKET_DEMAND_FLOOR) * 0.2
	TEST_ASSERT(abs(depleted / fresh - expected_ratio) < 0.01, "Цена продажи после выбитого спроса: [depleted / fresh] вместо [expected_ratio]")
	TEST_ASSERT(abs(commodity.buy_factor() - fresh) < 0.01, "Спрос не влияет на цену закупки")
	commodity.note_sale(100000)
	TEST_ASSERT(commodity.demand >= 0, "Спрос ушёл в минус")
	TEST_ASSERT(commodity.sell_factor() > 0, "Цена продажи без спроса не нулевая")
	for(var/i in 1 to 4)
		commodity.shift(0)
	TEST_ASSERT(abs(commodity.demand - 1) < 0.001, "Спрос не восстановился: [commodity.demand]")
	qdel(commodity)

/// Горячий товар дороже на продажу, не перегревается повторно и остывает за 2-4 сдвига.
/datum/unit_test/economy_market/hot/Run()
	var/datum/commodity/commodity = new
	commodity.volatility = 0
	commodity.shift(100)
	TEST_ASSERT(commodity.hot_mult >= MARKET_HOT_MULT_MIN && commodity.hot_mult <= MARKET_HOT_MULT_MAX, "Не стал горячим: [commodity.hot_mult]")
	TEST_ASSERT_EQUAL(hot_signals, 1, "Сигнал горячего товара")
	TEST_ASSERT(commodity.sell_factor() > commodity.buy_factor() * 1.4, "Горячий товар не дороже на продажу")
	commodity.shift(100)
	TEST_ASSERT_EQUAL(hot_signals, 1, "Горячий товар перегрелся повторно")
	TEST_ASSERT(commodity.hot_mult > 1, "Остыл раньше двух сдвигов")
	for(var/i in 1 to MARKET_HOT_SHIFTS_MAX - 1)
		commodity.shift(0)
	TEST_ASSERT(abs(commodity.hot_mult - 1) < 0.001, "Не остыл: [commodity.hot_mult]")
	TEST_ASSERT_EQUAL(commodity.hot_shifts_left, 0, "Счётчик горячих сдвигов")
	qdel(commodity)

/// Индекс цен плавно идёт к корзине потребительских товаров и держится в своём коридоре.
/datum/unit_test/economy_market/index/Run()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.price_factor = MARKET_PRICE_MAX
	SSmarket.recompute_price_index()
	var/expected = 1 + (MARKET_INDEX_MAX - 1) * MARKET_INDEX_SMOOTHING
	TEST_ASSERT(abs(SSmarket.price_index - expected) < 0.01, "Сглаживание индекса: [SSmarket.price_index] вместо [expected]")
	for(var/i in 1 to 30)
		SSmarket.recompute_price_index()
	TEST_ASSERT(SSmarket.price_index <= MARKET_INDEX_MAX, "Индекс выше потолка: [SSmarket.price_index]")
	TEST_ASSERT(SSmarket.price_index > MARKET_INDEX_MAX - 0.01, "Индекс не дошёл до потолка: [SSmarket.price_index]")
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.price_factor = MARKET_PRICE_MIN
	for(var/i in 1 to 30)
		SSmarket.recompute_price_index()
	TEST_ASSERT(SSmarket.price_index >= MARKET_INDEX_MIN, "Индекс ниже пола: [SSmarket.price_index]")
	TEST_ASSERT(SSmarket.price_index < MARKET_INDEX_MIN + 0.01, "Индекс не дошёл до пола: [SSmarket.price_index]")

/// Рост тренда товара тянет связанные товары, несвязанные стоят.
/datum/unit_test/economy_market/links/Run()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.volatility = 0
	SSmarket.hot_chance = 0
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.trend = 2
	SSmarket.market_shift()
	var/datum/commodity/construction = SSmarket.get_commodity(COMMODITY_CONSTRUCTION)
	var/datum/commodity/culture = SSmarket.get_commodity(COMMODITY_CULTURE)
	TEST_ASSERT(construction.trend > 1.01, "Стройматериалы не потянулись за металлами: [construction.trend]")
	TEST_ASSERT(abs(culture.trend - 1) < 0.001, "Культура сдвинулась без связи: [culture.trend]")
	TEST_ASSERT(metals.trend < 2, "Тренд металлов не возвращается к 1: [metals.trend]")

/// Сдвиг рынка по таймеру подсистемы: счётчик, сигнал, следующий сдвиг с разбросом.
/datum/unit_test/economy_market/fire/Run()
	var/count = SSmarket.shift_count
	SSmarket.next_shift = 0
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.shift_count, count, "Первый fire после лобби сразу сдвинул рынок")
	TEST_ASSERT(abs(SSmarket.next_shift - (world.time + SSmarket.shift_minutes MINUTES)) < 1, "Первый сдвиг не взведён от первого fire: [SSmarket.next_shift]")
	SSmarket.next_shift = world.time + 1 MINUTES
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.shift_count, count, "Рынок сдвинулся раньше срока")
	SSmarket.next_shift = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.shift_count, count + 1, "Рынок не сдвинулся в срок")
	TEST_ASSERT_EQUAL(shift_signals, 1, "Сигнал сдвига рынка")
	var/delay = SSmarket.next_shift - world.time
	var/base = SSmarket.shift_minutes MINUTES
	TEST_ASSERT(delay >= base - MARKET_SHIFT_JITTER && delay <= base + MARKET_SHIFT_JITTER, "Следующий сдвиг через [delay] дс")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	TEST_ASSERT_EQUAL(length(metals.history), 1, "Точка истории за сдвиг")

/// 500 сдвигов с горячими товарами на каждом шаге: цены, тренды и индекс в коридорах, контрабанда горячей не бывает.
/datum/unit_test/economy_market/long_run/Run()
	SSmarket.hot_chance = 100
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	for(var/i in 1 to 500)
		SSmarket.market_shift()
		TEST_ASSERT_EQUAL(contraband.hot_mult, 1, "Контрабанда стала горячей на сдвиге [i]")
		TEST_ASSERT(SSmarket.price_index >= MARKET_INDEX_MIN && SSmarket.price_index <= MARKET_INDEX_MAX, "Индекс вне коридора на сдвиге [i]: [SSmarket.price_index]")
		for(var/id in SSmarket.commodities)
			var/datum/commodity/commodity = SSmarket.commodities[id]
			TEST_ASSERT(commodity.price_factor >= MARKET_PRICE_MIN && commodity.price_factor <= MARKET_PRICE_MAX, "Цена [id] вне коридора на сдвиге [i]: [commodity.price_factor]")
			TEST_ASSERT(commodity.trend >= MARKET_PRICE_MIN && commodity.trend <= MARKET_PRICE_MAX, "Тренд [id] вне коридора на сдвиге [i]: [commodity.trend]")
			var/sell = commodity.sell_factor()
			TEST_ASSERT(sell >= MARKET_PRICE_MIN * MARKET_DEMAND_FLOOR && sell <= MARKET_PRICE_MAX, "Цена продажи [id] вне коридора на сдвиге [i]: [sell]")
	TEST_ASSERT_EQUAL(shift_signals, 500, "Сигнал на каждый сдвиг")
	TEST_ASSERT(hot_signals > 23, "Горячие товары при шансе 100: [hot_signals]")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	TEST_ASSERT_EQUAL(length(metals.history), MARKET_HISTORY_MAX, "История обрезается до [MARKET_HISTORY_MAX]")
