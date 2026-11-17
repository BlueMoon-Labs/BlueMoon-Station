/// Бум в секторе: акции всех компаний растут, несколько товаров становятся горячими.
/datum/round_event_control/sector_boom
	name = "Sector Boom"
	typepath = /datum/round_event/sector_boom
	weight = 12
	max_occurrences = 2
	earliest_start = 20 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	econ_state_weights = list(ECON_STATE_POOR = 2)
	description = "Stocks rise across the sector and a few goods become hot for station exports."

/datum/round_event/sector_boom
	fakeable = FALSE

/datum/round_event/sector_boom/start()
	SSmarket.station_event("sector_boom")
	var/list/candidates = list()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		if(id != COMMODITY_CONTRABAND && commodity.hot_mult <= 1)
			candidates += commodity
	for(var/i in 1 to min(SSeconomy.settings.event_boom_goods, length(candidates)))
		var/datum/commodity/commodity = pick_n_take(candidates)
		commodity.make_hot()
	log_econ("Бум в секторе")
