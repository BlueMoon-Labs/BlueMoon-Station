SUBSYSTEM_DEF(market)
	name = "Market"
	wait = 1 MINUTES
	init_order = INIT_ORDER_MARKET
	runlevels = RUNLEVEL_GAME
	/// id -> /datum/commodity
	var/list/commodities = list()
	/// Сглаженная средняя цена потребительских товаров
	var/price_index = 1
	var/next_shift = 0
	var/shift_count = 0
	var/shift_minutes = 5
	/// Шанс в процентах, что остывший товар станет горячим за сдвиг
	var/hot_chance = 4
	/// id -> /datum/trade_partner
	var/list/partners = list()
	var/partner_restock_minutes = 7
	var/partner_stock_default = 5
	var/reputation_per_credit = 0.01
	var/next_restock = 0
	/// Раз во сколько минут партнёры выставляют спецзаказы
	var/offer_minutes = 15
	var/offers_max = 2
	/// Шанс в процентах, что партнёр со свободным местом выставит спецзаказ
	var/offer_chance = 50
	/// Срок выполнения взятого спецзаказа
	var/offer_deadline_minutes = 30
	var/next_offers = 0
	/// тикер -> /datum/stock_company
	var/list/companies = list()
	/// /datum/market_event, ещё не наступившие
	var/list/scheduled_events = list()
	/// Ключ события станции -> list(тикер или STOCK_ALL_COMPANIES -> шок)
	var/list/station_events = list()
	/// list(key, headline, effect), из которых выбираются события компаний
	var/list/company_event_templates = list()
	/// Шанс в процентах, что компания получит событие за минуту
	var/company_event_chance = 2
	/// Ключ события станции -> world.time, раньше которого оно не повторяется
	var/list/station_event_cooldowns = list()
	/// Вид работы отдела -> list(тикер -> сдвиг цены на каждые STOCK_WORK_CREDITS кр., полученных отделом)
	var/list/work_stocks = list()
	/// Потолок сдвига цены компании от работы отделов за смену, в обе стороны
	var/work_stock_cap = 0.2
	/// Сообщение ЦК о сделках с контрабандным партнёром: его видит только взломанная консоль снабжения
	var/contraband_message = ""

/datum/controller/subsystem/market/Initialize(timeofday)
	for(var/error in load_settings(SSeconomy.settings.raw?["market"]))
		GLOB.economy_config_errors |= error
		log_config("economy.json: [error]")
	register_stock_signals()
	setup_news()
	restore_sector()
	return ..()

/datum/controller/subsystem/market/Recover()
	commodities = SSmarket.commodities
	price_index = SSmarket.price_index
	next_shift = SSmarket.next_shift
	shift_count = SSmarket.shift_count
	shift_minutes = SSmarket.shift_minutes
	hot_chance = SSmarket.hot_chance
	partners = SSmarket.partners
	partner_restock_minutes = SSmarket.partner_restock_minutes
	partner_stock_default = SSmarket.partner_stock_default
	reputation_per_credit = SSmarket.reputation_per_credit
	next_restock = SSmarket.next_restock
	offer_minutes = SSmarket.offer_minutes
	offers_max = SSmarket.offers_max
	offer_chance = SSmarket.offer_chance
	offer_deadline_minutes = SSmarket.offer_deadline_minutes
	next_offers = SSmarket.next_offers
	companies = SSmarket.companies
	scheduled_events = SSmarket.scheduled_events
	station_events = SSmarket.station_events
	company_event_templates = SSmarket.company_event_templates
	company_event_chance = SSmarket.company_event_chance
	station_event_cooldowns = SSmarket.station_event_cooldowns
	work_stocks = SSmarket.work_stocks
	work_stock_cap = SSmarket.work_stock_cap
	contraband_message = SSmarket.contraband_message
	recent_trades = SSmarket.recent_trades
	trade_serial = SSmarket.trade_serial
	contraband_exported_by = SSmarket.contraband_exported_by
	press_release_ready_at = SSmarket.press_release_ready_at
	press_released = SSmarket.press_released
	news_published = SSmarket.news_published
	guide_published = SSmarket.guide_published
	digest_minutes = SSmarket.digest_minutes
	last_digest_key = SSmarket.last_digest_key
	news_flash_minutes = SSmarket.news_flash_minutes
	next_digest = SSmarket.next_digest
	last_news = SSmarket.last_news
	pending_news = SSmarket.pending_news
	pending_hot = SSmarket.pending_hot
	persist_decay = SSmarket.persist_decay
	state_path = SSmarket.state_path
	round_end_hooked = SSmarket.round_end_hooked
	register_stock_signals()
	setup_news()

