/// Канал "Сводка сектора" создан при инициализации рынка один раз и закрыт для статей экипажа.
/datum/unit_test/economy_news_channel/Run()
	var/list/found = list()
	for(var/datum/news/feed_channel/candidate as anything in GLOB.news_network.network_channels)
		if(candidate.channel_name == MARKET_NEWS_CHANNEL)
			found += candidate
	TEST_ASSERT_EQUAL(length(found), 1, "Канал сводки сектора один")
	var/datum/news/feed_channel/channel = found[1]
	TEST_ASSERT(channel.locked, "Канал закрыт для экипажа")
	TEST_ASSERT_EQUAL(channel.author, MARKET_NEWS_AUTHOR, "Автор канала")
	TEST_ASSERT(SSmarket.news_channel() == channel, "Рынок пишет в этот канал")
	var/help = econ_cargo_market_help()
	TEST_ASSERT(findtext(help, "\"[MARKET_NEWS_CHANNEL]\" не чаще раза в [SSmarket.news_flash_minutes] мин.") && findtext(help, "раз в [SSmarket.digest_minutes] мин."), "Справка снабжения описывает канал: [help]")

/// Памятка по экономике выходит в канал сводки при инициализации рынка, без табов и с числами из настроек.
/datum/unit_test/economy_news_guide/Run()
	TEST_ASSERT(SSmarket.guide_published, "Памятка опубликована при инициализации рынка")
	var/text = econ_guide_summary_text()
	TEST_ASSERT(!findtext(text, "\t"), "В памятке табуляция")
	TEST_ASSERT(findtext(text, "до [SSeconomy.settings.tax_max]%"), "Памятка называет потолок налога")
	TEST_ASSERT(findtext(text, "[SSeconomy.settings.contract_performer_share]% награды"), "Памятка называет долю исполнителя контракта")
	TEST_ASSERT(findtext(text, "не переходят"), "Памятка говорит, что деньги не переходят в следующую смену")
	TEST_ASSERT(findtext(text, "капсулой") && findtext(text, "[SSeconomy.settings.department_express_markup]%"), "Памятка называет капсулу отдела и её наценку")

/// Тесты на изолированной копии рынка; статьи канала сводки и состояние SSmarket возвращаются.
/datum/unit_test/economy_news
	abstract_type = /datum/unit_test/economy_news
	var/list/saved_market
	var/datum/news/feed_channel/channel
	var/list/saved_messages

/datum/unit_test/economy_news/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	SSmarket.next_restock = world.time + 1 HOURS
	SSmarket.next_offers = world.time + 1 HOURS
	SSmarket.next_digest = world.time + 1 HOURS
	SSmarket.company_event_chance = 0
	SSmarket.hot_chance = 0
	flash_ready()
	channel = SSmarket.news_channel()
	if(channel)
		saved_messages = channel.messages.Copy()

/datum/unit_test/economy_news/Destroy()
	channel = null
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_news/proc/new_bodies()
	. = list()
	for(var/datum/news/feed_message/article as anything in channel.messages - saved_messages)
		. += article.body

/datum/unit_test/economy_news/proc/last_body()
	var/datum/news/feed_message/article = channel.messages[length(channel.messages)]
	return article.body

/datum/unit_test/economy_news/proc/flash_ready()
	SSmarket.last_news = world.time - SSmarket.news_flash_minutes MINUTES - 1

/// Событие компании до выхода не попадает ни в сводку, ни в новости; в момент выхода - статья с заголовком и ценой после шока.
/datum/unit_test/economy_news/company_event/Run()
	TEST_ASSERT_NOTNULL(channel, "Нет канала сводки")
	var/datum/stock_company/company = SSmarket.get_company("NKMR")
	var/headline = "Накамура запускает тестовый реактор [REF(src)]"
	var/datum/market_event/event = SSmarket.schedule_company_event(company, "test", headline, 0.2, 3 MINUTES)
	var/published = SSmarket.news_published
	SSmarket.next_digest = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Сводка по расписанию")
	TEST_ASSERT(findtext(last_body(), MARKET_NEWS_CHANNEL), "Сводка вышла: [last_body()]")
	TEST_ASSERT(abs(SSmarket.next_digest - (world.time + SSmarket.digest_minutes MINUTES)) < 1, "Следующая сводка через digest_minutes")
	for(var/body in new_bodies())
		TEST_ASSERT(!findtext(body, headline), "Заголовок события в новостях до его выхода")
	TEST_ASSERT(!findtext(SSmarket.build_digest(), headline), "Заголовок события в сводке до его выхода")
	flash_ready()
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Новость без вышедшего события")
	company.volatility = 0
	var/price_before = company.price
	event.eta = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 2, "Новость события")
	TEST_ASSERT(company.price > price_before, "Цена сдвинулась вместе с новостью")
	var/body = last_body()
	TEST_ASSERT(findtext(body, headline) && findtext(body, company.ticker), "Заголовок и тикер в новости: [body]")
	TEST_ASSERT(findtext(body, "[round(company.price, 0.01)]"), "Цена после шока в новости: [body]")

