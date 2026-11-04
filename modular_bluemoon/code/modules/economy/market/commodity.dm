/// Встроенные товары рынка: на них SSmarket откатывается, если секция market в economy.json битая.
GLOBAL_LIST_INIT(market_default_commodities, list(
	COMMODITY_METALS = list("name" = "Металлы", "volatility" = 0.05, "links" = list(COMMODITY_ELECTRONICS = 0.3, COMMODITY_MACHINERY = 0.3, COMMODITY_CONSTRUCTION = 0.4)),
	COMMODITY_PRECIOUS = list("name" = "Драгметаллы", "volatility" = 0.08, "links" = list(COMMODITY_LUXURY = 0.3)),
	COMMODITY_PLASMA = list("name" = "Плазма", "volatility" = 0.1, "links" = list(COMMODITY_FUEL = 0.5, COMMODITY_ENERGY = 0.2)),
	COMMODITY_CRYSTALS = list("name" = "Кристаллы", "volatility" = 0.09),
	COMMODITY_GASES = list("name" = "Газы", "volatility" = 0.06),
	COMMODITY_ENERGY = list("name" = "Энергия", "volatility" = 0.07),
	COMMODITY_FOOD = list("name" = "Продукты", "volatility" = 0.05, "consumer" = TRUE, "links" = list(COMMODITY_DRINKS = 0.3)),
	COMMODITY_DRINKS = list("name" = "Напитки", "volatility" = 0.05, "consumer" = TRUE),
	COMMODITY_MEDICINE = list("name" = "Медикаменты", "volatility" = 0.06, "consumer" = TRUE, "links" = list(COMMODITY_CHEMICALS = 0.4)),
	COMMODITY_CHEMICALS = list("name" = "Химреактивы", "volatility" = 0.07),
	COMMODITY_ELECTRONICS = list("name" = "Электроника", "volatility" = 0.06, "links" = list(COMMODITY_ROBOTICS = 0.4)),
	COMMODITY_MACHINERY = list("name" = "Механизмы", "volatility" = 0.05),
	COMMODITY_ROBOTICS = list("name" = "Роботехника", "volatility" = 0.07),
	COMMODITY_WEAPONS = list("name" = "Оружие", "volatility" = 0.08),
	COMMODITY_TEXTILES = list("name" = "Текстиль", "volatility" = 0.04, "consumer" = TRUE),
	COMMODITY_LUXURY = list("name" = "Роскошь", "volatility" = 0.1, "consumer" = TRUE),
	COMMODITY_BIOMATERIALS = list("name" = "Биоматериалы", "volatility" = 0.09),
	COMMODITY_ARTIFACTS = list("name" = "Артефакты", "volatility" = 0.12),
	COMMODITY_SEEDS = list("name" = "Семена", "volatility" = 0.05, "links" = list(COMMODITY_FOOD = 0.2)),
	COMMODITY_CONSTRUCTION = list("name" = "Стройматериалы", "volatility" = 0.04),
	COMMODITY_FUEL = list("name" = "Топливо", "volatility" = 0.08, "links" = list(COMMODITY_ENERGY = 0.3)),
	COMMODITY_CULTURE = list("name" = "Культура", "volatility" = 0.06),
	COMMODITY_CONTRABAND = list("name" = "Контрабанда", "volatility" = 0.12, "demand_capacity" = 5000),
))

/datum/commodity
	var/id
	var/name = "товар"
	/// Сигма случайного шага тренда за сдвиг
	var/volatility = 0.05
	var/trend = 1
	var/noise = 0
	/// Множитель цены продажи, пока товар горячий
	var/hot_mult = 1
	var/hot_shifts_left = 0
	/// 0..1, продажи выбивают, сдвиги восстанавливают
	var/demand = 1
	/// Сумма продаж, которая выбивает весь спрос
	var/demand_capacity = 20000
	var/demand_recovery = 0.1
	/// Входит в корзину индекса цен
	var/consumer = FALSE
	/// id связанного товара -> доля передачи отклонения тренда
	var/list/links = list()
	var/price_factor = 1
	var/list/history = list()
	/// Дефицит: столько сдвигов тренд не опускается ниже shortage_trend
	var/shortage_shifts_left = 0
	var/shortage_trend = 1