/datum/controller/subsystem/market/fire(resumed)
	tick_stocks()
	tick_auction()
	tick_bundles()
	if(!next_restock)
		next_restock = world.time + partner_restock_minutes MINUTES
	else if(world.time >= next_restock)
		next_restock = world.time + partner_restock_minutes MINUTES
		for(var/id in partners)
			var/datum/trade_partner/partner = partners[id]
			partner.restock()
	expire_offers()
	if(!next_offers)
		next_offers = world.time + offer_minutes MINUTES
	else if(world.time >= next_offers)
		next_offers = world.time + offer_minutes MINUTES
		generate_offers()
	if(!next_shift)
		next_shift = world.time + shift_minutes MINUTES
	else if(world.time >= next_shift)
		market_shift()
	news_tick()

/// Читает секцию market из economy.json, возвращает ошибки; неверные значения остаются встроенными.
/datum/controller/subsystem/market/proc/load_settings(list/section)
	. = list()
	shift_minutes = initial(shift_minutes)
	hot_chance = initial(hot_chance)
	partner_restock_minutes = initial(partner_restock_minutes)
	partner_stock_default = initial(partner_stock_default)
	reputation_per_credit = initial(reputation_per_credit)
	offer_minutes = initial(offer_minutes)
	offers_max = initial(offers_max)
	offer_chance = initial(offer_chance)
	offer_deadline_minutes = initial(offer_deadline_minutes)
	company_event_chance = initial(company_event_chance)
	work_stock_cap = initial(work_stock_cap)
	digest_minutes = initial(digest_minutes)
	news_flash_minutes = initial(news_flash_minutes)
	persist_decay = initial(persist_decay)
	if(!islist(section))
		. += "секции market нет или она не объект, рынок на встроенных товарах"
		. += load_commodities(list())
		. += load_partners(list())
		. += load_stocks(list())
		return
	var/minutes = section["shift_minutes"]
	if(!isnull(minutes))
		if(isnum(minutes) && minutes >= 1)
			shift_minutes = minutes
		else
			. += "market.shift_minutes: нужно число не меньше 1"
	var/chance = section["hot_chance"]
	if(!isnull(chance))
		if(isnum(chance) && chance >= 0 && chance <= 100)
			hot_chance = chance
		else
			. += "market.hot_chance: нужно число 0..100"
	var/restock_minutes = section["partner_restock_minutes"]
	if(!isnull(restock_minutes))
		if(isnum(restock_minutes) && restock_minutes >= 1)
			partner_restock_minutes = restock_minutes
		else
			. += "market.partner_restock_minutes: нужно число не меньше 1"
	var/stock_default = section["partner_stock_default"]
	if(!isnull(stock_default))
		if(isnum(stock_default) && stock_default >= 1 && round(stock_default) == stock_default)
			partner_stock_default = stock_default
		else
			. += "market.partner_stock_default: нужно целое не меньше 1"
	var/per_credit = section["reputation_per_credit"]
	if(!isnull(per_credit))
		if(isnum(per_credit) && per_credit >= 0 && per_credit <= 1)
			reputation_per_credit = per_credit
		else
			. += "market.reputation_per_credit: нужно число 0..1"
	var/offer_interval = section["offer_minutes"]
	if(!isnull(offer_interval))
		if(isnum(offer_interval) && offer_interval >= 1)
			offer_minutes = offer_interval
		else
			. += "market.offer_minutes: нужно число не меньше 1"
	var/max_offers = section["offers_max"]
	if(!isnull(max_offers))
		if(isnum(max_offers) && max_offers >= 0 && round(max_offers) == max_offers)
			offers_max = max_offers
		else
			. += "market.offers_max: нужно целое не меньше 0"
	var/spawn_chance = section["offer_chance"]
	if(!isnull(spawn_chance))
		if(isnum(spawn_chance) && spawn_chance >= 0 && spawn_chance <= 100)
			offer_chance = spawn_chance
		else
			. += "market.offer_chance: нужно число 0..100"
	var/deadline_minutes = section["offer_deadline_minutes"]
	if(!isnull(deadline_minutes))
		if(isnum(deadline_minutes) && deadline_minutes >= 1)
			offer_deadline_minutes = deadline_minutes
		else
			. += "market.offer_deadline_minutes: нужно число не меньше 1"
	var/digest_interval = section["digest_minutes"]
	if(!isnull(digest_interval))
		if(isnum(digest_interval) && digest_interval >= 1)
			digest_minutes = digest_interval
		else
			. += "market.digest_minutes: нужно число не меньше 1"
	var/flash_interval = section["news_flash_minutes"]
	if(!isnull(flash_interval))
		if(isnum(flash_interval) && flash_interval >= 1)
			news_flash_minutes = flash_interval
		else
			. += "market.news_flash_minutes: нужно число не меньше 1"
	if(news_flash_minutes * 2 > digest_minutes)
		. += "market.news_flash_minutes: нужно не больше половины digest_minutes, иначе между сводками не остаётся места срочным новостям"
		news_flash_minutes = digest_minutes / 2
	var/decay = section["persist_decay"]
	if(!isnull(decay))
		if(isnum(decay) && decay >= 0 && decay <= 100)
			persist_decay = decay
		else
			. += "market.persist_decay: нужно число 0..100"
	. += load_commodities(section["commodities"])
	. += load_partners(section["partners"])
	. += load_stocks(section)
	. += check_press_release_cooldown()

