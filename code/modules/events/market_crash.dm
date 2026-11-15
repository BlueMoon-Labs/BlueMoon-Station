/// Обвал рынка: тренды всех товаров и акции всех компаний падают вместе с объявлением,
/// а вендоры станции на несколько минут дорожают множителем price_surge_mult поверх индекса цен.
/datum/round_event_control/market_crash
	name = "Market Crash"
	typepath = /datum/round_event/market_crash
	weight = 20
	max_occurrences = 2
	earliest_start = 15 MINUTES
	min_players = 5
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_MILD
	econ_state_weights = list(ECON_STATE_RICH = 2, ECON_STATE_POOR = 0.5)
	description = "Commodity trends and all stocks fall; vending machine prices surge station-wide for a few minutes."

/datum/round_event/market_crash
	announce_when = 1
	start_when = 3
	fakeable = FALSE
	/// Обвал применён и ещё не откачен: страховка от завершения события в обход end()
	var/surge_applied = FALSE
	var/market_crashed = FALSE
	var/stocks_crashed = FALSE

/datum/round_event/market_crash/setup()
	end_when = rand(90, 150)

/datum/round_event/market_crash/announce(fake)
	crash_market()
	var/reason = pick(
		"неудачного взаимного расположения луны и солнца",
		"рискованных вложений в жилищный сектор",
		"безвременного расформирования команды проекта Б.Е.П.И.С.",
		"обратного эффекта спекулятивных грантов TerraGov",
		"сильно преувеличенных слухов о сокращении бухгалтерии NanoTrasen",
		"\"отличного вложения\" в \"невзаимозаменяемые токены\", сделанного \"гением\"",
		"серии рейдов агентов Тигрового Кооператива",
		"перебоев в цепочках поставок",
		"безвременного закрытия социальной сети \"NanoTrasen+\"",
		"неожиданного успеха социальной сети \"NanoTrasen+\"",
		"невезения, наверное",
	)
	priority_announce("Из-за [reason] рынок сектора обвалился: товары[stocks_crashed ? " и акции компаний" : ""] дешевеют, а цены в вендинговых автоматах станции будут временно повышены. Приносим извинения за неудобства.", "Отдел бухгалтерии NanoTrasen")

/// Рынок падает вместе с объявлением, а если его не было - в начале события.
/datum/round_event/market_crash/proc/crash_market()
	if(market_crashed)
		return
	market_crashed = TRUE
	var/remaining = 1 - SSeconomy.settings.event_crash_trend_drop / 100
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.trend *= remaining
		commodity.recompute()
	stocks_crashed = SSmarket.station_event("market_crash")

/datum/round_event/market_crash/start()
	crash_market()
	SSeconomy.price_surge_mult = pick(2, 3, 4)
	surge_applied = TRUE
	refresh_vendor_prices()

/datum/round_event/market_crash/end()
	reset_surge()
	priority_announce("Цены в вендинговых автоматах станции стабилизированы. Благодарим за терпение.", "Отдел бухгалтерии NanoTrasen")

/datum/round_event/market_crash/kill()
	// Если событие сняли до end() (админ/эвакуация), цены не должны застрять взвинченными
	if(surge_applied)
		reset_surge()
	return ..()

/datum/round_event/market_crash/proc/reset_surge()
	surge_applied = FALSE
	SSeconomy.price_surge_mult = 1
	refresh_vendor_prices()

/datum/round_event/market_crash/proc/refresh_vendor_prices()
	for(var/obj/machinery/vending/vendor in GLOB.machines)
		vendor.refresh_prices()
		CHECK_TICK
