/// Свой каталог на каждый параллельный мир тестов: шарды не трут чужие файлы сектора.
GLOBAL_VAR_INIT(econ_sector_test_dir, "data/unit_test_sector/[unit_test_shard_subdir()]")

#define SECTOR_TEST_DIR GLOB.econ_sector_test_dir
#define SECTOR_TEST_PATH "[SECTOR_TEST_DIR]state.json"
#define SECTOR_TEST_RESET_PATH "[SECTOR_TEST_DIR]reset.json"

/datum/unit_test/economy_market/sector
	abstract_type = /datum/unit_test/economy_market/sector

/datum/unit_test/economy_market/sector/Destroy()
	fdel(SECTOR_TEST_DIR)
	return ..()

/datum/unit_test/economy_market/sector/proc/keep_share()
	return (100 - SSmarket.persist_decay) / 100

/// Файл хранит только состояние сектора; сброс возвращает базу, загрузка сдвигает сохранённое на persist_decay к базе.
/datum/unit_test/economy_market/sector/roundtrip/Run()
	var/list/market_section = SSeconomy.settings.raw?["market"]
	var/datum/controller/subsystem/market/market = SSmarket
	var/configured = (islist(market_section) && isnum(market_section["persist_decay"])) ? market_section["persist_decay"] : initial(market.persist_decay)
	TEST_ASSERT_EQUAL(SSmarket.persist_decay, configured, "Затухание из конфига")
	var/keep = keep_share()
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	var/datum/stock_company/nanotrasen = SSmarket.get_company("NTRN")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/trade_partner/nakamura = SSmarket.get_partner("nakamura")
	var/datum/trade_partner/free_traders = SSmarket.get_partner("free_traders")
	TEST_ASSERT(!nakamura.unlocked && !free_traders.unlocked, "Накамура и Вольные торговцы закрыты со старта")
	TEST_ASSERT(free_traders.contraband, "Вольные торговцы - контрабандный партнёр")
	var/start_wealth = prospectors.start_wealth
	TEST_ASSERT(start_wealth > 0, "Стартовый капитал старателей из конфига")
	metals.trend = 2
	metals.demand = 0.5
	SSmarket.price_index = 1.4
	vey.price = vey.base_price * 3
	vey.event_mult = 2
	vey.trade_volume = 1000
	nanotrasen.price = nanotrasen.base_price * 0.03
	nanotrasen.halted_until = world.time + STOCK_HALT_TIME
	prospectors.reputation = 500
	prospectors.wealth = start_wealth * 5 + 0.5
	nakamura.unlocked = TRUE
	free_traders.unlocked = TRUE
	prospectors.new_offer()
	fdel(SECTOR_TEST_PATH)
	text2file("{}", SECTOR_TEST_PATH)
	SSmarket.save_state(SECTOR_TEST_PATH)
	TEST_ASSERT(fexists(SECTOR_TEST_PATH), "Файл состояния не записан")
	var/list/state = json_decode(file2text(SECTOR_TEST_PATH))
	TEST_ASSERT(islist(state), "Файл состояния - объект JSON")
	TEST_ASSERT_EQUAL(jointext(state, ","), "version,price_index,commodities,companies,partners", "Разделы файла")
	var/list/saved_partners = state["partners"]
	var/list/saved_prospectors = saved_partners["prospectors"]
	TEST_ASSERT_EQUAL(jointext(saved_prospectors, ","), "reputation,wealth,unlocked", "Поля партнёра в файле")
	var/list/saved_companies = state["companies"]
	var/list/saved_vey = saved_companies["VYMD"]
	TEST_ASSERT_EQUAL(jointext(saved_vey, ","), "price_ratio,event_mult,trade_volume", "Поля компании в файле")

	SSmarket.reset_sector(SECTOR_TEST_RESET_PATH)
	prospectors = SSmarket.get_partner("prospectors")
	nakamura = SSmarket.get_partner("nakamura")
	free_traders = SSmarket.get_partner("free_traders")
	TEST_ASSERT(abs(metals.trend - 1) < 0.001 && abs(metals.demand - 1) < 0.001, "Сброс товара: [metals.trend], [metals.demand]")
	TEST_ASSERT(abs(vey.price - vey.base_price) < 0.01, "Сброс цены акции: [vey.price]")
	TEST_ASSERT(!nakamura.unlocked && prospectors.reputation == 0 && !length(prospectors.offers), "Сброс партнёров")
	TEST_ASSERT(abs(prospectors.wealth - start_wealth) < 1, "Сброс капитала: [prospectors.wealth]")
	vey.base_price *= 2

	TEST_ASSERT(SSmarket.load_state(SECTOR_TEST_PATH), "Состояние не загружено")
	TEST_ASSERT(abs(metals.trend - (1 + keep)) < 0.001, "Тренд: [metals.trend]")
	TEST_ASSERT(abs(metals.demand - (1 - 0.5 * keep)) < 0.001, "Спрос: [metals.demand]")
	TEST_ASSERT(abs(metals.price_factor - (1 + keep)) < 0.001, "Цена товара не пересчитана: [metals.price_factor]")
	TEST_ASSERT(abs(SSmarket.price_index - (1 + 0.4 * keep)) < 0.001, "Индекс цен: [SSmarket.price_index]")
	TEST_ASSERT(abs(vey.price - vey.base_price * (1 + 2 * keep)) < 0.01, "Цена акции не относительно новой базы: [vey.price]")
	TEST_ASSERT(abs(vey.event_mult - (1 + keep)) < 0.001, "Множитель событий: [vey.event_mult]")
	TEST_ASSERT(abs(vey.trade_volume - 1000 * keep) < 0.1, "Объём торговли: [vey.trade_volume]")
	TEST_ASSERT(!nanotrasen.is_halted(), "Остановленные торги переходят в раунд")
	TEST_ASSERT(abs(nanotrasen.price - nanotrasen.base_price * (1 + (STOCK_RELIST_RATIO - 1) * keep)) < 0.01, "Банкрот сохраняется по цене повторного листинга: [nanotrasen.price]")
	TEST_ASSERT(abs(prospectors.reputation - 500 * keep) < 0.01, "Репутация: [prospectors.reputation]")
	TEST_ASSERT(abs(prospectors.wealth - (start_wealth + (start_wealth * 4 + 0.5) * keep)) < 0.01, "Капитал: [prospectors.wealth]")
	TEST_ASSERT(nakamura.unlocked, "Открытый партнёр закрылся")
	TEST_ASSERT(!free_traders.unlocked, "Контрабандный партнёр остался открыт после раунда")
	TEST_ASSERT(!length(prospectors.offers), "Спецзаказ пережил раунд")
	TEST_ASSERT(findtext(econ_cargo_market_help(), "на [SSmarket.persist_decay]% к исходным"), "Справка снабжения не называет затухание")

