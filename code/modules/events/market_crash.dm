/// Обвал рынка (порт tgstation "Market Crash"): бухгалтерия NanoTrasen объявляет
/// о временном скачке цен - на несколько минут все вендоры станции дорожают в разы,
/// потом цены стабилизируются. Реализовано множителем price_surge_mult поверх штатной
/// инфляции SSeconomy: вендоры пересчитываются штатным reset_prices, никакого нового
/// прайс-пути. Нелетальная неприятность и повод для нытья на общем канале.
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
	description = "Vending machine prices surge station-wide for a few minutes, then stabilize."

/datum/round_event/market_crash
	announce_when = 1
	start_when = 3
	/// Обвал применён и ещё не откачен: страховка от завершения события в обход end()
	var/surge_applied = FALSE

/datum/round_event/market_crash/setup()
	end_when = rand(90, 150)

/datum/round_event/market_crash/announce(fake)
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
	priority_announce("Из-за [reason] цены в вендинговых автоматах станции будут временно повышены. Приносим извинения за неудобства.", "Отдел бухгалтерии NanoTrasen")

/datum/round_event/market_crash/start()
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
		vendor.reset_prices(vendor.product_records, vendor.coin_records)
		CHECK_TICK
