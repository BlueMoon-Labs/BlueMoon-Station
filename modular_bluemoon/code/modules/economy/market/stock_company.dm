/// Встроенные компании биржи: на них SSmarket откатывается, если секция market.companies в economy.json битая.
GLOBAL_LIST_INIT(market_default_companies, list(
	"NTRN" = list("name" = "Нанотрейзен", "price" = 250, "volatility" = 0.015),
	"PRSP" = list("name" = "Гильдия старателей", "price" = 60, "volatility" = 0.03),
	"VYMD" = list("name" = "Вей-Мед", "price" = 120, "volatility" = 0.025),
	"NKMR" = list("name" = "Накамура Инжиниринг", "price" = 140, "volatility" = 0.025),
	"AGRO" = list("name" = "Аграрный союз", "price" = 45, "volatility" = 0.03),
	"SOLX" = list("name" = "Солнечная биржа", "price" = 180, "volatility" = 0.02),
	"CYBS" = list("name" = "Киберсан Индастриз", "price" = 90, "volatility" = 0.05),
	"EINS" = list("name" = "Эйнштейн Энджинс", "price" = 110, "volatility" = 0.03),
	"HEPH" = list("name" = "Гефест Индастриз", "price" = 160, "volatility" = 0.035),
	"BSHP" = list("name" = "Бишоп Кибернетикс", "price" = 95, "volatility" = 0.04),
))

/// Встроенные события компаний; %NAME% заменяется названием компании.
GLOBAL_LIST_INIT(market_default_company_events, list(
	list("key" = "product_launch", "headline" = "%NAME% представляет новую линейку продукции", "effect" = 0.15),
	list("key" = "contract_won", "headline" = "%NAME% выигрывает крупный контракт сектора", "effect" = 0.2),
	list("key" = "merger", "headline" = "%NAME% объявляет о слиянии", "effect" = 0.25),
	list("key" = "scandal", "headline" = "Скандал в руководстве %NAME%", "effect" = -0.2),
	list("key" = "recall", "headline" = "%NAME% отзывает партию продукции", "effect" = -0.15),
	list("key" = "strike", "headline" = "Забастовка на предприятиях %NAME%", "effect" = -0.12),
))

/// Встроенные привязки событий станции: ключ -> тикер или STOCK_ALL_COMPANIES -> шок цены.
GLOBAL_LIST_INIT(market_default_station_events, list(
	"sm_delam" = list("NTRN" = -0.25, "NKMR" = 0.1, "BSHP" = -0.05),
	"delta_alert" = list("NTRN" = -0.15, "HEPH" = 0.1),
	"disease_outbreak" = list("VYMD" = 0.2, "BSHP" = 0.05),
	"meteors" = list("NKMR" = 0.15, "PRSP" = 0.05),
	"power_failure" = list("NKMR" = -0.1, "NTRN" = -0.05),
	"gravity_lost" = list("NKMR" = -0.1, "NTRN" = -0.05),
	"radiation_storm" = list("AGRO" = -0.12, "VYMD" = 0.05),
	"red_alert" = list("NTRN" = -0.08, "HEPH" = 0.05),
	"market_crash" = list(STOCK_ALL_COMPANIES = -0.2),
	"sector_boom" = list(STOCK_ALL_COMPANIES = 0.1),
))

/// Названия событий станции для сносок биржи.
GLOBAL_LIST_INIT(market_station_event_names, list(
	"sm_delam" = "Расслоение суперматерии на станции",
	"delta_alert" = "Код \"Дельта\" на станции",
	"disease_outbreak" = "Вспышка болезни на станции",
	"meteors" = "Метеоритный дождь у станции",
	"power_failure" = "Сбой энергосети станции",
	"gravity_lost" = "Станция осталась без гравитации",
	"radiation_storm" = "Радиационный шторм в секторе",
	"red_alert" = "Красный код на станции",
	"market_crash" = "Обвал рынка сектора",
	"sector_boom" = "Бум в секторе",
))

