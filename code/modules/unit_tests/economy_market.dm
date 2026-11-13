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
		"crew_auction_results" = SSmarket.crew_auction_results,
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
	SSmarket.crew_auction_results = list()
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

/// Аукцион экипажа на подменённом рынке: пад подработки на станции, посылки с итогом встают на него.
/datum/unit_test/economy_market/crew_auction
	abstract_type = /datum/unit_test/economy_market/crew_auction
	var/obj/machinery/computer/piratepad_control/civilian/console
	var/obj/machinery/piratepad/civilian/pad
	var/turf/pad_turf
	/// Человек -> его ID-карта
	var/list/cards = list()

/datum/unit_test/economy_market/crew_auction/proc/setup_pad()
	econ_test_contraband_ready()
	pad_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(pad_turf, "Есть станционный турф")
	for(var/obj/item/stray in pad_turf)
		stray.forceMove(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/tech = allocate(/mob/living/carbon/human)
	pad = allocate(/obj/machinery/piratepad/civilian, pad_turf)
	console = allocate(/obj/machinery/computer/piratepad_control/civilian, pad_turf)
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	pad.multitool_act(tech, tool)
	console.multitool_act(tech, tool)
	TEST_ASSERT(console.linked_pad() == pad, "Пульт связан с падом")

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
/datum/unit_test/economy_market/crew_auction/proc/list_item(mob/living/user, atom/movable/thing, price = 100, minutes, anonymous = FALSE, buyout = 0)
	var/before = length(SSmarket.crew_lots)
	click(user, "auction_list", list("ref" = REF(thing), "price" = price, "minutes" = minutes || SSeconomy.settings.auction_minutes_options()[1], "anonymous" = anonymous, "buyout" = buyout))
	if(length(SSmarket.crew_lots) > before)
		return SSmarket.crew_lots[length(SSmarket.crew_lots)]

/datum/unit_test/economy_market/crew_auction/proc/finish(datum/auction_lot/crew/lot)
	lot.ends_at = world.time
	SSmarket.auction_step(lot)

/datum/unit_test/economy_market/crew_auction/proc/heard(datum/bank_account/econ_test_ear/account, text)
	return heard_count(account, text) > 0

/datum/unit_test/economy_market/crew_auction/proc/heard_count(datum/bank_account/econ_test_ear/account, text)
	. = 0
	for(var/message in account.heard)
		if(findtext(message, text))
			.++

/// Посылка аукциона на счёт owner, которая ещё летит капсулой: list(посылка, тип капсулы, область посадки). Капсула убирается до посадки, посылка ложится на тестовый турф.
/datum/unit_test/economy_market/crew_auction/proc/catch_pod_parcel(datum/bank_account/owner)
	for(var/obj/effect/pod_landingzone/zone in world)
		var/obj/item/storage/lockbox/order/parcel = locate() in zone.pod
		if(!parcel || parcel.buyer_account != owner)
			continue
		var/pod_type = zone.pod.type
		var/area/landing = get_area(zone)
		parcel.forceMove(run_loc_floor_bottom_left)
		allocated += parcel
		qdel(zone.helper)
		qdel(zone.pod)
		qdel(zone)
		return list(parcel, pod_type, landing)
	return list(null, null, null)

/// Общий канал слышит гарнитура-шпион рабочей системы оповещения.
/datum/unit_test/economy_market/crew_auction/proc/spy_radio()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/econ_test_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	SSmarket.auction_announce_ready_at = 0
	return spy

/// Лот экипажа: пад принимает разрешённую вещь, прячет имя анонимного продавца, отклоняет запрещённые категории и сверх лимита лотов на счёт; на пустом паде пульт ничего не предлагает.
/datum/unit_test/economy_market/crew_auction/listing/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0, FALSE)
	var/datum/bank_account/account = econ_account_of(seller)
	var/list/empty = console.ui_data(seller)["auction"]["items"]
	TEST_ASSERT_EQUAL(length(empty), 0, "На пустом паде пульт предлагает выставить: [json_encode(empty)]")
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