/// Встроенные товары, поверх - записи из конфига; уже существующие товары сохраняют рыночное состояние.
/datum/controller/subsystem/market/proc/load_commodities(list/section)
	. = list()
	if(!islist(section))
		. += "market.commodities не объект, рынок на встроенных товарах"
		section = list()
	var/list/loaded = list()
	for(var/id in GLOB.market_default_commodities)
		var/datum/commodity/commodity = commodities[id]
		if(!commodity)
			commodity = new
			commodity.id = id
		commodity.reset_params()
		commodity.configure(GLOB.market_default_commodities[id], GLOB.market_default_commodities)
		loaded[id] = commodity
	for(var/id in section)
		var/datum/commodity/commodity = loaded[id]
		if(!commodity)
			if(!ECON_CONFIG_COMMENT_KEY(id))
				. += "market.commodities.[id]: неизвестный товар"
			continue
		var/list/entry = section[id]
		if(!islist(entry))
			. += "market.commodities.[id]: не объект"
			continue
		for(var/error in commodity.configure(entry, loaded))
			. += "market.commodities.[error]"
	var/list/inbound = list()
	for(var/id in loaded)
		var/datum/commodity/commodity = loaded[id]
		for(var/linked_id in commodity.links)
			var/share = commodity.links[linked_id]
			if(round(inbound[linked_id] + share, 0.001) > MARKET_LINK_INBOUND_MAX)
				. += "market.commodities.[id].links.[linked_id]: входящая доля связей в [linked_id] больше [MARKET_LINK_INBOUND_MAX]"
				commodity.links -= linked_id
				continue
			inbound[linked_id] += share
	for(var/id in commodities - loaded)
		qdel(commodities[id])
	commodities = loaded

/// Встроенные партнёры, поверх - записи из конфига; уже существующие сохраняют репутацию, капитал и склад.
/datum/controller/subsystem/market/proc/load_partners(list/section)
	. = list()
	if(!islist(section))
		. += "market.partners не объект, партнёры встроенные"
		section = list()
	var/list/loaded = list()
	for(var/id in GLOB.market_default_partners)
		var/datum/trade_partner/partner = partners[id]
		var/fresh = !partner
		if(fresh)
			partner = new
			partner.id = id
		partner.reset_params()
		partner.configure(GLOB.market_default_partners[id], commodities, GLOB.market_default_partners, fresh)
		loaded[id] = partner
	for(var/id in section)
		var/datum/trade_partner/partner = loaded[id]
		if(!partner)
			if(!ECON_CONFIG_COMMENT_KEY(id))
				. += "market.partners.[id]: неизвестный партнёр"
			continue
		var/list/entry = section[id]
		if(!islist(entry))
			. += "market.partners.[id]: не объект"
			continue
		for(var/error in partner.configure(entry, commodities, loaded, !partners[id]))
			. += "market.partners.[error]"
	var/has_universal = FALSE
	for(var/id in loaded)
		var/datum/trade_partner/partner = loaded[id]
		if(partner.start_unlocked && (PARTNER_ANY in partner.sells_groups) && partner.buys[PARTNER_ANY] > 0)
			has_universal = TRUE
	if(!has_universal)
		. += "market.partners: нет открытого со старта партнёра, который продаёт и покупает всё (*), НТ Логистика встроенная"
		var/datum/trade_partner/fallback = loaded[PARTNER_UNIVERSAL_ID]
		fallback.reset_params()
		fallback.configure(GLOB.market_default_partners[PARTNER_UNIVERSAL_ID], commodities, loaded)
	for(var/id in loaded)
		var/datum/trade_partner/partner = loaded[id]
		if(partner.start_unlocked && !partner.contraband)
			partner.unlocked = TRUE
	for(var/id in partners - loaded)
		qdel(partners[id])
	partners = loaded
	check_unlocks()