/// Встроенные привязки работы отделов: вид работы -> тикер -> сдвиг цены на каждые STOCK_WORK_CREDITS кр., полученных отделом.
GLOBAL_LIST_INIT(market_default_work_stocks, list(
	WORK_MED_DISCHARGE_LIGHT = list("VYMD" = 0.1),
	WORK_MED_DISCHARGE_HEAVY = list("VYMD" = 0.1),
	WORK_MED_DISCHARGE_CRIT = list("VYMD" = 0.1),
	WORK_MED_REVIVE = list("VYMD" = 0.1),
	WORK_MED_SURGERY = list("BSHP" = 0.1, "VYMD" = 0.05),
	WORK_ENG_POWER_EXPORT = list("NKMR" = 0.04),
	WORK_SCI_NODE = list("EINS" = 0.3),
	WORK_SCI_SLIME_DISCOVERY = list("EINS" = 0.02),
	WORK_SCI_ARTIFACT = list("SOLX" = 0.1),
	WORK_MINING_ORE = list("PRSP" = 0.04),
	WORK_CARGO_PAPERWORK = list("SOLX" = 0.1),
	WORK_SRV_DISH = list("AGRO" = 0.1),
	WORK_SRV_DRINK = list("AGRO" = 0.1),
	WORK_SRV_NEW_PLANT = list("AGRO" = 0.1),
	WORK_SRV_CLEANING = list("NTRN" = 0.05),
	WORK_SEC_CONTRABAND = list("HEPH" = 0.1, "CYBS" = -0.1),
))

/// Вид работы -> list(название в сносках биржи, причина скачка в ленте и новостях).
GLOBAL_LIST_INIT(market_work_reasons, list(
	WORK_MED_DISCHARGE_LIGHT = list("выписка пациентов", "медики выписывают пациентов"),
	WORK_MED_DISCHARGE_HEAVY = list("выписка пациентов", "медики выписывают пациентов"),
	WORK_MED_DISCHARGE_CRIT = list("выписка пациентов", "медики выписывают пациентов"),
	WORK_MED_REVIVE = list("реанимация", "медики возвращают пациентов к жизни"),
	WORK_MED_SURGERY = list("операции", "хирурги оперируют"),
	WORK_ENG_POWER_EXPORT = list("экспорт энергии", "инженеры продают энергию сектору"),
	WORK_ENG_INTEGRITY = list("исправность станции", "инженеры держат станцию в порядке"),
	WORK_SCI_NODE = list("исследования", "учёные открывают технологии"),
	WORK_SCI_SLIME_DISCOVERY = list("новые экстракты слаймов", "ксенобиологи выводят новые экстракты"),
	WORK_SCI_ARTIFACT = list("артефакты", "станция сдаёт найденные артефакты"),
	WORK_MINING_ORE = list("переработка руды", "станция перерабатывает руду"),
	WORK_CARGO_PAPERWORK = list("расчёты на проблемном компьютере", "снабжение решает расчёты"),
	WORK_SRV_DISH = list("блюда", "кухня кормит экипаж"),
	WORK_SRV_DRINK = list("напитки", "бар поит экипаж"),
	WORK_SRV_NEW_PLANT = list("новый урожай", "ботаники выводят новые сорта"),
	WORK_SRV_CLEANING = list("уборка", "уборщики отмывают станцию"),
	WORK_SEC_CONTRABAND = list("изъятая контрабанда", "СБ изымает контрабанду"),
))

/proc/market_work_driver_name(work_type)
	var/list/reason = GLOB.market_work_reasons[work_type]
	return reason ? reason[1] : lowertext(econ_work_name(work_type))

/proc/market_work_reason(work_type)
	var/list/reason = GLOB.market_work_reasons[work_type]
	return reason ? reason[2] : "отделы станции: [lowertext(econ_work_name(work_type))]"

/datum/stock_company
	var/ticker
	var/name = "компания"
	var/base_price = 100
	var/price = 100
	var/volatility = 0.02
	/// Партнёр, у которого в market.partners указана эта компания
	var/partner_id
	/// Накопленный эффект событий: держит потолок их влияния, к 1 не возвращается
	var/event_mult = 1
	/// Продажи станции связанному партнёру с последнего листинга
	var/trade_volume = 0
	/// Сдвиг цены от работы отделов за смену, в пределах ±SSmarket.work_stock_cap; в следующую смену не переходит
	var/work_boost = 0
	/// work_boost на момент последней новости о работе станции и когда можно следующую
	var/work_news_boost = 0
	var/work_news_ready_at = 0
	/// Последние скачки цены: list(text, factor, at, time), старые в начале
	var/list/moves = list()
	var/halted_until = 0
	var/list/history = list()
	/// Индекс сектора: цена считается по остальным компаниям
	var/is_index = FALSE
	/// Доля закупок станции у партнёра; делится между держателями на выплате зарплаты, в следующую смену не переходит
	var/dividend_pool = 0

