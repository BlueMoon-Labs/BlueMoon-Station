GLOBAL_LIST_INIT(hk_contract_modifiers, hk_contract_singletons(/datum/hk_contract_modifier))

/// Дополнительное условие контракта: соблюдено в момент выполнения - бонусное очко, нарушено - просто без бонуса.
/datum/hk_contract_modifier
	var/name
	var/list/task_types
	/// Контракт следит за смертями от рук HK и слуг.
	var/tracks_collateral = FALSE

/datum/hk_contract_modifier/proc/compatible(datum/hk_contract/contract)
	return is_type_in_list(contract.task, task_types)

/datum/hk_contract_modifier/proc/holds(datum/hk_contract/contract)
	return FALSE

/datum/hk_contract_modifier/proc/rules_text()
	return ""

/datum/hk_contract_modifier/no_witnesses
	name = "без свидетелей"
	task_types = list(
		/datum/hk_contract_task/kill,
		/datum/hk_contract_task/capture,
		/datum/hk_contract_task/theft,
		/datum/hk_contract_task/sabotage,
	)

/datum/hk_contract_modifier/no_witnesses/holds(datum/hk_contract/contract)
	return !contract.witnessed && !length(contract.hunter.witnesses(contract))

/datum/hk_contract_modifier/no_witnesses/rules_text()
	return "Ни в один решающий момент рядом нет других игроков: в [HK47_WITNESS_RANGE] клетках от вас, в прямой видимости. Решающие моменты - удар вас или слуг по цели, её смерть, добыча кражи в вашей руке (ID, печать или ценность), вызов капсулы и выполнение контракта. Ваши слуги не в счёт."

/datum/hk_contract_modifier/urgent
	name = "срочно"
	task_types = list(
		/datum/hk_contract_task/kill,
		/datum/hk_contract_task/capture,
		/datum/hk_contract_task/theft,
		/datum/hk_contract_task/sabotage,
		/datum/hk_contract_task/hunt,
	)

/datum/hk_contract_modifier/urgent/holds(datum/hk_contract/contract)
	return world.time - contract.accepted_at <= HK47_URGENT_TIME

/datum/hk_contract_modifier/urgent/rules_text()
	return "Выполнить за [DisplayTimeText(HK47_URGENT_TIME)] после принятия."

/datum/hk_contract_modifier/accident
	name = "несчастный случай"
	task_types = list(
		/datum/hk_contract_task/kill,
		/datum/hk_contract_task/hunt,
	)

/datum/hk_contract_modifier/accident/compatible(datum/hk_contract/contract)
	return contract.lethal && ..()

/datum/hk_contract_modifier/accident/holds(datum/hk_contract/contract)
	return contract.target_died && contract.death_was_accident

/datum/hk_contract_modifier/accident/rules_text()
	return "Цель гибнет без прямого попадания от вас или ваших слуг за последние [DisplayTimeText(HK47_HIT_MEMORY)] до смерти."

/datum/hk_contract_modifier/no_collateral
	name = "без лишних жертв"
	task_types = list(
		/datum/hk_contract_task/kill,
		/datum/hk_contract_task/capture,
		/datum/hk_contract_task/theft,
		/datum/hk_contract_task/sabotage,
		/datum/hk_contract_task/protect,
		/datum/hk_contract_task/hunt,
	)
	tracks_collateral = TRUE

/datum/hk_contract_modifier/no_collateral/holds(datum/hk_contract/contract)
	return !contract.collateral

/datum/hk_contract_modifier/no_collateral/rules_text()
	return "Пока контракт активен, вы и ваши слуги больше никого не убиваете. Смерть в течение [DisplayTimeText(HK47_HIT_MEMORY)] после вашего попадания или попадания слуги считается вашей."