/datum/controller/subsystem/market/proc/get_commodity(id)
	return commodities[id]

/datum/controller/subsystem/market/proc/get_partner(id)
	return partners[id]

/datum/controller/subsystem/market/proc/get_company(ticker)
	return companies[ticker]

/// Шанс событий, компании, события компаний и станции из секции market; отсутствующий ключ оставляет встроенное без ошибки.
/datum/controller/subsystem/market/proc/load_stocks(list/section)
	. = list()
	var/chance = section["company_event_chance"]
	if(!isnull(chance))
		if(isnum(chance) && chance >= 0 && chance <= 100)
			company_event_chance = chance
		else
			. += "market.company_event_chance: нужно число 0..100"
	var/cap = section["work_stock_cap"]
	if(!isnull(cap))
		if(isnum(cap) && cap >= 0 && cap <= -STOCK_EFFECT_MIN)
			work_stock_cap = cap
		else
			. += "market.work_stock_cap: нужно число 0..[-STOCK_EFFECT_MIN]"
	. += load_companies(section["companies"])
	. += load_company_events(section["company_events"])
	. += load_station_events(section["station_events"])
	. += load_work_stocks(section["work_stocks"])

/// Встроенные компании, поверх - записи из конфига; уже существующие сохраняют цену и историю.
/datum/controller/subsystem/market/proc/load_companies(list/section)
	. = list()
	if(isnull(section))
		section = list()
	else if(!islist(section))
		. += "market.companies не объект, компании встроенные"
		section = list()
	var/list/loaded = list()
	for(var/ticker in GLOB.market_default_companies)
		var/datum/stock_company/company = companies[ticker]
		if(!company)
			company = new
			company.ticker = ticker
		company.reset_params()
		company.configure(GLOB.market_default_companies[ticker], !companies[ticker])
		loaded[ticker] = company
	for(var/ticker in section)
		var/datum/stock_company/company = loaded[ticker]
		if(!company)
			if(!ECON_CONFIG_COMMENT_KEY(ticker))
				. += "market.companies.[ticker]: неизвестная компания"
			continue
		var/list/entry = section[ticker]
		if(!islist(entry))
			. += "market.companies.[ticker]: не объект"
			continue
		for(var/error in company.configure(entry, !companies[ticker]))
			. += "market.companies.[error]"
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(!partner.company)
			continue
		var/datum/stock_company/company = loaded[partner.company]
		if(!company)
			. += "market.partners.[id].company: нет такой компании [partner.company]"
			partner.company = null
		else if(company.partner_id)
			. += "market.partners.[id].company: компания [partner.company] уже у партнёра [company.partner_id]"
			partner.company = null
		else
			company.partner_id = id
	var/datum/stock_company/index/fund = companies[STOCK_INDEX_TICKER]
	loaded[STOCK_INDEX_TICKER] = istype(fund) ? fund : new /datum/stock_company/index
	companies = loaded
	refresh_index_fund()

/// Шаблоны событий компаний; любая битая запись оставляет встроенный список целиком.
/datum/controller/subsystem/market/proc/load_company_events(list/section)
	. = list()
	company_event_templates = list()
	for(var/list/template as anything in GLOB.market_default_company_events)
		company_event_templates += list(template.Copy())
	if(isnull(section))
		return
	if(!islist(section))
		. += "market.company_events: нужен список"
		return
	var/list/accepted = list()
	var/list/errors = list()
	var/index = 0
	for(var/entry in section)
		index++
		var/parsed = parse_company_event(entry)
		if(istext(parsed))
			errors += "market.company_events[index]: [parsed]"
		else
			accepted += list(parsed)
	if(length(errors))
		return errors
	company_event_templates = accepted