/// Фильтр аукциона экипажа: оружие и взрывчатка, вещи антагонистов, вещь с аплинком и тяжёлое по силе удара не принимаются; пока каталог NT не сверен, не принимается ничего.
/datum/unit_test/economy_market/crew_auction/filter/Run()
	econ_test_contraband_ready()
	var/list/forbidden = list(
		/obj/item/chainsaw,
		/obj/item/hatchet,
		/obj/item/flamethrower/full,
		/obj/item/reagent_containers/spray/pepper,
		/obj/item/syndicatedetonator,
		/obj/item/necromantic_stone,
		/obj/item/kinetic_crusher,
	)
	for(var/forbidden_type in forbidden)
		var/obj/item/thing = allocate(forbidden_type, run_loc_floor_bottom_left)
		TEST_ASSERT(econ_auction_item_problem(thing), "[forbidden_type] пропущен на аукцион")
	var/obj/item/pen/pen = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(econ_auction_item_problem(pen), "Обычная ручка не годится: [econ_auction_item_problem(pen)]")
	pen.AddComponent(/datum/component/uplink, null, TRUE, FALSE, UPLINK_TRAITORS, 0)
	var/problem = econ_auction_item_problem(pen)
	TEST_ASSERT(problem && !findtext(problem, "аплинк"), "Ручка с аплинком пропущена или отказ его выдаёт: [problem]")
	var/obj/item/toy/plush/beeplushie/heavy = allocate(/obj/item/toy/plush/beeplushie, run_loc_floor_bottom_left)
	heavy.force = AUCTION_WEAPON_FORCE
	TEST_ASSERT(findtext(econ_auction_item_problem(heavy), "Оружие"), "Вещь с силой удара [AUCTION_WEAPON_FORCE] пропущена")

	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(econ_auction_item_problem(plush), "Плюшевый карп не годится")
	GLOB.econ_contraband_built = FALSE
	problem = econ_auction_item_problem(plush)
	GLOB.econ_contraband_built = TRUE
	TEST_ASSERT(findtext(problem, "сверяется"), "Пока каталог NT не сверен, вещь принята: [problem]")