/datum/stock_company/proc/reset_params()
	name = initial(name)
	base_price = initial(base_price)
	volatility = initial(volatility)
	partner_id = null

/// Накладывает запись конфига и возвращает ошибки "тикер.ключ: ..."; неверное значение параметр не меняет.
/datum/stock_company/proc/configure(list/entry, initial_state = FALSE)
	. = list()
	for(var/key in entry)
		var/value = entry[key]
		switch(key)
			if("name")
				if(istext(value) && length(value))
					name = value
				else
					. += "[ticker].name: нужна непустая строка"
			if("price")
				if(isnum(value) && value > 0)
					base_price = value
				else
					. += "[ticker].price: нужно число больше 0"
			if("volatility")
				if(isnum(value) && value >= 0 && value <= STOCK_VOLATILITY_MAX)
					volatility = value
				else
					. += "[ticker].volatility: нужно число 0..[STOCK_VOLATILITY_MAX]"
			else
				if(!ECON_CONFIG_COMMENT_KEY(key))
					. += "[ticker]: неизвестный ключ [key]"
	if(initial_state)
		price = base_price

/datum/stock_company/proc/is_halted()
	return halted_until && world.time < halted_until

/// Цена - мартингал: шум без сноса, события и торговля сдвигают её сразу и навсегда, без возврата к базе.
/datum/stock_company/proc/tick()
	if(halted_until)
		if(world.time < halted_until)
			return
		relist()
	set_price(price * (1 + gaussian(0, volatility)))
	history += round(price, 0.01)
	if(length(history) > STOCK_HISTORY_MAX)
		history.Cut(1, 2)
	if(price < base_price * STOCK_BANKRUPT_RATIO)
		halted_until = world.time + STOCK_HALT_TIME
		log_econ("Торги [ticker] остановлены: цена [round(price, 0.01)] ниже [STOCK_BANKRUPT_RATIO * 100]% базы [base_price]")

/datum/stock_company/proc/set_price(value)
	price = clamp(value, STOCK_PRICE_MIN, base_price * STOCK_PRICE_MAX_RATIO)
	SSmarket?.refresh_index_fund()

/// Повторный листинг после банкротства на доле базы; акции держателей консолидируются, их стоимость не растёт.
/datum/stock_company/proc/relist()
	var/halted_price = price
	halted_until = 0
	price = base_price * STOCK_RELIST_RATIO
	event_mult = 1
	trade_volume = 0
	work_boost = 0
	work_news_boost = 0
	log_econ("Торги [ticker] возобновлены, повторный листинг по [round(price, 0.01)]")
	SSmarket.consolidate_shares(src, halted_price / price)

/datum/stock_company/proc/apply_shock(effect)
	if(!isnum(effect) || effect <= -1)
		stack_trace("apply_shock: эффект [effect] обнулил бы цену [ticker]")
		return
	var/new_mult = min(event_mult * (1 + effect), STOCK_EVENT_MULT_MAX)
	set_price(price * new_mult / event_mult)
	event_mult = new_mult

/// Продажи партнёру поднимают цену скачком, пока прирост от торговли не упрётся в STOCK_TRADE_BOOST_MAX.
/datum/stock_company/proc/add_trade_volume(value)
	var/old_boost = min(trade_volume / STOCK_TRADE_SCALE, STOCK_TRADE_BOOST_MAX)
	trade_volume += value
	var/new_boost = min(trade_volume / STOCK_TRADE_SCALE, STOCK_TRADE_BOOST_MAX)
	set_price(price * (1 + new_boost) / (1 + old_boost))