/// Запись события компании или текст ошибки.
/datum/controller/subsystem/market/proc/parse_company_event(list/entry)
	if(!islist(entry))
		return "не объект"
	var/list/parsed = list()
	for(var/key in entry)
		var/value = entry[key]
		switch(key)
			if("key", "headline")
				if(!istext(value) || !length(value))
					return "[key]: нужна непустая строка"
				parsed[key] = value
			if("effect")
				if(!isnum(value) || value < STOCK_EFFECT_MIN || value > STOCK_EFFECT_MAX)
					return "effect: нужно число [STOCK_EFFECT_MIN]..[STOCK_EFFECT_MAX]"
				parsed[key] = value
			else
				if(!ECON_CONFIG_COMMENT_KEY(key))
					return "неизвестный ключ [key]"
	for(var/required in list("key", "headline", "effect"))
		if(isnull(parsed[required]))
			return "нет ключа [required]"
	return parsed

/// Привязки событий станции к компаниям; битая привязка оставляет встроенную для своего события.
/datum/controller/subsystem/market/proc/load_station_events(list/section)
	. = list()
	station_events = list()
	for(var/key in GLOB.market_default_station_events)
		var/list/effects = GLOB.market_default_station_events[key]
		station_events[key] = effects.Copy()
	if(isnull(section))
		return
	if(!islist(section))
		. += "market.station_events не объект"
		return
	for(var/key in section)
		if(!(key in station_events))
			if(!ECON_CONFIG_COMMENT_KEY(key))
				. += "market.station_events.[key]: неизвестное событие станции"
			continue
		var/list/effects = section[key]
		if(!islist(effects))
			. += "market.station_events.[key]: не объект"
			continue
		var/list/accepted = list()
		var/valid = TRUE
		for(var/ticker in effects)
			var/effect = effects[ticker]
			if(ticker != STOCK_ALL_COMPANIES && !companies[ticker])
				. += "market.station_events.[key].[ticker]: нет такой компании"
				valid = FALSE
			else if(!isnum(effect) || effect < STOCK_EFFECT_MIN || effect > STOCK_EFFECT_MAX)
				. += "market.station_events.[key].[ticker]: нужно число [STOCK_EFFECT_MIN]..[STOCK_EFFECT_MAX]"
				valid = FALSE
			else
				accepted[ticker] = effect
		if(valid)
			station_events[key] = accepted

/// Привязки работы отделов к компаниям; битая привязка оставляет встроенную для своего вида работы, пустая отключает его.
/datum/controller/subsystem/market/proc/load_work_stocks(list/section)
	. = list()
	work_stocks = list()
	for(var/work_type in GLOB.market_default_work_stocks)
		var/list/shares = GLOB.market_default_work_stocks[work_type]
		work_stocks[work_type] = shares.Copy()
	if(isnull(section))
		return
	if(!islist(section))
		. += "market.work_stocks не объект"
		return
	for(var/work_type in section)
		if(!GLOB.econ_work_names[work_type])
			if(!ECON_CONFIG_COMMENT_KEY(work_type))
				. += "market.work_stocks.[work_type]: неизвестный вид работы"
			continue
		var/list/shares = section[work_type]
		if(!islist(shares))
			. += "market.work_stocks.[work_type]: не объект"
			continue
		var/list/accepted = list()
		var/valid = TRUE
		for(var/ticker in shares)
			var/datum/stock_company/company = companies[ticker]
			var/share = shares[ticker]
			if(!company || company.is_index)
				. += "market.work_stocks.[work_type].[ticker]: нет такой компании"
				valid = FALSE
			else if(!isnum(share) || share < STOCK_EFFECT_MIN || share > STOCK_EFFECT_MAX)
				. += "market.work_stocks.[work_type].[ticker]: нужно число [STOCK_EFFECT_MIN]..[STOCK_EFFECT_MAX]"
				valid = FALSE
			else
				accepted[ticker] = share
		if(valid)
			work_stocks[work_type] = accepted