/// Статьи канала выходят не чаще раза в news_flash_minutes, сводка вплотную к статье ждёт; пропущенная минута новость не теряет; сводка без перемен не выходит.
/datum/unit_test/economy_news/throttle/Run()
	TEST_ASSERT_NOTNULL(channel, "Нет канала сводки")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		company.volatility = 0
	var/first_headline = "Первая тестовая новость [REF(src)]"
	var/second_headline = "Вторая тестовая новость [REF(src)]"
	var/third_headline = "Третья тестовая новость [REF(src)]"
	var/published = SSmarket.news_published
	SSmarket.schedule_company_event(SSmarket.get_company("PRSP"), "test", first_headline, 0.1, 0)
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Первая новость вышла сразу")
	TEST_ASSERT(findtext(last_body(), first_headline), "Первая новость: [last_body()]")
	SSmarket.schedule_company_event(SSmarket.get_company("AGRO"), "test", second_headline, -0.1, 0)
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Вторая новость вышла раньше news_flash_minutes")
	SSmarket.next_digest = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Сводка вышла вплотную к статье")
	flash_ready()
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 2, "Сводка вышла")
	var/body = last_body()
	TEST_ASSERT(findtext(body, MARKET_NEWS_CHANNEL) && findtext(body, second_headline), "Накопленная новость в сводке: [body]")
	TEST_ASSERT(!findtext(body, first_headline), "Вышедшая новость повторилась в сводке")
	TEST_ASSERT(!length(SSmarket.pending_news), "Очередь новостей не очищена")
	SSmarket.schedule_company_event(SSmarket.get_company("NTRN"), "test", third_headline, 0, 0)
	SSmarket.last_news = world.time - (SSmarket.news_flash_minutes + 3) MINUTES
	SSmarket.next_digest = world.time + 1 MINUTES
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 3, "Новость потерялась после пропущенных минут перед сводкой")
	TEST_ASSERT(findtext(last_body(), third_headline), "Третья новость: [last_body()]")
	flash_ready()
	SSmarket.next_digest = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 3, "Сводка без перемен вышла")
	TEST_ASSERT(SSmarket.next_digest > world.time, "Следующая сводка не назначена")
	SSmarket.station_event("disease_outbreak")
	SSmarket.next_digest = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 4, "Сводка со сменой лидера не вышла")
	TEST_ASSERT(findtext(last_body(), "VYMD"), "Новый лидер роста в сводке: [last_body()]")
	for(var/i in 1 to MARKET_NEWS_PENDING_MAX + 3)
		SSmarket.schedule_company_event(SSmarket.get_company("NTRN"), "test", "Новость [i] [REF(src)]", 0, 0)
		SSmarket.run_due_events()
	TEST_ASSERT_EQUAL(length(SSmarket.pending_news), MARKET_NEWS_PENDING_MAX, "Очередь новостей ограничена")
	TEST_ASSERT(findtext(SSmarket.pending_news[length(SSmarket.pending_news)], "Новость [MARKET_NEWS_PENDING_MAX + 3] "), "Отброшены не самые старые")
	for(var/i in 1 to MARKET_NEWS_KEEP + 5)
		SSmarket.publish("Архив [i]")
	TEST_ASSERT_EQUAL(length(channel.messages), MARKET_NEWS_KEEP, "Канал хранит не больше [MARKET_NEWS_KEEP] статей")
	TEST_ASSERT_EQUAL(last_body(), "Архив [MARKET_NEWS_KEEP + 5]", "Обрезаны не самые старые")

