/datum/controller/subsystem/market
	/// На сколько процентов к базе сдвигается сохранённое состояние сектора при загрузке
	var/persist_decay = 20
#ifdef UNIT_TESTS
	var/state_path
#else
	var/state_path = MARKET_STATE_PATH
#endif
	var/round_end_hooked = FALSE

/// Колбэк конца раунда через глобальный proc: после Recover() он попадает в новый экземпляр SSmarket.
/proc/market_save_sector_state()
	SSmarket.save_state()

/// Загрузка состояния сектора при инициализации и подписка на его запись в конце раунда.
/datum/controller/subsystem/market/proc/restore_sector()
#ifdef UNIT_TESTS
	if(!state_path)
		state_path = "[GLOB.econ_sector_test_dir]live.json"
#endif
	load_state()
	seed_history()
	if(round_end_hooked)
		return
	round_end_hooked = TRUE
	SSticker.OnRoundend(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(market_save_sector_state)))

/// Цена на старте смены - первая точка тренда: иначе график появляется только со второго сдвига рынка.
/datum/controller/subsystem/market/proc/seed_history()
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		if(!length(commodity.history))
			commodity.history += commodity.price_factor

/// Состояние сектора для следующего раунда. Счета и акции игроков, очередь событий, сдвиг цен от работы отделов, спецзаказы, склады, новости и открытие контрабандного партнёра сюда не входят.
/datum/controller/subsystem/market/proc/serialize_state()
	var/list/saved_commodities = list()
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		saved_commodities[id] = list("trend" = commodity.trend, "demand" = commodity.demand)
	var/list/saved_companies = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company.is_index)
			continue
		if(company.halted_until)
			saved_companies[ticker] = list("price_ratio" = STOCK_RELIST_RATIO, "event_mult" = 1, "trade_volume" = 0)
		else
			var/list/refuted = pending_refutation(company)
			saved_companies[ticker] = list("price_ratio" = company.price * refuted[1] / (1 + company.work_boost) / company.base_price, "event_mult" = company.event_mult * refuted[2], "trade_volume" = company.trade_volume)
	var/list/saved_partners = list()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		saved_partners[id] = list("reputation" = partner.reputation, "wealth" = partner.wealth, "unlocked" = partner.unlocked && !partner.contraband)
	return list("version" = MARKET_STATE_VERSION, "price_index" = price_index, "commodities" = saved_commodities, "companies" = saved_companies, "partners" = saved_partners, "slot_jackpot" = slot_jackpot_total())

/// Накладывает состояние, сдвинутое на decay процентов к базе одним скачком; FALSE - не объект или чужая версия. Неверные поля пропускаются.
/datum/controller/subsystem/market/proc/apply_state(list/state, decay)
	if(!islist(state) || state["version"] != MARKET_STATE_VERSION)
		return FALSE
	var/keep = (100 - decay) / 100
	var/list/unknown = list()
	for(var/key in state)
		if(!(key in list("version", "price_index", "commodities", "companies", "partners", "slot_jackpot")))
			unknown += "[key]"
	// Джекпот автоматов переходит в следующую смену целиком, без сдвига к базе
	var/saved_jackpot = state_number(state, "slot_jackpot", "sector")
	if(!isnull(saved_jackpot))
		slot_jackpot_carried = clamp(round(saved_jackpot), 0, SLOT_JACKPOT_CARRY_MAX)
	var/saved_index = state_number(state, "price_index", "sector")
	if(!isnull(saved_index))
		price_index = clamp(1 + (saved_index - 1) * keep, MARKET_INDEX_MIN, MARKET_INDEX_MAX)
	var/list/saved_commodities = state_section(state, "commodities")
	for(var/id in saved_commodities)
		var/list/entry = state_entry(saved_commodities, id, commodities, list("trend", "demand"), "commodities", unknown)
		if(!entry)
			continue
		var/datum/commodity/commodity = commodities[id]
		var/trend = state_number(entry, "trend", id)
		if(!isnull(trend))
			commodity.trend = 1 + (clamp(trend, MARKET_PRICE_MIN, MARKET_PRICE_MAX) - 1) * keep
		var/demand = state_number(entry, "demand", id)
		if(!isnull(demand))
			commodity.demand = 1 - (1 - clamp(demand, 0, 1)) * keep
		commodity.recompute()
	var/list/saved_companies = state_section(state, "companies")
	for(var/ticker in saved_companies)
		var/list/entry = state_entry(saved_companies, ticker, companies, list("price_ratio", "event_mult", "trade_volume"), "companies", unknown)
		if(!entry)
			continue
		var/datum/stock_company/company = companies[ticker]
		var/ratio = state_number(entry, "price_ratio", ticker, TRUE)
		if(!isnull(ratio))
			company.set_price(company.base_price * (1 + (min(ratio, STOCK_PRICE_MAX_RATIO) - 1) * keep))
		var/event_mult = state_number(entry, "event_mult", ticker, TRUE)
		if(!isnull(event_mult))
			company.event_mult = 1 + (min(event_mult, STOCK_EVENT_MULT_MAX) - 1) * keep
		var/trade_volume = state_number(entry, "trade_volume", ticker)
		if(!isnull(trade_volume))
			company.trade_volume = clamp(trade_volume, 0, STOCK_TRADE_SCALE * STOCK_TRADE_BOOST_MAX) * keep
	var/list/saved_partners = state_section(state, "partners")
	for(var/id in saved_partners)
		var/list/entry = state_entry(saved_partners, id, partners, list("reputation", "wealth", "unlocked"), "partners", unknown)
		if(!entry)
			continue
		var/datum/trade_partner/partner = partners[id]
		var/reputation = state_number(entry, "reputation", id)
		if(!isnull(reputation))
			partner.reputation = clamp(reputation, 0, PARTNER_REPUTATION_MAX) * keep
		var/wealth = state_number(entry, "wealth", id)
		if(!isnull(wealth))
			partner.wealth = partner.start_wealth + (clamp(wealth, 0, partner.start_wealth * MARKET_STATE_WEALTH_CAP_MULT) - partner.start_wealth) * keep
		if(entry["unlocked"] == TRUE && !partner.contraband)
			partner.unlocked = TRUE
	if(length(unknown))
		log_econ("Состояние сектора: пропущены неизвестные ключи [jointext(unknown, ", ")]")
	return TRUE

