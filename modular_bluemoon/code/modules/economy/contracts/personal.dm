/datum/controller/subsystem/economy/proc/personal_contracts_of(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/econ_contract/contract as anything in loose_contracts)
		if(contract.owner == account)
			. += contract

/// Личные заказы выдаются счетам экипажа станции.
/datum/controller/subsystem/economy/proc/gets_personal_offers(datum/bank_account/account)
	return account && !account.offstation && (account in bank_accounts)

/// Добирает подборку личных заказов счёта до contract_personal_offers.
/datum/controller/subsystem/economy/proc/ensure_personal_offers(datum/bank_account/account)
	if(!contracts_started || !gets_personal_offers(account))
		return
	var/have = length(personal_contracts_of(account))
	while(have < settings.contract_personal_offers)
		if(!generate_personal_contract(account))
			return
		have++

/// Личный заказ из заказов отдела счёта и общих гражданских; того, что уже есть в подборке, не повторяет.
/datum/controller/subsystem/economy/proc/generate_personal_contract(datum/bank_account/account)
	var/list/by_department = econ_bounty_types_by_department()
	var/list/bounty_types = list()
	for(var/department_id in list(account.department_id, ACCOUNT_CIV))
		var/list/department_types = by_department[department_id]
		if(department_types)
			bounty_types |= department_types
	for(var/datum/econ_contract/delivery/existing in personal_contracts_of(account))
		bounty_types -= existing.bounty.type
	var/datum/bounty/bounty = pick_bounty(bounty_types)
	if(!bounty)
		return null
	var/datum/econ_contract/delivery/contract = new(econ_bounty_department_of(bounty.type), bounty)
	contract.set_owner(account)
	loose_contracts += contract
	return contract

/// Меняет невзятые личные заказы счёта на новые. Возвращает list(удалось ли, ответ игроку).
/datum/controller/subsystem/economy/proc/reroll_personal_offers(datum/bank_account/account)
	if(!gets_personal_offers(account))
		return list(FALSE, "Личные заказы NT выдаёт только экипажу станции.")
	if(!COOLDOWN_FINISHED(account, contract_reroll_cooldown))
		return list(FALSE, "Подборку личных заказов можно обновить через [DisplayTimeText(COOLDOWN_TIMELEFT(account, contract_reroll_cooldown), 1)].")
	for(var/datum/econ_contract/contract as anything in personal_contracts_of(account))
		if(!contract.taker && !contract.has_progress())
			qdel(contract)
	COOLDOWN_START(account, contract_reroll_cooldown, ECON_CONTRACT_REROLL_COOLDOWN)
	ensure_personal_offers(account)
	return list(TRUE, "Подборка личных заказов обновлена.")
