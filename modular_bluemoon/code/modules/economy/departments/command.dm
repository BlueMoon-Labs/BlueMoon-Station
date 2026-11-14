/datum/economy_department/command
	id = ACCOUNT_CMD
	name = "Командование"
	budget_name = "казна станции"
	head_access = list(ACCESS_CAPTAIN, ACCESS_HOP)

/datum/economy_department/command/start_budget()
	return SSeconomy.settings.treasury_start_budget

/// Стартовая казна и по одному наибольшему запросу на каждый отдел.
/datum/economy_department/command/budget_threshold(list/stats)
	var/datum/economy_settings/settings = SSeconomy.settings
	return settings.treasury_start_budget + settings.treasury_request_max * (length(SSeconomy.departments) - 1)