/// Горячие товары сдвига выходят одной статьёй с множителем, контрабанда горячей не бывает; остывший до выпуска не объявляется; сводка перечисляет горячие.
/datum/unit_test/economy_news/hot/Run()
	TEST_ASSERT_NOTNULL(channel, "Нет канала сводки")
	var/published = SSmarket.news_published
	SSmarket.hot_chance = 100
	SSmarket.next_shift = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Горячие товары сдвига - одной статьёй")
	var/body = last_body()
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	TEST_ASSERT(metals.hot_mult > 1, "Металлы стали горячими")
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		if(id == COMMODITY_CONTRABAND)
			TEST_ASSERT(!findtext(body, commodity.name), "Контрабанда горячая в новости: [body]")
			continue
		TEST_ASSERT(findtext(body, commodity.name), "Горячий товар [id] не в новости: [body]")
	TEST_ASSERT(findtext(body, "×[round(metals.hot_mult, 0.1)]"), "Множитель горячего товара: [body]")
	var/digest = SSmarket.build_digest()
	TEST_ASSERT(findtext(digest, metals.name) && findtext(digest, "×[round(metals.hot_mult, 0.1)]"), "Горячий товар в сводке: [digest]")
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.hot_mult = 1
		commodity.hot_shifts_left = 0
	SSmarket.last_news = world.time
	SSmarket.next_shift = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Новость горячих вышла раньше news_flash_minutes")
	var/datum/commodity/food = SSmarket.get_commodity(COMMODITY_FOOD)
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.hot_shifts_left = commodity == metals ? 1 : 10
	SSmarket.hot_chance = 0
	SSmarket.next_shift = world.time
	flash_ready()
	SSmarket.fire()
	TEST_ASSERT_EQUAL(metals.hot_mult, 1, "Металлы остыли")
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 2, "Отложенная новость горячих вышла")
	body = last_body()
	TEST_ASSERT(findtext(body, food.name), "Горячие продукты в новости: [body]")
	TEST_ASSERT(!findtextEx(body, metals.name), "Остывший товар объявлен горячим: [body]")
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.hot_mult = 1
		commodity.hot_shifts_left = 0
	TEST_ASSERT(!findtext(SSmarket.build_digest(), food.name), "Сводка без горячих товаров называет товар")

/// Открытие партнёра покупкой у НТ Логистики выходит новостью; контрабандный партнёр не объявляется и не засчитывается в открытие Федерации.
/datum/unit_test/economy_news/partner_unlock/Run()
	TEST_ASSERT_NOTNULL(channel, "Нет канала сводки")
	var/datum/trade_partner/nt = SSmarket.get_partner("nt_logistics")
	var/datum/trade_partner/nakamura = SSmarket.get_partner("nakamura")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/trade_partner/free_traders = SSmarket.get_partner("free_traders")
	var/datum/supply_pack/pack
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/candidate = SSshuttle.supply_packs[pack_id]
		if(nt.sells_pack(candidate))
			pack = candidate
			break
	TEST_ASSERT_NOTNULL(pack, "НТ Логистика продаёт пак")
	var/published = SSmarket.news_published
	nt.reputation = PARTNER_TIER_STEP * 2 - 0.01
	nt.note_purchase(pack, 100)
	TEST_ASSERT(nakamura.unlocked, "Покупка открыла Накамуру")
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Новость об открытии партнёра")
	TEST_ASSERT(findtext(last_body(), nakamura.name) && findtext(last_body(), nakamura.desc), "Название и описание партнёра: [last_body()]")
	nt.reputation = 0
	prospectors.reputation = PARTNER_TIER_STEP * 2
	TEST_ASSERT(SSmarket.open_contraband_partners(), "Взлом не открыл Вольных торговцев")
	free_traders.note_sale(PARTNER_TIER_STEP * 2 / SSmarket.reputation_per_credit)
	TEST_ASSERT(free_traders.tier() >= 2 && prospectors.tier() >= 2, "Две ступени у Гильдии и Вольных торговцев")
	var/datum/trade_partner/sol = SSmarket.get_partner("sol_federation")
	TEST_ASSERT(!sol.unlocked, "Контрабандный партнёр открыл Солнечную Федерацию")
	flash_ready()
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Открытие контрабандного партнёра объявлено")
	TEST_ASSERT(!length(SSmarket.pending_news), "Контрабандный партнёр в очереди новостей")