/datum/controller/subsystem/market/proc/register_stock_signals()
	RegisterSignal(src, COMSIG_MARKET_TRADE, PROC_REF(on_stock_trade), override = TRUE)
	RegisterSignal(src, COMSIG_MARKET_OFFER_RESOLVED, PROC_REF(on_stock_offer_resolved), override = TRUE)
	RegisterSignal(src, COMSIG_MARKET_STOCK_TRADE, PROC_REF(note_trade_for_audit), override = TRUE)
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_WORK_RECORDED, PROC_REF(on_work_recorded), override = TRUE)

/datum/controller/subsystem/market/proc/on_stock_trade(datum/source, datum/trade_partner/partner, value, is_sale)
	SIGNAL_HANDLER
	var/datum/stock_company/company = companies[partner.company]
	if(!company || !(value > 0))
		return
	if(is_sale)
		var/price_before = company.price
		company.add_trade_volume(value)
		company.note_move(partner.contraband ? "Сделки на сером рынке сектора" : "Станция продаёт товары партнёру \"[partner.name]\"", price_before, TRUE)
	else
		company.dividend_pool += value * SSeconomy.settings.stock_dividend_share / 100

/datum/controller/subsystem/market/proc/on_stock_offer_resolved(datum/source, datum/market_offer/offer, success)
	SIGNAL_HANDLER
	if(success || !offer.station_involved)
		return
	var/datum/trade_partner/partner = partners[offer.partner_id]
	var/datum/stock_company/company = partner ? companies[partner.company] : null
	if(!company)
		return
	var/price_before = company.price
	company.apply_shock(-MARKET_OFFER_FAIL_STOCK_SHOCK)
	company.note_move("Станция сорвала спецзаказ партнёра \"[partner.name]\"", price_before)

/// Оплаченная работа отдела сдвигает цены привязанных компаний до потолка за смену; остановленные торги работа не двигает.
/datum/controller/subsystem/market/proc/on_work_recorded(datum/source, department_id, work_type, amount, mob/performer, paid, atom/subject)
	SIGNAL_HANDLER
	var/list/shares = work_stocks[work_type]
	if(!length(shares) || !(paid > 0))
		return
	for(var/ticker in shares)
		var/datum/stock_company/company = companies[ticker]
		if(!company || company.is_halted())
			continue
		var/price_before = company.price
		if(!company.add_work(paid * shares[ticker] / STOCK_WORK_CREDITS, work_stock_cap))
			continue
		company.note_move(market_work_reason(work_type), price_before, TRUE)
		note_work_news(company, work_type)

/// Минутный тик биржи: цены, индекс сектора, новые события компаний, выход созревших, заявки.
/datum/controller/subsystem/market/proc/tick_stocks()
	var/list/halted = list()
	var/list/relisted = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company.is_index)
			continue
		var/was_halted = !!company.halted_until
		company.tick()
		if(!was_halted && company.halted_until)
			halted += ticker
			alert_holders_halted(company)
		else if(was_halted && !company.halted_until)
			relisted += ticker
	var/datum/stock_company/fund = companies[STOCK_INDEX_TICKER]
	fund?.tick()
	maybe_schedule_events()
	run_due_events()
	run_stock_orders()
	SEND_SIGNAL(src, COMSIG_MARKET_STOCKS_TICKED, halted, relisted)

/// Ставит событие компании в очередь; второе фальшивое событие той же компании не ставится, возвращается null.
/datum/controller/subsystem/market/proc/schedule_company_event(datum/stock_company/company, key, headline, effect, delay, fake = FALSE)
	if(fake)
		for(var/datum/market_event/queued as anything in scheduled_events)
			if(queued.fake && queued.company == company)
				return null
	var/datum/market_event/event = new
	event.company = company
	event.key = key
	event.headline = headline
	event.effect = effect
	event.eta = world.time + delay
	event.fake = fake
	scheduled_events += event
	return event

/// Торгуемые компании без своего события в очереди с шансом company_event_chance получают событие с ETA 3-5 минут.
/datum/controller/subsystem/market/proc/maybe_schedule_events()
	if(!length(company_event_templates))
		return
	var/list/pending = list()
	for(var/datum/market_event/event as anything in scheduled_events)
		if(!event.fake)
			pending[event.company.ticker] = TRUE
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company.is_index || pending[ticker] || company.is_halted() || !prob(company_event_chance))
			continue
		var/list/template = pick(company_event_templates)
		schedule_company_event(company, template["key"], replacetext(template["headline"], "%NAME%", company.name), template["effect"], rand(STOCK_EVENT_ETA_MIN, STOCK_EVENT_ETA_MAX))