/// Загруженная цена акции сразу стоит на затухшем уровне и без шума не дрейфует к базе.
/datum/unit_test/economy_market/sector/no_drift/Run()
	SSmarket.company_event_chance = 0
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		company.volatility = 0
	var/keep = keep_share()
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	vey.price = vey.base_price * 3
	fdel(SECTOR_TEST_DIR)
	TEST_ASSERT(SSmarket.save_state(SECTOR_TEST_PATH) && fexists(SECTOR_TEST_PATH), "Каталог состояния не создан при записи")
	SSmarket.reset_sector(SECTOR_TEST_RESET_PATH)
	TEST_ASSERT(SSmarket.load_state(SECTOR_TEST_PATH), "Состояние не загружено")
	var/loaded = vey.price
	TEST_ASSERT(abs(loaded - vey.base_price * (1 + 2 * keep)) < 0.01, "Затухание не скачком при загрузке: [loaded]")
	for(var/i in 1 to 30)
		SSmarket.tick_stocks()
	TEST_ASSERT(abs(vey.price - loaded) < 0.01, "Цена дрейфует после загрузки: [loaded] -> [vey.price]")

/// Конец раунда пишет состояние в state_path через глобальный колбэк, инициализация читает его оттуда.
/datum/unit_test/economy_market/sector/live_path/Run()
	TEST_ASSERT_EQUAL(findtext(SSmarket.state_path, SECTOR_TEST_DIR), 1, "Тесты пишут не в тестовый каталог: [SSmarket.state_path]")
	var/list/hooks = list()
	for(var/datum/callback/callback as anything in SSticker.round_end_events)
		if(callback.delegate == GLOBAL_PROC_REF(market_save_sector_state))
			hooks += callback
	TEST_ASSERT_EQUAL(length(hooks), 1, "Рынок один раз подписан на конец раунда")
	var/datum/callback/save = hooks[1]
	TEST_ASSERT(save.object == GLOBAL_PROC, "Колбэк конца раунда привязан к экземпляру подсистемы")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.trend = 2
	fdel(SSmarket.state_path)
	save.InvokeAsync()
	TEST_ASSERT(fexists(SSmarket.state_path), "Конец раунда не записал состояние")
	SSmarket.reset_sector(SECTOR_TEST_RESET_PATH)
	SSmarket.restore_sector()
	TEST_ASSERT(abs(metals.trend - (1 + keep_share())) < 0.001, "Инициализация не прочитала состояние: [metals.trend]")
	var/count = 0
	for(var/datum/callback/callback as anything in SSticker.round_end_events)
		if(callback.delegate == GLOBAL_PROC_REF(market_save_sector_state))
			count++
	TEST_ASSERT_EQUAL(count, 1, "Повторная загрузка подписала конец раунда второй раз")

