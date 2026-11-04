/// Секторальная лотерея: билеты продаются в «Кошельке», по итогам NT забирает долю, остальное - владельцу выигравшего билета.
/datum/round_event_control/money_lottery
	name = "Money Lottery"
	typepath = /datum/round_event/money_lottery
	weight = 20
	max_occurrences = 2
	earliest_start = 15 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "Sector lottery: crew buy tickets in the Wallet app for a while, NT keeps a cut, one ticket wins the rest."

/datum/round_event/money_lottery
	fakeable = FALSE

/datum/round_event/money_lottery/start()
	if(!SSeconomy.start_lottery())
		log_econ("Лотерея не начата: предыдущая ещё идёт")