/datum/controller/subsystem/market/proc/run_due_events()
	for(var/datum/market_event/event as anything in scheduled_events)
		if(world.time >= event.eta && !press_release_held(event))
			release_event(event)

/// Событие выходит: шок цены, проверка инсайда, срочная новость.
/datum/controller/subsystem/market/proc/release_event(datum/market_event/event)
	scheduled_events -= event
	var/datum/stock_company/company = event.company
	var/price_before = company.price
	var/mult_before = company.event_mult
	if(event.refutes)
		company.undo_shock(event.refute_price, event.refute_mult)
	else
		company.apply_shock(event.effect)
	company.note_move(event.headline, price_before)
	alert_holders(company, price_before)
	if(!event.fake)
		company.last_real_event_at = world.time
	log_econ("Событие компании [company.ticker] вышло: \"[event.headline]\", шок [event.effect * 100]%[event.fake ? ", фальшивое" : ""]")
	check_insider(event)
	if(event.press_release)
		schedule_refutation(event, price_before, mult_before)
	SEND_SIGNAL(src, COMSIG_MARKET_COMPANY_EVENT, event)
	qdel(event)

/// Событие станции сразу двигает цену привязанных компаний; повтор в окне кулдауна не действует и возвращает FALSE.
/datum/controller/subsystem/market/proc/station_event(key)
	var/list/effects = station_events[key]
	if(!length(effects) || world.time < station_event_cooldowns[key])
		return FALSE
	station_event_cooldowns[key] = world.time + STOCK_STATION_EVENT_COOLDOWN
	var/list/prices_before = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		prices_before[ticker] = company.price
	for(var/ticker in effects)
		if(ticker != STOCK_ALL_COMPANIES)
			var/datum/stock_company/company = companies[ticker]
			company?.apply_shock(effects[ticker])
			continue
		for(var/other in companies)
			var/datum/stock_company/each = companies[other]
			each.apply_shock(effects[ticker])
	var/reason = GLOB.market_station_event_names[key] || key
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		company.note_move(reason, prices_before[ticker])
		alert_holders(company, prices_before[ticker])
	log_econ("Событие станции [key] сдвинуло акции компаний")
	var/news = GLOB.market_station_event_news[key]
	if(news)
		post_news(news)
	SEND_SIGNAL(src, COMSIG_MARKET_STATION_EVENT, key)
	return TRUE

/// Самый дешёвый открытый партнёр, у которого пак есть на складе; контрабандный - только для заказа со взломанной консоли снабжения.
/datum/controller/subsystem/market/proc/supplier_for(datum/supply_pack/pack, datum/bank_account/paying_account, allow_contraband = FALSE)
	var/list/offer = best_offer(pack, paying_account, allow_contraband)
	return offer ? offer[1] : null

/// list(поставщик по supplier_for(), его pack_price()) или null.
/datum/controller/subsystem/market/proc/best_offer(datum/supply_pack/pack, datum/bank_account/paying_account, allow_contraband = FALSE)
	return best_offers(list(pack), paying_account, allow_contraband)[pack]

/// best_offer() для списка паков: пак -> list(поставщик, цена) или null. Открытые партнёры и их скидки разбираются один раз на весь список.
/datum/controller/subsystem/market/proc/best_offers(list/packs, datum/bank_account/paying_account, allow_contraband = FALSE)
	. = list()
	var/list/open_partners = list()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if((!partner.contraband || allow_contraband) && partner.unlocked && !partner.embargoed())
			open_partners[partner] = 1 - partner.discount()
	for(var/datum/supply_pack/pack as anything in packs)
		.[pack] = null
		if(!econ_pack_traded(pack))
			continue
		var/datum/commodity/market_commodity = econ_pack_commodity(pack)
		var/total = pack.market_total()
		var/packaging = pack.market_packaging(paying_account, total)
		var/factor = market_commodity.buy_factor()
		var/datum/trade_partner/best
		var/best_price
		var/list/choices = list()
		for(var/datum/trade_partner/partner as anything in open_partners)
			if(!partner.sells_group(pack.group) || !partner.in_stock(pack) || !econ_exclusive_ok(partner, pack))
				continue
			var/price = econ_pack_partner_cost(total, packaging, factor, partner, open_partners[partner])
			choices += list(list(partner.id, price))
			if(!best || price < best_price)
				best = partner
				best_price = price
		if(best)
			.[pack] = list(best, best_price, length(choices) > 1 ? choices : null)