/datum/commodity/proc/reset_params()
	name = initial(name)
	volatility = initial(volatility)
	demand_capacity = initial(demand_capacity)
	demand_recovery = initial(demand_recovery)
	consumer = initial(consumer)
	links = list()

/// Накладывает запись конфига и возвращает ошибки "id.ключ: ..."; неверное значение параметр не меняет.
/datum/commodity/proc/configure(list/entry, list/known_ids)
	. = list()
	for(var/key in entry)
		var/value = entry[key]
		switch(key)
			if("name")
				if(istext(value) && length(value))
					name = value
				else
					. += "[id].name: нужна непустая строка"
			if("volatility")
				if(isnum(value) && value >= 0 && value <= MARKET_VOLATILITY_MAX)
					volatility = value
				else
					. += "[id].volatility: нужно число 0..[MARKET_VOLATILITY_MAX]"
			if("demand_capacity")
				if(isnum(value) && value >= 1)
					demand_capacity = value
				else
					. += "[id].demand_capacity: нужно число не меньше 1"
			if("demand_recovery")
				if(isnum(value) && value >= 0 && value <= 1)
					demand_recovery = value
				else
					. += "[id].demand_recovery: нужно число 0..1"
			if("consumer")
				if(isnum(value) && (value == TRUE || value == FALSE))
					consumer = value
				else
					. += "[id].consumer: нужно true или false"
			if("links")
				if(!islist(value))
					. += "[id].links: не объект"
					continue
				var/list/accepted = list()
				for(var/linked_id in value)
					var/share = value[linked_id]
					if(linked_id == id || !(linked_id in known_ids))
						. += "[id].links.[linked_id]: нет такого товара"
					else if(!isnum(share) || share < 0 || share > 1)
						. += "[id].links.[linked_id]: нужно число 0..1"
					else
						accepted[linked_id] = share
				links = accepted
			else
				if(!ECON_CONFIG_COMMENT_KEY(key))
					. += "[id]: неизвестный ключ [key]"

/datum/commodity/proc/shift(hot_chance)
	trend = 1 + (trend - 1) * MARKET_TREND_REVERSION + gaussian(0, volatility)
	if(shortage_shifts_left)
		shortage_shifts_left--
		trend = max(trend, shortage_trend)
	noise = gaussian(0, volatility / 2)
	if(hot_shifts_left)
		hot_shifts_left--
		if(!hot_shifts_left)
			hot_mult = 1
	else if(id != COMMODITY_CONTRABAND && prob(hot_chance))
		make_hot()
	demand = min(1, demand + demand_recovery)
	recompute()
	history += price_factor
	if(length(history) > MARKET_HISTORY_MAX)
		history.Cut(1, length(history) - MARKET_HISTORY_MAX + 1)

/datum/commodity/proc/make_hot()
	hot_mult = MARKET_HOT_MULT_MIN + rand() * (MARKET_HOT_MULT_MAX - MARKET_HOT_MULT_MIN)
	hot_shifts_left = rand(MARKET_HOT_SHIFTS_MIN, MARKET_HOT_SHIFTS_MAX)
	SEND_SIGNAL(SSmarket, COMSIG_MARKET_HOT, src)

/// Тренд сразу умножается на mult и держится не ниже этого уровня shifts сдвигов.
/datum/commodity/proc/start_shortage(mult, shifts)
	trend = clamp(trend * mult, MARKET_PRICE_MIN, MARKET_PRICE_MAX)
	shortage_trend = trend
	shortage_shifts_left = shifts
	recompute()

/datum/commodity/proc/recompute()
	trend = clamp(trend, MARKET_PRICE_MIN, MARKET_PRICE_MAX)
	price_factor = clamp(trend * (1 + noise), MARKET_PRICE_MIN, MARKET_PRICE_MAX)

/datum/commodity/proc/sell_factor()
	return clamp(price_factor * hot_mult, MARKET_PRICE_MIN, MARKET_PRICE_MAX) * (MARKET_DEMAND_FLOOR + (1 - MARKET_DEMAND_FLOOR) * demand)

/datum/commodity/proc/buy_factor()
	return price_factor

/datum/commodity/proc/note_sale(value)
	demand = clamp(demand - value / demand_capacity, 0, 1)