/datum/controller/subsystem/market/proc/state_section(list/state, key)
	var/list/section = state[key]
	return islist(section) ? section : list()

/// Запись известного объекта из раздела состояния или null; неизвестные id и поля дописываются в unknown.
/datum/controller/subsystem/market/proc/state_entry(list/section, id, list/known, list/fields, section_name, list/unknown)
	if(!istext(id) || !known[id])
		unknown += "[section_name].[id]"
		return null
	var/list/entry = section[id]
	if(!islist(entry))
		unknown += "[section_name].[id]"
		return null
	for(var/key in entry)
		if(!(key in fields))
			unknown += "[section_name].[id].[key]"
	return entry

/// Конечное число из записи состояния; иное или неположительное при positive - null и строка в лог.
/datum/controller/subsystem/market/proc/state_number(list/entry, key, owner, positive = FALSE)
	var/value = entry[key]
	if(isnull(value))
		return null
	if(IS_FINITE(value) && (!positive || value > 0))
		return value
	log_econ("Состояние сектора: [owner].[key] = [value] пропущено")
	return null

/// Пишет через временный файл; прошлое состояние остаётся в .bak, из него читается битый основной файл.
/datum/controller/subsystem/market/proc/save_state(path)
	if(!path)
		path = state_path
	var/temp_path = "[path].tmp"
	fdel(temp_path)
	rustg_file_write(json_encode(serialize_state()), temp_path)
	if(!fexists(temp_path))
		log_econ("Состояние сектора не записано в [path]")
		return FALSE
	if(fexists(path))
		fcopy(path, "[path].bak")
	. = fcopy(temp_path, path)
	fdel(temp_path)
	if(!.)
		log_econ("Состояние сектора не скопировано в [path]")
		return FALSE
	log_econ("Состояние сектора записано в [path]")
	return TRUE

/datum/controller/subsystem/market/proc/load_state(path)
	if(!path)
		path = state_path
	if(!fexists(path))
		return FALSE
	if(load_state_file(path))
		return TRUE
	return fexists("[path].bak") && load_state_file("[path].bak")

/datum/controller/subsystem/market/proc/load_state_file(path)
	var/list/state
	try
		state = json_decode(file2text(path))
	catch(var/exception/error)
		log_econ("Состояние сектора [path] не прочитано: [error]")
		return FALSE
	if(!apply_state(state, persist_decay))
		log_econ("Состояние сектора [path] отвергнуто: нужен объект версии [MARKET_STATE_VERSION]")
		return FALSE
	log_econ("Состояние сектора загружено из [path], затухание [persist_decay]%")
	return TRUE

/// Сектор к базе, файлы состояния удаляются; позиции держателей акций сохраняют стоимость.
/datum/controller/subsystem/market/proc/reset_sector(path)
	if(!path)
		path = state_path
	fdel(path)
	fdel("[path].bak")
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		commodity.trend = 1
		commodity.demand = 1
		commodity.noise = 0
		commodity.hot_mult = 1
		commodity.hot_shifts_left = 0
		commodity.shortage_shifts_left = 0
		commodity.shortage_trend = 1
		commodity.history = list()
		commodity.recompute()
	seed_history()
	price_index = 1
	QDEL_LIST(scheduled_events)
	pending_news = list()
	pending_hot = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		var/old_price = company.price
		company.halted_until = 0
		company.price = company.base_price
		company.event_mult = 1
		company.trade_volume = 0
		company.work_boost = 0
		company.work_news_boost = 0
		company.history = list()
		company.moves = list()
		if(abs(old_price - company.price) > STOCK_PRICE_EPSILON)
			consolidate_shares(company, old_price / company.price, "Сброс сектора")
	QDEL_LIST_ASSOC_VAL(partners)
	var/list/section = SSeconomy.settings.raw?["market"]
	for(var/error in load_partners(islist(section) ? section["partners"] : null))
		GLOB.economy_config_errors |= error
		log_config("economy.json: [error]")
	slot_jackpot_carried = 0
	log_econ("Сектор сброшен к базе")
	INVOKE_ASYNC(src, PROC_REF(refresh_vending_prices))