/// Битый основной файл читается из .bak с прошлым состоянием.
/datum/unit_test/economy_market/sector/backup/Run()
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.trend = 2
	SSmarket.save_state(SECTOR_TEST_PATH)
	metals.trend = 1.5
	SSmarket.save_state(SECTOR_TEST_PATH)
	fdel(SECTOR_TEST_PATH)
	text2file("{\"version\": 1, \"commod", SECTOR_TEST_PATH)
	SSmarket.reset_sector(SECTOR_TEST_RESET_PATH)
	TEST_ASSERT(SSmarket.load_state(SECTOR_TEST_PATH), "Не прочитан .bak при битом основном файле")
	TEST_ASSERT(abs(metals.trend - (1 + keep_share())) < 0.001, "Из .bak не прошлое состояние: [metals.trend]")
	SSmarket.reset_sector(SECTOR_TEST_PATH)
	TEST_ASSERT(!fexists("[SECTOR_TEST_PATH].bak"), "Сброс оставил .bak")

/// Нет файла, битый JSON, чужая версия, не объект - отказ без изменений; мусор, бесконечности и лишние ключи пропускаются, числа зажимаются.
/datum/unit_test/economy_market/sector/bad_file/Run()
	var/keep = keep_share()
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/trade_partner/nakamura = SSmarket.get_partner("nakamura")
	TEST_ASSERT(!SSmarket.load_state(SECTOR_TEST_PATH), "Нет файла")
	for(var/bad in list("{не json", "{\"version\": 999, \"commodities\": {\"metals\": {\"trend\": 2}}}", "\[1, 2\]", ""))
		fdel(SECTOR_TEST_PATH)
		text2file(bad, SECTOR_TEST_PATH)
		TEST_ASSERT(!SSmarket.load_state(SECTOR_TEST_PATH), "Принят файл: [bad]")
		TEST_ASSERT(abs(metals.trend - 1) < 0.001, "Отвергнутый файл изменил тренд: [bad]")
	fdel(SECTOR_TEST_PATH)
	text2file("{\"version\": 1, \"extra\": 1, \"price_index\": \"x\", \"commodities\": {\"metals\": {\"trend\": \"x\", \"demand\": 7, \"color\": 1}, \"unknown\": {\"trend\": 2}}, \"companies\": {\"VYMD\": {\"price\": 300, \"price_ratio\": -5, \"event_mult\": null}}, \"partners\": {\"prospectors\": {\"reputation\": 99999, \"wealth\": \"lots\", \"unlocked\": \"yes\"}, \"nakamura\": 5}}", SECTOR_TEST_PATH)
	var/wealth = prospectors.wealth
	TEST_ASSERT(SSmarket.load_state(SECTOR_TEST_PATH), "Файл своей версии с мусорными полями отвергнут целиком")
	TEST_ASSERT(abs(metals.trend - 1) < 0.001 && abs(metals.demand - 1) < 0.001, "Мусор в товаре: [metals.trend], [metals.demand]")
	TEST_ASSERT(abs(SSmarket.price_index - 1) < 0.001, "Мусор в индексе: [SSmarket.price_index]")
	TEST_ASSERT(abs(vey.price - vey.base_price) < 0.01 && abs(vey.event_mult - 1) < 0.001, "Мусор в компании: [vey.price], [vey.event_mult]")
	TEST_ASSERT(abs(prospectors.reputation - PARTNER_REPUTATION_MAX * keep) < 0.01, "Репутация не зажата: [prospectors.reputation]")
	TEST_ASSERT(abs(prospectors.wealth - wealth) < 1 && !nakamura.unlocked, "Мусор в партнёрах")

	SSmarket.reset_sector(SECTOR_TEST_RESET_PATH)
	prospectors = SSmarket.get_partner("prospectors")
	wealth = prospectors.wealth
	fdel(SECTOR_TEST_PATH)
	text2file("{\"version\": 1, \"price_index\": 1e999, \"commodities\": {\"metals\": {\"trend\": 1e999, \"demand\": -1e999}}, \"companies\": {\"VYMD\": {\"price_ratio\": 1e999, \"event_mult\": 1e999, \"trade_volume\": 1e999}}, \"partners\": {\"prospectors\": {\"reputation\": 1e999, \"wealth\": 1e999}}}", SECTOR_TEST_PATH)
	SSmarket.load_state(SECTOR_TEST_PATH)
	TEST_ASSERT(abs(metals.trend - 1) < 0.001 && abs(metals.demand - 1) < 0.001 && abs(SSmarket.price_index - 1) < 0.001, "Бесконечность в товаре: [metals.trend], [metals.demand], [SSmarket.price_index]")
	TEST_ASSERT(abs(vey.price - vey.base_price) < 0.01 && abs(vey.event_mult - 1) < 0.001 && vey.trade_volume == 0, "Бесконечность в компании: [vey.price], [vey.event_mult], [vey.trade_volume]")
	TEST_ASSERT(prospectors.reputation == 0 && abs(prospectors.wealth - wealth) < 1, "Бесконечность в партнёре: [prospectors.reputation], [prospectors.wealth]")

	fdel(SECTOR_TEST_PATH)
	text2file("{\"version\": 1, \"companies\": {\"VYMD\": {\"trade_volume\": 1e9}}, \"partners\": {\"prospectors\": {\"wealth\": 1e12}}}", SECTOR_TEST_PATH)
	TEST_ASSERT(SSmarket.load_state(SECTOR_TEST_PATH), "Большие числа отвергнуты")
	TEST_ASSERT(abs(vey.trade_volume - STOCK_TRADE_SCALE * STOCK_TRADE_BOOST_MAX * keep) < 0.1, "Объём торговли не зажат: [vey.trade_volume]")
	var/wealth_cap = prospectors.start_wealth * MARKET_STATE_WEALTH_CAP_MULT
	TEST_ASSERT(abs(prospectors.wealth - (prospectors.start_wealth + (wealth_cap - prospectors.start_wealth) * keep)) < 1, "Капитал не зажат: [prospectors.wealth]")

	var/datum/controller/subsystem/market/market = SSmarket
	var/list/errors = SSmarket.load_settings(list("persist_decay" = 150))
	TEST_ASSERT(findtext(jointext(errors, ";"), "persist_decay"), "Нет ошибки неверного persist_decay")
	TEST_ASSERT_EQUAL(SSmarket.persist_decay, initial(market.persist_decay), "Неверный persist_decay не откатился к встроенному")