/// Работа отдела двигает цену скачком, пока сдвиг от работы за смену не упрётся в ±cap. TRUE - цена сдвинулась.
/datum/stock_company/proc/add_work(effect, cap)
	var/old_boost = work_boost
	work_boost = clamp(work_boost + effect, -cap, cap)
	if(work_boost == old_boost)
		return FALSE
	set_price(price * (1 + work_boost) / (1 + old_boost))
	return TRUE

/// Пишет скачок от price_before в ленту причин; при merge тот же текст подряд в окне STOCK_MOVE_MERGE_TIME копится в одной строке.
/datum/stock_company/proc/note_move(text, price_before, merge = FALSE)
	if(!(price_before > 0))
		return
	var/factor = price / price_before
	if(abs(factor - 1) < STOCK_MOVE_MIN)
		return
	var/now = STATION_TIME_TIMESTAMP("hh:mm", world.time)
	var/list/last = length(moves) ? moves[length(moves)] : null
	if(merge && last && last["text"] == text && world.time - last["at"] < STOCK_MOVE_MERGE_TIME)
		last["factor"] = last["factor"] * factor
		last["at"] = world.time
		last["time"] = now
		return
	moves += list(list("text" = text, "factor" = factor, "at" = world.time, "time" = now))
	if(length(moves) > STOCK_MOVES_MAX)
		moves.Cut(1, 2)

/// Лента причин для окна биржи: новые сверху, сдвиг в процентах.
/datum/stock_company/proc/moves_ui()
	. = list()
	for(var/index in length(moves) to 1 step -1)
		var/list/move = moves[index]
		. += list(list("text" = move["text"], "effect" = round((move["factor"] - 1) * 100, 0.1), "time" = move["time"]))

/// Изменение цены в процентах от самой старой точки истории.
/datum/stock_company/proc/change_percent()
	if(length(history) < 2 || !history[1])
		return 0
	return round((price - history[1]) / history[1] * 100, 0.1)

/datum/stock_company/proc/ui_entry()
	return list("ticker" = ticker, "name" = name, "price" = round(price, 0.01), "change" = change_percent(), "halted" = is_halted(), "history" = history)

/// Сноски биржи: что двигает цену компании. effect - сдвиг в процентах, upto - это потолок, а не разовый скачок.
/// Событие станции только со сдвигом для всех компаний сюда не входит - оно в общей строке, см. market_common_drivers().
/datum/stock_company/proc/price_drivers()
	. = list()
	. += list(list("label" = "Случайные колебания за минуту", "effect" = null, "note" = "около ±[round(volatility * 100, 0.1)]%"))
	var/datum/trade_partner/partner = partner_id ? SSmarket.get_partner(partner_id) : null
	if(partner)
		var/list/goods = list()
		for(var/id in partner.buys)
			if(id == PARTNER_ANY)
				goods.Insert(1, "любые товары")
				continue
			var/datum/commodity/commodity = SSmarket.get_commodity(id)
			if(commodity)
				goods += lowertext(commodity.name)
		var/note = "[jointext(goods, ", ")]; +5% за каждые [round(STOCK_TRADE_SCALE / 20)] кр. продаж"
		if(!partner.unlocked)
			note += "; партнёр пока не торгует со станцией"
		. += list(list("label" = "Продажи станции через снабжение партнёру \"[partner.name]\"", "effect" = STOCK_TRADE_BOOST_MAX * 100, "upto" = TRUE, "note" = note))
		. += list(list("label" = "Сорванный станцией спецзаказ \"[partner.name]\"", "effect" = -MARKET_OFFER_FAIL_STOCK_SHOCK * 100))
		. += list(list("label" = "Закупки станции у \"[partner.name]\"", "effect" = null, "note" = "цену не двигают: [SSeconomy.settings.stock_dividend_share]% суммы идёт в дивиденды держателям"))
	var/list/work = work_driver()
	if(work)
		. += list(work)
	for(var/key in SSmarket.station_events)
		var/list/effects = SSmarket.station_events[key]
		if(isnull(effects[ticker]))
			continue
		var/mult = 1 + effects[ticker]
		if(!isnull(effects[STOCK_ALL_COMPANIES]))
			mult *= 1 + effects[STOCK_ALL_COMPANIES]
		. += list(list("label" = GLOB.market_station_event_names[key] || key, "effect" = round((mult - 1) * 100, 0.1)))

