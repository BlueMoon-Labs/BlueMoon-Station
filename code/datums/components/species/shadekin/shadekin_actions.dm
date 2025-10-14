/datum/action/shadekin
	name = "Базовая способность шадекинов"
	var/cost = 50
	var/passive_cost = 0

	//Уровень энергии, отправляет сигналом
	var/dark_energy = 0
	var/is_avalable = TRUE

/datum/action/shadekin/Grant(mob/grant_to)
	RegisterSignal(grant_to, COMSIG_INFORM_NEW_ENERGY_LEVEL, PROC_REF(handle_dark_energy_change))
	RegisterSignal(grant_to, COMSIG_SHADEKIN_ACTION_DELETE, PROC_REF(signal_shadekin_del))

/datum/action/shadekin/Remove(mob/remove_from)
	UnregisterSignal(remove_from, list(
		COMSIG_INFORM_NEW_ENERGY_LEVEL,
		COMSIG_SHADEKIN_ACTION_DELETE
	))

/datum/action/shadekin/IsAvailable(silent = FALSE)
	var/enough_energy = check_energy()
	is_avalable = FALSE

	if(enough_energy && ..())
		is_avalable = TRUE
		UpdateButtons()
	return is_avalable

/datum/action/shadekin/Trigger()
	. = ..()
	if(!.)
		return
	return use()

/datum/action/shadekin/proc/check_energy()
	return cost >= dark_energy ? TRUE : FALSE
//СВОя логика
/datum/action/shadekin/proc/use()

/datum/action/shadekin/proc/signal_shadekin_del(datum/source)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		qdel(src)

/datum/action/shadekin/proc/signal_shadekin_hide(datum/source)
	SIGNAL_HANDLER

/datum/action/shadekin/proc/use_dark_energy(amount = cost)
	return SEND_SIGNAL(COMSIG_ADJUST_DARK_ENERGY, amount)

/datum/action/shadekin/proc/handle_dark_energy_change(datum/source, dark_energy_level)
	SIGNAL_HANDLER
	dark_energy = dark_energy_level
	//Нечего лишний раз кнопочки обновлять
	if(!is_avalable)
		UpdateButtons()
