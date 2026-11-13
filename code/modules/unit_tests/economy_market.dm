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
		"slot_jackpot" = SSmarket.slot_jackpot,
		"slot_jackpot_carried" = SSmarket.slot_jackpot_carried,
		"auction" = SSmarket.auction,
		"next_auction_at" = SSmarket.next_auction_at,
		"auction_results" = SSmarket.auction_results,
		"auction_drop_turf" = SSmarket.auction_drop_turf,
		"crew_lots" = SSmarket.crew_lots,
		"auction_announce_ready_at" = SSmarket.auction_announce_ready_at,
		"bundles" = SSmarket.bundles,
		"next_bundle_at" = SSmarket.next_bundle_at,
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
	SSmarket.slot_jackpot = 0
	SSmarket.slot_jackpot_carried = 0
	SSmarket.auction = null
	SSmarket.next_auction_at = world.time + 1 HOURS
	SSmarket.auction_results = list()
	SSmarket.auction_drop_turf = null
	SSmarket.crew_lots = list()
	SSmarket.auction_announce_ready_at = world.time + 1 HOURS
	SSmarket.bundles = list()
	SSmarket.next_bundle_at = world.time + 1 HOURS
	SSmarket.load_settings(SSeconomy.settings.raw?["market"])

/proc/econ_test_restore_market(list/saved)
	if(!saved)
		return
	QDEL_LIST_ASSOC_VAL(SSmarket.commodities)
	QDEL_LIST_ASSOC_VAL(SSmarket.partners)
	QDEL_LIST(SSmarket.scheduled_events)
	QDEL_LIST_ASSOC_VAL(SSmarket.companies)
	QDEL_LIST(SSmarket.crew_lots)
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

/// Тренд на рынке консоли снабжения рисуется с первого сдвига смены: стартовая цена - первая точка истории.
/datum/unit_test/economy_market/history_from_shift_start/Run()
	SSmarket.restore_sector()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		TEST_ASSERT_EQUAL(length(commodity.history), 1, "[id]: стартовая точка истории")
	SSmarket.market_shift()
	var/list/market = econ_cargo_market_data(FALSE)
	for(var/list/entry as anything in market["commodities"])
		var/list/history = entry["history"]
		TEST_ASSERT_EQUAL(length(history), 2, "[entry["id"]]: после первого сдвига в окне две точки тренда")

/// Аукцион экипажа на подменённом рынке: пад подработки на станции, посылки падают на тестовый турф.
/datum/unit_test/economy_market/crew_auction
	abstract_type = /datum/unit_test/economy_market/crew_auction
	var/obj/machinery/computer/piratepad_control/civilian/console
	var/turf/pad_turf
	/// Человек -> его ID-карта
	var/list/cards = list()

/datum/unit_test/economy_market/crew_auction/proc/setup_pad()
	pad_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(pad_turf, "Есть станционный турф")
	var/mob/living/carbon/human/tech = allocate(/mob/living/carbon/human)
	var/obj/machinery/piratepad/civilian/pad = allocate(/obj/machinery/piratepad/civilian, pad_turf)
	console = allocate(/obj/machinery/computer/piratepad_control/civilian, pad_turf)
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	pad.multitool_act(tech, tool)
	console.multitool_act(tech, tool)
	TEST_ASSERT(console.linked_pad() == pad, "Пульт связан с падом")
	SSmarket.auction_drop_turf = run_loc_floor_bottom_left

/// Человек со счётом, который запоминает сообщения карты; with_pda - карта в КПК с кошельком, иначе в руке.
/datum/unit_test/economy_market/crew_auction/proc/make_person(holder, balance, with_pda = TRUE)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	var/datum/bank_account/econ_test_ear/account = new(holder)
	allocated += account
	econ_test_set_balance(account, balance)
	person.account_id = account.account_id
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	cards[person] = card
	if(with_pda)
		var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
		pda.InsertID(card)
		person.put_in_active_hand(pda)
	else
		person.put_in_active_hand(card)
	return person

/datum/unit_test/economy_market/crew_auction/proc/click(mob/living/user, action, list/params)
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "ContractBoard")
	window.status = UI_INTERACTIVE
	usr = user
	. = console.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_market/crew_auction/proc/wallet_of(mob/living/carbon/human/person)
	var/obj/item/modular_computer/pda/pda = person.get_active_held_item()
	return locate(/datum/computer_file/program/wallet) in pda.get_all_files()

