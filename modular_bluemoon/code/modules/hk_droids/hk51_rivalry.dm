/// Спецзаказ HK-47: ликвидация HK-51 экипажа. В таблицах заказчиков его нет, предложение добавляет add_rival_offer().
/datum/hk_contract_task/kill/rival
	name = "уничтожить улучшенную подделку"
	points = HK47_RIVAL_POINTS

/datum/hk_contract_task/kill/rival/candidate_targets(datum/antagonist/hk47/hunter)
	var/list/rivals = list()
	for(var/datum/mind/candidate as anything in hunter.hunt_pool())
		if(is_species(candidate.current, /datum/species/ipc/hk/hk51) && hunter.valid_target(candidate, required_level(hunter)))
			rivals += candidate
	return rivals

/datum/hk_contract_task/kill/rival/rules_text(datum/hk_contract/contract)
	var/kill_rules = ..()
	return "Цель - HK-51, дроид той же серии на службе у экипажа. [kill_rules]"

/datum/hk_contract_task/kill/rival/on_accept(datum/hk_contract/contract)
	var/mob/living/rival = contract.target_body()
	var/datum/component/hk_loyalty/loyalty = rival?.GetComponent(/datum/component/hk_loyalty)
	var/datum/mind/master = loyalty?.get_master()
	if(master?.current)
		contract.hunter.notify_vip(master.current, "Ваш HK-51 внесён в контракт: дроид-ассасин [HK47_NAME] получил заказ уничтожить «улучшенную подделку». Берегите своего дроида.")
	if(rival)
		contract.hunter.notify_vip(rival, "Предупреждение: ваш серийный номер внесён в контракт. Дроид-ассасин [HK47_NAME] получил заказ уничтожить «улучшенную подделку» - вас.")

/// Живой HK-51 игрока может заменить последнее из предложений спецзаказом на себя.
/datum/antagonist/hk47/proc/add_rival_offer()
	var/datum/hk_contract/rival = rival_offer()
	if(!rival)
		return
	if(length(offers) >= HK47_CONTRACT_OFFERS)
		var/datum/hk_contract/bumped = offers[length(offers)]
		offers -= bumped
		qdel(bumped)
	offers += rival

/datum/antagonist/hk47/proc/rival_offer()
	var/datum/hk_contract_task/rival_task = GLOB.hk_contract_tasks[/datum/hk_contract_task/kill/rival]
	if(!rival_task.is_available(src) || !roll_rival_offer())
		return null
	var/datum/hk_contract/offer = make_contract(pick(HK_CLIENT_SYNDICATE, HK_CLIENT_CORP, HK_CLIENT_PRIVATE), /datum/hk_contract_task/kill/rival)
	offer?.roll_modifier()
	return offer

/datum/antagonist/hk47/proc/roll_rival_offer()
	return prob(HK47_RIVAL_OFFER_CHANCE)