/// Сброс сектора удаляет файл, очередь событий, новости и историю, возвращает базу и снимает дефицит; позиции держателей акций сохраняют стоимость.
/datum/unit_test/economy_market/sector/reset/Run()
	var/datum/stock_company/agro = SSmarket.get_company("AGRO")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	var/datum/commodity/fuel = SSmarket.get_commodity(COMMODITY_FUEL)
	fuel.start_shortage(2, 5)
	var/datum/bank_account/holder = new("econ_test_sector_holder")
	allocated += holder
	holder.shares["AGRO"] = 100
	holder.cost_basis["AGRO"] = 1000
	agro.price = agro.base_price * 0.5
	agro.event_mult = 0.5
	agro.trade_volume = 3000
	agro.halted_until = world.time + STOCK_HALT_TIME
	agro.history += agro.price
	var/value_before = 100 * agro.price
	metals.trend = 2
	metals.hot_mult = 2
	metals.hot_shifts_left = 3
	metals.history += 2
	SSmarket.price_index = 1.3
	SSmarket.schedule_company_event(agro, "test", "test", 0.1, 1 MINUTES)
	SSmarket.pending_news += "test"
	SSmarket.pending_hot += COMMODITY_METALS
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	prospectors.reputation = 600
	text2file("{}", SECTOR_TEST_RESET_PATH)
	SSmarket.reset_sector(SECTOR_TEST_RESET_PATH)
	TEST_ASSERT(!fexists(SECTOR_TEST_RESET_PATH), "Файл состояния не удалён")
	TEST_ASSERT(abs(agro.price - agro.base_price) < 0.01 && !agro.is_halted(), "Акция не сброшена: [agro.price]")
	TEST_ASSERT(abs(agro.event_mult - 1) < 0.001 && agro.trade_volume == 0, "Множитель и объём не сброшены")
	TEST_ASSERT_EQUAL(holder.shares["AGRO"], 50, "Акции держателя не консолидированы по новой цене")
	TEST_ASSERT(holder.shares["AGRO"] * agro.price <= value_before + 0.01, "Позиция подорожала от сброса")
	TEST_ASSERT(abs(metals.price_factor - 1) < 0.001 && metals.hot_mult == 1 && !metals.hot_shifts_left, "Товар не сброшен")
	TEST_ASSERT(!length(metals.history) && !length(agro.history), "История не очищена")
	TEST_ASSERT(!fuel.shortage_shifts_left, "Дефицит пережил сброс сектора")
	fuel.shift(0)
	TEST_ASSERT(fuel.trend < 1.5, "Сдвиг после сброса вернул цену дефицита: тренд [fuel.trend]")
	TEST_ASSERT(!length(SSmarket.scheduled_events), "Очередь событий не очищена")
	TEST_ASSERT(!length(SSmarket.pending_news) && !length(SSmarket.pending_hot), "Новости в ожидании не очищены")
	TEST_ASSERT(abs(SSmarket.price_index - 1) < 0.001, "Индекс цен не сброшен")
	prospectors = SSmarket.get_partner("prospectors")
	TEST_ASSERT_EQUAL(prospectors.reputation, 0, "Репутация не сброшена")

#undef SECTOR_TEST_DIR
#undef SECTOR_TEST_PATH
#undef SECTOR_TEST_RESET_PATH