/// Нажатие в Кошельке КПК; возвращает ответ окна.
/datum/unit_test/economy_market/crew_auction/proc/press_wallet(mob/living/carbon/human/person, action, list/params)
	var/datum/computer_file/program/wallet/wallet = wallet_of(person)
	var/datum/tgui/window = allocate(/datum/tgui, person, wallet, "NtosWallet")
	window.status = UI_INTERACTIVE
	usr = person
	wallet.ui_act(action, params, window)
	usr = null
	return wallet.message

/// Выставляет вещь с пада кнопкой пульта; возвращает новый лот или null.
/datum/unit_test/economy_market/crew_auction/proc/list_item(mob/living/user, atom/movable/thing, price = 100, minutes, anonymous = FALSE)
	var/before = length(SSmarket.crew_lots)
	click(user, "auction_list", list("ref" = REF(thing), "price" = price, "minutes" = minutes || SSeconomy.settings.auction_minutes_options()[1], "anonymous" = anonymous))
	if(length(SSmarket.crew_lots) > before)
		return SSmarket.crew_lots[length(SSmarket.crew_lots)]

/datum/unit_test/economy_market/crew_auction/proc/finish(datum/auction_lot/crew/lot)
	lot.ends_at = world.time
	SSmarket.auction_step(lot)

/datum/unit_test/economy_market/crew_auction/proc/heard(datum/bank_account/econ_test_ear/account, text)
	for(var/message in account.heard)
		if(findtext(message, text))
			return TRUE
	return FALSE

/// Лот экипажа: пад принимает разрешённую вещь, прячет имя анонимного продавца, отклоняет запрещённые категории и сверх лимита лотов на счёт.
/datum/unit_test/economy_market/crew_auction/listing/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0, FALSE)
	var/datum/bank_account/account = econ_account_of(seller)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	var/list/pad_entry
	for(var/list/entry as anything in console.ui_data(seller)["auction"]["items"])
		if(entry["ref"] == REF(plush))
			pad_entry = entry
	TEST_ASSERT_NOTNULL(pad_entry, "Пульт видит вещь на паде")
	TEST_ASSERT_NULL(pad_entry["problem"], "Плюшевый карп годится для аукциона")
	var/minutes = SSeconomy.settings.auction_minutes_options()[1]
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 150, minutes, TRUE)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	TEST_ASSERT(isnull(plush.loc) && lot.stored == plush, "Вещь ушла с пада на хранение лота")
	TEST_ASSERT(lot.seller_account == account, "Продавец - счёт нажавшего")
	TEST_ASSERT_EQUAL(lot.min_bid(), 150, "Старт - цена продавца")
	TEST_ASSERT(abs(lot.ends_at - (world.time + minutes MINUTES)) < 1, "Торги идут выбранный срок")
	TEST_ASSERT_EQUAL(length(lot.rivals), 0, "У лота экипажа нет соперников-станций")
	var/list/entry = lot.ui_entry(null)
	TEST_ASSERT_EQUAL(entry["seller"], "аноним", "Анонимный продавец в окне")
	TEST_ASSERT(!findtext(json_encode(econ_auction_ui_data(null)), "Econ Auction Seller"), "Имя анонимного продавца не утекает в окно")

	var/list/forbidden = list(
		/obj/item/gun/energy/laser,
		/obj/item/kitchen/knife,
		/obj/item/organ/heart,
		/obj/item/implanter,
		/obj/item/card/id,
		/obj/item/stack/spacecash/c10,
		/obj/item/stack/metadollar,
		/obj/item/gps,
		/obj/item/clothing/accessory/medal/gold/captain,
		/obj/structure/closet/crate,
		/mob/living/simple_animal/mouse,
	)
	for(var/forbidden_type in forbidden)
		var/atom/movable/thing = allocate(forbidden_type, pad_turf)
		TEST_ASSERT_NULL(list_item(seller, thing), "[forbidden_type] выставлен на аукцион")
		TEST_ASSERT(thing.loc == pad_turf, "[forbidden_type] ушёл с пада: [console.status_report]")
	var/obj/item/storage/box/box = allocate(/obj/item/storage/box, pad_turf)
	allocate(/obj/item/toy/plush/beeplushie, box)
	TEST_ASSERT_NULL(list_item(seller, box), "Непустой контейнер выставлен")
	TEST_ASSERT(findtext(console.status_report, "контейнеры"), "Пульт объясняет отказ контейнеру: [console.status_report]")
	var/list/saved_items = GLOB.possible_items
	GLOB.possible_items = list(null)
	var/datum/objective/steal/objective = new
	GLOB.possible_items = saved_items
	allocated += objective
	objective.steal_target = /obj/item/toy/plush/lizardplushie
	var/obj/item/toy/plush/lizardplushie/target = allocate(/obj/item/toy/plush/lizardplushie, pad_turf)
	TEST_ASSERT_NULL(list_item(seller, target), "Цель кражи выставлена")
	TEST_ASSERT(!findtext(console.status_report, "краж"), "Отказ не выдаёт цель кражи: [console.status_report]")

	var/limit = SSeconomy.settings.auction_crew_lots_per_account
	for(var/i in 2 to limit)
		TEST_ASSERT_NOTNULL(list_item(seller, allocate(/obj/item/toy/plush/beeplushie, pad_turf)), "Лот [i] из [limit] выставлен")
	var/obj/item/toy/plush/beeplushie/extra = allocate(/obj/item/toy/plush/beeplushie, pad_turf)
	TEST_ASSERT_NULL(list_item(seller, extra), "Сверх лимита на счёт выставлено")
	TEST_ASSERT(findtext(console.status_report, "на торгах"), "Пульт объясняет лимит: [console.status_report]")