/// Открытый партнёр, который платит за товар больше всех; контрабандный - только для отгрузки с допуском контрабанды.
/datum/controller/subsystem/market/proc/best_buyer(commodity_id, allow_contraband = FALSE)
	var/datum/trade_partner/best
	var/best_multiplier = 0
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(partner.contraband && !allow_contraband)
			continue
		var/multiplier = partner.buy_multiplier(commodity_id)
		if(multiplier > best_multiplier)
			best = partner
			best_multiplier = multiplier
	return best

/// Открытые партнёры со свободным местом с шансом offer_chance выставляют по спецзаказу.
/datum/controller/subsystem/market/proc/generate_offers()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(partner.unlocked && !partner.embargoed() && length(partner.offer_items) && length(partner.offers) < offers_max && prob(offer_chance))
			partner.new_offer()

/// Просроченный взятый спецзаказ проваливается, невзятый снимается молча.
/datum/controller/subsystem/market/proc/expire_offers()
	for(var/datum/market_offer/offer as anything in all_offers())
		if(world.time <= offer.deadline)
			continue
		if(offer.accepted)
			offer.fail()
		else
			qdel(offer)

/datum/controller/subsystem/market/proc/all_offers()
	. = list()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		. += partner.offers

/datum/controller/subsystem/market/proc/offer_by_uid(uid)
	if(istext(uid))
		uid = text2num(uid)
	for(var/datum/market_offer/offer as anything in all_offers())
		if(offer.uid == uid)
			return offer

/// Репутация открывает партнёров по их правилу; контрабандного открывает только взлом консоли снабжения.
/datum/controller/subsystem/market/proc/check_unlocks()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(partner.unlocked || partner.contraband || !islist(partner.unlock))
			continue
		var/opened = FALSE
		if(partner.unlock["partner"])
			var/datum/trade_partner/sponsor = partners[partner.unlock["partner"]]
			opened = sponsor?.unlocked && sponsor.tier() >= partner.unlock["tier"]
		else
			var/count = 0
			for(var/other_id in partners)
				var/datum/trade_partner/other = partners[other_id]
				if(other != partner && other.unlocked && !other.contraband && other.tier() >= partner.unlock["any_two_tier"])
					count++
			opened = count >= PARTNER_UNLOCK_SPONSORS
		if(opened)
			partner.unlocked = TRUE
			log_econ("Репутация открыла торгового партнёра [partner.name] ([partner.id])")
			SEND_SIGNAL(src, COMSIG_MARKET_PARTNER_UNLOCKED, partner)

/datum/controller/subsystem/market/proc/market_shift()
	shift_count++
	next_shift = world.time + shift_minutes MINUTES + rand(-MARKET_SHIFT_JITTER, MARKET_SHIFT_JITTER)
	var/list/pull = list()
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		for(var/linked_id in commodity.links)
			pull[linked_id] += (commodity.trend - 1) * commodity.links[linked_id]
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		if(pull[id])
			commodity.trend += pull[id] * (1 - MARKET_TREND_REVERSION)
		commodity.shift(hot_chance)
	recompute_price_index()
	SEND_SIGNAL(src, COMSIG_MARKET_SHIFTED)
	refresh_vending_prices()

/// Автоматы пересчитывают цены, только если индекс ушёл от их последнего пересчёта дальше порога.
/datum/controller/subsystem/market/proc/refresh_vending_prices()
	var/index = SSeconomy.price_index()
	for(var/obj/machinery/vending/machine as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/vending))
		if(!machine.last_price_index || abs(index - machine.last_price_index) / machine.last_price_index > MARKET_VENDING_REFRESH_SHARE)
			machine.refresh_prices()
		CHECK_TICK

/datum/controller/subsystem/market/proc/recompute_price_index()
	var/total = 0
	var/count = 0
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		if(!commodity.consumer)
			continue
		total += commodity.price_factor
		count++
	var/target = count ? clamp(total / count, MARKET_INDEX_MIN, MARKET_INDEX_MAX) : 1
	price_index = clamp(price_index + (target - price_index) * MARKET_INDEX_SMOOTHING, MARKET_INDEX_MIN, MARKET_INDEX_MAX)
