/// Грант NT бедной станции: казна получает недостающее до порога бедности, в пределах настроек.
/datum/round_event_control/nt_grant
	name = "NT Grant"
	typepath = /datum/round_event/nt_grant
	weight = 8
	weight_can_change = TRUE
	max_occurrences = 2
	earliest_start = 30 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	econ_state_weights = list(ECON_STATE_NORMAL = 0, ECON_STATE_RICH = 0)
	description = "Only for a poor station: NT tops the treasury up toward the poverty line."

/datum/round_event/nt_grant
	fakeable = FALSE

/datum/round_event/nt_grant/start()
	if(triggered_randomly && SSeconomy.economy_state != ECON_STATE_POOR)
		log_econ("Грант NT отменён: станция больше не бедна")
		return
	var/deficit = SSeconomy.poor_deficit()
	if(deficit <= 0)
		log_econ("Грант NT не выдан: деньги станции не ниже черты бедности")
		if(!triggered_randomly)
			message_admins("NT Grant не выдан: деньги станции не ниже черты бедности, грант закрывает только дефицит до неё.")
		return
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/amount = clamp(round(deficit, 100), SSeconomy.settings.event_grant_min, SSeconomy.settings.event_grant_max)
	if(!treasury?.credit(amount, ECON_EVENT, memo = "Стабилизационный грант NT"))
		return
	priority_announce("Финансовый отдел Нанотрейзен признал положение станции тяжёлым и перечисляет в казну стабилизационный грант: [amount] кр. Распоряжаются им капитан и глава персонала.", "Финансовый отдел NT")