/// Лот экипажа: ставка из Кошелька КПК замораживается, на свой лот не поставить, перебитому за минуту до конца напоминает карта; итог - ставка продавцу без сбора NT, сбор сгорает, победителю запертая посылка на его имя; без ставок вещь едет продавцу посылкой.
/datum/unit_test/economy_market/crew_auction/sale/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/first = make_person("Econ Auction First", 1000)
	var/mob/living/carbon/human/second = make_person("Econ Auction Second", 1000)
	var/datum/bank_account/econ_test_ear/seller_account = econ_account_of(seller)
	var/datum/bank_account/econ_test_ear/first_account = econ_account_of(first)
	var/datum/bank_account/econ_test_ear/second_account = econ_account_of(second)
	var/datum/bank_account/escrow = SSeconomy.market_account
	var/escrow_before = escrow.account_balance
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	press_wallet(seller, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	TEST_ASSERT_NULL(lot.bidder_account, "Продавец поставил на свой лот")
	var/answer = press_wallet(first, "auction_bid", list("uid" = "[lot.uid]", "amount" = "100"))
	TEST_ASSERT(lot.bidder_account == first_account, "Ставка из Кошелька не прошла: [answer]")
	TEST_ASSERT_EQUAL(first_account.account_balance, 900, "Ставка заморожена")
	var/datum/computer_file/program/wallet/first_wallet = wallet_of(first)
	var/list/view = first_wallet.wallet_data(first)["crew_lots"][1]
	TEST_ASSERT(view["mine"] && view["seller"] == "Econ Auction Seller", "Кошелёк показывает лот, продавца и свою ставку")
	press_wallet(second, "auction_bid", list("uid" = lot.uid, "amount" = lot.min_bid()))
	var/price = lot.bid
	TEST_ASSERT(lot.bidder_account == second_account && price > 100, "Вторая ставка перебила первую")
	TEST_ASSERT_EQUAL(first_account.account_balance, 1000, "Перебитая ставка вернулась")
	view = first_wallet.wallet_data(first)["crew_lots"][1]
	TEST_ASSERT(view["outbid"], "Кошелёк знает, что ставку перебили")
	lot.ends_at = world.time + AUCTION_SNIPE_WINDOW - 1
	SSmarket.auction_step(lot)
	TEST_ASSERT(heard(first_account, "до конца торгов"), "Перебитому не напомнили о конце торгов")
	TEST_ASSERT(!heard(second_account, "до конца торгов"), "Ведущему напомнили, будто его перебили")
	var/burned_before = SSeconomy.ledger.burned
	var/total_before = seller_account.account_balance + first_account.account_balance + second_account.account_balance + escrow.account_balance
	finish(lot)
	TEST_ASSERT(QDELETED(lot) && !(lot in SSmarket.crew_lots), "Торги закрыты")
	var/fee = round(price * SSeconomy.settings.auction_crew_fee / 100)
	TEST_ASSERT(fee > 0, "Сбор NT не нулевой")
	TEST_ASSERT_EQUAL(seller_account.account_balance, price - fee, "Продавцу - ставка без сбора NT")
	TEST_ASSERT_EQUAL(second_account.account_balance, 1000 - price, "Победитель заплатил свою ставку")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, fee, "Сбор NT сгорел")
	TEST_ASSERT_EQUAL(escrow.account_balance, escrow_before, "На счёте биржи ничего не осталось")
	TEST_ASSERT_EQUAL(total_before - (seller_account.account_balance + first_account.account_balance + second_account.account_balance + escrow.account_balance), fee, "Аукцион экипажа не создаёт денег")
	TEST_ASSERT(length(second_account.audit_outflows?["[seller_account.account_id]"]), "Аудит не видит след денег от покупателя к продавцу")
	var/obj/item/storage/lockbox/order/parcel = plush.loc
	TEST_ASSERT(istype(parcel) && parcel.loc == run_loc_floor_bottom_left, "Лот приехал посылкой")
	allocated += parcel
	TEST_ASSERT(parcel.buyer_account == second_account && findtext(parcel.name, "Econ Auction Second"), "Посылка на имя победителя: [parcel.name]")
	TEST_ASSERT_EQUAL(econ_packaging_value(parcel.type), 0, "Посылку аукциона NT не выкупает как упаковку")
	parcel.attackby(cards[first], first)
	TEST_ASSERT(SEND_SIGNAL(parcel, COMSIG_IS_STORAGE_LOCKED), "Чужая карта открыла посылку")
	parcel.attackby(cards[second], second)
	TEST_ASSERT(!SEND_SIGNAL(parcel, COMSIG_IS_STORAGE_LOCKED), "Карта победителя не открыла посылку")
	TEST_ASSERT(heard(seller_account, "продан за [price] кр."), "Продавцу не сообщили о продаже")
	TEST_ASSERT(heard(second_account, "ваш за [price] кр."), "Победителю не сообщили о выигрыше")

	var/obj/item/toy/plush/beeplushie/bee = allocate(/obj/item/toy/plush/beeplushie, pad_turf)
	lot = list_item(seller, bee, 50, anonymous = TRUE)
	TEST_ASSERT_NOTNULL(lot, "Второй лот выставлен: [console.status_report]")
	var/seller_before = seller_account.account_balance
	finish(lot)
	var/obj/item/storage/lockbox/order/returned = bee.loc
	TEST_ASSERT(istype(returned) && returned.buyer_account == seller_account, "Без ставок вещь едет продавцу посылкой")
	allocated += returned
	TEST_ASSERT(!findtext(returned.name, "Econ Auction Seller"), "Посылка анонимного продавца без имени: [returned.name]")
	TEST_ASSERT_EQUAL(seller_account.account_balance, seller_before, "Без ставок денег не прибавилось")
	TEST_ASSERT(heard(seller_account, "без ставок"), "Продавцу не сообщили, что ставок не было")

