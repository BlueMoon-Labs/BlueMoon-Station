/// Дефицит товара: его цена сразу растёт и держится несколько сдвигов рынка, закупки дороже, продажа выгоднее.
/datum/round_event_control/commodity_shortage
	name = "Commodity Shortage"
	typepath = /datum/round_event/commodity_shortage
	weight = 12
	max_occurrences = 3
	earliest_start = 15 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "One commodity jumps in price for a few market shifts: supply packs cost more, exports pay more."

/datum/round_event/commodity_shortage
	fakeable = FALSE

/datum/round_event/commodity_shortage/start()
	var/list/candidates = list()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		if(id != COMMODITY_CONTRABAND && !commodity.shortage_shifts_left)
			candidates += commodity
	if(!length(candidates))
		return
	var/datum/commodity/commodity = pick(candidates)
	var/shifts = SSeconomy.settings.event_shortage_shifts
	commodity.start_shortage(SSeconomy.settings.event_shortage_mult, shifts)
	log_econ("Дефицит товара [commodity.name]: тренд [round(commodity.trend, 0.01)] на [shifts] сдвигов")
	SSmarket.post_news("Дефицит в секторе: [commodity.name] дорожает до ×[round(commodity.price_factor, 0.01)] базовой цены и держится около этого уровня ближайшие [shifts * SSmarket.shift_minutes] мин. Паки с этим товаром стоят дороже, продавать его выгоднее.")