/// Цель кражи из ходовых вещей (экстракты, баллоны) отказом себя не выдаёт: такие вещи аукцион экипажа принимает.
/datum/unit_test/economy_market/crew_auction/common_steal_target/Run()
	econ_test_contraband_ready()
	var/list/saved_items = GLOB.possible_items
	GLOB.possible_items = list(null)
	var/datum/objective/steal/objective = new
	GLOB.possible_items = saved_items
	allocated += objective
	objective.steal_target = /obj/item/slime_extract
	var/obj/item/slime_extract/grey/extract = allocate(/obj/item/slime_extract/grey, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(econ_auction_item_problem(extract), "Отказ всем экстрактам выдаёт цель кражи: [econ_auction_item_problem(extract)]")

/// Снявший свой лот выставляет новый только через auction_crew_relist_minutes, и пульт с Кошельком говорят когда.
/datum/unit_test/economy_market/crew_auction/relist/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/datum/bank_account/account = econ_account_of(seller)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	var/answer = press_wallet(seller, "auction_cancel", list("uid" = lot.uid))
	TEST_ASSERT(QDELETED(lot), "Продавец не снял лот: [answer]")
	allocated += plush.loc
	var/minutes = SSeconomy.settings.auction_crew_relist_minutes
	TEST_ASSERT(minutes > 0, "Пауза после снятия лота задана")
	TEST_ASSERT(findtext(answer, "через [minutes] мин."), "Кошелёк не говорит, когда можно выставить снова: [answer]")
	var/obj/item/toy/plush/beeplushie/bee = allocate(/obj/item/toy/plush/beeplushie, pad_turf)
	TEST_ASSERT_NULL(list_item(seller, bee, 100), "Новый лот выставлен сразу после снятия старого")
	TEST_ASSERT(findtext(console.status_report, "недавно сняли"), "Пульт не объясняет паузу: [console.status_report]")
	TEST_ASSERT(console.ui_data(seller)["auction"]["relist_left"] > 0, "Окно пульта не знает о паузе")
	COOLDOWN_RESET(account, auction_relist_cooldown)
	TEST_ASSERT_NOTNULL(list_item(seller, bee, 100), "После паузы лот не выставлен: [console.status_report]")

/// Лот экипажа: ставка из Кошелька КПК замораживается, на свой лот не поставить, перебитому за минуту до конца напоминает карта; итог - ставка продавцу без сбора NT, сбор сгорает, победителю запертая посылка на его имя на паде; аудит видит след от покупателя к продавцу одной строкой; без ставок вещь едет продавцу посылкой.
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
	TEST_ASSERT_EQUAL(length(second_account.audit_outflows), 1, "След покупателя в аудите не одной строкой: [json_encode(second_account.audit_outflows)]")
	TEST_ASSERT(!length(first_account.audit_outflows), "Перебитая ставка осталась в следе аудита: [json_encode(first_account.audit_outflows)]")
	var/obj/item/storage/lockbox/order/parcel = plush.loc
	catch_pod_parcel(second_account)
	TEST_ASSERT(istype(parcel) && parcel.loc == pad_turf, "Лот приехал не посылкой на пад: [parcel?.loc]")
	allocated += parcel
	TEST_ASSERT(parcel.buyer_account == second_account && findtext(parcel.name, "Econ Auction Second"), "Посылка на имя победителя: [parcel.name]")
	TEST_ASSERT_EQUAL(econ_packaging_value(parcel.type), 0, "Посылку аукциона NT не выкупает как упаковку")
	parcel.attackby(cards[first], first)
	TEST_ASSERT(SEND_SIGNAL(parcel, COMSIG_IS_STORAGE_LOCKED), "Чужая карта открыла посылку")
	parcel.attackby(cards[second], second)
	TEST_ASSERT(!SEND_SIGNAL(parcel, COMSIG_IS_STORAGE_LOCKED), "Карта победителя не открыла посылку")
	TEST_ASSERT(heard(seller_account, "продан за [price] кр."), "Продавцу не сообщили о продаже")
	TEST_ASSERT(heard(second_account, "ваш за [price] кр.: запертая посылка на ваше имя ждёт на паде подработки"), "Победителю не сказали, где посылка")
	TEST_ASSERT_EQUAL(SSmarket.crew_auction_results[1][2], "Econ Auction Second", "Итог лота экипажа")

	var/obj/item/toy/plush/beeplushie/bee = allocate(/obj/item/toy/plush/beeplushie, pad_turf)
	lot = list_item(seller, bee, 50, anonymous = TRUE)
	TEST_ASSERT_NOTNULL(lot, "Второй лот выставлен: [console.status_report]")
	var/seller_before = seller_account.account_balance
	finish(lot)
	var/obj/item/storage/lockbox/order/returned = bee.loc
	catch_pod_parcel(seller_account)
	TEST_ASSERT(istype(returned) && returned.buyer_account == seller_account && returned.loc == pad_turf, "Без ставок вещь едет продавцу посылкой на пад")
	allocated += returned
	TEST_ASSERT(!findtext(returned.name, "Econ Auction Seller"), "Посылка анонимного продавца без имени: [returned.name]")
	TEST_ASSERT_EQUAL(seller_account.account_balance, seller_before, "Без ставок денег не прибавилось")
	TEST_ASSERT(heard(seller_account, "без ставок, вещь возвращается к вам: безымянная запертая посылка"), "Анонимному продавцу не сказали про безымянную посылку")
	TEST_ASSERT(isnull(SSmarket.crew_auction_results[1][2]), "Лот без ставок в итогах с победителем")

/// Итог лота экипажа встаёт посылкой на пад, с которого вещь выставили; без пада - и у лота сектора всегда - посылка летит блюспейс-капсулой, которая не взрывается, в снабжение.
/datum/unit_test/economy_market/crew_auction/delivery/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/buyer = make_person("Econ Auction Buyer", 5000)
	var/datum/bank_account/econ_test_ear/buyer_account = econ_account_of(buyer)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	press_wallet(buyer, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	finish(lot)
	var/obj/item/storage/lockbox/order/parcel = plush.loc
	var/list/caught = catch_pod_parcel(buyer_account)
	allocated += parcel
	TEST_ASSERT(!caught[1] && parcel?.loc == pad_turf, "Проданный лот улетел капсулой вместо своего пада: [caught[2]]")
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/datum/bounty/item/bounty = new
	bounty.wanted_types = typecacheof(list(/obj/item/toy/plush/carpplushie))
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, bounty)
	civilian.contracts.Insert(1, contract)
	pad.warmup_time = 0
	click(seller, "send", list())
	civilian.contracts -= contract
	qdel(contract)
	TEST_ASSERT(!QDELETED(plush) && plush.loc == parcel, "Пад отправил по контракту вещь из чужой запертой посылки")

	var/obj/item/toy/plush/beeplushie/bee = allocate(/obj/item/toy/plush/beeplushie, pad_turf)
	lot = list_item(seller, bee, 100)
	TEST_ASSERT_NOTNULL(lot, "Второй лот выставлен: [console.status_report]")
	press_wallet(buyer, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	qdel(pad)
	finish(lot)
	caught = catch_pod_parcel(buyer_account)
	TEST_ASSERT(caught[1] && (locate(/obj/item/toy/plush/beeplushie) in caught[1]), "Без пада посылка не улетела капсулой")
	TEST_ASSERT_EQUAL(caught[2], /obj/structure/closet/supplypod/bluespacepod, "Посылка летит взрывающейся капсулой")
	TEST_ASSERT(istype(caught[3], /area/cargo), "Капсула садится не в снабжение: [caught[3]]")
	TEST_ASSERT(heard(buyer_account, "прилетит капсулой"), "Покупателю не сказали, что посылка прилетит капсулой")

	var/datum/auction_lot/sector = SSmarket.start_auction(list("path" = /obj/item/toy/plush/lizardplushie, "name" = "тестовая ящерица", "value" = 1000))
	sector.rivals = list()
	TEST_ASSERT_NULL(SSmarket.place_auction_bid(buyer_account, sector.min_bid(), buyer, sector.uid), "Ставка на лот сектора не прошла")
	SSmarket.finish_auction()
	caught = catch_pod_parcel(buyer_account)
	TEST_ASSERT(caught[1] && (locate(/obj/item/toy/plush/lizardplushie) in caught[1]), "Лот сектора не улетел капсулой")
	TEST_ASSERT_EQUAL(caught[2], /obj/structure/closet/supplypod/bluespacepod, "Лот сектора летит взрывающейся капсулой")

/// Со счёта вне станции на аукционе не торгуются: ни ставкой на лот экипажа или сектора, ни покупкой сразу.
/datum/unit_test/economy_market/crew_auction/offstation/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/outsider = make_person("Econ Auction Outsider", 1000)
	var/datum/bank_account/outsider_account = econ_account_of(outsider)
	outsider_account.offstation = TRUE
	var/datum/auction_lot/crew/lot = list_item(seller, allocate(/obj/item/toy/plush/carpplushie, pad_turf), 100, buyout = 200)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	var/answer = press_wallet(outsider, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	TEST_ASSERT(isnull(lot.bidder_account) && findtext(answer, "вне станции"), "Ставка со счёта вне станции: [answer]")
	answer = press_wallet(outsider, "auction_buyout", list("uid" = lot.uid))
	TEST_ASSERT((lot in SSmarket.crew_lots) && findtext(answer, "вне станции"), "Покупка сразу со счёта вне станции: [answer]")
	TEST_ASSERT_EQUAL(outsider_account.account_balance, 1000, "Со счёта вне станции списали деньги")
	var/datum/auction_lot/sector = SSmarket.start_auction(list("path" = /obj/item/toy/plush/lizardplushie, "name" = "тестовая ящерица", "value" = 1000))
	answer = SSmarket.place_auction_bid(outsider_account, sector.min_bid(), outsider, sector.uid)
	SSmarket.auction = null
	qdel(sector)
	TEST_ASSERT(findtext(answer, "вне станции"), "Ставка на лот сектора со счёта вне станции: [answer]")

/// Лот экипажа с ценой «купить сразу»: ставки идут ниже неё, покупка сразу закрывает лот проданным - продавцу без сбора NT, перебитому возврат, покупателю посылка на пад; свой лот сразу не купить, лот без цены выкупа - тоже; цена выкупа ниже старта не принимается.
/datum/unit_test/economy_market/crew_auction/buyout/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/first = make_person("Econ Auction First", 1000)
	var/mob/living/carbon/human/buyer = make_person("Econ Auction Buyer", 1000)
	var/datum/bank_account/econ_test_ear/seller_account = econ_account_of(seller)
	var/datum/bank_account/econ_test_ear/first_account = econ_account_of(first)
	var/datum/bank_account/econ_test_ear/buyer_account = econ_account_of(buyer)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	TEST_ASSERT_NULL(list_item(seller, plush, 100, buyout = 50), "Цена выкупа ниже старта принята")
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100, buyout = 300)
	TEST_ASSERT_NOTNULL(lot, "Лот с ценой выкупа не выставлен: [console.status_report]")
	TEST_ASSERT_EQUAL(lot.ui_entry(null)["buyout"], 300, "Окно не знает цену выкупа")
	press_wallet(seller, "auction_buyout", list("uid" = lot.uid))
	TEST_ASSERT(lot in SSmarket.crew_lots, "Продавец купил свой лот")
	press_wallet(first, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	TEST_ASSERT(lot.bidder_account == first_account, "Ставка ниже цены выкупа не прошла")
	var/answer = press_wallet(first, "auction_bid", list("uid" = lot.uid, "amount" = 300))
	TEST_ASSERT(lot.bid == 100 && findtext(answer, "купить за 300"), "Ставка дошла до цены выкупа: [answer]")
	answer = press_wallet(buyer, "auction_buyout", list("uid" = "[lot.uid]"))
	TEST_ASSERT(QDELETED(lot) && !(lot in SSmarket.crew_lots), "Лот не купили сразу: [answer]")
	TEST_ASSERT(findtext(answer, "ваш за 300 кр.: запертая посылка на ваше имя ждёт на паде подработки"), "Кошелёк не говорит, где посылка: [answer]")
	var/fee = round(300 * SSeconomy.settings.auction_crew_fee / 100)
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 700, "Покупатель заплатил цену выкупа")
	TEST_ASSERT_EQUAL(first_account.account_balance, 1000, "Перебитому не вернулась ставка")
	TEST_ASSERT_EQUAL(seller_account.account_balance, 300 - fee, "Продавцу - цена выкупа без сбора NT")
	TEST_ASSERT(heard(first_account, "купили сразу за 300 кр."), "Перебитому не сказали, что лот купили сразу")
	var/obj/item/storage/lockbox/order/parcel = plush.loc
	catch_pod_parcel(buyer_account)
	allocated += parcel
	TEST_ASSERT(istype(parcel) && parcel.buyer_account == buyer_account && parcel.loc == pad_turf, "Купленный сразу лот не на паде посылкой покупателя")

	var/datum/auction_lot/crew/plain = list_item(seller, allocate(/obj/item/toy/plush/beeplushie, pad_turf), 100)
	TEST_ASSERT_NOTNULL(plain, "Лот без цены выкупа выставлен")
	answer = press_wallet(buyer, "auction_buyout", list("uid" = plain.uid))
	TEST_ASSERT((plain in SSmarket.crew_lots) && findtext(answer, "только на торги"), "Лот без цены выкупа купили сразу: [answer]")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 700, "За отказ списали деньги")

/// Продавцу карта говорит о первой ставке на лот один раз, а за минуту до конца лота без ставок - что ставок нет, тоже один раз.
/datum/unit_test/economy_market/crew_auction/seller_notices/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/first = make_person("Econ Auction First", 1000)
	var/mob/living/carbon/human/second = make_person("Econ Auction Second", 1000)
	var/datum/bank_account/econ_test_ear/seller_account = econ_account_of(seller)
	var/datum/auction_lot/crew/lot = list_item(seller, allocate(/obj/item/toy/plush/carpplushie, pad_turf), 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	press_wallet(first, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	TEST_ASSERT_EQUAL(heard_count(seller_account, "поставили 100 кр."), 1, "Продавцу не сказали о первой ставке")
	press_wallet(second, "auction_bid", list("uid" = lot.uid, "amount" = lot.min_bid()))
	TEST_ASSERT_EQUAL(heard_count(seller_account, "поставили"), 1, "Продавцу сообщают о каждой ставке")
	lot.ends_at = world.time + AUCTION_SNIPE_WINDOW - 1
	SSmarket.auction_step(lot)
	TEST_ASSERT(!heard(seller_account, "ставок пока нет"), "Продавцу со ставками сказали, что ставок нет")
	var/datum/auction_lot/crew/quiet = list_item(seller, allocate(/obj/item/toy/plush/beeplushie, pad_turf), 100)
	TEST_ASSERT_NOTNULL(quiet, "Второй лот выставлен: [console.status_report]")
	quiet.ends_at = world.time + AUCTION_SNIPE_WINDOW - 1
	SSmarket.auction_step(quiet)
	SSmarket.auction_step(quiet)
	TEST_ASSERT_EQUAL(heard_count(seller_account, "ставок пока нет"), 1, "Продавцу лота без ставок не сказали один раз, что ставок нет")

/// Лот экипажа называется исходным именем вещи и описывается исходным описанием - в окне, по радио и в сообщениях карт; переименование ручкой видно в окне отдельной надписью.
/datum/unit_test/economy_market/crew_auction/inscription/Run()
	setup_pad()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_radio()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/buyer = make_person("Econ Auction Buyer", 1000)
	var/datum/bank_account/econ_test_ear/seller_account = econ_account_of(seller)
	var/datum/bank_account/econ_test_ear/buyer_account = econ_account_of(buyer)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	var/official_name = format_text(initial(plush.name))
	var/official_desc = format_text(initial(plush.desc))
	plush.name = "Самый ценный карп станции"
	plush.desc = "Продам срочно, звоните."
	plush.renamedByPlayer = TRUE
	var/list/pad_entry
	for(var/list/entry as anything in console.ui_data(seller)["auction"]["items"])
		if(entry["ref"] == REF(plush))
			pad_entry = entry
	TEST_ASSERT(pad_entry && pad_entry["name"] == official_name && findtext(pad_entry["inscription"], "Самый ценный карп"), "Пульт называет вещь не исходным именем или без надписи: [json_encode(pad_entry)]")
	var/datum/auction_lot/crew/lot = list_item(seller, plush, 100)
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен: [console.status_report]")
	var/list/entry = lot.ui_entry(null)
	TEST_ASSERT_EQUAL(entry["name"], official_name, "Лот назван правкой игрока")
	TEST_ASSERT_EQUAL(entry["desc"], official_desc, "Описание лота - правка игрока")
	TEST_ASSERT(findtext(entry["inscription"], "Самый ценный карп") && findtext(entry["inscription"], "звоните"), "Надпись игрока не видна в окне: [entry["inscription"]]")
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "О лоте не прозвучала одна строка")
	TEST_ASSERT(findtext(spy.heard[1], official_name) && !findtext(spy.heard[1], "Самый ценный") && !findtext(spy.heard[1], "звоните"), "Правки игрока ушли в эфир: [spy.heard[1]]")
	press_wallet(buyer, "auction_bid", list("uid" = lot.uid, "amount" = 100))
	finish(lot)
	allocated += plush.loc
	TEST_ASSERT(heard(buyer_account, official_name) && !heard(buyer_account, "Самый ценный") && !heard(seller_account, "Самый ценный"), "Правки игрока в сообщениях карт")

/// Выставленная вещь уходит с пада вместе со своим светом.
/datum/unit_test/economy_market/crew_auction/light/Run()
	setup_pad()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/obj/item/flashlight/torch = allocate(/obj/item/flashlight, pad_turf)
	torch.on = TRUE
	torch.update_brightness()
	var/datum/component/overlay_lighting/glow = torch.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT(glow?.current_holder == torch, "Фонарь на паде не светит")
	TEST_ASSERT_NOTNULL(list_item(seller, torch, 100), "Фонарь не выставлен: [console.status_report]")
	TEST_ASSERT_NULL(glow.current_holder, "Свет выставленного фонаря остался на паде")

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
	COOLDOWN_RESET(seller_account, auction_relist_cooldown)

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

/// О новом лоте общий канал слышит одну строку с исходным названием и описанием вещи, ценой «купить сразу» и выбранным именем продавца; описание игрока в эфир не идёт; лот в кулдаун канала молчит.
/datum/unit_test/economy_market/crew_auction/radio/Run()
	setup_pad()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_radio()
	var/mob/living/carbon/human/seller = make_person("Econ Auction Seller", 0)
	var/mob/living/carbon/human/shy = make_person("Econ Auction Shy", 0)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie, pad_turf)
	plush.desc = "Мягкий карп с паровозиком."
	TEST_ASSERT_NOTNULL(list_item(seller, plush, 100, buyout = 400), "Лот выставлен: [console.status_report]")
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Одна строка о новом лоте")
	var/line = spy.heard[1]
	TEST_ASSERT(findtext(line, "общий:") == 1, "Строка в общем канале: [line]")
	TEST_ASSERT(findtext(line, format_text(initial(plush.name))) && findtext(line, "Econ Auction Seller") && findtext(line, "купить сразу - 400 кр."), "В строке название, продавец и цена выкупа: [line]")
	TEST_ASSERT(!findtext(line, "паровозиком"), "Описание игрока ушло в эфир: [line]")
	TEST_ASSERT_NOTNULL(list_item(shy, allocate(/obj/item/toy/plush/beeplushie, pad_turf), 100, anonymous = TRUE), "Второй лот выставлен")
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Лот в кулдаун канала прозвучал")
	SSmarket.auction_announce_ready_at = 0
	TEST_ASSERT_NOTNULL(list_item(shy, allocate(/obj/item/toy/plush/lizardplushie, pad_turf), 100, anonymous = TRUE), "Третий лот выставлен")
	TEST_ASSERT_EQUAL(length(spy.heard), 2, "После кулдауна лот прозвучал")
	TEST_ASSERT(findtext(spy.heard[2], "аноним") && !findtext(spy.heard[2], "Econ Auction Shy"), "Анонимный продавец назван в канале: [spy.heard[2]]")
