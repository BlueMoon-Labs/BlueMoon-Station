/datum/action/shadekin
	name = "Базовая способность шадекинов"
	button_icon = 'icons/mob/actions/shadekin_abilities.dmi'
	icon_icon = 'icons/mob/actions/shadekin_abilities.dmi'
	background_icon_state = "grey_spell_ready"

	var/cost = 50
	var/passive_cost = 0

	//Уровень энергии, отправляет сигналом
	var/dark_energy = 0
	var/is_avalable = TRUE

/datum/action/shadekin/Grant(mob/grant_to)
	to_chat(world, "Вызов идет2")
	. = ..()
	if(!owner)
		return

	RegisterSignal(owner, COMSIG_INFORM_NEW_ENERGY_LEVEL, PROC_REF(handle_dark_energy_change), override = TRUE )
	RegisterSignal(owner, COMSIG_SHADEKIN_ACTION_DELETE, PROC_REF(signal_shadekin_del), override = TRUE )

/datum/action/shadekin/Remove(mob/remove_from)
	if(!owner)
		return ..()

	UnregisterSignal(remove_from, list(
		COMSIG_INFORM_NEW_ENERGY_LEVEL,
		COMSIG_SHADEKIN_ACTION_DELETE
	))
	. = ..()

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
	return cost <= dark_energy ? TRUE : FALSE
//СВОя логика
/datum/action/shadekin/proc/use()

/datum/action/shadekin/proc/signal_shadekin_del(datum/source)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		qdel(src)

/datum/action/shadekin/proc/signal_shadekin_hide(datum/source)
	SIGNAL_HANDLER

/datum/action/shadekin/proc/use_dark_energy(amount)
	return SEND_SIGNAL(owner, COMSIG_ADJUST_DARK_ENERGY, amount)

/datum/action/shadekin/proc/handle_dark_energy_change(datum/source, dark_energy_level)
	SIGNAL_HANDLER
	dark_energy = dark_energy_level
	//Нечего лишний раз кнопочки обновлять
	if(!is_avalable)
		UpdateButtons()