/// Сводка: лидеры роста и падения, остановленные торги, невзятые спецзаказы без контрабандных, индекс цен.
/datum/unit_test/economy_news/digest/Run()
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/trade_partner/free_traders = SSmarket.get_partner("free_traders")
	prospectors.reputation = PARTNER_TIER_STEP * 3 - 0.01
	prospectors.note_sale(100)
	SSmarket.open_contraband_partners()
	TEST_ASSERT(free_traders.unlocked, "Вольные торговцы открыты")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		company.volatility = 0
	SSmarket.fire()
	var/datum/stock_company/rising = SSmarket.get_company("NKMR")
	var/datum/stock_company/falling = SSmarket.get_company("AGRO")
	var/datum/stock_company/halted = SSmarket.get_company("CYBS")
	SSmarket.schedule_company_event(rising, "test", "рост", 0.2, 0)
	SSmarket.schedule_company_event(falling, "test", "падение", -0.2, 0)
	SSmarket.schedule_company_event(halted, "test", "крах", -0.9, 0)
	SSmarket.schedule_company_event(halted, "test", "крах", -0.9, 0)
	SSmarket.fire()
	SSmarket.fire()
	TEST_ASSERT(halted.is_halted(), "Крах остановил торги")
	var/datum/market_offer/open_offer = prospectors.new_offer()
	var/datum/market_offer/taken_offer = vey.new_offer()
	var/datum/market_offer/contraband_offer = free_traders.new_offer()
	TEST_ASSERT(open_offer && taken_offer && contraband_offer, "Спецзаказы созданы")
	taken_offer.accept()
	var/digest = SSmarket.build_digest(list("Новость с прошлого выпуска"))
	TEST_ASSERT(findtext(digest, "[rising.ticker] ([rising.name]) +20%"), "Лидер роста: [digest]")
	TEST_ASSERT(findtext(digest, "[falling.ticker] ([falling.name]) −20%"), "Лидер падения: [digest]")
	TEST_ASSERT(findtext(digest, "Торги остановлены: [halted.ticker]"), "Остановленная компания: [digest]")
	TEST_ASSERT(!findtext(digest, "[halted.ticker] ([halted.name])"), "Остановленная компания среди лидеров: [digest]")
	TEST_ASSERT(findtext(digest, "[prospectors.name] - [open_offer.wanted_name], [open_offer.quantity] шт."), "Невзятый спецзаказ: [digest]")
	TEST_ASSERT(!findtext(digest, "[vey.name] - "), "Взятый спецзаказ в сводке: [digest]")
	TEST_ASSERT(!findtext(digest, "[free_traders.name] - "), "Контрабандный спецзаказ в сводке: [digest]")
	TEST_ASSERT(findtext(digest, "×[round(SSeconomy.price_index(), 0.01)]"), "Индекс цен: [digest]")
	TEST_ASSERT(findtext(digest, "Новость с прошлого выпуска"), "Накопленные новости: [digest]")

/// Обвал и бум рынка сектора двигают все акции и выходят новостью.
/datum/unit_test/economy_news/station_market_events/Run()
	TEST_ASSERT_NOTNULL(channel, "Нет канала сводки")
	var/published = SSmarket.news_published
	var/datum/stock_company/company = SSmarket.get_company("NTRN")
	var/price_before = company.price
	SSmarket.station_event("market_crash")
	TEST_ASSERT(company.price < price_before, "Обвал сдвинул акции")
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 1, "Новость обвала")
	TEST_ASSERT(findtext(last_body(), "Обвал"), "Текст обвала: [last_body()]")
	SSmarket.station_event("sector_boom")
	flash_ready()
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 2, "Новость бума")
	TEST_ASSERT(findtext(last_body(), "Бум"), "Текст бума: [last_body()]")
	SSmarket.station_event("meteors")
	flash_ready()
	SSmarket.fire()
	TEST_ASSERT_EQUAL(SSmarket.news_published, published + 2, "Метеоры уже объявлены станции, рынок их не дублирует")

/// news_flash_minutes больше половины digest_minutes - ошибка настройки, окно срочных новостей ужимается до половины.
/datum/unit_test/economy_news/config/Run()
	var/list/errors = SSmarket.load_settings(list("digest_minutes" = 10, "news_flash_minutes" = 6))
	var/found = FALSE
	for(var/error in errors)
		if(findtext(error, "market.news_flash_minutes"))
			found = TRUE
	TEST_ASSERT(found, "Нет ошибки сочетания: [jointext(errors, "; ")]")
	TEST_ASSERT_EQUAL(SSmarket.digest_minutes, 10, "Интервал сводки")
	TEST_ASSERT_EQUAL(SSmarket.news_flash_minutes, 5, "Окно срочных новостей - половина сводки")
	errors = SSmarket.load_settings(list("digest_minutes" = 14, "news_flash_minutes" = 7))
	for(var/error in errors)
		TEST_ASSERT(!findtext(error, "news_flash_minutes"), "Ошибка при допустимом сочетании: [error]")
	TEST_ASSERT_EQUAL(SSmarket.news_flash_minutes, 7, "Допустимое окно принято")