/// Лот экипажа снимает только продавец и только до первой ставки; снятая вещь едет продавцу посылкой.
/datum/unit_test/economy_market/crew_auction/cancel/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/other = make_person("Econ Auction Other", 1000)
	var/datum/bank_account/seller_account = econ_account_of(seller)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	press_wallet(other, "auction_cancel", list("uid" = lot.uid))
	TEST_ASSERT(lot in SSmarket.crew_lots, "Чужой снял лот")
	var/answer = press_wallet(seller, "auction_cancel", list("uid" = "[lot.uid]"))
	TEST_ASSERT(QDELETED(lot) && !(lot in SSmarket.crew_lots), "Продавец не снял лот: [answer]")
	var/obj/item/storage/lockbox/order/returned = plush.loc
	TEST_ASSERT(istype(returned) && returned.buyer_account == seller_account, "Снятая вещь не вернулась посылкой продавцу")
	allocated += returned

	var/obj/item/toy/plush/beeplushie/bee = allocate(/obj/item/toy/plush/beeplushie, pad_turf)
	lot = list_item(seller, bee, 100)
	press_wallet(other, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	TEST_ASSERT(lot.bid, "Ставка прошла")
	answer = press_wallet(seller, "auction_cancel", list("uid" = lot.uid))
	TEST_ASSERT(lot in SSmarket.crew_lots, "Лот со ставкой снят")
	TEST_ASSERT(findtext(answer, "уже поставили"), "Кошелёк объясняет отказ: [answer]")
	finish(lot)
	allocated += bee.loc

/// Лот экипажа не держит ссылок: пропавшая вещь закрывает лот с возвратом ставки, закрытый счёт продавца - тоже, и вещь удаляется вместе с лотом.
/datum/unit_test/economy_market/crew_auction/cleanup/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/bidder = make_person("Econ Auction Bidder", 1000)
	var/datum/bank_account/bidder_account = econ_account_of(bidder)
	var/obj/item/toy/plush/carpplushie/plush = new(pad_turf)
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	press_wallet(bidder, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	TEST_ASSERT(lot.bidder_account == bidder_account, "Ставка прошла")
	qdel(plush)
	TEST_ASSERT(QDELETED(lot) && !(lot in SSmarket.crew_lots), "Лот без вещи не закрылся")
	TEST_ASSERT_EQUAL(bidder_account.account_balance, 1000, "Ставка на пропавший лот вернулась")
	TEST_ASSERT(refcount(lot) == GC_QUEUE_ONLY_REFS, "Закрытый лот держит кто-то, кроме очереди GC: [refcount(lot)]")
	TEST_ASSERT(isnull(lot.stored) && isnull(lot.seller_account) && isnull(lot.bidder_account), "Закрытый лот держит вещь или счета")

	var/mob/living/carbon/human/doomed = allocate(/mob/living/carbon/human)
	var/datum/bank_account/doomed_account = new("Econ Auction Doomed")
	doomed.account_id = doomed_account.account_id
	var/obj/item/toy/plush/beeplushie/bee = new(pad_turf)
	lot = list_item(doomed, bee, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	press_wallet(bidder, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	qdel(doomed_account)
	TEST_ASSERT(QDELETED(lot) && !(lot in SSmarket.crew_lots), "Лот закрытого счёта не закрылся")
	TEST_ASSERT(QDELETED(bee), "Вещь без продавца не удалилась вместе с лотом")
	TEST_ASSERT_EQUAL(bidder_account.account_balance, 1000, "Ставка на лот закрытого счёта вернулась")
	TEST_ASSERT(refcount(lot) == GC_QUEUE_ONLY_REFS, "Закрытый лот держит кто-то, кроме очереди GC: [refcount(lot)]")

/// О новом лоте общий канал слышит одну строку с названием, описанием и выбранным именем продавца; лот в кулдаун канала молчит.
/datum/unit_test/economy_market/crew_auction/radio/Run()
	setup_pad()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/econ_test_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	SSmarket.auction_announce_ready_at = 0
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/shy = make_person("Econ Auction Shy", 0)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	plush.desc = "Мягкий карп с паровозиком."
	TEST_ASSERT_NOTNULL(list_item(seller, plush, 100), "Лот выставлен: [console.status_report]")
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Одна строка о новом лоте")
	var/line = spy.heard[1]
	TEST_ASSERT(findtext(line, "общий:") == 1, "Строка в общем канале: [line]")
	TEST_ASSERT(findtext(line, plush.name) && findtext(line, "паровозиком") && findtext(line, "Econ Auction Seller"), "В строке название, описание и продавец: [line]")
	TEST_ASSERT_NOTNULL(list_item(shy, allocate(/obj/item/toy/plush/beeplushie, pad_turf), 100, anonymous = TRUE), "Второй лот выставлен")
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Лот в кулдаун канала прозвучал")
	SSmarket.auction_announce_ready_at = 0
	TEST_ASSERT_NOTNULL(list_item(shy, allocate(/obj/item/toy/plush/lizardplushie, pad_turf), 100, anonymous = TRUE), "Третий лот выставлен")
	TEST_ASSERT_EQUAL(length(spy.heard), 2, "После кулдауна лот прозвучал")
	TEST_ASSERT(findtext(spy.heard[2], "аноним") && !findtext(spy.heard[2], "Econ Auction Shy"), "Анонимный продавец назван в канале: [spy.heard[2]]")