/// Сноска о работе отделов: какие работы двигают цену и на сколько за каждые STOCK_WORK_NOTE_CREDITS кр. оплаты отделу; null - никакие.
/datum/stock_company/proc/work_driver()
	var/list/names = list()
	var/list/by_rate = list()
	var/rising = FALSE
	for(var/work_type in SSmarket.work_stocks)
		var/list/binding = SSmarket.work_stocks[work_type]
		var/share = binding[ticker]
		if(!share)
			continue
		var/work_name = market_work_driver_name(work_type)
		names |= work_name
		rising ||= share > 0
		var/rate = SSmarket.signed_percent(round(share * 100 * STOCK_WORK_NOTE_CREDITS / STOCK_WORK_CREDITS, 0.01))
		var/list/group = by_rate[rate]
		if(!group)
			group = list()
			by_rate[rate] = group
		group |= work_name
	if(!length(names) || !(SSmarket.work_stock_cap > 0))
		return null
	var/list/parts = list()
	for(var/rate in by_rate)
		parts += length(by_rate) > 1 ? "[jointext(by_rate[rate], ", ")] [rate]" : rate
	var/note = "[jointext(parts, "; ")] за каждые [STOCK_WORK_NOTE_CREDITS] кр., что отдел получил за эту работу; в следующую смену не переходит"
	return list("label" = "Работа станции: [jointext(names, ", ")]", "effect" = round((rising ? 1 : -1) * SSmarket.work_stock_cap * 100, 0.1), "upto" = TRUE, "note" = note)

/// Сноски биржи, общие для всех компаний: события станции со сдвигом STOCK_ALL_COMPANIES.
/proc/market_common_drivers()
	. = list()
	for(var/key in SSmarket.station_events)
		var/list/effects = SSmarket.station_events[key]
		if(!isnull(effects[STOCK_ALL_COMPANIES]))
			. += list(list("label" = GLOB.market_station_event_names[key] || key, "effect" = round(effects[STOCK_ALL_COMPANIES] * 100, 0.1)))

/// Индекс сектора: торгуется как компания, но цену берёт из остальных - без шума, событий, торгового объёма и остановок.
/datum/stock_company/index
	ticker = STOCK_INDEX_TICKER
	name = "Индекс сектора"
	volatility = 0
	is_index = TRUE

/datum/stock_company/index/proc/recompute()
	var/total = 0
	var/count = 0
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		if(company.is_index || !(company.base_price > 0))
			continue
		total += company.price / company.base_price
		count++
	price = count ? base_price * total / count : base_price

/datum/stock_company/index/tick()
	halted_until = 0
	recompute()
	history += round(price, 0.01)
	if(length(history) > STOCK_HISTORY_MAX)
		history.Cut(1, 2)

/datum/stock_company/index/is_halted()
	return FALSE

/datum/stock_company/index/set_price(value)
	return

/datum/stock_company/index/apply_shock(effect)
	return

/datum/stock_company/index/add_trade_volume(value)
	return

/datum/stock_company/index/add_work(effect, cap)
	return FALSE

/datum/stock_company/index/note_move(text, price_before, merge = FALSE)
	return

/datum/stock_company/index/price_drivers()
	return list(list("label" = "Среднее по всем компаниям сектора", "effect" = null, "note" = "100 - когда все по базовой цене; своих событий и остановок торгов нет"))

/datum/controller/subsystem/market/proc/refresh_index_fund()
	var/datum/stock_company/index/fund = companies[STOCK_INDEX_TICKER]
	if(istype(fund))
		fund.recompute()

/// Сколько настоящих компаний на бирже, без индекса.
/datum/controller/subsystem/market/proc/real_company_count()
	. = 0
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(!company.is_index)
			.++

/// Событие компании в очереди: в момент eta двигает акции и уходит в срочные новости рынка.
/datum/market_event
	var/datum/stock_company/company
	var/key
	var/headline
	var/effect
	var/eta
	/// Фальшивый пресс-релиз, а не настоящее событие
	var/fake = FALSE

/datum/market_event/Destroy()
	company = null
	SSmarket.scheduled_events -= src
	return ..()
